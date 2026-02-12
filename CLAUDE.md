# ELARO CLAUDE.md: Master Project Context

**Generated:** February 11, 2026 | All 19 audit findings resolved | Spring '26 (API v66.0)
**Standards aligned with:** Salesforce Apex Best Practices Through Spring '26 (PDF), Elaro Sovereign Architecture, Elaro Team Split Plan, Elaro Codebase Fix Report, Solentra Best Practices Guide

---

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Elaro** is a 2GP managed package targeting AppExchange distribution. It automates compliance across
HIPAA, SOC2, PCI-DSS, GDPR, CCPA, GLBA, ISO 27001, FINRA, FedRAMP, CMMC 2.0, SEC Cybersecurity,
NIS2, DORA, and AI Governance (EU AI Act / NIST AI RMF).

Current codebase: 299 Apex classes, 41 LWC components, 54 custom objects, 8 Platform Events,
5 Permission Sets, 5 Apex Triggers. All code has been audit-remediated to modern standards.
Audit score: 84/100.

## Technology Stack

| Layer      | Technology                     |
| ---------- | ------------------------------ |
| Backend    | Apex (Salesforce API v66.0)    |
| Frontend   | Lightning Web Components (LWC) |
| Testing    | Jest (LWC) + Apex Test Classes |
| Linting    | ESLint v9 with LWC plugin      |
| Formatting | Prettier                       |
| Monorepo   | Turborepo (platform/)          |
| Node.js    | v20.0.0+ required              |

## Architecture

- **ComplianceServiceFactory.cls** + **IComplianceModule.cls** interface: Extensible module registration
- **ElaroLogger.cls**: Structured logging via Platform Events (Publish Immediately mode)
- **ElaroSecurityUtils.cls**: Defense-in-depth security utilities
- **ElaroConstants.cls**: Centralized constants
- **ComplianceTestDataFactory.cls**: Shared test data factory

## Two-Team Build Structure

**Team 1** (Sovereign Infrastructure): Async Framework, CMMC 2.0, Rule Engine, Orchestration, NIS2/DORA
**Team 2** (User-Facing Modules): Health Check (separate 2GP), Command Center, Event Monitoring,
Assessment Wizards, SEC Module, AI Governance, Trust Center

## Package Structure

```
sfdx-project.json packageDirectories:
  - path: force-app           # Main Elaro 2GP managed package (shared namespace)
    package: "Elaro"
    versionName: "Spring 26"
    versionNumber: "3.1.0.NEXT"
    default: true

  - path: force-app-healthcheck  # Separate 2GP (elaroHC namespace)
    package: "Elaro Health Check"
    versionName: "Spring 26"
    versionNumber: "1.0.0.NEXT"
    default: false
```

Health Check components go in `force-app-healthcheck/main/default/`.
All other Team 2 components go in `force-app/main/default/`.

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
├── force-app/main/default/          # Main Elaro package
│   ├── classes/                     # Apex classes
│   ├── lwc/                         # LWC components
│   ├── objects/                     # Custom objects, fields, Platform Events (__e)
│   ├── customMetadata/              # Custom Metadata Type records
│   ├── permissionsets/              # Permission Sets
│   ├── labels/                      # Custom Labels
│   ├── flexipages/                  # Lightning App Pages
│   ├── tabs/                        # Custom Tabs
│   └── triggers/                    # Apex triggers
├── force-app-healthcheck/main/default/  # Health Check separate 2GP (elaroHC namespace)
│   ├── classes/                     # Health Check Apex classes
│   ├── lwc/                         # Health Check LWC components
│   ├── objects/                     # Health Check objects (if any)
│   ├── permissionsets/              # Health Check Permission Sets
│   ├── labels/                      # Health Check Custom Labels
│   ├── tabs/                        # Health Check Tabs
│   └── flexipages/                  # Health Check App Pages
├── platform/                        # TypeScript monorepo (Turborepo)
│   └── packages/
│       ├── cli/                     # elaro CLI
│       ├── sf-client/               # Salesforce API client
│       ├── types/                   # Shared TypeScript types
│       └── masking/                 # Data masking utilities
├── scripts/                         # Automation scripts
└── config/                          # Salesforce project config
```

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
<template lwc:if="{isLoading}">
  <lightning-spinner alternative-text="Loading"></lightning-spinner>
</template>
<template lwc:elseif="{hasError}">
  <c-error-panel message="{errorMessage}"></c-error-panel>
</template>
<template lwc:elseif="{isEmpty}">
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

All NEW code: API v66.0 (Spring '26) in .cls-meta.xml and .js-meta.xml:

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
sf org create scratch --definition-file config/project-scratch-def.json --duration-days 30 --alias elaro-dev

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

## Scratch Org Features Required

```json
{
  "orgName": "Elaro Development",
  "edition": "Enterprise",
  "features": [
    "PlatformEvents",
    "Sites",
    "CustomMetadataTypes",
    "BigObjects",
    "StreamingAPI",
    "ApexCursors"
  ],
  "settings": {
    "securitySettings": {
      "sessionSettings": {
        "forceRelogin": false
      }
    },
    "platformEventSettings": {
      "enablePlatformEvents": true
    }
  }
}
```

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/elaro-ci.yml`) runs on push to `main`, `develop`, `release/*`, `claude/*`:

1. **code-quality** - Format check, linting, security audit
2. **unit-tests** - LWC Jest tests
3. **security-scan** - Salesforce Code Analyzer with AppExchange selectors
4. **validate-metadata** - Directory structure validation
5. **cli-build** - Platform TypeScript build
6. **build-success** - Final deployment readiness check

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
# Check for LWC template violations
grep -rn '="{' force-app/main/default/lwc/**/*.html 2>/dev/null

# Run full pre-commit validation
npm run precommit

# Check for outdated security patterns
grep -rn 'WITH SECURITY_ENFORCED' force-app/main/default/classes/ 2>/dev/null
grep -rn 'System.assertEquals' force-app/main/default/classes/ 2>/dev/null
```

---

## TEAM 2: AGENT BUILD PROMPTS

> **Instructions**: Read all coding standards above first.
> Execute these agent prompts in order. Each agent builds one workstream.
> Do NOT skip agents. Each depends on patterns established by the previous one.
> After completing each agent, run `sf scanner run` and `sf apex run test` before proceeding.

### AGENT 1: WS4 — FREE HEALTH CHECK TOOL

**Package**: Separate 2GP, elaroHC namespace
**Directory**: force-app-healthcheck/main/default/
**Timeline**: Q1-Q2, Weeks 1-12
**Priority**: HIGHEST (ships first for lead generation)

#### Build Order

1. ToolingApiService (shared utility)
2. DTOs (HealthCheckResult, ScanFinding, ScanRecommendation)
3. Scanner services (5 scanners)
4. ScoreAggregator
5. HealthCheckController
6. Custom Labels
7. Permission Sets
8. Feature Flag Custom Setting
9. All Apex test classes
10. LWC components (dashboard, then children)
11. LWC Jest tests
12. Metadata (app, tab, flexipage)

#### Apex Classes to Build

**1. ToolingApiService.cls** (inherited sharing, force-app-healthcheck/main/default/classes/)

```apex
/**
 * Provides HTTP REST access to the Salesforce Tooling API for querying
 * SecurityHealthCheck, SecurityHealthCheckRisks, and other Tooling objects.
 *
 * SECURITY NOTE: Tooling API runs in system context. No WITH USER_MODE equivalent.
 * Caller permission validation happens in the controller layer (with sharing).
 * Tooling queries return org-wide security settings, not user record data.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 */
