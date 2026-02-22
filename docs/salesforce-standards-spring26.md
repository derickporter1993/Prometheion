# Salesforce Best Practices & Standards

**Winter '25 (API v62.0) through Spring '26 (API v66.0)**
**Last Updated:** February 22, 2026

---

## 1. Apex Security

### SOQL Access Control

`WITH USER_MODE` is the current Salesforce recommendation. `WITH SECURITY_ENFORCED` is being phased out.

| Feature | `WITH USER_MODE` | `WITH SECURITY_ENFORCED` |
|---|---|---|
| Scope | SOQL + DML | SOQL only |
| WHERE/ORDER BY FLS | Enforced | Not enforced |
| Polymorphic fields | Full support | Limited |
| Error reporting | All FLS errors | First error only |
| Future support | Active standard | "May likely be versioned out" |

```apex
// SOQL -- always WITH USER_MODE
List<Account> accts = [SELECT Id, Name FROM Account WHERE Id = :someId WITH USER_MODE];

// Dynamic SOQL -- Database.queryWithBinds() only, never string concatenation
Map<String, Object> binds = new Map<String, Object>{ 'status' => statusVal };
List<SObject> results = Database.queryWithBinds(
    'SELECT Id FROM Compliance_Score__c WHERE Status__c = :status WITH USER_MODE',
    binds, AccessLevel.USER_MODE
);

// DML -- always 'as user'
insert as user newRecords;
update as user existingRecords;
delete as user oldRecords;

// Database methods -- always AccessLevel.USER_MODE
Database.insert(records, false, AccessLevel.USER_MODE);
Database.update(records, false, AccessLevel.USER_MODE);
```

`Security.stripInaccessible()` remains valid for graceful degradation (silently stripping inaccessible fields instead of throwing exceptions).

### Sharing Keywords

| Class Type | Keyword | Behavior |
|---|---|---|
| Controllers, REST endpoints | `with sharing` | Enforces current user's sharing rules |
| Services, utilities, handlers | `inherited sharing` | Inherits caller's context; defaults to `with sharing` as entry point |
| System operations (documented) | `without sharing` | Bypasses sharing; must document why |
| Omitted (no keyword) | **Defaults to `without sharing`** | Not the same as `inherited sharing`; always specify explicitly |
| DTOs / data classes (no SOQL/DML) | No keyword needed | Pure data containers have no sharing context |
| `@IsTest` classes | No keyword needed | Test classes use `private class` |

Inner classes do NOT inherit sharing from outer classes. `inherited sharing` from a trigger context acts as `without sharing`. Explicitly specifying `inherited sharing` helps pass AppExchange security review.

### Access Modifiers (v65.0+ Breaking Change)

API v65.0+ requires explicit access modifiers on abstract and override methods. Omitting them causes a compilation failure.

```apex
public abstract class BaseProcessor {
    public abstract void process(List<SObject> records);   // MUST have modifier
    protected virtual void validate(SObject record) { }    // MUST have modifier
}

public class ConcreteProcessor extends BaseProcessor {
    public override void process(List<SObject> records) { }   // MUST match or widen
    protected override void validate(SObject record) { }
}
```

---

## 2. Null Handling

| Operator | Introduced | Purpose |
|---|---|---|
| Safe navigation `?.` | Winter '21 (API v50.0) | Returns null instead of NullPointerException |
| Null coalescing `??` | Spring '24 (API v60.0) | Default value when null |

```apex
// Null coalescing -- left-associative, lazy evaluation
String name = account.Name ?? 'Unknown';
String val = a ?? b ?? c ?? 'default';

// Safe navigation + null coalescing
String ownerName = [SELECT Owner.Name FROM Case WHERE Id = :caseId LIMIT 1]
    ?.Owner?.Name ?? 'Unassigned';
```

**Gotcha:** `?.` returns null (not an exception), so `null != someValue` evaluates to `true`. Reason through what null means in your comparisons.

---

## 3. Async Patterns

### Hierarchy of Preference

| Priority | Pattern | Use Case |
|---|---|---|
| 1st | **Queueable + Database.Cursor** | Modern standard. Complex types, chaining, monitoring, state. |
| 2nd | **Batch Apex** | Very large volumes (50M+ records) where Cursor limits are insufficient |
| Avoid | **`@future`** | Legacy. PMD GitHub Issue #6203 proposes flagging as violation. |

### Queueable

- 50 jobs per synchronous transaction, 1 per async transaction
- Supports complex data types (SObjects, custom classes)
- Job chaining with monitoring via AsyncApexJob
- State management between executions

