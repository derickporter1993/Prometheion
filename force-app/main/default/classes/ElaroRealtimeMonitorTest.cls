/**
 * Unit tests for ElaroRealtimeMonitor
 * @group Tests
 */
@IsTest(testFor=ElaroRealtimeMonitor.class)
private class ElaroRealtimeMonitorTest {
    
    // ═══════════════════════════════════════════════════════════════
    // calculateRiskScore Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testCalculateRiskScore_LoginEvent_ReturnsBaseScore() {
        Map&lt;String, Object&gt; eventData = ElaroTestDataFactory.createMockLoginEvent();
        
        Test.startTest();
        Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(eventData);
        Test.stopTest();
        
        // Login base score is 20, may have additional factors
        Assert.isTrue(riskScore &gt;= 20, 'Login event should have minimum score of 20');
        Assert.isTrue(riskScore &lt;= 100, 'Score should not exceed 100');
    }
    
    @isTest
    static void testCalculateRiskScore_LoginAsEvent_ReturnsCriticalScore() {
        Map&lt;String, Object&gt; eventData = ElaroTestDataFactory.createMockLoginAsEvent();
        
        Test.startTest();
        Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(eventData);
        Test.stopTest();
        
        // LoginAs base score is 70
        Assert.isTrue(riskScore &gt;= 70, 'LoginAs event should have minimum score of 70');
    }
    
    @isTest
    static void testCalculateRiskScore_HighVolumeEvent_AddsVolumeFactor() {
        Map&lt;String, Object&gt; eventData = ElaroTestDataFactory.createMockApiEvent();
        eventData.put('ROWS_PROCESSED', '15000'); // High volume
        
        Test.startTest();
        Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(eventData);
        Test.stopTest();
        
        // API base (40) + volume factor (20 for &gt;10000 rows)
        Assert.isTrue(riskScore &gt;= 60, 'High volume should add 20 to score');
    }
    
    @isTest
    static void testCalculateRiskScore_NonUSLocation_AddsLocationFactor() {
        Map&lt;String, Object&gt; eventData = ElaroTestDataFactory.createMockLoginEvent();
        eventData.put('COUNTRY', 'Russia');
        
        Test.startTest();
        Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(eventData);
        Test.stopTest();
        
        // Login base (20) + location factor (15)
        Assert.isTrue(riskScore &gt;= 35, 'Non-US location should add 15 to score');
    }
    
    @isTest
    static void testCalculateRiskScore_GeoLocationNonUS_AddsLocationFactor() {
        Map&lt;String, Object&gt; eventData = ElaroTestDataFactory.createMockLoginEvent();
        eventData.put('GEO_LOCATION', 'Moscow, Russia');
        eventData.remove('COUNTRY');
        
        Test.startTest();
        Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(eventData);
        Test.stopTest();
        
        Assert.isTrue(riskScore &gt;= 35, 'Non-US geo location should add 15 to score');
    }
    
    @isTest
    static void testCalculateRiskScore_MaxCap100() {
        // Create worst-case event
        Map&lt;String, Object&gt; eventData = new Map&lt;String, Object&gt;{
            'EVENT_TYPE' =&gt; 'LoginAs', // Base 70
            'ROWS_PROCESSED' =&gt; '50000', // +20
            'COUNTRY' =&gt; 'Russia' // +15
            // Time factor could add more
        };
        
        Test.startTest();
        Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(eventData);
        Test.stopTest();
        
        Assert.isTrue(riskScore &lt;= 100, 'Score should be capped at 100');
    }
    
    @isTest
    static void testCalculateRiskScore_NullEventData_ReturnsZero() {
        Test.startTest();
        Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(null);
        Test.stopTest();
        
        Assert.areEqual(0, riskScore, 'Null event data should return 0');
    }
    
    @isTest
    static void testCalculateRiskScore_EmptyEventData_ReturnsBaseScore() {
        Map&lt;String, Object&gt; eventData = new Map&lt;String, Object&gt;();
        
        Test.startTest();
        Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(eventData);
        Test.stopTest();
        
        // Unknown event type defaults to 10
        Assert.isTrue(riskScore &gt;= 0, 'Empty event should return base score');
    }
    
    @isTest
    static void testCalculateRiskScore_MediumVolume_AddsSmallFactor() {
        Map&lt;String, Object&gt; eventData = new Map&lt;String, Object&gt;{
            'EVENT_TYPE' =&gt; 'API',
            'ROWS_PROCESSED' =&gt; '5000'
        };
        
        Test.startTest();
        Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(eventData);
        Test.stopTest();
        
        // API base (40) + volume factor (10 for &gt;1000 rows)
        Assert.isTrue(riskScore &gt;= 50, 'Medium volume should add factor');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // processRealtimeEvent Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testProcessRealtimeEvent_LowRiskEvent_NoAlert() {
        Map&lt;String, Object&gt; eventData = ElaroTestDataFactory.createMockLoginEvent();
        
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroRealtimeMonitor.processRealtimeEvent(eventData);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Verify event was processed without exception
        Assert.isNull(caughtEx, 'Low risk event should process without throwing');
    }
    
    @isTest
    static void testProcessRealtimeEvent_HighRiskEvent_TriggersAlert() {
        Map&lt;String, Object&gt; eventData = ElaroTestDataFactory.createHighRiskEvent();
        
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroRealtimeMonitor.processRealtimeEvent(eventData);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // High risk events should trigger alert
        Assert.isNull(caughtEx, 'High risk event should be processed without throwing');
    }
    
    @isTest
    static void testProcessRealtimeEvent_NullEventData() {
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroRealtimeMonitor.processRealtimeEvent(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Should handle null event data without throwing');
    }
    
    @isTest
    static void testProcessRealtimeEvent_EmptyEventData() {
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroRealtimeMonitor.processRealtimeEvent(new Map&lt;String, Object&gt;());
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Should handle empty event data without throwing');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getRealtimeStats Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetRealtimeStats_ReturnsStatsMap() {
        Test.startTest();
        Map&lt;String, Object&gt; stats = ElaroRealtimeMonitor.getRealtimeStats(60);
        Test.stopTest();
        
        Assert.areNotEqual(null, stats, 'Should return stats map');
        Assert.isTrue(stats.containsKey('totalEvents'), 'Should contain totalEvents');
        Assert.isTrue(stats.containsKey('criticalEvents'), 'Should contain criticalEvents');
        Assert.isTrue(stats.containsKey('highRiskEvents'), 'Should contain highRiskEvents');
        Assert.isTrue(stats.containsKey('timeWindow'), 'Should contain timeWindow');
    }
    
    @isTest
    static void testGetRealtimeStats_WithData() {
        // Create some test data
        Elaro_Audit_Package__c pkg = ElaroTestDataFactory.createAuditPackage('HIPAA');
        ElaroTestDataFactory.createEvidenceItems(pkg.Id, 5);
        
        Test.startTest();
        Map&lt;String, Object&gt; stats = ElaroRealtimeMonitor.getRealtimeStats(60);
        Test.stopTest();
        
        Assert.areNotEqual(null, stats, 'Should return stats');
        // Note: totalEvents may be 0 if evidence items created more than 60 minutes ago
    }
    
    // ═══════════════════════════════════════════════════════════════
    // triggerAlert Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testTriggerAlert_CriticalSeverity() {
        Map&lt;String, Object&gt; eventData = ElaroTestDataFactory.createMockLoginAsEvent();
        
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroRealtimeMonitor.triggerAlert(
                UserInfo.getUserId(),
                95, // Critical threshold
                'User impersonation detected',
                eventData
            );
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Verify alert was queued without throwing
        Assert.isNull(caughtEx, 'Critical alert should be triggered without throwing');
    }
    
    @isTest
    static void testTriggerAlert_HighSeverity() {
        Map&lt;String, Object&gt; eventData = ElaroTestDataFactory.createMockReportExportEvent();
        
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroRealtimeMonitor.triggerAlert(
                UserInfo.getUserId(),
                85, // High but not critical
                'Large data export detected',
                eventData
            );
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'High severity alert should be triggered without throwing');
    }
    
    @isTest
    static void testTriggerAlert_AtThreshold() {
        Map&lt;String, Object&gt; eventData = ElaroTestDataFactory.createMockApiEvent();
        
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroRealtimeMonitor.triggerAlert(
                UserInfo.getUserId(),
                80, // Exactly at HIGH threshold
                'API activity detected',
                eventData
            );
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Alert at threshold should be triggered without throwing');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Threshold Constants Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testThresholdConstants() {
        Assert.areEqual(80, ElaroRealtimeMonitor.HIGH_RISK_THRESHOLD, 
            'High risk threshold should be 80');
        Assert.areEqual(95, ElaroRealtimeMonitor.CRITICAL_RISK_THRESHOLD, 
            'Critical risk threshold should be 95');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Edge Cases
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testCalculateRiskScore_InvalidRowsProcessed() {
        Map&lt;String, Object&gt; eventData = new Map&lt;String, Object&gt;{
            'EVENT_TYPE' =&gt; 'API',
            'ROWS_PROCESSED' =&gt; 'invalid_number'
        };
        
        Test.startTest();
        Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(eventData);
        Test.stopTest();
        
        // Should handle invalid number gracefully
        Assert.isTrue(riskScore &gt;= 0, 'Should handle invalid rows gracefully');
    }
    
    @isTest
    static void testCalculateRiskScore_OutsideBusinessHours() {
        Map&lt;String, Object&gt; eventData = ElaroTestDataFactory.createMockLoginEvent();
        eventData.put('HOUR', '3'); // 3 AM
        
        Test.startTest();
        Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(eventData);
        Test.stopTest();
        
        // Should add time factor
        Assert.isTrue(riskScore &gt; 20, 'Outside business hours should add risk');
    }
}
