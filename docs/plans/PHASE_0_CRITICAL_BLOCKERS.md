# PHASE 0: CRITICAL BLOCKERS

## Execution Plan

**Timeline:** Day 0 (First 4 Hours)
**Assignee:** Claude Code
**Priority:** CRITICAL - Must complete before any other work
**Dependencies:** None

---

## OVERVIEW

These 6 issues **prevent the codebase from compiling**. They must be resolved before any other development work can proceed.

| ID | Issue | File | Impact |
|----|-------|------|--------|
| P0.1 | Merge conflict | `ApiUsageDashboardController.cls` | Won't compile |
| P0.2 | Merge conflict | `AlertHistoryService.cls` | Won't compile |
| P0.3 | Method signature mismatch | `PerformanceAlertEventTrigger.trigger` | Won't compile |
| P0.4 | Return type mismatch | `ElaroComplianceScorer.cls` | Runtime errors in 8+ classes |
| P0.5 | Picklist case mismatch | `ComplianceTestDataFactory.cls` | DML failures |
| P0.6 | Non-deterministic hash | `ElaroGraphIndexer.cls` | Data integrity corruption |

---

## P0.1: RESOLVE MERGE CONFLICT - ApiUsageDashboardController

### Location
- **File:** `force-app/main/default/classes/ApiUsageDashboardController.cls`
- **Lines:** 36-57

### Current State (Broken)
```apex
<<<<<<< HEAD
            ORDER BY Taken_On__c DESC
=======
            WITH SECURITY_ENFORCED
            ORDER BY Taken_On__c DESC
>>>>>>> open-repo-f518a
```

### Required Fix
Keep the version with `WITH SECURITY_ENFORCED` (security best practice):
```apex
            WITH SECURITY_ENFORCED
            ORDER BY Taken_On__c DESC
```

### Implementation Steps
1. Open `ApiUsageDashboardController.cls`
2. Find lines 36-57
3. Remove all conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
4. Keep the `WITH SECURITY_ENFORCED` clause
5. Ensure query syntax is valid

### Acceptance Criteria
- [ ] No merge conflict markers in file
- [ ] `WITH SECURITY_ENFORCED` present in query
- [ ] Class compiles without errors
- [ ] `grep -r "<<<<<<" ApiUsageDashboardController.cls` returns nothing

### Estimated Time: 15 minutes

---

## P0.2: RESOLVE MERGE CONFLICT - AlertHistoryService

### Location
- **File:** `force-app/main/default/classes/AlertHistoryService.cls`
- **Lines:** 44-57

### Current State (Broken)
```apex
<<<<<<< HEAD
=======
    @AuraEnabled(cacheable = true)
    public static List<Row> recent(Integer limitSize) {
        return getRecentSnapshots(limitSize);
    }
>>>>>>> open-repo-f518a
```

### Issue Analysis
This creates a **duplicate method**. The `recent()` method likely already exists elsewhere in the file.

### Required Fix
1. Check if `recent()` method already exists in the class
2. If yes: Remove the duplicate (keep the existing one)
3. If no: Keep the new method, remove conflict markers

### Implementation Steps
1. Open `AlertHistoryService.cls`
2. Search for existing `recent` method
3. If duplicate exists, remove the entire conflicted block
4. If not duplicate, keep the method and remove markers
5. Verify no duplicate method definitions

### Acceptance Criteria
- [ ] No merge conflict markers in file
- [ ] No duplicate method definitions
- [ ] Class compiles without errors
- [ ] `recent()` method works correctly (if kept)

### Estimated Time: 20 minutes

---

## P0.3: FIX METHOD SIGNATURE - PerformanceAlertEventTrigger

### Location
- **File:** `force-app/main/default/triggers/PerformanceAlertEventTrigger.trigger`
- **Line:** 12

### Current State (Broken)
```apex
SlackNotifier.notifyPerformanceEvent(e);
```

