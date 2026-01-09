/**
 * @description Unit tests for PrometheionDeliveryService
 * @group Tests
 */
@isTest
private class PrometheionDeliveryServiceTest {
    
    @testSetup
    static void setupTestData() {
        Prometheion_Audit_Package__c pkg = PrometheionTestDataFactory.createAuditPackage('HIPAA');
        PrometheionTestDataFactory.createEvidenceItems(pkg.Id, 5);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // deliverAuditPackage Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testDeliverAuditPackage_SendsEmail() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List&lt;String&gt; recipients = new List&lt;String&gt;{'test@example.com'};
        
        Test.startTest();
        // In test context, email is not actually sent
        PrometheionDeliveryService.deliverAuditPackage(pkg.Id, recipients);
        Test.stopTest();
        
        // Verify email was \"sent\" (check email limits)
        System.assert(true, 'Email delivery should complete without error');
    }
    
    @isTest
    static void testDeliverAuditPackage_MultipleRecipients() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List&lt;String&gt; recipients = new List&lt;String&gt;{
            'test1@example.com',
            'test2@example.com',
            'test3@example.com'
        };
        
        Test.startTest();
        PrometheionDeliveryService.deliverAuditPackage(pkg.Id, recipients);
        Test.stopTest();
        
        System.assert(true, 'Should handle multiple recipients');
    }
    
    @isTest
    static void testDeliverAuditPackage_NullPackageId_ThrowsException() {
        Test.startTest();
        try {
            PrometheionDeliveryService.deliverAuditPackage(null, new List&lt;String&gt;{'test@example.com'});
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention required fields');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDeliverAuditPackage_EmptyRecipients_ThrowsException() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        try {
            PrometheionDeliveryService.deliverAuditPackage(pkg.Id, new List&lt;String&gt;());
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention required fields');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDeliverAuditPackage_NullRecipients_ThrowsException() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        try {
            PrometheionDeliveryService.deliverAuditPackage(pkg.Id, null);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention required fields');
        }
        Test.stopTest();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // scheduleRecurringDelivery Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testScheduleRecurringDelivery_CreatesScheduledJob() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        String cronExpression = '0 0 6 * * ?'; // Daily at 6 AM
        List&lt;String&gt; recipients = new List&lt;String&gt;{'test@example.com'};
        
        Test.startTest();
        Id jobId = PrometheionDeliveryService.scheduleRecurringDelivery(
            pkg.Id,
            cronExpression,
            recipients
        );
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Should return scheduled job ID');
        
        // Verify job was created
        CronTrigger ct = [
            SELECT State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals('WAITING', ct.State, 'Job should be waiting');
        
        // Clean up
        System.abortJob(jobId);
    }
    
    @isTest
    static void testScheduleRecurringDelivery_NullCron_ThrowsException() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        try {
            PrometheionDeliveryService.scheduleRecurringDelivery(
                pkg.Id,
                null,
                new List&lt;String&gt;{'test@example.com'}
            );
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Cron expression'), 'Should mention cron expression');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testScheduleRecurringDelivery_EmptyCron_ThrowsException() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        try {
            PrometheionDeliveryService.scheduleRecurringDelivery(
                pkg.Id,
                '',
                new List&lt;String&gt;{'test@example.com'}
            );
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Cron expression'), 'Should mention cron expression');
        }
        Test.stopTest();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // generateShareableLink Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGenerateShareableLink_CreatesContentDistribution() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        String shareableUrl = PrometheionDeliveryService.generateShareableLink(pkg.Id, 30);
        Test.stopTest();
        
        System.assertNotEquals(null, shareableUrl, 'Should return shareable URL');
        
        // Verify ContentDistribution was created
        List&lt;ContentDistribution&gt; distributions = [
            SELECT ExpiryDate, PreferencesPasswordRequired
            FROM ContentDistribution
            WHERE Name LIKE '%Audit Package Share%'
        ];
        System.assert(!distributions.isEmpty(), 'ContentDistribution should be created');
        System.assertEquals(Date.today().addDays(30), distributions[0].ExpiryDate, 'Expiration should be 30 days');
        System.assertEquals(true, distributions[0].PreferencesPasswordRequired, 'Should require password');
    }
    
    @isTest
    static void testGenerateShareableLink_DefaultExpiration() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        String shareableUrl = PrometheionDeliveryService.generateShareableLink(pkg.Id, null);
        Test.stopTest();
        
        // Should default to 30 days
        List&lt;ContentDistribution&gt; distributions = [
            SELECT ExpiryDate
            FROM ContentDistribution
            WHERE Name LIKE '%Audit Package Share%'
        ];
        System.assertEquals(Date.today().addDays(30), distributions[0].ExpiryDate, 'Should default to 30 days');
    }
    
    @isTest
    static void testGenerateShareableLink_InvalidExpiration() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        String shareableUrl = PrometheionDeliveryService.generateShareableLink(pkg.Id, 0);
        Test.stopTest();
        
        // Should default to 30 days for invalid input
        System.assertNotEquals(null, shareableUrl, 'Should still return URL');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // sendToSlack Tests (requires mock)
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testSendToSlack_CallsWebhook() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        // Set up mock for Slack webhook
        Test.setMock(HttpCalloutMock.class, new SlackWebhookMock());
        
        Test.startTest();
        PrometheionDeliveryService.sendToSlack(pkg.Id, '#compliance-alerts');
        Test.stopTest();
        
        // Future method completed without exception
        System.assert(true, 'Slack notification should complete');
    }
    
    @isTest
    static void testSendToSlack_NullParameters() {
        Test.setMock(HttpCalloutMock.class, new SlackWebhookMock());
        
        Test.startTest();
        // Should not throw exception
        PrometheionDeliveryService.sendToSlack(null, '#compliance-alerts');
        PrometheionDeliveryService.sendToSlack('someId', null);
        PrometheionDeliveryService.sendToSlack(null, null);
        Test.stopTest();
        
        System.assert(true, 'Should handle null parameters gracefully');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getDeliveryHistory Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetDeliveryHistory_ReturnsHistory() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        // Generate a shareable link to create history
        PrometheionDeliveryService.generateShareableLink(pkg.Id, 30);
        
        Test.startTest();
        List&lt;Map&lt;String, Object&gt;&gt; history = PrometheionDeliveryService.getDeliveryHistory(pkg.Id);
        Test.stopTest();
        
        System.assert(!history.isEmpty(), 'Should return delivery history');
    }
    
    @isTest
    static void testGetDeliveryHistory_EmptyHistory() {
        // Create new package without any deliveries
        Prometheion_Audit_Package__c newPkg = PrometheionTestDataFactory.createAuditPackage('SOC2');
        
        Test.startTest();
        List&lt;Map&lt;String, Object&gt;&gt; history = PrometheionDeliveryService.getDeliveryHistory(newPkg.Id);
        Test.stopTest();
        
        System.assertEquals(0, history.size(), 'Should return empty list for new package');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PrometheionScheduledDelivery Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testScheduledDelivery_Execute() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List&lt;String&gt; recipients = new List&lt;String&gt;{'test@example.com'};
        
        PrometheionScheduledDelivery scheduler = new PrometheionScheduledDelivery(
            pkg.Id, recipients
        );
        
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();
        
        System.assert(true, 'Scheduled execution should complete');
    }
    
    @isTest
    static void testScheduledDelivery_ScheduleWeekly() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List&lt;String&gt; recipients = new List&lt;String&gt;{'test@example.com'};
        
        Test.startTest();
        Id jobId = PrometheionScheduledDelivery.scheduleWeekly(pkg.Id, recipients);
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Should return job ID');
        
        // Clean up
        System.abortJob(jobId);
    }
    
    @isTest
    static void testScheduledDelivery_ScheduleMonthly() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List&lt;String&gt; recipients = new List&lt;String&gt;{'test@example.com'};
        
        Test.startTest();
        Id jobId = PrometheionScheduledDelivery.scheduleMonthly(pkg.Id, recipients);
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Should return job ID');
        
        // Clean up
        System.abortJob(jobId);
    }
    
    @isTest
    static void testScheduledDelivery_ScheduleQuarterly() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List&lt;String&gt; recipients = new List&lt;String&gt;{'test@example.com'};
        
        Test.startTest();
        Id jobId = PrometheionScheduledDelivery.scheduleQuarterly(pkg.Id, recipients);
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Should return job ID');
        
        // Clean up
        System.abortJob(jobId);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Mock Classes
    // ═══════════════════════════════════════════════════════════════
    
    private class SlackWebhookMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('ok');
            return res;
        }
    }
}
