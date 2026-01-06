/**
 * Test class for PrometheionDrillDownController
 * Comprehensive test coverage for drill-down viewer
 * @author Derick Porter
 * @date 2026-01-03
 */
@isTest
private class PrometheionDrillDownControllerTest {

    @testSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 30; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
    }

    @isTest
    static void testGetRecords() {
        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'displayFields' => new List<String>{'Name', 'CreatedDate'},
            'filters' => new List<Object>(),
            'pageSize' => 10,
            'offset' => 0
        });

        Test.startTest();
        PrometheionDrillDownController.DrillDownResult result =
            PrometheionDrillDownController.getRecords(contextJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(0, result.totalCount, 'Should return records');
        System.assertNotEquals(null, result.columns, 'Columns should be set');
    }

    @isTest
    static void testGetRecordsWithFilters() {
        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'displayFields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'Name',
                    'operator' => 'LIKE',
                    'value' => 'Test'
                }
            },
            'pageSize' => 10,
            'offset' => 0
        });

        Test.startTest();
        PrometheionDrillDownController.DrillDownResult result =
            PrometheionDrillDownController.getRecords(contextJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetRecordsPagination() {
        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'displayFields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'pageSize' => 5,
            'offset' => 5
        });

        Test.startTest();
        PrometheionDrillDownController.DrillDownResult result =
            PrometheionDrillDownController.getRecords(contextJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(5, result.currentOffset, 'Offset should match');
        System.assertEquals(5, result.pageSize, 'Page size should match');
    }

    @isTest
    static void testGetRecordsHasMore() {
        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'displayFields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'pageSize' => 10,
            'offset' => 0
        });

        Test.startTest();
        PrometheionDrillDownController.DrillDownResult result =
            PrometheionDrillDownController.getRecords(contextJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        if (result.totalCount > 10) {
            System.assertEquals(true, result.hasMore, 'Should indicate more records available');
        }
    }

    @isTest
    static void testGetRecordsEmptyContext() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDrillDownController.getRecords('');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for empty context');
    }

    @isTest
    static void testGetRecordsNullContext() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDrillDownController.getRecords(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for null context');
    }

    @isTest
    static void testGetRecordsInvalidJson() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDrillDownController.getRecords('invalid json');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for invalid JSON');
    }

    @isTest
    static void testGetRecordsInvalidObject() {
        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Invalid__c',
            'displayFields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'pageSize' => 10,
            'offset' => 0
        });

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDrillDownController.getRecords(contextJson);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for invalid object');
    }

    @isTest
    static void testGetRecordsNullPageSize() {
        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'displayFields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'pageSize' => null,
            'offset' => 0
        });

        Test.startTest();
        PrometheionDrillDownController.DrillDownResult result =
            PrometheionDrillDownController.getRecords(contextJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetRecordsNullOffset() {
        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'displayFields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'pageSize' => 10,
            'offset' => null
        });

        Test.startTest();
        PrometheionDrillDownController.DrillDownResult result =
            PrometheionDrillDownController.getRecords(contextJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.currentOffset, 'Offset should default to 0');
    }

    @isTest
    static void testGetRecordsWithOrderBy() {
        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'displayFields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'pageSize' => 10,
            'offset' => 0,
            'orderBy' => 'Name',
            'orderDirection' => 'DESC'
        });

        Test.startTest();
        PrometheionDrillDownController.DrillDownResult result =
            PrometheionDrillDownController.getRecords(contextJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetRecordsNullFilter() {
        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'displayFields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'ParentId',
                    'operator' => '=',
                    'value' => 'null'
                }
            },
            'pageSize' => 10,
            'offset' => 0
        });

        Test.startTest();
        PrometheionDrillDownController.DrillDownResult result =
            PrometheionDrillDownController.getRecords(contextJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testExportToCSV() {
        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'displayFields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'pageSize' => 10,
            'offset' => 0
        });

        Test.startTest();
        String csv = PrometheionDrillDownController.exportToCSV(contextJson);
        Test.stopTest();

        System.assertNotEquals(null, csv, 'CSV should not be null');
        System.assert(csv.contains('Name'), 'CSV should contain headers');
    }

    @isTest
    static void testExportToCSVEmptyContext() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDrillDownController.exportToCSV('');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for empty context');
    }

    @isTest
    static void testExportToCSVInvalidJson() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDrillDownController.exportToCSV('invalid json');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for invalid JSON');
    }

    @isTest
    static void testExportToCSVWithFilters() {
        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'displayFields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'Name',
                    'operator' => 'LIKE',
                    'value' => 'Test'
                }
            },
            'pageSize' => 10,
            'offset' => 0
        });

        Test.startTest();
        String csv = PrometheionDrillDownController.exportToCSV(contextJson);
        Test.stopTest();

        System.assertNotEquals(null, csv, 'CSV should not be null');
    }

    @isTest
    static void testExportToCSVRelationshipField() {
        Account acc = new Account(Name = 'Parent Account');
        insert acc;
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        String contextJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Contact',
            'displayFields' => new List<String>{'FirstName', 'LastName', 'Account.Name'},
            'filters' => new List<Object>(),
            'pageSize' => 10,
            'offset' => 0
        });

        Test.startTest();
        String csv = PrometheionDrillDownController.exportToCSV(contextJson);
        Test.stopTest();

        System.assertNotEquals(null, csv, 'CSV should not be null');
    }

    @isTest
    static void testDrillDownResultClassStructure() {
        PrometheionDrillDownController.DrillDownResult result =
            new PrometheionDrillDownController.DrillDownResult();

        result.records = new List<SObject>();
        result.columns = new List<PrometheionDrillDownController.ColumnDef>();
        result.totalCount = 10;
        result.pageSize = 5;
        result.currentOffset = 0;
        result.hasMore = true;
        result.objectLabel = 'Account';

        System.assertNotEquals(null, result.records, 'Records should be set');
        System.assertNotEquals(null, result.columns, 'Columns should be set');
        System.assertEquals(10, result.totalCount, 'Total count should be set');
        System.assertEquals(5, result.pageSize, 'Page size should be set');
    }

    @isTest
    static void testColumnDefClassStructure() {
        PrometheionDrillDownController.ColumnDef col =
            new PrometheionDrillDownController.ColumnDef();

        col.fieldName = 'Name';
        col.label = 'Account Name';
        col.type = 'text';
        col.sortable = true;

        System.assertEquals('Name', col.fieldName, 'Field name should be set');
        System.assertEquals('Account Name', col.label, 'Label should be set');
        System.assertEquals('text', col.type, 'Type should be set');
        System.assertEquals(true, col.sortable, 'Sortable should be set');
    }

    @isTest
    static void testFilterContextClassStructure() {
        PrometheionDrillDownController.FilterContext ctx =
            new PrometheionDrillDownController.FilterContext();

        ctx.objectApiName = 'Account';
        ctx.displayFields = new List<String>{'Name'};
        ctx.filters = new List<PrometheionDrillDownController.Filter>();
        ctx.orderBy = 'Name';
        ctx.orderDirection = 'ASC';
        ctx.pageSize = 10;
        ctx.offset = 0;

        System.assertEquals('Account', ctx.objectApiName, 'Object API name should be set');
    }

    @isTest
    static void testFilterClassStructure() {
        PrometheionDrillDownController.Filter f =
            new PrometheionDrillDownController.Filter();

        f.field = 'Name';
        f.operator = '=';
        f.value = 'Test';

        System.assertEquals('Name', f.field, 'Field should be set');
        System.assertEquals('=', f.operator, 'Operator should be set');
        System.assertEquals('Test', f.value, 'Value should be set');
    }
}
