/**
 * Unit tests for ElaroEventParser
 * @group Tests
 */
@IsTest
private class ElaroEventParserTest {
    
    // ═══════════════════════════════════════════════════════════════
    // parseLoginEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseLoginEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = ElaroTestDataFactory.createMockLoginEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseLoginEvent(raw);
        Test.stopTest();
        
        Assert.areEqual('Login', parsed.get('eventType'), 'Event type should be Login');
        Assert.areEqual(raw.get('USER_ID'), parsed.get('userId'), 'User ID should be mapped');
        Assert.areEqual(raw.get('SOURCE_IP'), parsed.get('sourceIp'), 'Source IP should be mapped');
        Assert.areEqual(raw.get('LOGIN_STATUS'), parsed.get('loginStatus'), 'Login status should be mapped');
        Assert.areNotEqual(null, parsed.get('geoLocation'), 'Geo location should be built');
    }
    
    @isTest
    static void testParseLoginEvent_GeoLocationBuilt() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'CITY' =&gt; 'San Francisco',
            'SUBDIVISION' =&gt; 'California',
            'COUNTRY' =&gt; 'United States'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseLoginEvent(raw);
        Test.stopTest();
        
        String geoLocation = (String)parsed.get('geoLocation');
        Assert.isTrue(geoLocation.contains('San Francisco'), 'Should contain city');
        Assert.isTrue(geoLocation.contains('California'), 'Should contain state');
        Assert.isTrue(geoLocation.contains('United States'), 'Should contain country');
    }
    
    @isTest
    static void testParseLoginEvent_EmptyInput() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseLoginEvent(raw);
        Test.stopTest();
        
        Assert.areEqual('Login', parsed.get('eventType'), 'Event type should be Login');
        Assert.areEqual('', parsed.get('userId'), 'Empty fields should be empty string');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseLoginAsEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseLoginAsEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = ElaroTestDataFactory.createMockLoginAsEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseLoginAsEvent(raw);
        Test.stopTest();
        
        Assert.areEqual('LoginAs', parsed.get('eventType'), 'Event type should be LoginAs');
        Assert.areEqual(raw.get('DELEGATED_USER_ID'), parsed.get('delegatedUserId'), 
            'Delegated user should be mapped');
        Assert.areEqual(raw.get('USER_ID'), parsed.get('targetUserId'), 
            'Target user should be mapped');
        Assert.areEqual(true, parsed.get('isHighRisk'), 'Should be flagged as high risk');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseReportExportEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseReportExportEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = ElaroTestDataFactory.createMockReportExportEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseReportExportEvent(raw);
        Test.stopTest();
        
        Assert.areEqual('ReportExport', parsed.get('eventType'), 'Event type should be ReportExport');
        Assert.areEqual(raw.get('REPORT_ID'), parsed.get('reportId'), 'Report ID should be mapped');
        Assert.areEqual(raw.get('REPORT_NAME'), parsed.get('reportName'), 'Report name should be mapped');
        Assert.areEqual(raw.get('EXPORT_TYPE'), parsed.get('exportFormat'), 'Export format should be mapped');
    }
    
    @isTest
    static void testParseReportExportEvent_LargeExportFlagged() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'ROWS_PROCESSED' =&gt; '5000'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseReportExportEvent(raw);
        Test.stopTest();
        
        Assert.areEqual(true, parsed.get('isLargeExport'), 'Should be flagged as large export');
        Assert.areEqual(false, parsed.get('isCriticalExport'), 'Should not be critical yet');
    }
    
    @isTest
    static void testParseReportExportEvent_CriticalExportFlagged() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'ROWS_PROCESSED' =&gt; '15000'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseReportExportEvent(raw);
        Test.stopTest();
        
        Assert.areEqual(true, parsed.get('isLargeExport'), 'Should be flagged as large export');
        Assert.areEqual(true, parsed.get('isCriticalExport'), 'Should be flagged as critical');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseApiEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseApiEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = ElaroTestDataFactory.createMockApiEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseApiEvent(raw);
        Test.stopTest();
        
        Assert.areEqual('API', parsed.get('eventType'), 'Event type should be API');
        Assert.areEqual(raw.get('API_TYPE'), parsed.get('apiType'), 'API type should be mapped');
        Assert.areEqual(raw.get('ENTITY_NAME'), parsed.get('entityName'), 'Entity name should be mapped');
    }
    
    @isTest
    static void testParseApiEvent_BulkOperationFlagged() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'ROWS_PROCESSED' =&gt; '500'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseApiEvent(raw);
        Test.stopTest();
        
        Assert.areEqual(true, parsed.get('isBulkOperation'), 'Should be flagged as bulk operation');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseContentDistributionEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseContentDistributionEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = ElaroTestDataFactory.createMockContentDistributionEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseContentDistributionEvent(raw);
        Test.stopTest();
        
        Assert.areEqual('ContentDistribution', parsed.get('eventType'), 
            'Event type should be ContentDistribution');
        Assert.areEqual(raw.get('CONTENT_DOCUMENT_ID'), parsed.get('contentDocumentId'), 
            'Content doc ID should be mapped');
        Assert.areEqual(raw.get('DISTRIBUTION_TYPE'), parsed.get('distributionType'), 
            'Distribution type should be mapped');
    }
    
    @isTest
    static void testParseContentDistributionEvent_UnprotectedPublicFlagged() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'DISTRIBUTION_TYPE' =&gt; 'Public',
            'IS_PASSWORD_PROTECTED' =&gt; 'false'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseContentDistributionEvent(raw);
        Test.stopTest();
        
        Assert.areEqual(true, parsed.get('isUnprotectedPublic'), 
            'Should be flagged as unprotected public');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseApexExecutionEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseApexExecutionEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = ElaroTestDataFactory.createMockApexExecutionEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseApexExecutionEvent(raw);
        Test.stopTest();
        
        Assert.areEqual('ApexExecution', parsed.get('eventType'), 
            'Event type should be ApexExecution');
        Assert.areEqual(raw.get('ENTRY_POINT'), parsed.get('entryPoint'), 
            'Entry point should be mapped');
    }
    
    @isTest
    static void testParseApexExecutionEvent_ResourceIntensiveFlagged() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'CPU_TIME' =&gt; '7000',
            'EXEC_TIME' =&gt; '15000'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseApexExecutionEvent(raw);
        Test.stopTest();
        
        Assert.areEqual(true, parsed.get('isResourceIntensive'), 
            'Should be flagged as resource intensive');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parsePermissionSetEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParsePermissionSetEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = ElaroTestDataFactory.createMockPermissionSetEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parsePermissionSetEvent(raw);
        Test.stopTest();
        
        Assert.areEqual('PermissionSetEventLog', parsed.get('eventType'), 
            'Event type should be PermissionSetEventLog');
        Assert.areEqual(raw.get('PERMISSION_SET_ID'), parsed.get('permissionSetId'), 
            'Permission set ID should be mapped');
        Assert.areEqual(true, parsed.get('isAssignment'), 
            'Should be flagged as assignment');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseEvent Factory Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseEvent_LoginType() {
        Map&lt;String, Object&gt; raw = ElaroTestDataFactory.createMockLoginEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseEvent('Login', raw);
        Test.stopTest();
        
        Assert.areEqual('Login', parsed.get('eventType'), 'Should use Login parser');
        Assert.areNotEqual(null, parsed.get('riskLevel'), 'Should have risk level');
    }
    
    @isTest
    static void testParseEvent_LoginAsType() {
        Map&lt;String, Object&gt; raw = ElaroTestDataFactory.createMockLoginAsEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseEvent('LoginAs', raw);
        Test.stopTest();
        
        Assert.areEqual('LoginAs', parsed.get('eventType'), 'Should use LoginAs parser');
    }
    
    @isTest
    static void testParseEvent_UnknownType_ReturnsRawWithEventType() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'SOME_FIELD' =&gt; 'someValue'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseEvent('UnknownType', raw);
        Test.stopTest();
        
        Assert.areEqual('UnknownType', parsed.get('eventType'), 
            'Should add event type to raw data');
        Assert.areEqual('someValue', parsed.get('SOME_FIELD'), 
            'Should preserve original fields');
    }
    
    @isTest
    static void testParseEvent_AllSupportedTypes() {
        List&lt;String&gt; supportedTypes = new List&lt;String&gt;{
            'Login', 'LoginAs', 'ReportExport', 'API', 
            'ContentDistribution', 'ApexExecution', 'PermissionSetEventLog'
        };
        
        Test.startTest();
        for (String eventType : supportedTypes) {
            Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{'TEST' =&gt; 'value'};
            Map&lt;String, Object&gt; parsed = ElaroEventParser.parseEvent(eventType, raw);
            Assert.areEqual(eventType, parsed.get('eventType'), 
                eventType + ' should be parsed correctly');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testParseEvent_NullInput() {
        Test.startTest();
        Map&lt;String, Object&gt; parsed = ElaroEventParser.parseEvent('Login', null);
        Test.stopTest();
        
        Assert.areEqual('Login', parsed.get('eventType'), 'Should handle null input');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // batchParseEvents Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testBatchParseEvents_MultipleEvents() {
        List&lt;Map&lt;String, Object&gt;&gt; rawEvents = new List&lt;Map&lt;String, Object&gt;&gt;{
            ElaroTestDataFactory.createMockLoginEvent(),
            ElaroTestDataFactory.createMockLoginEvent(),
            ElaroTestDataFactory.createMockLoginEvent()
        };
        
        Test.startTest();
        List&lt;Map&lt;String, Object&gt;&gt; parsedEvents = ElaroEventParser.batchParseEvents(
            'Login', rawEvents);
        Test.stopTest();
        
        Assert.areEqual(3, parsedEvents.size(), 'Should parse all events');
    }
    
    @isTest
    static void testBatchParseEvents_EmptyList() {
        Test.startTest();
        List&lt;Map&lt;String, Object&gt;&gt; parsedEvents = ElaroEventParser.batchParseEvents(
            'Login', new List&lt;Map&lt;String, Object&gt;&gt;());
        Test.stopTest();
        
        Assert.areEqual(0, parsedEvents.size(), 'Should return empty list');
    }
    
    @isTest
    static void testBatchParseEvents_NullList() {
        Test.startTest();
        List&lt;Map&lt;String, Object&gt;&gt; parsedEvents = ElaroEventParser.batchParseEvents(
            'Login', null);
        Test.stopTest();
        
        Assert.areEqual(0, parsedEvents.size(), 'Should return empty list for null');
    }
}
