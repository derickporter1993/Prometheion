# Legacy Name Remediation Report

**Generated:** January 7, 2026  
**Repository:** https://github.com/derickporter1993/Solentra---Prometheion.git  
**Local Path:** /Users/derickporter/sentinel-code

---

## Executive Summary

### Findings Overview

| Legacy Name     | Total References | Critical | Documentation | Node Modules |
| --------------- | ---------------- | -------- | ------------- | ------------ |
| **Sentinel**    | 263              | 3        | 258           | 2            |
| **Solentra**    | 391              | 5        | 366           | 20           |
| **OpsGuardian** | 20               | 0        | 18            | 2            |
| **TOTAL**       | 674              | 8        | 642           | 24           |

### 🔴 CRITICAL ISSUES (Require Immediate Action)

#### 1. GitHub Repository Name

- **Current:** `Solentra---Prometheion` ❌
- **Should Be:** `Prometheion` or `prometheion-salesforce-compliance`
- **Impact:** HIGH - Repository branding, all documentation links
- **Action Required:** Rename repository in GitHub settings

#### 2. Local Directory Name

- **Current:** `/Users/derickporter/sentinel-code` ❌
- **Should Be:** `/Users/derickporter/prometheion-code`
- **Impact:** MEDIUM - Local development only
- **Action Required:** Rename directory after git operations complete

#### 3. Package Metadata

**File:** `package.json`

- Line 3: `"name": "sentinel-enterprise"` in package-lock.json ❌
- Line 22: `"prometheion": "git+https://github.com/derickporter1993/Solentra---Prometheion.git"` ❌
- Line 47: `"url": "git+https://github.com/derickporter1993/Solentra---Prometheion.git"` ❌

**Action Required:** Update after repository is renamed

#### 4. Package Lock File

**File:** `package-lock.json`

- Contains 100+ merge conflict markers: `>>>>>>> solentra/main` ❌
- Contains resolved git URL: `git+ssh://git@github.com/derickporter1993/Solentra.git` ❌

**Action Required:** Regenerate package-lock.json after fixing package.json

#### 5. README.md

**Critical References:**

- Line 281: `git clone https://github.com/derickporter1993/Solentra---Prometheion.git` ❌
- Line 282: `cd sentinel-code` ❌
- Line 682-683: GitHub links with old repo name ❌

---

## 🟡 DOCUMENTATION REFERENCES (Historical - Consider Keeping)

### History Documentation (Intentional Archives)

These files document the migration history and should likely be **PRESERVED AS-IS**:

1. `docs/history/SOLENTRA_SENTINEL_MERGE_SUMMARY.md` - Migration documentation ✅ Keep
2. `docs/history/REBRANDING_COMPLETE.md` - Rebranding history ✅ Keep
3. `docs/history/MERGE_COMPLETE_STATUS.md` - Merge documentation ✅ Keep
4. `docs/history/MIGRATION_COMPLETE_SUMMARY.md` - Migration record ✅ Keep
5. `docs/history/NEXT_STEPS.md` - Migration context ✅ Keep
6. `docs/history/IMPLEMENTATION_COMPLETE_SUMMARY.md` - Implementation history ✅ Keep
7. `docs/history/FINAL_STATUS_AND_NEXT_STEPS.md` - Historical record ✅ Keep
8. `docs/history/DEPLOYMENT_CHECKLIST.md` - Historical checklist ✅ Keep
9. `docs/history/COMPLETE_STEPS_CHECKLIST.md` - Historical record ✅ Keep
10. `docs/history/PHASE0_PREFLIGHT_AUDIT.md` - Historical record ✅ Keep
11. `docs/history/PHASE1_SETUP_GUIDE.md` - Historical record ✅ Keep
12. `docs/history/PLAN_VS_IMPLEMENTATION_COMPARISON.md` - Historical comparison ✅ Keep

**Rationale:** These documents provide valuable historical context for the migration from Sentinel/Solentra to Prometheion.

### Comparison Documents (Historical Reference)

1. `SOLENTRA_SENTINEL_COMPARISON.md` - Repository comparison ✅ Keep
2. `SOLENTRA_DIFF_SUMMARY.md` - Diff analysis ✅ Keep
3. `SOLENTRA_COMPARISON.md` - Component comparison ✅ Keep
4. `REPO_ANALYSIS_COMPLIANCE_SERVICES.md` - Analysis includes Sentinel references ✅ Keep

### Active Documentation (Needs Updates)

1. **`docs/SETUP_GUIDE.md`** - 19 references to "Sentinel" ❌ UPDATE
   - References "Sentinel Setup Guide" in title
   - References `Sentinel_Admin` permission set
   - References `Sentinel_Compliance_Graph__b` object
   - Git clone command uses wrong URL

