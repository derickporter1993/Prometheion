# Salesforce Technical Debt Remediation (2026 Security Baseline)

This repository now tracks the 2026 Salesforce security debt baseline as first-class remediation actions.

## What changed

The compliance action catalog now explicitly covers the highest-risk debt areas identified after the 2025 incident wave:

1. Connected app governance and quarterly audits
2. Standard profile retirement in favor of permission-set-driven access
3. Trusted URL/CSP allowlisting requirements
4. IP restrictions and login hours enforcement
5. External Client App migration planning before Connected App EOS

## Operating cadence

Use the following sprint cadence:

- **0-30 days**: Run Security Health Check, connected app audit, and elevated access review.
- **30-60 days**: Implement least privilege hardening, trusted URLs, and login controls.
- **60-90 days**: Enable Event Monitoring + Security Center with weekly review.
- **Quarterly**: Re-run audits and validate drift.

## How this maps in Elaro

These controls are represented as `Compliance_Action__mdt` records so they can be surfaced in dashboard, wizard, and remediation workflows without hardcoding additional logic.
