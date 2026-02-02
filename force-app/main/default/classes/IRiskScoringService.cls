/**
 * Interface for framework-specific risk scoring services
 * Each compliance framework implements this interface to provide framework-specific scoring logic
 * 
 * @author Elaro
 * @version 3.0
 */
public interface IRiskScoringService {
    /**
     * Calculate risk score for a given entity and framework
     * @param entityType Type of entity (PERMISSION_SET, FLOW, etc.)
     * @param entityId ID of the entity
     * @param metadata Entity metadata map
     * @return Risk score (0-10)
     */
    Decimal calculateRiskScore(String entityType, String entityId, Map<String, Object> metadata);
    
    /**
     * Get compliance score for the framework
     * @return Compliance score (0-100)
     */
    Decimal getComplianceScore();
    
    /**
     * Get list of violations for the framework
     * @return List of violation details
     */
    List<Violation> getViolations();
    
    /**
     * Get framework name
     * @return Framework identifier
     */
    String getFrameworkName();
}
