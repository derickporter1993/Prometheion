# CLAUDE.md - AI Assistant Guide for Prometheion

This document provides guidance for AI assistants working with the Prometheion codebase.

## Project Overview

**Prometheion** is an AI-powered compliance and governance platform for Salesforce (v3.0 Enterprise Edition). It provides:

- Configuration drift detection for Salesforce orgs
- Audit evidence automation and collection
- Multi-framework compliance scoring (HIPAA, SOC2, NIST, FedRAMP, GDPR, SOX, PCI-DSS, CCPA, GLBA, ISO 27001)
- AI-powered compliance analysis via the Compliance Copilot
- Governor limit and performance monitoring

**Target Users:** Healthcare, government, nonprofits, financial services, and regulated organizations using Salesforce.

## Technology Stack

| Layer | Technology |
|-------|------------|
| Backend | Apex (Salesforce), API v63.0 |
| Frontend | Lightning Web Components (LWC) |
| UI Framework | SLDS (Salesforce Lightning Design System) |
| Testing | Jest (LWC), Apex Test Classes |
| Linting | ESLint v9 with LWC plugin |
| Formatting | Prettier |
| CI/CD | GitHub Actions |
| Node.js | v20.0.0+ required |

## Directory Structure

```
prometheion/
├── force-app/main/default/      # Salesforce source code
│   ├── classes/                 # Apex classes (~78 production + ~66 test)
│   ├── lwc/                     # Lightning Web Components (30 components)
│   ├── objects/                 # Custom objects (~33 objects)
│   ├── triggers/                # Apex triggers
│   ├── permissionsets/          # Permission sets (4 sets)
│   ├── events/                  # Platform events
│   ├── flexipages/              # Flex pages for UI layouts
│   ├── customMetadata/          # Custom metadata types
│   ├── namedCredentials/        # External service configurations
│   ├── labels/                  # Custom labels
│   ├── applications/            # App definitions
│   └── tabs/                    # Custom tabs
├── scripts/                     # Automation and deployment scripts
│   ├── orgInit.sh               # Scratch org initialization
│   ├── scheduleApiSnapshot.sh   # Periodic scan scheduling
│   └── create-test-data.apex    # Test data generation
├── config/                      # Salesforce project configuration
├── docs/                        # Extended documentation
├── examples/                    # Sample outputs and reports
├── .github/workflows/           # GitHub Actions CI/CD
├── .husky/                      # Git hooks (pre-commit)
└── manifest/                    # Deployment manifests
```

## Key Configuration Files

| File | Purpose |
|------|---------|
| `sfdx-project.json` | Salesforce project config (API v63.0) |
| `package.json` | NPM dependencies & scripts |
| `jest.config.js` | Jest test framework configuration |
| `eslint.config.js` | ESLint rules (ES2021, LWC plugin) |
| `.prettierrc` | Code formatting (semicolons, double quotes, 100 char width) |
| `.forceignore` | Deployment exclusions |

## Development Commands

### Code Quality

```bash
# Format code
npm run fmt

# Check formatting (CI uses this)
npm run fmt:check

# Run linter (max 3 warnings allowed)
npm run lint

# Fix lint issues automatically
npm run lint:fix
```

### Testing

```bash
# Run LWC unit tests
npm run test:unit

# Run tests in watch mode
npm run test:unit:watch

# Run all Apex tests (in org)
sf apex run test --target-org <org> --code-coverage

# Run specific Apex test class
sf apex run test --target-org <org> --tests <TestClassName>
```

### Deployment

```bash
# Deploy to org
sf project deploy start --target-org <org>

# Create scratch org
./scripts/orgInit.sh

# Assign permission set
sf org assign permset --name Prometheion_Admin --target-org <org>
```

### Pre-commit Validation

The pre-commit hook runs automatically via Husky:
1. `npm run fmt:check` - Prettier format check
2. `npm run lint` - ESLint validation
3. `npm run test:unit` - Jest unit tests

## Code Conventions

### Apex Classes

**Naming Conventions:**
- Production classes: `PascalCase` (e.g., `ComplianceBaselineScanner`, `PrometheionSecurityUtils`)
- Test classes: `<ClassName>Test` (e.g., `ComplianceDashboardControllerTest`)
- Controller classes: `<Feature>Controller` (e.g., `ComplianceDashboardController`)
- Service classes: `<Domain>Service` (e.g., `ComplianceFrameworkService`)
- Queueable classes: `<Feature>Queueable` (e.g., `PrometheionSlackNotifierQueueable`)

**Security Requirements (CRITICAL):**
- Always use `WITH SECURITY_ENFORCED` on SOQL queries
- Use `PrometheionSecurityUtils` for CRUD/FLS checks
- All classes must use `with sharing` keyword
- Strip inaccessible fields before returning data to LWC

```apex
// Good: Secure SOQL query
List<Account> accounts = [
    SELECT Id, Name FROM Account
    WITH SECURITY_ENFORCED
];

// Good: Using security utils
PrometheionSecurityUtils.validateCRUDAccess('Account', DmlOperation.DML_UPDATE);
```

**Documentation Pattern:**
```apex
/**
 * ClassName
 *
 * Brief description of the class purpose
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class ClassName {
    // Implementation
}
```

### Lightning Web Components

**Naming:**
- Component folders: `camelCase` (e.g., `complianceDashboard`, `prometheionCopilot`)
- Test files: `__tests__/<componentName>.test.js`

**Controller Integration:**
```javascript
import getMethod from "@salesforce/apex/ControllerName.methodName";

@wire(getMethod, { param: "$value" })
wiredResult;
```

