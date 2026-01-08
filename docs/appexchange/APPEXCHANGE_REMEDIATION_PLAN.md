# AppExchange Readiness: Complete Remediation Plan

**Generated**: January 2026  
**Target**: AppExchange Submission  
**Current Status**: 29% test coverage, P0 security issues identified

---

## Overview

This plan addresses all four priorities to prepare Prometheion for AppExchange submission:
1. **P0 Security Fixes** (Blocking for security review)
2. **Test Coverage Improvement** (29% → 75% required)
3. **P1 Reliability Issues** (Governor limits, error handling, permission sets)
4. **Security Review Preparation** (Documentation, final checks)

---

## Phase 1: P0 Security Fixes (Blocking - Week 1, Days 1-2)

### 1.1 Fix Deterministic Hashing in PrometheionReasoningEngine

**File**: `force-app/main/default/classes/PrometheionReasoningEngine.cls`

**Issue**: `generateCorrelationId()` uses `System.now().getTime()` making correlation IDs non-deterministic (line 196)

**Current Code**:
```apex
private static String generateCorrelationId(String nodeHash) {
    String input = nodeHash + '|' + UserInfo.getUserId() + '|' + System.now().getTime();
    Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(input));
    return EncodingUtil.base64Encode(hash).substring(0, 16);
}
```

**Fix**: Remove time component, use only stable inputs
```apex
private static String generateCorrelationId(String nodeHash) {
    String input = nodeHash + '|' + UserInfo.getUserId();
    Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(input));
    return EncodingUtil.base64Encode(hash).substring(0, 16);
}
```

**Impact**: Correlation IDs become deterministic and reproducible for audit trails

---

### 1.2 Implement Audit Logging in PrometheionAISettingsController

**File**: `force-app/main/default/classes/PrometheionAISettingsController.cls`

**Issue**: TODO comment indicates audit logging not implemented (line 125)

**Current Code**:
```apex
private static void logAuditEvent(String action, String entityType, String entityId, String details) {
    try {
        System.debug(LoggingLevel.INFO, '[Audit] ' + action + ' - ' + entityType + ' (' + entityId + '): ' + details);
        // TODO: Insert into Prometheion_Audit_Log__c when object is created
    } catch (Exception e) {
        System.debug(LoggingLevel.WARN, 'PrometheionAISettingsController: Failed to log audit event: ' + e.getMessage());
    }
}
```

**Fix**: Implement actual audit log insertion
```apex
private static void logAuditEvent(String action, String entityType, String entityId, String details) {
    try {
        Prometheion_Audit_Log__c auditLog = new Prometheion_Audit_Log__c(
            Action__c = action,
            Entity_Type__c = entityType,
            Entity_Id__c = entityId,
            Details__c = details,
            User__c = UserInfo.getUserId(),
            Timestamp__c = System.now()
        );
        
        // Strip inaccessible fields for security
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.CREATABLE,
            new List<Prometheion_Audit_Log__c>{ auditLog }
        );
        
        List<Prometheion_Audit_Log__c> sanitizedLogs = decision.getRecords();
        if (!sanitizedLogs.isEmpty()) {
            insert sanitizedLogs[0];
        }
    } catch (Exception e) {
        // Don't fail the main operation if audit logging fails
        System.debug(LoggingLevel.WARN, 'PrometheionAISettingsController: Failed to log audit event: ' + e.getMessage());
    }
}
```

**Note**: Verify `Prometheion_Audit_Log__c` object exists and has required fields

---

### 1.3 Verify PrometheionGraphIndexer Deterministic Hashing

**File**: `force-app/main/default/classes/PrometheionGraphIndexer.cls`

**Status**: ✅ Already fixed (lines 62-66 use only stable inputs: entityType, entityId, framework)

**Action**: Verify no other methods use time-based hashing
- Check `generateCorrelationId()` method (line 181) - uses System.now() for correlation IDs (acceptable, not for deterministic hashing)

---

### 1.4 Verify CRUD/FLS Enforcement

**Files to verify**:
- ✅ `PrometheionAISettingsController.cls` - Already uses `Security.stripInaccessible`
- ✅ `PrometheionReasoningEngine.cls` - Uses `without sharing` (documented justification)
- ✅ `PrometheionGraphIndexer.cls` - Uses `with sharing` and `WITH USER_MODE`

