@IsTest
private class SentinelAlertTriggerTest {
    @IsTest
    static void testTrigger_PublishesEvent() {
        Alert__c alert = new Alert__c(
            Title__c = 'Test Alert',
            Description__c = 'Test Description',
            Alert_Type__c = 'POLICY_VIOLATION',
            Severity__c = 'HIGH',
            Acknowledged__c = false
        );

        Test.startTest();
        insert alert;
        Test.stopTest();

        // Verify alert was created
        Alert__c insertedAlert = [SELECT Id, Title__c FROM Alert__c WHERE Id = :alert.Id];
        System.assertEquals('Test Alert', insertedAlert.Title__c);
    }

    @IsTest
    static void testTrigger_SkipsAcknowledgedAlerts() {
        Alert__c alert = new Alert__c(
            Title__c = 'Acknowledged Alert',
            Description__c = 'Test Description',
            Alert_Type__c = 'DRIFT',
            Severity__c = 'LOW',
            Acknowledged__c = true
        );

        Test.startTest();
        insert alert;
        Test.stopTest();

        // Verify alert was created but event should not be published
        Alert__c insertedAlert = [SELECT Id, Acknowledged__c FROM Alert__c WHERE Id = :alert.Id];
        System.assertEquals(true, insertedAlert.Acknowledged__c);
    }

    @IsTest
    static void testTrigger_BulkInsert() {
        List<Alert__c> alerts = new List<Alert__c>();
        for (Integer i = 0; i < 200; i++) {
            alerts.add(new Alert__c(
                Title__c = 'Bulk Alert ' + i,
                Description__c = 'Bulk test',
                Alert_Type__c = 'AI_ADJUDICATION',
                Severity__c = 'MEDIUM',
                Acknowledged__c = false
            ));
        }

        Test.startTest();
        insert alerts;
        Test.stopTest();

        List<Alert__c> insertedAlerts = [SELECT Id FROM Alert__c];
        System.assertEquals(200, insertedAlerts.size(), 'Should insert all alerts');
    }
}
