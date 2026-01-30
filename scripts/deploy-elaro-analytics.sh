#!/bin/bash
# Deployment script for Elaro Analytics Components
# Usage: ./deploy-elaro-analytics.sh [org-alias]

ORG_ALIAS=${1:-"default"}

echo "=========================================="
echo "Elaro Analytics Components Deployment"
echo "=========================================="
echo "Target Org: $ORG_ALIAS"
echo ""

# Step 1: Deploy Apex Controllers
echo "Step 1: Deploying Apex Controllers..."
sf project deploy start \
    --source-dir force-app/main/default/classes/Elaro*Controller.cls \
    --target-org $ORG_ALIAS \
    --wait 10

if [ $? -ne 0 ]; then
    echo "ERROR: Controller deployment failed"
    exit 1
fi

# Step 2: Deploy Controller Metadata
echo ""
echo "Step 2: Deploying Controller Metadata..."
sf project deploy start \
    --source-dir force-app/main/default/classes/Elaro*Controller.cls-meta.xml \
    --target-org $ORG_ALIAS \
    --wait 10

# Step 3: Deploy Test Classes
echo ""
echo "Step 3: Deploying Test Classes..."
sf project deploy start \
    --source-dir force-app/main/default/classes/Elaro*ControllerTest.cls \
    --target-org $ORG_ALIAS \
    --wait 10

# Step 4: Deploy Test Class Metadata
echo ""
echo "Step 4: Deploying Test Class Metadata..."
sf project deploy start \
    --source-dir force-app/main/default/classes/Elaro*ControllerTest.cls-meta.xml \
    --target-org $ORG_ALIAS \
    --wait 10

# Step 5: Run Tests
echo ""
echo "Step 5: Running Tests..."
sf apex run test \
    --class-names ElaroDynamicReportControllerTest,ElaroExecutiveKPIControllerTest,ElaroDrillDownControllerTest,ElaroComparativeAnalyticsControllerTest,ElaroTrendControllerTest \
    --result-format human \
    --code-coverage \
    --target-org $ORG_ALIAS \
    --wait 10

if [ $? -ne 0 ]; then
    echo "WARNING: Some tests may have failed. Review output above."
fi

# Step 6: Deploy LWC Components
echo ""
echo "Step 6: Deploying LWC Components..."
sf project deploy start \
    --source-dir force-app/main/default/lwc/elaro* \
    --target-org $ORG_ALIAS \
    --wait 10

if [ $? -ne 0 ]; then
    echo "ERROR: LWC deployment failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Configure Custom Metadata for KPIs (see docs/ELARO_ANALYTICS_IMPLEMENTATION_PLAN.md)"
echo "2. Set up Platform Cache partition 'ElaroReportCache' (optional)"
echo "3. Add components to Lightning pages"
echo "4. Update ALLOWED_OBJECTS in controllers if needed"
echo ""
