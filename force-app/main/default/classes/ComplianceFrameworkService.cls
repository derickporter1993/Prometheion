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
        try {
            if (String.isBlank(framework)) {
                throw new IllegalArgumentException('Framework cannot be blank');
            }

            FrameworkEvaluationResult result = new FrameworkEvaluationResult();
            result.framework = framework;
            result.evaluationDate = System.now();

            // Get all active policies for this framework
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

            Decimal totalScore = 0;
            Decimal maxScore = 0;

            // Collect all policy names for bulk query (avoid SOQL in loop)
            Set<String> policyNames = new Set<String>();
            for (Compliance_Policy__mdt policy : policies) {
                policyNames.add(policy.DeveloperName);
            }

            // Query all gaps for all policies in one query
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

            for (Compliance_Policy__mdt policy : policies) {
                maxScore += policy.Risk_Weight__c != null ? policy.Risk_Weight__c : 5.0;

                // Get gaps for this policy from the pre-queried map
                List<Compliance_Gap__c> policyGaps = gapsByPolicy.get(policy.DeveloperName);

                if (policyGaps == null || policyGaps.isEmpty()) {
                    result.compliantPolicies++;
                    totalScore += policy.Risk_Weight__c != null ? policy.Risk_Weight__c : 5.0;
                } else {
                    // Calculate score reduction based on gaps
                    Decimal gapPenalty = 0;
                    for (Compliance_Gap__c gap : policyGaps) {
                        Decimal gapScore = gap.Risk_Score__c != null ? gap.Risk_Score__c : 5.0;
                        gapPenalty += gapScore;

                        ComplianceGapSummary gapSummary = new ComplianceGapSummary();
                        gapSummary.policyName = policy.DeveloperName;
                        gapSummary.severity = gap.Severity__c;
                        gapSummary.status = gap.Status__c;
                        gapSummary.riskScore = gapScore;
                        result.gaps.add(gapSummary);
                    }

                    Decimal policyScore = (policy.Risk_Weight__c != null ? policy.Risk_Weight__c : 5.0) - (gapPenalty / policyGaps.size());
                    totalScore += Math.max(0, policyScore);
                }

                result.evaluatedPolicies++;
            }

            // Calculate overall compliance score (0-100)
            result.overallScore = maxScore > 0 ? (totalScore / maxScore) * 100 : 0;
            result.overallScore = result.overallScore.setScale(2);

            // Determine compliance status
            if (result.overallScore >= 90) {
                result.status = 'COMPLIANT';
            } else if (result.overallScore >= 70) {
                result.status = 'PARTIALLY_COMPLIANT';
            } else {
                result.status = 'NON_COMPLIANT';
            }

            return result;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('ComplianceFrameworkService.evaluateFramework', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
    }
    
    /**
     * Get compliance score for multiple frameworks
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, FrameworkEvaluationResult> evaluateMultipleFrameworks(List<String> frameworks) {
        try {
            Map<String, FrameworkEvaluationResult> results = new Map<String, FrameworkEvaluationResult>();

            for (String framework : frameworks) {
                try {
                    results.put(framework, evaluateFramework(framework));
                } catch (Exception e) {
                    ElaroLogger.error('Error evaluating framework ' + framework + ': ' + e.getMessage(), e);
                }
            }

            return results;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('ComplianceFrameworkService.evaluateMultipleFrameworks', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
    }
    
    /**
     * Get all supported frameworks
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getSupportedFrameworks() {
        try {
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
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('ComplianceFrameworkService.getSupportedFrameworks', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
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
