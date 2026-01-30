# PHASE 1: P1 BLOCKERS

## Execution Plan

**Timeline:** Days 1-3
**Assignees:** Claude Code (Backend) + Cursor (UI)
**Priority:** HIGH - AppExchange blocking issues
**Dependencies:** Phase 0 must be complete

---

## OVERVIEW

Phase 1 addresses all AppExchange-blocking issues across security, testing, and accessibility.

| Domain | Assignee | Tasks | Hours |
|--------|----------|-------|-------|
| Security & Backend | Claude Code | 22 tasks | 46h |
| UI & Accessibility | Cursor | 18 tasks | 36h |

---

# CLAUDE CODE TASKS

## 1.1 SECURITY: FLS/CRUD VIOLATIONS (8 hours)

### Task S1: ElaroQuickActionsService - Add WITH SECURITY_ENFORCED

**File:** `force-app/main/default/classes/ElaroQuickActionsService.cls`

| Location | Lines | Current Query |
|----------|-------|---------------|
| excessiveAdmins query | 63-75 | Missing `WITH SECURITY_ENFORCED` |
| modAllAssignments query | 104-111 | Missing `WITH SECURITY_ENFORCED` |
| inactiveUsers query | 161-168 | Missing `WITH SECURITY_ENFORCED` |
| assignments query | 228-233 | Missing `WITH SECURITY_ENFORCED` |
| excessiveAssignments query | 274-281 | Missing `WITH SECURITY_ENFORCED` |
| revokeModifyAllData query | 380-385 | Missing `WITH SECURITY_ENFORCED` |
| deactivateInactiveUsers query | 422-428 | Missing `WITH SECURITY_ENFORCED` |
| removePermissionSetAssignment query | 469-473 | Missing `WITH SECURITY_ENFORCED` |

**Fix Pattern:**
```apex
// BEFORE
List<User> users = [SELECT Id, Name FROM User WHERE IsActive = true];

// AFTER
List<User> users = [SELECT Id, Name FROM User WHERE IsActive = true WITH SECURITY_ENFORCED];
```

**Acceptance Criteria:**
- [ ] All 8 queries have `WITH SECURITY_ENFORCED`
- [ ] No FLS bypass warnings from security scanner

---

### Task S2: ElaroQuickActionsService - Add CRUD Validation

**File:** `force-app/main/default/classes/ElaroQuickActionsService.cls`

| Location | Line | Operation |
|----------|------|-----------|
| delete assignmentsToRemove | 139 | DELETE without validation |
| delete assignments | 236 | DELETE without validation |
| delete setsToRemove | 245 | DELETE without validation |
| delete toRemove | 338 | DELETE without validation |
| delete assignments | 393 | DELETE without validation |
| update inactiveUsers | 441 | UPDATE without validation |
| delete psa | 475 | DELETE without validation |

**Fix Pattern:**
```apex
// BEFORE
delete assignments;

// AFTER
if (Schema.sObjectType.PermissionSetAssignment.isDeletable()) {
    delete assignments;
} else {
    throw new AuraHandledException('Insufficient permissions to delete permission set assignments');
}

// OR use Security.stripInaccessible for updates:
SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, records);
update decision.getRecords();
```

**Acceptance Criteria:**
- [ ] All 7 DML operations have CRUD checks
- [ ] Appropriate exceptions thrown for permission failures

---

### Task S3: ApiUsageSnapshot - Add CRUD Check

**File:** `force-app/main/default/classes/ApiUsageSnapshot.cls`
**Line:** 37

```apex
// BEFORE
insert new API_Usage_Snapshot__c(...);

// AFTER
if (Schema.sObjectType.API_Usage_Snapshot__c.isCreateable()) {
    insert new API_Usage_Snapshot__c(...);
} else {
    System.debug(LoggingLevel.ERROR, 'Insufficient permissions to create API Usage Snapshot');
}
```

---

### Task S4: MetadataChangeTracker - Add CRUD Check

**File:** `force-app/main/default/classes/MetadataChangeTracker.cls`
**Line:** 38

```apex
// BEFORE
insert change;

// AFTER
if (Schema.sObjectType.Metadata_Change__c.isCreateable()) {
    insert change;
} else {
    throw new SecurityException('Cannot create Metadata_Change__c record');
}
```

---

### Task S5: PerformanceRuleEngine - Add Security

