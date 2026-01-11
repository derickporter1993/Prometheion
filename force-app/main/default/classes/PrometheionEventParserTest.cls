/**
 * @description Unit tests for PrometheionEventParser
 * @group Tests
 */
@isTest
private class PrometheionEventParserTest {
    
    // ═══════════════════════════════════════════════════════════════
    // parseLoginEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseLoginEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = PrometheionTestDataFactory.createMockLoginEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseLoginEvent(raw);
        Test.stopTest();
        
        System.assertEquals('Login', parsed.get('eventType'), 'Event type should be Login');
        System.assertEquals(raw.get('USER_ID'), parsed.get('userId'), 'User ID should be mapped');
        System.assertEquals(raw.get('SOURCE_IP'), parsed.get('sourceIp'), 'Source IP should be mapped');
        System.assertEquals(raw.get('LOGIN_STATUS'), parsed.get('loginStatus'), 'Login status should be mapped');
        System.assertNotEquals(null, parsed.get('geoLocation'), 'Geo location should be built');
    }
    
    @isTest
    static void testParseLoginEvent_GeoLocationBuilt() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'CITY' =&gt; 'San Francisco',
            'SUBDIVISION' =&gt; 'California',
            'COUNTRY' =&gt; 'United States'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseLoginEvent(raw);
        Test.stopTest();
        
        String geoLocation = (String)parsed.get('geoLocation');
        System.assert(geoLocation.contains('San Francisco'), 'Should contain city');
        System.assert(geoLocation.contains('California'), 'Should contain state');
        System.assert(geoLocation.contains('United States'), 'Should contain country');
    }
    
    @isTest
    static void testParseLoginEvent_EmptyInput() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseLoginEvent(raw);
        Test.stopTest();
        
        System.assertEquals('Login', parsed.get('eventType'), 'Event type should be Login');
        System.assertEquals('', parsed.get('userId'), 'Empty fields should be empty string');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseLoginAsEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseLoginAsEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = PrometheionTestDataFactory.createMockLoginAsEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseLoginAsEvent(raw);
        Test.stopTest();
        
        System.assertEquals('LoginAs', parsed.get('eventType'), 'Event type should be LoginAs');
        System.assertEquals(raw.get('DELEGATED_USER_ID'), parsed.get('delegatedUserId'), 
            'Delegated user should be mapped');
        System.assertEquals(raw.get('USER_ID'), parsed.get('targetUserId'), 
            'Target user should be mapped');
        System.assertEquals(true, parsed.get('isHighRisk'), 'Should be flagged as high risk');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseReportExportEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseReportExportEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = PrometheionTestDataFactory.createMockReportExportEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseReportExportEvent(raw);
        Test.stopTest();
        
        System.assertEquals('ReportExport', parsed.get('eventType'), 'Event type should be ReportExport');
        System.assertEquals(raw.get('REPORT_ID'), parsed.get('reportId'), 'Report ID should be mapped');
        System.assertEquals(raw.get('REPORT_NAME'), parsed.get('reportName'), 'Report name should be mapped');
        System.assertEquals(raw.get('EXPORT_TYPE'), parsed.get('exportFormat'), 'Export format should be mapped');
    }
    
    @isTest
    static void testParseReportExportEvent_LargeExportFlagged() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'ROWS_PROCESSED' =&gt; '5000'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseReportExportEvent(raw);
        Test.stopTest();
        
        System.assertEquals(true, parsed.get('isLargeExport'), 'Should be flagged as large export');
        System.assertEquals(false, parsed.get('isCriticalExport'), 'Should not be critical yet');
    }
    
    @isTest
    static void testParseReportExportEvent_CriticalExportFlagged() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'ROWS_PROCESSED' =&gt; '15000'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseReportExportEvent(raw);
        Test.stopTest();
        
        System.assertEquals(true, parsed.get('isLargeExport'), 'Should be flagged as large export');
        System.assertEquals(true, parsed.get('isCriticalExport'), 'Should be flagged as critical');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseApiEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseApiEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = PrometheionTestDataFactory.createMockApiEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseApiEvent(raw);
        Test.stopTest();
        
        System.assertEquals('API', parsed.get('eventType'), 'Event type should be API');
        System.assertEquals(raw.get('API_TYPE'), parsed.get('apiType'), 'API type should be mapped');
        System.assertEquals(raw.get('ENTITY_NAME'), parsed.get('entityName'), 'Entity name should be mapped');
    }
    
    @isTest
    static void testParseApiEvent_BulkOperationFlagged() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'ROWS_PROCESSED' =&gt; '500'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseApiEvent(raw);
        Test.stopTest();
        
        System.assertEquals(true, parsed.get('isBulkOperation'), 'Should be flagged as bulk operation');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseContentDistributionEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseContentDistributionEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = PrometheionTestDataFactory.createMockContentDistributionEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseContentDistributionEvent(raw);
        Test.stopTest();
        
        System.assertEquals('ContentDistribution', parsed.get('eventType'), 
            'Event type should be ContentDistribution');
        System.assertEquals(raw.get('CONTENT_DOCUMENT_ID'), parsed.get('contentDocumentId'), 
            'Content doc ID should be mapped');
        System.assertEquals(raw.get('DISTRIBUTION_TYPE'), parsed.get('distributionType'), 
            'Distribution type should be mapped');
    }
    
    @isTest
    static void testParseContentDistributionEvent_UnprotectedPublicFlagged() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'DISTRIBUTION_TYPE' =&gt; 'Public',
            'IS_PASSWORD_PROTECTED' =&gt; 'false'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseContentDistributionEvent(raw);
        Test.stopTest();
        
        System.assertEquals(true, parsed.get('isUnprotectedPublic'), 
            'Should be flagged as unprotected public');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseApexExecutionEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseApexExecutionEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = PrometheionTestDataFactory.createMockApexExecutionEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseApexExecutionEvent(raw);
        Test.stopTest();
        
        System.assertEquals('ApexExecution', parsed.get('eventType'), 
            'Event type should be ApexExecution');
        System.assertEquals(raw.get('ENTRY_POINT'), parsed.get('entryPoint'), 
            'Entry point should be mapped');
    }
    
    @isTest
    static void testParseApexExecutionEvent_ResourceIntensiveFlagged() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'CPU_TIME' =&gt; '7000',
            'EXEC_TIME' =&gt; '15000'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseApexExecutionEvent(raw);
        Test.stopTest();
        
        System.assertEquals(true, parsed.get('isResourceIntensive'), 
            'Should be flagged as resource intensive');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parsePermissionSetEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParsePermissionSetEvent_AllFieldsMapped() {
        Map&lt;String, Object&gt; raw = PrometheionTestDataFactory.createMockPermissionSetEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parsePermissionSetEvent(raw);
        Test.stopTest();
        
        System.assertEquals('PermissionSetEventLog', parsed.get('eventType'), 
            'Event type should be PermissionSetEventLog');
        System.assertEquals(raw.get('PERMISSION_SET_ID'), parsed.get('permissionSetId'), 
            'Permission set ID should be mapped');
        System.assertEquals(true, parsed.get('isAssignment'), 
            'Should be flagged as assignment');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseEvent Factory Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseEvent_LoginType() {
        Map&lt;String, Object&gt; raw = PrometheionTestDataFactory.createMockLoginEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseEvent('Login', raw);
        Test.stopTest();
        
        System.assertEquals('Login', parsed.get('eventType'), 'Should use Login parser');
        System.assertNotEquals(null, parsed.get('riskLevel'), 'Should have risk level');
    }
    
    @isTest
    static void testParseEvent_LoginAsType() {
        Map&lt;String, Object&gt; raw = PrometheionTestDataFactory.createMockLoginAsEvent();
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseEvent('LoginAs', raw);
        Test.stopTest();
        
        System.assertEquals('LoginAs', parsed.get('eventType'), 'Should use LoginAs parser');
    }
    
    @isTest
    static void testParseEvent_UnknownType_ReturnsRawWithEventType() {
        Map&lt;String, Object&gt; raw = new Map&lt;String, Object&gt;{
            'SOME_FIELD' =&gt; 'someValue'
        };
        
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseEvent('UnknownType', raw);
        Test.stopTest();
        
        System.assertEquals('UnknownType', parsed.get('eventType'), 
            'Should add event type to raw data');
        System.assertEquals('someValue', parsed.get('SOME_FIELD'), 
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
            Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseEvent(eventType, raw);
            System.assertEquals(eventType, parsed.get('eventType'), 
                eventType + ' should be parsed correctly');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testParseEvent_NullInput() {
        Test.startTest();
        Map&lt;String, Object&gt; parsed = PrometheionEventParser.parseEvent('Login', null);
        Test.stopTest();
        
        System.assertEquals('Login', parsed.get('eventType'), 'Should handle null input');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // batchParseEvents Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testBatchParseEvents_MultipleEvents() {
        List&lt;Map&lt;String, Object&gt;&gt; rawEvents = new List&lt;Map&lt;String, Object&gt;&gt;{
            PrometheionTestDataFactory.createMockLoginEvent(),
            PrometheionTestDataFactory.createMockLoginEvent(),
            PrometheionTestDataFactory.createMockLoginEvent()
        };
        
        Test.startTest();
        List&lt;Map&lt;String, Object&gt;&gt; parsedEvents = PrometheionEventParser.batchParseEvents(
            'Login', rawEvents);
        Test.stopTest();
        
        System.assertEquals(3, parsedEvents.size(), 'Should parse all events');
    }
    
    @isTest
    static void testBatchParseEvents_EmptyList() {
        Test.startTest();
        List&lt;Map&lt;String, Object&gt;&gt; parsedEvents = PrometheionEventParser.batchParseEvents(
            'Login', new List&lt;Map&lt;String, Object&gt;&gt;());
        Test.stopTest();
        
        System.assertEquals(0, parsedEvents.size(), 'Should return empty list');
    }
    
    @isTest
    static void testBatchParseEvents_NullList() {
        Test.startTest();
        List&lt;Map&lt;String, Object&gt;&gt; parsedEvents = PrometheionEventParser.batchParseEvents(
            'Login', null);
        Test.stopTest();
        
        System.assertEquals(0, parsedEvents.size(), 'Should return empty list for null');
    }
}
