#!/bin/bash
# Generates compliance evidence pack for Sentinel

set -e

echo "🔍 Sentinel Evidence Generator"
echo "=============================="
echo ""

# Get framework type
FRAMEWORK=${1:-SOC2}
echo "📊 Framework: $FRAMEWORK"

# Check if SFDX is installed
if ! command -v sfdx &> /dev/null; then
    echo "❌ Error: Salesforce CLI (sfdx) is not installed"
    exit 1
fi

# Check if authenticated
if ! sfdx force:org:list &> /dev/null; then
    echo "❌ Error: No authenticated orgs found"
    echo "Run: sfdx auth:web:login -d"
    exit 1
fi

echo "✅ SFDX authenticated"
echo ""

# Create Apex script to call evidence generator
cat > /tmp/sentinel-evidence.apex <<'EOF'
String result = SentinelEvidenceEngine.generateEvidencePack('FRAMEWORK_PLACEHOLDER');
System.debug('Evidence Pack Result: ' + result);
EOF

# Replace framework placeholder
sed -i "s/FRAMEWORK_PLACEHOLDER/$FRAMEWORK/g" /tmp/sentinel-evidence.apex

echo "🚀 Generating evidence pack..."
sfdx force:apex:execute -f /tmp/sentinel-evidence.apex

echo ""
echo "✅ Evidence pack generation complete!"
echo "📁 Check Salesforce Content for downloadable files"
echo ""

# Cleanup
rm /tmp/sentinel-evidence.apex