**File:** `force-app/main/default/classes/PerformanceRuleEngine.cls`
**Line:** 251

```apex
// BEFORE
List<Database.SaveResult> results = Database.insert(records, false);

// AFTER
if (Schema.sObjectType.Performance_Alert_History__c.isCreateable()) {
    SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, records);
    List<Database.SaveResult> results = Database.insert(decision.getRecords(), false);
} else {
    System.debug(LoggingLevel.ERROR, 'Cannot create Performance_Alert_History__c records');
}
```

---

## 1.2 SECURITY: AUTHENTICATION & INJECTION (6 hours)

### Task S6: ElaroScoreCallback - Add Authentication

**File:** `force-app/main/default/classes/ElaroScoreCallback.cls`
**Lines:** 14-15

**Current State (Vulnerable):**
```apex
@HttpPost
global static void handleScoreCallback() {
    RestRequest req = RestContext.request;
    // NO AUTHENTICATION CHECK!
}
```

**Required Fix:**
```apex
@HttpPost
global static void handleScoreCallback() {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;

    // Validate API Key
    String apiKey = req.headers.get('X-API-Key');
    if (!validateApiKey(apiKey)) {
        res.statusCode = 401;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'success' => false,
            'error' => 'Unauthorized: Invalid or missing API key'
        }));
        return;
    }

    // Continue with existing logic...
}

private static Boolean validateApiKey(String apiKey) {
    if (String.isBlank(apiKey)) {
        return false;
    }
    // Retrieve expected key from Custom Metadata or Protected Custom Setting
    Elaro_API_Config__mdt config = Elaro_API_Config__mdt.getInstance('ScoreCallback');
    return config != null && apiKey == config.API_Key__c;
}
```

**Additional Setup Required:**
1. Create Custom Metadata Type: `Elaro_API_Config__mdt`
2. Add field: `API_Key__c` (Text, Encrypted)
3. Create record: `ScoreCallback` with secure API key

---

### Task S7: ElaroScoreCallback - Remove Stack Trace Exposure

**File:** `force-app/main/default/classes/ElaroScoreCallback.cls`
**Lines:** 102-109

**Current State (Vulnerable):**
```apex
res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
    'success' => false,
    'error' => e.getMessage(),
    'stackTrace' => e.getStackTraceString() // SECURITY RISK!
}));
```

**Required Fix:**
```apex
// Log full error internally
System.debug(LoggingLevel.ERROR, 'Score callback error: ' + e.getMessage());
System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());

// Return sanitized error to external caller
res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
    'success' => false,
    'error' => 'An internal error occurred. Please contact support.',
    'correlationId' => generateCorrelationId() // For support reference
}));
```

---

### Task S8: TeamsNotifier - Fix URL Injection

**File:** `force-app/main/default/classes/TeamsNotifier.cls`
**Lines:** 204, 209

**Current State (Vulnerable):**
```apex
'url' => orgUrl + '/apex/ElaroApprove?id=' + result.remediationId
```

**Required Fix:**
```apex
'url' => orgUrl + '/apex/ElaroApprove?id=' + EncodingUtil.urlEncode(result.remediationId, 'UTF-8')
```

Apply same fix to line 209.

---

## 1.3 HTTP CALLOUT FIXES (4 hours)

### Task H1 & H2: TeamsNotifier - Add Timeouts

**File:** `force-app/main/default/classes/TeamsNotifier.cls`

**Lines 20-25 (notifyAsync):**
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Teams_Webhook');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setTimeout(10000); // ADD THIS LINE
req.setBody(JSON.serialize(new Map<String, Object>{ 'text' => text }));
```

**Lines 40-45 (notifyRichAsync):**
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Teams_Webhook');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setTimeout(10000); // ADD THIS LINE
req.setBody(jsonPayload);
```

---

### Task H3: TeamsNotifier - Add Retry Logic

**File:** `force-app/main/default/classes/TeamsNotifier.cls`

Add retry mechanism similar to `ElaroSlackNotifierQueueable`:

