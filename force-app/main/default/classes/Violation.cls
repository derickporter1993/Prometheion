/**
 * Violation data structure for compliance framework violations
 * Used by IRiskScoringService implementations
 * 
 * @author Elaro
 * @version 3.0
 */
public with sharing class Violation {
    @AuraEnabled public String title;
    @AuraEnabled public String description;
    @AuraEnabled public String severity;
    @AuraEnabled public String remediation;
    @AuraEnabled public String entityId;
    @AuraEnabled public Decimal riskScore;
}
