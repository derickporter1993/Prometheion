/**
 * @description Queueable class for processing alerts asynchronously
 * @group Automation & Alerting
 * @author Elaro Team
 */
public class ElaroAlertQueueable implements Queueable, Database.AllowsCallouts {
    
    private ElaroComplianceAlert.AlertQueueItem queueItem;
    
    public ElaroAlertQueueable(ElaroComplianceAlert.AlertQueueItem queueItem) {
        this.queueItem = queueItem;
    }
    
    public void execute(QueueableContext context) {
        if (queueItem == null) {
            return;
        }
        
        try {
            // Add alert metadata to event data
            Map<String, Object> alertData = new Map<String, Object>(queueItem.eventData);
            alertData.put('alertId', queueItem.alertId);
            alertData.put('severity', queueItem.severity);
            alertData.put('channel', queueItem.channel);
            alertData.put('timestamp', Datetime.now());
            alertData.put('message', buildAlertMessage(queueItem));
            
            // Send notification
            ElaroComplianceAlert.sendAlertNotification(
                queueItem.channel,
                JSON.serialize(alertData)
            );
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Alert queue processing error: ' + e.getMessage());
        }
    }
    
    private String buildAlertMessage(ElaroComplianceAlert.AlertQueueItem item) {
        String eventType = item.eventData.containsKey('eventType') 
            ? (String)item.eventData.get('eventType') 
            : 'Unknown';
        
        return 'A ' + item.severity + ' compliance alert has been triggered for ' + eventType + ' event.';
    }
}
