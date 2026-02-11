# Elaro Production Deployment Runbook

**Version**: 1.0
**Last Updated**: 2026-02-02
**Owner**: Solentra DevOps Team

---

## Overview

This runbook provides step-by-step instructions for deploying Elaro (Prometheion v3.0) to production Salesforce orgs. Follow these procedures carefully to ensure zero-downtime deployment and rapid rollback capability.

---

## Pre-Deployment Checklist

### Code Quality ✅

- [ ] All tests passing locally: `npm run test:all`
- [ ] Lint checks pass: `npm run lint`
- [ ] Format checks pass: `npm run fmt:check`
- [ ] Code review completed (minimum 2 reviewers)
- [ ] No merge conflicts with main branch

### Security Verification ✅

- [ ] Security review completed by designated security reviewer
- [ ] No hardcoded credentials in codebase (checked with `grep -r "password\|api_key\|secret" --exclude-dir=node_modules`)
- [ ] All SOQL queries use `WITH SECURITY_ENFORCED`
- [ ] CRUD/FLS checks present via `ElaroSecurityUtils.validateCRUDAccess()`
- [ ] All @AuraEnabled methods use FLS stripping with `stripInaccessibleFields()`
- [ ] Permission sets updated and tested in sandbox

### Testing ✅

- [ ] Apex test coverage ≥ 85% (verified with `sf apex run test --code-coverage`)
- [ ] LWC test coverage ≥ 80% (verified with `npm run test:unit`)
- [ ] Manual testing completed in full sandbox
- [ ] Load testing with 1000+ compliance records completed
- [ ] Security testing with restricted user profiles completed
- [ ] Governor limit monitoring verified (System Monitor Dashboard)

### Documentation ✅

- [ ] README.md updated with current version number
- [ ] CHANGELOG.md updated with release notes
- [ ] API documentation current (if applicable)
- [ ] Deployment notes documented (this file)
- [ ] Known issues documented

### Stakeholder Communication ✅

- [ ] Deployment window scheduled and communicated
- [ ] Deployment notification sent to all stakeholders
- [ ] Rollback team identified and on standby
- [ ] Customer support team briefed on changes

---

## Deployment Timeline

### Recommended Deployment Window

**Day**: Friday evening (low-traffic period)
**Time**: 6:00 PM - 10:00 PM EST
**Duration**: 2-4 hours (including validation and smoke testing)

### Team Roles

| Role | Responsibility | Contact |
|------|---------------|---------|
| Deployment Lead | Overall coordination | TBD |
| Developer | Technical execution | TBD |
| QA Lead | Post-deployment validation | TBD |
| Security Reviewer | Security sign-off | TBD |
| Customer Support | User communication | TBD |

---

## Pre-Deployment Steps

### 1. Backup Current Production State

**Critical**: Always backup before deployment!

```bash
# Navigate to project directory
cd /Users/derickporter/Elaro

# Create timestamped backup directory
BACKUP_DIR="backups/production-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

# Retrieve current production metadata
sf project retrieve start \
  --target-org production \
  --output-dir $BACKUP_DIR

# Verify backup completed
ls -lh $BACKUP_DIR/force-app/

# Archive backup
tar -czf "${BACKUP_DIR}.tar.gz" $BACKUP_DIR
echo "✅ Backup saved to: ${BACKUP_DIR}.tar.gz"
```

### 2. Verify Production Org Connection

```bash
# List all orgs
sf org list

# Test connection to production
sf org open --target-org production --url-only

# Verify you're connected to the RIGHT org
sf org display --target-org production
```

⚠️ **CRITICAL**: Verify the org username and instance URL match production!

### 3. Create Deployment Branch

```bash
# Ensure main is up to date
git checkout main
git pull origin main

# Create release branch
git checkout -b release/v3.0.$(date +%Y%m%d)

# Tag the release
git tag -a v3.0.$(date +%Y%m%d) -m "Production release v3.0 - $(date +%Y-%m-%d)"
git push origin --tags
```

---

## Deployment Steps

### Step 1: Validate Deployment (DRY RUN)

**Duration**: 15-30 minutes

This step validates the deployment without making changes.

```bash
# Run validation check
sf project deploy start \
  --target-org production \
  --dry-run \
  --test-level RunLocalTests \
  --verbose \
  2>&1 | tee logs/validation-$(date +%Y%m%d-%H%M%S).log
```

**Expected Output**:
```
Status: Succeeded
Test Result: 850 out of 850 (100%)
Code Coverage: 87%
```

**Validation Criteria**:
- [ ] Status: `Succeeded`
- [ ] All tests pass (100%)
- [ ] Code coverage ≥ 85%
- [ ] No component failures
- [ ] No test failures

