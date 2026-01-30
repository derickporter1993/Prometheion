# Elaro Product Roadmap

**Last Updated**: 2026-01-09

This roadmap outlines Elaro's evolution from a compliance drift detector to a comprehensive Salesforce governance platform.

---

## Product Vision

**Make every Salesforce org audit-ready by default** — no matter the size, industry, or compliance requirements.

Elaro starts as a **compliance drift guardrail** for regulated organizations, then expands to automated remediation, multi-org governance, and policy-as-code enforcement.

---

## Release Strategy

- **v1.x**: Compliance Drift Baseline (focus on detection & evidence)
- **v2.x**: Multi-Org Governance (scale to enterprise)
- **v3.x**: Automated Remediation (shift from detect to prevent)
- **v4.x+**: Policy-as-Code & AppExchange (platform maturity)

---

## ✅ v1.0 — Compliance Drift Baseline (CURRENT)

**Released**: 2025-01-15
**Status**: ✅ Complete

### Goals

- Provide a simple, opinionated compliance baseline for Salesforce orgs
- Detect configuration drift without requiring complex setup
- Generate audit evidence that regulators actually want to see

### Features Delivered

- [x] **Compliance Baseline Scan**: Generates Audit Readiness Score (0-100)
- [x] **Configuration Drift Detection**: Real-time tracking of setup changes
- [x] **Audit Evidence Export**: Markdown/CSV/JSON exports for compliance teams
- [x] **Slack Alerting**: Push notifications for high-risk changes
- [x] **LWC Dashboards**: Governor limits, API usage, Flow execution monitoring
- [x] **Permission Set Analysis**: Identify users with "Modify All" permissions
- [x] **Sharing Rules Audit**: Detect over-permissioned objects

### Metrics

- Test Coverage: **95%+**
- Installation Time: **<10 minutes**
- First Scan Time: **<60 seconds**

### User Feedback Themes (Expected)

- ❓ "Can I customize the Audit Readiness Score?" → v2.0
- ❓ "Can Elaro prevent changes, not just detect them?" → v3.0
- ❓ "Can I monitor multiple orgs from one dashboard?" → v2.0
- ❓ "Can you explain WHY a change is risky?" → v1.5

---

## 🚧 v1.5 — AI-Assisted Remediation

**Planned Release**: Q2 2025 (April-June)
**Status**: 🚧 In Planning

### Goals

- Reduce time-to-remediation from hours to minutes
- Use AI to explain complex compliance violations
- Automate evidence collection for recurring audits

### Planned Features

#### 1. **AI Change Explanations** 🤖

**Problem**: Users don't understand WHY a change is flagged as high-risk.
**Solution**: GPT/Claude integration to explain compliance violations in plain English.

**Example**:

```
🔴 High-Risk Change Detected

Change: Permission Set "Financial_Data_Access" modified
Risk Score: 8.7/10

AI Explanation:
This change grants 45 users "Modify All Data" permission, which violates
the principle of least privilege (NIST 800-53 AC-6). These users can now
access, modify, or delete ANY data in the org, including PHI/PII.

Compliance Impact:
- HIPAA: Fails "minimum necessary" access requirement (§164.514(d))
- SOC 2: Fails logical access controls (CC6.1)
- SOX: Fails segregation of duties (Section 404)

Suggested Fix:
Create a custom permission set with granular access to only:
- Financial_Transactions__c (Read/Edit)
- Account.AnnualRevenue (Read)
Instead of org-wide "Modify All Data".
```

**Implementation**:

- Integrate with OpenAI/Anthropic APIs
- Use Named Credentials for secure API key storage
- Cache AI responses to reduce API costs
- Fallback to rule-based explanations if AI unavailable

**Estimated Effort**: 3 weeks

---

#### 2. **Suggested Fixes** 🛠️

**Problem**: Users know WHAT'S wrong, but not HOW to fix it.
**Solution**: Auto-generate remediation steps with copy-paste Apex/metadata.

**Example**:

```
Suggested Fix for: "127 users with Modify All Data"

Step 1: Create Custom Permission Set
Run this Apex to create a granular permission set:

PermissionSet ps = new PermissionSet(
    Name = 'Financial_Data_Limited',
    Label = 'Financial Data (Limited Access)'
);
insert ps;

// Grant specific object permissions
ObjectPermissions op = new ObjectPermissions(
    ParentId = ps.Id,
    SObjectType = 'Financial_Transactions__c',
    PermissionsRead = true,
    PermissionsEdit = true,
    PermissionsCreate = false,
    PermissionsDelete = false
);
insert op;

Step 2: Reassign Users
Export users with "Modify All Data":
Reports → New Report → Users → Filter: PermissionsModifyAllData = true

Step 3: Remove "Modify All Data"
For each user, remove from "Modify All Data" profile/permission set and
assign new "Financial_Data_Limited" permission set.

Estimated Time: 2-3 hours (depending on # of users)
Compliance Impact: Reduces risk score by 20 points
```

**Implementation**:

- Template library for common fixes
- Dynamic code generation based on org metadata
- Validation before suggesting changes
- Rollback scripts included

**Estimated Effort**: 4 weeks

---

#### 3. **Jira Integration** 🎫

**Problem**: Compliance teams work in Jira, but Elaro alerts live in Salesforce/Slack.
**Solution**: Auto-create Jira tickets for high-risk changes, with bidirectional sync.

**Features**:

- Create Jira ticket when drift event detected
- Attach compliance evidence (audit logs, metadata exports)
- Update Elaro when Jira ticket is resolved
- Link Elaro dashboard to Jira issues

**Configuration**:

```apex
// Jira Named Credential setup
Elaro_Settings__c settings = Elaro_Settings__c.getInstance();
settings.Jira_Integration_Enabled__c = true;
settings.Jira_Project_Key__c = 'COMPLIANCE';
settings.Jira_Issue_Type__c = 'Compliance Violation';
upsert settings;
```

**Estimated Effort**: 2 weeks

---

#### 4. **Compliance Report Scheduler** 📧

**Problem**: Compliance teams want weekly/monthly reports, not on-demand scans.
**Solution**: Scheduled jobs that email compliance reports to stakeholders.

**Features**:

- Schedule daily/weekly/monthly scans
- Email report as PDF attachment
- Configurable recipients (compliance team, CISO, auditors)
- Trend charts showing improvement over time

**Configuration**:

```apex
// Schedule weekly report every Monday at 8 AM
System.schedule(
    'Elaro_Weekly_Report',
    '0 0 8 ? * MON *',
    new ComplianceReportScheduler('weekly', 'compliance@acme.org')
);
```

**Estimated Effort**: 1 week

---

#### 5. **Mobile Alerts** 📱

**Problem**: Critical drift events happen outside business hours.
**Solution**: Push notifications to Salesforce Mobile App for on-call teams.

**Features**:

- Push notifications for Critical/High-risk changes
- Deep links to Elaro dashboard
- Snooze/acknowledge alerts
- Escalation if not acknowledged in 30 minutes

**Estimated Effort**: 2 weeks

---

### Success Metrics (v1.5)

- **Time-to-Remediation**: <1 hour (down from 4+ hours)
- **AI Explanation Accuracy**: >90% user satisfaction
- **Jira Adoption**: >50% of customers enable integration
- **Alert Response Time**: <15 minutes for critical events

---

## 🔮 v2.0 — Multi-Org Governance

**Planned Release**: Q4 2025 (Oct-Dec)
**Status**: 🔮 Future

### Goals

- Scale Elaro to enterprise customers with 10+ Salesforce orgs
- Centralize compliance evidence across prod, sandboxes, dev orgs
- Add AI governance (track Einstein/AI feature usage)

### Planned Features

#### 1. **Multi-Org Dashboard** 🌐

**Problem**: Enterprises have 10-50 Salesforce orgs (prod, QA, sandboxes, dev).
**Solution**: Single pane of glass to monitor compliance across all orgs.

**Features**:

- Org hierarchy view (prod → staging → dev)
- Aggregate Audit Readiness Score across all orgs
- Drift detection across environments (e.g., prod has config not in staging)
- Centralized alert management

**UI Mockup**:

```
┌─────────────────────────────────────────────────────────────┐
│ Elaro Multi-Org Dashboard                                │
├─────────────────────────────────────────────────────────────┤
│ Overall Readiness: 74/100 🟡                                │
│ Critical Issues: 12    High: 34    Medium: 67              │
├─────────────────────────────────────────────────────────────┤
│ Org                     Score    Status    Last Scan        │
│ ─────────────────────────────────────────────────────────   │
│ 🟢 Production          82/100   ✅ Pass   2025-01-24 08:15  │
│ 🟡 Staging             68/100   ⚠️ Warn   2025-01-24 08:12  │
│ 🔴 Dev-Team-A          34/100   🔴 Fail   2025-01-23 14:30  │
│ 🟢 Sandbox-QA          91/100   ✅ Pass   2025-01-24 07:45  │
└─────────────────────────────────────────────────────────────┘
```

**Implementation**:

- Hub-and-spoke architecture (central monitoring org + spoke orgs)
- REST API for spoke orgs to push data to hub
- Platform Events for real-time sync
- LWC component for org hierarchy visualization

**Estimated Effort**: 8 weeks

---

#### 2. **Centralized Evidence Repository** 📚

**Problem**: Auditors want evidence from all orgs, not per-org exports.
**Solution**: Centralized repository that collects evidence from all connected orgs.

**Features**:

- Automatic evidence collection from all orgs (daily)
- Deduplicate and compress evidence
- Searchable evidence library (by date, org, change type)
- One-click export for auditors (ZIP file with all evidence)

**Evidence Types**:

- Setup Audit Trail (all orgs, last 180 days)
- Field History (all compliance-sensitive objects)
- Permission set assignments (with timestamps)
- Login history and failed login attempts
- API usage logs

**Storage**:

- Salesforce Files (for <2GB evidence per org)
- External storage (AWS S3, Azure Blob) for larger datasets

**Estimated Effort**: 6 weeks

---

#### 3. **AI Governance** 🤖

**Problem**: GDPR Article 22 requires explaining automated decisions made by AI.
**Solution**: Track Einstein/AI feature usage and provide compliance documentation.

**Features**:

- Detect when Einstein Prediction/Discovery is used
- Log when AI-generated insights influence decisions
- Track which users have access to AI features
- Generate GDPR Article 22 compliance reports

**Example Report**:

```
AI Governance Report — GDPR Article 22 Compliance

Organization: Acme Healthcare
Date: 2025-10-15

AI Features in Use:
- Einstein Lead Scoring (enabled on Lead object)
- Einstein Opportunity Insights (enabled for Sales team)
- Einstein Forecasting (used by 23 users)

Automated Decisions Made:
- 456 leads auto-scored in last 30 days
- 89 opportunities flagged as "at risk"
- 12 forecasts auto-generated

Human Oversight:
✅ All AI-generated scores require human approval before action
✅ Users can request explanation for AI decisions (via "Why this score?" button)
✅ Audit trail tracks when AI recommendations are overridden

Compliance Status: ✅ GDPR Article 22 Compliant
```

**Estimated Effort**: 4 weeks

---

#### 4. **SIEM Export** 📤

**Problem**: Security teams want Elaro events in their SIEM (Splunk, Datadog, etc.).
**Solution**: Real-time event streaming to SIEM tools.

**Features**:

- Push Elaro events to SIEM via REST API
- Support for Splunk, Datadog, Sumo Logic, AWS Security Hub
- Event normalization (map Salesforce events to SIEM schema)
- Configurable event filtering (only send Critical/High events)

**Configuration**:

```apex
SIEM_Integration__c siemConfig = new SIEM_Integration__c(
    Name = 'Splunk_Prod',
    Endpoint__c = 'https://splunk.acme.com/services/collector',
    API_Key__c = '{!$Credential.Splunk_HEC.Token}',
    Event_Severity_Filter__c = 'Critical;High',
    Enabled__c = true
);
insert siemConfig;
```

