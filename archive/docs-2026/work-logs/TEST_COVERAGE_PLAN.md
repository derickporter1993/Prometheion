# Test Coverage Plan to Reach 75%

**Current**: 48%  
**Target**: 75%  
**Gap**: 27 percentage points

---

## Classes Without Test Coverage

Based on analysis, the following classes need test coverage:

### Batch 1: Schedulers & Batch Classes (Priority 1)

1. WeeklyScorecardScheduler
2. PrometheionCCPASLAMonitorScheduler
3. PrometheionDormantAccountAlertScheduler
4. PrometheionGLBAAnnualNoticeBatch
5. PrometheionGLBAAnnualNoticeScheduler
6. PrometheionISO27001QuarterlyScheduler
7. PrometheionISO27001QuarterlyReviewScheduler

### Batch 2: Service Classes (Priority 2)

8. PrometheionChangeAdvisor
9. PrometheionQuickActionsService
10. PrometheionRemediationEngine
11. PrometheionPCIDataMaskingService
12. PrometheionPCIAccessLogger
13. PrometheionPCIAccessAlertHandler
14. PrometheionEventPublisher
15. PrometheionScoreCallback
16. PrometheionAuditTrailPoller
17. PrometheionConsentWithdrawalHandler
18. PrometheionSalesforceThreatDetector

### Batch 3: Controller Classes (Priority 3)

19. PrometheionTrendController
20. PrometheionMatrixController
21. PrometheionDrillDownController
22. PrometheionDynamicReportController
23. PrometheionExecutiveKPIController
24. PrometheionComplianceCopilot

### Batch 4: Utility Classes (Priority 4)

25. TeamsNotifier
26. DeploymentMetrics
27. AlertHistoryService
28. ApiUsageDashboardController
29. LimitMetrics

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

_Plan created: January 2026_
