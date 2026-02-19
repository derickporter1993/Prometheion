/**
 * Test class for TrustCenterLinkService.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Trust Center
 */
@IsTest(testFor=TrustCenterLinkService.class)
private class TrustCenterLinkServiceTest {

    @IsTest
    static void shouldCreateLink() {
        Test.startTest();
        TrustCenterLinkService service = new TrustCenterLinkService();
        Trust_Center_Link__c link = service.createLink(
            'Public', 30, 'Acme Corp'
        );
        Test.stopTest();

        Assert.isNotNull(link.Id, 'Link should be inserted');
        Assert.isNotNull(link.Link_Token__c, 'Should generate UUID token');
        Assert.areEqual(36, link.Link_Token__c.length(),
            'UUID should be 36 characters');
        Assert.areEqual('Public', link.Access_Tier__c,
            'Should set access tier');
        Assert.areEqual('Acme Corp', link.Created_For__c,
            'Should set created for');
        Assert.isTrue(link.Is_Active__c, 'Should be active');
        Assert.areEqual(0, link.Access_Count__c, 'Access count should be 0');

        // Verify expiration is ~30 days from now
        Long daysDiff = link.Expiration_Date__c.date().daysBetween(
            Date.today().addDays(30)
        );
        Assert.isTrue(Math.abs(daysDiff) <= 1,
            'Expiration should be ~30 days from now');
    }

    @IsTest
    static void shouldUseDefaultValues() {
        Test.startTest();
        TrustCenterLinkService service = new TrustCenterLinkService();
        Trust_Center_Link__c link = service.createLink(null, null, null);
        Test.stopTest();

        Assert.areEqual('Public', link.Access_Tier__c,
            'Should default to Public tier');

        Long daysDiff = link.Expiration_Date__c.date().daysBetween(
            Date.today().addDays(30)
        );
        Assert.isTrue(Math.abs(daysDiff) <= 1,
            'Should default to 30 days expiration');
    }

    @IsTest
    static void shouldValidateToken() {
        TrustCenterLinkService service = new TrustCenterLinkService();
        Trust_Center_Link__c created = service.createLink('Email_Gated', 7, 'Test Corp');

        Test.startTest();
        Trust_Center_Link__c validated = service.validateToken(created.Link_Token__c);
        Test.stopTest();

        Assert.isNotNull(validated, 'Should validate valid token');
        Assert.areEqual(created.Id, validated.Id,
            'Should return correct link');
        Assert.areEqual('Email_Gated', validated.Access_Tier__c,
            'Should return access tier');
    }

    @IsTest
    static void shouldRejectInvalidToken() {
        TrustCenterLinkService service = new TrustCenterLinkService();

        Test.startTest();
        Trust_Center_Link__c result = service.validateToken('invalid-uuid-12345');
        Test.stopTest();

        Assert.isNull(result, 'Should reject invalid token');
    }

    @IsTest
    static void shouldRejectExpiredToken() {
        TrustCenterLinkService service = new TrustCenterLinkService();
        Trust_Center_Link__c link = service.createLink('Public', 30, 'Test');

        // Manually set expiration to past
        link.Expiration_Date__c = Datetime.now().addDays(-1);
        update as user link;

        Test.startTest();
        Trust_Center_Link__c validated = service.validateToken(link.Link_Token__c);
        Test.stopTest();

        Assert.isNull(validated, 'Should reject expired token');
    }

    @IsTest
    static void shouldRejectInactiveLink() {
        TrustCenterLinkService service = new TrustCenterLinkService();
        Trust_Center_Link__c link = service.createLink('Public', 30, 'Test');

        link.Is_Active__c = false;
        update as user link;

        Test.startTest();
        Trust_Center_Link__c validated = service.validateToken(link.Link_Token__c);
        Test.stopTest();

        Assert.isNull(validated, 'Should reject inactive link');
    }

    @IsTest
    static void shouldRecordAccess() {
        TrustCenterLinkService service = new TrustCenterLinkService();
        Trust_Center_Link__c link = service.createLink('Public', 30, 'Test');

        Test.startTest();
        service.recordAccess(link.Id);
        service.recordAccess(link.Id);
        service.recordAccess(link.Id);
        Test.stopTest();

        Trust_Center_Link__c updated = [
            SELECT Id, Access_Count__c, Last_Accessed_Date__c
            FROM Trust_Center_Link__c
            WHERE Id = :link.Id
            WITH USER_MODE
            LIMIT 1
        ];

        Assert.areEqual(3, updated.Access_Count__c,
            'Should increment access count to 3');
        Assert.isNotNull(updated.Last_Accessed_Date__c,
            'Should set last accessed timestamp');

        Long secondsDiff = Math.abs(
            Datetime.now().getTime() - updated.Last_Accessed_Date__c.getTime()
        ) / 1000;
        Assert.isTrue(secondsDiff < 10,
            'Last accessed should be within last 10 seconds');
    }

    @IsTest
    static void shouldRevokeLink() {
        TrustCenterLinkService service = new TrustCenterLinkService();
        Trust_Center_Link__c link = service.createLink('Public', 30, 'Test');

        Assert.isTrue(link.Is_Active__c, 'Should start as active');

        Test.startTest();
        service.revokeLink(link.Id);
        Test.stopTest();

        Trust_Center_Link__c updated = [
            SELECT Id, Is_Active__c
            FROM Trust_Center_Link__c
            WHERE Id = :link.Id
            WITH USER_MODE
            LIMIT 1
        ];

        Assert.isFalse(updated.Is_Active__c, 'Should be revoked');

        // Verify revoked link cannot be validated
        Trust_Center_Link__c validated = service.validateToken(link.Link_Token__c);
        Assert.isNull(validated, 'Revoked link should not validate');
    }

    @IsTest
    static void shouldGetActiveLinks() {
        TrustCenterLinkService service = new TrustCenterLinkService();
        service.createLink('Public', 30, 'Corp A');
        service.createLink('Email_Gated', 7, 'Corp B');
        Trust_Center_Link__c revoked = service.createLink('NDA_Required', 90, 'Corp C');

        // Revoke one link
        service.revokeLink(revoked.Id);

        Test.startTest();
        List<Trust_Center_Link__c> active = service.getActiveLinks();
        Test.stopTest();

        Assert.areEqual(2, active.size(),
            'Should return only 2 active links');

        // Verify no revoked links returned
        for (Trust_Center_Link__c link : active) {
            Assert.isTrue(link.Is_Active__c, 'All returned links should be active');
        }
    }

    @IsTest
    static void shouldHandleNullLinkId() {
        TrustCenterLinkService service = new TrustCenterLinkService();

        Exception caughtEx;
        Test.startTest();
        try {
            service.recordAccess(null); // Should not throw exception
            service.revokeLink(null); // Should not throw exception
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Should handle null IDs gracefully without throwing');
    }

    @IsTest
    static void shouldGenerateUniqueTokens() {
        TrustCenterLinkService service = new TrustCenterLinkService();

        Set<String> tokens = new Set<String>();

        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            Trust_Center_Link__c link = service.createLink('Public', 30, 'Test ' + i);
            tokens.add(link.Link_Token__c);
        }
        Test.stopTest();

        Assert.areEqual(5, tokens.size(), 'Should generate 5 unique tokens');
    }
}
