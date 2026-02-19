/**
 * Batch processor for historical Shield EventLogFiles
 * Processes large volumes of historical events with heap limit protection
 * @group Security
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 */
public with sharing class ElaroHistoricalEventBatch implements Database.Batchable&lt;SObject&gt;, Database.Stateful {
    
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
    private List&lt;String&gt; errorMessages = new List&lt;String&gt;();
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * Constructor for the batch job
     * @param eventType The event type to process
     * @param startDate Start date for processing
     * @param endDate End date for processing
     */
    public ElaroHistoricalEventBatch(String eventType, Date startDate, Date endDate) {
        this.eventType = eventType;
        this.startDate = startDate;
        this.endDate = endDate;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // BATCHABLE INTERFACE METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * Start method - query EventLogFiles for processing
     * @param bc Batchable context
     * @return QueryLocator for EventLogFile records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        ElaroLogger.debug('Starting ElaroHistoricalEventBatch for ' + eventType + 
            ' from ' + startDate + ' to ' + endDate);
        
        return Database.getQueryLocator([
            SELECT Id, EventType, LogDate, LogFileLength, LogFile, Interval, Sequence
            FROM EventLogFile
            WHERE EventType = :eventType
            AND LogDate &gt;= :startDate
            AND LogDate &lt;= :endDate
            WITH USER_MODE
            ORDER BY LogDate ASC
        ]);
    }
    
    /**
     * Execute method - process batch of EventLogFiles
     * @param bc Batchable context
     * @param scope List of EventLogFile records to process
     */
    public void execute(Database.BatchableContext bc, List&lt;EventLogFile&gt; scope) {
        for (EventLogFile logFile : scope) {
            try {
                processLogFile(logFile);
                totalFilesProcessed++;
            } catch (Exception e) {
                totalErrors++;
                String errorMsg = 'Error processing LogFile ' + logFile.Id + ': ' + e.getMessage();
                errorMessages.add(errorMsg);
                ElaroLogger.error( errorMsg);
            }
        }
    }
    
    /**
     * Finish method - send completion notification
     * @param bc Batchable context
     */
    public void finish(Database.BatchableContext bc) {
        ElaroLogger.debug('ElaroHistoricalEventBatch completed');
        ElaroLogger.debug('Files processed: ' + totalFilesProcessed);
        ElaroLogger.debug('Events processed: ' + totalEventsProcessed);
        ElaroLogger.debug('Errors: ' + totalErrors);
        
        // Publish completion event
        publishCompletionEvent();
        
        // Send notification if errors occurred
        if (totalErrors &gt; 0) {
            sendErrorNotification();
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PROCESSING METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * Process a single EventLogFile
     * @param logFile The EventLogFile to process
     */
    private void processLogFile(EventLogFile logFile) {
        // Check file size for chunking
        if (logFile.LogFileLength &gt; CSV_CHUNK_THRESHOLD) {
            processLargeLogFile(logFile);
        } else {
            processNormalLogFile(logFile);
        }
    }
    
    /**
     * Process a normal-sized log file
     * @param logFile The EventLogFile to process
     */
    private void processNormalLogFile(EventLogFile logFile) {
        // Decode the CSV content
        String csvContent = logFile.LogFile.toString();
        
        // Parse the CSV
        List&lt;Map&lt;String, Object&gt;&gt; events = parseCSVContent(csvContent);
        
        // Process and publish events
        processEvents(events, logFile.LogDate);
    }
    
    /**
     * Process a large log file in chunks
     * @param logFile The EventLogFile to process
     */
    private void processLargeLogFile(EventLogFile logFile) {
        // For very large files, process in chunks to avoid heap limits
        String csvContent = logFile.LogFile.toString();
        
        // Split by lines
        List&lt;String&gt; lines = csvContent.split('\n');
        
        if (lines.isEmpty()) {
            return;
        }
        
        // Extract header
        String headerLine = lines[0];
        List&lt;String&gt; headers = parseCSVLine(headerLine);
        
        // Process in chunks
        Integer chunkSize = 1000;
        Integer currentIndex = 1; // Skip header
        
        while (currentIndex &lt; lines.size()) {
            List&lt;Map&lt;String, Object&gt;&gt; chunkEvents = new List&lt;Map&lt;String, Object&gt;&gt;();
            Integer endIndex = Math.min(currentIndex + chunkSize, lines.size());
            
            for (Integer i = currentIndex; i &lt; endIndex; i++) {
                String line = lines[i].trim();
                if (String.isNotBlank(line)) {
                    List&lt;String&gt; values = parseCSVLine(line);
                    Map&lt;String, Object&gt; row = new Map&lt;String, Object&gt;();
                    
                    for (Integer j = 0; j &lt; headers.size() &amp;&amp; j &lt; values.size(); j++) {
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
     * Process parsed events and publish Platform Events
     * @param events List of parsed event data
     * @param logDate The date of the log file
     */
    private void processEvents(List&lt;Map&lt;String, Object&gt;&gt; events, Date logDate) {
        List&lt;Elaro_Event__e&gt; platformEvents = new List&lt;Elaro_Event__e&gt;();
        
        for (Map&lt;String, Object&gt; eventData : events) {
            try {
                // Parse and enrich the event
                Map&lt;String, Object&gt; parsedEvent = ElaroEventParser.parseEvent(eventType, eventData);
                
                // Calculate risk score
                Integer riskScore = ElaroRealtimeMonitor.calculateRiskScore(eventData);
                parsedEvent.put('riskScore', riskScore);
                parsedEvent.put('logDate', logDate);
                parsedEvent.put('source', 'HistoricalBatch');
                
                // Create Platform Event
                Elaro_Event__e pe = new Elaro_Event__e(
                    Event_Type__c = eventType,
                    Payload__c = JSON.serialize(parsedEvent)
                );
                
                platformEvents.add(pe);
                totalEventsProcessed++;
                
                // Publish in batches to avoid limits
                if (platformEvents.size() &gt;= MAX_EVENTS_PER_PUBLISH) {
                    publishEvents(platformEvents);
                    platformEvents.clear();
                }
                
            } catch (Exception e) {
                totalErrors++;
                ElaroLogger.warn( 'Error processing event: ' + e.getMessage());
            }
        }
        
        // Publish remaining events
        if (!platformEvents.isEmpty()) {
            publishEvents(platformEvents);
        }
    }
    
    /**
     * Publish Platform Events
     * @param events List of events to publish
     */
    private void publishEvents(List&lt;Elaro_Event__e&gt; events) {
        if (events.isEmpty()) {
            return;
        }
        
        try {
            List&lt;Database.SaveResult&gt; results = EventBus.publish(events);
            
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        ElaroLogger.error( 'Event publish error: ' + err.getMessage());
                        totalErrors++;
                    }
                }
            }
        } catch (Exception e) {
            ElaroLogger.error( 'Failed to publish events: ' + e.getMessage());
            totalErrors++;
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // CSV PARSING METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * Parse CSV content into list of maps
     * @param csvContent The CSV string to parse
     * @return List of parsed rows
     */
    private List&lt;Map&lt;String, Object&gt;&gt; parseCSVContent(String csvContent) {
        List&lt;Map&lt;String, Object&gt;&gt; results = new List&lt;Map&lt;String, Object&gt;&gt;();
        
        if (String.isBlank(csvContent)) {
            return results;
        }
        
        List&lt;String&gt; lines = csvContent.split('\n');
        
        if (lines.size() &lt; 2) {
            return results;
        }
        
        // Parse header
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
     * Parse a single CSV line handling quoted fields
     * @param line The CSV line to parse
     * @return List of field values
     */
    private List&lt;String&gt; parseCSVLine(String line) {
        List&lt;String&gt; fields = new List&lt;String&gt;();
        
        if (String.isBlank(line)) {
            return fields;
        }
        
        Boolean inQuotes = false;
        String currentField = '';
        
        for (Integer i = 0; i &lt; line.length(); i++) {
            String c = line.substring(i, i + 1);
            
            if (c == '"') {
                if (i + 1 &lt; line.length() &amp;&amp; line.substring(i + 1, i + 2) == '"') {
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
     * Publish completion event
     */
    private void publishCompletionEvent() {
        try {
            Elaro_Event__e completionEvent = new Elaro_Event__e(
                Event_Type__c = 'BatchComplete',
                Payload__c = JSON.serialize(new Map&lt;String, Object&gt;{
                    'eventType' =&gt; eventType,
                    'startDate' =&gt; startDate,
                    'endDate' =&gt; endDate,
                    'filesProcessed' =&gt; totalFilesProcessed,
                    'eventsProcessed' =&gt; totalEventsProcessed,
                    'errors' =&gt; totalErrors,
                    'completedAt' =&gt; Datetime.now()
                })
            );
            
            EventBus.publish(completionEvent);
        } catch (Exception e) {
            ElaroLogger.error( 'Failed to publish completion event: ' + e.getMessage());
        }
    }
    
    /**
     * Send error notification email
     */
    private void sendErrorNotification() {
        // Build error summary
        String subject = 'Elaro Historical Event Batch - Errors Detected';
        String body = 'The historical event batch processing completed with errors.\n\n';
        body += 'Event Type: ' + eventType + '\n';
        body += 'Date Range: ' + startDate + ' to ' + endDate + '\n';
        body += 'Files Processed: ' + totalFilesProcessed + '\n';
        body += 'Events Processed: ' + totalEventsProcessed + '\n';
        body += 'Total Errors: ' + totalErrors + '\n\n';
        
        if (!errorMessages.isEmpty()) {
            body += 'Error Messages:\n';
            for (Integer i = 0; i &lt; Math.min(errorMessages.size(), 10); i++) {
                body += '- ' + errorMessages[i] + '\n';
            }
            if (errorMessages.size() &gt; 10) {
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
            
            Messaging.sendEmail(new List&lt;Messaging.SingleEmailMessage&gt;{ email });
        } catch (Exception e) {
            ElaroLogger.error( 'Failed to send error notification: ' + e.getMessage());
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // UTILITY METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * Get processing statistics
     * @return Map of statistics
     */
    public Map&lt;String, Object&gt; getStatistics() {
        return new Map&lt;String, Object&gt;{
            'eventType' =&gt; eventType,
            'startDate' =&gt; startDate,
            'endDate' =&gt; endDate,
            'filesProcessed' =&gt; totalFilesProcessed,
            'eventsProcessed' =&gt; totalEventsProcessed,
            'errors' =&gt; totalErrors
        };
    }
}