### Database.Cursor (GA -- Spring '26, API v66.0)

Beta in Summer '24. GA in Spring '26.

| Specification | Value |
|---|---|
| Max records per cursor | 50 million |
| Max fetch calls per transaction | 10 |
| Cursor expiration | 48 hours |
| Active instances per 24 hours | 100K-200K (upgraded from beta) |
| Aggregate rows per day | 100 million (shared with PaginationCursor) |
| Big Object support | No |
| Serializable for @AuraEnabled | Yes (GA feature) |

Each `fetch()` counts against SOQL query limit. Fetched rows count against query row limit.

### PaginationCursor (GA -- Spring '26, API v66.0)

Separate cursor type for UI pagination:

| Feature | Database.Cursor | Database.PaginationCursor |
|---|---|---|
| Max records | 50M | 100K |
| Active instances/24hrs | Up to 200K | 200K |
| Max rows per page | N/A | 2,000 |
| Page consistency | No | Yes (consistent page sizes) |
| Primary use | Backend processing | UI pagination, infinite scroll |

### Transaction Finalizers (GA -- Summer '21)

Cleanup/recovery after Queueable jobs. Runs in separate execution context. Can re-enqueue failed jobs (up to 5 times). Handles uncatchable limit exceptions.

```apex
public class ScanFinalizer implements Finalizer {
    public void execute(FinalizerContext ctx) {
        if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
            ElaroLogger.error('ScanProcessor', ctx.getException().getMessage(), '');
        }
    }
}
```

### AsyncOptions & QueueableDuplicateSignature (GA -- Winter '24)

```apex
AsyncOptions options = new AsyncOptions();
options.setMaximumQueueableStackDepth(5);
options.setMinimumQueueableDelayInMinutes(1);
options.setDuplicateSignature(
    new QueueableDuplicateSignature.Builder()
        .addId(someRecordId)
        .build()
);
System.enqueueJob(new ScanProcessor(cursor, 0), options);
// Throws DuplicateMessageException when duplicate detected
```

---

## 4. Testing Standards

### Assert Class (Winter '23, API v56.0)

The `Assert` class is the recommended standard. Old `System.assert*` methods are not deprecated but are superseded.

| New (Assert class) | Old (System class) |
|---|---|
| `Assert.areEqual(expected, actual, msg)` | `System.assertEquals()` |
| `Assert.areNotEqual(bad, actual, msg)` | `System.assertNotEquals()` |
| `Assert.isTrue(condition, msg)` | `System.assert()` |
| `Assert.isFalse(condition, msg)` | -- |
| `Assert.isNull(value, msg)` | -- |
| `Assert.isNotNull(value, msg)` | -- |
| `Assert.isInstanceOfType(obj, type, msg)` | -- |
| `Assert.fail(msg)` | `System.assert(false)` |

### @IsTest(testFor) -- Beta, Spring '26

Links test classes to production classes for the new `RunRelevantTests` test level.

```apex
// Syntax uses string format with ApexClass:/ApexTrigger: prefixes
@IsTest(testFor='ApexClass:HealthCheckScanner,ApexTrigger:ComplianceTrigger')
private class HealthCheckScannerTest {
    // ...
}

// Companion annotation -- ensures test always runs
@IsTest(critical=true)
private class CriticalSecurityTest { }
```

Works with: `sf project deploy start --test-level RunRelevantTests`

### Test Patterns

- `@TestSetup` for shared test data (runs once per class)
- `Test.startTest()` / `Test.stopTest()` to reset governor limits
- `System.runAs()` for permission and sharing tests
- `HttpCalloutMock` for callout testing
- 85%+ coverage per class with meaningful assertions

---

## 5. ApexDoc (Standardized -- Winter '26, API v65.0)

Based on JavaDoc standard. Parsed by Agentforce, platform tools, and AppExchange reviewers.

### Supported Tags

**Block tags:** `@author`, `@since`, `@group`, `@param`, `@return`, `@throws` / `@exception`, `@see`, `@deprecated`, `@example`

**Inline tags:** `{@link ClassName}`, `{@code someCode}`

**No `@description` tag.** Description is the first text block in the comment.

