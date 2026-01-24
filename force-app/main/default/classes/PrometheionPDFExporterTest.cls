/**
 * @description Unit tests for PrometheionPDFExporter
 * @group Tests
 */
@isTest
private class PrometheionPDFExporterTest {
    
    @testSetup
    static void setupTestData() {
        Prometheion_Audit_Package__c pkg = PrometheionTestDataFactory.createAuditPackage('HIPAA');
        PrometheionTestDataFactory.createEvidenceItems(pkg.Id, 10);
        PrometheionTestDataFactory.createFrameworkMappings('HIPAA');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // generateAuditPackagePDF Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGenerateAuditPackagePDF_CreatesContentVersion() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        Id contentVersionId = PrometheionPDFExporter.generateAuditPackagePDF(pkg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, contentVersionId, 'Should return ContentVersion ID');
        
        ContentVersion cv = [SELECT Title, FileExtension FROM ContentVersion WHERE Id = :contentVersionId];
        System.assert(cv.Title.contains('Audit Package'), 'Title should contain Audit Package');
        System.assertEquals('pdf', cv.FileExtension, 'Should be PDF file');
    }
    
    @isTest
    static void testGenerateAuditPackagePDF_UpdatesPackageTimestamp() {
        Prometheion_Audit_Package__c pkg = [SELECT Id, Last_Generated__c FROM Prometheion_Audit_Package__c LIMIT 1];
        Datetime beforeGeneration = pkg.Last_Generated__c;
        
        Test.startTest();
        PrometheionPDFExporter.generateAuditPackagePDF(pkg.Id);
        Test.stopTest();
        
        pkg = [SELECT Last_Generated__c FROM Prometheion_Audit_Package__c WHERE Id = :pkg.Id];
        System.assertNotEquals(beforeGeneration, pkg.Last_Generated__c, 'Timestamp should be updated');
    }
    
    @isTest
    static void testGenerateAuditPackagePDF_NullId_ThrowsException() {
        Test.startTest();
        try {
            PrometheionPDFExporter.generateAuditPackagePDF(null);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention required');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGenerateAuditPackagePDF_InvalidId_ThrowsException() {
        Test.startTest();
        try {
            PrometheionPDFExporter.generateAuditPackagePDF('001000000000000AAA');
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Should throw exception for invalid ID');
        }
        Test.stopTest();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // generateExecutiveSummary Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGenerateExecutiveSummary_CreatesContentVersion() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        Id contentVersionId = PrometheionPDFExporter.generateExecutiveSummary(pkg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, contentVersionId, 'Should return ContentVersion ID');
        
        ContentVersion cv = [SELECT Title FROM ContentVersion WHERE Id = :contentVersionId];
        System.assert(cv.Title.contains('Executive Summary'), 'Title should contain Executive Summary');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // generateEvidenceReport Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGenerateEvidenceReport_WithControlFilter() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        List<String> controlIds = new List<String>{'164.312(b)', '164.312(c)'};
        
        Test.startTest();
        Id contentVersionId = PrometheionPDFExporter.generateEvidenceReport(pkg.Id, controlIds);
        Test.stopTest();
        
        System.assertNotEquals(null, contentVersionId, 'Should return ContentVersion ID');
        
        ContentVersion cv = [SELECT Title FROM ContentVersion WHERE Id = :contentVersionId];
        System.assert(cv.Title.contains('Evidence Report'), 'Title should contain Evidence Report');
    }
    
    @isTest
    static void testGenerateEvidenceReport_NoFilter() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        Id contentVersionId = PrometheionPDFExporter.generateEvidenceReport(pkg.Id, null);
        Test.stopTest();
        
        System.assertNotEquals(null, contentVersionId, 'Should return ContentVersion ID');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // generateCSVExport Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGenerateCSVExport_ReturnsValidCSV() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        String csvContent = PrometheionPDFExporter.generateCSVExport(pkg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, csvContent, 'Should return CSV content');
        System.assert(csvContent.contains('Evidence ID'), 'Should contain header row');
        System.assert(csvContent.contains(','), 'Should be comma-separated');
    }
    
