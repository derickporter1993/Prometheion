/**
 * ComplianceDashboardController
 * 
 * Dashboard backend for compliance metrics and visualization
 * 
 * @author Prometheion
 * @version 1.0
 */
public with sharing class ComplianceDashboardController {
    
    /**
     * Get dashboard summary for all frameworks
     * Note: Not cacheable to ensure users always see current compliance status
     */
    @AuraEnabled(cacheable=false)
    public static DashboardSummary getDashboardSummary() {
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
                System.debug(LoggingLevel.ERROR, 'Error evaluating framework ' + framework + ': ' + e.getMessage());
            }
        }
        
        // Get recent gaps
        summary.recentGaps = [
            SELECT Id, Framework__c, Policy_Reference__c, Severity__c, Status__c, 
                   Detected_Date__c, Risk_Score__c
            FROM Compliance_Gap__c
            WHERE Status__c != 'VERIFIED'
            WITH SECURITY_ENFORCED
            ORDER BY Detected_Date__c DESC
            LIMIT 10
        ];
        
        // Get recent evidence
        summary.recentEvidence = [
            SELECT Id, Framework__c, Evidence_Type__c, Evidence_Date__c, Status__c, Compliance_Score__c
            FROM Compliance_Evidence__c
            WITH SECURITY_ENFORCED
            ORDER BY Evidence_Date__c DESC
            LIMIT 10
        ];
        
        return summary;
    }
    
    /**
     * Get framework-specific dashboard data
     * Note: Not cacheable to ensure users always see current compliance gaps and evidence
     */
    @AuraEnabled(cacheable=false)
    public static FrameworkDashboardData getFrameworkDashboard(String framework) {
        if (String.isBlank(framework)) {
            throw new IllegalArgumentException('Framework cannot be blank');
        }
        
        FrameworkDashboardData data = new FrameworkDashboardData();
        data.framework = framework;
        
        // Get evaluation result
        data.evaluation = ComplianceFrameworkService.evaluateFramework(framework);
        
        // Get all gaps for this framework
        data.gaps = [
            SELECT Id, Policy_Reference__c, Gap_Description__c, Severity__c, Status__c,
                   Risk_Score__c, Detected_Date__c, Remediation_Owner__c, Target_Remediation_Date__c
            FROM Compliance_Gap__c
            WHERE Framework__c = :framework
            WITH SECURITY_ENFORCED
            ORDER BY Risk_Score__c DESC NULLS LAST
        ];
        
        // Get evidence for this framework
        data.evidence = [
            SELECT Id, Evidence_Type__c, Evidence_Date__c, Status__c, Compliance_Score__c, Description__c
            FROM Compliance_Evidence__c
            WHERE Framework__c = :framework
            WITH SECURITY_ENFORCED
            ORDER BY Evidence_Date__c DESC
            LIMIT 50
        ];
        
        return data;
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
