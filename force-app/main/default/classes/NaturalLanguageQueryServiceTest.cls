/**
 * @description Unit tests for NaturalLanguageQueryService
 * @group Tests
 */
@isTest
private class NaturalLanguageQueryServiceTest {
    
    @testSetup
    static void setupTestData() {
        Elaro_Audit_Package__c pkg = ElaroTestDataFactory.createAuditPackage('HIPAA');
        ElaroTestDataFactory.createEvidenceItems(pkg.Id, 5);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // executeNaturalLanguageQuery Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testExecuteNaturalLanguageQuery_ReturnsResults() {
        Test.setMock(HttpCalloutMock.class, new NLQueryMock());
        
        Test.startTest();
        NaturalLanguageQueryService.QueryResult result = 
            NaturalLanguageQueryService.executeNaturalLanguageQuery('Show all audit packages');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return result');
        System.assertNotEquals(null, result.generatedSOQL, 'Should have generated SOQL');
        System.assertNotEquals(null, result.results, 'Should have results list');
        System.assert(result.confidence &gt;= 0, 'Should have confidence score');
    }
    
    @isTest
    static void testExecuteNaturalLanguageQuery_BlankQuery_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new NLQueryMock());
        
        Test.startTest();
        try {
            NaturalLanguageQueryService.executeNaturalLanguageQuery('');
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention required');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExecuteNaturalLanguageQuery_NullQuery_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new NLQueryMock());
        
        Test.startTest();
        try {
            NaturalLanguageQueryService.executeNaturalLanguageQuery(null);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention required');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExecuteNaturalLanguageQuery_EvidenceQuery() {
        Test.setMock(HttpCalloutMock.class, new NLQueryMock());
        
        Test.startTest();
        NaturalLanguageQueryService.QueryResult result = 
            NaturalLanguageQueryService.executeNaturalLanguageQuery('Show me all evidence items');
        Test.stopTest();
        
        System.assertNotEquals(null, result.results, 'Should return results');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getQuerySuggestions Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetQuerySuggestions_EmptyInput_ReturnsExamples() {
        Test.startTest();
        List&lt;String&gt; suggestions = NaturalLanguageQueryService.getQuerySuggestions('');
        Test.stopTest();
        
        System.assert(!suggestions.isEmpty(), 'Should return example suggestions');
    }
    
    @isTest
    static void testGetQuerySuggestions_NullInput_ReturnsExamples() {
        Test.startTest();
        List&lt;String&gt; suggestions = NaturalLanguageQueryService.getQuerySuggestions(null);
        Test.stopTest();
        
        System.assert(!suggestions.isEmpty(), 'Should return example suggestions for null');
    }
    
    @isTest
    static void testGetQuerySuggestions_PartialMatch() {
        Test.startTest();
        List&lt;String&gt; suggestions = NaturalLanguageQueryService.getQuerySuggestions('admin');
        Test.stopTest();
        
        // Should return suggestions containing 'admin'
        Boolean hasAdminSuggestion = false;
        for (String s : suggestions) {
            if (s.toLowerCase().contains('admin')) {
                hasAdminSuggestion = true;
                break;
            }
        }
        System.assert(hasAdminSuggestion, 'Should include admin-related suggestions');
    }
    
    @isTest
    static void testGetQuerySuggestions_ExportKeyword() {
        Test.startTest();
        List&lt;String&gt; suggestions = NaturalLanguageQueryService.getQuerySuggestions('export');
        Test.stopTest();
        
        System.assert(!suggestions.isEmpty(), 'Should return export-related suggestions');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // validateQuery Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testValidateQuery_ValidQuery() {
        Test.setMock(HttpCalloutMock.class, new NLQueryMock());
        
        Test.startTest();
        NaturalLanguageQueryService.ValidationResult result = 
            NaturalLanguageQueryService.validateQuery('Show audit packages');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return result');
        System.assertEquals(true, result.isValid, 'Should be valid');
        System.assertNotEquals(null, result.generatedSOQL, 'Should have generated SOQL');
    }
    
    @isTest
    static void testValidateQuery_EmptyQuery() {
        Test.setMock(HttpCalloutMock.class, new NLQueryMock());
        
        Test.startTest();
        NaturalLanguageQueryService.ValidationResult result = 
            NaturalLanguageQueryService.validateQuery('');
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Should be invalid');
        System.assert(result.message.contains('empty'), 'Should mention empty');
    }
    
    @isTest
    static void testValidateQuery_NullQuery() {
        Test.setMock(HttpCalloutMock.class, new NLQueryMock());
        
        Test.startTest();
        NaturalLanguageQueryService.ValidationResult result = 
            NaturalLanguageQueryService.validateQuery(null);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Should be invalid');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getRecentQueries Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetRecentQueries_ReturnsEmptyList() {
        Test.startTest();
        List&lt;String&gt; queries = NaturalLanguageQueryService.getRecentQueries();
        Test.stopTest();
        
        System.assertNotEquals(null, queries, 'Should return a list');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Mock Classes
    // ═══════════════════════════════════════════════════════════════
    
    private class NLQueryMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            Map&lt;String, Object&gt; response = new Map&lt;String, Object&gt;{
                'content' =&gt; new List&lt;Map&lt;String, Object&gt;&gt;{
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'text',
                        'text' =&gt; 'SELECT Id, Name FROM Elaro_Audit_Package__c LIMIT 100'
                    }
                }
            };
            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(response));
            return res;
        }
    }
}
