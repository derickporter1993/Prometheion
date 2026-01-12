# Cursor Task Guide - Prometheion AppExchange

> Owner: Cursor
> Branch: `claude/determine-project-phase-Q95M8`
> Total Estimated Time: ~14 hours

---

## Quick Start

```bash
# 1. Checkout branch
git checkout claude/determine-project-phase-Q95M8

# 2. Install dependencies
npm install

# 3. Run LWC tests to see current state
npm run test:unit:coverage

# 4. Read this guide and start with P1 tasks
```

---

## Priority 1 Tasks (CRITICAL - Blocks AppExchange)

### P1.1: LWC Jest Test Coverage
**Goal:** Achieve 75%+ coverage on all LWC components
**Est. Time:** 3-4 hours

#### Step 1: Run Coverage Report
```bash
npm run test:unit:coverage
```

#### Step 2: Identify Low-Coverage Components
Check the coverage report for components below 75%. Focus on these first:

| Component | Location |
|-----------|----------|
| complianceDashboard | `force-app/main/default/lwc/complianceDashboard/` |
| complianceScoreCard | `force-app/main/default/lwc/complianceScoreCard/` |
| gapRemediationWizard | `force-app/main/default/lwc/gapRemediationWizard/` |
| complianceCopilot | `force-app/main/default/lwc/complianceCopilot/` |
| auditWizard | `force-app/main/default/lwc/auditWizard/` |
| eventExplorer | `force-app/main/default/lwc/eventExplorer/` |

#### Step 3: Add Missing Tests
For each low-coverage component, add tests for:

```javascript
// Example test structure for LWC component
import { createElement } from 'lwc';
import ComponentName from 'c/componentName';

describe('c-component-name', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    // Test 1: Component renders
    it('renders component', () => {
        const element = createElement('c-component-name', {
            is: ComponentName
        });
        document.body.appendChild(element);
        expect(element).toBeTruthy();
    });

    // Test 2: Handles data loading
    it('displays data when loaded', async () => {
        // Mock wire adapter data
        // Assert expected output
    });

    // Test 3: Handles user interactions
    it('handles button click', async () => {
        // Simulate click
        // Assert state change
    });

    // Test 4: Handles errors
    it('displays error message on failure', async () => {
        // Mock error response
        // Assert error display
    });
});
```

#### Step 4: Fix Failing Tests
Common issues to fix:
- **Wire adapter mocking**: Use `@salesforce/sfdx-lwc-jest` utilities
- **Promise resolution**: Use `await Promise.resolve()` for async operations
- **DOM queries**: Use `element.shadowRoot.querySelector()`

#### Step 5: Verify Coverage
```bash
npm run test:unit:coverage
# Target: All components >= 75%
```

---

### P1.2: Input Validation Tests
**Goal:** Ensure all @AuraEnabled methods validate inputs
**Est. Time:** 2 hours

#### Target Controllers
Add input validation tests for these Apex controllers:

| Controller | Test File |
|------------|-----------|
| ComplianceDashboardController | ComplianceDashboardControllerTest.cls |
| ComplianceScoreCardController | ComplianceScoreCardControllerTest.cls |
| GapRemediationController | GapRemediationControllerTest.cls |
| EvidenceCollectionService | EvidenceCollectionServiceTest.cls |
| NaturalLanguageQueryService | NaturalLanguageQueryServiceTest.cls |

#### Test Cases to Add

For each @AuraEnabled method, add these test cases:

```apex
// 1. Null input test
@IsTest
static void testMethodName_NullInput() {
    Test.startTest();
    try {
        ControllerName.methodName(null);
        System.assert(false, 'Should throw exception for null input');
    } catch (AuraHandledException e) {
        System.assert(e.getMessage().contains('required') ||
                      e.getMessage().contains('null'),
            'Exception should indicate null input issue');
    }
    Test.stopTest();
}

// 2. Empty string test
@IsTest
static void testMethodName_EmptyString() {
    Test.startTest();
    try {
        ControllerName.methodName('');
        System.assert(false, 'Should throw exception for empty string');
    } catch (AuraHandledException e) {
        System.assert(true, 'Expected exception for empty input');
    }
    Test.stopTest();
}

// 3. Invalid ID format test
@IsTest
static void testMethodName_InvalidId() {
    Test.startTest();
    try {
        ControllerName.methodName('invalid-id-format');
        System.assert(false, 'Should throw exception for invalid ID');
    } catch (Exception e) {
        System.assert(true, 'Expected exception for invalid ID');
    }
    Test.stopTest();
}

// 4. Whitespace-only input test
@IsTest
static void testMethodName_WhitespaceInput() {
    Test.startTest();
    try {
        ControllerName.methodName('   ');
        System.assert(false, 'Should throw exception for whitespace input');
    } catch (AuraHandledException e) {
        System.assert(true, 'Expected exception for whitespace input');
    }
    Test.stopTest();
}
```

