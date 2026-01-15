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
2. ✅ PrometheionCCPASLAMonitorScheduler - **COMPLETE** (2026-01-14, Claude)
3. ✅ PrometheionDormantAccountAlertScheduler - **COMPLETE** (2026-01-14, Claude)
4. PrometheionGLBAAnnualNoticeBatch
5. ✅ PrometheionGLBAAnnualNoticeScheduler - **COMPLETE** (2026-01-14, Cursor)
6. ✅ PrometheionISO27001QuarterlyScheduler - **COMPLETE** (already had test class)
7. ~~PrometheionISO27001QuarterlyReviewScheduler~~ - **N/A** (class doesn't exist, likely meant PrometheionISO27001QuarterlyScheduler)

### Batch 2: Service Classes (Priority 2)

8. PrometheionChangeAdvisor
9. PrometheionQuickActionsService
10. ✅ RemediationOrchestrator - **COMPLETE** (2026-01-14, Claude)
11. PrometheionPCIDataMaskingService
12. PrometheionPCIAccessLogger
13. PrometheionPCIAccessAlertHandler
14. PrometheionEventPublisher
15. PrometheionScoreCallback
16. PrometheionAuditTrailPoller
17. PrometheionConsentWithdrawalHandler
18. PrometheionSalesforceThreatDetector
19. ✅ DataResidencyService - **COMPLETE** (2026-01-14, Claude)
20. ✅ MultiOrgManager - **COMPLETE** (2026-01-14, Cursor)
21. ✅ BenchmarkingService - **COMPLETE** (2026-01-14, Cursor)
22. ✅ PrometheionDailyDigest - **COMPLETE** (2026-01-14, Cursor)
23. ✅ PrometheionComplianceAlert - **COMPLETE** (2026-01-14, Cursor)
24. ✅ PrometheionScheduledDelivery - **COMPLETE** (2026-01-14, Cursor)

### Batch 3: Controller Classes (Priority 3)

25. PrometheionTrendController
26. PrometheionMatrixController
27. PrometheionDrillDownController
28. PrometheionDynamicReportController
29. PrometheionExecutiveKPIController
30. PrometheionComplianceCopilot
31. ✅ PrometheionPDFController - **COMPLETE** (2026-01-14, Claude)

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
40. ✅ PrometheionAlertQueueable - **COMPLETE** (2026-01-14, Claude)

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
- **Claude (7 classes)**: ServiceNowIntegrationTest, PrometheionAlertQueueableTest, PrometheionCCPASLAMonitorSchedulerTest, DataResidencyServiceTest, RemediationOrchestratorTest, BlockchainVerificationTest, PrometheionPDFControllerTest
- **Cursor (7 classes)**: PagerDutyIntegrationTest, PrometheionGLBAAnnualNoticeSchedulerTest, PrometheionScheduledDeliveryTest, MultiOrgManagerTest, BenchmarkingServiceTest, PrometheionDailyDigestTest, PrometheionComplianceAlertTest

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
