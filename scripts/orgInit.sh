#!/usr/bin/env bash
# Prometheion Demo Org Initialization Script
# Creates scratch org, deploys metadata, assigns permission sets, and creates sample data
set -euo pipefail

alias_name="${1:-prometheion-demo}"

echo "🚀 Prometheion Demo Org Setup"
echo "════════════════════════════════════════"

# Ensure DevHub exists
if ! sf org list --json | grep -q '"isDevHub": true'; then
  echo "❌ Please authenticate a DevHub first:"
  echo "   sf org login web --alias DevHub --set-default-dev-hub"
  exit 1
fi

echo "📦 Creating scratch org: $alias_name"
sf org create scratch \
  -f config/prometheion-scratch-def.json \
  -a "$alias_name" \
  -d 7 \
  --set-default

echo "📤 Deploying source code..."
sf project deploy start -o "$alias_name"

echo "🔐 Assigning permission sets..."
sf org assign permset \
  --name Prometheion_Admin \
  -o "$alias_name" || echo "⚠️  Prometheion_Admin permission set not found (may need to deploy first)"

sf org assign permset \
  --name Prometheion_User \
  -o "$alias_name" || echo "⚠️  Prometheion_User permission set not found"

echo "📊 Creating sample data..."
sf apex run \
  --file scripts/create-test-data.apex \
  -o "$alias_name" || echo "⚠️  Test data script failed (continuing...)"

echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Configure Named Credentials in Setup → Named Credentials"
echo "   2. Review docs/DEMO_ORG_SETUP.md for detailed configuration"
echo "   3. Open org: sf org open -o $alias_name"
echo ""
echo "Opening org..."
sf org open -o "$alias_name" -p /lightning/setup/SetupOneHome/home