/**
 * Classifies AI systems according to EU AI Act Annex III risk categories
 * (Unacceptable, High, Limited, Minimal). Uses Custom Metadata rules and
 * use case analysis to determine appropriate risk level and compliance requirements.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group AI Governance
 * @see AIDetectionEngine
 * @see AIGovernanceService
 */
public inherited sharing class AIRiskClassificationEngine {

    private static Map<String, AI_Classification_Rule__mdt> ruleCache;

    /**
     * Classifies an AI system based on its type and use case context.
     *
     * @param systemType The AI system type (e.g., 'Einstein Prediction', 'Einstein Bot')
     * @param useCase Optional use case description for context-specific classification
     * @return RiskClassification with risk level, article reference, and rationale
     * @throws AuraHandledException if classification fails
     * @example
     * AIRiskClassificationEngine.RiskClassification risk =
     *     AIRiskClassificationEngine.classifySystem('Einstein Prediction', 'Credit scoring');
     */
    public static RiskClassification classifySystem(String systemType, String useCase) {
        try {
            initializeRuleCache();

            // Find matching classification rule
            AI_Classification_Rule__mdt matchedRule = findMatchingRule(systemType, useCase);

            if (matchedRule != null) {
                RiskClassification classification = new RiskClassification();
                classification.riskLevel = matchedRule.Risk_Level__c;
                classification.euAIActArticle = matchedRule.EU_AI_Act_Article__c;
                classification.rationale = matchedRule.Rationale__c;
                classification.systemType = systemType;
                classification.useCase = useCase;
                classification.recommendedControls = getRecommendedControls(matchedRule.Risk_Level__c);
                return classification;
            }

            // Default to Limited risk if no rule matches
            return createDefaultClassification(systemType, useCase);

        } catch (Exception e) {
            ElaroLogger.error('AIRiskClassificationEngine.classifySystem', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to classify the AI system. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Initializes the classification rule cache from Custom Metadata.
     */
    private static void initializeRuleCache() {
        if (ruleCache == null) {
            ruleCache = new Map<String, AI_Classification_Rule__mdt>();

            List<AI_Classification_Rule__mdt> rules = [
                SELECT DeveloperName, Feature_Type__c, Use_Case_Context__c,
                       Risk_Level__c, EU_AI_Act_Article__c, Rationale__c
                FROM AI_Classification_Rule__mdt
                WITH USER_MODE
            ];

            for (AI_Classification_Rule__mdt rule : rules) {
                String key = rule.Feature_Type__c + '|' + (rule.Use_Case_Context__c ?? '');
                ruleCache.put(key, rule);
            }
        }
    }

    /**
     * Finds the most specific matching classification rule for a system type and use case.
     *
     * @param systemType The AI system type
     * @param useCase The use case context
     * @return Matching AI_Classification_Rule__mdt or null
     */
    private static AI_Classification_Rule__mdt findMatchingRule(String systemType, String useCase) {
        // Try exact match with use case
        if (String.isNotBlank(useCase)) {
            String exactKey = systemType + '|' + useCase;
            if (ruleCache.containsKey(exactKey)) {
                return ruleCache.get(exactKey);
            }
        }

        // Try partial use case match
        if (String.isNotBlank(useCase)) {
            for (String key : ruleCache.keySet()) {
                AI_Classification_Rule__mdt rule = ruleCache.get(key);
                if (rule.Feature_Type__c == systemType &&
                    String.isNotBlank(rule.Use_Case_Context__c) &&
                    useCase.containsIgnoreCase(rule.Use_Case_Context__c)) {
                    return rule;
                }
            }
        }

        // Fall back to default rule for system type
        String defaultKey = systemType + '|General prediction use cases';
        if (ruleCache.containsKey(defaultKey)) {
            return ruleCache.get(defaultKey);
        }

        // Try any rule matching the system type
        for (AI_Classification_Rule__mdt rule : ruleCache.values()) {
            if (rule.Feature_Type__c == systemType) {
                return rule;
            }
        }

        return null;
    }

    /**
     * Creates a default classification when no specific rule matches.
     *
     * @param systemType The AI system type
     * @param useCase The use case context
     * @return Default RiskClassification set to Limited risk
     */
    private static RiskClassification createDefaultClassification(String systemType, String useCase) {
        RiskClassification classification = new RiskClassification();
        classification.riskLevel = 'Limited';
        classification.euAIActArticle = 'Article 52';
        classification.rationale = 'Default classification: AI system requires transparency obligations';
        classification.systemType = systemType;
        classification.useCase = useCase;
        classification.recommendedControls = getRecommendedControls('Limited');
        return classification;
    }

    /**
     * Gets recommended controls based on risk level.
     *
     * @param riskLevel The EU AI Act risk level
     * @return List of recommended control measures
     */
    private static List<String> getRecommendedControls(String riskLevel) {
        switch on riskLevel {
            when 'Unacceptable' {
                return new List<String>{
                    'Immediate system deactivation required',
                    'Legal review mandatory',
                    'Prohibited use under EU AI Act'
                };
            }
            when 'High' {
                return new List<String>{
                    'Conformity assessment required',
                    'Risk management system mandatory',
                    'Data governance and quality controls',
                    'Human oversight mechanisms',
                    'Transparency and user information',
                    'Accuracy and robustness requirements',
                    'Registration in EU database'
                };
            }
            when 'Limited' {
                return new List<String>{
                    'Transparency obligations apply',
                    'Users must be informed of AI interaction',
                    'Documentation requirements'
                };
            }
            when else {
                return new List<String>{
                    'General good practices recommended',
                    'Voluntary codes of conduct'
                };
            }
        }
    }

    /**
     * Batch classifies multiple AI systems.
     *
     * @param systems List of AIDetectionEngine.AISystemMetadata to classify
     * @return Map of system name to RiskClassification
     */
    public static Map<String, RiskClassification> batchClassify(List<AIDetectionEngine.AISystemMetadata> systems) {
        Map<String, RiskClassification> classifications = new Map<String, RiskClassification>();

        for (AIDetectionEngine.AISystemMetadata system : systems) {
            RiskClassification classification = classifySystem(
                system.systemType,
                system.useCaseDescription
            );
            classifications.put(system.systemName, classification);
        }

        return classifications;
    }

    /**
     * Wrapper class representing an AI risk classification result.
     */
    public class RiskClassification {
        @AuraEnabled public String riskLevel { get; set; }
        @AuraEnabled public String euAIActArticle { get; set; }
        @AuraEnabled public String rationale { get; set; }
        @AuraEnabled public String systemType { get; set; }
        @AuraEnabled public String useCase { get; set; }
        @AuraEnabled public List<String> recommendedControls { get; set; }
    }
}
