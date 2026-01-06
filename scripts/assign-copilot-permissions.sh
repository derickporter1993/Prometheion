#!/bin/bash
# Assign Prometheion Admin permission set to current user
# Usage: ./scripts/assign-copilot-permissions.sh [org-alias]

ORG_ALIAS=${1:-"prod-org"}

echo "=========================================="
echo "Assigning Prometheion Admin Permissions"
echo "=========================================="
echo "Target Org: $ORG_ALIAS"
echo ""

# Get current user ID
echo "Step 1: Getting current user..."
CURRENT_USER=$(sf data query --query "SELECT Id, Username FROM User WHERE Id = '005bm00000YYzS5AAF' OR Username LIKE '%dbporter93%' LIMIT 1" --target-org $ORG_ALIAS --json 2>/dev/null | grep -o '"Id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$CURRENT_USER" ]; then
    echo "ERROR: Could not find current user. Please run manually:"
    echo "  sf data query --query \"SELECT Id, Username FROM User WHERE Username = 'YOUR_USERNAME'\" --target-org $ORG_ALIAS"
    exit 1
fi

echo "✅ Current User ID: $CURRENT_USER"
echo ""

# Get permission set ID
echo "Step 2: Getting Prometheion Admin permission set..."
PERM_SET_ID=$(sf data query --query "SELECT Id, Name FROM PermissionSet WHERE Name = 'Prometheion_Admin' OR Name = 'Prometheion_Admin_Extended'" --target-org $ORG_ALIAS --use-tooling-api --json 2>/dev/null | grep -o '"Id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$PERM_SET_ID" ]; then
    echo "ERROR: Could not find Prometheion Admin permission set."
    echo "Please verify the permission set is deployed."
    exit 1
fi

echo "✅ Permission Set ID: $PERM_SET_ID"
echo ""

# Check if already assigned
echo "Step 3: Checking if permission set is already assigned..."
EXISTING=$(sf data query --query "SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = '$CURRENT_USER' AND PermissionSetId = '$PERM_SET_ID'" --target-org $ORG_ALIAS --use-tooling-api --json 2>/dev/null | grep -o '"Id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$EXISTING" ]; then
    echo "✅ Permission set is already assigned to user."
    echo ""
    echo "=========================================="
    echo "✅ Complete - Permission set is assigned"
    echo "=========================================="
    echo ""
    echo "Next Steps:"
    echo "1. Refresh the Compliance Copilot component"
    echo "2. Try asking a question: 'Why did my score drop?'"
    echo ""
    exit 0
fi

# Assign permission set
echo "Step 4: Assigning permission set..."
sf data create record \
    --sobject PermissionSetAssignment \
    --values "AssigneeId=$CURRENT_USER PermissionSetId=$PERM_SET_ID" \
    --target-org $ORG_ALIAS \
    --use-tooling-api

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Success - Permission set assigned!"
    echo "=========================================="
    echo ""
    echo "Next Steps:"
    echo "1. Refresh the Compliance Copilot component"
    echo "2. Try asking a question: 'Why did my score drop?'"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ Error - Failed to assign permission set"
    echo "=========================================="
    echo ""
    echo "Manual Steps:"
    echo "1. Go to Setup → Users → Permission Sets"
    echo "2. Find 'Prometheion Admin' or 'Prometheion Admin Extended'"
    echo "3. Click 'Manage Assignments'"
    echo "4. Click 'Add Assignments'"
    echo "5. Select your user and click 'Assign'"
    echo ""
    exit 1
fi
