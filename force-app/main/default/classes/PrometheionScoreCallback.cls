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
            // Return error response
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'success' => false,
                'error' => e.getMessage(),
                'stackTrace' => e.getStackTraceString()
            }));
        }
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

