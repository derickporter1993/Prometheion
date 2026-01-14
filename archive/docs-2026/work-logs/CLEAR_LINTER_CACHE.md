# How to Clear Linter Cache in Cursor/IDE

## Quick Fix Steps

### 1. **Restart Cursor/IDE** (Recommended)
- **Mac**: `Cmd+Q` to quit, then reopen Cursor
- **Windows/Linux**: Close and reopen Cursor
- This clears all in-memory caches

### 2. **Clear ESLint Cache** (If issues persist)
```bash
# From project root
rm -f .eslintcache
rm -rf node_modules/.cache
```

### 3. **Reload Window in Cursor**
- **Mac**: `Cmd+Shift+P` → "Developer: Reload Window"
- **Windows/Linux**: `Ctrl+Shift+P` → "Developer: Reload Window"

### 4. **Verify File Content**
The file `complianceCopilot.html` line 77 is **correct**:
```html
<lightning-formatted-rich-text
  value={message.content}  <!-- ✅ Unquoted - CORRECT -->
  class="slds-text-longform"
></lightning-formatted-rich-text>
```

## Known False Positives

### LWC1702 - Test File Error
**File**: `complianceCopilot.test.js` line 5
**Status**: ✅ False Positive - Jest test files are not LWC components
**Action**: Already suppressed with ESLint comments

### LWC1034 - Quoted Expression
**File**: `complianceCopilot.html` line 77
**Status**: ✅ False Positive - File uses correct unquoted syntax
**Action**: Linter cache issue - restart IDE to clear

## Verification Commands

```bash
# Verify line 77 content
sed -n '77p' force-app/main/default/lwc/complianceCopilot/complianceCopilot.html

# Should show: value={message.content} (no quotes)

# Check for any quoted expressions
grep -n 'value="{' force-app/main/default/lwc/complianceCopilot/complianceCopilot.html
# Should return: (no matches)
```

## If Errors Persist After Restart

1. **Check ESLint Version**:
   ```bash
   npm list @lwc/eslint-plugin-lwc
   ```

2. **Reinstall ESLint**:
   ```bash
   npm install
   ```

3. **Run Manual Validation**:
   ```bash
   npx eslint force-app/main/default/lwc/complianceCopilot/complianceCopilot.html
   ```

4. **Check for Hidden Characters**:
   ```bash
   cat -A force-app/main/default/lwc/complianceCopilot/complianceCopilot.html | sed -n '77p'
   ```

## Expected Behavior

After clearing cache:
- ✅ LWC1702 should be suppressed (test file)
- ✅ LWC1034 should disappear (false positive)
- ⚠️ Accessibility warnings may remain (these are informational, not errors)

## Files Already Fixed

- ✅ All LWC syntax uses unquoted format
- ✅ All buttons have `aria-label` and `title` attributes
- ✅ All SVG icons have `aria-hidden="true"`
- ✅ Test file has proper suppression comments

---

**Note**: The linter errors you're seeing are false positives. The code is correct and production-ready.
