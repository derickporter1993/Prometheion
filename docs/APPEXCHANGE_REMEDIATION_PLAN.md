# ELARO APPEXCHANGE REMEDIATION PLAN

## Comprehensive Execution Guide

**Timeline:** 10 days (sequential) | 5-7 days (parallel)
**Total Issues Identified:** 195+
**Created:** January 2026
**Status:** READY FOR EXECUTION

---

## EXECUTIVE SUMMARY

### Current Blocking Issues

| Category | Current State | Required State | Gap | Issues Found |
|----------|--------------|----------------|-----|--------------|
| **Test Coverage** | 29% | 75% minimum | 46 percentage points | 13 test quality issues |
| **Security Vulnerabilities** | 33+ identified | 0 critical/high | 33 unresolved | FLS, SOQL injection, auth gaps |
| **Accessibility** | WCAG violations | WCAG 2.1 AA | Multiple violations | 20+ LWC template issues |
| **Code Compilation** | 4 critical bugs | 0 errors | 4 blockers | Merge conflicts, type mismatches |
| **Documentation** | Incomplete | Full docs | 3 docs missing | Install, User, Admin guides |

### Issue Severity Breakdown

| Severity | Count | Description |
|----------|-------|-------------|
| 🚨 **CRITICAL** | 18 | Compilation errors, security holes, data integrity |
| 🔴 **HIGH** | 58+ | Security vulnerabilities, missing error handling |
| 🟠 **MEDIUM** | 82+ | Code quality, validation, UX issues |
| 🟡 **LOW** | 37 | Naming conventions, documentation, optimization |

---

## PARALLEL DEVELOPMENT STRATEGY

### Domain Separation

| AI Assistant | Domain | File Paths | Focus |
|--------------|--------|------------|-------|
| **Claude Code** | Security & Backend | `/classes/*.cls`, `/triggers/*.trigger`, `/objects/*` | P1/P2 blockers, security, tests |
| **Cursor** | UI & Documentation | `/lwc/*`, `/docs/*`, `/README.md` | Accessibility, UX, documentation |

### Critical Success Factors

1. **Daily sync:** Both AIs commit to feature branches, human reviews PRs before merge
2. **Clear boundaries:** No shared files between domains (prevents merge conflicts)
3. **Integration testing:** Human runs full test suite after each domain completes
4. **Quality gates:** P1 items must pass before P2 begins

---

## PHASE 0: IMMEDIATE BLOCKERS (Day 0 - First 4 Hours)

> ⚠️ **These issues prevent compilation. Fix before any other work.**

### 0.1 Resolve Merge Conflicts (CRITICAL)

| File | Lines | Issue | Fix |
|------|-------|-------|-----|
| `ApiUsageDashboardController.cls` | 36-57 | Git merge conflict markers | Resolve conflict, keep `WITH SECURITY_ENFORCED` |
| `AlertHistoryService.cls` | 44-57 | Duplicate method definition | Remove duplicate `recent()` method |

**Command to verify:**
```bash
grep -r "<<<<<<" force-app/main/default/classes/
```

### 0.2 Fix Compilation Errors (CRITICAL)

| File | Line | Issue | Fix |
|------|------|-------|-----|
| `PerformanceAlertEventTrigger.trigger` | 12 | Method signature mismatch | Change `notifyPerformanceEvent(e)` to `notifyPerformanceAlert(e.Metric__c, e.Value__c, e.Threshold__c, e.Context_Record__c)` |
| `ElaroComplianceScorer.cls` | 3 | Returns `Decimal` but callers expect `ScoreResult` | Add inner class with `frameworkScores` Map and `overallScore` Decimal |
| `ComplianceTestDataFactory.cls` | 105 | Picklist case mismatch | Change `'CRITICAL'` to `'Critical'`, `'HIGH'` to `'High'`, etc. |

### 0.3 Fix Data Integrity Bug (CRITICAL)

