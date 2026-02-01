# Test Coverage Plan to Reach 75%

**Current**: 48%  
**Target**: 75%  
**Gap**: 27 percentage points

**Last Updated**: 2026-01-14

---

## Classes Without Test Coverage

Based on analysis, the following classes need test coverage:

### Batch 1: Schedulers & Batch Classes (Priority 1)

1. WeeklyScorecardScheduler
2. ✅ ElaroCCPASLAMonitorScheduler - **COMPLETE** (2026-01-14, Claude)
3. ✅ ElaroDormantAccountAlertScheduler - **COMPLETE** (2026-01-14, Claude)
4. ElaroGLBAAnnualNoticeBatch
5. ✅ ElaroGLBAAnnualNoticeScheduler - **COMPLETE** (2026-01-14, Cursor)
6. ✅ ElaroISO27001QuarterlyScheduler - **COMPLETE** (already had test class)
7. ~~ElaroISO27001QuarterlyReviewScheduler~~ - **N/A** (class doesn't exist, likely meant ElaroISO27001QuarterlyScheduler)

### Batch 2: Service Classes (Priority 2)

8. ElaroChangeAdvisor
9. ElaroQuickActionsService
10. ✅ RemediationOrchestrator - **COMPLETE** (2026-01-14, Claude)
11. ElaroPCIDataMaskingService
12. ElaroPCIAccessLogger
13. ElaroPCIAccessAlertHandler
14. ElaroEventPublisher
15. ElaroScoreCallback
16. ElaroAuditTrailPoller
17. ElaroConsentWithdrawalHandler
18. ElaroSalesforceThreatDetector
19. ✅ DataResidencyService - **COMPLETE** (2026-01-14, Claude)
20. ✅ MultiOrgManager - **COMPLETE** (2026-01-14, Cursor)
21. ✅ BenchmarkingService - **COMPLETE** (2026-01-14, Cursor)
22. ✅ ElaroDailyDigest - **COMPLETE** (2026-01-14, Cursor)
23. ✅ ElaroComplianceAlert - **COMPLETE** (2026-01-14, Cursor)
24. ✅ ElaroScheduledDelivery - **COMPLETE** (2026-01-14, Cursor)

### Batch 3: Controller Classes (Priority 3)

25. ElaroTrendController
26. ElaroMatrixController
27. ElaroDrillDownController
28. ElaroDynamicReportController
29. ElaroExecutiveKPIController
30. ElaroComplianceCopilot
31. ✅ ElaroPDFController - **COMPLETE** (2026-01-14, Claude)

### Batch 4: Utility Classes (Priority 4)

32. TeamsNotifier
33. DeploymentMetrics
34. AlertHistoryService
35. ApiUsageDashboardController
36. LimitMetrics

### Batch 5: Integration Classes (Priority 1)

37. ✅ ServiceNowIntegration - **COMPLETE** (2026-01-14, Claude)
38. ✅ PagerDutyIntegration - **COMPLETE** (2026-01-14, Cursor)
39. ✅ BlockchainVerification - **COMPLETE** (2026-01-14, Claude)
40. ✅ ElaroAlertQueueable - **COMPLETE** (2026-01-14, Claude)

---

## Test Creation Strategy

### For Each Class:

1. **Positive Path Tests** - Happy flow scenarios
2. **Negative Path Tests** - Error handling
3. **Bulk Tests** - 200+ records where applicable
4. **Edge Cases** - Null, empty, boundary values
5. **Permission Tests** - System.runAs for different users

### Estimated Time:

- Simple classes: 20-30 minutes
- Medium complexity: 30-45 minutes
- Complex classes: 45-60 minutes

**Total Estimated Time**: 15-25 hours

---

## Recent Completions (2026-01-14)

**14 Test Classes Created:**
- **Claude (7 classes)**: ServiceNowIntegrationTest, ElaroAlertQueueableTest, ElaroCCPASLAMonitorSchedulerTest, DataResidencyServiceTest, RemediationOrchestratorTest, BlockchainVerificationTest, ElaroPDFControllerTest
- **Cursor (7 classes)**: PagerDutyIntegrationTest, ElaroGLBAAnnualNoticeSchedulerTest, ElaroScheduledDeliveryTest, MultiOrgManagerTest, BenchmarkingServiceTest, ElaroDailyDigestTest, ElaroComplianceAlertTest

**All test classes include:**
- Positive and negative path tests
- Bulk operations (200+ records where applicable)
- Error handling and edge cases
- HTTP callout mocks (for integration classes)
- Permission/sharing tests (where applicable)

**Branch**: `cursor/add-test-classes-for-7-classes`

---

_Plan created: January 2026_  
_Last updated: 2026-01-14_
