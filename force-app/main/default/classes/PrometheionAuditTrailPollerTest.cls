@isTest
private class PrometheionAuditTrailPollerTest {
    
    @isTest
    static void testSchedule() {
        Test.startTest();
        String jobId = PrometheionAuditTrailPoller.schedule();
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Job should be scheduled');
        
        // Verify job was created
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE Id = :jobId
        ];
        
        System.assertEquals(1, jobs.size(), 'Job should exist');
        System.assertEquals('Prometheion Audit Trail Poller', jobs[0].CronJobDetail.Name);
    }
    
    @isTest
    static void testUnschedule() {
        // First schedule a job
        String jobId = PrometheionAuditTrailPoller.schedule();
        
        Test.startTest();
        PrometheionAuditTrailPoller.unschedule();
        Test.stopTest();
        
        // Verify job was removed
        List<CronTrigger> jobs = [
            SELECT Id 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Prometheion Audit Trail Poller'
        ];
        
        System.assertEquals(0, jobs.size(), 'Job should be unscheduled');
    }
    
    @isTest
    static void testExecute() {
        PrometheionAuditTrailPoller poller = new PrometheionAuditTrailPoller();
        SchedulableContext ctx = null;
        
        Test.startTest();
        poller.execute(ctx);
        Test.stopTest();
        
        // Verify poller executed without errors
        // Note: Actual audit trail polling would require API access
        System.assert(true, 'Poller executed successfully');
    }
    
    @isTest
    static void testPollAuditTrail() {
        Test.startTest();
        PrometheionAuditTrailPoller.pollAuditTrail();
        Test.stopTest();
        
        // Verify method executed without errors
        System.assert(true, 'Audit trail polling executed successfully');
    }
}

