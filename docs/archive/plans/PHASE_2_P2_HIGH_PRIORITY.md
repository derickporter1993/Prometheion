# PHASE 2: P2 HIGH PRIORITY

## Execution Plan

**Timeline:** Days 4-5
**Assignees:** Claude Code (Backend) + Cursor (UI)
**Priority:** HIGH - Strengthens security posture and reliability
**Dependencies:** Phase 1 must be complete

---

## OVERVIEW

Phase 2 addresses high-priority improvements that strengthen the application's security posture, reliability, and user experience.

| Domain | Assignee | Tasks | Hours |
|--------|----------|-------|-------|
| Backend Infrastructure | Claude Code | 12 tasks | 22h |
| UI Polish | Cursor | 6 tasks | 12h |

---

# CLAUDE CODE TASKS

## 2.1 SCHEDULER/BATCH ERROR HANDLING (8 hours)

### Task SCH1: ElaroCCPASLAMonitorScheduler

**File:** `force-app/main/default/classes/ElaroCCPASLAMonitorScheduler.cls`
**Issue:** No try-catch in execute() method (Line 22)

**Current State:**
```apex
public void execute(SchedulableContext sc) {
    checkSLACompliance();
    sendOverdueNotifications();
    updateRequestStatuses();
}
```

**Required Fix:**
```apex
public void execute(SchedulableContext sc) {
    Savepoint sp = Database.setSavepoint();
    try {
        checkSLACompliance();
        sendOverdueNotifications();
        updateRequestStatuses();
        logSuccessfulExecution();
    } catch (Exception e) {
        Database.rollback(sp);
        logExecutionError(e);
        notifyAdminsOfFailure(e);
    }
}

private void logSuccessfulExecution() {
    insert new Integration_Error__c(
        Error_Type__c = 'SCHEDULER_SUCCESS',
        Error_Message__c = 'CCPA SLA Monitor completed successfully',
        Timestamp__c = System.now(),
        Context__c = 'ElaroCCPASLAMonitorScheduler'
    );
}

private void logExecutionError(Exception e) {
    insert new Integration_Error__c(
        Error_Type__c = 'SCHEDULER_FAILURE',
        Error_Message__c = e.getMessage(),
        Stack_Trace__c = e.getStackTraceString().left(32000),
        Timestamp__c = System.now(),
        Context__c = 'ElaroCCPASLAMonitorScheduler'
    );
}

private void notifyAdminsOfFailure(Exception e) {
    // Send email or Slack notification
    try {
        SlackNotifier.notifyAsync('CCPA SLA Monitor failed: ' + e.getMessage());
    } catch (Exception notifyError) {
        System.debug(LoggingLevel.ERROR, 'Failed to notify: ' + notifyError.getMessage());
    }
}
```

**Also fix Line 89:** Add SaveResult handling
```apex
// BEFORE
Database.update(overdueRequests, AccessLevel.USER_MODE);

// AFTER
List<Database.SaveResult> results = Database.update(overdueRequests, false);
for (Database.SaveResult sr : results) {
    if (!sr.isSuccess()) {
        for (Database.Error err : sr.getErrors()) {
            System.debug(LoggingLevel.ERROR, 'Update failed: ' + err.getMessage());
        }
    }
}
```

---

### Task SCH2: ElaroDormantAccountAlertScheduler

**File:** `force-app/main/default/classes/ElaroDormantAccountAlertScheduler.cls`
**Issue:** No error handling in 4 methods

**Methods to wrap in try-catch:**
1. `execute()` (Line 22)
2. `detectDormantAccounts()` (Lines 31-82)
3. `detectApproachingDormant()` (Lines 87-115)
4. `generateSecurityReport()` (Lines 120-157)

**Pattern:**
```apex
public void execute(SchedulableContext sc) {
    try {
        detectDormantAccounts();
        detectApproachingDormant();
        generateSecurityReport();
    } catch (Exception e) {
        handleSchedulerError('ElaroDormantAccountAlertScheduler', e);
    }
}

private void detectDormantAccounts() {
    try {
        // Existing logic
    } catch (Exception e) {
        handleMethodError('detectDormantAccounts', e);
        throw e; // Re-throw to stop execution
    }
}

private void handleSchedulerError(String schedulerName, Exception e) {
    System.debug(LoggingLevel.ERROR, schedulerName + ' failed: ' + e.getMessage());
    // Log to Integration_Error__c
    // Send notification
}
```

