#!/bin/bash
# Prometheion Installation Script

set -e

echo "🚀 Prometheion Installation"
echo "===================================="

# Step 1: Validate environment
if ! command -v sf &> /dev/null; then
    echo "❌ Salesforce CLI not found. Please install: https://developer.salesforce.com/tools/salesforcecli"
    exit 1
fi

echo "✅ Salesforce CLI detected"

# Step 2: Create scratch org
echo "2️⃣  Creating scratch org..."
sf org create scratch -f config/prometheion-scratch-def.json -a prometheion-dev -d -y 30

# Step 3: Deploy metadata
echo "3️⃣  Deploying code..."
sf project deploy start -o prometheion-dev --wait 10

# Step 4: Assign permission sets
echo "4️⃣  Assigning permissions..."
sf org assign permset -n Prometheion_Admin -o prometheion-dev || echo "⚠️  Permission set assignment skipped (may not exist yet)"

# Step 5: Load sample data
echo "5️⃣  Loading sample compliance data..."
if [ -f "data/sample-data-plan.json" ]; then
    sf data import tree -p data/sample-data-plan.json -o prometheion-dev
else
    echo "⚠️  Sample data not found, skipping..."
fi

# Step 6: Run tests
echo "6️⃣  Running test suite..."
sf apex test run -o prometheion-dev --code-coverage --wait 10 || echo "⚠️  Some tests may have failed"

# Step 7: Open org
echo "7️⃣  Opening Prometheion app..."
sf org open -o prometheion-dev -p /lightning/page/home

echo ""
echo "✅ Installation complete! Next steps:"
echo "   1. Configure AI Settings: Setup → Custom Settings → Prometheion AI Settings"
echo "   2. Run baseline: sf apex run -f scripts/generate-baseline-report.apex -o prometheion-dev"
echo "   3. Review compliance dashboard in Lightning App"
