# Phase 1 Implementation Plan

**Created:** 2026-01-08
**Status:** Ready for Implementation
**Estimated Effort:** 82 hours (46h backend + 36h UI)

---

## Executive Summary

Phase 1 addresses all AppExchange-blocking issues. This plan prioritizes tasks by:
1. **Security fixes first** - Critical for AppExchange approval
2. **Test coverage** - Required 75% threshold
3. **Code quality** - Triggers, HTTP callouts

---

## Implementation Order (Backend)

### Block 1: Security Fixes (Priority: CRITICAL)

These must be completed first as they are AppExchange blockers.

#### 1.1 SOQL Security - Add WITH SECURITY_ENFORCED

**File:** `force-app/main/default/classes/PrometheionQuickActionsService.cls`

| Task | Lines | Query Description |
|------|-------|-------------------|
| S1.1 | 63-75 | excessiveAdmins query |
| S1.2 | 104-111 | modAllAssignments query |
| S1.3 | 161-168 | inactiveUsers query |
| S1.4 | 228-233 | assignments query |
| S1.5 | 274-281 | excessiveAssignments query |
| S1.6 | 380-385 | revokeModifyAllData query |
| S1.7 | 422-428 | deactivateInactiveUsers query |
| S1.8 | 469-473 | removePermissionSetAssignment query |

**Implementation:**
```apex
// Add to end of each SELECT...FROM...WHERE clause:
WITH SECURITY_ENFORCED
```

#### 1.2 DML Security - Add CRUD Validation

**File:** `force-app/main/default/classes/PrometheionQuickActionsService.cls`

| Task | Line | Operation | Object |
|------|------|-----------|--------|
| S2.1 | 139 | DELETE | PermissionSetAssignment |
| S2.2 | 236 | DELETE | PermissionSetAssignment |
| S2.3 | 245 | DELETE | PermissionSet |
| S2.4 | 338 | DELETE | (variable) |
| S2.5 | 393 | DELETE | PermissionSetAssignment |
| S2.6 | 441 | UPDATE | User |
| S2.7 | 475 | DELETE | PermissionSetAssignment |

**Implementation Pattern:**
```apex
// For DELETE operations:
if (Schema.sObjectType.ObjectName.isDeletable()) {
    delete records;
} else {
    throw new AuraHandledException('Insufficient permissions to delete records');
}

// For UPDATE operations:
if (Schema.sObjectType.ObjectName.isUpdateable()) {
    update records;
} else {
    throw new AuraHandledException('Insufficient permissions to update records');
}
```

#### 1.3 Additional CRUD Fixes

| Task | File | Line | Operation |
|------|------|------|-----------|
| S3 | ApiUsageSnapshot.cls | 37 | INSERT API_Usage_Snapshot__c |
| S4 | MetadataChangeTracker.cls | 38 | INSERT Metadata_Change__c |
| S5 | PerformanceRuleEngine.cls | 251 | INSERT Performance_Alert_History__c |

#### 1.4 REST Endpoint Authentication

**File:** `force-app/main/default/classes/PrometheionScoreCallback.cls`

**Tasks:**
- S6: Add API key validation at entry point (lines 14-15)
- S7: Remove stack trace from error responses (lines 102-109)

**Prerequisites:**
1. Create Custom Metadata Type: `Prometheion_API_Config__mdt`
2. Add field: `API_Key__c` (Text, 255)
3. Create record: `ScoreCallback`

**Implementation:**
```apex
@HttpPost
global static void handleScoreCallback() {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;

    // Validate API Key
    String apiKey = req.headers.get('X-API-Key');
    if (!validateApiKey(apiKey)) {
        res.statusCode = 401;
        res.responseBody = Blob.valueOf('{"success":false,"error":"Unauthorized"}');
        return;
    }
    // ... existing logic
}

private static Boolean validateApiKey(String apiKey) {
    if (String.isBlank(apiKey)) return false;
    Prometheion_API_Config__mdt config = Prometheion_API_Config__mdt.getInstance('ScoreCallback');
    return config != null && apiKey == config.API_Key__c;
}
```

#### 1.5 URL Injection Fix

**File:** `force-app/main/default/classes/TeamsNotifier.cls`

| Task | Line | Fix |
|------|------|-----|
| S8.1 | 204 | URL encode remediationId |
| S8.2 | 209 | URL encode remediationId |