**Also fix hardcoded LIMIT (Line 42):**
```apex
// BEFORE
LIMIT 500

// AFTER - Use Custom Metadata for configuration
Integer batchLimit = Elaro_Scheduler_Config__mdt.getInstance('DormantAccountAlert')?.Batch_Size__c?.intValue() ?? 500;
// ... LIMIT :batchLimit
```

---

### Task SCH3: ElaroGLBAAnnualNoticeScheduler

**File:** `force-app/main/default/classes/ElaroGLBAAnnualNoticeScheduler.cls`
**Issues:**
- No error handling in execute() (Line 19)
- No logging at all in entire class

**Required Fix:**
```apex
public void execute(SchedulableContext sc) {
    System.debug(LoggingLevel.INFO, 'GLBA Annual Notice Scheduler started');

    try {
        // Check if today is a business day
        if (!isBusinessDay(Date.today())) {
            System.debug(LoggingLevel.INFO, 'Skipping - not a business day');
            return;
        }

        Id batchId = Database.executeBatch(new ElaroGLBAAnnualNoticeBatch(), 200);
        System.debug(LoggingLevel.INFO, 'Batch job queued with ID: ' + batchId);

        // Log successful scheduling
        insert new Integration_Error__c(
            Error_Type__c = 'SCHEDULER_INFO',
            Error_Message__c = 'GLBA batch scheduled successfully',
            Context__c = 'BatchId: ' + batchId,
            Timestamp__c = System.now()
        );

    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'GLBA Scheduler failed: ' + e.getMessage());
        System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());

        insert new Integration_Error__c(
            Error_Type__c = 'SCHEDULER_FAILURE',
            Error_Message__c = e.getMessage(),
            Stack_Trace__c = e.getStackTraceString().left(32000),
            Context__c = 'ElaroGLBAAnnualNoticeScheduler',
            Timestamp__c = System.now()
        );
    }
}
```

---

### Task SCH4: ElaroGLBAAnnualNoticeBatch

**File:** `force-app/main/default/classes/ElaroGLBAAnnualNoticeBatch.cls`

**Fix start() method (Line 14):**
```apex
public Database.QueryLocator start(Database.BatchableContext bc) {
    System.debug(LoggingLevel.INFO, 'GLBA Batch start() - Job ID: ' + bc.getJobId());

    try {
        return Database.getQueryLocator([
            SELECT Id, Name, Email, MailingAddress, ...
            FROM Contact
            WHERE ...
            WITH SECURITY_ENFORCED
        ]);
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'Query failed: ' + e.getMessage());
        // Log error
        throw e;
    }
}
```

**Fix execute() method (Line 63) - Add SaveResult handling:**
```apex
// BEFORE
Database.insert(newNotices, AccessLevel.USER_MODE);

// AFTER
List<Database.SaveResult> results = Database.insert(newNotices, false);
for (Integer i = 0; i < results.size(); i++) {
    if (!results[i].isSuccess()) {
        errors++;
        for (Database.Error err : results[i].getErrors()) {
            System.debug(LoggingLevel.ERROR, 'Insert failed for notice ' + i + ': ' + err.getMessage());
        }
    } else {
        noticesSent++;
    }
}
```

