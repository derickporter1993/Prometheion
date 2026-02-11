# Elaro Feature Plan

**Date:** February 5, 2026
**Version:** 1.0
**Status:** Pending Review

---

## 1. Executive Summary

Elaro's single biggest product opportunity is **completing the audit report generation workflow**. Users can successfully detect compliance gaps, monitor drift, and query the AI copilot — but they cannot generate the formal documentation that auditors actually need. This fundamental disconnect between detection and delivery means customers are forced to manually compile evidence from screenshots, undermining the core value proposition of "audit-ready in 24 hours."

The report export functionality is 0% complete despite UI buttons existing throughout the application. Fixing this single workflow would transform Elaro from a monitoring tool into a compliance delivery platform — the difference between "interesting dashboard" and "audit-ready system."

Secondary opportunity: v1.5 features (AI explanations, suggested fixes, Jira integration) have been planned since Q2 2025 but remain undelivered. Completing these would fulfill product promises already made to the market.

---

## 2. Current State Assessment

### What's Working Well

| Feature                       | Status    | Notes                                                                                                              |
| ----------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------ |
| **Compliance Scoring Engine** | Excellent | Real-time 0-100 scores across 10 frameworks (HIPAA, SOC2, GDPR, NIST, FedRAMP, PCI-DSS, SOX, CCPA, GLBA, ISO27001) |
| **Gap Discovery Workflow**    | Excellent | Users can find, filter, and drill into compliance gaps with full CRUD                                              |
| **AI Copilot Q&A**            | Good      | Claude integration works; users can ask compliance questions and get actionable responses                          |
| **Real-Time Monitoring**      | Good      | Platform events power live dashboards for governor limits, API usage, flow execution, alerts                       |
| **Jira Integration**          | Good      | Users can create Jira issues directly from gap records                                                             |
| **Security Posture**          | Good      | 95%+ SOQL queries use WITH SECURITY_ENFORCED; CRUD checks via ElaroSecurityUtils                                   |
| **Test Coverage**             | Good      | 95%+ coverage with 67+ test classes                                                                                |

### What's Almost There But Incomplete

| Feature                        | Current State                            | Gap                                                                                              |
| ------------------------------ | ---------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Report Generation**          | UI wizard exists, backend missing        | auditReportGenerator has Export PDF button but no implementation                                 |
| **AI Auto-Fix**                | Button exists in elaroCopilot            | Shows "Coming Soon" dialog; remediation logic not implemented                                    |
| **Event Root Cause Analysis**  | Backend exists (RootCauseAnalysisEngine) | elaroEventExplorer "Analyze" button not wired to backend                                         |
| **Framework-Specific Reports** | Buttons exist in elaroDashboard          | "Generate SOC2 Report" and "Generate HIPAA Report" show "Coming Soon"                            |
| **Export Functions**           | Export buttons across 6+ components      | controlMappingMatrix, elaroDrillDownViewer, comparative analytics all have non-functional export |

### What's Missing Entirely

| Feature                               | Impact   | Notes                                                    |
| ------------------------------------- | -------- | -------------------------------------------------------- |
| **PDF Generation Capability**         | Critical | No library or service for generating formatted documents |
| **First-Time User Onboarding**        | Medium   | No guided walkthrough after installation                 |
| **Permission Intelligence Dashboard** | Medium   | PRD exists but UI not implemented                        |
| **Multi-Org Support**                 | Medium   | Roadmap v2.0 feature; no current infrastructure          |
| **Mobile Optimization**               | Low      | Unknown mobile experience; likely poor                   |

### What's At Risk

| Risk                                 | Severity | Evidence                                                                                                              |
| ------------------------------------ | -------- | --------------------------------------------------------------------------------------------------------------------- |
| **Dashboard Confusion**              | Medium   | Three similar dashboards (Elaro_All_Components, Elaro_Compliance_Hub, Elaro_Dashboard) with overlapping functionality |
| **Duplicate Components**             | Low      | Two KPI dashboards, two copilot variants exist                                                                        |
| **Outdated Roadmap**                 | Low      | Documentation references Q2 2025 for v1.5; it's now Feb 2026                                                          |
| **4 HTTP Callouts Missing Timeouts** | Medium   | SlackNotifier, ElaroDailyDigest, ElaroComplianceAlert (2 methods) could hang indefinitely                             |
| **1 Trigger Missing CRUD Check**     | Medium   | PerformanceAlertEventTrigger has direct DML without security check                                                    |

---

## 3. Documentation Gaps

