# Apex Test Coverage Report

## Overview

This document provides instructions for generating Apex test coverage reports and verifying that the Prometheion package meets the AppExchange requirement of ≥75% code coverage.

## Prerequisites

- Salesforce CLI (sf) installed and authenticated
- Access to a scratch org or sandbox
- All metadata deployed successfully

## Generating Coverage Report

### Step 1: Create Scratch Org (if needed)

```bash
# Create a fresh scratch org
sf org create scratch -f config/prometheion-scratch-def.json -a prometheion-coverage -d 7

# Or use existing org
sf org display -o prometheion-coverage
```

### Step 2: Deploy All Metadata

```bash
# Deploy all source to scratch org
sf project deploy start -o prometheion-coverage

# Verify deployment succeeded
sf project deploy report -o prometheion-coverage
```

### Step 3: Assign Permission Sets

```bash
# Assign required permission sets
sf org assign permset --name Prometheion_Admin -o prometheion-coverage
sf org assign permset --name Prometheion_User -o prometheion-coverage
sf org assign permset --name Prometheion_Auditor -o prometheion-coverage
```

### Step 4: Run All Apex Tests with Coverage

```bash
# Run all tests and generate coverage report
sf apex run test \
  --target-org prometheion-coverage \
  --code-coverage \
  --result-format human \
  --wait 30 \
  --detailed-coverage

# Save results to file
sf apex run test \
  --target-org prometheion-coverage \
  --code-coverage \
  --result-format human \
  --wait 30 \
  --detailed-coverage \
  --output-file coverage-report.txt
```

### Step 5: Generate JSON Coverage Report

```bash
# Generate JSON format for programmatic analysis
sf apex run test \
  --target-org prometheion-coverage \
  --code-coverage \
  --result-format json \
  --wait 30 \
  --output-file coverage-report.json
```

### Step 6: Verify Coverage Threshold

The output will show:

- **Total Coverage**: Must be ≥75%
- **Class-by-Class Coverage**: Each production class should have ≥75% coverage
- **Test Results**: All tests must pass

## Expected Results

### Coverage Targets

| Category           | Target | Minimum           |
| ------------------ | ------ | ----------------- |
| Overall Coverage   | 85%+   | 75%               |
| Production Classes | 85%+   | 75%               |
| Test Classes       | N/A    | N/A (not counted) |

### Coverage by Class

After running tests, verify coverage for key classes:

- `PrometheionSecurityUtils`: 95%+
- `PrometheionComplianceScorer`: 85%+
- `ComplianceDashboardController`: 85%+
- `PrometheionExecutiveKPIController`: 85%+
- All AI service classes: 80%+

## Troubleshooting

### Low Coverage Classes

If any class has <75% coverage:

1. Identify untested methods:

   ```bash
   # View detailed coverage for specific class
   sf apex run test \
     --target-org prometheion-coverage \
     --class-names PrometheionSecurityUtils \
     --code-coverage \
     --result-format human
   ```

2. Review the class and identify missing test scenarios
3. Add test methods to existing test class or create new test class
4. Re-run tests and verify coverage improved

### Test Failures

If tests fail:

1. Review failure messages in the output
2. Fix failing tests
3. Re-run tests until all pass
4. Verify coverage still meets threshold

## Coverage Report Format

### Human-Readable Format

```
Test Execution Summary
──────────────────────
Total Tests: 250
Passed: 250
Failed: 0
Skipped: 0

Code Coverage Summary
─────────────────────
Total Coverage: 82.5%
Classes: 137
Lines Covered: 12,450
Lines Not Covered: 2,650
```

### JSON Format

```json
{
  "summary": {
    "outcome": "Passed",
    "testsRan": 250,
    "passing": 250,
    "failing": 0,
    "skipped": 0,
    "passRate": "100%",
    "codeCoverage": {
      "totalCoverage": "82.5%",
      "classes": 137,
      "linesCovered": 12450,
      "linesNotCovered": 2650
    }
  },
  "tests": [...],
  "codeCoverage": [...]
}
```

## Continuous Monitoring

### Pre-Deployment Check

Before deploying to production:

```bash
# Run coverage check script
./scripts/checkCoverage.sh prometheion-coverage
```

### CI/CD Integration

Coverage checks should be integrated into CI/CD pipeline:

```yaml
# .github/workflows/prometheion-ci.yml
- name: Run Apex Tests with Coverage
  run: |
    sf apex run test \
      --target-org ${{ secrets.SCRATCH_ORG }} \
      --code-coverage \
      --result-format json \
      --output-file coverage.json

    # Verify coverage threshold
    node scripts/verifyCoverage.js coverage.json 75
```

## Notes

- Coverage is calculated based on lines executed during test runs
- Test classes themselves are not included in coverage calculations
- `@TestSetup` methods contribute to coverage
- Private methods are included in coverage calculations
- Platform events and triggers require special test setup

## Last Updated

- **Date**: January 10, 2026
- **Coverage**: TBD (requires org deployment)
- **Status**: Documentation complete, awaiting org deployment verification

## Next Steps

1. Deploy to scratch org
2. Run coverage report using commands above
3. Update this document with actual coverage percentages
4. Address any classes below 75% threshold
5. Re-run until all classes meet threshold
6. Save final coverage report for AppExchange submission