**Fix finish() method - Add job validation (Line 89):**
```apex
public void finish(Database.BatchableContext bc) {
    System.debug(LoggingLevel.INFO, 'GLBA Batch finish() - Notices sent: ' + noticesSent + ', Errors: ' + errors);

    // Query job status
    AsyncApexJob job = [
        SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
        FROM AsyncApexJob
        WHERE Id = :bc.getJobId()
    ];

    // Build summary
    String summary = String.format(
        'GLBA Annual Notice Batch Complete\n' +
        'Status: {0}\n' +
        'Items Processed: {1}/{2}\n' +
        'Notices Sent: {3}\n' +
        'Errors: {4}',
        new List<Object>{
            job.Status,
            job.JobItemsProcessed,
            job.TotalJobItems,
            noticesSent,
            errors + job.NumberOfErrors
        }
    );

    // Send notification
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(new String[] { job.CreatedBy.Email });
    mail.setSubject('GLBA Annual Notice Batch Complete');
    mail.setPlainTextBody(summary);

    try {
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'Failed to send notification email: ' + e.getMessage());
    }
}
```

**Uncomment email notification (Line 100):**
```apex
// Line 100 - UNCOMMENT
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
```

---

### Task SCH5-SCH6: Create Scheduler Utility Class

**New File:** `force-app/main/default/classes/SchedulerErrorHandler.cls`

```apex
public class SchedulerErrorHandler {

    public static void logError(String schedulerName, Exception e) {
        try {
            insert new Integration_Error__c(
                Error_Type__c = 'SCHEDULER_FAILURE',
                Error_Message__c = e.getMessage().left(255),
                Stack_Trace__c = e.getStackTraceString().left(32000),
                Context__c = schedulerName,
                Timestamp__c = System.now()
            );
        } catch (Exception logError) {
            System.debug(LoggingLevel.ERROR, 'Failed to log error: ' + logError.getMessage());
        }
    }

    public static void logSuccess(String schedulerName, String details) {
        try {
            insert new Integration_Error__c(
                Error_Type__c = 'SCHEDULER_SUCCESS',
                Error_Message__c = details.left(255),
                Context__c = schedulerName,
                Timestamp__c = System.now()
            );
        } catch (Exception logError) {
            System.debug(LoggingLevel.ERROR, 'Failed to log success: ' + logError.getMessage());
        }
    }

    public static void notifyOnFailure(String schedulerName, Exception e) {
        try {
            String message = schedulerName + ' failed: ' + e.getMessage();
            SlackNotifier.notifyAsync(message);
        } catch (Exception notifyError) {
            System.debug(LoggingLevel.ERROR, 'Failed to notify: ' + notifyError.getMessage());
        }
    }
}
```

---

## 2.2 PERMISSION SET FIXES (4 hours)

### Task P1: Remove modifyAllRecords from Admin_Extended

**File:** `force-app/main/default/permissionsets/Elaro_Admin_Extended.permissionset-meta.xml`

**Current State (Dangerous):**
```xml
<objectPermissions>
    <allowCreate>true</allowCreate>
    <allowDelete>true</allowDelete>
    <allowEdit>true</allowEdit>
    <allowRead>true</allowRead>
    <modifyAllRecords>true</modifyAllRecords>  <!-- REMOVE THIS -->
    <viewAllRecords>true</viewAllRecords>
    <object>Alert__c</object>
</objectPermissions>
```

**Required Fix:**
```xml
<objectPermissions>
    <allowCreate>true</allowCreate>
    <allowDelete>true</allowDelete>
    <allowEdit>true</allowEdit>
    <allowRead>true</allowRead>
    <modifyAllRecords>false</modifyAllRecords>
    <viewAllRecords>true</viewAllRecords>
    <object>Alert__c</object>
</objectPermissions>
```

**Apply to all 11 objects** in the permission set.

---

### Task P2: Add Missing Object Permissions

**File:** `force-app/main/default/permissionsets/Elaro_Admin.permissionset-meta.xml`

**Add permissions for 9 missing objects:**

```xml
<!-- Add these object permissions -->
<objectPermissions>
    <allowCreate>true</allowCreate>
    <allowDelete>false</allowDelete>
    <allowEdit>true</allowEdit>
    <allowRead>true</allowRead>
    <modifyAllRecords>false</modifyAllRecords>
    <viewAllRecords>true</viewAllRecords>
    <object>Access_Review__c</object>
</objectPermissions>

<objectPermissions>
    <allowCreate>true</allowCreate>
    <allowDelete>false</allowDelete>
    <allowEdit>true</allowEdit>
    <allowRead>true</allowRead>
    <modifyAllRecords>false</modifyAllRecords>
    <viewAllRecords>true</viewAllRecords>
    <object>CCPA_Request__c</object>
</objectPermissions>

<!-- Repeat for: Consent__c, GDPR_Erasure_Request__c, Privacy_Notice__c,
     Elaro_AI_Settings__c, Elaro_Audit_Log__c,
     Elaro_Compliance_Graph__b, CCX_Settings__c -->
```

