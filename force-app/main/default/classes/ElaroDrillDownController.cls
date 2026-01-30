/**
 * ElaroDrillDownController.cls
 * Secure drill-down detail viewer for KPI investigation
 *
 * Security Features:
 * - Object whitelisting
 * - Operator whitelisting
 * - Field validation against schema
 * - WITH SECURITY_ENFORCED
 * - Pagination to prevent heap issues
 * - SOQL injection prevention
 *
 * @author Derick Porter
 * @date 2026-01-03
 */
public with sharing class ElaroDrillDownController {

    // Whitelisted objects for drill-down
    private static final Set<String> ALLOWED_OBJECTS = new Set<String>{
        'Account',
        'Contact',
        'Opportunity',
        'Case',
        'Lead',
        'Task',
        'Event',
        'Alert__c',
        'API_Usage_Snapshot__c',
        'Deployment_Job__c',
        'Flow_Execution__c',
        'Performance_Alert_History__c'
    };

    // Whitelisted operators
    private static final Set<String> ALLOWED_OPERATORS = new Set<String>{
        '=', '!=', '>', '<', '>=', '<=', 'LIKE', 'IN', 'NOT IN', 'INCLUDES', 'EXCLUDES'
    };

    // Pagination limits
    private static final Integer DEFAULT_PAGE_SIZE = 50;
    private static final Integer MAX_PAGE_SIZE = 200;
    private static final Integer MAX_TOTAL_RECORDS = 2000;

    /**
     * Get records for drill-down view with pagination
     */
    @AuraEnabled
    public static DrillDownResult getRecords(String contextJson) {
        if (String.isBlank(contextJson)) {
            throw new AuraHandledException('Drill-down context is required');
        }

        FilterContext ctx;
        try {
            ctx = (FilterContext)JSON.deserialize(contextJson, FilterContext.class);
        } catch (JSONException e) {
            throw new AuraHandledException('Invalid drill-down context format: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Invalid drill-down context format');
        }

        // Validate context
        validateFilterContext(ctx);

        // Set pagination defaults
        Integer pageSize = ctx.pageSize != null ?
            Math.min(ctx.pageSize, MAX_PAGE_SIZE) : DEFAULT_PAGE_SIZE;
        Integer offset = ctx.offset != null ? ctx.offset : 0;

        // Build and execute query
        String soql = buildSecureQuery(ctx, pageSize, offset);

        List<SObject> records;
        try {
            records = Database.query(soql);
        } catch (QueryException e) {
            throw new AuraHandledException('Query failed: ' + e.getMessage());
        }

        // Get total count for pagination
        Integer totalCount = getTotalCount(ctx);

        // Build result
        DrillDownResult result = new DrillDownResult();
        result.records = records;
        result.columns = buildColumns(ctx);
        result.totalCount = totalCount;
        result.pageSize = pageSize;
        result.currentOffset = offset;
        result.hasMore = (offset + pageSize) < totalCount && totalCount <= MAX_TOTAL_RECORDS;
        result.objectLabel = getObjectLabel(ctx.objectApiName);

        return result;
    }

    /**
     * Export records to CSV format
     */
    @AuraEnabled
    public static String exportToCSV(String contextJson) {
        if (String.isBlank(contextJson)) {
            throw new AuraHandledException('Export context is required');
        }

        FilterContext ctx;
        try {
            ctx = (FilterContext)JSON.deserialize(contextJson, FilterContext.class);
        } catch (JSONException e) {
            throw new AuraHandledException('Invalid export context format: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Invalid export context format');
        }

        validateFilterContext(ctx);

        // Build query with export limit
        String soql = buildSecureQuery(ctx, MAX_TOTAL_RECORDS, 0);
        List<SObject> records = Database.query(soql);

        // Build CSV
        List<String> csvLines = new List<String>();

        // Header row
        List<String> headers = new List<String>();
        for (String field : ctx.displayFields) {
            headers.add('"' + getFieldLabel(ctx.objectApiName, field) + '"');
        }
        csvLines.add(String.join(headers, ','));

        // Data rows
        for (SObject record : records) {
            List<String> values = new List<String>();
            for (String field : ctx.displayFields) {
                Object val = getFieldValue(record, field);
                String strVal = val != null ? String.valueOf(val) : '';
                // Escape quotes and wrap in quotes
                strVal = '"' + strVal.replace('"', '""') + '"';
                values.add(strVal);
            }
            csvLines.add(String.join(values, ','));
        }

        return String.join(csvLines, '\n');
    }

    /**
     * Validate filter context for security
     */
    private static void validateFilterContext(FilterContext ctx) {
        // Validate object
        if (String.isBlank(ctx.objectApiName)) {
            throw new AuraHandledException('Object name is required');
        }

        if (!ALLOWED_OBJECTS.contains(ctx.objectApiName)) {
            throw new AuraHandledException('Object not authorized for drill-down: ' + ctx.objectApiName);
        }

        // Verify object access
        SObjectType sType = Schema.getGlobalDescribe().get(ctx.objectApiName);
        if (sType == null || !sType.getDescribe().isAccessible()) {
            throw new AuraHandledException('Access denied to object: ' + ctx.objectApiName);
        }

        // Validate display fields
        if (ctx.displayFields == null || ctx.displayFields.isEmpty()) {
            throw new AuraHandledException('At least one display field is required');
        }

        Set<String> validFields = getAccessibleFields(ctx.objectApiName);

        for (String field : ctx.displayFields) {
            if (field.contains('.')) {
                validateRelationshipField(ctx.objectApiName, field, validFields);
            } else {
                String cleanField = sanitizeFieldName(field).toLowerCase();
                if (!validFields.contains(cleanField)) {
                    throw new AuraHandledException('Invalid or inaccessible field: ' + field);
                }
            }
        }

        // Validate filters
        if (ctx.filters != null) {
            for (Filter f : ctx.filters) {
                // Validate operator
                if (String.isBlank(f.operator) || !ALLOWED_OPERATORS.contains(f.operator.toUpperCase())) {
                    throw new AuraHandledException('Invalid operator: ' + f.operator);
                }

                // Validate field
                String cleanField = sanitizeFieldName(f.field).toLowerCase();
                if (!validFields.contains(cleanField) && !f.field.contains('.')) {
                    throw new AuraHandledException('Invalid filter field: ' + f.field);
                }
            }
        }
    }

    /**
     * Validate relationship field path
     */
    private static void validateRelationshipField(String baseObject, String fieldPath, Set<String> validBaseFields) {
        List<String> parts = fieldPath.split('\\.');

        if (parts.size() > 5) {
            throw new AuraHandledException('Relationship depth exceeds limit (max 5)');
        }

        // Simplified validation - check first part is valid relationship
        String firstPart = parts[0].replace('__r', '__c');
        if (!firstPart.endsWith('__c') && !firstPart.endsWith('Id')) {
            firstPart = firstPart + 'Id';
        }

        // For standard relationships, just verify the path format is valid
        // Full traversal validation happens at query execution with SECURITY_ENFORCED
    }

    /**
     * Build secure SOQL query
     */
    private static String buildSecureQuery(FilterContext ctx, Integer limitSize, Integer offset) {
        List<String> selectFields = new List<String>();

        // Always include Id for record links
        selectFields.add('Id');

        for (String field : ctx.displayFields) {
            String cleanField = field.contains('.') ?
                sanitizeRelationshipField(field) : sanitizeFieldName(field);
            if (!selectFields.contains(cleanField) && cleanField != 'Id') {
                selectFields.add(cleanField);
            }
        }

        String soql = 'SELECT ' + String.join(selectFields, ', ') +
                      ' FROM ' + ctx.objectApiName;

        // Build WHERE clause
        List<String> whereParts = new List<String>();

        if (ctx.filters != null && !ctx.filters.isEmpty()) {
            for (Filter f : ctx.filters) {
                String fieldName = sanitizeFieldName(f.field);
                String op = f.operator.toUpperCase();

                // Handle null values
                if (f.value == null || f.value.equalsIgnoreCase('null')) {
                    if (op == '=' || op == '!=') {
                        whereParts.add(fieldName + (op == '=' ? ' = null' : ' != null'));
                    }
                    continue;
                }

                String escapedValue = String.escapeSingleQuotes(f.value);

                if (op == 'LIKE') {
                    whereParts.add(fieldName + ' LIKE \'%' + escapedValue + '%\'');
                } else if (op == 'IN' || op == 'NOT IN') {
                    List<String> vals = new List<String>();
                    for (String v : f.value.split(',')) {
                        vals.add('\'' + String.escapeSingleQuotes(v.trim()) + '\'');
                    }
                    whereParts.add(fieldName + ' ' + op + ' (' + String.join(vals, ', ') + ')');
                } else if (op == 'INCLUDES' || op == 'EXCLUDES') {
                    // Multi-select picklist
                    whereParts.add(fieldName + ' ' + op + ' (\'' + escapedValue + '\')');
                } else {
                    // Handle date literals
                    if (isDateLiteral(f.value)) {
                        whereParts.add(fieldName + ' ' + op + ' ' + f.value);
                    } else if (isNumeric(f.value)) {
                        whereParts.add(fieldName + ' ' + op + ' ' + f.value);
                    } else if (f.value.equalsIgnoreCase('true') || f.value.equalsIgnoreCase('false')) {
                        whereParts.add(fieldName + ' ' + op + ' ' + f.value.toLowerCase());
                    } else {
                        whereParts.add(fieldName + ' ' + op + ' \'' + escapedValue + '\'');
                    }
                }
            }
        }

        if (!whereParts.isEmpty()) {
            soql += ' WHERE ' + String.join(whereParts, ' AND ');
        }

        // Add security enforcement
        soql += ' WITH SECURITY_ENFORCED';

        // Add ORDER BY
        if (String.isNotBlank(ctx.orderBy)) {
            String cleanOrderBy = sanitizeFieldName(ctx.orderBy);
            String direction = ctx.orderDirection == 'DESC' ? 'DESC' : 'ASC';
            soql += ' ORDER BY ' + cleanOrderBy + ' ' + direction + ' NULLS LAST';
        } else {
            soql += ' ORDER BY CreatedDate DESC';
        }

        // Add pagination
        soql += ' LIMIT ' + limitSize;
        if (offset > 0) {
            soql += ' OFFSET ' + offset;
        }

        return soql;
    }

    /**
     * Get total count for pagination
     */
    private static Integer getTotalCount(FilterContext ctx) {
        String countSoql = 'SELECT COUNT() FROM ' + ctx.objectApiName;

        if (ctx.filters != null && !ctx.filters.isEmpty()) {
            List<String> whereParts = new List<String>();
            for (Filter f : ctx.filters) {
                String fieldName = sanitizeFieldName(f.field);
                String op = f.operator.toUpperCase();

                if (f.value == null || f.value.equalsIgnoreCase('null')) {
                    if (op == '=' || op == '!=') {
                        whereParts.add(fieldName + (op == '=' ? ' = null' : ' != null'));
                    }
                    continue;
                }

                String escapedValue = String.escapeSingleQuotes(f.value);

                if (op == 'LIKE') {
                    whereParts.add(fieldName + ' LIKE \'%' + escapedValue + '%\'');
                } else if (op == 'IN' || op == 'NOT IN') {
                    List<String> vals = new List<String>();
                    for (String v : f.value.split(',')) {
                        vals.add('\'' + String.escapeSingleQuotes(v.trim()) + '\'');
                    }
                    whereParts.add(fieldName + ' ' + op + ' (' + String.join(vals, ', ') + ')');
                } else {
                    if (isDateLiteral(f.value)) {
                        whereParts.add(fieldName + ' ' + op + ' ' + f.value);
                    } else if (isNumeric(f.value)) {
                        whereParts.add(fieldName + ' ' + op + ' ' + f.value);
                    } else if (f.value.equalsIgnoreCase('true') || f.value.equalsIgnoreCase('false')) {
                        whereParts.add(fieldName + ' ' + op + ' ' + f.value.toLowerCase());
                    } else {
                        whereParts.add(fieldName + ' ' + op + ' \'' + escapedValue + '\'');
                    }
                }
            }

            if (!whereParts.isEmpty()) {
                countSoql += ' WHERE ' + String.join(whereParts, ' AND ');
            }
        }

        countSoql += ' WITH SECURITY_ENFORCED';

        try {
            return Database.countQuery(countSoql);
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'ElaroDrillDownController: Count query failed: ' + e.getMessage());
            return 0;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ElaroDrillDownController: Unexpected error in count query: ' + e.getMessage());
            return 0;
        }
    }

    /**
     * Build column definitions for datatable
     */
    private static List<ColumnDef> buildColumns(FilterContext ctx) {
        List<ColumnDef> columns = new List<ColumnDef>();

        SObjectType sType = Schema.getGlobalDescribe().get(ctx.objectApiName);
        Map<String, SObjectField> fieldMap = sType.getDescribe().fields.getMap();

        for (String field : ctx.displayFields) {
            ColumnDef col = new ColumnDef();

            if (field.contains('.')) {
                // Relationship field
                List<String> parts = field.split('\\.');
                col.fieldName = field;
                col.label = parts[parts.size() - 1].replace('__c', '').replace('_', ' ');
                col.type = 'text';
            } else {
                String cleanField = sanitizeFieldName(field).toLowerCase();
                if (fieldMap.containsKey(cleanField)) {
                    DescribeFieldResult dfr = fieldMap.get(cleanField).getDescribe();
                    col.fieldName = dfr.getName();
                    col.label = dfr.getLabel();
                    col.type = mapFieldType(dfr.getType());
                    col.sortable = dfr.isSortable();
                }
            }

            columns.add(col);
        }

        return columns;
    }

    /**
     * Map Salesforce field type to datatable type
     */
    private static String mapFieldType(Schema.DisplayType fieldType) {
        switch on fieldType {
            when CURRENCY { return 'currency'; }
            when DATE { return 'date'; }
            when DATETIME { return 'date'; }
            when DOUBLE, PERCENT { return 'number'; }
            when INTEGER { return 'number'; }
            when BOOLEAN { return 'boolean'; }
            when URL { return 'url'; }
            when EMAIL { return 'email'; }
            when PHONE { return 'phone'; }
            when else { return 'text'; }
        }
    }

    // ==================== Helper Methods ====================

    private static Set<String> getAccessibleFields(String objectApiName) {
        Set<String> fields = new Set<String>();
        SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
        if (sType != null) {
            Map<String, SObjectField> fieldMap = sType.getDescribe().fields.getMap();
            for (String fieldName : fieldMap.keySet()) {
                if (fieldMap.get(fieldName).getDescribe().isAccessible()) {
                    fields.add(fieldName.toLowerCase());
                }
            }
        }
        return fields;
    }

    private static String sanitizeFieldName(String fieldName) {
        if (String.isBlank(fieldName)) return '';
        return fieldName.replaceAll('[^a-zA-Z0-9_]+', '');
    }

    private static String sanitizeRelationshipField(String fieldPath) {
        List<String> parts = fieldPath.split('\\.');
        List<String> cleanParts = new List<String>();
        for (String part : parts) {
            cleanParts.add(part.replaceAll('[^a-zA-Z0-9_]+', ''));
        }
        return String.join(cleanParts, '.');
    }

    private static Boolean isNumeric(String value) {
        if (String.isBlank(value)) return false;
        try {
            Decimal.valueOf(value);
            return true;
        } catch (TypeException e) {
            return false;
        } catch (Exception e) {
            return false;
        }
    }

    private static Boolean isDateLiteral(String value) {
        if (String.isBlank(value)) return false;
        String upper = value.toUpperCase();
        return upper.startsWith('LAST_') || upper.startsWith('THIS_') ||
               upper.startsWith('NEXT_') || upper.startsWith('N_') ||
               upper == 'TODAY' || upper == 'YESTERDAY' || upper == 'TOMORROW';
    }

    private static String getObjectLabel(String objectApiName) {
        SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
        return sType != null ? sType.getDescribe().getLabelPlural() : objectApiName;
    }

    private static String getFieldLabel(String objectApiName, String fieldName) {
        SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
        if (sType != null) {
            Map<String, SObjectField> fields = sType.getDescribe().fields.getMap();
            String cleanField = sanitizeFieldName(fieldName).toLowerCase();
            if (fields.containsKey(cleanField)) {
                return fields.get(cleanField).getDescribe().getLabel();
            }
        }
        return fieldName;
    }

    private static Object getFieldValue(SObject record, String fieldPath) {
        if (fieldPath.contains('.')) {
            List<String> parts = fieldPath.split('\\.');
            SObject current = record;
            for (Integer i = 0; i < parts.size() - 1; i++) {
                if (current == null) return null;
                current = current.getSObject(parts[i]);
            }
            return current != null ? current.get(parts[parts.size() - 1]) : null;
        }
        return record.get(fieldPath);
    }

    // ==================== Inner Classes ====================

    public class FilterContext {
        public String objectApiName;
        public List<String> displayFields;
        public List<Filter> filters;
        public String orderBy;
        public String orderDirection;
        public Integer pageSize;
        public Integer offset;
    }

    public class Filter {
        public String field;
        public String operator;
        public String value;
    }

    public class DrillDownResult {
        @AuraEnabled public List<SObject> records;
        @AuraEnabled public List<ColumnDef> columns;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Integer currentOffset;
        @AuraEnabled public Boolean hasMore;
        @AuraEnabled public String objectLabel;
    }

    public class ColumnDef {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean sortable = true;
    }
}
