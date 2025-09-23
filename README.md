# OpsGuardian™

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Salesforce API](https://img.shields.io/badge/API-62.0+-blue.svg)](#1-overview)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-yellow.svg)](.github/workflows)

OpsGuardian™ is a Salesforce-native monitoring and compliance framework that goes beyond Event Monitoring and Shield. It delivers real-time observability, AI diagnostics, and automation to help regulated organizations (finance, healthcare, government) maintain compliance, prevent failures, and scale securely.

---

## Table of Contents
1. [Overview](#1-overview)
2. [What It Does](#2-what-it-does)
3. [Use Cases & Personas](#3-use-cases--personas)
4. [Core Features](#4-core-features)
5. [Tech Stack](#5-tech-stack)
6. [Architecture](#6-architecture)
7. [Security Model and Data Access](#7-security-model-and-data-access)
8. [Data Privacy, Retention, and Erasure](#8-data-privacy-retention-and-erasure)
9. [Configuration Guide](#9-configuration-guide)
10. [Ingest API (Hub-and-Spoke)](#10-ingest-api-hub-and-spoke)
11. [Telemetry Schema Reference](#11-telemetry-schema-reference)
12. [Threat Model & Trust Boundaries](#12-threat-model--trust-boundaries)
13. [Performance & Scalability](#13-performance--scalability)
14. [Performance Benchmarks](#14-performance-benchmarks)
15. [Operations Runbook](#15-operations-runbook)
16. [Advanced Integration Scenarios](#16-advanced-integration-scenarios)
17. [Security Testing & Audit](#17-security-testing--audit)
18. [Localization & Internationalization](#18-localization--internationalization)
19. [Documentation & Support](#19-documentation--support)
20. [Installation](#20-installation)
21. [Usage](#21-usage)
22. [Plugin SDK](#22-plugin-sdk)
23. [Release Management & Rollback](#23-release-management--rollback)
24. [Upgrade & Migration](#24-upgrade--migration)
25. [Troubleshooting & FAQ](#25-troubleshooting--faq)
26. [Quality Gates](#26-quality-gates)
27. [License](#27-license)
28. [Appendix](#28-appendix)

---

## 1. Overview
- Distribution: Second-Generation Managed Package (2GP) targeted for AppExchange  
- API Version: 62.0+  
- Supported Orgs: Scratch, Sandbox, Developer Edition, Production  
- Status: Production-ready; AppExchange submission in progress

OpsGuardian provides:
- Real-time monitoring of governor limits, Flows, transactions, and API calls
- AI-assisted diagnostics (Einstein + external LLM)
- Policy-driven rules via Custom Metadata (CMDT)
- Event-driven alerts to Slack, Jira, and webhooks

---

## 2. What It Does
- Captures operational events in `OpsGuardian_History__c`
- Analyzes performance and compliance risks in real time
- Publishes alerts via Platform Events for downstream actions
- Surfaces dashboards and LWC tiles for live operations visibility
- Automates remediation via Flows and Invocable Apex

---

## 3. Use Cases & Personas

### Personas
- Salesforce Admin (Ops): needs live limits, failing flows, rapid remediation
- Security/Compliance: needs tamper-evident logs, retention, audits
- Engineering/DevOps: needs multi-org telemetry, CI gates, APIs

### Representative Use Cases
- Prevent Flow outages: detect spike in Flow faults, auto-create Jira, trigger rollback Flow
- Prove compliance: export encrypted `OpsGuardian_History__c` for audit in minutes
- Centralize telemetry: aggregate many orgs into one hub; alert teams by severity

---

## 4. Core Features
- Governance: detects Flow faults, governor overages, API misuse
- Compliance: Shield Platform Encryption plus full CRUD/FLS enforcement
- AI Diagnostics: GPT + Einstein hybrid scoring with remediation guidance
- Plugins: extensible connectors for Slack, Jira, webhooks
- Multi-Org: hub-and-spoke REST ingest for enterprise telemetry
- Offline Resilience: LDS and LocalStorage caching for LWC tiles
- DevOps Ready: GitHub Actions, PMD/sf-scanner, Jest unit testing

---

## 5. Tech Stack

**Salesforce Platform**
- Apex, Lightning Web Components (LWC), Platform Events
- Custom Metadata Types (CMDT) for policies (`OG_Policy__mdt`)
- Shield Platform Encryption

**AI Integration**
- Einstein Prediction Builder / Next Best Action
- External LLM via OAuth Named Credentials (JWT/Client Credentials)

**DevOps**
- Salesforce DX (SFDX), GitHub Actions CI
- PMD + `sf-scanner` for static analysis
- Jest for LWC tests; Apex coverage via CLI

**Integrations**
- MuleSoft (multi-cloud ingestion)
- Plugin framework: Slack, Jira, webhooks

**Compliance**
- GDPR, SOC 2, HIPAA-ready implementation patterns

---

## 6. Architecture
```mermaid
flowchart TD
  subgraph Salesforce Org
    A[OpsGuardian LWC Tiles] --> B[Lightning App Page]
    B --> C[OpsGuardian Apex Services]
    C --> D[OpsGuardian_History__c Object]
    C --> E[Platform Events]
    C --> F[CMDT: OG_Policy__mdt]
  end

  C -->|Named Credential (JWT)| G[(External AI Service)]
  C -->|REST API Hub| H[Other Salesforce Orgs]
  C -->|Plugins| I[(Slack/Jira/Webhooks)]


⸻

7. Security Model and Data Access
	•	Record Security: WITH SECURITY_ENFORCED on SOQL; Security.stripInaccessible() on all DML
	•	Sharing: with sharing classes; row-level security respected
	•	Permissions: least-privilege via OpsGuardian_Admin and dedicated field/object perms
	•	Segregation: multi-org ingestion keyed by org/business unit; no cross-org leakage
	•	Transport: TLS 1.3; OAuth 2.0 JWT/Client-Credentials; no secrets in source

⸻

8. Data Privacy, Retention, and Erasure
	•	Retention: default 180 days, configurable in CMDT; policy-driven purge windows per object/severity
	•	Erasure: admin-initiated deletion via Flow; batch jobs purge data and anonymize residual logs
	•	Encryption: Shield at rest; TLS 1.3 in transit; KMS key rotation per Salesforce policy
	•	See /docs/compliance/ for encryption, deletion, and data-flow artifacts

⸻

9. Configuration Guide

A. Policies (CMDT)
	1.	Setup → Custom Metadata Types → OG_Policy__mdt
	2.	Create records for CPU/SOQL/DML thresholds per environment
	3.	Commit CMDT records to VCS for code review

B. OAuth Named Credential (JWT)
	1.	Setup → External Credentials → create OG_AI (JWT Bearer)
	2.	Setup → Named Credentials → create OG_AI with the AI endpoint
	3.	Assign the principal to the OpsGuardian_Admin permission set

C. Platform Events
	1.	Verify Performance_Alert__e
	2.	Subscribe via Flow or Apex Trigger to route alerts to Slack/Jira

D. Permission Sets
	•	Assign OpsGuardian_Admin to admins only
	•	Verify field-level perms on OpsGuardian_History__c

⸻

10. Ingest API (Hub-and-Spoke)

OpenAPI (excerpt)

openapi: 3.0.3
info: { title: OpsGuardian Ingest, version: 1.0.0 }
paths:
  /services/apexrest/og/v1/ingest:
    post:
      security: [{ bearerAuth: [] }]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [type, severity, timestamp]
              properties:
                type: { type: string, maxLength: 40 }
                message: { type: string, maxLength: 255 }
                severity: { type: string, enum: [Info, Warning, Critical] }
                timestamp: { type: string, format: date-time }
      responses:
        "201": { description: Created }
        "400": { description: Invalid payload }
        "401": { description: Unauthorized }
        "429": { description: Rate limited }
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

Request example

curl -X POST "$SF_URL/services/apexrest/og/v1/ingest" \
 -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
 -d '{"type":"CPU","message":"after-insert breach","severity":"Critical","timestamp":"2025-09-22T17:00:00Z"}'


⸻

11. Telemetry Schema Reference

OpsGuardian_History__c

Field API Name	Type	Purpose	FLS
Event_Type__c	Text(40)	CPU, SOQL, DML, Flow, API	R/W
Severity__c	Picklist	Info, Warning, Critical	R/W
Message__c	Text(255)	Human-readable context	R/W
Timestamp__c	DateTime	Event time (UTC)	R
Correlation_Id__c	Text(64)	Trace across systems	R/W
Source_Org_Id__c	Text(18)	Hub ingestion key	R

Flow_Execution__c

Field API Name	Type	Purpose	FLS
Flow_Api_Name__c	Text(80)	Flow identifier	R/W
InterviewId__c	Text(40)	Run instance	R
Faulted__c	Checkbox	True if failed	R
DurationMs__c	Number(9,0)	Execution time	R
RunAt__c	DateTime	Start time	R


⸻

12. Threat Model & Trust Boundaries

Goals
	•	Prevent unauthorized read/write of telemetry
	•	Prevent privilege escalation via API and UI paths
	•	Ensure logs are tamper-evident and retained per policy

Diagram

flowchart LR
  ext[External Clients] -->|JWT| API[/Apex REST Ingest/]
  subgraph Salesforce Org
    API --> S[(Named Credential, AuthZ)]
    S --> SVC[OpsGuardian Services]
    SVC --> LOG[OpsGuardian_History__c (Shield)]
    SVC --> EVT[(Platform Events)]
    SVC --> POL[CMDT Policies]
  end
  SVC --> PLG[Plugins Slack/Jira]
  classDef boundary stroke-width:2px,stroke:#555,fill:#f9f9f9;
  class S,LOG,EVT,POL boundary;

STRIDE summary
	•	Spoofing: JWT validation + audience checks
	•	Tampering: WITH SECURITY_ENFORCED, stripInaccessible, Shield
	•	Repudiation: append-only logs with correlation IDs
	•	Information Disclosure: FLS/CRUD, field-level encryption
	•	DoS: Platform Cache rate limiting (429 + Retry-After)
	•	Elevation of Privilege: least-privilege perm sets; with sharing

⸻

13. Performance & Scalability
	•	Async: Queueable/Batch Apex for logging and heavy processing
	•	Rate Limiting: Platform Cache-backed sliding windows with HTTP 429 Retry-After
	•	Bulk Safety: governor-aware queries; selective indexes; LDS for UI caching
	•	Load Controls: configurable telemetry granularity; dashboard refresh intervals

⸻

14. Performance Benchmarks

Methodology
	•	Dataset: ~1M history records; ~10K events/hour
	•	Org: Enterprise Edition; API v62.0
	•	Tests: bulk ingest, dashboard refresh, risk scoring

Targets

Scenario	P50	P95	Notes
Ingest API (per request)	90ms	180ms	Queueable insert
Dashboard refresh	600ms	1200ms	Indexed + LDS
Risk scoring (1k recs)	120ms	250ms	Heuristic baseline

Tuning: set dashboard refresh 60–120s; batch compaction nightly; env-specific CMDT thresholds.

⸻

15. Operations Runbook

Alert taxonomy

Severity	Example	Action
Critical	CPU breach persists 5 minutes	Auto-open Jira P1, page on-call
High	Flow fault rate > 5%	Triage within 4h, create task
Normal	Event delivery retry	Monitor, no ticket

First response
	1.	Confirm impact (org/business unit)
	2.	Check recent deploys; correlate with Correlation_Id__c
	3.	Execute remediation Flow (rollback, throttle)

Escalation
	•	If not resolved in 30 minutes for Critical, engage Security & App Owner
	•	Post-mortem due within 5 business days

⸻

16. Advanced Integration Scenarios
	•	SIEM: stream Platform Events to Splunk/ELK/Datadog
	•	ITSM: Jira/ServiceNow ticketing from remediation flows
	•	Multi-Cloud: MuleSoft pipelines; hub-and-spoke org aggregation

⸻

17. Security Testing & Audit
	•	Static Analysis: PMD + sf-scanner on PRs; OWASP rulesets
	•	Unit/Integration: Apex and Jest with coverage reports; target ≥95%
	•	DAST: authenticated API smoke tests against scratch/sandbox
	•	Audit Trails: admin actions, policy edits, package updates logged

⸻

18. Localization & Internationalization
	•	Labels: all UI strings externalized to Custom Labels
	•	Translations: Translation Workbench support; date/number formats localized
	•	Accessibility: ARIA attributes; keyboard navigation; SLDS contrast

⸻

19. Documentation & Support
	•	Docs: /docs/ for architecture, compliance, and operations
	•	Troubleshooting: common errors and remediation steps in /docs
	•	Support: contact in SUPPORT.md; incident SLAs in /docs/compliance/incident-response.md

⸻

20. Installation

Scratch Org (developer testing)

sfdx force:auth:web:login -d -a DevHub
sfdx force:org:create -f config/project-scratch-def.json -a OGCCX -d 7
sfdx force:source:push
sfdx force:user:permset:assign -n OpsGuardian_Admin
sfdx force:org:open -p /lightning/app/OpsGuardian

Sandbox (UAT)
	1.	Install package: https://test.salesforce.com/packaging/installPackage.apexp?p0=XXXXXXXX
	2.	Assign OpsGuardian_Admin permission set
	3.	Upload Chart.js static resource if dashboards are blank

Production (AppExchange)
	•	AppExchange link (when published)
	•	Supports upgrade via 2GP; CMDT/data preserved

⸻

21. Usage
	•	Open the OpsGuardian Lightning app for dashboards and tiles
	•	Review events in OpsGuardian_History__c and Platform Event subscriptions
	•	Configure thresholds/policies in OG_Policy__mdt
	•	Enable remediation flows and optional Slack/Jira plugins

⸻

22. Plugin SDK

Interface

public interface OG_Plugin {
  void send(OpsGuardian_History__c eventRec);
  Boolean supports(String eventType, String severity);
}

Registration
	•	Implement OG_Plugin in a namespaced class
	•	Add CMDT record OG_Plugin_Config__mdt with class name and filters
	•	Service factory discovers enabled plugins and invokes send(...)

⸻

23. Release Management & Rollback
	•	Versioning: SemVer; package release notes and change logs
	•	Upgrades: 2GP managed package; CMDT and data preserved; perms auto-updated
	•	Rollback: tagged package versions; uninstall/restore procedures documented

⸻

24. Upgrade & Migration
	•	Breaking changes are versioned; deprecations maintained for two minor releases
	•	Rollback: uninstall latest package, reinstall N-1; re-assign perm sets
	•	Post-upgrade: run /scripts/post-upgrade.apex to backfill new fields

⸻

25. Troubleshooting & FAQ
	•	Charts are blank
Upload Chart.js static resource; clear app cache.
	•	FLS/DML exceptions during ingest
Verify OpsGuardian_Admin field-level perms; confirm stripInaccessible is deployed.
	•	429 responses from ingest
Org is rate-limited; inspect Platform Cache keys rl:*; lower event volume or increase quota.
	•	Einstein scoring not showing
Enable Prediction Builder model and grant user permission set license.

⸻

26. Quality Gates

(Enable these when your pipeline emits artifacts.)
	•	Build: 

	•	Coverage: 

	•	Security Scan: 


⸻

27. License

MIT License. See LICENSE.

⸻

28. Appendix

Demo Data

sfdx force:data:tree:import -p data/OG_History-plan.json
sfdx force:data:tree:import -p data/OG_Flow-plan.json

CI/CD example: .github/workflows/deploy.yml

name: Validate & Deploy
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Salesforce CLI
        run: npm install sfdx-cli --global
      - name: Auth Dev Hub
        run: sfdx force:auth:sfdxurl:store -f ./auth/devhub.json -a DevHub
      - name: Push
        run: sfdx force:source:push -u DevHub
      - name: Apex Tests
        run: sfdx force:apex:test:run --codecoverage --resultformat human --wait 10
      - name: Static Scan
        run: sfdx scanner:run --target force-app --format table

Compliance artifacts
	•	/docs/compliance/encryption.md
	•	/docs/compliance/incident-response.md
	•	/docs/compliance/deletion-policy.md
	•	/docs/compliance/data-flow.md
	•	COMPLIANCE.md (consolidated)

References
	•	Salesforce Shield: https://www.salesforce.com/platform/shield/
	•	Security best practices: https://security.salesforce.com/security-best-practices
	•	Event Monitoring overview: https://help.salesforce.com/s/articleView?id=xcloud.real_time_event_monitoring_overview.htm&type=