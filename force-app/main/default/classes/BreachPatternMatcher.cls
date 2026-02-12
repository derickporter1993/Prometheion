/**
 * Provides pattern matching utilities for breach detection. Analyzes security
 * event sequences against known attack patterns and calculates threat scores
 * based on event frequency, severity, and temporal proximity.
 *
 * Works in conjunction with {@link EventCorrelationEngine} to provide
 * a layered approach to breach detection — the engine handles rule-based
 * correlation while this class provides statistical pattern analysis.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Event Monitoring
 * @see EventCorrelationEngine
 * @see ComplianceAlertPublisher
 */
public inherited sharing class BreachPatternMatcher {

    private static final String CLASS_NAME = 'BreachPatternMatcher';

    /**
     * Threshold multiplier for anomaly detection. Events exceeding
     * this multiple of the baseline frequency are flagged.
     */
    private static final Decimal ANOMALY_THRESHOLD_MULTIPLIER = 3.0;

    /**
     * Minimum number of events required to establish a baseline.
     */
    private static final Integer MIN_BASELINE_EVENTS = 5;

    /**
     * Represents an analyzed breach pattern with threat scoring.
     */
    public class PatternAnalysis {
        @AuraEnabled public String patternName;
        @AuraEnabled public Decimal threatScore;
        @AuraEnabled public String severity;
        @AuraEnabled public Integer matchedEventCount;
        @AuraEnabled public Integer timeWindowMinutes;
        @AuraEnabled public String userId;
        @AuraEnabled public List<String> matchedEventTypes;
        @AuraEnabled public String description;

        public PatternAnalysis(String patternName) {
            this.patternName = patternName;
            this.threatScore = 0;
            this.matchedEventTypes = new List<String>();
        }
    }

    /**
     * Analyzes a set of security events for breach patterns by running
     * both rule-based correlation and statistical anomaly detection.
     *
     * @param events List of SecurityEvent objects to analyze
     * @return List of PatternAnalysis results for detected patterns
     */
    public static List<PatternAnalysis> analyzeEvents(
        List<EventCorrelationEngine.SecurityEvent> events
    ) {
        List<PatternAnalysis> analyses = new List<PatternAnalysis>();

        if (events == null || events.isEmpty()) {
            return analyses;
        }

        List<EventCorrelationEngine.CorrelationResult> correlations =
            EventCorrelationEngine.correlateEvents(events);

        for (EventCorrelationEngine.CorrelationResult correlation : correlations) {
            PatternAnalysis analysis = new PatternAnalysis(correlation.ruleName);
            analysis.severity = correlation.severity;
            analysis.userId = correlation.userId;
            analysis.matchedEventCount = correlation.matchedEvents.size();
            analysis.matchedEventTypes = correlation.matchedEvents;
            analysis.timeWindowMinutes = correlation.timeWindowMinutes;
            analysis.threatScore = calculateThreatScore(correlation);
            analyses.add(analysis);
        }

        List<PatternAnalysis> anomalies = detectFrequencyAnomalies(events);
        analyses.addAll(anomalies);

        if (!analyses.isEmpty()) {
            ElaroLogger.warn(CLASS_NAME + '.analyzeEvents: Patterns detected', new Map<String, Object>{
                'correlationMatches' => correlations.size(),
                'anomalies' => anomalies.size(),
                'totalPatterns' => analyses.size()
            });
        }

        return analyses;
    }

    /**
     * Calculates a threat score (0-10) for a correlation match based on
     * severity, event count, and time compression.
     *
     * @param correlation The correlation result to score
     * @return Threat score from 0.0 to 10.0
     */
    @TestVisible
    private static Decimal calculateThreatScore(
        EventCorrelationEngine.CorrelationResult correlation
    ) {
        Decimal baseScore = 0;

        if (correlation.severity == ElaroConstants.SEVERITY_CRITICAL) {
            baseScore = 8.0;
        } else if (correlation.severity == ElaroConstants.SEVERITY_HIGH) {
            baseScore = 6.0;
        } else if (correlation.severity == ElaroConstants.SEVERITY_MEDIUM) {
            baseScore = 4.0;
        } else {
            baseScore = 2.0;
        }

        Decimal eventCountBonus = Math.min(
            correlation.matchedEvents.size() * 0.3,
            1.0
        );

        Decimal timeCompressionBonus = 0;
        if (correlation.firstEventTime != null && correlation.lastEventTime != null
            && correlation.timeWindowMinutes > 0) {
            Long actualMinutes = (correlation.lastEventTime.getTime()
                - correlation.firstEventTime.getTime()) / 60000;
            Decimal compressionRatio = 1 - (Decimal.valueOf(actualMinutes)
                / Decimal.valueOf(correlation.timeWindowMinutes));
            timeCompressionBonus = Math.max(compressionRatio, 0) * 1.0;
        }

        Decimal totalScore = baseScore + eventCountBonus + timeCompressionBonus;
        return Math.min(totalScore, ElaroConstants.RISK_SCORE_MAX);
    }

    /**
     * Detects frequency-based anomalies by identifying event types that
     * occur at rates exceeding the baseline threshold.
     *
     * @param events List of SecurityEvent objects to analyze
     * @return List of PatternAnalysis objects for frequency anomalies
     */
    @TestVisible
    private static List<PatternAnalysis> detectFrequencyAnomalies(
        List<EventCorrelationEngine.SecurityEvent> events
    ) {
        List<PatternAnalysis> anomalies = new List<PatternAnalysis>();

        Map<String, Map<String, Integer>> eventCountsByUserAndType =
            new Map<String, Map<String, Integer>>();

        for (EventCorrelationEngine.SecurityEvent evt : events) {
            String key = evt.userId ?? 'UNKNOWN';
            if (!eventCountsByUserAndType.containsKey(key)) {
                eventCountsByUserAndType.put(key, new Map<String, Integer>());
            }
            Map<String, Integer> typeCounts = eventCountsByUserAndType.get(key);
            Integer current = typeCounts.get(evt.eventType) ?? 0;
            typeCounts.put(evt.eventType, current + 1);
        }

        for (String userId : eventCountsByUserAndType.keySet()) {
            Map<String, Integer> typeCounts = eventCountsByUserAndType.get(userId);
            Decimal avgCount = calculateAverage(typeCounts.values());

            if (avgCount < 1) {
                continue;
            }

            for (String eventType : typeCounts.keySet()) {
                Integer count = typeCounts.get(eventType);
                if (count >= MIN_BASELINE_EVENTS
                    && count > avgCount * ANOMALY_THRESHOLD_MULTIPLIER) {

                    PatternAnalysis anomaly = new PatternAnalysis('Frequency Anomaly: ' + eventType);
                    anomaly.severity = ElaroConstants.SEVERITY_MEDIUM;
                    anomaly.userId = userId;
                    anomaly.matchedEventCount = count;
                    anomaly.matchedEventTypes.add(eventType);
                    anomaly.description = 'Event type ' + eventType + ' occurred ' + count
                        + ' times (average: ' + avgCount.setScale(1) + ')';
                    anomaly.threatScore = Math.min(
                        (Decimal.valueOf(count) / (avgCount * ANOMALY_THRESHOLD_MULTIPLIER)) * 5,
                        ElaroConstants.RISK_SCORE_MAX
                    );
                    anomalies.add(anomaly);
                }
            }
        }

        return anomalies;
    }

    /**
     * Calculates the average of a collection of integer values.
     *
     * @param values Collection of integer values
     * @return Average as a Decimal, or 0 if empty
     */
    @TestVisible
    private static Decimal calculateAverage(List<Integer> values) {
        if (values == null || values.isEmpty()) {
            return 0;
        }
        Integer total = 0;
        for (Integer v : values) {
            total += v;
        }
        return Decimal.valueOf(total) / Decimal.valueOf(values.size());
    }

    /**
     * Checks whether a specific event sequence matches a known pattern.
     * Useful for real-time single-pattern validation without full correlation.
     *
     * @param eventTypes Ordered list of event types to check
     * @param patternTypes Expected ordered pattern of event types
     * @return True if the event types match the pattern in order
     */
    public static Boolean matchesPattern(List<String> eventTypes, List<String> patternTypes) {
        if (eventTypes == null || patternTypes == null
            || eventTypes.size() < patternTypes.size()) {
            return false;
        }

        Integer patternIndex = 0;
        for (String eventType : eventTypes) {
            if (patternIndex < patternTypes.size()
                && eventType == patternTypes[patternIndex]) {
                patternIndex++;
                if (patternIndex == patternTypes.size()) {
                    return true;
                }
            }
        }

        return false;
    }
}
