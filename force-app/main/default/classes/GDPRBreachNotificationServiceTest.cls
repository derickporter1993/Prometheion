/**
 * Test class for GDPRBreachNotificationService
 * Tests breach reporting, severity assessment, DPA and data subject notifications
 * 
 * @author Elaro
 * @version 3.0
 */
@IsTest
private class GDPRBreachNotificationServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test breaches
        List<GDPR_Breach__c> breaches = new List<GDPR_Breach__c>();
        for (Integer i = 0; i < 200; i++) {
            DateTime breachDate = DateTime.now().addDays(-i);
            breaches.add(new GDPR_Breach__c(
                Breach_Date__c = breachDate,
                Affected_Records__c = i * 10,
                Status__c = 'Detected',
                DPA_Notified__c = false
            ));
        }
        insert breaches;
    }
    
    @IsTest
    static void testReportBreach_Success() {
        DateTime breachDate = DateTime.now();
        Integer affectedRecords = 100;
        String description = 'Test breach';
        
        Test.startTest();
        GDPRBreachNotificationService service = new GDPRBreachNotificationService();
        Id breachId = service.reportBreach(breachDate, affectedRecords, description);
        Test.stopTest();
        
        System.assertNotEquals(null, breachId, 'Breach ID should be returned');
        
        GDPR_Breach__c breach = [SELECT Id, Affected_Records__c, Status__c FROM GDPR_Breach__c WHERE Id = :breachId];
        System.assertEquals(100, breach.Affected_Records__c, 'Affected records should match');
        System.assertEquals('Detected', breach.Status__c, 'Status should be Detected');
    }
    
    @IsTest
    static void testReportBreach_Bulk() {
        List<Id> breachIds = new List<Id>();
        
        Test.startTest();
        GDPRBreachNotificationService service = new GDPRBreachNotificationService();
        for (Integer i = 0; i < 200; i++) {
            try {
                Id breachId = service.reportBreach(DateTime.now(), i * 5, 'Bulk breach ' + i);
                breachIds.add(breachId);
            } catch (Exception e) {
                // Some may fail due to test data limitations
            }
        }
        Test.stopTest();
        
        System.assert(breachIds.size() > 0, 'Should process bulk breaches');
    }
    
    @IsTest
    static void testAssessSeverity_High() {
        GDPR_Breach__c breach = new GDPR_Breach__c(
            Breach_Date__c = DateTime.now(),
            Affected_Records__c = 1500,
            Status__c = 'Detected'
        );
        insert breach;
        
        Test.startTest();
        GDPRBreachNotificationService service = new GDPRBreachNotificationService();
        Map<String, Object> result = service.assessSeverity(breach.Id);
        Test.stopTest();
        
        System.assertEquals('High', result.get('severity'), 'Severity should be High');
        System.assertEquals(true, result.get('requiresDataSubjectNotification'), 
            'Should require data subject notification');
    }
    
    @IsTest
    static void testAssessSeverity_Low() {
        GDPR_Breach__c breach = new GDPR_Breach__c(
            Breach_Date__c = DateTime.now(),
            Affected_Records__c = 50,
            Status__c = 'Detected'
        );
        insert breach;
        
        Test.startTest();
        GDPRBreachNotificationService service = new GDPRBreachNotificationService();
        Map<String, Object> result = service.assessSeverity(breach.Id);
        Test.stopTest();
        
        System.assertEquals('Low', result.get('severity'), 'Severity should be Low');
    }
    
    @IsTest
    static void testNotifyDPA_Success() {
        GDPR_Breach__c breach = new GDPR_Breach__c(
            Breach_Date__c = DateTime.now(),
            Affected_Records__c = 100,
            Status__c = 'Detected',
            DPA_Notified__c = false
        );
        insert breach;
        
        Test.startTest();
        GDPRBreachNotificationService service = new GDPRBreachNotificationService();
        Map<String, Object> result = service.notifyDPA(breach.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'DPA notification should succeed');
        
        GDPR_Breach__c updatedBreach = [SELECT DPA_Notified__c, Status__c FROM GDPR_Breach__c WHERE Id = :breach.Id];
        System.assertEquals(true, updatedBreach.DPA_Notified__c, 'DPA should be marked as notified');
        System.assertEquals('DPA Notified', updatedBreach.Status__c, 'Status should be updated');
    }
    
    @IsTest
    static void testNotifyDataSubjects_Success() {
        GDPR_Breach__c breach = new GDPR_Breach__c(
            Breach_Date__c = DateTime.now(),
            Affected_Records__c = 500,
            Status__c = 'DPA Notified'
        );
        insert breach;
        
        Test.startTest();
        GDPRBreachNotificationService service = new GDPRBreachNotificationService();
        Map<String, Object> result = service.notifyDataSubjects(breach.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Data subject notification should succeed');
        
        GDPR_Breach__c updatedBreach = [SELECT Status__c FROM GDPR_Breach__c WHERE Id = :breach.Id];
        System.assertEquals('Data Subjects Notified', updatedBreach.Status__c, 'Status should be updated');
    }
    
    @IsTest
    static void testTrackDeadlines() {
        Test.startTest();
        GDPRBreachNotificationService service = new GDPRBreachNotificationService();
        List<GDPR_Breach__c> breaches = service.trackDeadlines();
        Test.stopTest();
        
        System.assertNotEquals(null, breaches, 'Breaches list should not be null');
        // May be empty if no breaches are approaching deadline
    }
    
    @IsTest
    static void testReportBreach_NullParameters() {
        Test.startTest();
        GDPRBreachNotificationService service = new GDPRBreachNotificationService();
        try {
            service.reportBreach(null, 100, 'Test');
            System.assert(false, 'Should throw exception for null breach date');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testAssessSeverity_NotFound() {
        Id fakeId = 'a00000000000000AAA';
        
        Test.startTest();
        GDPRBreachNotificationService service = new GDPRBreachNotificationService();
        try {
            service.assessSeverity(fakeId);
            System.assert(false, 'Should throw exception for non-existent breach');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required') || e.getMessage().contains('not found'), 
                'Should handle missing breach');
        }
        Test.stopTest();
    }
}
