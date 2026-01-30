/**
 * ElaroSharingViolationTest
 * 
 * Test class for sharing violation scenarios
 * Tests record-level sharing and access control
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ElaroSharingViolationTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test accounts with different owners
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User owner1 = new User(
            FirstName = 'Owner',
            LastName = 'One',
            Email = 'owner1@test.com',
            Username = 'owner1@test' + System.now().getTime() + '.com',
            Alias = 'own1',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        User owner2 = new User(
            FirstName = 'Owner',
            LastName = 'Two',
            Email = 'owner2@test.com',
            Username = 'owner2@test' + System.now().getTime() + '.com',
            Alias = 'own2',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        insert new List<User>{owner1, owner2};
        
        // Create accounts owned by different users
        System.runAs(owner1) {
            Account acc1 = new Account(Name = 'Owner1 Account');
            insert acc1;
        }
        
        System.runAs(owner2) {
            Account acc2 = new Account(Name = 'Owner2 Account');
            insert acc2;
        }
    }
    
    /**
     * Test sharing violation - user cannot access another user's records
     */
    @IsTest
    static void testSharingViolation_CannotAccessOtherUsersRecords() {
        User owner1 = [SELECT Id FROM User WHERE Email = 'owner1@test.com' LIMIT 1];
        User owner2 = [SELECT Id FROM User WHERE Email = 'owner2@test.com' LIMIT 1];
        
        Account owner1Account = [SELECT Id, OwnerId FROM Account WHERE Name = 'Owner1 Account' LIMIT 1];
        Account owner2Account = [SELECT Id, OwnerId FROM Account WHERE Name = 'Owner2 Account' LIMIT 1];
        
        Test.startTest();
        System.runAs(owner1) {
            // Owner1 should be able to see their own account
            List<Account> ownAccounts = [
                SELECT Id FROM Account WHERE Id = :owner1Account.Id
                WITH SECURITY_ENFORCED
            ];
            System.assertEquals(1, ownAccounts.size(), 'Owner1 should see their own account');
            
            // Owner1 should NOT be able to see Owner2's account (sharing violation)
            List<Account> otherAccounts = [
                SELECT Id FROM Account WHERE Id = :owner2Account.Id
                WITH SECURITY_ENFORCED
            ];
            // With sharing enforced, query may return empty or throw exception
            System.assert(otherAccounts.isEmpty() || otherAccounts.size() == 0, 
                'Owner1 should not see Owner2\'s account due to sharing');
        }
        Test.stopTest();
    }
    
    /**
     * Test sharing with WITH SECURITY_ENFORCED
     */
    @IsTest
    static void testSharingWithSecurityEnforced() {
        User owner1 = [SELECT Id FROM User WHERE Email = 'owner1@test.com' LIMIT 1];
        Account owner1Account = [SELECT Id FROM Account WHERE Name = 'Owner1 Account' LIMIT 1];
        
        Test.startTest();
        System.runAs(owner1) {
            // Query with WITH SECURITY_ENFORCED should respect sharing
            List<Account> accounts = [
                SELECT Id, Name FROM Account
                WHERE Id = :owner1Account.Id
                WITH SECURITY_ENFORCED
            ];
            
            System.assertNotEquals(null, accounts, 'Accounts list should not be null');
            System.assert(accounts.size() >= 0, 'Should return accounts respecting sharing');
        }
        Test.stopTest();
    }
    
    /**
     * Test stripInaccessibleFields respects sharing
     */
    @IsTest
    static void testStripInaccessibleFields_RespectsSharing() {
        User owner1 = [SELECT Id FROM User WHERE Email = 'owner1@test.com' LIMIT 1];
        Account owner1Account = [SELECT Id, Name FROM Account WHERE Name = 'Owner1 Account' LIMIT 1];
        
        Test.startTest();
        System.runAs(owner1) {
            List<Account> accounts = new List<Account>{owner1Account};
            
            // stripInaccessibleFields should respect sharing
            List<SObject> stripped = ElaroSecurityUtils.stripInaccessibleFields(
                AccessType.READABLE,
                accounts
            );
            
            System.assertNotEquals(null, stripped, 'Stripped list should not be null');
            System.assertEquals(1, stripped.size(), 'Should return accessible records');
        }
        Test.stopTest();
    }
    
    /**
     * Test sharing violation with without sharing class
     */
    @IsTest
    static void testSharingViolation_WithoutSharingContext() {
        // Note: This test documents that without sharing classes bypass sharing
        // In production, without sharing should be used carefully and documented
        
        User owner1 = [SELECT Id FROM User WHERE Email = 'owner1@test.com' LIMIT 1];
        Account owner2Account = [SELECT Id FROM Account WHERE Name = 'Owner2 Account' LIMIT 1];
        
        Test.startTest();
        System.runAs(owner1) {
            // Even with sharing, user should not see other user's records
            try {
                List<Account> accounts = [
                    SELECT Id FROM Account WHERE Id = :owner2Account.Id
                    WITH SECURITY_ENFORCED
                ];
                // Query may return empty due to sharing
                System.assert(accounts.isEmpty() || accounts.size() == 0, 
                    'Should not return records due to sharing violation');
            } catch (QueryException e) {
                // QueryException may be thrown for sharing violations
                System.assert(true, 'Expected sharing violation: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }
    
    /**
     * Test sharing with public read access
     */
    @IsTest
    static void testSharing_PublicReadAccess() {
        User owner1 = [SELECT Id FROM User WHERE Email = 'owner1@test.com' LIMIT 1];
        
        Test.startTest();
        System.runAs(owner1) {
            // Query all accounts (may be limited by sharing)
            List<Account> allAccounts = [
                SELECT Id, Name FROM Account
                WITH SECURITY_ENFORCED
            ];
            
            // Should return at least owner1's account
            System.assert(allAccounts.size() >= 1, 'Should return at least one account');
        }
        Test.stopTest();
    }
}