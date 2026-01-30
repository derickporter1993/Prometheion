# AI Workflow Orchestration System

## Overview
3-tier state management system for coordinating work between Claude Code and Cursor:
- **Tier 1:** Human-readable context (Markdown files in `.ai-workflow/`)
- **Tier 2:** Machine state (JSON in `~/.ai-state/`)
- **Tier 3:** Git commit messages (audit trail)

## Quick Start

### Initialize first task:
```bash
cd ~/path/to/elaro
.ai-workflow/sync.sh next
```

### Check workflow status:
```bash
.ai-workflow/sync.sh status
```

### Mark task complete and load next:
```bash
.ai-workflow/sync.sh complete
```

## AI Startup Prompts

### Claude Code Startup:
```
You're starting a new session. Sync workflow context:

1. Read .ai-workflow/current-task.md
2. Read ~/.ai-state/workflow-state.json
3. Summarize the active task and your role
4. If you're the design owner, proceed with design
5. If cursor is owner, explain that implementation is in progress
```

### Cursor Startup:
```
You're starting a new session. Sync workflow context:

1. Read .ai-workflow/current-task.md
2. Read ~/.ai-state/workflow-state.json
3. Check if active_owner is "cursor" and handoff is present
4. If yes: implement following the handoff instructions
5. After validation: update validation-results.md and run sync.sh complete
```

## File Structure

```
.ai-workflow/
├── README.md              # This file
├── backlog.md            # All pending tasks
├── current-task.md       # Active task details
├── completed-tasks.md    # Historical record
├── validation-results.md # Test/validation outcomes
└── sync.sh              # Orchestration script

~/.ai-state/
└── workflow-state.json   # Machine-readable state
```

## Workflow Phases

### Phase 1: Design (Claude Code)
1. Read current task requirements
2. Design solution following repo patterns
3. Document implementation details
4. Update workflow state with handoff to Cursor

### Phase 2: Implementation (Cursor)
1. Read design from current-task.md
2. Implement changes
3. Run validation steps
4. Update validation-results.md
5. Run `sync.sh complete`

## Validation Template

Add to `validation-results.md` after completing a task:

```markdown
## {task-id}: {Task Name}
**Completed:** {timestamp}
**Executor:** {cursor|claude_code}

### Changes Applied
✅ Created/Modified file1
✅ Created/Modified file2

### Validation Results
✅ Compile: PASS
✅ Tests: X/X passed
❌ Any failures with details

### Commit
```bash
git commit -m "feat({task-id}): {description}

{details}

Validated:
- Compile: PASS  
- Tests: X/X PASS

Handoff: claude_code → cursor
Status: complete"
```
```

## Troubleshooting

### "No active task to complete"
Run: `.ai-workflow/sync.sh status` to see current state
Run: `.ai-workflow/sync.sh next` to load next task

### Task stuck in progress
Manually edit `~/.ai-state/workflow-state.json` to reset state

### Need to skip a task
Edit `~/.ai-state/workflow-state.json` to remove task ID from queue

## Metrics

### View completed tasks:
```bash
cat .ai-workflow/completed-tasks.md
```

### View validation history:
```bash
cat .ai-workflow/validation-results.md
```

### View commit audit trail:
```bash
git log --grep="feat(" --oneline
```

## Advanced Usage

### Shell alias for quick status:
```bash
alias ws='cd ~/path/to/elaro && .ai-workflow/sync.sh status'
```

### Pre-commit hook:
See `.git/hooks/pre-commit` for validation enforcement