❌ **If validation fails**: Stop deployment, investigate errors, fix in sandbox, re-test.

### Step 2: Deploy to Production

**Duration**: 30-60 minutes

```bash
# Execute deployment with tests
sf project deploy start \
  --target-org production \
  --test-level RunLocalTests \
  --verbose \
  2>&1 | tee logs/deployment-$(date +%Y%m%d-%H%M%S).log
```

**Monitor Deployment Progress**:
```bash
# Check deployment status (in separate terminal)
sf project deploy report --target-org production
```

**Expected Output**:
```
=== Deployed Source
STATE FULL NAME TYPE FILE PATH
───── ───────── ──── ─────────
Add   ComplianceDashboardController ApexClass ...
Add   ElaroLogger ApexClass ...
...

Deployment Status: Succeeded
Tests Complete: 850/850 (100%)
Code Coverage: 87%
```

### Step 3: Post-Deployment Verification

**Duration**: 15-30 minutes

#### 3.1 Smoke Tests

**Access Production Org**:
```bash
sf org open --target-org production
```

**Manual Smoke Tests** (5-10 minutes):

1. **Login & Navigation**
   - [ ] Login to production org
   - [ ] Navigate to Elaro app
   - [ ] Verify app loads without errors

2. **Compliance Dashboard**
   - [ ] Navigate to Compliance Dashboard
   - [ ] Verify dashboard widgets load
   - [ ] Check compliance gaps display correctly
   - [ ] Verify no console errors (F12 Developer Tools)

3. **Core Functionality**
   - [ ] Create test compliance gap (manually)
   - [ ] Verify gap appears in dashboard
   - [ ] Verify audit trail logging works
   - [ ] Test quick actions (if available)

4. **System Monitor Dashboard**
   - [ ] Navigate to System Monitor Dashboard
   - [ ] Verify governor limit gauges display
   - [ ] Check API usage metrics
   - [ ] Verify no alerts triggered

#### 3.2 Automated Verification

```bash
# Run post-deployment verification tests
sf apex run test \
  --test-level RunLocalTests \
  --target-org production \
  --code-coverage \
  --result-format human \
  2>&1 | tee logs/post-deployment-tests-$(date +%Y%m%d-%H%M%S).log
```

**Verification Criteria**:
- [ ] All tests pass
- [ ] Code coverage ≥ 85%
- [ ] No new debug logs with ERROR severity
- [ ] No new exceptions in exception logs

#### 3.3 Monitor for Errors

**Check Debug Logs** (First 30 minutes):
```bash
# Query recent logs with errors
sf data query \
  --query "SELECT Id, Request, Operation, Status, DurationMilliseconds FROM ApexLog WHERE Status = 'Failure' AND CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 10" \
  --target-org production
```

**Expected**: No new failure logs related to deployment.

**Check Scheduled Jobs**:
```bash
# Verify scheduled jobs are running
sf data query \
  --query "SELECT Id, CronJobDetail.Name, State, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Elaro%' ORDER BY NextFireTime" \
  --target-org production
```

**Expected**: All Elaro* scheduled jobs in `WAITING` state with valid `NextFireTime`.

---

## Monitoring & Alerts (First 24 Hours)

### Critical Metrics to Monitor

1. **Governor Limits Dashboard**
   - [ ] SOQL queries < 80% of limit
   - [ ] DML statements < 80% of limit
   - [ ] CPU time < 75% of limit
   - [ ] Heap size < 70% of limit

2. **Compliance Gap Activity**
   - [ ] New gaps being created successfully
   - [ ] Gap status transitions working
   - [ ] Remediation workflows executing

3. **Audit Trail Logging**
   - [ ] Audit logs being created
   - [ ] Retention policies enforced
   - [ ] No gaps in audit trail

4. **User Access**
   - [ ] Users can login successfully
   - [ ] Permission sets applied correctly
   - [ ] FLS checks not blocking legitimate access

### Alert Channels

- **Email**: ops-team@solentra.com
- **Slack**: #elaro-production-alerts
- **PagerDuty**: Production on-call rotation

### Escalation Path

| Severity | Response Time | Escalation |
|----------|---------------|------------|
| CRITICAL | 15 minutes | Deployment Lead → CTO |
| HIGH | 1 hour | Deployment Lead → Engineering Manager |
| MEDIUM | 4 hours | Support Team → Deployment Lead |
| LOW | 24 hours | Support Team |

---

## Rollback Procedure (If Needed)

**Trigger Criteria**:
- Critical functionality broken
- >10% of users unable to access system
- Data integrity issues
- Security vulnerabilities discovered

### Quick Rollback (Option 1)

**Duration**: 15-30 minutes

