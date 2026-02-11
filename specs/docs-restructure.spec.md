# Specification: Documentation Restructure

**Status**: Approved
**Date**: 2026-02-11
**Author**: Planner (Opus)

## Objective

Reorganize 205 scattered documentation files into a clean, navigable structure suitable for AppExchange distribution.

## Current Problems

1. **Fragmentation**: 180+ docs across 15+ locations (root, `.ai-workflow/`, `.cursor/`, `.planning/`, `docs/` with 11 subdirectories)
2. **Duplication**: API_REFERENCE.md, SETUP_GUIDE.md, SECURITY_REVIEW.md exist in multiple places
3. **Outdated Content**: 90+ historical session logs, deployment summaries, old plans mixed with current docs
4. **Poor Navigation**: No index, unclear hierarchy, difficult to find information

## Target Structure

```
docs/
  README.md                   # Main navigation hub
  CHANGELOG.md                # From planning/
  ROADMAP.md                  # From planning/
  user/                       # User-facing docs
    README.md
    USER_GUIDE.md
    ADMIN_GUIDE.md
    INSTALLATION_GUIDE.md
    SETUP_GUIDE.md            # Consolidated
    DEMO_ORG_SETUP.md
  developer/                  # Developer docs
    README.md
    API_REFERENCE.md          # Consolidated
    TECHNICAL_DEEP_DIVE.md
    DATA_FLOWS.md
    EXTERNAL_SERVICES.md
    CONTRIBUTING.md
    IMPLEMENTATION_DESIGN.md
  architecture/               # ADRs (existing)
    README.md
    ADR-001-dual-repo-strategy.md
    ADR-002-monorepo-tooling.md
    ADR-003-dependency-management.md
    UI_UX_ARCHITECTURE.md
  security/                   # Security docs
    README.md
    FLS_AUDIT_REPORT.md
    SECURITY_REVIEW_CHECKLIST.md
    PAGERDUTY_INTEGRATION_SECURITY_REVIEW.md
  appexchange/                # AppExchange submission
    README.md
    APP_REVIEW.md
    MANUAL_SECURITY_REVIEW.md
    SECURITY_REVIEW.md
    APPEXCHANGE_REMEDIATION_PLAN.md
  audit/                      # Current audit (Feb 7) - unchanged
  business/                   # Business docs
  images/                     # Doc images
  archive/                    # Historical content
    README.md                 # Archive manifest
    session-logs/             # 45 work-logs
    history/                  # 21 historical summaries
    plans/                    # 14 old plans
    reports/                  # 10 old reports
    root/                     # 5 archived root files
    loose/                    # 34 archived loose docs
    destructive-changes/      # Existing archive
```

## File Dispositions

| Category | Count | Action |
|----------|-------|--------|
| Keep at root | 3 | CLAUDE.md, README.md, SECURITY.md |
| Keep in place | 12 | audit/, architecture/, specs/, scripts/, examples/ |
| Consolidate | 7 | Merge duplicates, move to new structure |
| Archive | 150 | Move to docs/archive/ |
| Delete | 19 | .ai-workflow/, .cursor/, .planning/ |

## Duplicates to Consolidate

| File | Locations | Resolution |
|------|-----------|------------|
| API_REFERENCE.md | docs/, docs/guides/ | Keep best → docs/developer/ |
| SETUP_GUIDE.md | docs/, docs/guides/ | Keep best → docs/user/ |
| SECURITY_REVIEW.md | docs/, docs/appexchange/ | Keep appexchange/ version |
| APPEXCHANGE_REMEDIATION_PLAN.md | docs/, docs/appexchange/ | Keep appexchange/ version |
| CLAUDE.md | root, docs/ | Delete docs/ version (stale) |

## Constraints

1. **Git History**: Use `git mv` (NOT copy+delete) to preserve file history
2. **Isolation**: Work on feature branch `feature/docs-restructure`
3. **No Code Changes**: Don't touch `force-app/`, `platform/`, `node_modules/`
4. **Atomic Commits**: Each task is independently committable

## Success Criteria

1. ✅ Total docs reduced from 205 to ~50 active files
2. ✅ Zero duplicates
3. ✅ Every section has README.md navigation
4. ✅ All internal markdown links validated
5. ✅ Git history preserved (verified with `git log --follow`)
6. ✅ Root `README.md` and `CLAUDE.md` references updated

## Open Questions

1. **docs/business/BUSINESS_PLAN_ALIGNMENT.md** - Contains sensitive info? Remove vs archive?
2. **Root .git-workflow.md** - Archive or delete? (rules exist in `~/.claude/rules/`)
3. **scripts/*.md** - Keep in scripts/ or move to docs/developer/?
4. **AppExchange loose files** - APPEXCHANGE_LISTING.md, SCANNER_REPORT_BUNDLE.md → appexchange/ or archive?

## Implementation Tasks

See `plans/docs-restructure.plan.md` for detailed task breakdown.

## References

- Planner Agent Output: agentId a9e19d8
- Audit Reports (keep): docs/audit/ (Feb 7, 2026)
- ADRs (keep): docs/architecture/
