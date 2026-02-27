# Elaro Codebase Review Findings

**Review Date:** 2026-02-27
**Standards:** Winter '26 (API v65.0) / Spring '26 (API v66.0)
**Reviewer:** Claude Code
**Scope:** All files in force-app/ and force-app-healthcheck/

---

## AUTO-FAIL CONDITIONS

### AF-1. BUG: SOQL Injection — `ElaroMatrixController.cls` (lines 304-305, 351-358)

Raw `cfg.filters` string from the LWC client is concatenated into SOQL after only denylist keyword blocking and single-quote escaping. The denylist (`INSERT`, `DELETE`, etc.) blocks DML keywords but does not prevent SOQL data-exfiltration payloads (e.g., `Status__c = 'Active') OR (Name LIKE '%`).

**Quoted code (line 304-305):**
```apex
String baseFilter = String.isNotBlank(cfg.filters) ?
    ' WHERE ' + sanitizeFilterClause(cfg.filters) : '';
```

**Quoted code (line 351-358, queryDirect):**
```apex
if (String.isNotBlank(cfg.filters)) {
    soql += ' WHERE ' + sanitizeFilterClause(cfg.filters);
}
```

**Corrected code:**
Migrate `MatrixConfiguration.filters` from a raw `String` to a structured `List<FilterCriteria>` with field/operator/value properties, then build the WHERE clause using bind variables via `Database.queryWithBinds()` — matching the pattern already used correctly in `ElaroDrillDownController` and `ElaroDynamicReportController`.

```apex
public class FilterCriteria {
    @AuraEnabled public String field;
    @AuraEnabled public String operator;
    @AuraEnabled public String value;
}

// In query builder:
private static String buildFilterClause(List<FilterCriteria> filters, String objectName, Map<String, Object> binds) {
    if (filters == null || filters.isEmpty()) {
        return '';
    }

    SObjectType sType = Schema.getGlobalDescribe().get(objectName);
    Map<String, SObjectField> fieldMap = sType.getDescribe().fields.getMap();

    List<String> conditions = new List<String>();
    Integer bindIndex = 0;

    for (FilterCriteria fc : filters) {
        String fieldLower = fc.field.toLowerCase();
        if (!fieldMap.containsKey(fieldLower)) {
            throw new AuraHandledException('Invalid filter field: ' + fc.field);
        }
        if (!fieldMap.get(fieldLower).getDescribe().isAccessible()) {
            throw new AuraHandledException('Field not accessible: ' + fc.field);
        }

        String op = validateOperator(fc.operator);
        String bindKey = 'filterVal' + bindIndex++;
        binds.put(bindKey, fc.value);
        conditions.add(fc.field + ' ' + op + ' :' + bindKey);
    }

    return String.join(conditions, ' AND ');
}
```

---

### AF-2. BUG: SOQL Injection — `ElaroTrendController.cls` (line 336-342)

Same pattern as AF-1. `additionalFilters` is a raw `String` parameter from the LWC concatenated into SOQL with only denylist sanitization.

**Quoted code (lines 336-342):**
```apex
if (String.isNotBlank(additionalFilters)) {
    String safeFilters = sanitizeFilterClause(additionalFilters);

    if (String.isNotBlank(safeFilters)) {
        soql += ' AND (' + safeFilters + ')';
    }
}
```

**Corrected code:** Same approach as AF-1 — replace with structured `List<FilterCriteria>` and bind variables.

---

### AF-3. BUG: Missing Sharing Declaration — 8 classes in main package, 3 in healthcheck

**Main package (force-app):**
- `ComplianceTestDataFactory.cls:12` — `public class ComplianceTestDataFactory`
- `ElaroTestDataFactory.cls:8` — `public class ElaroTestDataFactory`
- `ElaroTestUserFactory.cls:22` — `public class ElaroTestUserFactory`
- `ApiLimitsCalloutMock.cls:9` — `global class ApiLimitsCalloutMock`
- `ElaroClaudeAPIMock.cls:8` — `public class ElaroClaudeAPIMock`
- `HIPAABreachNotificationServiceTest.cls:10` — `public class` (missing `@IsTest private`)
- `HIPAAPrivacyRuleServiceTest.cls:10` — `public class` (missing `@IsTest private`)
- `SOC2AccessReviewServiceTest.cls:10` — `public class` (missing `@IsTest private`)

