# 🚀 AI Workflow Quick Start

## Setup Complete ✅
Your 3-tier state system is now operational!

## Current Status
- **Phase:** Phase 1 (Backend + Frontend fixes)
- **Total Tasks:** 9
- **Active Task:** backend-001 (Create TriggerRecursionGuard.cls)
- **Progress:** 0/9 complete

## Commands You'll Use Daily

### Check what's active:
```bash
.ai-workflow/sync.sh status
```

### Load next task:
```bash
.ai-workflow/sync.sh next
```

### Mark current task done:
```bash
.ai-workflow/sync.sh complete
```

## AI Startup Prompts

### 🤖 Claude Code (Design Phase)
Copy this into your first message:

```
You're starting a new session. Sync workflow context:

1. Read .ai-workflow/current-task.md
2. Read ~/.ai-state/workflow-state.json
3. Summarize the active task and your role
4. If you're the design owner, proceed with design
5. After design: update workflow state with handoff to Cursor
```

### 🎯 Cursor (Implementation Phase)
Copy this into your first message:

```
You're starting a new session. Sync workflow context:

1. Read .ai-workflow/current-task.md
2. Read ~/.ai-state/workflow-state.json
3. Check if active_owner is "cursor" and handoff is present
4. If yes: implement following the handoff instructions
5. After validation: update validation-results.md and run sync.sh complete
```

## Expected Flow

### Step 1: Claude Code Designs
- Reads current task from `.ai-workflow/current-task.md`
- Designs solution following repo patterns
- Writes implementation details to current-task.md
- Updates workflow state: `active_owner = "cursor"`

### Step 2: Cursor Implements
- Reads design from current-task.md
- Creates/modifies files as specified
- Runs validation (compile + tests)
- Updates validation-results.md
- Runs: `.ai-workflow/sync.sh complete`

### Step 3: Auto-Load Next
- Sync script archives completed task
- Loads next task from queue
- Ready for Claude Code to design

## Files to Watch

- `.ai-workflow/current-task.md` - What you're working on now
- `.ai-workflow/backlog.md` - All pending tasks
- `.ai-workflow/completed-tasks.md` - Historical record
- `.ai-workflow/validation-results.md` - Test outcomes
- `~/.ai-state/workflow-state.json` - Machine state

## Success Metrics

### After each task, you should have:
1. ✅ Design documented in current-task.md
2. ✅ Implementation completed and validated
3. ✅ Validation results recorded
4. ✅ Git commit with structured message
5. ✅ Task marked complete in system

### Check progress anytime:
```bash
# See what's done
cat .ai-workflow/completed-tasks.md

# See validation history
cat .ai-workflow/validation-results.md

# See commit trail
git log --grep="feat(" --oneline
```

## Troubleshooting

### "I don't know what to work on"
→ Run: `.ai-workflow/sync.sh status`

### "Task seems stuck"
→ Check: `cat ~/.ai-state/workflow-state.json`
→ Look for `active_owner` field

### "Need to skip a task"
→ Edit: `~/.ai-state/workflow-state.json`
→ Remove task ID from `queue` array

## Next Steps

### Right Now:
1. Open Claude Code
2. Give it the startup prompt above
3. Let it design backend-001 (TriggerRecursionGuard)

### After Design Complete:
1. Open Cursor
2. Give it the startup prompt above
3. Let it implement the design

### After Implementation:
1. Cursor runs validation
2. Cursor updates validation-results.md
3. Cursor runs: `.ai-workflow/sync.sh complete`
4. System auto-loads backend-002

## Time Investment

- **Setup:** 15 minutes (DONE ✅)
- **Per Task Overhead:** <1 minute
- **Time Saved:** ~5 minutes per task (no manual context switching)
- **ROI for Phase 1:** 30 minutes saved (9 tasks × 5 min - 15 min setup)

## Pro Tips

### Add shell alias:
```bash
echo "alias ws='cd ~/path/to/elaro && .ai-workflow/sync.sh status'" >> ~/.zshrc
source ~/.zshrc
```

Now just type `ws` from anywhere to check workflow status!

### Commit template:
```bash
git commit -m "feat(backend-001): implement TriggerRecursionGuard

Static Set-based recursion guard for trigger safety.

Validated:
- Compile: PASS
- Tests: 8/8 PASS

Handoff: claude_code → cursor
Status: complete"
```

---

**Ready to start?** Run `.ai-workflow/sync.sh status` to see your active task!
