/**
 * WeeklyScorecardScheduler - Automated Weekly Compliance Scorecard Notifications
 *
 * Sends weekly compliance scorecards to Slack and/or Teams channels.
 * Can be scheduled via Salesforce Scheduled Jobs or Flow Scheduler.
 *
 * Usage:
 * - Schedule via Setup → Apex → Schedule Apex
 * - Or call WeeklyScorecardScheduler.scheduleWeekly() to schedule programmatically
 *
 * @author Prometheion
 * @version 1.2
 */
public with sharing class WeeklyScorecardScheduler implements Schedulable {

    // Channel constants (using PrometheionConstants for consistency)
    public static final String SLACK = PrometheionConstants.CHANNEL_SLACK;
    public static final String TEAMS = PrometheionConstants.CHANNEL_TEAMS;
    public static final String BOTH = PrometheionConstants.CHANNEL_BOTH;

    // Logging prefix for easy log filtering
    private static final String LOG_PREFIX = '[WeeklyScorecardScheduler] ';

    /**
     * Execute method for Schedulable interface
     */
    public void execute(SchedulableContext ctx) {
        sendWeeklyScorecard(BOTH); // Default: send to both Slack and Teams
    }

    /**
     * Send weekly scorecard to specified channels
     * @param channel 'Slack', 'Teams', or 'Both'
     */
    public static void sendWeeklyScorecard(String channel) {
        System.debug(LoggingLevel.INFO, LOG_PREFIX + 'Starting weekly scorecard generation for channel: ' + channel);

        try {
            // Calculate current compliance score
            Long startTime = System.currentTimeMillis();
            PrometheionComplianceScorer.ScoreResult scoreResult = PrometheionComplianceScorer.calculateReadinessScore();
            Long duration = System.currentTimeMillis() - startTime;

            System.debug(LoggingLevel.INFO, LOG_PREFIX + 'Score calculation completed in ' + duration + 'ms. Score: ' + scoreResult.overallScore);

            // Validate score result
            if (scoreResult == null || scoreResult.overallScore == null) {
                throw new ScorecardException('Score calculation returned null result');
            }

            // Determine which channels to notify
            Boolean sendToSlack = channel == SLACK || channel == BOTH;
            Boolean sendToTeams = channel == TEAMS || channel == BOTH;

            if (sendToSlack) {
                System.debug(LoggingLevel.DEBUG, LOG_PREFIX + 'Sending to Slack...');
                sendSlackScorecard(scoreResult);
            }

            if (sendToTeams) {
                System.debug(LoggingLevel.DEBUG, LOG_PREFIX + 'Sending to Teams...');
                sendTeamsScorecard(scoreResult);
            }

            System.debug(LoggingLevel.INFO, LOG_PREFIX + 'Weekly scorecard sent successfully');

        } catch (Exception e) {
            // Safely handle null error messages (consistent with PrometheionComplianceCopilot)
            String errorMsg = String.isNotBlank(e.getMessage()) ? e.getMessage() : 'Unknown error';
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + 'Error: ' + errorMsg + '\n' + e.getStackTraceString());

            // Send error notification using custom label
            String formattedError = '❌ ' + Label.Scorecard_Error.replace('{0}', errorMsg);

            if (channel == SLACK || channel == BOTH) {
                SlackNotifier.notifyAsync(formattedError);
            }
            if (channel == TEAMS || channel == BOTH) {
                TeamsNotifier.notifyAsync(formattedError);
            }
        }
    }

    /**
     * Custom exception for scorecard errors
     */
    public class ScorecardException extends Exception {}

    /**
     * Send scorecard to Slack
     */
    private static void sendSlackScorecard(PrometheionComplianceScorer.ScoreResult scoreResult) {
        String emoji = getScoreEmoji(scoreResult.overallScore);
        String color = getScoreColor(scoreResult.overallScore);

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('text', emoji + ' ' + Label.Scorecard_Weekly_Title + ' - ' + scoreResult.overallScore.setScale(0) + '/100');

        List<Map<String, Object>> blocks = new List<Map<String, Object>>();

        // Header
        Map<String, Object> headerBlock = new Map<String, Object>();
        headerBlock.put('type', 'header');
        Map<String, Object> headerText = new Map<String, Object>();
        headerText.put('type', 'plain_text');
        headerText.put('text', emoji + ' ' + Label.Scorecard_Weekly_Title);
        headerBlock.put('text', headerText);
        blocks.add(headerBlock);

        blocks.add(new Map<String, Object>{ 'type' => 'divider' });

        // Overall Score
        Map<String, Object> scoreSection = new Map<String, Object>();
        scoreSection.put('type', 'section');
        Map<String, Object> scoreText = new Map<String, Object>();
        scoreText.put('type', 'mrkdwn');
        scoreText.put('text', '*' + Label.Scorecard_Overall_Score + '*\n' +
            '<!here> *' + scoreResult.overallScore.setScale(1) + '/100* (' + scoreResult.rating + ')');
        scoreSection.put('text', scoreText);
        blocks.add(scoreSection);

        blocks.add(new Map<String, Object>{ 'type' => 'divider' });

        // Framework Scores
        Map<String, Object> frameworkSection = new Map<String, Object>();
        frameworkSection.put('type', 'section');
        frameworkSection.put('text', new Map<String, Object>{
            'type' => 'mrkdwn',
            'text' => '*' + Label.Scorecard_Framework_Scores + '*'
        });
        List<Map<String, Object>> frameworkFields = new List<Map<String, Object>>();

        for (String framework : scoreResult.frameworkScores.keySet()) {
            Decimal frameworkScore = scoreResult.frameworkScores.get(framework);
            String frameworkEmoji = getScoreEmoji(frameworkScore);
            Map<String, Object> field = new Map<String, Object>();
            field.put('type', 'mrkdwn');
            field.put('text', frameworkEmoji + ' *' + framework + '*\n' + frameworkScore.setScale(1) + '/100');
            frameworkFields.add(field);
        }

        frameworkSection.put('fields', frameworkFields);
        blocks.add(frameworkSection);

        // Score Factors
        if (scoreResult.factors != null && !scoreResult.factors.isEmpty()) {
            blocks.add(new Map<String, Object>{ 'type' => 'divider' });

            Map<String, Object> factorsSection = new Map<String, Object>();
            factorsSection.put('type', 'section');
            factorsSection.put('text', new Map<String, Object>{
                'type' => 'mrkdwn',
                'text' => '*' + Label.Scorecard_Score_Breakdown + '*'
            });
            List<Map<String, Object>> factorFields = new List<Map<String, Object>>();

            for (PrometheionComplianceScorer.ScoreFactor factor : scoreResult.factors) {
                Map<String, Object> field = new Map<String, Object>();
                field.put('type', 'mrkdwn');
                field.put('text', '*' + factor.name + '*\n' + factor.score.setScale(0) + '/100 (' + factor.status + ')');
                factorFields.add(field);
            }

            factorsSection.put('fields', factorFields);
            blocks.add(factorsSection);
        }

        // Top Risks
        if (scoreResult.topRisks != null && !scoreResult.topRisks.isEmpty()) {
            blocks.add(new Map<String, Object>{ 'type' => 'divider' });

            Map<String, Object> risksSection = new Map<String, Object>();
            risksSection.put('type', 'section');
            risksSection.put('text', new Map<String, Object>{
                'type' => 'mrkdwn',
                'text' => '*⚠️ ' + Label.Scorecard_Top_Risks.replace('{0}', String.valueOf(scoreResult.topRisks.size())) + '*'
            });
            blocks.add(risksSection);

            for (PrometheionComplianceScorer.Risk risk : scoreResult.topRisks) {
                Map<String, Object> riskSection = new Map<String, Object>();
                riskSection.put('type', 'section');
                Map<String, Object> riskText = new Map<String, Object>();
                riskText.put('type', 'mrkdwn');
                riskText.put('text', '• *' + risk.title + '* (' + risk.severity + ')\n' +
                    risk.description + '\n_Framework: ' + risk.framework + '_');
                riskSection.put('text', riskText);
                blocks.add(riskSection);
            }
        }

        blocks.add(new Map<String, Object>{ 'type' => 'divider' });

        // Footer with action button
        String orgUrl = URL.getOrgDomainUrl().toExternalForm();
        Map<String, Object> actionsBlock = new Map<String, Object>();
        actionsBlock.put('type', 'actions');
        List<Map<String, Object>> elements = new List<Map<String, Object>>();

        Map<String, Object> viewButton = new Map<String, Object>();
        viewButton.put('type', 'button');
        viewButton.put('text', new Map<String, Object>{
            'type' => 'plain_text',
            'text' => '📊 ' + Label.Scorecard_View_Report
        });
        viewButton.put('url', orgUrl + '/lightning/page/home');
        elements.add(viewButton);

        actionsBlock.put('elements', elements);
        blocks.add(actionsBlock);

        payload.put('blocks', blocks);

        // Add attachment for color bar
        List<Map<String, Object>> attachments = new List<Map<String, Object>>();
        Map<String, Object> attachment = new Map<String, Object>();
        attachment.put('color', color);
        attachment.put('footer', 'Prometheion ' + Label.Scorecard_Weekly_Title + ' | ' + Datetime.now().format('yyyy-MM-dd'));
        attachments.add(attachment);
        payload.put('attachments', attachments);

        SlackNotifier.notifyRichAsync(JSON.serialize(payload));
    }

    /**
     * Send scorecard to Teams
     */
    private static void sendTeamsScorecard(PrometheionComplianceScorer.ScoreResult scoreResult) {
        // Use existing TeamsNotifier method
        TeamsNotifier.sendWeeklyScorecard();
    }

    /**
     * Get emoji based on score (using PrometheionConstants)
     */
    private static String getScoreEmoji(Decimal score) {
        return PrometheionConstants.getScoreEmoji(score);
    }

    /**
     * Get color hex code based on score (using PrometheionConstants)
     */
    private static String getScoreColor(Decimal score) {
        return PrometheionConstants.getScoreColor(score);
    }

    /**
     * Schedule weekly scorecard (runs every Monday at 9 AM)
     * @param channel 'Slack', 'Teams', or 'Both'
     */
    public static String scheduleWeekly(String channel) {
        // Calculate next Monday at 9 AM
        Datetime now = Datetime.now();
        // Get day of week (1=Sunday, 2=Monday, ..., 7=Saturday)
        Integer dayOfWeek = Integer.valueOf(now.format('u')); // ISO day of week (1=Monday, 7=Sunday)
        Integer daysUntilMonday = Math.mod(8 - dayOfWeek, 7);
        if (daysUntilMonday == 0 && now.hour() >= 9) {
            daysUntilMonday = 7; // If it's Monday after 9 AM, schedule for next Monday
        }

        Datetime nextRun = now.addDays(daysUntilMonday);
        nextRun = Datetime.newInstance(
            nextRun.year(),
            nextRun.month(),
            nextRun.day(),
            9, 0, 0
        );

        String jobName = 'Prometheion Weekly Scorecard - ' + channel + ' - ' + Datetime.now().format('yyyy-MM-dd');
        String cronExpression = getCronExpression(nextRun);

        WeeklyScorecardScheduler scheduler = new WeeklyScorecardScheduler();
        System.schedule(jobName, cronExpression, scheduler);

        String result = Label.Scorecard_Scheduled
            .replace('{0}', nextRun.format('yyyy-MM-dd HH:mm'))
            .replace('{1}', jobName);

        System.debug(LoggingLevel.INFO, LOG_PREFIX + result);
        return result;
    }

    /**
     * Generate cron expression for weekly schedule using Custom Metadata
     */
    private static String getCronExpression(Datetime dt) {
        // Get CRON from Custom Metadata, fallback to default
        // Format: second minute hour day_of_month month day_of_week year
        // For weekly: 0 0 9 ? * MON
        return SchedulerErrorHandler.getCronExpression('WeeklyScorecard', '0 0 9 ? * MON');
    }

    /**
     * Test method to send scorecard immediately
     */
    public static void sendTestScorecard() {
        sendWeeklyScorecard(BOTH);
    }
}
