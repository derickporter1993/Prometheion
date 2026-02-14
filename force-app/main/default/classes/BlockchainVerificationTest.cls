/**
 * @description Test class for BlockchainVerification
 * Tests blockchain evidence anchoring and verification
 * @group Tests
 * @see BlockchainVerification
 */
@isTest
private class BlockchainVerificationTest {

    @TestSetup
    static void setup() {
        Elaro_Audit_Package__c pkg = new Elaro_Audit_Package__c(
            Package_Name__c = 'Blockchain Test Package',
            Framework__c = 'SOC2',
            Status__c = 'DRAFT',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today()
        );
        insert as user pkg;

        // Create test content
        ContentVersion cv = new ContentVersion(
            Title = 'Test Evidence Document',
            PathOnClient = 'test_evidence.pdf',
            VersionData = Blob.valueOf('Test evidence content for blockchain verification'),
            IsMajorVersion = true
        );
        insert as user cv;

        // Link to package
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = pkg.Id,
            ContentDocumentId = insertedCV.ContentDocumentId,
            ShareType = 'V'
        );
        insert as user cdl;
    }

    @isTest
    static void testAnchorEvidence() {
        ContentVersion cv = [SELECT Id FROM ContentVersion WHERE Title = 'Test Evidence Document' LIMIT 1];

        Test.startTest();
        BlockchainVerification.AnchorResult result = BlockchainVerification.anchorEvidence(cv.Id);
        Test.stopTest();

        Assert.areEqual('ANCHORED', result.status, 'Status should be ANCHORED');
        Assert.areNotEqual(null, result.contentHash, 'Content hash should be generated');
        Assert.areNotEqual(null, result.transactionId, 'Transaction ID should be generated');
        Assert.areEqual('Ethereum', result.blockchainNetwork, 'Network should be Ethereum');
    }

    @isTest
    static void testVerifyEvidenceNotAnchored() {
        // Create new content that hasn't been anchored
        ContentVersion cv = new ContentVersion(
            Title = 'Unanchored Document',
            PathOnClient = 'unanchored.txt',
            VersionData = Blob.valueOf('Not anchored yet'),
            IsMajorVersion = true
        );
        insert as user cv;

        Test.startTest();
        BlockchainVerification.VerificationResult result = BlockchainVerification.verifyEvidence(cv.Id);
        Test.stopTest();

        Assert.areEqual(false, result.isVerified, 'Should not be verified');
        Assert.areEqual('NOT_ANCHORED', result.status, 'Status should be NOT_ANCHORED');
    }

    @isTest
    static void testVerifyEvidenceAfterAnchor() {
        ContentVersion cv = [SELECT Id FROM ContentVersion WHERE Title = 'Test Evidence Document' LIMIT 1];

        // First anchor the evidence
        BlockchainVerification.anchorEvidence(cv.Id);

        Test.startTest();
        BlockchainVerification.VerificationResult result = BlockchainVerification.verifyEvidence(cv.Id);
        Test.stopTest();

        Assert.areEqual(true, result.isVerified, 'Should be verified');
        Assert.areEqual('VERIFIED', result.status, 'Status should be VERIFIED');
        Assert.areNotEqual(null, result.transactionId, 'Transaction ID should be present');
    }

    @isTest
    static void testBatchAnchorEvidence() {
        // Create additional content
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Integer i = 0; i < 3; i++) {
            contentVersions.add(new ContentVersion(
                Title = 'Batch Test Document ' + i,
                PathOnClient = 'batch_test_' + i + '.txt',
                VersionData = Blob.valueOf('Batch content ' + i),
                IsMajorVersion = true
            ));
        }
        insert as user contentVersions;

        List<String> cvIds = new List<String>();
        for (ContentVersion cv : [SELECT Id FROM ContentVersion WHERE Title LIKE 'Batch Test Document%']) {
            cvIds.add(cv.Id);
        }

        Test.startTest();
        List<BlockchainVerification.AnchorResult> results = BlockchainVerification.batchAnchorEvidence(cvIds);
        Test.stopTest();

        Assert.areEqual(cvIds.size(), results.size(), 'Should return result for each document');
        for (BlockchainVerification.AnchorResult result : results) {
            Assert.areEqual('ANCHORED', result.status, 'All should be anchored');
        }
    }

    @isTest
    static void testGetVerificationHistory() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        ContentVersion cv = [SELECT Id FROM ContentVersion WHERE Title = 'Test Evidence Document' LIMIT 1];

        // Anchor the evidence first
        BlockchainVerification.anchorEvidence(cv.Id);

        Test.startTest();
        List<BlockchainVerification.VerificationRecord> history = BlockchainVerification.getVerificationHistory(pkg.Id);
        Test.stopTest();

        Assert.isTrue(history.size() > 0, 'Should have verification records');
    }

    @isTest
    static void testGenerateCertificate() {
        ContentVersion cv = [SELECT Id FROM ContentVersion WHERE Title = 'Test Evidence Document' LIMIT 1];

        // Anchor the evidence first
        BlockchainVerification.anchorEvidence(cv.Id);

        Test.startTest();
        String certificate = BlockchainVerification.generateCertificate(cv.Id);
        Test.stopTest();

        Assert.isTrue(certificate.contains('CERTIFICATE OF AUTHENTICITY'), 'Certificate should have proper header');
        Assert.isTrue(certificate.contains('AUTHENTIC'), 'Certificate should confirm authenticity');
    }

    @isTest
    static void testGenerateCertificateUnverified() {
        // Create unanchored content
        ContentVersion cv = new ContentVersion(
            Title = 'Unverified Document',
            PathOnClient = 'unverified.txt',
            VersionData = Blob.valueOf('Unverified content'),
            IsMajorVersion = true
        );
        insert as user cv;

        Test.startTest();
        try {
            BlockchainVerification.generateCertificate(cv.Id);
            Assert.fail( 'Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('not verified'), 'Error should indicate not verified');
        }
        Test.stopTest();
    }
}
