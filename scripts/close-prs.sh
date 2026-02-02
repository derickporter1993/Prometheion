#!/bin/bash
# Script to close all open pull requests in the Sentinel repository
# Usage: GITHUB_TOKEN=your_token ./scripts/close-prs.sh

REPO="derickporter1993/elaro"
PR_NUMBERS=(57 73 76 77 78 79 80)

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is required"
    echo "Get a token from: https://github.com/settings/tokens"
    echo "Required scope: 'repo' (full control of private repositories)"
    exit 1
fi

echo "Closing pull requests in $REPO..."
echo ""

for pr in "${PR_NUMBERS[@]}"; do
    echo "Closing PR #$pr..."
    response=$(curl -s -w "\n%{http_code}" -X PATCH \
        "https://api.github.com/repos/$REPO/pulls/$pr" \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -d '{"state":"closed"}')
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        title=$(echo "$body" | python3 -c "import sys, json; print(json.load(sys.stdin).get('title', 'N/A'))" 2>/dev/null)
        echo "  ✓ Closed: $title"
    else
        echo "  ✗ Failed (HTTP $http_code)"
        echo "$body" | python3 -c "import sys, json; err = json.load(sys.stdin); print(f\"    Error: {err.get('message', 'Unknown error')}\")" 2>/dev/null || echo "    Error: Unknown"
    fi
    echo ""
done

echo "Done! Verifying..."
open_count=$(curl -s "https://api.github.com/repos/$REPO/pulls?state=open" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" | \
    python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null)

echo "Open PRs remaining: $open_count"

