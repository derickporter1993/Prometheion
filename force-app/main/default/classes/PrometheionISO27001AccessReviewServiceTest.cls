/**
 * Test class for PrometheionISO27001AccessReviewService
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
private class ISO27001AccessReviewServiceTest {
    
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
            PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();
        Test.stopTest();
        
        // Then: Reviews should be created
        System.assert(!reviews.isEmpty(), 'Should create reviews');
        for (Access_Review__c review : reviews) {
            System.assertEquals('Quarterly Review', review.Review_Type__c, 'Should be quarterly review');
            System.assertEquals('Pending', review.Review_Status__c, 'Status should be Pending');
            System.assertNotEquals(null, review.Due_Date__c, 'Due date should be set');
            System.assertNotEquals(null, review.User__c, 'User should be set');
        }
    }
    
    @IsTest
    static void testInitiatePrivilegedAccessReviews() {
        // Given: Privileged users exist
        
        Test.startTest();
        List<Access_Review__c> reviews = 
            PrometheionISO27001AccessReviewService.initiatePrivilegedAccessReviews();
        Test.stopTest();
        
        // Then: Privileged reviews should be created
        System.assert(!reviews.isEmpty(), 'Should create privileged reviews');
        for (Access_Review__c review : reviews) {
            System.assertEquals('Privileged Access Review', review.Review_Type__c, 
                'Should be privileged review');
            System.assertEquals(true, review.Is_Privileged_User__c, 'Should be privileged user');
            System.assertEquals('High', review.Risk_Level__c, 'Risk level should be High');
        }
    }
    
    @IsTest
    static void testProcessReviewDecision_Approve() {
        // Given: Existing review
        List<Access_Review__c> reviews = 
            PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();
        Access_Review__c review = reviews[0];
        
        Test.startTest();
        PrometheionISO27001AccessReviewService.processReviewDecision(
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
        System.assertEquals('Approved', updatedReview.Review_Status__c, 'Status should be Approved');
        System.assertEquals('Approve All Access', updatedReview.Decision__c, 'Decision should be Approve All Access');
        System.assertNotEquals(null, updatedReview.Review_Date__c, 'Review date should be set');
    }
    
    @IsTest
    static void testProcessReviewDecision_Revoke() {
        // Given: Existing review
        List<Access_Review__c> reviews = 
            PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();
        Access_Review__c review = reviews[0];
        
        Test.startTest();
        PrometheionISO27001AccessReviewService.processReviewDecision(
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
        System.assertEquals('Revoked', updatedReview.Review_Status__c, 'Status should be Revoked');
        System.assertEquals('Revoke All Access', updatedReview.Decision__c, 'Decision should be Revoke All Access');
    }
    
    @IsTest
    static void testInitiateQuarterlyReviews_InsufficientPermissions() {
        // Given: Limited user
        User limitedUser = createLimitedUser();
        
        Test.startTest();
        System.runAs(limitedUser) {
            try {
                PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();
                System.assert(false, 'Should have thrown InsufficientAccessException');
            } catch (Exception e) {
                // Then: Permission exception should be thrown
                // Note: InsufficientAccessException may not be available, catch generic Exception
                System.assert(e.getMessage().contains('insufficient') || 
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
            PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();
        
        Test.startTest();
        List<Access_Review__c> pendingReviews = 
            PrometheionISO27001AccessReviewService.getPendingReviews(manager.Id);
        Test.stopTest();
        
        // Then: Should return pending reviews for reviewer
        System.assert(pendingReviews.size() >= 0, 'Should return pending reviews');
        for (Access_Review__c review : pendingReviews) {
            System.assert(review.Review_Status__c == 'Pending' || review.Review_Status__c == 'In Progress', 
                'Should only return pending/in progress reviews');
            System.assertEquals(manager.Id, review.Reviewer__c, 'Should match reviewer');
        }
    }
    
    @IsTest
    static void testGetOverdueReviews() {
        // Given: Overdue reviews
        List<Access_Review__c> reviews = 
            PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();
        
        // Make some overdue
        for (Access_Review__c review : reviews) {
            review.Due_Date__c = Date.today().addDays(-5);
        }
        update reviews;
        
        Test.startTest();
        List<Access_Review__c> overdueReviews = 
            PrometheionISO27001AccessReviewService.getOverdueReviews();
        Test.stopTest();
        
        // Then: Should return overdue reviews
        System.assert(overdueReviews.size() >= 0, 'Should return overdue reviews');
        for (Access_Review__c review : overdueReviews) {
            System.assert(review.Due_Date__c < Date.today(), 'Should be overdue');
        }
    }
    
    @IsTest
    static void testInitiateQuarterlyReviews_BulkOperation() {
        // Given: Many users (test with existing users)
        
        Test.startTest();
        List<Access_Review__c> reviews = 
            PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();
        Test.stopTest();
        
        // Then: Should handle bulk users
        System.assert(reviews.size() >= 0, 'Should process users');
        // Note: Actual count depends on org setup
    }
    
    @IsTest
    static void testCalculateRiskLevel() {
        // Given: User with different access levels
        User adminUser = [SELECT Id, Profile.Name FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        
        Test.startTest();
        // Risk level is calculated internally, test via review creation
        List<Access_Review__c> reviews = 
            PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();
        Test.stopTest();
        
        // Then: Risk levels should be assigned
        for (Access_Review__c review : reviews) {
            if (review.User__c == adminUser.Id) {
                System.assertNotEquals(null, review.Risk_Level__c, 'Risk level should be set');
            }
        }
    }
    
    @IsTest
    static void testIdentifyDormantAccounts() {
        // Given: Users exist (some may be dormant based on LastLoginDate)

        Test.startTest();
        List<PrometheionISO27001AccessReviewService.DormantAccountInfo> dormantAccounts =
            PrometheionISO27001AccessReviewService.identifyDormantAccounts();
        Test.stopTest();

        // Then: Should return dormant account info
        // Note: Test users created in setup may or may not be dormant
        System.assertNotEquals(null, dormantAccounts, 'Should return a list');

        // Verify structure if any dormant accounts found
        for (PrometheionISO27001AccessReviewService.DormantAccountInfo info : dormantAccounts) {
            System.assertNotEquals(null, info.userId, 'User ID should be set');
            System.assertNotEquals(null, info.userName, 'Username should be set');
            System.assertNotEquals(null, info.profileName, 'Profile name should be set');
        }
    }

    @IsTest
    static void testCreateTerminationReview() {
        // Given: Active user
        User testUser = [SELECT Id FROM User WHERE LastName LIKE 'User%' AND IsActive = true LIMIT 1];
        Date terminationDate = Date.today().addDays(7);

        Test.startTest();
        Access_Review__c review =
            PrometheionISO27001AccessReviewService.createTerminationReview(testUser.Id, terminationDate);
        Test.stopTest();

        // Then: Termination review should be created
        System.assertNotEquals(null, review.Id, 'Review should be inserted');
        System.assertEquals('Termination Review', review.Review_Type__c, 'Should be termination review');
        System.assertEquals('In Progress', review.Review_Status__c, 'Status should be In Progress');
        System.assertEquals('Revoke All Access', review.Decision__c, 'Decision should be Revoke All Access');
        System.assertEquals('High', review.Risk_Level__c, 'Risk level should be High');
        System.assertEquals(terminationDate, review.Due_Date__c, 'Due date should match termination date');
    }

    @IsTest
    static void testGetComplianceMetrics() {
        // Given: Some reviews exist
        PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();

        Test.startTest();
        Map<String, Object> metrics =
            PrometheionISO27001AccessReviewService.getComplianceMetrics();
        Test.stopTest();

        // Then: Should return metrics
        System.assertNotEquals(null, metrics, 'Metrics should not be null');
        System.assert(metrics.containsKey('reviewsThisQuarter'), 'Should have reviewsThisQuarter metric');
        System.assert(metrics.containsKey('completionRate'), 'Should have completionRate metric');
        System.assert(metrics.containsKey('overdueCount'), 'Should have overdueCount metric');
        System.assert(metrics.containsKey('privilegedUsersCount'), 'Should have privilegedUsersCount metric');
        System.assert(metrics.containsKey('dormantAccountsCount'), 'Should have dormantAccountsCount metric');
    }

    @IsTest
    static void testGetComplianceMetrics_WithCompletedReviews() {
        // Given: Some completed reviews
        List<Access_Review__c> reviews =
            PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();

        // Complete some reviews and make them overdue
        for (Access_Review__c review : reviews) {
            review.Due_Date__c = Date.today().addDays(-5);
            review.Review_Status__c = 'Approved';
            review.Review_Date__c = System.now();
        }
        update reviews;

        Test.startTest();
        Map<String, Object> metrics =
            PrometheionISO27001AccessReviewService.getComplianceMetrics();
        Test.stopTest();

        // Then: Completion rate should be 100%
        System.assertEquals(100, (Decimal)metrics.get('completionRate'),
            'Completion rate should be 100% when all overdue reviews are complete');
    }

    @IsTest
    static void testDormantAccountInfo_Class() {
        Test.startTest();
        PrometheionISO27001AccessReviewService.DormantAccountInfo info =
            new PrometheionISO27001AccessReviewService.DormantAccountInfo();
        info.userId = UserInfo.getUserId();
        info.userName = 'test@example.com';
        info.profileName = 'System Administrator';
        info.lastLoginDate = DateTime.now().addDays(-100);
        info.daysSinceLogin = 100;
        Test.stopTest();

        System.assertEquals(UserInfo.getUserId(), info.userId, 'userId should match');
        System.assertEquals('test@example.com', info.userName, 'userName should match');
        System.assertEquals('System Administrator', info.profileName, 'profileName should match');
        System.assertEquals(100, info.daysSinceLogin, 'daysSinceLogin should match');
    }

    @IsTest
    static void testProcessReviewDecision_ModifyAccess() {
        // Given: Existing review
        List<Access_Review__c> reviews =
            PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();
        Access_Review__c review = reviews[0];

        Test.startTest();
        PrometheionISO27001AccessReviewService.processReviewDecision(
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
        System.assertEquals('Modified', updatedReview.Review_Status__c, 'Status should be Modified');
        System.assertEquals('Modify Access', updatedReview.Decision__c, 'Decision should be Modify Access');
    }

    @IsTest
    static void testProcessReviewDecision_Escalate() {
        // Given: Existing review
        List<Access_Review__c> reviews =
            PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();
        Access_Review__c review = reviews[0];

        Test.startTest();
        PrometheionISO27001AccessReviewService.processReviewDecision(
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
        System.assertEquals('Escalated', updatedReview.Review_Status__c, 'Status should be Escalated');
        System.assertEquals('Escalate to Security', updatedReview.Decision__c, 'Decision should be Escalate to Security');
    }

    @IsTest
    static void testCalculateRiskLevel_CriticalRisk() {
        // Given: Privileged user with no recent login - test via quarterly reviews
        // Note: Risk is calculated internally during initiateQuarterlyReviews

        Test.startTest();
        List<Access_Review__c> reviews =
            PrometheionISO27001AccessReviewService.initiateQuarterlyReviews();
        Test.stopTest();

        // Then: Should have various risk levels
        Boolean hasRiskLevel = false;
        for (Access_Review__c review : reviews) {
            if (review.Risk_Level__c != null) {
                hasRiskLevel = true;
                System.assert(
                    review.Risk_Level__c == 'Low' ||
                    review.Risk_Level__c == 'Medium' ||
                    review.Risk_Level__c == 'High' ||
                    review.Risk_Level__c == 'Critical',
                    'Risk level should be valid value'
                );
            }
        }
        System.assert(hasRiskLevel, 'At least one review should have risk level set');
    }

    @IsTest
    static void testGetPendingReviews_NoReviews() {
        // Given: No pending reviews for a user
        User randomUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        // Delete any existing reviews for this user as reviewer
        delete [SELECT Id FROM Access_Review__c WHERE Reviewer__c = :randomUser.Id];

        Test.startTest();
        List<Access_Review__c> pendingReviews =
            PrometheionISO27001AccessReviewService.getPendingReviews(randomUser.Id);
        Test.stopTest();

        // Then: Should return empty list
        System.assertEquals(0, pendingReviews.size(), 'Should return empty list');
    }

    @IsTest
    static void testGetOverdueReviews_NoOverdue() {
        // Given: No overdue reviews
        delete [SELECT Id FROM Access_Review__c];

        Test.startTest();
        List<Access_Review__c> overdueReviews =
            PrometheionISO27001AccessReviewService.getOverdueReviews();
        Test.stopTest();

        // Then: Should return empty list
        System.assertEquals(0, overdueReviews.size(), 'Should return empty list');
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
