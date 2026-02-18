# Salesforce API Version Breaking Changes

**Scope:** v58.0 (Summer '23) through v66.0 (Spring '26)
**Purpose:** Code review reference for identifying version-dependent issues

---

## Critical Breaking Changes

### v61.0 — Summer '24: Set Mutation During Iteration

**Impact:** `System.FinalException` thrown at runtime

```apex
// BREAKS in v61.0+
Set<String> items = new Set<String>{ 'a', 'b', 'c' };
for (String item : items) {
    if (item == 'b') {
        items.remove(item); // System.FinalException
    }
}

// FIX: Collect items to remove, then modify after iteration
Set<String> items = new Set<String>{ 'a', 'b', 'c' };
Set<String> toRemove = new Set<String>();
for (String item : items) {
    if (item == 'b') {
        toRemove.add(item);
    }
}
items.removeAll(toRemove);
```

**Review check:** Search for `.remove(` or `.add(` inside `for` loops iterating over Sets.

---

### v63.0 — Spring '25: JSON Serialization of Exceptions

**Impact:** `System.JSONException` thrown when serializing exception objects

```apex
// BREAKS in v63.0+
try {
    // some operation
} catch (Exception e) {
    String json = JSON.serialize(e); // System.JSONException
}

// FIX: Extract exception data into a wrapper DTO
public class ExceptionInfo {
    public String message;
    public String typeName;
    public String stackTrace;

    public ExceptionInfo(Exception e) {
        this.message = e.getMessage();
        this.typeName = e.getTypeName();
        this.stackTrace = e.getStackTraceString();
    }
}

try {
    // some operation
} catch (Exception e) {
    String json = JSON.serialize(new ExceptionInfo(e)); // Works
}
```

**Review check:** Search for `JSON.serialize` where the argument could be an Exception.

---

### v63.0 — Spring '25: Default Accept Header for Callouts

**Impact:** Default Accept header changed to `*/*` for HTTP callouts

```apex
// In v63.0+, if you don't set Accept header, it defaults to */*
// Previously it was application/xml or varied by context

// FIX: Always set Accept header explicitly
HttpRequest req = new HttpRequest();
req.setHeader('Accept', 'application/json');
req.setHeader('Content-Type', 'application/json');
```

**Review check:** Verify all HttpRequest objects set the Accept header explicitly.

---

### v65.0 — Winter '26: Abstract/Override Access Modifiers Required

**Impact:** Compilation failure if access modifiers are omitted

```apex
// BREAKS in v65.0+ — missing access modifier
public abstract class BaseProcessor {
    abstract void process(List<SObject> records);       // COMPILE ERROR
    virtual void validate(SObject record) { }           // COMPILE ERROR
}

public class ConcreteProcessor extends BaseProcessor {
    override void process(List<SObject> records) { }    // COMPILE ERROR
    override void validate(SObject record) { }          // COMPILE ERROR
}

// FIX: Add explicit access modifiers
public abstract class BaseProcessor {
    public abstract void process(List<SObject> records);
    protected virtual void validate(SObject record) { }
}

public class ConcreteProcessor extends BaseProcessor {
    public override void process(List<SObject> records) { }
    protected override void validate(SObject record) { }
}
```

**Review check:** Search for `abstract` and `override` keywords. Verify each has
`public`, `protected`, or `global` preceding it.

---

## Spring '26 (v66.0) Security Breaking Changes

### Session IDs Removed from Outbound Messages (Feb 16, 2026)

**Impact:** "Send Session ID" checkbox no longer functions in Outbound Messages.
`UserInfo.getSessionId()` already returns null in Lightning context.

**Migration:**
- Use OAuth 2.0 for authenticated callouts
- Use Named Credentials for endpoint authentication
- Use Auth Providers for third-party integration

**Review check:** Search for `UserInfo.getSessionId()` and outbound message
configurations with session ID enabled.

---

### My Domain URL Enforcement in Production

**Impact:** All API traffic must use My Domain URLs. Hardcoded instance URLs
(e.g., `na1.salesforce.com`) will fail.

**Review check:** Search for hardcoded Salesforce instance URLs. Verify all
endpoints use `URL.getOrgDomainUrl().toExternalForm()` or Named Credentials.

---

### Connected App Creation Disabled by Default

**Impact:** New Connected App creation disabled across all orgs. External Client
Apps (ECAs) are the official replacement.

**Migration:**
- App Manager > Select Connected App > "Migrate to External Client App"
- ECAs support only secure OAuth 2.0 flows
- Username-password flow not available in ECAs
- Consumer secrets excluded from packaged components

**Review check:** Identify any code creating Connected Apps programmatically.
Verify OAuth patterns use secure flows.

---

### Encryption Algorithm Deprecation

**Impact:** Must use AES-128 or AES-256 before Summer '26 enforcement.

```apex
// BAD — MD5 is weak
Blob hash = Crypto.generateDigest('MD5', data);

// GOOD — Use SHA-256
Blob hash = Crypto.generateDigest('SHA-256', data);

// GOOD — Use AES-256 for encryption
Blob key = Crypto.generateAesKey(256);
Blob encrypted = Crypto.encryptWithManagedIV('AES256', key, data);
```

**Review check:** Search for `'MD5'`, `'DES'`, `'DESede'` in Crypto class calls.

---

### Blob.toPdf() Rendering Upgrade

**Impact:** PDF rendering engine upgraded in Spring '26, enforced Summer '26.
HTML/CSS rendering may produce different visual output.

**Review check:** If using `Blob.toPdf()`, verify output visually after upgrade.

---

## Version Compatibility Matrix

| Feature / Pattern                  | Minimum API | Recommended API |
|------------------------------------|-------------|-----------------|
| `WITH USER_MODE`                   | v56.0       | v66.0           |
| `Database.queryWithBinds()`        | v57.0       | v66.0           |
| Safe navigation (`?.`)             | v50.0       | v66.0           |
| Null coalescing (`??`)             | v60.0       | v66.0           |
| Assert class                       | v56.0       | v66.0           |
| Transaction Finalizers             | v52.0       | v66.0           |
| AsyncOptions                       | v59.0       | v66.0           |
| Apex Cursors                       | v61.0 Beta  | v66.0 Beta      |
| Explicit abstract/override modifiers | Required v65.0+ | v66.0       |

---

## Code Review Search Patterns

Use these grep patterns to find potential breaking change violations:

```bash
# v61.0: Set mutation during iteration (requires manual inspection)
grep -rn '\.remove\|\.add' force-app/main/default/classes/ | grep -i 'for\|while'

# v63.0: Exception serialization
grep -rn 'JSON.serialize.*catch\|JSON.serialize.*Exception' force-app/main/default/classes/

# v65.0: Missing access modifiers on abstract/override
grep -rn 'abstract void\|abstract String\|abstract Boolean\|abstract Integer\|abstract List' force-app/main/default/classes/
grep -rn 'override void\|override String\|override Boolean\|override Integer\|override List' force-app/main/default/classes/

# Spring '26: Session ID usage
grep -rn 'getSessionId\|SessionId' force-app/main/default/classes/

# Outdated patterns
grep -rn 'WITH SECURITY_ENFORCED' force-app/main/default/classes/
grep -rn 'System\.assertEquals\|System\.assertNotEquals\|System\.assert(' force-app/main/default/classes/
grep -rn '@future' force-app/main/default/classes/
```
