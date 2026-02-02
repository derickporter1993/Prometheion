/**
 * ComplianceReportScheduler - Automated Compliance Report Generation and Delivery
 *
 * Schedules and sends compliance reports to stakeholders with configurable frequencies.
 * Supports daily, weekly, and monthly report delivery with framework filtering.
 *
 * Usage:
 * - Schedule via Setup → Apex → Schedule Apex
 * - Or call ComplianceReportScheduler.scheduleReport() programmatically
 * - Use Configuration UI (reportSchedulerConfig LWC) for user-friendly setup
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class ComplianceReportScheduler implements Schedulable {

    // Logging prefix for easy filtering
    private static final String LOG_PREFIX = '[ComplianceReportScheduler] ';

    // Report frequency options
    public enum Frequency { DAILY, WEEKLY, MONTHLY }

    // Instance variables for scheduled job context
    private Frequency frequency;
    private List<String> recipients;
    private String framework;

    /**
     * Default constructor for basic scheduling
     */
    public ComplianceReportScheduler() {
        this.frequency = Frequency.WEEKLY;
        this.recipients = new List<String>();
        this.framework = 'ALL';
    }

    /**
     * Parameterized constructor for custom scheduling
     * @param freq Report frequency
     * @param recipientEmails List of recipient email addresses
     * @param frameworkFilter Framework to filter (or 'ALL')
     */
    public ComplianceReportScheduler(Frequency freq, List<String> recipientEmails, String frameworkFilter) {
        this.frequency = freq;
        this.recipients = recipientEmails != null ? recipientEmails : new List<String>();
        this.framework = String.isNotBlank(frameworkFilter) ? frameworkFilter : 'ALL';
    }

    /**
     * Execute method for Schedulable interface
     */
    public void execute(SchedulableContext ctx) {
        System.debug(LoggingLevel.INFO, LOG_PREFIX + 'Executing scheduled report for framework: ' + framework);

        // If no recipients configured, get from custom settings or default to running user
        if (recipients.isEmpty()) {
            recipients = getDefaultRecipients();
        }

        if (!recipients.isEmpty()) {
            generateAndSendReport(framework, recipients);
        } else {
            System.debug(LoggingLevel.WARN, LOG_PREFIX + 'No recipients configured for report');
        }
    }

    /**
     * Schedule a new compliance report
     * @param frequencyStr Report frequency (DAILY, WEEKLY, MONTHLY)
     * @param recipientEmails Comma-separated or list of email addresses
     * @param frameworkFilter Framework filter (e.g., 'HIPAA', 'SOC2', 'ALL')
     * @return Job ID of the scheduled report
     */
    @AuraEnabled
    public static String scheduleReport(String frequencyStr, List<String> recipientEmails, String frameworkFilter) {
        // Validate input
        if (String.isBlank(frequencyStr)) {
            throw new IllegalArgumentException('Frequency is required');
        }

        Frequency freq;
        try {
            freq = Frequency.valueOf(frequencyStr.toUpperCase());
        } catch (Exception e) {
            throw new IllegalArgumentException('Invalid frequency. Use DAILY, WEEKLY, or MONTHLY');
        }

        // Validate recipients
        List<String> validRecipients = validateEmails(recipientEmails);
        if (validRecipients.isEmpty()) {
            throw new IllegalArgumentException('At least one valid email recipient is required');
        }

        // Validate framework
        String framework = String.isNotBlank(frameworkFilter) ? frameworkFilter.toUpperCase() : 'ALL';
        if (framework != 'ALL' && !ElaroConstants.SUPPORTED_FRAMEWORKS.contains(framework)) {
            throw new IllegalArgumentException('Invalid framework: ' + frameworkFilter);
        }

        // Generate cron expression
        String cronExpression = getCronExpression(freq);
        String jobName = generateJobName(freq, framework);

        // Create and schedule the job
        ComplianceReportScheduler scheduler = new ComplianceReportScheduler(freq, validRecipients, framework);
        String jobId = System.schedule(jobName, cronExpression, scheduler);

        System.debug(LoggingLevel.INFO, LOG_PREFIX + 'Scheduled report - JobId: ' + jobId + ', Name: ' + jobName);

        return jobId;
    }

    /**
     * Get all scheduled compliance reports
     * @return List of scheduled report jobs
     */
    @AuraEnabled(cacheable=true)
    public static List<ScheduledReport> getScheduledReports() {
        List<ScheduledReport> reports = new List<ScheduledReport>();

        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name, NextFireTime, State, CronExpression
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'Elaro%Report%'
            WITH USER_MODE
            ORDER BY NextFireTime ASC
            LIMIT 50
        ];

        for (CronTrigger job : jobs) {
            ScheduledReport report = new ScheduledReport();
            report.jobId = job.Id;
            report.name = job.CronJobDetail.Name;
            report.nextRun = job.NextFireTime;
            report.status = job.State;
            report.cronExpression = job.CronExpression;

            // Parse frequency and framework from job name
            report.frequency = parseFrequencyFromJobName(job.CronJobDetail.Name);
            report.framework = parseFrameworkFromJobName(job.CronJobDetail.Name);

            reports.add(report);
        }

        return reports;
    }

    /**
     * Cancel a scheduled report
     * @param jobId The CronTrigger ID to cancel
     */
    @AuraEnabled
    public static void cancelScheduledReport(String jobId) {
        if (String.isBlank(jobId)) {
            throw new IllegalArgumentException('Job ID is required');
        }

        try {
            System.abortJob(jobId);
            System.debug(LoggingLevel.INFO, LOG_PREFIX + 'Cancelled scheduled report: ' + jobId);
        } catch (Exception e) {
            throw new AuraHandledException('Failed to cancel report: ' + e.getMessage());
        }
    }

    /**
     * Send a test report immediately
     * @param frameworkFilter Framework to include
     * @param recipientEmails Recipients for the test
     */
    @AuraEnabled
    public static void sendTestReport(String frameworkFilter, List<String> recipientEmails) {
        List<String> validRecipients = validateEmails(recipientEmails);
        if (validRecipients.isEmpty()) {
            validRecipients.add(UserInfo.getUserEmail());
        }

        String framework = String.isNotBlank(frameworkFilter) ? frameworkFilter : 'ALL';
        generateAndSendReport(framework, validRecipients);
    }

    /**
     * Generate and send the compliance report
     */
    private static void generateAndSendReport(String framework, List<String> recipientEmails) {
        System.debug(LoggingLevel.INFO, LOG_PREFIX + 'Generating report for framework: ' + framework);

        try {
            // Generate report content
            ComplianceReportGenerator.ReportData reportData = ComplianceReportGenerator.generateReportData(framework);

            // Build email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(recipientEmails);
            email.setSubject(buildEmailSubject(framework, reportData));
            email.setHtmlBody(buildEmailBody(framework, reportData));

            // Add PDF attachment if we have gaps to report
            if (reportData.gaps != null && !reportData.gaps.isEmpty()) {
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Compliance_Report_' + Date.today().format() + '.csv');
                attachment.setBody(Blob.valueOf(buildCsvContent(reportData)));
                attachment.setContentType('text/csv');
                email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
            }

            // Send email (skip in test context)
            if (!Test.isRunningTest()) {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            }

            System.debug(LoggingLevel.INFO, LOG_PREFIX + 'Report sent successfully to ' + recipientEmails.size() + ' recipients');

            // Log audit entry
            logReportDelivery(framework, recipientEmails);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + 'Error generating/sending report: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate report: ' + e.getMessage());
        }
    }

    /**
     * Build email subject line
     */
    private static String buildEmailSubject(String framework, ComplianceReportGenerator.ReportData reportData) {
        String emoji = ElaroConstants.getScoreEmoji(reportData.scoreResult.overallScore);
        String frameworkLabel = framework == 'ALL' ? 'All Frameworks' : framework;
        return emoji + ' Elaro Compliance Report - ' + frameworkLabel + ' - ' + Date.today().format();
    }

    /**
     * Build HTML email body
     */
    private static String buildEmailBody(String framework, ComplianceReportGenerator.ReportData reportData) {
        String scoreColor = ElaroConstants.getScoreColor(reportData.scoreResult.overallScore);
        String frameworkLabel = framework == 'ALL' ? 'All Frameworks' : framework;

        String html = '<html><head><style>';
        html += 'body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }';
        html += '.container { max-width: 600px; margin: 0 auto; padding: 20px; }';
        html += '.header { background: #1a365d; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }';
        html += '.score-box { background: #f7fafc; padding: 20px; text-align: center; border: 1px solid #e2e8f0; }';
        html += '.score { font-size: 48px; font-weight: bold; color: ' + scoreColor + '; }';
        html += '.rating { font-size: 18px; color: #4a5568; }';
        html += '.section { padding: 20px; border: 1px solid #e2e8f0; border-top: none; }';
        html += '.gap-table { width: 100%; border-collapse: collapse; margin-top: 10px; }';
        html += '.gap-table th, .gap-table td { border: 1px solid #e2e8f0; padding: 8px; text-align: left; }';
        html += '.gap-table th { background: #edf2f7; }';
        html += '.critical { color: #c53030; font-weight: bold; }';
        html += '.high { color: #dd6b20; }';
        html += '.medium { color: #d69e2e; }';
        html += '.low { color: #38a169; }';
        html += '.footer { background: #f7fafc; padding: 15px; text-align: center; font-size: 12px; color: #718096; border-radius: 0 0 8px 8px; }';
        html += '</style></head><body><div class="container">';

        // Header
        html += '<div class="header">';
        html += '<h1>Elaro Compliance Report</h1>';
        html += '<p>' + frameworkLabel + ' | ' + Date.today().format() + '</p>';
        html += '</div>';

        // Score Box
        html += '<div class="score-box">';
        html += '<div class="score">' + reportData.scoreResult.overallScore.setScale(0) + '/100</div>';
        html += '<div class="rating">' + reportData.scoreResult.rating + '</div>';
        html += '</div>';

        // Framework Scores Section
        html += '<div class="section">';
        html += '<h2>Framework Scores</h2>';
        html += '<table class="gap-table">';
        html += '<tr><th>Framework</th><th>Score</th><th>Status</th></tr>';

        for (String fw : reportData.scoreResult.frameworkScores.keySet()) {
            Decimal score = reportData.scoreResult.frameworkScores.get(fw);
            String status = ElaroConstants.getRatingFromScore(score);
            String statusClass = score >= 80 ? 'low' : (score >= 60 ? 'medium' : (score >= 40 ? 'high' : 'critical'));
            html += '<tr><td>' + fw + '</td><td>' + score.setScale(1) + '</td><td class="' + statusClass + '">' + status + '</td></tr>';
        }
        html += '</table></div>';

        // Open Gaps Section
        if (reportData.gaps != null && !reportData.gaps.isEmpty()) {
            html += '<div class="section">';
            html += '<h2>Open Compliance Gaps (' + reportData.gaps.size() + ')</h2>';
            html += '<table class="gap-table">';
            html += '<tr><th>Gap</th><th>Severity</th><th>Framework</th><th>Status</th></tr>';

            Integer maxGaps = Math.min(reportData.gaps.size(), 10);
            for (Integer i = 0; i < maxGaps; i++) {
                Compliance_Gap__c gap = reportData.gaps[i];
                String severityClass = gap.Severity__c == 'Critical' ? 'critical' :
                                       (gap.Severity__c == 'High' ? 'high' :
                                       (gap.Severity__c == 'Medium' ? 'medium' : 'low'));
                html += '<tr>';
                html += '<td>' + String.valueOf(gap.Name).abbreviate(50) + '</td>';
                html += '<td class="' + severityClass + '">' + gap.Severity__c + '</td>';
                html += '<td>' + (gap.Framework__c != null ? gap.Framework__c : 'N/A') + '</td>';
                html += '<td>' + (gap.Status__c != null ? gap.Status__c : 'Open') + '</td>';
                html += '</tr>';
            }

            if (reportData.gaps.size() > 10) {
                html += '<tr><td colspan="4" style="text-align:center; font-style:italic;">... and ' + (reportData.gaps.size() - 10) + ' more gaps (see attached CSV)</td></tr>';
            }
            html += '</table></div>';
        }

        // Top Risks Section
        if (reportData.scoreResult.topRisks != null && !reportData.scoreResult.topRisks.isEmpty()) {
            html += '<div class="section">';
            html += '<h2>Top Risks</h2>';
            html += '<ul>';
            for (ElaroComplianceScorer.Risk risk : reportData.scoreResult.topRisks) {
                html += '<li><strong>' + risk.title + '</strong> (' + risk.severity + ')<br/>';
                html += '<span style="color:#718096">' + risk.description + '</span></li>';
            }
            html += '</ul></div>';
        }

        // Footer
        html += '<div class="footer">';
        html += '<p>Generated by Elaro Compliance Platform</p>';
        html += '<p>Report generated at ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss z') + '</p>';
        html += '</div>';

        html += '</div></body></html>';
        return html;
    }

    /**
     * Build CSV content for attachment
     */
    private static String buildCsvContent(ComplianceReportGenerator.ReportData reportData) {
        String csv = 'Gap Name,Severity,Framework,Status,Description,Created Date\n';

        for (Compliance_Gap__c gap : reportData.gaps) {
            csv += '"' + String.valueOf(gap.Name).replace('"', '""') + '",';
            csv += '"' + (gap.Severity__c != null ? gap.Severity__c : '') + '",';
            csv += '"' + (gap.Framework__c != null ? gap.Framework__c : '') + '",';
            csv += '"' + (gap.Status__c != null ? gap.Status__c : '') + '",';
            csv += '"' + (gap.Description__c != null ? gap.Description__c.replace('"', '""').abbreviate(200) : '') + '",';
            csv += '"' + (gap.CreatedDate != null ? gap.CreatedDate.format('yyyy-MM-dd') : '') + '"\n';
        }

        return csv;
    }

    /**
     * Get default recipients from custom settings or org defaults
     */
    private static List<String> getDefaultRecipients() {
        List<String> defaults = new List<String>();

        // Try to get from custom settings
        try {
            // Check if Elaro_Settings__c exists and has report recipients
            // Fall back to running user's email
            defaults.add(UserInfo.getUserEmail());
        } catch (Exception e) {
            defaults.add(UserInfo.getUserEmail());
        }

        return defaults;
    }

    /**
     * Validate email addresses
     */
    private static List<String> validateEmails(List<String> emails) {
        List<String> valid = new List<String>();
        if (emails == null) return valid;

        Pattern emailPattern = Pattern.compile('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');

        for (String email : emails) {
            if (String.isNotBlank(email)) {
                String trimmed = email.trim();
                Matcher matcher = emailPattern.matcher(trimmed);
                if (matcher.matches()) {
                    valid.add(trimmed);
                }
            }
        }

        return valid;
    }

    /**
     * Generate cron expression for frequency
     */
    private static String getCronExpression(Frequency freq) {
        switch on freq {
            when DAILY {
                return '0 0 8 * * ?'; // 8 AM daily
            }
            when WEEKLY {
                return '0 0 8 ? * MON'; // 8 AM every Monday
            }
            when MONTHLY {
                return '0 0 8 1 * ?'; // 8 AM on 1st of each month
            }
            when else {
                return '0 0 8 ? * MON'; // Default to weekly
            }
        }
    }

    /**
     * Generate unique job name
     */
    private static String generateJobName(Frequency freq, String framework) {
        return 'Elaro ' + freq.name() + ' Report - ' + framework + ' - ' + Datetime.now().format('yyyyMMddHHmmss');
    }

    /**
     * Parse frequency from job name
     */
    private static String parseFrequencyFromJobName(String jobName) {
        if (jobName.containsIgnoreCase('DAILY')) return 'DAILY';
        if (jobName.containsIgnoreCase('MONTHLY')) return 'MONTHLY';
        return 'WEEKLY';
    }

    /**
     * Parse framework from job name
     */
    private static String parseFrameworkFromJobName(String jobName) {
        for (String fw : ElaroConstants.SUPPORTED_FRAMEWORKS) {
            if (jobName.containsIgnoreCase(fw)) {
                return fw;
            }
        }
        return 'ALL';
    }

    /**
     * Log report delivery for audit purposes
     */
    private static void logReportDelivery(String framework, List<String> recipients) {
        try {
            // Log to Elaro_Audit_Log__c if it exists
            Elaro_Audit_Log__c auditLog = new Elaro_Audit_Log__c(
                Action__c = 'REPORT_DELIVERED',
                Entity_Type__c = 'ComplianceReport',
                Details__c = 'Framework: ' + framework + ', Recipients: ' + String.join(recipients, ', '),
                Timestamp__c = Datetime.now()
            );

            // Use security-safe insert
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.CREATABLE,
                new List<Elaro_Audit_Log__c>{ auditLog }
            );

            List<Elaro_Audit_Log__c> sanitized = decision.getRecords();
            if (!sanitized.isEmpty()) {
                insert sanitized;
            }
        } catch (Exception e) {
            // Don't fail report delivery if audit logging fails
            System.debug(LoggingLevel.WARN, LOG_PREFIX + 'Audit logging failed: ' + e.getMessage());
        }
    }

    /**
     * Wrapper class for scheduled report information
     */
    public class ScheduledReport {
        @AuraEnabled public String jobId;
        @AuraEnabled public String name;
        @AuraEnabled public String frequency;
        @AuraEnabled public String framework;
        @AuraEnabled public Datetime nextRun;
        @AuraEnabled public String status;
        @AuraEnabled public String cronExpression;
    }
}
