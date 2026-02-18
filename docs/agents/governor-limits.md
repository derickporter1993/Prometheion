# Salesforce Governor Limits Reference

**Updated for:** Spring '26 (API v66.0)
**Purpose:** Quick reference for code review and development

---

## Synchronous Apex Limits (Per Transaction)

| Resource                           | Limit         | Notes                                          |
|------------------------------------|---------------|-------------------------------------------------|
| Total SOQL queries                 | 100           | Each cursor `fetch()` counts as one             |
| Total SOQL query rows              | 50,000        | Fetched cursor rows count against this          |
| Total SOSL searches                | 20            |                                                 |
| Total DML statements               | 150           |                                                 |
| Total DML rows                     | 10,000        |                                                 |
| Total callouts (HTTP + web svc)    | 100           |                                                 |
| Total callout timeout              | 120 seconds   | Individual callout max: 120s                    |
| Maximum CPU time                   | 10,000 ms     |                                                 |
| Maximum heap size                  | 6 MB          |                                                 |
| Maximum stack depth                | 16            |                                                 |
| Maximum SOQL query length          | 100,000 chars |                                                 |

## Asynchronous Apex Limits (Per Transaction)

| Resource                           | Limit         | Notes                                          |
|------------------------------------|---------------|-------------------------------------------------|
| Total SOQL queries                 | 200           |                                                 |
| Total SOQL query rows              | 50,000        |                                                 |
| Maximum CPU time                   | 60,000 ms     |                                                 |
| Maximum heap size                  | 12 MB         |                                                 |
| Total callouts                     | 100           |                                                 |

## Batch Apex Limits

| Resource                           | Limit         | Notes                                          |
|------------------------------------|---------------|-------------------------------------------------|
| Concurrent batch jobs              | 5             | Queued jobs wait for slot                       |
| Query locator rows                 | 50,000,000    |                                                 |
| Batch size (default)               | 200           | Configurable 1-2000                             |
| execute() invocations              | 250,000/day   |                                                 |
| Maximum batch chain depth          | 5             | start() can only enqueue 1 more batch           |

## Queueable Limits

| Resource                           | Limit         | Notes                                          |
|------------------------------------|---------------|-------------------------------------------------|
| Queueable jobs per transaction     | 1 (sync), 1 (async) | Can override with AsyncOptions          |
| Default chain depth                | 5             | Override with `setMaximumQueueableStackDepth()` |
| Maximum chain depth (Developer)    | 5             |                                                 |
| Maximum chain depth (Enterprise)   | Unlimited     | With AsyncOptions                               |

## Apex Cursor Limits (Beta)

| Resource                           | Limit         | Notes                                          |
|------------------------------------|---------------|-------------------------------------------------|
| Maximum rows per cursor            | 50,000,000    |                                                 |
| Maximum fetch() calls per txn      | 10            | Each counts against SOQL query limit            |
| Maximum cursor instances per day   | 10,000        |                                                 |
| Maximum aggregate rows per day     | 100,000,000   |                                                 |
| Cursor expiration                  | 48 hours      |                                                 |
| Big Object support                 | No            |                                                 |

## Platform Event Limits

| Resource                           | Limit         | Notes                                          |
|------------------------------------|---------------|-------------------------------------------------|
| Events published per hour          | Varies by ed. | Enterprise: 250K, Unlimited: 25M               |
| Maximum event payload              | 1 MB          |                                                 |
| Event retention                    | 72 hours      | With replay capability                          |
| CometD subscribers per org         | 2,000         |                                                 |

## Platform Cache Limits (ISV Partition)

| Resource                           | Limit         | Notes                                          |
|------------------------------------|---------------|-------------------------------------------------|
| Org Cache (ISV)                    | 3 MB          | Shared across all users                         |
| Session Cache (ISV)                | 1 MB          | Per user session                                |
| Maximum single value size          | 100 KB        |                                                 |
| Default TTL                        | 8 hours       | Configurable per put()                          |
| Maximum TTL                        | 48 hours      |                                                 |

## Concurrent Request Limits

| Resource                           | Limit         | Notes                                          |
|------------------------------------|---------------|-------------------------------------------------|
| Long-running Apex (> 5s)          | Dynamically adjusted, up to 50 | Spring '25 change    |
| Concurrent API requests            | Varies by ed. | Based on license count                          |

---

## Common Anti-Patterns (Auto-Fail in Review)

### 1. SOQL in Loop
```apex
// BAD — Auto-fail
for (Contact c : contacts) {
    Account a = [SELECT Name FROM Account WHERE Id = :c.AccountId WITH USER_MODE];
}

// GOOD — Query once, use Map
Map<Id, Account> accountMap = new Map<Id, Account>(
    [SELECT Id, Name FROM Account WHERE Id IN :accountIds WITH USER_MODE]
);
for (Contact c : contacts) {
    Account a = accountMap.get(c.AccountId);
}
```

### 2. DML in Loop
```apex
// BAD — Auto-fail
for (Account a : accounts) {
    a.Status__c = 'Active';
    update as user a;
}

// GOOD — Collect and bulkify
for (Account a : accounts) {
    a.Status__c = 'Active';
}
update as user accounts;
```

### 3. Nested Loops for Lookups
```apex
// BAD — O(n*m) complexity
for (Contact c : contacts) {
    for (Account a : accounts) {
        if (c.AccountId == a.Id) { /* ... */ }
    }
}

// GOOD — O(n+m) with Map
Map<Id, Account> accountMap = new Map<Id, Account>(accounts);
for (Contact c : contacts) {
    Account a = accountMap.get(c.AccountId);
}
```

### 4. Unbounded Queries
```apex
// BAD — Could return 50K+ rows, hit limit
List<Account> all = [SELECT Id FROM Account WITH USER_MODE];

// GOOD — Use WHERE filters, LIMIT, or Cursors for large datasets
List<Account> filtered = [SELECT Id FROM Account
    WHERE CreatedDate = LAST_N_DAYS:30 WITH USER_MODE LIMIT 200];
```

---

## Limits Monitoring in Code

```apex
// Use Limits class for defensive programming (not flow control)
System.debug('SOQL queries used: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
System.debug('DML statements used: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements());
System.debug('CPU time used: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());
System.debug('Heap size used: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());
```

**Note:** Use `Limits` class for logging/monitoring only. Do not design business logic
that branches based on remaining limits — this indicates a design problem.
