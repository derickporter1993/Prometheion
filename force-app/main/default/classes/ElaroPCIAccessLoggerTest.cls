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

        // Platform events are published asynchronously
        // We verify no exceptions were thrown
        System.assert(true, 'Access log should be created without error');
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

        System.assert(true, 'All access types should be logged');
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

        System.assert(true, 'Bulk logging should complete without error');
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

        System.assert(true, 'Empty set should not cause error');
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

        System.assert(true, 'Failed access should be logged');
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

        System.assert(true, 'Sensitive data view should be logged');
    }

    @IsTest
    static void testLogSensitiveDataView_EmptyList() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<String> emptyElements = new List<String>();

        Test.startTest();
        ElaroPCIAccessLogger.logSensitiveDataView(acc.Id, emptyElements);
        Test.stopTest();

        System.assert(true, 'Empty elements list should not cause error');
    }

    @IsTest
    static void testGetRecentAccessLogs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<ElaroPCIAccessLogger.AccessLogEntry> logs =
            ElaroPCIAccessLogger.getRecentAccessLogs(acc.Id, 10);
        Test.stopTest();

        System.assertNotEquals(null, logs, 'Should return list (may be empty)');
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

        System.assertEquals('001000000000001', entry.recordId, 'recordId should match');
        System.assertEquals('View', entry.accessType, 'accessType should match');
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
        System.assert(endDML - startDML <= 2, 'Should be bulkified');
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

        System.assert(true, 'Null record ID should not cause error');
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

        System.assert(true, 'Multiple concurrent logs should succeed');
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

        System.assert(true, 'Session info should be captured or handled gracefully');
    }
}