| File | Line | Issue | Fix |
|------|------|-------|-----|
| `ElaroGraphIndexer.cls` | 51 | `generateDeterministicHash()` uses `System.now().getTime()` | Remove timestamp from hash input |

**Estimated Time:** 4 hours
**Assignee:** Claude Code

---

## PHASE 1: P1 BLOCKERS (Days 1-3)

> **Objective:** Resolve all AppExchange-blocking issues for security review submission.

### Claude Code Tasks (Security & Backend)

#### 1.1 Security Fixes - FLS/CRUD Violations (8 hours)

| ID | File | Lines | Issue | Fix |
|----|------|-------|-------|-----|
| S1 | `ElaroQuickActionsService.cls` | 63-75, 104-111, 161-168, 228-233, 274-281, 380-385, 422-428, 469-473 | 8 queries missing `WITH SECURITY_ENFORCED` | Add clause to all queries |
| S2 | `ElaroQuickActionsService.cls` | 139, 236, 245, 338, 393, 441, 475 | 7 DML operations without CRUD check | Use `Security.stripInaccessible()` or validate permissions |
| S3 | `ApiUsageSnapshot.cls` | 37 | INSERT without FLS check | Add CRUD validation before insert |
| S4 | `MetadataChangeTracker.cls` | 38 | INSERT without FLS check | Add CRUD validation |
| S5 | `PerformanceRuleEngine.cls` | 251 | Database.insert without security | Use `Security.stripInaccessible()` |

#### 1.2 Security Fixes - Authentication & Injection (6 hours)

| ID | File | Lines | Issue | Fix |
|----|------|-------|-------|-----|
| S6 | `ElaroScoreCallback.cls` | 14-15 | REST endpoint has NO authentication | Add API key or JWT validation |
| S7 | `ElaroScoreCallback.cls` | 102-109 | Exposes stack traces to external callers | Remove `e.getStackTraceString()` from response |
| S8 | `TeamsNotifier.cls` | 204, 209 | URL injection - IDs not encoded | Use `EncodingUtil.urlEncode()` |

#### 1.3 HTTP Callout Fixes (4 hours)

| ID | File | Lines | Issue | Fix |
|----|------|-------|-------|-----|
| H1 | `TeamsNotifier.cls` | 20-25, 40-45 | Missing HTTP timeout | Add `req.setTimeout(10000);` |
| H2 | `ApiUsageSnapshot.cls` | 13-17 | Missing HTTP timeout | Add `req.setTimeout(10000);` |
| H3 | `TeamsNotifier.cls` | All | No retry logic | Implement retry with exponential backoff |

#### 1.4 Test Class Creation (20 hours)

| ID | Test Class | Target Class | Coverage Goal |
|----|-----------|--------------|---------------|
| T1 | `ElaroQuickActionsServiceTest.cls` | ElaroQuickActionsService | >75% |
| T2 | `ElaroGraphIndexerTest.cls` | ElaroGraphIndexer | >75% |
| T3 | `ElaroGDPRDataErasureServiceTest.cls` | ElaroGDPRDataErasureService | >75% |
| T4 | `ElaroScoreCallbackTest.cls` | ElaroScoreCallback | >75% |
| T5 | `ISO27001QuarterlyReviewSchedulerTest.cls` | ISO27001QuarterlyReviewScheduler | >75% |

#### 1.5 Fix Existing Test Issues (4 hours)

| ID | File | Lines | Issue | Fix |
|----|------|-------|-------|-----|
| TF1 | `ElaroEventPublisherTest.cls` | 21, 37, 51, 74, 84 | `System.assert(true)` - meaningless assertions | Add actual verification logic |
| TF2 | `SlackNotifierTest.cls` | 13, 22, 35, 44, 53, 62 | `System.assert(true)` - no verification | Add real assertions |
| TF3 | `DeploymentMetricsTest.cls` | All | Only 1 test, 5 lines total | Add comprehensive tests |
| TF4 | `LimitMetricsTest.cls` | 47-51 | Depends on org data | Create test data in test |

#### 1.6 Trigger Fixes (4 hours)