### Issue Analysis
`SlackNotifier.notifyPerformanceEvent()` expects 4 parameters, not a single event object:
```apex
// Expected signature:
public static void notifyPerformanceAlert(String metric, Decimal value, Decimal threshold, String contextRecord)
```

### Required Fix
```apex
SlackNotifier.notifyPerformanceAlert(e.Metric__c, e.Value__c, e.Threshold__c, e.Context_Record__c);
```

### Implementation Steps
1. Open `PerformanceAlertEventTrigger.trigger`
2. Find line 12
3. Replace the method call with correct parameters
4. Verify the field names match the `Performance_Alert__e` platform event

### Verification Query
```apex
// Check Platform Event fields
Schema.DescribeSObjectResult eventDescribe = Performance_Alert__e.SObjectType.getDescribe();
for(Schema.SObjectField field : eventDescribe.fields.getMap().values()) {
    System.debug(field.getDescribe().getName());
}
```

### Acceptance Criteria
- [ ] Method call uses correct signature with 4 parameters
- [ ] Trigger compiles without errors
- [ ] Field names match Platform Event definition

### Estimated Time: 20 minutes

---

## P0.4: FIX RETURN TYPE - ElaroComplianceScorer

### Location
- **File:** `force-app/main/default/classes/ElaroComplianceScorer.cls`
- **Line:** 3

### Current State (Broken)
```apex
public static Decimal calculateReadinessScore() {
    // Returns a Decimal
    return (accessScore + configScore + automationScore + evidenceScore) / 4;
}
```

### Issue Analysis
8+ classes call this method expecting a `ScoreResult` object with:
- `overallScore` (Decimal)
- `frameworkScores` (Map<String, Decimal>)

**Affected Classes:**
1. `ElaroGDPRComplianceService.cls` (Line 30)
2. `ElaroHIPAAComplianceService.cls` (Line 40)
3. `TeamsNotifier.cls` (Line 224)
4. `ElaroChangeAdvisor.cls` (Lines 21, 34, 36, 38, 40, 43)
5. `ElaroCCPAComplianceService.cls` (Line 25)
6. `ElaroSOC2ComplianceService.cls` (Line 36)
7. `ElaroPCIDSSComplianceService.cls` (Line 30)
8. `WeeklyScorecardScheduler.cls` (Lines 133-134)

### Required Fix

#### Step 1: Add ScoreResult Inner Class
```apex
public class ScoreResult {
    @AuraEnabled public Decimal overallScore { get; set; }
    @AuraEnabled public Map<String, Decimal> frameworkScores { get; set; }
    @AuraEnabled public String status { get; set; }
    @AuraEnabled public List<String> findings { get; set; }

    public ScoreResult() {
        this.frameworkScores = new Map<String, Decimal>();
        this.findings = new List<String>();
    }
}
```

#### Step 2: Modify Method Return Type
```apex
public static ScoreResult calculateReadinessScore() {
    ScoreResult result = new ScoreResult();

    // Calculate individual scores (existing logic)
    Decimal accessScore = calculateAccessScore();
    Decimal configScore = calculateConfigScore();
    Decimal automationScore = calculateAutomationScore();
    Decimal evidenceScore = calculateEvidenceScore();

    // Set overall score
    result.overallScore = ((accessScore + configScore + automationScore + evidenceScore) / 4).setScale(2);

    // Populate framework scores
    result.frameworkScores.put('HIPAA', calculateFrameworkScore('HIPAA'));
    result.frameworkScores.put('SOC2', calculateFrameworkScore('SOC2'));
    result.frameworkScores.put('GDPR', calculateFrameworkScore('GDPR'));
    result.frameworkScores.put('PCI-DSS', calculateFrameworkScore('PCI-DSS'));
    result.frameworkScores.put('NIST', calculateFrameworkScore('NIST'));
    result.frameworkScores.put('FedRAMP', calculateFrameworkScore('FedRAMP'));
    result.frameworkScores.put('ISO27001', calculateFrameworkScore('ISO27001'));
    result.frameworkScores.put('CCPA', calculateFrameworkScore('CCPA'));
    result.frameworkScores.put('GLBA', calculateFrameworkScore('GLBA'));
    result.frameworkScores.put('SOX', calculateFrameworkScore('SOX'));

    // Determine status
    if (result.overallScore >= 90) {
        result.status = 'COMPLIANT';
    } else if (result.overallScore >= 70) {
        result.status = 'PARTIALLY_COMPLIANT';
    } else {
        result.status = 'NON_COMPLIANT';
    }

    return result;
}

// Helper method for framework-specific scores
private static Decimal calculateFrameworkScore(String framework) {
    // Implement framework-specific scoring logic
    // For now, return base score with slight variation
    Decimal baseScore = 75.0;
    // Add framework-specific adjustments here
    return baseScore.setScale(2);
}
```

