# Compliance Services Implementation with Code Quality Improvements

## Overview

Extract and implement all compliance services from the Solentra branch (`claude/review-codebase-improvements-8aqoF`) while simultaneously addressing critical security vulnerabilities, test gaps, and code quality issues.

**Dual Objectives:**

1. ✅ Extract and implement 7 service classes + 5 schedulers + 4 LWC components + 5 custom objects + 4 Platform Events
2. ✅ Fix security vulnerabilities, improve test coverage, and refactor code quality issues

**Development Approach:** Work in dev org with aggressive refactoring, following Salesforce secure coding and clean-code practices, with explicit guidance on when to use Sonnet 4.5 vs Sonnet 4.5 Max mode.

**Estimated Time:** 5-6 hours

---

## Phase 0: Pre-flight in Dev Org (15 minutes - Sonnet 4.5 Normal)

**Purpose:** Establish clean baseline and deployment path before refactoring.

### Actions

1. **Confirm dev org setup:**

   - Verify dev org is "source-of-truth" scratchpad
   - Ensure all changes tracked in git (core Salesforce best practice)
   - Check `.gitignore` excludes org-specific metadata

2. **Identify external dependencies:**

   - Flows interacting with compliance services
   - External integrations (Slack, Teams, Anthropic API)
   - Platform Events: GDPR_Erasure_Event__e, GDPR_Data_Export_Event__e, PCI_Access_Event__e, GLBA_Compliance_Event__e
   - LWCs: privacyNoticeTracker, accessReviewWorkflow, pciAuditLogViewer, complianceRequestDashboard

3. **Decide tooling path:**

   - SFDX for deployment (already configured)
   - Git for version control
   - Plan for production promotion (SFDX deploy, Gearset, etc.)

### What to Look For

**Security violations:**

- Code bypassing CRUD/FLS or running in system mode without compensating controls
- Missing `WITH USER_MODE` in queries
- Missing `AccessLevel.USER_MODE` in DML

**"Snowflake org" signs:**

- Metadata only in dev org, not in git
- Manual configuration not captured
- Hardcoded IDs or org-specific values

**Audit commands:**

```bash
# Check for CRUD/FLS violations
grep -r "WITHOUT SHARING\|System\.runAs" force-app/main/default/classes/

# Check for hardcoded IDs
grep -r "00[0-9A-Za-z]{15}" force-app/main/default/

# Check for org-specific configuration
ls force-app/main/default/objects/*/fields/ | grep -v "__c.field-meta.xml"
```

### Sonnet 4.5 vs Max

**Use Sonnet 4.5 normal** - planning and quick audits don't need repo-wide context.

---

## Phase 1: Security Fixes (30 minutes - Sonnet 4.5 Normal)

**Purpose:** Fix critical vulnerabilities before extracting services.

Localized fixes in 4 files; ideal for normal Sonnet 4.5 with tight prompts.

### Salesforce Security Best Practices

1. **Enforce CRUD/FLS:**

   - Use `WITH USER_MODE` in SOQL
   - Use `AccessLevel.USER_MODE` in DML
   - Use `Schema.DescribeSObjectResult` for runtime checks

2. **Respect Sharing:**

   - Use `with sharing` where appropriate
   - Document any `without sharing` with justification

3. **Guard Against Injection:**

   - Use bind variables (`:variable`)
   - Validate and sanitize user inputs

### Fixes Required

**1.1 XSS in complianceCopilot.html:75**

- Sanitize `{message.content}` before rendering
- Use `lightning-formatted-rich-text` or manual DOM with sanitization

**1.2 Unvalidated URL in TeamsNotifier.cls:144**

- Validate `nodeId` with regex: `^[a-zA-Z0-9]{15,18}$`
- URL encode before concatenation

**1.3 HTTP Callout Hardening**

- Add 5s timeout to SlackNotifier and TeamsNotifier
- Implement retry logic (3 attempts)
- Validate response bodies

**1.4 Input Validation in ElaroComplianceCopilot**

- Add max length check (5000 chars)
- Implement rate limiting (10 queries per 5 min)

**1.5 Logging Hygiene**

- Remove stack traces from production logs
- Use correlation IDs for debugging

### Sonnet 4.5 vs Max

**Use Sonnet 4.5 normal** - touching few known files; Max overhead unnecessary.

---

## Phase 2: Extract Compliance Services (2 hours - Sonnet 4.5 Max)

**Purpose:** Extract ~7 services across many files.

### Wave A: GDPR Services (Max mode)

- GDPRDataErasureService + GDPRDataPortabilityService
- Objects: GDPR_Erasure_Request__c
- Events: GDPR_Erasure_Event__e, GDPR_Data_Export_Event__e

### Wave B: Remaining Services (Max mode)

- CCPA, PCI, GLBA, ISO 27001 services
- Related objects, events, schedulers, handlers

### Salesforce Best Practices

1. **Service/domain/selector layering:**

   - DML/queries in service classes
   - UI code (LWCs) stays thin
   - Controllers only handle `@AuraEnabled`

2. **Avoid tight coupling:**

   - Services depend on abstractions
   - Follow "leaf-to-root" migration

3. **Consistent naming:**

   - Classes: `Elaro*` prefix
   - Objects: descriptive `__c` suffix
   - Events: descriptive `__e` suffix

### Security at Boundaries

- Controllers validate access
- Services assume validation occurred
- Document security model in headers

### What to Look For

- Broken contracts (LWC ↔ Apex signatures)
- Bulkification issues
- Security regressions (missing USER_MODE)

### Sonnet 4.5 vs Max

