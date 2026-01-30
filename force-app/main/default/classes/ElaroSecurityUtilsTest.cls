/**
 * ElaroSecurityUtilsTest
 * 
 * Test class for ElaroSecurityUtils security utility
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ElaroSecurityUtilsTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account for CRUD testing
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
    }
    
    @IsTest
    static void testHasReadAccess() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasReadAccess('Account');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have read access to Account');
    }
    
    @IsTest
    static void testHasCreateAccess() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasCreateAccess('Account');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have create access to Account');
    }
    
    @IsTest
    static void testHasUpdateAccess() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasUpdateAccess('Account');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have update access to Account');
    }
    
    @IsTest
    static void testHasDeleteAccess() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasDeleteAccess('Account');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have delete access to Account');
    }
    
    @IsTest
    static void testHasFieldReadAccess() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldReadAccess('Account', 'Name');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have read access to Account.Name');
    }
    
    @IsTest
    static void testHasFieldWriteAccess() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldWriteAccess('Account', 'Name');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have write access to Account.Name');
    }
    
    @IsTest
    static void testHasFieldReadAccess_InvalidField() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldReadAccess('Account', 'InvalidField__c');
        Test.stopTest();
        
        System.assertEquals(false, hasAccess, 'Should not have access to invalid field');
    }
    
    @IsTest
    static void testHasFieldWriteAccess_InvalidField() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldWriteAccess('Account', 'InvalidField__c');
        Test.stopTest();
        
        System.assertEquals(false, hasAccess, 'Should not have write access to invalid field');
    }
    
    @IsTest
    static void testStripInaccessibleFields() {
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1];
        
        Test.startTest();
        List<SObject> stripped = ElaroSecurityUtils.stripInaccessibleFields(
            AccessType.READABLE,
            accounts
        );
        Test.stopTest();
        
        System.assertEquals(1, stripped.size(), 'Should return accessible records');
    }
    
    @IsTest
    static void testStripInaccessibleFields_EmptyList() {
        List<Account> emptyList = new List<Account>();
        
        Test.startTest();
        List<SObject> stripped = ElaroSecurityUtils.stripInaccessibleFields(
            AccessType.READABLE,
            emptyList
        );
        Test.stopTest();
        
        System.assertEquals(0, stripped.size(), 'Should return empty list');
    }
    
    @IsTest
    static void testValidateCRUDAccess_Insert() {
        Test.startTest();
        try {
            ElaroSecurityUtils.validateCRUDAccess(
                'Account',
                ElaroSecurityUtils.DmlOperation.DML_INSERT
            );
            System.assert(true, 'Should not throw exception for valid insert access');
        } catch (ElaroSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateCRUDAccess_Update() {
        Test.startTest();
        try {
            ElaroSecurityUtils.validateCRUDAccess(
                'Account',
                ElaroSecurityUtils.DmlOperation.DML_UPDATE
            );
            System.assert(true, 'Should not throw exception for valid update access');
        } catch (ElaroSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateCRUDAccess_Delete() {
        Test.startTest();
        try {
            ElaroSecurityUtils.validateCRUDAccess(
                'Account',
                ElaroSecurityUtils.DmlOperation.DML_DELETE
            );
            System.assert(true, 'Should not throw exception for valid delete access');
        } catch (ElaroSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateCRUDAccess_Upsert() {
        Test.startTest();
        try {
            ElaroSecurityUtils.validateCRUDAccess(
                'Account',
                ElaroSecurityUtils.DmlOperation.DML_UPSERT
            );
            System.assert(true, 'Should not throw exception for valid upsert access');
        } catch (ElaroSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateFLSAccess_Read() {
        List<String> fields = new List<String>{'Name', 'BillingCity'};
        
        Test.startTest();
        try {
            ElaroSecurityUtils.validateFLSAccess('Account', fields, false);
            System.assert(true, 'Should not throw exception for valid FLS read access');
        } catch (ElaroSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateFLSAccess_Write() {
        List<String> fields = new List<String>{'Name', 'BillingCity'};
        
        Test.startTest();
        try {
            ElaroSecurityUtils.validateFLSAccess('Account', fields, true);
            System.assert(true, 'Should not throw exception for valid FLS write access');
        } catch (ElaroSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testBuildSecureQuery() {
        String baseQuery = 'SELECT Id, Name FROM Account';
        
        Test.startTest();
        String secureQuery = ElaroSecurityUtils.buildSecureQuery(baseQuery);
        Test.stopTest();
        
        System.assert(secureQuery.contains('WITH SECURITY_ENFORCED'), 
            'Should add WITH SECURITY_ENFORCED');
        System.assert(secureQuery.contains('SELECT Id, Name FROM Account'), 
            'Should preserve original query');
    }
    
    @IsTest
    static void testBuildSecureQuery_AlreadyHasSecurityEnforced() {
        String baseQuery = 'SELECT Id, Name FROM Account WITH SECURITY_ENFORCED';

        Test.startTest();
        String secureQuery = ElaroSecurityUtils.buildSecureQuery(baseQuery);
        Test.stopTest();

        // Should only have one WITH SECURITY_ENFORCED
        Integer count = secureQuery.split('WITH SECURITY_ENFORCED', -1).size() - 1;
        System.assertEquals(1, count, 'Should have exactly one WITH SECURITY_ENFORCED');
    }

    @IsTest
    static void testHasReadAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasReadAccess('InvalidObject__c');
        Test.stopTest();

        System.assertEquals(false, hasAccess, 'Should not have read access to invalid object');
    }

    @IsTest
    static void testHasCreateAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasCreateAccess('InvalidObject__c');
        Test.stopTest();

        System.assertEquals(false, hasAccess, 'Should not have create access to invalid object');
    }

    @IsTest
    static void testHasUpdateAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasUpdateAccess('InvalidObject__c');
        Test.stopTest();

        System.assertEquals(false, hasAccess, 'Should not have update access to invalid object');
    }

    @IsTest
    static void testHasDeleteAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasDeleteAccess('InvalidObject__c');
        Test.stopTest();

        System.assertEquals(false, hasAccess, 'Should not have delete access to invalid object');
    }

    @IsTest
    static void testHasFieldReadAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldReadAccess('InvalidObject__c', 'Name');
        Test.stopTest();

        System.assertEquals(false, hasAccess, 'Should not have field access on invalid object');
    }

    @IsTest
    static void testHasFieldWriteAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldWriteAccess('InvalidObject__c', 'Name');
        Test.stopTest();

        System.assertEquals(false, hasAccess, 'Should not have field write access on invalid object');
    }

    @IsTest
    static void testStripInaccessibleFields_NullInput() {
        Test.startTest();
        List<SObject> stripped = ElaroSecurityUtils.stripInaccessibleFields(
            AccessType.READABLE,
            null
        );
        Test.stopTest();

        System.assertEquals(0, stripped.size(), 'Should return empty list for null input');
    }

    @IsTest
    static void testValidateFLSAccess_InvalidField() {
        List<String> fields = new List<String>{'Name', 'InvalidField__c'};

        Test.startTest();
        try {
            ElaroSecurityUtils.validateFLSAccess('Account', fields, false);
            System.assert(false, 'Should throw exception for invalid field');
        } catch (ElaroSecurityUtils.SecurityException e) {
            System.assert(e.getMessage().contains('Insufficient FLS access'),
                'Exception should mention FLS access');
        }
        Test.stopTest();
    }

    @IsTest
    static void testValidateFLSAccess_InvalidField_Write() {
        List<String> fields = new List<String>{'InvalidField__c'};

        Test.startTest();
        try {
            ElaroSecurityUtils.validateFLSAccess('Account', fields, true);
            System.assert(false, 'Should throw exception for invalid field write');
        } catch (ElaroSecurityUtils.SecurityException e) {
            System.assert(e.getMessage().contains('Insufficient FLS access'),
                'Exception should mention FLS access');
        }
        Test.stopTest();
    }

    @IsTest
    static void testValidateCRUDAccess_InvalidObject() {
        Test.startTest();
        try {
            ElaroSecurityUtils.validateCRUDAccess(
                'InvalidObject__c',
                ElaroSecurityUtils.DmlOperation.DML_INSERT
            );
            System.assert(false, 'Should throw exception for invalid object');
        } catch (ElaroSecurityUtils.SecurityException e) {
            System.assert(e.getMessage().contains('Insufficient CRUD access'),
                'Exception should mention CRUD access');
        }
        Test.stopTest();
    }

    @IsTest
    static void testStripInaccessibleFields_Updateable() {
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        List<SObject> stripped = ElaroSecurityUtils.stripInaccessibleFields(
            AccessType.UPDATABLE,
            accounts
        );
        Test.stopTest();

        System.assertEquals(1, stripped.size(), 'Should return updateable records');
    }

    @IsTest
    static void testStripInaccessibleFields_Creatable() {
        Account acc = new Account(Name = 'Test Strip Creatable');
        List<Account> accounts = new List<Account>{ acc };

        Test.startTest();
        List<SObject> stripped = ElaroSecurityUtils.stripInaccessibleFields(
            AccessType.CREATABLE,
            accounts
        );
        Test.stopTest();

        System.assertEquals(1, stripped.size(), 'Should return creatable records');
    }

    @IsTest
    static void testBuildSecureQuery_WithWhereClause() {
        String baseQuery = 'SELECT Id, Name FROM Account WHERE Name != null';

        Test.startTest();
        String secureQuery = ElaroSecurityUtils.buildSecureQuery(baseQuery);
        Test.stopTest();

        System.assert(secureQuery.contains('WITH SECURITY_ENFORCED'),
            'Should add WITH SECURITY_ENFORCED');
        System.assert(secureQuery.contains('WHERE Name != null'),
            'Should preserve WHERE clause');
    }

    @IsTest
    static void testBuildSecureQuery_LowerCase() {
        String baseQuery = 'SELECT Id FROM Account with security_enforced';

        Test.startTest();
        String secureQuery = ElaroSecurityUtils.buildSecureQuery(baseQuery);
        Test.stopTest();

        // Should handle case-insensitive removal
        Integer count = secureQuery.toLowerCase().split('with security_enforced', -1).size() - 1;
        System.assertEquals(1, count, 'Should have exactly one WITH SECURITY_ENFORCED');
    }

    @IsTest
    static void testSecurityException() {
        Test.startTest();
        try {
            throw new ElaroSecurityUtils.SecurityException('Test exception message');
        } catch (ElaroSecurityUtils.SecurityException e) {
            System.assertEquals('Test exception message', e.getMessage(),
                'Exception message should match');
        }
        Test.stopTest();
    }
}
