# Load Salesforce Project Context

This command loads the current state of the Elaro project and prepares you for development work.

## Steps

### 1. Read Session Context
Read `docs/SESSION_CONTEXT.md` to understand:
- Current project phase and status
- Recently completed work
- Work in progress
- Known issues or blockers
- Pending tasks by owner (Claude Code, Cursor, Human)

### 2. Provide Status Summary
Present a concise overview:
```
📊 Project Status: [phase and grade]
✅ Recently Completed: [list 2-3 items]
🔄 In Progress: [list current work]
⏳ Pending: [list next tasks]
```

### 3. Populate Todo List
Use TodoWrite to add pending Claude Code tasks from SESSION_CONTEXT.md to the active todo list for this session.

### 4. Check Org Status (Optional)
If appropriate, run:
```bash
sf org list --all
sf org display --target-org elaro-dev
```

### 5. Recommend Next Action
Based on the loaded context and pending tasks, recommend the highest-priority item to work on and ask if the user wants to proceed.

## Important Reminders
- Before ending the session, update `docs/SESSION_CONTEXT.md` with completed work
- Always run tests before deploying: `sf apex run test --test-level RunLocalTests`
- Use security-enforced queries and ElaroSecurityUtils
- Check `claude.me` for full project guidelines

## Example Output
```
📊 Elaro Project Status: v3.0 Production Ready (B+ 86/100)

✅ Recently Completed:
- Integrated ElaroSecurityUtils across all 207 Apex classes
- Achieved 100% deployment success (up from 55%)
- Added critical test coverage for security utilities

🔄 In Progress:
- Permission Intelligence Engine implementation
- AppExchange packaging preparation

⏳ Next Tasks:
1. Implement advanced permission analysis algorithms
2. Create compliance rule library for HIPAA/SOC2
3. Build API integration framework

Recommended: Start with Permission Intelligence Engine - the core algorithm for v3.1. Ready to proceed?
```
