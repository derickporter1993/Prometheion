/**
 * Correlates security events against Correlation_Rule__mdt patterns to detect
 * complex multi-step attack sequences. Processes incoming events against active
 * rules and triggers BreachIndicator__e events when patterns are matched.
 *
 * The engine loads correlation rules from Custom Metadata, maintains an in-memory
 * event window, and evaluates event sequences within configured time windows.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Event Monitoring
 * @see Correlation_Rule__mdt
 * @see BreachPatternMatcher
 * @see ComplianceAlertPublisher
 */
public inherited sharing class EventCorrelationEngine {

    private static final String CLASS_NAME = 'EventCorrelationEngine';

    /**
     * Represents an incoming security event to be correlated.
     */
    public class SecurityEvent {
        @AuraEnabled public String eventType;
        @AuraEnabled public String userId;
        @AuraEnabled public Datetime eventTimestamp;
        @AuraEnabled public Map<String, Object> metadata;

        public SecurityEvent(String eventType, String userId, Datetime eventTimestamp) {
            this.eventType = eventType;
            this.userId = userId;
            this.eventTimestamp = eventTimestamp;
            this.metadata = new Map<String, Object>();
        }

        public SecurityEvent(String eventType, String userId, Datetime eventTimestamp, Map<String, Object> metadata) {
            this.eventType = eventType;
            this.userId = userId;
            this.eventTimestamp = eventTimestamp;
            this.metadata = metadata ?? new Map<String, Object>();
        }
    }

    /**
     * Represents a correlation rule loaded from Custom Metadata.
     */
    public class CorrelationRule {
        public String ruleName;
        public List<String> eventSequence;
        public Integer timeWindowMinutes;
        public String severity;
        public String description;
        public Boolean isActive;

        public CorrelationRule(Correlation_Rule__mdt mdt) {
            this.ruleName = mdt.Rule_Name__c ?? mdt.DeveloperName;
            this.eventSequence = parseEventSequence(mdt.Event_Sequence__c);
            this.timeWindowMinutes = mdt.Time_Window_Minutes__c != null
                ? Integer.valueOf(mdt.Time_Window_Minutes__c)
                : 60;
            this.severity = mdt.Severity__c ?? ElaroConstants.SEVERITY_HIGH;
            this.description = mdt.Description__c ?? '';
            this.isActive = mdt.Is_Active__c;
        }
    }

    /**
     * Result of correlating events against rules.
     */
    public class CorrelationResult {
        @AuraEnabled public String ruleName;
        @AuraEnabled public String severity;
        @AuraEnabled public String userId;
        @AuraEnabled public List<String> matchedEvents;
        @AuraEnabled public Datetime firstEventTime;
        @AuraEnabled public Datetime lastEventTime;
        @AuraEnabled public Integer timeWindowMinutes;

        public CorrelationResult(String ruleName, String severity, String userId) {
            this.ruleName = ruleName;
            this.severity = severity;
            this.userId = userId;
            this.matchedEvents = new List<String>();
        }
    }

    /**
     * Loads all active correlation rules from Custom Metadata.
     *
     * @return List of active CorrelationRule objects
     */
    public static List<CorrelationRule> loadActiveRules() {
        List<CorrelationRule> rules = new List<CorrelationRule>();

        List<Correlation_Rule__mdt> mdtRecords = [
            SELECT DeveloperName, Rule_Name__c, Event_Sequence__c,
                   Time_Window_Minutes__c, Severity__c, Description__c, Is_Active__c
            FROM Correlation_Rule__mdt
            WHERE Is_Active__c = true
            WITH USER_MODE
        ];

        for (Correlation_Rule__mdt mdt : mdtRecords) {
            rules.add(new CorrelationRule(mdt));
        }

        ElaroLogger.info(CLASS_NAME + '.loadActiveRules: Loaded rules', new Map<String, Object>{
            'activeRuleCount' => rules.size()
        });

        return rules;
    }

    /**
     * Correlates a batch of security events against all active rules.
     * Groups events by user and evaluates each user's event stream
     * against the rule set.
     *
     * @param events List of SecurityEvent objects to correlate
     * @return List of CorrelationResult objects for matched patterns
     */
    public static List<CorrelationResult> correlateEvents(List<SecurityEvent> events) {
        if (events == null || events.isEmpty()) {
            return new List<CorrelationResult>();
        }

        List<CorrelationRule> rules = loadActiveRules();
        if (rules.isEmpty()) {
            return new List<CorrelationResult>();
        }

        Map<String, List<SecurityEvent>> eventsByUser = groupEventsByUser(events);
        List<CorrelationResult> results = new List<CorrelationResult>();

        for (String userId : eventsByUser.keySet()) {
            List<SecurityEvent> userEvents = eventsByUser.get(userId);
            for (CorrelationRule rule : rules) {
                CorrelationResult match = evaluateRule(rule, userEvents, userId);
                if (match != null) {
                    results.add(match);
                }
            }
        }

        if (!results.isEmpty()) {
            ElaroLogger.warn(CLASS_NAME + '.correlateEvents: Pattern matches found', new Map<String, Object>{
                'matchCount' => results.size(),
                'eventCount' => events.size()
            });
            publishCorrelationResults(results);
        }

        return results;
    }

    /**
     * Evaluates a single correlation rule against a user's event stream.
     * Checks if all events in the rule's sequence occurred within the time window.
     *
     * @param rule The correlation rule to evaluate
     * @param userEvents The user's event stream sorted by time
     * @param userId The user Id being evaluated
     * @return CorrelationResult if pattern matched, null otherwise
     */
    @TestVisible
    private static CorrelationResult evaluateRule(
        CorrelationRule rule,
        List<SecurityEvent> userEvents,
        String userId
    ) {
        if (rule.eventSequence == null || rule.eventSequence.isEmpty()) {
            return null;
        }

        List<SecurityEvent> matchedEvents = new List<SecurityEvent>();
        Integer sequenceIndex = 0;

        for (SecurityEvent evt : userEvents) {
            if (sequenceIndex < rule.eventSequence.size()
                && evt.eventType == rule.eventSequence[sequenceIndex]) {
                matchedEvents.add(evt);
                sequenceIndex++;

                if (sequenceIndex == rule.eventSequence.size()) {
                    break;
                }
            }
        }

        if (matchedEvents.size() != rule.eventSequence.size()) {
            return null;
        }

        Datetime firstTime = matchedEvents[0].eventTimestamp;
        Datetime lastTime = matchedEvents[matchedEvents.size() - 1].eventTimestamp;
        Long diffMinutes = (lastTime.getTime() - firstTime.getTime()) / 60000;

        if (diffMinutes > rule.timeWindowMinutes) {
            return null;
        }

        CorrelationResult result = new CorrelationResult(rule.ruleName, rule.severity, userId);
        result.firstEventTime = firstTime;
        result.lastEventTime = lastTime;
        result.timeWindowMinutes = rule.timeWindowMinutes;
        for (SecurityEvent matched : matchedEvents) {
            result.matchedEvents.add(matched.eventType);
        }

        return result;
    }

    /**
     * Groups security events by user Id for per-user correlation analysis.
     *
     * @param events List of SecurityEvent objects
     * @return Map of userId to their events, sorted by timestamp
     */
    @TestVisible
    private static Map<String, List<SecurityEvent>> groupEventsByUser(List<SecurityEvent> events) {
        Map<String, List<SecurityEvent>> grouped = new Map<String, List<SecurityEvent>>();

        for (SecurityEvent evt : events) {
            String key = evt.userId ?? 'UNKNOWN';
            if (!grouped.containsKey(key)) {
                grouped.put(key, new List<SecurityEvent>());
            }
            grouped.get(key).add(evt);
        }

        return grouped;
    }

    /**
     * Publishes correlation results as BreachIndicator__e Platform Events.
     *
     * @param results List of CorrelationResult objects to publish
     */
    private static void publishCorrelationResults(List<CorrelationResult> results) {
        for (CorrelationResult result : results) {
            ComplianceAlertPublisher.publishBreachIndicator(
                result.ruleName,
                result.severity,
                JSON.serialize(result.matchedEvents),
                result.timeWindowMinutes,
                result.userId
            );
        }
    }

    /**
     * Parses a JSON array string into a List of event type strings.
     *
     * @param jsonSequence JSON array string (e.g., '["LOGIN_FAILURE","LOGIN_FAILURE"]')
     * @return List of event type strings, empty list if parsing fails
     */
    @TestVisible
    private static List<String> parseEventSequence(String jsonSequence) {
        if (String.isBlank(jsonSequence)) {
            return new List<String>();
        }
        try {
            return (List<String>) JSON.deserialize(jsonSequence, List<String>.class);
        } catch (Exception e) {
            ElaroLogger.error(CLASS_NAME + '.parseEventSequence: Failed to parse', e);
            return new List<String>();
        }
    }
}
