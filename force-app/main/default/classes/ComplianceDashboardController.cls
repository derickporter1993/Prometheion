/**
 * ComplianceDashboardController
 * 
 * Dashboard backend for compliance metrics and visualization
 * 
 * @author Elaro
 * @version 1.0
 * @since v3.1.0 (Spring '26)
 * @group Compliance Framework
 */
public with sharing class ComplianceDashboardController {
    
    /**
     * Get dashboard summary for all frameworks
     * Note: Not cacheable to ensure users always see current compliance status
     */
    @AuraEnabled(cacheable=false)
    public static DashboardSummary getDashboardSummary() {
        try {
            DashboardSummary summary = new DashboardSummary();
            summary.lastUpdated = System.now();

            // Get all supported frameworks
            List<String> frameworks = ComplianceFrameworkService.getSupportedFrameworks();
            summary.frameworks = new List<FrameworkSummary>();

            for (String framework : frameworks) {
                try {
                    ComplianceFrameworkService.FrameworkEvaluationResult eval =
                        ComplianceFrameworkService.evaluateFramework(framework);

                    FrameworkSummary fwSummary = new FrameworkSummary();
                    fwSummary.framework = framework;
                    fwSummary.score = eval.overallScore;
                    fwSummary.status = eval.status;
                    fwSummary.totalPolicies = eval.totalPolicies;
                    fwSummary.compliantPolicies = eval.compliantPolicies;
                    fwSummary.gapCount = eval.gaps != null ? eval.gaps.size() : 0;

                    summary.frameworks.add(fwSummary);
                } catch (Exception e) {
                    ElaroLogger.error('Error evaluating framework ' + framework + ': ' + e.getMessage());
                }
            }

            // Get recent gaps
            List<Compliance_Gap__c> gaps = [
                SELECT Id, Framework__c, Policy_Reference__c, Severity__c, Status__c,
                       Detected_Date__c, Risk_Score__c
                FROM Compliance_Gap__c
                WHERE Status__c != 'VERIFIED'
                WITH USER_MODE
                ORDER BY Detected_Date__c DESC
                LIMIT 10
            ];
            summary.recentGaps = (List<Compliance_Gap__c>) ElaroSecurityUtils.stripInaccessibleFields(
                AccessType.READABLE,
                gaps
            );

            // Get recent evidence
            List<Compliance_Evidence__c> evidence = [
                SELECT Id, Framework__c, Evidence_Type__c, Evidence_Date__c, Status__c, Compliance_Score__c
                FROM Compliance_Evidence__c
                WITH USER_MODE
                ORDER BY Evidence_Date__c DESC
                LIMIT 10
            ];
            summary.recentEvidence = (List<Compliance_Evidence__c>) ElaroSecurityUtils.stripInaccessibleFields(
                AccessType.READABLE,
                evidence
            );

            return summary;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('ComplianceDashboardController.getDashboardSummary', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the dashboard summary operation. Please verify you have the required permissions and try again.');
        }
    }
    
    /**
     * Get framework-specific dashboard data
     * Note: Not cacheable to ensure users always see current compliance gaps and evidence
     */
    @AuraEnabled(cacheable=false)
    public static FrameworkDashboardData getFrameworkDashboard(String framework) {
        try {
            if (String.isBlank(framework)) {
                throw new IllegalArgumentException('Framework cannot be blank');
            }

            FrameworkDashboardData data = new FrameworkDashboardData();
            data.framework = framework;

            // Get evaluation result
            data.evaluation = ComplianceFrameworkService.evaluateFramework(framework);

            // Get all gaps for this framework
            List<Compliance_Gap__c> gaps = [
                SELECT Id, Policy_Reference__c, Gap_Description__c, Severity__c, Status__c,
                       Risk_Score__c, Detected_Date__c, Remediation_Owner__c, Target_Remediation_Date__c
                FROM Compliance_Gap__c
                WHERE Framework__c = :framework
                WITH USER_MODE
                ORDER BY Risk_Score__c DESC NULLS LAST
            ];
            data.gaps = (List<Compliance_Gap__c>) ElaroSecurityUtils.stripInaccessibleFields(
                AccessType.READABLE,
                gaps
            );

            // Get evidence for this framework
            List<Compliance_Evidence__c> evidence = [
                SELECT Id, Evidence_Type__c, Evidence_Date__c, Status__c, Compliance_Score__c, Description__c
                FROM Compliance_Evidence__c
                WHERE Framework__c = :framework
                WITH USER_MODE
                ORDER BY Evidence_Date__c DESC
                LIMIT 50
            ];
            data.evidence = (List<Compliance_Evidence__c>) ElaroSecurityUtils.stripInaccessibleFields(
                AccessType.READABLE,
                evidence
            );

            return data;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('ComplianceDashboardController.getFrameworkDashboard', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the framework dashboard operation. Please verify you have the required permissions and try again.');
        }
    }
    
    /**
     * Dashboard Summary
     */
    public class DashboardSummary {
        @AuraEnabled public Datetime lastUpdated;
        @AuraEnabled public List<FrameworkSummary> frameworks;
        @AuraEnabled public List<Compliance_Gap__c> recentGaps;
        @AuraEnabled public List<Compliance_Evidence__c> recentEvidence;
    }
    
    /**
     * Framework Summary
     */
    public class FrameworkSummary {
        @AuraEnabled public String framework;
        @AuraEnabled public Decimal score;
        @AuraEnabled public String status;
        @AuraEnabled public Integer totalPolicies;
        @AuraEnabled public Integer compliantPolicies;
        @AuraEnabled public Integer gapCount;
    }
    
    /**
     * Framework Dashboard Data
     */
    public class FrameworkDashboardData {
        @AuraEnabled public String framework;
        @AuraEnabled public ComplianceFrameworkService.FrameworkEvaluationResult evaluation;
        @AuraEnabled public List<Compliance_Gap__c> gaps;
        @AuraEnabled public List<Compliance_Evidence__c> evidence;
    }
}