**Healthcheck package (force-app-healthcheck):**
- `ScanFinding.cls:8` — `public class ScanFinding`
- `HealthCheckResult.cls:9` — `public class HealthCheckResult`
- `ScanRecommendation.cls:8` — `public class ScanRecommendation implements Comparable`

**Corrected code (example):**
```apex
// Test data factories — use inherited sharing
public inherited sharing class ComplianceTestDataFactory {

// Test mocks — use inherited sharing
public inherited sharing class ApiLimitsCalloutMock implements HttpCalloutMock {

// Test classes — use @IsTest private
@IsTest
private class HIPAABreachNotificationServiceTest {

// DTO classes — use inherited sharing
public inherited sharing class ScanFinding {
```

---

### AF-4. BUG: `UserInfo.getSessionId()` — `ToolingApiService.cls` (healthcheck package, line 40)

AppExchange AUTO-FAIL. Spring '26 enforcement (Feb 16, 2026) removes session IDs from outbound messages. Must use OAuth / Named Credentials instead.

**Quoted code (line 40):**
```apex
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
```

**Corrected code:** Replace with a Named Credential or External Credential that provides OAuth bearer tokens:
```apex
req.setEndpoint('callout:Tooling_API/services/data/v66.0/tooling/query/?q='
    + EncodingUtil.urlEncode(query, 'UTF-8'));
// Named Credential handles Authorization header via OAuth
```

---

### AF-5. BUG: Syntax Error — `ApiUsageSnapshot.cls` (line 28-29) — WILL NOT COMPILE

**Quoted code (lines 28-29):**
```apex
if (res.getStatusCode() {
    >= 300) throw new CalloutException('Limits callout failed: ' + res.getStatus());
}
```

**Corrected code:**
```apex
if (res.getStatusCode() >= 300) {
    throw new CalloutException('Limits callout failed: ' + res.getStatus());
}
```

---

## SECURITY FINDINGS

### SEC-1. BUG: Missing try-catch on @AuraEnabled methods — 7 controllers, 17 methods

These controllers have `@AuraEnabled` methods with no try-catch. Raw exceptions (QueryException, DmlException, etc.) propagate to the LWC as opaque internal errors, and failures are not logged via ElaroLogger.

| Controller | Methods Missing try-catch |
|---|---|
| `ApiUsageDashboardController.cls:31` | `getRecentSnapshots` |
| `AuditReportController.cls:21` | `generateAuditReport` |
| `ComplianceDashboardController.cls:18,81` | `getDashboardSummary`, `getFrameworkDashboard` |
| `ComplianceScoreCardController.cls:20` | `getFrameworkDetails` |
| `ElaroAISettingsController.cls:17` | `getSettings` |
| `ElaroDashboardController.cls:69` | `getAuditPackageStats` |
| `EscalationPathController.cls:16,40,52,63` | `getPaths`, `createPath`, `updatePath`, `deletePath` |

**Corrected pattern (for each method):**
```apex
@AuraEnabled
public static ReturnType methodName(params) {
    try {
        // existing logic
    } catch (AuraHandledException ae) {
        throw ae;
    } catch (Exception e) {
        ElaroLogger.error('ClassName.methodName', e.getMessage(), e.getStackTraceString());
        throw new AuraHandledException('User-friendly error message.');
    }
}
```

Additionally, `AuditReportController` and `ComplianceDashboardController` throw `IllegalArgumentException` for validation instead of `AuraHandledException`. Change to:
```apex
throw new AuraHandledException('Framework cannot be blank');
```

---

## GOVERNOR LIMITS & PERFORMANCE FINDINGS

### PERF-1. SUGGESTION: Repeated JSON deserialization per event field — `ElaroPCIAccessAlertHandler.cls`

The `parseEventField()` method (line 256-268) deserializes `event.Event_Data__c` JSON on every call. In `handleFailedAccess()` (lines 29-32), it's called 3 times per event in the loop body, parsing the same JSON 3 times.

**Quoted code (lines 29-32):**
```apex
for (Elaro_Raw_Event__e event : events) {
    if (!eventsByUser.containsKey(parseEventField(event, 'userId'))) {
        eventsByUser.put(parseEventField(event, 'userId'), new List<Elaro_Raw_Event__e>());
    }
    eventsByUser.get(parseEventField(event, 'userId')).add(event);
}
```

