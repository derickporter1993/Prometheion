# Prometheion Complete Steps Checklist

**Version:** 3.0.0
**Date:** 2025-12-25
**Status:** Ready for Testing & Deployment

---

## 📋 Table of Contents

1. [Pre-Testing Verification](#pre-testing-verification)
2. [Phase 1: Scratch Org Testing](#phase-1-scratch-org-testing)
3. [Phase 2: Sandbox Deployment](#phase-2-sandbox-deployment)
4. [Phase 3: Production Deployment](#phase-3-production-deployment)
5. [Post-Deployment Activities](#post-deployment-activities)
6. [Ongoing Maintenance](#ongoing-maintenance)

---

## ✅ Pre-Testing Verification

### Code Quality Checklist

- [x] All code follows Salesforce best practices (Dec 2025 standards)
- [x] All SOQL queries use `WITH SECURITY_ENFORCED`
- [x] All DML operations use `Security.stripInaccessible()`
- [x] No hardcoded IDs or sensitive data
- [x] All classes have proper error handling
- [x] Platform Cache implemented for performance-critical operations
- [x] Queueable classes used instead of `@future` methods
- [x] All Sentinel/OpsGuardian references replaced with Prometheion
- [x] VS Code settings configured
- [x] Recommended extensions documented

### Prerequisites

- [ ] Salesforce CLI (`sf` or `sfdx`) installed and up-to-date
- [ ] DevHub org authenticated (for scratch orgs)
- [ ] Git repository is clean and all changes committed
- [ ] Access to target sandbox/production orgs (if deploying)

---

## 🧪 Phase 1: Scratch Org Testing

### Step 1.1: Create Scratch Org

```bash
sf org create scratch -f config/prometheion-scratch-def.json -a prometheion-dev -d -y 30
```

- [ ] Scratch org created successfully
- [ ] Note the scratch org username/alias for later use

### Step 1.2: Deploy Metadata

```bash
sf project deploy start -o prometheion-dev --wait 10
```

- [ ] Deployment completed without errors
- [ ] All metadata components deployed successfully
- [ ] Check deployment report for any warnings

### Step 1.3: Assign Permission Sets

```bash
sf org assign permset -n Prometheion_Admin -o prometheion-dev
```

- [ ] Permission set assigned successfully
- [ ] Verify no permission errors

### Step 1.4: Verify Platform Cache Configuration

**In Setup UI:**

1. Navigate to: Setup → Platform Cache → Partitions
2. Look for partition named: `PrometheionCompliance`

- [ ] Partition exists
- [ ] Partition type is "Org Cache" (not Session)
- [ ] Partition has allocated capacity (minimum 5MB recommended)
- [ ] Description matches: "Prometheion Compliance cache partition for storing compliance scores"

### Step 1.5: Run Unit Tests

```bash
sf apex test run --test-level RunLocalTests --code-coverage --result-format human -o prometheion-dev
```

- [ ] All tests pass
- [ ] Test coverage ≥ 75%
- [ ] No test failures or errors
- [ ] Save test results for documentation

### Step 1.6: Verify Custom Objects Deployed

**Check in Setup → Object Manager:**

- [ ] `Prometheion_AI_Settings__c` exists (Custom Settings - Hierarchy)
- [ ] `Prometheion_Compliance_Graph__b` exists (Big Object)
- [ ] `Prometheion_Alert_Event__e` exists (Platform Event)
- [ ] `CCX_Settings__c` exists (Custom Settings)
- [ ] All field definitions are correct

### Step 1.7: Functional Testing in Scratch Org

#### A. Open Org and Navigate

```bash
sf org open -o prometheion-dev
```

- [ ] Org opens successfully
- [ ] Can navigate to Prometheion app/dashboard

#### B. Test AI Settings

1. Navigate to: Setup → Custom Settings → Prometheion AI Settings → Manage
2. Create/verify org default record

- [ ] AI Settings page loads
- [ ] Can view existing settings
- [ ] Can save new settings
- [ ] Settings persist correctly

#### C. Test Compliance Scoring

1. Navigate to compliance dashboard/readiness score component
2. Trigger compliance score calculation

- [ ] Score calculates successfully
- [ ] Score displays in UI
- [ ] No errors in browser console
- [ ] Platform Cache is being used (check debug logs)

#### D. Test Platform Events

- [ ] Platform events can be published
- [ ] Events appear in Platform Event Monitor (Setup → Platform Events → Monitor)
- [ ] No publishing errors

#### E. Test Permission Sets

- [ ] Users with `Prometheion_Admin` can access all features
- [ ] Users without permission set cannot access admin features
- [ ] Field-level security is enforced

### Step 1.8: Check Debug Logs

1. Setup → Debug Logs
2. Review recent logs for errors

- [ ] No critical errors
- [ ] Platform Cache hits logged (if applicable)
- [ ] No governor limit exceptions
- [ ] No security exceptions

### Step 1.9: Generate Baseline Report (Optional)

```bash
sf apex run -f scripts/generate-baseline-report.apex -o prometheion-dev
```

- [ ] Script executes successfully
- [ ] Report is generated
- [ ] Report contains expected data

### Step 1.10: Test Slack Integration (If Configured)

1. Verify Named Credential exists: Setup → Named Credentials → `Slack_Webhook`
2. Test notification:
   - Trigger a test notification
   - Check Slack channel for message

- [ ] Named Credential is configured
- [ ] Notification sends successfully
- [ ] Queueable job executes (check Setup → Apex Jobs)

### Step 1.11: Scratch Org Test Summary

- [ ] All functional tests pass
- [ ] No critical errors
- [ ] Performance is acceptable
- [ ] Ready to proceed to sandbox deployment

---

## 🏗️ Phase 2: Sandbox Deployment

### Step 2.1: Pre-Deployment Verification

- [ ] Scratch org testing completed successfully
- [ ] All issues from scratch org testing resolved
- [ ] Deployment plan reviewed and approved
- [ ] Sandbox org access confirmed
- [ ] Backup/rollback plan documented

### Step 2.2: Platform Cache Configuration in Sandbox

**In Sandbox Setup UI:**

1. Navigate to: Setup → Platform Cache → Partitions
2. Create new partition (if not exists):
   - **Label:** `PrometheionCompliance`
   - **Developer Name:** `PrometheionCompliance`
   - **Type:** Org Cache
   - **Description:** Prometheion Compliance cache partition for storing compliance scores
   - **Capacity:** Minimum 5MB (10MB+ recommended)
3. Save partition

- [ ] Platform Cache partition created/verified
- [ ] Partition type is "Org Cache"
- [ ] Capacity allocated appropriately

### Step 2.3: Named Credentials Setup (Optional - if using Slack)

**In Sandbox Setup UI:**

1. Navigate to: Setup → Named Credentials
2. Verify or create `Slack_Webhook`:
   - Type: Named Credential
   - URL: Your Slack webhook URL
   - Identity Type: Named Principal
   - Authentication Protocol: No Authentication (or OAuth if needed)

- [ ] Named Credential exists
- [ ] Credential is configured correctly
- [ ] Test connectivity (if possible)

### Step 2.4: Authenticate to Sandbox

```bash
sf org login web --alias sandbox-alias --instance-url https://test.salesforce.com
```

- [ ] Authenticated successfully
- [ ] Sandbox org accessible

### Step 2.5: Deploy Metadata to Sandbox

```bash
sf project deploy start --target-org sandbox-alias --wait 10
```

- [ ] Deployment started
- [ ] Deployment completed successfully
- [ ] Review deployment report
- [ ] No deployment errors
- [ ] Address any warnings (if applicable)

### Step 2.6: Verify Deployment in Sandbox

**Check in Setup:**

- [ ] All custom objects deployed
- [ ] Permission sets deployed
- [ ] Classes and triggers deployed
- [ ] Lightning Web Components deployed
- [ ] Platform Events deployed

### Step 2.7: Post-Deployment Configuration

#### A. Create Org Default Custom Settings

**Option 1: Via Apex (in Developer Console or VS Code)**

```apex
Prometheion_AI_Settings__c settings = Prometheion_AI_Settings__c.getInstance();
if (settings == null) {
    settings = new Prometheion_AI_Settings__c(
        SetupOwnerId = UserInfo.getOrganizationId(),
        Enable_AI_Reasoning__c = true,
        Confidence_Threshold__c = 0.85,
        Require_Human_Approval__c = true,
        Auto_Remediation_Enabled__c = false,
        Blacklisted_Users__c = ''
    );
    insert settings;
}
```

- [ ] Org default settings created
- [ ] Settings values are correct

**Option 2: Via Setup UI**

1. Setup → Custom Settings → Prometheion AI Settings → Manage
2. Click "New" and create org-wide default

- [ ] Org default created via UI
- [ ] All required fields populated

#### B. Assign Permission Sets

```bash
sf org assign permset -n Prometheion_Admin --target-org sandbox-alias -u admin-user@example.com
```

- [ ] Permission set assigned to appropriate users
- [ ] Users can access Prometheion features
- [ ] Verify with test user login

#### C. Verify CCX_Settings\_\_c (if needed)

- [ ] CCX_Settings\_\_c org default exists
- [ ] Threshold values configured appropriately

### Step 2.8: Run Tests in Sandbox

```bash
sf apex test run --test-level RunLocalTests --code-coverage --result-format human --target-org sandbox-alias
```

- [ ] All tests pass
- [ ] Test coverage ≥ 75%
- [ ] No test failures

### Step 2.9: Sandbox Functional Testing

- [ ] Navigate to Prometheion app/dashboard
- [ ] Test compliance readiness score
- [ ] Test AI settings configuration
- [ ] Test Platform Cache (check debug logs)
- [ ] Test Slack notifications (if configured)
- [ ] Test permission enforcement
- [ ] Generate baseline report
- [ ] Verify all components render correctly

### Step 2.10: User Acceptance Testing (UAT)

- [ ] UAT test plan created
- [ ] Test scenarios executed
- [ ] Users can complete key workflows
- [ ] Performance meets requirements
- [ ] No critical bugs discovered
- [ ] UAT sign-off obtained

### Step 2.11: Sandbox Deployment Sign-Off

- [ ] Technical verification complete
- [ ] Functional testing complete
- [ ] User acceptance testing complete
- [ ] Performance testing complete
- [ ] Security review complete
- [ ] Ready for production deployment

---

## 🚀 Phase 3: Production Deployment

### Step 3.1: Pre-Production Checklist

- [ ] Sandbox deployment successful
- [ ] All sandbox issues resolved
- [ ] UAT completed and approved
- [ ] Production deployment plan reviewed
- [ ] Rollback plan documented and tested
- [ ] Stakeholder approval obtained
- [ ] Maintenance window scheduled (if needed)
- [ ] Team notified of deployment

### Step 3.2: Production Backup & Verification

- [ ] Current production state documented
- [ ] Backup strategy confirmed
- [ ] Rollback procedure tested in sandbox
- [ ] Production org access confirmed

### Step 3.3: Platform Cache Configuration in Production

**In Production Setup UI:**

1. Navigate to: Setup → Platform Cache → Partitions
2. Create new partition:
   - **Label:** `PrometheionCompliance`
   - **Developer Name:** `PrometheionCompliance`
   - **Type:** Org Cache
   - **Description:** Prometheion Compliance cache partition for storing compliance scores
   - **Capacity:** Minimum 5MB (10MB+ recommended for production)
3. Save partition

- [ ] Platform Cache partition created
- [ ] Capacity allocated appropriately
- [ ] Partition is accessible

### Step 3.4: Named Credentials Setup in Production (Optional)

- [ ] `Slack_Webhook` Named Credential created/verified
- [ ] Credential configured with production webhook URL
- [ ] Connectivity tested

### Step 3.5: Authenticate to Production

```bash
sf org login web --alias production-alias --instance-url https://login.salesforce.com
```

- [ ] Authenticated successfully
- [ ] Production org accessible
- [ ] Correct org confirmed (double-check!)

### Step 3.6: Validate Deployment (Recommended First)

```bash
sf project deploy validate --target-org production-alias --wait 10
```

- [ ] Validation completed
- [ ] No validation errors
- [ ] Ready for actual deployment

### Step 3.7: Deploy to Production

```bash
sf project deploy start --target-org production-alias --wait 10
```

- [ ] Deployment started
- [ ] Deployment completed successfully
- [ ] Deployment report reviewed
- [ ] No deployment errors
- [ ] Address any warnings

### Step 3.8: Post-Deployment Configuration

#### A. Create Org Default Custom Settings

- [ ] `Prometheion_AI_Settings__c` org default created
- [ ] Settings configured appropriately for production
- [ ] Settings tested and verified

#### B. Assign Permission Sets

```bash
sf org assign permset -n Prometheion_Admin --target-org production-alias -u admin-user@example.com
```

- [ ] Permission set assigned to appropriate users
- [ ] Users notified of access
- [ ] Verify with test login

#### C. Verify Configuration

- [ ] Platform Cache partition exists
- [ ] Named Credentials configured (if applicable)
- [ ] Custom Settings created
- [ ] Permission sets assigned

### Step 3.9: Run Tests in Production

```bash
sf apex test run --test-level RunLocalTests --code-coverage --result-format human --target-org production-alias
```

- [ ] All tests pass
- [ ] Test coverage ≥ 75%
- [ ] No test failures

### Step 3.10: Production Smoke Testing

- [ ] Navigate to Prometheion app
- [ ] Test compliance readiness score calculation
- [ ] Test AI settings page
- [ ] Verify Platform Cache is working (debug logs)
- [ ] Test critical user workflows
- [ ] Verify no errors in debug logs
- [ ] Check system monitor dashboard

### Step 3.11: Generate Initial Baseline Report

```bash
sf apex run -f scripts/generate-baseline-report.apex --target-org production-alias
```

- [ ] Baseline report generated successfully
- [ ] Report reviewed and saved
- [ ] Report shared with compliance team (if applicable)

### Step 3.12: Production Deployment Sign-Off

- [ ] Deployment completed successfully
- [ ] All configuration complete
- [ ] Smoke testing passed
- [ ] Team notified of successful deployment
- [ ] Documentation updated

---

## 📊 Post-Deployment Activities

### Step 4.1: First 24 Hours Monitoring

- [ ] Monitor debug logs for errors
- [ ] Check Platform Cache hit rates
- [ ] Verify no governor limit exceptions
- [ ] Confirm scheduled jobs are running
- [ ] Monitor Slack notifications (if configured)
- [ ] Check for user-reported issues
- [ ] Performance metrics reviewed

### Step 4.2: Team Communication

- [ ] Deployment announcement sent
- [ ] User training materials shared (if needed)
- [ ] Support channels established
- [ ] Documentation links provided

### Step 4.3: Initial Configuration

- [ ] Configure compliance frameworks as needed
- [ ] Set up monitoring dashboards
- [ ] Configure alert thresholds
- [ ] Schedule compliance reports (if applicable)

### Step 4.4: User Training (If Needed)

- [ ] Training sessions scheduled
- [ ] User guides provided
- [ ] FAQs documented
- [ ] Support process established

---

## 🔄 Ongoing Maintenance

### Weekly Tasks

- [ ] Review compliance scores
- [ ] Check for critical alerts
- [ ] Review Platform Cache effectiveness
- [ ] Monitor performance metrics
- [ ] Review audit trail

### Monthly Tasks

- [ ] Review and optimize slow queries
- [ ] Update custom settings as needed
- [ ] Review compliance report trends
- [ ] Check for Salesforce platform updates
- [ ] Review security logs

### Quarterly Tasks

- [ ] Comprehensive security review
- [ ] Performance optimization review
- [ ] Update documentation
- [ ] Review and update compliance frameworks
- [ ] Capacity planning (Platform Cache, etc.)

---

## 🆘 Troubleshooting Quick Reference

### Platform Cache Not Working

- [ ] Verify partition exists: Setup → Platform Cache → Partitions
- [ ] Check partition name matches: `PrometheionCompliance`
- [ ] Verify partition type is "Org Cache"
- [ ] Check capacity allocation
- [ ] Review debug logs for `OrgCacheException`

### Compliance Score Calculation Fails

- [ ] Check debug logs for specific error
- [ ] Verify custom objects exist
- [ ] Check user permissions
- [ ] Verify SOQL queries aren't hitting limits
- [ ] Test with `clearCache()` method

### Slack Notifications Not Working

- [ ] Verify Named Credential `Slack_Webhook` exists
- [ ] Check Queueable jobs: Setup → Apex Jobs
- [ ] Review debug logs for callout errors
- [ ] Test webhook URL manually
- [ ] Verify Named Credential configuration

### Deployment Errors

- [ ] Check deployment report for specific errors
- [ ] Verify API version compatibility
- [ ] Check for missing dependencies
- [ ] Verify org limits not exceeded
- [ ] Review metadata validation errors

---

## 📝 Notes & Additional Information

### Key Files Reference

- `DEPLOYMENT_CHECKLIST.md` - Detailed deployment guide
- `MIGRATION_COMPLETE_SUMMARY.md` - Migration status summary
- `README.md` - Project overview and setup
- `ROADMAP.md` - Product roadmap
- `config/prometheion-scratch-def.json` - Scratch org definition

### Important Contacts

- Technical Lead: ********\_********
- QA Lead: ********\_********
- Product Owner: ********\_********
- Compliance Team: ********\_********

### Deployment Sign-Off

- [ ] Technical Lead: ********\_******** Date: **\_\_\_**
- [ ] QA Lead: ********\_******** Date: **\_\_\_**
- [ ] Product Owner: ********\_******** Date: **\_\_\_**

---

**Last Updated:** 2025-12-25
**Version:** 3.0.0
