public with sharing class SlackNotifier {

    /**
     * Send Slack notification using Queueable (recommended approach)
     * Provides retry logic, error handling, and better monitoring
     */
    public static void notifyAsyncQueueable(String text) {
        if (String.isBlank(text)) {
            System.debug(LoggingLevel.WARN, 'SlackNotifier: Empty text provided, skipping notification');
            return;
        }

        try {
            Map<String, Object> payload = new Map<String, Object>{ 'text' => text };
            String jsonPayload = JSON.serialize(payload);
            String correlationId = 'TEXT-' + System.now().getTime() + '-' + Crypto.getRandomInteger();

            PrometheionSlackNotifierQueueable job = new PrometheionSlackNotifierQueueable(jsonPayload, correlationId);
            System.enqueueJob(job);
        } catch (Exception e) {
            String correlationId = 'TEXT-ERROR-' + System.now().getTime();
            logIntegrationError('SLACK', 'Failed to enqueue notification', e.getMessage(), e.getStackTraceString(), correlationId, text);
            System.debug(LoggingLevel.ERROR, 'SlackNotifier: Failed to enqueue notification. CorrelationId: ' + correlationId + ', Error: ' + e.getMessage());
        }
    }


    /**
     * Send rich Slack notification using Queueable (recommended approach)
     * Provides retry logic, payload validation, and better error handling
     */
    public static void notifyRichAsyncQueueable(String jsonPayload) {
        if (String.isBlank(jsonPayload)) {
            System.debug(LoggingLevel.WARN, 'SlackNotifier: Empty payload provided, skipping notification');
            return;
        }

        try {
            // Validate JSON format
            JSON.deserializeUntyped(jsonPayload);

            String correlationId = 'RICH-' + System.now().getTime() + '-' + Crypto.getRandomInteger();
            PrometheionSlackNotifierQueueable job = new PrometheionSlackNotifierQueueable(jsonPayload, correlationId);
            System.enqueueJob(job);
        } catch (JSONException e) {
            String correlationId = 'RICH-ERROR-' + System.now().getTime();
            logIntegrationError('SLACK', 'Invalid JSON payload', e.getMessage(), e.getStackTraceString(), correlationId, jsonPayload);
            System.debug(LoggingLevel.ERROR, 'SlackNotifier: Invalid JSON payload. CorrelationId: ' + correlationId + ', Error: ' + e.getMessage());
        } catch (Exception e) {
            String correlationId = 'RICH-ERROR-' + System.now().getTime();
            logIntegrationError('SLACK', 'Failed to enqueue rich notification', e.getMessage(), e.getStackTraceString(), correlationId, jsonPayload);
            System.debug(LoggingLevel.ERROR, 'SlackNotifier: Failed to enqueue rich notification. CorrelationId: ' + correlationId + ', Error: ' + e.getMessage());
        }
    }

    /**
     * Notify about a performance event
     * Note: Performance_Alert__e platform event not available due to org limits.
     * Use notifyPerformanceAlert(String, Decimal, Decimal, String) instead.
     */
    public static void notifyPerformanceAlert(String metric, Decimal value, Decimal threshold, String contextRecord) {
        String jsonPayload = buildPerformanceAlertBlocks(metric, value, threshold, contextRecord, null);
        notifyRichAsyncQueueable(jsonPayload);
    }

    /**
     * Bulk notify for multiple performance events (trigger-safe)
     * Combines all events into a single future call to avoid governor limits
     * @param events List of performance alert events to notify
     */
    public static void notifyPerformanceEventsBulk(List<Performance_Alert__e> events) {
        if (events == null || events.isEmpty()) {
            return;
        }
        // Build all payloads and combine into single future call
        List<String> payloads = new List<String>();
        for (Performance_Alert__e evt : events) {
            payloads.add(buildPerformanceAlertBlocks(evt.Metric__c, evt.Value__c, evt.Threshold__c, evt.Context_Record__c, evt.Stack__c));
        }
        notifyBulkAsync(JSON.serialize(payloads));
    }

    @future(callout=true)
    public static void notifyBulkAsync(String serializedPayloads) {
        try {
            List<Object> payloads = (List<Object>) JSON.deserializeUntyped(serializedPayloads);
            for (Object payloadObj : payloads) {
                String jsonPayload = (String) payloadObj;
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:Slack_Webhook');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(jsonPayload);
                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                    System.debug(
                        LoggingLevel.ERROR,
                        'Slack bulk notify failed with status ' +
                            res.getStatusCode() +
                            ': ' +
                            res.getStatus()
                    );
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Slack bulk notify exception: ' + e.getMessage());
        }
    }

    // Build Slack Block Kit JSON for performance alerts (without platform event dependency)
    private static String buildPerformanceAlertBlocks(String metric, Decimal value, Decimal threshold, String contextRecord, String stack) {
        // Determine severity emoji and color
        String emoji = '⚠️';
        String color = '#ffb75d'; // Warning (orange)

        Decimal percentOfLimit = (value / threshold) * 100;

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
            metric +
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
            metric +
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
            String.valueOf(value.setScale(0)) +
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
            String.valueOf(threshold.setScale(0))
        );
        fields.add(thresholdField);

        // Metric Type
        Map<String, Object> metricField = new Map<String, Object>();
        metricField.put('type', 'mrkdwn');
        metricField.put('text', '*Metric:*\n' + metric);
        fields.add(metricField);

        // Context Record (if available)
        if (!String.isBlank(contextRecord)) {
            Map<String, Object> contextField = new Map<String, Object>();
            contextField.put('type', 'mrkdwn');
            contextField.put('text', '*Context:*\n' + contextRecord);
            fields.add(contextField);
        }

        infoSection.put('fields', fields);
        blocks.add(infoSection);

        // Stack trace context (if available) - truncate to prevent Slack limits
        if (!String.isBlank(stack)) {
            // Slack has a 3000 character limit per block, truncate if needed
            String stackTrace = stack;
            Integer maxLength = 2500; // Leave room for markdown formatting
            if (stackTrace.length() > maxLength) {
                stackTrace = stackTrace.substring(0, maxLength) + '\n... (truncated)';
            }
            
            Map<String, Object> stackSection = new Map<String, Object>();
            stackSection.put('type', 'section');
            Map<String, Object> stackText = new Map<String, Object>();
            stackText.put('type', 'mrkdwn');
            stackText.put('text', '*Details:*\n```' + stackTrace + '```');
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
        // Validate inputs
        if (String.isBlank(flowName)) {
            System.debug(LoggingLevel.WARN, 'SlackNotifier: Empty flowName provided, skipping notification');
            return;
        }
        if (cpuTime == null || cpuTime < 0) {
            System.debug(LoggingLevel.WARN, 'SlackNotifier: Invalid cpuTime provided, skipping notification');
            return;
        }
        if (String.isBlank(rating)) {
            rating = 'Unknown';
        }
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

        notifyRichAsyncQueueable(JSON.serialize(payload));
    }
    
    /**
     * Log integration errors to Integration_Error__c object for tracking and retry
     */
    private static void logIntegrationError(String errorType, String errorMessage, String stackTrace, String correlationId, String context) {
        logIntegrationError(errorType, errorMessage, stackTrace, correlationId, context, null);
    }
    
    private static void logIntegrationError(String errorType, String errorMessage, String stackTrace, String correlationId, String context, String additionalContext) {
        if (String.isBlank(errorMessage)) {
            errorMessage = 'Unknown error';
        }
        if (String.isBlank(stackTrace)) {
            stackTrace = '';
        }
        try {
            Integration_Error__c error = new Integration_Error__c(
                Error_Type__c = errorType,
                Error_Message__c = errorMessage,
                Stack_Trace__c = stackTrace,
                Correlation_Id__c = correlationId,
                Context__c = additionalContext != null ? context + '\n\nAdditional Context: ' + additionalContext : context,
                Status__c = 'NEW',
                Timestamp__c = System.now()
            );
            insert error;
        } catch (Exception e) {
            // Don't fail the main operation if error logging fails
            System.debug(LoggingLevel.ERROR, 'SlackNotifier: Failed to log integration error. Original error: ' + errorMessage + ', Logging error: ' + e.getMessage());
        }
    }
}
