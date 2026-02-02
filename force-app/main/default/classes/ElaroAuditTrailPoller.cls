/**
 * ElaroAuditTrailPoller
 * 
 * Scheduled job that polls Setup Audit Trail every 5 minutes and publishes
 * changes to AWS via Platform Events for processing.
 * 
 * Runs in system context to poll audit trail regardless of user permissions.
 */
public without sharing class ElaroAuditTrailPoller implements Schedulable {
    
    private static final String JOB_NAME = 'Elaro Audit Trail Poller';
    private static final Integer BATCH_SIZE = 200;
    
    /**
     * Execute method for Schedulable interface
     */
    public void execute(SchedulableContext ctx) {
        pollAuditTrail();
    }
    
    /**
     * Polls Setup Audit Trail for recent changes and publishes events
     */
    public static void pollAuditTrail() {
        String orgId = UserInfo.getOrganizationId();
        Datetime lastPollTime = getLastPollTime();
        Datetime now = Datetime.now();
        
        // Query Setup Audit Trail entries
        // Note: In production, you'd use the Setup Audit Trail API or Metadata API
        // This is a simplified implementation
        List<Map<String, Object>> auditEntries = getAuditTrailEntries(lastPollTime, now);
        
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();
        
        for (Map<String, Object> entry : auditEntries) {
            Elaro_Raw_Event__e event = new Elaro_Raw_Event__e(
                Org_ID__c = orgId,
                Event_Type__c = 'AuditTrail',
                Event_Data__c = JSON.serialize(entry),
                Timestamp__c = (Datetime)entry.get('CreatedDate')
            );
            events.add(event);
        }
        
        if (!events.isEmpty()) {
            ElaroEventPublisher.publishBatch(events);
            updateLastPollTime(now);
        }
    }
    
    /**
     * Schedules the poller to run every 5 minutes
     * @return The job ID
     */
    public static String schedule() {
        String cronExp = '0 0,5,10,15,20,25,30,35,40,45,50,55 * * * ?'; // Every 5 minutes
        return System.schedule(JOB_NAME, cronExp, new ElaroAuditTrailPoller());
    }
    
    /**
     * Unschedules the poller job
     */
    public static void unschedule() {
        List<CronTrigger> jobs = [
            SELECT Id FROM CronTrigger 
            WHERE CronJobDetail.Name = :JOB_NAME
        ];
        
        for (CronTrigger job : jobs) {
            System.abortJob(job.Id);
        }
    }
    
    /**
     * Gets audit trail entries since last poll time
     * Queries SetupAuditTrail object for configuration changes
     */
    private static List<Map<String, Object>> getAuditTrailEntries(
        Datetime startTime, 
        Datetime endTime
    ) {
        List<Map<String, Object>> entries = new List<Map<String, Object>>();
        
        try {
            // Query SetupAuditTrail for changes within the time window
            for (SetupAuditTrail trail : [
                SELECT Action, CreatedBy.Username, CreatedDate, Display, Section
                FROM SetupAuditTrail
                WHERE CreatedDate >= :startTime AND CreatedDate <= :endTime
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT :BATCH_SIZE
            ]) {
                entries.add(new Map<String, Object>{
                    'Action' => trail.Action,
                    'CreatedBy' => trail.CreatedBy.Username,
                    'CreatedDate' => trail.CreatedDate,
                    'Display' => trail.Display,
                    'Section' => trail.Section
                });
            }
        } catch (Exception e) {
            // Log error but don't fail the entire job
            System.debug(LoggingLevel.ERROR, 'ElaroAuditTrailPoller: Error querying SetupAuditTrail: ' + e.getMessage());
        }
        
        return entries;
    }
    
    /**
     * Gets the last poll time from custom settings or returns 1 hour ago
     * Uses Elaro_Settings__c Custom Setting to persist last poll time
     */
    private static Datetime getLastPollTime() {
        try {
            Elaro_Settings__c settings = Elaro_Settings__c.getOrgDefaults();
            if (settings != null && settings.Last_Audit_Trail_Poll__c != null) {
                return settings.Last_Audit_Trail_Poll__c;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'ElaroAuditTrailPoller: Could not retrieve last poll time: ' + e.getMessage());
        }
        
        // Default: return 1 hour ago for first run
        return Datetime.now().addHours(-1);
    }
    
    /**
     * Updates the last poll time in Custom Settings
     * Creates org default if it doesn't exist
     */
    private static void updateLastPollTime(Datetime pollTime) {
        try {
            Elaro_Settings__c settings = Elaro_Settings__c.getOrgDefaults();
            if (settings == null) {
                settings = new Elaro_Settings__c(SetupOwnerId = UserInfo.getOrganizationId());
            }
            settings.Last_Audit_Trail_Poll__c = pollTime;
            upsert settings;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ElaroAuditTrailPoller: Failed to update last poll time: ' + e.getMessage());
            // Don't throw - logging failure shouldn't break the poller
        }
    }
}