### Tier 1 - Required (Gaps Found)

| Document                | Status  | Impact                                                                |
| ----------------------- | ------- | --------------------------------------------------------------------- |
| **PRD/Feature Spec**    | Partial | Permission Intelligence PRD exists; no PRDs for core features or v1.5 |
| **App Flow/Sitemap**    | Missing | No formal documentation of screens, routes, or user journeys          |
| **Live App Experience** | N/A     | Analysis based on codebase inspection; no live app access             |

### Tier 2 - Important (Gaps Found)

| Document                | Status   | Impact                                                   |
| ----------------------- | -------- | -------------------------------------------------------- |
| **Implementation Plan** | Outdated | ROADMAP.md references Q2 2025; dates are 9+ months stale |
| **Progress Log**        | Missing  | No centralized tracking of what's shipped vs in-flight   |
| **Lessons Learned**     | Missing  | No post-mortems or retrospectives documented             |

### Tier 3 - Useful (Available)

| Document              | Status                                                 |
| --------------------- | ------------------------------------------------------ |
| **Tech Stack**        | Available in TECHNICAL_DEEP_DIVE.md, sfdx-project.json |
| **Design System**     | Using SLDS (Salesforce Lightning Design System)        |
| **Backend Structure** | Documented in CLAUDE.md, API_REFERENCE.md              |

### Assumptions Made Due to Gaps

1. **User Feedback:** No analytics or user feedback data available. Prioritization based on technical analysis of incomplete flows, not observed user behavior.
2. **Revenue Data:** No visibility into conversion, churn, or monetization metrics. Revenue proximity scores based on roadmap pricing tiers.
3. **Mobile Usage:** No data on mobile vs desktop usage patterns. Assumed desktop-primary based on enterprise compliance use case.
4. **Competitor Analysis:** No formal competitive analysis. Assumed compliance tooling market gaps based on roadmap positioning.

---

## 4. Phase 1 — Ship This Week

High impact, low effort features that address critical gaps with minimal risk.

### Feature 1.1: Implement Basic Report Export (CSV/JSON)

**What it does:** Enables users to export compliance gap data, evidence, and score history as CSV or JSON files from the elaroDynamicReportBuilder and auditReportGenerator components.

**Why it matters now:** Users complete the audit wizard flow but hit a dead end at "Export" — they literally cannot extract their data. This blocks the fundamental audit preparation use case. Evidence: auditReportGenerator.js has Export PDF button with no backend; users must manually screenshot dashboards.

**What it builds on:**

- elaroDynamicReportBuilder already queries Elaro objects and displays results
- Salesforce LWC has native CSV export capabilities via lightning-datatable
- ElaroAuditPackageBuilder exists and creates Elaro_Audit_Package\_\_c records

**What it doesn't touch:**

- No PDF generation (Phase 2)
- No email delivery (Phase 2)
- No scheduled exports (v1.5 roadmap)
- No multi-org data aggregation

**Prioritization Score:**

| Dimension               | Weight | Score   | Reasoning                                            |
| ----------------------- | ------ | ------- | ---------------------------------------------------- |
| User Pain               | 30%    | 5       | Blocking — users cannot complete primary workflow    |
| Revenue Proximity       | 25%    | 4       | Directly enables audit delivery value proposition    |
| Implementation Leverage | 25%    | 5       | CSV export is native LWC feature; JSON is trivial    |
| Compounding Effect      | 20%    | 3       | Enables email delivery, scheduled exports in Phase 2 |
| **Weighted Total**      |        | **4.3** | Phase 1 qualified                                    |

**Acceptance Criteria:**

1. User can click "Export CSV" in elaroDynamicReportBuilder and receive downloaded file
2. User can click "Export JSON" in auditReportGenerator and receive downloaded file
3. Exported CSV includes all visible columns with proper headers
4. Exported JSON includes audit package metadata (date range, frameworks, score)
5. Export completes within 10 seconds for datasets up to 10,000 records

**Risk Flags:**

- Large exports (>50,000 records) may hit browser memory limits — add pagination or streaming
- CSV encoding for non-ASCII characters needs testing

---

### Feature 1.2: Add HTTP Timeouts to Callout Methods

**What it does:** Adds `req.setTimeout(10000)` to 4 HTTP callout methods that currently lack timeouts, preventing indefinite hangs.

**Why it matters now:** Production callouts can hang forever, consuming governor limits and blocking user operations. Identified in CODEBASE_QUALITY_REVIEW.md as Critical severity. Evidence: SlackNotifier.notifyBulkAsync, ElaroDailyDigest.sendDigestToSlack, ElaroComplianceAlert.sendSlackAlert, ElaroComplianceAlert.sendPagerDutyAlert.