```bash
# Navigate to backup directory
cd /Users/derickporter/Elaro

# Find most recent backup
ls -lt backups/ | head -5

# Deploy backup to production
BACKUP_DIR="backups/production-backup-YYYYMMDD-HHMMSS"

sf project deploy start \
  --target-org production \
  --source-dir $BACKUP_DIR/force-app \
  --test-level RunLocalTests \
  --verbose
```

### Destructive Rollback (Option 2)

**Use only if schema changes were made and Option 1 fails.**

```bash
# Contact Salesforce Support for org restore from backup snapshot
# Support Case Priority: P1 - Critical
# Include: Org ID, Backup timestamp, Reason for restore
```

**Salesforce Support**: 1-800-NO-SOFTWARE

### Post-Rollback Actions

- [ ] Notify all stakeholders of rollback
- [ ] Create incident post-mortem document
- [ ] Schedule retrospective meeting
- [ ] Update deployment checklist based on lessons learned
- [ ] Fix issues in sandbox before next deployment attempt

---

## Post-Deployment Checklist

### Immediate (Within 1 Hour)

- [ ] Smoke tests passed
- [ ] Automated tests passed
- [ ] No critical errors in logs
- [ ] System Monitor Dashboard shows healthy metrics
- [ ] Scheduled jobs verified running
- [ ] Deployment announcement sent to stakeholders

### First 24 Hours

- [ ] Monitor governor limits dashboard
- [ ] Review debug logs for warnings/errors
- [ ] Verify audit trail logging continues
- [ ] Check compliance gap creation rate
- [ ] Monitor user feedback channels

### First Week

- [ ] Review production metrics vs. baseline
- [ ] Collect user feedback
- [ ] Document any issues or bugs
- [ ] Plan hotfix deployment if needed
- [ ] Update runbook based on lessons learned

---

## Scheduled Jobs Verification

**Critical Elaro Scheduled Jobs**:

| Job Name | Frequency | Purpose | Verification Query |
|----------|-----------|---------|-------------------|
| ElaroAuditTrailPoller | Every 15 min | Poll audit trail events | Check `Elaro_Audit_Log__c` for recent records |
| RetentionEnforcementScheduler | Daily 2 AM | Enforce data retention | Check scheduler last run time |
| ConsentExpirationScheduler | Daily 3 AM | Check consent expiration | Verify consent records processed |
| ElaroCCPASLAMonitorScheduler | Hourly | Monitor CCPA SLA | Check SLA violations count |
| ElaroGLBAAnnualNoticeBatch | Yearly | GLBA annual notice | Verify scheduled for next year |

**Verification Command**:
```bash
sf data query \
  --query "SELECT Id, CronJobDetail.Name, State, NextFireTime, PreviousFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Elaro%'" \
  --target-org production
```

---

## Known Issues & Workarounds

### Issue #1: Large Data Volume Performance

**Symptom**: Dashboard loads slowly with >10,000 compliance gaps
**Workaround**: Enable pagination, set default filter to "Last 90 Days"
**Permanent Fix**: Planned for v3.1 (scheduled query optimization)

### Issue #2: PDF Generation Timeout

**Symptom**: PDF export fails for reports >100 pages
**Workaround**: Split report into smaller date ranges
**Permanent Fix**: Planned for v3.1 (async PDF generation)

---

## Deployment Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| Deployment Lead | TBD | TBD | TBD |
| Engineering Manager | TBD | TBD | TBD |
| Security Lead | TBD | TBD | TBD |
| Customer Support | TBD | TBD | TBD |

---

## Change Log

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-02 | Initial production deployment runbook | Claude Sonnet 4.5 |

---

## Appendix A: Useful Commands

### Check Deployment Status
```bash
sf project deploy report --target-org production
```

### Query Recent Errors
```bash
sf data query \
  --query "SELECT Id, Message, CreatedDate FROM ApexLog WHERE LogCategory = 'Apex' AND CreatedDate = TODAY LIMIT 100" \
  --target-org production
```

### View Governor Limits
```bash
sf data query \
  --query "SELECT Id, Name, Value__c FROM Governor_Limit_Snapshot__c WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 10" \
  --target-org production
```

### Check Permission Set Assignments
```bash
sf data query \
  --query "SELECT Id, Assignee.Name, PermissionSet.Name FROM PermissionSetAssignment WHERE PermissionSet.Name LIKE 'Elaro%'" \
  --target-org production
```

---

## Appendix B: Emergency Contacts

**Salesforce Support**: 1-800-NO-SOFTWARE (1-800-667-6389)
**Premier Success Support**: Available 24/7 for P1 issues

**Internal Escalation**:
1. Deployment Lead
2. Engineering Manager
3. VP of Engineering
4. CTO

---

**END OF RUNBOOK**
