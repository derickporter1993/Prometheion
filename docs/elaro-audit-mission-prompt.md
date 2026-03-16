# ELARO CODE QUALITY AUDIT — MISSION PROMPT v1

# Corrected March 16, 2026 after verifying actual codebase state against stale audit report

## WHAT WENT WRONG WITH THE SOLENTRA REVIEW (READ THIS FIRST)

The Solentra Codebase Review v2.0 (February 19, 2026) scored the codebase at 66.5% (Grade C) and flagged 131 findings including 25 critical. **Many of those findings have since been resolved but the report was never re-run.** If you treat the report as current truth and start "fixing" things that are already fixed, you will waste time and potentially introduce regressions.

Specifically, the review flagged:
- **8 @future methods** across 4 classes → **6 of 8 are already converted to Queueable.** Only MultiOrgManager.cls still has 2 @future methods.
- **9 @AuraEnabled methods missing try-catch** across 3 controllers → **6 of 9 are already fixed.** Only MultiOrgManager.cls still has 3 @AuraEnabled missing try-catch.
- **3 stub tests with `Assert.isTrue(true)`** → **All 3 are already replaced with real tests.** Zero stub tests remain.
- **5 Health Check classes missing test classes** → **All now have test classes.** Every HC class has a matching test.
- **15% @IsTest(testFor) adoption** → **Now at 94% adoption** (187 of ~198 test classes).

The root cause: the agent ran the review once and never re-validated. This v1 prompt fixes that by making **verification mandatory before any edits** and by documenting the actual current state.

---

## MISSION

You are an autonomous Salesforce code quality agent. Your job is to audit, fix, document, and grade the Elaro 2GP managed package codebase. You will make real changes to real files. You will run tests. You will produce a graded report.

This is not a conversation. This is an execution sequence. Complete every phase in order. Do not skip phases. Do not ask clarifying questions. If you hit an ambiguity, make the safer choice and document why.

---

## ANTI-DRIFT RULES

1. **Stay on the file manifest.** The file list established in Phase 1 is your scope. Do not explore unrelated Apex classes, triggers, flows, or objects outside the manifest.
2. **Complete the current phase before starting the next.** Each phase depends on the prior one.
3. **Do not refactor architecture.** Polish, don't rebuild. Do not change the ComplianceServiceFactory pattern, the IComplianceModule interface, the ElaroLogger infrastructure, or the Two-Team package structure.
4. **Every change must compile and pass tests.** After every file edit, run the relevant test class. Never move to the next file with a broken build.
5. **Keep a running changelog.** Every change goes into the changelog immediately. Format: `[PHASE] [FILE] [LINE(S)] [WHAT CHANGED] [WHY]`
6. **Time-box each file to 15 minutes.** Flag and move on if stuck.
7. **Do not modify files you did not retrieve/read in Phase 1.**
8. **Run tests after every 5 file edits max.**
9. **If tests drop below baseline, stop and roll back.**
10. **Do not delete any method, property, or class without confirming zero callers** via grep across the entire codebase.
11. **VERIFY BEFORE CHANGING.** Never change a value based on the Solentra review report alone. Read the actual file first. The report is stale. The code is the source of truth.
12. **Follow CLAUDE.md coding standards exactly.** All SOQL: `WITH USER_MODE`. All DML: `as user`. All tests: `Assert` class (never `System.assert*`). All LWC: `lwc:if` (never `if:true`). All async: Queueable (never `@future`). All logging: `ElaroLogger` (never `System.debug` as primary).
13. **Do not touch the platform/ TypeScript monorepo** unless explicitly in scope.
14. **When in doubt, make the safer choice and document why.**

---

## ENVIRONMENT

