/**
 * TeamsNotifier - Microsoft Teams Integration for Sentinel Alerts
 * 
 * Q1 2025 Priority 2 Feature (alongside Slack)
 * 
 * Sends rich notifications to Microsoft Teams channels via Incoming Webhooks.
 * Supports Adaptive Cards for interactive compliance alerts with approve/reject buttons.
 * 
 * @author Sentinel Enterprise
 * @version 1.0
 */
public with sharing class TeamsNotifier {
    
    /**
     * Send simple text notification to Teams
     */
    @future(callout=true)
    public static void notifyAsync(String text) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Teams_Webhook');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(new Map<String, Object>{ 'text' => text }));
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                System.debug(LoggingLevel.ERROR, 'Teams notify failed: ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Teams notify exception: ' + e.getMessage());
        }
    }
    
    /**
     * Send rich Adaptive Card notification to Teams
     */
    @future(callout=true)
    public static void notifyRichAsync(String jsonPayload) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Teams_Webhook');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonPayload);
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                System.debug(LoggingLevel.ERROR, 'Teams rich notify failed: ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Teams rich notify exception: ' + e.getMessage());
        }
    }
    
    /**
     * Send compliance alert with Adaptive Card
     */
    public static void notifyComplianceAlert(
        String title,
        String severity,
        String framework,
        String description,
        String nodeId,
        Decimal confidence
    ) {
        String payload = buildComplianceAlertCard(title, severity, framework, description, nodeId, confidence);
        notifyRichAsync(payload);
    }
    
    /**
     * Send auto-remediation notification
     */
    public static void notifyRemediation(SentinelRemediationEngine.RemediationResult result, String framework) {
        String payload = buildRemediationCard(result, framework);
        notifyRichAsync(payload);
    }
    
    /**
     * Build Adaptive Card for compliance alerts
     */
    private static String buildComplianceAlertCard(
        String title,
        String severity,
        String framework,
        String description,
        String nodeId,
        Decimal confidence
    ) {
        // Determine color based on severity
        String color = severity == 'CRITICAL' ? 'attention' : severity == 'HIGH' ? 'warning' : 'accent';
        String emoji = severity == 'CRITICAL' ? '🔴' : severity == 'HIGH' ? '🟡' : 'ℹ️';
        
        String orgUrl = URL.getOrgDomainUrl().toExternalForm();
        
        Map<String, Object> card = new Map<String, Object>{
            'type' => 'message',
            'attachments' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'contentType' => 'application/vnd.microsoft.card.adaptive',
                    'content' => new Map<String, Object>{
                        '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
                        'type' => 'AdaptiveCard',
                        'version' => '1.4',
                        'body' => new List<Map<String, Object>>{
                            // Header
                            new Map<String, Object>{
                                'type' => 'TextBlock',
                                'size' => 'Large',
                                'weight' => 'Bolder',
                                'text' => emoji + ' Sentinel Compliance Alert',
                                'color' => color
                            },
                            // Title
                            new Map<String, Object>{
                                'type' => 'TextBlock',
                                'text' => title,
                                'wrap' => true,
                                'weight' => 'Bolder'
                            },
                            // Facts
                            new Map<String, Object>{
                                'type' => 'FactSet',
                                'facts' => new List<Map<String, Object>>{
                                    new Map<String, Object>{'title' => 'Severity', 'value' => severity},
                                    new Map<String, Object>{'title' => 'Framework', 'value' => framework},
                                    new Map<String, Object>{'title' => 'Confidence', 'value' => (confidence * 100).setScale(1) + '%'}
                                }
                            },
                            // Description
                            new Map<String, Object>{
                                'type' => 'TextBlock',
                                'text' => description,
                                'wrap' => true
                            }
                        },
                        'actions' => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                'type' => 'Action.OpenUrl',
                                'title' => '📊 View in Sentinel',
                                'url' => orgUrl + '/lightning/page/home'
                            },
                            new Map<String, Object>{
                                'type' => 'Action.OpenUrl',
                                'title' => '✅ Approve',
                                'url' => orgUrl + '/apex/SentinelApprove?id=' + nodeId
                            }
                        }
                    }
                }
            }
        };
        
        return JSON.serialize(card);
    }
    
    /**
     * Build Adaptive Card for remediation notifications
     */
    private static String buildRemediationCard(SentinelRemediationEngine.RemediationResult result, String framework) {
        String orgUrl = URL.getOrgDomainUrl().toExternalForm();
        String emoji = result.success ? '🛡️' : '⚠️';
        String color = result.success ? 'good' : 'warning';
        
        Map<String, Object> card = new Map<String, Object>{
            'type' => 'message',
            'attachments' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'contentType' => 'application/vnd.microsoft.card.adaptive',
                    'content' => new Map<String, Object>{
                        '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
                        'type' => 'AdaptiveCard',
                        'version' => '1.4',
                        'body' => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                'type' => 'TextBlock',
                                'size' => 'Large',
                                'weight' => 'Bolder',
                                'text' => emoji + ' Sentinel Auto-Remediation',
                                'color' => color
                            },
                            new Map<String, Object>{
                                'type' => 'TextBlock',
                                'text' => result.success ? 'Violation automatically remediated' : 'Remediation requires manual review',
                                'wrap' => true,
                                'weight' => 'Bolder'
                            },
                            new Map<String, Object>{
                                'type' => 'FactSet',
                                'facts' => new List<Map<String, Object>>{
                                    new Map<String, Object>{'title' => 'Action', 'value' => result.action},
                                    new Map<String, Object>{'title' => 'Framework', 'value' => framework},
                                    new Map<String, Object>{'title' => 'Review Deadline', 'value' => result.reviewDeadline != null ? result.reviewDeadline.format() : 'N/A'}
                                }
                            },
                            new Map<String, Object>{
                                'type' => 'TextBlock',
                                'text' => result.message,
                                'wrap' => true
                            }
                        },
                        'actions' => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                'type' => 'Action.OpenUrl',
                                'title' => '✅ Approve',
                                'url' => orgUrl + '/apex/SentinelApprove?id=' + result.remediationId
                            },
                            new Map<String, Object>{
                                'type' => 'Action.OpenUrl',
                                'title' => '↩️ Rollback',
                                'url' => orgUrl + '/apex/SentinelRollback?id=' + result.remediationId
                            }
                        }
                    }
                }
            }
        };
        
        return JSON.serialize(card);
    }
    
    /**
     * Send weekly compliance scorecard
     */
    public static void sendWeeklyScorecard() {
        SentinelComplianceScorer.ScoreResult score = SentinelComplianceScorer.calculateReadinessScore();
        
        String emoji = score.overallScore >= 80 ? '🟢' : score.overallScore >= 60 ? '🟡' : '🔴';
        String orgUrl = URL.getOrgDomainUrl().toExternalForm();
        
        Map<String, Object> card = new Map<String, Object>{
            'type' => 'message',
            'attachments' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'contentType' => 'application/vnd.microsoft.card.adaptive',
                    'content' => new Map<String, Object>{
                        '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
                        'type' => 'AdaptiveCard',
                        'version' => '1.4',
                        'body' => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                'type' => 'TextBlock',
                                'size' => 'Large',
                                'weight' => 'Bolder',
                                'text' => emoji + ' Weekly Compliance Scorecard'
                            },
                            new Map<String, Object>{
                                'type' => 'TextBlock',
                                'size' => 'ExtraLarge',
                                'text' => String.valueOf(score.overallScore.setScale(0)) + '/100',
                                'horizontalAlignment' => 'Center',
                                'weight' => 'Bolder'
                            },
                            new Map<String, Object>{
                                'type' => 'FactSet',
                                'facts' => buildFrameworkFacts(score.frameworkScores)
                            }
                        },
                        'actions' => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                'type' => 'Action.OpenUrl',
                                'title' => '📊 View Full Report',
                                'url' => orgUrl + '/lightning/page/home'
                            }
                        }
                    }
                }
            }
        };
        
        notifyRichAsync(JSON.serialize(card));
    }
    
    private static List<Map<String, Object>> buildFrameworkFacts(Map<String, Decimal> scores) {
        List<Map<String, Object>> facts = new List<Map<String, Object>>();
        for (String framework : scores.keySet()) {
            facts.add(new Map<String, Object>{
                'title' => framework,
                'value' => scores.get(framework).setScale(0) + '/100'
            });
        }
        return facts;
    }
}
