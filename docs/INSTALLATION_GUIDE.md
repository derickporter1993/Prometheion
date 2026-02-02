# Elaro v3.0 Installation Guide

**Version:** 3.0
**Last Updated:** 2026-01-11
**Target Audience:** Salesforce Administrators
**Estimated Installation Time:** 30-45 minutes
**Post-Configuration Time:** 1-2 hours

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pre-Installation Checklist](#pre-installation-checklist)
3. [Installation Steps](#installation-steps)
4. [Post-Installation Configuration](#post-installation-configuration)
5. [Permission Set Assignment](#permission-set-assignment)
6. [Verification Steps](#verification-steps)
7. [Optional Integrations](#optional-integrations)
8. [Troubleshooting](#troubleshooting)
9. [Uninstallation](#uninstallation)
10. [Support](#support)

---

## Prerequisites

### Salesforce Edition Requirements

- **Salesforce Edition:** Enterprise, Unlimited, or Performance Edition
- **API Version:** 65.0 or higher
- **My Domain:** Enabled and deployed
- **Chatter:** Enabled (recommended for notifications)

### Technical Requirements

- **Storage:** ~50 MB data storage available
- **API Calls:** Sufficient API limits for compliance scanning (minimum 5,000 daily API calls recommended)
- **Governor Limits:** Standard Salesforce governor limits apply

### User Requirements

- **Installing User:** System Administrator profile
- **End Users:** Minimum of Standard User profile with assigned Elaro permission sets

### Optional Service Accounts

For full functionality, you may need accounts with:

- **Claude AI (Anthropic):** For AI-powered compliance analysis ([Sign up](https://www.anthropic.com))
- **Slack:** For real-time compliance alerts ([Slack Webhooks](https://api.slack.com/messaging/webhooks))
- **PagerDuty:** For incident management ([PagerDuty Events API](https://developer.pagerduty.com))
- **ServiceNow:** For GRC integration ([ServiceNow REST API](https://docs.servicenow.com))
- **Microsoft Teams:** For compliance notifications ([Teams Webhooks](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors))

---

## Pre-Installation Checklist

Before installing Elaro, complete these steps:

### 1. Review System Requirements

- [ ] Verify Salesforce edition supports managed packages
- [ ] Confirm My Domain is deployed
- [ ] Check available data and file storage
- [ ] Review API call limits

### 2. Backup Current Configuration

- [ ] Export current permission set assignments
- [ ] Document existing automation (flows, process builders)
- [ ] Backup custom metadata records (if any exist)
- [ ] Create org backup via Salesforce Backup tool

### 3. Plan User Access

- [ ] Identify users who need Elaro Admin access
- [ ] Identify users who need Elaro Auditor access
- [ ] Identify users who need Elaro AI access
- [ ] Identify users who need standard Elaro User access

### 4. Prepare External Service Credentials (Optional)

If you plan to use AI or external integrations:

- [ ] Obtain Claude AI API key from Anthropic
- [ ] Create Slack Incoming Webhook URL
- [ ] Obtain PagerDuty routing key
- [ ] Create ServiceNow integration user credentials
- [ ] Create Microsoft Teams webhook URL

---

## Installation Steps

### Step 1: Install the Managed Package

1. **Obtain Package Installation URL**
   - AppExchange listing: [Search "Elaro" on AppExchange]
   - Or use direct installation link provided by vendor

2. **Navigate to Installation URL**
   - Log in as System Administrator
   - Click **Continue** to proceed with installation

3. **Choose Installation Level**
   - Select **Install for Admins Only** (recommended for initial setup)
   - Or **Install for All Users** if permission sets are pre-configured

4. **Review Package Components**
   - Review Apex classes: ~207 classes (122 production + 85 test)
   - Review Lightning Web Components: 33 components
   - Review Custom Objects: 46 objects
   - Review Permission Sets: 5 permission sets
   - Click **Approve Third-Party Access** (required for Claude AI integration)

5. **Start Installation**
   - Click **Install**
   - Installation typically takes 5-10 minutes
   - You will receive email notification when complete

6. **Monitor Installation Progress**
   - Navigate to: **Setup → Installed Packages**
   - Verify **Elaro** appears with status **Installed**

### Step 2: Post-Install Handler Execution

After installation completes, the `ElaroInstallHandler` automatically executes:

**Automatic Configuration:**
- ✅ Creates default AI settings (AI disabled until you configure API key)
- ✅ Creates welcome audit log entry
- ✅ Posts Chatter notification with next steps (if Chatter enabled)
- ✅ Initializes custom metadata with safe defaults

**To Verify Post-Install Success:**

```apex
// Execute Anonymous Apex to verify
Elaro_AI_Settings__c settings = Elaro_AI_Settings__c.getOrgDefaults();
System.debug('AI Enabled: ' + settings.AI_Enabled__c); // Should be false
System.debug('Model: ' + settings.Model_Name__c); // Should be claude-sonnet-4-20250514

// Check audit logs
List<Elaro_Audit_Log__c> logs = [
    SELECT Id, Action__c, Description__c
    FROM Elaro_Audit_Log__c
    WHERE Action__c = 'Package Installation'
    ORDER BY CreatedDate DESC
    LIMIT 1
];
System.debug('Install Log: ' + logs[0].Description__c);
```

---

## Post-Installation Configuration

### Step 1: Configure Named Credentials

#### 1.1 Claude AI API (Required for AI Features)

**Purpose:** Enables AI-powered compliance analysis, natural language queries, and root cause analysis

**Steps:**

1. Navigate to: **Setup → Named Credentials → New Legacy**
2. Enter configuration:
   - **Label:** Elaro Claude API
   - **Name:** `Elaro_Claude_API`
   - **URL:** `https://api.anthropic.com`
   - **Identity Type:** Named Principal
   - **Authentication Protocol:** Password Authentication
   - **Username:** `x-api-key` (literal value)
   - **Password:** [Your Anthropic API Key]
   - **Generate Authorization Header:** ✅ Checked
   - **Allow Merge Fields in HTTP Header:** ✅ Checked
   - **Allow Merge Fields in HTTP Body:** ✅ Checked

3. Click **Save**

4. **Add Custom HTTP Header:**
   - Click **Edit** on the Named Credential
   - Scroll to **Custom Headers**
   - Add header:
     - **Name:** `anthropic-version`
     - **Value:** `2023-06-01`
   - Click **Save**

5. **Test Connection:**

```apex
// Execute Anonymous Apex
Http http = new Http();
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Elaro_Claude_API');
req.setMethod('GET');
System.debug('Response Code: ' + http.send(req).getStatusCode()); // Should be 200 or 400 (method not allowed, but connection works)
```

#### 1.2 Slack Webhook (Optional)

**Purpose:** Real-time compliance alerts to Slack channels

**Steps:**

1. Create Slack Incoming Webhook:
   - Go to [Slack API Apps](https://api.slack.com/apps)
   - Click **Create New App** → **From Scratch**
   - Name: `Elaro Compliance Alerts`
   - Select your workspace
   - Navigate to **Incoming Webhooks** → Toggle **On**
   - Click **Add New Webhook to Workspace**
   - Select channel → **Authorize**
   - Copy Webhook URL

2. Create Named Credential in Salesforce:
   - Navigate to: **Setup → Named Credentials → New Legacy**
   - **Label:** Slack Webhook
   - **Name:** `Slack_Webhook`
   - **URL:** [Your Slack Webhook URL]
   - **Identity Type:** Named Principal
   - **Authentication Protocol:** No Authentication
   - Click **Save**

3. **Test Notification:**

```apex
SlackIntegration.sendMessage('Test message from Elaro!');
// Check your Slack channel for message
```

#### 1.3 PagerDuty Integration (Optional)

**Purpose:** Incident triggering for critical compliance alerts

**Steps:**

1. **Configure Custom Metadata** (PagerDuty uses Custom Metadata, not Named Credential):

Navigate to: **Setup → Custom Metadata Types → Elaro API Config → Manage Records**

If "PagerDuty" record doesn't exist:
   - Click **New**
   - **Label:** PagerDuty
   - **Elaro API Config Name:** PagerDuty
   - **API Key:** [Your PagerDuty Routing Key from Events API v2]
   - **Is Active:** ✅ Checked
   - Click **Save**

2. **Obtain PagerDuty Routing Key:**
   - Log in to [PagerDuty](https://www.pagerduty.com)
   - Navigate to: **Services → [Your Service] → Integrations**
   - Add Integration → **Events API v2**
   - Copy **Integration Key** (this is your routing key)

3. **Test Integration:**

```apex
PagerDutyIntegration.triggerIncident('{"alertId":"TEST-001","eventType":"Test Alert","severity":"HIGH","message":"Test integration"}');
// Check PagerDuty for new incident
```

---

### Step 2: Enable AI Features

1. Navigate to: **Setup → Custom Settings → Elaro AI Settings → Manage**
2. Click **Edit** next to organization defaults
3. Update settings:
   - **AI Enabled:** ✅ Checked (only after configuring Claude API Named Credential)
   - **Model Name:** `claude-sonnet-4-20250514` (default)
   - **Max Tokens:** `4096`
   - **Temperature:** `0.7`
   - **Cache Enabled:** ✅ Checked
   - **Cache TTL Minutes:** `60`
   - **Timeout Seconds:** `60`
4. Click **Save**

**⚠️ Important:** Do not enable AI until Claude API Named Credential is configured, or API calls will fail.

---

### Step 3: Configure Compliance Frameworks

Navigate to **Elaro** app and configure active compliance frameworks:

1. Click **Elaro Dashboard**
2. Click **Settings** gear icon
3. Select frameworks to enable:
   - [ ] HIPAA (Healthcare)
   - [ ] SOC 2 (Service Organizations)
   - [ ] NIST (Government/Federal)
   - [ ] FedRAMP (Federal Cloud)
   - [ ] GDPR (EU Data Privacy)
   - [ ] SOX (Financial Reporting)
   - [ ] PCI-DSS (Payment Card Industry)
   - [ ] CCPA (California Privacy)
   - [ ] GLBA (Financial Services)
   - [ ] ISO 27001 (Information Security)
4. Click **Save**

---

### Step 4: Initial Compliance Scan

Run your first compliance baseline scan:

1. Navigate to **Elaro** app
2. Click **Run Compliance Scan**
3. Select frameworks to scan
4. Click **Start Scan**
5. Monitor progress in **Scan History** tab
6. Review results in **Compliance Dashboard**

**Expected Scan Time:** 5-15 minutes depending on org size

---

## Permission Set Assignment

Elaro includes 5 permission sets. Assign users to appropriate permission sets based on their role.

### Permission Set Overview

| Permission Set | Purpose | Typical Users |
|----------------|---------|---------------|
| **Elaro_Admin** | Full administrative access to all Elaro features | Compliance Managers, System Administrators |
| **Elaro_Auditor** | Read-only access to audit data and reports | Internal Auditors, Compliance Officers |
| **Elaro_User** | Standard access to compliance dashboards and evidence | Compliance Team Members, Department Heads |
| **Elaro_AI_User** | Access to AI-powered compliance analysis features | Compliance Analysts, Risk Managers |
| **Elaro_API_User** | API access for external integrations | Integration Users, Service Accounts |

### Assigning Permission Sets

**Via Setup UI:**

1. Navigate to: **Setup → Users → [Select User]**
2. Scroll to **Permission Set Assignments**
3. Click **Edit Assignments**
4. Add desired Elaro permission sets
5. Click **Save**

**Via Permission Set Groups (Recommended for Large Deployments):**

1. Create permission set groups:
   - **Elaro_Full_Access:** Includes Admin + AI User
   - **Elaro_Read_Only:** Includes Auditor only
2. Assign users to groups instead of individual permission sets

**Bulk Assignment via Data Loader:**

```csv
AssigneeId,PermissionSetId
005000000000001AAA,[Elaro_Admin_Id]
005000000000002AAA,[Elaro_Auditor_Id]
```

**Via Apex:**

```apex
Id userId = '005000000000001AAA';
Id permSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Elaro_Admin' LIMIT 1].Id;
insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permSetId);
```

---

## Verification Steps

### 1. Verify Installation

- [ ] Navigate to **Setup → Installed Packages**
- [ ] Confirm **Elaro v3.0** appears with status **Installed**
- [ ] Verify installation date and installer name

### 2. Verify Package Components

```apex
// Execute Anonymous Apex
System.debug('Apex Classes: ' + [SELECT COUNT() FROM ApexClass WHERE NamespacePrefix = 'elaro']);
System.debug('Custom Objects: ' + [SELECT COUNT() FROM EntityDefinition WHERE NamespacePrefix = 'elaro']);
System.debug('Permission Sets: ' + [SELECT COUNT() FROM PermissionSet WHERE NamespacePrefix = 'elaro']);
```

Expected output:
- Apex Classes: ~207
- Custom Objects: ~46
- Permission Sets: 5

### 3. Verify Permission Sets

- [ ] Navigate to: **Setup → Permission Sets**
- [ ] Confirm all 5 Elaro permission sets exist:
  - Elaro_Admin
  - Elaro_Auditor
  - Elaro_User
  - Elaro_AI_User
  - Elaro_API_User

### 4. Verify Custom Settings

```apex
Elaro_AI_Settings__c settings = Elaro_AI_Settings__c.getOrgDefaults();
System.assertNotEquals(null, settings, 'AI Settings should exist');
System.assertEquals('claude-sonnet-4-20250514', settings.Model_Name__c, 'Model should be claude-sonnet-4');
```

### 5. Verify Audit Logging

```apex
List<Elaro_Audit_Log__c> logs = [
    SELECT Id, Action__c, Status__c
    FROM Elaro_Audit_Log__c
    WHERE Action__c = 'Package Installation'
    LIMIT 1
];
System.assertEquals(1, logs.size(), 'Install audit log should exist');
System.assertEquals('Completed', logs[0].Status__c, 'Install should be completed');
```

### 6. Access Elaro App

- [ ] Navigate to **App Launcher**
- [ ] Search for **Elaro**
- [ ] Click **Elaro** app
- [ ] Verify dashboard loads without errors

### 7. Test AI Features (If Configured)

```apex
// Only run if Claude API Named Credential is configured
String query = 'Analyze recent login patterns for compliance risks';
String result = ElaroComplianceCopilotService.analyzeCompliance(query, 'HIPAA');
System.assertNotEquals(null, result, 'AI analysis should return result');
```

### 8. Test Compliance Scan

- [ ] Navigate to **Elaro** app → **Compliance Dashboard**
- [ ] Click **Run Compliance Scan**
- [ ] Select **HIPAA** (or your primary framework)
- [ ] Click **Start Scan**
- [ ] Verify scan completes without errors
- [ ] Review **Compliance Score** on dashboard

---

## Optional Integrations

### Microsoft Teams Integration

1. Create Teams Incoming Webhook:
   - Go to Teams channel → **Connectors** → **Incoming Webhook**
   - Name: `Elaro Alerts`
   - Copy webhook URL

2. Create Named Credential:
   - **Setup → Named Credentials → New Legacy**
   - **Name:** `Teams_Webhook`
   - **URL:** [Teams Webhook URL]
   - **Authentication:** No Authentication

3. Test:
   ```apex
   ElaroTeamsNotifierQueueable.sendNotification('Test Teams alert');
   ```

### ServiceNow GRC Integration

1. Create ServiceNow Integration User
2. Create Named Credential:
   - **Setup → Named Credentials → New Legacy**
   - **Name:** `ServiceNow_API`
   - **URL:** `https://[instance].service-now.com`
   - **Authentication:** Password Authentication
   - **Username:** [ServiceNow integration user]
   - **Password:** [ServiceNow integration password]

3. Test:
   ```apex
   ServiceNowIntegration.createIncident('Test Incident', 'High', 'Testing integration');
   ```

---

## Troubleshooting

### Installation Issues

#### Issue: "Package Installation Failed"

**Symptoms:** Installation fails with generic error

**Resolution:**
1. Verify org meets all prerequisites (Edition, API version, My Domain)
2. Check available storage (Data and File storage)
3. Review installation error details in email notification
4. Contact Elaro support with error details

#### Issue: "Third-Party Access Not Approved"

**Symptoms:** Installation blocked waiting for approval

**Resolution:**
1. Check **Setup → Installed Packages → Elaro → View Components**
2. Click **Approve Third-Party Access**
3. Resume installation

---

### Post-Installation Issues

#### Issue: "AI Features Not Working"

**Symptoms:** AI analysis returns errors or null results

**Diagnosis:**
```apex
// Check AI settings
Elaro_AI_Settings__c settings = Elaro_AI_Settings__c.getOrgDefaults();
System.debug('AI Enabled: ' + settings.AI_Enabled__c);

// Check Named Credential
Http http = new Http();
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Elaro_Claude_API');
req.setMethod('GET');
System.debug('NC Status: ' + http.send(req).getStatusCode());
```

**Resolution:**
1. Verify Named Credential `Elaro_Claude_API` exists
2. Check API key is valid (test at api.anthropic.com)
3. Verify `anthropic-version` header is set to `2023-06-01`
4. Confirm AI settings `AI_Enabled__c` is **true**
5. Check Anthropic API status page for outages

#### Issue: "Slack Notifications Not Sending"

**Diagnosis:**
```bash
curl -X POST -H 'Content-Type: application/json' \
  -d '{"text":"Test from curl"}' \
  [YOUR_WEBHOOK_URL]
```

**Resolution:**
1. Verify webhook URL is correct and active
2. Check Slack app is installed in workspace
3. Confirm Named Credential `Slack_Webhook` uses exact webhook URL
4. Review Event Monitoring logs for callout failures

#### Issue: "Permission Sets Not Assigning"

**Resolution:**
1. Verify user has Standard User profile or higher
2. Check for conflicting permission set assignments
3. Review Setup Audit Trail for errors
4. Try assigning via Apex instead of UI

#### Issue: "Compliance Scan Fails"

**Diagnosis:**
```apex
List<Elaro_Audit_Log__c> errors = [
    SELECT Description__c, Severity__c
    FROM Elaro_Audit_Log__c
    WHERE Severity__c = 'ERROR'
    AND CreatedDate = TODAY
    ORDER BY CreatedDate DESC
];
for (Elaro_Audit_Log__c log : errors) {
    System.debug(log.Description__c);
}
```

**Resolution:**
1. Check API call limits (should have at least 5,000 available)
2. Verify user has access to objects being scanned
3. Review debug logs for SOQL errors
4. Confirm frameworks are enabled in settings

---

### Performance Issues

#### Issue: "Compliance Scans Taking Too Long"

**Optimization Steps:**
1. Run scans during off-peak hours
2. Reduce number of frameworks scanned simultaneously
3. Archive old compliance data (older than 365 days)
4. Consider increasing API call limits

#### Issue: "Dashboard Loading Slowly"

**Resolution:**
1. Clear browser cache
2. Verify no browser console errors
3. Check for large data volumes (>100,000 records)
4. Review Salesforce org performance metrics

---

## Uninstallation

⚠️ **Warning:** Uninstalling Elaro will delete all compliance data, audit logs, evidence items, and configuration. This action cannot be undone.

### Before Uninstalling

1. **Export Critical Data:**
   ```bash
   sf data export --query "SELECT * FROM Compliance_Score__c" --output-file compliance_scores.csv
   sf data export --query "SELECT * FROM Elaro_Audit_Log__c" --output-file audit_logs.csv
   sf data export --query "SELECT * FROM Compliance_Evidence__c" --output-file evidence.csv
   ```

2. **Document Named Credentials:**
   - Export Named Credential configurations (they will be deleted)
   - Save API keys and webhook URLs

3. **Remove Permission Set Assignments:**
   ```apex
   delete [SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.NamespacePrefix = 'elaro'];
   ```

### Uninstallation Steps

1. Navigate to: **Setup → Installed Packages**
2. Click **Uninstall** next to **Elaro**
3. Review components to be deleted
4. Click **Uninstall**
5. Confirm deletion

**Uninstallation Time:** 5-10 minutes

### Post-Uninstallation Cleanup

1. Remove any custom code references to Elaro classes
2. Delete any custom reports/dashboards using Elaro objects
3. Update any flows/process builders that referenced Elaro

---

## Support

### Documentation

- **Installation Guide:** This document
- **External Services Guide:** [docs/EXTERNAL_SERVICES.md](EXTERNAL_SERVICES.md)
- **PagerDuty Security Review:** [docs/PAGERDUTY_INTEGRATION_SECURITY_REVIEW.md](PAGERDUTY_INTEGRATION_SECURITY_REVIEW.md)
- **Technical Deep Dive:** [TECHNICAL_DEEP_DIVE.md](../TECHNICAL_DEEP_DIVE.md)
- **API Reference:** [API_REFERENCE.md](../API_REFERENCE.md)

### Getting Help

- **Email Support:** support@elaro.io
- **Documentation:** https://docs.elaro.io
- **Community Forum:** https://community.elaro.io
- **GitHub Issues:** https://github.com/elaro/elaro/issues

### Reporting Installation Issues

When reporting issues, please include:

1. **Org Information:**
   - Salesforce Edition
   - API Version
   - My Domain URL

2. **Installation Details:**
   - Package version installed
   - Installation date and time
   - Installer username

3. **Error Details:**
   - Full error message
   - Debug logs (if available)
   - Steps to reproduce

4. **Environment:**
   - Sandbox or Production
   - Number of users
   - Data volume

---

**Document Version:** 1.0
**Last Updated:** 2026-01-11
**Next Review:** Before AppExchange Submission
**Maintained By:** Elaro Engineering Team

© 2026 Elaro. All rights reserved.
