public with sharing class SlackNotifier {
    @future(callout=true)
    public static void notifyAsync(String text) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Slack_Webhook');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(new Map<String, Object>{ 'text' => text }));
            new Http().send(req);
        } catch (Exception e) {
            System.debug('Slack notify failed: ' + e.getMessage());
        }
    }

    public static void notifyPerformanceEvent(Performance_Alert__e evt) {
        String msg = '\u26a0\ufe0f *CCX Performance Alert*' +
            '\nMetric: ' + evt.Metric__c +
            '\nValue: ' + String.valueOf(evt.Value__c) +
            '\nThreshold: ' + String.valueOf(evt.Threshold__c) +
            (String.isBlank(evt.Context_Record__c) ? '' : '\nContext: ' + evt.Context_Record__c);
        notifyAsync(msg);
    }
}
