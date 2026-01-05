# PRD — Prometheion Permissions Intelligence (Months 1–2)

## 1. Product Overview
- **Product name (working):** Prometheion Permissions Intelligence
- **Module:** Core Trio – Feature 1 of 3
- **Goal:** Continuously analyze Salesforce permissions (Profiles, Permission Sets, Assignments) and produce:
  - User risk scores
  - Toxic permission detection
  - Permission inheritance maps ("why does this user have this access?")
  - Drift/change insights using Setup Audit Trail
- Serves as the foundation for Connected App Risk and Metadata Change Intelligence.

## 2. Problem Statement
- Salesforce orgs often contain thousands of fields, permission sets, and profiles.
- Unknown "god users" and over-privileged integration accounts create risk.
- Teams struggle to answer:
  - "Who has access to what?"
  - "Why do they have that access?"
  - "Which changes increased risk this week?"
- Current workflows (reports, Permission Set Explorer, spreadsheets) are manual and fail CISO expectations for IAM visibility.
- Prometheion solves this with a continuous, explainable permission intelligence layer.

## 3. Objectives & Success Metrics
### Objectives
1. Provide an org-wide permission inventory with risk scores per user.
2. Detect toxic permission combinations and outliers (e.g., "API-enabled users with ModifyAll on PII objects").
3. Explain inheritance clearly: "this access comes from Profile X + Permission Set Y + Public Group Z".
4. Surface weekly change deltas using Setup Audit Trail.

### KPIs (v1)
- **Time to answer "who has access to [Object/Field]?":** From hours → < 30 seconds.
- **Coverage:** 100% of active users, profiles, permission sets analyzed nightly.
- **Accuracy:** ≥ 95% match between "effective permissions" and Salesforce runtime behavior for CRUD/FLS (spot-checked).
- **Engagement:** Each security/admin team uses ≥ 3 recurring saved views after 30 days (e.g., "High-risk users", "Integration users").

## 4. Personas & Key User Stories
### Personas
1. **CISO / Security Lead** — cares about high-risk users, evidence for auditors, trends over time.
2. **Salesforce Architect / Admin** — cares about root-cause of access, simplifying sprawl, change impact.
3. **Compliance / Internal Audit** — cares about access review attestations, least-privilege proof, reports.

### Core User Stories (v1)
1. As a **Security Lead**, I want a ranked list of highest-risk users so I can focus remediation on the top 20 first.
2. As an **Architect**, I want to see why a user has access to Account.Read/Edit (profile vs permission set vs group) so I can adjust the right artifact.
3. As a **Compliance Analyst**, I want to export an access review report for a set of roles (e.g., finance users) that includes their effective permissions and risk score.
4. As an **Admin**, I want to see a weekly "what changed" view for permission changes (new perms, new assignments, profile changes) so I can detect misconfigurations early.
5. As a **Security Lead**, I want outlier detection that highlights users whose access is significantly broader than peers in the same role/department.

## 5. Scope
### In Scope (MVP)
- Read-only analysis of Users, Profiles, Permission Sets, Permission Set Assignments, Permission Set Groups, FieldPermissions, ObjectPermissions, RecordTypeAccess, and relevant Setup Audit Trail entries.
- Risk scoring for Users and Permission Sets, including toxic combination identification (configurable rules).
- Basic front-end: user risk list, user detail view with inheritance map, permission set/profile detail, weekly change summary, and CSV export.

### Out of Scope (Months 1–2)
- Automated remediation, cross-org analytics, connected app/integration analysis, real-time alerts (daily batch/on-demand only), AI explanations (use static heuristics for v1).

## 6. Functional Requirements
### 6.1 Data Ingestion & Normalization
- Pull and store snapshots of User, Profile, PermissionSet, PermissionSetAssignment, PermissionSetGroup, PermissionSetGroupComponent, ObjectPermissions, FieldPermissions, SetupAuditTrail.
- Support full initial scan and incremental daily/on-demand scans.
- **F-1:** Initial full snapshot for up to 10,000 users completes within 4 hours.
- **F-2:** Support scheduled daily re-scans (configurable time) plus a manual "Re-scan now" button.

