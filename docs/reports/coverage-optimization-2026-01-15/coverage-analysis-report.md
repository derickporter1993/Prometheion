# Prometheion Coverage Analysis Report

**Generated:** 2026-01-15

## Summary Statistics

- Total Production Classes: 151
- Classes Without Tests: 38
- Classes With Tests: 113
- Estimated Coverage Gap: 25.2%

## Classes Without Test Coverage (Priority Order)

| Class | Criticality | LOC | Methods | Callouts | DB Ops | Priority |
|-------|-------------|-----|---------|----------|--------|----------|
| PrometheionComplianceAlert | CRITICAL | 311 | 12 | ✓ | ✓ | 6451 |
| ComplianceServiceBase | CRITICAL | 300 | 8 |  | ✓ | 6210 |
| ComplianceTestDataFactory | CRITICAL | 160 | 2 |  |  | 6086 |
| IComplianceModule | CRITICAL | 108 | 0 |  |  | 6010 |
| IEvidenceCollectionService | CRITICAL | 36 | 0 |  |  | 6003 |
| ServiceNowIntegration | HIGH | 221 | 8 | ✓ |  | 5802 |
| PrometheionCCPASLAMonitorScheduler | HIGH | 177 | 9 |  | ✓ | 5757 |
| PrometheionDormantAccountAlertScheduler | HIGH | 187 | 6 |  | ✓ | 5728 |
| PrometheionPDFController | HIGH | 227 | 10 |  | ✓ | 5722 |
| BenchmarkingService | HIGH | 279 | 11 |  |  | 5687 |
| PrometheionSchedulerTests | HIGH | 257 | 0 |  | ✓ | 5675 |
| MultiOrgManager | MEDIUM | 210 | 10 | ✓ | ✓ | 5671 |
| RetentionEnforcementScheduler | HIGH | 58 | 3 |  | ✓ | 5635 |
| ConsentExpirationScheduler | HIGH | 59 | 3 |  | ✓ | 5635 |
| PrometheionGLBAAnnualNoticeScheduler | HIGH | 45 | 3 |  | ✓ | 5634 |
| PrometheionAlertQueueable | HIGH | 36 | 2 |  | ✓ | 5623 |
| ConsentExpirationBatch | HIGH | 39 | 2 |  | ✓ | 5623 |
| RetentionEnforcementBatch | HIGH | 28 | 2 |  | ✓ | 5622 |
| DataResidencyService | HIGH | 214 | 5 |  |  | 5621 |
| PrometheionTestDataFactory | MEDIUM | 503 | 14 |  | ✓ | 5540 |
| PrometheionEventScheduler | HIGH | 31 | 1 |  |  | 5513 |
| IAccessControlService | HIGH | 106 | 0 |  |  | 5510 |
| IBreachNotificationService | HIGH | 53 | 0 |  |  | 5505 |
| IDataSubjectService | HIGH | 46 | 0 |  |  | 5504 |
| PrometheionDailyDigest | LOW | 332 | 12 | ✓ |  | 5503 |
| IRiskScoringService | HIGH | 32 | 0 |  |  | 5503 |
| PrometheionTestUserFactory | MEDIUM | 199 | 8 |  | ✓ | 5449 |
| SlackIntegration | LOW | 210 | 8 | ✓ |  | 5401 |
| PagerDutyIntegration | LOW | 198 | 7 | ✓ |  | 5389 |
| RemediationOrchestrator | LOW | 297 | 11 |  | ✓ | 5389 |
| ApiLimitsCalloutMock | LOW | 10 | 1 | ✓ |  | 5311 |
| BlockchainVerification | LOW | 217 | 5 |  | ✓ | 5271 |
| SOC2Module | LOW | 178 | 5 |  |  | 5217 |
| HIPAAModule | LOW | 290 | 7 |  |  | 5199 |
| GDPRModule | LOW | 209 | 5 |  |  | 5170 |
| FINRAModule | LOW | 192 | 5 |  |  | 5169 |
| PrometheionScheduledDelivery | LOW | 94 | 6 |  |  | 5169 |
| BreachNotificationTypes | LOW | 82 | 0 |  |  | 5108 |