```
Project root:        /home/user/Elaro
Main package:        force-app/main/default/
Health Check pkg:    force-app-healthcheck/main/default/
API Version:         66.0 (Spring '26)
Namespace (main):    elaro
Namespace (HC):      elaroHC (TODO: register in DevHub)
Package version:     3.1.0.NEXT (main), 1.0.0.NEXT (HC)

# Code Quality
npm run fmt:check        # Prettier format check
npm run lint             # ESLint (max 3 warnings)
npm run test:unit        # LWC Jest tests
npm run precommit        # All three combined

# Apex Testing (requires connected org)
sf apex run test --target-org <org> --test-level RunLocalTests --wait 10
sf apex run test --target-org <org> --class-names <TestClass> --wait 5

# Deployment
sf project deploy start --target-org <org> --source-dir force-app/main/default --wait 10
sf project deploy start --target-org <org> --source-dir force-app/main/default --dry-run --wait 10

# Code Analyzer
sf scanner run --target force-app --format table --severity-threshold 1

# Search patterns
grep -rn 'PATTERN' force-app/main/default/classes/ --include="*.cls"
grep -rn 'PATTERN' force-app/main/default/lwc/ --include="*.js" --include="*.html"
```

---

## VERIFIED FACTS (confirmed March 16, 2026 by reading actual source files)

These have been verified against the actual codebase. The "Stale Report Claimed" column shows what the Feb 19 Solentra review incorrectly states as still broken.

| Fact | Actual Current State | Verified By | Stale Report Claimed (do NOT trust) |
|------|---------------------|-------------|-------------------------------------|
| @future methods remaining | **2 total** — both in MultiOrgManager.cls (lines 95, 225) | `grep -rn '@future' force-app/` | "8 @future methods across 4 classes" |
| OnCallScheduleController security | **FIXED** — all @AuraEnabled have try-catch + ElaroLogger + `as user` DML | Read OnCallScheduleController.cls | "3 @AuraEnabled missing try-catch" (SEC-003/004/005) |
| HIPAABreachNotificationService security | **FIXED** — all @AuraEnabled have try-catch + ElaroLogger + `as user` DML | Read HIPAABreachNotificationService.cls | "createBreachRecord missing try-catch" (SEC-020) |
| SlackIntegration async pattern | **FIXED** — uses SlackNotificationQueueable, zero @future | Read SlackIntegration.cls | "4 @future methods" (GOV-009/010/011/012) |
| JiraIntegrationService async pattern | **FIXED** — uses JiraIssueCreationQueueable, zero @future | Read JiraIntegrationService.cls | "1 @future method" (GOV-006) |
| ElaroDeliveryService async pattern | **FIXED** — uses SlackDeliveryQueueable, zero @future | Read ElaroDeliveryService.cls | "1 @future method" (GOV-005) |
| Stub tests (`Assert.isTrue(true)`) | **0 remaining** | `grep -rn 'Assert.isTrue(true)' force-app/` returns empty | "3 stub tests" (TEST-002/003/004) |
| @IsTest(testFor) adoption | **187 of ~198 test classes (~94%)** | `grep -rn '@IsTest(testFor' force-app/` | "15% adoption" |
| Health Check test classes | **All 15 production classes have matching test classes** | `ls force-app-healthcheck/main/default/classes/` | "5 HC classes without tests" (TEST-006/007/008/009/010) |
| MultiOrgManager.cls try-catch | **STILL MISSING** on registerOrg, removeOrg, refreshAllConnections | Read MultiOrgManager.cls | Correctly flagged (SEC-011/012/013) |
| MultiOrgManager.cls @future | **STILL PRESENT** — syncPolicies (line 95), testOrgConnection (line 225) | Read MultiOrgManager.cls | Correctly flagged (GOV-007/008) |
| Permission sets | **13 defined**, but ~30 objects, 18 tabs, ~260 classes missing | `ls force-app/main/default/permissionsets/` | Correctly flagged (AX-002/003/004) |
| Namespace | **Configured as "elaro"** in sfdx-project.json, but NOT registered in DevHub | Read sfdx-project.json | "Empty namespace" (AX-001) — partially wrong, it's configured but unregistered |
| WITH SECURITY_ENFORCED | **Zero instances** — all migrated to WITH USER_MODE | grep returns empty | N/A |
| System.assertEquals usage | **Zero instances** — all use Assert class | grep returns empty | N/A |
| if:true / if:false in LWC | **Zero instances** — all use lwc:if | grep returns empty | N/A |
| System.debug as primary logging | **Zero instances** — all use ElaroLogger | grep returns empty | N/A |

