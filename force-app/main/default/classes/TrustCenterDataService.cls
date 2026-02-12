/**
 * Scheduled service for aggregating compliance data into Trust_Center_View__c.
 * Runs nightly to materialize public-safe compliance metrics.
 *
 * SECURITY NOTE: without sharing required because this is a scheduled system job
 * that aggregates data across all frameworks regardless of user context.
 * This class never exposes raw Compliance_Finding__c or Evidence__c data.
 * It only creates aggregated, anonymized metrics in Trust_Center_View__c.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Trust Center
 * @see Trust_Center_View__c
 * @see TrustCenterLinkService
 */
public without sharing class TrustCenterDataService implements Schedulable {

    /**
     * Schedulable entry point. Executes daily aggregation.
     *
     * @param ctx SchedulableContext provided by platform
     */
    public void execute(SchedulableContext ctx) {
        try {
            aggregateComplianceData();
        } catch (Exception e) {
            ElaroLogger.error('TrustCenterDataService.execute',
                e.getMessage(), e.getStackTraceString());
        }
    }

    /**
     * Aggregates compliance data from all frameworks into materialized views.
     * Deletes existing views and rebuilds from current compliance state.
     *
     * @throws DmlException if aggregation or delete/insert operations fail
     */
    public void aggregateComplianceData() {
        // Delete existing views to rebuild fresh
        List<Trust_Center_View__c> existingViews = [
            SELECT Id FROM Trust_Center_View__c WITH USER_MODE LIMIT 10000
        ];
        if (!existingViews.isEmpty()) {
            delete as user existingViews;
        }

        List<Trust_Center_View__c> newViews = new List<Trust_Center_View__c>();

        // Define frameworks to aggregate
        List<String> frameworks = new List<String>{
            'SOC2', 'HIPAA', 'ISO27001', 'GDPR', 'PCI_DSS',
            'CCPA', 'CMMC', 'FedRAMP', 'NIST_CSF'
        };

        for (String framework : frameworks) {
            Trust_Center_View__c view = buildFrameworkView(framework);
            if (view != null) {
                newViews.add(view);
            }
        }

        if (!newViews.isEmpty()) {
            insert as user newViews;
        }

        ElaroLogger.info('TrustCenterDataService.aggregateComplianceData',
            'Aggregated ' + newViews.size() + ' framework views');
    }

    /**
     * Builds a materialized view for a single framework by querying
     * compliance control status (assumes Compliance_Control__c exists).
     *
     * @param framework Framework identifier (e.g., 'SOC2', 'HIPAA')
     * @return Trust_Center_View__c record with aggregated metrics, or null if no data
     */
    @TestVisible
    private Trust_Center_View__c buildFrameworkView(String framework) {
        // SECURITY: Query assumes Compliance_Control__c has Framework__c and Status__c
        // This aggregates control counts, not raw finding data

        // Count total controls for framework
        Integer totalControls = [
            SELECT COUNT()
            FROM Compliance_Control__c
            WHERE Framework__c = :framework
            WITH USER_MODE
        ];

        if (totalControls == 0) {
            return null; // No controls for this framework
        }

        // Count compliant controls
        Integer compliantControls = [
            SELECT COUNT()
            FROM Compliance_Control__c
            WHERE Framework__c = :framework
            AND Status__c = 'Compliant'
            WITH USER_MODE
        ];

        // Calculate percentage
        Decimal compliancePercentage = totalControls > 0
            ? (Decimal.valueOf(compliantControls) / Decimal.valueOf(totalControls)) * 100
            : 0;

        // Query most recent audit date (if Assessment objects exist)
        Date lastAudit = null;
        List<AggregateResult> auditResults = [
            SELECT MAX(Assessment_Date__c) maxDate
            FROM Compliance_Assessment__c
            WHERE Framework__c = :framework
            WITH USER_MODE
            LIMIT 1
        ];
        if (!auditResults.isEmpty() && auditResults[0].get('maxDate') != null) {
            lastAudit = (Date) auditResults[0].get('maxDate');
        }

        // Determine certification status
        String certStatus = determineCertificationStatus(
            compliancePercentage, lastAudit
        );

        Trust_Center_View__c view = new Trust_Center_View__c(
            Name = getFrameworkLabel(framework),
            Framework__c = framework,
            Compliance_Percentage__c = compliancePercentage.setScale(2),
            Controls_Total__c = totalControls,
            Controls_Compliant__c = compliantControls,
            Last_Audit_Date__c = lastAudit,
            Certification_Status__c = certStatus,
            Badge_Image_URL__c = getBadgeUrl(framework, certStatus),
            Is_Public__c = (compliancePercentage >= 80.0) // Only show if 80%+ compliant
        );

        return view;
    }

    /**
     * Determines certification status based on compliance percentage and audit date.
     *
     * @param compliancePercentage Overall compliance percentage (0-100)
     * @param lastAuditDate Most recent audit date, or null if never audited
     * @return Certification status: Certified, In_Progress, Renewal_Required, Not_Started
     */
    private String determineCertificationStatus(
        Decimal compliancePercentage, Date lastAuditDate
    ) {
        if (compliancePercentage >= 95.0 && lastAuditDate != null) {
            // Check if audit is within 1 year
            if (lastAuditDate.daysBetween(Date.today()) <= 365) {
                return 'Certified';
            } else {
                return 'Renewal_Required';
            }
        } else if (compliancePercentage >= 50.0) {
            return 'In_Progress';
        } else {
            return 'Not_Started';
        }
    }

    /**
     * Returns user-friendly label for framework code.
     *
     * @param framework Framework code (e.g., 'SOC2')
     * @return Human-readable label (e.g., 'SOC 2')
     */
    private String getFrameworkLabel(String framework) {
        Map<String, String> labels = new Map<String, String>{
            'SOC2' => 'SOC 2',
            'HIPAA' => 'HIPAA',
            'ISO27001' => 'ISO 27001',
            'GDPR' => 'GDPR',
            'PCI_DSS' => 'PCI-DSS',
            'CCPA' => 'CCPA',
            'CMMC' => 'CMMC 2.0',
            'FedRAMP' => 'FedRAMP',
            'NIST_CSF' => 'NIST CSF'
        };
        return labels.get(framework) ?? framework;
    }

    /**
     * Returns badge image URL from Static Resources based on framework and status.
     *
     * @param framework Framework code
     * @param status Certification status
     * @return Static Resource URL or empty string
     */
    private String getBadgeUrl(String framework, String status) {
        if (status == 'Certified') {
            return '/resource/Elaro_Badge_' + framework;
        }
        return '';
    }
}
