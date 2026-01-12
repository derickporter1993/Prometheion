#!/bin/bash
#
# sync-ai-commits.sh
#
# Gathers commits from AI assistants (Claude, Cursor, ChatGPT/OpenAI),
# merges them to main branch, and syncs all local/remote branches.
#
# Usage: ./scripts/sync-ai-commits.sh [options]
#
# Options:
#   --dry-run     Show what would be done without making changes
#   --force       Force push (use with caution)
#   --cleanup     Delete merged branches after sync
#   --target      Target branch (default: main)
#   --help        Show this help message

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
TARGET_BRANCH="main"
DRY_RUN=false
FORCE_PUSH=false
CLEANUP_BRANCHES=false

# AI patterns to search for in commits
AI_PATTERNS=(
    "claude"
    "Claude"
    "cursor"
    "Cursor"
    "chatgpt"
    "ChatGPT"
    "openai"
    "OpenAI"
    "GPT"
    "gpt-4"
    "gpt-3"
    "copilot"
    "Copilot"
)

# Branch patterns for AI-generated branches
AI_BRANCH_PATTERNS=(
    "claude/"
    "cursor/"
    "chatgpt/"
    "openai/"
    "ai/"
    "gpt/"
)

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

show_help() {
    cat << EOF
sync-ai-commits.sh - Sync AI assistant commits to main branch

USAGE:
    ./scripts/sync-ai-commits.sh [OPTIONS]

OPTIONS:
    --dry-run       Show what would be done without making changes
    --force         Force push to remote (use with caution)
    --cleanup       Delete merged branches after successful sync
    --target BRANCH Target branch to merge into (default: main)
    --help          Show this help message

EXAMPLES:
    # Preview what will be synced
    ./scripts/sync-ai-commits.sh --dry-run

    # Sync all AI commits to main
    ./scripts/sync-ai-commits.sh

    # Sync and cleanup merged branches
    ./scripts/sync-ai-commits.sh --cleanup

    # Sync to a different target branch
    ./scripts/sync-ai-commits.sh --target develop

SUPPORTED AI ASSISTANTS:
    - Claude (Anthropic)
    - Cursor
    - ChatGPT/OpenAI
    - GitHub Copilot

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE_PUSH=true
                shift
                ;;
            --cleanup)
                CLEANUP_BRANCHES=true
                shift
                ;;
            --target)
                TARGET_BRANCH="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

check_prerequisites() {
    log_header "Checking Prerequisites"

    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        log_error "Not inside a git repository"
        exit 1
    fi
    log_success "Git repository detected"

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_warn "You have uncommitted changes"
        git status --short
        echo ""
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborting. Please commit or stash your changes first."
            exit 1
        fi
    else
        log_success "Working tree is clean"
    fi

    # Check if target branch exists
    if ! git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
        log_error "Target branch '$TARGET_BRANCH' does not exist locally"
        exit 1
    fi
    log_success "Target branch '$TARGET_BRANCH' exists"
}

fetch_all_remotes() {
    log_header "Fetching All Remotes"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would fetch all remotes"
        return
    fi

    log_info "Fetching from all remotes..."
    git fetch --all --prune
    log_success "All remotes fetched"
}

find_ai_commits() {
    log_header "Finding AI Assistant Commits" >&2

    local pattern_string=""

    # Build grep pattern
    for pattern in "${AI_PATTERNS[@]}"; do
        if [ -z "$pattern_string" ]; then
            pattern_string="$pattern"
        else
            pattern_string="$pattern_string\|$pattern"
        fi
    done

    echo "Searching for commits matching: ${AI_PATTERNS[*]}" >&2

    # Find commits not in target branch
    local commits
    commits=$(git log --all --oneline --grep="$pattern_string" --not "$TARGET_BRANCH" 2>/dev/null || true)

    if [ -z "$commits" ]; then
        echo "No new AI commits found outside of $TARGET_BRANCH" >&2
    else
        echo "$commits" >&2
        echo "" >&2
        echo "Found $(echo "$commits" | wc -l | tr -d ' ') AI-related commits" >&2
    fi
}

