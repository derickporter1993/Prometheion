/**
 * PrometheionSecurityUtilsTest
 * 
 * Test class for PrometheionSecurityUtils security utility
 * 
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class PrometheionSecurityUtilsTest {
    
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
        Boolean hasAccess = PrometheionSecurityUtils.hasReadAccess('Account');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have read access to Account');
    }
    
    @IsTest
    static void testHasCreateAccess() {
        Test.startTest();
        Boolean hasAccess = PrometheionSecurityUtils.hasCreateAccess('Account');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have create access to Account');
    }
    
    @IsTest
    static void testHasUpdateAccess() {
        Test.startTest();
        Boolean hasAccess = PrometheionSecurityUtils.hasUpdateAccess('Account');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have update access to Account');
    }
    
    @IsTest
    static void testHasDeleteAccess() {
        Test.startTest();
        Boolean hasAccess = PrometheionSecurityUtils.hasDeleteAccess('Account');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have delete access to Account');
    }
    
    @IsTest
    static void testHasFieldReadAccess() {
        Test.startTest();
        Boolean hasAccess = PrometheionSecurityUtils.hasFieldReadAccess('Account', 'Name');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have read access to Account.Name');
    }
    
    @IsTest
    static void testHasFieldWriteAccess() {
        Test.startTest();
        Boolean hasAccess = PrometheionSecurityUtils.hasFieldWriteAccess('Account', 'Name');
        Test.stopTest();
        
        System.assertEquals(true, hasAccess, 'Should have write access to Account.Name');
    }
    
    @IsTest
    static void testHasFieldReadAccess_InvalidField() {
        Test.startTest();
        Boolean hasAccess = PrometheionSecurityUtils.hasFieldReadAccess('Account', 'InvalidField__c');
        Test.stopTest();
        
        System.assertEquals(false, hasAccess, 'Should not have access to invalid field');
    }
    
    @IsTest
    static void testHasFieldWriteAccess_InvalidField() {
        Test.startTest();
        Boolean hasAccess = PrometheionSecurityUtils.hasFieldWriteAccess('Account', 'InvalidField__c');
        Test.stopTest();
        
        System.assertEquals(false, hasAccess, 'Should not have write access to invalid field');
    }
    
    @IsTest
    static void testStripInaccessibleFields() {
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1];
        
        Test.startTest();
        List<SObject> stripped = PrometheionSecurityUtils.stripInaccessibleFields(
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
        List<SObject> stripped = PrometheionSecurityUtils.stripInaccessibleFields(
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
            PrometheionSecurityUtils.validateCRUDAccess(
                'Account',
                PrometheionSecurityUtils.DmlOperation.DML_INSERT
            );
            System.assert(true, 'Should not throw exception for valid insert access');
        } catch (PrometheionSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateCRUDAccess_Update() {
        Test.startTest();
        try {
            PrometheionSecurityUtils.validateCRUDAccess(
                'Account',
                PrometheionSecurityUtils.DmlOperation.DML_UPDATE
            );
            System.assert(true, 'Should not throw exception for valid update access');
        } catch (PrometheionSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateCRUDAccess_Delete() {
        Test.startTest();
        try {
            PrometheionSecurityUtils.validateCRUDAccess(
                'Account',
                PrometheionSecurityUtils.DmlOperation.DML_DELETE
            );
            System.assert(true, 'Should not throw exception for valid delete access');
        } catch (PrometheionSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateCRUDAccess_Upsert() {
        Test.startTest();
        try {
            PrometheionSecurityUtils.validateCRUDAccess(
                'Account',
                PrometheionSecurityUtils.DmlOperation.DML_UPSERT
            );
            System.assert(true, 'Should not throw exception for valid upsert access');
        } catch (PrometheionSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateFLSAccess_Read() {
        List<String> fields = new List<String>{'Name', 'BillingCity'};
        
        Test.startTest();
        try {
            PrometheionSecurityUtils.validateFLSAccess('Account', fields, false);
            System.assert(true, 'Should not throw exception for valid FLS read access');
        } catch (PrometheionSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateFLSAccess_Write() {
        List<String> fields = new List<String>{'Name', 'BillingCity'};
        
        Test.startTest();
        try {
            PrometheionSecurityUtils.validateFLSAccess('Account', fields, true);
            System.assert(true, 'Should not throw exception for valid FLS write access');
        } catch (PrometheionSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testBuildSecureQuery() {
        String baseQuery = 'SELECT Id, Name FROM Account';
        
        Test.startTest();
        String secureQuery = PrometheionSecurityUtils.buildSecureQuery(baseQuery);
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
        String secureQuery = PrometheionSecurityUtils.buildSecureQuery(baseQuery);
        Test.stopTest();
        
        // Should only have one WITH SECURITY_ENFORCED
        Integer count = secureQuery.split('WITH SECURITY_ENFORCED', -1).size() - 1;
        System.assertEquals(1, count, 'Should have exactly one WITH SECURITY_ENFORCED');
    }
}