---

### P1.3: Bulk Operation Tests
**Goal:** Verify all handlers work with 200+ records
**Est. Time:** 2 hours

#### Target Classes

| Class | Test File |
|-------|-----------|
| PrometheionAlertTriggerHandler | PrometheionAlertTriggerHandlerTest.cls |
| PrometheionConsentTriggerHandler | PrometheionConsentTriggerHandlerTest.cls |
| PrometheionBatchEventLoader | PrometheionBatchEventLoaderTest.cls |
| SOC2IncidentResponseService | SOC2IncidentResponseServiceTest.cls |
| HIPAABreachNotificationService | HIPAABreachNotificationServiceTest.cls |

#### Bulk Test Template

```apex
@IsTest
static void testBulkOperation_200Records() {
    // Setup: Create 200 test records
    List<SObjectType__c> records = new List<SObjectType__c>();
    for (Integer i = 0; i < 200; i++) {
        records.add(new SObjectType__c(
            Name = 'Bulk Test ' + i,
            // Add required fields
        ));
    }

    Test.startTest();
    insert records; // This triggers the handler
    Test.stopTest();

    // Verify all records processed
    List<SObjectType__c> inserted = [
        SELECT Id FROM SObjectType__c
        WHERE Name LIKE 'Bulk Test%'
    ];
    System.assertEquals(200, inserted.size(),
        'All 200 records should be processed');

    // Verify no governor limit errors occurred
    System.assert(Limits.getQueries() < 100,
        'Should not exceed SOQL query limit');
    System.assert(Limits.getDmlStatements() < 150,
        'Should not exceed DML statement limit');
}

@IsTest
static void testBulkOperation_MixedSuccessFailure() {
    // Setup: Create mix of valid and invalid records
    List<SObjectType__c> records = new List<SObjectType__c>();

    // 150 valid records
    for (Integer i = 0; i < 150; i++) {
        records.add(new SObjectType__c(
            Name = 'Valid ' + i,
            Required_Field__c = 'Valid Value'
        ));
    }

    // 50 invalid records (missing required field)
    for (Integer i = 0; i < 50; i++) {
        records.add(new SObjectType__c(
            Name = 'Invalid ' + i
            // Missing Required_Field__c
        ));
    }

    Test.startTest();
    Database.SaveResult[] results = Database.insert(records, false);
    Test.stopTest();

    // Count successes and failures
    Integer successes = 0;
    Integer failures = 0;
    for (Database.SaveResult sr : results) {
        if (sr.isSuccess()) {
            successes++;
        } else {
            failures++;
        }
    }

    System.assertEquals(150, successes, 'Valid records should succeed');
    System.assertEquals(50, failures, 'Invalid records should fail');
}
```

---

## Priority 2 Tasks (Required for AppExchange)

### P2.1: Accessibility Audit
**Goal:** WCAG 2.1 AA compliance for all LWC components
**Est. Time:** 3-4 hours

#### Tools Required
- **axe DevTools** (Chrome extension)
- **WAVE** (Chrome extension)
- **Lighthouse** (Chrome DevTools)

#### Step 1: Setup Test Environment
1. Deploy to scratch org or sandbox
2. Open each LWC component in browser
3. Enable axe DevTools extension

#### Step 2: Audit Each Component