**What it builds on:**

- 12 of 16 callout methods already have timeouts (good pattern exists)
- ElaroComplianceCopilotService uses TIMEOUT_MS constant (reusable pattern)

**What it doesn't touch:**

- No changes to callout logic or endpoints
- No retry mechanisms (separate feature)
- No error notification changes

**Prioritization Score:**

| Dimension               | Weight | Score    | Reasoning                                                             |
| ----------------------- | ------ | -------- | --------------------------------------------------------------------- |
| User Pain               | 30%    | 4        | Slack/PagerDuty alerts failing silently causes missed critical alerts |
| Revenue Proximity       | 25%    | 3        | Reliability issue affecting enterprise customers                      |
| Implementation Leverage | 25%    | 5        | Single line addition per method                                       |
| Compounding Effect      | 20%    | 2        | Standalone stability fix                                              |
| **Weighted Total**      |        | **3.55** | Phase 1 qualified                                                     |

**Acceptance Criteria:**

1. SlackNotifier.notifyBulkAsync includes `req.setTimeout(10000)`
2. ElaroDailyDigest.sendDigestToSlack includes `req.setTimeout(10000)`
3. ElaroComplianceAlert.sendSlackAlert includes `req.setTimeout(10000)`
4. ElaroComplianceAlert.sendPagerDutyAlert includes `req.setTimeout(10000)`
5. All existing callout tests pass without modification

**Risk Flags:**

- None — additive change with no behavioral impact on success path

---

### Feature 1.3: Add CRUD Security Check to PerformanceAlertEventTrigger

**What it does:** Adds Schema.sObjectType.Performance_Alert_History\_\_c.isCreateable() check before DML insert in the trigger.

**Why it matters now:** Security vulnerability — users without create permission could bypass security controls. Identified in CODEBASE_QUALITY_REVIEW.md as Critical severity. Evidence: Line 16 of PerformanceAlertEventTrigger.trigger has direct `insert hist;` without CRUD check.

**What it builds on:**

- ElaroSecurityUtils provides standardized CRUD checking
- All other triggers have proper security checks
- ApiUsageSnapshot.cls demonstrates correct pattern

**What it doesn't touch:**

- No changes to alert processing logic
- No changes to platform event handling
- No changes to Performance_Alert_History\_\_c object

**Prioritization Score:**

| Dimension               | Weight | Score   | Reasoning                                     |
| ----------------------- | ------ | ------- | --------------------------------------------- |
| User Pain               | 30%    | 3       | Security issue, not user-facing functionality |
| Revenue Proximity       | 25%    | 4       | AppExchange security review will flag this    |
| Implementation Leverage | 25%    | 5       | 5 lines of code addition                      |
| Compounding Effect      | 20%    | 2       | Standalone security fix                       |
| **Weighted Total**      |        | **3.5** | Phase 1 qualified                             |

**Acceptance Criteria:**

1. Trigger checks isCreateable() before insert DML
2. Trigger logs warning if permission check fails
3. Trigger gracefully returns without error if permission denied
4. PerformanceAlertEventTriggerTest passes with new security check
5. No regression in alert history creation for authorized users

**Risk Flags:**

- May surface permission issues in customer orgs that weren't previously visible
- Document in release notes that Elaro_Admin permission set is required

---

### Feature 1.4: Add Batch Failure Notifications

**What it does:** Adds email notification to administrators when RetentionEnforcementBatch or ConsentExpirationBatch completes with errors.

**Why it matters now:** Batch jobs can fail silently — compliance-critical data retention operations running without oversight. Evidence: finish() methods only log to debug; ElaroGLBAAnnualNoticeBatch correctly implements notification pattern.

**What it builds on:**

- ElaroGLBAAnnualNoticeBatch.finish() has working notification pattern
- AsyncApexJob query pattern already used elsewhere
- Messaging.SingleEmailMessage available in Apex

**What it doesn't touch:**

- No changes to batch processing logic
- No changes to retention policies
- No Slack/PagerDuty integration (future enhancement)

**Prioritization Score:**

