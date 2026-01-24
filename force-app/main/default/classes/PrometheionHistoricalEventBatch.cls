/**
 * @description Batch processor for historical Shield EventLogFiles
 * Processes large volumes of historical events with heap limit protection
 * @group Shield Integration
 * @author Prometheion Team
 */
public class PrometheionHistoricalEventBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════
    
    // Maximum events per Platform Event publish (avoid limits)
    private static final Integer MAX_EVENTS_PER_PUBLISH = 200;
    
    // CSV chunk size threshold (3MB to stay under heap limits)
    private static final Integer CSV_CHUNK_THRESHOLD = 3000000;
    
    // ═══════════════════════════════════════════════════════════════
    // INSTANCE VARIABLES (Stateful)
    // ═══════════════════════════════════════════════════════════════
    
    private String eventType;
    private Date startDate;
    private Date endDate;
    
    // Tracking statistics
    private Integer totalFilesProcessed = 0;
    private Integer totalEventsProcessed = 0;
    private Integer totalErrors = 0;
    private List<String> errorMessages = new List<String>();
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Constructor for the batch job
     * @param eventType The event type to process
     * @param startDate Start date for processing
     * @param endDate End date for processing
     */
    public PrometheionHistoricalEventBatch(String eventType, Date startDate, Date endDate) {
        this.eventType = eventType;
        this.startDate = startDate;
        this.endDate = endDate;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // BATCHABLE INTERFACE METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Start method - query EventLogFiles for processing
     * @param bc Batchable context
     * @return QueryLocator for EventLogFile records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Starting PrometheionHistoricalEventBatch for ' + eventType + 
            ' from ' + startDate + ' to ' + endDate);
        
        return Database.getQueryLocator([
            SELECT Id, EventType, LogDate, LogFileLength, LogFile, Interval, Sequence
            FROM EventLogFile
            WHERE EventType = :eventType
            AND LogDate >= :startDate
            AND LogDate <= :endDate
            ORDER BY LogDate ASC
        ]);
    }
    
    /**
     * @description Execute method - process batch of EventLogFiles
     * @param bc Batchable context
     * @param scope List of EventLogFile records to process
     */
    public void execute(Database.BatchableContext bc, List<EventLogFile> scope) {
        for (EventLogFile logFile : scope) {
            try {
                processLogFile(logFile);
                totalFilesProcessed++;
            } catch (Exception e) {
                totalErrors++;
                String errorMsg = 'Error processing LogFile ' + logFile.Id + ': ' + e.getMessage();
                errorMessages.add(errorMsg);
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
        }
    }
    
    /**
     * @description Finish method - send completion notification
     * @param bc Batchable context
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('PrometheionHistoricalEventBatch completed');
        System.debug('Files processed: ' + totalFilesProcessed);
        System.debug('Events processed: ' + totalEventsProcessed);
        System.debug('Errors: ' + totalErrors);
        
        // Publish completion event
        publishCompletionEvent();
        
        // Send notification if errors occurred
        if (totalErrors > 0) {
            sendErrorNotification();
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PROCESSING METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Process a single EventLogFile
     * @param logFile The EventLogFile to process
     */
    private void processLogFile(EventLogFile logFile) {
        // Check file size for chunking
        if (logFile.LogFileLength > CSV_CHUNK_THRESHOLD) {
            processLargeLogFile(logFile);
        } else {
            processNormalLogFile(logFile);
        }
    }
    
    /**
     * @description Process a normal-sized log file
     * @param logFile The EventLogFile to process
     */
    private void processNormalLogFile(EventLogFile logFile) {
        // Decode the CSV content
        String csvContent = logFile.LogFile.toString();
        
        // Parse the CSV
        List<Map<String, Object>> events = parseCSVContent(csvContent);
        
        // Process and publish events
        processEvents(events, logFile.LogDate);
    }
    
    /**
     * @description Process a large log file in chunks
     * @param logFile The EventLogFile to process
     */
    private void processLargeLogFile(EventLogFile logFile) {
        // For very large files, process in chunks to avoid heap limits
        String csvContent = logFile.LogFile.toString();
        
        // Split by lines
        List<String> lines = csvContent.split('\n');
        
        if (lines.isEmpty()) {
            return;
        }
        
        // Extract header
        String headerLine = lines[0];
        List<String> headers = parseCSVLine(headerLine);
        
        // Process in chunks
        Integer chunkSize = 1000;
        Integer currentIndex = 1; // Skip header
        
        while (currentIndex < lines.size()) {
            List<Map<String, Object>> chunkEvents = new List<Map<String, Object>>();
            Integer endIndex = Math.min(currentIndex + chunkSize, lines.size());
            
            for (Integer i = currentIndex; i < endIndex; i++) {
                String line = lines[i].trim();
                if (String.isNotBlank(line)) {
                    List<String> values = parseCSVLine(line);
                    Map<String, Object> row = new Map<String, Object>();
                    
                    for (Integer j = 0; j < headers.size() &amp;&amp; j < values.size(); j++) {
                        row.put(headers[j], values[j]);
                    }
                    
                    chunkEvents.add(row);
                }
            }
            
            // Process this chunk
            processEvents(chunkEvents, logFile.LogDate);
            
            currentIndex = endIndex;
        }
    }
    
    /**
     * @description Process parsed events and publish Platform Events
     * @param events List of parsed event data
     * @param logDate The date of the log file
     */
    private void processEvents(List<Map<String, Object>> events, Date logDate) {
        List<Prometheion_Event__e> platformEvents = new List<Prometheion_Event__e>();
        
        for (Map<String, Object> eventData : events) {
            try {
                // Parse and enrich the event
                Map<String, Object> parsedEvent = PrometheionEventParser.parseEvent(eventType, eventData);
                
                // Calculate risk score
                Integer riskScore = PrometheionRealtimeMonitor.calculateRiskScore(eventData);
                parsedEvent.put('riskScore', riskScore);
                parsedEvent.put('logDate', logDate);
                parsedEvent.put('source', 'HistoricalBatch');
                
                // Create Platform Event
                Prometheion_Event__e pe = new Prometheion_Event__e(
                    Event_Type__c = eventType,
                    Payload__c = JSON.serialize(parsedEvent)
                );
                
                platformEvents.add(pe);
                totalEventsProcessed++;
                
                // Publish in batches to avoid limits
                if (platformEvents.size() >= MAX_EVENTS_PER_PUBLISH) {
                    publishEvents(platformEvents);
                    platformEvents.clear();
                }
                
            } catch (Exception e) {
                totalErrors++;
                System.debug(LoggingLevel.WARN, 'Error processing event: ' + e.getMessage());
            }
        }
        
        // Publish remaining events
        if (!platformEvents.isEmpty()) {
            publishEvents(platformEvents);
        }
    }
    
    /**
     * @description Publish Platform Events
     * @param events List of events to publish
     */
    private void publishEvents(List<Prometheion_Event__e> events) {
        if (events.isEmpty()) {
            return;
        }
        
        try {
            List<Database.SaveResult> results = EventBus.publish(events);
            
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Event publish error: ' + err.getMessage());
                        totalErrors++;
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to publish events: ' + e.getMessage());
            totalErrors++;
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // CSV PARSING METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Parse CSV content into list of maps
     * @param csvContent The CSV string to parse
     * @return List of parsed rows
     */
    private List<Map<String, Object>> parseCSVContent(String csvContent) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        
        if (String.isBlank(csvContent)) {
            return results;
        }
        
        List<String> lines = csvContent.split('\n');
        
        if (lines.size() < 2) {
            return results;
        }
        
        // Parse header
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
    private List<String> parseCSVLine(String line) {
        List<String> fields = new List<String>();
        
        if (String.isBlank(line)) {
            return fields;
        }
        
        Boolean inQuotes = false;
        String currentField = '';
        
        for (Integer i = 0; i < line.length(); i++) {
            String c = line.substring(i, i + 1);
            
            if (c == '"') {
                if (i + 1 < line.length() &amp;&amp; line.substring(i + 1, i + 2) == '"') {
                    currentField += '"';
                    i++;
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
        
        fields.add(currentField.trim());
        
        return fields;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // NOTIFICATION METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Publish completion event
     */
    private void publishCompletionEvent() {
        try {
            Prometheion_Event__e completionEvent = new Prometheion_Event__e(
                Event_Type__c = 'BatchComplete',
                Payload__c = JSON.serialize(new Map<String, Object>{
                    'eventType' => eventType,
                    'startDate' => startDate,
                    'endDate' => endDate,
                    'filesProcessed' => totalFilesProcessed,
                    'eventsProcessed' => totalEventsProcessed,
                    'errors' => totalErrors,
                    'completedAt' => Datetime.now()
                })
            );
            
            EventBus.publish(completionEvent);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to publish completion event: ' + e.getMessage());
        }
    }
    
    /**
     * @description Send error notification email
     */
    private void sendErrorNotification() {
        // Build error summary
        String subject = 'Prometheion Historical Event Batch - Errors Detected';
        String body = 'The historical event batch processing completed with errors.\n\n';
        body += 'Event Type: ' + eventType + '\n';
        body += 'Date Range: ' + startDate + ' to ' + endDate + '\n';
        body += 'Files Processed: ' + totalFilesProcessed + '\n';
        body += 'Events Processed: ' + totalEventsProcessed + '\n';
        body += 'Total Errors: ' + totalErrors + '\n\n';
        
        if (!errorMessages.isEmpty()) {
            body += 'Error Messages:\n';
            for (Integer i = 0; i < Math.min(errorMessages.size(), 10); i++) {
                body += '- ' + errorMessages[i] + '\n';
            }
            if (errorMessages.size() > 10) {
                body += '... and ' + (errorMessages.size() - 10) + ' more errors\n';
            }
        }
        
        // Send to running user
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTargetObjectId(UserInfo.getUserId());
            email.setSubject(subject);
            email.setPlainTextBody(body);
            email.setSaveAsActivity(false);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to send error notification: ' + e.getMessage());
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // UTILITY METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Get processing statistics
     * @return Map of statistics
     */
    public Map<String, Object> getStatistics() {
        return new Map<String, Object>{
            'eventType' => eventType,
            'startDate' => startDate,
            'endDate' => endDate,
            'filesProcessed' => totalFilesProcessed,
            'eventsProcessed' => totalEventsProcessed,
            'errors' => totalErrors
        };
    }
}
