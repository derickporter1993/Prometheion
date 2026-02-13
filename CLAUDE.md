# ELARO CLAUDE.md: Master Project Context

**Last Updated:** February 13, 2026 | All 19 audit findings resolved | Spring '26 (API v66.0)
**Standards aligned with:** Salesforce Apex Best Practices Through Spring '26 (PDF), Elaro Sovereign Architecture, Elaro Team Split Plan, Elaro Codebase Fix Report, Solentra Best Practices Guide

**Team 2 Build Status:** All 8 agents COMPLETE as of 2026-02-11. See [TEAM2_BUILD_STATUS.md](./TEAM2_BUILD_STATUS.md) for details.

---

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Elaro** is a 2GP managed package targeting AppExchange distribution. It automates compliance across
HIPAA, SOC2, PCI-DSS, GDPR, CCPA, GLBA, ISO 27001, FINRA, FedRAMP, CMMC 2.0, SEC Cybersecurity,
NIS2, DORA, and AI Governance (EU AI Act / NIST AI RMF).

### Codebase Metrics

| Metric | Count |
| --- | --- |
| Apex Classes (production) | 186 (175 main + 11 health check) |
| Apex Test Classes | 184 (174 main + 10 health check) |
| **Total Apex Classes** | **370** |
| Total Apex Lines of Code | ~82,600 |
| LWC Components | 60 (54 main + 6 health check) |
| Custom Objects | 72 |
| Platform Events | 11 |
| Permission Sets | 10 (8 main + 2 health check) |
| Apex Triggers | 5 |
| Custom Labels | 187 (162 main + 25 health check) |
| Custom Metadata Types | 8 |
| Custom Metadata Records | 139 |
| GitHub Actions Workflows | 5 |

Audit score: 84/100. All code audit-remediated to modern standards.

## Technology Stack

| Layer | Technology |
| --- | --- |
| Backend | Apex (Salesforce API v66.0) |
| Frontend | Lightning Web Components (LWC) |
| Testing | Jest v30 (LWC) + Apex Test Classes |
| Linting | ESLint v9 (flat config) with LWC plugin |
| Formatting | Prettier v3 |
| Monorepo | Turborepo (platform/) |
| Node.js | v20.0.0+ required (npm >=10.0.0) |

## Architecture

### Core Framework

- **ComplianceServiceFactory.cls** + **IComplianceModule.cls** interface: Extensible module registration
- **ElaroFrameworkEngine.cls**: Framework evaluation engine (evaluateControls)
- **ElaroLogger.cls**: Structured logging via Platform Events (Publish Immediately mode)
- **ElaroSecurityUtils.cls**: Defense-in-depth security utilities
- **ElaroConstants.cls**: Centralized constants
- **ComplianceTestDataFactory.cls**: Shared test data factory

### Compliance Modules

| Module | Key Classes |
| --- | --- |
| HIPAA | HIPAAModule, HIPAABreachNotificationService |
| SOC 2 | SOC2Module |
| GDPR | GDPRModule, GDPRRequestProcessor |
| CCPA | CCPAOptOutService, CCPARequestProcessor |
| PCI-DSS | PCIAccessEventHandler |
| GLBA | GLBAComplianceModule |
| ISO 27001 | ISO27001AccessReviewService |
| SEC Cybersecurity | SECDisclosureController, MaterialityAssessmentService, DisclosureWorkflowService |
| AI Governance | AIDetectionEngine, AIRiskClassificationEngine, AIGovernanceService, AIGovernanceController |

### Event-Driven Architecture

11 Platform Events power real-time monitoring:
- **ComplianceAlert__e** — Core compliance alerts
- **ConfigurationDrift__e** — Configuration change notifications
- **BreachIndicator__e** — Breach pattern detection
- **Performance_Alert__e** — Performance monitoring
- CCPA_Request_Event__e, GDPR_Erasure_Event__e, GDPR_Data_Export_Event__e, GLBA_Compliance_Event__e, PCI_Access_Event__e, Elaro_Alert_Event__e, Elaro_Score_Result__e

Core event classes: ComplianceAlertPublisher (without sharing), ConfigDriftDetector, EventCorrelationEngine, BreachPatternMatcher, EventWindowService

### Integration Points

