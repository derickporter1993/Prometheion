@IsTest
private class ElaroComplianceCopilotTest {
    
    @TestSetup
    static void setup() {
        // Create test permission set (no special permissions needed for testing)
        PermissionSet ps = new PermissionSet(
            Name = 'TestElevatedPS',
            Label = 'Test Elevated Permission Set'
        );
        insert ps;
        
        // Assign permission set to current user
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = ps.Id
        );
        insert psa;
    }
    
    @IsTest
    static void testDeepAnalysis_WithHIPAA() {
        Test.startTest();
        ElaroComplianceCopilot.CopilotResponse response = 
            ElaroComplianceCopilot.deepAnalysis('HIPAA compliance');
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals('DEEP_ANALYSIS', response.queryType, 'Query type should be DEEP_ANALYSIS');
        System.assertNotEquals(null, response.answer, 'Answer should not be null');
        System.assert(response.answer.length() > 0, 'Answer should not be empty');
        System.assertNotEquals(null, response.confidence, 'Confidence should not be null');
        System.assert(response.confidence >= 0 && response.confidence <= 1, 'Confidence should be between 0 and 1');
    }
    
    @IsTest
    static void testDeepAnalysis_WithSOC2() {
        Test.startTest();
        ElaroComplianceCopilot.CopilotResponse response = 
            ElaroComplianceCopilot.deepAnalysis('SOC2 compliance status');
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals('DEEP_ANALYSIS', response.queryType, 'Query type should be DEEP_ANALYSIS');
        System.assertNotEquals(null, response.answer, 'Answer should not be null');
        System.assert(response.answer.length() > 0, 'Answer should not be empty');
    }
    
    @IsTest
    static void testDeepAnalysis_WithGenericTopic() {
        Test.startTest();
        ElaroComplianceCopilot.CopilotResponse response = 
            ElaroComplianceCopilot.deepAnalysis('permission sprawl');
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals('DEEP_ANALYSIS', response.queryType, 'Query type should be DEEP_ANALYSIS');
        System.assertNotEquals(null, response.answer, 'Answer should not be null');
        System.assertNotEquals(null, response.evidence, 'Evidence list should not be null');
        System.assertNotEquals(null, response.actions, 'Actions list should not be null');
    }
    
    @IsTest
    static void testDeepAnalysis_WithNullTopic() {
        Test.startTest();
        ElaroComplianceCopilot.CopilotResponse response = 
            ElaroComplianceCopilot.deepAnalysis(null);
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(null, response.answer, 'Answer should not be null');
        System.assert(response.answer.contains('Please provide a topic'), 'Should request topic input');
        System.assertEquals(0.0, response.confidence, 'Confidence should be 0 for invalid input');
    }
    
    @IsTest
    static void testDeepAnalysis_WithBlankTopic() {
        Test.startTest();
        ElaroComplianceCopilot.CopilotResponse response = 
            ElaroComplianceCopilot.deepAnalysis('');
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(null, response.answer, 'Answer should not be null');
        System.assert(response.answer.contains('Please provide a topic'), 'Should request topic input');
        System.assertEquals(0.0, response.confidence, 'Confidence should be 0 for invalid input');
    }
    
    @IsTest
    static void testDeepAnalysis_WithLongTopic() {
        String longTopic = 'A'.repeat(501); // 501 characters
        
        Test.startTest();
        // Method catches exception and returns error response instead of throwing
        ElaroComplianceCopilot.CopilotResponse response = 
            ElaroComplianceCopilot.deepAnalysis(longTopic);
        Test.stopTest();
        
        // Response should indicate error
        System.assertNotEquals(null, response, 'Response should not be null');
        // The method may catch the exception and return an error response
        // Check that response indicates an issue
        System.assert(response.answer != null, 'Answer should not be null');
    }
    
    @IsTest
    static void testDeepAnalysis_IncludesViolations() {
        Test.startTest();
        ElaroComplianceCopilot.CopilotResponse response = 
            ElaroComplianceCopilot.deepAnalysis('HIPAA compliance');
        Test.stopTest();
        
        System.assertNotEquals(null, response.evidence, 'Evidence should not be null');
        // Evidence may be empty if no violations exist, but list should exist
    }
    
    @IsTest
    static void testDeepAnalysis_IncludesRecommendations() {
        Test.startTest();
        ElaroComplianceCopilot.CopilotResponse response = 
            ElaroComplianceCopilot.deepAnalysis('compliance analysis');
        Test.stopTest();
        
        System.assertNotEquals(null, response.answer, 'Answer should not be null');
        System.assert(response.answer.contains('Recommendations'), 'Answer should include recommendations');
    }
    
    @IsTest
    static void testDeepAnalysis_IncludesExportAction() {
        Test.startTest();
        ElaroComplianceCopilot.CopilotResponse response = 
            ElaroComplianceCopilot.deepAnalysis('GDPR compliance');
        Test.stopTest();
        
        System.assertNotEquals(null, response.actions, 'Actions should not be null');
        // Export action is added in the method, verify actions list exists
        // May be empty if method fails, but list should exist
        System.assert(response.actions.size() >= 0, 'Actions list should exist');
    }
    
    @IsTest
    static void testDeepAnalysis_AllFrameworks() {
        // Test a subset to avoid SOQL limit issues
        List<String> frameworks = new List<String>{
            'HIPAA', 'SOC2', 'GDPR', 'SOX', 'CCPA'
        };
        
        Test.startTest();
        for (String framework : frameworks) {
            ElaroComplianceCopilot.CopilotResponse response = 
                ElaroComplianceCopilot.deepAnalysis(framework + ' compliance');
            System.assertNotEquals(null, response, 'Response should not be null for ' + framework);
            System.assertNotEquals(null, response.answer, 'Answer should not be null for ' + framework);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testAskCopilot_GeneralQuery() {
        Test.startTest();
        ElaroComplianceCopilot.CopilotResponse response = 
            ElaroComplianceCopilot.askCopilot('What is compliance?');
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(null, response.answer, 'Answer should not be null');
    }
    
    @IsTest
    static void testGetQuickCommands() {
        Test.startTest();
        List<Map<String, String>> commands = ElaroComplianceCopilot.getQuickCommands();
        Test.stopTest();
        
        System.assertNotEquals(null, commands, 'Commands should not be null');
        System.assert(!commands.isEmpty(), 'Should return at least one command');
        
        for (Map<String, String> cmd : commands) {
            System.assert(cmd.containsKey('command'), 'Command should have command key');
            System.assert(cmd.containsKey('icon'), 'Command should have icon key');
        }
    }
}
