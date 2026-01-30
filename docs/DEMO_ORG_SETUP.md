# Elaro Demo Org Setup Guide

## Overview

This guide provides step-by-step instructions for setting up a Elaro demo org with sample data, configuration, and permission sets for demonstration purposes.

## Prerequisites

- Salesforce CLI (sf) installed and authenticated
- Access to create scratch orgs or sandbox
- Elaro package deployed

## Quick Start

### Option 1: Automated Setup Script

```bash
# Run the automated setup script
./scripts/orgInit.sh

# Or with custom org alias
./scripts/orgInit.sh my-demo-org
```

### Option 2: Manual Setup

Follow the steps below for manual setup.

## Step-by-Step Setup

### Step 1: Create Scratch Org

```bash
# Create scratch org with Elaro configuration
sf org create scratch \
  -f config/elaro-scratch-def.json \
  -a elaro-demo \
  -d 30

# Open the org
sf org open -o elaro-demo
```

### Step 2: Deploy Source Code

```bash
# Deploy all metadata
sf project deploy start -o elaro-demo

# Verify deployment
sf project deploy report -o elaro-demo
```

### Step 3: Assign Permission Sets

```bash
# Assign Elaro Admin permission set
sf org assign permset \
  --name Elaro_Admin \
  -o elaro-demo

# Assign Elaro User permission set
sf org assign permset \
  --name Elaro_User \
  -o elaro-demo

# Assign Elaro Auditor permission set (optional)
sf org assign permset \
  --name Elaro_Auditor \
  -o elaro-demo
```

### Step 4: Configure Named Credentials

Named Credentials must be configured in the org UI (cannot be deployed):

1. Navigate to **Setup** → **Named Credentials**
2. Configure the following:
   - `Elaro_Claude_API` - Claude API endpoint for AI features
   - `Slack_Webhook` - Slack integration (optional)
   - `Teams_Webhook` - Microsoft Teams integration (optional)

**Note**: For demo purposes, you can use placeholder values, but AI features will not work without valid credentials.

### Step 5: Create Sample Data

#### Option A: Using Anonymous Apex Script

```bash
# Execute test data creation script
sf apex run \
  --file scripts/create-test-data.apex \
  -o elaro-demo
```

#### Option B: Using Data Import

1. Navigate to **Setup** → **Data Import Wizard**
2. Import sample compliance data:
   - Compliance Scores
   - Compliance Gaps
   - Evidence Items
   - Audit Packages

#### Option C: Manual Data Creation

Create sample records via UI:

1. **Compliance Scores**:
   - Navigate to Elaro → Compliance Scores
   - Create scores for different frameworks (HIPAA, SOC2, GDPR, etc.)
   - Set scores between 60-95% for variety

2. **Compliance Gaps**:
   - Navigate to Elaro → Compliance Gaps
   - Create gaps with different severity levels
   - Link to frameworks and controls

3. **Evidence Items**:
   - Navigate to Elaro → Evidence Items
   - Create evidence for audit packages
   - Set various statuses (Pending, Verified, Rejected)

### Step 6: Configure Custom Metadata

Custom Metadata records are deployed automatically, but verify they exist:

1. Navigate to **Setup** → **Custom Metadata Types**
2. Verify the following have records:
   - `Executive_KPI__mdt` - Should have at least one sample record
   - `Compliance_Policy__mdt` - Should have multiple framework policies
   - `Framework_Config__mdt` - Should have framework configurations

### Step 7: Verify Installation

#### Check Key Components

1. **Lightning Apps**:
   - Navigate to App Launcher → Elaro
   - Verify app loads without errors

2. **Dashboards**:
   - Navigate to Elaro → Compliance Dashboard
   - Verify data displays correctly

3. **AI Features** (if Named Credentials configured):
   - Navigate to Elaro → Compliance Copilot
   - Test a sample query

#### Run Health Check

```bash
# Run Apex tests to verify everything works
sf apex run test \
  --target-org elaro-demo \
  --code-coverage \
  --wait 30
```

## Demo Scenarios

### Scenario 1: Compliance Dashboard Overview

1. Navigate to **Elaro** → **Compliance Dashboard**
2. Review overall compliance scores
3. Drill down into specific frameworks
4. Review compliance gaps and remediation status

### Scenario 2: Executive KPI Dashboard

1. Navigate to **Elaro** → **Executive KPI Dashboard**
2. Review key performance indicators
3. Verify thresholds and status indicators
4. Test real-time refresh functionality

### Scenario 3: Compliance Copilot (AI Assistant)

1. Navigate to **Elaro** → **Compliance Copilot**
2. Ask questions like:
   - "What are the critical compliance gaps for HIPAA?"
   - "Show me evidence items pending review"
   - "What is our overall compliance score?"
3. Review AI-generated recommendations

### Scenario 4: Audit Package Builder

1. Navigate to **Elaro** → **Audit Package Builder**
2. Create a new audit package for SOC2
3. Add evidence items
4. Generate audit report

### Scenario 5: Risk Heatmap

1. Navigate to **Elaro** → **Risk Heatmap**
2. Review risk visualization by framework
3. Filter by severity level
4. Drill down into specific risks

## Troubleshooting

### Issue: Permission Sets Not Available

**Solution**: Verify permission sets were deployed:

```bash
sf project deploy start --source-dir force-app/main/default/permissionsets -o elaro-demo
```

### Issue: Custom Metadata Missing

**Solution**: Redeploy custom metadata:

```bash
sf project deploy start --source-dir force-app/main/default/customMetadata -o elaro-demo
```

### Issue: No Data in Dashboards

**Solution**:

1. Verify sample data was created
2. Check that data is within date ranges used by dashboards
3. Verify permission sets allow read access to custom objects

### Issue: AI Features Not Working

**Solution**:

1. Verify Named Credentials are configured
2. Check API endpoint is accessible
3. Review debug logs for API errors

## Post-Install Configuration

### Enable Features

1. Navigate to **Elaro** → **AI Settings**
2. Enable desired AI features:
   - AI Reasoning
   - Compliance Copilot
   - Risk Prediction

### Configure Schedulers

1. Navigate to **Setup** → **Apex Classes**
2. Schedule required jobs:
   - `ElaroISO27001QuarterlyScheduler`
   - `WeeklyScorecardScheduler`
   - `ConsentExpirationScheduler`

### Set Up Notifications

1. Navigate to **Elaro** → **Settings**
2. Configure notification channels:
   - Slack webhooks
   - Teams webhooks
   - Email notifications

## Sample Data Requirements

For a complete demo, create:

- **10-20 Compliance Scores** across different frameworks
- **15-30 Compliance Gaps** with various severity levels
- **20-40 Evidence Items** with different statuses
- **3-5 Audit Packages** for different frameworks
- **5-10 Users** with different permission sets assigned

## Cleanup

To reset the demo org:

```bash
# Delete and recreate scratch org
sf org delete scratch -o elaro-demo -p
sf org create scratch -f config/elaro-scratch-def.json -a elaro-demo -d 30

# Or use destructive changes
sf project deploy start \
  --source-dir destructiveChanges \
  -o elaro-demo
```

## Support

For issues or questions:

- Review logs: `sf apex get log -o elaro-demo`
- Check deployment status: `sf project deploy report -o elaro-demo`
- Review documentation: `docs/` directory

## Last Updated

- **Date**: January 10, 2026
- **Version**: 3.0.0
- **Status**: Complete