---

### Task P3: Add Missing Apex Class Access

**Add to both permission sets:**

```xml
<!-- Controllers -->
<classAccesses>
    <apexClass>ElaroMatrixController</apexClass>
    <enabled>true</enabled>
</classAccesses>
<classAccesses>
    <apexClass>ElaroTrendController</apexClass>
    <enabled>true</enabled>
</classAccesses>
<classAccesses>
    <apexClass>ElaroExecutiveKPIController</apexClass>
    <enabled>true</enabled>
</classAccesses>
<classAccesses>
    <apexClass>ElaroDrillDownController</apexClass>
    <enabled>true</enabled>
</classAccesses>
<classAccesses>
    <apexClass>ElaroDynamicReportController</apexClass>
    <enabled>true</enabled>
</classAccesses>

<!-- Services -->
<classAccesses>
    <apexClass>ElaroGDPRDataErasureService</apexClass>
    <enabled>true</enabled>
</classAccesses>
<classAccesses>
    <apexClass>ElaroGDPRDataPortabilityService</apexClass>
    <enabled>true</enabled>
</classAccesses>
<!-- ... add remaining 21 classes -->
```

**Full list of 28 classes to add:**
1. ElaroMatrixController
2. ElaroTrendController
3. ElaroExecutiveKPIController
4. ElaroDrillDownController
5. ElaroDynamicReportController
6. ElaroGDPRDataErasureService
7. ElaroGDPRDataPortabilityService
8. ElaroPCIAccessLogger
9. ElaroPCIDataMaskingService
10. ElaroSalesforceThreatDetector
11. ElaroRemediationEngine
12. ElaroChangeAdvisor
13. ElaroConsentWithdrawalHandler
14. ElaroCCPADataInventoryService
15. ISO27001QuarterlyReviewScheduler
16. ElaroAuditTrailPoller
17. ElaroCCPASLAMonitorScheduler
18. ElaroDormantAccountAlertScheduler
19. ElaroISO27001QuarterlyScheduler
20. ElaroGLBAAnnualNoticeBatch
21. ElaroGLBAAnnualNoticeScheduler
22. ElaroEventPublisher
23. ElaroScoreCallback
24. ElaroPCIAccessAlertHandler
25. ElaroSlackNotifierQueueable
26. ApiUsageSnapshot
27. PerformanceAlertPublisher
28. WeeklyScorecardScheduler

---

## 2.3 CODE QUALITY FIXES (6 hours)

### Task Q1: Bulkify ComplianceFrameworkService

**File:** `force-app/main/default/classes/ComplianceFrameworkService.cls`
**Lines:** 44-54

**Current State (SOQL in loop):**
```apex
for (Compliance_Policy__mdt policy : policies) {
    List<Compliance_Gap__c> policyGaps = [
        SELECT Id, Severity__c, Status__c, Risk_Score__c
        FROM Compliance_Gap__c
        WHERE Policy_Reference__c = :policy.DeveloperName
        AND Status__c != 'REMEDIATED'
        WITH SECURITY_ENFORCED
    ];
    // Process gaps
}
```