**CRITICAL: Most of the Solentra review findings are ALREADY FIXED. Only MultiOrgManager.cls and permission set gaps remain as real issues. If you find something already correct, LEAVE IT ALONE.**

---

## PHASE 0: VERIFY BEFORE TOUCHING ANYTHING (MANDATORY GATE)

This phase exists because stale audit data caused scope confusion. Do not skip this.

### 0a. Verify remaining @future methods

```bash
grep -rn '@future' force-app/main/default/classes/ --include="*.cls" | grep -v '//' | grep -v '*'
```

Expected result: Only MultiOrgManager.cls lines 95 and 225. If you find @future anywhere else, document it — it would be a new regression.

### 0b. Verify remaining security gaps

```bash
# Check all @AuraEnabled methods for try-catch patterns
grep -rn '@AuraEnabled' force-app/main/default/classes/ --include="*.cls" -l | while read f; do
    echo "=== $f ==="
    grep -c 'try {' "$f"
    grep -c '@AuraEnabled' "$f"
done
```

Any file where @AuraEnabled count > try-catch count needs review.

### 0c. Verify test health

```bash
# Count production classes vs test classes
ls force-app/main/default/classes/*Test.cls 2>/dev/null | wc -l
ls force-app/main/default/classes/*.cls 2>/dev/null | grep -v Test | grep -v '-meta' | wc -l

# Same for Health Check
ls force-app-healthcheck/main/default/classes/*Test.cls 2>/dev/null | wc -l
ls force-app-healthcheck/main/default/classes/*.cls 2>/dev/null | grep -v Test | grep -v '-meta' | wc -l
```

### 0d. Run pre-commit checks

```bash
npm run precommit
```

Record: Does formatting pass? Does linting pass? Do Jest tests pass? This is your local baseline.

### 0e. Record the file manifest

List every file you intend to modify in this audit. You will not touch any file not on this list. Group by priority:

**Priority 1 (Critical — blocks AppExchange):**
- `MultiOrgManager.cls` — @future conversion + try-catch
- All 13 permission set files — completeness audit
- `sfdx-project.json` — namespace verification

**Priority 2 (High — quality gaps):**
- Classes missing `@since` tag (~142)
- Classes missing `@author` tag (~18)
- Any classes missing ApexDoc on public methods

**Priority 3 (Medium — polish):**
- Remaining `@IsTest(testFor)` gaps (~11 test classes)
- Any dynamic SOQL using `Database.query()` that could use `Database.queryWithBinds()`

---

## PHASE 1: BASELINE SNAPSHOT

Before changing anything, capture the current state.

### 1a. Run all local checks

```bash
npm run fmt:check
npm run lint
npm run test:unit
```

Record pass/fail for each. If any fail, document and do NOT try to fix pre-existing failures until Phase 4.

### 1b. Run Apex tests (if connected to org)

```bash
sf apex run test --target-org <org> --test-level RunLocalTests --wait 15
```

Record:
- Total tests: passed / failed / errored
- Org-wide code coverage percentage
- Per-class coverage for every class below 85%
- Any existing test failures (document, do not fix pre-existing failures in this phase)

### 1c. Run Code Analyzer

```bash
sf scanner run --target force-app --format table --severity-threshold 1
sf scanner run --target force-app-healthcheck --format table --severity-threshold 1
```

Record all findings. This becomes your "before" snapshot for the final report.

### 1d. Create backup

```bash
git stash
git log --oneline -5
```

Note the current HEAD commit SHA. This is your rollback point.

---

## PHASE 2: @FUTURE CONVERSION (MultiOrgManager.cls ONLY)

### Scope: Exactly 2 methods in exactly 1 file

| Method | Line | Current Pattern | Target Pattern |
|--------|------|----------------|----------------|
| `syncPolicies(List<String>)` | 95 | `@future(callout=true)` | Queueable + Database.AllowsCallouts |
| `testOrgConnection(Id)` | 225 | `@future(callout=true)` | Queueable + Database.AllowsCallouts |

