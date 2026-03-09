/**
 * Unit tests for NaturalLanguageQueryService
 * @group Tests
 */
@IsTest
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
        
        Assert.areNotEqual(null, result, 'Should return result');
        Assert.areNotEqual(null, result.generatedSOQL, 'Should have generated SOQL');
        Assert.areNotEqual(null, result.results, 'Should have results list');
        Assert.isTrue(result.confidence &gt;= 0, 'Should have confidence score');
    }
    
    @isTest
    static void testExecuteNaturalLanguageQuery_BlankQuery_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new NLQueryMock());
        
        Test.startTest();
        try {
            NaturalLanguageQueryService.executeNaturalLanguageQuery('');
            Assert.fail( 'Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('required'), 'Should mention required');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExecuteNaturalLanguageQuery_NullQuery_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new NLQueryMock());
        
        Test.startTest();
        try {
            NaturalLanguageQueryService.executeNaturalLanguageQuery(null);
            Assert.fail( 'Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('required'), 'Should mention required');
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
        
        Assert.areNotEqual(null, result.results, 'Should return results');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getQuerySuggestions Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetQuerySuggestions_EmptyInput_ReturnsExamples() {
        Test.startTest();
        List&lt;String&gt; suggestions = NaturalLanguageQueryService.getQuerySuggestions('');
        Test.stopTest();
        
        Assert.isTrue(!suggestions.isEmpty(), 'Should return example suggestions');
    }
    
    @isTest
    static void testGetQuerySuggestions_NullInput_ReturnsExamples() {
        Test.startTest();
        List&lt;String&gt; suggestions = NaturalLanguageQueryService.getQuerySuggestions(null);
        Test.stopTest();
        
        Assert.isTrue(!suggestions.isEmpty(), 'Should return example suggestions for null');
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
        Assert.isTrue(hasAdminSuggestion, 'Should include admin-related suggestions');
    }
    
    @isTest
    static void testGetQuerySuggestions_ExportKeyword() {
        Test.startTest();
        List&lt;String&gt; suggestions = NaturalLanguageQueryService.getQuerySuggestions('export');
        Test.stopTest();
        
        Assert.isTrue(!suggestions.isEmpty(), 'Should return export-related suggestions');
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
        
        Assert.areNotEqual(null, result, 'Should return result');
        Assert.areEqual(true, result.isValid, 'Should be valid');
        Assert.areNotEqual(null, result.generatedSOQL, 'Should have generated SOQL');
    }
    
    @isTest
    static void testValidateQuery_EmptyQuery() {
        Test.setMock(HttpCalloutMock.class, new NLQueryMock());
        
        Test.startTest();
        NaturalLanguageQueryService.ValidationResult result = 
            NaturalLanguageQueryService.validateQuery('');
        Test.stopTest();
        
        Assert.areEqual(false, result.isValid, 'Should be invalid');
        Assert.isTrue(result.message.contains('empty'), 'Should mention empty');
    }
    
    @isTest
    static void testValidateQuery_NullQuery() {
        Test.setMock(HttpCalloutMock.class, new NLQueryMock());
        
        Test.startTest();
        NaturalLanguageQueryService.ValidationResult result = 
            NaturalLanguageQueryService.validateQuery(null);
        Test.stopTest();
        
        Assert.areEqual(false, result.isValid, 'Should be invalid');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getRecentQueries Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetRecentQueries_ReturnsEmptyList() {
        Test.startTest();
        List&lt;String&gt; queries = NaturalLanguageQueryService.getRecentQueries();
        Test.stopTest();
        
        Assert.areNotEqual(null, queries, 'Should return a list');
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