- **Command Center → Remediation Orchestrator** (RemediationOrchestrator.createRemediationCase)
- **Assessment Wizard → Rule Engine** (ElaroFrameworkEngine.evaluateControls)
- **Event Monitoring → Rule Engine** (EventCorrelationEngine with Big Object storage)
- External: SlackIntegration, TeamsNotifier, JiraIntegrationService, ServiceNowIntegration

### Schedulers

ComplianceReportScheduler, ConsentExpirationScheduler, WeeklyScorecardScheduler

## Two-Team Build Structure

**Team 1** (Sovereign Infrastructure): Async Framework, CMMC 2.0, Rule Engine, Orchestration, NIS2/DORA
**Team 2** (User-Facing Modules): Health Check (separate 2GP), Command Center, Event Monitoring,
Assessment Wizards, SEC Module, AI Governance, Trust Center — **ALL COMPLETE**

## Package Structure

```
sfdx-project.json packageDirectories:
  - path: force-app           # Main Elaro 2GP managed package
    package: "elaro"
    versionName: "v3.0 Enterprise"
    versionNumber: "3.0.0.NEXT"
    default: true

  - path: force-app-healthcheck  # Separate 2GP
    package: "Elaro Health Check"
    versionName: "Spring 26"
    versionNumber: "1.0.0.NEXT"
    default: false
```

Health Check components go in `force-app-healthcheck/main/default/`.
All other components go in `force-app/main/default/`.

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
npm run test:unit:coverage  # Jest with coverage report
npm run test:a11y        # Accessibility audit
sf apex run test -o <org> -c   # Run Apex tests with coverage

# Run single Apex test class
sf apex run test -o <org> --tests <TestClassName>

# Salesforce Deployment
sf project deploy start -o <org>             # Deploy to org
sf project deploy start -o <org> --dry-run   # Validate only

# Scratch Org Management
npm run org:create       # Create scratch org (alias: elaro-dev)
npm run org:open         # Open scratch org in browser
npm run org:delete       # Delete scratch org

# Pre-commit (runs automatically via Husky)
npm run precommit        # preflight + fmt:check + lint + test:unit

# Full validation
npm run validate         # Same as precommit

# Platform CLI (TypeScript monorepo)
npm run cli:build        # Build platform CLI packages
npm run cli:install      # Build and link CLI globally
```

## Project Structure

```
elaro/
├── force-app/main/default/          # Main Elaro package
│   ├── classes/                     # 349 Apex classes (175 prod + 174 test)
│   ├── lwc/                         # 54 LWC components
│   ├── objects/                     # 72 custom objects + Platform Events (__e)
│   ├── customMetadata/              # 139 Custom Metadata records
│   ├── permissionsets/              # 8 Permission Sets
│   ├── labels/                      # 162 Custom Labels
│   ├── flexipages/                  # Lightning App Pages
│   ├── tabs/                        # Custom Tabs
│   └── triggers/                    # 5 Apex triggers
├── force-app-healthcheck/main/default/  # Health Check separate 2GP
│   ├── classes/                     # 21 Apex classes (11 prod + 10 test)
│   ├── lwc/                         # 6 LWC components
│   ├── permissionsets/              # 2 Permission Sets
│   ├── labels/                      # 25 Custom Labels
│   ├── tabs/                        # Health Check Tabs
│   └── flexipages/                  # Health Check App Pages
├── platform/                        # TypeScript monorepo (Turborepo)
│   └── packages/
│       ├── cli/                     # elaro CLI
│       ├── sf-client/               # Salesforce API client
│       ├── types/                   # Shared TypeScript types
│       └── masking/                 # Data masking utilities
├── docs/                            # Documentation
│   ├── user/                        # User documentation
│   ├── business/                    # Business case and ROI
│   ├── developer/                   # Technical architecture
│   ├── architecture/                # System design
│   ├── security/                    # Security audit findings
│   ├── appexchange/                 # AppExchange prep materials
│   ├── audit/                       # Audit reports
│   └── archive/                     # Historical docs
├── agent_docs/                      # Agent build documentation
├── examples/                        # Example reports and templates
├── scripts/                         # Automation scripts
├── config/                          # Salesforce project config
├── manifest/                        # Deployment manifests
├── .github/workflows/               # 5 CI/CD workflows
└── .claude/                         # Claude Code configuration
```

## Permission Sets

| Permission Set | Package | Purpose |
| --- | --- | --- |
| Elaro_Admin | Main | Full administrative access |
| Elaro_Admin_Extended | Main | Extended admin functions |
| Elaro_User | Main | Standard user access |
| Elaro_Auditor | Main | Audit and read-only access |
| Elaro_AI_Governance_Admin | Main | AI governance administration |
| Elaro_AI_Governance_User | Main | AI governance user access |
| Elaro_SEC_Admin | Main | SEC disclosure administration |
| TechDebt_Manager | Main | Tech debt management |
| Elaro_Health_Check_Admin | HC | Health Check administration |
| Elaro_Health_Check_User | HC | Health Check user access |

## Triggers

| Trigger | Object | Purpose |
| --- | --- | --- |
| ElaroAlertTrigger | Alert__c | Alert record handling |
| ElaroConsentWithdrawalTrigger | Consent__c | Consent withdrawal events |
| ElaroEventCaptureTrigger | — | Real-time audit event capture |
| ElaroPCIAccessAlertTrigger | — | PCI access alert generation |
| PerformanceAlertEventTrigger | Performance_Alert__e | Performance monitoring |

---

## NON-NEGOTIABLE CODING STANDARDS

> **OVERRIDE NOTICE**: If you encounter `WITH SECURITY_ENFORCED` in existing code or documentation,
> that is OUTDATED. The standard is `WITH USER_MODE`. Do NOT copy patterns from existing files
> that use `WITH SECURITY_ENFORCED`.

### Apex Security (AppExchange rejection if violated)

```apex
// SOQL — ALWAYS WITH USER_MODE (never WITH SECURITY_ENFORCED)
List<Account> accts = [SELECT Id, Name FROM Account WHERE Id = :someId WITH USER_MODE];

