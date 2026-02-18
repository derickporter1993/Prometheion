# AppExchange Security Review Requirements

**Updated for:** Spring '26 (API v66.0) review cycle
**Source:** Salesforce Product Security team guidelines, Partner Security Portal

---

## Overview

The AppExchange security review is mandatory for all managed packages before listing.
Salesforce's Product Security team combines automated scanning with manual review over
4-6 weeks. Resubmission costs $999 per attempt for paid apps. Less than 50% pass on
first submission.

---

## Mandatory Scanner Toolchain

| Scanner                        | Purpose                         | Access                           |
|--------------------------------|---------------------------------|----------------------------------|
| Salesforce Code Analyzer v5    | PMD, ESLint, RetireJS           | `sf plugins install code-analyzer` |
| Checkmarx CxSAST              | Deep static analysis            | 3 free scans via Partner Portal  |
| OWASP ZAP or Burp Suite       | Dynamic application testing     | Open source / commercial         |
| Qualys SSL Scanner             | TLS/SSL endpoint verification   | Must achieve A grade             |

Chimera was retired June 16, 2025. Code Analyzer v4 was retired August 2025.

---

## Top 10 Failure Reasons (Ranked)

1. **CRUD/FLS violations** (most common by significant margin)
2. **Insecure software versions** (outdated JS libraries via RetireJS)
3. **Sharing violations** (missing `with sharing`)
4. **Insecure secrets storage** (hardcoded credentials)
5. **TLS/SSL misconfiguration** (weak ciphers, missing HSTS)
6. **Sensitive data in debug logs** (`System.debug()` with PII/secrets)
7. **CSRF** (missing token validation)
8. **XSS** (stored and reflected)
9. **Open redirect** (unvalidated redirect URLs)
10. **SOQL injection** (string concatenation in queries)

---

## CRUD/FLS Enforcement: Four Generations

### Generation 1: Schema.Describe (2006, Legacy)
```apex
// DO NOT USE — verbose, error-prone, incomplete
if (Schema.sObjectType.Account.isAccessible()) {
    if (Schema.sObjectType.Account.fields.Name.isAccessible()) {
        // query
    }
}
```

### Generation 2: stripInaccessible (Winter '19, v45.0)
```apex
// USE ONLY for graceful degradation (silently stripping fields)
SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, records);
List<SObject> sanitized = decision.getRecords();
```

### Generation 3: WITH SECURITY_ENFORCED (Summer '20, v48.0)
```apex
// OUTDATED — may be versioned out. Throws QueryException on violation.
// Only enforces FLS on SOQL, not DML. Do NOT use for new code.
List<Account> accts = [SELECT Id FROM Account WITH SECURITY_ENFORCED]; // NO
```

### Generation 4: WITH USER_MODE (Spring '23 GA) -- CURRENT STANDARD
```apex
// REQUIRED for all new code. Enforces CRUD, FLS, sharing rules, restriction rules.
List<Account> accts = [SELECT Id, Name FROM Account WITH USER_MODE];

// Dynamic SOQL
List<SObject> results = Database.queryWithBinds(query, binds, AccessLevel.USER_MODE);

// DML
insert as user newRecords;
update as user existingRecords;
Database.insert(records, false, AccessLevel.USER_MODE);
```

**Scanner note:** Checkmarx and PMD do not fully support DML user-mode detection,
producing false positives. Only the Code Analyzer Graph Engine (`scanner:run:dfa`)
handles both SOQL and DML user-mode patterns correctly.

---

## PMD AppExchange Rules (by Severity)

### Critical
- `AvoidApiVersionWithLockerDisabled` — Aura must use API v40+
- `AvoidHardCodedCredentialsInSetPassword` — No hardcoded passwords
- `AvoidSControls` — S-Controls removed from platform
- `AvoidSystemSetPassword` — No System.setPassword()

### High
- `AvoidApiSessionId` — No session ID in Apex
- `AvoidCreateElementScriptLinkTag` — No dynamic script/link creation
- `AvoidUnescapedHtml` — Escape all HTML output
- `ExposedLightningMessageChannel` — isExposed=true forbidden in managed packages
- `UnsafeHtml` — No unsafe HTML rendering

### Moderate
- `AvoidSessionIdInApex` — No session ID usage
- `FullScopeConnectedApp` — Connected app scope too broad
- `InsecureOAuthCallbackUrl` — Callback URL must be HTTPS
- `InsecureRemoteSiteSetting` — Remote site must be HTTPS
- `SensitiveDataNotProtected` — PII must be encrypted

