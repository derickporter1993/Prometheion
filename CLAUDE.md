# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Elaro** is an AI-powered compliance and governance platform for Salesforce v3.0 Enterprise Edition. It provides configuration drift detection, audit evidence automation, and multi-framework compliance scoring (HIPAA, SOC2, NIST, FedRAMP, GDPR, SOX, PCI-DSS, CCPA, GLBA, ISO 27001) for regulated organizations.

## Technology Stack

| Layer      | Technology                     |
| ---------- | ------------------------------ |
| Backend    | Apex (Salesforce API v65.0)    |
| Frontend   | Lightning Web Components (LWC) |
| Testing    | Jest (LWC) + Apex Test Classes |
| Linting    | ESLint v9 with LWC plugin      |
| Formatting | Prettier                       |
| Monorepo   | Turborepo (platform/)          |
| Node.js    | v20.0.0+ required              |

## Development Commands

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

# Run single Apex test class
sf apex run test -o <org> --tests <TestClassName>

# Salesforce Deployment
sf project deploy start -o <org>             # Deploy to org
sf project deploy start -o <org> --dry-run   # Validate only

# Pre-commit (runs automatically via Husky)
npm run precommit        # fmt:check + lint + test:unit

# Platform CLI (TypeScript monorepo)
cd platform && npm install && npm run build  # Build platform packages
```

## Project Structure

```
elaro/
├── force-app/main/default/     # Salesforce source
│   ├── classes/                # Apex (207 classes: 122 prod + 85 test)
│   ├── lwc/                    # Lightning Web Components (42)
│   ├── objects/                # Custom objects (53)
│   ├── triggers/               # Apex triggers
│   └── permissionsets/         # Permission sets (5)
├── platform/                   # TypeScript monorepo (Turborepo)
│   └── packages/
│       ├── cli/                # elaro CLI
│       ├── sf-client/          # Salesforce API client
│       ├── types/              # Shared TypeScript types
│       └── masking/            # Data masking utilities
├── scripts/                    # Automation scripts
└── config/                     # Salesforce project config
```

## Architecture

### Apex Service Layer Pattern

- **Controllers**: `*Controller.cls` - LWC Apex controllers with `@AuraEnabled` methods
- **Services**: `*Service.cls` - Business logic, compliance framework implementations
- **Queueables**: `*Queueable.cls` - Async processing (Slack notifications, batch operations)
- **Interfaces**: `I*.cls` - Service contracts (e.g., `IAccessControlService`, `IBreachNotificationService`)
- **Security**: `ElaroSecurityUtils.cls` - Central CRUD/FLS validation

### Compliance Framework Services

Each framework has dedicated service classes:

- `ElaroHIPAAComplianceService`, `ElaroGDPRComplianceService`, `ElaroCCPAComplianceService`
- `ElaroPCIDSSComplianceService`, `ElaroSOC2ComplianceService`, `ElaroGLBAPrivacyNoticeService`

### Key LWC Components

| Component                | Purpose                    |
| ------------------------ | -------------------------- |
| `elaroDashboard`         | Main compliance dashboard  |
| `complianceCopilot`      | AI compliance assistant    |
| `systemMonitorDashboard` | Governor limits monitoring |
| `apiUsageDashboard`      | API usage tracking         |
| `flowExecutionMonitor`   | Flow performance tracking  |
| `performanceAlertPanel`  | Real-time alerts           |

### Key Custom Objects

| Object                  | Purpose                                                    |
| ----------------------- | ---------------------------------------------------------- |
| `Compliance_Score__c`   | Framework compliance scores                                |
| `Compliance_Gap__c`     | Gap tracking & remediation                                 |
| `API_Usage_Snapshot__c` | API limit monitoring                                       |
| `Elora_AI_Settings__c`  | AI configuration _(Salesforce API name; product is Elaro)_ |
| `Elaro_Audit_Log__c`    | Audit trail                                                |

## Critical Development Rules

### Security (MANDATORY)

```apex
// ALL SOQL queries MUST use WITH SECURITY_ENFORCED
List<Account> accounts = [SELECT Id, Name FROM Account WITH SECURITY_ENFORCED];

// Use ElaroSecurityUtils for CRUD/FLS checks
ElaroSecurityUtils.validateCRUDAccess('Account', DmlOperation.DML_UPDATE);

// All classes MUST use with sharing
public with sharing class MyClass { }
```

### LWC Template Bindings (CRITICAL)

Never quote template bindings - this causes LWC1034 compilation errors:

```html
<!-- WRONG - causes compile error -->
<lightning-datatable data="{rows}"></lightning-datatable>

<!-- CORRECT - no quotes around bindings -->
<lightning-datatable data="{rows}"></lightning-datatable>
```

**Note**: Prettier is configured to skip LWC HTML files (`.prettierignore`) to prevent corrupting bindings.

### Apex Bulkification (CRITICAL)

Never put SOQL or DML inside loops:

```apex
// WRONG - Governor limit violation
for (Account acc : accounts) {
    Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];  // NO!
    update acc;  // NO!
}

// CORRECT - Bulkified
Map<Id, Contact> contactMap = new Map<Id, Contact>([
    SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds
]);
update accounts;  // Single DML outside loop
```

### Testing Requirements

- Target 90%+ code coverage
- Every production class needs corresponding `*Test.cls` file
- Use `@TestSetup` for shared test data
- Use `Test.startTest()` / `Test.stopTest()` for async operations

```apex
@isTest
static void testMethod_scenario_expectedResult() {
    // Arrange
    Test.startTest();
    // Act
    Test.stopTest();
    // Assert
    System.assertEquals(expected, actual, 'Descriptive message');
}
```

### LWC Jest Testing

```javascript
// Always add { virtual: true } to Salesforce module mocks
jest.mock("@salesforce/apex/Controller.method", () => ({ default: jest.fn() }), { virtual: true });

// Use factory functions for class mocks
jest.mock(
  "c/pollingManager",
  () => {
    return class MockPollingManager {
      start() {}
      stop() {}
    };
  },
  { virtual: true }
);
```

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/elaro-ci.yml`) runs on push to `main`, `develop`, `release/*`, `claude/*`:

1. **code-quality** - Format check, linting, security audit
2. **unit-tests** - LWC Jest tests
3. **security-scan** - Salesforce Code Analyzer with AppExchange selectors
4. **validate-metadata** - Directory structure validation
5. **cli-build** - Platform TypeScript build
6. **build-success** - Final deployment readiness check

## Quick Validation Before Commit

```bash
# Check for LWC template violations
grep -rn '="{' force-app/main/default/lwc/**/*.html 2>/dev/null

# Run full pre-commit validation
npm run precommit
```
