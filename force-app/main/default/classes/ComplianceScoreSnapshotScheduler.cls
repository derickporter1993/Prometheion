/**
 * ComplianceScoreSnapshotScheduler
 *
 * Scheduled job to capture daily compliance scores across all frameworks.
 * Creates historical snapshots for trend analysis and audit evidence.
 *
 * Schedule: Daily (recommended)
 * Example: System.schedule('Daily Compliance Snapshot', '0 0 1 * * ?', new ComplianceScoreSnapshotScheduler());
 *
 * @author Elaro
 * @version 1.0
 * @since v3.1.0 (Spring '26)
 * @group Data Structures
 */
public with sharing class ComplianceScoreSnapshotScheduler implements Schedulable {

    private static final String JOB_NAME = 'Elaro Compliance Snapshot';

    // Frameworks to evaluate
    private static final List<String> FRAMEWORKS = new List<String>{
        'SOC2', 'HIPAA', 'NIST', 'FedRAMP', 'GDPR', 'SOX', 'PCI-DSS', 'CCPA', 'GLBA', 'ISO27001'
    };

    /**
     * Schedulable execute method
     */
    public void execute(SchedulableContext ctx) {
        // Run in Queueable context for better error handling and monitoring
        if (!Test.isRunningTest()) {
            AsyncOptions options = new AsyncOptions();
            options.setMaximumQueueableStackDepth(5);
            options.setDuplicateSignature(
                new QueueableDuplicateSignature.Builder()
                    .addString('ComplianceSnapshotDaily')
                    .build()
            );
            System.enqueueJob(new ComplianceSnapshotQueueable(), options);
        } else {
            // Run synchronously in tests
            captureSnapshots();
        }
    }

    /**
     * Queueable implementation for compliance snapshot processing
     * Provides better error handling, chaining, and monitoring than @future
     */
    public class ComplianceSnapshotQueueable implements Queueable {
        public void execute(QueueableContext context) {
            try {
                ComplianceScoreSnapshotScheduler scheduler = new ComplianceScoreSnapshotScheduler();
                scheduler.captureSnapshots();
                
                ElaroLogger.info('ComplianceScoreSnapshotScheduler.ComplianceSnapshotQueueable',
                    'Successfully captured compliance score snapshots');
            } catch (Exception e) {
                ElaroLogger.error('ComplianceScoreSnapshotScheduler.ComplianceSnapshotQueueable',
                    e.getMessage(), e.getStackTraceString());
            }
        }
    }

    /**
     * Capture compliance score snapshots for all frameworks
     */
    public void captureSnapshots() {
        List<Compliance_Score__c> snapshots = new List<Compliance_Score__c>();
        Map<String, FrameworkResult> results = new Map<String, FrameworkResult>();

        try {
            // Evaluate each framework
            for (String framework : FRAMEWORKS) {
                FrameworkResult result = evaluateFramework(framework);
                results.put(framework, result);

                // Create snapshot record
                Compliance_Score__c snapshot = new Compliance_Score__c();
                snapshot.Framework__c = framework;
                snapshot.Score__c = result.score;
                snapshot.Status__c = result.compliant ? 'Compliant' : 'Non-Compliant';
                snapshot.Evaluation_Date__c = DateTime.now();
                snapshot.Gaps_Count__c = result.gapCount;
                snapshot.Violations_Count__c = result.violationCount;
                snapshot.Previous_Score__c = result.previousScore;
                snapshot.Score_Change__c = result.scoreChange;

                snapshots.add(snapshot);
            }

            // Insert all snapshots
            if (!snapshots.isEmpty()) {
                ElaroSecurityUtils.validateCRUDAccess('Compliance_Score__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
                insert as user snapshots;
            }

            // Calculate overall compliance score
            Decimal overallScore = calculateOverallScore(results);

            // Create summary record
            createDailySummary(results, overallScore);

            // Check for significant score drops
            checkScoreAlerts(results);

            // Log successful execution
            logExecution('Compliance snapshots captured', snapshots.size(), overallScore);

        } catch (Exception e) {
            logError('Snapshot capture failed: ' + e.getMessage());
        }
    }

    /**
     * Evaluate a specific framework
     */
    private FrameworkResult evaluateFramework(String framework) {
        FrameworkResult result = new FrameworkResult();
        result.framework = framework;
        result.score = 0;
        result.gapCount = 0;
        result.violationCount = 0;

        try {
            // Get service from factory
            IRiskScoringService service = ComplianceServiceFactory.getService(framework);

            if (service != null) {
                result.score = service.getComplianceScore();
                List<ComplianceServiceBase.Violation> violations = service.getViolations();
                result.violationCount = violations != null ? violations.size() : 0;
            }

            // Count active gaps for this framework (exclude verified/accepted)
            result.gapCount = [
                SELECT COUNT()
                FROM Compliance_Gap__c
                WHERE Framework__c = :framework
                AND Status__c NOT IN ('VERIFIED', 'ACCEPTED_RISK')
                WITH USER_MODE
            ];

            // Get previous score for comparison
            List<Compliance_Score__c> previousScores = [
                SELECT Score__c
                FROM Compliance_Score__c
                WHERE Framework__c = :framework
                WITH USER_MODE
                ORDER BY Evaluation_Date__c DESC
                LIMIT 1
            ];

            if (!previousScores.isEmpty()) {
                result.previousScore = previousScores[0].Score__c;
                result.scoreChange = result.score - result.previousScore;
            } else {
                result.previousScore = result.score;
                result.scoreChange = 0;
            }

            result.compliant = result.score >= 80;

        } catch (Exception e) {
            ElaroLogger.warn( 'Error evaluating framework ' + framework + ': ' + e.getMessage());
            result.score = 0;
            result.compliant = false;
        }

        return result;
    }

    /**
     * Calculate overall weighted compliance score
     */
    private Decimal calculateOverallScore(Map<String, FrameworkResult> results) {
        if (results.isEmpty()) {
            return 0;
        }

        Decimal totalScore = 0;
        Integer count = 0;

        for (FrameworkResult result : results.values()) {
            if (result.score > 0) {
                totalScore += result.score;
                count++;
            }
        }

        return count > 0 ? (totalScore / count).setScale(2) : 0;
    }

    /**
     * Create daily summary record
     */
    private void createDailySummary(Map<String, FrameworkResult> results, Decimal overallScore) {
        try {
            // Build summary details
            String summaryDetails = 'Daily Compliance Summary\n';
            summaryDetails += '=' .repeat(40) + '\n\n';
            summaryDetails += 'Overall Score: ' + overallScore + '%\n\n';

            Integer compliantCount = 0;
            Integer nonCompliantCount = 0;

            for (String framework : results.keySet()) {
                FrameworkResult result = results.get(framework);
                summaryDetails += framework + ': ' + result.score + '% ';
                summaryDetails += (result.compliant ? '✓' : '✗');

                if (result.scoreChange != 0) {
                    summaryDetails += ' (' + (result.scoreChange > 0 ? '+' : '') + result.scoreChange + ')';
                }
                summaryDetails += '\n';

                if (result.compliant) {
                    compliantCount++;
                } else {
                    nonCompliantCount++;
                }
            }

            summaryDetails += '\nCompliant: ' + compliantCount + '/' + results.size() + ' frameworks';

            // Create audit log with summary
            Elaro_Audit_Log__c log = new Elaro_Audit_Log__c();
            log.Action__c = 'Daily Compliance Summary';
            log.Status__c = nonCompliantCount == 0 ? 'Success' : 'Warning';
            log.Details__c = summaryDetails;
            log.User__c = UserInfo.getUserId();
            ElaroSecurityUtils.validateCRUDAccess('Elaro_Audit_Log__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
            insert as user log;

        } catch (Exception e) {
            ElaroLogger.error( 'Failed to create daily summary: ' + e.getMessage());
        }
    }

    /**
     * Check for significant score drops and create alerts
     */
    private void checkScoreAlerts(Map<String, FrameworkResult> results) {
        for (String framework : results.keySet()) {
            FrameworkResult result = results.get(framework);

            // Alert if score dropped by more than 5 points
            if (result.scoreChange < -5) {
                createScoreAlert(framework, result);
            }

            // Alert if framework became non-compliant
            if (!result.compliant && result.previousScore >= 80) {
                createComplianceAlert(framework, result);
            }
        }
    }

    /**
     * Create alert for significant score drop
     */
    private void createScoreAlert(String framework, FrameworkResult result) {
        try {
            Compliance_Gap__c gap = new Compliance_Gap__c();
            gap.Gap_Type__c = 'Score Decline';
            gap.Framework__c = framework;
            gap.Severity__c = 'High';
            gap.Status__c = 'Open';
            gap.Description__c = framework + ' compliance score dropped by ' +
                Math.abs(result.scoreChange) + ' points (from ' +
                result.previousScore + '% to ' + result.score + '%)';
            gap.Remediation_Steps__c = 'Review recent changes and address new violations.';
            gap.Due_Date__c = Date.today().addDays(7);

            ElaroSecurityUtils.validateCRUDAccess('Compliance_Gap__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
            insert as user gap;
        } catch (Exception e) {
            ElaroLogger.error( 'Failed to create score alert: ' + e.getMessage());
        }
    }

    /**
     * Create alert for compliance status change
     */
    private void createComplianceAlert(String framework, FrameworkResult result) {
        try {
            Compliance_Gap__c gap = new Compliance_Gap__c();
            gap.Gap_Type__c = 'Compliance Status Change';
            gap.Framework__c = framework;
            gap.Severity__c = 'Critical';
            gap.Status__c = 'Open';
            gap.Description__c = framework + ' is now NON-COMPLIANT. ' +
                'Score dropped from ' + result.previousScore + '% to ' + result.score + '%';
            gap.Remediation_Steps__c = 'Immediate attention required. Review all violations and remediate.';
            gap.Due_Date__c = Date.today().addDays(3);

            ElaroSecurityUtils.validateCRUDAccess('Compliance_Gap__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
            insert as user gap;
        } catch (Exception e) {
            ElaroLogger.error( 'Failed to create compliance alert: ' + e.getMessage());
        }
    }

    /**
     * Log successful execution
     */
    private void logExecution(String message, Integer snapshotsCreated, Decimal overallScore) {
        try {
            Elaro_Audit_Log__c log = new Elaro_Audit_Log__c();
            log.Action__c = 'Compliance Score Snapshot';
            log.Status__c = 'Success';
            log.Details__c = message + '. Snapshots: ' + snapshotsCreated +
                '. Overall Score: ' + overallScore + '%';
            log.User__c = UserInfo.getUserId();
            ElaroSecurityUtils.validateCRUDAccess('Elaro_Audit_Log__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
            insert as user log;
        } catch (Exception e) {
            ElaroLogger.error( 'Failed to log execution: ' + e.getMessage());
        }
    }

    /**
     * Log error
     */
    private void logError(String message) {
        try {
            Elaro_Audit_Log__c log = new Elaro_Audit_Log__c();
            log.Action__c = 'Compliance Score Snapshot';
            log.Status__c = 'Error';
            log.Details__c = message;
            log.User__c = UserInfo.getUserId();
            ElaroSecurityUtils.validateCRUDAccess('Elaro_Audit_Log__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
            insert as user log;
        } catch (Exception e) {
            ElaroLogger.error( 'Failed to log error: ' + e.getMessage());
        }
    }

    // ========== Static Utility Methods ==========

    /**
     * Schedule daily at 1 AM
     */
    public static String scheduleDaily() {
        String cronExp = '0 0 1 * * ?';
        return System.schedule(JOB_NAME + ' - Daily', cronExp, new ComplianceScoreSnapshotScheduler());
    }

    /**
     * Schedule with custom cron
     */
    public static String scheduleCustom(String cronExpression, String jobSuffix) {
        return System.schedule(JOB_NAME + ' - ' + jobSuffix, cronExpression, new ComplianceScoreSnapshotScheduler());
    }

    /**
     * Abort all scheduled snapshot jobs
     */
    public static void abortAllJobs() {
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :('%' + JOB_NAME + '%')
            WITH USER_MODE
        ];

        for (CronTrigger job : jobs) {
            System.abortJob(job.Id);
        }
    }

    /**
     * Run immediately
     */
    @AuraEnabled
    public static void runNow() {
        ComplianceScoreSnapshotScheduler scheduler = new ComplianceScoreSnapshotScheduler();
        scheduler.captureSnapshots();
    }

    /**
     * Get score trend for a framework
     */
    @AuraEnabled(cacheable=true)
    public static List<ScoreTrend> getScoreTrend(String framework, Integer days) {
        if (days == null || days <= 0) {
            days = 30;
        }

        Date startDate = Date.today().addDays(-days);
        List<ScoreTrend> trends = new List<ScoreTrend>();

        List<Compliance_Score__c> scores = [
            SELECT Score__c, Evaluation_Date__c, Status__c, Gaps_Count__c
            FROM Compliance_Score__c
            WHERE Framework__c = :framework
            AND Evaluation_Date__c >= :startDate
            WITH USER_MODE
            ORDER BY Evaluation_Date__c ASC
        ];

        for (Compliance_Score__c score : scores) {
            ScoreTrend trend = new ScoreTrend();
            trend.date = score.Evaluation_Date__c.date();
            trend.score = score.Score__c;
            trend.status = score.Status__c;
            trend.gapCount = score.Gaps_Count__c != null ? score.Gaps_Count__c.intValue() : 0;
            trends.add(trend);
        }

        return trends;
    }

    // ========== Inner Classes ==========

    private class FrameworkResult {
        public String framework;
        public Decimal score;
        public Boolean compliant;
        public Integer gapCount;
        public Integer violationCount;
        public Decimal previousScore;
        public Decimal scoreChange;
    }

    public class ScoreTrend {
        @AuraEnabled public Date date;
        @AuraEnabled public Decimal score;
        @AuraEnabled public String status;
        @AuraEnabled public Integer gapCount;
    }
}
