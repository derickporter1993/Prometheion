# Prometheion Setup Guide

This guide walks you through setting up Prometheion in your Salesforce org.

## Prerequisites

- Salesforce org (Enterprise Edition or higher)
- System Administrator access
- Anthropic Claude API key (for AI features)
- Salesforce CLI installed

## Step 1: Deploy Prometheion

### Option A: Using Salesforce CLI (Recommended)

```bash
# Navigate to project directory
cd /path/to/Solentra

# Authenticate with your org
sf org login web -a prod-org

# Deploy all metadata
sf project deploy start -o prod-org
```

### Option B: Using VS Code

1. Open VS Code with Salesforce Extensions
2. Right-click on `force-app` folder
3. Select "SFDX: Deploy Source to Org"
4. Select your target org

## Step 2: Configure Claude API Key

1. **Obtain API Key**
   - Sign up at [Anthropic Console](https://console.anthropic.com/)
   - Navigate to API Keys section
   - Create a new API key
   - Copy the key (you won't be able to see it again)

2. **Create Custom Metadata Record**
   - Navigate to: Setup > Custom Metadata Types
   - Click "Prometheion Claude Settings"
   - Click "Manage Prometheion Claude Settings"
   - Click "New"
   - Fill in:
     - **Label**: Default
     - **Developer Name**: Default (auto-filled)
     - **API Key**: Paste your Anthropic API key
   - Click "Save"

3. **Verify Configuration**
   - Navigate to: Setup > Custom Metadata Types > Prometheion Claude Settings
   - Verify the "Default" record exists
   - The API Key field should show as protected (masked)

## Step 3: Assign Permission Sets

1. **Navigate to Permission Sets**
   - Setup > Users > Permission Sets
   - Find "Prometheion Admin"

2. **Assign to Users**
   - Click "Prometheion Admin"
   - Click "Manage Assignments"
   - Click "Add Assignments"
   - Select users who need access
   - Click "Assign"
   - Click "Done"

3. **Verify Assignment**
   - Users should see "Prometheion" in App Launcher
   - Users can access Compliance Hub tab

## Step 4: Configure Email Digest (Optional)

The weekly email digest is automatically scheduled. To customize:

1. **View Scheduled Jobs**
   - Setup > Apex > Scheduled Jobs
   - Find "Prometheion Weekly Compliance Digest"

2. **Modify Schedule** (if needed)

   ```apex
   // In Developer Console or VS Code
   PrometheionEmailDigestScheduler.scheduleWeeklyJob();
   ```

3. **Unschedule** (if needed)
   ```apex
   PrometheionEmailDigestScheduler.unscheduleWeeklyJob();
   ```

## Step 5: Access Prometheion

1. **Open App Launcher**
   - Click App Launcher icon (9 dots) in top navigation
   - Search for "Prometheion"
   - Click on "Prometheion" app

2. **Navigate to Compliance Hub**
   - Click "Compliance Hub" tab
   - You should see the main dashboard

3. **Test AI Copilot**
   - Type a question: "What is our compliance score?"
   - Verify response is generated

## Step 6: Verify Installation

### Check Components

1. **Apex Classes**
   - Setup > Apex Classes
   - Verify all Prometheion\* classes are present

2. **Custom Metadata**
   - Setup > Custom Metadata Types
   - Verify "Prometheion Claude Settings" exists
   - Verify "Default" record exists

3. **Permission Sets**
   - Setup > Permission Sets
   - Verify "Prometheion Admin" exists

4. **Custom Application**
   - Setup > App Manager
   - Verify "Prometheion" app exists

### Run Tests

```bash
# Run all Prometheion tests
sf apex run test --class-names PrometheionConstantsTest -o prod-org
```

## Troubleshooting

### Issue: AI Copilot returns "API key not configured"

**Solution:**

1. Verify Custom Metadata record exists with Developer Name = "Default"
2. Check API key field is not empty
3. Verify API key is valid (not expired)
4. Check debug logs for specific error messages

### Issue: Permission denied errors

**Solution:**

1. Verify user has "Prometheion Admin" permission set assigned
2. Check user profile has necessary object permissions
3. Verify sharing settings allow access

### Issue: Compliance score shows 0 or null

**Solution:**

1. Check Platform Cache is enabled: Setup > Platform Cache
2. Verify partition exists: `local.PrometheionCompliance`
3. Clear cache and recalculate:
   ```apex
   Cache.OrgPartition orgPartition = Cache.Org.getPartition('local.PrometheionCompliance');
   orgPartition.remove('readinessScore');
   ```

### Issue: Email digest not sending

**Solution:**

1. Verify scheduled job is active
2. Check email deliverability: Setup > Email Deliverability
3. Verify admin users have valid email addresses
4. Check debug logs for email service errors

## Post-Installation Checklist

- [ ] All Prometheion classes deployed successfully
- [ ] Custom Metadata record created with API key
- [ ] Permission set assigned to admin users
- [ ] Prometheion app accessible from App Launcher
- [ ] Compliance Hub tab visible and functional
- [ ] AI Copilot responds to queries
- [ ] Compliance score displays correctly
- [ ] Email digest scheduled (if applicable)

## Next Steps

1. **Customize Compliance Frameworks**
   - Review framework-specific requirements
   - Adjust scoring weights if needed (in PrometheionConstants)

2. **Configure Monitoring**
   - Set up alerts for critical compliance issues
   - Configure weekly digest recipients

3. **Train Users**
   - Provide training on AI Copilot usage
   - Explain compliance scoring methodology
   - Demonstrate quick action features

4. **Review Initial Score**
   - Check baseline compliance score
   - Identify top risks
   - Create remediation plan

## Support

For additional help:

- Review debug logs: Setup > Debug Logs
- Check Apex test results: Setup > Apex Test Execution
- Review component errors in browser console
