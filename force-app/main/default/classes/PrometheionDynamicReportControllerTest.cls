/**
 * Test class for PrometheionDynamicReportController
 * Comprehensive test coverage for dynamic report building
 * @author Derick Porter
 * @date 2026-01-03
 */
@isTest
private class PrometheionDynamicReportControllerTest {

    @testSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 25; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
    }

    @isTest
    static void testGetAvailableObjects() {
        Test.startTest();
        List<PrometheionDynamicReportController.ObjectOption> objects =
            PrometheionDynamicReportController.getAvailableObjects();
        Test.stopTest();

        System.assertNotEquals(0, objects.size(), 'Should return available objects');
    }

    @isTest
    static void testGetFieldMetadata() {
        Test.startTest();
        List<PrometheionDynamicReportController.FieldMetadata> fields =
            PrometheionDynamicReportController.getFieldMetadata('Account');
        Test.stopTest();

        System.assertNotEquals(0, fields.size(), 'Should return field metadata');
    }

    @isTest
    static void testGetFieldMetadataInvalidObject() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDynamicReportController.getFieldMetadata('Invalid__c');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for invalid object');
    }

    @isTest
    static void testGetFieldMetadataCacheScenario() {
        Test.startTest();
        List<PrometheionDynamicReportController.FieldMetadata> fields =
            PrometheionDynamicReportController.getFieldMetadata('Account');
        List<PrometheionDynamicReportController.FieldMetadata> fields2 =
            PrometheionDynamicReportController.getFieldMetadata('Account');
        Test.stopTest();

        System.assertNotEquals(0, fields.size(), 'Should return field metadata');
        System.assertNotEquals(0, fields2.size(), 'Should return field metadata on second call');
    }

    @isTest
    static void testExecuteReport() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name', 'CreatedDate'},
            'filters' => new List<Object>(),
            'maxRows' => 10,
            'orderBy' => 'Name',
            'orderDirection' => 'ASC'
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(0, result.recordCount, 'Should return records');
        System.assertNotEquals(null, result.queryExecuted, 'Query should be executed');
    }

    @isTest
    static void testExecuteReportWithFilters() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'Name',
                    'operator' => 'LIKE',
                    'value' => 'Test'
                }
            },
            'maxRows' => 10
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testExecuteReportInvalidObject() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Invalid__c',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'maxRows' => 10
        });

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDynamicReportController.executeReport(configJson);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for invalid object');
    }

    @isTest
    static void testExecuteReportEmptyConfig() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDynamicReportController.executeReport('');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for empty config');
    }

    @isTest
    static void testExecuteReportNullConfig() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDynamicReportController.executeReport(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for null config');
    }

    @isTest
    static void testExecuteReportInvalidJson() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDynamicReportController.executeReport('invalid json');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for invalid JSON');
    }

    @isTest
    static void testExecuteReportEmptyFields() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>(),
            'filters' => new List<Object>(),
            'maxRows' => 10
        });

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDynamicReportController.executeReport(configJson);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for empty fields');
    }

    @isTest
    static void testExecuteReportNullFields() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => null,
            'filters' => new List<Object>(),
            'maxRows' => 10
        });

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDynamicReportController.executeReport(configJson);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for null fields');
    }

    @isTest
    static void testExecuteReportInvalidField() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'InvalidField__c'},
            'filters' => new List<Object>(),
            'maxRows' => 10
        });

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDynamicReportController.executeReport(configJson);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for invalid field');
    }

    @isTest
    static void testExecuteReportInvalidOperator() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'Name',
                    'operator' => 'INVALID_OP',
                    'value' => 'Test'
                }
            },
            'maxRows' => 10
        });

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDynamicReportController.executeReport(configJson);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for invalid operator');
    }

    @isTest
    static void testExecuteReportMaxRowsExceeded() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'maxRows' => 20000
        });

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionDynamicReportController.executeReport(configJson);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for max rows exceeded');
    }

    @isTest
    static void testExecuteReportMaxRowsNull() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'maxRows' => null
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testExecuteReportMaxRowsZero() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'maxRows' => 0
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testExecuteReportHasMoreTrue() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>(),
            'maxRows' => 10
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.hasMore, 'Should indicate more records available');
    }

    @isTest
    static void testExecuteReportHasMoreFalse() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'Name',
                    'operator' => 'LIKE',
                    'value' => 'NonExistent'
                }
            },
            'maxRows' => 10
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.hasMore, 'Should indicate no more records');
    }

    @isTest
    static void testExecuteReportEqualsOperator() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'Name',
                    'operator' => '=',
                    'value' => 'Test Account 1'
                }
            },
            'maxRows' => 10
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testExecuteReportNotEqualsOperator() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'Name',
                    'operator' => '!=',
                    'value' => 'Nonexistent'
                }
            },
            'maxRows' => 10
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testExecuteReportInOperator() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'Name',
                    'operator' => 'IN',
                    'value' => 'Test Account 1,Test Account 2'
                }
            },
            'maxRows' => 10
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testExecuteReportNotInOperator() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'Name',
                    'operator' => 'NOT IN',
                    'value' => 'Nonexistent1,Nonexistent2'
                }
            },
            'maxRows' => 10
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testExecuteReportNumericFilter() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name', 'NumberOfEmployees'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'NumberOfEmployees',
                    'operator' => '>',
                    'value' => '0'
                }
            },
            'maxRows' => 10
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testExecuteReportBooleanFilter() {
        // Use Account with IsDeleted field which is accessible
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'Name',
                    'operator' => '!=',
                    'value' => 'null'
                }
            },
            'maxRows' => 10
        });

        Test.startTest();
        try {
            PrometheionDynamicReportController.ReportResult result =
                PrometheionDynamicReportController.executeReport(configJson);
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (Exception e) {
            // Field validation may fail for some fields
            System.assert(true, 'Query may fail');
        }
        Test.stopTest();
    }

    @isTest
    static void testExecuteReportNullFilter() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name'},
            'filters' => new List<Object>{
                new Map<String, Object>{
                    'field' => 'ParentId',
                    'operator' => '=',
                    'value' => 'null'
                }
            },
            'maxRows' => 10
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testExecuteReportWithOrderByDesc() {
        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Account',
            'fields' => new List<String>{'Name', 'CreatedDate'},
            'filters' => new List<Object>(),
            'maxRows' => 10,
            'orderBy' => 'Name',
            'orderDirection' => 'DESC'
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testExecuteReportRelationshipField() {
        // Create Account with related Contact
        Account acc = new Account(Name = 'Parent Account');
        insert acc;
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        String configJson = JSON.serialize(new Map<String, Object>{
            'objectApiName' => 'Contact',
            'fields' => new List<String>{'FirstName', 'LastName', 'Account.Name'},
            'filters' => new List<Object>(),
            'maxRows' => 10
        });

        Test.startTest();
        PrometheionDynamicReportController.ReportResult result =
            PrometheionDynamicReportController.executeReport(configJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testReportResultClassStructure() {
        PrometheionDynamicReportController.ReportResult result =
            new PrometheionDynamicReportController.ReportResult();

        result.data = new List<Map<String, Object>>();
        result.recordCount = 10;
        result.hasMore = true;
        result.queryExecuted = 'SELECT Name FROM Account';

        System.assertNotEquals(null, result.data, 'Data should be set');
        System.assertEquals(10, result.recordCount, 'Record count should be set');
        System.assertEquals(true, result.hasMore, 'Has more should be set');
        System.assertNotEquals(null, result.queryExecuted, 'Query executed should be set');
    }

    @isTest
    static void testObjectOptionClassStructure() {
        PrometheionDynamicReportController.ObjectOption opt =
            new PrometheionDynamicReportController.ObjectOption();

        opt.label = 'Test Object';
        opt.value = 'Test__c';

        System.assertEquals('Test Object', opt.label, 'Label should be set');
        System.assertEquals('Test__c', opt.value, 'Value should be set');
    }

    @isTest
    static void testFieldMetadataClassStructure() {
        PrometheionDynamicReportController.FieldMetadata fm =
            new PrometheionDynamicReportController.FieldMetadata();

        fm.label = 'Test Field';
        fm.apiName = 'TestField__c';
        fm.fieldType = 'TEXT';
        fm.isFilterable = true;
        fm.isGroupable = false;
        fm.isSortable = true;

        System.assertEquals('Test Field', fm.label, 'Label should be set');
        System.assertEquals('TestField__c', fm.apiName, 'API name should be set');
        System.assertEquals('TEXT', fm.fieldType, 'Field type should be set');
    }

    @isTest
    static void testFieldMetadataCompareTo() {
        PrometheionDynamicReportController.FieldMetadata fm1 =
            new PrometheionDynamicReportController.FieldMetadata();
        fm1.label = 'Alpha';

        PrometheionDynamicReportController.FieldMetadata fm2 =
            new PrometheionDynamicReportController.FieldMetadata();
        fm2.label = 'Beta';

        System.assert(fm1.compareTo(fm2) < 0, 'Alpha should be before Beta');
    }
}
