# Cursor UI Tasks: Accessibility & Loading States

## Overview

**Assignee:** Cursor
**Priority:** HIGH - AppExchange requirements
**Estimated Time:** 8-10 hours
**Branch:** `claude/determine-project-phase-Q95M8`

---

## TASK A1: Add aria-hidden to Decorative Icons

### Problem
SVG icons without `aria-hidden="true"` are announced by screen readers, creating noise for visually impaired users.

### Files to Update

| File | Lines with SVG |
|------|----------------|
| `prometheionCopilot.html` | 8-12, 21-23, 49-85, 106-108, 117-121, 130-133, 167-170 |
| All components with `<svg>` or `<lightning-icon>` decorative icons |

### Fix Pattern

```html
<!-- BEFORE -->
<svg class="slds-icon">
    <use xlink:href="/assets/icons/utility-sprite/svg/symbols.svg#warning"></use>
</svg>

<!-- AFTER -->
<svg class="slds-icon" aria-hidden="true">
    <use xlink:href="/assets/icons/utility-sprite/svg/symbols.svg#warning"></use>
</svg>
```

```html
<!-- For lightning-icon decorative use -->
<!-- BEFORE -->
<lightning-icon icon-name="utility:warning" size="small"></lightning-icon>

<!-- AFTER (if purely decorative) -->
<lightning-icon icon-name="utility:warning" size="small" aria-hidden="true"></lightning-icon>

<!-- OR if meaningful, add alternative-text -->
<lightning-icon icon-name="utility:warning" size="small" alternative-text="Warning"></lightning-icon>
```

### Search Command
```bash
grep -rn "<svg\|<lightning-icon" force-app/main/default/lwc/**/*.html | grep -v "aria-hidden\|alternative-text"
```

---

## TASK A2: riskHeatmap.html - Add Text Labels for Color-Only Information

### Problem
Risk levels communicated only through color fail WCAG 2.1 Level A (1.4.1 Use of Color).

### File
`force-app/main/default/lwc/riskHeatmap/riskHeatmap.html`

### Fix Pattern

```html
<!-- BEFORE (color only) -->
<div class={riskClass}>
    {risk.score}
</div>

<!-- AFTER (accessible) -->
<div class={riskClass} role="cell" aria-label={riskAriaLabel}>
    <span class="slds-assistive-text">{risk.severity} risk:</span>
    {risk.score}
</div>
```

### JavaScript Addition (riskHeatmap.js)
```javascript
get riskAriaLabel() {
    return `${this.risk.severity} risk level: score ${this.risk.score}`;
}
```

---

## TASK A3: prometheionROICalculator.html - Fix Form Labels

### Problem
Form inputs without proper labels fail WCAG 2.1 Level A (1.3.1 Info and Relationships).

### File
`force-app/main/default/lwc/prometheionROICalculator/prometheionROICalculator.html`

### Fix Pattern

```html
<!-- BEFORE -->
<label>Industry</label>
<lightning-combobox value={industry} options={industryOptions}></lightning-combobox>

<!-- AFTER -->
<lightning-combobox
    label="Industry"
    value={industry}
    options={industryOptions}
></lightning-combobox>
```

### All Inputs to Fix
- Industry combobox
- Company size input
- Compliance frameworks multi-select
- Current manual hours input
- Hourly rate input
- Any other form fields

---

## TASK L1-L12: Add Loading/Error States to 12 Components

### Problem
Components without loading spinners and error messages provide poor UX and fail gracefully.

### Components to Update

| # | Component | File |
|---|-----------|------|
| L1 | apiUsageDashboard | `lwc/apiUsageDashboard/` |
| L2 | deploymentMonitorDashboard | `lwc/deploymentMonitorDashboard/` |
| L3 | systemMonitorDashboard | `lwc/systemMonitorDashboard/` |
| L4 | flowExecutionMonitor | `lwc/flowExecutionMonitor/` |
| L5 | performanceAlertPanel | `lwc/performanceAlertPanel/` |
| L6 | prometheionAiSettings | `lwc/prometheionAiSettings/` |
| L7 | prometheionROICalculator | `lwc/prometheionROICalculator/` |
| L8 | prometheionTrendAnalyzer | `lwc/prometheionTrendAnalyzer/` |
| L9 | riskHeatmap | `lwc/riskHeatmap/` |
| L10 | complianceScoreCard | `lwc/complianceScoreCard/` |
| L11 | complianceDashboard | `lwc/complianceDashboard/` |
| L12 | executiveKpiDashboard | `lwc/executiveKpiDashboard/` |

### HTML Template Pattern

