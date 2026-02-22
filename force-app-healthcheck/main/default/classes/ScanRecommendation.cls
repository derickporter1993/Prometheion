/**
 * Data transfer object representing a remediation recommendation for a security finding.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 */
public inherited sharing class ScanRecommendation implements Comparable {

    @AuraEnabled
    public String title { get; set; }

    @AuraEnabled
    public String description { get; set; }

    @AuraEnabled
    public String setupMenuPath { get; set; }

    @AuraEnabled
    public Integer priority { get; set; }

    @AuraEnabled
    public String category { get; set; }

    /**
     * Constructs a ScanRecommendation with all fields populated.
     *
     * @param title Short title for the recommendation
     * @param description Detailed explanation of the remediation action
     * @param setupMenuPath Salesforce Setup URL path (e.g., 'SecuritySession/home')
     * @param priority Urgency level: 1=critical, 2=high, 3=medium
     * @param category The scanner category this recommendation addresses
     */
    public ScanRecommendation(String title, String description, String setupMenuPath,
                              Integer priority, String category) {
        this.title = title;
        this.description = description;
        this.setupMenuPath = setupMenuPath;
        this.priority = priority;
        this.category = category;
    }

    /**
     * Default constructor for deserialization.
     */
    public ScanRecommendation() {}

    /**
     * Compares recommendations by priority (lower number = higher urgency).
     *
     * @param compareTo The object to compare against
     * @return Negative if this is higher priority, positive if lower, zero if equal
     */
    public Integer compareTo(Object compareTo) {
        ScanRecommendation other = (ScanRecommendation) compareTo;
        Integer thisPriority = this.priority ?? 99;
        Integer otherPriority = other.priority ?? 99;
        return thisPriority - otherPriority;
    }
}
