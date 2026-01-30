# Check Elaro Project Status

Quick status check for the Elaro project.

## Steps

### 1. Read Session Context
Read `docs/SESSION_CONTEXT.md` and `docs/TASK_AUDITOR.md` to understand current state.

### 2. Check Git Status
```bash
git status
git log --oneline -3
```

### 3. Check Connected Orgs
```bash
sf org list
```

### 4. Provide Brief Summary
Present:
- Current branch and sync status
- Any uncommitted changes
- Connected orgs
- Next recommended action from TASK_AUDITOR.md

## Example Output
```
Branch: main (up to date with origin)
Changes: None uncommitted
Orgs: prod-org connected

Next: Implement Compliance Report Scheduler (Week 1 priority)
```
