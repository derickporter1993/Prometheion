/**
 * NaturalLanguageQueryService
 * 
 * "Am I compliant?" natural language queries
 * 
 * @author Prometheion
 * @version 1.0
 */
public with sharing class NaturalLanguageQueryService {
    
    /**
     * Process natural language query about compliance
     * @param query Natural language question (e.g., "Am I SOX compliant?")
     * @return Query result with answer and details
     */
    @AuraEnabled
    public static QueryResult processQuery(String query) {
        if (String.isBlank(query)) {
            throw new IllegalArgumentException('Query cannot be blank');
        }
        
        QueryResult result = new QueryResult();
        result.originalQuery = query;
        result.processedDate = System.now();
        
        // Simple keyword matching (in production, use NLP/AI)
        String lowerQuery = query.toLowerCase();
        
        // Extract framework
        String framework = extractFramework(lowerQuery);
        if (String.isNotBlank(framework)) {
            // Get compliance status for framework
            ComplianceFrameworkService.FrameworkEvaluationResult eval = 
                ComplianceFrameworkService.evaluateFramework(framework);
            
            result.answer = generateAnswer(eval, framework);
            result.framework = framework;
            result.score = eval.overallScore;
            result.status = eval.status;
            result.details = 'Total Policies: ' + eval.totalPolicies + 
                          ', Compliant: ' + eval.compliantPolicies + 
                          ', Gaps: ' + (eval.gaps != null ? eval.gaps.size() : 0);
        } else {
            result.answer = 'I could not identify a compliance framework in your query. Please specify a framework (e.g., SOX, SOC2, HIPAA).';
            result.status = 'UNKNOWN';
        }
        
        return result;
    }
    
    /**
     * Extract framework from query
     */
    private static String extractFramework(String query) {
        Map<String, String> frameworkMap = new Map<String, String>{
            'sox' => 'SOX',
            'soc2' => 'SOC2',
            'soc 2' => 'SOC2',
            'hipaa' => 'HIPAA',
            'gdpr' => 'GDPR',
            'ccpa' => 'CCPA',
            'glba' => 'GLBA',
            'nist' => 'NIST',
            'iso' => 'ISO27001',
            'pci' => 'PCI_DSS'
        };
        
        for (String key : frameworkMap.keySet()) {
            if (query.contains(key)) {
                return frameworkMap.get(key);
            }
        }
        
        return null;
    }
    
    /**
     * Generate answer from evaluation result
     */
    private static String generateAnswer(ComplianceFrameworkService.FrameworkEvaluationResult eval, String framework) {
        if (eval.overallScore >= 90) {
            return 'Yes, you are ' + framework + ' compliant. Your compliance score is ' + eval.overallScore + '%.';
        } else if (eval.overallScore >= 70) {
            return 'You are partially ' + framework + ' compliant. Your score is ' + eval.overallScore + 
                   '%. There are ' + (eval.gaps != null ? eval.gaps.size() : 0) + ' compliance gaps that need attention.';
        } else {
            return 'You are not fully ' + framework + ' compliant. Your score is ' + eval.overallScore + 
                   '%. There are ' + (eval.gaps != null ? eval.gaps.size() : 0) + ' compliance gaps that require immediate remediation.';
        }
    }
    
    /**
     * Query Result
     */
    public class QueryResult {
        @AuraEnabled public String originalQuery;
        @AuraEnabled public Datetime processedDate;
        @AuraEnabled public String answer;
        @AuraEnabled public String framework;
        @AuraEnabled public Decimal score;
        @AuraEnabled public String status;
        @AuraEnabled public String details;
    }
}
