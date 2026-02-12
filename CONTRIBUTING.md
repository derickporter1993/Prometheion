# Contributing to Elaro

Thank you for your interest in contributing to Elaro! This document provides guidelines and standards for contributing to this Salesforce compliance automation platform.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Security Vulnerabilities](#security-vulnerabilities)

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please be respectful and professional in all interactions.

## Getting Started

### Prerequisites

- **Node.js**: v20.0.0 or higher
- **Salesforce CLI**: Latest version (`sf` CLI, not deprecated `sfdx`)
- **Git**: Latest version
- **DevHub**: Authenticated Salesforce DevHub org for scratch org creation

### Initial Setup

1. **Fork and clone the repository**:

   ```bash
   git clone https://github.com/derickporter1993/elaro.git
   cd elaro
   ```

2. **Install dependencies**:

   ```bash
   npm install
   ```

3. **Create a scratch org** (recommended for development):

   ```bash
   ./scripts/orgInit.sh
   ```

4. **Verify your environment**:
   ```bash
   npm run precommit  # Runs format check, linting, and unit tests
   ```

## Development Workflow

### Branch Naming

Use descriptive branch names that follow this pattern:

- `feature/[feature-name]` - New features
- `fix/[bug-name]` - Bug fixes
- `docs/[doc-name]` - Documentation updates
- `refactor/[scope]` - Code refactoring
- `test/[test-scope]` - Test additions/improvements

Examples:

- `feature/ai-governance-module`
- `fix/governor-limit-soql-loop`
- `docs/update-readme-installation`

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**

```
feat(health-check): add security baseline scanner

fix(pci-logger): bulkify alert creation to avoid governor limits

docs(contributing): add coding standards section

test(ai-governance): add edge case tests for AI system registry
```

## Coding Standards

### Apex Standards

#### 1. Security First (CRITICAL)

**SOQL Security:**

```apex
// ✅ CORRECT - Use WITH USER_MODE (Spring '26 standard)
List<Account> accounts = [
    SELECT Id, Name
    FROM Account
    WHERE Industry = 'Healthcare'
    WITH USER_MODE
];

// ❌ WRONG - Never use WITH SECURITY_ENFORCED (deprecated)
List<Account> accounts = [
    SELECT Id, Name
    FROM Account
    WITH SECURITY_ENFORCED
];

// ✅ CORRECT - Dynamic SOQL with Database.queryWithBinds()
Map<String, Object> binds = new Map<String, Object>{
    'status' => 'Active'
};
List<SObject> results = Database.queryWithBinds(
    'SELECT Id FROM Account WHERE Status__c = :status WITH USER_MODE',
    binds,
    AccessLevel.USER_MODE
);

// ❌ WRONG - Never use string concatenation
String query = 'SELECT Id FROM Account WHERE Name = \'' + userInput + '\'';
```

**DML Security:**

```apex
// ✅ CORRECT - Always use 'as user'
insert as user newRecords;
update as user existingRecords;
delete as user oldRecords;

// ✅ CORRECT - Database methods with AccessLevel
Database.insert(records, AccessLevel.USER_MODE);
Database.update(records, AccessLevel.USER_MODE);
// With allOrNone parameter:
Database.insert(records, false, AccessLevel.USER_MODE);
Database.update(records, true, AccessLevel.USER_MODE);
```

#### 2. Sharing Keywords

```apex
// Controllers (entry points) - enforces sharing
public with sharing class MyController { }

// Services, utilities, handlers - inherits caller context
public inherited sharing class MyService { }

// System operations ONLY - document why
/**
 * SECURITY: without sharing required for Platform Event publishing
 * which must succeed regardless of user's record access.
 */
public without sharing class MyEventPublisher { }
```

#### 3. Bulkification (Governor Limit Best Practices)

**✅ CORRECT - Bulkified Pattern:**

```apex
public class BulkifiedHandler {
    public void processRecords(List<Account> accounts) {
        // Step 1: Collect all IDs
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        // Step 2: Single SOQL query outside loop
        Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();
        for (Contact c : [
            SELECT Id, AccountId, Email
            FROM Contact
            WHERE AccountId IN :accountIds
            WITH USER_MODE
        ]) {
            if (!contactsByAccount.containsKey(c.AccountId)) {
                contactsByAccount.put(c.AccountId, new List<Contact>());
            }
            contactsByAccount.get(c.AccountId).add(c);
        }

        // Step 3: Process and collect DML operations
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Account acc : accounts) {
            List<Contact> contacts = contactsByAccount.get(acc.Id);
            if (contacts != null) {
                for (Contact c : contacts) {
                    c.Description = 'Updated';
                    contactsToUpdate.add(c);
                }
            }
        }

        // Step 4: Single DML operation
        if (!contactsToUpdate.isEmpty()) {
            update as user contactsToUpdate;
        }
    }
}
```

**❌ WRONG - Non-Bulkified Pattern:**

```apex
public class NonBulkifiedHandler {
    public void processRecords(List<Account> accounts) {
        for (Account acc : accounts) {
            // ❌ SOQL in loop - will hit governor limits
            List<Contact> contacts = [
                SELECT Id FROM Contact
                WHERE AccountId = :acc.Id
                WITH USER_MODE
            ];

            for (Contact c : contacts) {
                c.Description = 'Updated';
                // ❌ DML in loop - will hit governor limits
                update as user c;
            }
        }
    }
}
```

#### 4. Null Safety

```apex
// ✅ Use null coalescing operator (??)
String name = account.Name ?? 'Unknown';
String value = a ?? b ?? c ?? 'default';

// ✅ Use safe navigation (?.)
String ownerName = [
    SELECT Owner.Name
    FROM Case
    WHERE Id = :caseId
    LIMIT 1
]?.Owner?.Name ?? 'Unassigned';
```

#### 5. ApexDoc Requirements

Every public/global class and method MUST have ApexDoc:

```apex
/**
 * Processes compliance scans for HIPAA and SOC2 frameworks.
 *
 * @author Elaro Team
 * @since v3.0.0 (Spring '26)
 * @group Compliance Scanning
 * @see ComplianceServiceFactory
 * @see IComplianceModule
 */
public inherited sharing class ComplianceScanner {

    /**
     * Executes a compliance scan for the specified framework.
     *
     * @param framework The compliance framework to scan (HIPAA, SOC2, etc.)
     * @param includeDetails Whether to include detailed findings
     * @return ComplianceResult containing score and findings
     * @throws AuraHandledException if user lacks required permissions
     * @example
     * ComplianceResult result = new ComplianceScanner().scan('HIPAA', true);
     * System.debug('Score: ' + result.score);
     */
    public ComplianceResult scan(String framework, Boolean includeDetails) {
        // implementation
    }
}
```

#### 6. Error Handling

```apex
@AuraEnabled(cacheable=true)
public static ComplianceResult runScan() {
    try {
        // Business logic
        return new ComplianceScanner().scan('HIPAA', true);
    } catch (Exception e) {
        // Use ElaroLogger for structured logging
        ElaroLogger.error('ComplianceController.runScan', e.getMessage(), e.getStackTraceString());

        // Throw user-friendly message
        throw new AuraHandledException(
            'Unable to complete the compliance scan. Please verify permissions and try again.'
        );
    }
}
```

#### 7. Asynchronous Patterns

```apex
// ✅ PREFERRED - Queueable (NOT @future)
public class ScanProcessor implements Queueable {
    private List<Account> accounts;

    public ScanProcessor(List<Account> accounts) {
        this.accounts = accounts;
    }

    public void execute(QueueableContext ctx) {
        // Process accounts
        for (Account acc : accounts) {
            // Process logic
        }
    }
}

// Usage
System.enqueueJob(new ScanProcessor(accountList));
```

### Lightning Web Component Standards

#### 1. Conditional Rendering

```html
<!-- ✅ CORRECT - Use lwc:if / lwc:elseif / lwc:else -->
<template lwc:if="{isLoading}">
  <lightning-spinner alternative-text="Loading"></lightning-spinner>
</template>
<template lwc:elseif="{hasError}">
  <c-error-panel message="{errorMessage}"></c-error-panel>
</template>
<template lwc:else>
  <!-- Main content -->
</template>

<!-- ❌ WRONG - Never use if:true / if:false -->
<template if:true="{isLoading}">
  <lightning-spinner></lightning-spinner>
</template>
```

#### 2. Custom Labels (Required for i18n)

```javascript
// ✅ CORRECT - Use Custom Labels for all user-facing strings
import NoDataAvailable from '@salesforce/label/c.NoDataAvailable';
import ScanInProgress from '@salesforce/label/c.ScanInProgress';
import ErrorGeneric from '@salesforce/label/c.ErrorGeneric';

export default class MyComponent extends LightningElement {
    label = { NoDataAvailable, ScanInProgress, ErrorGeneric };
}

// ❌ WRONG - Never hardcode strings
<p>No data available</p>  <!-- Bad -->
<p>{label.NoDataAvailable}</p>  <!-- Good -->
```

#### 3. WCAG 2.1 AA Compliance

- Always include ARIA labels
- Support keyboard navigation
- Maintain proper focus management
- Use SLDS for styling consistency

### File Naming Conventions

- **Apex Classes**: `PascalCase.cls`
  - Controllers: `[Name]Controller.cls`
  - Services: `[Name]Service.cls`
  - Tests: `[ClassName]Test.cls`
- **LWC Components**: `camelCase` folder names
- **Objects**: `PascalCase__c`
- **Fields**: `Snake_Case__c`

## Testing Requirements

### Apex Testing

#### Minimum Coverage: 85% per class

```apex
@IsTest(testFor=HealthCheckScanner.class)
private class HealthCheckScannerTest {

    @TestSetup
    static void makeData() {
        // Create shared test data once per class
        Account testAccount = new Account(Name = 'Test Corp');
        insert as user testAccount;
    }

    @IsTest
    static void shouldCalculateCorrectScore() {
        // ALWAYS use Test.startTest() / Test.stopTest()
        Test.startTest();
        HealthCheckResult result = HealthCheckController.runFullScan();
        Test.stopTest();

        // Use Assert class (NEVER System.assertEquals)
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(
            result.overallScore >= 0 && result.overallScore <= 100,
            'Score should be 0-100, got: ' + result.overallScore
        );
    }

    @IsTest
    static void shouldHandleGovernorLimitEdgeCases() {
        // Create bulk test data
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Test ' + i));
        }
        insert as user accounts;

        Test.startTest();
        // Test with 200 records
        HealthCheckResult result = HealthCheckController.runBulkScan(accounts);
        Test.stopTest();

        Assert.isNotNull(result, 'Bulk scan should complete');
    }
}
```

#### Required Assertions

```apex
// ✅ CORRECT - Use Assert class
Assert.areEqual(expected, actual, 'Message');
Assert.areNotEqual(bad, actual, 'Message');
Assert.isTrue(condition, 'Message');
Assert.isFalse(condition, 'Message');
Assert.isNotNull(result, 'Message');
Assert.isInstanceOfType(obj, MyClass.class, 'Message');

// ❌ WRONG - Never use System.assert*
System.assertEquals(expected, actual);  // Deprecated
System.assert(condition);  // Deprecated
```

### LWC Testing (Jest)

```javascript
import { createElement } from "lwc";
import MyComponent from "c/myComponent";

// Mock Salesforce modules with { virtual: true }
jest.mock("@salesforce/apex/HealthCheckController.runFullScan", () => ({ default: jest.fn() }), {
  virtual: true,
});

describe("c-my-component", () => {
  // Note: DOM cleanup is handled globally in lwc/__tests__/setupTests.js
  // Use safeCleanupDom() for wire-adapter disconnect edge cases if needed

  it("renders loading state", () => {
    const element = createElement("c-my-component", { is: MyComponent });
    document.body.appendChild(element);

    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });
});
```

### Running Tests

```bash
# Run all LWC Jest tests
npm run test:unit

# Run in watch mode for TDD
npm run test:unit:watch

# Run Apex tests in scratch org
sf apex run test --target-org <org> --code-coverage

# Run specific test class
sf apex run test --target-org <org> --tests HealthCheckScannerTest
```

## Pull Request Process

### Before Submitting

1. **Run all quality checks**:

   ```bash
   npm run precommit  # Formatting, linting, unit tests
   ```

2. **Run Apex tests** (if you modified Apex code):

   ```bash
   sf apex run test --target-org <org> --code-coverage
   ```

3. **Run Code Analyzer**:

   ```bash
   sf scanner run --target force-app/ --severity-threshold 2
   ```

4. **Verify no security issues**:
   - No hardcoded credentials
   - All SOQL uses `WITH USER_MODE`
   - All DML uses `as user` or `AccessLevel.USER_MODE`

### PR Template

Use this template when creating a pull request:

```markdown
## Description

Brief description of changes and why they're needed.

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Code refactoring

## Testing

- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Tested in scratch org
- [ ] Code coverage >85% for new/modified classes

## Security Checklist

- [ ] All SOQL queries use WITH USER_MODE
- [ ] All DML operations use 'as user'
- [ ] No hardcoded credentials or sensitive data
- [ ] ApexDoc added for all public methods
- [ ] Governor limits considered (bulkified code)

## Screenshots (if applicable)

Add screenshots for UI changes.

## Related Issues

Fixes #[issue number]
```

### Review Process

1. **Automated Checks**: All CI checks must pass
2. **Code Review**: At least one approval required
3. **Security Review**: For changes to security-sensitive code
4. **Merge**: Squash and merge to keep history clean

## Issue Reporting

### Bug Reports

Use this template when reporting bugs:

```markdown
**Describe the Bug**
Clear description of what went wrong.

**To Reproduce**
Steps to reproduce:

1. Go to '...'
2. Click on '...'
3. See error

**Expected Behavior**
What should have happened.

**Screenshots**
If applicable, add screenshots.

**Environment**

- Salesforce Edition: [e.g., Enterprise, Unlimited]
- API Version: [e.g., v66.0]
- Browser: [e.g., Chrome 120]

**Additional Context**
Any other relevant information.
```

### Feature Requests

```markdown
**Feature Description**
Clear description of the proposed feature.

**Use Case**
Why is this feature needed? What problem does it solve?

**Proposed Solution**
How would you implement this?

**Alternatives Considered**
Other approaches you've considered.
```

## Security Vulnerabilities

**DO NOT** open public issues for security vulnerabilities.

Instead, email security details to: **security@elaro.io**

We will respond within 48 hours and work with you to address the issue.

## Code Quality Tools

### Pre-commit Hooks

We use Husky to enforce code quality:

```bash
# Runs automatically on git commit
- npm run fmt:check  # Prettier formatting
- npm run lint       # ESLint validation
- npm run test:unit  # LWC Jest tests
```

### Manual Quality Checks

```bash
# Format all code
npm run fmt

# Fix auto-fixable lint issues
npm run lint:fix

# Run Salesforce Code Analyzer
sf scanner run --target force-app/ --format table
```

## Additional Resources

- **[README.md](README.md)** - Project overview and setup
- **[CLAUDE.md](CLAUDE.md)** - Complete coding standards and patterns
- **[API_REFERENCE.md](API_REFERENCE.md)** - API documentation
- **[Salesforce CLI Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)** - CLI command reference

## Questions?

- **Discussions**: [GitHub Discussions](https://github.com/derickporter1993/elaro/discussions)
- **Issues**: [GitHub Issues](https://github.com/derickporter1993/elaro/issues)
- **Email**: support@elaro.io

---

Thank you for contributing to Elaro! Together, we're making Salesforce compliance automation accessible to all regulated organizations.
