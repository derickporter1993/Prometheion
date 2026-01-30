@isTest
private class ElaroScoreCallbackTest {
    
    @isTest
    static void testHandleScoreCallbackSuccess() {
        // Create test score data
        Map<String, Object> scoreData = new Map<String, Object>{
            'orgId' => UserInfo.getOrganizationId(),
            'entityType' => 'PermissionSet',
            'entityId' => '0PS000000000001',
            'riskScore' => 7.5,
            'frameworkScores' => new Map<String, Object>{
                'HIPAA' => 75.0,
                'SOC2' => 80.0
            },
            'findings' => new List<Object>{
                new Map<String, Object>{'severity' => 'HIGH', 'description' => 'Test finding'}
            },
            's3Key' => 's3://bucket/key.json'
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(JSON.serialize(scoreData));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ElaroScoreCallback.handleScoreCallback();
        Test.stopTest();
        
        // Verify response
        System.assertEquals(200, res.statusCode, 'Should return 200 on success');
        
        Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(true, responseBody.get('success'), 'Response should indicate success');
        System.assertNotEquals(null, responseBody.get('scoreId'), 'Should return score ID');
        
        // Verify Compliance_Score__c was created/updated
        List<Compliance_Score__c> scores = [
            SELECT Id, Risk_Score__c, Org_ID__c 
            FROM Compliance_Score__c 
            WHERE Org_ID__c = :UserInfo.getOrganizationId()
        ];
        
        System.assertEquals(1, scores.size(), 'Score record should be created');
        System.assertEquals(7.5, scores[0].Risk_Score__c, 'Risk score should match');
    }
    
    @isTest
    static void testHandleScoreCallbackError() {
        // Create invalid request (missing required fields)
        Map<String, Object> invalidData = new Map<String, Object>{
            'orgId' => UserInfo.getOrganizationId()
            // Missing required fields
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(JSON.serialize(invalidData));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ElaroScoreCallback.handleScoreCallback();
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(500, res.statusCode, 'Should return 500 on error');
        
        Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(false, responseBody.get('success'), 'Response should indicate failure');
        System.assertNotEquals(null, responseBody.get('error'), 'Should return error message');
    }
    
    @isTest
    static void testHandleScoreCallbackMalformedJSON() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('invalid json');
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ElaroScoreCallback.handleScoreCallback();
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(500, res.statusCode, 'Should return 500 on malformed JSON');
    }
}

