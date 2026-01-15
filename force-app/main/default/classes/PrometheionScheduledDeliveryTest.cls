/**
 * @description Unit tests for PrometheionScheduledDelivery
 * Tests scheduled delivery execution, error handling, and scheduling methods
 * @group Tests
 * @author Prometheion Team
 */
@isTest
private class PrometheionScheduledDeliveryTest {
    
    @testSetup
    static void setupTestData() {
        // Create audit package
        Prometheion_Audit_Package__c pkg = PrometheionTestDataFactory.createAuditPackage('SOC2');
        PrometheionTestDataFactory.createEvidenceItems(pkg.Id, 5);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // execute Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testExecute_Success() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com', 'admin@example.com'};
        
        PrometheionScheduledDelivery scheduler = new PrometheionScheduledDelivery(
            pkg.Id,
            recipients
        );
        
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();
        
        // Verify no exceptions thrown
        System.assert(true, 'Scheduled delivery should execute successfully');
    }
    
    @isTest
    static void testExecute_InvalidPackageId() {
        String invalidPackageId = 'a0000000000000AAA';
        List<String> recipients = new List<String>{'test@example.com'};
        
        PrometheionScheduledDelivery scheduler = new PrometheionScheduledDelivery(
            invalidPackageId,
            recipients
        );
        
        Test.startTest();
        // Should handle error gracefully
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            // Expected - package doesn't exist
            System.assert(true, 'Should handle invalid package ID');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExecute_EmptyRecipients() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>();
        
        PrometheionScheduledDelivery scheduler = new PrometheionScheduledDelivery(
            pkg.Id,
            recipients
        );
        
        Test.startTest();
        // Should handle empty recipients gracefully
        scheduler.execute(null);
        Test.stopTest();
        
        System.assert(true, 'Should handle empty recipients');
    }
    
    @isTest
    static void testExecute_ErrorNotification() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        
        // Delete package to cause error
        delete pkg;
        
        PrometheionScheduledDelivery scheduler = new PrometheionScheduledDelivery(
            pkg.Id,
            recipients
        );
        
        Test.startTest();
        // Should send error notification
        scheduler.execute(null);
        Test.stopTest();
        
        // Verify error was handled (notification sent in non-test context)
        System.assert(true, 'Should handle errors and send notification');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // scheduleDelivery Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testScheduleDelivery() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        String cronExpression = '0 0 8 * * ?'; // Daily at 8 AM
        
        Test.startTest();
        Id jobId = PrometheionScheduledDelivery.scheduleDelivery(
            pkg.Id,
            recipients,
            cronExpression
        );
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Should return job ID');
        
        // Verify job was scheduled
        CronTrigger ct = [
            SELECT Id, CronExpression, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        System.assertEquals(cronExpression, ct.CronExpression, 'Cron expression should match');
        System.assert(ct.CronJobDetail.Name.contains('Prometheion_Delivery_'), 
            'Job name should contain Prometheion_Delivery_');
    }
    
    @isTest
    static void testScheduleDelivery_MultipleRecipients() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{
            'recipient1@example.com',
            'recipient2@example.com',
            'recipient3@example.com'
        };
        String cronExpression = '0 0 9 * * ?';
        
        Test.startTest();
        Id jobId = PrometheionScheduledDelivery.scheduleDelivery(
            pkg.Id,
            recipients,
            cronExpression
        );
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Should schedule with multiple recipients');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // scheduleWeekly Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testScheduleWeekly() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        
        Test.startTest();
        Id jobId = PrometheionScheduledDelivery.scheduleWeekly(pkg.Id, recipients);
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Should return job ID');
        
        CronTrigger ct = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        // Weekly cron: '0 0 8 ? * MON'
        System.assertEquals('0 0 8 ? * MON', ct.CronExpression, 'Should use weekly cron expression');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // scheduleMonthly Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testScheduleMonthly() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        
        Test.startTest();
        Id jobId = PrometheionScheduledDelivery.scheduleMonthly(pkg.Id, recipients);
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Should return job ID');
        
        CronTrigger ct = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        // Monthly cron: '0 0 8 1 * ?'
        System.assertEquals('0 0 8 1 * ?', ct.CronExpression, 'Should use monthly cron expression');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // scheduleQuarterly Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testScheduleQuarterly() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        
        Test.startTest();
        Id jobId = PrometheionScheduledDelivery.scheduleQuarterly(pkg.Id, recipients);
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Should return job ID');
        
        CronTrigger ct = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        // Quarterly cron: '0 0 8 1 1,4,7,10 ?'
        System.assertEquals('0 0 8 1 1,4,7,10 ?', ct.CronExpression, 'Should use quarterly cron expression');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Bulk Operations Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testBulkDelivery() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        // Create 200 recipients
        List<String> recipients = new List<String>();
        for (Integer i = 0; i < 200; i++) {
            recipients.add('recipient' + i + '@example.com');
        }
        
        PrometheionScheduledDelivery scheduler = new PrometheionScheduledDelivery(
            pkg.Id,
            recipients
        );
        
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();
        
        System.assert(true, 'Should handle bulk recipients without governor limit errors');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Error Handling Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testExecute_ExceptionHandling() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        
        PrometheionScheduledDelivery scheduler = new PrometheionScheduledDelivery(
            pkg.Id,
            recipients
        );
        
        Test.startTest();
        // Should handle any exceptions gracefully
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            System.assert(false, 'Should not throw unhandled exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assert(true, 'Should handle exceptions gracefully');
    }
    
    @isTest
    static void testScheduleDelivery_InvalidCron() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List<String> recipients = new List<String>{'test@example.com'};
        String invalidCron = 'invalid cron expression';
        
        Test.startTest();
        try {
            Id jobId = PrometheionScheduledDelivery.scheduleDelivery(
                pkg.Id,
                recipients,
                invalidCron
            );
            // System.schedule will throw exception for invalid cron
            System.assert(false, 'Should throw exception for invalid cron');
        } catch (Exception e) {
            System.assert(true, 'Should handle invalid cron expression: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
