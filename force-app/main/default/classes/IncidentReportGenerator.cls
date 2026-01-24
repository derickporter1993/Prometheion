/**
 * IncidentReportGenerator
 *
 * Generates incident reports for SOC2 compliance.
 * Extracted from SOC2IncidentResponseService for single-responsibility.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class IncidentReportGenerator {

    /**
     * Generate incident report content in Markdown format
     */
    public String generateIncidentReportContent(HIPAA_Breach__c incident) {
        String report = '# Security Incident Report\n\n';
        report += '**Incident ID:** ' + incident.Name + '\n';
        report += '**Type:** ' + incident.Breach_Type__c + '\n';
        report += '**Severity:** ' + incident.Risk_Level__c + '\n';
        report += '**Status:** ' + incident.Status__c + '\n\n';

        report += '## Timeline\n\n';
        report += '- **Detected:** ' + (incident.Discovery_Date__c != null ? String.valueOf(incident.Discovery_Date__c) : 'N/A') + '\n';
        report += '- **Status:** ' + (incident.Status__c != null ? incident.Status__c : 'Unknown') + '\n\n';

        report += '## Description\n\n';
        report += (incident.Description__c != null ? incident.Description__c : 'No description provided') + '\n\n';

        report += '## Impact\n\n';
        report += '- **Records Affected:** ' + (incident.Records_Affected__c != null ? String.valueOf(incident.Records_Affected__c.intValue()) : 'Unknown') + '\n\n';

        report += '## Analysis\n\n';
        report += (incident.Description__c != null ? incident.Description__c : 'Pending analysis') + '\n\n';

        report += '---\n';
        report += '*Report generated: ' + DateTime.now().format() + '*\n';

        return report;
    }

    /**
     * Generate and save incident report as ContentVersion
     */
    public Id generateBreachReport(Id breachId) {
        HIPAA_Breach__c incident = [
            SELECT Id, Name, Breach_Type__c, Description__c, Risk_Level__c, Status__c,
                   Discovery_Date__c, Records_Affected__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
        ];

        String report = generateIncidentReportContent(incident);

        ContentVersion cv = new ContentVersion(
            Title = 'Incident_Report_' + incident.Name,
            PathOnClient = 'Incident_Report_' + incident.Name + '.md',
            VersionData = Blob.valueOf(report),
            Origin = 'H'
        );
        PrometheionSecurityUtils.validateCRUDAccess('ContentVersion', PrometheionSecurityUtils.DmlOperation.DML_INSERT);
        insert cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH SECURITY_ENFORCED];

        return cv.ContentDocumentId;
    }
}
