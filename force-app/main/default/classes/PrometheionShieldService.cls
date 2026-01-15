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
    private static final Map<String, String> EVENT_RISK_LEVELS = new Map<String, String>{
        'LoginAs' => 'CRITICAL',
        'ReportExport' => 'CRITICAL',
        'ContentDistribution' => 'CRITICAL',
        'BulkApiResult' => 'HIGH',
        'API' => 'HIGH',
        'PermissionSetEventLog' => 'HIGH',
        'Login' => 'MEDIUM',
        'Report' => 'MEDIUM',
        'ApexExecution' => 'MEDIUM',
        'FlowExecution' => 'MEDIUM',
        'Logout' => 'LOW',
        'URI' => 'LOW',
        'LightningInteraction' => 'LOW',
        'LightningPageView' => 'LOW'
    };
    
    // Valid event types for querying
    private static final Set<String> VALID_EVENT_TYPES = EVENT_RISK_LEVELS.keySet();
    
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
    public static List<EventLogFile> getEventLogFiles(String eventType, Date startDate, Date endDate) {
        // Validate event type
        if (!VALID_EVENT_TYPES.contains(eventType)) {
            throw new AuraHandledException('Invalid event type: ' + eventType + 
                '. Valid types are: ' + String.join(new List<String>(VALID_EVENT_TYPES), ', '));
        }
        
        // Validate date range
        if (startDate == null || endDate == null) {
            throw new AuraHandledException('Start date and end date are required');
        }
        
        if (startDate > endDate) {
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
                AND LogDate >= :startDate
                AND LogDate <= :endDate
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
    public static List<Map<String, Object>> parseEventLogContent(String logFileId) {
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
    public static List<String> getAvailableEventTypes() {
        Set<String> availableTypes = new Set<String>();
        
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
        
        return new List<String>(availableTypes);
    }
    
    /**
     * @description Check Shield license status and features
     * @return Map containing Shield feature availability
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getShieldStatus() {
        Map<String, Object> status = new Map<String, Object>{
            'shieldEnabled' => false,
            'eventMonitoring' => false,
            'platformEncryption' => false,
            'fieldAuditTrail' => false,
            'availableEventTypes' => new List<String>()
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
                status.put('platformEncryption', tenantSecretCount > 0);
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
    public static Map<String, String> getEventRiskLevels() {
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
    private static List<Map<String, Object>> parseCSVContent(String csvContent) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        
        if (String.isBlank(csvContent)) {
            return results;
        }
        
        // Split into lines
        List<String> lines = csvContent.split('\n');
        
        if (lines.size() < 2) {
            return results; // No data rows
        }
        
        // Parse header row
        List<String> headers = parseCSVLine(lines[0]);
        
        // Parse data rows
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i].trim();
            if (String.isBlank(line)) {
                continue;
            }
            
            List<String> values = parseCSVLine(line);
            Map<String, Object> row = new Map<String, Object>();
            
            for (Integer j = 0; j < headers.size() &amp;&amp; j < values.size(); j++) {
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
    private static List<String> parseCSVLine(String line) {
        List<String> fields = new List<String>();
        
        if (String.isBlank(line)) {
            return fields;
        }
        
        Boolean inQuotes = false;
        String currentField = '';
        
        for (Integer i = 0; i < line.length(); i++) {
            String c = line.substring(i, i + 1);
            
            if (c == '"') {
                // Check for escaped quote
                if (i + 1 < line.length() &amp;&amp; line.substring(i + 1, i + 2) == '"') {
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
