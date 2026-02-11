# CLAUDE.md - AI Assistant Guide for Elaro

This document provides guidance for AI assistants working with the Elaro codebase.

## Project Overview

**Elaro** is an AI-powered compliance and governance platform for Salesforce (v3.0 Enterprise Edition). It provides:

- Configuration drift detection for Salesforce orgs
- Audit evidence automation and collection
- Multi-framework compliance scoring (HIPAA, SOC2, NIST, FedRAMP, GDPR, SOX, PCI-DSS, CCPA, GLBA, ISO 27001)
- AI-powered compliance analysis via the Compliance Copilot
- Governor limit and performance monitoring

**Target Users:** Healthcare, government, nonprofits, financial services, and regulated organizations using Salesforce.

## Technology Stack

| Layer        | Technology                                |
| ------------ | ----------------------------------------- |
| Backend      | Apex (Salesforce), API v65.0              |
| Frontend     | Lightning Web Components (LWC)            |
| UI Framework | SLDS (Salesforce Lightning Design System) |
| Testing      | Jest (LWC), Apex Test Classes             |
| Linting      | ESLint v9 with LWC plugin                 |
| Formatting   | Prettier                                  |
| CI/CD        | GitHub Actions                            |
| Node.js      | v20.0.0+ required                         |

## Directory Structure

```
elaro/
├── force-app/main/default/      # Salesforce source code
│   ├── classes/                 # Apex classes (122 production + 85 test = 207 total)
│   ├── lwc/                     # Lightning Web Components (33 components)
│   ├── objects/                 # Custom objects (46 objects)
│   ├── triggers/                # Apex triggers
│   ├── permissionsets/          # Permission sets (5 sets)
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
├── manifest/                    # Deployment manifests
├── platform/                    # Node.js CLI and tooling (Turborepo monorepo)
│   ├── packages/
│   │   ├── cli/                 # Prometheion CLI (elaro command)
│   │   ├── types/               # Shared TypeScript types
│   │   ├── sf-client/           # Salesforce API client library
│   │   └── masking/             # Data masking engine
│   ├── package.json             # Platform monorepo orchestration
│   └── turbo.json               # Turborepo build configuration
└── specs/                       # Feature specifications (Law 1: Specs Before Code)
```

## Architecture: Dual-Repo Pattern

Elaro uses a **dual-architecture pattern** with two independent but coordinated codebases:

### 1. Salesforce Domain (`force-app/`)
- **Purpose**: LWC, Apex, Salesforce metadata
- **Deployment**: Salesforce CLI (`sf` commands)
- **Testing**: Jest (LWC) + Apex test classes
- **Build**: No build step (metadata deployed directly)

### 2. Platform Domain (`platform/`)
- **Purpose**: CLI tooling, API clients, utilities
- **Deployment**: npm package linking (local development)
- **Testing**: Jest (future implementation)
- **Build**: TypeScript compilation via Turborepo

### Why Dual Architecture?

See [Architecture Decision Records](./architecture/) for full context:
- **[ADR-001: Dual-Repo Strategy](./architecture/ADR-001-dual-repo-strategy.md)** - Why we maintain separate concerns
- **[ADR-002: Monorepo Tooling](./architecture/ADR-002-monorepo-tooling.md)** - Why we use Turborepo
- **[ADR-003: Dependency Management](./architecture/ADR-003-dependency-management.md)** - How dependencies are managed

**Key Principle**: Each domain is **independent**. Salesforce code never imports platform code, and vice versa.

### Platform Packages

| Package | Purpose | Dependencies |
|---------|---------|--------------|
| `@platform/types` | Shared TypeScript types | None |
| `@platform/sf-client` | Salesforce API client (REST, Bulk, Tooling) | types |
| `@platform/masking` | Data masking engine (PII, HIPAA, PCI-DSS) | types |
| `@platform/cli` | Prometheion CLI (`elaro` command) | types, sf-client |

**Build order**: `types` → `sf-client` & `masking` (parallel) → `cli`

### Setup Workflow

```bash
# 1. Install root dependencies (Salesforce tooling)
npm install              # Postinstall hook automatically sets up platform

# 2. Verify workspace (checks node_modules, specs/, etc.)
npm run preflight

# 3. Build platform (optional, only if using CLI)
cd platform && npm run build

# 4. Link CLI globally (optional)
npm run cli:install
elaro --version
```

See [`platform/README.md`](../platform/README.md) for platform-specific documentation.

## Key Configuration Files