| Component | Checklist |
|-----------|-----------|
| complianceDashboard | ☐ axe scan ☐ keyboard nav ☐ screen reader |
| complianceScoreCard | ☐ axe scan ☐ keyboard nav ☐ screen reader |
| gapRemediationWizard | ☐ axe scan ☐ keyboard nav ☐ screen reader |
| auditWizard | ☐ axe scan ☐ keyboard nav ☐ screen reader |
| eventExplorer | ☐ axe scan ☐ keyboard nav ☐ screen reader |
| complianceCopilot | ☐ axe scan ☐ keyboard nav ☐ screen reader |
| prometheionQuickActions | ☐ axe scan ☐ keyboard nav ☐ screen reader |
| frameworkSelector | ☐ axe scan ☐ keyboard nav ☐ screen reader |
| evidenceUploader | ☐ axe scan ☐ keyboard nav ☐ screen reader |
| reportGenerator | ☐ axe scan ☐ keyboard nav ☐ screen reader |

#### Step 3: Document Issues
Create a file `docs/ACCESSIBILITY_AUDIT.md` with findings:

```markdown
# Accessibility Audit Results

## Summary
- Total Components Audited: 10
- Critical Issues: X
- Major Issues: X
- Minor Issues: X

## Issues by Component

### complianceDashboard
| Issue | Severity | WCAG Rule | Fix |
|-------|----------|-----------|-----|
| Missing alt text on chart | Critical | 1.1.1 | Add aria-label |
| Low color contrast | Major | 1.4.3 | Increase contrast ratio |
```

#### Step 4: Fix Common Issues

**Missing Labels**
```html
<!-- Before -->
<lightning-input type="text"></lightning-input>

<!-- After -->
<lightning-input type="text" label="Search" aria-label="Search compliance gaps"></lightning-input>
```

**Missing Alt Text**
```html
<!-- Before -->
<img src={chartUrl} />

<!-- After -->
<img src={chartUrl} alt="Compliance score trend chart showing 85% current score" />
```

**Color Contrast**
```css
/* Before - contrast ratio 3.5:1 */
.score-label {
    color: #767676;
}

/* After - contrast ratio 4.5:1+ */
.score-label {
    color: #595959;
}
```

**Keyboard Navigation**
```html
<!-- Ensure focusable elements -->
<div role="button" tabindex="0" onkeydown={handleKeydown} onclick={handleClick}>
    Click or Press Enter
</div>
```

```javascript
// Handle keyboard events
handleKeydown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
        this.handleClick();
    }
}
```

**ARIA Attributes**
```html
<!-- Loading states -->
<div aria-busy={isLoading} aria-live="polite">
    <template if:true={isLoading}>
        <lightning-spinner alternative-text="Loading"></lightning-spinner>
    </template>
    <template if:false={isLoading}>
        {content}
    </template>
</div>

<!-- Error messages -->
<div role="alert" aria-live="assertive" if:true={hasError}>
    {errorMessage}
</div>
```

#### Step 5: Verify Fixes
Re-run axe DevTools after each fix to confirm resolution.

---

## Completion Checklist

### P1 Tasks (Must complete before AppExchange submission)
- [ ] LWC Jest coverage >= 75% on all components
- [ ] Input validation tests added for all @AuraEnabled methods
- [ ] Bulk operation tests (200+ records) for all handlers
- [ ] All Jest tests passing

### P2 Tasks (Required for AppExchange)
- [ ] axe DevTools scan on all 10 components
- [ ] Zero critical accessibility issues
- [ ] Zero major accessibility issues
- [ ] Keyboard navigation works on all interactive elements
- [ ] Screen reader tested on key workflows

---

## Commit Guidelines

```bash
# After completing each task section, commit with descriptive message:

# P1.1 - LWC Coverage
git add force-app/main/default/lwc/
git commit -m "test(lwc): Improve Jest coverage to 75%+ on all components"

# P1.2 - Input Validation
git add force-app/main/default/classes/*Test.cls
git commit -m "test(apex): Add input validation tests for @AuraEnabled methods"

# P1.3 - Bulk Tests
git add force-app/main/default/classes/*Test.cls
git commit -m "test(apex): Add bulk operation tests for 200+ records"

# P2.1 - Accessibility
git add force-app/main/default/lwc/
git add docs/ACCESSIBILITY_AUDIT.md
git commit -m "a11y: Fix WCAG 2.1 AA violations in LWC components"

# Push all changes
git push -u origin claude/determine-project-phase-Q95M8
```

---

## Questions?

If blocked, document the issue in `docs/TASK_AUDITOR.md` with status `❌ BLOCKED` and describe the blocker.

---

*Guide created: January 2026*
*For: Cursor AI Assistant*
