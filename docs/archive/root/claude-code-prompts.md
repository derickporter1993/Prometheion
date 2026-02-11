# Salesforce Security Compliance Runbook - Claude Code Prompts

This file contains the exact prompts to give to Claude Code for each task in the security compliance runbook.

---

## Backend (Phase 1)

### 1. Add WITH SECURITY_ENFORCED to ElaroQuickActionsService

**Prompt for Claude Code:**

```
Open ElaroQuickActionsService.cls. Identify the 3 methods requiring WITH SECURITY_ENFORCED. For each SOQL query in those methods, show the exact query rewritten with WITH SECURITY_ENFORCED. Note any dynamic SOQL and propose the safest compliant approach.
```

**Expected Output:**

- List of 3 methods with SOQL queries
- Each query rewritten with `WITH SECURITY_ENFORCED`
- Notes on any dynamic SOQL with safe implementation patterns
- Fields that may need to be removed due to inaccessibility

---

### 2. Add CRUD Checks to ElaroQuickActionsService DML

**Prompt for Claude Code:**

```
In ElaroQuickActionsService.cls, locate the 3 DML operations needing CRUD checks. For each, specify create/update/delete permission check(s), where to place them, and what exception/handling pattern matches this codebase. Provide the exact code blocks.
```

**Expected Output:**

- Location of each DML operation
- Exact permission checks: `Schema.sObjectType.X.isCreateable()`, `isUpdateable()`, `isDeletable()`
- Placement guidance (before DML)
- Exception handling pattern consistent with codebase
- Code for handling mixed sObject types if applicable

---

### 3. Add HTTP Timeout + CRUD Check to ApiUsageSnapshot

**Prompt for Claude Code:**

```
Open ApiUsageSnapshot. Identify where HttpRequest is built and add an explicit timeout (suggest a value consistent with repo norms). Identify reads/writes and add the appropriate CRUD checks. Provide exact edits and list impacted tests.
```

**Expected Output:**

- Location of HttpRequest instantiation
- Exact `req.setTimeout(<ms>)` code with suggested timeout value
- SOQL queries needing `isAccessible()` checks
- DML operations needing `isCreateable()`/`isUpdateable()` checks
- List of test classes that may need updates
- Notes on callout mocks that may be affected

---

### 4. Create TriggerRecursionGuard.cls

**Prompt for Claude Code:**

```
Design TriggerRecursionGuard.cls consistent with this repo's trigger framework. Provide a minimal API (e.g., enter(key) returns boolean) and include a test-reset hook only if consistent with existing patterns. Show the full class and metadata.
```

**Expected Output:**

- Complete `TriggerRecursionGuard.cls` implementation
- API design: `public static Boolean enter(String key)`
- Static map to track executed contexts
- Test reset method if needed: `@TestVisible private static void reset()`
- `TriggerRecursionGuard.cls-meta.xml` content
- Usage example in comments
- Optional: Basic test class outline

---

### 5. Create 2 Missing Trigger Handlers

**Prompt for Claude Code:**

```
Scan triggers to find the two that lack handler classes (missing references or inline logic without handlers). Infer the repo's trigger-handler pattern and generate the two missing handler classes accordingly (method stubs for the events used). Provide file names and exact scaffolding.
```

**Expected Output:**

- Identification of the 2 triggers without handlers
- Repo's trigger-handler pattern analysis
- Complete handler class implementations with:
  - Constructor if needed
  - Method stubs for each trigger event (beforeInsert, afterUpdate, etc.)
  - Consistent naming convention
- Handler class metadata files
- Notes on how triggers should call handlers

---

### 6. Add Recursion Guards to 5 Triggers

**Prompt for Claude Code:**

```
Identify the 5 triggers needing recursion guards. For each, specify whether the guard should be in the trigger entrypoint or in the handler entrypoint (based on repo pattern). Provide the exact guard key per trigger + event and show the precise code insertion.
```

**Expected Output:**

- List of 5 triggers requiring guards
- For each trigger:
  - Whether to place guard in trigger or handler
  - Exact guard key format (e.g., 'AccountTrigger.beforeUpdate')
  - Complete code snippet showing where/how to insert guard
  - Event-specific keys to avoid over-blocking
- Rationale for placement decisions

---

## Frontend (Phase 1)

### 7. Add aria-hidden="true" to Icons in complianceCopilot.html

**Prompt for Claude Code:**

```
In complianceCopilot.html, locate the 3 icon elements that must be aria-hidden. Confirm they're decorative (not the only meaning) and provide the exact markup edits for each.
```

**Expected Output:**

- Location of each of the 3 icons in the HTML
- Confirmation that icons are decorative (not semantic/interactive)
- Exact before/after markup for each icon
- Notes if any icon should NOT be hidden (is semantic)

---

### 8. Add Loading States to Components

**Prompt for Claude Code (use per component):**

```
For component [ComponentName], identify the async operations and propose a consistent loading pattern (isLoading state, spinner, disabling controls). Provide minimal code diffs per component and ensure isLoading is cleared in finally blocks.
```

**Expected Output (per component):**

- List of async operations in the component
- `@track isLoading = false;` property declaration
- Spinner HTML: `<lightning-spinner if:true={isLoading}></lightning-spinner>`
- Button disable attributes: `disabled={isLoading}`
- Code diffs showing:
  - `this.isLoading = true;` before async call
  - `finally { this.isLoading = false; }` after
- Complete try-catch-finally pattern

**Components to Process (repeat prompt for each):**

- Component A
- Component B
- Component C
- Component D (if applicable)

---

### 9. Create Jest Tests for Components

**Prompt for Claude Code (use per component):**

