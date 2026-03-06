/**
 * ComplianceFrameworkService
 * 
 * Core service for framework evaluation and compliance scoring
 * 
 * @author Elaro
 * @version 1.0
 * @since v3.1.0 (Spring '26)
 * @group Compliance Framework
 */
public with sharing class ComplianceFrameworkService {
    
    /**
     * Evaluate compliance for a specific framework
     * @param framework Framework name (SOX, SOC2, HIPAA, etc.)
     * @return FrameworkEvaluationResult with overall score and gaps
     */
    @AuraEnabled(cacheable=false)
    public static FrameworkEvaluationResult evaluateFramework(String framework) {
        if (String.isBlank(framework)) {
            throw new IllegalArgumentException('Framework cannot be blank');
        }

        FrameworkEvaluationResult result = new FrameworkEvaluationResult();
        result.framework = framework;
        result.evaluationDate = System.now();

        List<Compliance_Policy__mdt> policies = [
            SELECT DeveloperName, Policy_Description__c, Legal_Citation__c,
                   Risk_Weight__c, Severity__c, Entity_Types__c, Auto_Remediation_Allowed__c
            FROM Compliance_Policy__mdt
            WHERE Framework__c = :framework
            AND Is_Active__c = true
            WITH USER_MODE
        ];

        result.totalPolicies = policies.size();
        result.evaluatedPolicies = 0;
        result.compliantPolicies = 0;
        result.gaps = new List<ComplianceGapSummary>();

        Set<String> policyNames = new Set<String>();
        for (Compliance_Policy__mdt policy : policies) {
            policyNames.add(policy.DeveloperName);
        }

        Map<String, List<Compliance_Gap__c>> gapsByPolicy = queryGapsByPolicy(policyNames);

        Decimal totalScore = 0;
        Decimal maxScore = 0;

        for (Compliance_Policy__mdt policy : policies) {
            List<Compliance_Gap__c> policyGaps = gapsByPolicy.get(policy.DeveloperName);
            Decimal policyWeight = policy.Risk_Weight__c ?? 5.0;
            maxScore += policyWeight;
            totalScore += scorePolicy(policy, policyGaps, result);
            result.evaluatedPolicies++;
        }

        finalizeEvaluationScore(result, totalScore, maxScore);

        return result;
    }

    /**
     * Bulk queries compliance gaps grouped by policy reference.
     *
     * @param policyNames Set of policy developer names to query gaps for
     * @return Map of policy name to its list of unverified compliance gaps
     */
    private static Map<String, List<Compliance_Gap__c>> queryGapsByPolicy(Set<String> policyNames) {
        Map<String, List<Compliance_Gap__c>> gapsByPolicy = new Map<String, List<Compliance_Gap__c>>();
        for (Compliance_Gap__c gap : [
            SELECT Id, Policy_Reference__c, Severity__c, Status__c, Risk_Score__c
            FROM Compliance_Gap__c
            WHERE Policy_Reference__c IN :policyNames
            AND Status__c != 'VERIFIED'
            WITH USER_MODE
        ]) {
            if (!gapsByPolicy.containsKey(gap.Policy_Reference__c)) {
                gapsByPolicy.put(gap.Policy_Reference__c, new List<Compliance_Gap__c>());
            }
            gapsByPolicy.get(gap.Policy_Reference__c).add(gap);
        }
        return gapsByPolicy;
    }

    /**
     * Calculates the score contribution for a single policy based on its gaps.
     *
     * @param policy The compliance policy metadata record
     * @param gaps List of compliance gaps for this policy (may be null)
     * @param result FrameworkEvaluationResult to append gap summaries to
     * @return Decimal score contribution for this policy
     */
    private static Decimal scorePolicy(Compliance_Policy__mdt policy, List<Compliance_Gap__c> gaps, FrameworkEvaluationResult result) {
        Decimal policyWeight = policy.Risk_Weight__c ?? 5.0;

        if (gaps == null || gaps.isEmpty()) {
            result.compliantPolicies++;
            return policyWeight;
        }

        Decimal gapPenalty = 0;
        for (Compliance_Gap__c gap : gaps) {
            Decimal gapScore = gap.Risk_Score__c ?? 5.0;
            gapPenalty += gapScore;

            ComplianceGapSummary gapSummary = new ComplianceGapSummary();
            gapSummary.policyName = policy.DeveloperName;
            gapSummary.severity = gap.Severity__c;
            gapSummary.status = gap.Status__c;
            gapSummary.riskScore = gapScore;
            result.gaps.add(gapSummary);
        }

        Decimal policyScore = policyWeight - (gapPenalty / gaps.size());
        return Math.max(0, policyScore);
    }

    /**
     * Calculates the overall compliance percentage and determines status.
     *
     * @param result FrameworkEvaluationResult to set overallScore and status on
     * @param totalScore Sum of all policy score contributions
     * @param maxScore Sum of all policy weights (maximum possible score)
     */
    private static void finalizeEvaluationScore(FrameworkEvaluationResult result, Decimal totalScore, Decimal maxScore) {
        result.overallScore = maxScore > 0 ? (totalScore / maxScore) * 100 : 0;
        result.overallScore = result.overallScore.setScale(2);

        if (result.overallScore >= 90) {
            result.status = 'COMPLIANT';
        } else if (result.overallScore >= 70) {
            result.status = 'PARTIALLY_COMPLIANT';
        } else {
            result.status = 'NON_COMPLIANT';
        }
    }
    
    /**
     * Get compliance score for multiple frameworks
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, FrameworkEvaluationResult> evaluateMultipleFrameworks(List<String> frameworks) {
        Map<String, FrameworkEvaluationResult> results = new Map<String, FrameworkEvaluationResult>();
        
        for (String framework : frameworks) {
            try {
                results.put(framework, evaluateFramework(framework));
            } catch (Exception e) {
                ElaroLogger.error('Error evaluating framework ' + framework + ': ' + e.getMessage(), e);
            }
        }
        
        return results;
    }
    
    /**
     * Get all supported frameworks
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getSupportedFrameworks() {
        Set<String> frameworks = new Set<String>();
        
        List<Compliance_Policy__mdt> policies = [
            SELECT Framework__c
            FROM Compliance_Policy__mdt
            WHERE Is_Active__c = true
            WITH USER_MODE
        ];
        
        for (Compliance_Policy__mdt policy : policies) {
            if (String.isNotBlank(policy.Framework__c)) {
                frameworks.add(policy.Framework__c);
            }
        }
        
        return new List<String>(frameworks);
    }
    
    /**
     * Framework Evaluation Result
     */
    public class FrameworkEvaluationResult {
        @AuraEnabled public String framework;
        @AuraEnabled public Datetime evaluationDate;
        @AuraEnabled public Integer totalPolicies;
        @AuraEnabled public Integer evaluatedPolicies;
        @AuraEnabled public Integer compliantPolicies;
        @AuraEnabled public Decimal overallScore;
        @AuraEnabled public String status;
        @AuraEnabled public List<ComplianceGapSummary> gaps;
    }
    
    /**
     * Compliance Gap Summary
     */
    public class ComplianceGapSummary {
        @AuraEnabled public String policyName;
        @AuraEnabled public String severity;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal riskScore;
    }
}
