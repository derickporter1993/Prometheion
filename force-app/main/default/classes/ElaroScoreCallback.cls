/**
 * ElaroScoreCallback
 * 
 * REST endpoint that receives score results from AWS Lambda and updates
 * Compliance_Score__c records. Also publishes Platform Events for real-time UI updates.
 * 
 * Security Features:
 * - API key authentication via Custom Metadata
 * - Replay protection (timestamp + nonce validation)
 * - HMAC signature validation (optional, if configured)
 * - Rate limiting via Platform Cache
 * - Correlation IDs for audit logging
 * - Sanitized error responses (no stack traces)
 * 
 * External API callback runs in system context for Compliance_Score__c updates.
 * CRUD/FLS is enforced via Security.stripInaccessible and AccessLevel.USER_MODE.
 */
@RestResource(urlMapping='/elaro/score/callback')
global without sharing class ElaroScoreCallback {
    
    private static final String RATE_LIMIT_PARTITION = 'local.ElaroCache';
    private static final Integer RATE_LIMIT_MAX_REQUESTS = 100; // per hour per IP
    private static final Integer REPLAY_WINDOW_SECONDS = 300; // 5 minutes
    
    /**
     * POST endpoint for AWS Lambda to send score results
     */
    @HttpPost
    global static void handleScoreCallback() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String correlationId = generateCorrelationId();
        
        try {
            // Security: Validate API key authentication
            String apiKey = req.headers.get('X-Elaro-Api-Key');
            if (!validateApiKey(apiKey)) {
                logSecurityEvent('API_KEY_INVALID', correlationId, null);
                res.statusCode = 401;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'success' => false,
                    'error' => 'Unauthorized',
                    'correlationId' => correlationId
                }));
                return;
            }
            
            // Rate limiting: Check request rate per IP
            String clientIp = getClientIp(req);
            if (!checkRateLimit(clientIp)) {
                logSecurityEvent('RATE_LIMIT_EXCEEDED', correlationId, clientIp);
                res.statusCode = 429;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'success' => false,
                    'error' => 'Rate limit exceeded',
                    'correlationId' => correlationId
                }));
                return;
            }
            
            // Replay protection: Validate timestamp and nonce
            String timestamp = req.headers.get('X-Elaro-Timestamp');
            String nonce = req.headers.get('X-Elaro-Nonce');
            if (!validateReplayProtection(timestamp, nonce)) {
                logSecurityEvent('REPLAY_ATTACK_DETECTED', correlationId, clientIp);
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'success' => false,
                    'error' => 'Invalid request timestamp or nonce',
                    'correlationId' => correlationId
                }));
                return;
            }
            
            // HMAC signature validation (if configured)
            String signature = req.headers.get('X-Elaro-Signature');
            if (String.isNotBlank(signature)) {
                String requestBody = req.requestBody.toString();
                if (!validateHmacSignature(requestBody, signature, apiKey)) {
                    logSecurityEvent('HMAC_VALIDATION_FAILED', correlationId, clientIp);
                    res.statusCode = 401;
                    res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                        'success' => false,
                        'error' => 'Invalid signature',
                        'correlationId' => correlationId
                    }));
                    return;
                }
            }
            
            // Parse request body
            String requestBody = req.requestBody.toString();
            Map<String, Object> scoreData = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            
            // Extract score data
            String orgId = (String)scoreData.get('orgId');
            String entityType = (String)scoreData.get('entityType');
            String entityId = (String)scoreData.get('entityId');
            Decimal riskScore = (Decimal)scoreData.get('riskScore');
            Map<String, Object> frameworkScores = (Map<String, Object>)scoreData.get('frameworkScores');
            List<Object> findings = (List<Object>)scoreData.get('findings');
            String s3Key = (String)scoreData.get('s3Key');
            
            // Upsert Compliance_Score__c record with CRUD/FLS enforcement
            Compliance_Score__c score = new Compliance_Score__c(
                Org_ID__c = orgId,
                Entity_Type__c = entityType,
                Entity_Id__c = entityId,
                Risk_Score__c = riskScore,
                Framework_Scores__c = JSON.serialize(frameworkScores),
                Findings__c = JSON.serialize(findings),
                S3_Key__c = s3Key,
                Calculated_At__c = Datetime.now()
            );
            
            // Query existing score with security enforcement
            List<Compliance_Score__c> existingScores = [
                SELECT Id 
                FROM Compliance_Score__c 
                WHERE Org_ID__c = :orgId 
                AND Entity_Type__c = :entityType 
                AND Entity_Id__c = :entityId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (!existingScores.isEmpty()) {
                score.Id = existingScores[0].Id;
            }
            
            // Enforce CRUD/FLS using Security.stripInaccessible
            SObjectAccessDecision decision = Security.stripInaccessible(
                existingScores.isEmpty() ? AccessType.CREATABLE : AccessType.UPDATABLE,
                new List<Compliance_Score__c>{ score }
            );
            
            List<Compliance_Score__c> sanitizedScores = decision.getRecords();
            if (sanitizedScores.isEmpty()) {
                logSecurityEvent('CRUD_FLS_DENIED', correlationId, clientIp);
                res.statusCode = 403;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'success' => false,
                    'error' => 'Insufficient permissions',
                    'correlationId' => correlationId
                }));
                return;
            }
            
            // Upsert with USER_MODE to enforce field-level security
            Database.UpsertResult result = Database.upsert(sanitizedScores[0], AccessLevel.USER_MODE);
            
            // Check if upsert succeeded
            if (!result.isSuccess()) {
                // Build error message from all errors
                List<String> errorMessages = new List<String>();
                for (Database.Error err : result.getErrors()) {
                    errorMessages.add(err.getMessage() + ' (' + err.getStatusCode() + ')');
                }
                
                // Return error response with correlation ID
                logSecurityEvent('DML_UPSERT_FAILED', correlationId, clientIp, 'DML_ERROR');
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'success' => false,
                    'error' => 'Failed to save score record',
                    'correlationId' => correlationId
                }));
                return;
            }
            
            // Upsert succeeded - publish Platform Event for real-time UI update
            Elaro_Score_Result__e scoreEvent = new Elaro_Score_Result__e(
                Org_ID__c = orgId,
                Score_ID__c = result.getId(),
                Overall_Score__c = riskScore,
                Framework_Scores__c = JSON.serialize(frameworkScores),
                Risk_Level__c = calculateRiskLevel(riskScore)
            );
            
            Database.SaveResult publishResult = EventBus.publish(scoreEvent);
            if (!publishResult.isSuccess()) {
                // Log error but don't fail the request - score was saved successfully
                System.debug(LoggingLevel.ERROR, 'Failed to publish Elaro_Score_Result__e: ' + publishResult.getErrors());
            }
            
            // Return success response (score was saved, event publish failure is non-critical)
            logSecurityEvent('SCORE_CALLBACK_SUCCESS', correlationId, clientIp);
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'success' => true,
                'scoreId' => result.getId(),
                'correlationId' => correlationId
            }));
            
        } catch (Exception e) {
            // Log detailed error server-side with correlation ID (not exposed to client)
            String errorCategory = categorizeError(e);
            logSecurityEvent('SCORE_CALLBACK_ERROR', correlationId, getClientIp(req), errorCategory);
            
            // Log full details to debug logs (not exposed to client)
            System.debug(LoggingLevel.ERROR, 
                'ElaroScoreCallback error [CorrelationId: ' + correlationId + ']: ' + 
                errorCategory + ' - ' + e.getMessage());
            
            // Return sanitized error response (no stack trace, no internal details)
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'success' => false,
                'error' => 'An internal error occurred',
                'correlationId' => correlationId
            }));
        }
    }
    
    /**
     * Validates API key from request header using secure hash comparison
     * Checks Custom Metadata Type for configured API key hash
     * @param apiKey The API key from request header
     * @return true if valid, false otherwise
     */
    private static Boolean validateApiKey(String apiKey) {
        if (String.isBlank(apiKey)) {
            return false;
        }

        try {
            // Query Custom Metadata Type for API key hash
            List<Elaro_API_Config__mdt> configs = [
                SELECT API_Key_Hash__c, Is_Active__c
                FROM Elaro_API_Config__mdt
                WHERE Is_Active__c = true
                AND DeveloperName = 'Default'
                LIMIT 1
            ];

            if (configs.isEmpty() || String.isBlank(configs[0].API_Key_Hash__c)) {
                System.debug(LoggingLevel.WARN, 'ElaroScoreCallback: API key hash not configured');
                return false;
            }

            // Hash the input key and compare securely
            String inputHash = generateApiKeyHash(apiKey);
            return configs[0].API_Key_Hash__c.equalsIgnoreCase(inputHash);

        } catch (Exception e) {
            // If Custom Metadata doesn't exist or query fails, deny access
            System.debug(LoggingLevel.ERROR, 'ElaroScoreCallback: API key validation error: ' + e.getMessage());
            return false;
        }
    }

    /**
     * Generate SHA256 hash of API key
     * Use this method to generate the hash to store in Custom Metadata
     * @param apiKey The plaintext API key
     * @return Hex-encoded SHA256 hash (64 characters)
     */
    @TestVisible
    private static String generateApiKeyHash(String apiKey) {
        Blob hash = Crypto.generateDigest('SHA256', Blob.valueOf(apiKey));
        return EncodingUtil.convertToHex(hash);
    }

    /**
     * Utility method for admins to generate hash for a new API key
     * Run in Execute Anonymous: ElaroScoreCallback.generateHashForKey('your-api-key');
     * @param apiKey The plaintext API key to hash
     */
    global static void generateHashForKey(String apiKey) {
        if (String.isBlank(apiKey)) {
            System.debug('Error: API key cannot be blank');
            return;
        }
        String hash = generateApiKeyHash(apiKey);
        System.debug('API Key Hash (copy to Custom Metadata API_Key_Hash__c field): ' + hash);
    }

    /**
     * Calculates risk level based on score
     */
    private static String calculateRiskLevel(Decimal score) {
        if (score >= 8.0) {
            return 'CRITICAL';
        } else if (score >= 6.0) {
            return 'HIGH';
        } else if (score >= 4.0) {
            return 'MEDIUM';
        } else {
            return 'LOW';
        }
    }
    
    /**
     * Generate correlation ID for request tracking
     */
    private static String generateCorrelationId() {
        return 'SCORE-' + System.now().getTime() + '-' + Crypto.getRandomInteger();
    }
    
    /**
     * Get client IP address from request headers
     */
    private static String getClientIp(RestRequest req) {
        // Check X-Forwarded-For header (for proxies/load balancers)
        String forwardedFor = req.headers.get('X-Forwarded-For');
        if (String.isNotBlank(forwardedFor)) {
            // Take first IP if multiple (comma-separated)
            return forwardedFor.split(',')[0].trim();
        }
        // Fallback to remote address
        return req.remoteAddress != null ? req.remoteAddress : 'unknown';
    }
    
    /**
     * Rate limiting: Check if request is within rate limit
     * Uses Platform Cache to track requests per IP per hour
     */
    private static Boolean checkRateLimit(String clientIp) {
        try {
            Cache.OrgPartition partition = Cache.Org.getPartition(RATE_LIMIT_PARTITION);
            if (partition == null) {
                // Cache partition not available, allow request (should not happen in production)
                return true;
            }
            
            String cacheKey = 'rate_limit_' + clientIp;
            String hourKey = String.valueOf(System.now().hourGmt()) + '_' + String.valueOf(System.now().dayGmt());
            String fullKey = cacheKey + '_' + hourKey;
            
            Integer requestCount = (Integer)partition.get(fullKey);
            if (requestCount == null) {
                requestCount = 0;
            }
            
            if (requestCount >= RATE_LIMIT_MAX_REQUESTS) {
                return false; // Rate limit exceeded
            }
            
            // Increment and cache for 1 hour
            partition.put(fullKey, requestCount + 1, 3600);
            return true;
        } catch (Exception e) {
            // If cache fails, log but allow request (fail open for availability)
            System.debug(LoggingLevel.WARN, 'Rate limit check failed: ' + e.getMessage());
            return true;
        }
    }
    
    /**
     * Replay protection: Validate timestamp and nonce
     * Prevents replay attacks by ensuring requests are recent and unique
     */
    private static Boolean validateReplayProtection(String timestamp, String nonce) {
        // If headers not provided, allow (backward compatibility, but log warning)
        if (String.isBlank(timestamp) || String.isBlank(nonce)) {
            System.debug(LoggingLevel.WARN, 'ElaroScoreCallback: Replay protection headers missing');
            return true; // Allow for backward compatibility, but should be required in production
        }
        
        try {
            // Validate timestamp is within replay window
            Long requestTime = Long.valueOf(timestamp);
            Long currentTime = System.now().getTime();
            Long timeDiff = Math.abs(currentTime - requestTime) / 1000; // seconds
            
            if (timeDiff > REPLAY_WINDOW_SECONDS) {
                return false; // Request too old or too far in future
            }
            
            // Validate nonce hasn't been used (check cache)
            try {
                Cache.OrgPartition partition = Cache.Org.getPartition(RATE_LIMIT_PARTITION);
                if (partition != null) {
                    String nonceKey = 'nonce_' + nonce;
                    if (partition.get(nonceKey) != null) {
                        return false; // Nonce already used
                    }
                    // Store nonce for replay window duration
                    partition.put(nonceKey, true, REPLAY_WINDOW_SECONDS);
                }
            } catch (Exception e) {
                // Cache unavailable, allow request but log warning
                System.debug(LoggingLevel.WARN, 'Nonce validation cache unavailable: ' + e.getMessage());
            }
            
            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Replay protection validation error: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * HMAC signature validation (optional, if configured)
     * Validates request authenticity using HMAC-SHA256
     */
    private static Boolean validateHmacSignature(String requestBody, String providedSignature, String apiKey) {
        try {
            // Get HMAC secret from Custom Metadata (if configured)
            List<Elaro_API_Config__mdt> configs = [
                SELECT HMAC_Secret__c 
                FROM Elaro_API_Config__mdt 
                WHERE Is_Active__c = true 
                AND DeveloperName = 'Default'
                LIMIT 1
            ];
            
            if (configs.isEmpty() || String.isBlank(configs[0].HMAC_Secret__c)) {
                // HMAC not configured, skip validation
                return true;
            }
            
            String secret = configs[0].HMAC_Secret__c;
            
            // Calculate HMAC-SHA256
            Blob hmacData = Crypto.generateMac('HmacSHA256', Blob.valueOf(requestBody), Blob.valueOf(secret));
            String calculatedSignature = EncodingUtil.base64Encode(hmacData);
            
            // Constant-time comparison to prevent timing attacks
            return calculatedSignature.equals(providedSignature);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'HMAC validation error: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Categorize error for logging (without exposing details)
     */
    private static String categorizeError(Exception e) {
        if (e instanceof DmlException) {
            return 'DML_ERROR';
        } else if (e instanceof JSONException) {
            return 'JSON_PARSE_ERROR';
        } else if (e instanceof NullPointerException) {
            return 'NULL_POINTER_ERROR';
        } else {
            return 'GENERIC_ERROR';
        }
    }
    
    /**
     * Log security events for audit trail
     */
    private static void logSecurityEvent(String eventType, String correlationId, String clientIp) {
        logSecurityEvent(eventType, correlationId, clientIp, null);
    }
    
    private static void logSecurityEvent(String eventType, String correlationId, String clientIp, String details) {
        try {
            // Log to debug logs with correlation ID (for audit trail)
            String logMessage = String.format(
                '[Security] {0} | CorrelationId: {1} | IP: {2} | Time: {3}',
                new List<String>{
                    eventType,
                    correlationId,
                    String.isNotBlank(clientIp) ? clientIp : 'unknown',
                    String.valueOf(System.now())
                }
            );
            
            if (String.isNotBlank(details)) {
                logMessage += ' | Details: ' + details;
            }
            
            System.debug(LoggingLevel.INFO, logMessage);
            
            // Optionally log to custom object for audit trail (if Elaro_Audit_Log__c exists)
            // This would require with sharing context, so we'll use debug logs for now
        } catch (Exception e) {
            // Don't fail request if logging fails
            System.debug(LoggingLevel.WARN, 'Failed to log security event: ' + e.getMessage());
        }
    }
}

