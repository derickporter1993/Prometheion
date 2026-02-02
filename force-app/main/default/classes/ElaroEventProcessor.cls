/**
 * ElaroEventProcessor
 * 
 * Processes Elaro_Event__e Platform Events and indexes to Compliance Graph
 * 
 * @author Elaro
 * @version 1.0
 */
public with sharing class ElaroEventProcessor {
    
    /**
     * Process Platform Event and index to Compliance Graph
     * @param event Elaro Event
     */
    public static void processEvent(Elaro_Event__e event) {
        if (event == null) {
            return;
        }
        
        try {
            // Extract event data
            String entityType = event.Entity_Type__c;
            String entityId = event.Entity_Id__c;
            String framework = event.Framework__c;
            String eventType = event.Event_Type__c;
            
            if (String.isBlank(entityType) || String.isBlank(entityId)) {
                System.debug(LoggingLevel.WARN, '[ElaroEventProcessor] Missing entity type or ID');
                return;
            }
            
            // Index to Compliance Graph using ElaroGraphIndexer
            String nodeId = ElaroGraphIndexer.indexChange(
                entityType,
                entityId,
                null, // parentNodeId
                String.isNotBlank(framework) ? framework : ElaroConstants.FRAMEWORK_SOC2
            );
            
            System.debug(LoggingLevel.INFO, 
                '[ElaroEventProcessor] Event processed - NodeId: ' + nodeId + 
                ', EntityType: ' + entityType + 
                ', EntityId: ' + entityId);
            
        } catch (Exception e) {
            String correlationId = event.Correlation_Id__c != null ? event.Correlation_Id__c : 
                'EVT-' + System.now().getTime();
            System.debug(LoggingLevel.ERROR, 
                '[ElaroEventProcessor] Error processing event - CorrelationId: ' + correlationId + 
                ', Error: ' + e.getMessage() + 
                ', StackTrace: ' + e.getStackTraceString());
        }
    }
    
    /**
     * Process batch of Platform Events
     * @param events List of Elaro Events
     */
    public static void processEvents(List<Elaro_Event__e> events) {
        if (events == null || events.isEmpty()) {
            return;
        }
        
        for (Elaro_Event__e event : events) {
            processEvent(event);
        }
    }
}
