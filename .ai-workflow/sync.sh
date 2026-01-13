#!/bin/bash
# AI Workflow Orchestration Script

STATE_FILE="$HOME/.ai-state/workflow-state.json"
BACKLOG_FILE=".ai-workflow/backlog.md"
CURRENT_FILE=".ai-workflow/current-task.md"
VALIDATION_FILE=".ai-workflow/validation-results.md"
COMPLETED_FILE=".ai-workflow/completed-tasks.md"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_status() {
    echo -e "${YELLOW}=== Workflow Status ===${NC}"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        echo -e "${RED}State file not found${NC}"
        return 1
    fi
    
    local current=$(jq -r '.current_task // "none"' "$STATE_FILE")
    local owner=$(jq -r '.active_owner // "none"' "$STATE_FILE")
    local completed=$(jq -r '.completed_count' "$STATE_FILE")
    local total=$(jq -r '.total_count' "$STATE_FILE")
    local phase=$(jq -r '.phase' "$STATE_FILE")
    
    echo -e "Phase: ${BLUE}${phase}${NC}"
    echo -e "Progress: ${GREEN}${completed}/${total}${NC} tasks complete"
    echo -e "Active Task: ${YELLOW}${current}${NC}"
    echo -e "Active Owner: ${YELLOW}${owner}${NC}"
    
    if [[ -f "$CURRENT_FILE" ]] && [[ "$current" != "none" ]] && [[ "$current" != "null" ]]; then
        echo ""
        echo -e "${YELLOW}Current Task Details:${NC}"
        head -n 20 "$CURRENT_FILE"
    fi
}

load_next() {
    echo -e "${YELLOW}Loading next task from queue...${NC}"
    
    local next_id=$(jq -r '.queue[0] // "none"' "$STATE_FILE")
    
    if [[ "$next_id" == "none" ]] || [[ "$next_id" == "null" ]]; then
        echo -e "${GREEN}🎉 All tasks complete!${NC}"
        return 0
    fi
    
    # Extract task details from backlog
    local task_section=$(sed -n "/## ${next_id}:/,/^## /p" "$BACKLOG_FILE" | sed '$d')
    
    # Write to current-task.md
    cat > "$CURRENT_FILE" << EOF
# Current Task: ${next_id}
**Loaded:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")

${task_section}

---
## Handoff Instructions

### For Claude Code (Design Phase):
1. Read task requirements above
2. Design solution following repo patterns
3. Create handoff document with:
   - Files to modify/create
   - Exact changes required
   - Validation steps
4. Update ~/.ai-state/workflow-state.json:
   - Set active_owner to "cursor"
   - Add handoff details

### For Cursor (Implementation Phase):
1. Read design from current-task.md
2. Implement changes following handoff instructions
3. Run validation steps
4. Update validation-results.md with results
5. Run: .ai-workflow/sync.sh complete

EOF
    
    # Update JSON state
    local updated_state=$(jq --arg task "$next_id" --arg time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '.current_task = $task | .last_updated = $time | .queue |= .[1:]' "$STATE_FILE")
    echo "$updated_state" > "$STATE_FILE"
    
    echo -e "${GREEN}✅ Loaded: ${next_id}${NC}"
    echo "View details: cat $CURRENT_FILE"
}

mark_complete() {
    local current=$(jq -r '.current_task' "$STATE_FILE")
    
    if [[ "$current" == "null" ]] || [[ "$current" == "none" ]]; then
        echo -e "${RED}No active task to complete${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Marking ${current} as complete...${NC}"
    
    # Append to completed tasks
    echo "" >> "$COMPLETED_FILE"
    echo "## ${current} - Completed $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$COMPLETED_FILE"
    cat "$CURRENT_FILE" >> "$COMPLETED_FILE"
    
    # Copy validation results for this task
    if grep -q "## ${current}:" "$VALIDATION_FILE" 2>/dev/null; then
        echo "" >> "$COMPLETED_FILE"
        echo "### Validation Results" >> "$COMPLETED_FILE"
        sed -n "/## ${current}:/,/^## /p" "$VALIDATION_FILE" | sed '$d' >> "$COMPLETED_FILE"
    fi
    
    echo "---" >> "$COMPLETED_FILE"
    
    # Update JSON state
    local updated_state=$(jq '.completed_count += 1 | .current_task = null | .active_owner = null | .handoff = null' "$STATE_FILE")
    echo "$updated_state" > "$STATE_FILE"
    
    # Clear current task
    > "$CURRENT_FILE"
    
    echo -e "${GREEN}✅ Task complete!${NC}"
    echo ""
    
    # Auto-load next
    load_next
}

case "$1" in
    status)
        show_status
        ;;
    next|load)
        load_next
        ;;
    complete|done)
        mark_complete
        ;;
    *)
        echo "Usage: $0 {status|next|complete}"
        echo ""
        echo "  status   - Show current workflow state"
        echo "  next     - Load next task from queue"
        echo "  complete - Mark current task done and load next"
        exit 1
        ;;
esac
