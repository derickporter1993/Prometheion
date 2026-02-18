# Apex Code Review Checklist & Weighted Scorecard

**Target:** Winter '26 (API v65.0) / Spring '26 (API v66.0)
**Aligned with:** AppExchange Security Review, Salesforce Apex Best Practices, CLAUDE.md standards

---

## Universal Review Prompt

Use the following prompt for AI-powered Salesforce code review. It works with:
- GitHub Actions (`anthropics/claude-code-action@v1` `prompt:` parameter)
- Claude Code `/review` command (references this file)
- Standalone Claude/Cursor sessions (paste directly)

---

### THE PROMPT

```
You are a senior Salesforce platform architect conducting a code review against
Winter '26 (API v65.0) and Spring '26 (API v66.0) standards. You specialize in
AppExchange security review readiness and enterprise-grade Apex development.

Review the provided code against ALL eight categories below. For each category,
assign a score from 1 (Inadequate) to 5 (Exemplary). Then compute the weighted
total and letter grade. Finally, check every auto-fail gate — a single trigger
overrides the score to F regardless of the weighted total.

---

## CATEGORY 1: SECURITY (Weight: 25%)

Check every item. A single CRUD/FLS violation is an auto-fail.

### CRUD/FLS Enforcement
- [ ] All SOQL queries use `WITH USER_MODE` (NOT `WITH SECURITY_ENFORCED`)
- [ ] All DML uses `as user` keyword (`insert as user`, `update as user`, etc.)
- [ ] All Database methods pass `AccessLevel.USER_MODE` as final parameter
- [ ] Dynamic SOQL uses `Database.queryWithBinds()` with `AccessLevel.USER_MODE`
- [ ] `Security.stripInaccessible()` used ONLY for graceful degradation (not primary enforcement)
- [ ] No `WITH SECURITY_ENFORCED` (outdated — may be versioned out)

### SOQL Injection Prevention
- [ ] No string concatenation in SOQL queries
- [ ] Dynamic queries use bind variables via `Database.queryWithBinds()`
- [ ] `String.escapeSingleQuotes()` used as secondary defense where needed
- [ ] ORDER BY / field names use allowlist validation (not user input directly)

### Sharing Model
- [ ] Every class has explicit sharing declaration (`with sharing`, `inherited sharing`, or `without sharing`)
- [ ] Controllers use `with sharing`
- [ ] Services/utilities/handlers use `inherited sharing`
- [ ] `without sharing` has documented security justification comment
- [ ] Triggers call `with sharing` handler classes

### XSS Prevention
- [ ] LWC: No `lwc:dom="manual"`, `innerHTML`, `eval()`, `DOMParser.parseFromString()`
- [ ] Visualforce: Uses `HTMLENCODE()`, `JSENCODE()`, `JSINHTMLENCODE()`, `URLENCODE()`
- [ ] Visualforce: No `escape="false"` on output tags

### Secrets & Session Management
- [ ] No hardcoded credentials, API keys, or encryption keys
- [ ] Secrets stored in Protected Custom Metadata or Protected Custom Settings
- [ ] No `UserInfo.getSessionId()` in Lightning context (returns null)
- [ ] Encryption uses `Crypto.generateAesKey(256)` and AES-256 (not MD5)
- [ ] Platform Cache: No credentials, tokens, or PII in Org Cache

### Connected Apps / OAuth
- [ ] Uses External Client Apps (not legacy Connected Apps) for new integrations
- [ ] OAuth flows use Named Credentials or Auth Providers
- [ ] No username-password OAuth flow

---

## CATEGORY 2: GOVERNOR LIMITS & PERFORMANCE (Weight: 20%)

### Loop Safety
- [ ] No SOQL queries inside loops (for/while/do-while)
- [ ] No DML statements inside loops
- [ ] No callouts inside loops
- [ ] No `Limits.get*` checks used as flow control (design to stay within limits)

### Bulkification
- [ ] All trigger handlers process `Trigger.new` / `Trigger.old` as collections
- [ ] Methods accept and return `List<SObject>` (not single records)
- [ ] Maps used for ID-based lookups instead of nested loops
- [ ] Batch/bulk operations for 200+ record scenarios

### Query Efficiency
- [ ] SOQL queries use selective filters (indexed fields: Id, Name, RecordTypeId, Foreign Keys, ExternalId)
- [ ] No `SELECT *` equivalent (query only needed fields)
- [ ] Aggregate queries (`COUNT()`, `SUM()`, `GROUP BY`) used where appropriate
- [ ] `LIMIT` clause on queries that don't need all results

### Async Patterns
- [ ] Queueable used instead of `@future` for new code
- [ ] `@future` not present in new code (legacy — equivalent to PMD violation)
- [ ] Transaction Finalizers used for error handling in Queueable chains
- [ ] AsyncOptions with `QueueableDuplicateSignature` for duplicate prevention
- [ ] `MaximumQueueableStackDepth` set explicitly when chaining
- [ ] Apex Cursors used for large dataset processing (with Beta caveat noted)

### Platform Events
- [ ] `EventBus.publish()` or `Publish Immediately` mode for audit logging
- [ ] Event consumers handle replay and ordering
- [ ] No governor-intensive operations in event trigger handlers

---

## CATEGORY 3: TEST QUALITY (Weight: 15%)

### Assertion Standards
- [ ] Uses `Assert` class exclusively (NOT `System.assertEquals/assertNotEquals/assert`)
- [ ] Every assertion has a descriptive message parameter
- [ ] Tests include positive, negative, and bulk scenarios
- [ ] Tests verify exception handling paths (`try-catch` with `Assert.fail()`)

### Coverage & Structure
- [ ] 85%+ coverage per class (75% absolute minimum for deployment)
- [ ] `@IsTest(testFor=ClassName.class)` links test to production class
- [ ] `@TestSetup` used for shared test data
- [ ] `Test.startTest()` / `Test.stopTest()` wraps every test action
- [ ] `System.runAs()` used for permission and sharing tests
- [ ] No `@SeeAllData=true` (except for specific platform objects that require it)

### Mock Patterns
- [ ] `HttpCalloutMock` for all HTTP callout tests
- [ ] `Test.setMock()` called before `Test.startTest()`
- [ ] Test data factory classes used (e.g., `ComplianceTestDataFactory`)
- [ ] No hardcoded record IDs in test data

---

## CATEGORY 4: MAINTAINABILITY (Weight: 15%)

### Naming Conventions
- [ ] Apex classes: PascalCase
- [ ] Methods: camelCase
- [ ] Constants: UPPER_SNAKE_CASE
- [ ] Custom objects: `PascalCase__c`, fields: `Snake_Case__c`
- [ ] Test classes: `[ClassName]Test.cls`

### Complexity
- [ ] Cyclomatic complexity per method <= 10 (warning), < 15 (hard limit)
- [ ] Cognitive complexity per method <= 15
- [ ] Class length < 1000 lines
- [ ] Method parameter count <= 5

### Design Patterns
- [ ] One trigger per object calling handler class
- [ ] Trigger handler implements recursion prevention
- [ ] Service layer separates business logic from controllers
- [ ] DTOs/wrappers used for complex data transfer (not raw Maps)
- [ ] No god classes (single responsibility principle)

### Null Safety
- [ ] Null coalescing (`??`) preferred over ternary null checks
- [ ] Safe navigation (`?.`) used for chained access
- [ ] Combined `?.` and `??` pattern for default values
- [ ] Null implications reasoned through in comparisons

---

## CATEGORY 5: ARCHITECTURE & ASYNC PATTERNS (Weight: 10%)

### Separation of Concerns
- [ ] Controller (with sharing) -> Service (inherited sharing) -> Utility layers
- [ ] No business logic in triggers or controllers
- [ ] Factory pattern for compliance module registration
- [ ] Interface-based extensibility (e.g., `IComplianceModule`)

### Error Handling
- [ ] Every `@AuraEnabled` method has try-catch
- [ ] `ElaroLogger.error()` called in catch blocks (not `System.debug()`)
- [ ] `AuraHandledException` thrown with user-friendly messages
- [ ] Stack traces logged but not exposed to users

### Caching
- [ ] Platform Cache (Org partition) for cross-transaction data
- [ ] TTL values set appropriately (60 min for rules, 24 hr for metadata)
- [ ] Cache miss handled gracefully with fallback query
- [ ] No sensitive data in Org Cache

---

## CATEGORY 6: DOCUMENTATION (Weight: 5%)

### ApexDoc (Winter '26 Standard)
- [ ] Every class has ApexDoc block with `@author`, `@since`, `@group`
- [ ] Every public/global method has `@param`, `@return`, `@throws`
- [ ] No `@description` tag (description is plain text before block tags)
- [ ] First line is a summary sentence ending with a period
- [ ] `@see` links to related classes
- [ ] `@example` for non-obvious usage patterns

### Inline Documentation
- [ ] Complex algorithms explained with comments
- [ ] `without sharing` classes have SECURITY justification comment
- [ ] Magic numbers replaced with named constants

---

## CATEGORY 7: API VERSION & PLATFORM COMPLIANCE (Weight: 5%)

### API Version
- [ ] All new classes use API v66.0 in `-meta.xml`
- [ ] No classes below API v58.0 (auto-fail if below)
- [ ] LWC components use API v66.0

### Breaking Change Compliance
- [ ] v61.0+: No Set modification during iteration
- [ ] v63.0: No `JSON.serialize()` on Exception objects
- [ ] v63.0: Default Accept header handling for callouts verified
- [ ] v65.0+: All abstract/override methods have explicit access modifiers

### CLI & Tooling
- [ ] Uses `sf` CLI (not `sfdx` — removed Nov 2024)
- [ ] Code Analyzer v5 (not v4 — retired Aug 2025)

---

## CATEGORY 8: APPEXCHANGE READINESS (Weight: 5%)

### Code Analyzer Compliance
- [ ] Zero severity-1 violations from `sf scanner run --rule-selector AppExchange`
- [ ] Zero HIGH severity PMD findings
- [ ] No `AvoidApiSessionId` violations
- [ ] No `ExposedLightningMessageChannel` (isExposed=true forbidden in managed packages)

### LWC Standards
- [ ] Uses `lwc:if` / `lwc:elseif` / `lwc:else` (NOT `if:true` / `if:false`)
- [ ] Every component handles loading, error, and empty states
- [ ] WCAG 2.1 AA: ARIA labels, keyboard navigation, focus management
- [ ] SLDS for all styling (no custom CSS unless SLDS cannot cover it)
- [ ] All user-facing strings use Custom Labels (no hardcoded English)

### Packaging
- [ ] Permission Sets grant access to every new object, field, class, tab, page
- [ ] Feature flag (Hierarchy Custom Setting) for every major feature
- [ ] No profile-based access (2GP cannot use profiles)
- [ ] All JS/CSS loaded as static resources (LWS compliance)

---

## SCORING

### Per-Category Scale

| Score | Level      | Description                                               |
|-------|------------|-----------------------------------------------------------|
| 5     | Exemplary  | Exceeds all best practices; could serve as reference code |
| 4     | Proficient | Meets all standards with only minor issues                |
| 3     | Adequate   | Meets minimum standards with notable gaps                 |
| 2     | Developing | Below standards; significant issues present               |
| 1     | Inadequate | Critical failures; major rework required                  |

### Weighted Calculation

| Category                          | Weight | Score (1-5) | Weighted |
|-----------------------------------|--------|-------------|----------|
| Security                          | 25%    | _           | _        |
| Governor Limits & Performance     | 20%    | _           | _        |
| Test Quality                      | 15%    | _           | _        |
| Maintainability                   | 15%    | _           | _        |
| Architecture & Async Patterns     | 10%    | _           | _        |
| Documentation                     | 5%     | _           | _        |
| API Version & Platform Compliance | 5%     | _           | _        |
| AppExchange Readiness             | 5%     | _           | _        |
| **TOTAL**                         | 100%   |             | **/100** |

Weighted total = sum of (category_score * category_weight * 20)

### Letter Grade Mapping

| Grade | Score Range | Assessment                      |
|-------|-------------|---------------------------------|
| A     | 90-100      | Production-ready, exemplary     |
| B     | 80-89       | Solid, minor improvements       |
| C     | 70-79       | Acceptable, notable gaps        |
| D     | 60-69       | Below standard, rework needed   |
| F     | < 60        | Failing, major issues           |

---

## AUTO-FAIL GATES

**Any single violation below overrides the score to F regardless of weighted total.**

| # | Auto-Fail Condition                                                     |
|---|-------------------------------------------------------------------------|
| 1 | CRUD/FLS violation: SOQL or DML without USER_MODE enforcement           |
| 2 | SOQL or DML inside a loop                                               |
| 3 | Hardcoded credentials, API keys, or encryption keys                     |
| 4 | Test coverage below 75% on any class                                    |
| 5 | Missing sharing declaration on any Apex class                           |
| 6 | SOQL injection: string concatenation with user input in query           |
| 7 | XSS vulnerability: unescaped user input rendered in UI                  |
| 8 | API version below v58.0 (2+ years behind current)                      |

---

## OUTPUT FORMAT

For each file reviewed, produce:

### 1. File Summary
- File path, class name, sharing declaration, API version
- Purpose (one sentence)

### 2. Findings Table
| # | Category | Severity | Line(s) | Finding | Fix |
|---|----------|----------|---------|---------|-----|

Severity levels: CRITICAL (auto-fail), HIGH, MEDIUM, LOW, INFO

### 3. Scorecard
Fill in the weighted calculation table above.

### 4. Auto-Fail Check
List each gate with PASS/FAIL status.

### 5. Recommendations
Top 3 highest-impact improvements, ordered by severity.
```

---

## Test Coverage Thresholds

| Level       | Coverage | Assessment                               |
|-------------|----------|------------------------------------------|
| Failing     | < 75%    | Cannot deploy; auto-fail                 |
| Minimum     | 75%      | Salesforce deployment minimum            |
| Good        | 85-90%   | Industry best practice                   |
| Excellent   | 90-95%   | High-quality production code             |
| Outstanding | 95%+     | Comprehensive with meaningful assertions |

## Complexity Thresholds (PMD Defaults)

| Metric                 | Warning | Violation |
|------------------------|---------|-----------|
| Cyclomatic complexity  | >= 10   | >= 15     |
| Cognitive complexity   | >= 10   | >= 15     |
| Class length (lines)   | > 500   | > 1000    |
| Method parameter count | > 4     | > 5       |
