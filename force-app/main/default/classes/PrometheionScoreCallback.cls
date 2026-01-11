/**
 * PrometheionScoreCallback
 * 
 * REST endpoint that receives score results from AWS Lambda and updates
 * Compliance_Score__c records. Also publishes Platform Events for real-time UI updates.
 */
@RestResource(urlMapping='/prometheion/score/callback')
global class PrometheionScoreCallback {
    
    /**
     * POST endpoint for AWS Lambda to send score results
     */
    @HttpPost
    global static void handleScoreCallback() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        // Security: Validate API key authentication
        String apiKey = req.headers.get('X-Prometheion-Api-Key');
        if (!validateApiKey(apiKey)) {
            res.statusCode = 401;
            res.responseBody = Blob.valueOf('{"success":false,"error":"Unauthorized"}');
            return;
        }
        
        try {
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
            
            // Upsert Compliance_Score__c record
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
            
            // Use external IDs for upsert (composite key: Org_ID__c + Entity_Type__c + Entity_Id__c)
            // Note: Salesforce doesn't support composite external IDs directly
            // So we'll use a single external ID field or query first
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
            
            Database.UpsertResult result = Database.upsert(score, false);
            
            // Check if upsert succeeded
            if (!result.isSuccess()) {
                // Build error message from all errors
                List<String> errorMessages = new List<String>();
                for (Database.Error err : result.getErrors()) {
                    errorMessages.add(err.getMessage() + ' (' + err.getStatusCode() + ')');
                }
                
                // Return error response
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'success' => false,
                    'error' => 'Failed to upsert Compliance_Score__c record',
                    'details' => String.join(errorMessages, '; ')
                }));
                return;
            }
            
            // Upsert succeeded - publish Platform Event for real-time UI update
            Prometheion_Score_Result__e scoreEvent = new Prometheion_Score_Result__e(
                Org_ID__c = orgId,
                Score_ID__c = result.getId(),
                Overall_Score__c = riskScore,
                Framework_Scores__c = JSON.serialize(frameworkScores),
                Risk_Level__c = calculateRiskLevel(riskScore)
            );
            
            Database.SaveResult publishResult = EventBus.publish(scoreEvent);
            if (!publishResult.isSuccess()) {
                // Log error but don't fail the request - score was saved successfully
                System.debug(LoggingLevel.ERROR, 'Failed to publish Prometheion_Score_Result__e: ' + publishResult.getErrors());
            }
            
            // Return success response (score was saved, event publish failure is non-critical)
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'success' => true,
                'scoreId' => result.getId()
            }));
            
        } catch (Exception e) {
            // Return error response (sanitized - no stack trace exposed)
            System.debug(LoggingLevel.ERROR, 'PrometheionScoreCallback error: ' + e.getMessage() + ', Stack: ' + e.getStackTraceString());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'success' => false,
                'error' => 'An internal error occurred'
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
            List<Prometheion_API_Config__mdt> configs = [
                SELECT API_Key_Hash__c, Is_Active__c
                FROM Prometheion_API_Config__mdt
                WHERE Is_Active__c = true
                AND DeveloperName = 'Default'
                LIMIT 1
            ];

            if (configs.isEmpty() || String.isBlank(configs[0].API_Key_Hash__c)) {
                System.debug(LoggingLevel.WARN, 'PrometheionScoreCallback: API key hash not configured');
                return false;
            }

            // Hash the input key and compare securely
            String inputHash = generateApiKeyHash(apiKey);
            return configs[0].API_Key_Hash__c.equalsIgnoreCase(inputHash);

        } catch (Exception e) {
            // If Custom Metadata doesn't exist or query fails, deny access
            System.debug(LoggingLevel.ERROR, 'PrometheionScoreCallback: API key validation error: ' + e.getMessage());
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
     * Run in Execute Anonymous: PrometheionScoreCallback.generateHashForKey('your-api-key');
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
}