---

## Sharing Model Requirements

| Class Type              | Required Keyword    | Rationale                                  |
|-------------------------|---------------------|--------------------------------------------|
| Controllers             | `with sharing`      | Enforces record-level access for users     |
| Services / Utilities    | `inherited sharing` | Inherits caller's sharing context          |
| System operations       | `without sharing`   | Must document business justification       |
| Triggers                | N/A                 | Always system mode; call sharing handlers  |
| Missing declaration     | **AUTO-FAIL**       | Effectively runs as `without sharing`      |

---

## SOQL Injection Prevention (Approved Methods)

1. **Static queries with bind variables** (preferred)
   ```apex
   List<Account> accts = [SELECT Id FROM Account WHERE Name = :searchTerm WITH USER_MODE];
   ```

2. **Database.queryWithBinds()** (for dynamic queries)
   ```apex
   Map<String, Object> binds = new Map<String, Object>{ 'name' => searchTerm };
   Database.queryWithBinds('SELECT Id FROM Account WHERE Name = :name WITH USER_MODE',
       binds, AccessLevel.USER_MODE);
   ```

3. **String.escapeSingleQuotes()** (secondary defense)
   ```apex
   String safe = String.escapeSingleQuotes(userInput);
   ```

4. **Typecasting** for non-string inputs
5. **Allowlisting** for ORDER BY and field names

---

## XSS Prevention

### LWC (Lightning Web Security)
- No `lwc:dom="manual"`, `innerHTML`, `eval()`, `DOMParser.parseFromString()`
- Let the framework handle DOM manipulation
- All JS/CSS loaded as static resources (LWS compliance)
- Stricter CSP enforced

### Visualforce
- Use `HTMLENCODE()`, `JSENCODE()`, `JSINHTMLENCODE()`, `URLENCODE()`
- Never set `escape="false"` on output tags

---

## Spring '26 Breaking Changes (Security Impact)

### 1. Connected Apps Creation Disabled by Default
- External Client Apps (ECAs) are the official replacement
- ECAs support only secure OAuth 2.0 flows
- Exclude username-password flow
- Migration: App Manager > Select Connected App > "Migrate to External Client App"

### 2. Session ID Removed from Outbound Messages
- "Send Session ID" checkbox no longer functions
- `UserInfo.getSessionId()` returns null in Lightning context
- Migration: Use OAuth 2.0, Named Credentials, or Auth Providers

### 3. Encryption Algorithm Deprecation
- Must use AES-128 or AES-256 before Summer '26
- MD5 considered weak; use SHA256+ for digests
- `Crypto.generateAesKey(256)` for key generation

---

## Code Analyzer v5 Commands

```bash
# Full AppExchange scan
sf scanner run --target force-app --rule-selector AppExchange --format table --severity-threshold 1

# Security-specific scan
sf scanner run --target force-app --rule-selector "Recommended:Security" --format table

# Generate SARIF for GitHub integration
sf scanner run --target force-app --rule-selector AppExchange --format sarif --outfile results.sarif

# HTML report for review
sf scanner run --target force-app --rule-selector AppExchange --format html --outfile report.html
```

### Configuration (code-analyzer.yml)
```yaml
engines:
  pmd:
    custom_rulesets:
      - ./config/apex-ruleset.xml
rules:
  pmd:ApexSOQLInjection:
    severity: 1
  pmd:OperationWithLimitsInLoop:
    severity: 2
  pmd:ApexCRUDViolation:
    severity: 1
```

---

## Pre-Submission Checklist

- [ ] Code Analyzer v5: Zero sev-1 violations with AppExchange rules
- [ ] Checkmarx: All findings resolved (3 free scans via Partner Portal)
- [ ] OWASP ZAP / Burp Suite: No high/critical DAST findings
- [ ] Qualys SSL: A grade on all external endpoints
- [ ] All classes have explicit sharing declarations
- [ ] All SOQL uses `WITH USER_MODE`
- [ ] All DML uses `as user` or `AccessLevel.USER_MODE`
- [ ] No hardcoded secrets (use Protected Custom Metadata)
- [ ] No `System.debug()` with sensitive data
- [ ] No deprecated API patterns (`WITH SECURITY_ENFORCED`, `sfdx`, etc.)
- [ ] Permission Sets grant access to all package components
- [ ] LWC uses Custom Labels for all user-facing strings
- [ ] WCAG 2.1 AA compliance verified
