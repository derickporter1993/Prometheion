/**
 * Unit tests for ElaroShieldService
 * @group Tests
 */
@IsTest(testFor=ElaroShieldService.class)
private class ElaroShieldServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create framework mappings for testing
        ElaroTestDataFactory.createFrameworkMappings('HIPAA');
        ElaroTestDataFactory.createFrameworkMappings('SOC2');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getAvailableEventTypes Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetAvailableEventTypes_ReturnsListOrEmpty() {
        Test.startTest();
        List&lt;String&gt; eventTypes = ElaroShieldService.getAvailableEventTypes();
        Test.stopTest();
        
        // Should return a list (may be empty if no Shield license)
        Assert.areNotEqual(null, eventTypes, 'Should return a list');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getShieldStatus Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetShieldStatus_ReturnsStatusMap() {
        Test.startTest();
        Map&lt;String, Object&gt; status = ElaroShieldService.getShieldStatus();
        Test.stopTest();
        
        Assert.areNotEqual(null, status, 'Should return status map');
        Assert.isTrue(status.containsKey('shieldEnabled'), 'Should contain shieldEnabled key');
        Assert.isTrue(status.containsKey('platformEncryption'), 'Should contain platformEncryption key');
        Assert.isTrue(status.containsKey('eventMonitoring'), 'Should contain eventMonitoring key');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getRiskLevel Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetRiskLevel_LoginAs_ReturnsCritical() {
        Test.startTest();
        String riskLevel = ElaroShieldService.getRiskLevel('LoginAs');
        Test.stopTest();
        
        Assert.areEqual('CRITICAL', riskLevel, 'LoginAs should be CRITICAL');
    }
    
    @isTest
    static void testGetRiskLevel_ReportExport_ReturnsCritical() {
        Test.startTest();
        String riskLevel = ElaroShieldService.getRiskLevel('ReportExport');
        Test.stopTest();
        
        Assert.areEqual('CRITICAL', riskLevel, 'ReportExport should be CRITICAL');
    }
    
    @isTest
    static void testGetRiskLevel_ContentDistribution_ReturnsCritical() {
        Test.startTest();
        String riskLevel = ElaroShieldService.getRiskLevel('ContentDistribution');
        Test.stopTest();
        
        Assert.areEqual('CRITICAL', riskLevel, 'ContentDistribution should be CRITICAL');
    }
    
    @isTest
    static void testGetRiskLevel_API_ReturnsHigh() {
        Test.startTest();
        String riskLevel = ElaroShieldService.getRiskLevel('API');
        Test.stopTest();
        
        Assert.areEqual('HIGH', riskLevel, 'API should be HIGH');
    }
    
    @isTest
    static void testGetRiskLevel_Login_ReturnsMedium() {
        Test.startTest();
        String riskLevel = ElaroShieldService.getRiskLevel('Login');
        Test.stopTest();
        
        Assert.areEqual('MEDIUM', riskLevel, 'Login should be MEDIUM');
    }
    
    @isTest
    static void testGetRiskLevel_Logout_ReturnsLow() {
        Test.startTest();
        String riskLevel = ElaroShieldService.getRiskLevel('Logout');
        Test.stopTest();
        
        Assert.areEqual('LOW', riskLevel, 'Logout should be LOW');
    }
    
    @isTest
    static void testGetRiskLevel_UnknownType_ReturnsLow() {
        Test.startTest();
        String riskLevel = ElaroShieldService.getRiskLevel('UnknownEventType');
        Test.stopTest();
        
        Assert.areEqual('LOW', riskLevel, 'Unknown event type should default to LOW');
    }
    
    @isTest
    static void testGetRiskLevel_AllSupportedTypes() {
        Map&lt;String, String&gt; expectedLevels = new Map&lt;String, String&gt;{
            'LoginAs' =&gt; 'CRITICAL',
            'ReportExport' =&gt; 'CRITICAL',
            'ContentDistribution' =&gt; 'CRITICAL',
            'BulkApiResult' =&gt; 'HIGH',
            'API' =&gt; 'HIGH',
            'Login' =&gt; 'MEDIUM',
            'Report' =&gt; 'MEDIUM',
            'ApexExecution' =&gt; 'MEDIUM',
            'Logout' =&gt; 'LOW'
        };
        
        Test.startTest();
        for (String eventType : expectedLevels.keySet()) {
            String actualLevel = ElaroShieldService.getRiskLevel(eventType);
            Assert.areEqual(
                expectedLevels.get(eventType),
                actualLevel,
                eventType + ' should have correct risk level'
            );
        }
        Test.stopTest();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getEventRiskLevels Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetEventRiskLevels_ReturnsMap() {
        Test.startTest();
        Map&lt;String, String&gt; riskLevels = ElaroShieldService.getEventRiskLevels();
        Test.stopTest();
        
        Assert.areNotEqual(null, riskLevels, 'Should return risk levels map');
        Assert.isTrue(!riskLevels.isEmpty(), 'Map should not be empty');
        Assert.isTrue(riskLevels.containsKey('Login'), 'Should contain Login');
        Assert.isTrue(riskLevels.containsKey('LoginAs'), 'Should contain LoginAs');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getEventLogFiles Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetEventLogFiles_InvalidEventType_ThrowsException() {
        Test.startTest();
        try {
            ElaroShieldService.getEventLogFiles(
                'InvalidType',
                Date.today().addDays(-7),
                Date.today()
            );
            Assert.fail( 'Should have thrown exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Invalid event type'), 
                'Should mention invalid event type');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetEventLogFiles_NullDates_ThrowsException() {
        Test.startTest();
        try {
            ElaroShieldService.getEventLogFiles('Login', null, null);
            Assert.fail( 'Should have thrown exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('required'), 
                'Should mention required dates');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetEventLogFiles_InvalidDateRange_ThrowsException() {
        Test.startTest();
        try {
            ElaroShieldService.getEventLogFiles(
                'Login',
                Date.today(),
                Date.today().addDays(-7) // End before start
            );
            Assert.fail( 'Should have thrown exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('before'), 
                'Should mention date order');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetEventLogFiles_ValidEventType_ReturnsResults() {
        // Note: In orgs without Shield, this returns empty list
        Test.startTest();
        List&lt;EventLogFile&gt; results = ElaroShieldService.getEventLogFiles(
            'Login',
            Date.today().addDays(-7),
            Date.today()
        );
        Test.stopTest();
        
        Assert.areNotEqual(null, results, 'Should return a list');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // parseEventLogContent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testParseEventLogContent_NullId_ThrowsException() {
        Test.startTest();
        try {
            ElaroShieldService.parseEventLogContent(null);
            Assert.fail( 'Should have thrown exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('required'), 
                'Should mention required ID');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testParseEventLogContent_BlankId_ThrowsException() {
        Test.startTest();
        try {
            ElaroShieldService.parseEventLogContent('');
            Assert.fail( 'Should have thrown exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('required'), 
                'Should mention required ID');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testParseEventLogContent_InvalidId_ThrowsException() {
        Test.startTest();
        try {
            ElaroShieldService.parseEventLogContent('invalid_id');
            Assert.fail( 'Should have thrown exception');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Exception should have a message for invalid ID');
        }
        Test.stopTest();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // processHistoricalEvents Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testProcessHistoricalEvents_InvalidType_ThrowsException() {
        Test.startTest();
        try {
            ElaroShieldService.processHistoricalEvents(
                'InvalidType',
                Date.today().addDays(-30),
                Date.today()
            );
            Assert.fail( 'Should have thrown exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Invalid event type'), 
                'Should mention invalid event type');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testProcessHistoricalEvents_ValidType_ReturnsBatchId() {
        Test.startTest();
        Id batchId = ElaroShieldService.processHistoricalEvents(
            'Login',
            Date.today().addDays(-30),
            Date.today()
        );
        Test.stopTest();
        
        Assert.areNotEqual(null, batchId, 'Should return batch job ID');
        
        // Verify batch completed
        AsyncApexJob job = [
            SELECT Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :batchId
        ];
        Assert.areEqual('Completed', job.Status, 'Batch should complete');
    }
}
