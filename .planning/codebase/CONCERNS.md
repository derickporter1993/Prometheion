# Technical Debt and Concerns

## Critical Issues

### 1. Missing `with sharing` on ElaroAlertQueueable ✅ FIXED

**File**: `force-app/main/default/classes/ElaroAlertQueueable.cls:6`

**Status**: ✅ **RESOLVED** - Fixed in commit `96e461d`

**Resolution**:

```java
public with sharing class ElaroAlertQueueable implements Queueable, Database.AllowsCallouts {
```

**Commit**: `96e461d fix(security): add with sharing to ElaroAlertQueueable`

---

## Security Concerns

### 2. Hardcoded Mock IDs in Test Classes ⚠️ LOW

**Files**: Multiple test classes

**Pattern Found**:

```java
// In test classes only - ACCEPTABLE
Id mockId = '001000000000001AAA';
```

**Assessment**: These are safe - they're only in test classes using valid Salesforce ID patterns (001 = Account, 005 = User, 00D = Org).

**Risk**: None - test data only

---

### 3. TODO: Einstein Platform Integration ⚠️ MEDIUM

**File**: `force-app/main/default/classes/ElaroGraphIndexer.cls:130`

**Current**:

```java
// TODO: Implement Einstein Platform callout (see docs/GITHUB_ISSUE_TODO_EINSTEIN_PLATFORM.md)
```

**Issue**: Einstein integration stubbed but not implemented. Currently falls back to rule-based scoring.

**Impact**:

- AI risk predictions use simplified algorithms
- Less accurate than ML-based predictions

**Mitigation**: Rule-based fallback works adequately

---

## Code Quality Issues

### 4. Complex Methods Exceeding Ideal Length ✅ FIXED

**File**: `ElaroComplianceCopilot.cls`

**Status**: ✅ **RESOLVED** - Fixed in commit `fd1d3c1`

**askCopilot() Refactored**:

Broke down 80-line method into focused helpers:

```java
askCopilot()              // Main entry point (20 lines)
├── validateQuery()       // Input validation
├── checkRateLimit()      // Rate limiting
├── buildResponse()       // Response assembly
├── createErrorResponse() // Error response creation
└── handleError()         // Exception handling
```

**New Inner Classes**:

- `ValidationResult` - Encapsulates validation state
- `RateLimitResult` - Encapsulates rate limit check

**Commit**: `fd1d3c1 refactor(copilot): extract helper methods from askCopilot`

**Note**: `deepAnalysis()` still pending (lower priority)

---

### 5. Missing Class-Level Documentation ⚠️ LOW

**File**: `force-app/main/default/classes/ElaroGraphIndexer.cls`

**Issue**: No class-level JavaDoc header

**Recommendation**: Add header:

```java
/**
 * ElaroGraphIndexer - Compliance Graph Big Object Indexer
 *
 * Indexes compliance-related entity changes to Big Object storage
 * for historical tracking and audit trail purposes.
 *
 * @author Elaro Team
 * @version 1.0
 */
```

**Effort**: 10 minutes

---

## Testing Concerns

### 6. Limited HTTP Mocking for Claude API ⚠️ MEDIUM

**File**: `ElaroComplianceCopilotService.cls:249-253`

**Current**:

```java
@TestVisible
private static String callClaudeAPI(String userPrompt) {
    if (Test.isRunningTest()) {
        return ElaroTestDataFactory.createMockClaudeResponse();
    }
    // ... actual callout
}
```

**Issue**: Uses static test data method rather than proper `HttpCalloutMock`. Limits testing flexibility.

**Recommendation**: Implement proper mock:

```java
private class MockClaudeAPI implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        // Return dynamic responses based on request
    }
}
```

**Effort**: 45 minutes

---

### 7. Platform Events Excluded from Deployment ⚠️ MEDIUM

**File**: `.forceignore`

**Excluded Events**:

- `Performance_Alert__e`
- `PCI_Access_Event__e`
- `GLBA_Compliance_Event__e`
- `Elaro_Alert_Event__e`

**Issue**: Platform events excluded due to org custom object limits. This limits event-driven architecture.

**Impact**:

- Reduced real-time capabilities
- More reliance on polling/sync processing
- Workarounds needed for event-driven flows

**Mitigation**: Currently using synchronous processing and Queueable jobs

---

## Architectural Concerns

### 8. TODO in Production Code ⚠️ LOW

**File**: `ElaroGraphIndexer.cls:130`

**Pattern**: `// TODO:` comment in production code

**Assessment**: Acceptable for roadmap items, but should be tracked in issues

**Recommendation**: Create GitHub issue and reference in TODO:

```java
// TODO(#123): Implement Einstein Platform callout
```

---

### 9. Inconsistent Logging Format ⚠️ LOW

**Files**: Multiple classes

**Patterns Found**:

- `[ClassName] message`
- `ClassName: message`
- `[ClassName] Context: message`

**Recommendation**: Standardize to:

```
[ClassName] MethodName: message - CorrelationId: xxx
```

**Effort**: 30 minutes

---

### 10. Static Cache Without Thread Safety Considerations ⚠️ LOW