```apex
private static final Integer MAX_RETRIES = 3;
private static final Integer BASE_DELAY_MS = 1000;

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
                if (retryCount < MAX_RETRIES) {
                    // Exponential backoff would require async - log and continue
                    System.debug('Retry ' + retryCount + ' after status ' + res.getStatusCode());
                }
            } else {
                return res; // Client error, don't retry
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

### Task H4: ApiUsageSnapshot - Add Timeout

**File:** `force-app/main/default/classes/ApiUsageSnapshot.cls`
**Lines:** 13-17

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:SF_Limits/services/data/v60.0/limits');
req.setMethod('GET');
req.setHeader('Accept','application/json');
req.setTimeout(10000); // ADD THIS LINE
HttpResponse res = new Http().send(req);
```

---

## 1.4 TEST CLASS CREATION (20 hours)

### Task T1: ElaroQuickActionsServiceTest

**File to Create:** `force-app/main/default/classes/ElaroQuickActionsServiceTest.cls`

**Test Methods Required:**
```apex
@IsTest
private class ElaroQuickActionsServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create test users, permission sets, assignments
    }

    @IsTest
    static void testGetExcessiveAdmins() {
        // Test with users having ModifyAllData
    }

    @IsTest
    static void testRevokeModifyAllData() {
        // Test permission revocation
    }

    @IsTest
    static void testDeactivateInactiveUsers() {
        // Test user deactivation
    }

    @IsTest
    static void testRemovePermissionSetAssignment() {
        // Test assignment removal
    }

    @IsTest
    static void testSecurityExceptionHandling() {
        // Test behavior when user lacks permissions
    }

    @IsTest
    static void testBulkOperations() {
        // Test with 200+ records
    }
}
```

**Coverage Target:** >75%

---

### Task T2: ElaroGraphIndexerTest

**File to Create:** `force-app/main/default/classes/ElaroGraphIndexerTest.cls`

**Test Methods Required:**
```apex
@IsTest
private class ElaroGraphIndexerTest {

    @IsTest
    static void testGenerateDeterministicHash() {
        // Verify same inputs produce same hash
        String hash1 = ElaroGraphIndexer.generateDeterministicHash('TEST', '001000000000001', 'SOC2');
        String hash2 = ElaroGraphIndexer.generateDeterministicHash('TEST', '001000000000001', 'SOC2');
        System.assertEquals(hash1, hash2, 'Hash must be deterministic');
    }

    @IsTest
    static void testIndexChange() {
        // Test graph indexing
    }

    @IsTest
    static void testQueryEntityMetadata() {
        // Test metadata retrieval
    }

    @IsTest
    static void testNullInputHandling() {
        // Test with null/blank inputs
    }
}
```

---

### Task T3-T5: Additional Test Classes

Create test classes for:
- `ElaroGDPRDataErasureServiceTest.cls`
- `ElaroScoreCallbackTest.cls`
- `ISO27001QuarterlyReviewSchedulerTest.cls`

Each should have >75% coverage with positive, negative, and bulk tests.

---

## 1.5 FIX EXISTING TEST ISSUES (4 hours)

### Task TF1: Fix ElaroEventPublisherTest

**File:** `force-app/main/default/classes/ElaroEventPublisherTest.cls`

**Replace meaningless assertions:**

```apex
// BEFORE (Line 21)
System.assert(true, 'Event published successfully');

// AFTER
Test.startTest();
ElaroEventPublisher.publishEvent(testEvent);
Test.stopTest();

// Query for published events or verify side effects
List<EventBusSubscriber> subscribers = [SELECT Id FROM EventBusSubscriber LIMIT 1];
System.assertNotEquals(null, subscribers, 'Event should be published');
// Or verify Integration_Error__c was not created (success case)
List<Integration_Error__c> errors = [SELECT Id FROM Integration_Error__c];
System.assertEquals(0, errors.size(), 'No errors should occur on successful publish');
```

---

### Task TF2: Fix SlackNotifierTest

**File:** `force-app/main/default/classes/SlackNotifierTest.cls`

Similar pattern - replace `System.assert(true)` with actual verification.

---

### Task TF3: Expand DeploymentMetricsTest

**File:** `force-app/main/default/classes/DeploymentMetricsTest.cls`

**Current State:** Only 1 test method, 5 lines