**Action**: Document all `without sharing` classes in `ENTRY_POINT_AUDIT.md`

---

## Phase 2: Test Coverage Improvement (29% → 75%) - Week 1, Days 3-5

### 2.1 Identify Missing Test Classes

**Current State**:
- Production classes: 54
- Test classes: 24
- **Gap**: ~30 classes need tests or improved coverage

**Priority classes needing tests**:

1. **PrometheionAISettingsController** (0% coverage)
   - Create `PrometheionAISettingsControllerTest.cls`
   - Test scenarios:
     - `getSettings()` with null org defaults (should create)
     - `getSettings()` with existing defaults (should return)
     - `saveSettings()` with valid data
     - `saveSettings()` with CRUD/FLS enforcement (limited user)
     - Audit logging on save
     - Bulk operations (200+ records)

2. **PrometheionComplianceScorer** (has test, verify coverage)
   - Enhance `PrometheionComplianceScorerTest.cls`
   - Add bulk tests (200+ permission sets)
   - Add governor limit tests
   - Add error path tests

3. **PerformanceRuleEngine** (has test, verify coverage)
   - Enhance `PerformanceRuleEngineTest.cls`
   - Add null validation tests
   - Add error path tests
   - Add platform event publishing failure tests

4. **PrometheionReasoningEngine** (has test, verify coverage)
   - Enhance `PrometheionReasoningEngineTest.cls`
   - Add null safety tests
   - Add deterministic hash tests
   - Add Big Object query tests

5. **Framework Services** (verify all have tests)
   - ✅ `PrometheionGDPRDataErasureServiceTest.cls` - exists
   - ✅ `PrometheionCCPADataInventoryServiceTest.cls` - exists
   - ✅ `PrometheionGLBAPrivacyNoticeServiceTest.cls` - exists
   - ✅ `PrometheionISO27001AccessReviewServiceTest.cls` - exists
   - ⚠️ `PrometheionHIPAAComplianceService` - verify test exists
   - ⚠️ `PrometheionSOC2ComplianceService` - verify test exists
   - ⚠️ `PrometheionPCIDSSComplianceService` - verify test exists

### 2.2 Test Coverage Targets

| Class Category | Target Coverage | Priority |
|----------------|----------------|----------|
| Controllers | 90%+ | P1 |
| Services | 80%+ | P1 |
| Framework Services | 80%+ | P1 |
| Utilities | 75%+ | P2 |
| **Overall** | **75%+** | **P0** |

### 2.3 Test Class Template

```apex
@IsTest
private class PrometheionAISettingsControllerTest {
    @TestSetup
    static void setupTestData() {
        // Create test data
    }
    
    @IsTest
    static void testGetSettings_CreatesDefaults() {
        // Test: getSettings() creates org defaults when none exist
    }
    
    @IsTest
    static void testGetSettings_ReturnsExisting() {
        // Test: getSettings() returns existing defaults
    }
    
    @IsTest
    static void testSaveSettings_PositivePath() {
        // Test: saveSettings() with valid data
    }
    
    @IsTest
    static void testSaveSettings_InsufficientPermissions() {
        // Test: saveSettings() with limited user (CRUD/FLS enforcement)
        User limitedUser = TestDataFactory.createLimitedUser();
        System.runAs(limitedUser) {
            // Expect: InsufficientAccessException or Security.stripInaccessible filtering
        }
    }
    
    @IsTest
    static void testSaveSettings_AuditLogging() {
        // Test: Audit log created on save
    }
    
    @IsTest
    static void testSaveSettings_BulkOperation() {
        // Test: Bulk save (200+ records)
    }
}
```

---

## Phase 3: P1 Reliability Improvements - Week 2, Days 1-3

### 3.1 Batch Queries in PrometheionComplianceScorer

**File**: `force-app/main/default/classes/PrometheionComplianceScorer.cls`

**Issue**: Multiple synchronous COUNT queries risk governor exhaustion

