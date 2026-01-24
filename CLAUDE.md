# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Prometheion** is an AI compliance brain for Salesforce — configuration drift detection, audit evidence automation, and intelligent compliance analysis for regulated organizations (healthcare, government, financial services, nonprofits).

**Version:** v3.0 Unified Enterprise Platform
**Platform:** Salesforce API v65.0
**Status:** 207 Apex classes, 34 LWC components, 46 custom objects deployed

## Build & Development Commands

```bash
# Code quality
npm run fmt              # Format code with Prettier
npm run fmt:check        # Check formatting (CI uses this)
npm run lint             # ESLint check (max 3 warnings)
npm run lint:fix         # Auto-fix lint issues

# Testing
npm run test:unit        # Run LWC Jest tests
npm run test:unit:watch  # Jest watch mode
npm run test:unit:coverage # Jest with coverage report
sf apex run test --target-org <alias> --code-coverage  # Apex tests

# Run single test class
sf apex run test --target-org prometheion-dev --tests <TestClassName>

# Deployment
sf project deploy start --target-org prometheion-dev  # Deploy to org
sf project deploy start --dry-run --source-dir <path> # Validate only

# Scratch org workflow
./scripts/orgInit.sh [alias]  # Create and initialize scratch org
sf org assign permset --name Prometheion_Admin --target-org <alias>
```

## Architecture

```
force-app/main/default/
├── classes/         # 207 Apex classes (use PrometheionSecurityUtils for CRUD/FLS)
├── lwc/             # 34 Lightning Web Components
├── objects/         # 46 custom objects (compliance metadata, audit logs)
├── triggers/        # Audit trail automation
├── permissionsets/  # Prometheion_Admin, Prometheion_Auditor, Prometheion_User
└── events/          # Performance_Alert__e, GDPR_Erasure_Event__e, etc.

scripts/
├── orgInit.sh              # Scratch org initialization
├── sync-all.sh             # Git workflow automation (commit + merge to main)
├── scheduleApiSnapshot.sh  # Schedule periodic compliance scans
└── create-test-data.apex   # Test data generation
```

**Key Components:**
- `PrometheionSecurityUtils` - CRUD/FLS enforcement (use for all data access)
- `ComplianceBaselineScanner` - Core compliance scanning engine
- `PrometheionSlackNotifierQueueable` - Alert notifications
- `prometheionDashboard` (LWC) - Main compliance dashboard
- `complianceCopilot` (LWC) - AI compliance assistant

## Critical Code Patterns

### Apex Security (MANDATORY)

```apex
// All SOQL must include WITH SECURITY_ENFORCED
List<Account> accounts = [SELECT Id, Name FROM Account WITH SECURITY_ENFORCED];

// Use PrometheionSecurityUtils for CRUD checks
PrometheionSecurityUtils.validateCRUDAccess('Account', DmlOperation.DML_UPDATE);

// All classes must use 'with sharing'
public with sharing class MyClass { }
```

### Apex Bulkification (CRITICAL)

```apex
// WRONG - Governor limit violation
for (Account acc : accounts) {
    Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];  // NO!
}

// RIGHT - Query outside loop
Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();
for (Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
    // Build map
}
```

### LWC Template Syntax (CRITICAL)

```html
<!-- WRONG - Causes LWC1034 compile error -->
<lightning-datatable data="{rows}"></lightning-datatable>

<!-- RIGHT - No quotes around template bindings -->
<lightning-datatable data={rows}></lightning-datatable>
```

**Note:** Prettier can corrupt LWC HTML by adding quotes. LWC HTML files are excluded in `.prettierignore`.

## Git Workflow

After completing work, use the automated sync script:

```bash
./scripts/sync-all.sh "Commit message"
```

This handles: stage → commit → push to feature branch → merge to main → push main → return to feature branch.

Manual workflow:
```bash
git add .
git commit -m "type: description"  # Types: feat, fix, test, docs, refactor
git push origin $(git branch --show-current)
git checkout main && git pull && git merge --no-ff $(git branch --show-current) && git push origin main
git checkout -  # Return to feature branch
```

## Testing Requirements

- **Apex:** 75% minimum coverage (target 85%+)
- **LWC:** Jest tests in `__tests__/<componentName>.test.js`
- Test naming: `testMethodName_Scenario_ExpectedResult`
- Use `Test.startTest()` / `Test.stopTest()` for async/governor limit reset
- Mock callouts with `@isTest` classes implementing `HttpCalloutMock`

```bash
# Find tests for a class
grep -rn "ClassName" force-app/main/default/classes/*Test.cls
```

## Pre-Commit Checklist

```bash
npm run lint          # Must pass with ≤3 warnings
npm run fmt:check     # Must pass
npm run test:unit     # All tests must pass

# Check for LWC template corruption (should return nothing)
grep -rn '="{' force-app/main/default/lwc/**/*.html
```

## Environment

- **Default org alias:** prometheion-dev
- **Dev Hub:** prod-org
- **Node.js:** v20.0.0+ required
- **SF CLI:** Use `sf` commands (not legacy `sfdx`)

## Compliance Frameworks Supported

HIPAA, SOC 2, NIST, FedRAMP, GDPR, SOX, PCI-DSS, CCPA, GLBA, ISO 27001
