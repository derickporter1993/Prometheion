# Test Coverage Plan to Reach 75%

**Current**: 48%  
**Target**: 75%  
**Gap**: 27 percentage points

---

## Classes Without Test Coverage

Based on analysis, the following classes need test coverage:

### Batch 1: Schedulers & Batch Classes (Priority 1)

1. WeeklyScorecardScheduler
2. ElaroCCPASLAMonitorScheduler
3. ElaroDormantAccountAlertScheduler
4. ElaroGLBAAnnualNoticeBatch
5. ElaroGLBAAnnualNoticeScheduler
6. ElaroISO27001QuarterlyScheduler
7. ElaroISO27001QuarterlyReviewScheduler

### Batch 2: Service Classes (Priority 2)

8. ElaroChangeAdvisor
9. ElaroQuickActionsService
10. ElaroRemediationEngine
11. ElaroPCIDataMaskingService
12. ElaroPCIAccessLogger
13. ElaroPCIAccessAlertHandler
14. ElaroEventPublisher
15. ElaroScoreCallback
16. ElaroAuditTrailPoller
17. ElaroConsentWithdrawalHandler
18. ElaroSalesforceThreatDetector

### Batch 3: Controller Classes (Priority 3)

19. ElaroTrendController
20. ElaroMatrixController
21. ElaroDrillDownController
22. ElaroDynamicReportController
23. ElaroExecutiveKPIController
24. ElaroComplianceCopilot

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
