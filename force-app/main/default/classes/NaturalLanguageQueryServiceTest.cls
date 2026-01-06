/**
 * NaturalLanguageQueryServiceTest
 * 
 * Test class for NaturalLanguageQueryService
 * 
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class NaturalLanguageQueryServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test gaps for SOX
        List<Compliance_Gap__c> gaps = ComplianceTestDataFactory.createComplianceGaps('SOX', 3);
        insert gaps;
    }
    
    @IsTest
    static void testProcessQuery_SOXCompliance() {
        Test.startTest();
        NaturalLanguageQueryService.QueryResult result = 
            NaturalLanguageQueryService.processQuery('Am I SOX compliant?');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.answer, 'Answer should not be null');
        System.assertEquals('SOX', result.framework, 'Framework should be SOX');
        System.assertNotEquals(null, result.score, 'Score should not be null');
    }
    
    @IsTest
    static void testProcessQuery_SOC2Compliance() {
        Test.startTest();
        NaturalLanguageQueryService.QueryResult result = 
            NaturalLanguageQueryService.processQuery('Am I SOC2 compliant?');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.answer, 'Answer should not be null');
    }
    
    @IsTest
    static void testProcessQuery_UnknownFramework() {
        Test.startTest();
        NaturalLanguageQueryService.QueryResult result = 
            NaturalLanguageQueryService.processQuery('Am I XYZ compliant?');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.answer, 'Answer should not be null');
        System.assertEquals('UNKNOWN', result.status, 'Status should be UNKNOWN');
    }
    
    @IsTest
    static void testProcessQuery_BlankQuery() {
        Test.startTest();
        try {
            NaturalLanguageQueryService.processQuery('');
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for blank query');
        }
        Test.stopTest();
    }
}