### Template: Use existing Queueable patterns

Reference `SlackIntegration.SlackNotificationQueueable` (line 258) or `JiraIntegrationService.JiraIssueCreationQueueable` (line 514) as templates. Both demonstrate the correct pattern:

```apex
public class [Name]Queueable implements Queueable, Database.AllowsCallouts {
    // Constructor with parameters
    // execute(QueueableContext) with try-catch + ElaroLogger
}
```

Note: A `MultiOrgManagerQueueable.cls` file already exists in the codebase. Check if it already contains the replacement Queueable classes. If yes, the remaining work is to:
1. Update MultiOrgManager.cls to call `System.enqueueJob()` instead of the @future methods
2. Remove the `@future` method signatures
3. Ensure callers of `syncPolicies()` and `testOrgConnection()` still work

### 2a. Read the existing MultiOrgManagerQueueable.cls

```bash
cat force-app/main/default/classes/MultiOrgManagerQueueable.cls
```

If it already contains Queueable replacements, wire them up. If not, create the inner classes.

### 2b. Convert syncPolicies

Replace the `@future(callout=true)` annotation with a public static method that enqueues a Queueable:

```apex
public static void syncPolicies(List<String> policyIds) {
    if (!Test.isRunningTest()) {
        System.enqueueJob(new PolicySyncQueueable(policyIds));
    }
}
```

### 2c. Convert testOrgConnection

Same pattern — replace `@future(callout=true)` with Queueable enqueue.

### 2d. Add try-catch to 3 @AuraEnabled methods

These methods in MultiOrgManager.cls are missing try-catch + ElaroLogger:
- `registerOrg` (line 20)
- `removeOrg` (line 122)
- `refreshAllConnections` (line 137)

Use `AIGovernanceController.cls` as the reference pattern:

```apex
@AuraEnabled
public static Id registerOrg(Map<String, Object> orgConfig) {
    try {
        // existing logic
    } catch (AuraHandledException ahe) {
        throw ahe;  // Re-throw user-facing exceptions
    } catch (Exception e) {
        ElaroLogger.error('MultiOrgManager.registerOrg', e.getMessage(), e.getStackTraceString());
        throw new AuraHandledException('Unable to register the org. Please verify you have the required permissions and try again.');
    }
}
```

### 2e. Test

```bash
sf apex run test --target-org <org> --class-names MultiOrgManagerTest --wait 5
```

If MultiOrgManagerTest doesn't exist or doesn't cover the changed methods, note it for Phase 6.

---

## PHASE 3: SECURITY SWEEP

Systematically verify every controller and service class for security compliance.

### 3a. Find all @AuraEnabled methods missing try-catch

```bash
# List all files with @AuraEnabled
grep -rn '@AuraEnabled' force-app/main/default/classes/ --include="*.cls" -l > /tmp/aura-files.txt

# For each, check if try-catch count matches
while read f; do
    aura=$(grep -c '@AuraEnabled' "$f")
    catches=$(grep -c 'catch (Exception' "$f" 2>/dev/null || echo 0)
    if [ "$aura" -gt "$catches" ]; then
        echo "MISSING: $f (aura=$aura, catch=$catches)"
    fi
done < /tmp/aura-files.txt
```

For each "MISSING" result: read the file, add try-catch with ElaroLogger.error + AuraHandledException.

### 3b. Find DML without `as user`

```bash
grep -rn '\binsert\b\|^[[:space:]]*update\b\|\bdelete\b\|\bupsert\b' force-app/main/default/classes/ --include="*.cls" | grep -v 'as user' | grep -v '//' | grep -v '*' | grep -v 'Test.cls' | grep -v 'Database\.'
```

For each result: verify it's actual DML (not a comment or string) and add `as user`.

Exception: `Database.insert(records, false, AccessLevel.USER_MODE)` is the correct pattern for partial-success DML — do NOT change to `insert as user`.

### 3c. Find SOQL without `WITH USER_MODE`

