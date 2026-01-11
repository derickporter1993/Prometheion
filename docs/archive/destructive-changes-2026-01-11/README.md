# Archived Destructive Changes - Sentinel → Prometheion Rebranding

**Archived Date:** 2026-01-11
**Original Location:** `/destructiveChanges/`
**Reason:** Historical cleanup manifests from Sentinel→Prometheion rebrand, already applied
**Archived By:** Claude Code (AppExchange preparation cleanup)

---

## Overview

This directory contains historical destructive changes XML manifests from the Sentinel→Prometheion rebranding effort. These manifests were used to remove legacy Sentinel components during the migration to Prometheion v3.0.

## Contents

| File | Purpose | Status |
|------|---------|--------|
| `destructiveChanges.xml` | Master destructive changes manifest | ✅ Applied |
| `destructiveChanges-all-old.xml` | Legacy components removal | ✅ Applied |
| `destructiveChanges-lwc.xml` | Legacy LWC components removal | ✅ Applied |
| `destructiveChanges-tabs-old.xml` | Legacy tab removal | ✅ Applied |
| `destructiveChanges-unused-objects.xml` | Unused objects removal | ⚠️ **CONFLICT DETECTED** |
| `package.xml` | Package manifest for destructive changes | Reference only |

---

## ⚠️ CRITICAL WARNING: Executive_KPI__mdt Conflict

### The Problem

The file `destructiveChanges-unused-objects.xml` listed `Executive_KPI__mdt` (Custom Metadata Type) for **deletion**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Executive_KPI__mdt</members>
        <name>CustomObject</name>
    </types>
    <version>63.0</version>
</Package>
```

### Why This Is a Problem

**The current Prometheion codebase actively uses `Executive_KPI__mdt`:**

**File:** `force-app/main/default/classes/PrometheionExecutiveKPIController.cls`
**Lines:** 29-32

```apex
List<Executive_KPI__mdt> kpis = [
    SELECT Id, Label, MasterLabel, Query__c, Icon__c, Color__c
    FROM Executive_KPI__mdt
];
```

### Impact

If `destructiveChanges-unused-objects.xml` were applied to a Prometheion org:
- ❌ `Executive_KPI__mdt` would be deleted
- ❌ `PrometheionExecutiveKPIController.cls` would throw SOQL errors
- ❌ Executive KPI dashboard would fail to load
- ❌ Deployment of Prometheion package would fail

### Resolution

**DO NOT apply `destructiveChanges-unused-objects.xml` to any Prometheion org.**

Instead, Cursor AI is creating the missing `Executive_KPI__mdt` metadata type definition as part of the AppExchange preparation (see Task 3 in the combined plan).

---

## Archive Justification

### Why Archive Instead of Delete?

1. **Historical Context**: Provides audit trail of Sentinel→Prometheion migration
2. **Documentation**: Shows what was removed and why
3. **Conflict Evidence**: Preserves proof of Executive_KPI__mdt deletion attempt
4. **AppExchange Review**: Demonstrates intentional cleanup vs. accidental deletion

### Why Not Keep in Root?

1. **Deployment Risk**: Prevents accidental application of destructive changes
2. **Confusion**: Root-level presence suggests these are "pending" changes
3. **Package Conflicts**: Could interfere with 2GP package build
4. **AppExchange Compliance**: Reviewers prefer clean repository structure

---

## Reference: Destructive Changes Strategy

### What Were Destructive Changes?

During the Sentinel→Prometheion rebrand, the following components were removed:
- Legacy Sentinel-branded custom objects
- Old LWC components replaced by Prometheion versions
- Deprecated tabs and app pages
- Unused metadata types (except Executive_KPI__mdt)

### Deployment Pattern

```bash
# Historical deployment (DO NOT RE-RUN)
sf project deploy start \
  --manifest destructiveChanges/package.xml \
  --pre-destructive-changes destructiveChanges/destructiveChanges.xml \
  --target-org <org-alias>
```

### Current Best Practice

For new component removal, use:
1. **Protected metadata**: Use `.forceignore` instead of destructive changes
2. **2GP packages**: Remove from `sfdx-project.json` directories
3. **Managed components**: Document deprecation in CHANGELOG.md
4. **Unmanaged orgs**: Create org-specific destructive changes (not in repo)

---

## Related Documentation

- **Evaluation Report**: `/docs/DESTRUCTIVE_CHANGES_EVALUATION.md` (Phase 0, Task 4)
- **Combined Plan**: `/.claude/plans/lexical-leaping-meerkat.md`
- **AppExchange Checklist**: `/docs/APPEXCHANGE_REVIEW_REPORT.md`
- **Repository Cleanup**: `/docs/REPOSITORY_CLEANUP_REPORT.md`

---

## For Future Reference

If you need to understand what was removed during the Sentinel→Prometheion migration:

1. Read the XML files in `destructiveChanges/` directory
2. Check git history: `git log --all --full-history -- destructiveChanges/`
3. Review the AppExchange preparation plan
4. **DO NOT reapply these destructive changes**

---

## Restoration

If you need to restore this directory to the repository root (NOT recommended):

```bash
# From repo root
cp -r docs/archive/destructive-changes-2026-01-11/destructiveChanges ./
git add destructiveChanges/
git commit -m "Restore destructiveChanges from archive"
```

**Warning**: This is only recommended if you need to apply these changes to a Sentinel-era org. For Prometheion orgs, this is dangerous.

---

**Archived by:** Claude Code AppExchange Preparation Workflow
**Archive Date:** 2026-01-11
**Branch:** `claude/review-prometheion-app-0BLu9`
**Related Issue:** Executive_KPI__mdt metadata type creation (Cursor AI Task 3)
