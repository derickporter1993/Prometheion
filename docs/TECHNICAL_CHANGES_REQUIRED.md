# Technical Changes Required - Prometheion Compliance Platform

## By the Numbers

| Category | Add | Update | Remove |
|----------|-----|--------|--------|
| Apex Classes | 12 | 8 | 0 |
| LWC Components | 9 | 3 | 0 |
| Custom Objects | 4 | 2 | 0 |
| Custom Metadata (Policies) | 28 | 0 | 0 |
| Permission Sets | 2 | 3 | 0 |
| Test Classes | 8 | 6 | 0 |
| **Total** | **63** | **22** | **0** |

---

## UPDATE (8 Apex Classes - Security Fixes)

| Class | Fix Required |
|-------|-------------|
| PrometheionGraphIndexer.cls | Add CRUD/FLS checks |
| PrometheionReasoningEngine.cls | Change to `with sharing` + add FLS |
| PrometheionLegalDocumentGenerator.cls | Add ContentVersion FLS check |
| PrometheionAISettingsController.cls | Add input validation + CRUD check |
| AlertHistoryService.cls | Add CRUD/FLS enforcement |
| FlowExecutionLogger.cls | Add CRUD/FLS enforcement |
| PerformanceAlertPublisher.cls | Add CRUD/FLS enforcement |
| PrometheionComplianceScorer.cls | Add `WITH SECURITY_ENFORCED` |

---

## ADD (28 Compliance Policy Metadata)

| Framework | Policies | Status |
|-----------|----------|--------|
| CCPA | 7 policies | Missing |
| GLBA | 5 policies | Missing |
| NIST 800-53 | 8 policies | Missing |
| SOX | 8 policies | Missing |
| **Existing** | **SOC2(2), HIPAA(2), GDPR(2), ISO(1), PCI(1)** | ✓ |

---

## ADD (12 New Apex Classes)

### Core Business Logic:
- `ComplianceFrameworkService.cls` - Framework evaluation
- `EvidenceCollectionService.cls` - Automated evidence
- `ComplianceDashboardController.cls` - Dashboard backend
- `AuditReportController.cls` - Report generation
- `PrometheionSecurityUtils.cls` - Centralized security

### AI/ML:
- `PrometheionAIRiskPredictor.cls` - Einstein risk prediction
- `AnomalyDetectionService.cls` - Pattern detection
- `NaturalLanguageQueryService.cls` - "Am I compliant?" queries

### Change Management (vs Strongpoint):
- `MetadataChangeTracker.cls` - Track all changes
- `ChangeImpactAnalyzer.cls` - Pre-deployment analysis
- `SegregationOfDutiesService.cls` - SoD violations

---

## ADD (9 New LWC Components)

### Core Dashboard:
- `complianceDashboard` - Main compliance view
- `frameworkSelector` - Filter by framework
- `complianceScoreCard` - Score visualization
- `complianceGapList` - Remediation list
- `auditReportGenerator` - Report builder

### Analytics:
- `executiveKpiDashboard` - C-level metrics
- `complianceTrendChart` - Historical trends
- `riskHeatmap` - Visual risk map
- `complianceTimeline` - Audit timeline

---

## ADD (4 New Custom Objects)

| Object | Purpose |
|--------|---------|
| Compliance_Evidence__c | Store audit evidence |
| Compliance_Gap__c | Track compliance gaps |
| Vendor_Compliance__c | Third-party risk (Phase 4) |
| Metadata_Change__c | Change tracking (vs Strongpoint) |

---

## REMOVE

| Item | Reason |
|------|--------|
| StringBuilder in LegalDocGenerator | Not valid Apex |
| mcp-servers-config.json | Add to .gitignore |
| Dead code | Clean up during refactor |

---

## Implementation Timeline (12 Weeks)

| Sprint | Focus | Deliverables |
|--------|-------|--------------|
| 1-2 | Security | All CRUD/FLS fixes, security utils |
| 3-4 | Frameworks | CCPA, GLBA, NIST, SOX metadata |
| 5-6 | Objects & UI | Evidence/Gap objects, dashboard LWC |
| 7-8 | AI | Risk predictor, analytics components |
| 9-10 | Change Mgmt | Metadata tracking (Strongpoint feature) |
| 11-12 | Launch | 80% coverage, AppExchange prep |

---

**Last Updated:** January 6, 2025
