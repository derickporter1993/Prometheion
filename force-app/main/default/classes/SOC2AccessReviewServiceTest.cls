/**
 * SOC2AccessReviewServiceTest
 *
 * Test class for SOC2AccessReviewService
 *
 * @author Prometheion
 * @version 1.0
 */
@isTest
public class SOC2AccessReviewServiceTest {

    @TestSetup
    static void setup() {
        // Create test access review records
        List<Access_Review__c> reviews = new List<Access_Review__c>();
        for (Integer i = 0; i < 5; i++) {
            reviews.add(new Access_Review__c(
                Review_Type__c = 'QUARTERLY',
                Status__c = 'PENDING',
                Framework__c = 'SOC2',
                Due_Date__c = Date.today().addDays(30)
            ));
        }
        insert reviews;
    }

    @isTest
    static void testGetFrameworkName() {
        SOC2AccessReviewService service = new SOC2AccessReviewService();

        Test.startTest();
        String frameworkName = service.getFrameworkName();
        Test.stopTest();

        System.assertEquals('SOC2', frameworkName, 'Framework name should be SOC2');
    }

    @isTest
    static void testInitiateAccessReview() {
        SOC2AccessReviewService service = new SOC2AccessReviewService();

        Test.startTest();
        Id reviewId = service.initiateAccessReview('QUARTERLY');
        Test.stopTest();

        // Review may or may not be created depending on available users
        // Just verify no exception is thrown
    }

    @isTest
    static void testGetReviewStatus() {
        SOC2AccessReviewService service = new SOC2AccessReviewService();

        // Get an existing review
        Access_Review__c existingReview = [SELECT Id FROM Access_Review__c LIMIT 1];

        Test.startTest();
        IAccessControlService.AccessReviewStatus status = service.getReviewStatus(existingReview.Id);
        Test.stopTest();

        System.assertNotEquals(null, status, 'Status should not be null');
    }

    @isTest
    static void testGetExcessiveAccessUsers() {
        SOC2AccessReviewService service = new SOC2AccessReviewService();

        Test.startTest();
        List<IAccessControlService.ExcessiveAccessUser> users = service.getExcessiveAccessUsers();
        Test.stopTest();

        System.assertNotEquals(null, users, 'Users list should not be null');
    }

    @isTest
    static void testRevokeAccess() {
        SOC2AccessReviewService service = new SOC2AccessReviewService();

        // Test with empty list
        Test.startTest();
        IAccessControlService.RevokeAccessResult result = service.revokeAccess(new List<Id>(), 'Test revocation');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.success, 'Should fail with empty user list');
    }

    @isTest
    static void testGetStalePermissions() {
        SOC2AccessReviewService service = new SOC2AccessReviewService();

        Test.startTest();
        List<IAccessControlService.StalePermission> stalePerms = service.getStalePermissions(90);
        Test.stopTest();

        System.assertNotEquals(null, stalePerms, 'Stale permissions list should not be null');
    }

    @isTest
    static void testValidateNeedToKnow() {
        SOC2AccessReviewService service = new SOC2AccessReviewService();

        Test.startTest();
        IAccessControlService.NeedToKnowResult result = service.validateNeedToKnow(UserInfo.getUserId());
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(UserInfo.getUserId(), result.userId, 'User ID should match');
    }

    @isTest
    static void testGetViolations() {
        SOC2AccessReviewService service = new SOC2AccessReviewService();

        Test.startTest();
        List<ComplianceServiceBase.Violation> violations = service.getViolations();
        Test.stopTest();

        System.assertNotEquals(null, violations, 'Violations should not be null');
    }

    @isTest
    static void testGetComplianceScore() {
        SOC2AccessReviewService service = new SOC2AccessReviewService();

        Test.startTest();
        Decimal score = service.getComplianceScore();
        Test.stopTest();

        System.assert(score >= 0 && score <= 100, 'Score should be between 0 and 100');
    }

    @isTest
    static void testInitiateAnnualReview() {
        SOC2AccessReviewService service = new SOC2AccessReviewService();

        Test.startTest();
        Id reviewId = service.initiateAccessReview('ANNUAL');
        Test.stopTest();

        // Verify no exception thrown
    }

    @isTest
    static void testInitiateAdHocReview() {
        SOC2AccessReviewService service = new SOC2AccessReviewService();

        Test.startTest();
        Id reviewId = service.initiateAccessReview('AD_HOC');
        Test.stopTest();

        // Verify no exception thrown
    }

    @isTest
    static void testBulkAccessReview() {
        // Create bulk access review records
        List<Access_Review__c> bulkReviews = new List<Access_Review__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkReviews.add(new Access_Review__c(
                Review_Type__c = 'QUARTERLY',
                Status__c = 'PENDING',
                Framework__c = 'SOC2',
                Due_Date__c = Date.today().addDays(30)
            ));
        }
        insert bulkReviews;

        SOC2AccessReviewService service = new SOC2AccessReviewService();

        Test.startTest();
        List<IAccessControlService.ExcessiveAccessUser> users = service.getExcessiveAccessUsers();
        Test.stopTest();

        System.assertNotEquals(null, users, 'Users list should not be null for bulk test');
    }
}
