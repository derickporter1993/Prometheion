/**
 * @description PDF and export generation service for audit packages
 * Generates PDF reports, CSV exports, and JSON exports with integrity hashing
 * @group Export &amp; Delivery
 * @author Elaro Team
 */
public with sharing class ElaroPDFExporter {
    
    // ═══════════════════════════════════════════════════════════════
    // PUBLIC METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Generate PDF for audit package
     * @param packageId The audit package ID
     * @return ContentVersion ID of the generated PDF
     * @throws AuraHandledException if generation fails
     */
    @AuraEnabled
    public static Id generateAuditPackagePDF(String packageId) {
        validatePackageId(packageId);
        
        try {
            // Query the audit package
            Elaro_Audit_Package__c pkg = queryAuditPackage(packageId);
            
            // Generate PDF via Visualforce
            PageReference pdfPage = Page.ElaroAuditPackagePDF;
            pdfPage.getParameters().put('id', packageId);
            
            Blob pdfContent;
            if (Test.isRunningTest()) {
                pdfContent = Blob.valueOf('Test PDF Content for Audit Package');
            } else {
                pdfContent = pdfPage.getContentAsPDF();
            }
            
            // Calculate SHA-256 hash for integrity
            String documentHash = generateHash(pdfContent);
            
            // Create ContentVersion
            ContentVersion cv = new ContentVersion(
                Title = 'Audit Package - ' + pkg.Package_Name__c + ' - ' + Date.today().format(),
                PathOnClient = 'AuditPackage_' + pkg.Framework__c + '_' + Date.today().format() + '.pdf',
                VersionData = pdfContent,
                Description = 'Generated audit package PDF. SHA-256: ' + documentHash
            );
            insert cv;
            
            // Link to the audit package record
            linkContentToRecord(cv.Id, packageId);
            
            // Update package with generation timestamp
            pkg.Last_Generated__c = Datetime.now();
            update pkg;
            
            return cv.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate executive summary PDF
     * @param packageId The audit package ID
     * @return ContentVersion ID of the generated PDF
     */
    @AuraEnabled
    public static Id generateExecutiveSummary(String packageId) {
        validatePackageId(packageId);
        
        try {
            Elaro_Audit_Package__c pkg = queryAuditPackage(packageId);
            
            PageReference pdfPage = Page.ElaroExecutiveSummaryPDF;
            pdfPage.getParameters().put('id', packageId);
            
            Blob pdfContent;
            if (Test.isRunningTest()) {
                pdfContent = Blob.valueOf('Test Executive Summary PDF');
            } else {
                pdfContent = pdfPage.getContentAsPDF();
            }
            
            String documentHash = generateHash(pdfContent);
            
            ContentVersion cv = new ContentVersion(
                Title = 'Executive Summary - ' + pkg.Package_Name__c + ' - ' + Date.today().format(),
                PathOnClient = 'ExecutiveSummary_' + pkg.Framework__c + '_' + Date.today().format() + '.pdf',
                VersionData = pdfContent,
                Description = 'Executive summary PDF. SHA-256: ' + documentHash
            );
            insert cv;
            
            linkContentToRecord(cv.Id, packageId);
            
            return cv.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating executive summary: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate detailed evidence report
     * @param packageId The audit package ID
     * @param controlIds List of control IDs to filter (optional)
     * @return ContentVersion ID of the generated PDF
     */
    @AuraEnabled
    public static Id generateEvidenceReport(String packageId, List&lt;String&gt; controlIds) {
        validatePackageId(packageId);
        
        try {
            Elaro_Audit_Package__c pkg = queryAuditPackage(packageId);
            
            PageReference pdfPage = Page.ElaroEvidenceReportPDF;
            pdfPage.getParameters().put('id', packageId);
            
            if (controlIds != null &amp;&amp; !controlIds.isEmpty()) {
                pdfPage.getParameters().put('controls', String.join(controlIds, ','));
            }
            
            Blob pdfContent;
            if (Test.isRunningTest()) {
                pdfContent = Blob.valueOf('Test Evidence Report PDF');
            } else {
                pdfContent = pdfPage.getContentAsPDF();
            }
            
            String documentHash = generateHash(pdfContent);
            
            ContentVersion cv = new ContentVersion(
                Title = 'Evidence Report - ' + pkg.Package_Name__c + ' - ' + Date.today().format(),
                PathOnClient = 'EvidenceReport_' + pkg.Framework__c + '_' + Date.today().format() + '.pdf',
                VersionData = pdfContent,
                Description = 'Detailed evidence report PDF. SHA-256: ' + documentHash
            );
            insert cv;
            
            linkContentToRecord(cv.Id, packageId);
            
            return cv.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating evidence report: ' + e.getMessage());
        }
    }
    
    /**
     * @description Batch generate PDFs for multiple packages
     * @param packageIds List of audit package IDs
     * @return List of ContentVersion IDs
     */
    public static List&lt;Id&gt; batchGeneratePDFs(List&lt;String&gt; packageIds) {
        List&lt;Id&gt; contentVersionIds = new List&lt;Id&gt;();
        
        for (String packageId : packageIds) {
            try {
                Id cvId = generateAuditPackagePDF(packageId);
                contentVersionIds.add(cvId);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error generating PDF for package ' + packageId + ': ' + e.getMessage());
            }
        }
        
        return contentVersionIds;
    }
    
    /**
     * @description Generate CSV export of audit package evidence
     * @param packageId The audit package ID
     * @return CSV content as string
     */
    @AuraEnabled
    public static String generateCSVExport(String packageId) {
        validatePackageId(packageId);
        
        try {
            // Query evidence items
            List&lt;Elaro_Evidence_Item__c&gt; evidence = [
                SELECT Id, Name, Evidence_Type__c, Evidence_Date__c, Description__c, 
                       Status__c, CreatedDate
                FROM Elaro_Evidence_Item__c
                WHERE Audit_Package__c = :packageId
                ORDER BY Evidence_Date__c DESC
            ];
            
            // Build CSV content
            String csv = 'Evidence ID,Name,Type,Date,Description,Status,Created Date\n';
            
            for (Elaro_Evidence_Item__c item : evidence) {
                csv += escapeCSVField(item.Id) + ',';
                csv += escapeCSVField(item.Name) + ',';
                csv += escapeCSVField(item.Evidence_Type__c) + ',';
                csv += escapeCSVField(String.valueOf(item.Evidence_Date__c)) + ',';
                csv += escapeCSVField(item.Description__c) + ',';
                csv += escapeCSVField(item.Status__c) + ',';
                csv += escapeCSVField(String.valueOf(item.CreatedDate)) + '\n';
            }
            
            return csv;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating CSV: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate JSON export of audit package
     * @param packageId The audit package ID
     * @return JSON content as string
     */
    @AuraEnabled
    public static String generateJSONExport(String packageId) {
        validatePackageId(packageId);
        
        try {
            // Query audit package
            Elaro_Audit_Package__c pkg = queryAuditPackage(packageId);
            
            // Query evidence items
            List&lt;Elaro_Evidence_Item__c&gt; evidence = [
                SELECT Id, Name, Evidence_Type__c, Evidence_Date__c, Description__c, 
                       Status__c, CreatedDate
                FROM Elaro_Evidence_Item__c
                WHERE Audit_Package__c = :packageId
                ORDER BY Evidence_Date__c DESC
            ];
            
            // Build export object
            Map&lt;String, Object&gt; exportData = new Map&lt;String, Object&gt;{
                'exportDate' =&gt; Datetime.now(),
                'package' =&gt; new Map&lt;String, Object&gt;{
                    'id' =&gt; pkg.Id,
                    'name' =&gt; pkg.Package_Name__c,
                    'framework' =&gt; pkg.Framework__c,
                    'status' =&gt; pkg.Status__c,
                    'periodStart' =&gt; pkg.Audit_Period_Start__c,
                    'periodEnd' =&gt; pkg.Audit_Period_End__c
                },
                'evidence' =&gt; new List&lt;Map&lt;String, Object&gt;&gt;(),
                'metadata' =&gt; new Map&lt;String, Object&gt;{
                    'totalEvidence' =&gt; evidence.size(),
                    'generatedBy' =&gt; UserInfo.getName(),
                    'generatedAt' =&gt; Datetime.now()
                }
            };
            
            // Add evidence items
            List&lt;Map&lt;String, Object&gt;&gt; evidenceList = new List&lt;Map&lt;String, Object&gt;&gt;();
            for (Elaro_Evidence_Item__c item : evidence) {
                evidenceList.add(new Map&lt;String, Object&gt;{
                    'id' =&gt; item.Id,
                    'name' =&gt; item.Name,
                    'type' =&gt; item.Evidence_Type__c,
                    'date' =&gt; item.Evidence_Date__c,
                    'description' =&gt; item.Description__c,
                    'status' =&gt; item.Status__c,
                    'createdDate' =&gt; item.CreatedDate
                });
            }
            exportData.put('evidence', evidenceList);
            
            return JSON.serializePretty(exportData);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating JSON: ' + e.getMessage());
        }
    }
    
    /**
     * @description Save CSV export as ContentVersion
     * @param packageId The audit package ID
     * @return ContentVersion ID
     */
    @AuraEnabled
    public static Id saveCSVExport(String packageId) {
        String csvContent = generateCSVExport(packageId);
        Elaro_Audit_Package__c pkg = queryAuditPackage(packageId);
        
        ContentVersion cv = new ContentVersion(
            Title = 'Evidence Export - ' + pkg.Package_Name__c + ' - ' + Date.today().format(),
            PathOnClient = 'EvidenceExport_' + pkg.Framework__c + '_' + Date.today().format() + '.csv',
            VersionData = Blob.valueOf(csvContent),
            Description = 'CSV export of audit evidence'
        );
        insert cv;
        
        linkContentToRecord(cv.Id, packageId);
        
        return cv.Id;
    }
    
    /**
     * @description Save JSON export as ContentVersion
     * @param packageId The audit package ID
     * @return ContentVersion ID
     */
    @AuraEnabled
    public static Id saveJSONExport(String packageId) {
        String jsonContent = generateJSONExport(packageId);
        Elaro_Audit_Package__c pkg = queryAuditPackage(packageId);
        
        ContentVersion cv = new ContentVersion(
            Title = 'Package Export - ' + pkg.Package_Name__c + ' - ' + Date.today().format(),
            PathOnClient = 'PackageExport_' + pkg.Framework__c + '_' + Date.today().format() + '.json',
            VersionData = Blob.valueOf(jsonContent),
            Description = 'JSON export of audit package'
        );
        insert cv;
        
        linkContentToRecord(cv.Id, packageId);
        
        return cv.Id;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE HELPER METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Validate package ID
     * @param packageId The ID to validate
     */
    private static void validatePackageId(String packageId) {
        if (String.isBlank(packageId)) {
            throw new AuraHandledException('Package ID is required');
        }
    }
    
    /**
     * @description Query audit package with error handling
     * @param packageId The package ID
     * @return Elaro_Audit_Package__c record
     */
    private static Elaro_Audit_Package__c queryAuditPackage(String packageId) {
        List&lt;Elaro_Audit_Package__c&gt; packages = [
            SELECT Id, Name, Package_Name__c, Framework__c, Status__c,
                   Audit_Period_Start__c, Audit_Period_End__c, Last_Generated__c
            FROM Elaro_Audit_Package__c
            WHERE Id = :packageId
            LIMIT 1
        ];
        
        if (packages.isEmpty()) {
            throw new AuraHandledException('Audit package not found: ' + packageId);
        }
        
        return packages[0];
    }
    
    /**
     * @description Generate SHA-256 hash for document integrity
     * @param content The content to hash
     * @return Hex-encoded hash string
     */
    private static String generateHash(Blob content) {
        Blob hash = Crypto.generateDigest('SHA-256', content);
        return EncodingUtil.convertToHex(hash);
    }
    
    /**
     * @description Link ContentVersion to a record
     * @param contentVersionId The ContentVersion ID
     * @param recordId The record to link to
     */
    private static void linkContentToRecord(Id contentVersionId, Id recordId) {
        // Query the ContentDocumentId
        ContentVersion cv = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersionId
        ];
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = recordId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
    }
    
    /**
     * @description Escape a field value for CSV
     * @param value The value to escape
     * @return Escaped value
     */
    private static String escapeCSVField(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        
        // If contains comma, newline, or quote, wrap in quotes
        if (value.contains(',') || value.contains('\n') || value.contains('"')) {
            // Escape existing quotes
            value = value.replace('"', '""');
            return '"' + value + '"';
        }
        
        return value;
    }
}