**Current Pattern** (example):
```apex
List<AggregateResult> modifyAllResults = [
    SELECT COUNT(Id) assignmentCount
    FROM PermissionSetAssignment
    WHERE PermissionSet.PermissionsModifyAllData = true
    AND Assignee.IsActive = true
    WITH SECURITY_ENFORCED
];
```

**Fix**: 
1. Use aggregate queries with GROUP BY where possible
2. Cache results within transaction scope
3. Add limit guards (max 1000 records per query)
4. Combine related queries where possible

**Methods to fix**:
- `calculatePermissionSprawlScore()` - Batch permission set queries
- `calculateAuditTrailScore()` - Batch field history queries
- `calculateConfigDriftScore()` - Batch graph queries

**Example Fix**:
```apex
private static ScoreFactor calculatePermissionSprawlScore() {
    // Cache results to avoid duplicate queries
    if (permissionSprawlCache != null) {
        return permissionSprawlCache;
    }
    
    // Single aggregate query instead of multiple
    List<AggregateResult> results = [
        SELECT 
            COUNT(Id) totalAssignments,
            COUNT_DISTINCT(AssigneeId) uniqueUsers
        FROM PermissionSetAssignment
        WHERE PermissionSet.PermissionsModifyAllData = true
        AND Assignee.IsActive = true
        WITH SECURITY_ENFORCED
        LIMIT 1000
    ];
    
    // Calculate score from aggregate results
    // Cache for reuse
    permissionSprawlCache = new ScoreFactor(...);
    return permissionSprawlCache;
}
```

---

### 3.2 Add Permission Set Access for Framework Services

**File**: `force-app/main/default/permissionsets/Prometheion_Admin.permissionset-meta.xml`

**Issue**: Missing class access for framework services (GDPR, CCPA, GLBA, ISO27001, HIPAA, SOC2, PCI-DSS)

**Current State**: Only has access to:
- `PrometheionComplianceCopilot`
- `PrometheionComplianceScorer`

**Fix**: Add `<classAccesses>` entries for:
```xml
<classAccesses>
    <apexClass>PrometheionGDPRComplianceService</apexClass>
    <enabled>true</enabled>
</classAccesses>
<classAccesses>
    <apexClass>PrometheionCCPAComplianceService</apexClass>
    <enabled>true</enabled>
</classAccesses>
<classAccesses>
    <apexClass>PrometheionGLBAPrivacyNoticeService</apexClass>
    <enabled>true</enabled>
</classAccesses>
<classAccesses>
    <apexClass>PrometheionISO27001AccessReviewService</apexClass>
    <enabled>true</enabled>
</classAccesses>
<classAccesses>
    <apexClass>PrometheionHIPAAComplianceService</apexClass>
    <enabled>true</enabled>
</classAccesses>
<classAccesses>
    <apexClass>PrometheionSOC2ComplianceService</apexClass>
    <enabled>true</enabled>
</classAccesses>
<classAccesses>
    <apexClass>PrometheionPCIDSSComplianceService</apexClass>
    <enabled>true</enabled>
</classAccesses>
```

---

### 3.3 Create Prometheion_User Permission Set

**File**: `force-app/main/default/permissionsets/Prometheion_User.permissionset-meta.xml` (new file)

**Purpose**: Read-only access for end users

**Permissions**:
- Read access to compliance scores
- Read access to compliance reports
- No write access
- No admin functions

**Template**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
  <hasActivationRequired>false</hasActivationRequired>
  <label>Prometheion User</label>
  <description>Read-only access to Prometheion compliance features</description>
  <classAccesses>
    <apexClass>PrometheionComplianceScorer</apexClass>
    <enabled>true</enabled>
  </classAccesses>
  <!-- Add object permissions for read-only access -->
