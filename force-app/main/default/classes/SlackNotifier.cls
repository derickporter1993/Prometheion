public with sharing class SlackNotifier {
    @future(callout=true)
    public static void notifyAsync(String text) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Slack_Webhook');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(new Map<String, Object>{ 'text' => text }));
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                System.debug(
                    LoggingLevel.ERROR,
                    'Slack notify failed with status ' +
                        res.getStatusCode() +
                        ': ' +
                        res.getStatus()
                );
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Slack notify exception: ' + e.getMessage());
        }
    }

    @future(callout=true)
    public static void notifyRichAsync(String jsonPayload) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Slack_Webhook');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonPayload);
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                System.debug(
                    LoggingLevel.ERROR,
                    'Slack rich notify failed with status ' +
                        res.getStatusCode() +
                        ': ' +
                        res.getStatus()
                );
            }
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Slack rich notify exception: ' + e.getMessage()
            );
        }
    }

    public static void notifyPerformanceEvent(Performance_Alert__e evt) {
        // Use rich formatting for performance alerts
        String jsonPayload = buildPerformanceAlertBlocks(evt);
        notifyRichAsync(jsonPayload);
    }

    // Build Slack Block Kit JSON for performance alerts
    private static String buildPerformanceAlertBlocks(Performance_Alert__e evt) {
        // Determine severity emoji and color
        String emoji = '⚠️';
        String color = '#ffb75d'; // Warning (orange)

        Decimal percentOfLimit = (evt.Value__c / evt.Threshold__c) * 100;

        if (percentOfLimit >= 95) {
            emoji = '🔴';
            color = '#c23934'; // Critical (red)
        } else if (percentOfLimit >= 90) {
            emoji = '🟡';
            color = '#ffb75d'; // Warning (orange)
        }

        // Build the blocks structure
        Map<String, Object> payload = new Map<String, Object>();

        // Fallback text for notifications
        payload.put(
            'text',
            emoji +
            ' Prometheion Alert: ' +
            evt.Metric__c +
            ' at ' +
            percentOfLimit.setScale(1) +
            '%'
        );

        // Build rich blocks
        List<Map<String, Object>> blocks = new List<Map<String, Object>>();

        // Header block
        Map<String, Object> headerBlock = new Map<String, Object>();
        headerBlock.put('type', 'header');
        Map<String, Object> headerText = new Map<String, Object>();
        headerText.put('type', 'plain_text');
        headerText.put(
            'text',
            emoji +
            ' ' +
            evt.Metric__c +
            ' Performance Alert'
        );
        headerBlock.put('text', headerText);
        blocks.add(headerBlock);

        // Divider
        blocks.add(new Map<String, Object>{ 'type' => 'divider' });

        // Main info section
        Map<String, Object> infoSection = new Map<String, Object>();
        infoSection.put('type', 'section');
        List<Map<String, Object>> fields = new List<Map<String, Object>>();

        // Current Value
        Map<String, Object> valueField = new Map<String, Object>();
        valueField.put('type', 'mrkdwn');
        valueField.put(
            'text',
            '*Current Value:*\n' +
            String.valueOf(evt.Value__c.setScale(0)) +
            ' (' +
            percentOfLimit.setScale(1) +
            '%)'
        );
        fields.add(valueField);

        // Threshold
        Map<String, Object> thresholdField = new Map<String, Object>();
        thresholdField.put('type', 'mrkdwn');
        thresholdField.put(
            'text',
            '*Threshold:*\n' +
            String.valueOf(evt.Threshold__c.setScale(0))
        );
        fields.add(thresholdField);

        // Metric Type
        Map<String, Object> metricField = new Map<String, Object>();
        metricField.put('type', 'mrkdwn');
        metricField.put('text', '*Metric:*\n' + evt.Metric__c);
        fields.add(metricField);

        // Context Record (if available)
        if (!String.isBlank(evt.Context_Record__c)) {
            Map<String, Object> contextField = new Map<String, Object>();
            contextField.put('type', 'mrkdwn');
            contextField.put('text', '*Context:*\n' + evt.Context_Record__c);
            fields.add(contextField);
        }

        infoSection.put('fields', fields);
        blocks.add(infoSection);

        // Stack trace context (if available)
        if (!String.isBlank(evt.Stack__c)) {
            Map<String, Object> stackSection = new Map<String, Object>();
            stackSection.put('type', 'section');
            Map<String, Object> stackText = new Map<String, Object>();
            stackText.put('type', 'mrkdwn');
            stackText.put('text', '*Details:*\n```' + evt.Stack__c + '```');
            stackSection.put('text', stackText);
            blocks.add(stackSection);
        }

        // Divider before actions
        blocks.add(new Map<String, Object>{ 'type' => 'divider' });

        // Action buttons (if Salesforce URL is available)
        String orgUrl = URL.getOrgDomainUrl().toExternalForm();
        Map<String, Object> actionsBlock = new Map<String, Object>();
        actionsBlock.put('type', 'actions');
        List<Map<String, Object>> elements = new List<Map<String, Object>>();

        // View Dashboard button
        Map<String, Object> dashboardButton = new Map<String, Object>();
        dashboardButton.put('type', 'button');
        Map<String, Object> dashboardText = new Map<String, Object>();
        dashboardText.put('type', 'plain_text');
        dashboardText.put('text', '📊 View Dashboard');
        dashboardButton.put('text', dashboardText);
        dashboardButton.put('url', orgUrl + '/lightning/page/home');
        elements.add(dashboardButton);

        actionsBlock.put('elements', elements);
        blocks.add(actionsBlock);

        // Add blocks and attachments to payload
        payload.put('blocks', blocks);

        // Add attachment for color bar
        List<Map<String, Object>> attachments = new List<Map<String, Object>>();
        Map<String, Object> attachment = new Map<String, Object>();
        attachment.put('color', color);
        attachment.put(
            'footer',
            'Prometheion | ' +
            Datetime.now().format('yyyy-MM-dd HH:mm:ss')
        );
        attachments.add(attachment);
        payload.put('attachments', attachments);

        return JSON.serialize(payload);
    }

    // Build Slack notification for Flow performance issues
    public static void notifyFlowPerformance(
        String flowName,
        Decimal cpuTime,
        String rating,
        Decimal percentileRank
    ) {
        Map<String, Object> payload = new Map<String, Object>();

        String emoji = rating == 'Critical' ? '🔴' : rating == 'Slow' ? '🟡' : 'ℹ️';

        payload.put('text', emoji + ' Flow Performance Alert: ' + flowName);

        List<Map<String, Object>> blocks = new List<Map<String, Object>>();

        // Header
        Map<String, Object> headerBlock = new Map<String, Object>();
        headerBlock.put('type', 'header');
        Map<String, Object> headerText = new Map<String, Object>();
        headerText.put('type', 'plain_text');
        headerText.put('text', emoji + ' Flow Performance: ' + flowName);
        headerBlock.put('text', headerText);
        blocks.add(headerBlock);

        blocks.add(new Map<String, Object>{ 'type' => 'divider' });

        // Info section
        Map<String, Object> infoSection = new Map<String, Object>();
        infoSection.put('type', 'section');
        List<Map<String, Object>> fields = new List<Map<String, Object>>();

        Map<String, Object> cpuField = new Map<String, Object>();
        cpuField.put('type', 'mrkdwn');
        cpuField.put('text', '*CPU Time:*\n' + cpuTime.setScale(0) + 'ms');
        fields.add(cpuField);

        Map<String, Object> ratingField = new Map<String, Object>();
        ratingField.put('type', 'mrkdwn');
        ratingField.put('text', '*Rating:*\n' + rating);
        fields.add(ratingField);

        if (percentileRank != null) {
            Map<String, Object> percentileField = new Map<String, Object>();
            percentileField.put('type', 'mrkdwn');
            percentileField.put(
                'text',
                '*Percentile:*\n' +
                percentileRank.setScale(1) +
                'th'
            );
            fields.add(percentileField);
        }

        infoSection.put('fields', fields);
        blocks.add(infoSection);

        payload.put('blocks', blocks);

        notifyRichAsync(JSON.serialize(payload));
    }
}
