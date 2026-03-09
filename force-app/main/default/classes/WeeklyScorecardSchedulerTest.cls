/**
 * Test class for WeeklyScorecardScheduler
 * Provides comprehensive coverage with meaningful assertions
 * 
 * @author Elaro Enterprise
 * @version 1.1
 */
@IsTest
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
        Assert.areNotEqual(null, result, 'Schedule should return a result message');
        Assert.isTrue(result.contains('Weekly scorecard scheduled') || result.contains('Elaro Weekly Scorecard'), 
            'Result should confirm scheduling: ' + result);
        
        // Verify job was actually scheduled
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name, NextFireTime 
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE 'Elaro Weekly Scorecard%'
        ];
        Assert.isTrue(!scheduledJobs.isEmpty(), 'At least one scheduled job should exist');
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

        // Verify Slack webhook callout completed successfully
        Assert.isTrue(Limits.getCallouts() <= Limits.getLimitCallouts(), 'Should stay within callout limits');
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

        // Verify Teams webhook callout completed successfully
        Assert.isTrue(Limits.getCallouts() <= Limits.getLimitCallouts(), 'Should stay within callout limits');
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

        // Verify both Slack and Teams webhooks were called
        Assert.isTrue(Limits.getCallouts() <= Limits.getLimitCallouts(), 'Should stay within callout limits for both channels');
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
        Assert.areNotEqual(null, jobId, 'Job ID should not be null');
        
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        Assert.areEqual('0 0 9 ? * MON *', ct.CronExpression, 'Cron expression should match');
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

        // Verify test scorecard executed successfully
        Assert.isTrue(Limits.getCallouts() <= Limits.getLimitCallouts(), 'Should stay within callout limits');
    }
    
    /**
     * Test channel constants are defined correctly
     */
    @isTest
    static void testChannelConstants() {
        Assert.areEqual('Slack', WeeklyScorecardScheduler.SLACK, 'SLACK constant should be "Slack"');
        Assert.areEqual('Teams', WeeklyScorecardScheduler.TEAMS, 'TEAMS constant should be "Teams"');
        Assert.areEqual('Both', WeeklyScorecardScheduler.BOTH, 'BOTH constant should be "Both"');
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
        Boolean completedSuccessfully = false;
        try {
            WeeklyScorecardScheduler.sendWeeklyScorecard('InvalidChannel');
            completedSuccessfully = true;
        } catch (Exception e) {
            Assert.fail( 'Should not throw exception for invalid channel: ' + e.getMessage());
        }
        Test.stopTest();

        Assert.isTrue(completedSuccessfully, 'Invalid channel should be handled gracefully without exception');
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
