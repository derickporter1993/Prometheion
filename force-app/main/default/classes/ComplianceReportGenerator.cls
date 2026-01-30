/**
 * ComplianceReportGenerator - Generates compliance report content
 *
 * Creates structured report data including compliance scores, gaps, and trends.
 * Used by ComplianceReportScheduler for automated reports and can be called
 * directly for on-demand report generation.
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class ComplianceReportGenerator {

    // Logging prefix
    private static final String LOG_PREFIX = '[ComplianceReportGenerator] ';

    /**
     * Container for all report data
     */
    public class ReportData {
        @AuraEnabled public ElaroComplianceScorer.ScoreResult scoreResult;
        @AuraEnabled public List<Compliance_Gap__c> gaps;
        @AuraEnabled public List<TrendPoint> scoreTrend;
        @AuraEnabled public Map<String, Integer> gapsBySeverity;
        @AuraEnabled public Map<String, Integer> gapsByFramework;
        @AuraEnabled public Datetime generatedAt;
        @AuraEnabled public String framework;

        public ReportData() {
            this.gaps = new List<Compliance_Gap__c>();
            this.scoreTrend = new List<TrendPoint>();
            this.gapsBySeverity = new Map<String, Integer>();
            this.gapsByFramework = new Map<String, Integer>();
            this.generatedAt = Datetime.now();
        }
    }

    /**
     * Score trend data point
     */
    public class TrendPoint {
        @AuraEnabled public Date reportDate;
        @AuraEnabled public Decimal score;
        @AuraEnabled public String period;
    }

    /**
     * Generate complete report data
     * @param frameworkFilter Framework to filter (or 'ALL' for all frameworks)
     * @return ReportData containing all report elements
     */
    @AuraEnabled
    public static ReportData generateReportData(String frameworkFilter) {
        System.debug(LoggingLevel.INFO, LOG_PREFIX + 'Generating report data for: ' + frameworkFilter);

        ReportData data = new ReportData();
        data.framework = String.isNotBlank(frameworkFilter) ? frameworkFilter : 'ALL';

        try {
            // Get current compliance score
            data.scoreResult = ElaroComplianceScorer.calculateReadinessScore();

            // Get compliance gaps
            data.gaps = getComplianceGaps(data.framework);

            // Calculate gap statistics
            data.gapsBySeverity = calculateGapsBySeverity(data.gaps);
            data.gapsByFramework = calculateGapsByFramework(data.gaps);

            // Get score trend (if historical data available)
            data.scoreTrend = getScoreTrend(data.framework);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + 'Error generating report: ' + e.getMessage());
            // Return partial data rather than failing completely
            if (data.scoreResult == null) {
                data.scoreResult = new ElaroComplianceScorer.ScoreResult();
                data.scoreResult.overallScore = 0;
                data.scoreResult.rating = 'Error';
            }
        }

        return data;
    }

    /**
     * Get compliance gaps filtered by framework
     */
    private static List<Compliance_Gap__c> getComplianceGaps(String framework) {
        String query = 'SELECT Id, Name, Severity__c, Framework__c, Status__c, Description__c, CreatedDate ';
        query += 'FROM Compliance_Gap__c ';
        query += 'WHERE Status__c != \'Resolved\' ';

        if (framework != 'ALL' && String.isNotBlank(framework)) {
            query += 'AND Framework__c = :framework ';
        }

        query += 'ORDER BY Severity__c DESC, CreatedDate DESC ';
        query += 'LIMIT 200';

        return Database.query(query);
    }

    /**
     * Calculate gap counts by severity
     */
    private static Map<String, Integer> calculateGapsBySeverity(List<Compliance_Gap__c> gaps) {
        Map<String, Integer> counts = new Map<String, Integer>{
            'Critical' => 0,
            'High' => 0,
            'Medium' => 0,
            'Low' => 0
        };

        for (Compliance_Gap__c gap : gaps) {
            String severity = gap.Severity__c != null ? gap.Severity__c : 'Medium';
            if (counts.containsKey(severity)) {
                counts.put(severity, counts.get(severity) + 1);
            }
        }

        return counts;
    }

    /**
     * Calculate gap counts by framework
     */
    private static Map<String, Integer> calculateGapsByFramework(List<Compliance_Gap__c> gaps) {
        Map<String, Integer> counts = new Map<String, Integer>();

        for (Compliance_Gap__c gap : gaps) {
            String fw = gap.Framework__c != null ? gap.Framework__c : 'Unknown';
            if (!counts.containsKey(fw)) {
                counts.put(fw, 0);
            }
            counts.put(fw, counts.get(fw) + 1);
        }

        return counts;
    }

    /**
     * Get historical score trend
     */
    private static List<TrendPoint> getScoreTrend(String framework) {
        List<TrendPoint> trend = new List<TrendPoint>();

        try {
            // Query Compliance_Score__c for historical snapshots
            List<Compliance_Score__c> scores = [
                SELECT Id, Risk_Score__c, CreatedDate
                FROM Compliance_Score__c
                WHERE CreatedDate >= LAST_N_DAYS:90
                WITH USER_MODE
                ORDER BY CreatedDate ASC
                LIMIT 12
            ];

            for (Compliance_Score__c score : scores) {
                TrendPoint point = new TrendPoint();
                point.reportDate = score.CreatedDate.date();
                // Convert risk score to compliance score (inverse)
                point.score = score.Risk_Score__c != null ? (100 - score.Risk_Score__c) : 0;
                point.period = score.CreatedDate.format('MMM d');
                trend.add(point);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, LOG_PREFIX + 'Could not retrieve score trend: ' + e.getMessage());
        }

        return trend;
    }

    /**
     * Generate executive summary text
     * @param data The report data
     * @return Formatted executive summary
     */
    @AuraEnabled
    public static String generateExecutiveSummary(ReportData data) {
        if (data == null || data.scoreResult == null) {
            return 'Unable to generate summary - no data available.';
        }

        String summary = 'Compliance Score: ' + data.scoreResult.overallScore.setScale(0) + '/100 (' + data.scoreResult.rating + ')\n\n';

        // Gap summary
        Integer criticalCount = data.gapsBySeverity.get('Critical');
        Integer highCount = data.gapsBySeverity.get('High');

        if (criticalCount > 0 || highCount > 0) {
            summary += 'Priority Issues:\n';
            if (criticalCount > 0) {
                summary += '• ' + criticalCount + ' Critical gaps require immediate attention\n';
            }
            if (highCount > 0) {
                summary += '• ' + highCount + ' High-priority gaps should be addressed this week\n';
            }
        } else {
            summary += 'No critical or high-priority gaps at this time.\n';
        }

        // Framework highlights
        summary += '\nFramework Status:\n';
        for (String fw : data.scoreResult.frameworkScores.keySet()) {
            Decimal score = data.scoreResult.frameworkScores.get(fw);
            String status = ElaroConstants.getRatingFromScore(score);
            summary += '• ' + fw + ': ' + score.setScale(0) + '/100 (' + status + ')\n';
        }

        return summary;
    }

    /**
     * Generate recommendations based on report data
     * @param data The report data
     * @return List of prioritized recommendations
     */
    @AuraEnabled
    public static List<String> generateRecommendations(ReportData data) {
        List<String> recommendations = new List<String>();

        if (data == null || data.scoreResult == null) {
            recommendations.add('Unable to generate recommendations - refresh report data.');
            return recommendations;
        }

        // Score-based recommendations
        if (data.scoreResult.overallScore < 60) {
            recommendations.add('Overall compliance score is below acceptable threshold. Schedule an immediate compliance review.');
        }

        // Gap-based recommendations
        Integer criticalCount = data.gapsBySeverity.get('Critical');
        if (criticalCount > 0) {
            recommendations.add('Address ' + criticalCount + ' critical gap(s) within 24-48 hours to maintain compliance posture.');
        }

        // Framework-specific recommendations
        for (String fw : data.scoreResult.frameworkScores.keySet()) {
            Decimal score = data.scoreResult.frameworkScores.get(fw);
            if (score < 50) {
                recommendations.add(fw + ' compliance is critically low (' + score.setScale(0) + '%). Prioritize ' + fw + '-specific controls.');
            } else if (score < 70) {
                recommendations.add('Improve ' + fw + ' compliance score from ' + score.setScale(0) + '% by implementing recommended controls.');
            }
        }

        // Risk-based recommendations
        if (data.scoreResult.topRisks != null) {
            for (ElaroComplianceScorer.Risk risk : data.scoreResult.topRisks) {
                if (risk.remediation != null) {
                    recommendations.add(risk.remediation);
                }
            }
        }

        // Ensure we have at least one recommendation
        if (recommendations.isEmpty()) {
            recommendations.add('Maintain current compliance posture. Continue regular monitoring and reviews.');
        }

        return recommendations;
    }
}