    @isTest
    static void testGenerateCSVExport_ContainsAllEvidence() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        Integer evidenceCount = [SELECT COUNT() FROM Prometheion_Evidence_Item__c WHERE Audit_Package__c = :pkg.Id];
        
        Test.startTest();
        String csvContent = PrometheionPDFExporter.generateCSVExport(pkg.Id);
        Test.stopTest();
        
        // Count lines (header + data rows)
        List<String> lines = csvContent.split('\n');
        System.assertEquals(evidenceCount + 1, lines.size(), 'Should have header + all evidence rows');
    }
    
    @isTest
    static void testGenerateCSVExport_EmptyPackage() {
        // Create package without evidence
        Prometheion_Audit_Package__c emptyPkg = PrometheionTestDataFactory.createAuditPackage('SOC2');
        
        Test.startTest();
        String csvContent = PrometheionPDFExporter.generateCSVExport(emptyPkg.Id);
        Test.stopTest();
        
        // Should only have header
        List<String> lines = csvContent.split('\n');
        System.assertEquals(1, lines.size(), 'Should only have header for empty package');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // generateJSONExport Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGenerateJSONExport_ReturnsValidJSON() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        String jsonContent = PrometheionPDFExporter.generateJSONExport(pkg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, jsonContent, 'Should return JSON content');
        
        // Verify it's valid JSON
        Map<String, Object> parsed = (Map<String, Object>)JSON.deserializeUntyped(jsonContent);
        System.assert(parsed.containsKey('package'), 'Should contain package data');
        System.assert(parsed.containsKey('evidence'), 'Should contain evidence data');
        System.assert(parsed.containsKey('exportDate'), 'Should contain export date');
    }
    
    @isTest
    static void testGenerateJSONExport_ContainsMetadata() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        String jsonContent = PrometheionPDFExporter.generateJSONExport(pkg.Id);
        Test.stopTest();
        
        Map<String, Object> parsed = (Map<String, Object>)JSON.deserializeUntyped(jsonContent);
        System.assert(parsed.containsKey('metadata'), 'Should contain metadata');
        
        Map<String, Object> metadata = (Map<String, Object>)parsed.get('metadata');
        System.assert(metadata.containsKey('generatedBy'), 'Should contain generatedBy');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // saveCSVExport Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testSaveCSVExport_CreatesContentVersion() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        Id contentVersionId = PrometheionPDFExporter.saveCSVExport(pkg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, contentVersionId, 'Should return ContentVersion ID');
        
        ContentVersion cv = [SELECT FileExtension FROM ContentVersion WHERE Id = :contentVersionId];
        System.assertEquals('csv', cv.FileExtension, 'Should be CSV file');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // saveJSONExport Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testSaveJSONExport_CreatesContentVersion() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.startTest();
        Id contentVersionId = PrometheionPDFExporter.saveJSONExport(pkg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, contentVersionId, 'Should return ContentVersion ID');
        
        ContentVersion cv = [SELECT FileExtension FROM ContentVersion WHERE Id = :contentVersionId];
        System.assertEquals('json', cv.FileExtension, 'Should be JSON file');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // batchGeneratePDFs Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testBatchGeneratePDFs_MultiplePackages() {
        // Create additional packages
        Prometheion_Audit_Package__c pkg2 = PrometheionTestDataFactory.createAuditPackage('SOC2');
        Prometheion_Audit_Package__c pkg3 = PrometheionTestDataFactory.createAuditPackage('GDPR');
        
        List<Prometheion_Audit_Package__c> allPackages = [SELECT Id FROM Prometheion_Audit_Package__c];
        List<String> packageIds = new List<String>();
        for (Prometheion_Audit_Package__c p : allPackages) {
            packageIds.add(p.Id);
        }
        
        Test.startTest();
        List<Id> contentVersionIds = PrometheionPDFExporter.batchGeneratePDFs(packageIds);
        Test.stopTest();
        
        System.assertEquals(packageIds.size(), contentVersionIds.size(), 'Should generate PDF for each package');
    }
}