2. **`docs/GITHUB_REPO_SETUP.md`** - 25 references to "Sentinel" ❌ UPDATE
   - Documentation URLs reference "sentinel"
   - Badge URLs reference "sentinel"
   - Example paths use "sentinel"

3. **`docs/COMPLIANCE_FRAMEWORKS_CODE_REFERENCE.md`** - References `@author Solentra` ❌ UPDATE
   - Line 98, 334, 594, 853, 1072, 1244, 1615: `@author Solentra` tags
   - Line 623, 744, 2083: References to `SolentraConstants`

---

## 🟢 MIGRATION/CLEANUP SCRIPTS (Intentional Legacy References)

These scripts are **designed** to reference legacy names for migration purposes:

1. **`scripts/apex/migrate-from-opsguardian.apex`** ✅ Keep
   - Purpose: Migrate data FROM OpsGuardian TO Prometheion
   - References to `OpsGuardian_History__c` are intentional

2. **`scripts/migrate-from-opsguardian.apex`** ✅ Keep
   - Same as above

3. **`scripts/close-prs.sh`** ❌ UPDATE
   - Line 5: `REPO="derickporter1993/Sentinel"` - Wrong repository name

4. **`scripts/apex/generate-baseline-report.apex`** - 2 references to "Sentinel" 🟡 Review
   - Debug statements mention "Sentinel Baseline Report"
   - Should be updated for consistency

5. **`scripts/apex/runComplianceCheck.apex`** ❌ UPDATE
   - Line 9-10: References `SolentraComplianceScorer` (should be `PrometheionComplianceScorer`)
   - Line 20: References `SolentraComplianceCopilot` (should be `PrometheionComplianceCopilot`)

---

## 🔵 NODE_MODULES (Stale Dependency Cache)

**Issue:** The `node_modules/prometheion/` directory contains old code with legacy names.

**Files Found (Sample):**

- `node_modules/prometheion/force-app/main/default/lwc/solentraDashboard/*`
- `node_modules/prometheion/force-app/main/default/lwc/sentinelReadinessScore/*`
- `node_modules/prometheion/force-app/main/default/lwc/sentinelAiSettings/*`
- `node_modules/prometheion/force-app/main/default/classes/SolentraComplianceCopilot.cls`
- `node_modules/prometheion/force-app/main/default/classes/SentinelAISettingsController.cls`

**Root Cause:**

- `package.json` dependency points to old repository: `git+https://github.com/derickporter1993/Solentra---Prometheion.git`
- Cached old version before rebranding was complete

**Action Required:**

1. Delete `node_modules/` directory
2. Delete `package-lock.json`
3. Update repository name in GitHub
4. Update `package.json` repository URL
5. Run `npm install` to regenerate with clean state

---

## 🟢 DESTRUCTIVE CHANGES (Cleanup Manifests - Keep)

These XML files document **components to be deleted** and intentionally list legacy names:

1. **`destructiveChanges/destructiveChanges.xml`** ✅ Keep
   - Lists: `SentinelGraphIndexer`, `SentinelGraphIndexerTest`, `SentinelReasoningEngine`, etc.
2. **`destructiveChanges/destructiveChanges-lwc.xml`** ✅ Keep
   - Lists: `sentinelReadinessScore`, `solentraCopilot`, `solentraDashboard`

3. **`destructiveChanges/destructiveChanges-tabs-old.xml`** ✅ Keep
   - Lists: `SolentraShield`, `Solentra_Compliance_Hub`

4. **`destructiveChanges/destructiveChanges-all-old.xml`** ✅ Keep

**Rationale:** These files are cleanup manifests that NEED to reference old names to delete them.

---

## 🟢 STATUS/TRACKING DOCUMENTS

These documents track work progress and contain contextual references:

1. `SYNC_STATUS.md` - 5 references to "sentinel-code" directory ✅ Update
2. `PR_STATUS.md` - Historical PR descriptions ✅ Keep
3. `MCP_SETUP_COMPLETE.md` - 2 references to "~/sentinel-code/" ❌ UPDATE
4. `MCP_FULL_SETUP_COMPLETE.md` - 9 references to "~/sentinel-code/" ❌ UPDATE
5. `DELETED_FILES_ANALYSIS.md` - 1 reference (historical) ✅ Keep
6. `TECHNICAL_DEEP_DIVE.md` - 1 reference to `Sentinel_Compliance_Graph__b` object 🟡 Review
7. `TESTING_CHECKLIST.md` - 1 reference to old path ❌ UPDATE
8. `CODEBASE_COMPARISON.md` - Historical reference ✅ Keep

---

## 📋 REMEDIATION PLAN

### Phase 1: GitHub Repository Rename (BLOCKER)