```apex
/**
 * Scans Salesforce Security Health Check settings via Tooling API and returns
 * risk-categorized findings with a composite security score.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see ScoreAggregator
 */
public inherited sharing class HealthCheckScanner {

    /**
     * Executes a full security health check scan.
     *
     * @param includeRiskItems Whether to include individual risk item details
     * @return HealthCheckResult containing score and categorized findings
     * @throws AuraHandledException if Tooling API query fails
     * @example
     * HealthCheckResult result = new HealthCheckScanner().scan(true);
     */
    public HealthCheckResult scan(Boolean includeRiskItems) { }
}
```

---

## 6. LWC Standards

### Template Directives

`lwc:if` / `lwc:elseif` / `lwc:else` (Spring '23). Legacy `if:true` / `if:false` are deprecated and will be removed.

Performance improvement: property getters accessed only once per directive instance with `lwc:if`.

**Spring '26 Beta:** Complex Template Expressions allow JavaScript expressions directly in LWC templates (API v66.0). Do NOT use in production.

### Component Requirements

Every LWC component must handle: loading state, error state, empty state.

- WCAG 2.1 AA: ARIA labels, keyboard navigation, focus management
- SLDS for all styling
- Custom Labels for all user-facing strings (required for i18n and AppExchange)
- `@wire` for reactive read operations; imperative calls for user-triggered actions

---

## 7. Breaking Changes (v62.0 -- v66.0)

| API Version | Release | Change | Error |
|---|---|---|---|
| v62.0 | Winter '25 | Set modification during iteration blocked | `System.FinalException` |
| v63.0 | Spring '25 | JSON serialization of exceptions removed | `System.JSONException` |
| v63.0 | Spring '25 | Default Accept header for callouts changed to `*/*` | Behavioral |
| v65.0 | Winter '26 | Abstract/override methods require explicit access modifiers | Compilation failure |
| v65.0 | Winter '26 | SOAP API `login()` deprecated | HTTP 500 / `UNSUPPORTED_API_VERSION` |
| -- | Summer '25 | API versions 21.0 through 30.0 retired | `410 GONE` |

### Spring '26 Platform Changes

| Change | Date | Impact |
|---|---|---|
| Session IDs removed from Outbound Messages | ~Feb 16-23, 2026 | Use OAuth instead |
| My Domain enforced in production | Spring '26 | All API traffic must use My Domain URLs |
| Connected App creation disabled by default | Spring '26 | Use External Client Apps |
| `Blob.toPdf()` rendering engine upgraded | Spring '26 (enforced Summer '26) | Font/rendering changes |
| SOAP Login v31.0-64.0 retiring | Summer '27 | Plan migration to ECAs |

---

## 8. Integration Patterns

### Authentication Architecture

#### Named Credentials + External Credentials (Winter '23+)

Salesforce has separated authentication into two metadata types:

- **Named Credential**: Stores endpoint URL, references an External Credential
- **External Credential**: Stores auth configuration (OAuth, API Key, JWT, AWS Sig V4, Basic, Custom)
- **Principal**: Holds actual auth details within External Credential, access controlled via Permission Sets