**Corrected code:**
```apex
for (Elaro_Raw_Event__e event : events) {
    String userId = parseEventField(event, 'userId');
    if (!eventsByUser.containsKey(userId)) {
        eventsByUser.put(userId, new List<Elaro_Raw_Event__e>());
    }
    eventsByUser.get(userId).add(event);
}
```

---

### PERF-2. SUGGESTION: Linear iteration in `ElaroConstants.isValidFramework()` — `ElaroConstants.cls` (line 264-275)

Iterates through the Set linearly with `.toUpperCase()` comparison instead of using `Set.contains()`.

**Quoted code (lines 264-275):**
```apex
public static Boolean isValidFramework(String framework) {
    if (String.isBlank(framework)) {
        return false;
    }
    String upperFramework = framework.toUpperCase();
    for (String validFramework : ALL_FRAMEWORKS) {
        if (validFramework.toUpperCase().equals(upperFramework)) {
            return true;
        }
    }
    return false;
}
```

**Corrected code:**
```apex
public static Boolean isValidFramework(String framework) {
    if (String.isBlank(framework)) {
        return false;
    }
    return ALL_FRAMEWORKS.contains(framework.toUpperCase());
}
```

Note: This works because `ALL_FRAMEWORKS` already stores values in UPPER_CASE (e.g., `'HIPAA'`, `'SOC2'`).

---

### PERF-3. BUG: DML in Loop — `ComplianceOrchestrationEngine.cls` (line 132)

`publishFailureAlerts()` calls `ComplianceAlertPublisher.publishAlert()` inside a `for` loop iterating over `RuleResult` objects. Each call publishes a Platform Event (DML). With 150+ failing rules this hits the DML statement limit.

**Quoted code (lines 128-132):**
```apex
for (RuleResult result : results) {
    if (!result.passed && result.severity != null) {
        try {
            ComplianceAlertPublisher.publishAlert(
                framework,
                result.controlReference,
```

**Corrected code:** Collect all events in a list and publish once outside the loop:
```apex
List<Compliance_Alert__e> alertEvents = new List<Compliance_Alert__e>();
for (RuleResult result : results) {
    if (!result.passed && result.severity != null) {
        alertEvents.add(ComplianceAlertPublisher.buildAlertEvent(
            framework, result.controlReference, result.severity,
            result.findingDetails ?? 'Rule evaluation failed: ' + result.ruleName,
            'FINDING', null
        ));
    }
}
if (!alertEvents.isEmpty()) {
    EventBus.publish(alertEvents);
}
```

---

### PERF-4. BUG: DML in Loop — `ComplianceScoreSnapshotScheduler.cls` (lines 246-252, 274, 296)

`checkScoreAlerts()` loops over frameworks and calls `createScoreAlert()` / `createComplianceAlert()` which each execute `insert as user gap;` individually.

**Quoted code (lines 246-252):**
```apex
for (String framework : results.keySet()) {
    FrameworkResult result = results.get(framework);
    if (result.scoreChange < -5) {
        createScoreAlert(framework, result);
    }
    if (!result.compliant && result.previousScore >= 80) {
        createComplianceAlert(framework, result);
    }
}
```

**Quoted code (line 274 inside createScoreAlert):**
```apex
ElaroSecurityUtils.validateCRUDAccess('Compliance_Gap__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
insert as user gap;
```

**Corrected code:** Collect gaps in a list, insert once after the loop:
```apex
List<Compliance_Gap__c> gapsToInsert = new List<Compliance_Gap__c>();
for (String framework : results.keySet()) {
    FrameworkResult result = results.get(framework);
    if (result.scoreChange < -5) {
        gapsToInsert.add(buildScoreAlert(framework, result));
    }
    if (!result.compliant && result.previousScore >= 80) {
        gapsToInsert.add(buildComplianceAlert(framework, result));
    }
}
if (!gapsToInsert.isEmpty()) {
    ElaroSecurityUtils.validateCRUDAccess('Compliance_Gap__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
    insert as user gapsToInsert;
}
```

---

### PERF-5. BUG: DML in Loop — `AccessReviewScheduler.cls` (lines 186-190, 209)

