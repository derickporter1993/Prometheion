# Elaro Compliance Hub - Admin Guide

This guide is for system administrators responsible for configuring, managing, and maintaining Elaro Compliance Hub in your Salesforce org.

---

## Table of Contents

1. [Initial Setup](#1-initial-setup)
2. [Permission Management](#2-permission-management)
3. [Scheduled Jobs Management](#3-scheduled-jobs-management)
4. [Integration Configuration](#4-integration-configuration)
5. [Custom Metadata Configuration](#5-custom-metadata-configuration)
6. [Maintenance Tasks](#6-maintenance-tasks)
7. [Security Best Practices](#7-security-best-practices)

---

## 1. Initial Setup

### Post-Installation Checklist

After deploying Elaro to your org, complete these setup tasks:

- [ ] Assign permission sets to administrators
- [ ] Configure Named Credentials for external integrations
- [ ] Set up Custom Metadata records for schedulers
- [ ] Configure alert thresholds and rules
- [ ] Test scheduled job execution
- [ ] Verify integration connectivity (Slack, Teams, etc.)
- [ ] Review and adjust security settings
- [ ] Set up initial compliance framework assessments

### Named Credential Configuration

Elaro requires Named Credentials for external API integrations.

#### Claude API Named Credential

Required for AI Copilot functionality:

1. Navigate to **Setup** → **Named Credentials**
2. Find **"Elaro_Claude_API"**
3. Click **Edit**
4. Configure:
   - **URL**: `https://api.anthropic.com`
   - **Identity Type**: Named Principal
   - **Authentication Protocol**: OAuth 2.0 (or API Key)
   - **API Key**: Enter your Claude API key
5. Click **Save**

**Security Note**: Store API keys securely. Consider using Protected Custom Settings or Secure Storage for sensitive credentials.

#### Slack Webhook Configuration

For Slack notifications:

1. Create a Slack Incoming Webhook in your Slack workspace
2. Navigate to **Setup** → **Named Credentials**
3. Create new Named Credential:
   - **Label**: `Elaro_Slack_Webhook`
   - **URL**: Your Slack webhook URL
   - **Identity Type**: Anonymous
4. Update `SlackNotifier` class to use this Named Credential

### External Service Setup

**Claude AI Service**
- Sign up for Anthropic Claude API access
- Obtain API key from Anthropic dashboard
- Configure rate limits and usage monitoring

**Slack Workspace**
- Create dedicated channel for compliance alerts (e.g., `#compliance-alerts`)
- Set up Incoming Webhook for the channel
- Test webhook connectivity

**Microsoft Teams** (if using)
- Create Teams webhook connector
- Configure channel for notifications
- Test webhook URL

---

## 2. Permission Management

Elaro includes two permission sets for role-based access control.

### Permission Sets Overview

#### Elaro_Admin

**Purpose**: Standard administrator access for day-to-day compliance management

**Permissions Include**:
- Read/Edit access to all Elaro custom objects
- View All Records on compliance objects
- Access to all Elaro Apex classes
- Ability to run assessments and generate reports
- Access to AI Copilot

**Use Case**: Compliance managers, security analysts, and administrators who need full operational access.

#### Elaro_Admin_Extended

**Purpose**: Extended permissions for system configuration and advanced features

**Additional Permissions**:
- Modify access to scheduler configurations
- Access to integration settings
- Ability to modify Custom Metadata (via Apex)
- Extended object permissions for audit operations

**Use Case**: System administrators who configure and maintain Elaro.

**Security Note**: `Elaro_Admin_Extended` does NOT include `modifyAllRecords` permissions. This follows the principle of least privilege.

### Assigning Permissions to Users

#### Via Setup UI

1. Navigate to **Setup** → **Users** → **Permission Sets**
2. Find **"Elaro_Admin"** or **"Elaro_Admin_Extended"**
3. Click **Manage Assignments**
4. Click **Add Assignments**
5. Select users to assign
6. Click **Assign**

#### Via Salesforce CLI

```bash
# Assign Elaro_Admin to a user
sf org assign permset \
  --name Elaro_Admin \
  --target-org myorg \
  --target-username user@example.com

# Assign Elaro_Admin_Extended
sf org assign permset \
  --name Elaro_Admin_Extended \
  --target-org myorg \
  --target-username admin@example.com
```

### Object-Level vs Field-Level Security

**Object-Level Security** is managed through permission sets:
- Which objects users can access
- CRUD permissions (Create, Read, Update, Delete)
- Record-level visibility (View All, Modify All)

**Field-Level Security** considerations:
- Sensitive fields (e.g., API keys, audit logs) should have restricted access
- Use Field-Level Security (FLS) profiles or permission sets
- Review field accessibility in Apex classes (use `WITH USER_MODE` or `WITH SYSTEM_MODE`)

**Best Practice**: Grant minimum necessary permissions. Start with `Elaro_Admin` and only upgrade to `Elaro_Admin_Extended` when configuration access is required.

---

## 3. Scheduled Jobs Management

Elaro includes several scheduled jobs for automated compliance monitoring.

### Available Schedulers

#### CCPA SLA Monitor
- **Frequency**: Daily at 8:00 AM
- **Purpose**: Monitors CCPA consumer request deadlines and sends alerts for approaching/overdue requests
- **Custom Metadata**: `CCPASLAMonitor`
- **CRON Expression**: `0 0 8 * * ?` (configurable)

#### Dormant Account Alert
- **Frequency**: Daily at 5:00 AM
- **Purpose**: Identifies inactive user accounts (90+ days) and generates security reports
- **Custom Metadata**: `DormantAccountAlert`
- **CRON Expression**: `0 0 5 * * ?` (configurable)
- **Batch Size**: 500 records (configurable)

#### GLBA Annual Notice
- **Frequency**: Daily at 6:00 AM (runs only on business days)
- **Purpose**: Sends annual privacy notices to customers as required by GLBA
- **Custom Metadata**: `GLBAAnnualNotice`
- **CRON Expression**: `0 0 6 * * ?` (configurable)
- **Batch Size**: 200 records (configurable)

#### ISO 27001 Quarterly Review
- **Frequency**: Quarterly (first day of each quarter at 7:00 AM)
- **Purpose**: Initiates quarterly access reviews for ISO 27001 compliance
- **Custom Metadata**: `ISO27001QuarterlyReview`
- **CRON Expression**: `0 0 7 1 1,4,7,10 ?` (configurable)

#### Weekly Scorecard
- **Frequency**: Weekly on Mondays at 9:00 AM
- **Purpose**: Generates and distributes weekly compliance scorecard reports
- **Custom Metadata**: `WeeklyScorecard`
- **CRON Expression**: `0 0 9 ? * MON *` (configurable)

### Configuring via Custom Metadata

Scheduler configurations are managed through `Elaro_Scheduler_Config__mdt` Custom Metadata Type.

#### Accessing Custom Metadata

1. Navigate to **Setup** → **Custom Metadata Types**
2. Find **"Elaro Scheduler Config"**
3. Click **Manage Records**
4. Select the scheduler you want to configure

#### Configuration Fields

- **Scheduler Name**: Unique identifier (e.g., `CCPASLAMonitor`)
- **CRON Expression**: Schedule pattern (e.g., `0 0 8 * * ?` for daily at 8 AM)
- **Batch Size**: Number of records to process per batch (for batchable jobs)
- **Is Active**: Enable/disable the scheduler
- **Description**: Human-readable description of the scheduler

#### Example: Configuring CCPA SLA Monitor

1. Open **"CCPASLAMonitor"** Custom Metadata record
2. Update **CRON Expression** if needed (default: `0 0 8 * * ?`)
3. Ensure **Is Active** is checked
4. Click **Save**

**CRON Expression Reference**:
```
Format: Second Minute Hour Day Month DayOfWeek Year
Example: 0 0 8 * * ? = Daily at 8:00 AM
Example: 0 0 7 1 1,4,7,10 ? = First day of each quarter at 7:00 AM
```

### Monitoring Job Execution

#### Via Setup UI

1. Navigate to **Setup** → **Apex Jobs**
2. Filter by job type: **"Scheduled Apex"**
3. View job status, execution time, and errors

#### Via Developer Console

1. Open **Developer Console**
2. Navigate to **Debug** → **Apex Jobs**
3. View detailed execution logs

#### Error Monitoring

Elaro logs scheduler errors to `Integration_Error__c`:

1. Navigate to **Integration Errors** tab (if available)
2. Filter by **Error Type**: `SCHEDULER_FAILURE`
3. Review error messages and stack traces
4. Check Slack notifications for real-time alerts

**Common Issues**:
- **Job Not Running**: Check `Is_Active__c` in Custom Metadata
- **CRON Invalid**: Verify CRON expression syntax
- **Batch Failures**: Review batch size and governor limits
- **Permission Errors**: Ensure running user has necessary permissions

---

## 4. Integration Configuration

### Slack Integration Setup

#### Named Credential Creation

1. Navigate to **Setup** → **Named Credentials**
2. Click **New**
3. Configure:
   - **Label**: `Elaro_Slack_Webhook`
   - **Name**: `Elaro_Slack_Webhook`
   - **URL**: Your Slack Incoming Webhook URL
   - **Identity Type**: Anonymous
4. Click **Save**

#### Channel Configuration

1. In your Slack workspace, create a channel (e.g., `#compliance-alerts`)
2. Add the Elaro app/bot to the channel
3. Configure webhook to post to this channel

#### Test Notification

Use Anonymous Apex to test:

```apex
// Test Slack notification
SlackNotifier.notifyAsyncQueueable('Test notification from Elaro');
```

Check your Slack channel for the test message.

### Microsoft Teams Integration

#### Webhook URL Setup

1. In Microsoft Teams, create a channel
2. Add an **Incoming Webhook** connector:
   - Click channel **...** → **Connectors**
   - Find **Incoming Webhook**
   - Click **Configure**
   - Copy the webhook URL
3. Store webhook URL in Custom Settings or Named Credential

#### Channel Mapping

Configure which Teams channels receive which alert types:

1. Navigate to **Elaro AI Settings** (if available)
2. Configure Teams webhook URL
3. Map alert types to channels:
   - Critical alerts → `#compliance-critical`
   - Warning alerts → `#compliance-warnings`
   - Info alerts → `#compliance-info`

### PagerDuty Integration

1. Create a PagerDuty service for Elaro
2. Obtain integration key or webhook URL
3. Configure in `PagerDutyIntegration` class
4. Test with sample alert

### ServiceNow Integration

1. Create ServiceNow API user with appropriate permissions
2. Configure Named Credential for ServiceNow instance
3. Set up integration mapping (Elaro alerts → ServiceNow incidents)
4. Test incident creation

---

## 5. Custom Metadata Configuration

### Elaro_Scheduler_Config__mdt

Manages scheduler configurations (CRON expressions, batch sizes, active status).

**Records**:
- `CCPASLAMonitor`: CCPA SLA monitoring
- `DormantAccountAlert`: Dormant account detection
- `GLBAAnnualNotice`: GLBA annual notices
- `ISO27001QuarterlyReview`: ISO 27001 quarterly reviews
- `WeeklyScorecard`: Weekly scorecard generation

**Configuration Steps**:
1. Navigate to **Setup** → **Custom Metadata Types** → **Elaro Scheduler Config**
2. Click **Manage Records**
3. Edit the desired scheduler record
4. Update fields as needed
5. Save changes

**Note**: Changes to Custom Metadata require a deployment or manual update in the org.

### Compliance_Policy__mdt

Defines compliance policies and controls for each framework.

**Access**:
1. Navigate to **Setup** → **Custom Metadata Types** → **Compliance Policy**
2. View or edit policy records

**Policy Fields**:
- Policy name and description
- Framework association
- Control requirements
- Evidence requirements
- Remediation guidance

### Alert Thresholds and Rules

Configure alert thresholds via `Elaro_Alert_Config__c` custom object:

1. Navigate to **Elaro Alert Config** tab
2. Create or edit alert configuration records
3. Configure:
   - **Alert Type**: Type of alert (e.g., `GAP_DETECTED`, `DEADLINE_APPROACHING`)
   - **Framework**: Associated compliance framework
   - **Severity**: Alert severity level
   - **Threshold**: Trigger threshold value
   - **Channels**: Notification channels (Slack, Teams, Email)
   - **Is Active**: Enable/disable the alert rule

---

## 6. Maintenance Tasks

### Log Cleanup Procedures

Elaro generates logs in `Integration_Error__c` for error tracking.

#### Regular Cleanup

**Recommended Frequency**: Monthly

1. Navigate to **Integration Errors** (or query `Integration_Error__c`)
2. Filter by date (older than 90 days)
3. Export logs if needed for compliance
4. Delete old records

**Anonymous Apex Cleanup Script**:
```apex
// Delete Integration_Error__c records older than 90 days
Date cutoffDate = Date.today().addDays(-90);
List<Integration_Error__c> oldErrors = [
    SELECT Id FROM Integration_Error__c
    WHERE Timestamp__c < :cutoffDate
    LIMIT 10000
];
delete oldErrors;
```

#### Performance Monitoring

Monitor system performance:

1. **Apex Jobs**: Review scheduled job execution times
2. **API Usage**: Monitor API call consumption
3. **Database**: Check SOQL query performance
4. **Storage**: Monitor data storage usage

**Tools**:
- **Setup** → **Apex Jobs**: View job execution
- **Developer Console** → **Logs**: Analyze execution details
- **Setup** → **System Overview**: Monitor org health

### Backup Recommendations

**Critical Data to Backup**:
- Compliance assessment results
- Evidence packages
- Audit logs
- Custom Metadata configurations
- Alert configurations

**Backup Methods**:
1. **Salesforce Data Export**: Monthly full export
2. **Salesforce Files**: Backup evidence documents
3. **Version Control**: Backup Custom Metadata via SFDX
4. **External Storage**: Archive evidence packages to secure storage

### Troubleshooting Common Issues

#### Scheduler Not Running

**Symptoms**: Scheduled job doesn't execute

**Solutions**:
1. Check `Is_Active__c` in Custom Metadata
2. Verify CRON expression syntax
3. Check Apex Jobs for error messages
4. Ensure running user has permissions
5. Review `Integration_Error__c` for scheduler failures

#### Integration Failures

**Symptoms**: Slack/Teams notifications not working

**Solutions**:
1. Verify Named Credential configuration
2. Test webhook URL manually (curl/Postman)
3. Check network/firewall settings
4. Review `Integration_Error__c` for callout failures
5. Verify API keys/credentials are valid

#### Performance Issues

**Symptoms**: Slow dashboard loading, timeouts

**Solutions**:
1. Review SOQL query performance
2. Check governor limit usage
3. Optimize batch sizes in Custom Metadata
4. Review Apex code for bulkification issues
5. Consider increasing batch job frequency

#### Permission Errors

**Symptoms**: Users can't access features

**Solutions**:
1. Verify permission set assignments
2. Check object-level permissions
3. Review field-level security
4. Ensure Apex classes are accessible
5. Check sharing rules if applicable

---

## 7. Security Best Practices

### Least Privilege Principle

**Guidelines**:
- Grant minimum necessary permissions
- Use `Elaro_Admin` for most users
- Reserve `Elaro_Admin_Extended` for system admins only
- Regularly audit permission assignments
- Remove permissions when users change roles

**Permission Audit**:
1. Run report on permission set assignments
2. Review quarterly
3. Remove unused assignments
4. Document exceptions

### Audit Trail Monitoring

Elaro maintains audit trails for:
- Compliance assessments
- Gap remediation actions
- Configuration changes
- User access

**Monitoring Steps**:
1. Review `Elaro_Audit_Log__c` records regularly
2. Set up alerts for critical changes
3. Export audit logs for compliance
4. Monitor for suspicious activity

### API Security Considerations

**Named Credentials**:
- Use Named Credentials instead of hardcoded credentials
- Rotate API keys regularly
- Use OAuth 2.0 where possible
- Store sensitive credentials securely

**Callout Security**:
- Validate all external API responses
- Implement retry logic with exponential backoff
- Monitor for failed callouts
- Set appropriate timeout values

**Rate Limiting**:
- Monitor API usage against limits
- Implement rate limiting in Apex
- Use queueable jobs for async callouts
- Cache responses where appropriate

### Data Protection

**Sensitive Data**:
- Encrypt sensitive compliance data at rest (Shield Platform Encryption)
- Use field-level encryption for PII/PHI
- Implement data masking in non-production orgs
- Follow data retention policies

**Access Controls**:
- Implement IP restrictions for admin access
- Use MFA for all admin users
- Monitor login history for anomalies
- Set session timeout policies

---

## Additional Resources

- **User Guide**: See [USER_GUIDE.md](USER_GUIDE.md) for end-user documentation
- **Setup Guide**: See [SETUP_GUIDE.md](SETUP_GUIDE.md) for installation instructions
- **Salesforce Documentation**: [Salesforce Help](https://help.salesforce.com)

---

*Last Updated: January 2026*
