@IsTest
private class DeploymentMetricsTest {

    @TestSetup
    static void setupTestData() {
        List<Deployment_Job__c> jobs = new List<Deployment_Job__c>();
        for (Integer i = 0; i < 10; i++) {
            jobs.add(new Deployment_Job__c(
                Status__c = Math.mod(i, 2) == 0 ? 'Success' : 'Failed',
                Started_On__c = System.now().addMinutes(-i * 10),
                Finished_On__c = System.now().addMinutes(-i * 10 + 5),
                Tests_Passed__c = i * 10,
                Tests_Failed__c = Math.mod(i, 3)
            ));
        }
        insert jobs;
    }

    @IsTest
    static void testRecent() {
        Test.startTest();
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.recent(5);
        Test.stopTest();

        System.assertEquals(5, rows.size(), 'Should return 5 records');
    }

    @IsTest
    static void testGetRecentDeployments() {
        Test.startTest();
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.getRecentDeployments(3);
        Test.stopTest();

        System.assertEquals(3, rows.size(), 'Should return 3 records');
        // Verify ordering (most recent first)
        System.assert(rows[0].startedOn >= rows[1].startedOn, 'Should be ordered by startedOn DESC');
    }

    @IsTest
    static void testRecentEmpty() {
        // Delete all test data
        delete [SELECT Id FROM Deployment_Job__c];

        Test.startTest();
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.recent(5);
        Test.stopTest();

        System.assertEquals(0, rows.size(), 'Should return 0 when no data');
    }

    @IsTest
    static void testRecentWithInvalidLimit() {
        Test.startTest();
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.recent(0);
        Test.stopTest();

        // With limit 0, Math.max(1, 0) = 1, so should return 1 record
        System.assertEquals(1, rows.size(), 'Should handle zero limit gracefully');
    }

    @IsTest
    static void testRecentWithNegativeLimit() {
        Test.startTest();
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.recent(-5);
        Test.stopTest();

        // With limit -5, Math.max(1, -5) = 1, so should return 1 record
        System.assertEquals(1, rows.size(), 'Should handle negative limit gracefully');
    }

    @IsTest
    static void testFieldValues() {
        Test.startTest();
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.recent(1);
        Test.stopTest();

        System.assertEquals(1, rows.size(), 'Should return 1 record');
        DeploymentMetrics.Row row = rows[0];

        System.assertNotEquals(null, row.status, 'Status should not be null');
        System.assertNotEquals(null, row.startedOn, 'StartedOn should not be null');
        System.assertNotEquals(null, row.testsPassed, 'TestsPassed should not be null');
        System.assertNotEquals(null, row.testsFailed, 'TestsFailed should not be null');
    }

    @IsTest
    static void testRowConstructor() {
        Deployment_Job__c job = new Deployment_Job__c(
            Status__c = 'Success',
            Started_On__c = System.now().addHours(-1),
            Finished_On__c = System.now(),
            Tests_Passed__c = 100,
            Tests_Failed__c = 5
        );
        insert job;

        // Re-query to get Name
        job = [SELECT Name, Status__c, Started_On__c, Finished_On__c, Tests_Passed__c, Tests_Failed__c FROM Deployment_Job__c WHERE Id = :job.Id];

        Test.startTest();
        DeploymentMetrics.Row row = new DeploymentMetrics.Row(job);
        Test.stopTest();

        System.assertEquals(job.Name, row.name, 'Name should match');
        System.assertEquals('Success', row.status, 'Status should match');
        System.assertEquals(100, row.testsPassed, 'TestsPassed should match');
        System.assertEquals(5, row.testsFailed, 'TestsFailed should match');
    }

    @IsTest
    static void testLargeLimit() {
        Test.startTest();
        // Request more than exists
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.recent(100);
        Test.stopTest();

        // Should return all 10 records from @TestSetup
        System.assertEquals(10, rows.size(), 'Should return all available records');
    }
}
