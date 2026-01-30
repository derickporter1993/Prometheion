#!/bin/bash
# Monitor CI and auto-merge PR when all checks pass

set -e

PR_NUMBER=102
MAX_WAIT_MINUTES=30
CHECK_INTERVAL=30  # seconds
TAG_VERSION="v1.0.0-phase1"

echo "🚀 PR Monitor & Auto-Merge Script"
echo "=================================="
echo "PR: #${PR_NUMBER}"
echo "Max wait: ${MAX_WAIT_MINUTES} minutes"
echo "Check interval: ${CHECK_INTERVAL} seconds"
echo ""

# Function to check CI status
check_ci_status() {
    gh pr checks ${PR_NUMBER} --json name,state,conclusion 2>/dev/null | jq -r '.[] | "\(.name)|\(.state)|\(.conclusion // "null")"'
}

# Function to get all check statuses
get_all_statuses() {
    check_ci_status | cut -d'|' -f2
}

# Function to get all conclusions
get_all_conclusions() {
    check_ci_status | cut -d'|' -f3
}

# Function to check if all checks are complete
all_checks_complete() {
    local statuses=$(get_all_statuses)
    local has_pending=$(echo "$statuses" | grep -c "PENDING\|QUEUED" || true)
    [ "$has_pending" -eq 0 ] && [ -n "$statuses" ]
}

# Function to check if all checks passed
all_checks_passed() {
    local conclusions=$(get_all_conclusions)
    local has_failure=$(echo "$conclusions" | grep -v "SUCCESS\|null" | grep -v "^$" | wc -l || true)
    [ "$has_failure" -eq 0 ] && [ -n "$(echo "$conclusions" | grep "SUCCESS")" ]
}

# Function to display current status
display_status() {
    echo ""
    echo "📊 Current CI Status ($(date '+%H:%M:%S')):"
    echo "----------------------------------------"
    check_ci_status | while IFS='|' read -r name state conclusion; do
        case "$state" in
            "COMPLETED")
                if [ "$conclusion" = "SUCCESS" ]; then
                    echo "  ✅ $name: PASSED"
                else
                    echo "  ❌ $name: FAILED ($conclusion)"
                fi
                ;;
            "IN_PROGRESS")
                echo "  🔄 $name: RUNNING"
                ;;
            "QUEUED"|"PENDING")
                echo "  ⏳ $name: QUEUED"
                ;;
            *)
                echo "  ⚠️  $name: $state ($conclusion)"
                ;;
        esac
    done
    echo ""
}

# Initial status check
echo "🔍 Initial CI Status:"
display_status

# Wait for checks to complete
echo "⏳ Waiting for CI checks to complete..."
start_time=$(date +%s)
max_wait_seconds=$((MAX_WAIT_MINUTES * 60))

while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [ $elapsed -ge $max_wait_seconds ]; then
        echo "⏰ Timeout: Waited ${MAX_WAIT_MINUTES} minutes"
        echo "❌ CI checks did not complete in time"
        exit 1
    fi
    
    if all_checks_complete; then
        echo "✅ All CI checks completed!"
        display_status
        break
    fi
    
    # Show progress every minute
    if [ $((elapsed % 60)) -eq 0 ] && [ $elapsed -gt 0 ]; then
        echo "⏳ Still waiting... ($((elapsed / 60))m elapsed)"
        display_status
    fi
    
    sleep $CHECK_INTERVAL
done

# Check if all passed
if all_checks_passed; then
    echo "🎉 All CI checks passed!"
    echo ""
    
    # Confirm merge
    echo "📝 Ready to merge PR #${PR_NUMBER}"
    echo "   This will:"
    echo "   1. Squash merge to main"
    echo "   2. Delete branch phase-1-core-infrastructure"
    echo "   3. Tag release as ${TAG_VERSION}"
    echo ""
    read -p "Continue with merge? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Merge PR
        echo "🔄 Merging PR #${PR_NUMBER}..."
        gh pr merge ${PR_NUMBER} --squash --delete-branch
        
        # Switch to main and pull
        echo "📥 Switching to main and pulling latest..."
        git checkout main
        git pull origin main
        
        # Tag release
        echo "🏷️  Tagging release ${TAG_VERSION}..."
        git tag ${TAG_VERSION}
        git push --tags
        
        echo ""
        echo "✅ Success!"
        echo "   PR merged: https://github.com/derickporter1993/Elaro/pull/${PR_NUMBER}"
        echo "   Release tagged: ${TAG_VERSION}"
        echo "   Branch deleted: phase-1-core-infrastructure"
    else
        echo "❌ Merge cancelled by user"
        exit 0
    fi
else
    echo "❌ Some CI checks failed!"
    display_status
    echo ""
    echo "Please review the failed checks:"
    gh pr view ${PR_NUMBER} --web
    exit 1
fi
