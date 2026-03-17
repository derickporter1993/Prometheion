/**
 * ElaroDynamicReportController.cls
 * Secure dynamic report builder for Elaro Analytics
 *
 * Security Features:
 * - Object whitelisting
 * - Operator whitelisting
 * - Field validation against schema
 * - SOQL injection prevention
 * - WITH USER_MODE
 * - Platform Cache for metadata
 *
 * @author Derick Porter
 * @date 2026-01-03
 * @since v3.1.0 (Spring '26)
 * @group Compliance Framework
 */
public with sharing class ElaroDynamicReportController {

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
        try {
            // Validate object is allowed
            if (!ALLOWED_OBJECTS.contains(objectApiName)) {
                throw new AuraHandledException('Object not authorized: ' + objectApiName);
            }

            // Check cache first
            String cacheKey = 'fieldMeta_' + objectApiName.replaceAll('[^a-zA-Z0-9_]+', '');
            Cache.OrgPartition orgCache = null;
            try {
                orgCache = Cache.Org.getPartition('local.ElaroReportCache');
                if (orgCache != null && orgCache.contains(cacheKey)) {
                    return (List<FieldMetadata>)orgCache.get(cacheKey);
                }
            } catch (Cache.Org.OrgCacheException e) {
                // Cache not configured, continue without it
                ElaroLogger.warn( 'Cache partition not available: ' + e.getMessage());
            } catch (Exception e) {
                // Unexpected cache error - log but continue
                ElaroLogger.warn( 'Unexpected cache error: ' + e.getMessage());
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
                } catch (Cache.Org.OrgCacheException e) {
                    ElaroLogger.warn( 'Failed to cache field metadata: ' + e.getMessage());
                } catch (Exception e) {
                    ElaroLogger.warn( 'Unexpected cache error: ' + e.getMessage());
                }
            }

            return result;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('ElaroDynamicReportController.getFieldMetadata', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
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
        } catch (JSONException e) {
            ElaroLogger.error('ElaroDynamicReportController.executeReport', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to parse the report configuration. Please verify the request format and try again.');
        } catch (Exception e) {
            ElaroLogger.error('ElaroDynamicReportController.executeReport', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to parse the report configuration. Please verify the request format and try again.');
        }

        // Validate configuration security
        validateReportConfigSecurity(cfg);

        // Build and execute secure SOQL with bind variables
        QueryWithBinds qwb = buildSecureSOQL(cfg);

        List<SObject> rows;
        try {
            rows = Database.queryWithBinds(qwb.query, qwb.binds, AccessLevel.USER_MODE);
        } catch (QueryException e) {
            ElaroLogger.error('ElaroDynamicReportController.executeReport', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to execute the report query. Please verify you have the required permissions and try again.');
        }

        // Strip inaccessible fields for FLS security
        rows = ElaroSecurityUtils.stripInaccessibleFields(
            AccessType.READABLE,
            rows
        );

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
                } catch (SObjectException e) {
                    // Field not accessible or doesn't exist - set to null
                    rowData.put(safeField, null);
                } catch (Exception e) {
                    // Unexpected error accessing field - log and set to null
                    ElaroLogger.warn( 'Unexpected error accessing field ' + safeField + ': ' + e.getMessage());
                    rowData.put(safeField, null);
                }
            }
            data.add(rowData);
        }

        ReportResult result = new ReportResult();
        result.data = data;
        result.recordCount = rows.size();
        result.hasMore = rows.size() >= cfg.maxRows;
        // Removed: exposing SOQL to client creates information disclosure risk

        return result;
    }

    /**
     * Get available objects for the report builder
     */
    @AuraEnabled(cacheable=true)
    public static List<ObjectOption> getAvailableObjects() {
        try {
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
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('ElaroDynamicReportController.getAvailableObjects', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
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
     * Build secure SOQL query with bind variables
     *
     * @param cfg The report configuration containing object, fields, filters, and options
     * @return QueryWithBinds containing the parameterized query and bind map
     */
    private static QueryWithBinds buildSecureSOQL(ReportConfiguration cfg) {
        Map<String, Object> binds = new Map<String, Object>();
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

        // NOPMD ApexSOQLInjection - field names validated against schema, object validated against ALLOWED_OBJECTS allowlist, filter values use bind variables
        String soql = 'SELECT ' + String.join(selectFields, ', ') +
                      ' FROM ' + cfg.objectApiName;

        // Build WHERE clause with bind variables
        if (cfg.filters != null && !cfg.filters.isEmpty()) {
            List<String> whereParts = new List<String>();
            Integer bindIndex = 0;

            for (FilterCriteria fc : cfg.filters) {
                String field = sanitizeFieldName(fc.field);
                String op = fc.operator.toUpperCase();
                String bindKey = 'filterVal_' + bindIndex;
                bindIndex++;

                if (op == 'LIKE') {
                    binds.put(bindKey, '%' + fc.value + '%');
                    whereParts.add(field + ' LIKE :' + bindKey);
                } else if (op == 'IN' || op == 'NOT IN') {
                    List<String> vals = new List<String>();
                    for (String v : fc.value.split(',')) {
                        vals.add(v.trim());
                    }
                    binds.put(bindKey, vals);
                    whereParts.add(field + ' ' + op + ' :' + bindKey);
                } else {
                    // Handle different data types
                    if (isNumericValue(fc.value)) {
                        binds.put(bindKey, Decimal.valueOf(fc.value));
                        whereParts.add(field + ' ' + op + ' :' + bindKey);
                    } else if (fc.value.equalsIgnoreCase('true') || fc.value.equalsIgnoreCase('false')) {
                        binds.put(bindKey, Boolean.valueOf(fc.value));
                        whereParts.add(field + ' ' + op + ' :' + bindKey);
                    } else if (fc.value.equalsIgnoreCase('null')) {
                        whereParts.add(field + ' ' + op + ' null');
                    } else {
                        binds.put(bindKey, fc.value);
                        whereParts.add(field + ' ' + op + ' :' + bindKey);
                    }
                }
            }

            if (!whereParts.isEmpty()) {
                soql += ' WHERE ' + String.join(whereParts, ' AND ');
            }
        }

        // Add security enforcement
        soql += ' WITH USER_MODE';

        // Add ORDER BY if specified
        if (String.isNotBlank(cfg.orderBy)) {
            String cleanOrderBy = sanitizeFieldName(cfg.orderBy);
            String direction = cfg.orderDirection == 'DESC' ? 'DESC' : 'ASC';
            soql += ' ORDER BY ' + cleanOrderBy + ' ' + direction;
        }

        // Add LIMIT with bind variable
        binds.put('queryLimit', cfg.maxRows);
        soql += ' LIMIT :queryLimit';

        QueryWithBinds result = new QueryWithBinds();
        result.query = soql;
        result.binds = binds;
        return result;
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
        } catch (TypeException e) {
            return false;
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

    /**
     * Wrapper for a parameterized SOQL query and its bind variable map
     */
    private class QueryWithBinds {
        public String query;
        public Map<String, Object> binds;
    }
}