| Dimension               | Weight | Score   | Reasoning                                                 |
| ----------------------- | ------ | ------- | --------------------------------------------------------- |
| User Pain               | 30%    | 3       | Silent failures cause compliance gaps discovered too late |
| Revenue Proximity       | 25%    | 3       | Reliability affects enterprise trust                      |
| Implementation Leverage | 25%    | 5       | Copy existing pattern from GLBA batch                     |
| Compounding Effect      | 20%    | 3       | Enables monitoring across all batch jobs                  |
| **Weighted Total**      |        | **3.4** | Phase 1 qualified                                         |

**Acceptance Criteria:**

1. RetentionEnforcementBatch.finish() sends email when NumberOfErrors > 0
2. ConsentExpirationBatch.finish() sends email when NumberOfErrors > 0
3. Email includes job status, error count, total items processed
4. Email sent to user who scheduled the batch (CreatedBy.Email)
5. No email sent when job completes successfully with 0 errors

**Risk Flags:**

- Email delivery depends on org email settings being configured
- Document prerequisite of org-wide email address setup

---

## 5. Phase 2 — Ship This Sprint

Features that make Elaro feel professional and complete.

### Feature 2.1: Implement Framework-Specific PDF Reports

**What it does:** Generates professional PDF audit reports for the top 3 frameworks: SOC 2, HIPAA, and GDPR. Each report includes executive summary, compliance score, gap analysis, evidence references, and remediation recommendations.

**Why it matters now:** The "Generate SOC2 Report" and "Generate HIPAA Report" buttons in elaroDashboard are the most visible broken features. Users click them expecting audit documentation and get "Coming Soon." This is the difference between a monitoring tool and an audit-ready platform.

**What it builds on:**

- ElaroAuditPackageBuilder exists and collects audit data
- Compliance scoring engine provides per-framework scores
- Compliance_Gap**c, Compliance_Evidence**c objects have all required data
- Framework-specific control mappings exist in custom metadata

**What it doesn't touch:**

- No changes to scoring algorithms
- No new data collection (uses existing evidence)
- No scheduled delivery (v1.5 feature)
- No multi-org aggregation

**Prioritization Score:**

| Dimension               | Weight | Score   | Reasoning                                                        |
| ----------------------- | ------ | ------- | ---------------------------------------------------------------- |
| User Pain               | 30%    | 5       | Visible "Coming Soon" on primary dashboard                       |
| Revenue Proximity       | 25%    | 5       | Audit reports are the monetizable deliverable                    |
| Implementation Leverage | 25%    | 3       | Requires PDF library selection and template design               |
| Compounding Effect      | 20%    | 4       | Enables scheduled reports, email delivery, additional frameworks |
| **Weighted Total**      |        | **4.3** | Phase 2 qualified                                                |

**Acceptance Criteria:**

1. User clicks "Generate SOC2 Report" and receives downloadable PDF
2. User clicks "Generate HIPAA Report" and receives downloadable PDF
3. User can generate GDPR report from framework selector
4. PDF includes: cover page, executive summary, compliance score, gap list, evidence references
5. PDF generation completes within 30 seconds
6. PDF follows consistent visual design with Elaro branding

**Risk Flags:**

- PDF library selection (options: Salesforce PDF via Visualforce, third-party like PDFKit, or Apex PDF library)
- Governor limits for large reports (>100 gaps) — may need async generation
- Template design requires product/design decision

---

### Feature 2.2: Complete AI Auto-Fix Suggestions

**What it does:** When users view a compliance gap, the AI copilot provides specific remediation steps with copy-paste Apex/metadata code. Not auto-execution — human-reviewed suggestions only.

**Why it matters now:** v1.5 roadmap promised "Suggested Fixes" with auto-generated remediation steps. The elaroCopilot "Auto-Fix" button exists but shows "Coming Soon." Users see AI capabilities but can't use them for remediation.

**What it builds on:**

- elaroCopilot already integrates with Claude API
- Remediation_Suggestion\_\_c object exists for storing suggestions
- remediationSuggestionCard component exists but needs content
- ElaroComplianceCopilot service handles AI interactions

**What it doesn't touch:**

- No automatic execution of changes (safety constraint)
- No approval workflows (v3.0 feature)
- No Jira ticket creation (separate integration)

**Prioritization Score:**

| Dimension               | Weight | Score   | Reasoning                                           |
| ----------------------- | ------ | ------- | --------------------------------------------------- |
| User Pain               | 30%    | 4       | Users know WHAT's wrong but not HOW to fix it       |
| Revenue Proximity       | 25%    | 4       | AI differentiation drives premium pricing           |
| Implementation Leverage | 25%    | 4       | Claude integration exists; needs prompt engineering |
| Compounding Effect      | 20%    | 4       | Enables Jira integration, approval workflows        |
| **Weighted Total**      |        | **4.0** | Phase 2 qualified                                   |