```html
<template>
    <lightning-card title="Component Title" icon-name="utility:chart">
        <!-- Loading State -->
        <template lwc:if={isLoading}>
            <div class="slds-is-relative slds-p-around_medium" style="min-height: 200px;">
                <lightning-spinner
                    alternative-text="Loading data..."
                    size="medium">
                </lightning-spinner>
            </div>
        </template>

        <!-- Error State -->
        <template lwc:if={hasError}>
            <div class="slds-text-color_error slds-p-around_medium slds-text-align_center">
                <lightning-icon
                    icon-name="utility:error"
                    size="small"
                    class="slds-m-right_x-small"
                    alternative-text="Error">
                </lightning-icon>
                <span>{errorMessage}</span>
                <div class="slds-m-top_small">
                    <lightning-button
                        label="Retry"
                        onclick={handleRetry}
                        variant="neutral">
                    </lightning-button>
                </div>
            </div>
        </template>

        <!-- Empty State -->
        <template lwc:if={isEmpty}>
            <div class="slds-text-color_weak slds-p-around_large slds-text-align_center">
                <lightning-icon
                    icon-name="utility:info"
                    size="small"
                    class="slds-m-right_x-small"
                    alternative-text="Information">
                </lightning-icon>
                <span>No data available</span>
            </div>
        </template>

        <!-- Content (only show when loaded and no error) -->
        <template lwc:if={hasData}>
            <!-- Existing component content here -->
        </template>
    </lightning-card>
</template>
```

### JavaScript Pattern

```javascript
import { LightningElement, wire, track } from 'lwc';
import getData from '@salesforce/apex/Controller.getData';

export default class ComponentName extends LightningElement {
    @track data = [];
    isLoading = true;
    error = null;

    @wire(getData)
    wiredData({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.data = data;
            this.error = null;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    }

    // Computed properties for template
    get hasError() {
        return this.error != null;
    }

    get errorMessage() {
        return this.error?.body?.message || this.error?.message || 'An unexpected error occurred';
    }

    get hasData() {
        return !this.isLoading && !this.error && this.data.length > 0;
    }

    get isEmpty() {
        return !this.isLoading && !this.error && this.data.length === 0;
    }

    handleRetry() {
        this.isLoading = true;
        this.error = null;
        // Refresh wire adapter
        return refreshApex(this.wiredDataResult);
    }
}
```

---

## TASK J1: Fix error.body Null Checks

### Problem
Accessing `error.body.message` without null checks causes runtime errors.

### Search Command
```bash
grep -rn "error\.body\.message" force-app/main/default/lwc/**/*.js
```

### Fix Pattern

```javascript
// BEFORE
.catch(error => {
    this.error = error.body.message;
});

// AFTER
.catch(error => {
    this.error = error?.body?.message || error?.message || 'An unknown error occurred';
});
```

---

## TASK J2: Wrap JSON.parse in Try-Catch

### File
`force-app/main/default/lwc/prometheionDrillDownViewer/prometheionDrillDownViewer.js`

### Lines
29, 69, 86

### Fix Pattern

```javascript
// BEFORE
const data = JSON.parse(jsonString);

// AFTER
let data;
try {
    data = JSON.parse(jsonString);
} catch (e) {
    console.error('Failed to parse JSON:', e);
    data = null;
    this.error = 'Invalid data format';
}
```

---

## Validation Checklist

### After Each Component Update
- [ ] Run `npm run lint` - no errors
- [ ] Run `npm run test:unit` - all tests pass
- [ ] Manual test: Loading spinner appears
- [ ] Manual test: Error state displays correctly
- [ ] Manual test: Empty state displays correctly
- [ ] Screen reader test: No unlabeled icons announced

### Final Validation
```bash
# Lint check
npm run lint

# Unit tests
npm run test:unit

# Check for remaining issues
grep -rn "aria-hidden" force-app/main/default/lwc/**/*.html | wc -l  # Should increase
grep -rn "isLoading" force-app/main/default/lwc/**/*.js | wc -l      # Should be 12+
grep -rn "alternative-text" force-app/main/default/lwc/**/*.html     # Should have entries
```

---

## Commit Strategy

### Commit 1: Accessibility (A1-A3)
```bash
git add -A
git commit -m "fix: Add ARIA labels and accessibility improvements to LWC components

- Add aria-hidden to decorative icons
- Add screen reader text to riskHeatmap color indicators
- Fix form labels in prometheionROICalculator"
```

### Commit 2: Loading/Error States (L1-L12)
```bash
git add -A
git commit -m "feat: Add loading spinners and error states to 12 LWC components

- Add isLoading, hasError, isEmpty computed properties
- Add lightning-spinner for loading state
- Add error message display with retry button
- Add empty state messaging"
```

### Commit 3: JavaScript Fixes (J1-J2)
```bash
git add -A
git commit -m "fix: Add null safety to LWC JavaScript

- Add optional chaining for error.body.message
- Wrap JSON.parse in try-catch blocks"
```

### Push
```bash
git push -u origin claude/determine-project-phase-Q95M8
```

---

## Notes

- Use `lwc:if` NOT `if:true` (already migrated)
- Don't quote template bindings: `onclick={handler}` NOT `onclick="{handler}"`
- Test with keyboard navigation and screen reader if possible
- Lightning components have built-in accessibility - prefer them over custom HTML