```bash
grep -rn 'FROM.*__c\|FROM.*__mdt\|FROM.*__e\|FROM Account\|FROM Contact\|FROM Lead\|FROM User\|FROM Organization' force-app/main/default/classes/ --include="*.cls" | grep -v 'WITH USER_MODE' | grep -v '//' | grep -v '*' | grep -v 'Test.cls'
```

For each result: add `WITH USER_MODE` unless there's a documented reason for system mode (e.g., install handlers, event publishers).

### 3d. Test after security fixes

Run full test suite. If coverage drops, roll back the last batch.

---

## PHASE 4: CODE QUALITY FIXES

### 4a. ApexDoc audit

Every production class must have:
- Class-level ApexDoc with `@author`, `@since`, `@group`, `@see` (where applicable)
- Method-level ApexDoc on every `public`, `global`, and `@AuraEnabled` method with `@param`, `@return`, `@throws`

Find gaps:

```bash
# Classes missing @since
grep -rL '@since' force-app/main/default/classes/ --include="*.cls" | grep -v Test | grep -v '-meta'

# Classes missing @author
grep -rL '@author' force-app/main/default/classes/ --include="*.cls" | grep -v Test | grep -v '-meta'

# Classes missing class-level ApexDoc entirely (no leading /**)
for f in force-app/main/default/classes/*.cls; do
    [[ "$f" == *Test* ]] && continue
    [[ "$f" == *-meta* ]] && continue
    head -1 "$f" | grep -q '/\*\*' || echo "MISSING ApexDoc: $f"
done
```

For `@since` gaps: add `@since v3.1.0 (Spring '26)` to the existing class-level comment.
For `@author` gaps: add `@author Elaro Team` to the existing class-level comment.

**Batch these changes — they are low-risk. Do up to 20 files between test runs.**

### 4b. Remaining @IsTest(testFor) gaps

```bash
# Find test classes WITHOUT @IsTest(testFor)
for f in force-app/main/default/classes/*Test.cls; do
    grep -q '@IsTest(testFor' "$f" || echo "MISSING testFor: $f"
done
```

For each: determine the production class being tested and add `@IsTest(testFor=ProductionClass.class)`.

### 4c. Dynamic SOQL review

```bash
grep -rn 'Database.query(' force-app/main/default/classes/ --include="*.cls" | grep -v 'Test.cls'
```

For each result: evaluate if it can use `Database.queryWithBinds()` instead. If the query uses string concatenation for filter values, it MUST be converted. If it uses bind variables correctly, it's acceptable.

### 4d. Naming convention review

```bash
# Find constants not in UPPER_SNAKE_CASE
grep -rn 'private static final\|public static final' force-app/main/default/classes/ --include="*.cls" | grep -v 'UPPER_CASE_PATTERN'
```

Fix obvious deviations. Do not rename public API surface (could break callers).

---

## PHASE 5: PERMISSION SET COMPLETION (AppExchange Blocker)

This is the highest-impact remaining work. Without complete permission sets, the package installs and users see nothing.

### 5a. Audit current permission sets

```bash
ls -la force-app/main/default/permissionsets/
```

Current permission sets (13):
- Elaro_Admin.permissionset-meta.xml
- Elaro_Admin_Extended.permissionset-meta.xml
- Elaro_User.permissionset-meta.xml
- Elaro_Auditor.permissionset-meta.xml
- Elaro_Async_Admin.permissionset-meta.xml
- Elaro_Async_User.permissionset-meta.xml
- Elaro_Rule_Engine_Admin.permissionset-meta.xml
- Elaro_Rule_Engine_User.permissionset-meta.xml
- Elaro_AI_Governance_Admin.permissionset-meta.xml
- Elaro_AI_Governance_User.permissionset-meta.xml
- Elaro_SEC_Admin.permissionset-meta.xml
- Elaro_SEC_User.permissionset-meta.xml
- TechDebt_Manager.permissionset-meta.xml

### 5b. Find objects missing from permission sets

```bash
# List all custom objects
ls force-app/main/default/objects/ | head -50

# Check which objects appear in permission sets
grep -rn 'objectPermissions\|fieldPermissions' force-app/main/default/permissionsets/ | grep -oP 'object">[^<]+' | sort -u
```