**Acceptance Criteria:**

1. User views gap → copilot shows "Suggested Fix" section
2. Suggestion includes: root cause explanation, step-by-step remediation, copy-paste code
3. Suggestion indicates which frameworks the fix addresses
4. Suggestion estimates compliance score impact ("Fixes this: +5 points")
5. User can copy code snippets with one click
6. Suggestions are cached to reduce API costs (TTL: 24 hours)

**Risk Flags:**

- AI hallucination risk — suggestions must be marked as "AI-generated, human review required"
- Code suggestions may not compile in all orgs — add disclaimer
- API costs for Claude need monitoring

---

### Feature 2.3: Wire Event Analysis UI to Backend

**What it does:** Connects the elaroEventExplorer "Analyze" button to the existing RootCauseAnalysisEngine backend, displaying root cause analysis in a modal.

**Why it matters now:** Backend capability exists but UI is disconnected. Users can see events but can't understand why they happened. The "Analyze" button exists and does nothing — classic incomplete feature.

**What it builds on:**

- RootCauseAnalysisEngine.analyzeRootCause() method exists
- elaroEventExplorer has "Analyze" row action defined
- Modal pattern used throughout other components

**What it doesn't touch:**

- No changes to analysis algorithms
- No changes to event collection
- No new event types

**Prioritization Score:**

| Dimension               | Weight | Score    | Reasoning                                          |
| ----------------------- | ------ | -------- | -------------------------------------------------- |
| User Pain               | 30%    | 3        | Users want to understand events, not just see them |
| Revenue Proximity       | 25%    | 3        | Event analysis is table-stakes for security tools  |
| Implementation Leverage | 25%    | 5        | Backend exists; just need UI wiring                |
| Compounding Effect      | 20%    | 3        | Enables correlation features, automated response   |
| **Weighted Total**      |        | **3.45** | Phase 2 qualified                                  |

**Acceptance Criteria:**

1. User clicks "Analyze" on event row
2. Modal appears with loading state
3. Modal displays: event details, root cause analysis, related events, risk assessment
4. Modal has "Create Gap" action to convert event to compliance gap
5. Analysis completes within 5 seconds
6. Error state shown if analysis fails

**Risk Flags:**

- Backend method may need error handling improvements
- Large event volumes may slow analysis — consider async processing

---

### Feature 2.4: Consolidate Dashboard Navigation

**What it does:** Removes duplicate dashboard tabs and establishes Elaro_Compliance_Hub as the primary entry point. Archives Elaro_Dashboard (legacy) and rebrands Elaro_All_Components as "Advanced View."

**Why it matters now:** Users don't know which of three similar dashboards to use. This creates confusion and support burden. Evidence: Three tabs with overlapping components; no clear differentiation.

**What it builds on:**

- Elaro_Compliance_Hub has the most complete component set
- Elaro_Dashboard is documented as "legacy" in code comments
- Tab visibility is configuration-only change

**What it doesn't touch:**

- No component deletions (preserve backward compatibility)
- No new components
- No data changes

**Prioritization Score:**

| Dimension               | Weight | Score    | Reasoning                            |
| ----------------------- | ------ | -------- | ------------------------------------ |
| User Pain               | 30%    | 3        | Confusion, not blocking              |
| Revenue Proximity       | 25%    | 2        | UX polish, not revenue driver        |
| Implementation Leverage | 25%    | 5        | Configuration change only            |
| Compounding Effect      | 20%    | 3        | Simplifies onboarding, documentation |
| **Weighted Total**      |        | **3.15** | Phase 2 qualified                    |

**Acceptance Criteria:**

1. Elaro app shows 2 main tabs: "Compliance Hub" (primary), "Advanced View" (power users)
2. Legacy Elaro_Dashboard tab is hidden from navigation
3. Setup guide updated to direct users to Compliance Hub
4. No functionality lost (components still accessible)
5. Users with existing bookmarks still reach valid pages

**Risk Flags:**

- Existing users may have bookmarks to removed tabs — add redirect
- Documentation references need updating

---

### Feature 2.5: Add Compliance Score Explainer

**What it does:** Adds a "Why this score?" tooltip/panel to elaroDashboard and elaroReadinessScore showing how the score is calculated and what would improve it.

**Why it matters now:** Users see "72/100" but don't understand how to improve. The score is opaque. Evidence: elaroReadinessScore shows factors but no explanatory text or improvement suggestions.

**What it builds on:**

