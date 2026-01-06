/**
 * PrometheionMatrixController.cls
 * Matrix/heatmap comparison analytics with governor limit protection
 *
 * Security Features:
 * - Object whitelisting
 * - Field validation against schema
 * - Aggregate function whitelisting
 * - WITH SECURITY_ENFORCED
 * - Group count estimation to prevent limit errors
 * - Automatic fallback to summary objects
 *
 * @author Derick Porter
 * @date 2026-01-03
 */
public with sharing class PrometheionMatrixController {

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

    // Allowed aggregate functions
    private static final Set<String> ALLOWED_AGGREGATES = new Set<String>{
        'COUNT', 'COUNT_DISTINCT', 'SUM', 'AVG', 'MIN', 'MAX'
    };

    // Governor limit thresholds
    private static final Integer MAX_GROUP_COMBINATIONS = 1800;
    private static final Integer MAX_QUERY_ROWS = 2000;

    /**
     * Execute matrix query with automatic limit protection
     */
    @AuraEnabled
    public static MatrixResult executeMatrixQuery(String configJson) {
        if (String.isBlank(configJson)) {
            throw new AuraHandledException('Matrix configuration is required');
        }

        MatrixConfiguration cfg;
        try {
            cfg = (MatrixConfiguration)JSON.deserialize(configJson, MatrixConfiguration.class);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid matrix configuration format');
        }

        // Validate configuration
        validateMatrixConfig(cfg);

        // Estimate group count to determine query strategy
        Integer estimatedGroups = estimateGroupCount(cfg);

        MatrixResult result;

        if (estimatedGroups > MAX_GROUP_COMBINATIONS) {
            // Too many combinations - use pre-aggregated summary
            result = queryFromSummaryObject(cfg);
            result.usedSummaryFallback = true;
            result.estimatedGroups = estimatedGroups;
        } else {
            // Direct query is safe
            result = queryDirect(cfg);
            result.usedSummaryFallback = false;
            result.estimatedGroups = estimatedGroups;
        }

        return result;
    }

    /**
     * Get available dimension fields for matrix configuration
     */
    @AuraEnabled(cacheable=true)
    public static List<DimensionField> getDimensionFields(String objectApiName) {
        if (!ALLOWED_OBJECTS.contains(objectApiName)) {
            throw new AuraHandledException('Object not authorized: ' + objectApiName);
        }

        List<DimensionField> dimensions = new List<DimensionField>();

        SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
        if (sType == null || !sType.getDescribe().isAccessible()) {
            return dimensions;
        }

        Map<String, SObjectField> fieldMap = sType.getDescribe().fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();

            // Only include groupable, accessible fields
            if (!dfr.isAccessible() || !dfr.isGroupable()) {
                continue;
            }

            // Suitable dimension types: picklist, reference, date, boolean
            Schema.DisplayType fieldType = dfr.getType();
            if (fieldType == Schema.DisplayType.PICKLIST ||
                fieldType == Schema.DisplayType.REFERENCE ||
                fieldType == Schema.DisplayType.DATE ||
                fieldType == Schema.DisplayType.BOOLEAN ||
                fieldType == Schema.DisplayType.STRING) {

                DimensionField dim = new DimensionField();
                dim.apiName = dfr.getName();
                dim.label = dfr.getLabel();
                dim.fieldType = String.valueOf(fieldType);
                dimensions.add(dim);
            }
        }

        return dimensions;
    }

    /**
     * Validate matrix configuration
     */
    private static void validateMatrixConfig(MatrixConfiguration cfg) {
        // Validate object
        if (String.isBlank(cfg.objectName)) {
            throw new AuraHandledException('Object name is required');
        }

        if (!ALLOWED_OBJECTS.contains(cfg.objectName)) {
            throw new AuraHandledException('Object not authorized: ' + cfg.objectName);
        }

        // Verify object access
        SObjectType sType = Schema.getGlobalDescribe().get(cfg.objectName);
        if (sType == null || !sType.getDescribe().isAccessible()) {
            throw new AuraHandledException('Access denied to object: ' + cfg.objectName);
        }

        // Validate row and column fields
        if (String.isBlank(cfg.rowField) || String.isBlank(cfg.columnField)) {
            throw new AuraHandledException('Row and column fields are required');
        }

        validateField(cfg.objectName, cfg.rowField);
        validateField(cfg.objectName, cfg.columnField);

        // Validate aggregate expression
        if (String.isBlank(cfg.aggregateExpression)) {
            throw new AuraHandledException('Aggregate expression is required');
        }

        validateAggregateExpression(cfg.aggregateExpression, cfg.objectName);

        // Validate filters if present
        if (String.isNotBlank(cfg.filters)) {
            validateFilterClause(cfg.filters, cfg.objectName);
        }
    }

    /**
     * Validate a field exists and is accessible
     */
    private static void validateField(String objectName, String fieldName) {
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

        if (!dfr.isGroupable()) {
            throw new AuraHandledException('Field not groupable: ' + fieldName);
        }
    }

    /**
     * Validate aggregate expression
     */
    private static void validateAggregateExpression(String expression, String objectName) {
        String upper = expression.toUpperCase().trim();

        // Must start with allowed aggregate function
        Boolean hasValidAggregate = false;
        for (String agg : ALLOWED_AGGREGATES) {
            if (upper.startsWith(agg + '(') || upper.startsWith(agg + ' (')) {
                hasValidAggregate = true;
                break;
            }
        }

        if (!hasValidAggregate) {
            throw new AuraHandledException('Invalid aggregate function. Allowed: ' + String.join(new List<String>(ALLOWED_AGGREGATES), ', '));
        }

        // Extract field name from aggregate
        Pattern p = Pattern.compile('(?i)\\w+\\s*\\(\\s*(\\w+)\\s*\\)');
        Matcher m = p.matcher(expression);

        if (m.find()) {
            String fieldInAggregate = m.group(1);

            // Skip validation for COUNT() without field
            if (fieldInAggregate.equalsIgnoreCase('Id') ||
                upper.startsWith('COUNT()') ||
                upper.startsWith('COUNT(ID)')) {
                return;
            }

            // Validate the field in aggregate
            SObjectType sType = Schema.getGlobalDescribe().get(objectName);
            Map<String, SObjectField> fieldMap = sType.getDescribe().fields.getMap();

            if (!fieldMap.containsKey(fieldInAggregate.toLowerCase())) {
                throw new AuraHandledException('Invalid field in aggregate: ' + fieldInAggregate);
            }

            if (!fieldMap.get(fieldInAggregate.toLowerCase()).getDescribe().isAccessible()) {
                throw new AuraHandledException('Aggregate field not accessible: ' + fieldInAggregate);
            }
        }
    }

    /**
     * Validate filter clause (basic validation)
     */
    private static void validateFilterClause(String filters, String objectName) {
        // Check for dangerous patterns
        String upper = filters.toUpperCase();

        Set<String> dangerous = new Set<String>{
            'INSERT', 'UPDATE', 'DELETE', 'UPSERT', 'MERGE',
            'DROP', 'TRUNCATE', 'ALTER', 'CREATE', 'GRANT'
        };

        for (String keyword : dangerous) {
            if (upper.contains(keyword)) {
                throw new AuraHandledException('Invalid filter keyword: ' + keyword);
            }
        }

        // Basic structure validation - should have field, operator, value pattern
        if (!filters.contains('=') && !filters.contains('>') &&
            !filters.contains('<') && !upper.contains(' IN ') &&
            !upper.contains(' LIKE ')) {
            throw new AuraHandledException('Filter must contain valid comparison operators');
        }
    }

    /**
     * Estimate group count to determine if direct query is safe
     */
    private static Integer estimateGroupCount(MatrixConfiguration cfg) {
        String rowField = sanitizeFieldName(cfg.rowField);
        String colField = sanitizeFieldName(cfg.columnField);

        String baseFilter = String.isNotBlank(cfg.filters) ?
            ' WHERE ' + cfg.filters : '';

        try {
            // Count distinct row values
            String rowCountQuery = 'SELECT COUNT_DISTINCT(' + rowField + ') distinctCount ' +
                                   'FROM ' + cfg.objectName + baseFilter +
                                   ' WITH SECURITY_ENFORCED';
            List<AggregateResult> rowResults = Database.query(rowCountQuery);
            Integer rowCount = rowResults.isEmpty() ? 0 : (Integer)rowResults[0].get('distinctCount');

            // Count distinct column values
            String colCountQuery = 'SELECT COUNT_DISTINCT(' + colField + ') distinctCount ' +
                                   'FROM ' + cfg.objectName + baseFilter +
                                   ' WITH SECURITY_ENFORCED';
            List<AggregateResult> colResults = Database.query(colCountQuery);
            Integer colCount = colResults.isEmpty() ? 0 : (Integer)colResults[0].get('distinctCount');

            return rowCount * colCount;
        } catch (Exception e) {
            // If estimation fails, assume worst case
            return MAX_GROUP_COMBINATIONS + 1;
        }
    }

    /**
     * Direct aggregate query
     */
    private static MatrixResult queryDirect(MatrixConfiguration cfg) {
        String rowField = sanitizeFieldName(cfg.rowField);
        String colField = sanitizeFieldName(cfg.columnField);
        String aggExpr = cfg.aggregateExpression;

        String soql = 'SELECT ' + rowField + ' rowDim, ' +
                                  colField + ' colDim, ' +
                                  aggExpr + ' metricValue ' +
                      'FROM ' + cfg.objectName;

        if (String.isNotBlank(cfg.filters)) {
            soql += ' WHERE ' + cfg.filters;
        }

        soql += ' GROUP BY ' + rowField + ', ' + colField +
                ' WITH SECURITY_ENFORCED' +
                ' LIMIT ' + MAX_QUERY_ROWS;

        List<AggregateResult> results;
        try {
            results = Database.query(soql);
        } catch (Exception e) {
            throw new AuraHandledException('Matrix query failed: ' + e.getMessage());
        }

        return transformToMatrix(results, cfg);
    }

    /**
     * Query from pre-aggregated summary object
     */
    private static MatrixResult queryFromSummaryObject(MatrixConfiguration cfg) {
        String summaryObjectName = cfg.objectName.replace('__c', '_Summary__c');

        // Check if summary object exists
        if (!Schema.getGlobalDescribe().containsKey(summaryObjectName)) {
            throw new AuraHandledException(
                'Data volume too large for real-time query. ' +
                'Summary object ' + summaryObjectName + ' not configured. ' +
                'Please contact your administrator.'
            );
        }

        // Query the summary object
        String soql = 'SELECT Row_Dimension__c rowDim, ' +
                             'Column_Dimension__c colDim, ' +
                             'Metric_Value__c metricValue ' +
                      'FROM ' + summaryObjectName +
                      ' WHERE Summary_Type__c = :summaryType' +
                      ' WITH SECURITY_ENFORCED' +
                      ' LIMIT ' + MAX_QUERY_ROWS;

        String summaryType = cfg.rowField + '_' + cfg.columnField;

        List<SObject> summaryRecords;
        try {
            summaryRecords = Database.query(soql);
        } catch (Exception e) {
            throw new AuraHandledException('Summary query failed: ' + e.getMessage());
        }

        return transformSummaryToMatrix(summaryRecords, cfg);
    }

    /**
     * Transform aggregate results to matrix format
     */
    private static MatrixResult transformToMatrix(List<AggregateResult> results, MatrixConfiguration cfg) {
        // Build matrix structure
        Map<String, Map<String, Decimal>> matrix = new Map<String, Map<String, Decimal>>();
        Set<String> allColumns = new Set<String>();

        Decimal total = 0;
        Decimal minValue = null;
        Decimal maxValue = null;

        for (AggregateResult ar : results) {
            String rowKey = String.valueOf(ar.get('rowDim'));
            String colKey = String.valueOf(ar.get('colDim'));
            Decimal value = ar.get('metricValue') != null ?
                (Decimal)ar.get('metricValue') : 0;

            if (rowKey == null) rowKey = '(blank)';
            if (colKey == null) colKey = '(blank)';

            if (!matrix.containsKey(rowKey)) {
                matrix.put(rowKey, new Map<String, Decimal>());
            }
            matrix.get(rowKey).put(colKey, value);
            allColumns.add(colKey);

            total += value;
            if (minValue == null || value < minValue) minValue = value;
            if (maxValue == null || value > maxValue) maxValue = value;
        }

        // Calculate benchmarks (column averages)
        Map<String, Decimal> benchmarks = calculateBenchmarks(matrix, allColumns);

        // Calculate row totals
        Map<String, Decimal> rowTotals = calculateRowTotals(matrix);

        // Build result
        MatrixResult result = new MatrixResult();
        result.matrix = matrix;
        result.columns = new List<String>(allColumns);
        result.columns.sort();
        result.rows = new List<String>(matrix.keySet());
        result.rows.sort();
        result.benchmarks = benchmarks;
        result.rowTotals = rowTotals;
        result.grandTotal = total;
        result.minValue = minValue;
        result.maxValue = maxValue;
        result.recordCount = results.size();

        return result;
    }

    /**
     * Transform summary records to matrix format
     */
    private static MatrixResult transformSummaryToMatrix(List<SObject> summaries, MatrixConfiguration cfg) {
        Map<String, Map<String, Decimal>> matrix = new Map<String, Map<String, Decimal>>();
        Set<String> allColumns = new Set<String>();

        Decimal total = 0;
        Decimal minValue = null;
        Decimal maxValue = null;

        for (SObject s : summaries) {
            String rowKey = String.valueOf(s.get('Row_Dimension__c'));
            String colKey = String.valueOf(s.get('Column_Dimension__c'));
            Decimal value = (Decimal)s.get('Metric_Value__c');

            if (rowKey == null) rowKey = '(blank)';
            if (colKey == null) colKey = '(blank)';
            if (value == null) value = 0;

            if (!matrix.containsKey(rowKey)) {
                matrix.put(rowKey, new Map<String, Decimal>());
            }
            matrix.get(rowKey).put(colKey, value);
            allColumns.add(colKey);

            total += value;
            if (minValue == null || value < minValue) minValue = value;
            if (maxValue == null || value > maxValue) maxValue = value;
        }

        Map<String, Decimal> benchmarks = calculateBenchmarks(matrix, allColumns);
        Map<String, Decimal> rowTotals = calculateRowTotals(matrix);

        MatrixResult result = new MatrixResult();
        result.matrix = matrix;
        result.columns = new List<String>(allColumns);
        result.columns.sort();
        result.rows = new List<String>(matrix.keySet());
        result.rows.sort();
        result.benchmarks = benchmarks;
        result.rowTotals = rowTotals;
        result.grandTotal = total;
        result.minValue = minValue;
        result.maxValue = maxValue;
        result.recordCount = summaries.size();

        return result;
    }

    /**
     * Calculate column benchmarks (averages)
     */
    private static Map<String, Decimal> calculateBenchmarks(
        Map<String, Map<String, Decimal>> matrix,
        Set<String> columns
    ) {
        Map<String, Decimal> sums = new Map<String, Decimal>();
        Map<String, Integer> counts = new Map<String, Integer>();

        for (String row : matrix.keySet()) {
            for (String col : matrix.get(row).keySet()) {
                Decimal val = matrix.get(row).get(col);

                if (!sums.containsKey(col)) {
                    sums.put(col, 0);
                    counts.put(col, 0);
                }

                sums.put(col, sums.get(col) + val);
                counts.put(col, counts.get(col) + 1);
            }
        }

        Map<String, Decimal> benchmarks = new Map<String, Decimal>();
        for (String col : sums.keySet()) {
            Integer count = counts.get(col);
            if (count > 0) {
                benchmarks.put(col, (sums.get(col) / count).setScale(2, RoundingMode.HALF_UP));
            } else {
                benchmarks.put(col, 0);
            }
        }

        return benchmarks;
    }

    /**
     * Calculate row totals
     */
    private static Map<String, Decimal> calculateRowTotals(Map<String, Map<String, Decimal>> matrix) {
        Map<String, Decimal> totals = new Map<String, Decimal>();

        for (String row : matrix.keySet()) {
            Decimal rowTotal = 0;
            for (Decimal val : matrix.get(row).values()) {
                rowTotal += val;
            }
            totals.put(row, rowTotal);
        }

        return totals;
    }

    /**
     * Sanitize field name
     */
    private static String sanitizeFieldName(String fieldName) {
        if (String.isBlank(fieldName)) return '';
        return fieldName.replaceAll('[^a-zA-Z0-9_]+', '');
    }

    // ==================== Inner Classes ====================

    public class MatrixConfiguration {
        public String objectName;
        public String rowField;
        public String columnField;
        public String aggregateExpression;
        public String filters;
    }

    public class MatrixResult {
        @AuraEnabled public Map<String, Map<String, Decimal>> matrix;
        @AuraEnabled public List<String> rows;
        @AuraEnabled public List<String> columns;
        @AuraEnabled public Map<String, Decimal> benchmarks;
        @AuraEnabled public Map<String, Decimal> rowTotals;
        @AuraEnabled public Decimal grandTotal;
        @AuraEnabled public Decimal minValue;
        @AuraEnabled public Decimal maxValue;
        @AuraEnabled public Integer recordCount;
        @AuraEnabled public Integer estimatedGroups;
        @AuraEnabled public Boolean usedSummaryFallback;
    }

    public class DimensionField {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String fieldType;
    }
}
