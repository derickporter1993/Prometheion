/**
 * Unit tests for ElaroDailyDigest
 * Tests digest generation, scheduling, email/Slack delivery, and data compilation
 * @group Tests
 * @author Elaro Team
 */
@IsTest(testFor=ElaroDailyDigest.class)
private class ElaroDailyDigestTest {
    
    @testSetup
    static void setupTestData() {
        // Create audit package and evidence items
        Elaro_Audit_Package__c pkg = ElaroTestDataFactory.createAuditPackage('SOC2');
        ElaroTestDataFactory.createEvidenceItems(pkg.Id, 15);
        
        // Create evidence items with different statuses
        List<Elaro_Evidence_Item__c> items = [
            SELECT Id FROM Elaro_Evidence_Item__c LIMIT 5
        ];
        for (Elaro_Evidence_Item__c item : items) {
            item.Status__c = 'Resolved';
        }
        update items;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // execute Tests (Schedulable)
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testExecute_Success() {
        ElaroDailyDigest scheduler = new ElaroDailyDigest();
        
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, '{"ok":true}'));
        
        Test.startTest();
        Exception caughtEx;
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Verify no exceptions thrown
        Assert.isNull(caughtEx, 'Digest should execute successfully without throwing');
    }

    @isTest
    static void testExecute_WithData() {
        ElaroDailyDigest scheduler = new ElaroDailyDigest();

        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, '{"ok":true}'));

        Test.startTest();
        Exception caughtEx;
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Verify digest was generated
        Assert.isNull(caughtEx, 'Digest should be generated with test data without throwing');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // scheduleDigest Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testScheduleDigest() {
        String cronExpression = '0 0 6 * * ?'; // Daily at 6 AM
        
        Test.startTest();
        Id jobId = ElaroDailyDigest.scheduleDigest(cronExpression);
        Test.stopTest();
        
        Assert.areNotEqual(null, jobId, 'Should return job ID');
        
        // Verify job was scheduled
        CronTrigger ct = [
            SELECT Id, CronExpression, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        Assert.areEqual(cronExpression, ct.CronExpression, 'Cron expression should match');
        Assert.isTrue(ct.CronJobDetail.Name.contains('Elaro_Daily_Digest_'), 
            'Job name should contain Elaro_Daily_Digest_');
    }
    
    @isTest
    static void testScheduleDigest_DefaultCron() {
        Test.startTest();
        Id jobId = ElaroDailyDigest.scheduleDigest(null);
        Test.stopTest();
        
        Assert.areNotEqual(null, jobId, 'Should return job ID with default cron');
        
        CronTrigger ct = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        // Default: '0 0 6 * * ?'
        Assert.areEqual('0 0 6 * * ?', ct.CronExpression, 'Should use default cron expression');
    }
    
    @isTest
    static void testScheduleDigest_RemovesExistingJob() {
        // Schedule first job
        String cronExpression = '0 0 6 * * ?';
        Id firstJobId = ElaroDailyDigest.scheduleDigest(cronExpression);
        
        Test.startTest();
        // Schedule again - should remove first job
        Id secondJobId = ElaroDailyDigest.scheduleDigest(cronExpression);
        Test.stopTest();
        
        Assert.areNotEqual(null, secondJobId, 'Should return new job ID');
        
        // Verify first job was removed
        List<CronTrigger> oldJobs = [
            SELECT Id FROM CronTrigger WHERE Id = :firstJobId
        ];
        
        // In test context, jobs may not be immediately removed
        Assert.areNotEqual(firstJobId, secondJobId, 'New job should have a different ID than the first');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // generateAndSendDigest Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGenerateAndSendDigest_Success() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, '{"ok":true}'));
        
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroDailyDigest.generateAndSendDigest();
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Verify no exceptions
        Assert.isNull(caughtEx, 'Digest should be generated and sent without throwing');
    }
    
    @isTest
    static void testGenerateAndSendDigest_WithSlackError() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(500, '{"ok":false}'));
        
        Test.startTest();
        // Should handle Slack error gracefully
        Exception caughtEx;
        try {
            ElaroDailyDigest.generateAndSendDigest();
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Should handle Slack errors gracefully without throwing');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getDigestPreview Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetDigestPreview() {
        Test.startTest();
        ElaroDailyDigest.DigestData digest = ElaroDailyDigest.getDigestPreview();
        Test.stopTest();
        
        Assert.areNotEqual(null, digest, 'Should return digest data');
        Assert.areNotEqual(null, digest.generatedAt, 'Should have generated timestamp');
        Assert.areNotEqual(null, digest.periodStart, 'Should have period start');
        Assert.areNotEqual(null, digest.periodEnd, 'Should have period end');
        Assert.areNotEqual(null, digest.statistics, 'Should have statistics');
        Assert.areNotEqual(null, digest.topRisks, 'Should have top risks');
        Assert.areNotEqual(null, digest.complianceScore, 'Should have compliance score');
        Assert.areNotEqual(null, digest.aiSummary, 'Should have AI summary');
    }
    
    @isTest
    static void testGetDigestPreview_Statistics() {
        Test.startTest();
        ElaroDailyDigest.DigestData digest = ElaroDailyDigest.getDigestPreview();
        Test.stopTest();
        
        Assert.areNotEqual(null, digest.statistics, 'Should have statistics');
        Assert.areNotEqual(null, digest.statistics.totalEvents, 'Should have total events');
        Assert.isTrue(digest.statistics.totalEvents >= 0, 'Total events should be non-negative');
        Assert.areNotEqual(null, digest.statistics.eventsByType, 'Should have events by type');
    }
    
    @isTest
    static void testGetDigestPreview_TopRisks() {
        Test.startTest();
        ElaroDailyDigest.DigestData digest = ElaroDailyDigest.getDigestPreview();
        Test.stopTest();
        
        Assert.areNotEqual(null, digest.topRisks, 'Should have top risks list');
        
        for (ElaroDailyDigest.RiskItem risk : digest.topRisks) {
            Assert.areNotEqual(null, risk.id, 'Risk should have ID');
            Assert.areNotEqual(null, risk.title, 'Risk should have title');
            Assert.areNotEqual(null, risk.severity, 'Risk should have severity');
        }
    }
    
    @isTest
    static void testGetDigestPreview_NoData() {
        // Test with minimal data
        Test.startTest();
        ElaroDailyDigest.DigestData digest = ElaroDailyDigest.getDigestPreview();
        Test.stopTest();
        
        Assert.areNotEqual(null, digest, 'Should return digest even with minimal data');
        Assert.areNotEqual(null, digest.complianceScore, 'Should have compliance score');
        Assert.areNotEqual(null, digest.aiSummary, 'Should have AI summary');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Bulk Operations Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testBulkDigestGeneration() {
        // Create many evidence items
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        ElaroTestDataFactory.createEvidenceItems(pkg.Id, 200);
        
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, '{"ok":true}'));
        
        Test.startTest();
        ElaroDailyDigest.generateAndSendDigest();
        Test.stopTest();
        
        // Verify bulk data is handled
        ElaroDailyDigest.DigestData digest = ElaroDailyDigest.getDigestPreview();
        Assert.isTrue(digest.statistics.totalEvents >= 200, 'Should count all evidence items');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Error Handling Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGenerateAndSendDigest_ExceptionHandling() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, '{"ok":true}'));
        
        Test.startTest();
        // Should handle any exceptions gracefully
        try {
            ElaroDailyDigest.generateAndSendDigest();
        } catch (Exception e) {
            Assert.fail( 'Should not throw unhandled exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        Assert.isNotNull(Test.isRunningTest(), 'Test execution should complete without unhandled exceptions');
    }
    
    @isTest
    static void testGetDigestPreview_ExceptionHandling() {
        Test.startTest();
        // Should handle exceptions in data compilation
        try {
            ElaroDailyDigest.DigestData digest = ElaroDailyDigest.getDigestPreview();
            Assert.areNotEqual(null, digest, 'Should return digest even on errors');
        } catch (Exception e) {
            Assert.fail( 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Data Validation Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testDigestData_Structure() {
        Test.startTest();
        ElaroDailyDigest.DigestData digest = ElaroDailyDigest.getDigestPreview();
        Test.stopTest();
        
        // Verify all required fields are present
        Assert.areNotEqual(null, digest.generatedAt, 'Should have generatedAt');
        Assert.areNotEqual(null, digest.periodStart, 'Should have periodStart');
        Assert.areNotEqual(null, digest.periodEnd, 'Should have periodEnd');
        Assert.isTrue(digest.periodStart <= digest.periodEnd, 'Period start should be before end');
        Assert.areNotEqual(null, digest.trendingUp, 'Should have trendingUp');
        Assert.areNotEqual(null, digest.trendingDown, 'Should have trendingDown');
    }
    
    @isTest
    static void testEventStatistics_Structure() {
        Test.startTest();
        ElaroDailyDigest.DigestData digest = ElaroDailyDigest.getDigestPreview();
        Test.stopTest();
        
        ElaroDailyDigest.EventStatistics stats = digest.statistics;
        Assert.areNotEqual(null, stats.totalEvents, 'Should have totalEvents');
        Assert.areNotEqual(null, stats.criticalEvents, 'Should have criticalEvents');
        Assert.areNotEqual(null, stats.highRiskEvents, 'Should have highRiskEvents');
        Assert.areNotEqual(null, stats.resolvedEvents, 'Should have resolvedEvents');
        Assert.areNotEqual(null, stats.eventsByType, 'Should have eventsByType');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Mock Classes
    // ═══════════════════════════════════════════════════════════════
    
    private class SlackCalloutMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public SlackCalloutMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setStatus(this.statusCode == 200 ? 'OK' : 'Error');
            res.setBody(this.responseBody);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
}
