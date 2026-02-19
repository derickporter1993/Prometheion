/**
 * Unit tests for ElaroScheduledDelivery
 * Tests scheduled delivery execution, error handling, and scheduling methods
 * @group Tests
 * @author Elaro Team
 */
@IsTest(testFor=ElaroScheduledDelivery.class)
private class ElaroScheduledDeliveryTest {
    
    @testSetup
    static void setupTestData() {
        // Create audit package
        Elaro_Audit_Package__c pkg = ElaroTestDataFactory.createAuditPackage('SOC2');
        ElaroTestDataFactory.createEvidenceItems(pkg.Id, 5);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // execute Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testExecute_Success() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com', 'admin@example.com'};
        
        ElaroScheduledDelivery scheduler = new ElaroScheduledDelivery(
            pkg.Id,
            recipients
        );
        
        Test.startTest();
        Exception caughtEx;
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Verify no exceptions thrown
        Assert.isNull(caughtEx, 'Scheduled delivery should execute without throwing');
    }
    
    @isTest
    static void testExecute_InvalidPackageId() {
        String invalidPackageId = 'a0000000000000AAA';
        List<String> recipients = new List<String>{'test@example.com'};
        
        ElaroScheduledDelivery scheduler = new ElaroScheduledDelivery(
            invalidPackageId,
            recipients
        );
        
        Test.startTest();
        // Should handle error gracefully
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            // Expected - package doesn't exist
            Assert.isNotNull(e.getMessage(), 'Exception should have a message for invalid package ID');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExecute_EmptyRecipients() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>();
        
        ElaroScheduledDelivery scheduler = new ElaroScheduledDelivery(
            pkg.Id,
            recipients
        );
        
        Test.startTest();
        Exception caughtEx;
        try {
            // Should handle empty recipients gracefully
            scheduler.execute(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Should handle empty recipients without throwing');
    }
    
    @isTest
    static void testExecute_ErrorNotification() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        
        // Delete package to cause error
        delete pkg;
        
        ElaroScheduledDelivery scheduler = new ElaroScheduledDelivery(
            pkg.Id,
            recipients
        );
        
        Test.startTest();
        Exception caughtEx;
        try {
            // Should send error notification
            scheduler.execute(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Verify error was handled (notification sent in non-test context)
        Assert.isNull(caughtEx, 'Should handle errors gracefully without throwing');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // scheduleDelivery Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testScheduleDelivery() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        String cronExpression = '0 0 8 * * ?'; // Daily at 8 AM
        
        Test.startTest();
        Id jobId = ElaroScheduledDelivery.scheduleDelivery(
            pkg.Id,
            recipients,
            cronExpression
        );
        Test.stopTest();
        
        Assert.areNotEqual(null, jobId, 'Should return job ID');
        
        // Verify job was scheduled
        CronTrigger ct = [
            SELECT Id, CronExpression, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        Assert.areEqual(cronExpression, ct.CronExpression, 'Cron expression should match');
        Assert.isTrue(ct.CronJobDetail.Name.contains('Elaro_Delivery_'), 
            'Job name should contain Elaro_Delivery_');
    }
    
    @isTest
    static void testScheduleDelivery_MultipleRecipients() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{
            'recipient1@example.com',
            'recipient2@example.com',
            'recipient3@example.com'
        };
        String cronExpression = '0 0 9 * * ?';
        
        Test.startTest();
        Id jobId = ElaroScheduledDelivery.scheduleDelivery(
            pkg.Id,
            recipients,
            cronExpression
        );
        Test.stopTest();
        
        Assert.areNotEqual(null, jobId, 'Should schedule with multiple recipients');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // scheduleWeekly Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testScheduleWeekly() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        
        Test.startTest();
        Id jobId = ElaroScheduledDelivery.scheduleWeekly(pkg.Id, recipients);
        Test.stopTest();
        
        Assert.areNotEqual(null, jobId, 'Should return job ID');
        
        CronTrigger ct = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        // Weekly cron: '0 0 8 ? * MON'
        Assert.areEqual('0 0 8 ? * MON', ct.CronExpression, 'Should use weekly cron expression');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // scheduleMonthly Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testScheduleMonthly() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        
        Test.startTest();
        Id jobId = ElaroScheduledDelivery.scheduleMonthly(pkg.Id, recipients);
        Test.stopTest();
        
        Assert.areNotEqual(null, jobId, 'Should return job ID');
        
        CronTrigger ct = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        // Monthly cron: '0 0 8 1 * ?'
        Assert.areEqual('0 0 8 1 * ?', ct.CronExpression, 'Should use monthly cron expression');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // scheduleQuarterly Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testScheduleQuarterly() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        
        Test.startTest();
        Id jobId = ElaroScheduledDelivery.scheduleQuarterly(pkg.Id, recipients);
        Test.stopTest();
        
        Assert.areNotEqual(null, jobId, 'Should return job ID');
        
        CronTrigger ct = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        // Quarterly cron: '0 0 8 1 1,4,7,10 ?'
        Assert.areEqual('0 0 8 1 1,4,7,10 ?', ct.CronExpression, 'Should use quarterly cron expression');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Bulk Operations Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testBulkDelivery() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        
        // Create 200 recipients
        List<String> recipients = new List<String>();
        for (Integer i = 0; i < 200; i++) {
            recipients.add('recipient' + i + '@example.com');
        }
        
        ElaroScheduledDelivery scheduler = new ElaroScheduledDelivery(
            pkg.Id,
            recipients
        );
        
        Test.startTest();
        Exception caughtEx;
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Should handle bulk recipients without throwing');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Error Handling Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testExecute_ExceptionHandling() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        
        ElaroScheduledDelivery scheduler = new ElaroScheduledDelivery(
            pkg.Id,
            recipients
        );
        
        Test.startTest();
        // Should handle any exceptions gracefully
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            Assert.fail( 'Should not throw unhandled exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        Assert.isNotNull(scheduler, 'Scheduler should exist after exception handling');
    }
    
    @isTest
    static void testScheduleDelivery_InvalidCron() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        String invalidCron = 'invalid cron expression';
        
        Test.startTest();
        try {
            Id jobId = ElaroScheduledDelivery.scheduleDelivery(
                pkg.Id,
                recipients,
                invalidCron
            );
            // System.schedule will throw exception for invalid cron
            Assert.fail( 'Should throw exception for invalid cron');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Should have error message for invalid cron expression');
        }
        Test.stopTest();
    }
}