public inherited sharing class ToolingApiService {
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
```

**2. HealthCheckResult.cls** — wrapper DTO: overallScore (Integer 0-100), categoryScores (Map<String, Integer>), findings (List<ScanFinding>), recommendations (List<ScanRecommendation>), scanTimestamp (Datetime)

**3. ScanFinding.cls** — wrapper DTO: category, setting, currentValue, recommendedValue, severity (HIGH_RISK/MEDIUM_RISK/LOW_RISK), description

**4. ScanRecommendation.cls** — wrapper DTO: title, description, setupMenuPath, priority (1=critical, 2=high, 3=medium), category

**5. HealthCheckScanner.cls** (inherited sharing) — Query SecurityHealthCheck and SecurityHealthCheckRisks via Tooling API

**6. MFAComplianceScanner.cls** (inherited sharing) — Query LoginHistory for MFA adoption percentage

**7. ProfilePermissionScanner.cls** (inherited sharing) — Query PermissionSets with ModifyAllData/ViewAllData

**8. SessionSettingsScanner.cls** (inherited sharing) — Query SessionSettings via Tooling API

**9. AuditTrailScanner.cls** (inherited sharing) — Query SetupAuditTrail for high-risk changes

**10. ScoreAggregator.cls** (inherited sharing) — Weighted composite score: Health Check 40%, MFA 20%, Permissions 15%, Sessions 15%, Audit 10%

**11. HealthCheckController.cls** (with sharing) — @AuraEnabled runFullScan(), getLastScanTimestamp()

**12. HealthCheckFeatureFlags.cls** (inherited sharing) — Hierarchy Custom Setting wrapper

#### Custom Labels Required

HC_ScanInProgress, HC_ScanComplete, HC_ScanFailed, HC_NoDataAvailable, HC_HighRisk, HC_MediumRisk, HC_LowRisk, HC_OverallScore, HC_MfaAdoption, HC_PermissionHygiene, HC_SessionSecurity, HC_AuditTrailRisk, HC_GoToSetup, HC_CtaTitle, HC_CtaBody, HC_CtaLink, HC_ScoreExcellent, HC_ScoreGood, HC_ScoreNeedsWork, HC_ScoreCritical, HC_UsersOnMfa, HC_FilterAll, HC_FilterHigh, HC_FilterMedium, HC_FilterLow

#### LWC Components

- **healthCheckDashboard** — Main container, imperative scan call
- **healthCheckScoreGauge** — SVG radial arc gauge 0-100
- **healthCheckRiskTable** — lightning-datatable with severity filters
- **healthCheckRecommendations** — SLDS cards with Setup navigation
- **healthCheckMfaIndicator** — Circular progress ring
- **healthCheckCtaBanner** — AppExchange CTA

#### Quality Gate

```bash
sf scanner run --target force-app-healthcheck --format table --severity-threshold 1
sf apex run test --target-org elaro-dev --test-level RunLocalTests --wait 10
npm run test:unit -- --testPathPattern=healthCheck
```

---

### AGENT 2: WS-CC — COMPLIANCE COMMAND CENTER

**Package**: Main Elaro 2GP
**Directory**: force-app/main/default/
**Timeline**: Q2, Weeks 13-16
**Dependency**: Team 1 Async Framework (Week 8), CMMC data model (Week 12)

#### Build Order

1. Compliance_Action\_\_mdt Custom Metadata Type + 30-50 action records
2. ComplianceContextEngine.cls
3. CommandCenterController.cls
4. Custom Labels
5. LWC components (complianceCommandCenter, complianceActionCard, complianceContextSidebar, complianceNotificationFeed)
6. Test classes and Jest tests

---

### AGENT 3: WS-EM — EVENT-DRIVEN MONITORING

**Package**: Main Elaro 2GP
**Timeline**: Q2-Q3, Weeks 17-20
**Dependency**: Team 1 Async Framework for ConfigDriftDetector as CursorStep

#### Platform Events

- **ComplianceAlert\_\_e**: Framework, Control_Reference, Severity, Finding_Summary, Alert_Type, Source_Record_Id
- **ConfigurationDrift\_\_e**: Change_Type, Changed_By, Changed_Object, Old_Value, New_Value, Risk_Level, Detection_Timestamp
- **BreachIndicator\_\_e**: Pattern_Name, Severity, Event_Sequence (JSON), Time_Window_Minutes, Affected_User_Id

#### Core Classes

- ComplianceAlertPublisher.cls (without sharing — must publish regardless of user context)
- ConfigDriftDetector.cls (inherited sharing, implement as CursorStep or Schedulable)
- EventCorrelationEngine.cls (inherited sharing)
- BreachPatternMatcher.cls (inherited sharing)
- EventWindowService.cls (inherited sharing) — Big Object operations

#### Custom Metadata

- **Correlation_Rule\_\_mdt**: Rule_Name, Event_Sequence (JSON), Time_Window_Minutes, Severity, Description, Is_Active

---

### AGENT 4: WS-AW — GUIDED ASSESSMENT WIZARDS

**Package**: Main Elaro 2GP
**Timeline**: Q3, Weeks 21-24
**Dependency**: Team 1 Rule Engine schema (Week 22), CMMC data model (Week 12)

#### Custom Objects

- **Compliance_Assessment_Session\_\_c**: Session_State (JSON), Wizard_Name, Framework, Current_Stage, Current_Step, Status, Percent_Complete

#### Custom Metadata

- **Assessment_Wizard_Config\_\_mdt**: Wizard_Name, Framework, Stage_Order, Step_Order, Step_Type (Auto_Scan/Manual_Attestation/Evidence_Upload/Approval/Review), Control_Reference, Help_Text, Is_Required

#### LWC Components

- **assessmentWizard** — Parent, persists state to Session\_\_c
- **wizardStep** — Polymorphic based on Step_Type
- **assessmentProgressTracker** — Visual progress bar
- **crossFrameworkPrefill** — Pre-fill from prior assessments

---

### AGENT 5: WS8 — SEC CYBERSECURITY DISCLOSURE MODULE

**Package**: Main Elaro 2GP
**Timeline**: Q3, Weeks 25-32

#### Custom Objects

- **Materiality_Assessment\_\_c**: Incident details, Discovery_Date, Determination_Date, Filing_Deadline (formula: +4 business days), AG_Delay fields, Qualitative impact picklists, Determination_Result, Status
- **Disclosure_Workflow\_\_c**: Form_Type (8-K/10-K), EDGAR_Filing_Number, multi-step Status
- **Board_Governance_Report\_\_c**: Annual 10-K governance reporting
- **Incident_Timeline\_\_c**: Event tracking with SLA indicators
- **Holiday\_\_c**: Business day calculation support
- **SEC_Control_Mapping\_\_c**: Junction to existing control objects

#### Filing Deadline Formula

Filing_Deadline**c = Determination_Date + 4 business days (excludes weekends, Holiday**c checked via validation rule/flow)

#### Approval Process

Multi-step declarative: CISO > Legal > CFO > CEO > Board > Filing

---

### AGENT 6: WS2 — AI GOVERNANCE MODULE MVP

**Package**: Main Elaro 2GP
**Timeline**: Q3-Q4, Weeks 29-38
**DEADLINE**: EU AI Act enforcement August 2, 2026

#### Custom Objects

- **AI_System_Registry\_\_c**: System_Name, System_Type (Einstein_Prediction/Einstein_Bot/GenAI_Function/GenAI_Planner/Custom_ML), Detection_Method, Risk_Level (Unacceptable/High/Limited/Minimal per EU AI Act Annex III), Status, Use_Case_Description
- **AI_Human_Oversight_Record\_\_c**: Original_AI_Output, Human_Decision (Accept/Modify/Reject/Override), Justification, Reviewer
- **AI_Classification_Rule\_\_mdt**: Feature_Type, Use_Case_Context, Risk_Level, EU_AI_Act_Article, Rationale
- **AI_RMF_Mapping\_\_c**: RMF_Function (Govern/Map/Measure/Manage), Compliance_Status

#### Core Classes

- AIDetectionEngine.cls — Metadata API listMetadata() scan for Einstein/GenAI components
- AIAuditTrailScanner.cls — SetupAuditTrail for AI-related changes
- AILicenseDetector.cls — PermissionSetAssignment for Einstein licenses
- AIRiskClassificationEngine.cls — EU AI Act Annex III classification
- AIGovernanceService.cls — IComplianceModule implementation
- AIGovernanceController.cls — Dashboard and discovery endpoints

---

### AGENT 7: WS5 — TRUST CENTER MVP

**Package**: Main Elaro 2GP
**Timeline**: Q4, Weeks 39-46

**CRITICAL SECURITY**: This module exposes data publicly via Salesforce Sites.

- NEVER expose Compliance_Finding**c, Evidence**c, or any PII
- ONLY expose Trust_Center_View\_\_c (materialized/aggregated data)
- Guest User gets minimal field-level access
- Every Sites page load validates shareable link expiration

#### Custom Objects

- **Trust_Center_View\_\_c** (materialized view): Framework, Compliance_Percentage, Last_Audit_Date, Certification_Status, Badge_Image_URL, Is_Public
- **Trust_Center_Link\_\_c**: Link_Token (UUID), Expiration_Date, Access_Tier (Public/Email_Gated/NDA_Required), Access_Count, Is_Active

#### Core Classes

- TrustCenterDataService.cls (without sharing — scheduled aggregation)
- TrustCenterLinkService.cls (inherited sharing — token management)
- TrustCenterController.cls (with sharing — internal admin)
- TrustCenterGuestController.cls (with sharing — Sites, triple-check every method)

#### Sites Configuration

- Guest User Profile: ZERO access to Compliance_Finding**c, Evidence**c, **mdt, **e
- Only Trust_Center_View\_\_c read, only TrustCenterGuestController execute

---

### AGENT 8: INTEGRATION, QA & LAUNCH (Weeks 47-52)

1. Upgrade all v65.0 classes to v66.0
2. Wire Command Center to Team 1 Orchestration Engine
3. Wire Assessment Wizard auto-scan to Team 1 Rule Engine
4. Wire Event Monitoring to Team 1 Rule Engine results
5. Joint Checkmarx scan — fix ALL findings
6. End-to-end testing: CMMC, SEC, AI Gov workflows
7. Performance testing: 500+ rules, 1000+ controls
8. WCAG 2.1 AA audit
9. AppExchange security review submission
10. Documentation and listing content

#### Final Quality Gates

```bash
sf scanner run --target force-app --format table --severity-threshold 1
sf scanner run --target force-app-healthcheck --format table --severity-threshold 1
sf apex run test --target-org elaro-dev --test-level RunLocalTests --wait 30
npm run test:unit
sf apex run test --target-org elaro-dev --test-level RunLocalTests --code-coverage --wait 30
```

Zero HIGH findings. 85%+ coverage per class. All Jest tests passing. WCAG 2.1 AA compliant.
