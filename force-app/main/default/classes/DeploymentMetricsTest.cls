@IsTest
private class DeploymentMetricsTest {
    @IsTest static void testRecent() {
        insert new Deployment_Job__c(Status__c='Success', Started_On__c=System.now().addMinutes(-10), Finished_On__c=System.now(), Tests_Passed__c=10, Tests_Failed__c=0);
        Test.startTest();
        List<DeploymentMetrics.DeployRow> rows = DeploymentMetrics.recent(5);
        Test.stopTest();
        System.assert(rows.size() >= 1);
    }
}