Every custom object (`__c`) must appear in at least one permission set with appropriate CRUD access.

### 5c. Find Apex classes missing from permission sets

```bash
# List all @AuraEnabled classes (these MUST be in permission sets)
grep -rl '@AuraEnabled' force-app/main/default/classes/ --include="*.cls" | grep -v Test | sort

# Check which classes appear in permission sets
grep -rn 'apexClass' force-app/main/default/permissionsets/ | grep -oP '<apexClass>[^<]+' | sort -u
```

Every class with `@AuraEnabled` methods must have `<classAccesses><apexClass>ClassName</apexClass><enabled>true</enabled></classAccesses>`.

### 5d. Find tabs missing from permission sets

```bash
ls force-app/main/default/tabs/
grep -rn 'tabSettings' force-app/main/default/permissionsets/ | grep -oP '<tab>[^<]+' | sort -u
```

Every custom tab must appear in at least one permission set.

### 5e. Update Elaro_Admin.permissionset-meta.xml

The admin permission set should grant full access to all objects, classes, and tabs. Add missing entries. Use existing entries as the template for XML structure.

### 5f. Update role-specific permission sets

Each module's permission sets (AI Governance, SEC, Rule Engine, etc.) should grant access to that module's objects, classes, and tabs. Use minimum-privilege principle for User permission sets.

### 5g. Health Check permission sets

```bash
ls force-app-healthcheck/main/default/permissionsets/
```

Verify the Health Check package has its own admin and user permission sets covering all HC objects, classes, and tabs.

---

## PHASE 6: TEST COVERAGE

### 6a. Identify coverage gaps

If connected to an org:

```bash
sf apex run test --target-org <org> --test-level RunLocalTests --code-coverage --wait 15
```

Flag any class below 85% coverage.

### 6b. Local Jest test review

```bash
npm run test:unit -- --coverage
```

Flag any LWC component below 80% line coverage.

### 6c. Fix coverage gaps

For Apex classes below 85%:
- Add test methods for untested code paths
- Focus on negative tests (error handling, edge cases)
- Use `ComplianceTestDataFactory` for test data
- Every test must have `Test.startTest()` / `Test.stopTest()` boundaries
- Every test must have meaningful assertions with descriptive messages

For LWC components below 80%:
- Add tests for loading, error, and empty states
- Test user interactions (clicks, input changes)
- Mock all Apex wire adapters and imperative calls

---

## PHASE 7: LWC REVIEW

### 7a. Verify template compliance

```bash
# Should return zero results:
grep -rn 'if:true\|if:false' force-app/main/default/lwc/ --include="*.html"
grep -rn 'if:true\|if:false' force-app-healthcheck/main/default/lwc/ --include="*.html"
```

### 7b. Verify custom label usage

```bash
# Find hardcoded English strings in HTML (potential label gaps)
grep -rn '>[A-Z][a-z].*</' force-app/main/default/lwc/ --include="*.html" | grep -v '{' | head -20
```

All user-facing strings should use `{label.LabelName}` imported from `@salesforce/label/c.LabelName`.

### 7c. Verify ARIA and accessibility

```bash
# Find interactive elements missing ARIA labels
grep -rn '<lightning-button\|<lightning-input\|<lightning-combobox' force-app/main/default/lwc/ --include="*.html" | grep -v 'aria-label\|label=' | head -20
```

### 7d. Verify loading/error/empty states

Every LWC component should handle:
- Loading: `<lightning-spinner>` when data is being fetched
- Error: Error panel or toast when operations fail
- Empty: Illustration or message when no data exists

```bash
# Components missing spinner
for dir in force-app/main/default/lwc/*/; do
    name=$(basename "$dir")
    grep -q 'lightning-spinner\|isLoading' "$dir"*.html 2>/dev/null || echo "MISSING loading state: $name"
done
```

---

## PHASE 8: HEALTH CHECK PACKAGE AUDIT

The Health Check is a separate 2GP package in `force-app-healthcheck/`. Apply the same standards.

### 8a. Class inventory

