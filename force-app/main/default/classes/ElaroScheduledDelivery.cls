/**
 * @description Schedulable class for recurring audit package delivery
 * @group Export &amp; Delivery
 * @author Elaro Team
 */
global class ElaroScheduledDelivery implements Schedulable {
    
    private String packageId;
    private List&lt;String&gt; recipientEmails;
    
    /**
     * @description Constructor for scheduled delivery
     * @param packageId The audit package ID
     * @param recipientEmails List of recipient email addresses
     */
    global ElaroScheduledDelivery(String packageId, List&lt;String&gt; recipientEmails) {
        this.packageId = packageId;
        this.recipientEmails = recipientEmails;
    }
    
    /**
     * @description Execute the scheduled job
     * @param sc SchedulableContext
     */
    global void execute(SchedulableContext sc) {
        try {
            // Regenerate PDF with latest data
            Id contentVersionId = ElaroPDFExporter.generateAuditPackagePDF(packageId);
            
            // Deliver to recipients
            ElaroDeliveryService.deliverAuditPackage(packageId, recipientEmails);
            
            System.debug('Scheduled delivery completed for package: ' + packageId);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Scheduled delivery failed: ' + e.getMessage());
            
            // Send error notification
            sendErrorNotification(e.getMessage());
        }
    }
    
    /**
     * @description Send error notification to admins
     * @param errorMessage The error message
     */
    private void sendErrorNotification(String errorMessage) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTargetObjectId(UserInfo.getUserId());
            email.setSubject('Elaro Scheduled Delivery Failed');
            email.setPlainTextBody(
                'A scheduled audit package delivery has failed.\n\n' +
                'Package ID: ' + packageId + '\n' +
                'Error: ' + errorMessage + '\n\n' +
                'Please investigate and reschedule if necessary.'
            );
            email.setSaveAsActivity(false);
            
            if (!Test.isRunningTest()) {
                Messaging.sendEmail(new List&lt;Messaging.SingleEmailMessage&gt;{ email });
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to send error notification: ' + e.getMessage());
        }
    }
    
    /**
     * @description Schedule a delivery job
     * @param packageId The audit package ID
     * @param recipientEmails List of recipient email addresses
     * @param cronExpression The cron expression
     * @return Job ID
     */
    public static Id scheduleDelivery(String packageId, List&lt;String&gt; recipientEmails, String cronExpression) {
        ElaroScheduledDelivery scheduler = new ElaroScheduledDelivery(packageId, recipientEmails);
        String jobName = 'Elaro_Delivery_' + packageId.left(15) + '_' + Datetime.now().getTime();
        return System.schedule(jobName, cronExpression, scheduler);
    }
    
    /**
     * @description Schedule weekly delivery (every Monday at 8 AM)
     * @param packageId The audit package ID
     * @param recipientEmails List of recipient email addresses
     * @return Job ID
     */
    public static Id scheduleWeekly(String packageId, List&lt;String&gt; recipientEmails) {
        return scheduleDelivery(packageId, recipientEmails, '0 0 8 ? * MON');
    }
    
    /**
     * @description Schedule monthly delivery (1st of each month at 8 AM)
     * @param packageId The audit package ID
     * @param recipientEmails List of recipient email addresses
     * @return Job ID
     */
    public static Id scheduleMonthly(String packageId, List&lt;String&gt; recipientEmails) {
        return scheduleDelivery(packageId, recipientEmails, '0 0 8 1 * ?');
    }
    
    /**
     * @description Schedule quarterly delivery (1st of Jan, Apr, Jul, Oct at 8 AM)
     * @param packageId The audit package ID
     * @param recipientEmails List of recipient email addresses
     * @return Job ID
     */
    public static Id scheduleQuarterly(String packageId, List&lt;String&gt; recipientEmails) {
        return scheduleDelivery(packageId, recipientEmails, '0 0 8 1 1,4,7,10 ?');
    }
}
