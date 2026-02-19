/**
 * ElaroBatchEventLoaderTest
 *
 * Test class for ElaroBatchEventLoader
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ElaroBatchEventLoader.class)
private class ElaroBatchEventLoaderTest {

    @TestSetup
    static void setup() {
        // Create test audit logs for bulk testing
        List<Elaro_Audit_Log__c> logs = new List<Elaro_Audit_Log__c>();
        for (Integer i = 0; i < 200; i++) {
            logs.add(new Elaro_Audit_Log__c(
                Action__c = 'TEST_ACTION_' + i,
                Object_Type__c = 'Account',
                Timestamp__c = System.now()
            ));
        }
        insert logs;
    }

    @isTest
    static void testBasicFunctionality() {
        Test.startTest();
        ElaroBatchEventLoader batch = new ElaroBatchEventLoader(
            'AUDIT',
            Date.today().addDays(-30),
            Date.today(),
            'SOC2'
        );
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify batch job was executed
        List<AsyncApexJob> jobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'ElaroBatchEventLoader'
        ];
        Assert.isTrue(jobs.size() > 0, 'Batch job should have been executed');
    }

    @isTest
    static void testBatch_BulkExecution() {
        Test.startTest();
        ElaroBatchEventLoader batch = new ElaroBatchEventLoader(
            'COMPLIANCE',
            Date.today().addDays(-90),
            Date.today(),
            'HIPAA'
        );
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();

        Assert.areNotEqual(null, batchId, 'Batch ID should not be null');
        Assert.isTrue(Limits.getQueries() < 100, 'Should stay under SOQL limit');
        Assert.isTrue(Limits.getDmlStatements() < 150, 'Should stay under DML limit');
    }

    @isTest
    static void testBatch_SmallBatchSize() {
        Test.startTest();
        ElaroBatchEventLoader batch = new ElaroBatchEventLoader(
            'SECURITY',
            Date.today().addDays(-7),
            Date.today(),
            'PCI-DSS'
        );
        Database.executeBatch(batch, 10);
        Test.stopTest();

        // Verify batch completed with small batch size
        List<AsyncApexJob> jobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'ElaroBatchEventLoader'
        ];
        Assert.isTrue(jobs.size() > 0, 'Batch should execute with small batch size');
    }

    @isTest
    static void testBatch_AllFrameworks() {
        List<String> frameworks = new List<String>{'SOC2', 'HIPAA', 'GDPR', 'PCI-DSS', 'NIST'};

        Test.startTest();
        for (String framework : frameworks) {
            ElaroBatchEventLoader batch = new ElaroBatchEventLoader(
                'AUDIT',
                Date.today().addDays(-30),
                Date.today(),
                framework
            );
            Database.executeBatch(batch, 50);
        }
        Test.stopTest();

        // Verify batch jobs were created for all frameworks
        List<AsyncApexJob> jobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'ElaroBatchEventLoader'
        ];
        Assert.areEqual(frameworks.size(), jobs.size(), 'Should have one batch job per framework');
    }

    @isTest
    static void testBatch_DateRanges() {
        Test.startTest();

        // Test with narrow date range
        ElaroBatchEventLoader narrowBatch = new ElaroBatchEventLoader(
            'AUDIT',
            Date.today(),
            Date.today(),
            'SOC2'
        );
        Database.executeBatch(narrowBatch, 200);

        // Test with wide date range
        ElaroBatchEventLoader wideBatch = new ElaroBatchEventLoader(
            'AUDIT',
            Date.today().addDays(-365),
            Date.today(),
            'SOC2'
        );
        Database.executeBatch(wideBatch, 200);

        Test.stopTest();

        // Verify both batch jobs were created for different date ranges
        List<AsyncApexJob> jobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'ElaroBatchEventLoader'
        ];
        Assert.areEqual(2, jobs.size(), 'Should have two batch jobs for narrow and wide date ranges');
    }
}