| File                | Purpose                                                     |
| ------------------- | ----------------------------------------------------------- |
| `sfdx-project.json` | Salesforce project config (API v65.0)                       |
| `package.json`      | NPM dependencies & scripts                                  |
| `jest.config.js`    | Jest test framework configuration                           |
| `eslint.config.js`  | ESLint rules (ES2021, LWC plugin)                           |
| `.prettierrc`       | Code formatting (semicolons, double quotes, 100 char width) |
| `.forceignore`      | Deployment exclusions                                       |

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
sf org assign permset --name Elaro_Admin --target-org <org>
```

### Pre-commit Validation

The pre-commit hook runs automatically via Husky:

1. `npm run fmt:check` - Prettier format check
2. `npm run lint` - ESLint validation
3. `npm run test:unit` - Jest unit tests

## Code Conventions

### Apex Classes

**Naming Conventions:**

- Production classes: `PascalCase` (e.g., `ComplianceBaselineScanner`, `ElaroSecurityUtils`)
- Test classes: `<ClassName>Test` (e.g., `ComplianceDashboardControllerTest`)
- Controller classes: `<Feature>Controller` (e.g., `ComplianceDashboardController`)
- Service classes: `<Domain>Service` (e.g., `ComplianceFrameworkService`)
- Queueable classes: `<Feature>Queueable` (e.g., `ElaroSlackNotifierQueueable`)

**Security Requirements (CRITICAL):**

- Always use `WITH SECURITY_ENFORCED` on SOQL queries
- Use `ElaroSecurityUtils` for CRUD/FLS checks
- All classes must use `with sharing` keyword
- Strip inaccessible fields before returning data to LWC

```apex
// Good: Secure SOQL query
List<Account> accounts = [
    SELECT Id, Name FROM Account
    WITH SECURITY_ENFORCED
];

// Good: Using security utils
ElaroSecurityUtils.validateCRUDAccess('Account', DmlOperation.DML_UPDATE);
```

**Documentation Pattern:**

```apex
/**
 * ClassName
 *
 * Brief description of the class purpose
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class ClassName {
    // Implementation
}
```

### Lightning Web Components

**Naming:**

- Component folders: `camelCase` (e.g., `complianceDashboard`, `elaroCopilot`)
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
| `elaroDashboard` | Main compliance dashboard |
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
| `Elaro_AI_Settings__c` | AI configuration |
| `Elaro_Audit_Log__c` | Audit trail |
| `Elaro_Compliance_Graph__b` | Big Object for graph data |

**Platform Events:**

- `Performance_Alert__e` - Performance threshold alerts
- `Elaro_Alert_Event__e` - General alerts
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

GitHub Actions workflow (`.github/workflows/elaro-ci.yml`):

1. **code-quality** - Format check, linting, security audit
2. **unit-tests** - LWC Jest tests
3. **validate-metadata** - Directory structure validation
4. **build-success** - Final deployment readiness check

**Triggers:** Push to `main`, `develop`, `release/*`, `claude/*` branches

## Permission Sets

| Permission Set         | Purpose                |
| ---------------------- | ---------------------- |
| `Elaro_Admin`    | Full admin access      |
| `Elaro_Auditor`  | Read-only audit access |
| `Elaro_User`     | Standard user access   |
| `Elaro_API_User` | API integration access |

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
- [ ] CRUD/FLS checks via `ElaroSecurityUtils`
- [ ] Classes use `with sharing` keyword
- [ ] No hardcoded credentials or secrets
- [ ] Input validation on all user inputs
- [ ] XSS prevention in LWC templates

### Performance Considerations

- Use batch Apex for large data operations
- Use Platform Events for async processing
- Cache expensive operations where appropriate
- Be mindful of governor limits

### Apex Bulkification (CRITICAL)

Never perform SOQL or DML inside loops:

```apex
// WRONG - Governor limit violation
for (Account acc : accounts) {
    Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];  // NO!
    update acc;  // NO!
}

// RIGHT - Bulkified
Map<Id, Contact> contactMap = new Map<Id, Contact>([
    SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds
]);
update accounts;  // Single DML outside loop
```

### LWC Template Syntax (CRITICAL)

Never quote template bindings - this causes compile errors:

```html
<!-- WRONG - Causes LWC1034 error -->
<lightning-datatable data="{rows}" columns="{columns}"></lightning-datatable>
<lightning-button onclick="{handleClick}"></lightning-button>

<!-- RIGHT - No quotes around bindings -->
<lightning-datatable data="{rows}" columns="{columns}"></lightning-datatable>
<lightning-button onclick="{handleClick}"></lightning-button>
```

**Note:** Prettier can corrupt LWC HTML files by adding quotes. LWC HTML files are excluded in `.prettierignore` to prevent this.

### LWC Jest Testing Patterns

```javascript
// Always add { virtual: true } to Salesforce module mocks
jest.mock(
  "@salesforce/apex/Controller.method",
  () => ({
    default: jest.fn(),
  }),
  { virtual: true }
);

// Use factory functions for class mocks (avoids hoisting issues)
jest.mock(
  "c/pollingManager",
  () => {
    return class MockPollingManager {
      constructor(callback, interval) {
        this.callback = callback;
        this.interval = interval;
      }
      start() {}
      stop() {}
      cleanup() {}
    };
  },
  { virtual: true }
);

// Never access private properties in tests
// WRONG: expect(element.rows).toEqual([])
// RIGHT: expect(element.shadowRoot.querySelector("lightning-datatable")).not.toBeNull()
```

## Git Workflow (MANDATORY)

### Before Starting Work

```bash
# Always sync with remote first
git fetch origin
git pull origin <current-branch>
```

### After Making Changes (ALWAYS DO THIS)

```bash
# 1. Check what changed
git status

# 2. Run quality checks
npm run lint
npm run test:unit
npm run fmt

# 3. Stage and commit
git add -A
git commit -m "type: Description of changes"

# 4. Push to remote
git push -u origin <current-branch>

# 5. Verify sync
git status
```

### Commit Message Format

```
type: Brief description

Types: feat, fix, test, docs, refactor, style
```

### IMPORTANT

- ALWAYS commit and push after completing work
- ALWAYS pull before starting new work
- NEVER leave uncommitted changes
- Check that local and remote are in sync before ending session

---

## Code Quality Checks (MANDATORY)

### Before Coding

1. **Check for LWC Template Syntax Violations** (if modifying LWC templates):

   ```bash
   # Find any quoted bindings that will cause LWC1034 errors
   grep -rn '="{' force-app/main/default/lwc/**/*.html 2>/dev/null | grep -v node_modules
   ```

   - If found, fix BEFORE making other changes
   - Pattern: `data="{rows}"` must become `data={rows}`

2. **Check for SOQL Without Security**:

   ```bash
   # Find SOQL queries missing WITH SECURITY_ENFORCED
   grep -rn "SELECT.*FROM" force-app/main/default/classes/*.cls | grep -v "WITH SECURITY_ENFORCED" | grep -v "Test.cls"
   ```

3. **Check for Hardcoded Record IDs**:

   ```bash
   # Find potential hardcoded Salesforce IDs (15 or 18 char)
   grep -rn "['\"][a-zA-Z0-9]\{15,18\}['\"]" force-app/main/default/classes/*.cls
   ```

4. **Check for System.debug in Production Code**:

   ```bash
   # Find debug statements (should be removed before commit)
   grep -rn "System.debug" force-app/main/default/classes/*.cls | grep -v Test.cls
   ```

5. **Check for API Version Consistency**:
   ```bash
   # All metadata should use API version 65.0
   grep -rn "apiVersion" force-app/main/default/**/*.xml | grep -v "65.0"
   ```

### After Coding

Run these checks EVERY TIME before committing:

```bash
# 1. Lint check (must pass with 0 warnings for LWC)
npm run lint

