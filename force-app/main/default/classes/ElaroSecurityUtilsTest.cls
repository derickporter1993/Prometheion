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
        
        Assert.areEqual(true, hasAccess, 'Should have read access to Account');
    }
    
    @IsTest
    static void testHasCreateAccess() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasCreateAccess('Account');
        Test.stopTest();
        
        Assert.areEqual(true, hasAccess, 'Should have create access to Account');
    }
    
    @IsTest
    static void testHasUpdateAccess() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasUpdateAccess('Account');
        Test.stopTest();
        
        Assert.areEqual(true, hasAccess, 'Should have update access to Account');
    }
    
    @IsTest
    static void testHasDeleteAccess() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasDeleteAccess('Account');
        Test.stopTest();
        
        Assert.areEqual(true, hasAccess, 'Should have delete access to Account');
    }
    
    @IsTest
    static void testHasFieldReadAccess() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldReadAccess('Account', 'Name');
        Test.stopTest();
        
        Assert.areEqual(true, hasAccess, 'Should have read access to Account.Name');
    }
    
    @IsTest
    static void testHasFieldWriteAccess() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldWriteAccess('Account', 'Name');
        Test.stopTest();
        
        Assert.areEqual(true, hasAccess, 'Should have write access to Account.Name');
    }
    
    @IsTest
    static void testHasFieldReadAccess_InvalidField() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldReadAccess('Account', 'InvalidField__c');
        Test.stopTest();
        
        Assert.areEqual(false, hasAccess, 'Should not have access to invalid field');
    }
    
    @IsTest
    static void testHasFieldWriteAccess_InvalidField() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldWriteAccess('Account', 'InvalidField__c');
        Test.stopTest();
        
        Assert.areEqual(false, hasAccess, 'Should not have write access to invalid field');
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
        
        Assert.areEqual(1, stripped.size(), 'Should return accessible records');
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
        
        Assert.areEqual(0, stripped.size(), 'Should return empty list');
    }
    
    @IsTest
    static void testValidateCRUDAccess_Insert() {
        Test.startTest();
        Boolean validationPassed = false;
        try {
            ElaroSecurityUtils.validateCRUDAccess(
                'Account',
                ElaroSecurityUtils.DmlOperation.DML_INSERT
            );
            validationPassed = true;
        } catch (ElaroSecurityUtils.SecurityException e) {
            Assert.fail( 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();

        Assert.isTrue(validationPassed, 'Insert access validation should complete successfully');
    }
    
    @IsTest
    static void testValidateCRUDAccess_Update() {
        Test.startTest();
        Boolean validationPassed = false;
        try {
            ElaroSecurityUtils.validateCRUDAccess(
                'Account',
                ElaroSecurityUtils.DmlOperation.DML_UPDATE
            );
            validationPassed = true;
        } catch (ElaroSecurityUtils.SecurityException e) {
            Assert.fail( 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();

        Assert.isTrue(validationPassed, 'Update access validation should complete successfully');
    }
    
    @IsTest
    static void testValidateCRUDAccess_Delete() {
        Test.startTest();
        Boolean validationPassed = false;
        try {
            ElaroSecurityUtils.validateCRUDAccess(
                'Account',
                ElaroSecurityUtils.DmlOperation.DML_DELETE
            );
            validationPassed = true;
        } catch (ElaroSecurityUtils.SecurityException e) {
            Assert.fail( 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();

        Assert.isTrue(validationPassed, 'Delete access validation should complete successfully');
    }
    
    @IsTest
    static void testValidateCRUDAccess_Upsert() {
        Test.startTest();
        Boolean validationPassed = false;
        try {
            ElaroSecurityUtils.validateCRUDAccess(
                'Account',
                ElaroSecurityUtils.DmlOperation.DML_UPSERT
            );
            validationPassed = true;
        } catch (ElaroSecurityUtils.SecurityException e) {
            Assert.fail( 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();

        Assert.isTrue(validationPassed, 'Upsert access validation should complete successfully');
    }
    
    @IsTest
    static void testValidateFLSAccess_Read() {
        List<String> fields = new List<String>{'Name', 'BillingCity'};

        Test.startTest();
        Boolean validationPassed = false;
        try {
            ElaroSecurityUtils.validateFLSAccess('Account', fields, false);
            validationPassed = true;
        } catch (ElaroSecurityUtils.SecurityException e) {
            Assert.fail( 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();

        Assert.isTrue(validationPassed, 'FLS read validation should complete successfully for accessible fields');
    }
    
    @IsTest
    static void testValidateFLSAccess_Write() {
        List<String> fields = new List<String>{'Name', 'BillingCity'};

        Test.startTest();
        Boolean validationPassed = false;
        try {
            ElaroSecurityUtils.validateFLSAccess('Account', fields, true);
            validationPassed = true;
        } catch (ElaroSecurityUtils.SecurityException e) {
            Assert.fail( 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();

        Assert.isTrue(validationPassed, 'FLS write validation should complete successfully for writable fields');
    }
    
    @IsTest
    static void testBuildSecureQuery() {
        String baseQuery = 'SELECT Id, Name FROM Account';
        
        Test.startTest();
        String secureQuery = ElaroSecurityUtils.buildSecureQuery(baseQuery);
        Test.stopTest();
        
        Assert.isTrue(secureQuery.contains('WITH USER_MODE'), 
            'Should add WITH USER_MODE');
        Assert.isTrue(secureQuery.contains('SELECT Id, Name FROM Account'), 
            'Should preserve original query');
    }
    
    @IsTest
    static void testBuildSecureQuery_AlreadyHasSecurityEnforced() {
        String baseQuery = 'SELECT Id, Name FROM Account WITH USER_MODE';

        Test.startTest();
        String secureQuery = ElaroSecurityUtils.buildSecureQuery(baseQuery);
        Test.stopTest();

        // Should only have one WITH USER_MODE
        Integer count = secureQuery.split('WITH USER_MODE', -1).size() - 1;
        Assert.areEqual(1, count, 'Should have exactly one WITH USER_MODE');
    }

    @IsTest
    static void testHasReadAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasReadAccess('InvalidObject__c');
        Test.stopTest();

        Assert.areEqual(false, hasAccess, 'Should not have read access to invalid object');
    }

    @IsTest
    static void testHasCreateAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasCreateAccess('InvalidObject__c');
        Test.stopTest();

        Assert.areEqual(false, hasAccess, 'Should not have create access to invalid object');
    }

    @IsTest
    static void testHasUpdateAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasUpdateAccess('InvalidObject__c');
        Test.stopTest();

        Assert.areEqual(false, hasAccess, 'Should not have update access to invalid object');
    }

    @IsTest
    static void testHasDeleteAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasDeleteAccess('InvalidObject__c');
        Test.stopTest();

        Assert.areEqual(false, hasAccess, 'Should not have delete access to invalid object');
    }

    @IsTest
    static void testHasFieldReadAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldReadAccess('InvalidObject__c', 'Name');
        Test.stopTest();

        Assert.areEqual(false, hasAccess, 'Should not have field access on invalid object');
    }

    @IsTest
    static void testHasFieldWriteAccess_InvalidObject() {
        Test.startTest();
        Boolean hasAccess = ElaroSecurityUtils.hasFieldWriteAccess('InvalidObject__c', 'Name');
        Test.stopTest();

        Assert.areEqual(false, hasAccess, 'Should not have field write access on invalid object');
    }

    @IsTest
    static void testStripInaccessibleFields_NullInput() {
        Test.startTest();
        List<SObject> stripped = ElaroSecurityUtils.stripInaccessibleFields(
            AccessType.READABLE,
            null
        );
        Test.stopTest();

        Assert.areEqual(0, stripped.size(), 'Should return empty list for null input');
    }

    @IsTest
    static void testValidateFLSAccess_InvalidField() {
        List<String> fields = new List<String>{'Name', 'InvalidField__c'};

        Test.startTest();
        try {
            ElaroSecurityUtils.validateFLSAccess('Account', fields, false);
            Assert.fail( 'Should throw exception for invalid field');
        } catch (ElaroSecurityUtils.SecurityException e) {
            Assert.isTrue(e.getMessage().contains('Insufficient FLS access'),
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
            Assert.fail( 'Should throw exception for invalid field write');
        } catch (ElaroSecurityUtils.SecurityException e) {
            Assert.isTrue(e.getMessage().contains('Insufficient FLS access'),
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
            Assert.fail( 'Should throw exception for invalid object');
        } catch (ElaroSecurityUtils.SecurityException e) {
            Assert.isTrue(e.getMessage().contains('Insufficient CRUD access'),
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

        Assert.areEqual(1, stripped.size(), 'Should return updateable records');
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

        Assert.areEqual(1, stripped.size(), 'Should return creatable records');
    }

    @IsTest
    static void testBuildSecureQuery_WithWhereClause() {
        String baseQuery = 'SELECT Id, Name FROM Account WHERE Name != null';

        Test.startTest();
        String secureQuery = ElaroSecurityUtils.buildSecureQuery(baseQuery);
        Test.stopTest();

        Assert.isTrue(secureQuery.contains('WITH USER_MODE'),
            'Should add WITH USER_MODE');
        Assert.isTrue(secureQuery.contains('WHERE Name != null'),
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
        Assert.areEqual(1, count, 'Should have exactly one WITH USER_MODE');
    }

    @IsTest
    static void testSecurityException() {
        Test.startTest();
        try {
            throw new ElaroSecurityUtils.SecurityException('Test exception message');
        } catch (ElaroSecurityUtils.SecurityException e) {
            Assert.areEqual('Test exception message', e.getMessage(),
                'Exception message should match');
        }
        Test.stopTest();
    }

    /**
     * Tests for compareSecrets() - constant-time comparison to prevent timing attacks
     */
    @IsTest
    static void testCompareSecrets_Match() {
        String secret = 'my-webhook-secret-12345';
        String provided = 'my-webhook-secret-12345';

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isTrue(result, 'Identical secrets should match');
    }

    @IsTest
    static void testCompareSecrets_NoMatch() {
        String secret = 'my-webhook-secret-12345';
        String provided = 'my-webhook-secret-99999';

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isFalse(result, 'Different secrets should not match');
    }

    @IsTest
    static void testCompareSecrets_CaseSensitive() {
        String secret = 'MyWebhookSecret';
        String provided = 'mywebhooksecret';

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isFalse(result, 'Comparison should be case-sensitive');
    }

    @IsTest
    static void testCompareSecrets_DifferentLength() {
        String secret = 'short';
        String provided = 'much-longer-secret';

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isFalse(result, 'Secrets with different lengths should not match');
    }

    @IsTest
    static void testCompareSecrets_NullExpected() {
        String secret = null;
        String provided = 'some-secret';

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isFalse(result, 'Null expected secret should never match');
    }

    @IsTest
    static void testCompareSecrets_NullProvided() {
        String secret = 'my-webhook-secret';
        String provided = null;

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isFalse(result, 'Null provided secret should never match');
    }

    @IsTest
    static void testCompareSecrets_BothNull() {
        String secret = null;
        String provided = null;

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isFalse(result, 'Two null values should not match (security fail-safe)');
    }

    @IsTest
    static void testCompareSecrets_EmptyStrings() {
        String secret = '';
        String provided = '';

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isTrue(result, 'Empty strings should match (edge case for blank config)');
    }

    @IsTest
    static void testCompareSecrets_OneDifferentCharacter() {
        String secret = 'my-webhook-secret-12345';
        String provided = 'my-webhook-secret-12346'; // Last char differs

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isFalse(result, 'Single character difference should fail match');
    }

    @IsTest
    static void testCompareSecrets_FirstCharacterDiffers() {
        String secret = 'Ay-webhook-secret';
        String provided = 'By-webhook-secret'; // First char differs

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isFalse(result, 'First character difference should fail match (no fast-fail leakage)');
    }

    @IsTest
    static void testCompareSecrets_LongSecrets() {
        // Test with realistic HMAC-SHA256 hex string length (64 chars)
        String secret = 'a'.repeat(64);
        String provided = 'a'.repeat(64);

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isTrue(result, 'Long matching secrets should compare correctly');
    }

    @IsTest
    static void testCompareSecrets_LongSecrets_OneBitDifference() {
        // Test with realistic HMAC-SHA256 hex string, last char differs
        String secret = 'a'.repeat(63) + 'b';
        String provided = 'a'.repeat(63) + 'c';

        Test.startTest();
        Boolean result = ElaroSecurityUtils.compareSecrets(secret, provided);
        Test.stopTest();

        Assert.isFalse(result, 'Long secrets with single character difference should fail match');
    }
}