**Implementation:**
```apex
// Replace:
'url' => orgUrl + '/apex/PrometheionApprove?id=' + result.remediationId
// With:
'url' => orgUrl + '/apex/PrometheionApprove?id=' + EncodingUtil.urlEncode(result.remediationId, 'UTF-8')
```

---

### Block 2: HTTP Callout Fixes (Priority: HIGH)

#### 2.1 Add Timeouts

| Task | File | Lines | Method |
|------|------|-------|--------|
| H1 | TeamsNotifier.cls | 20-25 | notifyAsync |
| H2 | TeamsNotifier.cls | 40-45 | notifyRichAsync |
| H4 | ApiUsageSnapshot.cls | 13-17 | capture |

**Implementation:**
```apex
HttpRequest req = new HttpRequest();
// ... existing setup
req.setTimeout(10000); // Add this line (10 second timeout)
```

#### 2.2 Add Retry Logic

**File:** `force-app/main/default/classes/TeamsNotifier.cls`

**Implementation:**
```apex
private static final Integer MAX_RETRIES = 3;

private static HttpResponse sendWithRetry(HttpRequest req) {
    Integer retryCount = 0;
    HttpResponse res;

    while (retryCount < MAX_RETRIES) {
        try {
            res = new Http().send(req);
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                return res;
            }
            if (res.getStatusCode() == 429 || res.getStatusCode() >= 500) {
                retryCount++;
                System.debug('Retry ' + retryCount + ' after status ' + res.getStatusCode());
            } else {
                return res;
            }
        } catch (Exception e) {
            retryCount++;
            System.debug(LoggingLevel.ERROR, 'Callout failed: ' + e.getMessage());
        }
    }
    return res;
}
```

---

### Block 3: Trigger Improvements (Priority: MEDIUM)

#### 3.1 Create Recursion Guard Utility

**New File:** `force-app/main/default/classes/TriggerRecursionGuard.cls`

```apex
public class TriggerRecursionGuard {
    private static Set<String> runningTriggers = new Set<String>();

    public static Boolean isFirstRun(String triggerName) {
        if (runningTriggers.contains(triggerName)) {
            return false;
        }
        runningTriggers.add(triggerName);
        return true;
    }

    public static void reset(String triggerName) {
        runningTriggers.remove(triggerName);
    }

    @TestVisible
    private static void resetAll() {
        runningTriggers.clear();
    }
}
```

#### 3.2 Create Trigger Handler Classes

For each trigger, create a handler class following this pattern:

**Handler:** `PrometheionAlertTriggerHandler.cls`
```apex
public with sharing class PrometheionAlertTriggerHandler {
    public static void handleAfterInsert(List<Alert__c> newAlerts) {
        // Move business logic from trigger here
    }
}
```

**Updated Trigger:**
```apex
trigger PrometheionAlertTrigger on Alert__c (after insert) {
    if (!TriggerRecursionGuard.isFirstRun('PrometheionAlertTrigger')) {
        return;
    }
    try {
        PrometheionAlertTriggerHandler.handleAfterInsert(Trigger.new);
    } finally {
        TriggerRecursionGuard.reset('PrometheionAlertTrigger');
    }
}
```

---

### Block 4: Test Class Creation (Priority: HIGH)

#### 4.1 New Test Classes Required

| Task | File | Coverage Target |
|------|------|-----------------|
| T1 | PrometheionQuickActionsServiceTest.cls | 75%+ |
| T2 | PrometheionGraphIndexerTest.cls | 75%+ |
| T3 | PrometheionGDPRDataErasureServiceTest.cls | 75%+ |
| T4 | PrometheionScoreCallbackTest.cls | 75%+ |
| T5 | ISO27001QuarterlyReviewSchedulerTest.cls | 75%+ |

**Test Class Template:**
```apex
@IsTest
private class ClassNameTest {

    @TestSetup
    static void setupTestData() {
        // Create test data
    }

    @IsTest
    static void testPositiveCase() {
        Test.startTest();
        // Call method
        Test.stopTest();
        // Assert results
    }

    @IsTest
    static void testNegativeCase() {
        // Test error handling
    }

    @IsTest
    static void testBulkOperations() {
        // Test with 200+ records
    }

    @IsTest
    static void testSecurityException() {
        // Test behavior without permissions
    }
}
```

#### 4.2 Fix Existing Test Classes