```
Production classes (15):
- ToolingApiService.cls
- HealthCheckResult.cls
- ScanFinding.cls
- ScanRecommendation.cls
- HealthCheckScanner.cls
- MFAComplianceScanner.cls
- ProfilePermissionScanner.cls
- SessionSettingsScanner.cls
- AuditTrailScanner.cls
- ScoreAggregator.cls
- HealthCheckController.cls
- HealthCheckFeatureFlags.cls
- HCLogger.cls

Test classes (matching):
- All 15 production classes have corresponding *Test.cls files
```

### 8b. Security review

```bash
grep -rn '@AuraEnabled' force-app-healthcheck/main/default/classes/ --include="*.cls"
grep -rn 'WITH USER_MODE' force-app-healthcheck/main/default/classes/ --include="*.cls"
grep -rn 'as user' force-app-healthcheck/main/default/classes/ --include="*.cls"
```

Verify the same security patterns (try-catch, `WITH USER_MODE`, `as user`) are followed.

### 8c. Permission sets

```bash
ls force-app-healthcheck/main/default/permissionsets/
```

Verify admin + user permission sets exist and cover all HC objects, classes, and tabs.

### 8d. Custom Labels

```bash
cat force-app-healthcheck/main/default/labels/CustomLabels.labels-meta.xml
```

Verify all labels referenced in HC LWC components are defined.

### 8e. LWC components

```bash
ls force-app-healthcheck/main/default/lwc/
```

Apply Phase 7 checks to HC LWC components.

---

## PHASE 9: FINAL VERIFICATION

### 9a. Full local checks

```bash
npm run precommit
```

Must pass: formatting, linting, Jest tests.

### 9b. Full Apex test run (if connected to org)

```bash
sf apex run test --target-org <org> --test-level RunLocalTests --code-coverage --wait 15
```

All tests pass. Zero failures. 85%+ per class.

### 9c. Code Analyzer

```bash
sf scanner run --target force-app --format table --severity-threshold 1
sf scanner run --target force-app-healthcheck --format table --severity-threshold 1
```

Zero HIGH severity findings.

### 9d. Dry-run deploy

```bash
sf project deploy start --target-org <org> --source-dir force-app/main/default --dry-run --wait 10
sf project deploy start --target-org <org> --source-dir force-app-healthcheck/main/default --dry-run --wait 10
```

### 9e. Smoke test checklist

1. All Jest tests pass (`npm run test:unit`)
2. ESLint passes with max 3 warnings (`npm run lint`)
3. Prettier check passes (`npm run fmt:check`)
4. Code Analyzer: zero HIGH findings
5. Dry-run deploy succeeds for both packages
6. All Apex tests pass with 85%+ per class

---

## PHASE 10: PRODUCE THE REPORT

### 10a. Code quality grade

| Dimension | Weight | Score (1-10) | Weighted | Notes |
|-----------|--------|-------------|----------|-------|
| Security (USER_MODE, as user, try-catch, input validation, XSS) | 25% | | | |
| Governor Limits & Performance (no @future, bulk-safe, no SOQL/DML in loops) | 20% | | | |
| Test Quality (org-wide %, per-class %, negative tests, @IsTest(testFor)) | 15% | | | |
| Maintainability & Documentation (ApexDoc, naming, dead code, comments) | 15% | | | |
| Architecture & Async Patterns (Queueable, Cursors, AsyncOptions, Finalizers) | 10% | | | |
| AppExchange Readiness (permission sets, namespace, labels, feature flags) | 10% | | | |
| LWC Quality (lwc:if, ARIA, loading/error/empty, custom labels, Jest) | 5% | | | |
| **WEIGHTED AVERAGE** | **100%** | | | |

Letter grade: A (90-100), B (80-89), C (70-79), D (60-69), F (<60)

### 10b. Changelog

Every change made during this audit, in order:
```
[PHASE] [FILE] [LINE(S)] [CHANGE] [REASON]
```

### 10c. What still needs fixing

```
[SEVERITY] [FILE] [ISSUE] [REASON NOT FIXED]
```