- ElaroComplianceScorer.calculateReadinessScore() has weighted factors
- Score breakdown already displayed in elaroReadinessScore
- Tooltip patterns exist in other components

**What it doesn't touch:**

- No changes to scoring algorithm
- No new data collection
- No historical comparison (Phase 3)

**Prioritization Score:**

| Dimension               | Weight | Score    | Reasoning                                           |
| ----------------------- | ------ | -------- | --------------------------------------------------- |
| User Pain               | 30%    | 3        | Users confused about improvement path               |
| Revenue Proximity       | 25%    | 3        | Drives engagement with premium features             |
| Implementation Leverage | 25%    | 4        | Scoring logic already exists; needs UI presentation |
| Compounding Effect      | 20%    | 3        | Enables goal-setting, trend analysis                |
| **Weighted Total**      |        | **3.25** | Phase 2 qualified                                   |

**Acceptance Criteria:**

1. Info icon next to score opens explainer panel
2. Panel shows: 5 scoring factors with current weights and values
3. Panel shows: "Top 3 ways to improve your score" with specific actions
4. Each improvement shows estimated point increase
5. Panel links to relevant gaps for each factor

**Risk Flags:**

- Improvement suggestions require consistent scoring methodology
- Point estimates may set unrealistic expectations — add "estimated" qualifier

---

## 6. Phase 3 — Ship This Quarter

Strategic investments that create platform defensibility.

### Feature 3.1: Permission Intelligence Dashboard

**What it does:** Implements the Permission Intelligence PRD — a dedicated dashboard for analyzing permission sets, detecting privilege escalation, identifying over-privileged users, and generating access control reports.

**Why it matters now:** PRD exists and is comprehensive. Permission sprawl is a top compliance concern across HIPAA, SOC2, NIST, and GDPR. This is a differentiating feature that competitors lack.

**What it builds on:**

- Permission_Intelligence_PRD.md has full requirements
- Threat detector already has detectPermissionSetClones() method
- Platform events infrastructure exists
- Dashboard component patterns established

**What it doesn't touch:**

- No auto-remediation (v3.0+)
- No approval workflows
- No multi-org permission comparison

**Prioritization Score:**

| Dimension               | Weight | Score    | Reasoning                                                          |
| ----------------------- | ------ | -------- | ------------------------------------------------------------------ |
| User Pain               | 30%    | 4        | Permission sprawl is audit fail point                              |
| Revenue Proximity       | 25%    | 4        | Enterprise differentiator                                          |
| Implementation Leverage | 25%    | 3        | PRD complete but significant build                                 |
| Compounding Effect      | 20%    | 5        | Enables approval workflows, auto-remediation, multi-org governance |
| **Weighted Total**      |        | **3.95** | Phase 3 qualified                                                  |

**Acceptance Criteria:**

1. User can view Permission Intelligence Dashboard from Elaro app
2. Dashboard shows: total permission sets, assignments per user average, over-privileged users count
3. User can see timeline of permission changes
4. System detects and alerts on permission set clones with elevated privileges
5. User can generate Access Control Audit Report (PDF/CSV)
6. Detection rate >95% for unauthorized permission escalations

**Risk Flags:**

- Performance impact on large orgs (50,000+ users) — needs async processing
- False positives in clone detection — needs tuning mechanism
- Platform event limits for high-volume orgs

---

### Feature 3.2: Jira Bidirectional Sync

**What it does:** Extends existing Jira integration to sync status bidirectionally — when Jira ticket is resolved, Elaro gap is auto-updated; when Elaro gap is closed, Jira ticket is updated.

**Why it matters now:** v1.5 roadmap promised bidirectional sync. Current integration is one-way (create ticket from Elaro). Compliance teams track work in Jira but must manually update Elaro.

**What it builds on:**

- jiraCreateModal successfully creates Jira issues
- Elaro_Jira_Settings\_\_c stores integration configuration
- Jira webhook capability for incoming updates

**What it doesn't touch:**

- No ServiceNow integration (future)
- No automatic gap closure (requires human confirmation)
- No custom field mapping

**Prioritization Score:**

| Dimension               | Weight | Score   | Reasoning                                        |
| ----------------------- | ------ | ------- | ------------------------------------------------ |
| User Pain               | 30%    | 3       | Manual sync is tedious but not blocking          |
| Revenue Proximity       | 25%    | 3       | Enterprise workflow integration                  |
| Implementation Leverage | 25%    | 3       | Requires webhook endpoint and Jira configuration |
| Compounding Effect      | 20%    | 4       | Enables automated remediation workflows          |
| **Weighted Total**      |        | **3.2** | Phase 3 qualified                                |

