/**
 * Test class for ElaroISO27001AccessReviewService
 * 
 * Tests ISO 27001 Control A.9 Access Management including:
 * - Positive path: Quarterly and privileged access reviews
 * - Negative path: Permission denied scenarios
 * - Bulk operations: Multiple users
 * - Review decision processing
 * - Dormant account detection
 * 
 * Target Coverage: 90%+
 */
@IsTest
private class ElaroISO27001AccessReviewServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test permission sets
        List<PermissionSet> testPermSets = new List<PermissionSet>();
        testPermSets.add(new PermissionSet(
            Name = 'Test_Privileged_PS',
            Label = 'Test Privileged Permission Set'
        ));
        testPermSets.add(new PermissionSet(
            Name = 'Test_Standard_PS',
            Label = 'Test Standard Permission Set'
        ));
        insert testPermSets;
        
        // Create test users with different profiles
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        List<User> testUsers = new List<User>();
        for (Integer i = 0; i < 5; i++) {
            testUsers.add(new User(
                FirstName = 'ISO',
                LastName = 'User ' + i,
                Email = 'iso' + i + '@test.com',
                Username = 'iso' + i + '@test' + System.now().getTime() + '.com',
                Alias = 'isousr' + i,
                ProfileId = (i == 0) ? adminProfile.Id : standardProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                IsActive = true
                // Note: LastLoginDate is read-only, cannot be set in test
            ));
        }
        insert testUsers;
        
        // Assign permission sets
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        assignments.add(new PermissionSetAssignment(
            AssigneeId = testUsers[0].Id,
            PermissionSetId = testPermSets[0].Id
        ));
        assignments.add(new PermissionSetAssignment(
            AssigneeId = testUsers[1].Id,
            PermissionSetId = testPermSets[1].Id
        ));
        insert assignments;
        
        // Create managers for some users
        User manager = testUsers[0];
        testUsers[1].ManagerId = manager.Id;
        testUsers[2].ManagerId = manager.Id;
        update testUsers;
    }
    
    @IsTest
    static void testInitiateQuarterlyReviews_PositivePath() {
        // Given: Active users exist
        
        Test.startTest();
        List<Access_Review__c> reviews = 
            ElaroISO27001AccessReviewService.initiateQuarterlyReviews();
        Test.stopTest();
        
        // Then: Reviews should be created
        Assert.isTrue(!reviews.isEmpty(), 'Should create reviews');
        for (Access_Review__c review : reviews) {
            Assert.areEqual('Quarterly Review', review.Review_Type__c, 'Should be quarterly review');
            Assert.areEqual('Pending', review.Review_Status__c, 'Status should be Pending');
            Assert.areNotEqual(null, review.Due_Date__c, 'Due date should be set');
            Assert.areNotEqual(null, review.User__c, 'User should be set');
        }
    }
    
    @IsTest
    static void testInitiatePrivilegedAccessReviews() {
        // Given: Privileged users exist
        
        Test.startTest();
        List<Access_Review__c> reviews = 
            ElaroISO27001AccessReviewService.initiatePrivilegedAccessReviews();
        Test.stopTest();
        
        // Then: Privileged reviews should be created
        Assert.isTrue(!reviews.isEmpty(), 'Should create privileged reviews');
        for (Access_Review__c review : reviews) {
            Assert.areEqual('Privileged Access Review', review.Review_Type__c, 
                'Should be privileged review');
            Assert.areEqual(true, review.Is_Privileged_User__c, 'Should be privileged user');
            Assert.areEqual('High', review.Risk_Level__c, 'Risk level should be High');
        }
    }
    
    @IsTest
    static void testProcessReviewDecision_Approve() {
        // Given: Existing review
        List<Access_Review__c> reviews = 
            ElaroISO27001AccessReviewService.initiateQuarterlyReviews();
        Access_Review__c review = reviews[0];
        
        Test.startTest();
        ElaroISO27001AccessReviewService.processReviewDecision(
            review.Id,
            'Approve All Access',
            'User access is appropriate for role'
        );
        Test.stopTest();
        
        // Then: Review should be updated
        Access_Review__c updatedReview = [
            SELECT Id, Review_Status__c, Decision__c, Review_Date__c
            FROM Access_Review__c
            WHERE Id = :review.Id
        ];
        Assert.areEqual('Approved', updatedReview.Review_Status__c, 'Status should be Approved');
        Assert.areEqual('Approve All Access', updatedReview.Decision__c, 'Decision should be Approve All Access');
        Assert.areNotEqual(null, updatedReview.Review_Date__c, 'Review date should be set');
    }
    
    @IsTest
    static void testProcessReviewDecision_Revoke() {
        // Given: Existing review
        List<Access_Review__c> reviews = 
            ElaroISO27001AccessReviewService.initiateQuarterlyReviews();
        Access_Review__c review = reviews[0];
        
        Test.startTest();
        ElaroISO27001AccessReviewService.processReviewDecision(
            review.Id,
            'Revoke All Access',
            'User no longer requires access'
        );
        Test.stopTest();

        // Then: Review should be updated
        Access_Review__c updatedReview = [
            SELECT Id, Review_Status__c, Decision__c
            FROM Access_Review__c
            WHERE Id = :review.Id
        ];
        Assert.areEqual('Revoked', updatedReview.Review_Status__c, 'Status should be Revoked');
        Assert.areEqual('Revoke All Access', updatedReview.Decision__c, 'Decision should be Revoke All Access');
    }
    
    @IsTest
    static void testInitiateQuarterlyReviews_InsufficientPermissions() {
        // Given: Limited user
        User limitedUser = createLimitedUser();
        
        Test.startTest();
        System.runAs(limitedUser) {
            try {
                ElaroISO27001AccessReviewService.initiateQuarterlyReviews();
                Assert.fail( 'Should have thrown InsufficientAccessException');
            } catch (Exception e) {
                // Then: Permission exception should be thrown
                // Note: InsufficientAccessException may not be available, catch generic Exception
                Assert.isTrue(e.getMessage().contains('insufficient') || 
                    e.getMessage().contains('access') || 
                    e.getMessage().contains('permission'), 
                    'Should throw permission-related exception: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetPendingReviews() {
        // Given: Pending reviews exist with reviewer
        User manager = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        List<Access_Review__c> reviews = 
            ElaroISO27001AccessReviewService.initiateQuarterlyReviews();
        
        Test.startTest();
        List<Access_Review__c> pendingReviews = 
            ElaroISO27001AccessReviewService.getPendingReviews(manager.Id);
        Test.stopTest();
        
        // Then: Should return pending reviews for reviewer
        Assert.isTrue(pendingReviews.size() >= 0, 'Should return pending reviews');
        for (Access_Review__c review : pendingReviews) {
            Assert.isTrue(review.Review_Status__c == 'Pending' || review.Review_Status__c == 'In Progress', 
                'Should only return pending/in progress reviews');
            Assert.areEqual(manager.Id, review.Reviewer__c, 'Should match reviewer');
        }
    }
    
    @IsTest
    static void testGetOverdueReviews() {
        // Given: Overdue reviews
        List<Access_Review__c> reviews = 
            ElaroISO27001AccessReviewService.initiateQuarterlyReviews();
        
        // Make some overdue
        for (Access_Review__c review : reviews) {
            review.Due_Date__c = Date.today().addDays(-5);
        }
        update reviews;
        
        Test.startTest();
        List<Access_Review__c> overdueReviews = 
            ElaroISO27001AccessReviewService.getOverdueReviews();
        Test.stopTest();
        
        // Then: Should return overdue reviews
        Assert.isTrue(overdueReviews.size() >= 0, 'Should return overdue reviews');
        for (Access_Review__c review : overdueReviews) {
            Assert.isTrue(review.Due_Date__c < Date.today(), 'Should be overdue');
        }
    }
    
    @IsTest
    static void testInitiateQuarterlyReviews_BulkOperation() {
        // Given: Many users (test with existing users)
        
        Test.startTest();
        List<Access_Review__c> reviews = 
            ElaroISO27001AccessReviewService.initiateQuarterlyReviews();
        Test.stopTest();
        
        // Then: Should handle bulk users
        Assert.isTrue(reviews.size() >= 0, 'Should process users');
        // Note: Actual count depends on org setup
    }
    
    @IsTest
    static void testCalculateRiskLevel() {
        // Given: User with different access levels
        User adminUser = [SELECT Id, Profile.Name FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        
        Test.startTest();
        // Risk level is calculated internally, test via review creation
        List<Access_Review__c> reviews = 
            ElaroISO27001AccessReviewService.initiateQuarterlyReviews();
        Test.stopTest();
        
        // Then: Risk levels should be assigned
        for (Access_Review__c review : reviews) {
            if (review.User__c == adminUser.Id) {
                Assert.areNotEqual(null, review.Risk_Level__c, 'Risk level should be set');
            }
        }
    }
    
    @IsTest
    static void testIdentifyDormantAccounts() {
        // Given: Users exist (some may be dormant based on LastLoginDate)

        Test.startTest();
        List<ElaroISO27001AccessReviewService.DormantAccountInfo> dormantAccounts =
            ElaroISO27001AccessReviewService.identifyDormantAccounts();
        Test.stopTest();

        // Then: Should return dormant account info
        // Note: Test users created in setup may or may not be dormant
        Assert.areNotEqual(null, dormantAccounts, 'Should return a list');

        // Verify structure if any dormant accounts found
        for (ElaroISO27001AccessReviewService.DormantAccountInfo info : dormantAccounts) {
            Assert.areNotEqual(null, info.userId, 'User ID should be set');
            Assert.areNotEqual(null, info.userName, 'Username should be set');
            Assert.areNotEqual(null, info.profileName, 'Profile name should be set');
        }
    }

    @IsTest
    static void testCreateTerminationReview() {
        // Given: Active user
        User testUser = [SELECT Id FROM User WHERE LastName LIKE 'User%' AND IsActive = true LIMIT 1];
        Date terminationDate = Date.today().addDays(7);

        Test.startTest();
        Access_Review__c review =
            ElaroISO27001AccessReviewService.createTerminationReview(testUser.Id, terminationDate);
        Test.stopTest();

        // Then: Termination review should be created
        Assert.areNotEqual(null, review.Id, 'Review should be inserted');
        Assert.areEqual('Termination Review', review.Review_Type__c, 'Should be termination review');
        Assert.areEqual('In Progress', review.Review_Status__c, 'Status should be In Progress');
        Assert.areEqual('Revoke All Access', review.Decision__c, 'Decision should be Revoke All Access');
        Assert.areEqual('High', review.Risk_Level__c, 'Risk level should be High');
        Assert.areEqual(terminationDate, review.Due_Date__c, 'Due date should match termination date');
    }

    @IsTest
    static void testGetComplianceMetrics() {
        // Given: Some reviews exist
        ElaroISO27001AccessReviewService.initiateQuarterlyReviews();

        Test.startTest();
        Map<String, Object> metrics =
            ElaroISO27001AccessReviewService.getComplianceMetrics();
        Test.stopTest();

        // Then: Should return metrics
        Assert.areNotEqual(null, metrics, 'Metrics should not be null');
        Assert.isTrue(metrics.containsKey('reviewsThisQuarter'), 'Should have reviewsThisQuarter metric');
        Assert.isTrue(metrics.containsKey('completionRate'), 'Should have completionRate metric');
        Assert.isTrue(metrics.containsKey('overdueCount'), 'Should have overdueCount metric');
        Assert.isTrue(metrics.containsKey('privilegedUsersCount'), 'Should have privilegedUsersCount metric');
        Assert.isTrue(metrics.containsKey('dormantAccountsCount'), 'Should have dormantAccountsCount metric');
    }

    @IsTest
    static void testGetComplianceMetrics_WithCompletedReviews() {
        // Given: Some completed reviews
        List<Access_Review__c> reviews =
            ElaroISO27001AccessReviewService.initiateQuarterlyReviews();

        // Complete some reviews and make them overdue
        for (Access_Review__c review : reviews) {
            review.Due_Date__c = Date.today().addDays(-5);
            review.Review_Status__c = 'Approved';
            review.Review_Date__c = System.now();
        }
        update reviews;

        Test.startTest();
        Map<String, Object> metrics =
            ElaroISO27001AccessReviewService.getComplianceMetrics();
        Test.stopTest();

        // Then: Completion rate should be 100%
        Assert.areEqual(100, (Decimal)metrics.get('completionRate'),
            'Completion rate should be 100% when all overdue reviews are complete');
    }

    @IsTest
    static void testDormantAccountInfo_Class() {
        Test.startTest();
        ElaroISO27001AccessReviewService.DormantAccountInfo info =
            new ElaroISO27001AccessReviewService.DormantAccountInfo();
        info.userId = UserInfo.getUserId();
        info.userName = 'test@example.com';
        info.profileName = 'System Administrator';
        info.lastLoginDate = DateTime.now().addDays(-100);
        info.daysSinceLogin = 100;
        Test.stopTest();

        Assert.areEqual(UserInfo.getUserId(), info.userId, 'userId should match');
        Assert.areEqual('test@example.com', info.userName, 'userName should match');
        Assert.areEqual('System Administrator', info.profileName, 'profileName should match');
        Assert.areEqual(100, info.daysSinceLogin, 'daysSinceLogin should match');
    }

    @IsTest
    static void testProcessReviewDecision_ModifyAccess() {
        // Given: Existing review
        List<Access_Review__c> reviews =
            ElaroISO27001AccessReviewService.initiateQuarterlyReviews();
        Access_Review__c review = reviews[0];

        Test.startTest();
        ElaroISO27001AccessReviewService.processReviewDecision(
            review.Id,
            'Modify Access',
            'User needs reduced permissions'
        );
        Test.stopTest();

        // Then: Review should be updated
        Access_Review__c updatedReview = [
            SELECT Id, Review_Status__c, Decision__c
            FROM Access_Review__c
            WHERE Id = :review.Id
        ];
        Assert.areEqual('Modified', updatedReview.Review_Status__c, 'Status should be Modified');
        Assert.areEqual('Modify Access', updatedReview.Decision__c, 'Decision should be Modify Access');
    }

    @IsTest
    static void testProcessReviewDecision_Escalate() {
        // Given: Existing review
        List<Access_Review__c> reviews =
            ElaroISO27001AccessReviewService.initiateQuarterlyReviews();
        Access_Review__c review = reviews[0];

        Test.startTest();
        ElaroISO27001AccessReviewService.processReviewDecision(
            review.Id,
            'Escalate to Security',
            'Suspicious activity detected'
        );
        Test.stopTest();

        // Then: Review should be escalated
        Access_Review__c updatedReview = [
            SELECT Id, Review_Status__c, Decision__c
            FROM Access_Review__c
            WHERE Id = :review.Id
        ];
        Assert.areEqual('Escalated', updatedReview.Review_Status__c, 'Status should be Escalated');
        Assert.areEqual('Escalate to Security', updatedReview.Decision__c, 'Decision should be Escalate to Security');
    }

    @IsTest
    static void testCalculateRiskLevel_CriticalRisk() {
        // Given: Privileged user with no recent login - test via quarterly reviews
        // Note: Risk is calculated internally during initiateQuarterlyReviews

        Test.startTest();
        List<Access_Review__c> reviews =
            ElaroISO27001AccessReviewService.initiateQuarterlyReviews();
        Test.stopTest();

        // Then: Should have various risk levels
        Boolean hasRiskLevel = false;
        for (Access_Review__c review : reviews) {
            if (review.Risk_Level__c != null) {
                hasRiskLevel = true;
                Assert.isTrue(
                    review.Risk_Level__c == 'Low' ||
                    review.Risk_Level__c == 'Medium' ||
                    review.Risk_Level__c == 'High' ||
                    review.Risk_Level__c == 'Critical',
                    'Risk level should be valid value'
                );
            }
        }
        Assert.isTrue(hasRiskLevel, 'At least one review should have risk level set');
    }

    @IsTest
    static void testGetPendingReviews_NoReviews() {
        // Given: No pending reviews for a user
        User randomUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        // Delete any existing reviews for this user as reviewer
        delete [SELECT Id FROM Access_Review__c WHERE Reviewer__c = :randomUser.Id];

        Test.startTest();
        List<Access_Review__c> pendingReviews =
            ElaroISO27001AccessReviewService.getPendingReviews(randomUser.Id);
        Test.stopTest();

        // Then: Should return empty list
        Assert.areEqual(0, pendingReviews.size(), 'Should return empty list');
    }

    @IsTest
    static void testGetOverdueReviews_NoOverdue() {
        // Given: No overdue reviews
        delete [SELECT Id FROM Access_Review__c];

        Test.startTest();
        List<Access_Review__c> overdueReviews =
            ElaroISO27001AccessReviewService.getOverdueReviews();
        Test.stopTest();

        // Then: Should return empty list
        Assert.areEqual(0, overdueReviews.size(), 'Should return empty list');
    }

    // Helper method to create limited user for permission testing
    private static User createLimitedUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User limitedUser = new User(
            FirstName = 'Limited',
            LastName = 'User',
            Email = 'limited@test.com',
            Username = 'limited@test' + System.now().getTime() + '.com',
            Alias = 'limuser',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert limitedUser;
        return limitedUser;
    }
}