```
For component [ComponentName], produce 3-5 Jest cases each covering: renders default state, toggles loading spinner during async, renders success state, renders error state, disables actions while loading. Include Apex mocks/wire adapters as needed. Provide full test files.
```

**Expected Output (per component):**

- Complete test file: `componentName/__tests__/componentName.test.js`
- Test structure:
  - `describe('componentName', () => { ... })`
  - Test case: Default render
  - Test case: Loading spinner during async
  - Test case: Success state rendering
  - Test case: Error state rendering
  - Test case: Controls disabled while loading
- Apex mocks setup (if needed)
- Wire adapter mocks (if needed)
- Mock data structures
- Import statements

**Components to Test (repeat prompt for each):**

- Component X
- Component Y

---

## Lower Priority Items

### Phase 2: Add notifyOnFailure() to ElaroGLBAAnnualNoticeBatch

**Prompt for Claude Code:**

```
Open ElaroGLBAAnnualNoticeBatch. Determine existing error tracking/notification patterns in similar batch classes. Implement notifyOnFailure() in finish() so it triggers only when failures occurred. Provide exact code edits and list tests to update/add.
```

**Expected Output:**

- Analysis of existing batch error patterns in codebase
- Complete `notifyOnFailure()` method implementation
- Integration into `finish()` method
- Condition check: only notify if failures exist
- Error message formatting
- Notification mechanism (email, platform event, etc.)
- Test updates/additions needed
- Safety notes (no unhandled exceptions in finish)

---

### Phase 3: Add Descriptions to 59 Custom Fields

**Prompt for Claude Code:**

```
Given a list of 59 field API names and intended meaning, generate consistent field Description text (1-2 sentences) and indicate which metadata files need edits. Provide a deterministic mapping output (API name → description).

[Provide the list of 59 fields with their intended meanings]
```

**Expected Output:**

- Table or mapping: Field API Name → Description text
- Format:
  ```
  FieldAPIName__c: "Brief description of the field's purpose and usage (1-2 sentences)."
  ```
- List of metadata file paths to edit
- Consistent description style/tone
- Optional: Script to automate metadata updates

---

### Phase 3: Capture 12 AppExchange Screenshots

**Prompt for Claude Code:**

```
Create a screenshot shot-list for AppExchange: enumerate the 12 required views (setup, key UI screens, permissions, sample outputs) and provide a consistent naming convention and capture steps.
```

**Expected Output:**

- Enumerated list of 12 screenshots needed:
  1. Setup screen (describe specific view)
  2. Key UI screen 1 (describe)
  3. Key UI screen 2 (describe)
  4. Permission set configuration
  5. Sample output/report
  6. [etc. through 12]
- Naming convention: `elaro_appexchange_01_setup.png`
- Capture steps for each screenshot:
  - Navigation path in org
  - What to show/highlight
  - Window/viewport size recommendations
- Notes on what should be visible/hidden in each screenshot

---

## Usage Instructions

### How to Use These Prompts with Claude Code

1. **Sequential Execution**: Work through prompts in order (Backend Phase 1, then Frontend Phase 1, then Lower Priority)

2. **Copy-Paste**: Copy the exact prompt text under each section header and paste into Claude Code

3. **Context**: Give Claude Code access to:
   - The specific file(s) mentioned in the prompt
   - Related test files
   - Similar classes/patterns in the codebase for consistency

4. **Review Output**: After Claude Code responds:
   - Review the proposed changes
   - Verify consistency with codebase patterns
   - Check for edge cases

5. **Implement in Cursor**: Take Claude Code's output and implement in Cursor following the Cursor runbook steps

6. **Compile and Test**: After implementation, run the compile and test commands from `.cursorrules`

---

## Tips for Best Results

### Providing Context to Claude Code

- **Show similar patterns**: If asking for a new handler, show an existing handler first
- **Highlight repo conventions**: Point out naming patterns, error handling styles, test patterns
- **Be specific about unknowns**: If trigger/handler names are TBD, say "determine these from codebase analysis"

### Iterating on Claude Code's Output

- **Ask for alternatives**: "Show me 2-3 ways to implement this CRUD check"
- **Request refinement**: "Make the recursion guard thread-safe" or "Add more defensive error handling"
- **Clarify edge cases**: "What happens if the list contains null values?"

### Connecting Phases

- **Reference earlier work**: "Using the TriggerRecursionGuard you designed earlier, show how to integrate it into AccountTrigger"
- **Maintain consistency**: "Use the same loading pattern you suggested for Component A"

---

## Quick Reference: Prompt Patterns

### Discovery Prompts (What exists?)

```
"Scan [directory/file pattern] to identify [what you're looking for]"
"Analyze existing [pattern/framework] in the codebase"
```

### Design Prompts (How should it work?)

```
"Design [component] consistent with repo patterns"
"Propose [solution] matching existing [similar feature]"
```

### Implementation Prompts (Show me the code)

```
"Provide exact code blocks for [change]"
"Show precise insertion points and diffs"
```

### Testing Prompts

```
"List impacted tests and required updates"
"Generate Jest test cases covering [scenarios]"
```

---

## Customization Needed

When you have actual names, update these prompts by replacing:

- `[ComponentName]` - Actual LWC component names
- `Component A/B/C/D` - Actual component names for loading states
- `Component X/Y` - Actual component names for Jest tests
- The list of 59 fields - Actual field API names and intended meanings

You can also add specific repo context like:

- "Our trigger framework uses the TriggerHandler base class pattern"
- "We use CustomException\_\_c for error logging"
- "Tests should use Test.startTest() / Test.stopTest() pattern"