| ID | File | Issue | Fix |
|----|------|-------|-----|
| TR1 | All 4 triggers | No recursion guards | Add static flag to prevent re-entry |
| TR2 | `PerformanceAlertEventTrigger.trigger` | Business logic in trigger | Move to handler class |
| TR3 | `ElaroPCIAccessAlertTrigger.trigger` | 70+ lines of logic in trigger | Move to handler |
| TR4 | `ElaroAlertTrigger.trigger` | No handler class | Create handler, delegate logic |

**Claude Code Phase 1 Total:** 46 hours

---

### Cursor Tasks (UI & Accessibility)

#### 1.7 Fix Malformed Event Handlers (CRITICAL - 2 hours)

| ID | File | Lines | Issue | Fix |
|----|------|-------|-------|-----|
| E1 | `systemMonitorDashboard.html` | 29-33 | `onclick="{refresh;}"` | Change to `onclick={refresh}` |
| E2 | `elaroAiSettings.html` | 8-12, 21-25, 34-37, 50-54, 66-69, 81-85 | Malformed `onchange` handlers | Fix syntax |
| E3 | `elaroReadinessScore.html` | 54-58, 65-69 | Malformed `onclick` handlers | Fix syntax |

#### 1.8 Add ARIA Labels & Accessibility (6 hours)

| ID | Component | Issue | Fix |
|----|-----------|-------|-----|
| A1 | `elaroCopilot.html` | SVG icons missing `aria-hidden` | Add `aria-hidden="true"` to decorative icons |
| A2 | `riskHeatmap.html` | Color-only severity indicators | Add text labels or ARIA descriptions |
| A3 | `elaroROICalculator.html` | Form inputs not properly labeled | Use component's `label` attribute |
| A4 | All LWCs with inputs | Missing label associations | Fix label-input relationships |

#### 1.9 Fix Null Safety Issues (4 hours)

| ID | File | Issue | Fix |
|----|------|-------|-----|
| N1 | `complianceScoreCard.html` | Accesses `framework.score` without null check | Add `if:true={framework}` wrapper |
| N2 | `complianceDashboard.html` | `{error.body.message}` no null check | Use `{error.body?.message}` or add conditional |
| N3 | `executiveKpiDashboard.html` | Same null safety issue | Add null check |
| N4 | `riskHeatmap.html` | Calls method in template | Move to getter in JS |

#### 1.10 Add Loading/Error States (6 hours)

**Components missing loading states (add `lightning-spinner`):**
- `deploymentMonitorDashboard.html`
- `flowExecutionMonitor.html`
- `performanceAlertPanel.html`
- `complianceTimeline.html`
- `complianceScoreCard.html`
- `riskHeatmap.html`
- `elaroAiSettings.html`
- `elaroReadinessScore.html`
- `elaroROICalculator.html`
- `complianceGapList.html`
- `complianceTrendChart.html`
- `frameworkSelector.html`

#### 1.11 LWC JavaScript Fixes (8 hours)

| ID | File | Lines | Issue | Fix |
|----|------|-------|-------|-----|
| J1 | Multiple files | Various | Missing `error.body` null check | Add `error.body?.message \|\| error.message` pattern |
| J2 | `elaroDrillDownViewer.js` | 29, 69, 86 | `JSON.parse` without try-catch | Wrap in try-catch |
| J3 | 12 components | Various | Unnecessary `@track` on primitives | Remove `@track` from primitives |
| J4 | 15+ files | Various | `console.log/error` in production | Remove or wrap in debug flag |

#### 1.12 Create Jest Tests (10 hours)

Create `__tests__/*.test.js` for all LWC components without tests:
- `apiUsageDashboard`
- `deploymentMonitorDashboard`
- `systemMonitorDashboard`
- `flowExecutionMonitor`
- `performanceAlertPanel`
- `elaroAiSettings`
- `elaroROICalculator`
- `elaroTrendAnalyzer`
- `riskHeatmap`
- `complianceScoreCard`

