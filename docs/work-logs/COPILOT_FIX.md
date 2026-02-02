# Copilot Apex Access Fix

## ✅ Fixed: Apex Class Access

The `ElaroComplianceCopilot` Apex class is now accessible through the permission sets.

### What Was Fixed

1. **Deployed Apex Class**: `ElaroComplianceCopilot.cls` is deployed to your org
2. **Added to Permission Sets**: 
   - `Elaro_Admin` - Added `ElaroComplianceCopilot` and `ElaroComplianceScorer` class access
   - `Elaro_Admin_Extended` - Already had access (no changes needed)

### Next Steps

**Assign the Permission Set to Your User:**

1. Go to **Setup** → **Users** → **Permission Sets**
2. Find **"Elaro Admin"** or **"Elaro Admin Extended"**
3. Click **"Manage Assignments"**
4. Click **"Add Assignments"**
5. Select your user (or all users who need access)
6. Click **"Assign"** → **"Done"**

**OR** use the CLI:

```bash
# Get your user ID
sf data query --query "SELECT Id, Username FROM User WHERE Username = 'YOUR_USERNAME'" --target-org prod-org

# Get permission set ID
sf data query --query "SELECT Id, Name FROM PermissionSet WHERE Name = 'Elaro_Admin'" --target-org prod-org --use-tooling-api

# Assign permission set (replace USER_ID and PERMISSION_SET_ID)
sf data create record --sobject PermissionSetAssignment --values "AssigneeId=USER_ID PermissionSetId=PERMISSION_SET_ID" --target-org prod-org --use-tooling-api
```

### Verify Access

After assigning the permission set:

1. Refresh the Compliance Copilot component
2. Try asking a question like: **"Why did my score drop?"**
3. The error should be resolved

### Alternative: Make Class Public

If you want to avoid permission set assignments, you can make the class `global` instead of `public`, but this is **not recommended** for security reasons.

---

## 🔍 Troubleshooting

### Error: "No apex action available"

**Cause**: User doesn't have access to the Apex class.

**Solution**: 
- Assign `Elaro_Admin` or `Elaro_Admin_Extended` permission set
- Or verify the class is deployed: `sf data query --query "SELECT Id, Name FROM ApexClass WHERE Name = 'ElaroComplianceCopilot'" --target-org prod-org --use-tooling-api`

### Error: "Insufficient access rights"

**Cause**: Permission set is assigned but class access is not enabled.

**Solution**: 
- Verify class access in permission set: Setup → Permission Sets → Elaro Admin → Apex Class Access
- Ensure `ElaroComplianceCopilot` is listed and enabled

### Error: "Method not found"

**Cause**: Method signature mismatch or class not deployed.

**Solution**: 
- Verify class is deployed: `sf project deploy start --source-dir force-app/main/default/classes/ElaroComplianceCopilot.cls --target-org prod-org`
- Check method signature matches: `@AuraEnabled public static CopilotResponse askCopilot(String query)`
