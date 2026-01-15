/**
 * @description Factory class for parsing different Shield event types
 * Provides type-specific parsing for Login, LoginAs, API, ReportExport, etc.
 * @group Shield Integration
 * @author Prometheion Team
 */
public with sharing class PrometheionEventParser {
    
    // ═══════════════════════════════════════════════════════════════
    // FACTORY METHOD
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Factory method to parse event based on type
     * @param eventType The type of event to parse
     * @param rawData The raw event data from EventLogFile
     * @return Parsed and normalized event data
     */
    public static Map<String, Object> parseEvent(String eventType, Map<String, Object> rawData) {
        if (rawData == null) {
            rawData = new Map<String, Object>();
        }
        
        Map<String, Object> parsed;
        
        switch on eventType {
            when 'Login' {
                parsed = parseLoginEvent(rawData);
            }
            when 'LoginAs' {
                parsed = parseLoginAsEvent(rawData);
            }
            when 'ReportExport' {
                parsed = parseReportExportEvent(rawData);
            }
            when 'API' {
                parsed = parseApiEvent(rawData);
            }
            when 'ContentDistribution' {
                parsed = parseContentDistributionEvent(rawData);
            }
            when 'ApexExecution' {
                parsed = parseApexExecutionEvent(rawData);
            }
            when 'PermissionSetEventLog' {
                parsed = parsePermissionSetEvent(rawData);
            }
            when else {
                // Return raw data with event type for unsupported types
                parsed = new Map<String, Object>(rawData);
                parsed.put('eventType', eventType);
            }
        }
        
        // Add common fields
        parsed.put('parsedAt', Datetime.now());
        parsed.put('riskLevel', PrometheionShieldService.getRiskLevel(eventType));
        
        return parsed;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // EVENT-SPECIFIC PARSERS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Parse Login event data
     * @param raw Raw event data
     * @return Parsed Login event
     */
    public static Map<String, Object> parseLoginEvent(Map<String, Object> raw) {
        Map<String, Object> parsed = new Map<String, Object>();
        
        parsed.put('eventType', 'Login');
        parsed.put('userId', getString(raw, 'USER_ID'));
        parsed.put('userName', getString(raw, 'USER_NAME'));
        parsed.put('sourceIp', getString(raw, 'SOURCE_IP'));
        parsed.put('loginStatus', getString(raw, 'LOGIN_STATUS'));
        parsed.put('loginType', getString(raw, 'LOGIN_TYPE'));
        parsed.put('authenticationMethod', getString(raw, 'AUTHENTICATION_METHOD_REFERENCE'));
        parsed.put('browserType', getString(raw, 'BROWSER_TYPE'));
        parsed.put('platformType', getString(raw, 'PLATFORM_TYPE'));
        parsed.put('cipherSuite', getString(raw, 'CIPHER_SUITE'));
        parsed.put('tlsProtocol', getString(raw, 'TLS_PROTOCOL'));
        parsed.put('sessionKey', getString(raw, 'SESSION_KEY'));
        parsed.put('timestamp', parseTimestamp(getString(raw, 'TIMESTAMP')));
        
        // Build geo location
        String city = getString(raw, 'CITY');
        String subdivision = getString(raw, 'SUBDIVISION');
        String country = getString(raw, 'COUNTRY');
        parsed.put('geoLocation', buildGeoLocation(city, subdivision, country));
        parsed.put('city', city);
        parsed.put('subdivision', subdivision);
        parsed.put('country', country);
        
        // Determine if login is suspicious
        parsed.put('isSuspicious', isLoginSuspicious(parsed));
        
        return parsed;
    }
    
    /**
     * @description Parse LoginAs (impersonation) event data
     * @param raw Raw event data
     * @return Parsed LoginAs event
     */
    public static Map<String, Object> parseLoginAsEvent(Map<String, Object> raw) {
        Map<String, Object> parsed = new Map<String, Object>();
        
        parsed.put('eventType', 'LoginAs');
        parsed.put('delegatedUserId', getString(raw, 'DELEGATED_USER_ID'));
        parsed.put('delegatedUserName', getString(raw, 'DELEGATED_USER_NAME'));
        parsed.put('targetUserId', getString(raw, 'USER_ID'));
        parsed.put('targetUserName', getString(raw, 'USER_NAME'));
        parsed.put('sourceIp', getString(raw, 'SOURCE_IP'));
        parsed.put('sessionKey', getString(raw, 'SESSION_KEY'));
        parsed.put('timestamp', parseTimestamp(getString(raw, 'TIMESTAMP')));
        
        // LoginAs events are always flagged as high risk
        parsed.put('isHighRisk', true);
        parsed.put('riskReason', 'User impersonation event');
        
        return parsed;
    }
    
    /**
     * @description Parse ReportExport event data
     * @param raw Raw event data
     * @return Parsed ReportExport event
     */
    public static Map<String, Object> parseReportExportEvent(Map<String, Object> raw) {
        Map<String, Object> parsed = new Map<String, Object>();
        
        parsed.put('eventType', 'ReportExport');
        parsed.put('userId', getString(raw, 'USER_ID'));
        parsed.put('reportId', getString(raw, 'REPORT_ID'));
        parsed.put('reportName', getString(raw, 'REPORT_NAME'));
        parsed.put('exportFormat', getString(raw, 'EXPORT_TYPE'));
        parsed.put('numberOfColumns', getInteger(raw, 'NUMBER_OF_COLUMNS'));
        parsed.put('rowsProcessed', getInteger(raw, 'ROWS_PROCESSED'));
        parsed.put('sourceIp', getString(raw, 'SOURCE_IP'));
        parsed.put('timestamp', parseTimestamp(getString(raw, 'TIMESTAMP')));
        
        // Flag large exports
        Integer rows = getInteger(raw, 'ROWS_PROCESSED');
        parsed.put('isLargeExport', rows > 1000);
        parsed.put('isCriticalExport', rows > 10000);
        
        return parsed;
    }
    
    /**
     * @description Parse API event data
     * @param raw Raw event data
     * @return Parsed API event
     */
    public static Map<String, Object> parseApiEvent(Map<String, Object> raw) {
        Map<String, Object> parsed = new Map<String, Object>();
        
        parsed.put('eventType', 'API');
        parsed.put('userId', getString(raw, 'USER_ID'));
        parsed.put('apiType', getString(raw, 'API_TYPE'));
        parsed.put('apiVersion', getString(raw, 'API_VERSION'));
        parsed.put('methodName', getString(raw, 'METHOD_NAME'));
        parsed.put('entityName', getString(raw, 'ENTITY_NAME'));
        parsed.put('rowsProcessed', getInteger(raw, 'ROWS_PROCESSED'));
        parsed.put('cpuTime', getInteger(raw, 'CPU_TIME'));
        parsed.put('runTime', getInteger(raw, 'RUN_TIME'));
        parsed.put('clientName', getString(raw, 'CLIENT_NAME'));
        parsed.put('sourceIp', getString(raw, 'SOURCE_IP'));
        parsed.put('timestamp', parseTimestamp(getString(raw, 'TIMESTAMP')));
        
        // Flag bulk operations
        Integer rows = getInteger(raw, 'ROWS_PROCESSED');
        parsed.put('isBulkOperation', rows > 200);
        parsed.put('isHighVolume', rows > 10000);
        
        return parsed;
    }
    
    /**
     * @description Parse ContentDistribution event data
     * @param raw Raw event data
     * @return Parsed ContentDistribution event
     */
    public static Map<String, Object> parseContentDistributionEvent(Map<String, Object> raw) {
        Map<String, Object> parsed = new Map<String, Object>();
        
        parsed.put('eventType', 'ContentDistribution');
        parsed.put('userId', getString(raw, 'USER_ID'));
        parsed.put('contentDocumentId', getString(raw, 'CONTENT_DOCUMENT_ID'));
        parsed.put('distributionType', getString(raw, 'DISTRIBUTION_TYPE'));
        parsed.put('expirationDate', getString(raw, 'EXPIRATION_DATE'));
        parsed.put('isPasswordProtected', getString(raw, 'IS_PASSWORD_PROTECTED') == 'true');
        parsed.put('sourceIp', getString(raw, 'SOURCE_IP'));
        parsed.put('timestamp', parseTimestamp(getString(raw, 'TIMESTAMP')));
        
        // Flag public distributions without password protection
        String distType = getString(raw, 'DISTRIBUTION_TYPE');
        Boolean hasPassword = getString(raw, 'IS_PASSWORD_PROTECTED') == 'true';
        parsed.put('isUnprotectedPublic', distType == 'Public' &amp;&amp; !hasPassword);
        
        return parsed;
    }
    
    /**
     * @description Parse ApexExecution event data
     * @param raw Raw event data
     * @return Parsed ApexExecution event
     */
    public static Map<String, Object> parseApexExecutionEvent(Map<String, Object> raw) {
        Map<String, Object> parsed = new Map<String, Object>();
        
        parsed.put('eventType', 'ApexExecution');
        parsed.put('userId', getString(raw, 'USER_ID'));
        parsed.put('entryPoint', getString(raw, 'ENTRY_POINT'));
        parsed.put('quiddity', getString(raw, 'QUIDDITY'));
        parsed.put('cpuTime', getInteger(raw, 'CPU_TIME'));
        parsed.put('execTime', getInteger(raw, 'EXEC_TIME'));
        parsed.put('calloutTime', getInteger(raw, 'CALLOUT_TIME'));
        parsed.put('dbTotalTime', getInteger(raw, 'DB_TOTAL_TIME'));
        parsed.put('dmlRows', getInteger(raw, 'DML_ROWS'));
        parsed.put('soqlQueries', getInteger(raw, 'SOQL_QUERIES'));
        parsed.put('success', getString(raw, 'SUCCESS') == 'true');
        parsed.put('timestamp', parseTimestamp(getString(raw, 'TIMESTAMP')));
        
        // Flag resource-intensive executions
        Integer cpuTime = getInteger(raw, 'CPU_TIME');
        Integer execTime = getInteger(raw, 'EXEC_TIME');
        parsed.put('isResourceIntensive', cpuTime > 5000 || execTime > 10000);
        
        return parsed;
    }
    
    /**
     * @description Parse PermissionSetEventLog data
     * @param raw Raw event data
     * @return Parsed PermissionSet event
     */
    public static Map<String, Object> parsePermissionSetEvent(Map<String, Object> raw) {
        Map<String, Object> parsed = new Map<String, Object>();
        
        parsed.put('eventType', 'PermissionSetEventLog');
        parsed.put('userId', getString(raw, 'USER_ID'));
        parsed.put('permissionSetId', getString(raw, 'PERMISSION_SET_ID'));
        parsed.put('operation', getString(raw, 'OPERATION'));
        parsed.put('delegateUser', getString(raw, 'DELEGATE_USER'));
        parsed.put('sourceIp', getString(raw, 'SOURCE_IP'));
        parsed.put('timestamp', parseTimestamp(getString(raw, 'TIMESTAMP')));
        
        // Flag permission assignments (potential privilege escalation)
        String operation = getString(raw, 'OPERATION');
        parsed.put('isAssignment', operation == 'PermissionSetAssignment');
        parsed.put('isPotentialEscalation', operation == 'PermissionSetAssignment');
        
        return parsed;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // UTILITY METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Safely get string value from map
     * @param data The source map
     * @param key The key to retrieve
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
     * @description Safely get integer value from map
     * @param data The source map
     * @param key The key to retrieve
     * @return Integer value or 0
     */
    private static Integer getInteger(Map<String, Object> data, String key) {
        String strVal = getString(data, key);
        if (String.isBlank(strVal)) {
            return 0;
        }
        try {
            return Integer.valueOf(strVal);
        } catch (Exception e) {
            return 0;
        }
    }
    
    /**
     * @description Parse timestamp string to Datetime
     * @param timestampStr The timestamp string
     * @return Datetime value or null
     */
    private static Datetime parseTimestamp(String timestampStr) {
        if (String.isBlank(timestampStr)) {
            return null;
        }
        try {
            // Try ISO format first
            return Datetime.valueOf(timestampStr.replace('T', ' ').substring(0, 19));
        } catch (Exception e) {
            try {
                // Try other common formats
                return Datetime.parse(timestampStr);
            } catch (Exception e2) {
                return null;
            }
        }
    }
    
    /**
     * @description Build geo location string from components
     * @param city City name
     * @param subdivision State/province
     * @param country Country name
     * @return Formatted geo location string
     */
    private static String buildGeoLocation(String city, String subdivision, String country) {
        List<String> parts = new List<String>();
        
        if (String.isNotBlank(city)) {
            parts.add(city);
        }
        if (String.isNotBlank(subdivision)) {
            parts.add(subdivision);
        }
        if (String.isNotBlank(country)) {
            parts.add(country);
        }
        
        return String.join(parts, ', ');
    }
    
    /**
     * @description Determine if a login event is suspicious
     * @param loginData Parsed login event data
     * @return True if login appears suspicious
     */
    private static Boolean isLoginSuspicious(Map<String, Object> loginData) {
        // Check for failed logins
        String status = (String)loginData.get('loginStatus');
        if (status != 'Success') {
            return true;
        }
        
        // Check for non-US locations (configurable in production)
        String country = (String)loginData.get('country');
        if (String.isNotBlank(country) &amp;&amp; country != 'United States') {
            return true;
        }
        
        // Check for weak TLS
        String tls = (String)loginData.get('tlsProtocol');
        if (String.isNotBlank(tls) &amp;&amp; (tls.contains('1.0') || tls.contains('1.1'))) {
            return true;
        }
        
        return false;
    }
    
    /**
     * @description Batch parse multiple events
     * @param eventType The event type
     * @param rawEvents List of raw event data
     * @return List of parsed events
     */
    public static List<Map<String, Object>> batchParseEvents(String eventType, List<Map<String, Object>> rawEvents) {
        List<Map<String, Object>> parsedEvents = new List<Map<String, Object>>();
        
        if (rawEvents == null || rawEvents.isEmpty()) {
            return parsedEvents;
        }
        
        for (Map<String, Object> rawEvent : rawEvents) {
            parsedEvents.add(parseEvent(eventType, rawEvent));
        }
        
        return parsedEvents;
    }
}
