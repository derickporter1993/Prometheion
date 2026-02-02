# Elaro

**The AI Compliance Brain for Salesforce — Configuration drift detection, audit evidence automation, and intelligent compliance analysis for regulated organizations.**

_Current: v3.0 — Unified Enterprise Platform_

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Salesforce API](https://img.shields.io/badge/Salesforce-v65.0-blue.svg)](https://developer.salesforce.com)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-success.svg)](.github/workflows)

[Quick Start](#quick-start) • [Sample Report](examples/compliance-baseline-report-sample.md) • [Who It's For](#who-its-for) • [Roadmap](#roadmap) • [Permission Intelligence PRD](docs/permission-intelligence-engine-prd.md)

</div>

---

## What is Elaro?

Elaro makes your Salesforce org **audit-ready and protected from configuration drift** in 24 hours.

**Today (v3.0)**: Elaro continuously monitors your Salesforce configuration for compliance violations, permission sprawl, and undocumented changes — then generates audit evidence and a baseline compliance report that regulators actually want to see.

**Tomorrow (v1.5+)**: Elaro evolves into an **AI Compliance Brain** that doesn't just detect drift, but interprets the _intent, impact, and compliance reasoning_ behind every change — answering questions no other tool can answer.

**Think of it as**: Your AI compliance analyst that works 24/7, understands regulatory frameworks, and speaks both technical and auditor language.

---

## Current Status

**Grade: B+ (86/100)** - Significant improvements from code review remediation

### Recent Improvements (January-February 2026)

- ✅ **Security**: Integrated ElaroSecurityUtils across all classes
- ✅ **Deployment**: 207/207 Apex classes deployed (100% - up from 55%)
- ✅ **Git**: Main branch synced, cleaned up abandoned branches
- ✅ **Tests**: Added critical test coverage for security utilities
- ✅ **Code Quality**: Removed dead code, fixed all compilation errors
- ✅ **CI/CD**: Automated PR merging and status monitoring ([docs](docs/PR_AUTO_MERGE.md))

### Component Status

- ✅ **100% of LWC components** deployed (34 active)
- ✅ **100% of custom objects** deployed (46 objects)
- ✅ **100% of Apex classes** deployed (207/207)
- ✅ **100% of UI components** deployed
- ✅ **All SOQL queries secured** (WITH SECURITY_ENFORCED)

See [REMEDIATION_SUMMARY.md](REMEDIATION_SUMMARY.md) for detailed changes and [SYNC_STATUS.md](SYNC_STATUS.md) for current sync status.

---

## Why This Exists

- **Audits fail** because nobody can explain who changed what and why
- **Regulated orgs** can't afford Salesforce misconfigurations or permission sprawl
- **Existing tools** are too complex/expensive or not tailored to nonprofits and smaller regulated teams
- **Elaro** gives them a simple, opinionated compliance guardrail + evidence engine

---

## Who It's For

Elaro is built for **regulated organizations using Salesforce**:

- 🏥 **Healthcare**: HIPAA compliance, PHI protection, audit trails
- 🏛️ **Government & Nonprofits**: FedRAMP, FISMA, NIST, grants management, donor privacy
- 💰 **Financial Services**: SOX, PCI-DSS, GLBA, transaction auditing, privacy notices
- 🏢 **Any Regulated Org**: SOC 2, GDPR, CCPA, ISO 27001, or compliance frameworks requiring audit evidence

If you're spending weeks preparing for audits, manually reviewing permissions, or can't explain recent configuration changes — Elaro is for you.

---

## What v3.0 Does Today

### 1. **Compliance Baseline Scan** 📊

Generates a comprehensive compliance baseline report showing:

- Audit Readiness Score (0-100)
- Top 5 compliance risks ranked by severity
- Permissions overview (who has access to what)
- Sharing rules and data access analysis
- Compliance checklist across 10 frameworks: HIPAA, SOC 2, NIST, FedRAMP, GDPR, SOX, PCI-DSS, CCPA, GLBA, ISO 27001

**📄 [View Sample Report](examples/compliance-baseline-report-sample.md)**

### 2. **Configuration Drift Detection** 🔍

Tracks Salesforce metadata changes in real-time:

- Profile & permission set modifications
- Sharing rule changes
- Object & field-level security updates
- Setup changes without change control tickets
- Unreviewed production changes

**Alerts you when**: High-risk changes happen (e.g., "Modify All Data" permission granted)

### 3. **Audit Evidence Export** 📁

Automatically collects audit evidence:

- Setup Audit Trail exports
- Field History Tracking data
- Event Monitoring logs (if Shield is enabled)
- Permission set assignment history
- Correlation IDs for tracing changes across systems

**Export formats**: Markdown, CSV, JSON for compliance documentation

### 4. **Audit Readiness Score** 🎯

Calculates a compliance score based on:

- Permission sprawl (how many users have elevated access)
- Audit trail coverage (% of objects with field history enabled)
- Configuration drift (# of unreviewed changes)
- Policy violations (OWD too permissive, no encryption, etc.)

**Score updates**: Real-time as you fix issues

---

## What v3.0 Does NOT Do (Non-Goals)

To keep Elaro simple and focused, v3.0 intentionally:

- ❌ **Does not replace SIEM**: Not a generic security information & event management tool
- ❌ **Does not monitor every SaaS**: Salesforce only (multi-SaaS is v2+)
- ❌ **Does not do complex AI governance**: AI-powered change explanations are v1.5+
- ❌ **Does not prevent changes**: It detects and alerts; it doesn't block (approval workflows are future work)

Elaro is a **compliance drift detector**, not a full GRC platform.

---

## The Future: AI Compliance Intelligence

Elaro is evolving into the world's first **AI Compliance Brain** — a system that doesn't just detect drift, but **interprets the meaning, intent, and compliance impact** of every change.

**Vision**: Intelligence, not dashboards.

Where competitors show logs, Elaro will provide judgment, context, and compliance reasoning.

### Coming in v1.5 (Q2 2025) — AI-Assisted Remediation

#### **Change Intent Analysis** 🧠

The signature feature that sets Elaro apart — AI that understands the _why_ behind every change:

**What competitors show**:

```
Permission Set "Financial_Data_Access" modified by j.smith@acme.org
```

**What Elaro shows**:

```
⚠️ High-Risk Change Detected

Change: Permission Set "Financial_Data_Access" modified
Changed By: j.smith@acme.org
Risk Score: 8.7/10

AI Analysis:
This change grants 45 users "Modify All Data" permission, which:
• Violates SOC2-CC6.3 (logical access controls)
• Expands donor-data exposure by 340%
• Bypasses approval workflow for financial records
• Fails HIPAA "minimum necessary" access rule (§164.514(d))

Compliance Impact:
- HIPAA: ❌ Non-compliant
- SOC 2: ❌ Control failure (CC6.1)
- SOX: ❌ Segregation of duties violation

Recommended Fix:
Create granular permission set with access to:
- Financial_Transactions__c (Read/Edit only)
- Account.AnnualRevenue (Read only)

Evidence Generated: Attached to audit trail
```

This level of reasoning is **impossible for competitors to match** without rebuilding their entire platform.

#### **Automated Remediation Suggestions** 🛠️

One-click fixes for common compliance violations:

- Remove stale permission set assignments (users inactive >90 days)
- Revert OWD settings to "Private" when changed without approval
- Re-enable Field History Tracking on compliance-sensitive objects

#### **Jira Integration** 🎫

Auto-create tickets for high-risk changes with full compliance evidence attached.

---

### Coming in v2.0 (Q4 2025) — Multi-Org Governance

#### **Compliance Co-Pilot** 🤖

Natural language interface for compliance queries:

```
You: "Show me all risky flows touching PII"
Elaro: [Displays 12 flows with PII exposure risks, ranked by severity]

You: "Generate SOC2 evidence for Q2"
Elaro: [Exports audit-ready PDF with all Q2 evidence]

You: "Why did our readiness score drop from 87 to 72?"
Elaro: "3 high-risk changes detected:
1. 23 users granted 'View All Data' without approval
2. Patient_Records__c sharing changed to Public Read/Write
3. Shield Platform Encryption disabled on SSN__c field"
```

#### **Cross-CRM Unified Governance** 🌐

One compliance model across all your CRMs:

- Salesforce
- HubSpot
- Dynamics 365
- Zendesk
- ServiceNow
- Custom apps

**The Moat**: Once Elaro builds this unified compliance graph, competitors cannot catch up without 3-4 years of development.

#### **Predictive Risk Modeling** 📈

Proactive alerts before violations happen:

```
⚡ Predictive Alert

Based on recent admin behavior and automation dependencies,
the upcoming Flow deployment has an 87% probability of causing
HIPAA access violations.

Suggested Action: Review Flow permissions before deployment.
```

---

### Why This Matters — Elaro's Uncopyable Differentiators

1. **AI Change Intent Analysis** — Competitors show _what_ changed; Elaro explains _why it matters_
2. **Automated Compliance Mapping** — Instant mapping to SOC2, HIPAA, NIST, FedRAMP, GDPR
3. **Evidence Packs** — Auto-generated, auditor-ready documentation
4. **Cross-CRM Intelligence** — Unified compliance model (impossible to copy quickly)
5. **Nonprofit-Focused** — Purpose-built for regulated nonprofits (underserved market)

**No one else is building this.**

[See full roadmap →](ROADMAP.md)

---

## Quick Start

### Prerequisites

- Salesforce org (Production, Sandbox, or Scratch Org)
- Salesforce CLI (`sf` or `sfdx`) installed
- DevHub org authenticated (for scratch orgs)

### Installation

#### Option 1: Deploy to Existing Org

```bash
# Clone the repo
git clone https://github.com/derickporter1993/elaro.git
cd elaro

# Authenticate to your Salesforce org
sf org login web --alias myorg

# Deploy the package
sf project deploy start --target-org myorg

# Assign permissions
sf org assign permset --name Elaro_Admin --target-org myorg

# Open the org
sf org open --target-org myorg
```

#### Option 2: Create Scratch Org (for testing)

```bash
# Run the initialization script
./scripts/orgInit.sh

# This will:
# - Create a 7-day scratch org
# - Push source code
# - Assign Elaro_Admin permission set
# - Open the org in your browser
```

### Run Your First Compliance Scan

1. **Navigate to Elaro** in the App Launcher
2. **Click "Run Baseline Scan"** on the dashboard
3. **Wait 30-60 seconds** while Elaro analyzes your org
4. **View your Audit Readiness Score** and top risks
5. **Export the report** (Markdown or PDF) for your compliance team

---

## Core Features in Detail

### Compliance Baseline Scan

**What it does**: Scans your Salesforce org's configuration and generates a compliance baseline report.

**What it scans**:

- Profiles and Permission Sets (elevated permissions, stale assignments)
- Sharing Rules and OWD settings (over-permissioned objects)
- Object and Field-Level Security (sensitive data exposure)
- Audit Trail configuration (Field History, Event Monitoring)
- Platform Encryption status (Shield enabled/disabled)

**How to use**:

```apex
// Programmatically trigger a scan
ComplianceBaselineScanner scanner = new ComplianceBaselineScanner();
ComplianceReport report = scanner.runScan();
System.debug('Audit Readiness Score: ' + report.getScore());
```

Or use the Lightning Web Component dashboard (navigate to Elaro app).

---

### Configuration Drift Detection

**What it does**: Monitors Setup Audit Trail and Field History for configuration changes.

**What it tracks**:

- Profile/Permission Set modifications
- Sharing Rule changes
- Custom Object/Field changes
- User permission assignments
- Integration/Connected App changes

**How it works**:

1. **Platform Events**: Elaro listens to Salesforce Platform Events for real-time changes
2. **Scheduled Jobs**: Runs hourly to poll Setup Audit Trail API
3. **Risk Scoring**: Each change is scored based on impact (Critical/High/Medium/Low)
4. **Alerting**: High-risk changes trigger Slack/email notifications

**Sample alert**:

```
⚠️ Elaro Drift Alert

Change: Permission Set Modified
Object: Financial_Data_Access
Changed By: j.smith@acme.org
Risk Level: 🔴 High
Reason: Grants "Modify All Data" without change control ticket
Action Required: Review and approve or rollback
```

**Schedule automatic scans**:

```bash
# Run this script to schedule hourly drift detection
./scripts/scheduleApiSnapshot.sh myorg
```

---

### Audit Evidence Export

**What it does**: Collects and exports audit evidence required by auditors.

**Evidence collected**:

- Setup Audit Trail (last 180 days)
- Field History records for compliance-sensitive objects
- Permission set assignment changes
- Login history and session activity (if Event Monitoring enabled)

**Export formats**:

- **Markdown**: Human-readable reports
- **CSV**: For import into GRC tools
- **JSON**: For SIEM integration

**Export a compliance report**:

```bash
# Using Salesforce CLI
sf apex run --file scripts/exportEvidenceReport.apex --target-org myorg

# Or use the LWC dashboard
# Navigate to Elaro → Reports → Export Compliance Evidence
```

---

### Audit Readiness Score

**How it's calculated**:

| Factor                   | Weight | Criteria                                                     |
| ------------------------ | ------ | ------------------------------------------------------------ |
| **Permission Sprawl**    | 30%    | # of users with "Modify All" or "View All" permissions       |
| **Audit Trail Coverage** | 25%    | % of compliance-sensitive objects with Field History enabled |
| **Configuration Drift**  | 20%    | # of unreviewed high-risk changes in last 30 days            |
| **Encryption Status**    | 15%    | Shield Platform Encryption enabled for PHI/PII fields        |
| **Policy Compliance**    | 10%    | OWD settings, session timeout, password policy               |

**Example score calculation**:

```
Base Score: 100

Deductions:
- 127 users with "Modify All Data": -20 points
- Field History not enabled on Patient_Records__c: -10 points
- 34 unreviewed changes: -15 points
- Shield Platform Encryption disabled: -10 points
- OWD set to "Public Read/Write" on 2 objects: -8 points

Final Score: 100 - 63 = 37/100 (🔴 Critical)
```

**Improving your score**:

1. Follow the "Suggested Actions" in your baseline report
2. Re-run the scan after making changes
3. Track score improvements over time

---

## Dashboard Components

Elaro includes Lightning Web Components for real-time monitoring:

### 1. **System Monitor Dashboard**

- Governor limit tracking (CPU, Heap, SOQL, DML)
- Real-time alerts when limits are approaching
- Historical trending

**Location**: `force-app/main/default/lwc/systemMonitorDashboard/`

### 2. **API Usage Dashboard**

- API call consumption tracking
- Predict when you'll hit API limits
- Integration health monitoring

**Location**: `force-app/main/default/lwc/apiUsageDashboard/`

### 3. **Flow Execution Monitor**

- Track Flow runs, faults, and performance
- Identify slow or failing automations
- Audit trail for business logic changes

**Location**: `force-app/main/default/lwc/flowExecutionMonitor/`

### 4. **Performance Alert Panel**

- Real-time alerts for threshold breaches
- Configurable alert rules
- Integration with Slack/Jira

**Location**: `force-app/main/default/lwc/performanceAlertPanel/`

---

## Configuration

### Elaro Settings

Configure compliance thresholds in **Elaro Settings** (Custom Settings):

| Setting        | Description                       | Default |
| -------------- | --------------------------------- | ------- |
| `CPU_Warn__c`  | CPU time warning threshold (ms)   | 8000    |
| `CPU_Crit__c`  | CPU time critical threshold (ms)  | 9500    |
| `Heap_Warn__c` | Heap size warning threshold (KB)  | 10000   |
| `Heap_Crit__c` | Heap size critical threshold (KB) | 11500   |
| `SOQL_Warn__c` | SOQL query warning threshold      | 80      |
| `SOQL_Crit__c` | SOQL query critical threshold     | 95      |

**Access**: Setup → Custom Settings → Elaro Settings → Manage

### Alert Integrations

Elaro supports multiple alert channels:

#### Slack Integration

1. Create a Slack Webhook URL: https://api.slack.com/messaging/webhooks
2. Setup → Named Credentials → New Named Credential
   - Label: `Slack_Webhook`
   - URL: Your Slack webhook URL
3. Test the integration:
   ```apex
   ElaroSlackNotifierQueueable.notifyAsync('🚨 Test alert from Elaro');
   ```

#### Jira Integration (Future)

Coming in v1.5 — automatically create Jira tickets for high-risk changes.

---

## Development

### Project Structure

```
elaro/
├── force-app/main/default/          # Salesforce code
│   ├── classes/                     # Apex classes
│   │   ├── ApiUsageSnapshot.cls     # API usage tracking
│   │   ├── PerformanceRuleEngine.cls # Alert rule evaluation
│   │   ├── FlowExecutionLogger.cls  # Flow monitoring
│   │   └── ElaroSlackNotifierQueueable.cls # Alert notifications
│   ├── lwc/                         # Lightning Web Components
│   │   ├── systemMonitorDashboard/  # Real-time monitoring UI
│   │   ├── apiUsageDashboard/       # API usage dashboard
│   │   ├── elaroDashboard/    # Main compliance dashboard
│   │   └── complianceCopilot/       # AI compliance assistant
│   ├── objects/                     # Custom Objects & Settings
│   │   ├── Elaro_AI_Settings__c/ # AI configuration
│   │   ├── Elaro_Compliance_Graph__b/ # Big Object for graph data
│   │   └── Performance_Alert_History__c/ # Alert history
│   └── permissionsets/              # Permission sets
│       └── Elaro_Admin.permissionset-meta.xml
├── scripts/                         # Automation scripts
│   ├── orgInit.sh                   # Scratch org initialization
│   ├── scheduleApiSnapshot.sh       # Schedule periodic scans
│   └── get-all-prs-to-main.sh       # Get all PRs targeting main branch
├── config/                          # Salesforce project config
│   └── project-scratch-def.json     # Scratch org definition
├── examples/                        # Sample outputs
│   └── compliance-baseline-report-sample.md
├── docs/                            # Documentation
└── README.md
```

### Running Tests

```bash
# Run all Apex tests
sf apex run test --target-org myorg --code-coverage --result-format human

# Run specific test class
sf apex run test --target-org myorg --tests PerformanceRuleEngineTest

# Current test coverage: 95%+
```

### Code Quality

```bash
# Format code
npm run fmt

# Check formatting
npm run fmt:check

# Run linter
npm run lint
```

---

## Roadmap

### ✅ v3.0 (Current) - Unified Enterprise Platform

- [x] Compliance Baseline Scan
- [x] Configuration Drift Detection
- [x] Audit Evidence Export
- [x] Audit Readiness Score
- [x] Slack alerting
- [x] LWC dashboards (governor limits, API usage, Flow monitoring)
- [x] AI Compliance Copilot
- [x] Multi-framework compliance scoring (HIPAA, SOC2, NIST, FedRAMP, GDPR, SOX, PCI-DSS, CCPA, GLBA, ISO 27001)
- [x] Enhanced error logging and correlation IDs
- [x] Batched queries for governor limit optimization

### 🚧 v1.5 (Next 3-6 months) - AI-Assisted Remediation

- [ ] **AI Change Explanations**: GPT/Claude integration to explain why a change is risky
- [ ] **Suggested Fixes**: Auto-generate remediation steps (e.g., "Create permission set to replace 'Modify All'")
- [ ] **Jira Integration**: Auto-create tickets for high-risk changes
- [ ] **Compliance Report Scheduler**: Email weekly/monthly reports to compliance team
- [ ] **Mobile Alerts**: Push notifications for critical drift events

### 🔮 v2.0 (6-12 months) - Multi-Org Governance

- [ ] **Multi-Org Dashboard**: Monitor compliance across production, sandboxes, dev orgs
- [ ] **Centralized Evidence Repository**: Store audit evidence from multiple orgs in a single location
- [ ] **AI Governance**: Track Einstein/AI feature usage and compliance (e.g., GDPR Article 22)
- [ ] **SIEM Export**: Push events to Splunk, DataDog, or other SIEM tools
- [ ] **Custom Compliance Frameworks**: Define your own compliance rules beyond the 10 supported frameworks

### 🌟 v3.0+ (Future) - Automated Remediation

- [ ] **Auto-Remediation**: Automatically fix common drift issues (e.g., remove stale permission sets)
- [ ] **Change Control Workflows**: Require approval before high-risk changes go live
- [ ] **Policy-as-Code**: Define compliance policies in YAML, enforce via CI/CD
- [ ] **AppExchange Listing**: Publish as managed package for easy installation

---

## FAQ

### Q: Does Elaro prevent users from making non-compliant changes?

**A**: Not in v3.0. Elaro **detects** and **alerts** on drift, but doesn't block changes. Automated remediation and approval workflows are planned for v2+.

### Q: Does Elaro require Shield Platform Encryption?

**A**: No, but it will flag missing encryption as a compliance risk in your baseline report. If you need HIPAA or SOX compliance, Shield is strongly recommended.

### Q: Can I use Elaro in a sandbox?

**A**: Yes! We recommend testing in a sandbox first. Elaro works in Production, Sandbox, Scratch Orgs, and Developer Orgs.

### Q: Does Elaro store data outside Salesforce?

**A**: No. All data stays in your Salesforce org. Elaro does not send data to external servers (except for Slack/Jira if you configure those integrations).

### Q: What about GDPR compliance?

**A**: Elaro helps with GDPR by tracking access to personal data and providing audit evidence. See the [Compliance section in the full README](docs/compliance-frameworks.md) for details.

### Q: Can I customize the Audit Readiness Score calculation?

**A**: Not yet. Custom scoring is planned for v2. For now, the score is based on industry best practices across 10 compliance frameworks (HIPAA, SOC 2, NIST, FedRAMP, GDPR, SOX, PCI-DSS, CCPA, GLBA, ISO 27001).

---

## Contributing

Elaro is under active development. Contributions welcome!

**Priority areas for v3.0+**:

- Improved drift detection rules
- Test coverage improvements (target 75%+)
- Enhanced error handling and logging
- Performance optimizations

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

## Documentation

### Installation & Setup

- **📦 [Installation Guide](docs/INSTALLATION_GUIDE.md)** - Complete installation instructions with step-by-step configuration
- **🔌 [External Services Guide](docs/EXTERNAL_SERVICES.md)** - Claude AI, Slack, PagerDuty, ServiceNow, Teams integration setup
- **⚙️ Post-Install Configuration** - Named Credentials, AI settings, compliance frameworks

### Security & Testing

- **🔒 [PagerDuty Security Review](docs/PAGERDUTY_INTEGRATION_SECURITY_REVIEW.md)** - Critical security findings and remediation
- **🛡️ [Scanner Report Bundle](docs/SCANNER_REPORT_BUNDLE.md)** - AppExchange Code Analyzer guide and security scanning
- **🧪 Test Utilities** - `ElaroTestUserFactory`, `ElaroTestDataFactory` for security testing

### Development

- **🤝 [Contributing Guide](CONTRIBUTING.md)** - Development workflow, coding standards, testing requirements
- **📝 [Changelog](CHANGELOG.md)** - Release notes and version history
- **🗺️ [Roadmap](ROADMAP.md)** - Feature roadmap and planned releases

### Architecture & Reference

- **📘 [Technical Deep Dive](TECHNICAL_DEEP_DIVE.md)** - Architecture and implementation details
- **📚 [API Reference](API_REFERENCE.md)** - API documentation and code examples
- **🤖 [Claude.md](CLAUDE.md)** - AI assistant guide for the codebase
- **📋 [Compliance Frameworks Reference](docs/COMPLIANCE_FRAMEWORKS_CODE_REFERENCE.md)** - Framework code patterns

### Examples & Reports

- **📊 [Sample Compliance Report](examples/compliance-baseline-report-sample.md)** - Example compliance baseline report
- **📁 [Examples Directory](examples/)** - Sample outputs and reports

### Support

- **🐛 [Report Issues](https://github.com/derickporter1993/elaro/issues)** - Bug reports and feature requests
- **💬 [Discussions](https://github.com/derickporter1993/elaro/discussions)** - Community discussions and Q&A
- **📧 Email Support**: support@elaro.io
- **🔒 Security Issues**: security@elaro.io

---

---

_Elaro™ — Keep your Salesforce org audit-ready, every day._
