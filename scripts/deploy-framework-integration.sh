#!/bin/bash
# Deployment script for Prometheion Framework Integration
# Deploys all 10 compliance frameworks with policies and dashboard updates
# Usage: ./deploy-framework-integration.sh [org-alias]

ORG_ALIAS=${1:-"default"}

echo "=========================================="
echo "Prometheion Framework Integration Deployment"
echo "=========================================="
echo "Target Org: $ORG_ALIAS"
echo ""

# Step 1: Deploy Constants and Scorer
echo "Step 1: Deploying Framework Constants and Scorer..."
sf project deploy start \
    --source-dir force-app/main/default/classes/PrometheionConstants.cls \
    --source-dir force-app/main/default/classes/PrometheionComplianceScorer.cls \
    --target-org $ORG_ALIAS \
    --wait 10

if [ $? -ne 0 ]; then
    echo "ERROR: Constants/Scorer deployment failed"
    exit 1
fi

# Step 2: Deploy Custom Metadata Type Definition (with updated Framework picklist)
echo ""
echo "Step 2: Deploying Custom Metadata Type Definition..."
sf project deploy start \
    --source-dir force-app/main/default/objects/Compliance_Policy__mdt \
    --target-org $ORG_ALIAS \
    --wait 10

if [ $? -ne 0 ]; then
    echo "ERROR: Custom Metadata Type deployment failed"
    exit 1
fi

# Step 3: Deploy Custom Metadata Policies
echo ""
echo "Step 3: Deploying Compliance Policies..."
sf project deploy start \
    --source-dir force-app/main/default/customMetadata \
    --target-org $ORG_ALIAS \
    --wait 10

if [ $? -ne 0 ]; then
    echo "WARNING: Some metadata policies may have failed. Review output above."
fi

# Step 4: Deploy Dashboard Component
echo ""
echo "Step 4: Deploying Dashboard Component..."
sf project deploy start \
    --source-dir force-app/main/default/lwc/prometheionDashboard \
    --target-org $ORG_ALIAS \
    --wait 10

if [ $? -ne 0 ]; then
    echo "ERROR: Dashboard deployment failed"
    exit 1
fi

# Step 5: Deploy FlexiPage
echo ""
echo "Step 5: Deploying Compliance Hub Page..."
sf project deploy start \
    --source-dir force-app/main/default/flexipages/Prometheion_Compliance_Hub.flexipage-meta.xml \
    --target-org $ORG_ALIAS \
    --wait 10

# Step 6: Run Tests
echo ""
echo "Step 6: Running Compliance Scorer Tests..."
sf apex run test \
    --class-names PrometheionComplianceScorerTest \
    --result-format human \
    --code-coverage \
    --target-org $ORG_ALIAS \
    --wait 10

if [ $? -ne 0 ]; then
    echo "WARNING: Some tests may have failed. Review output above."
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Frameworks Deployed:"
echo "  ✅ HIPAA, SOC 2, NIST, FedRAMP, GDPR"
echo "  ✅ SOX, PCI-DSS, CCPA, GLBA, ISO 27001"
echo ""
echo "Next Steps:"
echo "1. Navigate to Prometheion Compliance Hub in your org"
echo "2. Verify all 10 frameworks appear in the dashboard"
echo "3. Run a compliance scan to see framework scores"
echo "4. Review compliance policies in Setup > Custom Metadata Types"
echo ""
