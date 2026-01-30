# Claude Configuration for Elaro

This directory contains Claude Code configuration files that enhance AI-assisted development for the Elaro project.

## 📁 File Structure

```
.claude/
├── README.md                    # This file
├── settings.json               # Core Claude configuration
└── commands/                   # Custom slash commands
    ├── sfcontext.md           # Load project context
    ├── deploy.md              # Safe deployment workflow
    ├── newclass.md            # Create new Apex class
    ├── test.md                # Run tests
    └── scratchorg.md          # Scratch org management
```

## 🚀 Getting Started

### 1. Read Project Context
Before starting work, Claude should read:
- `claude.me` (root) - Full project overview and guidelines
- `docs/SESSION_CONTEXT.md` - Current session state

### 2. Use Custom Commands
Access helpful workflows with slash commands:
- `/sfcontext` - Load current project status
- `/deploy` - Safe deployment workflow
- `/test` - Run tests with coverage
- `/newclass` - Create new Apex class
- `/scratchorg` - Manage scratch orgs

## ⚙️ Configuration Overview

### settings.json

**Key Sections:**

1. **customInstructions** - High-level guidance for Claude
   - Security-first development (ElaroSecurityUtils)
   - Salesforce best practices
   - Test coverage requirements (75%+ minimum)

2. **rules** - Project-specific development rules
   - Security enforcement
   - Test coverage standards
   - Deployment safety
   - Documentation requirements

3. **permissions** - What Claude can and cannot do
   - ✅ **Allow:** SF CLI commands, git operations, file writes
   - ❌ **Deny:** Production deploys, destructive operations

4. **env** - Environment variables
   - `SF_ORG_ALIAS`: Default org (elaro-dev)
   - `SF_DEFAULT_DEV_HUB`: Dev Hub org (prod-org)
   - `SF_LOG_LEVEL`: Logging level (warn)

5. **ignorePatterns** - Excluded from Claude's context
   - node_modules, .sfdx, coverage, logs, etc.

6. **includePatterns** - Explicitly included in context
   - Apex classes, LWC, objects, docs, configs

## 📝 Custom Commands Explained

### /sfcontext - Load Project Context
**Purpose:** Load current project status and pending tasks

**What it does:**
1. Reads `docs/SESSION_CONTEXT.md`
2. Provides status summary
3. Populates TodoList with pending tasks
4. Recommends next action

**When to use:** Start of every session

### /deploy - Safe Deployment
**Purpose:** Deploy code with built-in safety checks

**What it does:**
1. Pre-deployment checklist (tests, org verification)
2. Preview changes
3. Validate (dry run)
4. Deploy with tests
5. Verify and monitor

**When to use:** Before any deployment

### /test - Run Tests
**Purpose:** Execute Apex and LWC tests with coverage

**What it does:**
- Quick commands for running tests
- Coverage requirements table
- Debugging failed tests
- Best practices and common patterns

**When to use:** Before commits and deployments

### /newclass - Create Apex Class
**Purpose:** Generate new Apex class following standards

**What it does:**
1. Gathers class details (name, purpose, type)
2. Provides template with security checks
3. Creates test class structure
4. Deployment and verification steps

**When to use:** Creating any new Apex class

### /scratchorg - Scratch Org Management
**Purpose:** Create and manage scratch orgs

**What it does:**
- Quick commands for org operations
- Standard workflow for feature development
- Naming conventions
- Troubleshooting guide

**When to use:** Starting new features or bug fixes

## 🔒 Security Features

### Permission Guards

**Allowed Operations:**
- Salesforce CLI commands (deploy, retrieve, test, query)
- Git operations (status, diff, commit, push)
- NPM scripts (lint, test, build)
- File writes to project directories

**Blocked Operations:**
- Production org deployments
- Deleting production scratch orgs
- Removing critical directories (force-app, node_modules, .git)
- Force pushing to git
- Hard resets to main branch

### Security-First Development

All Apex code must:
- Use `WITH SECURITY_ENFORCED` in SOQL
- Use ElaroSecurityUtils for CRUD/FLS checks
- Include `with sharing` (unless documented exception)
- Pass security violation tests

## 📊 Development Rules

### 1. Security-First Development
- Pattern: `**/*.cls`
- All Apex must use ElaroSecurityUtils
- All SOQL must include WITH SECURITY_ENFORCED

### 2. Test Coverage Requirement
- Pattern: `force-app/main/default/classes/**`
- Minimum: 75% per class
- Target: 85%+ org-wide

### 3. No Direct Production Deploys
- Never deploy to prod-org or elaro-prod
- Use scratch orgs for development
- Use staging for validation

### 4. Documentation Standards
- JSDoc for Apex, TSDoc for TypeScript
- Update SESSION_CONTEXT.md after significant work

## 🎯 Best Practices

### Context Management
- Use `.claudeignore` to exclude noise (node_modules, logs)
- Use `includePatterns` to focus on relevant code
- Keep claude.me updated with project changes

### Session Workflow
1. Start: Run `/sfcontext` to load project state
2. Work: Use TodoList to track progress
3. End: Update `docs/SESSION_CONTEXT.md`

### Command Usage
- Use custom commands for common workflows
- Reference `claude.me` for detailed guidelines
- Check settings.json for permission boundaries

## 🔧 Customization

### Adding New Commands
1. Create file: `.claude/commands/mycommand.md`
2. Use markdown format with clear sections
3. Include examples and best practices
4. Document in this README

### Modifying Settings
Edit `settings.json` to:
- Add new permissions
- Update environment variables
- Add ignore/include patterns
- Define new rules

### Updating Project Context
Edit `claude.me` to:
- Update tech stack
- Add new capabilities
- Modify development guidelines
- Update common tasks

## 📚 Additional Resources

- **Project Overview:** `claude.me` (root directory)
- **Session State:** `docs/SESSION_CONTEXT.md`
- **Architecture:** `docs/architecture/`
- **API Docs:** `docs/api/`
- **Sample Data:** `scripts/apex/sample-data/`

## 🐛 Troubleshooting

### Claude Not Following Rules
- Verify rules are enabled in settings.json
- Check customInstructions are loaded
- Ensure claude.me is in root directory

### Permission Denied Errors
- Check permissions.allow in settings.json
- Verify paths match actual file locations
- Review permissions.deny for conflicts

### Commands Not Working
- Ensure command files exist in `.claude/commands/`
- Check markdown syntax is valid
- Verify file names match command names

### Context Overload
- Review and expand ignorePatterns
- Narrow includePatterns to essential files
- Use .claudeignore for additional exclusions

## 📖 Version History

### v2.0 (January 2026) - Current
- ✅ Created claude.me with full project context
- ✅ Enhanced settings.json with rules and includePatterns
- ✅ Added 5 custom commands (sfcontext, deploy, test, newclass, scratchorg)
- ✅ Created .claudeignore for context optimization
- ✅ Updated to use session-based paths
- ✅ Added comprehensive documentation

### v1.0 (Previous)
- Basic settings.json with permissions
- Single sfcontext command
- Limited documentation

## 🤝 Contributing

When updating Claude configuration:
1. Test changes in development sessions
2. Document new commands/rules in this README
3. Update claude.me if project structure changes
4. Maintain backward compatibility where possible

---

**Questions?** Check `claude.me` or ask Claude to explain any configuration aspect.
