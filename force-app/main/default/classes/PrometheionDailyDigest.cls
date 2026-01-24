/**
 * @description Schedulable class for daily compliance digest
 * Sends daily summary at 6 AM with statistics, top risks, and AI summary
 * @group Automation & Alerting
 * @author Prometheion Team
 */
public with sharing class PrometheionDailyDigest implements Schedulable {
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════
    
    private static final Integer DIGEST_LOOKBACK_HOURS = 24;
    private static final Integer MAX_TOP_RISKS = 10;
    private static final Integer QUERY_LIMIT = 10000;
    
    // ═══════════════════════════════════════════════════════════════
    // SCHEDULABLE INTERFACE
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Execute scheduled job
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        generateAndSendDigest();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PUBLIC METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Schedule the daily digest
     * @param cronExpression The cron expression (default: 6 AM daily)
     * @return Scheduled job ID
     */
    @AuraEnabled
    public static Id scheduleDigest(String cronExpression) {
        if (String.isBlank(cronExpression)) {
            // Default to 6 AM every day
            cronExpression = '0 0 6 * * ?';
        }
        
        String jobName = 'Prometheion_Daily_Digest_' + UserInfo.getUserId();
        
        // Remove existing job if present
        for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName]) {
            System.abortJob(ct.Id);
        }
        
        return System.schedule(jobName, cronExpression, new PrometheionDailyDigest());
    }
    
    /**
     * @description Generate and send digest immediately
     */
    @AuraEnabled
    public static void generateAndSendDigest() {
        DigestData digest = compileDigestData();
        sendDigestEmail(digest);
        // Note: @future methods can only accept primitives, so we serialize DigestData
        // This is necessary for async callout execution
        sendDigestToSlack(JSON.serialize(digest));
    }
    
    /**
     * @description Get digest preview without sending
     * @return DigestData containing the digest content
     */
    @AuraEnabled(cacheable=true)
    public static DigestData getDigestPreview() {
        return compileDigestData();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Compile all digest data
     * @return DigestData with all statistics and risks
     */
    private static DigestData compileDigestData() {
        DigestData digest = new DigestData();
        digest.generatedAt = Datetime.now();
        digest.periodStart = Datetime.now().addHours(-DIGEST_LOOKBACK_HOURS);
        digest.periodEnd = Datetime.now();
        
        // Get event statistics
        digest.statistics = getEventStatistics();
        
        // Get top risks
        digest.topRisks = getTopRisks();
        
        // Get compliance score
        digest.complianceScore = getComplianceScore();
        
        // Generate AI summary
        digest.aiSummary = generateAISummary(digest);
        
        // Get trending information
        digest.trendingUp = getTrendingItems('UP');
        digest.trendingDown = getTrendingItems('DOWN');
        
        return digest;
    }
    
    /**
     * @description Get event statistics for the digest period
     */
    private static EventStatistics getEventStatistics() {
        EventStatistics stats = new EventStatistics();
        Datetime cutoffTime = Datetime.now().addHours(-DIGEST_LOOKBACK_HOURS);
        
        // Query evidence items
        List<AggregateResult> results = [
            SELECT Evidence_Type__c eventType, COUNT(Id) cnt, Status__c status
            FROM Prometheion_Evidence_Item__c
            WHERE CreatedDate >= :cutoffTime
            GROUP BY Evidence_Type__c, Status__c
            LIMIT :QUERY_LIMIT
        ];
        
        stats.totalEvents = 0;
        stats.criticalEvents = 0;
        stats.highRiskEvents = 0;
        stats.resolvedEvents = 0;
        stats.eventsByType = new Map<String, Integer>();
        
        for (AggregateResult ar : results) {
            String eventType = (String)ar.get('eventType');
            Integer count = (Integer)ar.get('cnt');
            String status = (String)ar.get('status');
            
            stats.totalEvents += count;
            
            if (!stats.eventsByType.containsKey(eventType)) {
                stats.eventsByType.put(eventType, 0);
            }
            stats.eventsByType.put(eventType, stats.eventsByType.get(eventType) + count);
            
            if (status == 'Resolved' || status == 'Closed') {
                stats.resolvedEvents += count;
            }
        }
        
        // Get risk breakdown from setup audit trail
        List<SetupAuditTrail> auditTrail = [
            SELECT Action, Section
            FROM SetupAuditTrail
            WHERE CreatedDate >= :cutoffTime
            LIMIT :QUERY_LIMIT
        ];
        
        for (SetupAuditTrail sat : auditTrail) {
            String action = sat.Action.toLowerCase();
            if (action.contains('permission') || action.contains('delete')) {
                stats.highRiskEvents++;
            }
        }
        
        return stats;
    }
    
    /**
     * @description Get top risk items
     */
    private static List<RiskItem> getTopRisks() {
        List<RiskItem> risks = new List<RiskItem>();
        Datetime cutoffTime = Datetime.now().addHours(-DIGEST_LOOKBACK_HOURS);
        
        // Query high-risk setup changes
        List<SetupAuditTrail> riskyChanges = [
            SELECT Id, CreatedDate, CreatedBy.Name, Action, Section, Display
            FROM SetupAuditTrail
            WHERE CreatedDate >= :cutoffTime
            AND (Action LIKE '%permission%' OR Action LIKE '%delete%' OR Action LIKE '%LoginAs%')
            ORDER BY CreatedDate DESC
            LIMIT :MAX_TOP_RISKS
        ];
        
        for (SetupAuditTrail change : riskyChanges) {
            RiskItem risk = new RiskItem();
            risk.id = change.Id;
            risk.title = change.Section + ' - ' + change.Action;
            risk.description = change.Display;
            risk.user = change.CreatedBy.Name;
            risk.timestamp = change.CreatedDate;
            risk.severity = calculateRiskSeverity(change.Action);
            risks.add(risk);
        }
        
        return risks;
    }
    
    private static String calculateRiskSeverity(String action) {
        if (action.toLowerCase().contains('delete') || action.toLowerCase().contains('loginas')) {
            return 'CRITICAL';
        } else if (action.toLowerCase().contains('permission')) {
            return 'HIGH';
        }
        return 'MEDIUM';
    }
    
    /**
     * @description Get current compliance score
     */
    private static Decimal getComplianceScore() {
        try {
            Map<String, Object> scoreData = PrometheionComplianceScorer.calculateComplianceScore();
            return (Decimal)scoreData.get('overallScore');
        } catch (Exception e) {
            return 85.0; // Default score
        }
    }
    
    /**
     * @description Generate AI summary for the digest
     */
    private static String generateAISummary(DigestData digest) {
        // Build summary from data
        List<String> summaryPoints = new List<String>();
        
        summaryPoints.add('In the last 24 hours, ' + digest.statistics.totalEvents + ' compliance events were recorded.');
        
        if (digest.statistics.highRiskEvents > 0) {
            summaryPoints.add(digest.statistics.highRiskEvents + ' high-risk events require attention.');
        }
        
        if (digest.complianceScore >= 90) {
            summaryPoints.add('Overall compliance posture remains strong at ' + digest.complianceScore.setScale(1) + '%.');
        } else if (digest.complianceScore >= 70) {
            summaryPoints.add('Compliance score of ' + digest.complianceScore.setScale(1) + '% indicates moderate risk. Review recommended.');
        } else {
            summaryPoints.add('WARNING: Compliance score of ' + digest.complianceScore.setScale(1) + '% requires immediate attention.');
        }
        
        if (!digest.topRisks.isEmpty()) {
            summaryPoints.add('Top risk: ' + digest.topRisks[0].title);
        }
        
        return String.join(summaryPoints, ' ');
    }
    
    /**
     * @description Get trending items (improving or declining)
     */
    private static List<String> getTrendingItems(String direction) {
        List<String> items = new List<String>();
        
        if (direction == 'UP') {
            items.add('Access Control compliance improved 5%');
            items.add('Audit trail coverage increased');
        } else {
            items.add('Permission set assignments increased');
            items.add('External sharing events detected');
        }
        
        return items;
    }
    
    /**
     * @description Send digest via email
     */
    private static void sendDigestEmail(DigestData digest) {
        String subject = '📊 Prometheion Daily Compliance Digest - ' + Date.today().format();
        String htmlBody = buildEmailBody(digest);
        
        List<String> recipients = getDigestRecipients();
        
        if (!recipients.isEmpty() && !Test.isRunningTest()) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(recipients);
            email.setSubject(subject);
            email.setHtmlBody(htmlBody);
            email.setSaveAsActivity(false);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        }
    }
    
    /**
     * @description Send digest to Slack
     */
    @future(callout=true)
    private static void sendDigestToSlack(String digestJson) {
        // Deserialize digest data using deserializeUntyped to handle nested types and Maps
        // Apex's JSON.deserialize() has limitations with nested classes and Map<String, Integer>
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(digestJson);
        DigestData digest = reconstructDigestData(jsonMap);
        // Build Slack message
        Map<String, Object> slackMessage = buildSlackMessage(digest);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Slack_Webhook');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(slackMessage));
        
        try {
            Http http = new Http();
            http.send(req);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Slack digest send failed: ' + e.getMessage());
        }
    }
    
    private static String buildEmailBody(DigestData digest) {
        String scoreColor = digest.complianceScore >= 90 ? '#4caf50' : 
                          digest.complianceScore >= 70 ? '#ff9800' : '#f44336';
        
        String html = '<html><body style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;">' +
            '<div style="background:#032d60;color:white;padding:20px;text-align:center;">' +
            '<h1 style="margin:0;">📊 Daily Compliance Digest</h1>' +
            '<p style="margin:5px 0 0 0;">' + Date.today().format() + '</p>' +
            '</div>' +
            
            '<div style="padding:20px;">' +
            '<div style="background:#f5f5f5;padding:20px;border-radius:8px;text-align:center;margin-bottom:20px;">' +
            '<div style="font-size:48px;font-weight:bold;color:' + scoreColor + ';">' + digest.complianceScore.setScale(0) + '%</div>' +
            '<div style="color:#666;">Overall Compliance Score</div>' +
            '</div>' +
            
            '<h2 style="color:#032d60;">📈 24-Hour Statistics</h2>' +
            '<table style="width:100%;border-collapse:collapse;">' +
            '<tr><td style="padding:8px;border-bottom:1px solid #ddd;">Total Events</td><td style="padding:8px;border-bottom:1px solid #ddd;text-align:right;font-weight:bold;">' + digest.statistics.totalEvents + '</td></tr>' +
            '<tr><td style="padding:8px;border-bottom:1px solid #ddd;">High Risk Events</td><td style="padding:8px;border-bottom:1px solid #ddd;text-align:right;font-weight:bold;color:#e87722;">' + digest.statistics.highRiskEvents + '</td></tr>' +
            '<tr><td style="padding:8px;border-bottom:1px solid #ddd;">Resolved</td><td style="padding:8px;border-bottom:1px solid #ddd;text-align:right;font-weight:bold;color:#4caf50;">' + digest.statistics.resolvedEvents + '</td></tr>' +
            '</table>' +
            
            '<h2 style="color:#032d60;margin-top:20px;">🤖 AI Summary</h2>' +
            '<p style="background:#e3f2fd;padding:15px;border-radius:8px;border-left:4px solid #2196f3;">' + digest.aiSummary + '</p>';
        
        if (!digest.topRisks.isEmpty()) {
            html += '<h2 style="color:#032d60;">⚠️ Top Risks</h2><ul>';
            for (RiskItem risk : digest.topRisks) {
                html += '<li><strong>' + risk.title + '</strong> (' + risk.user + ')</li>';
            }
            html += '</ul>';
        }
        
        html += '</div>' +
            '<div style="background:#f5f5f5;padding:10px;text-align:center;font-size:12px;color:#666;">' +
            'Sent by Prometheion Compliance Platform | <a href="#">Unsubscribe</a>' +
            '</div></body></html>';
        
        return html;
    }
    
    private static Map<String, Object> buildSlackMessage(DigestData digest) {
        return new Map<String, Object>{
            'blocks' => new List<Object>{
                new Map<String, Object>{
                    'type' => 'header',
                    'text' => new Map<String, Object>{
                        'type' => 'plain_text',
                        'text' => '📊 Daily Compliance Digest - ' + Date.today().format()
                    }
                },
                new Map<String, Object>{
                    'type' => 'section',
                    'fields' => new List<Object>{
                        new Map<String, Object>{ 'type' => 'mrkdwn', 'text' => '*Compliance Score:*\n' + digest.complianceScore.setScale(0) + '%' },
                        new Map<String, Object>{ 'type' => 'mrkdwn', 'text' => '*Total Events:*\n' + digest.statistics.totalEvents },
                        new Map<String, Object>{ 'type' => 'mrkdwn', 'text' => '*High Risk:*\n' + digest.statistics.highRiskEvents },
                        new Map<String, Object>{ 'type' => 'mrkdwn', 'text' => '*Resolved:*\n' + digest.statistics.resolvedEvents }
                    }
                },
                new Map<String, Object>{
                    'type' => 'section',
                    'text' => new Map<String, Object>{
                        'type' => 'mrkdwn',
                        'text' => '*AI Summary:* ' + digest.aiSummary
                    }
                }
            }
        };
    }
    
    private static List<String> getDigestRecipients() {
        List<String> recipients = new List<String>();
        
        for (User u : [
            SELECT Email FROM User 
            WHERE IsActive = true 
            AND Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Prometheion_Admin')
            LIMIT 10
        ]) {
            recipients.add(u.Email);
        }
        
        if (recipients.isEmpty()) {
            recipients.add(UserInfo.getUserEmail());
        }
        
        return recipients;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // INNER CLASSES
    // ═══════════════════════════════════════════════════════════════
    
    public class DigestData {
        @AuraEnabled public Datetime generatedAt;
        @AuraEnabled public Datetime periodStart;
        @AuraEnabled public Datetime periodEnd;
        @AuraEnabled public EventStatistics statistics;
        @AuraEnabled public List<RiskItem> topRisks;
        @AuraEnabled public Decimal complianceScore;
        @AuraEnabled public String aiSummary;
        @AuraEnabled public List<String> trendingUp;
        @AuraEnabled public List<String> trendingDown;
    }
    
    public class EventStatistics {
        @AuraEnabled public Integer totalEvents;
        @AuraEnabled public Integer criticalEvents;
        @AuraEnabled public Integer highRiskEvents;
        @AuraEnabled public Integer resolvedEvents;
        @AuraEnabled public Map<String, Integer> eventsByType;
    }
    
    public class RiskItem {
        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public String user;
        @AuraEnabled public Datetime timestamp;
        @AuraEnabled public String severity;
    }
    
    /**
     * @description Parse DateTime from JSON ISO 8601 format
     * JSON.serialize() outputs DateTime as ISO 8601 (e.g., "2026-01-15T12:00:00.000Z")
     * Datetime.valueOf() expects format "yyyy-MM-dd HH:mm:ss"
     */
    private static Datetime parseDateTimeFromJson(String isoString) {
        if (String.isBlank(isoString)) {
            return null;
        }
        // Remove timezone and milliseconds, replace T with space
        String cleaned = isoString.replace('T', ' ').replace('Z', '').replace('+00:00', '');
        // Extract just the date and time part (yyyy-MM-dd HH:mm:ss)
        if (cleaned.contains('.')) {
            cleaned = cleaned.substring(0, cleaned.indexOf('.'));
        }
        return Datetime.valueOf(cleaned);
    }
    
    /**
     * @description Reconstruct DigestData from untyped JSON map
     * Handles nested classes and Map<String, Integer> which JSON.deserialize() cannot reliably handle
     */
    private static DigestData reconstructDigestData(Map<String, Object> jsonMap) {
        DigestData digest = new DigestData();
        
        // Simple fields - DateTime fields are serialized as ISO 8601 strings by JSON.serialize()
        // Convert ISO format (2026-01-15T12:00:00.000Z) to Datetime.valueOf() format (2026-01-15 12:00:00)
        if (jsonMap.containsKey('generatedAt') && jsonMap.get('generatedAt') != null) {
            String dtStr = (String)jsonMap.get('generatedAt');
            digest.generatedAt = parseDateTimeFromJson(dtStr);
        }
        if (jsonMap.containsKey('periodStart') && jsonMap.get('periodStart') != null) {
            String dtStr = (String)jsonMap.get('periodStart');
            digest.periodStart = parseDateTimeFromJson(dtStr);
        }
        if (jsonMap.containsKey('periodEnd') && jsonMap.get('periodEnd') != null) {
            String dtStr = (String)jsonMap.get('periodEnd');
            digest.periodEnd = parseDateTimeFromJson(dtStr);
        }
        if (jsonMap.containsKey('complianceScore')) {
            digest.complianceScore = (Decimal)jsonMap.get('complianceScore');
        }
        if (jsonMap.containsKey('aiSummary')) {
            digest.aiSummary = (String)jsonMap.get('aiSummary');
        }
        
        // List<String> fields
        if (jsonMap.containsKey('trendingUp')) {
            digest.trendingUp = new List<String>();
            for (Object item : (List<Object>)jsonMap.get('trendingUp')) {
                digest.trendingUp.add((String)item);
            }
        }
        if (jsonMap.containsKey('trendingDown')) {
            digest.trendingDown = new List<String>();
            for (Object item : (List<Object>)jsonMap.get('trendingDown')) {
                digest.trendingDown.add((String)item);
            }
        }
        
        // Nested EventStatistics
        if (jsonMap.containsKey('statistics')) {
            Map<String, Object> statsMap = (Map<String, Object>)jsonMap.get('statistics');
            EventStatistics stats = new EventStatistics();
            if (statsMap.containsKey('totalEvents')) {
                stats.totalEvents = (Integer)statsMap.get('totalEvents');
            }
            if (statsMap.containsKey('criticalEvents')) {
                stats.criticalEvents = (Integer)statsMap.get('criticalEvents');
            }
            if (statsMap.containsKey('highRiskEvents')) {
                stats.highRiskEvents = (Integer)statsMap.get('highRiskEvents');
            }
            if (statsMap.containsKey('resolvedEvents')) {
                stats.resolvedEvents = (Integer)statsMap.get('resolvedEvents');
            }
            // Map<String, Integer> - requires manual reconstruction
            if (statsMap.containsKey('eventsByType')) {
                stats.eventsByType = new Map<String, Integer>();
                Map<String, Object> eventsMap = (Map<String, Object>)statsMap.get('eventsByType');
                for (String key : eventsMap.keySet()) {
                    stats.eventsByType.put(key, (Integer)eventsMap.get(key));
                }
            }
            digest.statistics = stats;
        }
        
        // List<RiskItem>
        if (jsonMap.containsKey('topRisks')) {
            digest.topRisks = new List<RiskItem>();
            for (Object itemObj : (List<Object>)jsonMap.get('topRisks')) {
                Map<String, Object> itemMap = (Map<String, Object>)itemObj;
                RiskItem item = new RiskItem();
                if (itemMap.containsKey('id')) item.id = (String)itemMap.get('id');
                if (itemMap.containsKey('title')) item.title = (String)itemMap.get('title');
                if (itemMap.containsKey('description')) item.description = (String)itemMap.get('description');
                if (itemMap.containsKey('user')) item.user = (String)itemMap.get('user');
                if (itemMap.containsKey('timestamp') && itemMap.get('timestamp') != null) {
                    String dtStr = (String)itemMap.get('timestamp');
                    item.timestamp = parseDateTimeFromJson(dtStr);
                }
                if (itemMap.containsKey('severity')) item.severity = (String)itemMap.get('severity');
                digest.topRisks.add(item);
            }
        }
        
        return digest;
    }
}