# 2. Format check
npm run fmt:check

# 3. Unit tests (all 67 must pass)
npm run test:unit

# 4. Check for LWC template corruption
grep -rn '="{' force-app/main/default/lwc/**/*.html 2>/dev/null | head -5

# 5. Verify no uncommitted changes remain
git status
```

### Quick Pre-Commit Validation Script

```bash
#!/bin/bash
# Run this before every commit

echo "=== Pre-Commit Validation ==="

# Check for LWC template violations
if grep -rq '="{' force-app/main/default/lwc/**/*.html 2>/dev/null; then
    echo "❌ FAIL: LWC template has quoted bindings (will cause LWC1034)"
    grep -rn '="{' force-app/main/default/lwc/**/*.html 2>/dev/null
    exit 1
fi
echo "✅ LWC templates OK"

# Run lint
if ! npm run lint --silent; then
    echo "❌ FAIL: Lint errors"
    exit 1
fi
echo "✅ Lint OK"

# Run tests
if ! npm run test:unit --silent; then
    echo "❌ FAIL: Unit tests failed"
    exit 1
fi
echo "✅ Tests OK"

echo "=== All checks passed ==="
```

### Common Violations Checklist

| Issue                     | Detection                | Fix                             |
| ------------------------- | ------------------------ | ------------------------------- |
| LWC quoted bindings       | `grep '="{' *.html`      | Remove quotes: `data={rows}`    |
| Missing SECURITY_ENFORCED | grep SOQL without clause | Add `WITH SECURITY_ENFORCED`    |
| SOQL in loop              | Manual review            | Bulkify queries outside loop    |
| DML in loop               | Manual review            | Collect records, single DML     |
| Unused catch variable     | ESLint warning           | Use `catch { }` or `catch (_e)` |
| Missing test coverage     | sf apex run test         | Add test methods                |
| Wrong API version         | grep apiVersion          | Update to 63.0                  |

---

### Legacy Note

The project was previously named "Sentinel" - some references may still exist in configuration files. The current branding is **Elaro**.

## Useful Resources

- [README.md](README.md) - Project overview and quick start
- [TECHNICAL_DEEP_DIVE.md](TECHNICAL_DEEP_DIVE.md) - Detailed architecture
- [API_REFERENCE.md](API_REFERENCE.md) - API documentation
- [docs/COMPLIANCE_FRAMEWORKS_CODE_REFERENCE.md](docs/COMPLIANCE_FRAMEWORKS_CODE_REFERENCE.md) - Framework code patterns
- [ROADMAP.md](ROADMAP.md) - Feature roadmap