`checkStalePermissions()` calls `createComplianceGap()` inside a loop over user IDs. Each call executes `insert as user gap;`.

**Quoted code (lines 186-190):**
```apex
for (Id userId : permissionCounts.keySet()) {
    if (permissionCounts.get(userId) > 10) {
        createComplianceGap(userId, permissionCounts.get(userId));
    }
}
```

**Quoted code (line 209 inside createComplianceGap):**
```apex
ElaroSecurityUtils.validateCRUDAccess('Compliance_Gap__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
insert as user gap;
```

**Corrected code:** Same pattern as PERF-4 — collect gaps in a list, insert once after the loop.

---

### PERF-6. BUG: SOQL/DML/Callout in Loop — `JiraIntegrationService.cls` (lines 128-141)

`createBulkIssues()` calls `createIssue()` in a loop. Each call runs a SOQL query, an HTTP callout to Jira, and `update as user gap`. Exceeds all three governor limits (100 SOQL, 100 callouts, 150 DML) with a moderate list.

**Quoted code (lines 128-141):**
```apex
for (String gapId : gapIds) {
    try {
        JiraIssue issue = createIssue(gapId, null);
        createdIssues.add(issue);
    } catch (Exception e) {
        ElaroLogger.warn('Failed to create issue for gap ' + gapId + ': ' + e.getMessage());
    }
}
```

**Corrected code:** Delegate to the existing `createIssueAsync()` which enqueues `JiraIssueCreationQueueable`:
```apex
@AuraEnabled
public static void createBulkIssues(List<String> gapIds) {
    if (gapIds == null || gapIds.isEmpty()) {
        return;
    }
    for (String gapId : gapIds) {
        createIssueAsync(gapId, null);
    }
}
```

---

### PERF-7. BUG: SOQL in Loop — `SOC2IncidentResponseService.cls` (lines 251-278, 308-325)

`getOpenBreaches()` and `getBreachMetrics()` both call `getNotificationDeadline(inc.Id)` inside loops. That method runs a SOQL query to fetch the same record already available in the outer query.

**Quoted code (line 270 in getOpenBreaches):**
```apex
for (Security_Incident__c inc : incidents) {
    summary.notificationDeadline = getNotificationDeadline(inc.Id);
}
```

**Corrected code:** Calculate deadline inline from the already-queried `inc.Detected_Date__c` and `inc.Severity__c`:
```apex
summary.notificationDeadline = calculateDeadlineFromIncident(inc);

private DateTime calculateDeadlineFromIncident(Security_Incident__c incident) {
    Integer responseDays;
    if (incident.Severity__c == 'CRITICAL') { responseDays = 1; }
    else if (incident.Severity__c == 'HIGH') { responseDays = 3; }
    else { responseDays = 7; }
    return incident.Detected_Date__c.addDays(responseDays);
}
```

---

### PERF-8. BUG: SOQL/DML in Loop — `RemediationSuggestionService.cls` (lines 163-176)

`bulkGenerateSuggestions()` calls `generateSuggestions()` in a loop. Each call runs a SOQL query and `insert as user suggestions`.

**Quoted code (lines 163-176):**
```apex
for (String gapId : gapIds) {
    try {
        List<Remediation_Suggestion__c> suggestions = generateSuggestions(gapId);
        totalGenerated += suggestions.size();
    } catch (Exception e) {
        ElaroLogger.warn('Failed to generate suggestions for gap ' + gapId + ': ' + e.getMessage());
    }
}
```

**Corrected code:** Bulk-query all gaps once, build all suggestions in memory, insert once outside the loop.

---

### PERF-9. BUG: Callout in Loop — `ServiceNowIntegration.cls` (lines 57-58)

`ServiceNowSyncControlsQueueable.execute()` calls `syncSingleControl()` in a loop. Each call makes an HTTP callout. Exceeds 100-callout limit with large frameworks.

**Quoted code (lines 57-58):**
```apex
for (Map<String, Object> control : controls) {
    syncSingleControl(control);
}
```

**Corrected code:** Batch controls with Queueable chaining (process 50 per transaction, chain the rest).

---

### PERF-10. BUG: Corrupted Code Block — `ServiceNowIntegration.cls` (lines 256-258)