### Implementation Steps
1. Read current `ElaroComplianceScorer.cls` to understand existing structure
2. Add `ScoreResult` inner class at top of class
3. Modify `calculateReadinessScore()` to return `ScoreResult`
4. Add helper method for framework scores if not exists
5. Verify all calling classes work with new return type

### Acceptance Criteria
- [ ] `ScoreResult` inner class exists with required properties
- [ ] `calculateReadinessScore()` returns `ScoreResult`
- [ ] All 8 calling classes compile without errors
- [ ] Test class passes

### Estimated Time: 1 hour

---

## P0.5: FIX PICKLIST CASE - ComplianceTestDataFactory

### Location
- **File:** `force-app/main/default/classes/ComplianceTestDataFactory.cls`
- **Line:** 105

### Current State (Broken)
```apex
Risk_Level__c = mod4 == 0 ? 'CRITICAL' : mod4 == 1 ? 'HIGH' : mod4 == 2 ? 'MEDIUM' : 'LOW'
```

### Issue Analysis
The `Access_Review__c.Risk_Level__c` picklist values are defined as:
- `Critical` (not `CRITICAL`)
- `High` (not `HIGH`)
- `Medium` (not `MEDIUM`)
- `Low` (not `LOW`)

This causes DML errors when test data is created.

### Required Fix
```apex
Risk_Level__c = mod4 == 0 ? 'Critical' : mod4 == 1 ? 'High' : mod4 == 2 ? 'Medium' : 'Low'
```

### Implementation Steps
1. Open `ComplianceTestDataFactory.cls`
2. Find line 105 (and any other Risk_Level__c assignments)
3. Change ALL CAPS values to Title Case
4. Search entire file for other picklist assignments that might have same issue

### Search for Similar Issues
```bash
grep -n "Risk_Level__c" force-app/main/default/classes/*.cls
grep -n "CRITICAL\|HIGH\|MEDIUM\|LOW" force-app/main/default/classes/*.cls
```

### Acceptance Criteria
- [ ] All `Risk_Level__c` assignments use Title Case
- [ ] No ALL CAPS picklist values in test factories
- [ ] Test classes run without DML errors
- [ ] `System.runAs()` tests pass

### Estimated Time: 30 minutes

---

## P0.6: FIX NON-DETERMINISTIC HASH - ElaroGraphIndexer

### Location
- **File:** `force-app/main/default/classes/ElaroGraphIndexer.cls`
- **Line:** 51

### Current State (Broken)
```apex
private static String generateDeterministicHash(String entityType, Id entityId, String framework) {
    String input = entityType + '|' + entityId + '|' + framework + '|' + System.now().getTime();
    Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(input));
    return EncodingUtil.convertToHex(hash);
}
```

### Issue Analysis
Including `System.now().getTime()` makes the hash **non-deterministic**:
- Same entity generates different hash each time
- Defeats purpose of deterministic indexing
- Creates duplicate graph nodes
- Corrupts data integrity

### Required Fix
Remove the timestamp:
```apex
private static String generateDeterministicHash(String entityType, Id entityId, String framework) {
    String input = entityType + '|' + entityId + '|' + framework;
    Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(input));
    return EncodingUtil.convertToHex(hash);
}
```

