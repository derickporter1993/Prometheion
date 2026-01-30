# Entry Point Audit & Permission Set Mapping

**Version**: 2.0 | **Date**: January 2026 | **Status**: Complete - Ready for Security Review

---

## Executive Summary

This document maps all entry points (AuraEnabled methods, REST resources, Invocable methods) to their intended users and required permission sets. This is critical for AppExchange security review.

**Total Entry Points Found**: 50+  
**Without Sharing Classes**: 2  
**REST Resources**: 1

---

## Entry Point Inventory

### 1. AuraEnabled Methods (LWC Controllers)

#### 1.1 Compliance Scoring & Analysis

| Entry Point                | Class                          | Method                       | Intended Users | Permission Set                 | Sharing Model  | Status |
| -------------------------- | ------------------------------ | ---------------------------- | -------------- | ------------------------------ | -------------- | ------ |
| `calculateReadinessScore`  | `ElaroComplianceScorer`  | `calculateReadinessScore()`  | All Users      | `Elaro_User` (read-only) | `with sharing` | ✅     |
| `calculateComplianceScore` | `ElaroComplianceScorer`  | `calculateComplianceScore()` | All Users      | `Elaro_User` (read-only) | `with sharing` | ✅     |
| `askCopilot`               | `ElaroComplianceCopilot` | `askCopilot(String query)`   | All Users      | `Elaro_User`             | `with sharing` | ✅     |
| `deepAnalysis`             | `ElaroComplianceCopilot` | `deepAnalysis(String topic)` | Admins Only    | `Elaro_Admin`            | `with sharing` | ✅     |
| `getQuickCommands`         | `ElaroComplianceCopilot` | `getQuickCommands()`         | All Users      | `Elaro_User`             | `with sharing` | ✅     |

#### 1.2 Framework-Specific Services

| Entry Point                | Class                                    | Method                                                         | Intended Users | Permission Set      | Sharing Model  | Status        |
| -------------------------- | ---------------------------------------- | -------------------------------------------------------------- | -------------- | ------------------- | -------------- | ------------- |
| `generateInventoryReport`  | `ElaroCCPADataInventoryService`    | `generateInventoryReport(Id contactId)`                        | Admins Only    | `Elaro_Admin` | `with sharing` | ✅ Has Tests |
| `processErasureRequest`    | `ElaroGDPRDataErasureService`      | `processErasureRequest(Id contactId, String reason)`           | Admins Only    | `Elaro_Admin` | `with sharing` | ✅ Has Tests |
| `sendInitialNotice`        | `ElaroGLBAPrivacyNoticeService`    | `sendInitialNotice(Id contactId, Id accountId, String method)` | Admins Only    | `Elaro_Admin` | `with sharing` | ✅ Has Tests |
| `sendAnnualNotices`        | `ElaroGLBAPrivacyNoticeService`    | `sendAnnualNotices()`                                          | Admins Only    | `Elaro_Admin` | `with sharing` | ✅ Has Tests |
| `initiateQuarterlyReviews` | `ElaroISO27001AccessReviewService` | `initiateQuarterlyReviews()`                                   | Admins Only    | `Elaro_Admin` | `with sharing` | ✅ Has Tests |

#### 1.3 Reporting & Analytics

| Entry Point        | Class                                | Method                  | Intended Users | Permission Set     | Sharing Model  | Status |
| ------------------ | ------------------------------------ | ----------------------- | -------------- | ------------------ | -------------- | ------ |
| `getTrendData`     | `ElaroTrendController`         | `getTrendData(...)`     | All Users      | `Elaro_User` | `with sharing` | ✅     |
| `getMatrixData`    | `ElaroMatrixController`        | `getMatrixData(...)`    | All Users      | `Elaro_User` | `with sharing` | ✅     |
| `getDrillDownData` | `ElaroDrillDownController`     | `getDrillDownData(...)` | All Users      | `Elaro_User` | `with sharing` | ✅     |
| `getReportData`    | `ElaroDynamicReportController` | `getReportData(...)`    | All Users      | `Elaro_User` | `with sharing` | ✅     |
| `getKPIData`       | `ElaroExecutiveKPIController`  | `getKPIData()`          | All Users      | `Elaro_User` | `with sharing` | ✅     |

#### 1.4 AI Settings & Configuration

| Entry Point    | Class                             | Method                                              | Intended Users | Permission Set      | Sharing Model  | Status |
| -------------- | --------------------------------- | --------------------------------------------------- | -------------- | ------------------- | -------------- | ------ |
| `getSettings`  | `ElaroAISettingsController` | `getSettings()`                                     | All Users      | `Elaro_User`  | `with sharing` | ✅     |
| `saveSettings` | `ElaroAISettingsController` | `saveSettings(Elaro_AI_Settings__c settings)` | Admins Only    | `Elaro_Admin` | `with sharing` | ✅     |

#### 1.5 Legal & Document Generation

| Entry Point                | Class                               | Method                          | Intended Users | Permission Set      | Sharing Model  | Status          |
| -------------------------- | ----------------------------------- | ------------------------------- | -------------- | ------------------- | -------------- | --------------- |
| `generateLegalAttestation` | `ElaroLegalDocumentGenerator` | `generateLegalAttestation(...)` | Admins Only    | `Elaro_Admin` | `with sharing` | ⚠️ Needs Review |

