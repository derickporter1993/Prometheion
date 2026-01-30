/**
 * ElaroEventPublisher
 * 
 * Lightweight event publisher that publishes configuration changes, audit trail events,
 * and permission changes to AWS via Platform Events. Zero CPU cost - Platform Events
 * are asynchronous and don't count against governor limits.
 * 
 * Security: Uses 'without sharing' because Platform Events must be published regardless
 * of user's sharing rules. This is intentional and follows Salesforce best practices
 * for event publishing. The events themselves contain only metadata, not sensitive data.
 * 
 * @author Elaro TeamCRM
 * @version 1.0
 */
public without sharing class ElaroEventPublisher {
    
    /**
     * Publishes a configuration change event to AWS via Platform Events
     * @param orgId The Salesforce org ID
     * @param entityType The type of entity that changed (e.g., 'PermissionSet', 'Profile')
     * @param entityId The ID of the entity that changed
     * @param changeData Map containing change details
     */
    public static void publishConfigChange(
        String orgId,
        String entityType,
        String entityId,
        Map<String, Object> changeData
    ) {
        Elaro_Raw_Event__e event = new Elaro_Raw_Event__e(
            Org_ID__c = orgId,
            Event_Type__c = 'ConfigChange',
            Entity_Type__c = entityType,
            Entity_ID__c = entityId,
            Event_Data__c = JSON.serialize(changeData),
            Timestamp__c = Datetime.now()
        );
        
        EventBus.publish(event);
    }
    
    /**
     * Publishes an audit trail change event
     * @param orgId The Salesforce org ID
     * @param auditData Map containing audit trail entry details
     */
    public static void publishAuditTrailChange(
        String orgId,
        Map<String, Object> auditData
    ) {
        Elaro_Raw_Event__e event = new Elaro_Raw_Event__e(
            Org_ID__c = orgId,
            Event_Type__c = 'AuditTrail',
            Event_Data__c = JSON.serialize(auditData),
            Timestamp__c = Datetime.now()
        );
        
        EventBus.publish(event);
    }
    
    /**
     * Publishes a permission change event
     * @param orgId The Salesforce org ID
     * @param userId The user ID affected
     * @param permissionSetId The permission set ID
     * @param action The action taken ('ASSIGNED' or 'REMOVED')
     */
    public static void publishPermissionChange(
        String orgId,
        String userId,
        String permissionSetId,
        String action
    ) {
        Map<String, Object> changeData = new Map<String, Object>{
            'userId' => userId,
            'permissionSetId' => permissionSetId,
            'action' => action,
            'timestamp' => Datetime.now().getTime()
        };
        
        Elaro_Raw_Event__e event = new Elaro_Raw_Event__e(
            Org_ID__c = orgId,
            Event_Type__c = 'PermissionChange',
            Entity_Type__c = 'PermissionSetAssignment',
            Entity_ID__c = userId + '_' + permissionSetId,
            Event_Data__c = JSON.serialize(changeData),
            Timestamp__c = Datetime.now()
        );
        
        EventBus.publish(event);
    }
    
    /**
     * Publishes multiple events in a batch
     * @param events List of Elaro_Raw_Event__e events to publish
     */
    public static void publishBatch(List<Elaro_Raw_Event__e> events) {
        if (events != null && !events.isEmpty()) {
            EventBus.publish(events);
        }
    }
}