// Dynamic SOQL — ONLY Database.queryWithBinds(), NEVER string concatenation
// GOTCHA: Map keys are case-insensitive (duplicates throw QueryException)
// GOTCHA: Bind syntax uses first token before dot (:record.Name resolves to key "record")
Map<String, Object> binds = new Map<String, Object>{ 'status' => statusVal };
List<SObject> results = Database.queryWithBinds(
    'SELECT Id FROM Compliance_Score__c WHERE Status__c = :status WITH USER_MODE',
    binds, AccessLevel.USER_MODE
);

// DML — ALWAYS 'as user'
insert as user newRecords;
update as user existingRecords;
delete as user oldRecords;
upsert as user records External_Id__c;

// Database methods — ALWAYS AccessLevel.USER_MODE
Database.insert(records, false, AccessLevel.USER_MODE);
Database.update(records, false, AccessLevel.USER_MODE);

// Security.stripInaccessible() — use ONLY for graceful degradation
// (silently stripping inaccessible fields instead of throwing exceptions)
SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, records);
List<SObject> sanitized = decision.getRecords();
```

### Null Handling (use modern operators)

```apex
// Null coalescing (??) — prefer over ternary null checks
String name = account.Name ?? 'Unknown';
String val = a ?? b ?? c ?? 'default';  // Left-associative, lazy evaluation

// Safe navigation (?.) — combine with ?? for clean patterns
String ownerName = [SELECT Owner.Name FROM Case WHERE Id = :caseId LIMIT 1]?.Owner?.Name ?? 'Unassigned';

// GOTCHA: ?. returns null (not exception), so null != someValue evaluates to true
// Always reason through what null means in your comparison
```

### Sharing Keywords

```apex
// Controllers (entry points) — enforces sharing
public with sharing class MyController { }

// Services, utilities, handlers, engines — inherits caller context
public inherited sharing class MyService { }

// System operations ONLY (install handlers, event publishers) — MUST document why
/**
 * SECURITY: without sharing required because this class publishes Platform Events
 * for audit logging which must succeed regardless of the running user's record access.
 */
public without sharing class MyEventPublisher { }
```

### Access Modifiers (BREAKING CHANGE v65.0+)

```apex
// v65.0+ REQUIRES explicit access modifiers on abstract and override methods
// Omitting them causes compilation failure
public abstract class BaseProcessor {
    public abstract void process(List<SObject> records);  // MUST have public/protected/global
    protected virtual void validate(SObject record) { }   // MUST have modifier
}

