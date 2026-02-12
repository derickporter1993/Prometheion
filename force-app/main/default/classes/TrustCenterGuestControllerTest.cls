/**
 * Test class for TrustCenterGuestController.
 *
 * SECURITY TESTING: Validates token authentication, expiration checks,
 * and data access controls for guest/Sites context.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Trust Center
 */
@IsTest(testFor=TrustCenterGuestController.class)
private class TrustCenterGuestControllerTest {

    @TestSetup
    static void makeData() {
        // Create public views
        List<Trust_Center_View__c> views = new List<Trust_Center_View__c>();
        views.add(new Trust_Center_View__c(
            Name = 'SOC 2',
            Framework__c = 'SOC2',
            Compliance_Percentage__c = 92.0,
            Controls_Total__c = 50,
            Controls_Compliant__c = 46,
            Certification_Status__c = 'Certified',
            Is_Public__c = true
        ));
        views.add(new Trust_Center_View__c(
            Name = 'HIPAA',
            Framework__c = 'HIPAA',
            Compliance_Percentage__c = 88.0,
            Controls_Total__c = 40,
            Controls_Compliant__c = 35,
            Certification_Status__c = 'Certified',
            Is_Public__c = true
        ));
        views.add(new Trust_Center_View__c(
            Name = 'Internal Only',
            Framework__c = 'GDPR',
            Compliance_Percentage__c = 65.0,
            Controls_Total__c = 20,
            Controls_Compliant__c = 13,
            Certification_Status__c = 'In_Progress',
            Is_Public__c = false // MUST NOT be returned to guests
        ));

        insert as user views;

        // Create valid link
        TrustCenterLinkService service = new TrustCenterLinkService();
        service.createLink('Public', 30, 'Test Org');
    }

    @IsTest
    static void shouldReturnPublicDataWithValidToken() {
        Trust_Center_Link__c link = [
            SELECT Id, Link_Token__c FROM Trust_Center_Link__c LIMIT 1
        ];

        Test.startTest();
        TrustCenterGuestController.TrustCenterResponse response =
            TrustCenterGuestController.getPublicData(link.Link_Token__c);
        Test.stopTest();

        Assert.isTrue(response.isValid, 'Response should be valid');
        Assert.isNull(response.errorMessage, 'Should have no error message');
        Assert.areEqual(2, response.views.size(),
            'Should return only 2 public views');

        // SECURITY CHECK: Verify no non-public data returned
        for (Trust_Center_View__c view : response.views) {
            Assert.isTrue(view.Is_Public__c,
                'SECURITY VIOLATION: Non-public view returned to guest');
            Assert.areNotEqual('GDPR', view.Framework__c,
                'SECURITY VIOLATION: GDPR view should not be returned');
        }

        // Verify access was recorded
        Trust_Center_Link__c updated = [
            SELECT Id, Access_Count__c
            FROM Trust_Center_Link__c
            WHERE Id = :link.Id
            LIMIT 1
        ];
        Assert.areEqual(1, updated.Access_Count__c,
            'Access count should be incremented');
    }

    @IsTest
    static void shouldRejectInvalidToken() {
        Test.startTest();
        TrustCenterGuestController.TrustCenterResponse response =
            TrustCenterGuestController.getPublicData('invalid-token-abc123');
        Test.stopTest();

        Assert.isFalse(response.isValid, 'Response should be invalid');
        Assert.isNotNull(response.errorMessage,
            'Should have error message');
        Assert.isTrue(response.errorMessage.contains('invalid'),
            'Error message should mention invalid token');
        Assert.areEqual(0, response.views.size(),
            'Should return no views for invalid token');
    }