**Cursor Phase 1 Total:** 36 hours

---

## PHASE 2: P2 HIGH PRIORITY (Days 4-5)

> **Objective:** Strengthen security posture and improve reliability.

### Claude Code Tasks

#### 2.1 Scheduler/Batch Error Handling (8 hours)

| ID | File | Issue | Fix |
|----|------|-------|-----|
| SCH1 | `ElaroCCPASLAMonitorScheduler.cls` | No try-catch in execute() | Add comprehensive error handling |
| SCH2 | `ElaroDormantAccountAlertScheduler.cls` | No error handling in 4 methods | Add try-catch to all methods |
| SCH3 | `ElaroGLBAAnnualNoticeScheduler.cls` | No error handling, no logging | Add both |
| SCH4 | `ElaroGLBAAnnualNoticeBatch.cls` | No error handling in start/finish | Add error handling |
| SCH5 | `ElaroGLBAAnnualNoticeBatch.cls` | Line 100 - Email commented out | Uncomment or implement alternative |
| SCH6 | `ElaroGLBAAnnualNoticeBatch.cls` | Line 63 - No SaveResult handling | Implement `Database.SaveResult[]` handling |

#### 2.2 Permission Set Fixes (4 hours)

| ID | Issue | Fix |
|----|-------|-----|
| P1 | `Elaro_Admin_Extended` has `modifyAllRecords=true` on all objects | Remove or restrict |
| P2 | 9 objects missing from all permission sets | Add object permissions |
| P3 | 28 Apex classes missing class access | Add class access |
| P4 | Missing field permissions on 6+ objects | Add field permissions |

**Objects to add permissions for:**
- `Access_Review__c`
- `CCPA_Request__c`
- `Consent__c`
- `GDPR_Erasure_Request__c`
- `Privacy_Notice__c`
- `Elaro_AI_Settings__c`
- `Elaro_Audit_Log__c`
- `Elaro_Compliance_Graph__b`
- `CCX_Settings__c`

#### 2.3 Code Quality Fixes (6 hours)

| ID | File | Lines | Issue | Fix |
|----|------|-------|-------|-----|
| Q1 | `ComplianceFrameworkService.cls` | 44-54 | SOQL in loop | Bulkify - collect IDs, query once |
| Q2 | `ComplianceDashboardController.cls` | 24-27 | Cascading N+1 problem | Refactor to bulk query |
| Q3 | `ElaroISO27001AccessReviewService.cls` | 309-378 | 6 separate COUNT queries | Combine into aggregate query |
| Q4 | `ElaroGDPRDataErasureService.cls` | 52-128 | No savepoint/rollback | Add Database.Savepoint |

#### 2.4 Sharing Declaration Fixes (2 hours)

| File | Current | Should Be |
|------|---------|-----------|
| `ElaroAuditTrailPoller.cls` | No declaration | `without sharing` (schedulable) |
| `ElaroScoreCallback.cls` | No declaration | `without sharing` (external API) |

#### 2.5 Configuration Standardization (2 hours)

| Issue | Files | Fix |
|-------|-------|-----|
| Inconsistent API versions | All triggers (62.0, 64.0, 65.0) | Standardize to 63.0 |
| Hardcoded CRON expressions | 7 schedulers | Move to Custom Metadata |
| Duplicate scheduler classes | `ISO27001QuarterlyReviewScheduler` vs `ElaroISO27001QuarterlyScheduler` | Remove duplicate |

**Claude Code Phase 2 Total:** 22 hours

---

### Cursor Tasks

#### 2.6 Hardcoded Text to Custom Labels (6 hours)

Replace hardcoded strings in all 25 LWC components with Custom Labels for i18n support.

#### 2.7 XSS Prevention (2 hours)

| File | Lines | Issue | Fix |
|------|-------|-------|-----|
| `elaroCopilot.html` | 103, 124 | User content in `lightning-formatted-rich-text` | Sanitize server-side or use `lightning-formatted-text` |
| `complianceCopilot.html` | 76-79 | Same issue | Same fix |