**Estimated Effort**: 3 weeks

---

#### 5. **Custom Compliance Frameworks** 📋

**Problem**: Not all orgs use HIPAA/SOC 2; some need ISO 27001, FedRAMP, etc.
**Solution**: Allow users to define custom compliance rules.

**Features**:

- Compliance Framework Builder (UI to define rules)
- Rule types: metadata checks, permission checks, audit trail requirements
- Custom scoring weights (e.g., encryption = 40%, permissions = 30%)
- Export/import frameworks (share with community)

**Example Custom Rule**:

```yaml
# ISO 27001 Custom Rule
name: "A.9.2.3 — User Access Provisioning"
description: "Users should not have access rights beyond what is necessary"
rule:
  - check: user_permission_sets
    condition: contains("Modify All Data")
    severity: high
    action: flag_as_violation
    remediation: "Remove 'Modify All Data' and assign granular permission sets"
```

**Estimated Effort**: 6 weeks

---

### Success Metrics (v2.0)

- **Multi-Org Adoption**: >30% of customers connect 3+ orgs
- **Evidence Export Time**: <5 minutes for all orgs
- **SIEM Integration**: >20% of customers enable SIEM export
- **Custom Framework Usage**: >10 community-contributed frameworks

---

## 🌟 v3.0+ — Automated Remediation

**Planned Release**: 2026+
**Status**: 🌟 Future Vision

### Goals

- Shift from "detect" to "prevent" — stop compliance violations before they happen
- Automate remediation of common drift issues
- Enforce compliance policies via CI/CD

### Planned Features

#### 1. **Auto-Remediation** ⚡

**Problem**: Detecting drift is great, but fixing it manually is tedious.
**Solution**: Automatically fix common compliance violations.

**Example Auto-Remediations**:

- Remove stale permission set assignments (user inactive >90 days)
- Reset OWD to "Private" if changed to "Public Read/Write" without approval
- Revoke "Modify All Data" for non-admin users
- Re-enable Field History Tracking if disabled on compliance-sensitive object

**Safety**:

- Dry-run mode (preview changes before applying)
- Rollback capability (undo last 10 auto-remediations)
- Require approval for high-risk fixes
- Audit trail of all auto-remediations

**Estimated Effort**: 10 weeks

---

#### 2. **Change Control Workflows** 🚦

**Problem**: High-risk changes should require approval, not just alerting.
**Solution**: Approval workflows for setup changes (like pull request reviews).

**Features**:

- Require approval before deploying permission set changes
- Approval matrix (junior admin → senior admin → CISO)
- Integration with existing approval tools (Jira, ServiceNow)
- Auto-reject changes that violate policy

**Example**:

```
Change Request #1234

Requested By: j.smith@acme.org
Change: Add "Modify All Data" to Financial_Data_Access permission set
Risk Level: 🔴 Critical
Compliance Impact: Violates SOX segregation of duties

Status: ⏳ Pending Approval
Approvers:
- Jane Doe (Senior Admin): ⏳ Pending
- John Smith (CISO): ⏳ Pending

Comments:
- j.smith: "Need this to debug production issue"
- Elaro AI: "This change affects 45 users and increases risk score by 15 points"
```

**Estimated Effort**: 12 weeks

---

#### 3. **Policy-as-Code** 📜

**Problem**: Compliance policies are documented in Word docs, not enforced.
**Solution**: Define compliance policies in YAML, enforce via CI/CD.

**Example Policy**:

```yaml
# acme-healthcare-compliance-policy.yml

policy_name: "Acme Healthcare HIPAA Compliance Policy"
version: "1.2"
effective_date: "2025-01-01"

rules:
  - id: "AC-01"
    name: "Minimum Necessary Access"
    description: "No user should have Modify All Data permission"
    severity: critical
    check:
      - user_permissions.contains("Modify All Data")
    action: block_deployment
    remediation: "Remove Modify All Data, assign granular permission sets"

  - id: "AC-02"
    name: "Audit Trail Coverage"
    description: "Field History must be enabled on all PHI objects"
    severity: high
    check:
      - object.contains_phi == true
      - field_history_tracking.enabled == false
    action: flag_violation
    remediation: "Enable Field History Tracking on {object_name}"

enforcement:
  - block_deployments: true
  - require_approval_on_violation: true
  - auto_remediate_if_possible: false
```

**CI/CD Integration**:

```bash
# GitHub Actions workflow
- name: Elaro Policy Check
  run: |
    sf sentinel policy validate \
      --policy acme-healthcare-compliance-policy.yml \
      --target-org production \
      --fail-on-violation
```

**Estimated Effort**: 14 weeks

---

#### 4. **AppExchange Listing** 🏪

**Problem**: Installation is complex (git clone, deploy, configure).
**Solution**: Publish Elaro as a managed package on AppExchange.

**Features**:

- One-click installation from AppExchange
- Managed package (no code visibility, automatic updates)
- Free tier (limited to 1 org, 1 scan/day)
- Paid tiers (multi-org, unlimited scans, premium support)

**Pricing** (proposed):

- Free: 1 org, 1 scan/day, community support
- Starter ($99/mo): 3 orgs, daily scans, email support
- Professional ($299/mo): 10 orgs, hourly scans, Slack integration, phone support
- Enterprise ($999/mo): Unlimited orgs, real-time scans, SIEM export, dedicated CSM

**Estimated Effort**: 20 weeks (includes packaging, AppExchange review, billing)

---

### Success Metrics (v3.0+)

- **Auto-Remediation Adoption**: >40% of violations auto-fixed
- **Policy-as-Code Usage**: >100 customers using custom policies
- **AppExchange Installs**: >1,000 installs in first year
- **Customer Satisfaction**: NPS >50

---

## Beyond v3.0 — Long-Term Vision

### Potential Future Features (v4.0+)

- **Predictive Compliance**: ML models predict when org will drift out of compliance
- **Compliance Copilot**: ChatGPT-like interface ("Show me all users with Modify All Data")
- **Blockchain Evidence Storage**: Immutable audit trail using blockchain
- **Compliance Marketplace**: Buy/sell compliance policies and frameworks
- **Multi-Cloud Support**: Expand beyond Salesforce (AWS, Azure, Google Cloud)
- **Automated Audits**: Generate full audit reports without human input

---

## Release Cadence

- **Major versions** (v1.0, v2.0, v3.0): Every 12-18 months
- **Minor versions** (v1.1, v1.2, v1.3): Every 3-4 months
- **Patch releases** (v1.0.1, v1.0.2): As needed (bug fixes, security patches)

---

## Contributing to the Roadmap

We welcome community input on this roadmap!

**How to suggest features**:

1. Open a GitHub Discussion: [Feature Requests](https://github.com/derickporter1993/Elaro/discussions/categories/feature-requests)
2. Describe the problem you're solving (not just the solution)
3. Explain who benefits (compliance teams, auditors, developers?)
4. Vote on existing feature requests

**What gets prioritized**:

- High user demand (>10 votes)
- Aligns with product vision (compliance drift → governance → remediation)
- Technical feasibility (can we build it in 3-6 months?)
- Compliance impact (does it help pass audits?)

---

## Changelog

### v1.0 (2025-01-15)

- Initial release
- Compliance Baseline Scan
- Configuration Drift Detection
- Audit Evidence Export
- Slack alerting

### v1.5 (Planned Q2 2025)

- AI Change Explanations
- Suggested Fixes
- Jira Integration
- Compliance Report Scheduler
- Mobile Alerts

### v2.0 (Planned Q4 2025)

- Multi-Org Dashboard
- Centralized Evidence Repository
- AI Governance
- SIEM Export
- Custom Compliance Frameworks

---

_This roadmap is a living document and subject to change based on user feedback, market needs, and technical feasibility._

**Last Updated**: 2025-01-24
