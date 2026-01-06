/**
 * Violation data structure for compliance framework violations
 * Used by IRiskScoringService implementations
 * 
 * @author Prometheion
 * @version 3.0
 */
public class Violation {
    @AuraEnabled public String title;
    @AuraEnabled public String description;
    @AuraEnabled public String severity;
    @AuraEnabled public String remediation;
    @AuraEnabled public String entityId;
    @AuraEnabled public Decimal riskScore;
}
