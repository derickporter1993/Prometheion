# Elaro Deployment Checklist

**Version:** 3.0.0  
**Last Updated:** 2025-12-25

## Pre-Deployment Verification

### ✅ Code Quality Checks
- [ ] All code follows Salesforce best practices (Dec 2025 standards)
- [ ] All SOQL queries use `WITH SECURITY_ENFORCED`
- [ ] All DML operations use `Security.stripInaccessible()`
- [ ] No hardcoded IDs or sensitive data
- [ ] All classes have proper error handling
- [ ] Platform Cache implemented for performance-critical operations
- [ ] Queueable classes used instead of `@future` methods

### ✅ Naming & Cleanup
- [ ] All Sentinel/OpsGuardian references replaced with Elaro
- [ ] All object metadata files updated
- [ ] All permission sets renamed
- [ ] All configuration files updated
- [ ] Documentation updated

### ✅ Test Coverage
- [ ] Run all unit tests: `sf apex run test --test-level RunLocalTests --code-coverage`
- [ ] Verify test coverage ≥ 75%
- [ ] All test classes pass
- [ ] Test Platform Cache functionality
- [ ] Test Queueable notification system
- [ ] Test compliance scoring

### ✅ Metadata Validation
- [ ] Validate metadata: `sf project validate source`
- [ ] Check for missing dependencies
- [ ] Verify all custom objects deploy correctly
- [ ] Verify Platform Cache partition configuration
- [ ] Check permission sets are valid

---

## Deployment Steps

### Step 1: Scratch Org Testing (Recommended First)

```bash
# Create scratch org with Platform Cache
sf org create scratch -f config/elaro-scratch-def.json -a elaro-dev -d -y 30

# Deploy metadata
sf project deploy start -o elaro-dev --wait 10

# Run tests
sf apex run test --test-level RunLocalTests --code-coverage -o elaro-dev

# Assign permission set
sf org assign permset -n Elaro_Admin -o elaro-dev

# Verify Platform Cache partition exists
# (Check in Setup → Platform Cache → Partitions)

# Open org to verify
sf org open -o elaro-dev
```

### Step 2: Sandbox Deployment

#### A. Pre-Deployment Setup

1. **Platform Cache Configuration**
   - Navigate to: Setup → Platform Cache → Partitions
   - Create new partition:
     - **Label:** ElaroCompliance
     - **Type:** Org Cache
     - **Description:** Elaro Compliance cache partition for storing compliance scores
     - **Capacity:** Minimum 5MB (recommended 10MB+)
   - Save the partition

2. **Named Credentials** (if using Slack integration)
   - Navigate to: Setup → Named Credentials
   - Verify `Slack_Webhook` exists and is configured
   - Test connectivity if needed

3. **Custom Settings Preparation**
   - `Elaro_AI_Settings__c` will be created during deployment
   - `CCX_Settings__c` should exist (verify or create)

#### B. Deploy Metadata

```bash
# Deploy to sandbox
sf project deploy start --target-org sandbox-alias --wait 10

# Verify deployment succeeded
sf project deploy report --target-org sandbox-alias
```

#### C. Post-Deployment Configuration

1. **Custom Settings**
   ```apex
   // Create org default for Elaro_AI_Settings__c
   Elaro_AI_Settings__c settings = Elaro_AI_Settings__c.getInstance();
   if (settings == null) {
       settings = new Elaro_AI_Settings__c(
           SetupOwnerId = UserInfo.getOrganizationId(),
           Enable_AI_Reasoning__c = true,
           Confidence_Threshold__c = 0.85,
           Require_Human_Approval__c = true,
           Auto_Remediation_Enabled__c = false
       );
       insert settings;
   }
   ```

2. **Permission Sets**
   ```bash
   # Assign to admin users
   sf org assign permset -n Elaro_Admin -u admin-user@example.com -o sandbox-alias
   ```

3. **Initial Data Setup**
   ```bash
   # Run baseline report generation (if needed)
   sf apex run -f scripts/generate-baseline-report.apex -o sandbox-alias
   ```

### Step 3: Production Deployment

**⚠️ IMPORTANT:** Only proceed after successful sandbox testing and user acceptance.

