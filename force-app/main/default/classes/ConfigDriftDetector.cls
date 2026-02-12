/**
 * Detects configuration drift by scanning SetupAuditTrail for security-relevant
 * changes and publishing ConfigurationDrift__e Platform Events when risky
 * modifications are found.
 *
 * Implements Schedulable for periodic drift detection scans. Can be scheduled
 * to run hourly or daily to detect unauthorized configuration changes.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Event Monitoring
 * @see ComplianceAlertPublisher
 * @see ConfigurationDrift__e
 */
public inherited sharing class ConfigDriftDetector implements Schedulable {

    private static final String CLASS_NAME = 'ConfigDriftDetector';

    /**
     * High-risk SetupAuditTrail sections that indicate security-relevant changes.
     */
    @TestVisible
    private static final Set<String> HIGH_RISK_SECTIONS = new Set<String>{
        'Manage Users',
        'Security Controls',
        'Sharing Rules',
        'Permission Sets',
        'Session Settings',
        'Password Policies',
        'Certificate and Key Management',
        'Network Access',
        'Login Access Policies',
        'Connected Apps'
    };

    /**
     * Medium-risk sections indicating potentially impactful changes.
     */
    @TestVisible
    private static final Set<String> MEDIUM_RISK_SECTIONS = new Set<String>{
        'Profiles',
        'Email Administration',
        'Data Management',
        'Custom Objects',
        'Apex Class',
        'Remote Access',
        'Auth. Providers'
    };

    /**
     * Represents a detected configuration drift event.
     */
    public class DriftEvent {
        @AuraEnabled public String changeType;
        @AuraEnabled public String changedBy;
        @AuraEnabled public String changedObject;
        @AuraEnabled public String oldValue;
        @AuraEnabled public String newValue;
        @AuraEnabled public String riskLevel;
        @AuraEnabled public Datetime detectionTimestamp;

        public DriftEvent(String changeType, String changedBy, String changedObject, String riskLevel) {
            this.changeType = changeType;
            this.changedBy = changedBy;
            this.changedObject = changedObject;
            this.riskLevel = riskLevel;
            this.detectionTimestamp = System.now();
        }
    }

    /**
     * Schedulable execute method for periodic drift detection.
     *
     * @param ctx The SchedulableContext provided by the platform
     */
    public void execute(SchedulableContext ctx) {
        ElaroLogger.info(CLASS_NAME + '.execute: Starting scheduled drift detection');
        List<DriftEvent> drifts = detectDrift(1);
        publishDriftEvents(drifts);
        ElaroLogger.info(CLASS_NAME + '.execute: Drift detection complete', new Map<String, Object>{
            'driftsDetected' => drifts.size()
        });
    }

    /**
     * Scans SetupAuditTrail for configuration changes within the specified
     * number of hours and classifies them by risk level.
     *
     * @param hoursBack Number of hours to look back for changes
     * @return List of classified DriftEvent objects
     */
    public List<DriftEvent> detectDrift(Integer hoursBack) {
        List<DriftEvent> driftEvents = new List<DriftEvent>();
        Datetime cutoff = System.now().addHours(-hoursBack);

        List<SetupAuditTrail> auditEntries = [
            SELECT Action, Section, CreatedBy.Username, CreatedDate, Display
            FROM SetupAuditTrail
            WHERE CreatedDate >= :cutoff
            ORDER BY CreatedDate DESC
            WITH USER_MODE
            LIMIT 1000
        ];

        for (SetupAuditTrail entry : auditEntries) {
            String riskLevel = classifyRisk(entry.Section);
            if (riskLevel != null) {
                DriftEvent drift = new DriftEvent(
                    entry.Action ?? 'Unknown Action',
                    entry.CreatedBy?.Username ?? 'Unknown User',
                    entry.Section ?? 'Unknown Section',
                    riskLevel
                );
                drift.oldValue = null;
                drift.newValue = entry.Display ?? '';
                drift.detectionTimestamp = entry.CreatedDate;
                driftEvents.add(drift);
            }
        }

        return driftEvents;
    }

    /**
     * Classifies the risk level of a SetupAuditTrail section.
     *
     * @param section The SetupAuditTrail Section value
     * @return Risk level string (CRITICAL, HIGH, MEDIUM) or null if low-risk
     */
    @TestVisible
    private static String classifyRisk(String section) {
        if (String.isBlank(section)) {
            return null;
        }
        if (HIGH_RISK_SECTIONS.contains(section)) {
            return ElaroConstants.SEVERITY_HIGH;
        }
        if (MEDIUM_RISK_SECTIONS.contains(section)) {
            return ElaroConstants.SEVERITY_MEDIUM;
        }
        return null;
    }

    /**
     * Publishes detected drift events as ConfigurationDrift__e Platform Events
     * via the ComplianceAlertPublisher.
     *
     * @param driftEvents List of detected drift events to publish
     */
    public void publishDriftEvents(List<DriftEvent> driftEvents) {
        if (driftEvents == null || driftEvents.isEmpty()) {
            return;
        }

        for (DriftEvent drift : driftEvents) {
            ComplianceAlertPublisher.publishDriftAlert(
                drift.changeType,
                drift.changedBy,
                drift.changedObject,
                drift.oldValue,
                drift.newValue,
                drift.riskLevel
            );
        }

        ElaroLogger.info(CLASS_NAME + '.publishDriftEvents: Published drift events', new Map<String, Object>{
            'count' => driftEvents.size()
        });
    }

    /**
     * Returns the set of high-risk sections for external configuration or testing.
     *
     * @return Set of high-risk SetupAuditTrail section names
     */
    public static Set<String> getHighRiskSections() {
        return HIGH_RISK_SECTIONS;
    }

    /**
     * Returns the set of medium-risk sections for external configuration or testing.
     *
     * @return Set of medium-risk SetupAuditTrail section names
     */
    public static Set<String> getMediumRiskSections() {
        return MEDIUM_RISK_SECTIONS;
    }
}