| Task | File | Issue | Fix |
|------|------|-------|-----|
| TF1 | PrometheionEventPublisherTest.cls | Meaningless assertions | Replace System.assert(true) with actual verification |
| TF2 | SlackNotifierTest.cls | Meaningless assertions | Same |
| TF3 | DeploymentMetricsTest.cls | Only 1 test method | Expand to 5+ tests |
| TF4 | LimitMetricsTest.cls | Depends on org data | Create test data in @TestSetup |

---

## Implementation Order (UI/LWC) - For Cursor

### Block 5: Event Handler Fixes (Priority: CRITICAL)

| Task | File | Issue |
|------|------|-------|
| E1 | systemMonitorDashboard.html | `onclick="{refresh;}"` → `onclick={refresh}` |
| E2 | prometheionAiSettings.html | 6 malformed handlers |
| E3 | prometheionReadinessScore.html | 2 malformed handlers |

### Block 6: Accessibility (Priority: HIGH)

| Task | Description |
|------|-------------|
| A1 | Add `aria-hidden="true"` to decorative SVG icons |
| A2 | Add text labels to riskHeatmap cells |
| A3 | Fix form input labels in prometheionROICalculator |

### Block 7: Null Safety (Priority: MEDIUM)

Add null checks to templates:
- complianceScoreCard.html
- complianceDashboard.html
- executiveKpiDashboard.html
- riskHeatmap.html

### Block 8: Loading/Error States (Priority: MEDIUM)

Add loading spinners and error states to 12 components.

### Block 9: JavaScript Fixes (Priority: MEDIUM)

| Task | Description |
|------|-------------|
| J1 | Fix error.body null checks |
| J2 | Wrap JSON.parse in try-catch |
| J3 | Remove unnecessary @track decorators |
| J4 | Remove console.log statements |

### Block 10: Jest Tests (Priority: HIGH)

Create Jest tests for 10 LWC components with 75%+ coverage.

---

## Validation Steps

### After Each Block

1. Run local validation:
   ```bash
   # Apex syntax check
   sfdx force:source:deploy --checkonly -p force-app

   # Jest tests
   npm run test:unit
   ```

2. Run full test suite:
   ```bash
   sfdx force:apex:test:run --codecoverage --resultformat human
   ```

### Before Phase 1 Sign-off

- [ ] All security scanner warnings resolved
- [ ] Apex test coverage ≥75%
- [ ] LWC Jest test coverage ≥75%
- [ ] No ESLint errors
- [ ] All acceptance criteria met

---

## Files to Modify Summary

### Apex Classes (Modify)
1. PrometheionQuickActionsService.cls
2. ApiUsageSnapshot.cls
3. MetadataChangeTracker.cls
4. PerformanceRuleEngine.cls
5. PrometheionScoreCallback.cls
6. TeamsNotifier.cls

### Apex Classes (Create)
1. TriggerRecursionGuard.cls
2. TriggerRecursionGuardTest.cls
3. PrometheionQuickActionsServiceTest.cls
4. PrometheionGraphIndexerTest.cls
5. PrometheionGDPRDataErasureServiceTest.cls
6. PrometheionScoreCallbackTest.cls
7. ISO27001QuarterlyReviewSchedulerTest.cls
8. PrometheionAlertTriggerHandler.cls (and other handlers)

### Apex Test Classes (Modify)
1. PrometheionEventPublisherTest.cls
2. SlackNotifierTest.cls
3. DeploymentMetricsTest.cls
4. LimitMetricsTest.cls

### Metadata (Create)
1. Prometheion_API_Config__mdt (Custom Metadata Type)

### LWC Components (Modify)
1. systemMonitorDashboard
2. prometheionAiSettings
3. prometheionReadinessScore
4. prometheionCopilot
5. riskHeatmap
6. prometheionROICalculator
7. complianceScoreCard
8. complianceDashboard
9. executiveKpiDashboard
10. prometheionDrillDownViewer

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| WITH SECURITY_ENFORCED breaks queries | Test in sandbox first; have rollback plan |
| CRUD checks cause permission errors | Add clear error messages; document required permissions |
| Test data isolation issues | Use @TestSetup and seeAllData=false |
| LWC changes break functionality | Run Jest tests after each change |

---

## Next Steps

1. Start with Block 1 (Security fixes) - highest priority
2. Create test classes in parallel with security fixes
3. Validate each block before moving to next
4. Document any deviations from plan

**Ready to begin implementation.**