Malformed ApexDoc block — `/**` followed immediately by closing braces. Likely a truncated or corrupted method definition.

**Quoted code (lines 256-258):**
```apex
    /**
        }
    }
```

**Corrected code:** Remove the dangling block entirely.

---

## ARCHITECTURE & ASYNC FINDINGS

### ARCH-1. SUGGESTION: Business logic in trigger bodies — `ElaroAlertTrigger.trigger` and `ElaroPCIAccessAlertTrigger.trigger`

**ElaroAlertTrigger.trigger** (lines 6-18): Builds Platform Events directly in the trigger body instead of delegating to a handler class. All other triggers correctly delegate to handlers.

**ElaroPCIAccessAlertTrigger.trigger** (lines 19-78): Contains significant business logic — JSON parsing, event categorization, classification into failed/afterHours/bulk buckets. Should delegate all logic to `ElaroPCIAccessAlertHandler`.

**Corrected pattern:**
```apex
trigger ElaroAlertTrigger on Alert__c (after insert) {
    if (!TriggerRecursionGuard.isFirstRun('ElaroAlertTrigger')) return;
    try {
        ElaroAlertTriggerHandler.handleAfterInsert(Trigger.new);
    } finally {
        TriggerRecursionGuard.reset('ElaroAlertTrigger');
    }
}
```

---

### ARCH-2. SUGGESTION: `@future` methods still in `MultiOrgManager.cls` — lines 95, 225

Two `@future(callout=true)` methods remain even though `MultiOrgManagerQueueable.cls` exists as the replacement. These should be removed after migrating all callers.

**Quoted code (line 95):**
```apex
@future(callout=true)
public static void syncPolicies(List<String> policyIds) {
```

**Quoted code (line 225):**
```apex
@future(callout=true)
private static void testOrgConnection(Id orgRecordId) {
```

**Corrected:** Remove both methods and update callers to use `MultiOrgManagerQueueable`.

---

### ARCH-3. SUGGESTION: ElaroLogger uses System.debug() not Platform Events — `ElaroLogger.cls` (lines 60-71)

The CLAUDE.md states "Structured logging via Platform Events. Publish Immediately mode so logs survive rollback." However, the actual implementation uses `System.debug()`:

**Quoted code (lines 60-71):**
```apex
// For now, use System.debug with structured format
String logMessage = formatLogEntry(entry);
if (level == Level.ERROR) {
    System.debug(LoggingLevel.ERROR, logMessage);
} else if (level == Level.WARN) {
    System.debug(LoggingLevel.WARN, logMessage);
}
```

**Corrected:** Implement Platform Event publishing (e.g., `Elaro_Log_Event__e`) with `EventBus.publish()` for production-grade logging that survives transaction rollback.

---

### ARCH-4. BUG: Missing failure notification in `ElaroBatchEventLoader.finish()` — (lines 62-64)

The `finish()` method only logs a generic info message. No `AsyncApexJob` query, no error detection, no admin notification on failure.

**Quoted code (lines 62-64):**
```apex
public void finish(Database.BatchableContext bc) {
    ElaroLogger.info( '[ElaroBatchEventLoader] Batch completed');
}
```

**Corrected code:**
```apex
public void finish(Database.BatchableContext bc) {
    AsyncApexJob job;
    try {
        job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob WHERE Id = :bc.getJobId() WITH USER_MODE LIMIT 1
        ];
    } catch (Exception e) {
        ElaroLogger.error('ElaroBatchEventLoader.finish', 'Failed to query job status: ' + e.getMessage(), e.getStackTraceString());
        return;
    }
    String summary = 'ElaroBatchEventLoader Complete - Status: ' + job.Status +
        ', Items: ' + job.JobItemsProcessed + '/' + job.TotalJobItems +
        ', Errors: ' + job.NumberOfErrors;
    if (job.NumberOfErrors > 0) {
        ElaroLogger.error('ElaroBatchEventLoader.finish', summary, '');
        notifyOnFailure(job);
    } else {
        ElaroLogger.info('ElaroBatchEventLoader.finish', summary);
    }
}
```

---

### ARCH-5. SUGGESTION: `System.debug` instead of ElaroLogger — `ElaroPCIAccessAlertTrigger.trigger` (line 46)