find_ai_branches() {
    log_header "Finding AI-Related Branches" >&2

    local branches=()
    local remote_branches=()

    # Find local AI branches
    echo "Local AI branches:" >&2
    for pattern in "${AI_BRANCH_PATTERNS[@]}"; do
        local found
        found=$(git branch --list "*${pattern}*" 2>/dev/null | sed 's/^[ *]*//' || true)
        if [ -n "$found" ]; then
            echo "$found" >&2
            while IFS= read -r branch; do
                [ -n "$branch" ] && branches+=("$branch")
            done <<< "$found"
        fi
    done

    echo "" >&2

    # Find remote AI branches
    echo "Remote AI branches:" >&2
    for pattern in "${AI_BRANCH_PATTERNS[@]}"; do
        local found
        found=$(git branch -r --list "*${pattern}*" 2>/dev/null | sed 's/^[ ]*//' || true)
        if [ -n "$found" ]; then
            echo "$found" >&2
            while IFS= read -r branch; do
                [ -n "$branch" ] && remote_branches+=("$branch")
            done <<< "$found"
        fi
    done

    echo "" >&2
    echo "Found ${#branches[@]} local AI branches, ${#remote_branches[@]} remote AI branches" >&2

    # Output only the branch names (local first, then remote)
    for branch in "${branches[@]}"; do
        echo "$branch"
    done
    for branch in "${remote_branches[@]}"; do
        echo "$branch"
    done
}

