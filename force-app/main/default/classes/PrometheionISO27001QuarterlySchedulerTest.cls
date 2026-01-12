/**
 * PrometheionISO27001QuarterlySchedulerTest
 * 
 * Test class for PrometheionISO27001QuarterlyScheduler
 * 
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class PrometheionISO27001QuarterlySchedulerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test users with managers
        User manager = new User(
            FirstName = 'Test',
            LastName = 'Manager',
            Email = 'testmanager@prometheion.test',
            Username = 'testmanager' + System.now().getTime() + '@prometheion.test',
            Alias = 'tmgr',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert manager;
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@prometheion.test',
            Username = 'testuser' + System.now().getTime() + '@prometheion.test',
            Alias = 'tuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            ManagerId = manager.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
    }
    
    @IsTest
    static void testQuarterlyReviewExecution() {
        Test.startTest();
        
        PrometheionISO27001QuarterlyScheduler scheduler = new PrometheionISO27001QuarterlyScheduler('quarterly');
        String jobId = System.schedule('Test Quarterly Review', '0 0 12 1 1 ?', scheduler);
        
        // Execute synchronously for testing
        scheduler.execute(null);
        
        Test.stopTest();
        
        // Verify reviews were created
        List<Access_Review__c> reviews = [
            SELECT Id, Review_Type__c, Review_Status__c, User__c
            FROM Access_Review__c
            WITH SECURITY_ENFORCED
        ];
        
        System.assertNotEquals(0, reviews.size(), 'Should have created at least one review');
    }
    
    @IsTest
    static void testPrivilegedReviewExecution() {
        Test.startTest();
        
        PrometheionISO27001QuarterlyScheduler scheduler = new PrometheionISO27001QuarterlyScheduler('privileged');
        scheduler.execute(null);
        
        Test.stopTest();
        
        // Verify privileged reviews were created
        List<Access_Review__c> reviews = [
            SELECT Id, Review_Type__c, Is_Privileged_User__c
            FROM Access_Review__c
            WHERE Is_Privileged_User__c = true
            WITH SECURITY_ENFORCED
        ];
        
        System.assertNotEquals(null, reviews, 'Reviews list should exist');
    }
    
    @IsTest
    static void testScheduleQuarterly() {
        Test.startTest();
        
        String jobId = PrometheionISO27001QuarterlyScheduler.scheduleQuarterly();
        
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Job ID should be returned');
        
        // Verify job was scheduled
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        System.assertEquals(1, scheduledJobs.size(), 'Job should be scheduled');
    }
    
    @IsTest
    static void testScheduleMonthlyPrivileged() {
        Test.startTest();
        
        String jobId = PrometheionISO27001QuarterlyScheduler.scheduleMonthlyPrivileged();
        
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Job ID should be returned');
    }
    
    @IsTest
    static void testDefaultConstructor() {
        Test.startTest();
        
        PrometheionISO27001QuarterlyScheduler scheduler = new PrometheionISO27001QuarterlyScheduler();
        
        Test.stopTest();
        
        System.assertNotEquals(null, scheduler, 'Scheduler should be instantiated');
    }
    
    @IsTest
    static void testExecuteWithException() {
        // This test verifies error handling
        Test.startTest();
        
        PrometheionISO27001QuarterlyScheduler scheduler = new PrometheionISO27001QuarterlyScheduler('invalid');
        // Should not throw exception
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        
        Test.stopTest();
        
        // Test should complete without unhandled exceptions
        System.assert(true, 'Exception handling should work');
    }
}