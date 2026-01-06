# Prometheion AppExchange Improvement To-Do List
**Generated**: January 2026
**Total Items**: 47

---

## Priority Legend
- **P1** = Blocking for AppExchange (must fix)
- **P2** = High priority (should fix before release)
- **P3** = Medium priority (fix when possible)
- **P4** = Low priority (future enhancement)

---

## 1. SECURITY IMPROVEMENTS (P1)

### 1.1 Input Validation
- [ ] **P1** Add input validation to `PrometheionGraphIndexer.indexChange()` for `entityType`, `entityId` parameters
- [ ] **P1** Add input validation to `PerformanceAlertPublisher.publish()` for `metric`, `stack` parameters (XSS prevention)
- [ ] **P1** Add input validation to `FlowExecutionLogger.log()` for `flowName`, `status` parameters
- [ ] **P1** Add framework validation to `PrometheionLegalDocumentGenerator.generateLegalAttestation()` against allowed values

### 1.2 USER_MODE Enforcement
- [ ] **P1** Add `WITH USER_MODE` to query in `PrometheionGraphIndexer.cls:42-47` (PermissionSet query)
- [ ] **P1** Add `WITH USER_MODE` to query in `PrometheionGraphIndexer.cls:53-56` (FlowDefinitionView query)
- [ ] **P1** Add `WITH USER_MODE` to query in `AlertHistoryService.cls:22-27` (Performance_Alert_History__c query)
- [ ] **P1** Add `WITH USER_MODE` to query in `ApiUsageDashboardController.cls:28-38` (API_Usage_Snapshot__c query)

### 1.3 Sharing Model Documentation
- [ ] **P1** Document justification for `without sharing` on `PrometheionReasoningEngine` class

---

## 2. ERROR HANDLING (P2)

### 2.1 Silent Failures
- [ ] **P2** Replace `System.debug` with proper error logging in `SlackNotifier.cls:20-22`
- [ ] **P2** Replace `System.debug` with proper error logging in `SlackNotifier.cls:44-47`
- [ ] **P2** Add error tracking for Einstein prediction failures in `PrometheionGraphIndexer.cls:77-79`
- [ ] **P2** Create `Integration_Error__c` custom object or platform event for integration failure tracking

### 2.2 Exception Details
- [ ] **P2** Include `SaveResult` error details in `PerformanceAlertPublisher.publish()` exception message

---

## 3. CODE QUALITY (P3)

### 3.1 Reserved Words
- [ ] **P3** Rename `limit` variable in `ApiUsageDashboardController.cls:8` to `recordLimit`
- [ ] **P3** Rename `limit` variable in `ApiUsageDashboardController.cls:26` to `queryLimit`

### 3.2 Method Naming Conventions
- [ ] **P3** Rename `AlertHistoryService.recent()` to `getRecentAlerts()`
- [ ] **P3** Rename `ApiUsageDashboardController.recent()` to `getRecentSnapshots()`
- [ ] **P3** Rename `FlowExecutionStats.topFlows()` to `getTopFlows()`

### 3.3 Magic Numbers
- [ ] **P3** Extract constant `DEFAULT_RISK_SCORE = 5.0` in `PrometheionGraphIndexer.cls:76`
- [ ] **P3** Extract constant `MAX_RISK_SCORE = 10.0` in `PrometheionGraphIndexer.cls:76`
- [ ] **P3** Extract constant `BASE_RISK_SCORE = 3.0` in `PrometheionGraphIndexer.cls:83`
- [ ] **P3** Add documentation explaining what each risk score value represents

---

## 4. ARCHITECTURE (P4)

### 4.1 Dependency Decoupling
- [ ] **P4** Create `IRiskScoringService` interface for Einstein AI abstraction
- [ ] **P4** Create `EinsteinRiskScoringService` implementation
- [ ] **P4** Create `FallbackRiskScoringService` implementation
- [ ] **P4** Refactor `PrometheionGraphIndexer` to use interface
- [ ] **P4** Refactor `PrometheionReasoningEngine` to use interface

### 4.2 Async Processing
- [ ] **P3** Implement `Queueable` version of `PrometheionLegalDocumentGenerator.generateLegalAttestation()` for large datasets
- [ ] **P3** Add record count check to decide sync vs async processing

### 4.3 Bulkification
- [ ] **P3** Create bulk version of `PrometheionGraphIndexer.indexChange()` that accepts `List<IndexRequest>`
- [ ] **P3** Add bulkification guard/warning to single-record method

---

## 5. MISSING FEATURES (P2-P3)

### 5.1 Rate Limiting
- [ ] **P2** Implement rate limiting for `PrometheionLegalDocumentGenerator.generateLegalAttestation()`
- [ ] **P2** Implement rate limiting for `PerformanceAlertPublisher.publish()`
- [ ] **P3** Implement rate limiting for `FlowExecutionLogger.log()`

