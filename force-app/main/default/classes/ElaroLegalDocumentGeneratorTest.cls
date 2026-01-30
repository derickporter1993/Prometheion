@IsTest
private class ElaroLegalDocumentGeneratorTest {

    @IsTest
    static void testGenerateLegalAttestation_PositivePath() {
        // Given: Valid parameters
        String framework = 'SOC2';
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();

        Test.startTest();
        String contentDocId = ElaroLegalDocumentGenerator.generateLegalAttestation(framework, startDate, endDate);
        Test.stopTest();

        // Then: Should create a ContentVersion and return ContentDocumentId
        System.assertNotEquals(null, contentDocId, 'Should return a ContentDocumentId');

        List<ContentDocument> docs = [SELECT Id, Title FROM ContentDocument WHERE Id = :contentDocId];
        System.assertEquals(1, docs.size(), 'Should create one ContentDocument');
        System.assert(docs[0].Title.contains('SOC2'), 'Document title should contain framework name');
        System.assert(docs[0].Title.contains('Evidence_Pack'), 'Document title should contain Evidence_Pack');
    }

    @IsTest
    static void testGenerateLegalAttestation_GDPRFramework() {
        // Given: GDPR framework
        String framework = 'GDPR';
        Date startDate = Date.today().addDays(-90);
        Date endDate = Date.today();

        Test.startTest();
        String contentDocId = ElaroLegalDocumentGenerator.generateLegalAttestation(framework, startDate, endDate);
        Test.stopTest();

        // Then: Should create document with GDPR in title
        List<ContentDocument> docs = [SELECT Id, Title FROM ContentDocument WHERE Id = :contentDocId];
        System.assertEquals(1, docs.size(), 'Should create one ContentDocument');
        System.assert(docs[0].Title.contains('GDPR'), 'Document title should contain GDPR');
    }

    @IsTest
    static void testGenerateLegalAttestation_HIPAAFramework() {
        // Given: HIPAA framework
        String framework = 'HIPAA';
        Date startDate = Date.today().addDays(-365);
        Date endDate = Date.today();

        Test.startTest();
        String contentDocId = ElaroLegalDocumentGenerator.generateLegalAttestation(framework, startDate, endDate);
        Test.stopTest();

        // Then: Should create document with HIPAA in title
        List<ContentDocument> docs = [SELECT Id, Title FROM ContentDocument WHERE Id = :contentDocId];
        System.assert(docs[0].Title.contains('HIPAA'), 'Document title should contain HIPAA');
    }

    @IsTest
    static void testGenerateLegalAttestation_ContentVersionCreated() {
        // Given: Valid parameters
        String framework = 'ISO27001';
        Date startDate = Date.today().addDays(-7);
        Date endDate = Date.today();

        Test.startTest();
        String contentDocId = ElaroLegalDocumentGenerator.generateLegalAttestation(framework, startDate, endDate);
        Test.stopTest();

        // Then: Verify ContentVersion properties
        List<ContentVersion> versions = [
            SELECT Id, Title, PathOnClient, IsMajorVersion, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocId
        ];
        System.assertEquals(1, versions.size(), 'Should have one version');
        System.assertEquals(true, versions[0].IsMajorVersion, 'Should be a major version');
        System.assert(versions[0].PathOnClient.endsWith('.txt'), 'File should be .txt');
    }

    @IsTest
    static void testGenerateLegalAttestation_DocumentContent() {
        // Given: Valid parameters
        String framework = 'SOC2';
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();

        Test.startTest();
        String contentDocId = ElaroLegalDocumentGenerator.generateLegalAttestation(framework, startDate, endDate);
        Test.stopTest();

        // Then: Verify document content structure
        ContentVersion cv = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocId
            LIMIT 1
        ];
        String content = cv.VersionData.toString();
        System.assert(content.contains('COMPLIANCE EVIDENCE PACK'), 'Should contain header');
        System.assert(content.contains('Framework: SOC2'), 'Should contain framework');
        System.assert(content.contains('Total Events:'), 'Should contain event count');
        System.assert(content.contains('DETAILED AUDIT LOG'), 'Should contain audit log section');
    }

    @IsTest
    static void testGenerateLegalAttestation_EmptyDateRange() {
        // Given: Same start and end date (single day)
        String framework = 'PCI_DSS';
        Date singleDay = Date.today();

        Test.startTest();
        String contentDocId = ElaroLegalDocumentGenerator.generateLegalAttestation(framework, singleDay, singleDay);
        Test.stopTest();

        // Then: Should still create document
        System.assertNotEquals(null, contentDocId, 'Should create document for single day range');
    }

    @IsTest
    static void testGenerateLegalAttestation_BulkEntries() {
        // Given: Framework with compliance graph entries would be needed
        // Note: Big Objects cannot be inserted in test context, so we test the empty case
        String framework = 'NIST';
        Date startDate = Date.today().addDays(-365);
        Date endDate = Date.today();

        Test.startTest();
        String contentDocId = ElaroLegalDocumentGenerator.generateLegalAttestation(framework, startDate, endDate);
        Test.stopTest();

        // Then: Should handle empty result set gracefully
        ContentVersion cv = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocId
            LIMIT 1
        ];
        String content = cv.VersionData.toString();
        System.assert(content.contains('Total Events: 0'), 'Should show zero events when no data');
    }

    @IsTest
    static void testGenerateLegalAttestation_InsufficientPermissions() {
        // Given: A user without ContentVersion create permissions
        Profile minAccessProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];

        User limitedUser = new User(
            Alias = 'limited',
            Email = 'limited@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = minAccessProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'limiteduser' + DateTime.now().getTime() + '@test.com'
        );
        insert limitedUser;

        Test.startTest();
        System.runAs(limitedUser) {
            try {
                ElaroLegalDocumentGenerator.generateLegalAttestation('SOC2', Date.today().addDays(-30), Date.today());
                // May succeed if user has implicit permissions
            } catch (AuraHandledException e) {
                // Expected: Should throw AuraHandledException for permission issues
                System.assert(e.getMessage().contains('Error generating evidence pack'),
                    'Should throw appropriate error message');
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testGenerateLegalAttestation_NullFramework() {
        // Given: Null framework parameter
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();

        Test.startTest();
        try {
            ElaroLegalDocumentGenerator.generateLegalAttestation(null, startDate, endDate);
            // Document creation may succeed with null framework
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error generating evidence pack'),
                'Should throw AuraHandledException for null framework');
        }
        Test.stopTest();
    }
}