**Required Fix:**
```apex
// Collect all policy names first
Set<String> policyNames = new Set<String>();
for (Compliance_Policy__mdt policy : policies) {
    policyNames.add(policy.DeveloperName);
}

// Single query for all gaps
Map<String, List<Compliance_Gap__c>> gapsByPolicy = new Map<String, List<Compliance_Gap__c>>();
for (Compliance_Gap__c gap : [
    SELECT Id, Severity__c, Status__c, Risk_Score__c, Policy_Reference__c
    FROM Compliance_Gap__c
    WHERE Policy_Reference__c IN :policyNames
    AND Status__c != 'REMEDIATED'
    WITH SECURITY_ENFORCED
]) {
    if (!gapsByPolicy.containsKey(gap.Policy_Reference__c)) {
        gapsByPolicy.put(gap.Policy_Reference__c, new List<Compliance_Gap__c>());
    }
    gapsByPolicy.get(gap.Policy_Reference__c).add(gap);
}

// Process using map
for (Compliance_Policy__mdt policy : policies) {
    List<Compliance_Gap__c> policyGaps = gapsByPolicy.get(policy.DeveloperName);
    if (policyGaps == null) {
        policyGaps = new List<Compliance_Gap__c>();
    }
    // Process gaps
}
```

---

### Task Q2: Optimize ElaroISO27001AccessReviewService

**File:** `force-app/main/default/classes/ElaroISO27001AccessReviewService.cls`
**Lines:** 309-378

**Current State (6 separate COUNT queries):**
```apex
metrics.put('reviewsThisQuarter', [SELECT COUNT() FROM Access_Review__c WHERE ...]);
Integer total = [SELECT COUNT() FROM Access_Review__c WHERE ...];
Integer completed = [SELECT COUNT() FROM Access_Review__c WHERE ...];
metrics.put('overdueCount', [SELECT COUNT() FROM Access_Review__c WHERE ...]);
metrics.put('privilegedUsersCount', [SELECT COUNT() FROM User WHERE ...]);
metrics.put('dormantAccountsCount', [SELECT COUNT() FROM User WHERE ...]);
```

**Required Fix (combine into aggregate queries):**
```apex
// Combine Access_Review counts into single query
List<AggregateResult> reviewStats = [
    SELECT
        COUNT(Id) total,
        SUM(CASE WHEN Review_Status__c = 'Completed' THEN 1 ELSE 0 END) completed,
        SUM(CASE WHEN Due_Date__c < TODAY AND Review_Status__c != 'Completed' THEN 1 ELSE 0 END) overdue,
        SUM(CASE WHEN CreatedDate >= THIS_QUARTER THEN 1 ELSE 0 END) thisQuarter
    FROM Access_Review__c
    WHERE Review_Type__c = 'ISO27001'
    WITH SECURITY_ENFORCED
];

if (!reviewStats.isEmpty()) {
    AggregateResult ar = reviewStats[0];
    metrics.put('reviewsThisQuarter', ar.get('thisQuarter'));
    metrics.put('overdueCount', ar.get('overdue'));
    Integer total = (Integer)ar.get('total');
    Integer completed = (Integer)ar.get('completed');
    metrics.put('completionRate', total > 0 ? (completed * 100 / total) : 0);
}

// Combine User counts
List<AggregateResult> userStats = [
    SELECT
        SUM(CASE WHEN Profile.PermissionsModifyAllData = true THEN 1 ELSE 0 END) privileged,
        SUM(CASE WHEN LastLoginDate < LAST_N_DAYS:90 THEN 1 ELSE 0 END) dormant
    FROM User
    WHERE IsActive = true
    WITH SECURITY_ENFORCED
];
```

---

### Task Q3: Add Transaction Management to GDPR Erasure

**File:** `force-app/main/default/classes/ElaroGDPRDataErasureService.cls`
**Lines:** 52-128

```apex
public static void eraseContactData(Id contactId) {
    // Add savepoint for rollback
    Savepoint sp = Database.setSavepoint();

    try {
        // Validate first
        validateForErasure(contactId);

        // Delete related records
        deleteRelatedCases(contactId);
        deleteRelatedTasks(contactId);
        deleteRelatedEvents(contactId);
        deleteRelatedOpportunities(contactId);
        deleteRelatedCampaignMembers(contactId);

        // Anonymize contact
        anonymizeContact(contactId);

        // Create audit record
        createErasureAuditRecord(contactId);

    } catch (Exception e) {
        // Rollback all changes
        Database.rollback(sp);

        // Log error
        insert new Integration_Error__c(
            Error_Type__c = 'GDPR_ERASURE_FAILURE',
            Error_Message__c = e.getMessage(),
            Stack_Trace__c = e.getStackTraceString().left(32000),
            Context__c = 'ContactId: ' + contactId,
            Timestamp__c = System.now()
        );

        throw new GDPRErasureException('Failed to complete erasure: ' + e.getMessage(), e);
    }
}

public class GDPRErasureException extends Exception {}
```

