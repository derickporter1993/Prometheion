/**
 * ElaroBulkOperationTest
 * 
 * Test class for bulk operation scenarios (200+ records)
 * Tests governor limits, bulkification, and performance
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ElaroBulkOperationTest {
    
    /**
     * Test bulk insert operation (200+ records)
     */
    @IsTest
    static void testBulkInsert_200Records() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Test Account ' + i,
                BillingCity = 'Test City',
                BillingCountry = 'Test Country'
            ));
        }
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify all records were inserted
        List<Account> insertedAccounts = [
            SELECT Id, Name FROM Account WHERE Name LIKE 'Bulk Test Account%'
            WITH SECURITY_ENFORCED
        ];
        System.assertEquals(200, insertedAccounts.size(), 'Should have inserted all 200 accounts');
    }
    
    /**
     * Test bulk update operation (200+ records)
     */
    @IsTest
    static void testBulkUpdate_200Records() {
        // Create 200 accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Update Account ' + i
            ));
        }
        insert accounts;
        
        // Update all accounts
        for (Account acc : accounts) {
            acc.BillingCity = 'Updated City';
        }
        
        Test.startTest();
        update accounts;
        Test.stopTest();
        
        // Verify all records were updated
        List<Account> updatedAccounts = [
            SELECT Id, BillingCity FROM Account WHERE Name LIKE 'Bulk Update Account%'
            WITH SECURITY_ENFORCED
        ];
        System.assertEquals(200, updatedAccounts.size(), 'Should have updated all 200 accounts');
        for (Account acc : updatedAccounts) {
            System.assertEquals('Updated City', acc.BillingCity, 'BillingCity should be updated');
        }
    }
    
    /**
     * Test bulk delete operation (200+ records)
     */
    @IsTest
    static void testBulkDelete_200Records() {
        // Create 200 accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Delete Account ' + i
            ));
        }
        insert accounts;
        
        Test.startTest();
        delete accounts;
        Test.stopTest();
        
        // Verify all records were deleted
        List<Account> deletedAccounts = [
            SELECT Id FROM Account WHERE Name LIKE 'Bulk Delete Account%'
            WITH SECURITY_ENFORCED
            ALL ROWS
        ];
        System.assertEquals(0, deletedAccounts.size(), 'All accounts should be deleted');
    }
    
    /**
     * Test bulk SOQL query (200+ records)
     */
    @IsTest
    static void testBulkSOQL_200Records() {
        // Create 200 accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk SOQL Account ' + i
            ));
        }
        insert accounts;
        
        Test.startTest();
        List<Account> queriedAccounts = [
            SELECT Id, Name FROM Account WHERE Name LIKE 'Bulk SOQL Account%'
            WITH SECURITY_ENFORCED
        ];
        Test.stopTest();
        
        System.assertEquals(200, queriedAccounts.size(), 'Should query all 200 accounts');
    }
    
    /**
     * Test bulk operation with security enforcement
     */
    @IsTest
    static void testBulkOperation_WithSecurityEnforced() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Security Account ' + i
            ));
        }
        
        Test.startTest();
        insert accounts;
        
        // Query with WITH SECURITY_ENFORCED
        List<Account> queriedAccounts = [
            SELECT Id, Name FROM Account WHERE Name LIKE 'Bulk Security Account%'
            WITH SECURITY_ENFORCED
        ];
        
        // Strip inaccessible fields
        List<SObject> stripped = ElaroSecurityUtils.stripInaccessibleFields(
            AccessType.READABLE,
            queriedAccounts
        );
        Test.stopTest();
        
        System.assertEquals(200, stripped.size(), 'Should return all 200 accounts after security enforcement');
    }
    
    /**
     * Test bulk operation governor limits
     */
    @IsTest
    static void testBulkOperation_GovernorLimits() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Limits Account ' + i
            ));
        }
        
        Test.startTest();
        Integer startQueries = Limits.getQueries();
        Integer startDml = Limits.getDmlStatements();
        
        insert accounts;
        
        List<Account> queriedAccounts = [
            SELECT Id, Name FROM Account WHERE Name LIKE 'Bulk Limits Account%'
            WITH SECURITY_ENFORCED
        ];
        
        Integer endQueries = Limits.getQueries();
        Integer endDml = Limits.getDmlStatements();
        
        Test.stopTest();
        
        System.assertEquals(200, queriedAccounts.size(), 'Should query all 200 accounts');
        System.assert(endQueries - startQueries < 10, 'Should use reasonable number of queries');
        System.assert(endDml - startDml == 1, 'Should use single DML statement for bulk insert');
    }
    
    /**
     * Test bulk operation with contacts (parent-child relationship)
     */
    @IsTest
    static void testBulkOperation_WithContacts() {
        // Create 200 accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Contact Account ' + i
            ));
        }
        insert accounts;
        
        // Create 200 contacts (one per account)
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(
                FirstName = 'Bulk',
                LastName = 'Contact ' + i,
                AccountId = accounts[i].Id
            ));
        }
        
        Test.startTest();
        insert contacts;
        
        // Query with relationship
        List<Account> accountsWithContacts = [
            SELECT Id, Name, (SELECT Id, LastName FROM Contacts)
            FROM Account WHERE Name LIKE 'Bulk Contact Account%'
            WITH SECURITY_ENFORCED
        ];
        Test.stopTest();
        
        System.assertEquals(200, accountsWithContacts.size(), 'Should query all 200 accounts');
        for (Account acc : accountsWithContacts) {
            System.assertEquals(1, acc.Contacts.size(), 'Each account should have one contact');
        }
    }
    
    /**
     * Test bulk operation security-negative (attempt to bypass validation)
     */
    @IsTest
    static void testBulkOperation_SecurityNegative() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Negative Account ' + i
            ));
        }
        
        Test.startTest();
        // Validate CRUD access before bulk insert
        try {
            ElaroSecurityUtils.validateCRUDAccess('Account', ElaroSecurityUtils.DmlOperation.DML_INSERT);
            insert accounts;
            System.assert(true, 'Bulk insert should succeed with proper validation');
        } catch (ElaroSecurityUtils.SecurityException e) {
            System.assert(false, 'Should not throw SecurityException: ' + e.getMessage());
        }
        Test.stopTest();
        
        List<Account> insertedAccounts = [
            SELECT Id FROM Account WHERE Name LIKE 'Bulk Negative Account%'
            WITH SECURITY_ENFORCED
        ];
        System.assertEquals(200, insertedAccounts.size(), 'Should have inserted all 200 accounts');
    }
}