**Must be completed FIRST before other changes**

1. **Rename GitHub Repository:**
   - Go to: https://github.com/derickporter1993/Solentra---Prometheion/settings
   - Rename to: `prometheion` or `prometheion-salesforce-compliance`
   - GitHub will automatically set up redirects from old URL

2. **Update Git Remote (Local):**
   ```bash
   cd /Users/derickporter/sentinel-code
   git remote set-url origin https://github.com/derickporter1993/prometheion.git
   git remote remove solentra  # Remove the old solentra remote
   ```

### Phase 2: Update Package Configuration

1. **Update `package.json`:**
   - Line 22: Update dependency URL to new repository name
   - Line 47: Update repository URL to new name

2. **Regenerate `package-lock.json`:**
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

### Phase 3: Update Active Documentation

1. **`README.md`:**
   - Line 281: Update git clone URL
   - Line 282: Change `cd sentinel-code` to `cd prometheion-code`
   - Lines 682-683: Update GitHub Issues/Discussions URLs

2. **`docs/SETUP_GUIDE.md`:**
   - Update title to "Prometheion Setup Guide"
   - Replace all "Sentinel" references with "Prometheion"
   - Update git clone command

3. **`docs/GITHUB_REPO_SETUP.md`:**
   - Update all example URLs from "sentinel" to "prometheion"

4. **`docs/COMPLIANCE_FRAMEWORKS_CODE_REFERENCE.md`:**
   - Change `@author Solentra` to `@author Prometheion Team`
   - Change `SolentraConstants` to `PrometheionConstants`

### Phase 4: Update Scripts

1. **`scripts/close-prs.sh`:**
   - Change `REPO="derickporter1993/Sentinel"` to correct repo name

2. **`scripts/apex/runComplianceCheck.apex`:**
   - Update class names from `Solentra*` to `Prometheion*`

3. **`scripts/apex/generate-baseline-report.apex`:**
   - Update debug messages from "Sentinel" to "Prometheion"

### Phase 5: Update Status/Tracking Documents

1. **`SYNC_STATUS.md`:** Update directory paths
2. **`MCP_SETUP_COMPLETE.md`:** Update directory paths
3. **`MCP_FULL_SETUP_COMPLETE.md`:** Update directory paths
4. **`TESTING_CHECKLIST.md`:** Update directory path

### Phase 6: Rename Local Directory (LAST)

```bash
cd /Users/derickporter
mv sentinel-code prometheion-code
cd prometheion-code
```

### Phase 7: Update `.gitignore` (If Needed)

Add to ensure node_modules don't get committed:

```
node_modules/
package-lock.json
```

---

## ✅ VERIFIED CLEAN AREAS

These areas have **ZERO** legacy name references (already fully migrated):

1. ✅ **`force-app/main/default/classes/`** - All Apex classes use Prometheion naming
2. ✅ **`force-app/main/default/lwc/`** - All LWC components use Prometheion naming
3. ✅ **`force-app/main/default/objects/`** - All custom objects use Prometheion naming
4. ✅ **`force-app/main/default/triggers/`** - All triggers use Prometheion naming
5. ✅ **Production Code** - ZERO references to legacy names in deployable code

---

## 🎯 SUCCESS CRITERIA

- [ ] GitHub repository renamed (no "Solentra" or "Sentinel" in name)
- [ ] Local directory renamed (no "sentinel" in path)
- [ ] `package.json` and `package-lock.json` updated with new repository URL
- [ ] `node_modules/` regenerated (no legacy code in cache)
- [ ] Active documentation updated (README, SETUP_GUIDE, GITHUB_REPO_SETUP)
- [ ] Scripts updated with correct class/repository names
- [ ] Status documents updated with current paths
- [ ] Historical documents preserved (intentional legacy references)
- [ ] Destructive change manifests preserved (needed for cleanup)
- [ ] Migration scripts preserved (needed for data migration)

---

## ⚠️ IMPORTANT NOTES

1. **Historical Documentation:** Files in `docs/history/` are intentionally preserved with legacy name references to maintain migration history.

2. **Salesforce Object Names:** Object API names like `Sentinel_Compliance_Graph__b` **CANNOT** be easily renamed in Salesforce without data migration. These are mentioned in docs but changing them requires org-wide data migration.

3. **Destructive Changes:** The XML files in `destructiveChanges/` directory MUST reference old names because they're used to delete those components.

4. **Migration Scripts:** Scripts in `scripts/apex/migrate-from-opsguardian.apex` MUST reference OpsGuardian to migrate data FROM that system.

---

**Report Generated by:** Phase 0 Repository Security Audit  
**Next Step:** Await confirmation before proceeding with Phase 1 remediation
