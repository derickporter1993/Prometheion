/**
 * @description PagerDuty integration service for Prometheion
 * Provides incident triggering and resolution
 * @group Integrations
 * @author Prometheion Team
 */
public with sharing class PagerDutyIntegration {
    
    private static final String EVENTS_API = 'https://events.pagerduty.com/v2/enqueue';
    
    /**
     * @description Trigger a PagerDuty incident
     * @param alertData Alert information
     * @return Dedup key for the incident
     */
    @future(callout=true)
    public static void triggerIncident(String alertDataJson) {
        Map<String, Object> alertData = (Map<String, Object>)JSON.deserializeUntyped(alertDataJson);
        
        String severity = (String)alertData.get('severity');
        String pdSeverity = mapSeverity(severity);
        String dedupKey = 'prometheion-' + alertData.get('alertId');
        
        Map<String, Object> event = new Map<String, Object>{
            'routing_key' => getRoutingKey(),
            'event_action' => 'trigger',
            'dedup_key' => dedupKey,
            'payload' => new Map<String, Object>{
                'summary' => 'Prometheion Compliance Alert: ' + alertData.get('eventType'),
                'severity' => pdSeverity,
                'source' => 'Prometheion Compliance Platform',
                'component' => 'compliance-monitoring',
                'group' => (String)alertData.get('framework'),
                'class' => 'compliance',
                'custom_details' => new Map<String, Object>{
                    'alert_id' => alertData.get('alertId'),
                    'event_type' => alertData.get('eventType'),
                    'risk_score' => alertData.get('riskScore'),
                    'message' => alertData.get('message'),
                    'timestamp' => alertData.get('timestamp'),
                    'salesforce_url' => URL.getOrgDomainUrl().toExternalForm()
                }
            },
            'links' => new List<Object>{
                new Map<String, Object>{
                    'href' => URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/Prometheion',
                    'text' => 'View in Prometheion'
                }
            }
        };
        
        sendToPagerDuty(event);
    }
    
    /**
     * @description Resolve a PagerDuty incident
     * @param dedupKey The dedup key used when triggering
     */
    @future(callout=true)
    public static void resolveIncident(String dedupKey) {
        Map<String, Object> event = new Map<String, Object>{
            'routing_key' => getRoutingKey(),
            'event_action' => 'resolve',
            'dedup_key' => dedupKey
        };
        
        sendToPagerDuty(event);
    }
    
    /**
     * @description Acknowledge a PagerDuty incident
     * @param dedupKey The dedup key used when triggering
     */
    @future(callout=true)
    public static void acknowledgeIncident(String dedupKey) {
        Map<String, Object> event = new Map<String, Object>{
            'routing_key' => getRoutingKey(),
            'event_action' => 'acknowledge',
            'dedup_key' => dedupKey
        };
        
        sendToPagerDuty(event);
    }
    
    /**
     * @description Trigger incident with severity mapping
     * @param title Incident title
     * @param description Incident description
     * @param severity Severity (CRITICAL, HIGH, MEDIUM, LOW)
     * @param alertId Alert ID for dedup
     * @return Dedup key
     */
    @AuraEnabled
    public static String createIncident(String title, String description, String severity, String alertId) {
        String dedupKey = 'prometheion-' + (String.isNotBlank(alertId) ? alertId : String.valueOf(Datetime.now().getTime()));
        
        Map<String, Object> alertData = new Map<String, Object>{
            'alertId' => alertId,
            'eventType' => title,
            'severity' => severity,
            'message' => description,
            'timestamp' => Datetime.now()
        };
        
        triggerIncident(JSON.serialize(alertData));
        
        return dedupKey;
    }
    
    /**
     * @description Get PagerDuty incident history (mock - PD API requires different auth)
     * @return List of recent incidents
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRecentIncidents() {
        // In production, this would query PagerDuty REST API
        // For now, return empty list
        return new List<Map<String, Object>>();
    }
    
    private static void sendToPagerDuty(Map<String, Object> event) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(EVENTS_API);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(event));
        req.setTimeout(30000);
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 202) {
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                System.debug(LoggingLevel.INFO, 'PagerDuty event sent: ' + response.get('dedup_key'));
            } else {
                System.debug(LoggingLevel.ERROR, 'PagerDuty error: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'PagerDuty integration error: ' + e.getMessage());
        }
    }
    
    private static String getRoutingKey() {
        // In production, retrieve from Custom Metadata or Named Credential
        // This is a placeholder
        return 'your-pagerduty-routing-key';
    }
    
    private static String mapSeverity(String severity) {
        Map<String, String> severityMap = new Map<String, String>{
            'CRITICAL' => 'critical',
            'HIGH' => 'error',
            'MEDIUM' => 'warning',
            'LOW' => 'info',
            'INFO' => 'info'
        };
        return severityMap.containsKey(severity) ? severityMap.get(severity) : 'warning';
    }
}