Legacy Named Credentials (pre-Winter '23) still function but migration to the modern split architecture is recommended.

```apex
// Always use Named Credentials -- never hardcode endpoints or credentials
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:MyNamedCredential/api/v1/resource');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setBody(JSON.serialize(payload));
req.setTimeout(30000);

Http http = new Http();
HttpResponse res = http.send(req);
```

#### External Client Apps (Replacing Connected Apps)

| Feature | Connected Apps | External Client Apps |
|---|---|---|
| Security posture | Open by default | Closed by default |
| 2GP packaging | Limited | Native support |
| OAuth flows | All (including legacy) | Modern only (no username-password) |
| Scratch org support | Workarounds needed | Local creation supported |

Spring '26: Creation of new Connected Apps disabled by default. Existing ones continue to function. Migrate via App Manager > "Migrate to External Client App."

#### OAuth Flow Selection

| Use Case | Flow | Security |
|---|---|---|
| Server-to-server (preferred) | **JWT Bearer Token** | Highest -- private key signed |
| Server-to-server (simpler) | **Client Credentials** | Good |
| Web apps with backend | **Authorization Code + PKCE** | High |
| Headless devices | **Device Authorization** | Medium |
| Legacy (avoid) | **Username-Password** | Low -- not supported by ECAs |

### Callout Patterns

#### Governor Limits

| Limit | Value |
|---|---|
| Max callouts per sync transaction | 100 |
| Max timeout per callout | 120,000 ms (2 minutes) |
| Default timeout | 10,000 ms (10 seconds) |
| Max response size (sync) | 6 MB |
| Max response size (async) | 12 MB |

#### Staying Within 100-Callout Limit

- **Batch Apex**: Limits reset per `execute()` invocation
- **Queueable chaining**: Each job gets fresh limits
- **Continuation** (Visualforce/Aura): Async callouts, limits reset on return
- Monitor with `Limits.getCallouts()` / `Limits.getLimitCallouts()`

#### Retry Patterns

Salesforce does not auto-retry failed callouts. Implement using:
1. Queueable chaining with exponential backoff
2. Transaction Finalizers to detect failures and re-enqueue
3. Circuit breaker pattern for persistently failing APIs
4. Custom error logging object for batch retries

---

## 9. Event-Driven Architecture

### Platform Events

All new Platform Events are **High-Volume** by default (API v45.0+). 72-hour replay retention.

| Publish Mode | When Published | Survives Rollback | Best For |
|---|---|---|---|
| Publish Immediately | When `EventBus.publish()` executes | Yes | Logging, audit, notifications |
| Publish After Commit | After transaction commits | No | Data sync requiring committed data |

**Apex trigger best practices:**
- Only `after insert` triggers supported
- Use `EventBus.TriggerContext.currentContext().setResumeCheckpoint()` for trigger resumption
- Use partition key fields for parallel subscriber scaling
- Triggers run asynchronously with separate governor limits

**Apex publish callbacks:** Implement `EventBus.EventPublishFailureCallback` and/or `EventBus.EventPublishSuccessCallback` for confirmation of async publish results.

### Pub/Sub API (gRPC) -- Recommended for External Subscribers

Salesforce's first customer-facing gRPC API. HTTP/2 with Apache Avro binary encoding.

| Feature | Streaming API (CometD) | Pub/Sub API (gRPC) |
|---|---|---|
| Protocol | HTTP/1.1, Bayeux/CometD | HTTP/2, gRPC |
| Encoding | JSON | Apache Avro (binary) |
| Direction | Subscribe only | Bidirectional (publish + subscribe) |
| Flow control | Push-based (server) | Pull-based (client via FetchRequest) |
| Language support | Java (EMP-Connector) | 11 languages |

- Max 1,000 concurrent streams per gRPC channel
- Max 200 events per publish request
- **All new projects should use Pub/Sub API.** CometD is legacy.
- Streaming API versions 23.0-36.0 retired in Winter '25.

### Change Data Capture (CDC)

Near real-time event messages when records are created, updated, deleted, or undeleted. 3-day retention.

**When to use:** External data sync, triggering external workflows, replacing polling patterns.

**Spring '26 change:** Custom formula fields are no longer supported in CDC events.

**Best practices:**
- Use `ChangeEventHeader` to filter unwanted events (prevent integration loops)
- Subscribe via Pub/Sub API for external consumers
- Design idempotent consumers with Replay ID deduplication

---

## 10. External Services & Flow Integration

### External Services

Register an external REST API by importing its OpenAPI (OAS 2.0/3.0) spec. Salesforce generates invocable actions for Flow Builder, Apex, and Agentforce.

- Winter '26: Binary file uploads/downloads up to 16 MB (OAS 3.0)
- Spring '26: Generate OpenAPI docs from `@AuraEnabled` Apex classes for agent actions

### HTTP Callout Actions in Flow (GA)

No-code callouts from Flow Builder. Supports GET, POST, PUT, PATCH, DELETE.

1. Set up Named Credential + External Credential
2. Create HTTP Callout action in Flow Builder
3. Provide sample response -- Salesforce infers the data structure
4. No OpenAPI spec needed (unlike External Services)

**Limitations:**
- Callouts not allowed directly in Scheduled Flows (use "Launch Flow Dynamically")
- Only handles 2xx by default -- edit External Service to add error response schemas
- Always use fault paths on callout elements
- Same governor limits as Apex callouts

---

## 11. API Standards

### Current API Versioning

| Status | API Versions |
|---|---|
| **Latest** | v66.0 (Spring '26) |
| Supported minimum | v31.0 |
| Retired (Summer '25) | v21.0 - v30.0 |
| SOAP Login retiring (Summer '27) | v31.0 - v64.0 |

Salesforce supports each version for minimum 3 years with 1 year deprecation notice. Retired versions return `410 GONE`.

### Which API to Use

| Scenario | API |
|---|---|
| Standard CRUD, mobile/web apps | **REST API** |
| Enterprise ERP, contract-driven | **SOAP API** |
| 2,000+ records, data migrations, ETL | **Bulk API 2.0** (always v2, not v1) |
| Bundling multiple calls atomically | **Composite API** (up to 25 subrequests) |
| Nested data, modern UI | **GraphQL API** |

---

## 12. Middleware Patterns

### Event-Driven vs Request-Reply

| Pattern | When | Salesforce Tools |
|---|---|---|
| Event-driven | Async, loose coupling, multi-subscriber | Platform Events, CDC, Pub/Sub API |
| Request-reply | Synchronous data needs, real-time validation | REST API, SOAP API, Named Credentials + Apex |

### Orchestration vs Choreography

Most mature integrations use a **hybrid approach**:
- **Orchestration** (single controller): Strict ordering, complex multi-step processes -- via MuleSoft or Flow Orchestrator
- **Choreography** (autonomous services): Loose coupling, scalability -- via Platform Events/CDC

### When to Use Middleware (MuleSoft, Informatica, Boomi)

- Orchestration across multiple external systems
- Complex transformation logic
- Aggregation of multiple API calls
- Transactional integrity across systems
- Message queuing and guaranteed delivery
- Protocol translation (SOAP to REST, XML to JSON)

### MuleSoft Integration Best Practices

API-Led Connectivity (three-layer approach):
- **System Layer**: Direct connectors to source systems
- **Process Layer**: Business logic, orchestration, transformation
- **Experience Layer**: APIs tailored for specific consumers

Rules of thumb:
- Business logic belongs in Salesforce unless MuleSoft APIs serve multiple consumers
- Use OAuth 2.0 (not basic auth) between MuleSoft and Salesforce
- Monitor Salesforce API limits

### Anti-Patterns

- Do not use Platform Events for internal Salesforce communication when subflows suffice
- Do not publish events from triggers on the same event object (infinite loop)
- Do not use Outbound Messages for new integrations (legacy Workflow Rules pattern)

---

## 13. Retired & Deprecated Features

| Feature | Status | Replacement |
|---|---|---|
| **Salesforce Functions** | Retired Jan 31, 2025 | Heroku, AWS Lambda, on-platform Queueable |
| **Workflow Rules & Process Builder** | End-of-support Dec 31, 2025 | Flow Builder |
| **Outbound Messages** | Legacy (no Session IDs) | Platform Events + Pub/Sub API, or Flow HTTP Callout |
| **`sfdx` commands** | Removed Nov 2024 | `sf` CLI v2 |
| **Code Analyzer v4** | Retired Aug 2025 | Code Analyzer v5 (`sf code-analyzer run`) |
| **Connected Apps (creation)** | Disabled by default Spring '26 | External Client Apps |
| **Streaming API (CometD)** | De-emphasized | Pub/Sub API (gRPC) |
| **PushTopic events** | Legacy | Change Data Capture |
| **`@future`** | Legacy (PMD violation proposed) | Queueable |
| **`WITH SECURITY_ENFORCED`** | Being phased out | `WITH USER_MODE` |
| **`System.assertEquals`** | Superseded | `Assert` class |
| **`if:true` / `if:false`** | Deprecated | `lwc:if` / `lwc:elseif` / `lwc:else` |
| **Heroku enterprise sales** | Retired early 2026 | Credit-card Heroku, AWS, other cloud |

---

## 14. CLI & Tooling

### sf CLI (v2)

```bash
# Deploy
sf project deploy start --target-org myOrg --test-level RunLocalTests --wait 30

# Test
sf apex run test --target-org myOrg --test-level RunLocalTests --wait 10

# Scratch org
sf org create scratch --definition-file config/project-scratch-def.json --duration-days 30

# Code Analyzer v5 (NOT sf scanner -- that was v4)
sf code-analyzer run --target force-app --format table --severity-threshold 1
```

Never use `sfdx` commands. Deprecated June 2024, removed November 2024.

### Code Analyzer v5 (GA -- April 2025)

| v4 (retired) | v5 (current) |
|---|---|
| `sf scanner run` | `sf code-analyzer run` |
| 6 commands | 3 commands: `run`, `rules`, `config` |
| -- | `--rule-selector AppExchange` for AppExchange rules |
| PMD older versions | PMD v7.15, 500+ built-in rules |

---

## Sources

All findings sourced from official Salesforce documentation (developer.salesforce.com, help.salesforce.com), Salesforce release notes (Spring '26, Winter '26, Winter '25), Trailhead modules, Salesforce developer blog, PMD GitHub issues, and recognized community sources (Salesforce Ben, Bob Buzzard, UnofficialSF).
