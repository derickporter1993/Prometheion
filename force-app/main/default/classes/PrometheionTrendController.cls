/**
 * PrometheionTrendController.cls
 * Time-series trend analysis with configurable granularity
 *
 * Security Features:
 * - Object whitelisting
 * - Field validation against schema
 * - Granularity validation
 * - WITH SECURITY_ENFORCED
 * - Date range bounds
 * - Mobile-friendly data sampling
 *
 * @author Derick Porter
 * @date 2026-01-03
 */
public with sharing class PrometheionTrendController {

    // Whitelisted objects
    private static final Set<String> ALLOWED_OBJECTS = new Set<String>{
        'Account',
        'Contact',
        'Opportunity',
        'Case',
        'Lead',
        'Alert__c',
        'API_Usage_Snapshot__c',
        'Deployment_Job__c',
        'Flow_Execution__c'
    };

    // Allowed granularities
    private static final Set<String> ALLOWED_GRANULARITIES = new Set<String>{
        'day', 'week', 'month', 'quarter', 'year'
    };

    // Date range limits
    private static final Integer MIN_MONTHS_BACK = 1;
    private static final Integer MAX_MONTHS_BACK = 36;
    private static final Integer DEFAULT_MONTHS_BACK = 12;

    // Data point limits
    private static final Integer MAX_DATA_POINTS = 500;

    /**
     * Get time-series trend data
     */
    @AuraEnabled(cacheable=true)
    public static TrendResult getTimeSeries(
        String objectApiName,
        String dateField,
        String metricField,
        String granularity,
        Integer monthsBack,
        String additionalFilters
    ) {
        // Validate inputs
        validateInputs(objectApiName, dateField, metricField, granularity);

        // Sanitize field names
        String safeDateField = sanitizeFieldName(dateField);
        String safeMetricField = sanitizeFieldName(metricField);
        String safeGranularity = granularity.toLowerCase();

        // Bound the date range
        Integer safeMonthsBack = boundMonthsBack(monthsBack);

        // Build the aggregation query
        String bucketExpr = getBucketExpression(safeGranularity, safeDateField);

        String soql = buildTrendQuery(
            objectApiName,
            bucketExpr,
            safeMetricField,
            safeDateField,
            safeMonthsBack,
            additionalFilters
        );

        List<AggregateResult> results;
        try {
            results = Database.query(soql);
        } catch (Exception e) {
            throw new AuraHandledException('Trend query failed: ' + e.getMessage());
        }

        // Transform to trend data
        return transformResults(results, safeGranularity, safeMonthsBack);
    }

    /**
     * Get available metric fields for an object
     */
    @AuraEnabled(cacheable=true)
    public static List<MetricFieldOption> getMetricFields(String objectApiName) {
        if (!ALLOWED_OBJECTS.contains(objectApiName)) {
            throw new AuraHandledException('Object not authorized: ' + objectApiName);
        }

        List<MetricFieldOption> options = new List<MetricFieldOption>();

        SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
        if (sType == null || !sType.getDescribe().isAccessible()) {
            return options;
        }

        Map<String, SObjectField> fieldMap = sType.getDescribe().fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();

            if (!dfr.isAccessible() || !dfr.isAggregatable()) {
                continue;
            }

            // Only numeric fields for metrics
            Schema.DisplayType fieldType = dfr.getType();
            if (fieldType == Schema.DisplayType.CURRENCY ||
                fieldType == Schema.DisplayType.DOUBLE ||
                fieldType == Schema.DisplayType.INTEGER ||
                fieldType == Schema.DisplayType.PERCENT) {

                MetricFieldOption opt = new MetricFieldOption();
                opt.apiName = dfr.getName();
                opt.label = dfr.getLabel();
                opt.fieldType = String.valueOf(fieldType);
                options.add(opt);
            }
        }

        // Add COUNT option
        MetricFieldOption countOpt = new MetricFieldOption();
        countOpt.apiName = 'Id';
        countOpt.label = 'Record Count';
        countOpt.fieldType = 'COUNT';
        options.add(0, countOpt);

        return options;
    }

    /**
     * Get available date fields for an object
     */
    @AuraEnabled(cacheable=true)
    public static List<DateFieldOption> getDateFields(String objectApiName) {
        if (!ALLOWED_OBJECTS.contains(objectApiName)) {
            throw new AuraHandledException('Object not authorized: ' + objectApiName);
        }

        List<DateFieldOption> options = new List<DateFieldOption>();

        SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
        if (sType == null || !sType.getDescribe().isAccessible()) {
            return options;
        }

        Map<String, SObjectField> fieldMap = sType.getDescribe().fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();

            if (!dfr.isAccessible() || !dfr.isFilterable()) {
                continue;
            }

            Schema.DisplayType fieldType = dfr.getType();
            if (fieldType == Schema.DisplayType.DATE ||
                fieldType == Schema.DisplayType.DATETIME) {

                DateFieldOption opt = new DateFieldOption();
                opt.apiName = dfr.getName();
                opt.label = dfr.getLabel();
                opt.fieldType = String.valueOf(fieldType);
                options.add(opt);
            }
        }

        return options;
    }

    /**
     * Validate all inputs
     */
    private static void validateInputs(
        String objectApiName,
        String dateField,
        String metricField,
        String granularity
    ) {
        // Validate object
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object name is required');
        }

        if (!ALLOWED_OBJECTS.contains(objectApiName)) {
            throw new AuraHandledException('Object not authorized: ' + objectApiName);
        }

        // Verify object access
        SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
        if (sType == null || !sType.getDescribe().isAccessible()) {
            throw new AuraHandledException('Access denied to object: ' + objectApiName);
        }

        // Validate fields
        if (String.isBlank(dateField)) {
            throw new AuraHandledException('Date field is required');
        }

        if (String.isBlank(metricField)) {
            throw new AuraHandledException('Metric field is required');
        }

        validateField(objectApiName, dateField, true);  // Must be date
        validateField(objectApiName, metricField, false); // Must be aggregatable

        // Validate granularity
        if (String.isBlank(granularity)) {
            throw new AuraHandledException('Granularity is required');
        }

        if (!ALLOWED_GRANULARITIES.contains(granularity.toLowerCase())) {
            throw new AuraHandledException('Invalid granularity. Allowed: ' +
                String.join(new List<String>(ALLOWED_GRANULARITIES), ', '));
        }
    }

    /**
     * Validate a field
     */
    private static void validateField(String objectName, String fieldName, Boolean mustBeDate) {
        String cleanField = sanitizeFieldName(fieldName);

        SObjectType sType = Schema.getGlobalDescribe().get(objectName);
        Map<String, SObjectField> fieldMap = sType.getDescribe().fields.getMap();

        if (!fieldMap.containsKey(cleanField.toLowerCase())) {
            throw new AuraHandledException('Invalid field: ' + fieldName);
        }

        DescribeFieldResult dfr = fieldMap.get(cleanField.toLowerCase()).getDescribe();

        if (!dfr.isAccessible()) {
            throw new AuraHandledException('Field not accessible: ' + fieldName);
        }

        if (mustBeDate) {
            Schema.DisplayType fieldType = dfr.getType();
            if (fieldType != Schema.DisplayType.DATE &&
                fieldType != Schema.DisplayType.DATETIME) {
                throw new AuraHandledException('Field must be a date type: ' + fieldName);
            }
        } else {
            // For metric fields, verify aggregatable
            if (!dfr.isAggregatable()) {
                throw new AuraHandledException('Field must be aggregatable: ' + fieldName);
            }
        }
    }

    /**
     * Bound months back to safe range
     */
    private static Integer boundMonthsBack(Integer monthsBack) {
        if (monthsBack == null || monthsBack < MIN_MONTHS_BACK) {
            return DEFAULT_MONTHS_BACK;
        }
        return Math.min(monthsBack, MAX_MONTHS_BACK);
    }

    /**
     * Get bucket expression for granularity
     */
    private static String getBucketExpression(String granularity, String dateField) {
        switch on granularity {
            when 'day' {
                return 'DAY_ONLY(' + dateField + ')';
            }
            when 'week' {
                return 'WEEK_IN_YEAR(' + dateField + ')';
            }
            when 'quarter' {
                return 'CALENDAR_QUARTER(' + dateField + ')';
            }
            when 'year' {
                return 'CALENDAR_YEAR(' + dateField + ')';
            }
            when else {
                return 'CALENDAR_MONTH(' + dateField + ')';
            }
        }
    }

    /**
     * Build the trend query
     */
    private static String buildTrendQuery(
        String objectName,
        String bucketExpr,
        String metricField,
        String dateField,
        Integer monthsBack,
        String additionalFilters
    ) {
        // Determine aggregate function
        String aggExpr;
        if (metricField.equalsIgnoreCase('Id')) {
            aggExpr = 'COUNT(Id)';
        } else {
            aggExpr = 'SUM(' + metricField + ')';
        }

        String soql = 'SELECT ' + bucketExpr + ' bucketDate, ' +
                                  aggExpr + ' metricValue, ' +
                                  'CALENDAR_YEAR(' + dateField + ') bucketYear ' +
                      'FROM ' + objectName +
                      ' WHERE ' + dateField + ' = LAST_N_MONTHS:' + monthsBack;

        // Add additional filters if provided
        if (String.isNotBlank(additionalFilters)) {
            // Basic sanitization
            String safeFilters = additionalFilters
                .replaceAll('(?i)(INSERT|UPDATE|DELETE|DROP)', '')
                .trim();

            if (String.isNotBlank(safeFilters)) {
                soql += ' AND (' + safeFilters + ')';
            }
        }

        soql += ' GROUP BY ' + bucketExpr + ', CALENDAR_YEAR(' + dateField + ')' +
                ' ORDER BY CALENDAR_YEAR(' + dateField + '), ' + bucketExpr +
                ' WITH SECURITY_ENFORCED' +
                ' LIMIT ' + MAX_DATA_POINTS;

        return soql;
    }

    /**
     * Transform aggregate results to trend data
     */
    private static TrendResult transformResults(
        List<AggregateResult> results,
        String granularity,
        Integer monthsBack
    ) {
        List<TimeBucket> buckets = new List<TimeBucket>();

        Decimal total = 0;
        Decimal minValue = null;
        Decimal maxValue = null;
        Decimal prevValue = null;

        for (AggregateResult ar : results) {
            TimeBucket tb = new TimeBucket();

            // Build bucket label based on granularity
            Object bucketDate = ar.get('bucketDate');
            Integer bucketYear = (Integer)ar.get('bucketYear');

            tb.bucketDate = formatBucketLabel(bucketDate, bucketYear, granularity);
            tb.bucketValue = bucketDate;
            tb.bucketYear = bucketYear;

            // Get metric value
            Decimal value = ar.get('metricValue') != null ?
                (Decimal)ar.get('metricValue') : 0;

            tb.metricValue = value;

            // Calculate change from previous period
            if (prevValue != null) {
                tb.changeFromPrevious = value - prevValue;
                tb.percentChange = prevValue != 0 ?
                    ((value - prevValue) / prevValue * 100).setScale(1, RoundingMode.HALF_UP) : null;
            }
            prevValue = value;

            // Track aggregates
            total += value;
            if (minValue == null || value < minValue) minValue = value;
            if (maxValue == null || value > maxValue) maxValue = value;

            buckets.add(tb);
        }

        // Calculate statistics
        TrendResult result = new TrendResult();
        result.buckets = buckets;
        result.granularity = granularity;
        result.periodCount = buckets.size();
        result.total = total;
        result.average = buckets.isEmpty() ? 0 :
            (total / buckets.size()).setScale(2, RoundingMode.HALF_UP);
        result.minValue = minValue;
        result.maxValue = maxValue;
        result.monthsBack = monthsBack;

        // Calculate overall trend
        if (buckets.size() >= 2) {
            Decimal firstValue = buckets[0].metricValue;
            Decimal lastValue = buckets[buckets.size() - 1].metricValue;
            result.overallChange = lastValue - firstValue;
            result.overallPercentChange = firstValue != 0 ?
                ((lastValue - firstValue) / firstValue * 100).setScale(1, RoundingMode.HALF_UP) : null;
            result.trendDirection = lastValue > firstValue ? 'up' :
                                   (lastValue < firstValue ? 'down' : 'flat');
        } else {
            result.trendDirection = 'insufficient_data';
        }

        return result;
    }

    /**
     * Format bucket label for display
     */
    private static String formatBucketLabel(Object bucketDate, Integer year, String granularity) {
        if (bucketDate == null) {
            return 'Unknown';
        }

        switch on granularity {
            when 'day' {
                return String.valueOf(bucketDate);
            }
            when 'week' {
                return 'Week ' + bucketDate + ', ' + year;
            }
            when 'quarter' {
                return 'Q' + bucketDate + ' ' + year;
            }
            when 'year' {
                return String.valueOf(bucketDate);
            }
            when else {
                // Month
                Integer monthNum = (Integer)bucketDate;
                List<String> monthNames = new List<String>{
                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                };
                String monthName = monthNum > 0 && monthNum <= 12 ?
                    monthNames[monthNum - 1] : String.valueOf(monthNum);
                return monthName + ' ' + year;
            }
        }
    }

    /**
     * Sanitize field name
     */
    private static String sanitizeFieldName(String fieldName) {
        if (String.isBlank(fieldName)) return '';
        return fieldName.replaceAll('[^a-zA-Z0-9_]+', '');
    }

    // ==================== Inner Classes ====================

    public class TimeBucket {
        @AuraEnabled public String bucketDate;
        @AuraEnabled public Object bucketValue;
        @AuraEnabled public Integer bucketYear;
        @AuraEnabled public Decimal metricValue;
        @AuraEnabled public Decimal changeFromPrevious;
        @AuraEnabled public Decimal percentChange;
    }

    public class TrendResult {
        @AuraEnabled public List<TimeBucket> buckets;
        @AuraEnabled public String granularity;
        @AuraEnabled public Integer periodCount;
        @AuraEnabled public Integer monthsBack;
        @AuraEnabled public Decimal total;
        @AuraEnabled public Decimal average;
        @AuraEnabled public Decimal minValue;
        @AuraEnabled public Decimal maxValue;
        @AuraEnabled public Decimal overallChange;
        @AuraEnabled public Decimal overallPercentChange;
        @AuraEnabled public String trendDirection;
    }

    public class MetricFieldOption {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String fieldType;
    }

    public class DateFieldOption {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String fieldType;
    }
}
