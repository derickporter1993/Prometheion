#!/bin/bash
# Sync All - Complete Git Workflow Automation
# Usage: ./scripts/sync-all.sh [commit-message] [merge-message]

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

if [ -z "$CURRENT_BRANCH" ]; then
    echo -e "${RED}Error: Not on any branch${NC}"
    exit 1
fi

# Check if we're on main
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo -e "${YELLOW}Warning: You're on main branch.${NC}"
    echo -e "${YELLOW}This script is designed for feature branches.${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get commit message
if [ -z "$1" ]; then
    echo -e "${BLUE}Enter commit message:${NC}"
    read -r COMMIT_MSG
else
    COMMIT_MSG="$1"
fi

if [ -z "$COMMIT_MSG" ]; then
    echo -e "${RED}Error: Commit message is required${NC}"
    exit 1
fi

# Get merge message
if [ -z "$2" ]; then
    MERGE_MSG="Merge feature branch: $COMMIT_MSG"
else
    MERGE_MSG="$2"
fi

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Sync All - Complete Git Workflow   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "Branch: ${GREEN}$CURRENT_BRANCH${NC}"
echo -e "Commit: ${GREEN}$COMMIT_MSG${NC}"
echo -e "Merge:  ${GREEN}$MERGE_MSG${NC}"
echo ""

# Step 1: Check for changes
if git diff --quiet && git diff --cached --quiet; then
    echo -e "${YELLOW}⚠ No changes to commit${NC}"
    SKIP_COMMIT=true
else
    SKIP_COMMIT=false
    echo -e "${BLUE}[1/5] Staging changes...${NC}"
    git add .
    
    echo -e "${BLUE}[2/5] Committing changes...${NC}"
    git commit -m "$COMMIT_MSG"
    echo -e "${GREEN}✓ Committed locally${NC}"
fi

# Step 3: Push to feature branch
echo -e "${BLUE}[3/5] Pushing to remote feature branch...${NC}"
if [ "$SKIP_COMMIT" = false ]; then
    git push origin "$CURRENT_BRANCH"
else
    # Even if no commit, check if we need to push
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
    if [ -z "$REMOTE" ] || [ "$LOCAL" != "$REMOTE" ]; then
        git push origin "$CURRENT_BRANCH"
    else
        echo -e "${YELLOW}⚠ Feature branch already up to date${NC}"
    fi
fi
echo -e "${GREEN}✓ Pushed to origin/$CURRENT_BRANCH${NC}"

# Step 4: Merge to main
echo -e "${BLUE}[4/5] Merging to main...${NC}"
git checkout main
git pull origin main

# Check if merge is needed
if git merge-base --is-ancestor "$CURRENT_BRANCH" main 2>/dev/null; then
    echo -e "${YELLOW}⚠ Feature branch is already merged into main${NC}"
else
    git merge "$CURRENT_BRANCH" --no-ff -m "$MERGE_MSG"
    echo -e "${GREEN}✓ Merged to main${NC}"
    
    # Step 5: Push main
    echo -e "${BLUE}[5/5] Pushing main to remote...${NC}"
    git push origin main
    echo -e "${GREEN}✓ Pushed main to origin/main${NC}"
fi

# Step 6: Return to feature branch
echo -e "${BLUE}Returning to feature branch...${NC}"
git checkout "$CURRENT_BRANCH"
echo -e "${GREEN}✓ Returned to $CURRENT_BRANCH${NC}"

# Verification
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Verification Status           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

FEATURE_AHEAD=$(git rev-list --count origin/$CURRENT_BRANCH..$CURRENT_BRANCH 2>/dev/null || echo "0")
FEATURE_BEHIND=$(git rev-list --count $CURRENT_BRANCH..origin/$CURRENT_BRANCH 2>/dev/null || echo "0")

git checkout main > /dev/null 2>&1
MAIN_AHEAD=$(git rev-list --count origin/main..main 2>/dev/null || echo "0")
MAIN_BEHIND=$(git rev-list --count main..origin/main 2>/dev/null || echo "0")
git checkout $CURRENT_BRANCH > /dev/null 2>&1

if [ "$FEATURE_AHEAD" = "0" ] && [ "$FEATURE_BEHIND" = "0" ]; then
    echo -e "Feature branch: ${GREEN}✓ Synced${NC}"
else
    echo -e "Feature branch: ${YELLOW}⚠ Ahead: $FEATURE_AHEAD, Behind: $FEATURE_BEHIND${NC}"
fi

if [ "$MAIN_AHEAD" = "0" ] && [ "$MAIN_BEHIND" = "0" ]; then
    echo -e "Main branch:    ${GREEN}✓ Synced${NC}"
else
    echo -e "Main branch:    ${YELLOW}⚠ Ahead: $MAIN_AHEAD, Behind: $MAIN_BEHIND${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✓ All branches synchronized!      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