### Implementation Steps
1. Open `ElaroGraphIndexer.cls`
2. Find line 51 (the `generateDeterministicHash` method)
3. Remove `+ '|' + System.now().getTime()` from input string
4. Verify method still produces consistent output

### Verification Test
```apex
// Should return same hash for same inputs
String hash1 = ElaroGraphIndexer.generateDeterministicHash('PERMISSION_SET', '0PS000000000001', 'SOC2');
String hash2 = ElaroGraphIndexer.generateDeterministicHash('PERMISSION_SET', '0PS000000000001', 'SOC2');
System.assertEquals(hash1, hash2, 'Hash should be deterministic');
```

### Acceptance Criteria
- [ ] `System.now().getTime()` removed from hash input
- [ ] Same inputs produce same hash
- [ ] Graph indexer test passes
- [ ] No duplicate nodes created on re-index

### Estimated Time: 20 minutes

---

## EXECUTION ORDER

```
P0.1 (15 min) ─┬─► P0.3 (20 min) ─► P0.4 (60 min)
               │
P0.2 (20 min) ─┘

P0.5 (30 min) ─► Independent

P0.6 (20 min) ─► Independent
```

**Recommended Order:**
1. P0.1 + P0.2 (merge conflicts) - Unblocks everything
2. P0.3 (trigger fix) - Quick win
3. P0.5 (picklist fix) - Quick win
4. P0.6 (hash fix) - Quick win
5. P0.4 (return type) - Most complex, do last

---

## VALIDATION CHECKLIST

After completing all Phase 0 tasks:

```bash
# 1. Check for remaining merge conflicts
grep -r "<<<<<<" force-app/main/default/classes/
grep -r "<<<<<<" force-app/main/default/triggers/

# 2. Verify Apex compilation
sfdx force:apex:compile --targetusername <org>

# 3. Run affected test classes
sfdx force:apex:test:run --tests ApiUsageDashboardControllerTest,AlertHistoryServiceTest,PerformanceAlertEventTriggerTest,ElaroComplianceScorerTest,ComplianceTestDataFactoryTest,ElaroGraphIndexerTest --resultformat human

# 4. Check for runtime errors
sfdx force:apex:execute -f scripts/apex/verify-phase0.apex
```

### verify-phase0.apex
```apex
// Test P0.4 - ScoreResult
ElaroComplianceScorer.ScoreResult result = ElaroComplianceScorer.calculateReadinessScore();
System.assertNotEquals(null, result, 'ScoreResult should not be null');
System.assertNotEquals(null, result.frameworkScores, 'frameworkScores should not be null');
System.assertNotEquals(null, result.overallScore, 'overallScore should not be null');

// Test P0.6 - Deterministic hash
String hash1 = ElaroGraphIndexer.generateDeterministicHash('TEST', '001000000000001', 'SOC2');
String hash2 = ElaroGraphIndexer.generateDeterministicHash('TEST', '001000000000001', 'SOC2');
System.assertEquals(hash1, hash2, 'Hash must be deterministic');

System.debug('Phase 0 verification PASSED');
```

---

## ROLLBACK PLAN

If any fix causes issues:

1. **Git revert:** `git revert HEAD~1`
2. **Restore from backup:** Each file should be backed up before modification
3. **Contact:** Escalate to human reviewer immediately

---

## SIGN-OFF

| Task | Completed | Verified | Notes |
|------|-----------|----------|-------|
| P0.1 | ☐ | ☐ | |
| P0.2 | ☐ | ☐ | |
| P0.3 | ☐ | ☐ | |
| P0.4 | ☐ | ☐ | |
| P0.5 | ☐ | ☐ | |
| P0.6 | ☐ | ☐ | |
| Full compilation | ☐ | ☐ | |
| Test run | ☐ | ☐ | |

**Phase 0 Complete:** ☐
**Ready for Phase 1:** ☐
