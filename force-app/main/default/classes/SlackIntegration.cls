/**
 * @description Slack integration service for Elaro
 * Provides alert notifications, audit package sharing, and daily digest delivery
 * @group Integrations
 * @author Elaro Team
 */
public with sharing class SlackIntegration {
    
    private static final String NAMED_CREDENTIAL = 'callout:Slack_Webhook';
    
    /**
     * @description Send alert to Slack channel
     * @param alertData Alert data including severity, message, etc.
     */
    @future(callout=true)
    public static void sendAlert(String alertDataJson) {
        Map<String, Object> alertData = (Map<String, Object>)JSON.deserializeUntyped(alertDataJson);
        
        String severity = (String)alertData.get('severity');
        String color = getColorForSeverity(severity);
        
        Map<String, Object> message = new Map<String, Object>{
            'attachments' => new List<Object>{
                new Map<String, Object>{
                    'color' => color,
                    'blocks' => new List<Object>{
                        new Map<String, Object>{
                            'type' => 'header',
                            'text' => new Map<String, Object>{
                                'type' => 'plain_text',
                                'text' => '⚠️ Elaro Compliance Alert',
                                'emoji' => true
                            }
                        },
                        new Map<String, Object>{
                            'type' => 'section',
                            'fields' => new List<Object>{
                                new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Severity:*\n' + severity},
                                new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Alert ID:*\n' + alertData.get('alertId')},
                                new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Event Type:*\n' + alertData.get('eventType')},
                                new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Risk Score:*\n' + alertData.get('riskScore')}
                            }
                        },
                        new Map<String, Object>{
                            'type' => 'section',
                            'text' => new Map<String, Object>{
                                'type' => 'mrkdwn',
                                'text' => '*Details:*\n' + alertData.get('message')
                            }
                        },
                        new Map<String, Object>{
                            'type' => 'actions',
                            'elements' => new List<Object>{
                                new Map<String, Object>{
                                    'type' => 'button',
                                    'text' => new Map<String, Object>{'type' => 'plain_text', 'text' => 'View in Salesforce'},
                                    'url' => URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Elaro_Evidence_Item__c/' + alertData.get('eventId') + '/view'
                                }
                            }
                        }
                    }
                }
            }
        };
        
        sendToSlack(message);
    }
    
    /**
     * @description Send audit package notification to Slack
     * @param packageId Audit package ID
     * @param channel Slack channel name
     */
    @future(callout=true)
    public static void sendAuditPackageNotification(String packageId, String channel) {
        Elaro_Audit_Package__c pkg = [
            SELECT Id, Name, Package_Name__c, Framework__c, Status__c
            FROM Elaro_Audit_Package__c
            WHERE Id = :packageId
            LIMIT 1
        ];
        
        Map<String, Object> message = new Map<String, Object>{
            'channel' => channel,
            'blocks' => new List<Object>{
                new Map<String, Object>{
                    'type' => 'header',
                    'text' => new Map<String, Object>{
                        'type' => 'plain_text',
                        'text' => '📋 Audit Package Generated'
                    }
                },
                new Map<String, Object>{
                    'type' => 'section',
                    'fields' => new List<Object>{
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Package:*\n' + pkg.Package_Name__c},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Framework:*\n' + pkg.Framework__c},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Status:*\n' + pkg.Status__c},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Generated:*\n' + Datetime.now().format()}
                    }
                },
                new Map<String, Object>{
                    'type' => 'actions',
                    'elements' => new List<Object>{
                        new Map<String, Object>{
                            'type' => 'button',
                            'text' => new Map<String, Object>{'type' => 'plain_text', 'text' => 'View Package'},
                            'style' => 'primary',
                            'url' => URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Elaro_Audit_Package__c/' + packageId + '/view'
                        }
                    }
                }
            }
        };
        
        sendToSlack(message);
    }
    
    /**
     * @description Send daily digest to Slack
     * @param digestJson JSON serialized digest data
     */
    @future(callout=true)
    public static void sendDailyDigest(String digestJson) {
        Map<String, Object> digest = (Map<String, Object>)JSON.deserializeUntyped(digestJson);
        
        Map<String, Object> stats = (Map<String, Object>)digest.get('statistics');
        
        Map<String, Object> message = new Map<String, Object>{
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
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Compliance Score:*\n' + digest.get('complianceScore') + '%'},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Total Events:*\n' + stats.get('totalEvents')},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*High Risk:*\n' + stats.get('highRiskEvents')},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Resolved:*\n' + stats.get('resolvedEvents')}
                    }
                },
                new Map<String, Object>{
                    'type' => 'section',
                    'text' => new Map<String, Object>{
                        'type' => 'mrkdwn',
                        'text' => '*AI Summary:*\n' + digest.get('aiSummary')
                    }
                },
                new Map<String, Object>{
                    'type' => 'divider'
                },
                new Map<String, Object>{
                    'type' => 'context',
                    'elements' => new List<Object>{
                        new Map<String, Object>{
                            'type' => 'mrkdwn',
                            'text' => 'Sent by Elaro Compliance Platform'
                        }
                    }
                }
            }
        };
        
        sendToSlack(message);
    }
    
    /**
     * @description Send custom message to Slack
     * @param channel Channel name
     * @param text Message text
     */
    public static void sendMessage(String channel, String text) {
        Map<String, Object> message = new Map<String, Object>{
            'channel' => channel,
            'text' => text
        };
        
        sendToSlackImmediate(message);
    }
    
    private static void sendToSlack(Map<String, Object> message) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(message));
        req.setTimeout(30000);
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() != 200) {
                System.debug(LoggingLevel.ERROR, 'Slack send failed: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Slack integration error: ' + e.getMessage());
        }
    }
    
    private static void sendToSlackImmediate(Map<String, Object> message) {
        if (!System.isFuture() && !System.isBatch()) {
            sendToSlackFuture(JSON.serialize(message));
        } else {
            sendToSlack(message);
        }
    }
    
    @future(callout=true)
    private static void sendToSlackFuture(String messageJson) {
        Map<String, Object> message = (Map<String, Object>)JSON.deserializeUntyped(messageJson);
        sendToSlack(message);
    }
    
    private static String getColorForSeverity(String severity) {
        Map<String, String> colors = new Map<String, String>{
            'CRITICAL' => '#c23934',
            'HIGH' => '#e87722',
            'MEDIUM' => '#f7b924',
            'LOW' => '#4bca81',
            'INFO' => '#2196f3'
        };
        return colors.containsKey(severity) ? colors.get(severity) : '#666666';
    }
}
