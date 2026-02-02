# Safe Deployment Workflow

Deploy changes to a Salesforce org following best practices with built-in safety checks.

## Pre-Deployment Checklist

Before running any deployment commands, verify:

1. **Tests Pass Locally**
   ```bash
   npm run test:unit        # LWC tests
   npm run lint             # Code quality
   ```

2. **Target Org Verified**
   ```bash
   sf org display --target-org [alias]
   ```
   - ✅ Confirm it's NOT a production org
   - ✅ Verify org status is Active

3. **Changes Reviewed**
   ```bash
   git status
   git diff
   ```

## Deployment Steps

### Step 1: Preview Changes
```bash
sf project deploy preview --target-org [org-alias]
```

Review the output for:
- Number of components to deploy
- Any potential conflicts
- Metadata types being updated

### Step 2: Validate (Dry Run)
```bash
sf project deploy validate --target-org [org-alias] --test-level RunLocalTests
```

This runs all tests WITHOUT making changes. Wait for:
- ✅ All tests pass
- ✅ Code coverage meets minimum (75%+)
- ✅ No deployment errors

### Step 3: Deploy
Only if validation passes:
```bash
sf project deploy start --target-org [org-alias] --test-level RunLocalTests
```

### Step 4: Monitor & Verify
```bash
sf project deploy report --target-org [org-alias]
```

After deployment:
- Check for any warnings or errors
- Verify expected components deployed
- Open org and spot-check critical functionality:
  ```bash
  sf org open --target-org [org-alias]
  ```

## Quick Commands

### Deploy Specific Components
```bash
# Single class
sf project deploy start --source-dir force-app/main/default/classes/MyClass.cls --target-org [alias]

# Directory
sf project deploy start --source-dir force-app/main/default/lwc/myComponent --target-org [alias]

# Metadata type
sf project deploy start --metadata ApexClass:MyClass --target-org [alias]
```

### Deploy with Specific Tests
```bash
sf project deploy start --target-org [alias] --test-level RunSpecifiedTests --tests ElaroSecurityUtilsTest,MyComponentTest
```

### Check Deployment Status
```bash
sf project deploy report --job-id [deployment-id] --target-org [alias]
```

## Safety Guardrails

The following commands are **BLOCKED** in settings.json:
- ❌ `sf project deploy start --target-org prod-org`
- ❌ `sf project deploy start --target-org elaro-prod`
- ❌ `sf org delete scratch -o elaro-prod`

## Rollback Strategy

If deployment fails or causes issues:

1. **Quick Fix**: Deploy previous working version from git
   ```bash
   git checkout [last-good-commit]
   sf project deploy start --target-org [alias]
   git checkout main  # return to current
   ```

2. **Full Rollback**: Use destructive changes
   ```bash
   # Create destructiveChanges.xml with failed components
   sf project deploy start --pre-destructive-changes destructiveChanges.xml --target-org [alias]
   ```

## Troubleshooting

### Deployment Fails with Test Coverage < 75%
- Identify classes without tests: Review deployment output
- Add test classes or increase coverage in existing tests
- Re-run validation

### Deployment Fails with SOQL Error
- Check for missing `WITH SECURITY_ENFORCED` clauses
- Verify FLS/CRUD checks using ElaroSecurityUtils
- Review object permissions in scratch org

### Component Conflicts
- Retrieve latest from org: `sf project retrieve start --target-org [alias]`
- Resolve conflicts locally
- Re-attempt deployment

## Post-Deployment

✅ Update `docs/SESSION_CONTEXT.md` with:
- What was deployed
- Deploy date and org
- Any issues encountered
- Next steps

✅ Commit changes:
```bash
git add .
git commit -m "Deploy: [description] to [org-alias]"
git push
```
