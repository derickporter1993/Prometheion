# Prometheion Setup Guide

Complete setup instructions for deploying and configuring Prometheion in your Salesforce org.

---

## 📋 Prerequisites

- Salesforce org (Production, Sandbox, or Scratch Org)
- Salesforce CLI (`sf` or `sfdx`) installed
- DevHub org authenticated (for scratch orgs)
- Admin access to configure Named Credentials

---

## 🚀 Installation

### Option 1: Deploy to Existing Org

```bash
# Clone the repo (if not already done)
git clone https://github.com/derickporter1993/Prometheion.git
cd prometheion

# Authenticate to your Salesforce org
sf org login web --alias myorg

# Deploy the package
sf project deploy start --target-org myorg

# Assign permissions
sf org assign permset --name Prometheion_Admin --target-org myorg

# Open the org
sf org open --target-org myorg
```

### Option 2: Create Scratch Org (for testing)

```bash
# Run the initialization script
./scripts/orgInit.sh

# This will:
# - Create a 7-day scratch org
# - Push source code
# - Assign Prometheion_Admin permission set
# - Open the org in your browser
```

---

## 🔧 Configuration

### 1. Configure Named Credentials

Prometheion requires Named Credentials for Slack and Teams integrations.

#### Slack Webhook Setup

1. **Create Slack Incoming Webhook:**
   - Go to https://api.slack.com/messaging/webhooks
   - Click "Create New Webhook"
   - Select your Slack channel
   - Copy the webhook URL

2. **Create Named Credential in Salesforce:**
   - Navigate to **Setup → Named Credentials → New**
   - **Label:** `Slack_Webhook`
   - **Name:** `Slack_Webhook` (must match exactly)
   - **URL:** Paste your Slack webhook URL
   - **Identity Type:** Named Principal
   - **Authentication Protocol:** No Authentication
   - **Save**

#### Teams Webhook Setup

1. **Create Teams Incoming Webhook:**
   - In Microsoft Teams, go to your channel
   - Click **...** (More options) → **Connectors**
   - Search for "Incoming Webhook" and click **Configure**
   - Give it a name and click **Create**
   - Copy the webhook URL

2. **Create Named Credential in Salesforce:**
   - Navigate to **Setup → Named Credentials → New**
   - **Label:** `Teams_Webhook`
   - **Name:** `Teams_Webhook` (must match exactly)
   - **URL:** Paste your Teams webhook URL
   - **Identity Type:** Named Principal
   - **Authentication Protocol:** No Authentication
   - **Save**

### 2. Schedule Weekly Scorecard

#### Via Setup UI:
1. Navigate to **Setup → Apex → Schedule Apex**
2. Click **Schedule Apex**
3. **Apex Class:** `WeeklyScorecardScheduler`
4. **Job Name:** `Prometheion Weekly Scorecard`
5. **Frequency:** Weekly
6. **Preferred Start Time:** 9:00 AM
7. **Preferred Start Day:** Monday
8. **Save**

#### Via Anonymous Apex:
```apex
// Schedule for both Slack and Teams
WeeklyScorecardScheduler.scheduleWeekly('Both');

// Or schedule for specific channel
WeeklyScorecardScheduler.scheduleWeekly('Slack');
WeeklyScorecardScheduler.scheduleWeekly('Teams');
```

### 3. Add Compliance Copilot to Lightning Page

1. Navigate to **Setup → App Builder**
2. Open or create a Lightning page (Home, App, or Record)
3. Drag the **Compliance Copilot** component onto the page
4. Configure component properties (optional):
   - **Height:** 600px (default)
5. **Save** and **Activate**

---

## ✅ Verification

### Test Compliance Copilot

1. Navigate to a Lightning page with the Compliance Copilot component
2. Try these queries:
   - "Why did my compliance score drop?"
   - "Show me all risky Flows touching PII"
   - "Generate SOC2 evidence for Q4"
   - "Who has Modify All Data permission?"
   - "What is our HIPAA compliance status?"

### Test Weekly Scorecard

```apex
// Run in Anonymous Apex to send test scorecard immediately
WeeklyScorecardScheduler.sendTestScorecard();
```

Check your Slack/Teams channel for the scorecard notification.

### Verify Named Credentials

```apex
// Test Slack notification
SlackNotifier.notifyAsync('🧪 Test notification from Prometheion');

// Test Teams notification
TeamsNotifier.notifyAsync('🧪 Test notification from Prometheion');
```

---

## 📊 Run Your First Compliance Scan

1. **Navigate to Prometheion** in the App Launcher
2. **Click "Run Baseline Scan"** on the dashboard
3. **Wait 30-60 seconds** while Prometheion analyzes your org
4. **View your Audit Readiness Score** and top risks
5. **Export the report** (Markdown or PDF) for your compliance team

---

## 🔍 Troubleshooting

### Named Credential Issues

**Problem:** "Callout failed" errors

**Solutions:**
- Verify Named Credential name matches exactly: `Slack_Webhook` or `Teams_Webhook`
- Check webhook URL is valid (test in browser/Postman)
- Ensure Named Credential is saved and active
- Check org's network settings allow outbound callouts

### Weekly Scorecard Not Sending

**Problem:** Scheduled job runs but no notifications received

**Solutions:**
- Verify Named Credentials are configured correctly
- Check Apex Debug Logs for errors
- Run `WeeklyScorecardScheduler.sendTestScorecard()` to test manually
- Verify score calculation: `PrometheionComplianceScorer.calculateReadinessScore()`

### Compliance Copilot Not Responding

**Problem:** Component shows error or no response

**Solutions:**
- Check browser console for JavaScript errors
- Verify user has `Prometheion_Admin` permission set assigned
- Check Apex Debug Logs for errors
- Ensure `Prometheion_Compliance_Graph__b` BigObject has data (for some queries)

### Permission Errors

**Problem:** "Insufficient Privileges" errors

**Solutions:**
- Assign `Prometheion_Admin` permission set to user
- Verify user has access to required objects:
  - `Prometheion_Compliance_Graph__b`
  - `PermissionSetAssignment`
  - `User`
  - Custom objects used by Prometheion

---

## 📚 Additional Resources

- **Sample Report:** [examples/compliance-baseline-report-sample.md](../examples/compliance-baseline-report-sample.md)
- **Roadmap:** [ROADMAP.md](../ROADMAP.md)
- **Security:** [SECURITY.md](../SECURITY.md)

---

## 🆘 Support

- **Issues:** [GitHub Issues](https://github.com/derickporter1993/Prometheion/issues)
- **Documentation:** [docs/](../docs/)
- **Discussions:** [GitHub Discussions](https://github.com/derickporter1993/Prometheion/discussions)

---

*Last Updated: 2025-01-15*