1. **Final Verification**
   - [ ] All tests pass in sandbox
   - [ ] Platform Cache partition configured
   - [ ] Named credentials configured
   - [ ] Permission sets assigned to appropriate users
   - [ ] Custom settings configured
   - [ ] User acceptance testing completed
   - [ ] Rollback plan documented

2. **Deploy to Production**
   ```bash
   # Deploy to production (use caution!)
   sf project deploy start --target-org production-alias --wait 10
   ```

3. **Post-Production Steps**
   - [ ] Verify Platform Cache partition exists
   - [ ] Create org default custom settings
   - [ ] Assign permission sets
   - [ ] Run initial baseline report
   - [ ] Monitor for errors in first 24 hours
   - [ ] Verify compliance scoring works
   - [ ] Test Slack notifications (if configured)

---

## Rollback Plan

If deployment fails or issues are discovered:

1. **Metadata Rollback**
   ```bash
   # Retrieve previous version from version control
   git checkout <previous-commit-hash> -- force-app/
   
   # Deploy previous version
   sf project deploy start --target-org target-alias
   ```

2. **Data Considerations**
   - Elaro objects (Big Object, Custom Settings) contain audit data
   - Decide whether to preserve or clear data before rollback
   - Document data migration strategy if needed

3. **Configuration Cleanup**
   - Remove Platform Cache partition if needed
   - Clean up permission set assignments
   - Remove custom settings if necessary

---

## Post-Deployment Verification

### Functional Tests

- [ ] Navigate to Elaro app/dashboard
- [ ] Verify compliance readiness score calculates correctly
- [ ] Test AI settings configuration page
- [ ] Verify Platform Cache is working (check debug logs for cache hits)
- [ ] Test Slack notifications (if configured)
- [ ] Generate baseline compliance report
- [ ] Verify platform events are publishing correctly
- [ ] Check system monitor dashboard loads

### Performance Tests

- [ ] Compliance score calculation completes in < 5 seconds
- [ ] Platform Cache reduces query time on subsequent calls
- [ ] Dashboard components load within acceptable time
- [ ] No governor limit exceptions in debug logs

### Security Tests

- [ ] Users without Elaro_Admin cannot access admin features
- [ ] FLS is enforced (test with restricted user)
- [ ] SOQL queries respect sharing rules
- [ ] Platform Cache partition access is secure

---

## Monitoring & Maintenance

### First 24 Hours

- [ ] Monitor debug logs for errors
- [ ] Check Platform Cache hit rates
- [ ] Verify no governor limit exceptions
- [ ] Confirm all scheduled jobs are running
- [ ] Monitor Slack notification delivery (if configured)

### Ongoing

- [ ] Review compliance scores weekly
- [ ] Monitor Platform Cache effectiveness
- [ ] Review and optimize slow queries
- [ ] Update custom settings as needed
- [ ] Review audit trail for compliance events

---

## Troubleshooting

### Platform Cache Not Working

**Symptoms:** Cache misses in debug logs, slower performance

**Solution:**
1. Verify partition exists: Setup → Platform Cache → Partitions
2. Check partition name matches: `ElaroCompliance`
3. Verify partition type is "Org Cache" (not Session)
4. Check capacity allocation (increase if needed)
5. Review debug logs for `OrgCacheException`

### Compliance Score Calculation Fails

**Symptoms:** Errors when calling `ElaroComplianceScorer.calculateReadinessScore()`

**Solution:**
1. Check debug logs for specific error
2. Verify custom objects exist (Elaro_Compliance_Graph__b)
3. Check user has necessary permissions
4. Verify SOQL queries aren't hitting governor limits
5. Test with `clearCache()` to reset state

### Slack Notifications Not Working

**Symptoms:** No notifications received in Slack

**Solution:**
1. Verify Named Credential `Slack_Webhook` exists and is configured
2. Check Queueable jobs are executing (Setup → Apex Jobs)
3. Review debug logs for callout errors
4. Test with `SlackNotifier.notifyAsyncQueueable('Test message')`
5. Verify webhook URL is correct in Named Credential

---

## Support Contacts

- **Technical Issues:** Check debug logs and error messages
- **Configuration Questions:** Refer to README.md
- **Best Practices:** See docs/code-review.md

---

**Deployment Sign-Off:**

- [ ] Technical Lead: _________________ Date: _______
- [ ] QA Lead: _________________ Date: _______
- [ ] Product Owner: _________________ Date: _______

