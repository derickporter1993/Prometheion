# Compliance Baseline Report

**Organization**: Acme Healthcare Foundation
**Scan Date**: 2025-01-15 14:23:47 UTC
**Report Generated**: 2025-01-15 14:24:12 UTC
**Sentinel Version**: 1.0.0

---

## Executive Summary

### Audit Readiness Score: 68/100 ⚠️

Your Salesforce org has **moderate compliance risk**. While basic security controls are in place, several configuration issues require immediate attention to meet audit requirements.

**Status**: 🟡 Action Required
**Next Audit Date**: 2025-03-01
**Days Until Audit**: 45

---

## Top 5 Risks

| Priority | Risk | Impact | Status |
|----------|------|--------|--------|
| 🔴 **Critical** | 127 users with "Modify All Data" permission | Data breach exposure | Open |
| 🔴 **Critical** | No audit trail enabled for Custom Settings changes | Compliance violation | Open |
| 🟠 **High** | 23 profiles not reviewed in 180+ days | Permission sprawl | Open |
| 🟠 **High** | Sharing rules grant "Public Read/Write" to 3 objects | Over-permissioned | Open |
| 🟡 **Medium** | 45 API integrations with undefined expiration | Credential hygiene | Open |

---

## Configuration Drift Summary

### Changes in Last 30 Days

**Total Changes Detected**: 87
**High-Risk Changes**: 12
**Unreviewed Changes**: 34

#### Critical Configuration Drift Events

| Date | Change Type | Object/Component | Changed By | Risk Level | Reviewed |
|------|-------------|------------------|------------|------------|----------|
| 2025-01-12 | Permission Set Modified | `Financial_Data_Access` | j.smith@acme.org | 🔴 High | ❌ No |
| 2025-01-10 | Profile Updated | `System Administrator` | admin@acme.org | 🔴 High | ❌ No |
| 2025-01-08 | Sharing Rule Created | `Patient_Records__c` | k.jones@acme.org | 🔴 High | ❌ No |
| 2025-01-05 | Field-Level Security Changed | `SSN__c` on Contact | j.smith@acme.org | 🔴 High | ✅ Yes |
| 2024-12-28 | Public Group Modified | `HIPAA_Compliance_Team` | admin@acme.org | 🟠 Medium | ❌ No |

---

## Permissions Overview

### Users with Elevated Privileges

| Permission Level | User Count | Change (30d) | Compliance Status |
|------------------|------------|--------------|-------------------|
| System Administrator | 8 | +2 ⬆️ | 🔴 Exceeds policy (max 5) |
| Modify All Data | 127 | +15 ⬆️ | 🔴 Critical risk |
| View All Data | 234 | -3 ⬇️ | 🟡 Acceptable |
| API Enabled | 456 | +12 ⬆️ | 🟢 Within policy |

### Permission Set Assignments

**Total Permission Sets**: 47
**Assigned in Last 30 Days**: 89 assignments
**Stale Assignments** (user inactive >90d): 23

#### High-Risk Permission Sets

| Permission Set | Users | Last Modified | Risk Reason |
|----------------|-------|---------------|-------------|
| `Financial_Data_Access` | 45 | 2025-01-12 | Modified without change control ticket |
| `PHI_Full_Access` | 23 | 2024-11-03 | Not reviewed in 180+ days |
| `Integration_User_Elevated` | 12 | 2024-10-15 | Grants "Modify All" + API access |

---

## Sharing & Data Access

### Sharing Rules Analysis

| Object | Rule Type | Access Level | Granted To | Risk Level |
|--------|-----------|--------------|------------|------------|
| `Patient_Records__c` | Criteria-Based | Public Read/Write | All Internal Users | 🔴 Critical |
| `Financial_Transactions__c` | Ownership-Based | Public Read/Write | Finance Department | 🔴 Critical |
| `Contact` | Criteria-Based | Public Read Only | All Internal Users | 🟡 Medium |

### Organization-Wide Defaults (OWD)

| Object | OWD Setting | Recommended | Status |
|--------|-------------|-------------|--------|
| `Patient_Records__c` | Public Read/Write | Private | 🔴 Non-compliant |
| `Account` | Public Read Only | Private | 🟡 Review needed |
| `Contact` | Controlled by Parent | Private | 🟢 Compliant |
| `Financial_Transactions__c` | Public Read/Write | Private | 🔴 Non-compliant |

---

## Audit Trail & Evidence

### Platform Encryption Status

| Feature | Status | Compliance Requirement |
|---------|--------|------------------------|
| Shield Platform Encryption | ❌ Not Enabled | Required for HIPAA/SOX |
| Event Monitoring | ✅ Enabled | Required |
| Field Audit Trail | ✅ Enabled (18 objects) | Required |
| Setup Audit Trail | ✅ Enabled (retained 6 months) | Required |

**🔴 Action Required**: Enable Shield Platform Encryption for PHI/PII fields.

### Audit Trail Coverage

