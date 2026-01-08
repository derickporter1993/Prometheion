# Linter False Positives and Known Issues

This document explains known false positives and warnings from the linter that can be safely ignored.

## CSS Parsing False Positives (RESOLVED)

**Status:** ✅ Resolved - CSS parsing errors no longer appear

**Previous Issue:** The CSS linter was trying to parse template expressions in `style` attributes (e.g., `style="{scoreRingStyle}"`) as CSS, causing errors like:
- "at-rule or selector expected"
- "} expected"  
- "Do not use empty rulesets"

**Resolution:** These errors have been resolved. The linter now correctly handles template expressions in style attributes.

## Accessibility Warnings (False Positives)

**Status:** ⚠️ Warnings (not errors) - Can be safely ignored

**Issue:** The linter reports accessibility warnings for buttons that already have proper accessibility attributes:

### Button Analysis:

1. **Line 19: Refresh button**
   - ✅ Has `aria-label="Refresh dashboard data"`
   - ✅ Has visible text: "Refresh"
   - ✅ SVG icon has `aria-hidden="true"` (correctly hidden from screen readers)
   - ✅ Button is fully accessible

2. **Line 135: Risk action button**
   - ✅ Has `aria-label="{risk.viewDetailsLabel}"` (dynamic label)
   - ✅ Has visible text: "View Details →"
   - ✅ No icon, so no aria-hidden needed
   - ✅ Button is fully accessible

3. **Line 157: SOC2 Report button**
   - ✅ Has `aria-label="Generate SOC2 Report"`
   - ✅ Has visible text: "Generate SOC2 Report"
   - ✅ SVG icon has `aria-hidden="true"` (correctly hidden from screen readers)
   - ✅ Button is fully accessible

4. **Line 180: HIPAA Report button**
   - ✅ Has `aria-label="Generate HIPAA Report"`
   - ✅ Has visible text: "Generate HIPAA Report"
   - ✅ SVG icon has `aria-hidden="true"` (correctly hidden from screen readers)
   - ✅ Button is fully accessible

**Explanation:** These are false positives. All buttons have:
- Proper `aria-label` attributes for screen readers
- Visible text labels for all users
- SVG icons correctly marked with `aria-hidden="true"` to avoid duplicate announcements
- Full accessibility compliance

The linter warning "Clickable images, Lightning button icons, and form elements require labels for mobile users" is incorrectly flagging these buttons. The linter may not recognize:
- The combination of visible text + `aria-label` + `aria-hidden` SVG as a complete accessibility solution
- Dynamic `aria-label` values (e.g., `{risk.viewDetailsLabel}`)

**Action:** No action required. These warnings can be safely ignored as all buttons are properly labeled and accessible according to WCAG 2.1 guidelines.

## LWC1034 and LWC1043 Errors (Real Syntax Errors)

**Status:** ❌ Errors - Invalid LWC syntax

**Issue:** The linter reports errors for quoted template expressions:
- `LWC1034: Ambiguous attribute value` - for attributes like `disabled="{isLoading}"`
- `LWC1043: Event handler should be an expression` - for event handlers like `onclick="{\n  handler;\n}"`

**Explanation:** 
- **These are REAL syntax errors, not false positives**
- The quoted format `onclick="{\n  handler;\n}"` is **invalid LWC syntax** and will **not work at runtime**
- The correct format is `onclick={handler}` (unquoted)
- Other components in the codebase (e.g., `systemMonitorDashboard.html`) use the correct unquoted format: `onclick={refresh}`
- The LWC compiler requires unquoted expressions for event handlers and data bindings

**Impact:**
- Event handlers using quoted format will **not fire** at runtime
- This causes buttons to appear clickable but do nothing when clicked
- The linter is correctly identifying invalid syntax

**Action Required:**
- Fix all event handlers to use unquoted format: `onclick={handler}`
- Fix all attribute bindings to use unquoted format: `disabled={isLoading}`, `class={variable}`, etc.
- Fix all template directives to use unquoted format: `lwc:if={condition}`, `for:each={list}`, `key={item}`

**Note:** The codebase was previously fixed to use unquoted format, but changes were reverted. The handlers need to be corrected again for the code to function properly.

## Summary

- ✅ CSS parsing errors: Resolved
- ⚠️ Accessibility warnings: False positives - buttons are properly labeled (can be ignored)
- ❌ LWC syntax errors: **Real errors** - quoted format is invalid and prevents handlers from working

**Critical:** The LWC1034/LWC1043 errors indicate that event handlers will **not work** at runtime. These must be fixed by using unquoted format (`onclick={handler}` instead of `onclick="{\n  handler;\n}"`).
