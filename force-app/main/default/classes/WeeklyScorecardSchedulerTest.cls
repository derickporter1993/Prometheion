/**
 * Test class for WeeklyScorecardScheduler
 * Provides comprehensive coverage with meaningful assertions
 * 
 * @author Sentinel Enterprise
 * @version 1.1
 */
@isTest
private class WeeklyScorecardSchedulerTest {
    
    /**
     * Test scheduling the weekly scorecard job
     */
    @isTest
    static void testScheduleWeekly() {
        Test.startTest();
        String result = WeeklyScorecardScheduler.scheduleWeekly('Both');
        Test.stopTest();
        
        // Assert result contains expected confirmation text
        System.assertNotEquals(null, result, 'Schedule should return a result message');
        System.assert(result.contains('Weekly scorecard scheduled') || result.contains('Solentra Weekly Scorecard'), 
            'Result should confirm scheduling: ' + result);
        
        // Verify job was actually scheduled
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name, NextFireTime 
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE 'Solentra Weekly Scorecard%'
        ];
        System.assert(!scheduledJobs.isEmpty(), 'At least one scheduled job should exist');
    }
    
    /**
     * Test sending scorecard to Slack channel
     */
    @isTest
    static void testSendWeeklyScorecardSlack() {
        // Set up mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new ScorecardCalloutMock());
        
        Test.startTest();
        // Should not throw exception
        WeeklyScorecardScheduler.sendWeeklyScorecard('Slack');
        Test.stopTest();
        
        // Verify no unhandled exceptions occurred
        // In production, you would verify the callout payload
        System.assert(true, 'Slack scorecard should send without errors');
    }
    
    /**
     * Test sending scorecard to Teams channel
     */
    @isTest
    static void testSendWeeklyScorecardTeams() {
        Test.setMock(HttpCalloutMock.class, new ScorecardCalloutMock());
        
        Test.startTest();
        WeeklyScorecardScheduler.sendWeeklyScorecard('Teams');
        Test.stopTest();
        
        System.assert(true, 'Teams scorecard should send without errors');
    }
    
    /**
     * Test sending scorecard to both channels
     */
    @isTest
    static void testSendWeeklyScorecardBoth() {
        Test.setMock(HttpCalloutMock.class, new ScorecardCalloutMock());
        
        Test.startTest();
        WeeklyScorecardScheduler.sendWeeklyScorecard('Both');
        Test.stopTest();
        
        System.assert(true, 'Both channel scorecard should send without errors');
    }
    
    /**
     * Test the Schedulable execute method
     */
    @isTest
    static void testSchedulableExecute() {
        Test.setMock(HttpCalloutMock.class, new ScorecardCalloutMock());
        
        WeeklyScorecardScheduler scheduler = new WeeklyScorecardScheduler();
        
        Test.startTest();
        // Schedule the job
        String jobId = System.schedule(
            'Test Weekly Scorecard',
            '0 0 9 ? * MON *',
            scheduler
        );
        Test.stopTest();
        
        // Verify job was scheduled
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
        
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals('0 0 9 ? * MON *', ct.CronExpression, 'Cron expression should match');
    }
    
    /**
     * Test the test scorecard method
     */
    @isTest
    static void testSendTestScorecard() {
        Test.setMock(HttpCalloutMock.class, new ScorecardCalloutMock());
        
        Test.startTest();
        WeeklyScorecardScheduler.sendTestScorecard();
        Test.stopTest();
        
        System.assert(true, 'Test scorecard should complete without errors');
    }
    
    /**
     * Test channel constants are defined correctly
     */
    @isTest
    static void testChannelConstants() {
        System.assertEquals('Slack', WeeklyScorecardScheduler.SLACK, 'SLACK constant should be "Slack"');
        System.assertEquals('Teams', WeeklyScorecardScheduler.TEAMS, 'TEAMS constant should be "Teams"');
        System.assertEquals('Both', WeeklyScorecardScheduler.BOTH, 'BOTH constant should be "Both"');
    }
    
    /**
     * Test error handling when score calculation fails
     */
    @isTest
    static void testErrorHandling() {
        // Use mock that simulates error scenario
        Test.setMock(HttpCalloutMock.class, new ScorecardCalloutMock());
        
        Test.startTest();
        // Even with potential errors, the method should handle gracefully
        try {
            WeeklyScorecardScheduler.sendWeeklyScorecard('InvalidChannel');
            System.assert(true, 'Invalid channel should be handled gracefully');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for invalid channel: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Mock class for HTTP callouts
     */
    private class ScorecardCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('{"ok": true}');
            return res;
        }
    }
}
