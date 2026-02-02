# AI Workflow Orchestration - Cheat Sheet

## 🎯 Three Commands You Need

```bash
.ai-workflow/sync.sh status    # What's active?
.ai-workflow/sync.sh next      # Load next task
.ai-workflow/sync.sh complete  # Mark done, load next
```

## 🤖 AI Startup Prompts

### Claude Code (Design):
```
Read .ai-workflow/current-task.md and ~/.ai-state/workflow-state.json
Summarize active task and proceed with design
```

### Cursor (Implementation):
```
Read .ai-workflow/current-task.md and ~/.ai-state/workflow-state.json
Implement design, validate, update validation-results.md
Run: .ai-workflow/sync.sh complete
```

## 📝 Handoff Checklist

### Claude Code → Cursor:
- [ ] Design documented in current-task.md
- [ ] Files to create/modify listed
- [ ] Exact changes specified
- [ ] Validation steps provided
- [ ] Update workflow state: `active_owner = "cursor"`

### Cursor → Complete:
- [ ] Changes implemented
- [ ] Validation run (compile + tests)
- [ ] Results in validation-results.md
- [ ] Git commit with structured message
- [ ] Run: `.ai-workflow/sync.sh complete`

## 📊 Files Quick Reference

| File | Purpose | Updated By |
|------|---------|-----------|
| `current-task.md` | Active work | Both AIs |
| `backlog.md` | All pending tasks | Manual |
| `completed-tasks.md` | History | Sync script |
| `validation-results.md` | Test outcomes | Cursor |
| `workflow-state.json` | Machine state | Both AIs |

## 🎨 Commit Message Template

```bash
git commit -m "feat(task-id): brief description

Detailed explanation of changes.

Validated:
- Compile: PASS
- Tests: X/X PASS

Handoff: claude_code → cursor
Status: complete"
```

## 🔧 Validation Template

```markdown
## task-id: Task Name
**Completed:** {timestamp}
**Executor:** {cursor|claude_code}

### Changes Applied
✅ Created/Modified files

### Validation Results
✅ Compile: PASS
✅ Tests: X/X passed

### Commit
{commit command}
```

## ⚡ Quick Checks

```bash
# See current task
cat .ai-workflow/current-task.md

# See all pending
cat .ai-workflow/backlog.md

# See what's done
cat .ai-workflow/completed-tasks.md

# See test results
cat .ai-workflow/validation-results.md

# See machine state
cat ~/.ai-state/workflow-state.json

# See commit history
git log --grep="feat(" --oneline
```

## 🚨 Troubleshooting

| Problem | Solution |
|---------|----------|
| No active task | `sync.sh status` then `sync.sh next` |
| Task stuck | Check `workflow-state.json` |
| Wrong task loaded | Edit `workflow-state.json`, remove from queue |
| Validation failed | Fix issues, re-run validation, update results |
| Need to skip task | Edit queue in `workflow-state.json` |

## 📈 Workflow States

```
pending → loading → designing → implementing → validating → complete
   ↑                                                            ↓
   └────────────────────────────────────────────────────────────┘
                         (sync.sh complete)
```

## 🎯 Phase 1 Tasks (9 total)

### Backend (6):
1. **backend-001** - TriggerRecursionGuard.cls ← START HERE
2. **backend-002** - 2 Missing Trigger Handlers
3. **backend-003** - Add Recursion Guards (5 triggers)
4. **backend-004** - WITH SECURITY_ENFORCED (3 methods)
5. **backend-005** - CRUD Checks (3 DML operations)
6. **backend-006** - ApiUsageSnapshot fixes

### Frontend (3):
7. **frontend-001** - aria-hidden (3 icons)
8. **frontend-002** - Loading States (3-4 components)
9. **frontend-003** - Jest Tests (2 components)

## 💡 Pro Tips

### Shell Alias:
```bash
alias ws='cd ~/path/to/elaro && .ai-workflow/sync.sh status'
```

### Watch Mode:
```bash
watch -n 5 '.ai-workflow/sync.sh status'
```

### Quick Jump:
```bash
alias wt='cd ~/path/to/elaro && cat .ai-workflow/current-task.md'
```

---
**Remember:** The system automates handoffs. You just design, implement, validate, and mark complete!