**Objects with Field History Tracking**: 18 / 34 compliance-sensitive objects (53%)
**Missing Coverage**:
- `Patient_Records__c`
- `Financial_Transactions__c`
- `Medical_Notes__c`

---

## Compliance Checklist

### HIPAA Requirements

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Minimum necessary access | 🔴 Failed | 127 users with "Modify All Data" |
| Audit trail for PHI access | 🟡 Partial | Event Monitoring enabled, but no reports configured |
| Data encryption at rest | 🔴 Failed | Shield Platform Encryption not enabled |
| Session timeout ≤ 30 minutes | ✅ Passed | Currently set to 15 minutes |
| Password complexity | ✅ Passed | Meets NIST 800-63B standards |

**Overall HIPAA Readiness**: 🔴 Not Ready (2/5 controls passing)

### SOC 2 Type II Requirements

| Control | Status | Evidence |
|---------|--------|----------|
| Change management process | 🔴 Failed | 34 unreviewed changes in production |
| Segregation of duties | 🟡 Partial | 8 users with full admin access |
| Periodic access review | 🔴 Failed | Last review: 247 days ago |
| Data retention policy | ✅ Passed | Configured for 180-day retention |

**Overall SOC 2 Readiness**: 🟡 Needs Improvement (1/4 controls passing)

---

## Suggested Actions

### Immediate (Within 7 Days)

1. **🔴 CRITICAL**: Reduce "Modify All Data" permission assignments from 127 to <10 users
   - **How**: Audit all users with this permission, create custom permission sets with granular access
   - **Estimated Effort**: 8 hours
   - **Impact**: Reduces data breach risk by 78%

2. **🔴 CRITICAL**: Enable Field History Tracking on `Patient_Records__c`, `Financial_Transactions__c`
   - **How**: Setup → Object Manager → Enable "Track Field History" for PHI/PII fields
   - **Estimated Effort**: 2 hours
   - **Impact**: Meets HIPAA audit trail requirements

3. **🔴 CRITICAL**: Change OWD to "Private" for `Patient_Records__c` and `Financial_Transactions__c`
   - **How**: Setup → Sharing Settings → Edit OWD for each object
   - **Estimated Effort**: 4 hours (includes testing sharing rules)
   - **Impact**: Reduces unauthorized data access risk

### Short-Term (Within 30 Days)

4. **🟠 HIGH**: Conduct quarterly access review and revoke stale permission set assignments
   - **How**: Reports → Create "User Permissions & Assignments" report → Review inactive users
   - **Estimated Effort**: 6 hours
   - **Impact**: Meets SOC 2 periodic review requirements

5. **🟠 HIGH**: Enable Shield Platform Encryption for PHI fields
   - **How**: Purchase Shield license → Setup → Platform Encryption → Enable for sensitive fields
   - **Estimated Effort**: 16 hours (includes key management setup)
   - **Impact**: Meets HIPAA encryption-at-rest requirements

6. **🟠 HIGH**: Implement change control workflow requiring approval for production changes
   - **How**: Create approval process in Salesforce for Setup changes, integrate with Jira/ServiceNow
   - **Estimated Effort**: 12 hours
   - **Impact**: Meets SOC 2 change management requirements

### Long-Term (Within 90 Days)

7. **🟡 MEDIUM**: Create automated monthly access review dashboard
   - **How**: Build Sentinel dashboard or use Analytics for permission set assignment trends
   - **Estimated Effort**: 8 hours
   - **Impact**: Continuous compliance monitoring

8. **🟡 MEDIUM**: Define and enforce API credential expiration policy
   - **How**: Audit Named Credentials, set expiration dates, create renewal process
   - **Estimated Effort**: 6 hours
   - **Impact**: Reduces credential hygiene risk

---

## Methodology

This baseline report was generated by scanning the following Salesforce metadata and audit logs:

- **Metadata Types Analyzed**: Profiles, Permission Sets, Sharing Rules, OWD Settings, Custom Objects, Field-Level Security
- **Audit Sources**: Setup Audit Trail (last 180 days), Field History (where enabled), Event Monitoring logs
- **Risk Scoring**: Based on NIST 800-53, HIPAA Security Rule, SOC 2 Trust Services Criteria
- **Drift Detection Window**: Last 30 days

### Scan Scope

| Component | Items Scanned | High-Risk Items |
|-----------|---------------|-----------------|
| Users | 1,247 | 127 |
| Profiles | 34 | 23 |
| Permission Sets | 47 | 3 |
| Sharing Rules | 18 | 3 |
| Custom Objects | 156 | 34 |
| Integrations | 45 | 12 |

---

## Next Steps

1. **Review this report** with your compliance team and CISO
2. **Prioritize remediation** using the "Suggested Actions" section
3. **Re-scan in 30 days** to measure improvement
4. **Schedule recurring scans** (recommended: weekly) to catch drift early

**Questions?** Contact your Sentinel administrator or visit [documentation](https://docs.sentinel.dev)

---

*This report is generated automatically by Sentinel. For audit purposes, this document serves as point-in-time evidence of your Salesforce configuration state. Export date: 2025-01-15 14:24:12 UTC*