merge_ai_branches() {
    log_header "Merging AI Branches to $TARGET_BRANCH"

    local branches=("$@")
    local current_branch
    current_branch=$(git branch --show-current)

    if [ ${#branches[@]} -eq 0 ]; then
        log_info "No AI branches to merge"
        return
    fi

    # Checkout target branch
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would checkout $TARGET_BRANCH"
    else
        log_info "Checking out $TARGET_BRANCH..."
        git checkout "$TARGET_BRANCH"
        git pull origin "$TARGET_BRANCH" --no-rebase 2>/dev/null || true
    fi

    local merged_branches=()
    local failed_branches=()

    for branch in "${branches[@]}"; do
        [ -z "$branch" ] && continue

        # Skip if it's the target branch
        if [ "$branch" = "$TARGET_BRANCH" ]; then
            continue
        fi

        log_info "Processing branch: $branch"

        # Check if branch has commits not in target
        local ahead
        ahead=$(git rev-list --count "$TARGET_BRANCH".."$branch" 2>/dev/null || echo "0")

        if [ "$ahead" -eq 0 ]; then
            log_info "  Branch $branch is already merged or has no new commits"
            merged_branches+=("$branch")
            continue
        fi

        log_info "  Branch has $ahead commit(s) ahead of $TARGET_BRANCH"

        if [ "$DRY_RUN" = true ]; then
            log_info "  [DRY-RUN] Would merge $branch into $TARGET_BRANCH"
            continue
        fi

        # Try to merge
        if git merge --no-ff "$branch" -m "merge: Integrate AI commits from $branch"; then
            log_success "  Successfully merged $branch"
            merged_branches+=("$branch")
        else
            log_error "  Failed to merge $branch - conflicts detected"
            git merge --abort 2>/dev/null || true
            failed_branches+=("$branch")
        fi
    done

    # Return to original branch if different
    if [ "$current_branch" != "$TARGET_BRANCH" ] && [ "$DRY_RUN" = false ]; then
        git checkout "$current_branch" 2>/dev/null || true
    fi

    echo ""
    log_info "Merge Summary:"
    log_success "  Merged: ${#merged_branches[@]} branches"
    if [ ${#failed_branches[@]} -gt 0 ]; then
        log_error "  Failed: ${#failed_branches[@]} branches"
        for branch in "${failed_branches[@]}"; do
            log_error "    - $branch"
        done
    fi
}

push_to_remote() {
    log_header "Pushing to Remote"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would push $TARGET_BRANCH to origin"
        return
    fi

    log_info "Pushing $TARGET_BRANCH to origin..."

    local push_args="-u origin $TARGET_BRANCH"
    if [ "$FORCE_PUSH" = true ]; then
        push_args="--force $push_args"
        log_warn "Force pushing enabled"
    fi

    # Retry logic with exponential backoff
    local max_retries=4
    local retry_count=0
    local wait_time=2

    while [ $retry_count -lt $max_retries ]; do
        if git push $push_args; then
            log_success "Successfully pushed to origin/$TARGET_BRANCH"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                log_warn "Push failed, retrying in ${wait_time}s... (attempt $retry_count/$max_retries)"
                sleep $wait_time
                wait_time=$((wait_time * 2))
            fi
        fi
    done

    log_error "Failed to push after $max_retries attempts"
    return 1
}

sync_all_branches() {
    log_header "Syncing All Branches"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would sync all local branches with their remotes"
        return
    fi

    local current_branch
    current_branch=$(git branch --show-current)

    # Get all local branches that have remote tracking
    local branches
    branches=$(git branch -vv | grep '\[origin/' | awk '{print $1}' | sed 's/^\*//')

    for branch in $branches; do
        [ -z "$branch" ] && continue

        log_info "Syncing branch: $branch"

        git checkout "$branch" 2>/dev/null || continue

        # Pull latest changes
        if git pull origin "$branch" --no-rebase 2>/dev/null; then
            log_success "  Synced $branch"
        else
            log_warn "  Could not sync $branch (may have conflicts)"
        fi
    done

    # Return to original branch
    git checkout "$current_branch" 2>/dev/null || true
}

cleanup_merged_branches() {
    log_header "Cleaning Up Merged Branches"

    if [ "$CLEANUP_BRANCHES" = false ]; then
        log_info "Cleanup not requested (use --cleanup to enable)"
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would delete merged AI branches"
        return
    fi

    local deleted_count=0

    # Find merged branches
    local merged_branches
    merged_branches=$(git branch --merged "$TARGET_BRANCH" | grep -v "^\*" | grep -v "$TARGET_BRANCH")

    for branch in $merged_branches; do
        branch=$(echo "$branch" | tr -d ' ')
        [ -z "$branch" ] && continue

        # Check if it's an AI branch
        local is_ai_branch=false
        for pattern in "${AI_BRANCH_PATTERNS[@]}"; do
            if [[ "$branch" == *"$pattern"* ]]; then
                is_ai_branch=true
                break
            fi
        done

        if [ "$is_ai_branch" = true ]; then
            log_info "Deleting merged branch: $branch"

            # Delete local branch
            if git branch -d "$branch" 2>/dev/null; then
                log_success "  Deleted local: $branch"
                deleted_count=$((deleted_count + 1))
            fi

            # Try to delete remote branch (may fail due to permissions)
            if git push origin --delete "$branch" 2>/dev/null; then
                log_success "  Deleted remote: origin/$branch"
            else
                log_warn "  Could not delete remote: origin/$branch (permission denied)"
            fi
        fi
    done

    log_info "Deleted $deleted_count merged AI branches"
}

generate_report() {
    log_header "Sync Report"

    echo "Repository: $(basename "$(git rev-parse --show-toplevel)")"
    echo "Target Branch: $TARGET_BRANCH"
    echo "Current Commit: $(git rev-parse --short HEAD)"
    echo "Timestamp: $(date)"
    echo ""

    echo "Branch Status:"
    git branch -vv
    echo ""

    echo "Recent Commits on $TARGET_BRANCH:"
    git log --oneline -10 "$TARGET_BRANCH"
    echo ""

    # Check if local is synced with remote
    local local_commit
    local remote_commit
    local_commit=$(git rev-parse "$TARGET_BRANCH")
    remote_commit=$(git rev-parse "origin/$TARGET_BRANCH" 2>/dev/null || echo "unknown")

    if [ "$local_commit" = "$remote_commit" ]; then
        log_success "Local and remote $TARGET_BRANCH are in sync"
    else
        log_warn "Local and remote $TARGET_BRANCH may be out of sync"
        echo "  Local:  $local_commit"
        echo "  Remote: $remote_commit"
    fi
}

main() {
    parse_args "$@"

    log_header "AI Commits Sync Script"

    if [ "$DRY_RUN" = true ]; then
        log_warn "Running in DRY-RUN mode - no changes will be made"
    fi

    check_prerequisites
    fetch_all_remotes

    # Find AI commits and branches
    local ai_commits
    ai_commits=$(find_ai_commits)

    local ai_branches
    mapfile -t ai_branches < <(find_ai_branches)

    # Merge AI branches
    merge_ai_branches "${ai_branches[@]}"

    # Push to remote
    push_to_remote

    # Sync all branches
    sync_all_branches

    # Cleanup if requested
    cleanup_merged_branches

    # Generate final report
    generate_report

    log_header "Sync Complete"
    log_success "All AI commits have been processed"
}

# Run main function
main "$@"
