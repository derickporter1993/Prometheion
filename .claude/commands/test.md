# Run Tests

Execute Apex and LWC tests for the Elaro project with comprehensive coverage reporting.

## Quick Commands

### Run All Tests
```bash
# All Apex tests
sf apex run test --test-level RunLocalTests --target-org elaro-dev --result-format human --code-coverage

# All LWC tests
npm run test:unit

# Lint code
npm run lint
```

### Run Specific Tests
```bash
# Single test class
sf apex run test --tests ElaroSecurityUtilsTest --target-org elaro-dev --result-format human --code-coverage

# Multiple test classes
sf apex run test --tests ElaroSecurityUtilsTest,ElaroComplianceEngineTest --target-org elaro-dev --result-format human --code-coverage

# Tests matching pattern
sf apex run test --class-names "Elaro*Test" --target-org elaro-dev --result-format human --code-coverage
```

### Run Tests for Specific Class
```bash
# Test a single Apex class
sf apex run test --tests ElaroMyClassTest --synchronous --target-org elaro-dev --result-format human --code-coverage
```

## Test Levels Explained

- **RunSpecifiedTests** - Run only specific test classes (use with `--tests`)
- **RunLocalTests** - Run all tests in the org EXCEPT managed packages (recommended for deployment)
- **RunAllTestsInOrg** - Run ALL tests including managed packages (slow, rarely needed)

## Coverage Requirements

| Category | Minimum | Target | Status |
|----------|---------|--------|--------|
| Org-wide | 75% | 85% | Required for deployment |
| Per-class | 75% | 90% | Required for new code |
| Critical classes | 85% | 95% | Security & compliance |

## Running Tests in Different Formats

### Human-Readable Output
```bash
sf apex run test --tests ElaroMyClassTest --result-format human --target-org elaro-dev
```

### JSON Output (for parsing)
```bash
sf apex run test --tests ElaroMyClassTest --result-format json --target-org elaro-dev
```

### TAP Format (Test Anything Protocol)
```bash
sf apex run test --tests ElaroMyClassTest --result-format tap --target-org elaro-dev
```

## Checking Coverage

### Get Coverage Report
```bash
sf apex get test --test-run-id [run-id] --code-coverage --result-format human
```

### Coverage by Class
```bash
sf apex get test --code-coverage --result-format human --target-org elaro-dev | grep ElaroMyClass
```

## Debugging Failed Tests

### View Detailed Logs
```bash
# Tail logs in real-time
sf apex tail log --target-org elaro-dev

# Get specific test log
sf apex get log --number 1 --target-org elaro-dev

# List recent logs
sf apex list log --target-org elaro-dev
```

### Debug Specific Test
Add debug statements in your test:
```apex
System.debug(LoggingLevel.ERROR, '🔍 Variable value: ' + myVariable);
System.debug(LoggingLevel.WARN, '⚠️ Entering critical section');
```

Then run with synchronous mode:
```bash
sf apex run test --tests ElaroMyClassTest --synchronous --target-org elaro-dev
```

## LWC Testing

### Run All LWC Tests
```bash
npm run test:unit
```

### Run Specific Component Tests
```bash
npm run test:unit -- myComponent
```

### Watch Mode (auto-run on changes)
```bash
npm run test:unit:watch
```

### Generate Coverage Report
```bash
npm run test:unit:coverage
```

Coverage report will be in `coverage/lcov-report/index.html`

### Debug LWC Tests
```bash
npm run test:unit:debug
```

This opens Chrome DevTools for debugging.

## Test Data Management

### Create Test Data
Use `@TestSetup` for reusable test data:
```apex
@TestSetup
static void setup() {
    List<MyObject__c> testRecords = new List<MyObject__c>();
    for (Integer i = 0; i < 200; i++) {
        testRecords.add(new MyObject__c(
            Name = 'Test Record ' + i,
            Status__c = 'Active'
        ));
    }
    insert testRecords;
}
```

### Import Test Data from Files
```bash
sf data import tree --plan scripts/apex/sample-data/data-plan.json --target-org elaro-dev
```

## Pre-Deployment Testing

Before deploying, always run:
```bash
# 1. Lint code
npm run lint

# 2. LWC tests
npm run test:unit

# 3. Apex tests with coverage
sf apex run test --test-level RunLocalTests --target-org elaro-dev --result-format human --code-coverage

# 4. Check results
# Ensure ALL tests pass and coverage ≥ 75%
```

## Troubleshooting

### Test Timeout
Increase timeout in test class:
```apex
@isTest
static void myLongRunningTest() {
    Test.setTimeout(120000); // 120 seconds
    // ... test logic
}
```

### UNABLE_TO_LOCK_ROW
Use separate test contexts:
```apex
@isTest
static void testWithLocking() {
    Test.startTest();
    // Your test logic - ensures isolated execution context
    Test.stopTest();
}
```

### Governor Limits
Check limits in tests:
```apex
System.debug('SOQL Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
System.debug('DML Rows: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows());
```

### Test Class Not Found
Verify class is deployed:
```bash
sf apex list class --target-org elaro-dev | grep ElaroMyClassTest
```

If missing, deploy:
```bash
sf project deploy start --source-dir force-app/main/default/classes/ElaroMyClassTest.cls --target-org elaro-dev
```

## CI/CD Integration

Tests automatically run in CI pipeline:
```yaml
# .github/workflows/test.yml
- name: Run Apex Tests
  run: sf apex run test --test-level RunLocalTests --target-org ci-org --wait 20 --code-coverage
```

## Best Practices

✅ **DO:**
- Use `Test.startTest()` and `Test.stopTest()` for async operations
- Use `System.runAs()` to test different permission scenarios
- Test bulk operations (200+ records)
- Use meaningful test data (not "Test 1", "Test 2")
- Assert specific values, not just "no exception thrown"
- Clean up test data if creating in `@isTest` methods (not needed for `@TestSetup`)

❌ **DON'T:**
- Use `@isTest(SeeAllData=true)` - always create test data
- Make callouts without using mock responses
- Assume test execution order
- Test implementation details - test behavior
- Leave commented-out debug statements

## Coverage Report Location

After running tests, find reports at:
- **Apex**: `.sfdx/tools/testresults/[run-id]/`
- **LWC**: `coverage/lcov-report/index.html`

## Example Test Session

```bash
# 1. Run tests
sf apex run test --test-level RunLocalTests --target-org elaro-dev --result-format human --code-coverage

# 2. Check output
# Test Results:
# Passed: 145
# Failed: 0
# Total Coverage: 87%

# 3. If coverage low, identify classes
sf apex get test --code-coverage --result-format human | grep -E "^[^ ]" | awk '$2 < 75'

# 4. Add tests for low-coverage classes

# 5. Re-run tests
```

## Post-Testing Checklist

- [ ] All tests pass ✅
- [ ] Org-wide coverage ≥ 75%
- [ ] New classes have ≥ 75% coverage
- [ ] No compiler warnings
- [ ] Debug statements removed or minimized
- [ ] Test logs reviewed for errors
- [ ] Ready to deploy
