# Elaro Compliance Hub - User Guide

Welcome to Elaro Compliance Hub, your comprehensive solution for managing multi-framework compliance in Salesforce. This guide will help you navigate the platform, understand its features, and maximize your compliance management efficiency.

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [Dashboard Overview](#2-dashboard-overview)
3. [Supported Compliance Frameworks](#3-supported-compliance-frameworks)
4. [Workflow Walkthroughs](#4-workflow-walkthroughs)
5. [AI Copilot Usage Guide](#5-ai-copilot-usage-guide)
6. [Reports and Exports](#6-reports-and-exports)

---

## 1. Getting Started

### Accessing Elaro

After installation, access Elaro through the Salesforce App Launcher:

1. Click the **App Launcher** icon (9 dots) in the top navigation
2. Search for **"Elaro"** or **"Compliance Hub"**
3. Click the Elaro app tile to launch

Alternatively, navigate directly to the Elaro Dashboard tab if it's been added to your navigation menu.

### Navigation Overview

The Elaro interface consists of several key areas:

- **Main Dashboard**: Central hub displaying compliance scores, alerts, and key metrics
- **Framework Selector**: Choose which compliance framework to view (HIPAA, SOC2, GDPR, etc.)
- **AI Copilot**: Access AI-powered compliance assistance
- **Reports**: Generate audit reports and evidence packages
- **Settings**: Configure alerts, integrations, and preferences

### Quick Start Checklist

To get started with Elaro:

- [ ] Access the Elaro Dashboard
- [ ] Review your current compliance scores across all frameworks
- [ ] Explore the AI Copilot with a sample query
- [ ] Run your first compliance assessment
- [ ] Review any identified gaps
- [ ] Generate a baseline compliance report

---

## 2. Dashboard Overview

The Elaro Dashboard provides a unified view of your organization's compliance posture across all supported frameworks.

![Dashboard Overview](images/dashboard-overview.png)

### Main Compliance Dashboard Layout

The dashboard is organized into several key sections:

#### Compliance Score Cards

Each framework displays a score card showing:
- **Overall Score**: Percentage-based compliance rating (0-100%)
- **Status Indicator**: Visual status (🟢 Compliant, 🟡 At Risk, 🔴 Non-Compliant)
- **Gap Count**: Number of identified compliance gaps
- **Trend Indicator**: Whether scores are improving (↑), declining (↓), or stable (→)

![Compliance Score Card](images/compliance-scorecard.png)

#### Key Metrics Panel

The metrics panel displays:
- **Total Frameworks Monitored**: Number of active compliance frameworks
- **Critical Gaps**: High-priority issues requiring immediate attention
- **Remediation Progress**: Percentage of gaps that have been addressed
- **Last Assessment Date**: When the most recent compliance scan was performed

#### Alert Panel

Real-time alerts appear in the alert panel for:
- New compliance gaps detected
- Approaching deadlines (e.g., CCPA request deadlines)
- Critical security issues
- Scheduled job failures

![Alert Panel](images/alert-panel.png)

### Score Cards and Metrics Explanation

**Compliance Score Calculation**

Each framework's score is calculated based on:
- **Control Coverage**: Percentage of required controls that are implemented
- **Evidence Completeness**: Availability of audit evidence for controls
- **Gap Severity**: Weighted impact of identified gaps
- **Remediation Status**: Progress on closing identified gaps

**Understanding Score Ranges**

- **90-100%**: Fully compliant - minimal risk
- **70-89%**: Mostly compliant - some gaps require attention
- **50-69%**: At risk - significant gaps present
- **Below 50%**: Non-compliant - critical issues require immediate remediation

---

## 3. Supported Compliance Frameworks

Elaro supports multiple compliance frameworks simultaneously, allowing you to manage all your compliance requirements from a single platform.

![Framework Selector](images/framework-selector.png)

### HIPAA (Health Insurance Portability and Accountability Act)

**Purpose**: Healthcare data protection and privacy

**Key Controls Monitored**:
- Administrative safeguards (workforce security, access management)
- Physical safeguards (facility access controls, workstation security)
- Technical safeguards (access control, audit controls, integrity controls)
- Breach notification procedures

**Use Cases**: Healthcare providers, health plans, healthcare clearinghouses, and business associates handling protected health information (PHI).

### SOC 2 (Service Organization Control 2)

**Purpose**: Security, availability, processing integrity, confidentiality, and privacy trust principles

**Key Controls Monitored**:
- Logical access controls
- System operations monitoring
- Change management processes
- Risk assessment procedures
- Vendor management

**Use Cases**: SaaS providers, cloud service providers, and organizations providing services that require trust and security assurance.

### GDPR (General Data Protection Regulation)

**Purpose**: EU data privacy and protection

**Key Controls Monitored**:
- Data subject rights (access, erasure, portability)
- Consent management
- Data breach notification (72-hour requirement)
- Data minimization principles
- Privacy by design and default

**Use Cases**: Organizations processing personal data of EU residents, regardless of location.

### PCI-DSS (Payment Card Industry Data Security Standard)

**Purpose**: Payment card data security

**Key Controls Monitored**:
- Cardholder data protection
- Access control measures
- Network security
- Vulnerability management
- Security monitoring and testing

**Use Cases**: Merchants, payment processors, and service providers handling credit card data.

### ISO 27001 (Information Security Management)

**Purpose**: Information security management system (ISMS)

**Key Controls Monitored**:
- Access control policies
- Cryptography controls
- Physical and environmental security
- Operations security
- Supplier relationships

**Use Cases**: Organizations seeking ISO 27001 certification or implementing ISMS best practices.

### GLBA (Gramm-Leach-Bliley Act)

**Purpose**: Financial privacy and data protection

**Key Controls Monitored**:
- Privacy notice requirements
- Safeguards rule compliance
- Annual notice distribution
- Customer information protection

**Use Cases**: Financial institutions, banks, credit unions, and financial service providers.

### CCPA (California Consumer Privacy Act)

**Purpose**: California consumer privacy rights

**Key Controls Monitored**:
- Consumer rights (access, deletion, opt-out)
- Privacy policy requirements
- Data sale opt-out mechanisms
- Request handling (45-day SLA)
- Non-discrimination practices

**Use Cases**: Businesses collecting personal information from California residents.

---

## 4. Workflow Walkthroughs

### Running a Compliance Assessment

1. **Navigate to Dashboard**
   - Open the Elaro Dashboard
   - Select the framework you want to assess from the framework selector

2. **Initiate Assessment**
   - Click the **"Run Assessment"** button
   - Select assessment scope (full org, specific objects, or custom scope)
   - Choose assessment depth (quick scan or comprehensive)

3. **Monitor Progress**
   - Assessment progress is displayed in real-time
   - Estimated completion time is shown
   - You can continue working while the assessment runs

4. **Review Results**
   - Once complete, results appear in the dashboard
   - Review the compliance score and identified gaps
   - Click on individual gaps for detailed information

### Reviewing and Remediating Gaps

![Gap Analysis](images/gap-analysis.png)

1. **Access Gap List**
   - Navigate to the **"Compliance Gaps"** section
   - Filter by framework, severity, or status

2. **Review Gap Details**
   - Click on a gap to view:
     - Gap description and impact
     - Affected controls or processes
     - Recommended remediation steps
     - Evidence requirements

3. **Remediate Gap**
   - Follow the recommended remediation steps
   - Upload evidence documents if required
   - Update gap status as you progress

4. **Mark as Remediated**
   - Once remediation is complete, mark the gap as **"Remediated"**
   - The system will verify evidence and update compliance scores
   - Re-run assessment to confirm gap closure

### Generating Audit Reports

![Audit Wizard](images/audit-wizard.png)

1. **Access Report Generator**
   - Navigate to **"Reports"** → **"Audit Reports"**
   - Click **"Generate New Report"**

2. **Configure Report**
   - Select framework(s) to include
   - Choose report type:
     - Executive Summary
     - Detailed Compliance Report
     - Gap Analysis Report
     - Evidence Package
   - Set date range for assessment data

3. **Customize Content**
   - Include/exclude specific sections
   - Add custom notes or commentary
   - Select evidence documents to attach

4. **Generate and Export**
   - Click **"Generate Report"**
   - Report is created as a PDF
   - Download or email the report
   - Reports are saved in the system for future reference

### Exporting Evidence Packages

1. **Access Evidence Package Builder**
   - Navigate to **"Reports"** → **"Evidence Packages"**
   - Click **"Build New Package"**

2. **Select Evidence**
   - Choose framework and assessment period
   - Select controls to include
   - Attach supporting documents:
     - Policy documents
     - Configuration screenshots
     - Audit logs
     - Test results

3. **Package Configuration**
   - Set package format (ZIP, PDF bundle)
   - Add package metadata (auditor name, audit date)
   - Include compliance score summary

4. **Generate Package**
   - Click **"Build Package"**
   - Package is compiled and prepared for download
   - Download link is provided
   - Package can be shared with auditors or stored for records

---

## 5. AI Copilot Usage Guide

The Elaro AI Copilot provides intelligent, context-aware assistance for compliance management tasks.

![AI Copilot](images/ai-copilot.png)

### Accessing the Copilot

1. Click the **"AI Copilot"** icon in the navigation bar
2. The Copilot panel opens on the right side of the screen
3. Start typing your question or request

### Example Prompts and Queries

**Framework-Specific Questions**
```
"What are the key requirements for HIPAA compliance in Salesforce?"
"Show me all GDPR gaps that need attention this quarter"
"How do I remediate PCI-DSS gap #123?"
```

**General Compliance Guidance**
```
"Explain the difference between SOC 2 Type I and Type II"
"What evidence do I need for ISO 27001 access control controls?"
"Help me understand CCPA consumer request handling requirements"
```

**Remediation Assistance**
```
"Generate a remediation plan for the top 5 critical gaps"
"What steps should I take to fix the data encryption gap?"
"Create a checklist for GDPR consent management implementation"
```

**Report Generation**
```
"Generate an executive summary for SOC 2 compliance"
"Create a gap analysis report for HIPAA"
"Summarize our compliance posture across all frameworks"
```

### Understanding AI Recommendations

The AI Copilot provides recommendations based on:
- **Framework Requirements**: Official compliance framework documentation
- **Best Practices**: Industry-standard implementation approaches
- **Your Org Context**: Specific configuration and data in your Salesforce org
- **Historical Patterns**: Similar gaps and their successful remediation

**Recommendation Types**:
- **Action Items**: Specific steps to take
- **Configuration Changes**: Settings or metadata modifications
- **Process Improvements**: Workflow or policy updates
- **Evidence Requirements**: Documentation needed for audit

### Best Practices for AI-Assisted Compliance

1. **Be Specific**: Provide context about your framework, gap, or question
2. **Ask Follow-ups**: Use the Copilot's responses to dive deeper
3. **Verify Recommendations**: Cross-reference AI suggestions with official documentation
4. **Use for Learning**: Ask "why" questions to understand compliance requirements
5. **Iterate**: Refine your questions based on initial responses

**Example Conversation Flow**:
```
You: "What are the HIPAA access control requirements?"

Copilot: "HIPAA requires administrative, physical, and technical safeguards for access control. 
Key requirements include unique user identification, emergency access procedures, automatic 
logoff, and encryption/decryption of ePHI. Would you like details on any specific requirement?"

You: "Tell me more about unique user identification"

Copilot: "Unique user identification means each user must have a unique identifier (username) 
that cannot be shared. In Salesforce, this is enforced by the User object where each user 
has a unique Username field. You should also implement multi-factor authentication (MFA) 
for additional security. Would you like help checking your MFA configuration?"
```

---

## 6. Reports and Exports

### Available Report Types

**Executive Summary Report**
- High-level compliance overview
- Key metrics and scores
- Critical gaps summary
- Recommended actions
- Suitable for C-suite and board presentations

**Detailed Compliance Report**
- Comprehensive framework analysis
- All controls and their status
- Detailed gap descriptions
- Remediation recommendations
- Evidence requirements

**Gap Analysis Report**
- Focused on identified gaps
- Prioritized by severity
- Remediation timelines
- Resource requirements
- Progress tracking

**Evidence Package**
- Complete audit documentation
- All supporting evidence
- Control-to-evidence mapping
- Compliance score documentation
- Ready for external auditor review

### PDF Generation

All reports can be generated as PDF documents:

1. **Select Report Type**: Choose from available report templates
2. **Configure Options**: Set date ranges, frameworks, and content sections
3. **Preview**: Review report content before generation
4. **Generate**: Click "Generate PDF" to create the document
5. **Download**: Save the PDF to your local system or Salesforce Files

**PDF Features**:
- Professional formatting with Elaro branding
- Table of contents and page numbering
- Charts and visualizations
- Appendices with detailed evidence
- Watermarking for draft/final versions

### Evidence Package Builder

The Evidence Package Builder helps you compile all necessary documentation for audits:

**Package Contents**:
- Compliance assessment results
- Control implementation evidence
- Policy documents
- Configuration screenshots
- Audit logs and trail data
- Test results and validation reports

**Package Formats**:
- **ZIP Archive**: All files organized in folders
- **PDF Bundle**: Single PDF with all documents
- **Salesforce Files**: Uploaded to Salesforce Files for sharing

### Scheduling Automated Reports

Set up automated report generation:

1. **Navigate to Settings** → **"Scheduled Reports"**
2. **Create New Schedule**:
   - Select report type
   - Choose frequency (daily, weekly, monthly, quarterly)
   - Set recipients (email addresses)
   - Configure report parameters
3. **Save Schedule**: The system will generate and distribute reports automatically

**Use Cases**:
- Weekly compliance score updates to management
- Monthly gap analysis reports to compliance team
- Quarterly executive summaries to board
- Annual evidence packages for external audits

---

## Additional Resources

- **Admin Guide**: See [ADMIN_GUIDE.md](ADMIN_GUIDE.md) for configuration and administration
- **Setup Guide**: See [SETUP_GUIDE.md](SETUP_GUIDE.md) for installation instructions
- **Support**: Contact your system administrator or Elaro support team

---

*Last Updated: January 2026*
