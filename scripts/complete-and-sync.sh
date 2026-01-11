#!/bin/bash
# Complete and Sync Workflow
# Automates: commit, push to feature branch, merge to main, push main

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

if [ -z "$CURRENT_BRANCH" ]; then
    echo "Error: Not on any branch"
    exit 1
fi

# Check if we're on main
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo -e "${YELLOW}Warning: You're on main branch. This script is for feature branches.${NC}"
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
    echo "Error: Commit message is required"
    exit 1
fi

# Get merge message
if [ -z "$2" ]; then
    MERGE_MSG="Merge feature branch: $COMMIT_MSG"
else
    MERGE_MSG="$2"
fi

echo -e "${BLUE}=== Complete and Sync Workflow ===${NC}"
echo -e "Branch: ${GREEN}$CURRENT_BRANCH${NC}"
echo -e "Commit message: ${GREEN}$COMMIT_MSG${NC}"
echo ""

# Step 1: Check for changes
if git diff --quiet && git diff --cached --quiet; then
    echo -e "${YELLOW}No changes to commit${NC}"
else
    echo -e "${BLUE}Step 1: Staging changes...${NC}"
    git add .
    
    echo -e "${BLUE}Step 2: Committing changes...${NC}"
    git commit -m "$COMMIT_MSG"
    echo -e "${GREEN}✓ Committed locally${NC}"
fi

# Step 3: Push to feature branch
echo -e "${BLUE}Step 3: Pushing to remote feature branch...${NC}"
git push origin "$CURRENT_BRANCH"
echo -e "${GREEN}✓ Pushed to origin/$CURRENT_BRANCH${NC}"

# Step 4: Merge to main
echo -e "${BLUE}Step 4: Merging to main...${NC}"
git checkout main
git pull origin main

# Check if merge is needed
if git merge-base --is-ancestor "$CURRENT_BRANCH" main; then
    echo -e "${YELLOW}Feature branch is already merged into main${NC}"
else
    git merge "$CURRENT_BRANCH" --no-ff -m "$MERGE_MSG"
    echo -e "${GREEN}✓ Merged to main${NC}"
    
    # Step 5: Push main
    echo -e "${BLUE}Step 5: Pushing main to remote...${NC}"
    git push origin main
    echo -e "${GREEN}✓ Pushed main to origin/main${NC}"
fi

# Step 6: Return to feature branch
echo -e "${BLUE}Step 6: Returning to feature branch...${NC}"
git checkout "$CURRENT_BRANCH"
echo -e "${GREEN}✓ Returned to $CURRENT_BRANCH${NC}"

echo ""
echo -e "${GREEN}=== Workflow Complete ===${NC}"
echo -e "All changes committed, pushed, and merged to main!"