**Acceptance Criteria:**

1. When Jira issue transitions to "Done," linked Elaro gap status updates to "Resolved"
2. When Elaro gap status changes, Jira issue receives comment with update
3. User can configure which Jira transitions trigger Elaro updates
4. Webhook endpoint handles Jira signature verification
5. Failed syncs logged to Integration_Error\_\_c with retry mechanism

**Risk Flags:**

- Jira webhook configuration varies by Jira version (Cloud vs Server)
- Network failures need robust retry handling
- Circular update prevention required

---

### Feature 3.3: Custom Compliance Framework Builder

**What it does:** Allows users to define custom compliance rules via UI, supporting organizations with internal policies or frameworks beyond the built-in 10.

**Why it matters now:** v2.0 roadmap feature. Organizations have unique compliance requirements that don't map to standard frameworks. Evidence: Roadmap explicitly lists "Custom Compliance Frameworks" as v2.0 deliverable.

**What it builds on:**

- Compliance_Control\_\_mdt custom metadata exists
- Compliance_Policy\_\_mdt custom metadata exists
- Elaro_Framework_Mapping\_\_c for control mappings
- Scoring engine supports multiple frameworks

**What it doesn't touch:**

- No policy-as-code YAML (v3.0+)
- No framework marketplace (future)
- No CI/CD enforcement

**Prioritization Score:**

| Dimension               | Weight | Score    | Reasoning                                    |
| ----------------------- | ------ | -------- | -------------------------------------------- |
| User Pain               | 30%    | 3        | Enterprises have custom requirements         |
| Revenue Proximity       | 25%    | 4        | Enterprise pricing tier feature              |
| Implementation Leverage | 25%    | 3        | Custom metadata CRUD + UI builder            |
| Compounding Effect      | 20%    | 5        | Enables policy marketplace, sharing, imports |
| **Weighted Total**      |        | **3.65** | Phase 3 qualified                            |

**Acceptance Criteria:**

1. User can create new compliance framework via UI
2. User can add rules to framework (metadata checks, permission checks, audit requirements)
3. User can assign weights to rules
4. Custom frameworks appear in framework selector alongside built-in ones
5. Custom framework scores included in overall compliance score
6. User can export/import frameworks as JSON

**Risk Flags:**

- Rule validation needed to prevent invalid configurations
- Performance impact of custom rules on scoring engine
- Version management for imported frameworks

---

## 7. Parking Lot

Ideas that are too early, too expensive, or dependent on infrastructure that doesn't exist.

| Idea                             | Blocker                                                   | Move to Active When                                           |
| -------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------- |
| **Auto-Remediation**             | Requires change control workflow, approval infrastructure | Phase 3 complete; customer validation of suggested fixes      |
| **Multi-Org Dashboard**          | Hub-and-spoke architecture not built                      | Single-org features complete; 3+ enterprise customers request |
| **Policy-as-Code YAML**          | Requires CI/CD integration, GitHub Actions setup          | Custom frameworks shipped; DevOps teams adopt                 |
| **Predictive Compliance ML**     | Insufficient historical data; no ML infrastructure        | 12+ months of compliance score history across customers       |
| **Blockchain Evidence Storage**  | No clear customer demand; expensive                       | Regulatory requirement emerges                                |
| **Mobile App Optimization**      | Unknown mobile usage patterns                             | Analytics show >20% mobile traffic                            |
| **SIEM Export (Splunk/Datadog)** | Integration effort high; customer count unclear           | 5+ customers on enterprise tier request                       |
| **AppExchange Managed Package**  | Packaging requires namespace, ISV partnership             | Revenue >$100k ARR; dedicated support team                    |

---

## 8. Rejected Ideas

Ideas seriously considered but deliberately excluded.

### 8.1: Build Custom PDF Library in Apex

**Considered because:** PDF generation is critical; native solution avoids external dependencies.

**Rejected because:** Apex has no native PDF capability. Building from scratch would require byte-level PDF specification implementation — months of work that doesn't exist in any Apex library. Better to use Visualforce renderAs="pdf" or a third-party service.

**Alternative:** Use Visualforce page with renderAs="pdf" for report generation.

---

### 8.2: Real-Time Collaboration Features

**Considered because:** Multiple compliance team members working on same gaps; comments, @mentions would improve workflow.

