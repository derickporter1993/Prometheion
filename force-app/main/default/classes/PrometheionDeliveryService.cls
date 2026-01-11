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
    public static void deliverAuditPackage(String packageId, List&lt;String&gt; recipientEmails) {
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
            List&lt;Messaging.SingleEmailMessage&gt; emails = new List&lt;Messaging.SingleEmailMessage&gt;();
            
            for (String email : recipientEmails) {
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setToAddresses(new List&lt;String&gt;{ email });
                message.setSubject('Audit Package: ' + pkg.Package_Name__c + ' (' + pkg.Framework__c + ')');
                message.setPlainTextBody(buildEmailBody(pkg));
                message.setHtmlBody(buildHtmlEmailBody(pkg));
                
                // Attach PDF
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(cv.Title + '.pdf');
                attachment.setBody(cv.VersionData);
                attachment.setContentType('application/pdf');
                message.setFileAttachments(new List&lt;Messaging.EmailFileAttachment&gt;{ attachment });
                
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
    public static Id scheduleRecurringDelivery(String packageId, String cronExpression, List&lt;String&gt; recipientEmails) {
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
        
        if (expirationDays == null || expirationDays &lt; 1) {
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
            Map&lt;String, Object&gt; slackMessage = buildSlackMessage(pkg, channel);
            
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
    public static List&lt;Map&lt;String, Object&gt;&gt; getDeliveryHistory(String packageId) {
        List&lt;Map&lt;String, Object&gt;&gt; history = new List&lt;Map&lt;String, Object&gt;&gt;();
        
        // Query ContentDistribution records
        List&lt;ContentDocumentLink&gt; links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :packageId
        ];
        
        Set&lt;Id&gt; docIds = new Set&lt;Id&gt;();
        for (ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }
        
        if (!docIds.isEmpty()) {
            List&lt;ContentDistribution&gt; distributions = [
                SELECT Id, Name, DistributionPublicUrl, ExpiryDate, 
                       FirstViewDate, LastViewDate, ViewCount, CreatedDate
                FROM ContentDistribution
                WHERE ContentDocumentId IN :docIds
                ORDER BY CreatedDate DESC
            ];
            
            for (ContentDistribution cd : distributions) {
                history.add(new Map&lt;String, Object&gt;{
                    'id' =&gt; cd.Id,
                    'name' =&gt; cd.Name,
                    'url' =&gt; cd.DistributionPublicUrl,
                    'expiryDate' =&gt; cd.ExpiryDate,
                    'firstViewDate' =&gt; cd.FirstViewDate,
                    'lastViewDate' =&gt; cd.LastViewDate,
                    'viewCount' =&gt; cd.ViewCount,
                    'createdDate' =&gt; cd.CreatedDate
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
        return '&lt;html&gt;&lt;body style="font-family: Arial, sans-serif;"&gt;' +
               '&lt;div style="background-color: #032d60; color: white; padding: 20px;"&gt;' +
               '&lt;h1 style="margin: 0;"&gt;Audit Package Delivery&lt;/h1&gt;' +
               '&lt;/div&gt;' +
               '&lt;div style="padding: 20px;"&gt;' +
               '&lt;table style="border-collapse: collapse; width: 100%;"&gt;' +
               '&lt;tr&gt;&lt;td style="padding: 10px; border-bottom: 1px solid #ddd;"&gt;&lt;strong&gt;Package:&lt;/strong&gt;&lt;/td&gt;' +
               '&lt;td style="padding: 10px; border-bottom: 1px solid #ddd;"&gt;' + pkg.Package_Name__c + '&lt;/td&gt;&lt;/tr&gt;' +
               '&lt;tr&gt;&lt;td style="padding: 10px; border-bottom: 1px solid #ddd;"&gt;&lt;strong&gt;Framework:&lt;/strong&gt;&lt;/td&gt;' +
               '&lt;td style="padding: 10px; border-bottom: 1px solid #ddd;"&gt;' + pkg.Framework__c + '&lt;/td&gt;&lt;/tr&gt;' +
               '&lt;tr&gt;&lt;td style="padding: 10px; border-bottom: 1px solid #ddd;"&gt;&lt;strong&gt;Status:&lt;/strong&gt;&lt;/td&gt;' +
               '&lt;td style="padding: 10px; border-bottom: 1px solid #ddd;"&gt;' + pkg.Status__c + '&lt;/td&gt;&lt;/tr&gt;' +
               '&lt;/table&gt;' +
               '&lt;p&gt;Please find the attached audit package PDF.&lt;/p&gt;' +
               '&lt;/div&gt;' +
               '&lt;div style="background-color: #f5f5f5; padding: 10px; font-size: 12px; color: #666;"&gt;' +
               'This is an automated message from Prometheion Compliance Platform.' +
               '&lt;/div&gt;' +
               '&lt;/body&gt;&lt;/html&gt;';
    }
    
    /**
     * @description Build Slack Block Kit message
     * @param pkg The audit package
     * @param channel The Slack channel
     * @return Slack message object
     */
    private static Map&lt;String, Object&gt; buildSlackMessage(Prometheion_Audit_Package__c pkg, String channel) {
        List&lt;Object&gt; blocks = new List&lt;Object&gt;{
            new Map&lt;String, Object&gt;{
                'type' =&gt; 'header',
                'text' =&gt; new Map&lt;String, Object&gt;{
                    'type' =&gt; 'plain_text',
                    'text' =&gt; '📋 Audit Package Generated',
                    'emoji' =&gt; true
                }
            },
            new Map&lt;String, Object&gt;{
                'type' =&gt; 'section',
                'fields' =&gt; new List&lt;Object&gt;{
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'mrkdwn',
                        'text' =&gt; '*Package:*\n' + pkg.Package_Name__c
                    },
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'mrkdwn',
                        'text' =&gt; '*Framework:*\n' + pkg.Framework__c
                    },
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'mrkdwn',
                        'text' =&gt; '*Status:*\n' + pkg.Status__c
                    },
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'mrkdwn',
                        'text' =&gt; '*Generated:*\n' + Datetime.now().format()
                    }
                }
            },
            new Map&lt;String, Object&gt;{
                'type' =&gt; 'divider'
            },
            new Map&lt;String, Object&gt;{
                'type' =&gt; 'context',
                'elements' =&gt; new List&lt;Object&gt;{
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'mrkdwn',
                        'text' =&gt; 'Sent from *Prometheion Compliance Platform*'
                    }
                }
            }
        };
        
        return new Map&lt;String, Object&gt;{
            'channel' =&gt; channel,
            'blocks' =&gt; blocks
        };
    }
}
