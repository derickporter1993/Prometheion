/**
 * PrometheionDynamicReportController.cls
 * Secure dynamic report builder for Prometheion Analytics
 *
 * Security Features:
 * - Object whitelisting
 * - Operator whitelisting
 * - Field validation against schema
 * - SOQL injection prevention
 * - WITH SECURITY_ENFORCED
 * - Platform Cache for metadata
 *
 * @author Derick Porter
 * @date 2026-01-03
 */
public with sharing class PrometheionDynamicReportController {

    // Whitelisted objects - add objects as needed
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
        '=', '!=', '>', '<', '>=', '<=', 'LIKE', 'IN', 'NOT IN'
    };

    // Maximum rows to prevent heap issues
    private static final Integer MAX_ROWS = 10000;
    private static final Integer DEFAULT_ROWS = 1000;

    /**
     * Get field metadata for an object with caching
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldMetadata> getFieldMetadata(String objectApiName) {
        // Validate object is allowed
        if (!ALLOWED_OBJECTS.contains(objectApiName)) {
            throw new AuraHandledException('Object not authorized: ' + objectApiName);
        }

        // Check cache first
        String cacheKey = 'fieldMeta_' + objectApiName.replaceAll('[^a-zA-Z0-9_]+', '');
        Cache.OrgPartition orgCache = null;
        try {
            orgCache = Cache.Org.getPartition('local.PrometheionReportCache');
            if (orgCache != null && orgCache.contains(cacheKey)) {
                return (List<FieldMetadata>)orgCache.get(cacheKey);
            }
        } catch (Exception e) {
            // Cache not configured, continue without it
            System.debug(LoggingLevel.WARN, 'Cache partition not available: ' + e.getMessage());
        }

        // Validate object exists and is accessible
        SObjectType sobj = Schema.getGlobalDescribe().get(objectApiName);
        if (sobj == null || !sobj.getDescribe().isAccessible()) {
            throw new AuraHandledException('Access denied to object: ' + objectApiName);
        }

        // Build field metadata list
        Map<String, SObjectField> fieldMap = sobj.getDescribe().fields.getMap();
        List<FieldMetadata> result = new List<FieldMetadata>();

        for (String fieldName : fieldMap.keySet()) {
            DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();

            // Only include accessible fields
            if (!dfr.isAccessible()) {
                continue;
            }

            FieldMetadata fm = new FieldMetadata();
            fm.label = dfr.getLabel();
            fm.apiName = dfr.getName();
            fm.fieldType = String.valueOf(dfr.getType());
            fm.isFilterable = dfr.isFilterable();
            fm.isGroupable = dfr.isGroupable();
            fm.isSortable = dfr.isSortable();
            result.add(fm);
        }

        result.sort();

        // Cache the results
        if (orgCache != null) {
            try {
                orgCache.put(cacheKey, result, 86400); // 24 hour TTL
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Failed to cache field metadata: ' + e.getMessage());
            }
        }

        return result;
    }

    /**
     * Execute a dynamic report query
     */
    @AuraEnabled
    public static ReportResult executeReport(String reportConfigJson) {
        if (String.isBlank(reportConfigJson)) {
            throw new AuraHandledException('Report configuration is required');
        }

        ReportConfiguration cfg;
        try {
            cfg = (ReportConfiguration)JSON.deserialize(reportConfigJson, ReportConfiguration.class);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid report configuration format');
        }

        // Validate configuration security
        validateReportConfigSecurity(cfg);

        // Build and execute secure SOQL
        String soql = buildSecureSOQL(cfg);

        List<SObject> rows;
        try {
            rows = Database.query(soql);
        } catch (QueryException e) {
            throw new AuraHandledException('Query failed: ' + e.getMessage());
        }

        // Transform results
        List<Map<String, Object>> data = new List<Map<String, Object>>();
        for (SObject row : rows) {
            Map<String, Object> rowData = new Map<String, Object>();
            for (String field : cfg.fields) {
                String safeField = sanitizeFieldName(field);
                try {
                    // Handle relationship fields
                    if (field.contains('.')) {
                        rowData.put(field, getRelationshipValue(row, field));
                    } else {
                        rowData.put(safeField, row.get(safeField));
                    }
                } catch (Exception e) {
                    rowData.put(safeField, null);
                }
            }
            data.add(rowData);
        }

        ReportResult result = new ReportResult();
        result.data = data;
        result.recordCount = rows.size();
        result.hasMore = rows.size() >= cfg.maxRows;
        result.queryExecuted = soql;

        return result;
    }

    /**
     * Get available objects for the report builder
     */
    @AuraEnabled(cacheable=true)
    public static List<ObjectOption> getAvailableObjects() {
        List<ObjectOption> options = new List<ObjectOption>();

        for (String objName : ALLOWED_OBJECTS) {
            SObjectType sType = Schema.getGlobalDescribe().get(objName);
            if (sType != null && sType.getDescribe().isAccessible()) {
                ObjectOption opt = new ObjectOption();
                opt.label = sType.getDescribe().getLabel();
                opt.value = objName;
                options.add(opt);
            }
        }

        return options;
    }

    /**
     * Validate report configuration for security
     */
    private static void validateReportConfigSecurity(ReportConfiguration cfg) {
        // Validate object
        if (String.isBlank(cfg.objectApiName)) {
            throw new AuraHandledException('Object name is required');
        }

        if (!ALLOWED_OBJECTS.contains(cfg.objectApiName)) {
            throw new AuraHandledException('Object not authorized: ' + cfg.objectApiName);
        }

        // Verify object-level access
        SObjectType sType = Schema.getGlobalDescribe().get(cfg.objectApiName);
        if (sType == null || !sType.getDescribe().isAccessible()) {
            throw new AuraHandledException('Access denied to object: ' + cfg.objectApiName);
        }

        // Validate fields
        if (cfg.fields == null || cfg.fields.isEmpty()) {
            throw new AuraHandledException('At least one field is required');
        }

        Set<String> validFields = getValidFieldsFromSchema(cfg.objectApiName);

        for (String field : cfg.fields) {
            if (field.contains('.')) {
                // Validate relationship field
                validateRelationshipField(cfg.objectApiName, field);
            } else {
                String cleanField = sanitizeFieldName(field).toLowerCase();
                if (!validFields.contains(cleanField)) {
                    throw new AuraHandledException('Invalid or inaccessible field: ' + field);
                }
            }
        }

        // Validate filters
        if (cfg.filters != null) {
            for (FilterCriteria fc : cfg.filters) {
                // Validate operator
                if (!ALLOWED_OPERATORS.contains(fc.operator.toUpperCase())) {
                    throw new AuraHandledException('Invalid operator: ' + fc.operator);
                }

                // Validate filter field
                String cleanField = sanitizeFieldName(fc.field).toLowerCase();
                if (!validFields.contains(cleanField) && !fc.field.contains('.')) {
                    throw new AuraHandledException('Invalid filter field: ' + fc.field);
                }
            }
        }

        // Validate row limit
        if (cfg.maxRows == null || cfg.maxRows <= 0) {
            cfg.maxRows = DEFAULT_ROWS;
        }
        if (cfg.maxRows > MAX_ROWS) {
            throw new AuraHandledException('Max rows cannot exceed ' + MAX_ROWS);
        }
    }

    /**
     * Validate a relationship field path
     */
    private static void validateRelationshipField(String baseObject, String fieldPath) {
        List<String> parts = fieldPath.split('\\.');

        // Limit relationship depth
        if (parts.size() > 5) {
            throw new AuraHandledException('Relationship depth exceeds limit (max 5)');
        }

        String currentObject = baseObject;

        for (Integer i = 0; i < parts.size(); i++) {
            String part = sanitizeFieldName(parts[i]);
            SObjectType sType = Schema.getGlobalDescribe().get(currentObject);

            if (sType == null) {
                throw new AuraHandledException('Invalid object in relationship path');
            }

            Map<String, SObjectField> fields = sType.getDescribe().fields.getMap();

            if (i < parts.size() - 1) {
                // This is a relationship, find the reference field
                String relFieldName = part.endsWith('__r') ?
                    part.replace('__r', '__c') : part + 'Id';

                if (!fields.containsKey(relFieldName.toLowerCase())) {
                    // Try without Id suffix
                    relFieldName = part;
                }

                SObjectField relField = fields.get(relFieldName.toLowerCase());
                if (relField == null) {
                    throw new AuraHandledException('Invalid relationship: ' + part);
                }

                DescribeFieldResult dfr = relField.getDescribe();
                if (!dfr.isAccessible()) {
                    throw new AuraHandledException('Relationship not accessible: ' + part);
                }

                // Get the referenced object for next iteration
                List<SObjectType> refs = dfr.getReferenceTo();
                if (!refs.isEmpty()) {
                    currentObject = refs[0].getDescribe().getName();
                }
            } else {
                // This is the final field
                if (!fields.containsKey(part.toLowerCase())) {
                    throw new AuraHandledException('Invalid field in relationship: ' + part);
                }
                if (!fields.get(part.toLowerCase()).getDescribe().isAccessible()) {
                    throw new AuraHandledException('Field not accessible: ' + part);
                }
            }
        }
    }

    /**
     * Build secure SOQL query
     */
    private static String buildSecureSOQL(ReportConfiguration cfg) {
        List<String> selectFields = new List<String>();

        for (String field : cfg.fields) {
            if (field.contains('.')) {
                // Relationship field - sanitize each part
                List<String> parts = field.split('\\.');
                List<String> cleanParts = new List<String>();
                for (String part : parts) {
                    cleanParts.add(sanitizeFieldName(part));
                }
                selectFields.add(String.join(cleanParts, '.'));
            } else {
                selectFields.add(sanitizeFieldName(field));
            }
        }

        String soql = 'SELECT ' + String.join(selectFields, ', ') +
                      ' FROM ' + cfg.objectApiName;

        // Build WHERE clause
        if (cfg.filters != null && !cfg.filters.isEmpty()) {
            List<String> whereParts = new List<String>();

            for (FilterCriteria fc : cfg.filters) {
                String field = sanitizeFieldName(fc.field);
                String op = fc.operator.toUpperCase();
                String val = String.escapeSingleQuotes(fc.value);

                if (op == 'LIKE') {
                    whereParts.add(field + ' LIKE \'%' + val + '%\'');
                } else if (op == 'IN' || op == 'NOT IN') {
                    List<String> vals = new List<String>();
                    for (String v : fc.value.split(',')) {
                        vals.add('\'' + String.escapeSingleQuotes(v.trim()) + '\'');
                    }
                    whereParts.add(field + ' ' + op + ' (' + String.join(vals, ', ') + ')');
                } else {
                    // Handle different data types
                    if (isNumericValue(fc.value)) {
                        whereParts.add(field + ' ' + op + ' ' + fc.value);
                    } else if (fc.value.equalsIgnoreCase('true') || fc.value.equalsIgnoreCase('false')) {
                        whereParts.add(field + ' ' + op + ' ' + fc.value.toLowerCase());
                    } else if (fc.value.equalsIgnoreCase('null')) {
                        whereParts.add(field + ' ' + op + ' null');
                    } else {
                        whereParts.add(field + ' ' + op + ' \'' + val + '\'');
                    }
                }
            }

            if (!whereParts.isEmpty()) {
                soql += ' WHERE ' + String.join(whereParts, ' AND ');
            }
        }

        // Add security enforcement
        soql += ' WITH SECURITY_ENFORCED';

        // Add ORDER BY if specified
        if (String.isNotBlank(cfg.orderBy)) {
            String cleanOrderBy = sanitizeFieldName(cfg.orderBy);
            String direction = cfg.orderDirection == 'DESC' ? 'DESC' : 'ASC';
            soql += ' ORDER BY ' + cleanOrderBy + ' ' + direction;
        }

        // Add LIMIT
        soql += ' LIMIT ' + cfg.maxRows;

        return soql;
    }

    /**
     * Get valid accessible fields from schema
     */
    private static Set<String> getValidFieldsFromSchema(String objectApiName) {
        Set<String> validFields = new Set<String>();

        SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
        if (sType == null) {
            return validFields;
        }

        Map<String, SObjectField> fieldMap = sType.getDescribe().fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            if (fieldMap.get(fieldName).getDescribe().isAccessible()) {
                validFields.add(fieldName.toLowerCase());
            }
        }

        return validFields;
    }

    /**
     * Sanitize field name to prevent injection
     */
    private static String sanitizeFieldName(String fieldName) {
        if (String.isBlank(fieldName)) {
            return '';
        }
        // Allow only alphanumeric, underscore (no dots here - handle separately)
        return fieldName.replaceAll('[^a-zA-Z0-9_]+', '');
    }

    /**
     * Check if value is numeric
     */
    private static Boolean isNumericValue(String value) {
        if (String.isBlank(value)) {
            return false;
        }
        try {
            Decimal.valueOf(value);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Get value from relationship field path
     */
    private static Object getRelationshipValue(SObject record, String fieldPath) {
        List<String> parts = fieldPath.split('\\.');
        SObject current = record;

        for (Integer i = 0; i < parts.size() - 1; i++) {
            if (current == null) {
                return null;
            }
            current = current.getSObject(parts[i]);
        }

        if (current == null) {
            return null;
        }

        return current.get(parts[parts.size() - 1]);
    }

    // ==================== Inner Classes ====================

    public class FieldMetadata implements Comparable {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        @AuraEnabled public String fieldType;
        @AuraEnabled public Boolean isFilterable;
        @AuraEnabled public Boolean isGroupable;
        @AuraEnabled public Boolean isSortable;

        public Integer compareTo(Object compareTo) {
            FieldMetadata other = (FieldMetadata)compareTo;
            return this.label.compareTo(other.label);
        }
    }

    public class ReportConfiguration {
        public String objectApiName;
        public List<String> fields;
        public List<FilterCriteria> filters;
        public Integer maxRows;
        public String orderBy;
        public String orderDirection;
    }

    public class FilterCriteria {
        public String field;
        public String operator;
        public String value;
    }

    public class ReportResult {
        @AuraEnabled public List<Map<String, Object>> data;
        @AuraEnabled public Integer recordCount;
        @AuraEnabled public Boolean hasMore;
        @AuraEnabled public String queryExecuted;
    }

    public class ObjectOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
}