**Required Tests:**
```apex
@IsTest
private class DeploymentMetricsTest {

    @TestSetup
    static void setupTestData() {
        List<Deployment_Job__c> jobs = new List<Deployment_Job__c>();
        for (Integer i = 0; i < 10; i++) {
            jobs.add(new Deployment_Job__c(
                Status__c = Math.mod(i, 2) == 0 ? 'Success' : 'Failed',
                Started_On__c = System.now().addMinutes(-i * 10),
                Finished_On__c = System.now().addMinutes(-i * 10 + 5),
                Tests_Passed__c = i * 10,
                Tests_Failed__c = Math.mod(i, 3)
            ));
        }
        insert jobs;
    }

    @IsTest
    static void testRecent() {
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.recent(5);
        System.assertEquals(5, rows.size(), 'Should return 5 records');
    }

    @IsTest
    static void testRecentEmpty() {
        delete [SELECT Id FROM Deployment_Job__c];
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.recent(5);
        System.assertEquals(0, rows.size(), 'Should return 0 when no data');
    }

    @IsTest
    static void testRecentWithInvalidLimit() {
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.recent(-1);
        System.assertNotEquals(null, rows, 'Should handle invalid limit gracefully');
    }

    @IsTest
    static void testRecentWithNullLimit() {
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.recent(null);
        System.assertNotEquals(null, rows, 'Should handle null limit');
    }

    @IsTest
    static void testFieldValues() {
        List<DeploymentMetrics.Row> rows = DeploymentMetrics.recent(1);
        System.assertNotEquals(null, rows[0].status, 'Status should not be null');
        System.assertNotEquals(null, rows[0].startedOn, 'StartedOn should not be null');
    }
}
```

---

### Task TF4: Fix LimitMetricsTest

**File:** `force-app/main/default/classes/LimitMetricsTest.cls`
**Lines:** 47-51

**Issue:** Depends on org data

```apex
// BEFORE (depends on existing data)
List<Performance_Alert_History__c> records = [
    SELECT Id FROM Performance_Alert_History__c LIMIT 1
];

// AFTER (create test data)
@TestSetup
static void setupTestData() {
    insert new Performance_Alert_History__c(
        Metric__c = 'CPU',
        Value__c = 50.0,
        Threshold__c = 80.0,
        Context_Record__c = 'TestContext'
    );
}

@IsTest
static void testGovernorStatsAfterSOQL() {
    // Now query test data we created
    List<Performance_Alert_History__c> records = [
        SELECT Id FROM Performance_Alert_History__c LIMIT 1
    ];
    System.assertEquals(1, records.size(), 'Should have test data');
}
```

---

## 1.6 TRIGGER FIXES (4 hours)

### Task TR1: Add Recursion Guards

**Create utility class:** `force-app/main/default/classes/TriggerRecursionGuard.cls`

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

    public static void resetAll() {
        runningTriggers.clear();
    }
}
```

**Apply to all triggers:**

```apex
trigger ElaroAlertTrigger on Alert__c (after insert) {
    if (!TriggerRecursionGuard.isFirstRun('ElaroAlertTrigger')) {
        return;
    }
    try {
        // Existing logic
    } finally {
        TriggerRecursionGuard.reset('ElaroAlertTrigger');
    }
}
```

---

### Task TR2-TR4: Create Handler Classes

**Pattern for each trigger:**

1. Create handler class: `ElaroAlertTriggerHandler.cls`
2. Move all business logic from trigger to handler
3. Trigger only calls handler methods

**Example:**

```apex
// Trigger (minimal)
trigger ElaroAlertTrigger on Alert__c (after insert) {
    if (!TriggerRecursionGuard.isFirstRun('ElaroAlertTrigger')) {
        return;
    }
    try {
        ElaroAlertTriggerHandler.handleAfterInsert(Trigger.new);
    } finally {
        TriggerRecursionGuard.reset('ElaroAlertTrigger');
    }
}

// Handler (all logic)
public with sharing class ElaroAlertTriggerHandler {
    public static void handleAfterInsert(List<Alert__c> newAlerts) {
        List<Elaro_Alert_Event__e> events = new List<Elaro_Alert_Event__e>();
        for (Alert__c alert : newAlerts) {
            if (alert.Severity__c == 'CRITICAL' || alert.Severity__c == 'HIGH') {
                events.add(new Elaro_Alert_Event__e(
                    Alert_Id__c = alert.Id,
                    Alert_Type__c = alert.Alert_Type__c,
                    Severity__c = alert.Severity__c,
                    Title__c = alert.Title__c
                ));
            }
        }
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }
}
```

---

# CURSOR TASKS

## 1.7 FIX MALFORMED EVENT HANDLERS (2 hours)

### Task E1: systemMonitorDashboard.html

**File:** `force-app/main/default/lwc/systemMonitorDashboard/systemMonitorDashboard.html`
**Lines:** 29-33

```html
<!-- BEFORE (broken) -->
<lightning-button
    label="Refresh"
    onclick="{refresh;}"
