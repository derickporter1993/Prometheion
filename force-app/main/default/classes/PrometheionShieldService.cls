/**
 * @description Shield Event Monitoring API integration service
 * Provides methods to query, parse, and process Shield EventLogFile data
 * @group Shield Integration
 * @author Prometheion Team
 */
public with sharing class PrometheionShieldService {
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════
    
    // Supported event types with their risk levels
    private static final Map&lt;String, String&gt; EVENT_RISK_LEVELS = new Map&lt;String, String&gt;{
        'LoginAs' =&gt; 'CRITICAL',
        'ReportExport' =&gt; 'CRITICAL',
        'ContentDistribution' =&gt; 'CRITICAL',
        'BulkApiResult' =&gt; 'HIGH',
        'API' =&gt; 'HIGH',
        'PermissionSetEventLog' =&gt; 'HIGH',
        'Login' =&gt; 'MEDIUM',
        'Report' =&gt; 'MEDIUM',
        'ApexExecution' =&gt; 'MEDIUM',
        'FlowExecution' =&gt; 'MEDIUM',
        'Logout' =&gt; 'LOW',
        'URI' =&gt; 'LOW',
        'LightningInteraction' =&gt; 'LOW',
        'LightningPageView' =&gt; 'LOW'
    };
    
    // Valid event types for querying
    private static final Set&lt;String&gt; VALID_EVENT_TYPES = EVENT_RISK_LEVELS.keySet();
    
    // ═══════════════════════════════════════════════════════════════
    // PUBLIC METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Query EventLogFile objects for specific event types
     * @param eventType The type of event to query (e.g., 'Login', 'LoginAs')
     * @param startDate Start date for the query range
     * @param endDate End date for the query range
     * @return List of EventLogFile records
     * @throws AuraHandledException if event type is invalid or query fails
     */
    @AuraEnabled(cacheable=true)
    public static List&lt;EventLogFile&gt; getEventLogFiles(String eventType, Date startDate, Date endDate) {
        // Validate event type
        if (!VALID_EVENT_TYPES.contains(eventType)) {
            throw new AuraHandledException('Invalid event type: ' + eventType + 
                '. Valid types are: ' + String.join(new List&lt;String&gt;(VALID_EVENT_TYPES), ', '));
        }
        
        // Validate date range
        if (startDate == null || endDate == null) {
            throw new AuraHandledException('Start date and end date are required');
        }
        
        if (startDate &gt; endDate) {
            throw new AuraHandledException('Start date must be before end date');
        }
        
        try {
            // Query EventLogFile with CRUD/FLS check
            if (!Schema.sObjectType.EventLogFile.isAccessible()) {
                throw new AuraHandledException('Insufficient permissions to access EventLogFile. Shield Event Monitoring license may be required.');
            }
            
            return [
                SELECT Id, EventType, LogDate, LogFileLength, LogFile, Interval, Sequence, CreatedDate
                FROM EventLogFile
                WHERE EventType = :eventType
                AND LogDate &gt;= :startDate
                AND LogDate &lt;= :endDate
                ORDER BY LogDate DESC
                LIMIT 1000
            ];
        } catch (QueryException e) {
            throw new AuraHandledException('Error querying EventLogFile: ' + e.getMessage());
        }
    }
    
    /**
     * @description Parse EventLogFile CSV content into structured data
     * @param logFileId The ID of the EventLogFile record
     * @return List of parsed event records as maps
     * @throws AuraHandledException if parsing fails
     */
    @AuraEnabled
    public static List&lt;Map&lt;String, Object&gt;&gt; parseEventLogContent(String logFileId) {
        if (String.isBlank(logFileId)) {
            throw new AuraHandledException('Log file ID is required');
        }
        
        try {
            // Query the EventLogFile
            EventLogFile logFile = [
                SELECT Id, EventType, LogFile, LogFileLength
                FROM EventLogFile
                WHERE Id = :logFileId
                LIMIT 1
            ];
            
            // Decode and parse the CSV content
            String csvContent = logFile.LogFile.toString();
            return parseCSVContent(csvContent);
            
        } catch (QueryException e) {
            throw new AuraHandledException('EventLogFile not found: ' + logFileId);
        } catch (Exception e) {
            throw new AuraHandledException('Error parsing EventLogFile: ' + e.getMessage());
        }
    }
    
    /**
     * @description Batch process historical EventLogFiles
     * @param eventType The event type to process
     * @param startDate Start date for processing
     * @param endDate End date for processing
     * @return Batch job ID
     * @throws AuraHandledException if batch cannot be started
     */
    @AuraEnabled
    public static Id processHistoricalEvents(String eventType, Date startDate, Date endDate) {
        // Validate event type
        if (!VALID_EVENT_TYPES.contains(eventType)) {
            throw new AuraHandledException('Invalid event type: ' + eventType);
        }
        
        try {
            PrometheionHistoricalEventBatch batch = new PrometheionHistoricalEventBatch(
                eventType, startDate, endDate
            );
            return Database.executeBatch(batch, 10);
        } catch (Exception e) {
            throw new AuraHandledException('Error starting batch process: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get available event types in the org
     * @return List of available event type names
     */
    @AuraEnabled(cacheable=true)
    public static List&lt;String&gt; getAvailableEventTypes() {
        Set&lt;String&gt; availableTypes = new Set&lt;String&gt;();
        
        try {
            // Query distinct event types from EventLogFile
            if (Schema.sObjectType.EventLogFile.isAccessible()) {
                for (AggregateResult ar : [
                    SELECT EventType
                    FROM EventLogFile
                    WHERE LogDate = LAST_N_DAYS:30
                    GROUP BY EventType
                    LIMIT 50
                ]) {
                    String eventType = (String)ar.get('EventType');
                    if (VALID_EVENT_TYPES.contains(eventType)) {
                        availableTypes.add(eventType);
                    }
                }
            }
        } catch (Exception e) {
            // Return empty list if Shield is not available
            System.debug(LoggingLevel.WARN, 'Unable to query EventLogFile: ' + e.getMessage());
        }
        
        return new List&lt;String&gt;(availableTypes);
    }
    
    /**
     * @description Check Shield license status and features
     * @return Map containing Shield feature availability
     */
    @AuraEnabled(cacheable=true)
    public static Map&lt;String, Object&gt; getShieldStatus() {
        Map&lt;String, Object&gt; status = new Map&lt;String, Object&gt;{
            'shieldEnabled' =&gt; false,
            'eventMonitoring' =&gt; false,
            'platformEncryption' =&gt; false,
            'fieldAuditTrail' =&gt; false,
            'availableEventTypes' =&gt; new List&lt;String&gt;()
        };
        
        try {
            // Check if EventLogFile is accessible (indicates Event Monitoring)
            status.put('eventMonitoring', Schema.sObjectType.EventLogFile.isAccessible());
            
            // If event monitoring is available, Shield is enabled
            if ((Boolean)status.get('eventMonitoring')) {
                status.put('shieldEnabled', true);
                status.put('availableEventTypes', getAvailableEventTypes());
            }
            
            // Check for Platform Encryption (TenantSecret object)
            try {
                Integer tenantSecretCount = Database.countQuery(
                    'SELECT COUNT() FROM TenantSecret WHERE Status = \'Active\''
                );
                status.put('platformEncryption', tenantSecretCount &gt; 0);
            } catch (Exception e) {
                status.put('platformEncryption', false);
            }
            
            // Check for Field Audit Trail
            status.put('fieldAuditTrail', Schema.sObjectType.FieldHistoryArchive.isAccessible());
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error checking Shield status: ' + e.getMessage());
        }
        
        return status;
    }
    
    /**
     * @description Get risk level for an event type
     * @param eventType The event type to check
     * @return Risk level (CRITICAL, HIGH, MEDIUM, LOW)
     */
    public static String getRiskLevel(String eventType) {
        return EVENT_RISK_LEVELS.containsKey(eventType) 
            ? EVENT_RISK_LEVELS.get(eventType) 
            : 'LOW';
    }
    
    /**
     * @description Get all supported event types with their risk levels
     * @return Map of event type to risk level
     */
    @AuraEnabled(cacheable=true)
    public static Map&lt;String, String&gt; getEventRiskLevels() {
        return EVENT_RISK_LEVELS;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE HELPER METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Parse CSV content into list of maps
     * @param csvContent The CSV string to parse
     * @return List of maps representing each row
     */
    private static List&lt;Map&lt;String, Object&gt;&gt; parseCSVContent(String csvContent) {
        List&lt;Map&lt;String, Object&gt;&gt; results = new List&lt;Map&lt;String, Object&gt;&gt;();
        
        if (String.isBlank(csvContent)) {
            return results;
        }
        
        // Split into lines
        List&lt;String&gt; lines = csvContent.split('\n');
        
        if (lines.size() &lt; 2) {
            return results; // No data rows
        }
        
        // Parse header row
        List&lt;String&gt; headers = parseCSVLine(lines[0]);
        
        // Parse data rows
        for (Integer i = 1; i &lt; lines.size(); i++) {
            String line = lines[i].trim();
            if (String.isBlank(line)) {
                continue;
            }
            
            List&lt;String&gt; values = parseCSVLine(line);
            Map&lt;String, Object&gt; row = new Map&lt;String, Object&gt;();
            
            for (Integer j = 0; j &lt; headers.size() &amp;&amp; j &lt; values.size(); j++) {
                row.put(headers[j], values[j]);
            }
            
            results.add(row);
        }
        
        return results;
    }
    
    /**
     * @description Parse a single CSV line handling quoted fields
     * @param line The CSV line to parse
     * @return List of field values
     */
    private static List&lt;String&gt; parseCSVLine(String line) {
        List&lt;String&gt; fields = new List&lt;String&gt;();
        
        if (String.isBlank(line)) {
            return fields;
        }
        
        Boolean inQuotes = false;
        String currentField = '';
        
        for (Integer i = 0; i &lt; line.length(); i++) {
            String c = line.substring(i, i + 1);
            
            if (c == '"') {
                // Check for escaped quote
                if (i + 1 &lt; line.length() &amp;&amp; line.substring(i + 1, i + 2) == '"') {
                    currentField += '"';
                    i++; // Skip next quote
                } else {
                    inQuotes = !inQuotes;
                }
            } else if (c == ',' &amp;&amp; !inQuotes) {
                fields.add(currentField.trim());
                currentField = '';
            } else {
                currentField += c;
            }
        }
        
        // Add last field
        fields.add(currentField.trim());
        
        return fields;
    }
}
