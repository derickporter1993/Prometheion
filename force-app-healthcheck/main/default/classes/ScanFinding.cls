/**
 * Data transfer object representing a single security finding from an org scan.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 */
public inherited sharing class ScanFinding {

    @AuraEnabled
    public String category { get; set; }

    @AuraEnabled
    public String setting { get; set; }

    @AuraEnabled
    public String currentValue { get; set; }

    @AuraEnabled
    public String recommendedValue { get; set; }

    @AuraEnabled
    public String severity { get; set; }

    @AuraEnabled
    public String description { get; set; }

    /**
     * Constructs a ScanFinding with all fields populated.
     *
     * @param category The scanner category (SecurityHealthCheck, MFA, Permissions, Session, AuditTrail)
     * @param setting The specific setting name
     * @param currentValue The current org value
     * @param recommendedValue The recommended best-practice value
     * @param severity Risk level: HIGH_RISK, MEDIUM_RISK, or LOW_RISK
     * @param description Human-readable description of the finding
     */
    public ScanFinding(String category, String setting, String currentValue,
                       String recommendedValue, String severity, String description) {
        this.category = category;
        this.setting = setting;
        this.currentValue = currentValue;
        this.recommendedValue = recommendedValue;
        this.severity = severity;
        this.description = description;
    }

    /**
     * Default constructor for deserialization.
     */
    public ScanFinding() {}
}