**Quoted code (line 46):**
```apex
System.debug(LoggingLevel.ERROR, 'Failed to parse PCI event data: ' + e.getMessage());
```

**Corrected code:**
```apex
ElaroLogger.error('ElaroPCIAccessAlertTrigger', 'Failed to parse PCI event data: ' + e.getMessage(), e.getStackTraceString());
```

---

## TEST QUALITY FINDINGS

### TEST-1. SUGGESTION: Coverage-only tests with no assertions — 4 methods in 2 files

**`ElaroPCIAccessLoggerTest.cls:194` — `testLoggingWithNullRecordId()`:**
```apex
@IsTest
static void testLoggingWithNullRecordId() {
    Test.startTest();
    ElaroPCIAccessLogger.logPaymentDataAccess(null, 'Query', 'Query with null record ID');
    Test.stopTest();
    // Verify null record ID is handled gracefully without exception
}
```

**`SOC2AccessReviewServiceTest.cls:38,133,144` — `testInitiateAccessReview()`, `testInitiateAnnualReview()`, `testInitiateAdHocReview()`:**
```apex
@isTest
static void testInitiateAccessReview() {
    SOC2AccessReviewService service = new SOC2AccessReviewService();
    Test.startTest();
    Id reviewId = service.initiateAccessReview('QUARTERLY');
    Test.stopTest();
    // Just verify no exception is thrown
}
```

**Corrected code (add explicit assertions):**
```apex
Assert.isTrue(true, 'Method completed without exception for null record ID');
// or better:
Assert.isNotNull(reviewId, 'Should return a review ID or null');
```

---

### TEST-2. SUGGESTION: Hardcoded IDs in 30 test files (~59 occurrences)

Test classes use hardcoded 15/18-character Salesforce ID strings. While many are used as string tokens in wrapper objects (not DML), these should be centralized in `ElaroTestDataFactory` or use `Test.getStandardPricebookId()` / factory patterns.

**Most affected files:** `RemediationExecutorTest.cls` (9 occurrences), `SlackIntegrationTest.cls` (4), `ElaroTestDataFactory.cls` (5), `ComplianceGraphServiceTest.cls` (5).

---

## APPEXCHANGE READINESS FINDINGS

### AX-1. BUG: Hardcoded English strings in 40+ LWC components

This is an AppExchange i18n requirement violation. Nearly every component has hardcoded English in `title=`, `label=`, `alternative-text=`, and inline text content. Only ~7 components correctly use Custom Labels (Trust Center, Command Center, AI Governance, SEC Disclosure, Compliance Copilot).

**Example (elaroROICalculator.html lines 4-5):**
```html
<h2>Elaro ROI Calculator</h2>
<p class="subtitle">Calculate your annual compliance cost savings</p>
```

**Example (34 `<lightning-card>` components with hardcoded `title=`):**
```html
<lightning-card title="Performance Alerts">
<lightning-card title="Event Explorer">
<lightning-card title="Compliance Dashboard">
```

**Corrected pattern (from the well-implemented components):**
```javascript
import CardTitle from "@salesforce/label/c.PERF_AlertsTitle";
export default class PerformanceAlertPanel extends LightningElement {
    label = { CardTitle };
}
```
```html
<lightning-card title={label.CardTitle}>
```

---

## DOCUMENTATION FINDINGS

### DOC-1. SUGGESTION: Missing ApexDoc on @AuraEnabled methods — 4 controllers

| File | Method | Issue |
|---|---|---|
| `ElaroAISettingsController.cls:16` | `getSettings()` | No ApexDoc |
| `ElaroAISettingsController.cls:85` | `saveSettings()` | No ApexDoc |
| `ApiUsageDashboardController.cls:30` | `getRecentSnapshots()` | No ApexDoc |
| `ComplianceDashboardController.cls:14,78` | `getDashboardSummary()`, `getFrameworkDashboard()` | Missing @return, @throws |

---

### DOC-2. SUGGESTION: Missing ApexDoc on public methods — 5 facade service classes

All public methods in these IRiskScoringService implementations lack ApexDoc entirely:

| File | Methods Missing ApexDoc |
|---|---|
| `ElaroCCPAComplianceService.cls` | `calculateRiskScore`, `getComplianceScore`, `getViolations`, `getFrameworkName` |
| `ElaroGDPRComplianceService.cls` | `calculateRiskScore`, `getComplianceScore`, `getViolations`, `getFrameworkName` |
| `ElaroHIPAAComplianceService.cls` | `calculateRiskScore`, `getComplianceScore`, `getViolations`, `getFrameworkName` |
| `ElaroPCIDSSComplianceService.cls` | `calculateRiskScore`, `getComplianceScore`, `getViolations`, `getFrameworkName` |
| `ElaroSOC2ComplianceService.cls` | `calculateRiskScore`, `getComplianceScore`, `getViolations`, `getFrameworkName` |

Per CLAUDE.md: "Every class and every public/global method MUST have ApexDoc comments."

---

### DOC-3. SUGGESTION: Methods exceeding 60-line recommended maximum — 21 methods across 14 service classes

Worst offenders:

| File | Method | Line Count |
|---|---|---|
| `ElaroGDPRDataErasureService.cls` | `processErasureRequest` | 134 |
| `ElaroQuickActionsService.cls` | `remediateExcessiveAdminPermissions` | 109 |
| `AssessmentWizardService.cls` | `saveStepAndAdvance` | 100 |
| `ComplianceFrameworkService.cls` | `evaluateFramework` | 94 |
| `SegregationOfDutiesService.cls` | `detectViolations` | 92 |
| `HIPAAAuditControlService.cls` | `detectSuspiciousAccess` | 85 |
| `ComplianceGraphService.cls` | `getComplianceGraph` | 83 |
| `ElaroQuickActionsService.cls` | `remediateExcessiveAssignments` | 83 |

Each should be refactored into smaller, focused helper methods.

---

## CLEAN AREAS (No Issues Found)