CRITICAL = blocks AppExchange. HIGH = should fix before submission. MEDIUM = fix soon. LOW = nice to have. BLOCKED = needs human action (e.g., DevHub namespace registration).

### 10d. Before vs. after comparison

| Metric | Before (Phase 1) | After (Phase 9) | Delta |
|--------|------------------|-----------------|-------|
| @future methods | | | |
| @AuraEnabled missing try-catch | | | |
| SOQL without WITH USER_MODE | | | |
| DML without `as user` | | | |
| Classes missing @since | | | |
| Classes missing @author | | | |
| Test classes missing @IsTest(testFor) | | | |
| Objects missing from permission sets | | | |
| Apex classes missing from permission sets | | | |
| Tabs missing from permission sets | | | |
| Code Analyzer HIGH findings | | | |
| Jest test pass rate | | | |
| Apex test pass rate | | | |
| Org-wide coverage % | | | |

### 10e. Final task list

Numbered, sequenced, grouped by who can do it:

**Agent Can Do Now:**
- Items the autonomous agent can complete without human interaction

**Needs DevHub Access (Human Required):**
- Register `elaro` namespace in DevHub
- Register `elaroHC` namespace in DevHub

**Needs Org Admin (Human Required):**
- Items requiring Setup access or connected org

**Post-MVP (Future):**
- Items that can wait until after AppExchange submission

---

## HARD RULES

1. **CLAUDE.md is law.** Every coding standard in CLAUDE.md applies to every change you make. Do not deviate.
2. **The Solentra review report (.review-state/final-report.md) is STALE.** Do not trust finding statuses without verifying against actual code.
3. **WITH USER_MODE on all SOQL.** No exceptions except documented system-mode requirements (install handlers, event publishers).
4. **`as user` on all DML.** No exceptions except `Database.insert/update/delete(records, false, AccessLevel.USER_MODE)`.
5. **Queueable, never @future.** The only acceptable @future is one you are in the process of converting.
6. **Assert class only.** Never `System.assertEquals`, `System.assertNotEquals`, or `System.assert`.
7. **lwc:if only.** Never `if:true` or `if:false`.
8. **ElaroLogger only.** Never `System.debug` as primary logging.
9. **Custom Labels only.** Never hardcoded English strings in LWC HTML or JS.
10. **API v66.0 on all new code.** Check `.cls-meta.xml` and `.js-meta.xml`.
11. **Do not touch the platform/ TypeScript monorepo** unless explicitly requested.
12. **Do not modify ComplianceServiceFactory, IComplianceModule, ElaroLogger, ElaroSecurityUtils, or ElaroConstants** unless fixing a bug IN those files.
13. **Test after every 5 file edits max.** If tests fail, roll back.
14. **Run `npm run precommit` before any commit.**
15. **When in doubt, make the safer choice and document why.**

---

## REFERENCE IMPLEMENTATIONS

Use these files as gold-standard templates when making changes:

| File | What Makes It Exemplary |
|------|------------------------|
| `AIGovernanceController.cls` | Perfect @AuraEnabled pattern: `with sharing`, try-catch, ElaroLogger, `as user` DML, `WITH USER_MODE` |
| `EventCorrelationEngine.cls` | Full ApexDoc (`@author`, `@since`, `@group`, `@example`), structured logging, `@TestVisible`, `??` operators |
| `ElaroDailyDigest.SlackDigestQueueable` | Correct Queueable + `Database.AllowsCallouts` pattern — template for @future replacements |
| `SlackIntegration.SlackNotificationQueueable` | Consolidated Queueable replacing 4 @future methods, proper error handling |
| `ComplianceServiceBase.cls` | Abstract base class with interface implementation, audit logging, gap creation |
| `CommandCenterControllerTest.cls` | Negative testing: tests unsupported actions, blank inputs, `Assert.fail` on expected exceptions |
| `HealthCheckScannerTest.cls` | Strong assertions: validates score, finding count, severity, setting names, categories |

---

*Prompt version: v1 | Created: March 16, 2026 | Verified against codebase commit at HEAD*
*Previous audit: Solentra Review v2.0, February 19, 2026, Score: 66.5% (Grade C), 131 findings*
