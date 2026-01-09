/**
 * @description Compliance alert service for multi-channel notifications
 * Supports Email, Slack, PagerDuty, and Bell notifications
 * @group Automation & Alerting
 * @author Prometheion Team
 */
public with sharing class PrometheionComplianceAlert {
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════
    
    public enum AlertChannel { EMAIL, SLACK, PAGERDUTY, BELL }
    public enum AlertSeverity { CRITICAL, HIGH, MEDIUM, LOW, INFO }
    
    private static final Integer HIGH_RISK_THRESHOLD = 80;
    private static final Integer CRITICAL_RISK_THRESHOLD = 95;
    
    // ═══════════════════════════════════════════════════════════════
    // PUBLIC METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Configure a new alert rule
     * @param config The alert configuration
     * @return Id of the created alert configuration
     */
    @AuraEnabled
    public static Id configureAlert(AlertConfig config) {
        validateAlertConfig(config);
        
        // Create custom metadata or custom setting record
        Prometheion_Alert_Config__c alertRecord = new Prometheion_Alert_Config__c(
            Name = config.name,
            Alert_Type__c = config.alertType,
            Threshold__c = config.threshold,
            Channels__c = String.join(config.channels, ';'),
            Severity__c = config.severity,
            Is_Active__c = true,
            Framework__c = config.framework,
            Description__c = config.description
        );
        
        insert alertRecord;
        return alertRecord.Id;
    }
    
    /**
     * @description Process an alert based on event data
     * @param eventData The event data to evaluate
     * @return AlertResult with processing outcome
     */
    public static AlertResult processAlert(Map<String, Object> eventData) {
        AlertResult result = new AlertResult();
        result.processed = true;
        result.timestamp = Datetime.now();
        
        // Get risk score from event
        Integer riskScore = 0;
        if (eventData.containsKey('riskScore')) {
            riskScore = Integer.valueOf(eventData.get('riskScore'));
        } else if (eventData.containsKey('calculatedRiskScore')) {
            riskScore = Integer.valueOf(eventData.get('calculatedRiskScore'));
        }
        
        // Determine severity
        result.severity = determineSeverity(riskScore);
        result.riskScore = riskScore;
        
        // Check if alert should be triggered
        if (riskScore >= HIGH_RISK_THRESHOLD) {
            result.alertTriggered = true;
            result.alertId = generateAlertId();
            
            // Get matching alert configurations
            List<Prometheion_Alert_Config__c> configs = getMatchingAlertConfigs(eventData, riskScore);
            
            // Queue alert for each matching config
            for (Prometheion_Alert_Config__c config : configs) {
                queueAlert(config, eventData, result);
            }
        }
        
        return result;
    }
    
    /**
     * @description Queue an alert for asynchronous processing
     * @param config The alert configuration
     * @param eventData The event data
     * @param result The alert result
     */
    public static void queueAlert(Prometheion_Alert_Config__c config, Map<String, Object> eventData, AlertResult result) {
        // Parse channels
        List<String> channels = config.Channels__c != null 
            ? config.Channels__c.split(';') 
            : new List<String>{ 'EMAIL' };
        
        // Queue for async processing
        for (String channel : channels) {
            AlertQueueItem queueItem = new AlertQueueItem();
            queueItem.alertId = result.alertId;
            queueItem.channel = channel;
            queueItem.severity = config.Severity__c;
            queueItem.eventData = eventData;
            queueItem.configId = config.Id;
            
            // Enqueue for processing
            if (!Test.isRunningTest()) {
                System.enqueueJob(new PrometheionAlertQueueable(queueItem));
            }
        }
    }
    
    /**
     * @description Send alert notification to specified channel
     * @param channel The notification channel
     * @param alertData The alert data
     */
    @future(callout=true)
    public static void sendAlertNotification(String channel, String alertDataJson) {
        Map<String, Object> alertData = (Map<String, Object>)JSON.deserializeUntyped(alertDataJson);
        
        switch on channel.toUpperCase() {
            when 'EMAIL' {
                sendEmailAlert(alertData);
            }
            when 'SLACK' {
                sendSlackAlert(alertData);
            }
            when 'PAGERDUTY' {
                sendPagerDutyAlert(alertData);
            }
            when 'BELL' {
                createBellNotification(alertData);
            }
        }
    }
    
    /**
     * @description Get active alerts for the current user
     * @return List of active alerts
     */
    @AuraEnabled(cacheable=true)
    public static List<AlertSummary> getActiveAlerts() {
        List<AlertSummary> alerts = new List<AlertSummary>();
        
        // Query recent platform events or custom objects
        List<Prometheion_Evidence_Item__c> recentEvents = [
            SELECT Id, Name, Evidence_Type__c, Evidence_Date__c, Description__c, Status__c
            FROM Prometheion_Evidence_Item__c
            WHERE CreatedDate >= LAST_N_DAYS:7
            AND Status__c = 'Pending Review'
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
        
        for (Prometheion_Evidence_Item__c event : recentEvents) {
            AlertSummary summary = new AlertSummary();
            summary.id = event.Id;
            summary.title = event.Evidence_Type__c + ' Alert';
            summary.description = event.Description__c;
            summary.severity = 'HIGH';
            summary.timestamp = event.Evidence_Date__c;
            alerts.add(summary);
        }
        
        return alerts;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════
    
    private static void validateAlertConfig(AlertConfig config) {
        if (String.isBlank(config.name)) {
            throw new AuraHandledException('Alert name is required');
        }
        if (config.threshold == null || config.threshold < 0 || config.threshold > 100) {
            throw new AuraHandledException('Threshold must be between 0 and 100');
        }
        if (config.channels == null || config.channels.isEmpty()) {
            throw new AuraHandledException('At least one notification channel is required');
        }
    }
    
    private static String determineSeverity(Integer riskScore) {
        if (riskScore >= CRITICAL_RISK_THRESHOLD) return 'CRITICAL';
        if (riskScore >= HIGH_RISK_THRESHOLD) return 'HIGH';
        if (riskScore >= 50) return 'MEDIUM';
        if (riskScore >= 25) return 'LOW';
        return 'INFO';
    }
    
    private static String generateAlertId() {
        return 'ALERT-' + String.valueOf(Datetime.now().getTime()) + '-' + 
               String.valueOf(Math.abs(Crypto.getRandomInteger())).left(6);
    }
    
    private static List<Prometheion_Alert_Config__c> getMatchingAlertConfigs(Map<String, Object> eventData, Integer riskScore) {
        String eventType = (String)eventData.get('eventType');
        String framework = (String)eventData.get('framework');
        
        String query = 'SELECT Id, Name, Alert_Type__c, Threshold__c, Channels__c, Severity__c, Framework__c ' +
                       'FROM Prometheion_Alert_Config__c ' +
                       'WHERE Is_Active__c = true AND Threshold__c <= :riskScore';
        
        return Database.query(query);
    }
    
    private static void sendEmailAlert(Map<String, Object> alertData) {
        String subject = 'Prometheion Alert: ' + alertData.get('severity') + ' - ' + alertData.get('alertId');
        String body = buildEmailBody(alertData);
        
        List<String> recipients = getAlertRecipients();
        
        if (!recipients.isEmpty()) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(recipients);
            email.setSubject(subject);
            email.setHtmlBody(body);
            email.setSaveAsActivity(false);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        }
    }
    
    private static void sendSlackAlert(Map<String, Object> alertData) {
        Map<String, Object> slackMessage = buildSlackMessage(alertData);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Slack_Webhook');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(slackMessage));
        
        Http http = new Http();
        http.send(req);
    }
    
    private static void sendPagerDutyAlert(Map<String, Object> alertData) {
        String severity = (String)alertData.get('severity');
        String pdSeverity = severity == 'CRITICAL' ? 'critical' : 
                          severity == 'HIGH' ? 'error' : 
                          severity == 'MEDIUM' ? 'warning' : 'info';
        
        Map<String, Object> pdEvent = new Map<String, Object>{
            'routing_key' => '{!$Credential.PagerDuty_API_Key}',
            'event_action' => 'trigger',
            'payload' => new Map<String, Object>{
                'summary' => 'Prometheion Alert: ' + alertData.get('alertId'),
                'severity' => pdSeverity,
                'source' => 'Prometheion Compliance Platform',
                'custom_details' => alertData
            }
        };
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://events.pagerduty.com/v2/enqueue');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(pdEvent));
        
        Http http = new Http();
        http.send(req);
    }
    
    private static void createBellNotification(Map<String, Object> alertData) {
        // Create Salesforce Bell notification
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'Prometheion_Alert'
            LIMIT 1
        ];
        
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('Prometheion Alert');
        notification.setBody((String)alertData.get('message'));
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(UserInfo.getUserId());
        
        notification.send(new Set<String>{ UserInfo.getUserId() });
    }
    
    private static String buildEmailBody(Map<String, Object> alertData) {
        return '<html><body>' +
               '<div style="background-color:#c23934;color:white;padding:15px;">' +
               '<h2>⚠️ Prometheion Compliance Alert</h2></div>' +
               '<div style="padding:20px;">' +
               '<p><strong>Alert ID:</strong> ' + alertData.get('alertId') + '</p>' +
               '<p><strong>Severity:</strong> ' + alertData.get('severity') + '</p>' +
               '<p><strong>Risk Score:</strong> ' + alertData.get('riskScore') + '</p>' +
               '<p><strong>Event Type:</strong> ' + alertData.get('eventType') + '</p>' +
               '<p><strong>Timestamp:</strong> ' + alertData.get('timestamp') + '</p>' +
               '<p><strong>Details:</strong> ' + alertData.get('message') + '</p>' +
               '</div></body></html>';
    }
    
    private static Map<String, Object> buildSlackMessage(Map<String, Object> alertData) {
        String severity = (String)alertData.get('severity');
        String color = severity == 'CRITICAL' ? '#c23934' : 
                      severity == 'HIGH' ? '#e87722' : 
                      severity == 'MEDIUM' ? '#f7b924' : '#4bca81';
        
        return new Map<String, Object>{
            'attachments' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'color' => color,
                    'blocks' => new List<Object>{
                        new Map<String, Object>{
                            'type' => 'header',
                            'text' => new Map<String, Object>{
                                'type' => 'plain_text',
                                'text' => '⚠️ Prometheion Compliance Alert'
                            }
                        },
                        new Map<String, Object>{
                            'type' => 'section',
                            'fields' => new List<Object>{
                                new Map<String, Object>{ 'type' => 'mrkdwn', 'text' => '*Alert ID:*\n' + alertData.get('alertId') },
                                new Map<String, Object>{ 'type' => 'mrkdwn', 'text' => '*Severity:*\n' + severity },
                                new Map<String, Object>{ 'type' => 'mrkdwn', 'text' => '*Risk Score:*\n' + alertData.get('riskScore') },
                                new Map<String, Object>{ 'type' => 'mrkdwn', 'text' => '*Event Type:*\n' + alertData.get('eventType') }
                            }
                        }
                    }
                }
            }
        };
    }
    
    private static List<String> getAlertRecipients() {
        // Get users with Prometheion Admin permission set
        List<String> recipients = new List<String>();
        
        for (User u : [
            SELECT Email FROM User 
            WHERE IsActive = true 
            AND Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Prometheion_Admin')
            LIMIT 10
        ]) {
            recipients.add(u.Email);
        }
        
        // Fallback to running user
        if (recipients.isEmpty()) {
            recipients.add(UserInfo.getUserEmail());
        }
        
        return recipients;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // INNER CLASSES
    // ═══════════════════════════════════════════════════════════════
    
    public class AlertConfig {
        @AuraEnabled public String name;
        @AuraEnabled public String alertType;
        @AuraEnabled public Decimal threshold;
        @AuraEnabled public List<String> channels;
        @AuraEnabled public String severity;
        @AuraEnabled public String framework;
        @AuraEnabled public String description;
    }
    
    public class AlertResult {
        @AuraEnabled public Boolean processed;
        @AuraEnabled public Boolean alertTriggered;
        @AuraEnabled public String alertId;
        @AuraEnabled public String severity;
        @AuraEnabled public Integer riskScore;
        @AuraEnabled public Datetime timestamp;
    }
    
    public class AlertQueueItem {
        public String alertId;
        public String channel;
        public String severity;
        public Map<String, Object> eventData;
        public Id configId;
    }
    
    public class AlertSummary {
        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public String severity;
        @AuraEnabled public Date timestamp;
    }
}
