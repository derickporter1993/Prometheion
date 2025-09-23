OpsGuardian™ Command Center X (CCX)

A Salesforce-Native Compliance, Security, and AI Monitoring Framework

⸻

Status & Compatibility
	•	Status: ✅ Production-ready reference build (AppExchange submission in progress)
	•	Version: 1.0.0
	•	API Version: 62.0+
	•	Supported Orgs: Scratch, Sandbox, Developer Edition, Production
	•	Limitations: External plugins (Slack, Jira) provided as stubs; multi-cloud ingestion roadmap for v2.0

⸻

What It Does

OpsGuardian CCX extends Salesforce observability and compliance monitoring, moving beyond Shield by embedding proactive security and AI-powered diagnostics.

Core Features
	•	Governor Limits Dashboard: CPU, SOQL, DML, heap usage
	•	Flow & Transaction Monitor: Faulting flows and heavy transactions surfaced in real-time
	•	AI Diagnostics Tile: GPT + Einstein hybrid anomaly detection
	•	Predictive Alerts: Proactive scoring and alerts via Platform Events
	•	Policy-as-Code: CMDT-based (OG_Policy__mdt) configurable thresholds
	•	Remediation Automation: Flow Invocables to auto-rollback or trigger Jira/Slack tickets
	•	Multi-Org Hub-and-Spoke: Apex REST endpoint for telemetry ingestion
	•	CI/CD Ready: Jest tests, GitHub Actions, PMD + sf-scanner integrated

⸻

Architecture & Security Highlights
	•	Managed Package (2GP) structure
	•	Permissions: OpsGuardian_Admin with object + field-level controls
	•	Security Enforcement:
	•	WITH SECURITY_ENFORCED in SOQL queries
	•	Security.stripInaccessible() for all DML
	•	Authentication: OAuth 2.0 JWT/Client Credentials in Named Credentials; TLS 1.3 required
	•	Resilience: Queueable + Batch Apex, circuit breaker + retry/backoff on callouts
	•	Accessibility & i18n: ARIA-labeled LWCs; text externalized to Custom Labels

⸻

Getting Started
	1.	Clone this repo
	2.	Authenticate to Dev Hub:

sfdx force:auth:web:login -d -a DevHub


	3.	Create a scratch org:

sfdx force:org:create -f config/project-scratch-def.json -a OGCCX -d 7


	4.	Push source and assign perms:

sfdx force:source:push
sfdx force:user:permset:assign -n OpsGuardian_Admin


	5.	(Optional) Install Chart.js static resource and sample data
	6.	Launch the OpsGuardian Command Center Lightning App

⸻

Post-Install Checklist

Step	Description
Upload Chart.js static resource	Required for dashboards
Confirm OpsGuardian_History__c object	Schema must match managed package
Verify Platform Event Performance_Alert__e	Ensure deployed and subscribed
Assign OpsGuardian_Admin perm set	Grants access
Adjust thresholds via CMDT	Configure OG_Policy__mdt records
Test AI Diagnostics Tile	Validate OpenAI + Einstein integration


⸻

Screenshots & Architecture

Command Center Dashboard

Governor limit tracking and alerts in one console.

AI Diagnostics Tile

Hybrid AI scoring with remediation options.

Policy Management

Thresholds stored in CMDT for no-code updates.

High-Level Architecture Diagram

flowchart TD
  subgraph Salesforce Org
    A[OpsGuardian LWC Tiles] --> B[Lightning App Page]
    B --> C[OpsGuardian Apex Services]
    C --> D[OpsGuardian_History__c]
    C --> E[Platform Events]
    C --> F[CMDT: OG_Policy__mdt]
  end
  C -->|Named Credential (JWT)| G[(External AI)]
  C -->|REST API Hub| H[Other Salesforce Orgs]
  C -->|Plugins| I[(Slack/Jira)]


⸻

Roadmap
	•	v1.0: AppExchange package, pilot clients
	•	v1.1: Slack/Jira plugins, advanced dashboards, i18n improvements
	•	v2.0: Multi-cloud ingestion, standalone SaaS dashboard

⸻

Compliance Readiness
	•	95%+ Apex code coverage target
	•	Jest tests for LWCs with coverage reporting
	•	PMD + sf-scanner static analysis integrated
	•	GDPR + SOC 2 data flow diagrams included
	•	Security Review packet prepared: incident response, deletion policies, architecture docs

⸻

License & Contribution
	•	Licensed under MIT
	•	Contributions welcome via PRs
	•	Security disclosures: see SECURITY.md

⸻
