# Contributing to Prometheion

Thank you for your interest in contributing to Prometheion! This document provides guidelines and best practices for contributing to the project.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing Requirements](#testing-requirements)
6. [Commit Guidelines](#commit-guidelines)
7. [Pull Request Process](#pull-request-process)
8. [Documentation](#documentation)
9. [Security](#security)

---

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please:

- **Be respectful** and considerate in all interactions
- **Be collaborative** and help others learn and grow
- **Be patient** with questions and feedback
- **Be constructive** in criticism and suggestions

---

## Getting Started

### Prerequisites

- **Salesforce CLI:** `npm install -g @salesforce/cli`
- **Node.js:** v20.0.0 or higher
- **Git:** Latest version
- **IDE:** VS Code with Salesforce extensions (recommended)

### Repository Setup

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR_USERNAME/prometheion.git
cd prometheion

# Add upstream remote
git remote add upstream https://github.com/prometheion/prometheion.git

# Install dependencies
npm install

# Create scratch org
./scripts/orgInit.sh

# Assign permission set
sf org assign permset --name Prometheion_Admin
```

---

## Development Workflow

### 1. Create a Feature Branch

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name
```

**Branch Naming Conventions:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions/improvements
- `chore/` - Maintenance tasks

### 2. Make Changes

- Follow [coding standards](#coding-standards)
- Write tests for new functionality
- Update documentation as needed
- Run linter and formatter before committing

### 3. Test Your Changes

```bash
# Format code
npm run fmt

# Run linter
npm run lint

# Run LWC unit tests
npm run test:unit

# Run Apex tests in scratch org
sf apex run test --target-org YOUR_ORG --code-coverage --result-format human
```

### 4. Commit Your Changes

```bash
# Stage changes
git add .

# Commit with conventional commit message
git commit -m "feat: add compliance score trend analysis"

# Pre-commit hooks will run automatically
```

### 5. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create PR on GitHub targeting main branch
```

---

## Coding Standards

### Apex Classes

#### File Organization

```apex
/**
 * @description Class purpose
 * @group Group name
 * @author Author name
 * @version 1.0
 */
public with sharing class ClassName {

    // Constants (UPPER_SNAKE_CASE)
    private static final Integer MAX_RETRIES = 3;

    // Instance variables (camelCase)
    private String instanceVariable;

    // Constructor
    public ClassName() {
        this.instanceVariable = 'value';
    }

    // Public methods
    /**
     * @description Method purpose
     * @param param Parameter description
     * @return Return value description
     */
    public String publicMethod(String param) {
        return 'result';
    }

    // Private methods
    private void privateMethod() {
        // Implementation
    }
}
```

#### Naming Conventions

- **Classes:** `PascalCase` (e.g., `ComplianceDashboardController`)
- **Methods:** `camelCase` (e.g., `getComplianceScores`)
- **Variables:** `camelCase` (e.g., `userEmail`)
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `MAX_BATCH_SIZE`)
- **Test Classes:** `ClassNameTest` (e.g., `ComplianceDashboardControllerTest`)

#### Security Requirements (CRITICAL)

**All Apex classes MUST:**

1. **Use `with sharing` keyword**
   ```apex
   public with sharing class MyClass { }
   ```

2. **Include `WITH SECURITY_ENFORCED` on SOQL queries**
   ```apex
   List<Account> accounts = [
       SELECT Id, Name FROM Account
       WITH SECURITY_ENFORCED
   ];
   ```

3. **Use PrometheionSecurityUtils for CRUD/FLS checks**
   ```apex
   PrometheionSecurityUtils.validateCRUDAccess('Account', DmlOperation.DML_UPDATE);
   update Security.stripInaccessible(AccessType.UPDATABLE, accounts).getRecords();
   ```

4. **Sanitize user inputs**
   ```apex
   String userInput = String.escapeSingleQuotes(rawInput);
   ```

5. **No hardcoded credentials or secrets**
   ```apex
   // ❌ BAD
   String apiKey = 'sk-abc123';

   // ✅ GOOD
   String apiKey = [SELECT API_Key__c FROM Prometheion_API_Config__mdt WHERE DeveloperName = 'ClaudeAI'].API_Key__c;
   ```

### Lightning Web Components

#### File Structure

```
myComponent/
├── myComponent.html          # Template
├── myComponent.js            # Controller
├── myComponent.js-meta.xml   # Metadata
├── myComponent.css           # Styles (optional)
└── __tests__/
    └── myComponent.test.js   # Jest tests
```

#### Naming Conventions

- **Component folders:** `camelCase` (e.g., `complianceDashboard`)
- **CSS classes:** `kebab-case` (e.g., `.compliance-score`)
- **JavaScript variables:** `camelCase` (e.g., `complianceScores`)
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `API_VERSION`)

#### LWC Best Practices

```javascript
import { LightningElement, wire, api } from 'lwc';
import getScores from '@salesforce/apex/Controller.getScores';

export default class MyComponent extends LightningElement {
    // Public properties
    @api recordId;

    // Private properties
    scores;
    error;

    // Wire service
    @wire(getScores, { recordId: '$recordId' })
    wiredScores({ error, data }) {
        if (data) {
            this.scores = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.scores = undefined;
        }
    }

    // Event handlers
    handleRefresh() {
        // Implementation
    }
}
```

### Code Formatting

**Use Prettier for all formatting:**

```bash
# Format all files
npm run fmt

# Check formatting (CI uses this)
npm run fmt:check
```

**Prettier Configuration (`.prettierrc`):**
```json
{
  "semi": true,
  "singleQuote": false,
  "printWidth": 100,
  "tabWidth": 4,
  "trailingComma": "none"
}
```

### Linting

**Run ESLint before committing:**

```bash
# Run linter
npm run lint

# Fix auto-fixable issues
npm run lint:fix
```

**ESLint enforces:**
- ES2021 syntax
- LWC best practices
- Security patterns
- Code complexity limits (max 3 warnings allowed)

---

## Testing Requirements

### Apex Tests

**Every production Apex class MUST have a corresponding test class with ≥95% coverage.**

#### Test Class Template

```apex
/**
 * @description Test class for MyClass
 * @group Tests
 * @see MyClass
 */
@isTest
private class MyClassTest {

    @TestSetup
    static void setup() {
        // Create test data
        PrometheionTestDataFactory.createComprehensiveTestDataset();
    }

    @isTest
    static void testMethodName_Scenario_ExpectedResult() {
        // Arrange
        String input = 'test';

        // Act
        Test.startTest();
        String result = MyClass.myMethod(input);
        Test.stopTest();

        // Assert
        System.assertEquals('expected', result, 'Result should match expected value');
    }

    @isTest
    static void testMethodName_ErrorScenario_ThrowsException() {
        // Arrange
        String invalidInput = null;

        // Act & Assert
        Test.startTest();
        try {
            MyClass.myMethod(invalidInput);
            System.assert(false, 'Should have thrown exception');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
}
```

#### Test Data Factories

Use provided test data factories:

```apex
// User factory
User admin = PrometheionTestUserFactory.createPrometheionAdmin();
System.runAs(admin) {
    // Test code
}

// Data factory
List<Compliance_Score__c> scores = PrometheionTestDataFactory.createBulkComplianceScores(250, true);
```

### LWC Tests

**Every LWC component MUST have Jest unit tests.**

#### LWC Test Template

```javascript
import { createElement } from 'lwc';
import MyComponent from 'c/myComponent';
import getScores from '@salesforce/apex/Controller.getScores';

// Mock Apex wire adapter
jest.mock(
    '@salesforce/apex/Controller.getScores',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

describe('c-my-component', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('should render data from wire', async () => {
        const element = createElement('c-my-component', { is: MyComponent });
        document.body.appendChild(element);

        getScores.emit({ data: [{ Id: '001', Score__c: 85 }] });
        await Promise.resolve();

        const scoreElement = element.shadowRoot.querySelector('.score');
        expect(scoreElement.textContent).toBe('85');
    });
});
```

### Running Tests

```bash
# Run all LWC tests
npm run test:unit

# Run tests in watch mode
npm run test:unit:watch

# Run tests with coverage
npm run test:unit:coverage

# Run Apex tests
sf apex run test --target-org YOUR_ORG --code-coverage --result-format human
```

---

## Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat:** New feature
- **fix:** Bug fix
- **docs:** Documentation changes
- **style:** Code style changes (formatting, no logic change)
- **refactor:** Code refactoring
- **test:** Adding or updating tests
- **chore:** Maintenance tasks (dependencies, build, etc.)
- **perf:** Performance improvements
- **ci:** CI/CD changes

### Examples

```bash
# Feature
git commit -m "feat(dashboard): add compliance trend chart"

# Bug fix
git commit -m "fix(scanner): handle null framework parameter"

# Documentation
git commit -m "docs(api): update API reference for v3.0"

# Breaking change
git commit -m "feat(api)!: change compliance score API response format

BREAKING CHANGE: Score API now returns nested object instead of flat structure"
```

### Pre-Commit Hooks

Husky runs automatically before each commit:

1. **Prettier format check** - `npm run fmt:check`
2. **ESLint** - `npm run lint`
3. **Jest unit tests** - `npm run test:unit`

If any check fails, commit is blocked. Fix issues and retry.

---

## Pull Request Process

### Before Creating PR

- [ ] Code follows coding standards
- [ ] All tests pass (`npm run precommit`)
- [ ] New features have tests (≥95% coverage)
- [ ] Documentation updated (README, API docs, etc.)
- [ ] Commit messages follow conventional commits
- [ ] No merge conflicts with main branch

### PR Title Format

Use conventional commit format:

```
feat(scanner): add support for FedRAMP compliance framework
```

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] Test coverage ≥95%

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests pass locally

## Related Issues
Closes #123
```

### Review Process

1. **Automated Checks:** CI/CD runs automatically
   - Code quality (Prettier, ESLint)
   - Unit tests (Jest)
   - Security scan (Code Analyzer)
   - Build validation

2. **Code Review:** At least one approval required
   - Maintainers review for quality, security, performance
   - Address feedback and update PR

3. **Merge:** Once approved and CI passes
   - Squash and merge (default)
   - Delete feature branch after merge

---

## Documentation

### When to Update Documentation

Update documentation when:
- Adding new features
- Changing public APIs
- Modifying configuration
- Adding/removing dependencies
- Changing installation steps

### Documentation Files

- **README.md** - Project overview and quick start
- **docs/INSTALLATION_GUIDE.md** - Detailed installation instructions
- **docs/EXTERNAL_SERVICES.md** - External integrations guide
- **docs/SCANNER_REPORT_BUNDLE.md** - Security scanning guide
- **API_REFERENCE.md** - API documentation
- **TECHNICAL_DEEP_DIVE.md** - Architecture deep dive
- **CLAUDE.md** - AI assistant guide

### Code Comments

**Use JSDoc-style comments for all public methods:**

```apex
/**
 * @description Calculate compliance score for framework
 * @param framework The compliance framework (HIPAA, SOC2, etc.)
 * @param includeHistory Whether to include historical data
 * @return Compliance score object with current score and trend
 * @throws IllegalArgumentException if framework is null or empty
 */
public ComplianceScore calculateScore(String framework, Boolean includeHistory) {
    // Implementation
}
```

---

## Security

### Reporting Security Vulnerabilities

**DO NOT open public GitHub issues for security vulnerabilities.**

Instead:
1. Email: security@prometheion.io
2. Include:
   - Detailed description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will respond within 48 hours.

### Security Best Practices

1. **Never commit secrets**
   - Use Named Credentials or Protected Custom Metadata
   - Check `.gitignore` before committing

2. **Validate all user inputs**
   - Use `String.escapeSingleQuotes()`
   - Sanitize before using in SOQL/DML

3. **Use security utilities**
   - `PrometheionSecurityUtils.validateCRUDAccess()`
   - `Security.stripInaccessible()`
   - `WITH SECURITY_ENFORCED` on all SOQL

4. **Run security scans**
   ```bash
   ./scripts/run-appexchange-scanner.sh
   ```

---

## Getting Help

- **Documentation:** [docs/](docs/)
- **Issues:** [GitHub Issues](https://github.com/prometheion/prometheion/issues)
- **Discussions:** [GitHub Discussions](https://github.com/prometheion/prometheion/discussions)
- **Email:** support@prometheion.io

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

## Recognition

Contributors will be recognized in:
- Release notes
- Contributors list
- Project documentation

Thank you for contributing to Prometheion! 🚀

---

**Version:** 1.0
**Last Updated:** 2026-01-11
**Maintainers:** Prometheion Engineering Team
