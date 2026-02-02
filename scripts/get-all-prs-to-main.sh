#!/bin/bash
# Script to get all pull requests targeting the main branch
# Usage: ./scripts/get-all-prs-to-main.sh [state]
# state: open, closed, all (default: all)

REPO="derickporter1993/Elaro"
STATE="${1:-all}"

# Show help
if [[ "$STATE" == "-h" || "$STATE" == "--help" ]]; then
    echo "Get all pull requests to main branch"
    echo ""
    echo "Usage: $0 [state]"
    echo ""
    echo "Arguments:"
    echo "  state    Filter PRs by state: open, closed, all (default: all)"
    echo ""
    echo "Examples:"
    echo "  $0           # Get all PRs (open and closed)"
    echo "  $0 open      # Get only open PRs"
    echo "  $0 closed    # Get only closed PRs"
    echo ""
    echo "Requirements:"
    echo "  - GitHub CLI (gh) installed and authenticated, OR"
    echo "  - GITHUB_TOKEN environment variable set"
    exit 0
fi

# Validate state parameter
if [[ ! "$STATE" =~ ^(open|closed|all)$ ]]; then
    echo "Error: Invalid state '$STATE'"
    echo "Usage: $0 [state]"
    echo "  state: open, closed, all (default: all)"
    echo "Run '$0 --help' for more information"
    exit 1
fi

echo "🔍 Fetching pull requests to main branch..."
echo "Repository: $REPO"
echo "State: $STATE"
echo ""

# Function to format PR output with jq (for gh CLI)
format_pr_jq() {
    jq -r '.[] | "PR #\(.number) - \(.state)\n  Title: \(.title)\n  Author: \(.author.login)\n  Created: \(.createdAt)\n  Updated: \(.updatedAt)\n"'
}

# Function to format PR output with Python (for GitHub API)
format_pr_python() {
    python3 -c "
import sys, json
try:
    prs = json.load(sys.stdin)
    for pr in prs:
        print(f\"PR #{pr['number']} - {pr['state'].upper()}\")
        print(f\"  Title: {pr['title']}\")
        print(f\"  Author: {pr['user']['login']}\")
        print(f\"  Created: {pr['created_at']}\")
        print(f\"  Updated: {pr['updated_at']}\")
        print()
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
"
}

# Check if gh CLI is available
if command -v gh &> /dev/null; then
    # Use gh CLI (preferred method)
    echo "📊 Pull Requests:"
    echo "=================================="
    
    if [ "$STATE" = "all" ]; then
        # Get both open and closed PRs
        gh pr list --repo "$REPO" --base main --state open --limit 100 --json number,title,author,state,createdAt,updatedAt | format_pr_jq
        gh pr list --repo "$REPO" --base main --state closed --limit 100 --json number,title,author,state,createdAt,updatedAt | format_pr_jq
    else
        # Get PRs with specific state
        gh pr list --repo "$REPO" --base main --state "$STATE" --limit 100 --json number,title,author,state,createdAt,updatedAt | format_pr_jq
    fi
    
    # Get count
    if [ "$STATE" = "all" ]; then
        OPEN_COUNT=$(gh pr list --repo "$REPO" --base main --state open --limit 100 --json number | jq '. | length')
        CLOSED_COUNT=$(gh pr list --repo "$REPO" --base main --state closed --limit 100 --json number | jq '. | length')
        echo "=================================="
        echo "Summary:"
        echo "  Open PRs: $OPEN_COUNT"
        echo "  Closed PRs: $CLOSED_COUNT"
        echo "  Total PRs: $((OPEN_COUNT + CLOSED_COUNT))"
    else
        COUNT=$(gh pr list --repo "$REPO" --base main --state "$STATE" --limit 100 --json number | jq '. | length')
        echo "=================================="
        echo "Total $STATE PRs: $COUNT"
    fi
    
elif [ -n "$GITHUB_TOKEN" ]; then
    # Fallback to curl with GitHub API (requires Python 3 for JSON parsing)
    echo "Using GitHub API (GITHUB_TOKEN)..."
    
    # Check if Python 3 is available
    if ! command -v python3 &> /dev/null; then
        echo "Error: Python 3 is required for GitHub API fallback but not found"
        echo "Please install Python 3 or use GitHub CLI instead"
        exit 1
    fi
    
    if [ "$STATE" = "all" ]; then
        # Fetch both open and closed
        OPEN_COUNT=0
        CLOSED_COUNT=0
        
        for current_state in open closed; do
            response=$(curl -s "https://api.github.com/repos/$REPO/pulls?state=$current_state&base=main&per_page=100" \
                -H "Authorization: token $GITHUB_TOKEN" \
                -H "Accept: application/vnd.github.v3+json")
            
            echo "$response" | format_pr_python
            
            # Count PRs
            if [ "$current_state" = "open" ]; then
                OPEN_COUNT=$(echo "$response" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))")
            else
                CLOSED_COUNT=$(echo "$response" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))")
            fi
        done
        
        # Print summary
        echo "=================================="
        echo "Summary:"
        echo "  Open PRs: $OPEN_COUNT"
        echo "  Closed PRs: $CLOSED_COUNT"
        echo "  Total PRs: $((OPEN_COUNT + CLOSED_COUNT))"
    else
        response=$(curl -s "https://api.github.com/repos/$REPO/pulls?state=$STATE&base=main&per_page=100" \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json")
        
        echo "$response" | format_pr_python
        
        # Print summary
        echo "=================================="
        COUNT=$(echo "$response" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))")
        echo "Total $STATE PRs: $COUNT"
    fi
else
    echo "Error: Neither 'gh' CLI nor GITHUB_TOKEN environment variable is available"
    echo ""
    echo "Please either:"
    echo "  1. Install GitHub CLI: https://cli.github.com/"
    echo "  2. Set GITHUB_TOKEN environment variable with a GitHub personal access token"
    echo "     Get a token from: https://github.com/settings/tokens"
    echo ""
    echo "Note: GitHub API fallback also requires Python 3 for JSON parsing"
    exit 1
fi
