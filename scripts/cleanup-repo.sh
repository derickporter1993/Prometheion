#!/bin/bash

# GitHub Repository Cleanup Script
# This script removes unnecessary files and directories from the repository

set -e  # Exit on error

echo "🧹 Starting GitHub repository cleanup..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to safely remove files
remove_file() {
    if [ -f "$1" ]; then
        echo -e "${YELLOW}Removing:${NC} $1"
        rm -f "$1"
        echo -e "${GREEN}✓ Removed${NC}"
    else
        echo -e "${RED}✗ Not found:${NC} $1"
    fi
}

# Function to safely remove directories
remove_dir() {
    if [ -d "$1" ]; then
        echo -e "${YELLOW}Removing directory:${NC} $1"
        rm -rf "$1"
        echo -e "${GREEN}✓ Removed${NC}"
    else
        echo -e "${RED}✗ Not found:${NC} $1"
    fi
}

# Confirm before proceeding
echo "This script will remove:"
echo "  - ZIP files (build artifacts)"
echo "  - Temporary documentation files"
echo "  - Legacy Sentinel-main directory (if confirmed)"
echo ""
read -p "Do you want to continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "📦 Removing ZIP files..."
echo "=========================="

# Remove ZIP files from root
ZIP_FILES=(
    "OpsGuardian_Pretty_CI_PR_Patch.zip"
    "OpsGuardian_Quality_Security_Pack.zip"
    "OpsGuardian_PR_Pack_Nov-02-2025.zip"
    "OpsGuardian_Release_Automation_Pack.zip"
    "OpsGuardian_Pretty_Extras.zip"
    "OpsGuardian_Prettier_Fix_Pack.zip"
)

for zip_file in "${ZIP_FILES[@]}"; do
    remove_file "$zip_file"
done

# Remove ZIP files from Sentinel-main (if it exists)
if [ -d "Sentinel-main" ]; then
    echo ""
    echo "Removing ZIP files from Sentinel-main..."
    for zip_file in "${ZIP_FILES[@]}"; do
        remove_file "Sentinel-main/$zip_file"
    done
    # Sentinel-main has an additional file
    remove_file "Sentinel-main/OpsGuardian_Quality_Security_Pack.zip"
fi

echo ""
echo "📄 Removing temporary documentation..."
echo "======================================"

# Remove temporary documentation files
remove_file "FAILED_PRS_SUMMARY.md"

# Remove from Sentinel-main if it exists
if [ -d "Sentinel-main" ]; then
    remove_file "Sentinel-main/FAILED_PRS_SUMMARY.md"
fi

# Remove from docs/history if it exists
remove_file "docs/history/FAILED_PRS_SUMMARY.md"

echo ""
echo "🗂️  Checking for legacy directories..."
echo "======================================="

# Check if Sentinel-main directory should be removed
if [ -d "Sentinel-main" ]; then
    echo -e "${YELLOW}Found:${NC} Sentinel-main/ directory"
    echo "This appears to be a legacy/duplicate directory."
    echo ""
    read -p "Remove Sentinel-main directory? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        remove_dir "Sentinel-main"
        echo -e "${GREEN}✓ Sentinel-main directory removed${NC}"
    else
        echo -e "${YELLOW}⚠ Keeping Sentinel-main directory${NC}"
    fi
else
    echo -e "${GREEN}✓ No Sentinel-main directory found${NC}"
fi

echo ""
echo "🔍 Checking for other temporary files..."
echo "========================================"

# Look for other temporary files
find . -name "*_TEMP.md" -o -name "*_ANALYSIS.md" -o -name "*_SUMMARY.md" 2>/dev/null | while read -r file; do
    if [ -f "$file" ]; then
        echo -e "${YELLOW}Found temporary file:${NC} $file"
        read -p "Remove? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            remove_file "$file"
        fi
    fi
done

echo ""
echo "🔧 Post-cleanup tasks..."
echo "=========================="

# Update Jest configs if Sentinel-main was removed
if [ ! -d "Sentinel-main" ]; then
    echo "Updating Jest configuration files..."
    
    # Update jest.config.js
    if [ -f "jest.config.js" ]; then
        if grep -q "Sentinel-main" jest.config.js; then
            echo -e "${YELLOW}Updating jest.config.js...${NC}"
            # Remove Sentinel-main from ignore patterns
            sed -i.bak 's|, "<rootDir>/Sentinel-main/"||g' jest.config.js
            sed -i.bak 's|"<rootDir>/Sentinel-main/"||g' jest.config.js
            rm -f jest.config.js.bak
            echo -e "${GREEN}✓ Updated jest.config.js${NC}"
        fi
    fi
    
    # Update jest.config.cjs
    if [ -f "jest.config.cjs" ]; then
        if grep -q "Sentinel-main" jest.config.cjs; then
            echo -e "${YELLOW}Updating jest.config.cjs...${NC}"
            sed -i.bak 's|, "<rootDir>/Sentinel-main/"||g' jest.config.cjs
            sed -i.bak 's|"<rootDir>/Sentinel-main/"||g' jest.config.cjs
            rm -f jest.config.cjs.bak
            echo -e "${GREEN}✓ Updated jest.config.cjs${NC}"
        fi
    fi
fi

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "  1. Review changes: git status"
echo "  2. Stage removals: git add -u"
echo "  3. Stage config updates: git add jest.config.* .gitignore"
echo "  4. Commit: git commit -m 'chore: cleanup repository - remove ZIP files, temporary docs, and legacy Sentinel-main directory'"
echo "  5. Verify .gitignore is updated: cat .gitignore"
echo ""