**Rejected because:** Salesforce Chatter already provides collaboration features on records. Building duplicate functionality adds maintenance burden without clear differentiation. Users can enable Chatter on Compliance_Gap\_\_c.

**Alternative:** Document how to enable Chatter on Elaro objects.

---

### 8.3: White-Label / Multi-Tenant Architecture

**Considered because:** Consultants/MSPs could resell Elaro to multiple clients from one instance.

**Rejected because:** Adds significant complexity (tenant isolation, data segregation, billing). Current architecture is single-tenant per org. Multi-org dashboard (v2.0) addresses the enterprise use case without white-labeling.

**Alternative:** Multi-org dashboard for enterprises managing multiple Salesforce orgs.

---

### 8.4: Natural Language Search Across All Data

**Considered because:** "Show me all HIPAA gaps from last month" via natural language would be powerful.

**Rejected because:** elaroDynamicReportBuilder already provides structured querying. NLP search requires significant AI infrastructure for query translation, and errors would be confusing. Copilot Q&A handles natural language for questions, not data retrieval.

**Alternative:** Improve elaroDynamicReportBuilder with saved queries and templates.

---

### 8.5: Gamification / Compliance Leaderboards

**Considered because:** Competition between teams could drive compliance improvements.

**Rejected because:** Compliance is not a game. Leaderboards could incentivize gaming metrics rather than actual security improvements. Enterprise compliance officers would view gamification as unprofessional.

**Alternative:** ROI calculator (already exists) shows business value without gamification.

---

## 9. Dependency Map

What must be built before what.

### Phase 1 Dependencies (None — All Independent)

- Feature 1.1 (CSV/JSON Export) — No dependencies
- Feature 1.2 (HTTP Timeouts) — No dependencies
- Feature 1.3 (CRUD Security Check) — No dependencies
- Feature 1.4 (Batch Failure Notifications) — No dependencies

### Phase 2 Dependencies

- Feature 2.1 (PDF Reports) ← Feature 1.1 (CSV/JSON Export) — PDF builds on export patterns
- Feature 2.2 (AI Auto-Fix) — No dependencies (Claude integration exists)
- Feature 2.3 (Event Analysis UI) — No dependencies (backend exists)
- Feature 2.4 (Dashboard Consolidation) — No dependencies
- Feature 2.5 (Score Explainer) — No dependencies

### Phase 3 Dependencies

- Feature 3.1 (Permission Intelligence) ← Feature 2.1 (PDF Reports) — Needs report generation for access control audits
- Feature 3.2 (Jira Bidirectional Sync) — No dependencies (extends existing integration)
- Feature 3.3 (Custom Frameworks) ← Feature 2.5 (Score Explainer) — Needs scoring transparency for custom rules

### Critical Path

```
Phase 1.1 (CSV/JSON Export)
    ↓
Phase 2.1 (PDF Reports)
    ↓
Phase 3.1 (Permission Intelligence)
```

This path represents the core audit delivery capability — from basic data export to professional PDFs to specialized permission reports.

---

## 10. Iteration Trigger

Re-run this strategist prompt when:

1. **After Phase 1 ships** — Validate CSV/JSON export usage; gather user feedback on report formats needed
2. **After Phase 2 ships** — Measure PDF report generation volume; identify top 3 requested frameworks beyond SOC2/HIPAA/GDPR
3. **If competitor launches significant feature** — Reassess differentiation priorities
4. **If tech stack changes** — PDF library selection, new Salesforce API version, or Claude API changes
5. **If customer churn exceeds 5%** — Deep dive into feature gaps causing churn
6. **If enterprise customer requests multi-org** — Accelerate v2.0 roadmap features
7. **Quarterly by default** — Even without triggers, refresh priorities based on market and usage data

---

## Approval Checklist

- [ ] Executive Summary captures the core opportunity
- [ ] Current State Assessment is accurate
- [ ] Documentation Gaps are acknowledged and assumptions flagged
- [ ] Phase 1 features are truly achievable in one week
- [ ] Phase 2 features are achievable in one sprint (2-3 weeks)
- [ ] Phase 3 features are achievable in one quarter
- [ ] Scoring is defensible and transparent
- [ ] Acceptance criteria are testable
- [ ] Risk flags are addressable
- [ ] Rejected ideas demonstrate thoughtful prioritization
- [ ] Dependency map is accurate

---

**Document Status:** Pending Review
**Next Action:** Review with stakeholders, approve, pass to build agent
**Build Agent Instruction:** Upon approval, implement Phase 1 features first, verify acceptance criteria, update progress.txt after each feature completes.