**Use Max when:** Coordinating changes across many files, consistent naming across repo

**Drop to normal for:** Single class adjustments, small bug fixes

---

## Phase 3: Test Coverage (1.5 hours - Sonnet 4.5 Max for Cross-Cutting)

**Purpose:** Validate extracted code, prevent regressions.

### Developer Best Practices

1. **Test behavior, not implementation:**

   - Test public APIs
   - Don't test private methods
   - Focus on business logic

2. **Use test factories:**

   - Consistent data creation
   - No org data dependencies
   - Reproducible tests

3. **Salesforce testing patterns:**

   - `Test.startTest()/stopTest()` for async
   - `Test.setMock()` for HTTP callouts
   - Bulkify tests (200 records)

### Tests to Create

**Missing test classes:**

- ConsentWithdrawalHandlerTest (GDPR-critical)
- PCIAccessAlertHandlerTest (Security-critical)
- GLBAAnnualNoticeSchedulerTest
- ISO27001QuarterlyReviewSchedulerTest
- CCPASLAMonitorSchedulerTest
- DormantAccountAlertSchedulerTest

**Stub tests to replace:**

- FlowExecutionLoggerTest - add real assertions
- PerformanceAlertEventTriggerTest - test event handling

**LWC tests to create:**

- privacyNoticeTracker.test.js
- accessReviewWorkflow.test.js
- pciAuditLogViewer.test.js
- complianceRequestDashboard.test.js

### Test Quality

Replace `System.assert(true)` with specific assertions:

```apex
System.assertEquals('Completed', result.status, 'Status should be Completed');
System.assertEquals(45, result.responseDeadlineDays, 'CCPA deadline is 45 days');
```

### Sonnet 4.5 vs Max

**Use Max when:** Designing cross-cutting test suite, seeing patterns

**Use normal when:** Single test class, fixing specific failure

---

## Phase 4: Code Quality (1 hour - Sonnet 4.5 Normal)

**Purpose:** Improve readability and maintainability with test safety net.

### Clean-Code Practices

1. **Consistent naming** - Follow Salesforce conventions
2. **Comments only where necessary** - Self-documenting code
3. **Clear error handling** - Specific exceptions, correlation IDs
4. **Remove dead code** - Keep org lean

### Refactoring Tasks

**1. Large methods:**

- WeeklyScorecardScheduler.sendSlackScorecard() (130+ lines) → Extract helper methods
- ElaroComplianceCopilot.classifyQuery() (40 lines) → Map-based lookup

**2. Code duplication:**

- Risk score calculation (3 implementations) → Centralize in ElaroReasoningEngine

**3. Exception handling:**

- Replace broad `catch (Exception e)` with specific types
- 20+ instances across service classes

**4. Governor limits:**

- GDPRDataErasureService: Bulkify sequential deletes
- ElaroComplianceScorer: Combine multiple COUNT queries

### Sonnet 4.5 vs Max

**Use normal for:** Single method refactoring, naming improvements

**Use Max only for:** Repo-wide naming sweep, multi-module consistency

---

## Phase 5: LWC Polish (30 minutes - Sonnet 4.5 Normal)

**Purpose:** Production readiness.

### Tasks

1. **Remove console logging (11 instances):**

   - Replace with `ShowToastEvent`
   - Log to server-side handler

2. **Add accessibility:**

   - ARIA labels on interactive elements
   - Keyboard navigation
   - Screen reader compatibility

### Files to Fix

- elaroScoreListener.js (5 console statements)
- elaroDashboard.js (2)
- complianceCopilot.js (1)
- elaroCopilot.js (1)
- Plus 4 more components

### Sonnet 4.5 vs Max

**Use normal** - localized LWC improvements don't need repo-wide context.

---

## Phase 6: Documentation (30 minutes - Sonnet 4.5 Normal)

**Purpose:** Complete documentation gaps.

### Tasks

1. **Add parameter descriptions:**

   - FlowExecutionLogger.cls @InvocableMethod
   - All @AuraEnabled methods

2. **Document complex logic:**

   - WeeklyScorecardScheduler date calculations
   - ElaroComplianceScorer return structure

3. **Create service catalog:**

   - Document each service's responsibilities
   - Public API reference
   - Usage examples

### Sonnet 4.5 vs Max

**Use normal** - documentation of individual methods/classes.

---

## Implementation Order

1. **Phase 0: Pre-flight** (15 min) - Sonnet 4.5 normal
2. **Phase 1: Security** (30 min) - Sonnet 4.5 normal
3. **Phase 2: Extract Services** (2 hours) - Sonnet 4.5 Max (2 waves)
4. **Phase 3: Tests** (1.5 hours) - Sonnet 4.5 Max for design, normal for implementation
5. **Phase 4: Code Quality** (1 hour) - Sonnet 4.5 normal
6. **Phase 5: LWC Polish** (30 min) - Sonnet 4.5 normal
7. **Phase 6: Documentation** (30 min) - Sonnet 4.5 normal

**Total:** 5.5-6 hours

---

## Success Criteria

✅ All security vulnerabilities fixed

✅ All compliance services deployed

✅ 80%+ test coverage

✅ No stub tests

✅ Code quality improvements complete

✅ No console.log in production

✅ Accessibility added

✅ Documentation complete

---

## Key Principles

**Security:** WITH USER_MODE, AccessLevel.USER_MODE, with sharing

**Testing:** Behavior-focused, 200-record bulk, edge cases

**Code Quality:** Small methods, no duplication, specific exceptions

**Deployment:** Everything in git, reproducible from source

**Ready to implement!** 🚀