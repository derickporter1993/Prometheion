/**
 * @description Controller extension for Visualforce PDF pages
 * Provides data for audit package, executive summary, and evidence report PDFs
 * @group Export &amp; Delivery
 * @author Elaro Team
 */
public with sharing class ElaroPDFController {
    
    // ═══════════════════════════════════════════════════════════════
    // PROPERTIES
    // ═══════════════════════════════════════════════════════════════
    
    public Elaro_Audit_Package__c auditPackage { get; private set; }
    public List&lt;Elaro_Evidence_Item__c&gt; evidenceItems { get; private set; }
    public Integer evidenceCount { get; private set; }
    public List&lt;ControlSummary&gt; controlSummary { get; private set; }
    public String documentHash { get; private set; }
    public Datetime generatedAt { get; private set; }
    public String generatedBy { get; private set; }
    
    // Statistics
    public Integer criticalCount { get; private set; }
    public Integer highCount { get; private set; }
    public Integer mediumCount { get; private set; }
    public Integer lowCount { get; private set; }
    
    // Filtered controls (for evidence report)
    public List&lt;String&gt; selectedControls { get; private set; }
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Constructor for standard controller extension
     * @param stdController The standard controller for Elaro_Audit_Package__c
     */
    public ElaroPDFController(ApexPages.StandardController stdController) {
        Id packageId = stdController.getId();
        
        if (packageId == null) {
            packageId = ApexPages.currentPage().getParameters().get('id');
        }
        
        if (packageId != null) {
            loadPackageData(packageId);
            loadEvidenceData(packageId);
            calculateStatistics();
            buildControlSummary();
            generateDocumentMetadata();
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // DATA LOADING METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Load audit package data
     * @param packageId The package ID
     */
    private void loadPackageData(Id packageId) {
        List&lt;Elaro_Audit_Package__c&gt; packages = [
            SELECT Id, Name, Package_Name__c, Framework__c, Status__c,
                   Audit_Period_Start__c, Audit_Period_End__c, 
                   Last_Generated__c, CreatedDate, CreatedById,
                   CreatedBy.Name
            FROM Elaro_Audit_Package__c
            WHERE Id = :packageId
            LIMIT 1
        ];
        
        if (!packages.isEmpty()) {
            auditPackage = packages[0];
        }
    }
    
    /**
     * @description Load evidence items for the package
     * @param packageId The package ID
     */
    private void loadEvidenceData(Id packageId) {
        // Check for control filter parameter
        String controlFilter = ApexPages.currentPage().getParameters().get('controls');
        selectedControls = new List&lt;String&gt;();
        
        if (String.isNotBlank(controlFilter)) {
            selectedControls = controlFilter.split(',');
        }
        
        // Build query
        String query = 'SELECT Id, Name, Evidence_Type__c, Evidence_Date__c, ' +
                       'Description__c, Status__c, CreatedDate ' +
                       'FROM Elaro_Evidence_Item__c ' +
                       'WHERE Audit_Package__c = :packageId ';
        
        // Note: Control filtering would require a Control_Reference__c field
        // For now, we'll load all evidence
        
        query += 'ORDER BY Evidence_Date__c DESC LIMIT 5000';
        
        evidenceItems = Database.query(query);
        evidenceCount = evidenceItems.size();
    }
    
    /**
     * @description Calculate risk statistics
     */
    private void calculateStatistics() {
        criticalCount = 0;
        highCount = 0;
        mediumCount = 0;
        lowCount = 0;
        
        Map&lt;String, String&gt; eventRiskLevels = new Map&lt;String, String&gt;{
            'LoginAs' =&gt; 'CRITICAL',
            'ReportExport' =&gt; 'CRITICAL',
            'ContentDistribution' =&gt; 'CRITICAL',
            'API' =&gt; 'HIGH',
            'BulkApiResult' =&gt; 'HIGH',
            'PermissionSetEventLog' =&gt; 'HIGH',
            'Login' =&gt; 'MEDIUM',
            'ApexExecution' =&gt; 'MEDIUM',
            'Logout' =&gt; 'LOW'
        };
        
        for (Elaro_Evidence_Item__c item : evidenceItems) {
            String riskLevel = eventRiskLevels.containsKey(item.Evidence_Type__c)
                ? eventRiskLevels.get(item.Evidence_Type__c)
                : 'MEDIUM';
            
            if (riskLevel == 'CRITICAL') {
                criticalCount++;
            } else if (riskLevel == 'HIGH') {
                highCount++;
            } else if (riskLevel == 'MEDIUM') {
                mediumCount++;
            } else {
                lowCount++;
            }
        }
    }
    
    /**
     * @description Build control summary for the package
     */
    private void buildControlSummary() {
        controlSummary = new List&lt;ControlSummary&gt;();
        
        // Group evidence by type
        Map&lt;String, Integer&gt; typeCounts = new Map&lt;String, Integer&gt;();
        
        for (Elaro_Evidence_Item__c item : evidenceItems) {
            String eventType = item.Evidence_Type__c;
            if (!typeCounts.containsKey(eventType)) {
                typeCounts.put(eventType, 0);
            }
            typeCounts.put(eventType, typeCounts.get(eventType) + 1);
        }
        
        // Build summary list
        for (String eventType : typeCounts.keySet()) {
            ControlSummary cs = new ControlSummary();
            cs.controlId = eventType;
            cs.controlName = getControlName(eventType);
            cs.evidenceCount = typeCounts.get(eventType);
            cs.status = cs.evidenceCount &gt; 0 ? 'Evidence Collected' : 'No Evidence';
            cs.riskLevel = ElaroShieldService.getRiskLevel(eventType);
            controlSummary.add(cs);
        }
        
        // Sort by evidence count descending
        controlSummary.sort();
    }
    
    /**
     * @description Generate document metadata
     */
    private void generateDocumentMetadata() {
        generatedAt = Datetime.now();
        generatedBy = UserInfo.getName();
        
        // Generate document hash based on content
        String contentSignature = String.valueOf(auditPackage?.Id) + 
                                  String.valueOf(evidenceCount) + 
                                  String.valueOf(generatedAt);
        Blob hashBlob = Crypto.generateDigest('SHA-256', Blob.valueOf(contentSignature));
        documentHash = EncodingUtil.convertToHex(hashBlob);
    }
    
    /**
     * @description Get human-readable control name
     * @param eventType The event type
     * @return Control name
     */
    private String getControlName(String eventType) {
        Map&lt;String, String&gt; controlNames = new Map&lt;String, String&gt;{
            'Login' =&gt; 'User Authentication Events',
            'LoginAs' =&gt; 'User Impersonation Events',
            'Logout' =&gt; 'Session Termination Events',
            'API' =&gt; 'API Access Events',
            'ReportExport' =&gt; 'Report Export Events',
            'ContentDistribution' =&gt; 'Content Sharing Events',
            'ApexExecution' =&gt; 'Code Execution Events',
            'PermissionSetEventLog' =&gt; 'Permission Change Events',
            'BulkApiResult' =&gt; 'Bulk Data Operation Events'
        };
        
        return controlNames.containsKey(eventType) 
            ? controlNames.get(eventType) 
            : eventType + ' Events';
    }
    
    // ═══════════════════════════════════════════════════════════════
    // UTILITY METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Get compliance score percentage
     * @return Compliance score
     */
    public Decimal getComplianceScore() {
        if (evidenceCount == 0) {
            return 0;
        }
        
        // Simple scoring: based on evidence coverage
        // Critical events reduce score, collected evidence increases it
        Decimal baseScore = 100;
        
        if (criticalCount &gt; 0) {
            baseScore -= Math.min(criticalCount * 5, 30);
        }
        if (highCount &gt; 0) {
            baseScore -= Math.min(highCount * 2, 20);
        }
        
        return Math.max(baseScore, 0).setScale(1);
    }
    
    /**
     * @description Get formatted date range
     * @return Date range string
     */
    public String getDateRange() {
        if (auditPackage == null) {
            return 'N/A';
        }
        
        String start = auditPackage.Audit_Period_Start__c != null 
            ? auditPackage.Audit_Period_Start__c.format() 
            : 'N/A';
        String endDate = auditPackage.Audit_Period_End__c != null 
            ? auditPackage.Audit_Period_End__c.format() 
            : 'N/A';
        
        return start + ' - ' + endDate;
    }
    
    /**
     * @description Get risk color class for styling
     * @param riskLevel The risk level
     * @return CSS color class
     */
    public String getRiskColorClass(String riskLevel) {
        Map&lt;String, String&gt; colorClasses = new Map&lt;String, String&gt;{
            'CRITICAL' =&gt; 'risk-critical',
            'HIGH' =&gt; 'risk-high',
            'MEDIUM' =&gt; 'risk-medium',
            'LOW' =&gt; 'risk-low'
        };
        
        return colorClasses.containsKey(riskLevel) 
            ? colorClasses.get(riskLevel) 
            : 'risk-medium';
    }
    
    // ═══════════════════════════════════════════════════════════════
    // INNER CLASSES
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Control summary wrapper class
     */
    public class ControlSummary implements Comparable {
        public String controlId { get; set; }
        public String controlName { get; set; }
        public Integer evidenceCount { get; set; }
        public String status { get; set; }
        public String riskLevel { get; set; }
        
        public Integer compareTo(Object other) {
            ControlSummary otherCS = (ControlSummary)other;
            // Sort by evidence count descending
            return otherCS.evidenceCount - this.evidenceCount;
        }
    }
}