---

### Task Q4: Add Sharing Declarations

**File:** `force-app/main/default/classes/ElaroAuditTrailPoller.cls`

```apex
// BEFORE
public class ElaroAuditTrailPoller implements Schedulable {

// AFTER
public without sharing class ElaroAuditTrailPoller implements Schedulable {
    // Runs in system context to poll audit trail regardless of user permissions
```

**File:** `force-app/main/default/classes/ElaroScoreCallback.cls`

```apex
// BEFORE
global class ElaroScoreCallback {

// AFTER
global without sharing class ElaroScoreCallback {
    // External API callback runs in system context
```

---

## 2.4 CONFIGURATION STANDARDIZATION (2 hours)

### Task CFG1: Standardize API Versions

**Update all triggers to API 63.0:**

| File | Current | Target |
|------|---------|--------|
| `ElaroAlertTrigger.trigger-meta.xml` | 62.0 | 63.0 |
| `ElaroPCIAccessAlertTrigger.trigger-meta.xml` | 64.0 | 63.0 |
| `ElaroConsentWithdrawalTrigger.trigger-meta.xml` | 64.0 | 63.0 |
| `PerformanceAlertEventTrigger.trigger-meta.xml` | 65.0 | 63.0 |

---

### Task CFG2: Move CRON to Custom Metadata

**Create Custom Metadata Type:** `Elaro_Scheduler_Config__mdt`

**Fields:**
- `Scheduler_Name__c` (Text, Unique)
- `CRON_Expression__c` (Text)
- `Batch_Size__c` (Number)
- `Is_Active__c` (Checkbox)
- `Description__c` (Long Text)

**Records to create:**
```
Name: ISO27001QuarterlyReview
CRON_Expression__c: 0 0 7 1 1,4,7,10 ?
Batch_Size__c: 200
Is_Active__c: true

Name: CCPASLAMonitor
CRON_Expression__c: 0 0 8 * * ?
Batch_Size__c: 200
Is_Active__c: true

Name: DormantAccountAlert
CRON_Expression__c: 0 0 5 * * ?
Batch_Size__c: 500
Is_Active__c: true

Name: GLBAAnnualNotice
CRON_Expression__c: 0 0 6 * * ?
Batch_Size__c: 200
Is_Active__c: true

Name: WeeklyScorecard
CRON_Expression__c: 0 0 9 ? * MON *
Batch_Size__c: 100
Is_Active__c: true
```

---

### Task CFG3: Remove Duplicate Scheduler

Delete one of:
- `ISO27001QuarterlyReviewScheduler.cls`
- `ElaroISO27001QuarterlyScheduler.cls`

**Keep:** `ElaroISO27001QuarterlyScheduler.cls` (follows naming convention)
**Delete:** `ISO27001QuarterlyReviewScheduler.cls`

**Update references** in any test classes or scheduled jobs.

---

# CURSOR TASKS

## 2.5 INTERNATIONALIZATION (6 hours)

### Task i18n1: Create Custom Labels

**File to create:** `force-app/main/default/labels/CustomLabels.labels-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomLabels xmlns="http://soap.sforce.com/2006/04/metadata">
    <!-- Dashboard Titles -->
    <labels>
        <fullName>Elaro_Dashboard_Title</fullName>
        <language>en_US</language>
        <protected>false</protected>
        <shortDescription>Dashboard Title</shortDescription>
        <value>Elaro Compliance Hub</value>
    </labels>
    <labels>
        <fullName>API_Usage_Title</fullName>
        <language>en_US</language>
        <protected>false</protected>
        <shortDescription>API Usage Title</shortDescription>
        <value>API Usage &amp; Forecasting</value>
    </labels>
    <!-- Add 50+ more labels for all hardcoded text -->
</CustomLabels>
```