public class ConcreteProcessor extends BaseProcessor {
    public override void process(List<SObject> records) { }  // MUST have modifier
    protected override void validate(SObject record) { }     // MUST match or widen
}
```

### ApexDoc (Official Platform Standard — Winter '26+)

Every class and every public/global method MUST have ApexDoc comments.
Agentforce and platform tools parse these. AppExchange reviewers expect them.

```apex
/**
 * Scans Salesforce Security Health Check settings via Tooling API and returns
 * risk-categorized findings with a composite security score.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see ScoreAggregator
 * @see HealthCheckResult
 */
public inherited sharing class HealthCheckScanner {

    /**
     * Executes a full security health check scan against the current org.
     *
     * @param includeRiskItems Whether to include individual risk item details
     * @return HealthCheckResult containing score and categorized findings
     * @throws AuraHandledException if Tooling API query fails or user lacks permission
     * @example
     * HealthCheckResult result = new HealthCheckScanner().scan(true);
     * System.debug('Score: ' + result.overallScore);
     */
    public HealthCheckResult scan(Boolean includeRiskItems) {
        // implementation
    }
}
```

Required tags: `@author`, `@since`, `@group`, `@param`, `@return`, `@throws`, `@see` (where applicable).
No `@description` tag — the description is the first text in the comment block.
Inline tags: `{@link ClassName}`, `{@code someCode}`.

### Async Patterns

```apex
// PREFERRED: Queueable + Cursors (Spring '26 GA). NEVER @future.
// @future is legacy. A Salesforce PM opened a PR to flag it as a PMD violation.

// Cursor + Queueable pattern for large dataset processing:
public class ScanProcessor implements Queueable {
    private Database.Cursor cursor;
    private Integer position;

    public ScanProcessor(Database.Cursor cursor, Integer position) {
        this.cursor = cursor;
        this.position = position;
    }

    public void execute(QueueableContext ctx) {
        List<SObject> records = cursor.fetch(position, 200);
        // Process records...
        if (position + 200 < cursor.getNumRecords()) {
            System.enqueueJob(new ScanProcessor(cursor, position + 200));
        }
    }
}

// Cursor limits: 50M rows/cursor, 10 fetch calls/txn, 10K instances/day,
// 100M aggregate rows/day. Expires after 48 hours. No Big Object support.
// Each fetch() counts against SOQL query limit. Fetched rows count against query row limit.

// PaginationCursor — for UI pagination (100K record limit, 200K instances/day)
// Use for paginated datatables in LWC

// Transaction Finalizers — for retry patterns and error logging
public class ScanFinalizer implements Finalizer {
    public void execute(FinalizerContext ctx) {
        if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
            ElaroLogger.error('ScanProcessor', ctx.getException().getMessage(), '');
            // Optionally re-enqueue with backoff
        }
    }
}

// AsyncOptions — for duplicate prevention and chaining control
AsyncOptions options = new AsyncOptions();
options.setMaximumQueueableStackDepth(5);
options.setDuplicateSignature(
    new QueueableDuplicateSignature.Builder()
        .addId(someRecordId)
        .build()
);
System.enqueueJob(new ScanProcessor(cursor, 0), options);
```

### Error Handling

```apex
// Every @AuraEnabled method — try-catch with user-friendly messages
@AuraEnabled(cacheable=true)
public static HealthCheckResult runFullScan() {
    try {
        // logic
    } catch (Exception e) {
        ElaroLogger.error('HealthCheckController.runFullScan', e.getMessage(), e.getStackTraceString());
        throw new AuraHandledException('Unable to complete the security scan. Please verify you have the required permissions and try again.');
    }
}
```

### Logging

```apex
// Structured logging via Platform Events. Publish Immediately mode so logs survive rollback.
// NEVER System.debug() as primary logging.
ElaroLogger.info('ClassName.methodName', 'What happened');
ElaroLogger.error('ClassName.methodName', e.getMessage(), e.getStackTraceString());
```

### Platform Cache

```apex
// Use Org Cache (3MB ISV partition) for cross-transaction caching
// TTL: 60 minutes for rule metadata, 24 hours for Metadata API results
Cache.OrgPartition orgPart = Cache.Org.getPartition('local.ElaroCache');
List<Compliance_Rule__mdt> rules = (List<Compliance_Rule__mdt>) orgPart.get('complianceRules');
if (rules == null) {
    rules = [SELECT Id, DeveloperName, Rule_Query__c FROM Compliance_Rule__mdt WITH USER_MODE];
    orgPart.put('complianceRules', rules, 3600); // 60-min TTL
}
```

### Test Standards

```apex
// ONLY Assert class. NEVER System.assertEquals/assertNotEquals/assert.
Assert.areEqual(expected, actual, 'Descriptive message');
Assert.areNotEqual(bad, actual, 'Should not match');
Assert.isTrue(condition, 'Why this should be true');
Assert.isFalse(condition, 'Why this should be false');
Assert.isNotNull(result, 'Result should exist');
Assert.isInstanceOfType(obj, MyClass.class, 'Should be MyClass');
Assert.fail('Should not reach here');