    @IsTest
    static void shouldRejectBlankToken() {
        Test.startTest();
        TrustCenterGuestController.TrustCenterResponse response1 =
            TrustCenterGuestController.getPublicData('');
        TrustCenterGuestController.TrustCenterResponse response2 =
            TrustCenterGuestController.getPublicData(null);
        Test.stopTest();

        Assert.isFalse(response1.isValid, 'Blank token should be invalid');
        Assert.isFalse(response2.isValid, 'Null token should be invalid');
        Assert.areEqual(0, response1.views.size(), 'Should return no views');
        Assert.areEqual(0, response2.views.size(), 'Should return no views');
    }

    @IsTest
    static void shouldRejectExpiredToken() {
        Trust_Center_Link__c link = [
            SELECT Id, Link_Token__c FROM Trust_Center_Link__c LIMIT 1
        ];

        // Manually expire the link
        link.Expiration_Date__c = Datetime.now().addDays(-1);
        update as user link;

        Test.startTest();
        TrustCenterGuestController.TrustCenterResponse response =
            TrustCenterGuestController.getPublicData(link.Link_Token__c);
        Test.stopTest();

        Assert.isFalse(response.isValid, 'Expired token should be invalid');
        Assert.isTrue(response.errorMessage.contains('expired'),
            'Error should mention expiration');
        Assert.areEqual(0, response.views.size(),
            'Should return no data for expired token');
    }

    @IsTest
    static void shouldRejectRevokedLink() {
        Trust_Center_Link__c link = [
            SELECT Id, Link_Token__c FROM Trust_Center_Link__c LIMIT 1
        ];

        // Revoke the link
        link.Is_Active__c = false;
        update as user link;

        Test.startTest();
        TrustCenterGuestController.TrustCenterResponse response =
            TrustCenterGuestController.getPublicData(link.Link_Token__c);
        Test.stopTest();

        Assert.isFalse(response.isValid, 'Revoked link should be invalid');
        Assert.isTrue(response.errorMessage.contains('revoked'),
            'Error should mention revocation');
        Assert.areEqual(0, response.views.size(),
            'Should return no data for revoked link');
    }

    @IsTest
    static void shouldReturnAccessTierInResponse() {
        // Create Email_Gated link
        TrustCenterLinkService service = new TrustCenterLinkService();
        Trust_Center_Link__c emailLink = service.createLink('Email_Gated', 7, 'Premium Customer');

        Test.startTest();
        TrustCenterGuestController.TrustCenterResponse response =
            TrustCenterGuestController.getPublicData(emailLink.Link_Token__c);
        Test.stopTest();

        Assert.isTrue(response.isValid, 'Should be valid');
        Assert.areEqual('Email_Gated', response.accessTier,
            'Should return access tier');
    }

    @IsTest
    static void shouldHandleMultipleAccesses() {
        Trust_Center_Link__c link = [
            SELECT Id, Link_Token__c FROM Trust_Center_Link__c LIMIT 1
        ];

        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TrustCenterGuestController.TrustCenterResponse response =
                TrustCenterGuestController.getPublicData(link.Link_Token__c);
            Assert.isTrue(response.isValid, 'Each access should be valid');
        }
        Test.stopTest();

        Trust_Center_Link__c updated = [
            SELECT Id, Access_Count__c
            FROM Trust_Center_Link__c
            WHERE Id = :link.Id
            LIMIT 1
        ];

        Assert.areEqual(5, updated.Access_Count__c,
            'Should record all 5 accesses');
    }

    @IsTest
    static void shouldReturnViewsSortedByCompliance() {
        Trust_Center_Link__c link = [
            SELECT Id, Link_Token__c FROM Trust_Center_Link__c LIMIT 1
        ];

        Test.startTest();
        TrustCenterGuestController.TrustCenterResponse response =
            TrustCenterGuestController.getPublicData(link.Link_Token__c);
        Test.stopTest();

        // Verify sorted DESC by compliance percentage
        Assert.areEqual('SOC2', response.views[0].Framework__c,
            'SOC2 (92%) should be first');
        Assert.areEqual('HIPAA', response.views[1].Framework__c,
            'HIPAA (88%) should be second');
    }
}
