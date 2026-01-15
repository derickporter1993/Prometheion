/**
 * @description Real-time event stream processing with risk scoring
 * Provides immediate risk assessment and alert triggering for Shield events
 * @group Shield Integration
 * @author Prometheion Team
 */
public with sharing class PrometheionRealtimeMonitor {
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════
    
    // Risk thresholds
    public static final Integer HIGH_RISK_THRESHOLD = 80;
    public static final Integer CRITICAL_RISK_THRESHOLD = 95;
    
    // Base risk scores by event type
    private static final Map<String, Integer> BASE_RISK_SCORES = new Map<String, Integer>{
        'LoginAs' => 70,
        'ReportExport' => 60,
        'ContentDistribution' => 60,
        'BulkApiResult' => 50,
        'API' => 40,
        'PermissionSetEventLog' => 50,
        'Login' => 20,
        'Report' => 30,
        'ApexExecution' => 25,
        'FlowExecution' => 20,
        'Logout' => 5,
        'URI' => 10,
        'LightningInteraction' => 5,
        'LightningPageView' => 5
    };
    
    // Risk factor weights
    private static final Integer TIME_FACTOR_OUTSIDE_HOURS = 10;
    private static final Integer TIME_FACTOR_WEEKEND = 15;
    private static final Integer LOCATION_FACTOR_NON_US = 15;
    private static final Integer VOLUME_FACTOR_HIGH = 10;
    private static final Integer VOLUME_FACTOR_CRITICAL = 20;
    private static final Integer ADMIN_USER_FACTOR = 10;
    
    // ═══════════════════════════════════════════════════════════════
    // PUBLIC METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Process incoming real-time event
     * @param eventData The event data to process
     */
    public static void processRealtimeEvent(Map<String, Object> eventData) {
        if (eventData == null || eventData.isEmpty()) {
            return;
        }
        
        // Parse the event
        String eventType = (String)eventData.get('EVENT_TYPE');
        Map<String, Object> parsedEvent = PrometheionEventParser.parseEvent(eventType, eventData);
        
        // Calculate risk score
        Integer riskScore = calculateRiskScore(eventData);
        parsedEvent.put('calculatedRiskScore', riskScore);
        
        // Determine if alert should be triggered
        if (riskScore >= HIGH_RISK_THRESHOLD) {
            String userId = (String)eventData.get('USER_ID');
            String reason = buildRiskReason(eventData, riskScore);
            
            triggerAlert(userId, riskScore, reason, eventData);
        }
        
        // Publish platform event for downstream processing
        publishEventNotification(parsedEvent, riskScore);
    }
    
    /**
     * @description Calculate comprehensive risk score (0-100)
     * @param eventData The event data to score
     * @return Risk score between 0 and 100
     */
    public static Integer calculateRiskScore(Map<String, Object> eventData) {
        if (eventData == null) {
            return 0;
        }
        
        Integer score = 0;
        
        // 1. Base score by event type
        String eventType = getString(eventData, 'EVENT_TYPE');
        score += getBaseScore(eventType);
        
        // 2. Time factor
        score += calculateTimeFactor(eventData);
        
        // 3. Location factor
        score += calculateLocationFactor(eventData);
        
        // 4. Volume factor
        score += calculateVolumeFactor(eventData);
        
        // 5. User factor (admin users get higher score)
        score += calculateUserFactor(eventData);
        
        // Cap at 100
        return Math.min(score, 100);
    }
    
    /**
     * @description Trigger alert for high-risk event
     * @param userId The user ID associated with the event
     * @param riskScore The calculated risk score
     * @param reason The reason for the alert
     * @param eventData The original event data
     */
    public static void triggerAlert(String userId, Integer riskScore, String reason, Map<String, Object> eventData) {
        // Determine severity
        String severity = riskScore >= CRITICAL_RISK_THRESHOLD ? 'CRITICAL' : 'HIGH';
        
        // Create alert record (could be custom object or platform event)
        AlertConfig config = new AlertConfig();
        config.userId = userId;
        config.riskScore = riskScore;
        config.reason = reason;
        config.eventData = eventData;
        config.timestamp = Datetime.now();
        config.severity = severity;
        config.requiresImmediate = severity == 'CRITICAL';
        
        // Queue the alert for async processing
        queueAlert(config);
    }
    
    /**
     * @description Get real-time statistics for a time window
     * @param timeWindowMinutes The number of minutes to look back
     * @return Map of statistics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRealtimeStats(Integer timeWindowMinutes) {
        Map<String, Object> stats = new Map<String, Object>{
            'totalEvents' => 0,
            'criticalEvents' => 0,
            'highRiskEvents' => 0,
            'mediumRiskEvents' => 0,
            'lowRiskEvents' => 0,
            'topEventTypes' => new List<String>(),
            'averageRiskScore' => 0,
            'timeWindow' => timeWindowMinutes
        };
        
        // Query recent evidence items as proxy for events
        // In production, this could query a real-time event store
        Datetime cutoffTime = Datetime.now().addMinutes(-timeWindowMinutes);
        
        try {
            List<AggregateResult> results = [
                SELECT Evidence_Type__c eventType, COUNT(Id) cnt
                FROM Prometheion_Evidence_Item__c
                WHERE CreatedDate >= :cutoffTime
                GROUP BY Evidence_Type__c
                ORDER BY COUNT(Id) DESC
                LIMIT 10
            ];
            
            Integer total = 0;
            List<String> topTypes = new List<String>();
            
            for (AggregateResult ar : results) {
                String eventType = (String)ar.get('eventType');
                Integer count = (Integer)ar.get('cnt');
                total += count;
                topTypes.add(eventType);
            }
            
            stats.put('totalEvents', total);
            stats.put('topEventTypes', topTypes);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error getting realtime stats: ' + e.getMessage());
        }
        
        return stats;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // RISK CALCULATION METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Get base risk score for event type
     * @param eventType The event type
     * @return Base risk score
     */
    private static Integer getBaseScore(String eventType) {
        return BASE_RISK_SCORES.containsKey(eventType) 
            ? BASE_RISK_SCORES.get(eventType) 
            : 10;
    }
    
    /**
     * @description Calculate time-based risk factor
     * @param eventData The event data
     * @return Time factor score
     */
    private static Integer calculateTimeFactor(Map<String, Object> eventData) {
        Integer factor = 0;
        
        // Get timestamp from event
        String timestampStr = getString(eventData, 'TIMESTAMP');
        Datetime eventTime = parseTimestamp(timestampStr);
        
        if (eventTime == null) {
            eventTime = Datetime.now();
        }
        
        // Check hour override in test data
        String hourOverride = getString(eventData, 'HOUR');
        Integer hour = String.isNotBlank(hourOverride) 
            ? Integer.valueOf(hourOverride) 
            : eventTime.hour();
        
        // Outside business hours (before 8 AM or after 6 PM)
        if (hour < 8 || hour >= 18) {
            factor += TIME_FACTOR_OUTSIDE_HOURS;
        }
        
        // Weekend
        String dayOfWeek = eventTime.format('EEEE');
        if (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday') {
            factor += TIME_FACTOR_WEEKEND;
        }
        
        return factor;
    }
    
    /**
     * @description Calculate location-based risk factor
     * @param eventData The event data
     * @return Location factor score
     */
    private static Integer calculateLocationFactor(Map<String, Object> eventData) {
        Integer factor = 0;
        
        // Check country
        String country = getString(eventData, 'COUNTRY');
        String geoLocation = getString(eventData, 'GEO_LOCATION');
        
        // Non-US location increases risk
        if (String.isNotBlank(country) &amp;&amp; country != 'United States') {
            factor += LOCATION_FACTOR_NON_US;
        } else if (String.isNotBlank(geoLocation) &amp;&amp; !geoLocation.contains('United States')) {
            factor += LOCATION_FACTOR_NON_US;
        }
        
        return factor;
    }
    
    /**
     * @description Calculate volume-based risk factor
     * @param eventData The event data
     * @return Volume factor score
     */
    private static Integer calculateVolumeFactor(Map<String, Object> eventData) {
        Integer factor = 0;
        
        // Get rows processed
        String rowsStr = getString(eventData, 'ROWS_PROCESSED');
        Integer rows = 0;
        
        if (String.isNotBlank(rowsStr)) {
            try {
                rows = Integer.valueOf(rowsStr);
            } catch (Exception e) {
                rows = 0;
            }
        }
        
        // High volume (>1000 rows)
        if (rows > 10000) {
            factor += VOLUME_FACTOR_CRITICAL;
        } else if (rows > 1000) {
            factor += VOLUME_FACTOR_HIGH;
        }
        
        return factor;
    }
    
    /**
     * @description Calculate user-based risk factor
     * @param eventData The event data
     * @return User factor score
     */
    private static Integer calculateUserFactor(Map<String, Object> eventData) {
        Integer factor = 0;
        
        String userId = getString(eventData, 'USER_ID');
        
        if (String.isNotBlank(userId)) {
            // Check if user is an admin (simplified check)
            try {
                User u = [
                    SELECT Profile.Name
                    FROM User
                    WHERE Id = :userId
                    LIMIT 1
                ];
                
                if (u.Profile.Name.contains('Admin') || u.Profile.Name == 'System Administrator') {
                    factor += ADMIN_USER_FACTOR;
                }
            } catch (Exception e) {
                // User not found or no access
            }
        }
        
        return factor;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // HELPER METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Build human-readable risk reason
     * @param eventData The event data
     * @param riskScore The calculated risk score
     * @return Risk reason string
     */
    private static String buildRiskReason(Map<String, Object> eventData, Integer riskScore) {
        List<String> reasons = new List<String>();
        
        String eventType = getString(eventData, 'EVENT_TYPE');
        reasons.add(eventType + ' event detected');
        
        // Check specific risk factors
        if (eventType == 'LoginAs') {
            reasons.add('User impersonation');
        }
        
        String country = getString(eventData, 'COUNTRY');
        if (String.isNotBlank(country) &amp;&amp; country != 'United States') {
            reasons.add('Non-US location: ' + country);
        }
        
        String rowsStr = getString(eventData, 'ROWS_PROCESSED');
        if (String.isNotBlank(rowsStr)) {
            Integer rows = Integer.valueOf(rowsStr);
            if (rows > 10000) {
                reasons.add('Large data volume: ' + rows + ' rows');
            }
        }
        
        return String.join(reasons, '; ') + ' (Risk Score: ' + riskScore + ')';
    }
    
    /**
     * @description Queue alert for async processing
     * @param config The alert configuration
     */
    private static void queueAlert(AlertConfig config) {
        // In production, this would queue to a Queueable or Platform Event
        // For now, log the alert
        System.debug(LoggingLevel.WARN, 'ALERT: ' + config.severity + ' - ' + config.reason);
        
        // Publish platform event
        Prometheion_Event__e alertEvent = new Prometheion_Event__e(
            Event_Type__c = 'Alert',
            Payload__c = JSON.serialize(config)
        );
        
        try {
            EventBus.publish(alertEvent);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to publish alert event: ' + e.getMessage());
        }
    }
    
    /**
     * @description Publish platform event notification
     * @param parsedEvent The parsed event data
     * @param riskScore The calculated risk score
     */
    private static void publishEventNotification(Map<String, Object> parsedEvent, Integer riskScore) {
        Prometheion_Event__e notification = new Prometheion_Event__e(
            Event_Type__c = (String)parsedEvent.get('eventType'),
            Payload__c = JSON.serialize(new Map<String, Object>{
                'event' => parsedEvent,
                'riskScore' => riskScore,
                'processedAt' => Datetime.now()
            })
        );
        
        try {
            EventBus.publish(notification);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to publish event notification: ' + e.getMessage());
        }
    }
    
    /**
     * @description Safely get string from map
     * @param data Source map
     * @param key Key to retrieve
     * @return String value or empty string
     */
    private static String getString(Map<String, Object> data, String key) {
        if (data == null || !data.containsKey(key)) {
            return '';
        }
        Object val = data.get(key);
        return val != null ? String.valueOf(val) : '';
    }
    
    /**
     * @description Parse timestamp string
     * @param timestampStr The timestamp string
     * @return Parsed Datetime or null
     */
    private static Datetime parseTimestamp(String timestampStr) {
        if (String.isBlank(timestampStr)) {
            return null;
        }
        try {
            return Datetime.valueOf(timestampStr.replace('T', ' ').left(19));
        } catch (Exception e) {
            return null;
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // INNER CLASSES
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Alert configuration wrapper
     */
    public class AlertConfig {
        public String userId;
        public Integer riskScore;
        public String reason;
        public Map<String, Object> eventData;
        public Datetime timestamp;
        public String severity; // CRITICAL, HIGH
        public Boolean requiresImmediate;
    }
}
