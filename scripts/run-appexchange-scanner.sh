#!/bin/bash
# Run Salesforce Code Analyzer with AppExchange Selectors
# This script generates all required scanner reports for AppExchange submission

set -e

echo "=================================="
echo "AppExchange Code Analyzer Scanner"
echo "=================================="
echo ""

# Create scanner reports directory
mkdir -p scanner-reports

# Check if sf CLI is installed
if ! command -v sf &> /dev/null; then
    echo "❌ Salesforce CLI (sf) is not installed"
    echo ""
    echo "Install Salesforce CLI:"
    echo "  npm install -g @salesforce/cli"
    echo ""
    echo "Install Code Analyzer plugin:"
    echo "  sf plugins install @salesforce/sfdx-scanner"
    echo ""
    exit 1
fi

# Check if Code Analyzer is installed
if ! sf scanner --help &> /dev/null; then
    echo "❌ Code Analyzer plugin is not installed"
    echo ""
    echo "Install Code Analyzer:"
    echo "  sf plugins install @salesforce/sfdx-scanner"
    echo ""
    exit 1
fi

echo "✅ Prerequisites met"
echo ""

# Run AppExchange scan (HTML format)
echo "📊 Running AppExchange scan (HTML)..."
sf scanner run \
  --target "force-app/" \
  --rule-selector "AppExchange" \
  --rule-selector "Recommended:Security" \
  --format "html" \
  --outfile "scanner-reports/code-analyzer-appexchange.html" \
  --severity-threshold 2 || echo "⚠️  AppExchange scan found issues (see HTML report)"

echo ""

# Run AppExchange scan (JSON format)
echo "📊 Running AppExchange scan (JSON)..."
sf scanner run \
  --target "force-app/" \
  --rule-selector "AppExchange" \
  --rule-selector "Recommended:Security" \
  --format "json" \
  --outfile "scanner-reports/code-analyzer-appexchange.json" || true

echo ""

# Run AppExchange scan (Table format for console)
echo "📊 Running AppExchange scan (Table)..."
sf scanner run \
  --target "force-app/" \
  --rule-selector "AppExchange" \
  --rule-selector "Recommended:Security" \
  --format "table" \
  --severity-threshold 2 || echo "⚠️  Review scanner reports for details"

echo ""
echo "=================================="
echo "✅ Scanner reports generated:"
echo "   - scanner-reports/code-analyzer-appexchange.html"
echo "   - scanner-reports/code-analyzer-appexchange.json"
echo "=================================="
echo ""
echo "Next steps:"
echo "  1. Review the HTML report: open scanner-reports/code-analyzer-appexchange.html"
echo "  2. Address any High/Critical findings"
echo "  3. Document false positives in docs/SCANNER_FALSE_POSITIVES.md"
echo ""