### 6.2 Effective Permission Resolution
- For each user, compute effective CRUD/FLS across configurable key objects.
- **F-3:** Resolve effective object permissions (C/R/U/D, ViewAll, ModifyAll) and field permissions (Read, Edit) per selected object.
- **F-4:** Build inheritance graph listing contributing artifacts for each permission (e.g., "Account.Edit = Profile Sales_Profile + Permission Set PS_DealEdit").

### 6.3 Risk Scoring
- **F-5:** Compute a 0–100 User Risk Score using toxic combinations, sensitive object access, admin-like capabilities, and integration user flags.
- **F-6:** Risk scoring components configurable via admin UI with weights, sliders, and custom toxic rules (IF perm1 AND perm2 THEN risk points).

### 6.4 Outlier Detection
- **F-7:** Detect outlier users per peer group (Role, Department, Profile) using heuristics: risk > avg + 2*stdDev with > X points, or permission set count > group median + N (configurable).

### 6.5 Change Intelligence (Setup Audit Trail)
- **F-8:** Ingest Setup Audit Trail entries for profile, permission set, assignment changes, and user activation/deactivation.
- **F-9:** Produce a weekly "what changed" view highlighting new high-risk users, high-risk permission changes, and new assignments increasing risk.

### 6.6 UI / UX Requirements
- **User Risk List:** Columns (User Name, Username, Role, Department, Risk Score, Key Risk Factors), filters (risk range, role/profile, integration users), action to view detail.
- **User Detail View:** Summary (risk score, flags), effective permissions table, inheritance map (profiles/perm sets/groups), change history from Setup Audit Trail.
- **Weekly Changes View:** Timeline/table with date, actor, change type, impact (risk delta). Filters for high-risk changes and time window (7/30 days).

## 7. Data Model & Storage (Conceptual)
- Native-first approach using custom objects such as Prometheion_User_Risk__c, Prometheion_Permission_Snapshot__c, Prometheion_Permission_Lineage__c, Prometheion_Change_Event__c.
- Fields capture risk scores/flags, effective permission snapshots, permission lineage sources, change events, and optional hashed sensitive data.

## 8. Algorithms & Implementation Sketch
### Effective Permission Resolution (High-Level)
1. Query all Users, Profiles, Permission Sets, and Assignments.
2. For each user: start with Profile permissions, overlay Permission Set/Group permissions, resolve CRUD/FLS per object/field.
3. Store results in Prometheion_Permission_Snapshot__c.

**Example SOQL snippets:**
- Permission set assignments: `SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment`
- Object permissions: `SELECT ParentId, SObjectType, PermissionsCreate, PermissionsRead, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM ObjectPermissions`

### Risk Score Calculation (Pseudo-code)
- Base weights:
  - ModifyAllData (+25), ViewAllData (+15), AuthorApex (+10), CustomizeApplication (+10)
  - Sensitive objects (Account, Contact, Case, CustomPII__c): ModifyAll (+10), Edit (+5)
  - Integration user + API access (+15)
- Normalize to 0–100; weights configurable via custom metadata.

### Outlier Detection (Simple v1)
- For each peer group, compute average and standard deviation of risk scores.
- Mark user as outlier if risk > avg + 2*stdDev or num permission sets > group median + X (configurable).

## 9. Architecture
- Batch Apex for full scans; Scheduled Apex for daily scans.
- Tooling/REST API via Named Credentials as needed for metadata and Setup Audit Trail access.
- Lightning App with tabs: User Risk, Weekly Changes, Settings (risk weights).
- Future refactor: external worker service for analysis.

## 10. Security, Privacy, and Compliance
- App is read-only; no DML against core Salesforce security artifacts.
- Least privilege via dedicated integration user with read-only Setup access.
- Configurable storage: option to hash sensitive flags; support data export and deletion on request.

## 11. Rollout & Phasing
- **Phase 1 (Weeks 1–4):** Implement data ingestion/snapshot, build risk scoring service, create basic User Risk list view.
- **Phase 2 (Weeks 5–8):** Add inheritance maps, ingest Setup Audit Trail with weekly view, add configuration UI for risk weights/toxic combos, harden performance and security.

## 12. What You Can Do With This Now
- Provide this PRD to developers/partners for implementation guidance.
- Use as a prompt skeleton (e.g., generate Apex classes, custom objects, Lightning pages for Phase 1).
- Future options: convert into a repo scaffold/class design or a CISO-facing one-pager.