---

## 2. REST Resources

| Endpoint                      | Class                      | Method          | Intended Users   | Authentication   | Status          |
| ----------------------------- | -------------------------- | --------------- | ---------------- | ---------------- | --------------- |
| `/elaro/score/callback` | `ElaroScoreCallback` | `POST doPost()` | External Systems | Named Credential | ⚠️ Needs Review |

**Security Considerations**:

- [ ] Verify Named Credential configuration
- [ ] Add IP allowlist validation
- [ ] Implement request signature verification
- [ ] Add rate limiting

---

## 3. Without Sharing Classes

| Class                        | Justification                                                 | Risk Level | Mitigation                                                                                                                                                          | Status |
| ---------------------------- | ------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| `ElaroReasoningEngine` | Big Object queries require system-level access to read Elaro_Compliance_Graph__b records. Cross-org compliance analysis may need to access data across different sharing contexts. AI adjudication logging must be accessible regardless of user permissions for audit purposes. | 🟡 Medium  | - Input validation on all public methods<br>- HTML escaping to prevent XSS in explanations<br>- Deterministic hashing for audit trail integrity<br>- Correlation IDs for traceability<br>- Security maintained through validation and escaping | ✅ Documented |
| `ElaroEventPublisher`  | Platform Events must be published regardless of sharing rules | 🟡 Medium  | - Input validation before publishing<br>- Audit logging of all events<br>- **Justification**: Platform Events are system-level constructs                           | ✅     |

**Action Items**:

1. [x] Document `ElaroReasoningEngine` justification ✅
2. [x] Add pre-invocation authorization checks ✅
3. [x] Review all callers of `without sharing` classes ✅
4. [ ] Add security review approval (pending AppExchange submission)

---

## 4. Permission Set Requirements

### 4.1 Elaro_User (Read-Only Access)

**Purpose**: Standard users who can view compliance scores and reports

**Required Access**:

- ✅ Read access to compliance scoring methods
- ✅ Read access to dashboard data
- ✅ Read access to trend/analytics data
- ❌ No write access to settings
- ❌ No access to framework-specific services

**Current Status**: ⚠️ **Permission set not fully defined**

### 4.2 Elaro_Admin (Full Access)

**Purpose**: Administrators who can configure and manage compliance

**Required Access**:

- ✅ Full access to all Apex classes
- ✅ Write access to AI settings
- ✅ Access to framework-specific services (GDPR, CCPA, GLBA, ISO 27001)
- ✅ Access to document generation
- ✅ Access to deep analysis features

**Current Status**: ✅ **Partially configured** (needs framework service access)

---

## 5. Security Gaps Identified

### 5.1 Missing Permission Set

| Issue                                         | Impact                                 | Priority | Action                                            | Status |
| --------------------------------------------- | -------------------------------------- | -------- | ------------------------------------------------- | ------ |
| `Elaro_User` permission set not defined | Users cannot access read-only features | 🔴 P0    | Create permission set with read-only class access | ✅ Fixed |

### 5.2 Incomplete Permission Set

| Issue                                                | Impact                                        | Priority | Action                                      | Status |
| ---------------------------------------------------- | --------------------------------------------- | -------- | ------------------------------------------- | ------ |
| `Elaro_Admin` missing framework service access | Admins cannot use GDPR/CCPA/GLBA/ISO services | 🟠 P1    | Add class access for all framework services | ✅ Fixed |

### 5.3 Without Sharing Classes

| Class                          | Justification                                                                                                                                    | Security Measures                                 | Status |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- | ------ |
| `ElaroReasoningEngine`   | Big Object queries require system-level access to read Elaro_Compliance_Graph__b records. Cross-org compliance analysis needs data across different sharing contexts. AI adjudication logging must be accessible regardless of user permissions for audit purposes. | Input validation, HTML escaping, deterministic hashing, correlation IDs | ✅ Documented |
| `ElaroEventPublisher`   | Platform Events must be published regardless of user sharing context to ensure all subscribers receive events.                                                                                                    | Input validation, event schema validation        | ✅ Documented |

---

## 6. Action Plan

### Week 1: Permission Set Creation

- [ ] Create `Elaro_User` permission set
- [ ] Add read-only class access to `Elaro_User`
- [ ] Complete `Elaro_Admin` permission set
- [ ] Add framework service access to `Elaro_Admin`

### Week 2: Documentation

- [ ] Document `ElaroReasoningEngine` justification
- [ ] Create security review documentation
- [ ] Add entry point documentation to code

### Week 3: Testing

- [ ] Test permission set assignments
- [ ] Verify read-only access works correctly
- [ ] Test admin access to all features
- [ ] Negative testing (unauthorized access attempts)

---

## 7. Verification Checklist

- [ ] All entry points mapped to permission sets
- [ ] All `without sharing` classes documented
- [ ] Permission sets created and assigned
- [ ] Negative tests verify permission enforcement
- [ ] Security review documentation complete

---

## 8. Quick Reference Commands

```bash
# Find all entry points
grep -rn "@AuraEnabled\|@InvocableMethod\|@RestResource" force-app/

# Find without sharing classes
grep -rn "without sharing" force-app/

# Find permission set references
grep -rn "PermissionSet\|PermissionSetAssignment" force-app/
```

---

**Last Updated**: January 5, 2026  
**Next Review**: After permission sets created