></lightning-button>

<!-- AFTER (fixed) -->
<lightning-button
    label="Refresh"
    onclick={refresh}
></lightning-button>
```

---

### Task E2: elaroAiSettings.html

**File:** `force-app/main/default/lwc/elaroAiSettings/elaroAiSettings.html`

Fix ALL malformed handlers:
- Lines 8-12: `onchange="{handleToggleAI;}"` → `onchange={handleToggleAI}`
- Lines 21-25: Same pattern
- Lines 34-37: Same pattern
- Lines 50-54: Same pattern
- Lines 66-69: Same pattern
- Lines 81-85: Same pattern

---

### Task E3: elaroReadinessScore.html

**File:** `force-app/main/default/lwc/elaroReadinessScore/elaroReadinessScore.html`

- Lines 54-58: `onclick="{handleGenerateSoc2;}"` → `onclick={handleGenerateSoc2}`
- Lines 65-69: Same pattern

---

## 1.8 ACCESSIBILITY - ARIA LABELS (6 hours)

### Task A1: Add aria-hidden to Decorative Icons

**Pattern for all LWC components:**

```html
<!-- BEFORE -->
<svg class="icon">...</svg>

<!-- AFTER -->
<svg class="icon" aria-hidden="true">...</svg>
```

**Files to update:**
- `elaroCopilot.html` (Lines 8-12, 21-23, 49-85, 106-108, 117-121, 130-133, 167-170)
- All other components with SVG icons

---

### Task A2: riskHeatmap.html - Add Text Labels

**File:** `force-app/main/default/lwc/riskHeatmap/riskHeatmap.html`

```html
<!-- BEFORE (color only) -->
<div class={riskClass}>
    {risk.score}
</div>

<!-- AFTER (accessible) -->
<div class={riskClass} role="cell" aria-label={riskAriaLabel}>
    <span class="slds-assistive-text">{risk.severity} risk:</span>
    {risk.score}
</div>
```

---

### Task A3: elaroROICalculator.html - Fix Labels

**File:** `force-app/main/default/lwc/elaroROICalculator/elaroROICalculator.html`

```html
<!-- BEFORE -->
<label>Industry</label>
<lightning-combobox value={industry} options={industryOptions}></lightning-combobox>

<!-- AFTER -->
<lightning-combobox
    label="Industry"
    value={industry}
    options={industryOptions}
></lightning-combobox>
```

Apply to all form inputs in the component.

---

## 1.9 NULL SAFETY (4 hours)

### Task N1-N4: Add Null Checks to Templates

**Pattern:**

```html
<!-- BEFORE -->
<div>{framework.score}</div>

<!-- AFTER -->
<template if:true={framework}>
    <div>{framework.score}</div>
</template>
<template if:false={framework}>
    <div class="slds-text-color_weak">No data available</div>
</template>
```

**Files to update:**
- `complianceScoreCard.html`
- `complianceDashboard.html`
- `executiveKpiDashboard.html`
- `riskHeatmap.html`

---

## 1.10 LOADING/ERROR STATES (6 hours)

### Add Loading Spinner Pattern

```html
<template>
    <lightning-card title="Component Title">
        <template if:true={isLoading}>
            <div class="slds-is-relative slds-p-around_medium">
                <lightning-spinner alternative-text="Loading..." size="medium"></lightning-spinner>
            </div>
        </template>

        <template if:true={error}>
            <div class="slds-text-color_error slds-p-around_medium">
                <lightning-icon icon-name="utility:error" size="small" class="slds-m-right_x-small"></lightning-icon>
                {errorMessage}
            </div>
        </template>

        <template if:true={hasData}>
            <!-- Main content -->
        </template>

        <template if:true={isEmpty}>
            <div class="slds-text-color_weak slds-p-around_medium slds-text-align_center">
                <lightning-icon icon-name="utility:info" size="small" class="slds-m-right_x-small"></lightning-icon>
                No data available
            </div>
        </template>
    </lightning-card>