// @IsTest(testFor) — links test to production class for RunRelevantTests (Spring '26 Beta)
@IsTest(testFor=HealthCheckScanner.class)
private class HealthCheckScannerTest {

    // @TestSetup — create shared test data once per class (reduces test execution time)
    @TestSetup
    static void makeData() {
        // Use ComplianceTestDataFactory patterns
    }

    @IsTest
    static void shouldCalculateCorrectScore() {
        // ALWAYS use Test.startTest()/Test.stopTest() to reset governor limits
        Test.startTest();
        HealthCheckResult result = HealthCheckController.runFullScan();
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.overallScore >= 0 && result.overallScore <= 100,
            'Score should be between 0 and 100, got: ' + result.overallScore);
    }
}

// HttpCalloutMock for Tooling API mocking
@IsTest
private class HealthCheckScannerTest {
    private class ToolingApiMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"records":[{"Score":72,"RiskType":"HIGH_RISK"}]}');
            return res;
        }
    }

    @IsTest
    static void shouldQueryToolingApi() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock());
        Test.startTest();
        // test code
        Test.stopTest();
    }
}

// 85%+ coverage per class. Meaningful assertions on every test.
// System.runAs() for permission testing. @TestSetup for shared data.
```

### Tooling API Access Pattern

```apex
// Tooling API queries use HTTP REST, not standard SOQL.
// SecurityHealthCheck, SecurityHealthCheckRisks, etc. require Tooling API endpoint.

public inherited sharing class ToolingApiService {
    /**
     * Executes a SOQL query against the Tooling API.
     *
     * @param query The SOQL query string (e.g., 'SELECT Score FROM SecurityHealthCheck')
     * @return Parsed JSON response as Map
     * @throws AuraHandledException on HTTP errors
     */
    public static Map<String, Object> queryTooling(String query) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm()
            + '/services/data/v66.0/tooling/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Tooling API query failed: ' + res.getStatus());
        }
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }
}

// SECURITY NOTE: Tooling API runs in system context (no WITH USER_MODE equivalent).
// Document this exception clearly. Validate caller permissions in the controller layer.
// The controller (with sharing) ensures record-level access; the Tooling query
// returns org-wide security settings (not record data), so sharing is N/A.
```

### LWC Standards

```html
<!-- ONLY lwc:if / lwc:elseif / lwc:else. NEVER if:true / if:false. -->
<template lwc:if={isLoading}>
  <lightning-spinner alternative-text="Loading"></lightning-spinner>
</template>
<template lwc:elseif={hasError}>
  <c-error-panel message={errorMessage}></c-error-panel>
</template>
<template lwc:elseif={isEmpty}>
  <div class="slds-illustration slds-illustration_small">
    <p>{label.NoDataAvailable}</p>
  </div>
</template>
<template lwc:else>
  <!-- Main content -->
</template>
```

Every LWC component MUST handle: loading state, error state, empty state.
WCAG 2.1 AA: ARIA labels, keyboard navigation, focus management.
SLDS for all styling. No custom CSS unless SLDS cannot cover it.

**Wire vs. Imperative**: Use `@wire` for reactive read operations. Use imperative calls
for user-triggered actions and expensive operations (like scanning, which takes >5 seconds).

**Custom Labels for ALL user-facing strings** (required for i18n and AppExchange):

```javascript
import NoDataAvailable from "@salesforce/label/c.NoDataAvailable";
import ScanInProgress from "@salesforce/label/c.ScanInProgress";
import ScanComplete from "@salesforce/label/c.ScanComplete";
import ErrorGeneric from "@salesforce/label/c.ErrorGeneric";

export default class MyComponent extends LightningElement {
  label = { NoDataAvailable, ScanInProgress, ScanComplete, ErrorGeneric };
}
```

NEVER hardcode English strings in HTML templates or JS files.

**LWC Jest Tests** (required for every component):

```javascript
import { createElement } from "lwc";
import MyComponent from "c/myComponent";