#### 2.8 Mobile Responsiveness (4 hours)

Verify all LWC components render correctly on mobile devices. Key focus:
- `elaroDashboard`
- `elaroROICalculator`
- `complianceDashboard`
- `executiveKpiDashboard`

**Cursor Phase 2 Total:** 12 hours

---

## PHASE 3: DOCUMENTATION & POLISH (Days 6-7)

> **Objective:** Complete all documentation and AppExchange listing materials.

### 3.1 Required Documentation (Cursor-led)

| Document | Pages | Content |
|----------|-------|---------|
| **Installation Guide** | 5-10 | Prerequisites, package install, post-install config |
| **User Guide** | 20-30 | Feature walkthroughs, screenshots, workflows, troubleshooting |
| **Admin Guide** | 15-20 | Permission sets, custom settings, maintenance tasks |
| **API Documentation** | 5-10 | REST endpoints, parameters, response formats |

### 3.2 AppExchange Listing Materials

- [ ] Title and description
- [ ] 10+ high-quality screenshots
- [ ] 2-minute demo video
- [ ] Feature highlights
- [ ] Pricing information
- [ ] Support information

### 3.3 Object Documentation (Claude Code support)

Add field descriptions and help text to:
- 32 fields without descriptions
- All custom objects (currently 0 fields have help text)

**Phase 3 Total:** 16 hours (Cursor) + 4 hours (Claude Code)

---

## PHASE 4: VALIDATION & SUBMISSION (Day 8)

### Pre-Submission Checklist

| Requirement | Validation Method | Status |
|-------------|-------------------|--------|
| Apex test coverage ≥75% (org-wide) | `sfdx force:apex:test:run --codecoverage` | ☐ |
| LWC Jest test coverage ≥75% | `npm run test:unit:coverage` | ☐ |
| Zero critical/high security vulnerabilities | Manual code review + PMD scan | ☐ |
| WCAG 2.1 AA accessibility compliance | axe DevTools audit | ☐ |
| All documentation complete | Manual review | ☐ |
| AppExchange listing finalized | SF Partner Portal | ☐ |
| Governor limit stress testing | Bulk data tests (200+ records) | ☐ |
| Mobile responsiveness validated | iOS Safari + Android Chrome | ☐ |
| No merge conflicts in codebase | `grep -r "<<<<<<" .` | ☐ |
| All malformed HTML fixed | LWC linting | ☐ |

### Human Review Points

| Day | Review Task |
|-----|-------------|
| End of Day 0 | Verify Phase 0 fixes compile successfully |
| End of Day 3 | Review P1 PRs, run full test suite, verify no conflicts |
| End of Day 5 | Integration testing, UAT on backend + UI |
| End of Day 7 | Final documentation review, AppExchange listing QA |
| Day 8 | Demo video recording, final submission |

---

## COMPLETE TASK LIST BY ASSIGNEE

### Claude Code - Backend (92 hours total)

| Phase | Category | Tasks | Hours |
|-------|----------|-------|-------|
| 0 | Critical Fixes | Merge conflicts, compilation errors, data integrity | 4 |
| 1 | Security | FLS/CRUD fixes, authentication, injection prevention | 18 |
| 1 | Tests | New test classes, fix existing tests | 24 |
| 1 | Triggers | Recursion guards, handler extraction | 4 |
| 2 | Schedulers | Error handling, SaveResult handling | 8 |
| 2 | Permissions | Permission set fixes, class access | 4 |
| 2 | Code Quality | Bulkification, savepoints, queries | 6 |
| 2 | Config | API versions, sharing declarations | 4 |
| 3 | Support | Field descriptions, help text | 4 |
| 4 | Validation | Security review, testing | 16 |

### Cursor - UI/Docs (68 hours total)

