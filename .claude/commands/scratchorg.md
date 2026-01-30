# Scratch Org Management

Create, manage, and work with Salesforce scratch orgs for Elaro development.

## Quick Commands

### Create New Scratch Org
```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias my-feature-scratch --duration-days 30 --set-default
```

### List All Orgs
```bash
sf org list --all
```

### Open Scratch Org
```bash
sf org open --target-org my-feature-scratch
```

### Delete Scratch Org
```bash
sf org delete scratch --target-org my-feature-scratch --no-prompt
```

## Standard Workflow

### 1. Create Scratch Org for Feature Development
```bash
# Create 30-day scratch org
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias elaro-feature-permissionintel \
  --duration-days 30 \
  --set-default

# Wait for creation (usually 2-3 minutes)
```

### 2. Deploy Code to Scratch Org
```bash
# Deploy all metadata
sf project deploy start --target-org elaro-feature-permissionintel

# Or deploy specific components
sf project deploy start \
  --source-dir force-app/main/default/classes \
  --target-org elaro-feature-permissionintel
```

### 3. Import Test Data
```bash
# Import sample compliance data
sf data import tree \
  --plan scripts/apex/sample-data/data-plan.json \
  --target-org elaro-feature-permissionintel
```

### 4. Open and Configure
```bash
# Open scratch org in browser
sf org open --target-org elaro-feature-permissionintel

# Manually configure:
# - Assign permission sets
# - Set up test users
# - Configure connected apps
# - Import additional data via UI if needed
```

### 5. Work in Scratch Org
Develop and test your feature. Retrieve changes when ready:
```bash
# Retrieve specific metadata
sf project retrieve start \
  --metadata ApexClass:ElaroNewClass \
  --target-org elaro-feature-permissionintel

# Or retrieve all
sf project retrieve start \
  --target-org elaro-feature-permissionintel
```

### 6. Clean Up
```bash
# When done, delete the scratch org
sf org delete scratch --target-org elaro-feature-permissionintel --no-prompt
```

## Scratch Org Configuration

Default config location: `config/project-scratch-def.json`

```json
{
  "orgName": "Elaro Dev Org",
  "edition": "Developer",
  "features": ["API", "AuthorApex", "MultiCurrency"],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "securitySettings": {
      "sessionSettings": {
        "forceRelogin": false
      }
    }
  }
}
```

### Common Features to Enable
- `API` - Enable REST/SOAP APIs
- `AuthorApex` - Apex development
- `MultiCurrency` - Multi-currency support
- `DebugApex` - Debug logs
- `ServiceCloud` - Service Cloud features
- `Communities` - Experience Cloud

## Org Display Info

Check org details:
```bash
sf org display --target-org elaro-feature-permissionintel
```

Output includes:
- Username
- Org ID
- Instance URL
- Access Token
- Expiration date
- Status

## Managing Multiple Scratch Orgs

### Set Default Org
```bash
sf config set target-org=elaro-feature-permissionintel
```

### Check Current Default
```bash
sf config get target-org
```

### Deploy to Specific Org (Override Default)
```bash
sf project deploy start --target-org specific-org-alias
```

## Scratch Org Naming Convention

Use descriptive aliases:
```
elaro-[purpose]-[feature/name]

Examples:
- elaro-dev-main          # Primary dev org
- elaro-feature-permint   # Feature: Permission Intelligence
- elaro-bugfix-soql       # Bug fix: SOQL issue
- elaro-test-integration  # Integration testing
- elaro-demo-appexchange  # Demo for AppExchange
```

## Extending Scratch Org Lifetime

Default max: 30 days

If you need more time:
1. Retrieve all changes: `sf project retrieve start`
2. Delete old scratch org
3. Create new scratch org
4. Deploy changes to new org

**Note:** You cannot extend an existing scratch org beyond 30 days.

## Snapshot Orgs (Alternative)

For consistent testing environments, use org snapshots:
```bash
# Create snapshot (requires DevHub access)
sf org create snapshot --source-org [source-org] --name MySnapshot --description "Baseline config"

# Create org from snapshot
sf org create scratch --snapshot MySnapshot --alias elaro-from-snapshot
```

## Troubleshooting

### Scratch Org Creation Fails
- Check Dev Hub connection: `sf org display --target-org prod-org`
- Verify scratch org allocation: Not exceeded daily/active limits
- Check config file syntax: `config/project-scratch-def.json`

### Deployment to Scratch Org Fails
- Ensure org is active: `sf org list`
- Check for missing dependencies
- Try: `sf project deploy validate` first

### Can't Access Scratch Org
- Check expiration: `sf org list --all`
- If expired, create new org
- Retrieve code before expiration: `sf project retrieve start`

### "Source is Newer" Conflict
```bash
# Force overwrite local with scratch org
sf project retrieve start --target-org my-scratch --ignore-conflicts

# Or force overwrite scratch org with local
sf project deploy start --target-org my-scratch --ignore-conflicts
```

## Best Practices

✅ **DO:**
- Use descriptive alias names
- Set reasonable durations (7 days for quick tests, 30 for features)
- Deploy and test frequently
- Keep scratch orgs for specific purposes
- Delete when done to free up allocation
- Retrieve code before expiration

❌ **DON'T:**
- Use scratch orgs for production testing
- Store sensitive data in scratch orgs
- Forget to retrieve changes before deletion
- Share scratch org credentials
- Create too many concurrent orgs (limited allocation)

## Scratch Org Checklist

When creating a new scratch org:
- [ ] Descriptive alias name
- [ ] Appropriate duration (7-30 days)
- [ ] Deploy all code
- [ ] Import test data
- [ ] Assign permission sets
- [ ] Configure settings
- [ ] Document purpose (in SESSION_CONTEXT.md if long-lived)

Before deleting:
- [ ] Retrieve all changes
- [ ] Export any test data needed
- [ ] Verify nothing is lost
- [ ] Update git with changes
- [ ] Remove from SESSION_CONTEXT.md tracking
