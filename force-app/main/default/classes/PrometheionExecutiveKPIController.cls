/**
 * PrometheionExecutiveKPIController.cls
 * Metadata-driven KPI dashboard with real-time Platform Event refresh
 *
 * Security Features:
 * - Custom Metadata driven configuration
 * - SOQL query validation and sanitization
 * - WITH SECURITY_ENFORCED on all queries
 * - Aggregate-only query enforcement
 * - Error isolation per KPI
 *
 * @author Derick Porter
 * @date 2026-01-03
 */
public with sharing class PrometheionExecutiveKPIController {

    // Allowed aggregate functions
    private static final Set<String> ALLOWED_AGGREGATES = new Set<String>{
        'COUNT(', 'COUNT_DISTINCT(', 'SUM(', 'AVG(', 'MIN(', 'MAX('
    };

    // Disallowed keywords for query injection prevention
    private static final Set<String> DISALLOWED_KEYWORDS = new Set<String>{
        'INSERT', 'UPDATE', 'DELETE', 'UPSERT', 'MERGE', 'UNDELETE',
        'DROP', 'TRUNCATE', 'ALTER', 'CREATE', 'GRANT', 'REVOKE'
    };

    /**
     * Get all active KPI metrics
     */
    @AuraEnabled(cacheable=true)
    public static List<KPIMetric> getKPIMetrics(String metadataRecordIds) {
        List<KPIMetric> results = new List<KPIMetric>();

        List<Executive_KPI__mdt> kpiConfigs = [
            SELECT
                DeveloperName,
                KPI_Name__c,
                Metric_Label__c,
                SOQL_Query__c,
                Format_Type__c,
                Target_Value__c,
                Green_Threshold__c,
                Yellow_Threshold__c,
                Red_Threshold__c,
                Trend_Direction__c,
                Sort_Order__c,
                Description__c
            FROM Executive_KPI__mdt
            WHERE Is_Active__c = true
            ORDER BY Sort_Order__c NULLS LAST
            LIMIT 50
        ];

        for (Executive_KPI__mdt config : kpiConfigs) {
            try {
                KPIMetric metric = executeKPIQuery(config);
                if (metric != null) {
                    results.add(metric);
                }
            } catch (Exception e) {
                // Log error but don't fail entire dashboard
                System.debug(LoggingLevel.ERROR,
                    'KPI query failed for ' + config.DeveloperName + ': ' + e.getMessage());

                // Add placeholder with error state
                KPIMetric errorMetric = new KPIMetric();
                errorMetric.kpiName = config.KPI_Name__c;
                errorMetric.label = config.Metric_Label__c;
                errorMetric.hasError = true;
                errorMetric.errorMessage = 'Unable to calculate metric';
                results.add(errorMetric);
            }
        }

        return results;
    }

    /**
     * Get a single KPI by name (for real-time refresh)
     */
    @AuraEnabled
    public static KPIMetric getKPIByName(String kpiName) {
        if (String.isBlank(kpiName)) {
            throw new AuraHandledException('KPI name is required');
        }

        String sanitizedName = kpiName.replaceAll('[^a-zA-Z0-9_]+', '');

        List<Executive_KPI__mdt> configs = [
            SELECT
                DeveloperName,
                KPI_Name__c,
                Metric_Label__c,
                SOQL_Query__c,
                Format_Type__c,
                Target_Value__c,
                Green_Threshold__c,
                Yellow_Threshold__c,
                Red_Threshold__c,
                Trend_Direction__c
            FROM Executive_KPI__mdt
            WHERE KPI_Name__c = :sanitizedName
            AND Is_Active__c = true
            LIMIT 1
        ];

        if (configs.isEmpty()) {
            throw new AuraHandledException('KPI not found: ' + kpiName);
        }

        return executeKPIQuery(configs[0]);
    }

    /**
     * Execute a KPI query with full security validation
     */
    private static KPIMetric executeKPIQuery(Executive_KPI__mdt config) {
        // Validate and secure the query
        String safeQuery = validateAndSecureQuery(config.SOQL_Query__c);

        // Execute the query
        List<AggregateResult> queryResults = Database.query(safeQuery);

        if (queryResults.isEmpty()) {
            return null;
        }

        // Extract the metric value
        Decimal metricValue = extractMetricValue(queryResults[0]);

        // Build the KPI metric response
        KPIMetric metric = new KPIMetric();
        metric.kpiName = config.KPI_Name__c;
        metric.label = config.Metric_Label__c;
        metric.description = config.Description__c;
        metric.currentValue = metricValue;
        metric.targetValue = config.Target_Value__c;
        metric.greenThreshold = config.Green_Threshold__c;
        metric.yellowThreshold = config.Yellow_Threshold__c;
        metric.redThreshold = config.Red_Threshold__c;
        metric.formatType = config.Format_Type__c;
        metric.trendDirection = config.Trend_Direction__c;
        metric.status = calculateStatus(metricValue, config);
        metric.percentOfTarget = calculatePercentOfTarget(metricValue, config.Target_Value__c);
        metric.hasError = false;

        return metric;
    }

    /**
     * Validate and secure a SOQL query from metadata
     */
    private static String validateAndSecureQuery(String query) {
        if (String.isBlank(query)) {
            throw new AuraHandledException('KPI query cannot be empty');
        }

        String upperQuery = query.toUpperCase().trim();

        // Must be a SELECT statement
        if (!upperQuery.startsWith('SELECT')) {
            throw new AuraHandledException('Only SELECT queries are allowed');
        }

        // Must contain an aggregate function
        Boolean hasAggregate = false;
        for (String agg : ALLOWED_AGGREGATES) {
            if (upperQuery.contains(agg)) {
                hasAggregate = true;
                break;
            }
        }

        if (!hasAggregate) {
            throw new AuraHandledException('KPI queries must use aggregate functions (COUNT, SUM, AVG, MIN, MAX)');
        }

        // Check for disallowed keywords (DML, DDL)
        for (String keyword : DISALLOWED_KEYWORDS) {
            if (upperQuery.contains(keyword)) {
                throw new AuraHandledException('Query contains disallowed keyword: ' + keyword);
            }
        }

        // Check for subqueries (not allowed for KPIs)
        Integer selectCount = upperQuery.countMatches('SELECT');
        if (selectCount > 1) {
            throw new AuraHandledException('Subqueries are not allowed in KPI queries');
        }

        // Add WITH SECURITY_ENFORCED if not present
        if (!upperQuery.contains('WITH SECURITY_ENFORCED')) {
            // Find the right position to insert (before GROUP BY, HAVING, ORDER BY, LIMIT, or end)
            String insertPattern = '(?i)(\\s+GROUP\\s+BY|\\s+HAVING|\\s+ORDER\\s+BY|\\s+LIMIT|$)';
            query = query.replaceFirst(insertPattern, ' WITH SECURITY_ENFORCED$1');
        }

        return query;
    }

    /**
     * Extract metric value from aggregate result
     */
    private static Decimal extractMetricValue(AggregateResult ar) {
        // Try common aggregate aliases
        Object value = ar.get('metricValue');

        if (value == null) {
            value = ar.get('expr0'); // Default aggregate alias
        }

        if (value == null) {
            // Try to get any numeric field
            Map<String, Object> fields = ar.getPopulatedFieldsAsMap();
            for (Object v : fields.values()) {
                if (v instanceof Decimal || v instanceof Integer || v instanceof Double) {
                    value = v;
                    break;
                }
            }
        }

        if (value == null) {
            return 0;
        }

        if (value instanceof Integer) {
            return Decimal.valueOf((Integer)value);
        } else if (value instanceof Double) {
            return Decimal.valueOf((Double)value);
        } else if (value instanceof Decimal) {
            return (Decimal)value;
        }

        return 0;
    }

    /**
     * Calculate KPI status based on thresholds
     */
    private static String calculateStatus(Decimal value, Executive_KPI__mdt config) {
        if (value == null) {
            return 'unknown';
        }

        // Higher is better (default)
        if (config.Trend_Direction__c == null || config.Trend_Direction__c == 'higher_is_better') {
            if (config.Green_Threshold__c != null && value >= config.Green_Threshold__c) {
                return 'green';
            } else if (config.Yellow_Threshold__c != null && value >= config.Yellow_Threshold__c) {
                return 'yellow';
            } else {
                return 'red';
            }
        }
        // Lower is better (e.g., cycle time, delinquency)
        else if (config.Trend_Direction__c == 'lower_is_better') {
            if (config.Green_Threshold__c != null && value <= config.Green_Threshold__c) {
                return 'green';
            } else if (config.Yellow_Threshold__c != null && value <= config.Yellow_Threshold__c) {
                return 'yellow';
            } else {
                return 'red';
            }
        }

        return 'unknown';
    }

    /**
     * Calculate percentage of target achieved
     */
    private static Decimal calculatePercentOfTarget(Decimal value, Decimal target) {
        if (value == null || target == null || target == 0) {
            return null;
        }
        return (value / target * 100).setScale(1, RoundingMode.HALF_UP);
    }

    // ==================== Inner Classes ====================

    public class KPIMetric {
        @AuraEnabled public String kpiName;
        @AuraEnabled public String label;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal currentValue;
        @AuraEnabled public Decimal targetValue;
        @AuraEnabled public Decimal greenThreshold;
        @AuraEnabled public Decimal yellowThreshold;
        @AuraEnabled public Decimal redThreshold;
        @AuraEnabled public String formatType;
        @AuraEnabled public String trendDirection;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal percentOfTarget;
        @AuraEnabled public Decimal trendValue;
        @AuraEnabled public Boolean hasError;
        @AuraEnabled public String errorMessage;
    }
}
