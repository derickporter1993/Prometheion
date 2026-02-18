# Elaro

**Enterprise Compliance Automation for Salesforce — Multi-framework drift detection, AI-powered risk analysis, automated evidence collection, and real-time remediation for regulated organizations.**

_Current: v3.0.0 — Spring '26 | API v66.0 | 2GP Managed Package_

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Salesforce API](https://img.shields.io/badge/Salesforce-v66.0-blue.svg)](https://developer.salesforce.com)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-success.svg)](.github/workflows)
[![Code Quality](https://img.shields.io/badge/Code%20Quality-Passing-brightgreen.svg)](.github/workflows/elaro-ci.yml)
[![Security Scan](https://img.shields.io/badge/Security-Scanned-blue.svg)](.github/workflows/elaro-ci.yml)
[![Test Coverage](https://img.shields.io/badge/Coverage-85%25+-success.svg)](force-app/main/default/classes)

[Quick Start](#quick-start) · [Features](#features) · [Compliance Frameworks](#supported-compliance-frameworks) · [Architecture](#architecture) · [Documentation](#documentation)

</div>

---

## What is Elaro?

Elaro is a **2GP managed package** for the Salesforce AppExchange that turns your org into a continuously monitored, audit-ready compliance platform. It automates the work that compliance teams spend weeks doing manually — detecting configuration drift, scoring risk across regulatory frameworks, collecting audit evidence, and remediating violations.

Elaro covers **14 compliance frameworks** out of the box, with dedicated service classes, automated scanners, and framework-specific scoring for each one. It doesn't just detect problems — it explains *why* they matter, suggests fixes, and can auto-remediate common violations with a single click.

---

## Who It's For

Elaro is built for **regulated organizations running Salesforce**:

- **Healthcare** — HIPAA Privacy/Security Rules, PHI protection, breach notification tracking
- **Financial Services** — SOC 2, PCI-DSS, GLBA, FINRA, SEC Cybersecurity, SOX compliance
- **Government & Defense** — FedRAMP, CMMC 2.0, NIST controls
- **EU-Regulated Organizations** — GDPR, NIS2, DORA, EU AI Act
- **Any Regulated Org** — ISO 27001, CCPA, AI Governance (NIST AI RMF)

If you're spending weeks preparing for audits, manually reviewing permissions, or can't explain recent configuration changes — Elaro is for you.

---

## Features

### Compliance Scoring Engine

Multi-framework compliance scoring with weighted risk factors across every supported framework. Scores update in real-time as your org configuration changes.

| Factor | Weight | What It Measures |
|---|---|---|
| Permission Sprawl | 30% | Users with elevated access (ModifyAllData, ViewAllData) |
| Audit Trail Coverage | 25% | Objects with Field History Tracking enabled |
| Configuration Drift | 20% | Unreviewed high-risk changes in the last 30 days |
| Encryption Status | 15% | Shield Platform Encryption on PHI/PII fields |
| Policy Compliance | 10% | OWD settings, session timeout, password policy |

Each framework applies additional framework-specific scoring: HIPAA weighs PHI field exposure, PCI-DSS penalizes unencrypted cardholder data (+4.0 risk), GDPR focuses on personal data protection, and so on.

### Configuration Drift Detection

Real-time monitoring of Salesforce metadata changes via Platform Events and scheduled Setup Audit Trail polling:

- Profile and Permission Set modifications
- Sharing Rule and OWD changes
- Object and Field-Level Security updates
- Flow, Apex, and automation deployments
- Connected App and integration changes
- Session and security setting modifications

High-risk changes trigger multi-channel alerts with AI-generated risk analysis explaining the compliance impact.

### AI-Powered Compliance Intelligence

- **Compliance Copilot** — Natural language interface for compliance queries ("Why did my score drop?", "Show me all risky flows touching PII"). Backed by Claude API integration via Named Credential
- **Change Advisor** — Analyzes proposed changes *before* they happen and returns score deltas with safer alternatives
- **Risk Predictor** — Einstein-based risk prediction for compliance violations
- **Root Cause Analysis** — AI-powered event chain analysis to identify root causes of compliance events within 24-hour windows
- **Natural Language Query** — Converts plain English to secure SOQL against whitelisted compliance objects
- **Reasoning Engine** — Compliance adjudication using Big Object graph data with deterministic hashing for audit integrity

### Automated Remediation

- **Quick Actions** — One-click fixes for the most common compliance violations
- **Remediation Suggestions** — AI-assisted remediation with confidence scoring and auto-remediation payloads
- **Remediation Orchestrator** — Executes actions: revoke permissions, lock users, notify managers, create cases, quarantine data, force logout, disable API access
- **Rollback Support** — Failed remediations can be rolled back with full audit trail

### Audit Evidence Collection & Export

- **Automated Evidence Gathering** — Collects compliance evidence by framework and date range
- **Audit Package Generator** — Creates complete audit packages with associated evidence items
- **Export Formats** — PDF reports (with SHA-256 integrity hash), CSV, JSON
- **Blockchain Anchoring** — Tamper-proof evidence via OriginStamp API integration
- **Legal Document Generation** — Attestation documents for compliance frameworks
- **Scheduled Delivery** — Automated recurring delivery of audit packages to stakeholders via email, Slack, or shareable links

### Event Monitoring & Shield Integration

Deep integration with Salesforce Shield Event Monitoring:

- **Real-Time Processing** — Processes Shield events as they happen with risk scoring (CRITICAL at 95+, HIGH at 80+)
- **Historical Batch Processing** — Batch ingestion of historical EventLogFiles with heap limit protection
- **Event Correlation Engine** — Detects multi-step attack sequences using Custom Metadata correlation rules
- **Breach Pattern Matching** — Statistical analysis of event frequency, severity, and temporal proximity
- **Threat Detection** — Identifies inactive accounts, suspicious permission grants, and account hierarchy anomalies

### Multi-Channel Alert System

Compliance alerts delivered across every channel your team uses:

| Channel | Integration |
|---|---|
| Email | Native Salesforce email with daily/weekly digests |
| Slack | Webhook integration with rich Block Kit messages |
| Microsoft Teams | Adaptive Card notifications via Incoming Webhooks |
| PagerDuty | Events API v2 — trigger and resolve incidents |
| ServiceNow | GRC integration — sync controls, push evidence, create incidents |
| Mobile Push | Salesforce Custom Notifications with on-call schedule integration |
| In-App Bell | Lightning notification bell |

Alerts support configurable escalation paths (Team Lead, Manager, CISO/Director), on-call rotation schedules, acknowledgment tracking, and snooze.

### Jira Integration

Bidirectional synchronization between Salesforce compliance gaps and Jira:

- Auto-create Jira issues from compliance gaps with full context
- Real-time status sync via webhooks (`jira:issue_updated`, `comment_created`)
- Bulk operations for batch compliance gap creation
- Webhook secret validation for security

### Trust Center

Public-facing compliance portal for external stakeholders:

- **Internal Admin Portal** — Manage Trust Center content and view aggregated compliance data
- **Guest-Accessible Portal** — Token-validated, expiration-controlled public links exposing only materialized `Trust_Center_View__c` data (never raw findings or evidence)
- **Access Tiers** — Public, Email-Gated, NDA-Required
- **Nightly Materialization** — Scheduled job aggregates public-safe compliance metrics

### Assessment Wizards

Guided compliance assessment workflows driven by Custom Metadata configuration:

- Multi-step wizard flows: auto-scan, attestation, evidence upload, approval, review
- Cross-framework control prefill to avoid duplicate work
- Session state persistence for interrupted assessments
- Progress tracking with visual indicators

### Performance & Operational Monitoring

- **Governor Limit Dashboard** — Real-time CPU, Heap, SOQL, DML tracking
- **API Usage Monitoring** — Daily API consumption snapshots with limit projections
- **Flow Execution Monitoring** — Track runs, faults, and performance per flow (invocable from Flows)
- **Deployment Metrics** — Deployment job tracking with test pass/fail stats
- **Performance Rule Engine** — Configurable alert rules against governor limit metrics

### Enterprise Features

- **Multi-Org Management** — Register connected orgs, sync compliance policies, aggregate cross-org status
- **Data Residency Validation** — Map countries to regions (US, EU, APAC) and validate data processing compliance
- **Industry Benchmarking** — Compare org scores against industry benchmarks (Healthcare, Finance) with maturity levels (Ad Hoc through Optimized)
- **Compliance Graph** — D3.js visualization of framework-to-policy relationships, gap linkages, and impact analysis
- **Daily Score Snapshots** — Historical compliance score trends across all frameworks

---

## Supported Compliance Frameworks

Elaro includes dedicated service classes, automated controls, and framework-specific scoring for each framework:

### HIPAA

Full coverage of 45 CFR Parts 164.308, 164.310, 164.312:

- **Privacy Rule** (164.500-534) — Minimum-necessary PHI access enforcement, disclosure tracking, access pattern monitoring
- **Security Rule** (164.312) — Technical safeguards: access controls, audit controls, integrity, transmission security
- **Audit Controls** (164.312(b)) — Log analysis, suspicious access detection (100-access threshold), 6-year retention
- **Breach Notification** (164.400-414) — 4-factor risk analysis, 60-day notification deadline tracking, 500-individual HHS threshold for immediate reporting
- **Breach Deadline Monitor** — Daily scheduled job with 14-day WARNING and 7-day CRITICAL alerts

### SOC 2 Type II

Trust Service Criteria CC6-CC9:

- **Access Reviews** (CC6.2/CC6.3) — Automated quarterly/annual reviews, stale login detection (90 days), high-risk permission identification
- **Change Management** (CC6.1-CC6.8) — 30-day lookback metadata change monitoring, change control validation
- **Data Retention** (CC6.6/CC6.7) — Retention policy enforcement, 6-year audit log retention
- **Incident Response** (CC7.x) — SLA enforcement: CRITICAL 1 hr, HIGH 4 hr, MEDIUM 24 hr, LOW 72 hr

### GDPR

Articles 5-34 coverage:

- **Data Subject Rights** (Art. 15-20) — Access, rectification, erasure ("Right to be Forgotten"), and data portability with machine-readable JSON export
- **Consent Management** (Art. 6-7, 13-14) — Legal basis tracking, consent recording/withdrawal, information notices
- **Records of Processing Activities** (Art. 30) — Data inventory, processing activity tracking, third-party recipient management
- **Breach Notification** (Art. 33-34) — 72-hour supervisory authority notification deadline, data subject communication
- **Retention Enforcement** (Art. 5(1)(e)) — Automated batch deletion of expired data processing activities
- **Consent Expiration** — Daily batch monitoring with 30-day renewal reminders

### PCI-DSS

Requirements 3, 4, 7-10:

- **Data Protection** (Req. 3-4) — Encryption and tokenization validation for stored and transmitted cardholder data
- **Data Masking** (Req. 3.2-3.3) — PAN masking (last 4 digits only), CVV non-storage enforcement
- **Access Control** (Req. 7-9) — Role-based access control (RBAC), credential lifecycle management
- **Audit Trail** (Req. 10) — Immutable logging of all cardholder data access via Platform Events
- **Access Alerts** — Threshold-based detection: failed attempts (3), after-hours access, bulk access (50+ records)

### CCPA

California Consumer Privacy Act (1798.100-125):

- **Right to Know** (1798.100) — Consumer data inventory and export with categorized personal information
- **Right to Delete** (1798.105) — Deletion request processing with cascading record removal
- **Right to Opt-Out** (1798.120) — Global Privacy Control (GPC) signal support, "Do Not Sell" list, vendor synchronization
- **Non-Discrimination** (1798.125) — Tracking and compliance monitoring
- **SLA Monitor** — Daily scheduled job tracking 45-day response deadline with 7-day and 3-day alerts

### GLBA

Gramm-Leach-Bliley Act (16 CFR Part 313):

- **Privacy Notice Distribution** — Initial and annual privacy notice management
- **Opt-Out Tracking** — 30-day opt-out deadline monitoring
- **Annual Notice Batch** — Automated scheduled renewal processing on business days

### ISO 27001

Annex A.9 Access Control and related controls:

- **Access Reviews** (A.9.2.1-A.9.2.6) — Quarterly reviews (90 days), annual certifications (365 days), dormant account detection
- **Segregation of Duties** — SoD violation detection by analyzing conflicting permission set assignments
- **Dormant Account Alerts** — Daily detection of accounts with no login for 90+ days (warning at 60 days)

### FINRA

Rules 3110, 4511, 4370:

- **Supervisory System** (Rule 3110) — Written supervisory procedures and internal inspection controls
- **Books and Records** (Rule 4511) — Records retention compliance
- **Business Continuity** (Rule 4370) — BCP plan controls

### SEC Cybersecurity

Regulation S-K Item 106 and Form 8-K Item 1.05:

- **Materiality Assessment** — Full lifecycle (Draft through Disclosure), 4-business-day Form 8-K filing deadline calculation
- **Disclosure Workflow** — 7-stage workflow: Drafting, Legal Review, CFO Review, CEO Approval, Board Review, Ready to File, Filed
- **Board Governance** — Annual 10-K governance reports covering risk management, strategy, board oversight, management role
- **Incident Timeline** — Milestone tracking with SLAs: Detection-to-Containment (4 hr), Detection-to-Investigation (24 hr), Containment-to-Notification (72 hr)
- **Dedicated LWC Suite** — Dashboard, disclosure form, materiality card, incident timeline components

### AI Governance

EU AI Act + NIST AI RMF v1.0:

- **AI Detection Engine** — Scans org metadata for Einstein and GenAI components (MLPredictionDefinition, Bot, GenAiFunction, GenAiPlanner)
- **Risk Classification** — EU AI Act Annex III categories (Unacceptable, High, Limited, Minimal) using Custom Metadata rules with Platform Cache
- **License Detection** — Identifies users with AI-related permissions across all permission sets
- **Audit Trail Scanner** — Tracks AI-related configuration changes in SetupAuditTrail
- **AI Settings Management** — Configurable confidence thresholds, auto-remediation flags, human approval requirements

### Additional Frameworks

- **FedRAMP** — Referenced in compliance scoring engine
- **CMMC 2.0** — Team 1 sovereign infrastructure module
- **NIS2** — Team 1 sovereign infrastructure module
- **DORA** — Team 1 sovereign infrastructure module
- **NIST** — Referenced in compliance scoring engine

---

## Architecture

### Package Structure

Elaro ships as **two separate 2GP managed packages**:

| Package | Namespace | Path | Description |
|---|---|---|---|
| Elaro | — | `force-app/` | Main compliance platform |
| Elaro Health Check | — | `force-app-healthcheck/` | Standalone security posture scanner |

### Health Check Package

A standalone AppExchange package that scans an org's security posture across five dimensions:

| Scanner | Weight | What It Scans |
|---|---|---|
| Security Health Check | 40% | Native Salesforce SecurityHealthCheck via Tooling API |
| MFA Compliance | 20% | LoginHistory MFA adoption percentage |
| Profile Permissions | 15% | Over-provisioned ModifyAllData/ViewAllData access |
| Session Settings | 15% | Timeout, HTTPS enforcement, IP locking, XSS protection |
| Audit Trail | 10% | High-risk administrative changes |

Results are aggregated by `ScoreAggregator` into a weighted composite score with prioritized remediation recommendations.

### Core Architecture Components

| Component | Role |
|---|---|
| `ComplianceServiceFactory` | Factory pattern for framework service resolution — caches singletons for `IRiskScoringService`, `IAccessControlService`, `IBreachNotificationService` |
| `IComplianceModule` | Interface all framework modules implement: `getFrameworkName()`, `getControls()`, `calculateComplianceScore()` |
| `ComplianceServiceBase` | Abstract base class providing common gap creation, evidence collection, audit logging |
| `ElaroLogger` | Structured logging via Platform Events (Publish Immediately — survives rollbacks) |
| `ElaroSecurityUtils` | Defense-in-depth security utilities: CRUD/FLS validation, access checks |
| `ElaroConstants` | Centralized constants: framework names, severity levels, thresholds, API versions |
| `ComplianceTestDataFactory` | Shared test data factory for all compliance test classes |

### Data Model

**Custom Objects (54+):**

- **Compliance Core** — `Compliance_Score__c`, `Compliance_Gap__c`, `Compliance_Evidence__c`, `Compliance_Assessment_Session__c`
- **HIPAA** — `HIPAA_Breach__c`
- **GDPR** — `GDPR_Breach__c`, `GDPR_Erasure_Request__c`, `Consent__c`, `Data_Processing_Activity__c`, `Third_Party_Recipient__c`
- **CCPA** — `CCPA_Request__c`
- **PCI-DSS** — (uses Platform Events for access logging)
- **SEC** — `Materiality_Assessment__c`, `Disclosure_Workflow__c`, `Board_Governance_Report__c`, `Incident_Timeline__c`, `SEC_Control_Mapping__c`
- **AI Governance** — `AI_System_Registry__c`, `AI_Human_Oversight_Record__c`, `AI_RMF_Mapping__c`
- **GLBA** — `Privacy_Notice__c`
- **Audit** — `Elaro_Audit_Package__c`, `Elaro_Evidence_Item__c`, `Elaro_Evidence_Anchor__c`, `Elaro_Audit_Log__c`
- **Alerts** — `Alert__c`, `Elaro_Alert_Config__c`, `Performance_Alert_History__c`, `Elaro_Escalation_Path__c`, `Elaro_On_Call_Schedule__c`
- **Integration** — `Elaro_Jira_Settings__c`, `Elaro_Connected_Org__c`, `Integration_Error__c`
- **Operations** — `Metadata_Change__c`, `Access_Review__c`, `Remediation_Suggestion__c`, `Security_Incident__c`, `Holiday__c`
- **Monitoring** — `API_Usage_Snapshot__c`, `Flow_Execution__c`, `Deployment_Job__c`
- **Trust Center** — `Trust_Center_Link__c` (+ `Trust_Center_View__c`)
- **Big Object** — `Elaro_Compliance_Graph__b` (long-term audit retention via deterministic node hashing)

**Platform Events (11):**

`ComplianceAlert__e`, `ConfigurationDrift__e`, `Elaro_Alert_Event__e`, `Elaro_Score_Result__e`, `BreachIndicator__e`, `Performance_Alert__e`, `PCI_Access_Event__e`, `GDPR_Erasure_Event__e`, `GDPR_Data_Export_Event__e`, `CCPA_Request_Event__e`, `GLBA_Compliance_Event__e`

**Custom Metadata Types (10):**

`Compliance_Control__mdt`, `Compliance_Policy__mdt`, `Compliance_Action__mdt`, `Correlation_Rule__mdt`, `AI_Classification_Rule__mdt`, `Assessment_Wizard_Config__mdt`, `Framework_Config__mdt`, `Executive_KPI__mdt`, `Elaro_Scheduler_Config__mdt`, `Elaro_API_Config__mdt`

### LWC Components

**Main Package (53 components):**

| Category | Components |
|---|---|
| Command Center | `complianceCommandCenter`, `complianceDashboard`, `elaroDashboard`, `frameworkSelector` |
| Compliance Views | `complianceScoreCard`, `complianceGapList`, `complianceTimeline`, `complianceTrendChart`, `complianceGraphViewer`, `complianceContextSidebar`, `complianceNotificationFeed`, `complianceActionCard` |
| AI & Copilot | `complianceCopilot`, `elaroCopilot`, `elaroAiSettings` |
| SEC Cybersecurity | `secDisclosureDashboard`, `secDisclosureForm`, `secMaterialityCard`, `secIncidentTimeline` |
| Assessment | `assessmentWizard`, `assessmentProgressTracker`, `wizardStep`, `crossFrameworkPrefill`, `elaroAuditWizard` |
| Analytics | `elaroComparativeAnalytics`, `elaroExecutiveKPIDashboard`, `executiveKpiDashboard`, `elaroDrillDownViewer`, `elaroDynamicReportBuilder`, `elaroTrendAnalyzer`, `riskHeatmap`, `controlMappingMatrix`, `elaroROICalculator` |
| Evidence & Audit | `elaroAuditPackageBuilder`, `auditReportGenerator`, `reportSchedulerConfig` |
| Monitoring | `systemMonitorDashboard`, `apiUsageDashboard`, `flowExecutionMonitor`, `deploymentMonitorDashboard`, `performanceAlertPanel`, `elaroEventMonitor`, `elaroEventExplorer`, `elaroScoreListener`, `pollingManager` |
| Jira | `jiraCreateModal`, `jiraIssueCard` |
| Alerts & Operations | `escalationPathConfig`, `onCallScheduleManager`, `remediationSuggestionCard` |
| Setup | `elaroSetupWizard`, `elaroReadinessScore` |
| Utilities | `utils` |

**Health Check Package (6 components):**

`healthCheckDashboard`, `healthCheckScoreGauge`, `healthCheckRiskTable`, `healthCheckRecommendations`, `healthCheckMfaIndicator`, `healthCheckCtaBanner`

### Named Credentials

| Name | Purpose |
|---|---|
| `Elaro_Claude_API` | Anthropic Claude API for AI-powered compliance analysis |
| `Jira_API` | Jira REST API v3 for bidirectional issue sync |
| `Slack_Webhook` | Slack Incoming Webhook for alert delivery |
| `Teams_Webhook` | Microsoft Teams Incoming Webhook for alert delivery |

### Scheduled Jobs

Elaro includes 15+ schedulable jobs for continuous compliance monitoring:

| Job | Frequency | Purpose |
|---|---|---|
| `ConfigDriftDetector` | Every 5 min | Detect configuration changes via SetupAuditTrail |
| `ElaroAuditTrailPoller` | Every 5 min | Publish audit trail changes as Platform Events |
| `ComplianceScoreSnapshotScheduler` | Daily 1 AM | Capture compliance scores for trend analysis |
| `ElaroDormantAccountAlertScheduler` | Daily 5 AM | Identify dormant user accounts (90+ days) |
| `ElaroDailyDigest` | Daily 6 AM | Send daily compliance summary to stakeholders |
| `ElaroGLBAAnnualNoticeScheduler` | Daily 6 AM | Process GLBA annual privacy notices |
| `ElaroCCPASLAMonitorScheduler` | Daily 8 AM | Monitor CCPA 45-day response deadlines |
| `ConsentExpirationScheduler` | Daily 8 AM | GDPR consent expiration monitoring |
| `BreachDeadlineMonitor` | Daily | HIPAA 60-day breach notification deadlines |
| `RetentionEnforcementScheduler` | Weekly Sun 2 AM | GDPR data retention enforcement |
| `AccessReviewScheduler` | Monthly | SOC 2 / HIPAA periodic access reviews |
| `ElaroISO27001QuarterlyScheduler` | Quarterly | ISO 27001 access reviews and certifications |
| `WeeklyScorecardScheduler` | Weekly | Slack/Teams compliance scorecard delivery |
| `TrustCenterDataService` | Nightly | Materialize public-safe compliance metrics |
| `MobileAlertEscalator` | On-demand | Escalate unacknowledged mobile alerts |

### REST Endpoints

| Endpoint | Purpose |
|---|---|
| `POST /elaro/score/callback` | Receive compliance scores from external services (API key + HMAC validation) |
| `POST /jira/webhook/*` | Handle Jira webhook events for bidirectional sync |

### Triggers

| Trigger | Fires On | Purpose |
|---|---|---|
| `ElaroAlertTrigger` | `ComplianceAlert__e` | Route compliance alerts to channels |
| `ElaroConsentWithdrawalTrigger` | Consent events | Process GDPR consent withdrawal |
| `ElaroEventCaptureTrigger` | `Elaro_Alert_Event__e` | Capture and index compliance events |
| `ElaroPCIAccessAlertTrigger` | `PCI_Access_Event__e` | Detect PCI-DSS access violations |
| `PerformanceAlertEventTrigger` | `Performance_Alert__e` | Process performance threshold alerts |

---

## Technology Stack

| Layer | Technology |
|---|---|
| Backend | Apex (Salesforce API v66.0, Spring '26) |
| Frontend | Lightning Web Components (LWC) |
| Testing | Jest (LWC) + Apex Test Classes |
| Linting | ESLint v9 with LWC plugin |
| Formatting | Prettier |
| Monorepo | Turborepo (`platform/`) |
| Node.js | v20.0.0+ required |
| AI | Anthropic Claude API, Salesforce Einstein |

### Codebase Stats

| Metric | Count |
|---|---|
| Apex Classes (main) | 349 (177 production + 172 test) |
| Apex Classes (Health Check) | 21 (13 production + 8 test) |
| LWC Components | 59 (53 main + 6 Health Check) |
| Custom Objects | 54+ |
| Platform Events | 11 |
| Custom Metadata Types | 10 |
| Big Objects | 1 (`Elaro_Compliance_Graph__b`) |
| Apex Triggers | 5 |
| Permission Sets | 10 (8 main + 2 Health Check) |
| Named Credentials | 4 |
| Scheduled Jobs | 15+ |

---

## Quick Start

### Prerequisites

- Salesforce org (Production, Sandbox, or Scratch Org)
- Salesforce CLI (`sf`) installed
- Node.js v20.0.0+
- DevHub org authenticated (for scratch orgs)

### Installation

#### Option 1: Deploy to Existing Org

```bash
# Clone the repo
git clone https://github.com/derickporter1993/elaro.git
cd elaro

# Install dependencies
npm install

# Authenticate to your Salesforce org
sf org login web --alias myorg

# Deploy the main package
sf project deploy start --target-org myorg

# Assign permissions
sf org assign permset --name Elaro_Admin --target-org myorg

# Open the org
sf org open --target-org myorg
```

#### Option 2: Create Scratch Org

```bash
# Run the initialization script
./scripts/orgInit.sh

# This will:
# - Create a scratch org with required features
# - Push source code
# - Assign Elaro_Admin permission set
# - Open the org in your browser
```

### Permission Sets

Assign permission sets based on user role:

| Permission Set | Role | Access |
|---|---|---|
| `Elaro_Admin` | Compliance Admin | Full read/write access to all Elaro objects, classes, and tabs |
| `Elaro_Admin_Extended` | Super Admin | Extended admin capabilities |
| `Elaro_User` | Compliance User | Read/execute access to dashboards and reports |
| `Elaro_Auditor` | External Auditor | Read-only access to compliance data and evidence |
| `Elaro_SEC_Admin` | SEC Compliance Lead | SEC disclosure workflow management |
| `Elaro_AI_Governance_Admin` | AI Governance Lead | AI system registry and classification management |
| `Elaro_AI_Governance_User` | AI Governance Viewer | Read access to AI governance data |
| `Elaro_Health_Check_Admin` | HC Admin | Health Check full access |
| `Elaro_Health_Check_User` | HC User | Health Check read/execute access |

### Run Your First Compliance Scan

1. Navigate to **Elaro** in the App Launcher
2. Click **Run Baseline Scan** on the Command Center
3. View your **Compliance Score** across all frameworks
4. Review **prioritized gaps** with AI-generated remediation suggestions
5. **Export audit evidence** (PDF, CSV, or JSON) for your compliance team

---

## Configuration

### Alert Integrations

#### Slack

1. Create a Slack Webhook URL
2. Setup > Named Credentials > `Slack_Webhook` > set your webhook URL
3. Alerts will automatically route to Slack for CRITICAL and HIGH severity

#### Microsoft Teams

1. Create an Incoming Webhook in your Teams channel
2. Setup > Named Credentials > `Teams_Webhook` > set your webhook URL

#### PagerDuty

Configure via `callout:PagerDuty_API` Named Credential with your Events API v2 integration key.

#### Jira

1. Setup > Named Credentials > `Jira_API` > configure your Jira Cloud instance URL and API token
2. Configure `Elaro_Jira_Settings__c` with your project key and webhook secret
3. Register the webhook URL (`/jira/webhook/*`) in your Jira project settings

#### AI (Claude API)

1. Setup > Named Credentials > `Elaro_Claude_API` > set your Anthropic API key
2. Configure `Elaro_AI_Settings__c` for confidence thresholds and auto-remediation preferences

### Custom Settings

| Setting | Description |
|---|---|
| `Elaro_AI_Settings__c` | AI confidence thresholds, auto-remediation flags, human approval requirements |
| `Elaro_Alert_Config__c` | Alert routing and severity thresholds |
| `Elaro_Jira_Settings__c` | Jira project key, webhook secret, sync preferences |
| `Elaro_Feature_Flags__c` | Per-feature kill switches for subscriber orgs |
| `CCX_Settings__c` | General platform configuration |

---

## Development

### Commands

```bash
# Code Quality
npm run fmt              # Format code with Prettier
npm run fmt:check        # Check formatting
npm run lint             # Run ESLint (max 3 warnings)
npm run lint:fix         # Auto-fix lint issues

# Testing
npm run test:unit        # Run LWC Jest tests
npm run test:unit:watch  # Watch mode for TDD
sf apex run test -o <org> -c   # Run Apex tests with coverage

# Pre-commit (runs automatically via Husky)
npm run precommit        # fmt:check + lint + test:unit

# Salesforce Deployment
sf project deploy start -o <org>             # Deploy to org
sf project deploy start -o <org> --dry-run   # Validate only

# Platform CLI (TypeScript monorepo)
cd platform && npm install && npm run build
```

### Project Structure

```
elaro/
├── force-app/main/default/              # Main Elaro 2GP managed package
│   ├── classes/                         # 349 Apex classes (177 production + 172 test)
│   ├── lwc/                             # 53 LWC components
│   ├── objects/                         # 54+ custom objects, platform events, big objects
│   ├── customMetadata/                  # Custom Metadata Type records
│   ├── permissionsets/                  # 8 Permission Sets
│   ├── labels/                          # Custom Labels (i18n)
│   ├── namedCredentials/                # Claude API, Jira, Slack, Teams
│   ├── flexipages/                      # Lightning App Pages
│   ├── tabs/                            # Custom Tabs
│   └── triggers/                        # 5 Platform Event triggers
├── force-app-healthcheck/main/default/  # Health Check separate 2GP (elaroHC)
│   ├── classes/                         # 21 Apex classes (13 production + 8 test)
│   ├── lwc/                             # 6 LWC components
│   ├── permissionsets/                  # 2 Permission Sets
│   ├── labels/                          # Health Check labels
│   └── tabs/                            # Health Check tabs
├── platform/                            # TypeScript monorepo (Turborepo)
│   └── packages/
│       ├── cli/                         # elaro CLI
│       ├── sf-client/                   # Salesforce API client
│       ├── types/                       # Shared TypeScript types
│       └── masking/                     # Data masking utilities
├── scripts/                             # Automation scripts
├── config/                              # Scratch org definition
├── examples/                            # Sample compliance reports
├── docs/                                # Documentation
└── .github/workflows/                   # CI/CD pipeline
```

### CI/CD Pipeline

GitHub Actions runs on push to `main`, `develop`, `release/*`, `claude/*`:

1. **code-quality** — Format check, linting, security audit
2. **unit-tests** — LWC Jest tests
3. **security-scan** — Salesforce Code Analyzer with AppExchange selectors
4. **validate-metadata** — Directory structure validation
5. **cli-build** — Platform TypeScript build
6. **build-success** — Final deployment readiness check

### Quality Gates

- Code Analyzer v5: Zero HIGH severity findings
- Jest tests: All passing
- Apex tests: 85%+ coverage per class
- WCAG 2.1 AA: Screen reader and keyboard navigation verified

---

## Two-Team Build Structure

| Team | Focus | Modules |
|---|---|---|
| Team 1 — Sovereign Infrastructure | Backend engine and cross-cutting concerns | Async Framework, CMMC 2.0, Rule Engine, Orchestration, NIS2/DORA |
| Team 2 — User-Facing Modules | Dashboards, wizards, and framework-specific UIs | Health Check, Command Center, Event Monitoring, Assessment Wizards, SEC Module, AI Governance, Trust Center |

---

## FAQ

**Does Elaro require Shield Platform Encryption?**
No, but Elaro flags missing encryption as a compliance risk. Shield is strongly recommended for HIPAA and PCI-DSS.

**Does Elaro store data outside Salesforce?**
No. All data stays in your Salesforce org. External integrations (Slack, Jira, PagerDuty, Teams, ServiceNow, Claude API) only send alerts or receive webhooks — no compliance data is stored externally.

**Can I use Elaro in a sandbox?**
Yes. Elaro works in Production, Sandbox, Scratch Orgs, and Developer Edition orgs.

**Can I customize compliance scoring?**
Yes. Compliance controls, policies, and actions are driven by Custom Metadata (`Compliance_Control__mdt`, `Compliance_Policy__mdt`, `Compliance_Action__mdt`), which you can configure per org.

**What about the Health Check package?**
Health Check is a separate 2GP managed package (`elaroHC` namespace) that can be installed independently for organizations that only need security posture scanning without full compliance automation.

---

## Documentation

### Installation & Setup

- [Installation Guide](docs/INSTALLATION_GUIDE.md) — Complete installation with step-by-step configuration
- [External Services Guide](docs/EXTERNAL_SERVICES.md) — Claude AI, Slack, PagerDuty, ServiceNow, Teams integration setup

### Security & Testing

- [PagerDuty Security Review](docs/PAGERDUTY_INTEGRATION_SECURITY_REVIEW.md) — Security findings and remediation
- [Scanner Report Bundle](docs/SCANNER_REPORT_BUNDLE.md) — AppExchange Code Analyzer guide
- [Compliance Frameworks Reference](docs/COMPLIANCE_FRAMEWORKS_CODE_REFERENCE.md) — Framework code patterns

### Development

- [Contributing Guide](CONTRIBUTING.md) — Development workflow, coding standards, testing requirements
- [Changelog](CHANGELOG.md) — Release notes and version history
- [Technical Deep Dive](TECHNICAL_DEEP_DIVE.md) — Architecture and implementation details
- [API Reference](API_REFERENCE.md) — API documentation and code examples
- [Claude.md](CLAUDE.md) — AI assistant guide and coding standards

### Support

- [Report Issues](https://github.com/derickporter1993/elaro/issues) — Bug reports and feature requests
- [Discussions](https://github.com/derickporter1993/elaro/discussions) — Community Q&A

---

## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for complete guidelines.

```bash
# 1. Fork and clone
git clone https://github.com/derickporter1993/elaro.git
cd elaro

# 2. Install dependencies
npm install

# 3. Create a scratch org
./scripts/orgInit.sh

# 4. Run quality checks before committing
npm run precommit
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

_Elaro — Enterprise compliance automation for Salesforce._