</PermissionSet>
```

---

### 3.4 Enhance Error Handling in PerformanceRuleEngine

**File**: `force-app/main/default/classes/PerformanceRuleEngine.cls`

**Status**: ✅ Already has improvements (safe parsing, helper methods)

**Action**: Verify error messages are user-safe (no stack traces)
- Check all `throw` statements
- Check all `AuraHandledException` messages
- Ensure no sensitive data in error messages

**Action**: Add retry logic for platform event publishing failures
- Implement exponential backoff
- Log failures to `Integration_Error__c`

---

## Phase 4: Security Review Preparation - Week 2, Days 4-5

### 4.1 Complete Entry Point Audit Documentation

**File**: `ENTRY_POINT_AUDIT.md`

**Actions**:
1. Update with all fixes applied
2. Document all `without sharing` justifications
3. Verify all entry points mapped to permission sets
4. Add missing entry points if any

**Template for Entry Point**:
```markdown
| Entry Point | Class | Method | Intended Users | Permission Set | Security Model |
|-------------|-------|--------|----------------|----------------|----------------|
| getComplianceScore | PrometheionComplianceScorer | calculateReadinessScore | All Users | Prometheion_User | with sharing |
```

---

### 4.2 Create Security Review Checklist

**File**: `SECURITY_REVIEW_CHECKLIST.md` (new file)

**Contents**:
- [ ] All P0 security issues resolved
- [ ] Test coverage ≥75%
- [ ] No hardcoded credentials (grep for apiKey, password, secret, token)
- [ ] All entry points secured with permission sets
- [ ] CRUD/FLS enforced on all DML operations
- [ ] Input validation on all public methods
- [ ] Error messages don't leak sensitive data
- [ ] No SOQL injection vulnerabilities
- [ ] No XSS vulnerabilities in LWC
- [ ] All `without sharing` classes documented
- [ ] Named Credentials used (no hardcoded URLs)
- [ ] Debug logs sanitized (no secrets)

---

### 4.3 Run Code Analyzer

**Command**:
```bash
sf code-analyzer run --target force-app/ --outfile security-report.html
```

**Actions**:
1. Review all findings
2. Fix critical and high severity issues
3. Document any suppressions with justification
4. Create `CODE_ANALYZER_SUPPRESSIONS.md` if needed

---

### 4.4 Update APP_REVIEW.md

**File**: `APP_REVIEW.md`

**Actions**:
1. Update test coverage percentage (29% → 75%+)
2. Mark security issues as resolved
3. Update overall rating if improved
4. Add security review status

---

## Implementation Timeline

### Week 1: Critical Fixes
- **Days 1-2**: P0 Security Fixes (4-6 hours)
  - Fix deterministic hashing
  - Implement audit logging
  - Verify CRUD/FLS

- **Days 3-5**: Test Coverage Sprint (12-16 hours)
  - Create missing test classes
  - Enhance existing tests
  - Achieve 75% coverage

### Week 2: Reliability & Preparation
- **Days 1-3**: P1 Reliability (6-8 hours)
  - Batch queries in ComplianceScorer
  - Add permission set access
  - Create Prometheion_User permission set
  - Enhance error handling

- **Days 4-5**: Security Review Prep (4-6 hours)
  - Complete documentation
  - Run code analyzer
  - Final verification

**Total Estimated Effort**: 26-36 hours (1.5-2 weeks)

---

## Success Criteria

- [ ] All P0 security issues resolved
- [ ] Test coverage ≥75% (verified via `sf apex run test --code-coverage`)
- [ ] All P1 reliability issues addressed
- [ ] Security review checklist complete
- [ ] Code analyzer shows zero critical findings
- [ ] All entry points documented and secured
- [ ] Permission sets configured correctly
- [ ] Documentation updated

---

## Verification Commands

```bash
# Test coverage
sf apex run test --code-coverage --result-format human

# Code analyzer
sf code-analyzer run --target force-app/ --outfile security-report.html

# Find hardcoded credentials
grep -rn "apiKey\|password\|secret\|token" force-app/ --include="*.cls" --include="*.js"

# Find entry points
grep -rn "@AuraEnabled\|@InvocableMethod\|@RestResource" force-app/

# Find without sharing
grep -rn "without sharing" force-app/
```

---

## Next Steps

1. Start with Phase 1 (P0 Security) - blocking for security review
2. Proceed to Phase 2 (Test Coverage) - required for AppExchange
3. Complete Phase 3 (P1 Reliability) - improves production readiness
4. Finish with Phase 4 (Security Review Prep) - final submission preparation

---

*Plan generated: January 2026*  
*Target completion: 2 weeks from start date*