</template>
```

**Apply to 12 components** listed in Phase 1 overview.

---

## 1.11 LWC JAVASCRIPT FIXES (8 hours)

### Task J1: Fix error.body Null Checks

**Pattern:**

```javascript
// BEFORE
.catch(error => {
    this.error = error.body.message;
});

// AFTER
.catch(error => {
    this.error = error.body?.message || error.message || 'An unknown error occurred';
});
```

---

### Task J2: Wrap JSON.parse in Try-Catch

**File:** `elaroDrillDownViewer.js`
**Lines:** 29, 69, 86

```javascript
// BEFORE
const data = JSON.parse(jsonString);

// AFTER
let data;
try {
    data = JSON.parse(jsonString);
} catch (e) {
    console.error('Failed to parse JSON:', e);
    data = null;
}
```

---

### Task J3: Remove Unnecessary @track

**Files to update:** 12 components

```javascript
// BEFORE
@track score = 0;
@track isLoading = false;
@track errorMessage = '';

// AFTER (primitives don't need @track)
score = 0;
isLoading = false;
errorMessage = '';

// Only use @track for objects/arrays when mutating
@track data = [];
```

---

### Task J4: Remove Console Statements

**Search and remove or wrap:**

```javascript
// Option 1: Remove entirely
// console.log('debug info');  // DELETE

// Option 2: Wrap in debug flag
if (this.debugMode) {
    console.log('debug info');
}
```

---

## 1.12 JEST TESTS (10 hours)

### Create Test Files

For each component, create `__tests__/componentName.test.js`:

```javascript
import { createElement } from 'lwc';
import ComponentName from 'c/componentName';

describe('c-component-name', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders component', () => {
        const element = createElement('c-component-name', {
            is: ComponentName
        });
        document.body.appendChild(element);
        expect(element).not.toBeNull();
    });

    it('displays loading spinner when loading', () => {
        const element = createElement('c-component-name', {
            is: ComponentName
        });
        element.isLoading = true;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const spinner = element.shadowRoot.querySelector('lightning-spinner');
            expect(spinner).not.toBeNull();
        });
    });

    it('displays error message on error', () => {
        const element = createElement('c-component-name', {
            is: ComponentName
        });
        element.error = { body: { message: 'Test error' } };
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const errorDiv = element.shadowRoot.querySelector('.slds-text-color_error');
            expect(errorDiv).not.toBeNull();
        });
    });
});
```

**Components to test:**
- apiUsageDashboard
- deploymentMonitorDashboard
- systemMonitorDashboard
- flowExecutionMonitor
- performanceAlertPanel
- elaroAiSettings
- elaroROICalculator
- elaroTrendAnalyzer
- riskHeatmap
- complianceScoreCard

---

## VALIDATION CHECKLIST

### End of Day 1
- [ ] All FLS/CRUD violations fixed (S1-S5)
- [ ] Authentication added to REST endpoint (S6)
- [ ] Malformed event handlers fixed (E1-E3)

### End of Day 2
- [ ] HTTP timeouts added (H1-H4)
- [ ] 3 new test classes created (T1-T3)
- [ ] ARIA labels added (A1-A3)

### End of Day 3
- [ ] All test issues fixed (TF1-TF4)
- [ ] Trigger handlers created (TR1-TR4)
- [ ] Loading/error states added
- [ ] Jest tests created

### Full Test Run
```bash
# Apex tests
sfdx force:apex:test:run --codecoverage --resultformat human

# Jest tests
npm run test:unit:coverage

# Verify coverage
sfdx force:apex:test:report --codecoverage
```

---

## SIGN-OFF

| Task | Claude Code | Cursor | Verified |
|------|-------------|--------|----------|
| Security Fixes | ☐ | - | ☐ |
| HTTP Fixes | ☐ | - | ☐ |
| Test Creation | ☐ | - | ☐ |
| Test Fixes | ☐ | - | ☐ |
| Trigger Fixes | ☐ | - | ☐ |
| Event Handlers | - | ☐ | ☐ |
| ARIA Labels | - | ☐ | ☐ |
| Null Safety | - | ☐ | ☐ |
| Loading States | - | ☐ | ☐ |
| JS Fixes | - | ☐ | ☐ |
| Jest Tests | - | ☐ | ☐ |

**Phase 1 Complete:** ☐
**Ready for Phase 2:** ☐