### 5.2 Audit Logging
- [ ] **P2** Add audit logging when AI Settings are changed in `PrometheionAISettingsController.saveSettings()`
- [ ] **P2** Add audit logging when evidence packs are generated in `PrometheionLegalDocumentGenerator`
- [ ] **P3** Create `Prometheion_Audit_Log__c` custom object for tracking

### 5.3 Framework Validation
- [ ] **P1** Create `SUPPORTED_FRAMEWORKS` constant set in `PrometheionLegalDocumentGenerator`
- [ ] **P1** Add framework validation with user-friendly error message

---

## 6. TEST COVERAGE (P1-P2)

### 6.1 Error Path Tests
- [ ] **P2** Add test for Einstein callout failure in `PrometheionGraphIndexerTest`
- [ ] **P2** Add test for invalid `entityType` in switch statement in `PrometheionGraphIndexerTest`
- [ ] **P2** Add test for HTTP 4xx/5xx responses in `SlackNotifierTest`
- [ ] **P2** Add test for ContentVersion insert failure in `PrometheionLegalDocumentGeneratorTest`

### 6.2 Bulk Tests
- [ ] **P1** Add 200+ record bulk test to `FlowExecutionLoggerTest`
- [ ] **P1** Add bulk test to `PrometheionGraphIndexerTest`

---

## 7. COMPLIANCE FRAMEWORK SERVICES (P3-P4)

### 7.1 Infrastructure
- [ ] **P2** Deploy `Compliance_Policy__mdt` custom metadata type
- [ ] **P3** Create `Compliance_Control__mdt` for control-to-framework mappings
- [ ] **P3** Create `Framework_Config__mdt` for framework-specific settings
- [ ] **P2** Seed initial compliance policy records

### 7.2 SOC2 Framework
- [ ] **P4** Create `SOC2DataRetentionService` for Trust Service Criteria enforcement
- [ ] **P4** Create `SOC2AccessReviewService` for periodic access review automation
- [ ] **P4** Create `SOC2ChangeManagementService` for CC6.1-CC6.8 change tracking
- [ ] **P4** Create `SOC2IncidentResponseService` for CC7.x incident handling

### 7.3 HIPAA Framework
- [ ] **P4** Create `HIPAAPrivacyRuleService` for PHI access controls
- [ ] **P4** Create `HIPAASecurityRuleService` for technical safeguards (164.312)
- [ ] **P4** Create `HIPAABreachNotificationService` for breach assessment
- [ ] **P4** Create `HIPAAAuditControlService` for 164.312(b) audit controls

### 7.4 GDPR Framework
- [ ] **P4** Create `GDPRDataErasureService` for Art. 17 Right to erasure
- [ ] **P4** Create `GDPRDataPortabilityService` for Art. 20 Data portability
- [ ] **P4** Create `GDPRConsentManagementService` for Art. 7 Consent tracking
- [ ] **P4** Create `GDPRDataInventoryService` for Art. 30 Records of processing
- [ ] **P4** Create `GDPRBreachNotificationService` for Art. 33/34 72-hour notification

### 7.5 CCPA Framework
- [ ] **P4** Create `CCPADataInventoryService` for personal info categorization
- [ ] **P4** Create `CCPAOptOutService` for "Do Not Sell" handling
- [ ] **P4** Create `CCPADeletionService` for consumer deletion requests

### 7.6 PCI-DSS Framework
- [ ] **P4** Create `PCIAccessControlService` for Req 7-8 access restrictions
- [ ] **P4** Create `PCILoggingService` for Req 10 audit trails

### 7.7 UI Enhancements
- [ ] **P3** Add GDPR button to `prometheionReadinessScore` LWC
- [ ] **P3** Add ISO27001 button to `prometheionReadinessScore` LWC
- [ ] **P3** Add framework selector dropdown instead of individual buttons

---

## 8. DOCUMENTATION (P2)

- [ ] **P2** Document `without sharing` justification for `PrometheionReasoningEngine`
- [ ] **P2** Create ApexDoc comments for all public methods
- [ ] **P3** Create architecture diagram showing class relationships
- [ ] **P3** Document risk score calculation methodology

---

## Summary by Priority

| Priority | Count | Category |
|----------|-------|----------|
| **P1** | 12 | Security, Test Coverage, Blocking Issues |
| **P2** | 16 | Error Handling, Rate Limiting, Audit Logging |
| **P3** | 12 | Code Quality, Architecture, UI |
| **P4** | 17 | Compliance Framework Services |
| **Total** | **47** | |

---

## Quick Wins (Low Effort, High Impact)

1. Add `WITH USER_MODE` to 4 queries (~30 min)
2. Add framework validation constant (~15 min)
3. Rename reserved word variables (~10 min)
4. Extract magic numbers to constants (~20 min)
5. Add bulk tests (~1 hour)

---

## Next Steps

1. Start with P1 items - these block AppExchange submission
2. Address P2 items before security review
3. P3/P4 can be addressed in subsequent releases

---

*Document generated from code review findings.*
