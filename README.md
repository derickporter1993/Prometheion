# Solentra

**Court-defensible compliance & AI governance platform for Salesforce**

[![Salesforce](https://img.shields.io/badge/Salesforce-00A1E0?style=flat&logo=salesforce&logoColor=white)](https://salesforce.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

Solentra is an enterprise-grade compliance and AI governance platform built natively on Salesforce. It provides automated compliance monitoring, audit evidence generation, and real-time alerting across multiple regulatory frameworks.

## Key Features

### 🔍 Compliance Baseline Scan
Automated scanning and documentation of your org's security posture, including:
- Permission set and profile analysis
- Field-level security audit
- Sharing rule evaluation
- Custom object configuration review

### 🔄 Configuration Drift Detection
Real-time monitoring of security-relevant changes:
- Track modifications to permission sets and profiles
- Monitor sharing rule updates
- Alert on field-level security changes
- Audit trail for all configuration changes

### 📋 Audit Evidence Export
Generate court-defensible documentation:
- Timestamped compliance snapshots
- Regulatory framework mapping (HIPAA, SOC2, NIST, FedRAMP, GDPR)
- Evidence chain of custody
- Automated report generation

### 📊 Audit Readiness Score
Real-time compliance scoring across frameworks:
- Multi-framework support (HIPAA, SOC2, NIST, FedRAMP, GDPR)
- Weighted scoring based on risk factors
- Trend analysis and historical tracking
- Actionable remediation recommendations

### 🤖 AI Compliance Copilot
Natural language interface for compliance queries:
- Ask questions about your compliance status
- Get instant answers with evidence
- Suggested remediation actions
- Framework-specific guidance

### 📱 Real-Time Notifications
Multi-channel alerting:
- Slack integration with rich Block Kit messages
- Microsoft Teams with Adaptive Cards
- Weekly compliance scorecards
- Customizable alert thresholds

## Supported Compliance Frameworks

| Framework | Coverage |
|-----------|----------|
| **HIPAA** | PHI protection, audit controls, encryption requirements |
| **SOC 2** | Trust service criteria, logical access, change management |
| **NIST** | Access control, audit accountability, system integrity |
| **FedRAMP** | Federal security requirements, incident response, monitoring |
| **GDPR** | Data subject rights, data minimization, breach notification |

## Quick Start

### Prerequisites
- Salesforce CLI installed
- Node.js 20+ and npm 10+
- A Salesforce org (Developer, Sandbox, or Production)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/derickporter1993/Solentra.git
   cd Solentra
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Authorize your org**
   ```bash
   sf org login web -a solentra-org
   ```

4. **Deploy to your org**
   ```bash
   sf project deploy start --target-org solentra-org
   ```

5. **Assign permission set**
   ```bash
   sf org assign permset --name Solentra_Admin --target-org solentra-org
   ```

### Setting Up Notifications

#### Slack Integration
1. Create a Slack Incoming Webhook
2. Create a Named Credential called `Slack_Webhook` with the webhook URL
3. See `docs/SETUP_GUIDE.md` for detailed instructions

#### Microsoft Teams Integration
1. Create a Teams Incoming Webhook
2. Create a Named Credential called `Teams_Webhook` with the webhook URL
3. See `docs/SETUP_GUIDE.md` for detailed instructions

### Schedule Weekly Scorecards
```apex
// Schedule for every Monday at 9 AM
String cronExp = '0 0 9 ? * MON';
System.schedule('Solentra Weekly Scorecard', cronExp, new WeeklyScorecardScheduler());
```

## Project Structure

```
Solentra/
├── force-app/main/default/
│   ├── classes/           # Apex classes
│   ├── lwc/               # Lightning Web Components
│   ├── customMetadata/    # Compliance policies
│   ├── labels/            # Custom labels (i18n)
│   ├── objects/           # Custom objects
│   ├── events/            # Platform events
│   ├── triggers/          # Apex triggers
│   └── permissionsets/    # Permission sets
├── docs/                  # Documentation
├── examples/              # Sample reports
├── scripts/               # Utility scripts
└── config/                # Project configuration
```

## Components

### Apex Classes
- `SentinelComplianceCopilot` - Natural language compliance query interface
- `SentinelComplianceScorer` - Multi-framework compliance scoring
- `SentinelReasoningEngine` - AI-powered compliance analysis
- `SentinelRemediationEngine` - Automated remediation suggestions
- `SentinelGraphIndexer` - Compliance relationship mapping
- `WeeklyScorecardScheduler` - Scheduled compliance reports
- `SlackNotifier` / `TeamsNotifier` - Multi-channel notifications
- `SentinelConstants` - Centralized constants and utilities

### Lightning Web Components
- `complianceCopilot` - AI-powered compliance chat interface
- `sentinelReadinessScore` - Visual compliance dashboard
- `apiUsageDashboard` - API usage monitoring
- `flowExecutionMonitor` - Flow performance tracking
- `systemMonitorDashboard` - System health overview
- `performanceAlertPanel` - Real-time alert display

## Development

### Running Tests
```bash
# Run all LWC tests
npm run test:unit

# Run with coverage
npm run test:unit:coverage

# Watch mode
npm run test:unit:watch
```

### Linting & Formatting
```bash
# Format code
npm run fmt

# Check formatting
npm run fmt:check

# Lint JavaScript
npm run lint

# Fix lint issues
npm run lint:fix
```

### Validation
```bash
# Run full validation (format, lint, test)
npm run validate
```

## Documentation

- [Setup Guide](docs/SETUP_GUIDE.md) - Detailed installation and configuration
- [GitHub Repository Setup](docs/GITHUB_REPO_SETUP.md) - CI/CD configuration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions or issues, please open a GitHub issue or contact the Solentra team.

---

**Built with ❤️ for Salesforce compliance professionals**