**File**: `ElaroComplianceScorer.cls:27-30`

**Code**:

```java
private static ScoreFactor permissionSprawlCache;
private static ScoreFactor auditTrailCache;
private static ScoreFactor configDriftCache;
```

**Issue**: Static variables used for caching without explicit thread safety considerations.

**Assessment**: In Apex, this is generally safe due to transaction isolation, but should be documented.

---

## Performance Concerns

### 11. Aggregate Queries on SetupAuditTrail ⚠️ LOW

**File**: `ElaroComplianceScorer.cls:254-259`

**Code**:

```java
Integer auditTrailCount = [
    SELECT COUNT() FROM SetupAuditTrail
    WHERE CreatedDate >= LAST_N_DAYS:30
    WITH USER_MODE
    LIMIT 10000
];
```

**Issue**: SetupAuditTrail can be large. Query has LIMIT guard but may still be slow.

**Mitigation**: LIMIT 10000 prevents worst case

**Recommendation**: Consider asynchronous processing for large orgs

---

### 12. Query in Loop (Low Risk) ⚠️ LOW

**File**: `ElaroComplianceCopilot.cls:197-205`

**Assessment**: Has LIMIT 10, which keeps it safe. However, consider bulkification for future scalability.

---

## Governor Limit Considerations

### 13. DML Operations in Integration Classes ⚠️ MEDIUM

**Pattern**: Integration classes performing DML on error logging

**Assessment**: Properly guarded with CRUD checks, but should monitor in high-volume scenarios.

**Recommendation**: Consider async error logging for high-volume integrations

---

## Documentation Debt

### 14. Missing Method-Level JavaDoc ⚠️ LOW

**File**: `ElaroGraphIndexer.cls`

**Methods Missing Documentation**:

- `indexChange()`
- `generateDeterministicHash()`
- `indexChangeBulk()`

**Recommendation**: Add JavaDoc for public methods

**Effort**: 20 minutes

---

## Dependency Concerns

### 15. External API Dependencies ⚠️ MEDIUM

**Critical External Services**:

- Claude API (Anthropic)
- Slack Webhook
- Jira API
- ServiceNow API
- PagerDuty API

**Risks**:

- Rate limiting
- API versioning changes
- Service outages
- Authentication expiration

**Mitigation**:

- Retry logic in Queueable classes
- Error logging to `Integration_Error__c`
- Graceful degradation (fallbacks)
- Named Credentials for easy auth rotation

---

## Refactoring Candidates

### High Priority

1. **Add `with sharing` to ElaroAlertQueueable** (5 min)
2. **Implement proper HTTP mocking** (45 min)
3. **Refactor askCopilot() method** (60 min)

### Medium Priority

4. **Implement Einstein Platform** (4-8 hours)
5. **Standardize logging format** (30 min)
6. **Add class documentation** (10 min)

### Low Priority

7. **Add method JavaDoc** (20 min)
8. **Resolve TODO comments** (ongoing)
9. **Optimize SetupAuditTrail queries** (when needed)

---

## Security Best Practices (Current Status)

### ✅ Implemented

- Named Credentials for all external APIs
- `with sharing` on most classes (except ElaroAlertQueueable)
- CRUD/FLS checks via SecurityUtils
- Input validation on all @AuraEnabled methods
- Correlation IDs for request tracing
- Error logging without sensitive data exposure

### ⚠️ Needs Attention

- Fix ElaroAlertQueueable sharing
- Verify all test IDs are mock-only
- Review any hardcoded values in non-test code

---

## Risk Assessment Matrix

| Issue                | Severity | Effort  | Priority       |
| -------------------- | -------- | ------- | -------------- |
| Missing with sharing | High     | 5 min   | P0             |
| Complex methods      | Medium   | 60 min  | P1             |
| HTTP mocking         | Medium   | 45 min  | P1             |
| Einstein TODO        | Medium   | 4-8 hrs | P2             |
| Logging format       | Low      | 30 min  | P3             |
| Documentation        | Low      | 30 min  | P3             |
| Platform events      | Medium   | N/A     | P2 (org limit) |

---

## Recommendations Summary

### Immediate Actions (This Week)

1. Fix `ElaroAlertQueueable` sharing keyword
2. Verify test class ID safety
3. Create GitHub issue for Einstein integration

### Short Term (Next Sprint)

1. Refactor complex methods in ElaroComplianceCopilot
2. Implement proper HTTP mocking
3. Standardize logging across classes

### Long Term (Backlog)

1. Implement Einstein Platform integration
2. Re-enable platform events (when org limits allow)
3. Add comprehensive documentation
4. Performance optimization for large orgs

---

## Monitoring Recommendations

### Metrics to Track

- Integration error rates (`Integration_Error__c` volume)
- Queueable job failures
- API rate limit usage
- Query performance (SetupAuditTrail)
- Test coverage trends

### Alerts

- Integration failure spike
- Queueable job failure rate > 5%
- API rate limit > 80%
- Test coverage < 75%

---

_Last Updated: $(date)_
_Based on codebase analysis of commit: [current commit hash]_
