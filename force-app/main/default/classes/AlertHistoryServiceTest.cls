@IsTest
private class AlertHistoryServiceTest {
    @IsTest static void testHistory() {
        insert new Performance_Alert_History__c(Metric__c='CPU', Value__c=9000, Threshold__c=8000, Context_Record__c='001000000000001');
        Test.startTest();
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.recent(5);
        Test.stopTest();
        System.assert(rows.size() >= 1);
    }
}