// ALWAYS use { virtual: true } for Salesforce module mocks
jest.mock("@salesforce/apex/HealthCheckController.runFullScan", () => ({ default: jest.fn() }), {
  virtual: true,
});

describe("c-my-component", () => {
  afterEach(() => {
    while (document.body.firstChild) document.body.removeChild(document.body.firstChild);
  });

  it("renders loading state", () => {
    const element = createElement("c-my-component", { is: MyComponent });
    document.body.appendChild(element);
    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });
});
```

### Permission Sets (REQUIRED for 2GP)

2GP managed packages CANNOT use profiles. Every new object, field, Apex class, LWC page,
and tab MUST have a Permission Set granting access. Without this, the package installs and
users see nothing.

```xml
<!-- Example: Elaro_Health_Check_User.permissionset-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Elaro Health Check User</label>
    <description>Grants access to Health Check dashboard and scanner results</description>
    <hasActivationRequired>false</hasActivationRequired>
    <classAccesses>
        <apexClass>HealthCheckController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <tabSettings>
        <tab>Health_Check_Dashboard</tab>
        <visibility>Visible</visibility>
    </tabSettings>
    <pageAccesses>
        <apexPage>HealthCheckDashboardPage</apexPage>
        <enabled>true</enabled>
    </pageAccesses>
</PermissionSet>
```

Create one admin Permission Set (full access) and one user Permission Set (read/execute)
per functional area.

### Custom Labels (REQUIRED for AppExchange)

All user-facing strings must be Custom Labels. No hardcoded English in LWC HTML or JS.

```xml
<!-- labels/CustomLabels.labels-meta.xml -->
<CustomLabels xmlns="http://soap.sforce.com/2006/04/metadata">
    <labels>
        <fullName>HC_ScanInProgress</fullName>
        <language>en_US</language>
        <protected>true</protected>
        <shortDescription>Health Check scan in progress message</shortDescription>
        <value>Scanning your org security settings...</value>
    </labels>
</CustomLabels>
```

### Feature Flags (Kill Switch for Subscriber Orgs)

```apex
// Every major feature needs a Custom Setting kill switch
// Use Hierarchy Custom Setting (not Custom Metadata) for per-org/per-user overrides
public inherited sharing class FeatureFlags {
    public static Boolean isHealthCheckEnabled() {
        Elaro_Feature_Flags__c flags = Elaro_Feature_Flags__c.getInstance();
        return flags?.Health_Check_Enabled__c ?? true; // Default ON
    }
}
```

### API Version

All code: API v66.0 (Spring '26) in .cls-meta.xml and .js-meta.xml:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

### Naming Conventions

- Apex classes: PascalCase. Scanners: `[Name]Scanner.cls`. Controllers: `[Name]Controller.cls`
- Test classes: `[ClassName]Test.cls` (same directory as production class)
- LWC: camelCase folder name. Prefix `healthCheck` for HC package, no prefix for main package generic components
- Objects: PascalCase with `__c`. Fields: `Snake_Case__c`
- Custom Metadata: PascalCase with `__mdt`. Platform Events: PascalCase with `__e`
- Permission Sets: `Elaro_[Module]_[Role].permissionset-meta.xml`
- Custom Labels: `[MODULE]_[Description]` (e.g., `HC_ScanInProgress`, `SEC_FilingDeadline`)

---

## SF CLI Commands (sfdx is DEAD — removed Nov 2024)

```bash
# Deploy to org
sf project deploy start --target-org myOrg --test-level RunLocalTests --wait 30

# Run tests
sf apex run test --target-org myOrg --test-level RunLocalTests --wait 10

# Create scratch org
sf org create scratch --definition-file config/elaro-scratch-def.json --duration-days 30 --alias elaro-dev

# Run Code Analyzer v5 (v4 retired Aug 2025)
sf scanner run --target force-app --format table --severity-threshold 1

# Push source
sf project deploy start --target-org elaro-dev

# Retrieve source
sf project retrieve start --target-org elaro-dev

