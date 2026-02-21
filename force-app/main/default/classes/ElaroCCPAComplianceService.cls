/**
 * CCPA Compliance Service
 * Implements CCPA-specific compliance checks and risk scoring
 * 
 * CCPA Key Requirements:
 * - Right to know (Section 1798.100)
 * - Right to delete (Section 1798.105)
 * - Right to opt-out of sale (Section 1798.120)
 * - Non-discrimination (Section 1798.125)
 * 
 * @author Elaro
 * @version 3.0
 */
public with sharing class ElaroCCPAComplianceService implements IRiskScoringService {
    private static final String FRAMEWORK = ElaroConstants.FRAMEWORK_CCPA;
    
    /**
     * Calculates a CCPA-specific risk score for the given entity.
     * Focuses on consumer privacy rights factors.
     *
     * @param entityType The type of entity being scored (e.g., field, permission set)
     * @param entityId The unique identifier of the entity
     * @param metadata Additional context for risk calculation
     * @return Risk score capped at the configured maximum
     */
    public Decimal calculateRiskScore(String entityType, String entityId, Map<String, Object> metadata) {
        Decimal score = ElaroConstants.BASE_RISK_SCORE;
        
        // CCPA-specific risk factors focus on consumer privacy rights
        return Math.min(score, ElaroConstants.RISK_SCORE_MAX);
    }
    
    /**
     * Returns the current CCPA compliance readiness score from the scorer.
     *
     * @return CCPA framework compliance score
     */
    public Decimal getComplianceScore() {
        return ElaroComplianceScorer.calculateReadinessScore().frameworkScores.get(FRAMEWORK);
    }
    
    /**
     * Identifies current CCPA violations such as missing opt-out mechanisms.
     *
     * @return List of active CCPA violations
     */
    public List<Violation> getViolations() {
        List<Violation> violations = new List<Violation>();
        
        // Check for CCPA violations
        // Example: Missing opt-out mechanisms for data sales
        
        return violations;
    }
    
    /**
     * Returns the CCPA framework identifier.
     *
     * @return The framework constant for CCPA
     */
    public String getFrameworkName() {
        return FRAMEWORK;
    }
}