| Phase | Category | Tasks | Hours |
|-------|----------|-------|-------|
| 1 | Critical Fixes | Malformed event handlers | 2 |
| 1 | Accessibility | ARIA labels, keyboard nav, contrast | 10 |
| 1 | Null Safety | Template null checks | 4 |
| 1 | UX | Loading/error states | 6 |
| 1 | JavaScript | Error handling, remove console logs | 8 |
| 1 | Tests | Jest test creation | 10 |
| 2 | i18n | Custom labels for hardcoded text | 6 |
| 2 | Security | XSS prevention | 2 |
| 2 | Mobile | Responsiveness validation | 4 |
| 3 | Docs | Installation, User, Admin guides | 12 |
| 3 | AppExchange | Listing, screenshots, video | 4 |

---

## TIMELINE SUMMARY

| Day | Claude Code | Cursor | Human Tasks |
|-----|-------------|--------|-------------|
| 0 | Phase 0: Critical blockers (4h) | - | Verify compilation |
| 1-3 | Phase 1: Security, Tests, Triggers (46h) | Phase 1: Accessibility, LWC fixes (36h) | EOD review + merge |
| 4-5 | Phase 2: Schedulers, Permissions, Quality (22h) | Phase 2: i18n, XSS, Mobile (12h) | Integration testing |
| 6-7 | Phase 3: Field docs (4h) | Phase 3: Documentation (16h) | Final QA |
| 8 | Validation support (16h) | AppExchange materials | Submit |

**Total:** 7-8 business days (parallel execution)

---

## RISK MITIGATION

| Risk | Mitigation |
|------|------------|
| Merge conflicts between AIs | Strict file domain separation |
| Test coverage below 75% | Prioritize high-value test classes |
| Security review rejection | Pre-scan with PMD/Checkmarx |
| Documentation delays | Use templates, AI-assisted writing |
| Integration issues | Daily sync points, feature branches |

**Buffer:** 2 days built into timeline for unexpected issues.

---

## APPENDIX A: COMPLETE ISSUE INVENTORY

### Critical Issues (18)

1. `ApiUsageDashboardController.cls:36-57` - Merge conflict
2. `AlertHistoryService.cls:44-57` - Merge conflict
3. `PerformanceAlertEventTrigger.trigger:12` - Method signature mismatch
4. `ElaroComplianceScorer.cls:3` - Return type mismatch
5. `ComplianceTestDataFactory.cls:105` - Picklist case mismatch
6. `ElaroGraphIndexer.cls:51` - Non-deterministic hash
7. `ElaroScoreCallback.cls:14-15` - No authentication
8. `ElaroScoreCallback.cls:102-109` - Stack trace exposure
9. `TeamsNotifier.cls:20-25` - Missing timeout
10. `TeamsNotifier.cls:40-45` - Missing timeout
11. `ApiUsageSnapshot.cls:13-17` - Missing timeout
12. `ElaroCCPASLAMonitorScheduler.cls:22` - No error handling
13. `ElaroDormantAccountAlertScheduler.cls` - No error handling (4 methods)
14. `ElaroGLBAAnnualNoticeScheduler.cls:19` - No error handling, no logging
15. `ElaroGLBAAnnualNoticeBatch.cls:100` - Email commented out
16. `Elaro_Admin_Extended.permissionset` - modifyAllRecords=true
17. `systemMonitorDashboard.html:29-33` - Malformed onclick
18. `elaroAiSettings.html` - 6 malformed onchange handlers

### High Issues (58+)

See detailed listings in Phase 1 and Phase 2 sections above.

---

## APPENDIX B: FILE OWNERSHIP MAP

### Claude Code Exclusive Files
```
force-app/main/default/classes/*.cls
force-app/main/default/triggers/*.trigger
force-app/main/default/objects/*
force-app/main/default/permissionsets/*
```

### Cursor Exclusive Files
```
force-app/main/default/lwc/*
docs/*
README.md
SETUP_GUIDE.md
```

### Shared (Coordinate)
```
manifest/package.xml
sfdx-project.json
```

---

**Document Version:** 1.0
**Last Updated:** January 2026
**Next Review:** After Phase 1 completion