# Query data
sf data query --query "SELECT Id, Name FROM Account LIMIT 10" --target-org myOrg
```

NEVER use `sfdx` commands. They were deprecated June 2024 and removed November 2024.

## Scratch Org Configuration

Actual scratch org definition (`config/elaro-scratch-def.json`):

```json
{
  "orgName": "Elaro Enterprise Scratch Org",
  "edition": "Developer",
  "features": ["EinsteinGPT", "MultiCurrency", "Communities", "PlatformCache"],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "securitySettings": {
      "sessionSettings": {
        "enforceIpRangesEveryRequest": false
      }
    },
    "mobileSettings": {
      "enableS1EncryptedStoragePref2": false
    },
    "platformCacheSettings": {
      "cachePartitions": [
        {
          "description": "Elaro Compliance cache partition for storing compliance scores",
          "isDefaultPartition": false,
          "masterLabel": "ElaroCompliance",
          "platformCacheType": "Org"
        }
      ]
    }
  }
}
```

## CI/CD Pipeline

GitHub Actions workflows in `.github/workflows/`:

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| **elaro-ci.yml** | Push to main/develop/release/*/claude/*; PRs to main | Main CI pipeline (6 jobs) |
| **auto-merge-pr.yml** | PR events | Automatic PR merging on success |
| **pr-status-monitor.yml** | PR events | PR status monitoring |
| **codeql.yml** | Push/PR | CodeQL security scanning |
| **salesforce-review.yml** | Push/PR | Salesforce-specific code review |

### Main CI Pipeline Jobs (elaro-ci.yml)

1. **code-quality** — Format check, linting, `npm audit`
2. **unit-tests** — LWC Jest tests
3. **security-scan** — Salesforce Code Analyzer with AppExchange selectors
4. **validate-metadata** — Directory structure validation
5. **cli-build** — Platform TypeScript build
6. **build-success** — Final deployment readiness check

Environment: Node.js 20.17.0

## Quality Gates

1. **Code Analyzer v5**: `sf scanner run` after every build. Zero HIGH severity findings.
2. **Checkmarx**: Before every AppExchange security review submission. Fix ALL findings.
3. **Jest tests**: `npm run test:unit` for LWC. All passing.
4. **Apex tests**: `sf apex run test --test-level RunLocalTests`. 85%+ per class.
5. **WCAG 2.1 AA**: Verify all LWC components with screen reader and keyboard nav.

## Breaking Changes to Watch (Affects v65.0+ / v66.0)

- **v62.0+**: Modifying a Set during iteration throws `System.FinalException`
- **v63.0**: JSON serialization of exceptions removed (throws `System.JSONException`)
- **v63.0**: Default Accept header for callouts changed to `*/*`
- **v65.0+**: Abstract/override methods REQUIRE explicit access modifiers
- **Spring '26**: Session IDs removed from outbound messages (Feb 16, 2026 — use OAuth)
- **Spring '26**: My Domain URL enforcement in production for all API traffic
- **Spring '26**: Connected app creation disabled by default (use External Client Apps)
- **Spring '26**: `Blob.toPdf()` rendering upgraded (enforced Summer '26)

## Quick Validation Before Commit

```bash
# Run full pre-commit validation
npm run precommit

# Check for outdated security patterns
grep -rn 'WITH SECURITY_ENFORCED' force-app/main/default/classes/ 2>/dev/null
grep -rn 'System.assertEquals' force-app/main/default/classes/ 2>/dev/null

# Check for deprecated LWC template directives
grep -rn 'if:true\|if:false' force-app/main/default/lwc/ 2>/dev/null
```

---

## TEAM 2: BUILD REFERENCE (ALL COMPLETE)

> All 8 agent workstreams completed as of February 11, 2026.
> This section serves as architectural reference for the implemented modules.
> See [TEAM2_BUILD_STATUS.md](./TEAM2_BUILD_STATUS.md) for full completion details.

### WS4 — FREE HEALTH CHECK TOOL (Agent 1 - COMPLETE)

**Package**: Separate 2GP | **Directory**: force-app-healthcheck/main/default/

**Implemented classes**: ToolingApiService, HealthCheckResult, ScanFinding, ScanRecommendation,
HealthCheckScanner, MFAComplianceScanner, ProfilePermissionScanner, SessionSettingsScanner,
AuditTrailScanner, ScoreAggregator, HealthCheckController, HealthCheckFeatureFlags, HCLogger

**LWC components**: healthCheckDashboard, healthCheckScoreGauge, healthCheckRiskTable,
healthCheckRecommendations, healthCheckMfaIndicator, healthCheckCtaBanner

**Score weights**: Health Check 40%, MFA 20%, Permissions 15%, Sessions 15%, Audit 10%

### WS-CC — COMPLIANCE COMMAND CENTER (Agent 2 - COMPLETE)

**Package**: Main Elaro 2GP

**Implemented**: Compliance_Action__mdt (52+ action records), ComplianceContextEngine,
CommandCenterController, complianceCommandCenter LWC, complianceActionCard, complianceContextSidebar,
complianceNotificationFeed

### WS-EM — EVENT-DRIVEN MONITORING (Agent 3 - COMPLETE)

**Package**: Main Elaro 2GP

**Platform Events**: ComplianceAlert__e, ConfigurationDrift__e, BreachIndicator__e

**Implemented**: ComplianceAlertPublisher (without sharing), ConfigDriftDetector,
EventCorrelationEngine, BreachPatternMatcher, EventWindowService

**Custom Metadata**: Correlation_Rule__mdt

### WS-AW — GUIDED ASSESSMENT WIZARDS (Agent 4 - COMPLETE)

**Package**: Main Elaro 2GP

**Custom Objects**: Compliance_Assessment_Session__c

**Custom Metadata**: Assessment_Wizard_Config__mdt (16 records: HIPAA, PCI, SOC2)

**LWC components**: assessmentWizard, wizardStep, assessmentProgressTracker, crossFrameworkPrefill

### WS8 — SEC CYBERSECURITY DISCLOSURE (Agent 5 - COMPLETE)

**Package**: Main Elaro 2GP

**Custom Objects**: Materiality_Assessment__c, Disclosure_Workflow__c, Board_Governance_Report__c,
Incident_Timeline__c, Holiday__c, SEC_Control_Mapping__c

**Filing deadline**: Determination_Date + 4 business days (excludes weekends + Holiday__c)

**Approval flow**: CISO > Legal > CFO > CEO > Board > Filing

### WS2 — AI GOVERNANCE MODULE (Agent 6 - COMPLETE)

**Package**: Main Elaro 2GP | **Deadline**: EU AI Act enforcement August 2, 2026

**Custom Objects**: AI_System_Registry__c, AI_Human_Oversight_Record__c, AI_RMF_Mapping__c

**Custom Metadata**: AI_Classification_Rule__mdt (4 rules)

**Implemented**: AIDetectionEngine, AIAuditTrailScanner, AILicenseDetector,
AIRiskClassificationEngine, AIGovernanceService (IComplianceModule), AIGovernanceController

**Risk levels**: Unacceptable/High/Limited/Minimal per EU AI Act Annex III

### WS5 — TRUST CENTER MVP (Agent 7 - COMPLETE)

**Package**: Main Elaro 2GP

**CRITICAL SECURITY**: Exposes data publicly via Salesforce Sites.
- NEVER expose Compliance_Finding__c, Evidence__c, or any PII
- ONLY expose Trust_Center_View__c (materialized/aggregated data)

**Custom Objects**: Trust_Center_View__c, Trust_Center_Link__c

**Implemented**: TrustCenterDataService (without sharing — scheduled aggregation),
TrustCenterLinkService, TrustCenterController (with sharing), TrustCenterGuestController (with sharing)

### INTEGRATION, QA & LAUNCH (Agent 8 - COMPLETE)

- All 370 Apex classes + 60 LWC components upgraded to API v66.0
- Command Center wired to Remediation Orchestrator
- Assessment Wizard wired to Rule Engine
- Event Monitoring wired to Rule Engine results

### Pre-AppExchange Submission (Remaining)

1. Joint Checkmarx security scan (zero HIGH findings required)
2. End-to-end workflow testing (CMMC, SEC, AI Gov)
3. Performance testing (500+ rules, 1000+ controls)
4. WCAG 2.1 AA accessibility audit
5. AppExchange security review submission
6. Demo video production and listing content

### Final Quality Gates

```bash
sf scanner run --target force-app --format table --severity-threshold 1
sf scanner run --target force-app-healthcheck --format table --severity-threshold 1
sf apex run test --target-org elaro-dev --test-level RunLocalTests --wait 30
npm run test:unit
sf apex run test --target-org elaro-dev --test-level RunLocalTests --code-coverage --wait 30
```

Zero HIGH findings. 85%+ coverage per class. All Jest tests passing. WCAG 2.1 AA compliant.