**Key LWC Components:**
| Component | Purpose |
|-----------|---------|
| `prometheionDashboard` | Main compliance dashboard |
| `complianceCopilot` | AI compliance assistant |
| `complianceScoreCard` | Framework score display |
| `systemMonitorDashboard` | Governor limits monitoring |
| `apiUsageDashboard` | API usage tracking |
| `flowExecutionMonitor` | Flow monitoring |
| `performanceAlertPanel` | Real-time alerts |

### Custom Objects

**Key Objects:**
| Object | Purpose |
|--------|---------|
| `Compliance_Score__c` | Stores compliance scores |
| `Compliance_Gap__c` | Tracks compliance gaps |
| `Compliance_Evidence__c` | Audit evidence records |
| `API_Usage_Snapshot__c` | API limit tracking |
| `Performance_Alert_History__c` | Alert history |
| `Prometheion_AI_Settings__c` | AI configuration |
| `Prometheion_Audit_Log__c` | Audit trail |
| `Prometheion_Compliance_Graph__b` | Big Object for graph data |

**Platform Events:**
- `Performance_Alert__e` - Performance threshold alerts
- `Prometheion_Alert_Event__e` - General alerts
- `GDPR_Erasure_Event__e` - GDPR data erasure events
- `PCI_Access_Event__e` - PCI access logging

## Testing Patterns

### Apex Test Classes

```apex
@isTest
public class MyClassTest {

    @TestSetup
    static void setup() {
        // Create test data
    }

    @isTest
    static void testMethodName_Scenario_ExpectedResult() {
        // Arrange
        // Act
        Test.startTest();
        // ... call method
        Test.stopTest();
        // Assert
        System.assertEquals(expected, actual, 'Error message');
    }
}
```

**Test Requirements:**
- Target 95%+ code coverage
- Each production class has corresponding `*Test.cls` file
- Use `@TestSetup` for shared test data
- Use `Test.startTest()` / `Test.stopTest()` for async operations
- Use mock classes for callouts (e.g., `ApiLimitsCalloutMock`)

### LWC Tests

```javascript
import { createElement } from "lwc";
import { getNavigateCalledWith } from "lightning/navigation";
import { createLdsTestWireAdapter } from "@salesforce/wire-service-jest-util";
import MyComponent from "c/myComponent";
import getMethod from "@salesforce/apex/Controller.getMethod";

// Create wire adapter for mocking
const getMethodAdapter = createLdsTestWireAdapter(getMethod);

describe("c-my-component", () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it("should render correctly", async () => {
        const element = createElement("c-my-component", { is: MyComponent });
        document.body.appendChild(element);

        // Emit mock data
        getMethodAdapter.emit({ data: mockData });

        await Promise.resolve();

        // Assert
        expect(element.shadowRoot.querySelector("div")).toBeTruthy();
    });
});
```

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/prometheion-ci.yml`):

1. **code-quality** - Format check, linting, security audit
2. **unit-tests** - LWC Jest tests
3. **validate-metadata** - Directory structure validation
4. **build-success** - Final deployment readiness check

**Triggers:** Push to `main`, `develop`, `release/*`, `claude/*` branches

## Permission Sets

| Permission Set | Purpose |
|----------------|---------|
| `Prometheion_Admin` | Full admin access |
| `Prometheion_Auditor` | Read-only audit access |
| `Prometheion_User` | Standard user access |
| `Prometheion_API_User` | API integration access |

## Common Tasks

### Adding a New Apex Class

1. Create class in `force-app/main/default/classes/<ClassName>.cls`
2. Create corresponding test class `<ClassName>Test.cls`
3. Add `with sharing` keyword
4. Use `WITH SECURITY_ENFORCED` on all SOQL queries
5. Add to relevant permission set if needed
6. Run `npm run lint` and `npm run fmt`

### Adding a New LWC Component

1. Create folder `force-app/main/default/lwc/<componentName>/`
2. Create files: `<componentName>.html`, `<componentName>.js`, `<componentName>.js-meta.xml`
3. Create test file: `__tests__/<componentName>.test.js`
4. Follow SLDS styling conventions
5. Run `npm run test:unit` to verify tests pass

### Fixing Lint/Format Issues

```bash
# Auto-fix formatting
npm run fmt

# Auto-fix lint issues
npm run lint:fix

# Manual check
npm run precommit
```

## Important Notes

### Security Checklist

- [ ] All SOQL uses `WITH SECURITY_ENFORCED`
- [ ] CRUD/FLS checks via `PrometheionSecurityUtils`
- [ ] Classes use `with sharing` keyword
- [ ] No hardcoded credentials or secrets
- [ ] Input validation on all user inputs
- [ ] XSS prevention in LWC templates

### Performance Considerations

- Use batch Apex for large data operations
- Use Platform Events for async processing
- Cache expensive operations where appropriate
- Be mindful of governor limits

### Legacy Note

The project was previously named "Sentinel" - some references may still exist in configuration files. The current branding is **Prometheion**.

## Useful Resources

- [README.md](README.md) - Project overview and quick start
- [TECHNICAL_DEEP_DIVE.md](TECHNICAL_DEEP_DIVE.md) - Detailed architecture
- [API_REFERENCE.md](API_REFERENCE.md) - API documentation
- [docs/COMPLIANCE_FRAMEWORKS_CODE_REFERENCE.md](docs/COMPLIANCE_FRAMEWORKS_CODE_REFERENCE.md) - Framework code patterns
- [ROADMAP.md](ROADMAP.md) - Feature roadmap
