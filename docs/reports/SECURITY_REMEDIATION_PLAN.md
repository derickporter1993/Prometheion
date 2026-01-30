# Security Remediation Plan - Elaro AppExchange Compliance

**Date:** 2026-01-11
**Priority:** P0-P2 based on AppExchange security requirements

---

## Executive Summary

This plan addresses remaining security issues identified in the codebase audit:

- **4 CRITICAL issues** requiring immediate attention
- **5 HIGH priority** SOQL security fixes
- **3 MEDIUM priority** cryptographic improvements

---

## P0 - Critical (AppExchange Blockers)

### 1. SOQL Security: ElaroComplianceCopilot.cls

**Issue:** 4 SetupAuditTrail queries missing `WITH SECURITY_ENFORCED`

| Line    | Query Type         | Fix Required                 |
| ------- | ------------------ | ---------------------------- |
| 198-204 | SELECT with fields | Add `WITH SECURITY_ENFORCED` |
| 295     | COUNT()            | Add `WITH SECURITY_ENFORCED` |
| 321-327 | SELECT with LIKE   | Add `WITH SECURITY_ENFORCED` |
| 499-505 | SELECT with LIKE   | Add `WITH SECURITY_ENFORCED` |

**Status:** PENDING

### 2. SOQL Security: ElaroCCPASLAMonitorScheduler.cls

**Issue:** Uses `WITH USER_MODE` instead of `WITH SECURITY_ENFORCED`

| Line | Query Type | Current        | Fix Required           |
| ---- | ---------- | -------------- | ---------------------- |
| 103  | COUNT()    | WITH USER_MODE | WITH SECURITY_ENFORCED |
| 104  | COUNT()    | WITH USER_MODE | WITH SECURITY_ENFORCED |
| 106  | COUNT()    | WITH USER_MODE | WITH SECURITY_ENFORCED |
| 107  | COUNT()    | WITH USER_MODE | WITH SECURITY_ENFORCED |
| 115  | AVG()      | WITH USER_MODE | WITH SECURITY_ENFORCED |

**Note:** `WITH USER_MODE` is acceptable for AppExchange but `WITH SECURITY_ENFORCED` is preferred for consistency.

**Status:** PENDING (optional - WITH USER_MODE is compliant)

### 3. CRUD/FLS: ComplianceServiceBase.cls

**Status:** ALREADY COMPLIANT

- Line 90-92: Compliance_Gap\_\_c has `isCreateable()` check
- Line 122-124: Compliance_Evidence\_\_c has `isCreateable()` check
- Line 193-196: Elaro_Audit_Log\_\_c has `isCreateable()` check

### 4. CRUD/FLS: EvidenceCollectionService.cls

**Status:** ALREADY COMPLIANT

- Line 47-48: Uses `ElaroSecurityUtils.validateCRUDAccess()`

### 5. Bulkification: ElaroConsentWithdrawalHandler.cls

**Status:** ALREADY COMPLIANT

- Line 99-102: Uses `WHERE Id IN :contactIds` (single query, not in loop)
- Line 152: Bulk `Database.insert()` outside loop

---

## P1 - High Priority

### 6. API Key Security: ElaroScoreCallback.cls

**Issue:** API keys stored in Custom Metadata Type (plain-text, visible in Setup)

**Location:** Lines 138-147

```apex
List<Elaro_API_Config__mdt> configs = [
    SELECT API_Key__c, Is_Active__c
    FROM Elaro_API_Config__mdt
    WHERE Is_Active__c = true
];
return apiKey == configs[0].API_Key__c;  // Direct comparison
```

**Recommended Fix Options:**

1. **Option A (Preferred):** Migrate to Named Credentials with Per-User OAuth
2. **Option B:** Use Protected Custom Metadata Type
3. **Option C:** Store hashed key and compare with HMAC

**Status:** PENDING - Requires architectural decision

### 7. MD5 to SHA256 Migration

**Issue:** MD5 is cryptographically deprecated

| File                           | Line | Current | Fix        |
| ------------------------------ | ---- | ------- | ---------- |
| PerformanceRuleEngine.cls      | 307  | `'MD5'` | `'SHA256'` |
| PerformanceRuleEngine.cls      | 313  | `'MD5'` | `'SHA256'` |
| ElaroReasoningEngine.cls | 215  | `'MD5'` | `'SHA256'` |
| ElaroGraphIndexer.cls    | 224  | `'MD5'` | `'SHA256'` |

**Note:** Line 65 in ElaroGraphIndexer.cls already uses SHA256 correctly.

**Status:** PENDING

---

## P2 - Medium Priority

### 8. Named Credentials Verification

**Current Status:** COMPLIANT

- `Slack_Webhook` - Named Credential defined
- `Teams_Webhook` - Named Credential defined
- `SF_Limits` - Named Credential used in ApiUsageSnapshot.cls

### 9. Shield Encryption Enforcement

**Issue:** HIPAASecurityRuleService.cls validates encryption but doesn't enforce

**Location:** Line 127 - `fieldDesc.isEncrypted()`

**Recommendation:** Add enforcement logic to throw exception for unencrypted PHI fields

**Status:** DEFERRED - Requires Shield Platform Encryption license

### 10. LWC Template Migration (if:true to lwc:if)

**Issue:** 37 templates use deprecated `if:true` directive

**Status:** DEFERRED - Low priority, `if:true` still functional

---

## SOC2Module.cls Review

The provided SOC2Module.cls file uses proper security patterns:

- Uses `WITH USER_MODE` for all SOQL queries (lines 97, 103, 110, 116)
- No DML operations requiring CRUD checks
- Implements IComplianceModule interface correctly

**Status:** COMPLIANT (uses WITH USER_MODE which is acceptable)

---

## Implementation Order

| Priority | Task                             | File                                   | Est. Effort |
| -------- | -------------------------------- | -------------------------------------- | ----------- |
| 1        | Add WITH SECURITY_ENFORCED       | ElaroComplianceCopilot.cls       | 15 min      |
| 2        | Migrate MD5 to SHA256            | 3 files                                | 15 min      |
| 3        | Document API key migration plan  | ElaroScoreCallback.cls           | 30 min      |
| 4        | Update WITH USER_MODE (optional) | ElaroCCPASLAMonitorScheduler.cls | 10 min      |

---

## Completed Tasks (Previous Session)

- [x] HIPAAAuditControlService.cls - SOQL + CRUD
- [x] HIPAAPrivacyRuleService.cls - SOQL + CRUD
- [x] SOC2ChangeManagementService.cls - SOQL + CRUD
- [x] SOC2IncidentResponseService.cls - SOQL + CRUD
- [x] HIPAABreachNotificationService.cls - CRUD
- [x] Formatting (npm run fmt)
- [x] Encryption Audit completed

---

## Remaining Work

- [ ] ElaroComplianceCopilot.cls - 4 SOQL queries
- [ ] MD5 to SHA256 migration - 4 instances in 3 files
- [ ] API key security documentation
- [ ] (Optional) WITH USER_MODE to WITH SECURITY_ENFORCED

---

**Author:** Claude Code
**Last Updated:** 2026-01-11
