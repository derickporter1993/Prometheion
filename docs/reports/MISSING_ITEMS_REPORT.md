# Missing Items Report - Complete Audit

**Date:** January 10, 2026  
**Scope:** Complete codebase verification

---

## Items Completed (Just Fixed)

### ✅ 1. elaroCopilot Accessibility Fix
**File:** `force-app/main/default/lwc/elaroCopilot/elaroCopilot.html:73-78`
**Issue:** Missing `type="button"` and `aria-label` attributes on quick action cards
**Status:** ✅ FIXED
- Added `type="button"` attribute
- Added `aria-label={cmd.ariaLabel}` attribute

### ✅ 2. if:false → lwc:if Migration (25 instances in 9 files)
**Status:** ✅ FIXED (25 instances migrated)

**Files Fixed:**
1. ✅ `deploymentMonitorDashboard.html` - 3 instances (lines 28-34)
2. ✅ `flowExecutionMonitor.html` - 3 instances (lines 24-34)
3. ✅ `frameworkSelector.html` - 3 instances (lines 24-35)
4. ✅ `complianceTrendChart.html` - 2 instances (lines 24-32)
5. ✅ `complianceTimeline.html` - 2 instances (lines 24-42)
6. ✅ `complianceGapList.html` - 2 instances (lines 23-42)
7. ✅ `riskHeatmap.html` - 2 instances (lines 24-40)
8. ✅ `elaroReadinessScore.html` - 2 instances (lines 17-79)
9. ✅ `elaroAiSettings.html` - 2 instances (lines 17-75)
10. ✅ `systemMonitorDashboard.html` - 1 instance (line 25)

---

## Items Still Missing / Not Fixed

### ❌ 1. LWC1060 formatDate() Template Error (CRITICAL)
**File:** `force-app/main/default/lwc/elaroDashboard/elaroDashboard.html`
- **Line 245:** `{formatDate(pkg.periodStart)} - {formatDate(pkg.periodEnd)}`
- **Line 249:** `Created: {formatDate(pkg.createdDate)}`

**Issue:** LWC templates cannot call functions directly (LWC1060 error)
**Impact:** Blocks Jest test suite from running
**Fix Required:** Use pre-computed getter `formattedAuditPackages` instead

---

### ❌ 2. Remaining if:true/if:false Instances (24 instances in 4 files)

**Files Still Need Migration:**

| File | Instances | Status |
|------|-----------|--------|
| `elaroAuditWizard.html` | 9 | ❌ Not fixed |
| `elaroEventExplorer.html` | 6 | ❌ Not fixed |
| `controlMappingMatrix.html` | 6 | ❌ Not fixed |
| `performanceAlertPanel.html` | 3 | ❌ Not fixed |

**Total:** 24 instances remaining

---

### ❌ 3. Legacy "Sentinel" Branding References

| File | Line | Current | Should Be |
|------|------|---------|-----------|
| `config/project-scratch-def.json` | 2 | `"orgName": "Sentinel"` | `"orgName": "Elaro"` |
| `scripts/orgInit.sh` | 3 | `alias_name="${1:-Sentinel}"` | `alias_name="${1:-elaro}"` |
| `scripts/orgInit.sh` | 10 | `Sentinel_Admin` | `Elaro_Admin` |
| `jest.config.js` | 8 | `"<rootDir>/Sentinel-main/"` | Remove or update if dir exists |
| `scripts/apex/migrate-from-opsguardian.apex` | Multiple | "Sentinel" references | Legacy script (low priority) |
| `scripts/generate-baseline-report.apex` | Multiple | "Sentinel" references | Legacy script (low priority) |
| `scripts/cleanup-repo.sh` | Multiple | "Sentinel-main" references | Legacy cleanup script (low priority) |
| `scripts/scheduleApiSnapshot.sh` | Multiple | "Sentinel" references | Update scheduler name |
| `scripts/close-prs.sh` | 2 | Comment reference | Update comment |

**Priority Files (3 files):**
1. `config/project-scratch-def.json` - P1
2. `scripts/orgInit.sh` - P1
3. `jest.config.js` - P1

---

### ❌ 4. Static Resources Directory (MISSING)
**Location:** `force-app/main/default/staticresources/`
**Status:** Directory does not exist
**Required for:** AppExchange listing
**Assets Needed:**
- Elaro_Logo.png (200x200px)
- Elaro_Logo_Small.png (64x64px)
- Elaro_Logo_Large.png (512x512px)
- App launcher icon (120x120px)

---

### ❌ 5. PostInstallHandler Class (MISSING)
**Location:** `force-app/main/default/classes/ElaroInstallHandler.cls`
**Status:** Class does not exist
**Required for:** AppExchange managed package installation
**Should implement:** `InstallHandler` interface

---

### ❌ 6. Setup Wizard LWC Component (MISSING)
**Location:** `force-app/main/default/lwc/elaroSetupWizard/`
**Status:** Component does not exist
**Purpose:** Guided configuration for new installations
**Priority:** P2 (nice to have, not required)

---

### ❌ 7. Console Statement (ESLint Warning)
**File:** `force-app/main/default/lwc/elaroDrillDownViewer/elaroDrillDownViewer.js:128`
```javascript
console.error('Failed to parse contextJson:', e);
```
**Issue:** ESLint warning for `no-console` rule
**Fix:** Remove or wrap with conditional for development

---

### ❌ 8. TODO Comment (Low Priority)
**File:** `force-app/main/default/classes/ElaroGraphIndexer.cls:129`
```apex
// TODO: Implement Einstein Platform callout when available
```
**Status:** Informational - not a blocker

---

## Summary

| Category | Total | Fixed | Remaining |
|----------|-------|-------|-----------|
| **Accessibility** | 1 | ✅ 1 | 0 |
| **if:true/if:false Migration** | 49 | ✅ 25 | ❌ 24 |
| **Template Errors** | 1 | 0 | ❌ 1 (CRITICAL) |
| **Branding References** | ~35 | 0 | ❌ ~35 |
| **Static Resources** | 1 | 0 | ❌ 1 |
| **PostInstallHandler** | 1 | 0 | ❌ 1 |
| **Setup Wizard** | 1 | 0 | ❌ 1 |
| **Code Quality** | 2 | 0 | ❌ 2 |

---

## Priority Breakdown

### P0 - Critical Blockers
1. ❌ **LWC1060 formatDate() error** - Blocks Jest tests

### P1 - High Priority
2. ❌ **24 remaining if:true/if:false instances** - Rule violation
3. ❌ **3 branding files** (config, scripts/orgInit.sh, jest.config.js)

### P2 - AppExchange Requirements
4. ❌ **Static resources directory**
5. ❌ **PostInstallHandler class**

### P3 - Low Priority
6. ❌ **Console statement** (1 ESLint warning)
7. ❌ **TODO comment** (informational)
8. ❌ **Setup Wizard** (nice to have)
9. ❌ **Legacy script references** (old migration scripts)

---

**Report Generated:** January 10, 2026  
**Next Steps:** Fix P0 and P1 items for code compliance
