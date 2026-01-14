# Next Steps for Prometheion Migration

## Overview
The codebase has been updated with best practices and security improvements. The following steps are recommended to complete the migration from Sentinel/OpsGuardian to Prometheion.

## Priority 1: File Cleanup & Renaming

### A. Remove Duplicate Class Files
Several classes exist in both old (Sentinel*) and new (Prometheion*) versions. The new versions have the latest code:

**Files to DELETE (old versions with updated content):**
- `force-app/main/default/classes/SentinelAISettingsController.cls` (replaced by `PrometheionAISettingsController.cls`)
- `force-app/main/default/classes/SentinelComplianceScorer.cls` (replaced by `PrometheionComplianceScorer.cls`)
- `force-app/main/default/classes/SentinelLegalDocumentGenerator.cls` (content updated to Prometheion)

**Files to RENAME (content updated but filename unchanged):**
- `SentinelGraphIndexer.cls` → `PrometheionGraphIndexer.cls`
- `SentinelReasoningEngine.cls` → `PrometheionReasoningEngine.cls`
- `SentinelComplianceScorerTest.cls` → `PrometheionComplianceScorerTest.cls`
- `SentinelGraphIndexerTest.cls` → `PrometheionGraphIndexerTest.cls`
- `SentinelReasoningEngineTest.cls` → `PrometheionReasoningEngineTest.cls`
- `SentinelAlertTriggerTest.cls` → `PrometheionAlertTriggerTest.cls`

### B. Update Configuration Files

1. **Scratch Org Definition**
   - Rename: `config/sentinel-scratch-def.json` → `config/prometheion-scratch-def.json`
   - Update content (orgName, etc.)

2. **Workspace File**
   - `Sentinel.code-workspace` → `Prometheion.code-workspace`

### C. Update LWC Components

**Folders to RENAME:**
- `sentinelAiSettings/` → `prometheionAiSettings/`
- `sentinelReadinessScore/` → `prometheionReadinessScore/`

**Files to UPDATE:**
- Update import paths in any components that reference these LWCs

### D. Update Triggers & Objects

**Triggers:**
- `SentinelAlertTrigger.trigger` → `PrometheionAlertTrigger.trigger`
- Update trigger content to use `Prometheion_Alert_Event__e`

**Permission Sets:**
- `Sentinel_Admin.permissionset-meta.xml` → `Prometheion_Admin.permissionset-meta.xml`
- Update label and references

**Note:** Object API names (Sentinel_*__c) cannot be renamed in Salesforce without data migration. Consider:
- Option A: Keep object names as-is (recommended for production)
- Option B: Create new objects with Prometheion naming and migrate data

## Priority 2: Testing & Validation

### A. Unit Tests
1. Run all test classes to ensure they pass with new naming
2. Update any hardcoded class names in tests
3. Verify test coverage remains above 75%

### B. Integration Tests
1. Test Slack notification queueable with retry logic
2. Test Platform Cache implementation
3. Test compliance scoring with caching
4. Validate all API endpoints

### C. Security Review
1. Verify all SOQL queries use `WITH SECURITY_ENFORCED`
2. Confirm `Security.stripInaccessible()` is used on DML
3. Review permission sets and sharing settings
4. Validate input sanitization

## Priority 3: Deployment Preparation

### A. Platform Cache Setup
1. Create Platform Cache partition: `PrometheionCompliance`
   - Setup → Platform Cache → Partitions
   - Create new partition: `PrometheionCompliance`
   - Allocate cache capacity (recommended: 5MB minimum)

### B. Named Credentials
1. Verify `Slack_Webhook` named credential exists
2. Test connectivity to Slack endpoint

### C. Custom Settings
1. Verify `Prometheion_AI_Settings__c` custom settings exist
2. Create org default record if needed
3. Verify `CCX_Settings__c` has appropriate values

### D. Permission Sets
1. Deploy `Prometheion_Admin` permission set
2. Assign to appropriate users
3. Verify field-level security settings

## Priority 4: Documentation Updates

### A. Update Documentation Files
- `README.md` - Update all references from Sentinel to Prometheion
- `docs/code-review.md` - Mark completed items
- `ROADMAP.md` - Update with Prometheion branding

### B. API Documentation
- Update any API documentation with new class names
- Document new Platform Cache implementation
- Document Queueable notification system

## Priority 5: Monitoring & Operations

### A. Set Up Monitoring
1. Create dashboards for compliance scores
2. Set up alerts for notification failures
3. Monitor Platform Cache hit rates

### B. Performance Optimization
1. Monitor compliance score calculation performance
2. Review Platform Cache effectiveness
3. Optimize SOQL queries if needed

## Recommended Action Plan

### Phase 1: Cleanup (Week 1)
1. Delete duplicate old class files
2. Rename class files that were updated
3. Update configuration files
4. Run tests to verify everything works

### Phase 2: LWC & UI (Week 1-2)
1. Rename LWC component folders
2. Update all import references
3. Test UI components end-to-end
4. Update permission sets

### Phase 3: Testing (Week 2)
1. Comprehensive unit test run
2. Integration testing
3. Security review
4. Performance testing

### Phase 4: Deployment (Week 2-3)
1. Set up Platform Cache partition
2. Configure named credentials
3. Deploy to sandbox first
4. User acceptance testing
5. Production deployment

## Important Notes

⚠️ **Object API Names:** Changing object API names (Sentinel_*__c → Prometheion_*__c) requires:
- Data migration scripts
- Updating all references in code
- Potential data loss if not done carefully
- Consider keeping object names as-is for production stability

⚠️ **Breaking Changes:** The Queueable implementation replaces @future methods. Update any code that calls:
- `SlackNotifier.notifyAsync()` → now uses Queueable internally
- `SlackNotifier.notifyRichAsync()` → now uses Queueable internally

⚠️ **Platform Cache:** Ensure Platform Cache partition exists before deployment, or the compliance scorer will fall back to direct queries (still functional, just slower).

## Quick Start Commands

```bash
# Run tests
sf apex run test --test-level RunLocalTests --code-coverage --result-format human

# Deploy to sandbox
sf project deploy start --target-org sandbox-alias

# Validate deployment
sf project validate source
```

## Questions to Consider

1. Do you want to rename Salesforce object API names, or keep them as Sentinel_*__c?
2. Should we keep old files for reference during migration period?
3. What's the target deployment timeline?
4. Do you have Platform Cache licenses available?

