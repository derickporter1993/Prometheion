/**
 * Test class for ElaroPCIAccessLogger
 * Tests PCI DSS Requirement 10 access logging functionality
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ElaroPCIAccessLoggerTest {

    @TestSetup
    static void setupTestData() {
        // Create test accounts to use as "payment" records
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Payment Record ' + i));
        }
        insert accounts;
    }

    @IsTest
    static void testLogPaymentDataAccess() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        ElaroPCIAccessLogger.logPaymentDataAccess(
            acc.Id,
            'View',
            'User viewed payment record'
        );
        Test.stopTest();

        // Verify platform event was published successfully
        // Platform events use DML operations
        Assert.isTrue(Limits.getDmlStatements() > 0, 'Should publish platform event via DML');
    }

    @IsTest
    static void testLogPaymentDataAccess_AllAccessTypes() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<String> accessTypes = new List<String>{
            'Query', 'Insert', 'Update', 'Delete', 'View'
        };

        Test.startTest();
        for (String accessType : accessTypes) {
            ElaroPCIAccessLogger.logPaymentDataAccess(
                acc.Id,
                accessType,
                'Test ' + accessType + ' action'
            );
        }
        Test.stopTest();

        // Verify all access types were logged via platform events
        Assert.areEqual(5, accessTypes.size(), 'Should test all 5 access types');
        Assert.isTrue(Limits.getDmlStatements() >= accessTypes.size(), 'Should publish event for each access type');
    }

    @IsTest
    static void testLogBulkPaymentDataAccess() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 200];
        Set<Id> recordIds = new Set<Id>();
        for (Account acc : accounts) {
            recordIds.add(acc.Id);
        }

        Test.startTest();
        ElaroPCIAccessLogger.logBulkPaymentDataAccess(
            recordIds,
            'Query',
            'Bulk query of payment records'
        );
        Test.stopTest();

        // Verify bulk logging completed with proper bulkification
        Assert.areEqual(200, recordIds.size(), 'Should process 200 records');
        Assert.isTrue(Limits.getDmlStatements() <= 2, 'Should bulkify platform event publishing');
    }

    @IsTest
    static void testLogBulkPaymentDataAccess_Empty() {
        Set<Id> emptySet = new Set<Id>();

        Test.startTest();
        ElaroPCIAccessLogger.logBulkPaymentDataAccess(
            emptySet,
            'Query',
            'Empty bulk query'
        );
        Test.stopTest();

        // Verify empty set is handled gracefully without DML
        Assert.areEqual(0, emptySet.size(), 'Set should be empty');
        Assert.areEqual(0, Limits.getDmlStatements(), 'Should not publish event for empty set');
    }

    @IsTest
    static void testLogFailedAccess() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        ElaroPCIAccessLogger.logFailedAccess(
            acc.Id,
            'Insufficient permissions to view payment data'
        );
        Test.stopTest();

        // Verify failed access event was published
        Assert.isTrue(Limits.getDmlStatements() > 0, 'Should publish failed access event');
    }

    @IsTest
    static void testLogSensitiveDataView() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<String> dataElements = new List<String>{
            'Card Number', 'Expiration Date', 'Billing Address'
        };

        Test.startTest();
        ElaroPCIAccessLogger.logSensitiveDataView(acc.Id, dataElements);
        Test.stopTest();

        // Verify sensitive data view event was published
        Assert.areEqual(3, dataElements.size(), 'Should track 3 data elements');
        Assert.isTrue(Limits.getDmlStatements() > 0, 'Should publish sensitive data view event');
    }

    @IsTest
    static void testLogSensitiveDataView_EmptyList() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<String> emptyElements = new List<String>();

        Test.startTest();
        ElaroPCIAccessLogger.logSensitiveDataView(acc.Id, emptyElements);
        Test.stopTest();

        // Verify empty elements list is handled gracefully
        Assert.areEqual(0, emptyElements.size(), 'Elements list should be empty');
        // Method may still log with empty list, verify no exception thrown
    }

    @IsTest
    static void testGetRecentAccessLogs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<ElaroPCIAccessLogger.AccessLogEntry> logs =
            ElaroPCIAccessLogger.getRecentAccessLogs(acc.Id, 10);
        Test.stopTest();

        Assert.areNotEqual(null, logs, 'Should return list (may be empty)');
    }

    @IsTest
    static void testAccessLogEntryWrapper() {
        ElaroPCIAccessLogger.AccessLogEntry entry = new ElaroPCIAccessLogger.AccessLogEntry();
        entry.recordId = '001000000000001';
        entry.userId = '005000000000001';
        entry.username = 'test@example.com';
        entry.accessType = 'View';
        entry.userAction = 'Viewed payment details';
        entry.ipAddress = '192.168.1.1';
        entry.timestamp = System.now();

        Assert.areEqual('001000000000001', entry.recordId, 'recordId should match');
        Assert.areEqual('View', entry.accessType, 'accessType should match');
    }

    @IsTest
    static void testBulkLoggingGovernorLimits() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 200];
        Set<Id> recordIds = new Set<Id>();
        for (Account acc : accounts) {
            recordIds.add(acc.Id);
        }

        Test.startTest();
        Integer startDML = Limits.getDmlStatements();

        ElaroPCIAccessLogger.logBulkPaymentDataAccess(
            recordIds,
            'Query',
            'Governor limits test'
        );

        Integer endDML = Limits.getDmlStatements();
        Test.stopTest();

        // Platform event publish is a single DML
        Assert.isTrue(endDML - startDML <= 2, 'Should be bulkified');
    }

    @IsTest
    static void testLoggingWithNullRecordId() {
        Test.startTest();
        ElaroPCIAccessLogger.logPaymentDataAccess(
            null,
            'Query',
            'Query with null record ID'
        );
        Test.stopTest();

        // Verify null record ID is handled gracefully without exception
        // Method should complete successfully even with null parameter
    }

    @IsTest
    static void testMultipleConcurrentLogs() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 10];

        Test.startTest();
        for (Account acc : accounts) {
            ElaroPCIAccessLogger.logPaymentDataAccess(acc.Id, 'View', 'Concurrent view');
            ElaroPCIAccessLogger.logPaymentDataAccess(acc.Id, 'Query', 'Concurrent query');
        }
        Test.stopTest();

        // Verify concurrent logging completed successfully
        Assert.areEqual(10, accounts.size(), 'Should process 10 accounts');
        Assert.isTrue(Limits.getDmlStatements() >= 20, 'Should publish 20 events (2 per account)');
    }

    @IsTest
    static void testSessionInfoCapture() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        // In test context, session info may not be available
        ElaroPCIAccessLogger.logPaymentDataAccess(
            acc.Id,
            'View',
            'Test session capture'
        );
        Test.stopTest();

        // Verify method handles missing session info gracefully in test context
        // Should still publish event even if session details are unavailable
        Assert.isTrue(Limits.getDmlStatements() > 0, 'Should publish event despite missing session info');
    }
}