### Task i18n2: Update LWC Components

**Pattern:**
```javascript
// Import labels
import DASHBOARD_TITLE from '@salesforce/label/c.Elaro_Dashboard_Title';

export default class ElaroDashboard extends LightningElement {
    labels = {
        dashboardTitle: DASHBOARD_TITLE
    };
}
```

```html
<!-- Use in template -->
<h1>{labels.dashboardTitle}</h1>
```

---

## 2.6 XSS PREVENTION (2 hours)

### Task XSS1: Sanitize Rich Text Content

**Files:** `elaroCopilot.html`, `complianceCopilot.html`

**Option 1: Use lightning-formatted-text instead:**
```html
<!-- BEFORE -->
<lightning-formatted-rich-text value={message.content}></lightning-formatted-rich-text>

<!-- AFTER (safer) -->
<lightning-formatted-text value={message.content}></lightning-formatted-text>
```

**Option 2: Sanitize server-side:**
```apex
// In controller
@AuraEnabled
public static String sanitizeContent(String content) {
    // Remove script tags and event handlers
    String sanitized = content.replaceAll('(?i)<script[^>]*>.*?</script>', '');
    sanitized = sanitized.replaceAll('(?i)\\son\\w+\\s*=', ' ');
    return sanitized;
}
```

---

## 2.7 MOBILE RESPONSIVENESS (4 hours)

### Task MOB1: Add Responsive CSS

**Create:** `force-app/main/default/lwc/elaroDashboard/elaroDashboard.css`

```css
/* Mobile-first responsive design */
.dashboard-container {
    display: grid;
    gap: 1rem;
    padding: 1rem;
}

/* Mobile: Stack everything */
@media (max-width: 767px) {
    .dashboard-container {
        grid-template-columns: 1fr;
    }

    .card-header {
        font-size: 1rem;
    }

    .metric-value {
        font-size: 1.5rem;
    }
}

/* Tablet: 2 columns */
@media (min-width: 768px) and (max-width: 1023px) {
    .dashboard-container {
        grid-template-columns: repeat(2, 1fr);
    }
}

/* Desktop: 3-4 columns */
@media (min-width: 1024px) {
    .dashboard-container {
        grid-template-columns: repeat(3, 1fr);
    }
}

@media (min-width: 1280px) {
    .dashboard-container {
        grid-template-columns: repeat(4, 1fr);
    }
}
```

### Task MOB2: Test on Devices

**Test matrix:**
- iPhone 12/13/14 (Safari)
- Samsung Galaxy S21/S22 (Chrome)
- iPad (Safari)
- iPad Pro (Safari)
- Desktop Chrome, Firefox, Safari, Edge

---

## VALIDATION CHECKLIST

### End of Day 4
- [ ] All scheduler error handling implemented (SCH1-SCH6)
- [ ] Permission set fixes applied (P1-P3)
- [ ] Custom labels created (i18n1)

### End of Day 5
- [ ] Code quality fixes complete (Q1-Q4)
- [ ] Configuration standardized (CFG1-CFG3)
- [ ] XSS prevention implemented (XSS1)
- [ ] Mobile responsiveness verified (MOB1-MOB2)

### Integration Testing
```bash
# Run all tests
sfdx force:apex:test:run --codecoverage --resultformat human

# Verify schedulers
sfdx force:apex:execute -f scripts/apex/verify-schedulers.apex

# Test permission sets
sfdx force:user:permset:assign -n Elaro_Admin -u testuser@example.com
```

---

## SIGN-OFF

| Task | Claude Code | Cursor | Verified |
|------|-------------|--------|----------|
| Scheduler Error Handling | ☐ | - | ☐ |
| Permission Set Fixes | ☐ | - | ☐ |
| Code Quality | ☐ | - | ☐ |
| Config Standardization | ☐ | - | ☐ |
| Custom Labels | - | ☐ | ☐ |
| XSS Prevention | - | ☐ | ☐ |
| Mobile Responsive | - | ☐ | ☐ |

**Phase 2 Complete:** ☐
**Ready for Phase 3:** ☐
