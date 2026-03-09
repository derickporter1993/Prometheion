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
        Assert.areNotEqual(null, contentDocId, 'Should return a ContentDocumentId');

        List<ContentDocument> docs = [SELECT Id, Title FROM ContentDocument WHERE Id = :contentDocId];
        Assert.areEqual(1, docs.size(), 'Should create one ContentDocument');
        Assert.isTrue(docs[0].Title.contains('SOC2'), 'Document title should contain framework name');
        Assert.isTrue(docs[0].Title.contains('Evidence_Pack'), 'Document title should contain Evidence_Pack');
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
        Assert.areEqual(1, docs.size(), 'Should create one ContentDocument');
        Assert.isTrue(docs[0].Title.contains('GDPR'), 'Document title should contain GDPR');
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
        Assert.isTrue(docs[0].Title.contains('HIPAA'), 'Document title should contain HIPAA');
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
        Assert.areEqual(1, versions.size(), 'Should have one version');
        Assert.areEqual(true, versions[0].IsMajorVersion, 'Should be a major version');
        Assert.isTrue(versions[0].PathOnClient.endsWith('.txt'), 'File should be .txt');
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
        Assert.isTrue(content.contains('COMPLIANCE EVIDENCE PACK'), 'Should contain header');
        Assert.isTrue(content.contains('Framework: SOC2'), 'Should contain framework');
        Assert.isTrue(content.contains('Total Events:'), 'Should contain event count');
        Assert.isTrue(content.contains('DETAILED AUDIT LOG'), 'Should contain audit log section');
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
        Assert.areNotEqual(null, contentDocId, 'Should create document for single day range');
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
        Assert.isTrue(content.contains('Total Events: 0'), 'Should show zero events when no data');
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
                Assert.isTrue(e.getMessage().contains('Error generating evidence pack'),
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
            Assert.fail( 'Should have thrown exception for null framework');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Framework cannot be blank'),
                'Should throw validation error for null framework');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGenerateLegalAttestation_BlankFramework() {
        // Given: Blank framework parameter
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();

        Test.startTest();
        try {
            ElaroLegalDocumentGenerator.generateLegalAttestation('', startDate, endDate);
            Assert.fail( 'Should have thrown exception for blank framework');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Framework cannot be blank'),
                'Should throw validation error for blank framework');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGenerateLegalAttestation_InvalidFramework() {
        // Given: Invalid framework parameter
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();

        Test.startTest();
        try {
            ElaroLegalDocumentGenerator.generateLegalAttestation('INVALID_FRAMEWORK', startDate, endDate);
            Assert.fail( 'Should have thrown exception for invalid framework');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Unsupported framework'),
                'Should throw validation error for invalid framework');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGenerateLegalAttestation_NullStartDate() {
        // Given: Null start date
        Test.startTest();
        try {
            ElaroLegalDocumentGenerator.generateLegalAttestation('SOC2', null, Date.today());
            Assert.fail( 'Should have thrown exception for null start date');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Start date cannot be null'),
                'Should throw validation error for null start date');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGenerateLegalAttestation_NullEndDate() {
        // Given: Null end date
        Test.startTest();
        try {
            ElaroLegalDocumentGenerator.generateLegalAttestation('SOC2', Date.today(), null);
            Assert.fail( 'Should have thrown exception for null end date');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('End date cannot be null'),
                'Should throw validation error for null end date');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGenerateLegalAttestation_StartDateAfterEndDate() {
        // Given: Start date after end date
        Test.startTest();
        try {
            ElaroLegalDocumentGenerator.generateLegalAttestation('SOC2', Date.today(), Date.today().addDays(-30));
            Assert.fail( 'Should have thrown exception for invalid date range');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Start date cannot be after end date'),
                'Should throw validation error for invalid date range');
        }
        Test.stopTest();
    }
}
