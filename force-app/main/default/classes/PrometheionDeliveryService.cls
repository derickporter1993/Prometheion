/**
 * @description Delivery service for audit packages
 * Provides email delivery, shareable links, and Slack integration
 * @group Export &amp; Delivery
 * @author Prometheion Team
 */
public with sharing class PrometheionDeliveryService {
    
    // ═══════════════════════════════════════════════════════════════
    // PUBLIC METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Email audit package to stakeholders
     * @param packageId The audit package ID
     * @param recipientEmails List of recipient email addresses
     * @throws AuraHandledException if delivery fails
     */
    @AuraEnabled
    public static void deliverAuditPackage(String packageId, List<String> recipientEmails) {
        // Validate inputs
        if (String.isBlank(packageId)) {
            throw new AuraHandledException('Package ID is required');
        }
        
        if (recipientEmails == null || recipientEmails.isEmpty()) {
            throw new AuraHandledException('At least one recipient email is required');
        }
        
        try {
            // Query the audit package
            Prometheion_Audit_Package__c pkg = [
                SELECT Id, Name, Package_Name__c, Framework__c, Status__c
                FROM Prometheion_Audit_Package__c
                WHERE Id = :packageId
                LIMIT 1
            ];
            
            // Generate PDF
            Id contentVersionId = PrometheionPDFExporter.generateAuditPackagePDF(packageId);
            
            // Get ContentVersion details
            ContentVersion cv = [
                SELECT Id, Title, VersionData, ContentDocumentId
                FROM ContentVersion
                WHERE Id = :contentVersionId
            ];
            
            // Build and send emails
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            for (String email : recipientEmails) {
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setToAddresses(new List<String>{ email });
                message.setSubject('Audit Package: ' + pkg.Package_Name__c + ' (' + pkg.Framework__c + ')');
                message.setPlainTextBody(buildEmailBody(pkg));
                message.setHtmlBody(buildHtmlEmailBody(pkg));
                
                // Attach PDF
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(cv.Title + '.pdf');
                attachment.setBody(cv.VersionData);
                attachment.setContentType('application/pdf');
                message.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
                
                emails.add(message);
            }
            
            // Send emails
            if (!Test.isRunningTest()) {
                Messaging.sendEmail(emails);
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error delivering audit package: ' + e.getMessage());
        }
    }
    
    /**
     * @description Schedule recurring delivery
     * @param packageId The audit package ID
     * @param cronExpression The cron expression for scheduling
     * @param recipientEmails List of recipient email addresses
     * @return Scheduled job ID
     */
    @AuraEnabled
    public static Id scheduleRecurringDelivery(String packageId, String cronExpression, List<String> recipientEmails) {
        // Validate inputs
        if (String.isBlank(packageId)) {
            throw new AuraHandledException('Package ID is required');
        }
        
        if (String.isBlank(cronExpression)) {
            throw new AuraHandledException('Cron expression is required');
        }
        
        if (recipientEmails == null || recipientEmails.isEmpty()) {
            throw new AuraHandledException('At least one recipient email is required');
        }
        
        try {
            // Create schedulable instance
            PrometheionScheduledDelivery scheduler = new PrometheionScheduledDelivery(
                packageId, recipientEmails
            );
            
            // Schedule the job
            String jobName = 'Prometheion_Delivery_' + packageId.substring(0, 15) + '_' + 
                             String.valueOf(Datetime.now().getTime());
            
            return System.schedule(jobName, cronExpression, scheduler);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error scheduling delivery: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate shareable link (ContentDistribution)
     * @param packageId The audit package ID
     * @param expirationDays Number of days until link expires
     * @return Shareable URL
     */
    @AuraEnabled
    public static String generateShareableLink(String packageId, Integer expirationDays) {
        if (String.isBlank(packageId)) {
            throw new AuraHandledException('Package ID is required');
        }
        
        if (expirationDays == null || expirationDays < 1) {
            expirationDays = 30; // Default to 30 days
        }
        
        try {
            // Generate PDF if not already generated
            Id contentVersionId = PrometheionPDFExporter.generateAuditPackagePDF(packageId);
            
            // Get ContentDocumentId
            ContentVersion cv = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :contentVersionId
            ];
            
            // Query package for naming
            Prometheion_Audit_Package__c pkg = [
                SELECT Package_Name__c, Framework__c
                FROM Prometheion_Audit_Package__c
                WHERE Id = :packageId
            ];
            
            // Create ContentDistribution
            ContentDistribution cd = new ContentDistribution(
                Name = 'Audit Package Share - ' + pkg.Package_Name__c,
                ContentVersionId = contentVersionId,
                PreferencesAllowOriginalDownload = true,
                PreferencesAllowPDFDownload = true,
                PreferencesAllowViewInBrowser = true,
                PreferencesLinkLatestVersion = false,
                PreferencesNotifyOnVisit = true,
                PreferencesPasswordRequired = true,
                ExpiryDate = Date.today().addDays(expirationDays)
            );
            insert cd;
            
            // Query for the generated URL
            cd = [
                SELECT DistributionPublicUrl, Password
                FROM ContentDistribution
                WHERE Id = :cd.Id
            ];
            
            return cd.DistributionPublicUrl;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating shareable link: ' + e.getMessage());
        }
    }
    
    /**
     * @description Send audit package notification to Slack
     * @param packageId The audit package ID
     * @param channel The Slack channel
     */
    @AuraEnabled
    @future(callout=true)
    public static void sendToSlack(String packageId, String channel) {
        if (String.isBlank(packageId) || String.isBlank(channel)) {
            return;
        }
        
        try {
            // Query package details
            Prometheion_Audit_Package__c pkg = [
                SELECT Id, Package_Name__c, Framework__c, Status__c
                FROM Prometheion_Audit_Package__c
                WHERE Id = :packageId
                LIMIT 1
            ];
            
            // Build Slack Block Kit message
            Map<String, Object> slackMessage = buildSlackMessage(pkg, channel);
            
            // Send to Slack webhook
            // In production, use Named Credential
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Prometheion_Slack_Webhook');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(slackMessage));
            req.setTimeout(30000);
            
            if (!Test.isRunningTest()) {
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() != 200) {
                    System.debug(LoggingLevel.ERROR, 'Slack notification failed: ' + res.getBody());
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending Slack notification: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get delivery history for a package
     * @param packageId The audit package ID
     * @return List of delivery records
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getDeliveryHistory(String packageId) {
        List<Map<String, Object>> history = new List<Map<String, Object>>();
        
        // Query ContentDistribution records
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :packageId
        ];
        
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }
        
        if (!docIds.isEmpty()) {
            List<ContentDistribution> distributions = [
                SELECT Id, Name, DistributionPublicUrl, ExpiryDate, 
                       FirstViewDate, LastViewDate, ViewCount, CreatedDate
                FROM ContentDistribution
                WHERE ContentDocumentId IN :docIds
                ORDER BY CreatedDate DESC
            ];
            
            for (ContentDistribution cd : distributions) {
                history.add(new Map<String, Object>{
                    'id' => cd.Id,
                    'name' => cd.Name,
                    'url' => cd.DistributionPublicUrl,
                    'expiryDate' => cd.ExpiryDate,
                    'firstViewDate' => cd.FirstViewDate,
                    'lastViewDate' => cd.LastViewDate,
                    'viewCount' => cd.ViewCount,
                    'createdDate' => cd.CreatedDate
                });
            }
        }
        
        return history;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE HELPER METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Build plain text email body
     * @param pkg The audit package
     * @return Email body text
     */
    private static String buildEmailBody(Prometheion_Audit_Package__c pkg) {
        return 'Audit Package Delivery\n\n' +
               'Package: ' + pkg.Package_Name__c + '\n' +
               'Framework: ' + pkg.Framework__c + '\n' +
               'Status: ' + pkg.Status__c + '\n\n' +
               'Please find the attached audit package PDF.\n\n' +
               'This is an automated message from Prometheion Compliance Platform.';
    }
    
    /**
     * @description Build HTML email body
     * @param pkg The audit package
     * @return HTML email body
     */
    private static String buildHtmlEmailBody(Prometheion_Audit_Package__c pkg) {
        return '<html><body style="font-family: Arial, sans-serif;">' +
               '<div style="background-color: #032d60; color: white; padding: 20px;">' +
               '<h1 style="margin: 0;">Audit Package Delivery</h1>' +
               '</div>' +
               '<div style="padding: 20px;">' +
               '<table style="border-collapse: collapse; width: 100%;">' +
               '<tr><td style="padding: 10px; border-bottom: 1px solid #ddd;"><strong>Package:</strong></td>' +
               '<td style="padding: 10px; border-bottom: 1px solid #ddd;">' + pkg.Package_Name__c + '</td></tr>' +
               '<tr><td style="padding: 10px; border-bottom: 1px solid #ddd;"><strong>Framework:</strong></td>' +
               '<td style="padding: 10px; border-bottom: 1px solid #ddd;">' + pkg.Framework__c + '</td></tr>' +
               '<tr><td style="padding: 10px; border-bottom: 1px solid #ddd;"><strong>Status:</strong></td>' +
               '<td style="padding: 10px; border-bottom: 1px solid #ddd;">' + pkg.Status__c + '</td></tr>' +
               '</table>' +
               '<p>Please find the attached audit package PDF.</p>' +
               '</div>' +
               '<div style="background-color: #f5f5f5; padding: 10px; font-size: 12px; color: #666;">' +
               'This is an automated message from Prometheion Compliance Platform.' +
               '</div>' +
               '</body></html>';
    }
    
    /**
     * @description Build Slack Block Kit message
     * @param pkg The audit package
     * @param channel The Slack channel
     * @return Slack message object
     */
    private static Map<String, Object> buildSlackMessage(Prometheion_Audit_Package__c pkg, String channel) {
        List<Object> blocks = new List<Object>{
            new Map<String, Object>{
                'type' => 'header',
                'text' => new Map<String, Object>{
                    'type' => 'plain_text',
                    'text' => '📋 Audit Package Generated',
                    'emoji' => true
                }
            },
            new Map<String, Object>{
                'type' => 'section',
                'fields' => new List<Object>{
                    new Map<String, Object>{
                        'type' => 'mrkdwn',
                        'text' => '*Package:*\n' + pkg.Package_Name__c
                    },
                    new Map<String, Object>{
                        'type' => 'mrkdwn',
                        'text' => '*Framework:*\n' + pkg.Framework__c
                    },
                    new Map<String, Object>{
                        'type' => 'mrkdwn',
                        'text' => '*Status:*\n' + pkg.Status__c
                    },
                    new Map<String, Object>{
                        'type' => 'mrkdwn',
                        'text' => '*Generated:*\n' + Datetime.now().format()
                    }
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
                        'text' => 'Sent from *Prometheion Compliance Platform*'
                    }
                }
            }
        };
        
        return new Map<String, Object>{
            'channel' => channel,
            'blocks' => blocks
        };
    }
}