- **API Versions:** All 505 metadata files at v66.0 (Spring '26) — exemplary
- **WITH SECURITY_ENFORCED:** Zero usage — fully migrated to WITH USER_MODE
- **System.assertEquals:** Zero usage — fully migrated to Assert class
- **@SeeAllData=true:** Zero test classes
- **LWC deprecated directives:** Zero `if:true`/`if:false` — all using `lwc:if`
- **LWC XSS risks:** Zero `innerHTML`/`eval()`/`document.write()` — clean
- **Lightning Message Channels:** None exist — no `isExposed` risk
- **Visualforce XSS:** All 3 pages are PDF renderers with auto-escaped merge fields
- **Hardcoded credentials:** None found
- **without sharing justification:** All 8 `without sharing` classes have documented security rationale
- **Named Credentials:** All HTTP callouts use `callout:` prefix (main package)
- **Triggers per object:** No duplicate triggers on the same sObject
- **SOQL injection in services:** All dynamic SOQL uses `Database.queryWithBinds()` with bind maps
- **System.debug in services:** All 48 service classes use ElaroLogger exclusively
- **@future in services:** Zero `@future` methods — all async uses Queueable pattern

---

## SCORECARD

| Category | Weight | Score | Weighted |
|---|---|---|---|
| Security | 25% | 3.0/5 | 0.750 |
| Governor Limits & Performance | 20% | 2.5/5 | 0.500 |
| Test Quality | 15% | 4.0/5 | 0.600 |
| Maintainability | 15% | 3.5/5 | 0.525 |
| Architecture & Async | 10% | 3.5/5 | 0.350 |
| Documentation | 5% | 3.0/5 | 0.150 |
| API Version & Compliance | 5% | 5.0/5 | 0.250 |
| AppExchange Readiness | 5% | 2.0/5 | 0.100 |
| **TOTAL** | **100%** | | **3.225/5.00** |

**Percentage:** 64.5%
**Letter Grade:** D
**Auto-Fail Triggered:** YES — SOQL injection (AF-1, AF-2), `UserInfo.getSessionId()` (AF-4), syntax error (AF-5)
**Adjusted Grade:** F (auto-fail overrides score)

**AppExchange Ready:** NO — 8 blockers must be resolved

**Blockers that must be resolved before submission:**
1. Fix SOQL injection in `ElaroMatrixController.cls` — migrate to structured filters with bind variables
2. Fix SOQL injection in `ElaroTrendController.cls` — migrate to structured filters with bind variables
3. Remove `UserInfo.getSessionId()` from `ToolingApiService.cls` — use Named Credential with OAuth
4. Fix syntax error in `ApiUsageSnapshot.cls` — class will not compile
5. Fix DML-in-loop in 5 classes (`ComplianceOrchestrationEngine`, `ComplianceScoreSnapshotScheduler`, `AccessReviewScheduler`, `JiraIntegrationService`, `RemediationSuggestionService`)
6. Fix SOQL/callout-in-loop in `SOC2IncidentResponseService` and `ServiceNowIntegration`
7. Add sharing declarations to all 11 classes missing them
8. Add try-catch to all 17 `@AuraEnabled` methods missing error handling

**Additional items required for full AppExchange readiness:**
- Migrate all hardcoded English strings in 40+ LWC components to Custom Labels
- Fix corrupted code block in `ServiceNowIntegration.cls` (lines 256-258)
- Add failure notification to `ElaroBatchEventLoader.finish()`

---

## PRIORITY FIX LIST — Top 15

| # | File | Finding | Type | Effort |
|---|---|---|---|---|
| 1 | `ApiUsageSnapshot.cls` | Syntax error — will not compile | BUG | Trivial |
| 2 | `ElaroMatrixController.cls` | SOQL injection via raw filter concatenation | BUG | Medium |
| 3 | `ElaroTrendController.cls` | SOQL injection via raw additionalFilters | BUG | Medium |
| 4 | `ToolingApiService.cls` (healthcheck) | `UserInfo.getSessionId()` — AppExchange auto-fail | BUG | Medium |
| 5 | `JiraIntegrationService.cls` | SOQL/DML/Callout all in loop | BUG | Small |
| 6 | `SOC2IncidentResponseService.cls` | SOQL in loop (2 methods) | BUG | Small |
| 7 | `ComplianceScoreSnapshotScheduler.cls` | DML in loop (2 helper methods) | BUG | Small |
| 8 | `AccessReviewScheduler.cls` | DML in loop via createComplianceGap | BUG | Small |
| 9 | `ComplianceOrchestrationEngine.cls` | EventBus.publish in loop | BUG | Small |
| 10 | `RemediationSuggestionService.cls` | SOQL/DML in loop (bulkGenerateSuggestions) | BUG | Small |
| 11 | `ServiceNowIntegration.cls` | Callout in loop + corrupted code block | BUG | Medium |
| 12 | 7 controller classes | Missing try-catch on 17 @AuraEnabled methods | BUG | Small |
| 13 | 11 classes (main + healthcheck) | Missing sharing declarations | BUG | Trivial |
| 14 | 40+ LWC components | Hardcoded English strings (AppExchange blocker) | BUG | Large |
| 15 | `ElaroBatchEventLoader.cls` | Missing finish() failure notification | BUG | Small |

---

## MODERNIZATION TABLE

| Legacy Pattern | Modern Pattern | Affected Files |
|---|---|---|
| `WITH SECURITY_ENFORCED` | `WITH USER_MODE` | **0 files** — fully migrated |
| `System.assertEquals` | `Assert.areEqual` | **0 files** — fully migrated |
| `@future` | `Queueable` | `MultiOrgManager.cls` (2 methods; replacement exists) |
| Ternary null checks | `??` operator | Already using `??` extensively |
| Nested null guards | `?.` operator | Already using `?.` extensively |
| Schema.Describe FLS | `WITH USER_MODE` | `ElaroSecurityUtils.cls` still has Schema.Describe helpers (kept for backward compat); all SOQL uses `WITH USER_MODE` |
| `sfdx` commands | `sf` CLI | **0 references** — fully migrated |
| `if:true` / `if:false` | `lwc:if` / `lwc:elseif` / `lwc:else` | **0 files** — fully migrated |
| `UserInfo.getSessionId()` | Named Credential + OAuth | `ToolingApiService.cls` (healthcheck package) |
| DML in loops | Bulk collect + single DML | 5 classes (see PERF-3 through PERF-8) |
| SOQL in loops | Pre-query or inline calculation | 2 classes (see PERF-7) |
| Callout in loops | Queueable chaining | 2 classes (see PERF-6, PERF-9) |

---

**1709 files discovered, 1709 files reviewed, 27 findings recorded (covering 50+ individual issues across 30+ files).**
