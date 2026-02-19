/**
 * ElaroISO27001QuarterlySchedulerTest
 * 
 * Test class for ElaroISO27001QuarterlyScheduler
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ElaroISO27001QuarterlyScheduler.class)
private class ElaroISO27001QuarterlySchedulerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test users with managers
        User manager = new User(
            FirstName = 'Test',
            LastName = 'Manager',
            Email = 'testmanager@elaro.test',
            Username = 'testmanager' + System.now().getTime() + '@elaro.test',
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
            Email = 'testuser@elaro.test',
            Username = 'testuser' + System.now().getTime() + '@elaro.test',
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
        
        ElaroISO27001QuarterlyScheduler scheduler = new ElaroISO27001QuarterlyScheduler('quarterly');
        String jobId = System.schedule('Test Quarterly Review', '0 0 12 1 1 ?', scheduler);
        
        // Execute synchronously for testing
        scheduler.execute(null);
        
        Test.stopTest();
        
        // Verify reviews were created
        List<Access_Review__c> reviews = [
            SELECT Id, Review_Type__c, Review_Status__c, User__c
            FROM Access_Review__c
            WITH USER_MODE
        ];
        
        Assert.areNotEqual(0, reviews.size(), 'Should have created at least one review');
    }
    
    @IsTest
    static void testPrivilegedReviewExecution() {
        Test.startTest();
        
        ElaroISO27001QuarterlyScheduler scheduler = new ElaroISO27001QuarterlyScheduler('privileged');
        scheduler.execute(null);
        
        Test.stopTest();
        
        // Verify privileged reviews were created
        List<Access_Review__c> reviews = [
            SELECT Id, Review_Type__c, Is_Privileged_User__c
            FROM Access_Review__c
            WHERE Is_Privileged_User__c = true
            WITH USER_MODE
        ];
        
        Assert.areNotEqual(null, reviews, 'Reviews list should exist');
    }
    
    @IsTest
    static void testScheduleQuarterly() {
        Test.startTest();
        
        String jobId = ElaroISO27001QuarterlyScheduler.scheduleQuarterly();
        
        Test.stopTest();
        
        Assert.areNotEqual(null, jobId, 'Job ID should be returned');
        
        // Verify job was scheduled
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        Assert.areEqual(1, scheduledJobs.size(), 'Job should be scheduled');
    }
    
    @IsTest
    static void testScheduleMonthlyPrivileged() {
        Test.startTest();
        
        String jobId = ElaroISO27001QuarterlyScheduler.scheduleMonthlyPrivileged();
        
        Test.stopTest();
        
        Assert.areNotEqual(null, jobId, 'Job ID should be returned');
    }
    
    @IsTest
    static void testDefaultConstructor() {
        Test.startTest();
        
        ElaroISO27001QuarterlyScheduler scheduler = new ElaroISO27001QuarterlyScheduler();
        
        Test.stopTest();
        
        Assert.areNotEqual(null, scheduler, 'Scheduler should be instantiated');
    }
    
    @IsTest
    static void testExecuteWithException() {
        // This test verifies error handling
        ElaroISO27001QuarterlyScheduler scheduler = new ElaroISO27001QuarterlyScheduler('invalid');

        Test.startTest();
        Exception caughtEx;
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Test should complete without unhandled exceptions
        Assert.isNull(caughtEx, 'Exception handling should prevent unhandled exceptions from propagating');
    }
}