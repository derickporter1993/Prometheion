# PHASE 4: VALIDATION & SUBMISSION

## Execution Plan

**Timeline:** Day 8
**Assignees:** Human (Primary) + Claude Code + Cursor (Support)
**Priority:** FINAL - AppExchange submission
**Dependencies:** Phases 0-3 must be complete

---

## OVERVIEW

Phase 4 is the final quality gate before AppExchange submission. All validation must pass before proceeding.

| Activity | Owner | Hours |
|----------|-------|-------|
| Code Quality Validation | Claude Code | 4h |
| UI/UX Validation | Cursor | 2h |
| Security Scan | Claude Code | 2h |
| Integration Testing | Human | 4h |
| Final Review & Submission | Human | 4h |

**Total:** 16 hours

---

## 4.1 PRE-SUBMISSION CHECKLIST

### Mandatory Requirements

| # | Requirement | Validation Method | Status |
|---|-------------|-------------------|--------|
| 1 | Apex test coverage ≥75% (org-wide) | `sfdx force:apex:test:run --codecoverage` | ☐ |
| 2 | LWC Jest test coverage ≥75% | `npm run test:unit:coverage` | ☐ |
| 3 | Zero critical security vulnerabilities | PMD scan + manual review | ☐ |
| 4 | Zero high security vulnerabilities | PMD scan + manual review | ☐ |
| 5 | WCAG 2.1 AA accessibility compliance | axe DevTools audit | ☐ |
| 6 | All documentation complete | Manual review | ☐ |
| 7 | AppExchange listing finalized | Partner Portal | ☐ |
| 8 | Governor limit stress testing passed | Bulk data tests | ☐ |
| 9 | Mobile responsiveness validated | Device testing | ☐ |
| 10 | No merge conflicts in codebase | `grep -r "<<<<<<" .` | ☐ |

---

## 4.2 APEX TEST COVERAGE VALIDATION

### Run Full Test Suite

```bash
# Run all tests with coverage
sfdx force:apex:test:run \
  --codecoverage \
  --resultformat human \
  --wait 30 \
  --targetusername myOrg

# Get coverage report
sfdx force:apex:test:report \
  --codecoverage \
  --outputdir ./test-results
```

### Coverage Requirements

| Class Type | Minimum Coverage | Target |
|------------|------------------|--------|
| Controllers | 75% | 85% |
| Services | 75% | 90% |
| Triggers | 75% | 95% |
| Schedulers | 75% | 80% |
| Utilities | 75% | 85% |

### Classes Requiring Attention

If any class is below 75%, prioritize:

```apex
// Quick coverage boost - add to existing test class
@IsTest
static void testBulkOperations() {
    List<SObject> records = new List<SObject>();
    for (Integer i = 0; i < 200; i++) {
        records.add(createTestRecord(i));
    }
    Test.startTest();
    // Call method with bulk data
    Test.stopTest();
    System.assert(true);
}

@IsTest
static void testNegativeScenarios() {
    try {
        // Call method with invalid input
        System.assert(false, 'Expected exception');
    } catch (Exception e) {
        System.assert(e.getMessage().contains('expected text'));
    }
}
```

---

## 4.3 LWC JEST TEST VALIDATION

### Run Jest Tests

```bash
# Run all LWC tests with coverage
npm run test:unit:coverage

# Generate HTML coverage report
npm run test:unit:coverage -- --coverageReporters=html

# View report
open coverage/lcov-report/index.html
```

### Jest Coverage Requirements

| Component Type | Minimum | Target |
|----------------|---------|--------|
| Dashboard components | 75% | 85% |
| Form components | 75% | 90% |
| Utility components | 75% | 80% |

### Quick Jest Test Template

```javascript
import { createElement } from 'lwc';
import MyComponent from 'c/myComponent';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import getRecords from '@salesforce/apex/Controller.getRecords';

// Mock Apex
const mockGetRecords = registerApexTestWireAdapter(getRecords);

describe('c-my-component', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders without errors', () => {
        const element = createElement('c-my-component', { is: MyComponent });
        document.body.appendChild(element);
        expect(element).not.toBeNull();
    });

    it('displays data when loaded', () => {
        const element = createElement('c-my-component', { is: MyComponent });
        document.body.appendChild(element);

        mockGetRecords.emit([{ Id: '001', Name: 'Test' }]);

        return Promise.resolve().then(() => {
            const items = element.shadowRoot.querySelectorAll('.item');
            expect(items.length).toBe(1);
        });
    });

    it('shows error on failure', () => {
        const element = createElement('c-my-component', { is: MyComponent });
        document.body.appendChild(element);

        mockGetRecords.error({ body: { message: 'Error' } });

        return Promise.resolve().then(() => {
            const error = element.shadowRoot.querySelector('.error');
            expect(error).not.toBeNull();
        });
    });
});
```

---

## 4.4 SECURITY SCAN

### PMD Scan

```bash
# Install PMD (if not installed)
brew install pmd

# Run security scan
pmd check \
  --dir force-app/main/default/classes \
  --rulesets category/apex/security.xml \
  --format html \
  --report-file security-report.html

# View critical issues
pmd check \
  --dir force-app/main/default/classes \
  --rulesets category/apex/security.xml \
  --minimum-priority 1
```

### Security Checklist

| Check | Command/Action | Status |
|-------|----------------|--------|
| No SOQL injection | Search for dynamic SOQL without bind variables | ☐ |
| FLS enforced | Search for WITH SECURITY_ENFORCED | ☐ |
| CRUD checks | Search for Schema.sObjectType checks | ☐ |
| No hardcoded secrets | Search for password, secret, key, token | ☐ |
| Sharing enforced | All classes have sharing declaration | ☐ |
| XSS prevention | No raw HTML output | ☐ |

### Security Search Commands

```bash
# Check for dynamic SOQL without bind variables
grep -rn "Database.query" force-app/main/default/classes/ | grep -v ":"

# Check for missing WITH SECURITY_ENFORCED
grep -rn "FROM " force-app/main/default/classes/*.cls | grep -v "SECURITY_ENFORCED" | grep -v "Test.cls"

# Check for hardcoded credentials
grep -rni "password\|secret\|apikey\|api_key\|token" force-app/main/default/classes/

# Check for sharing declarations
grep -L "with sharing\|without sharing\|inherited sharing" force-app/main/default/classes/*.cls | grep -v Test.cls

# Check for merge conflicts
grep -r "<<<<<<\|======\|>>>>>>" force-app/main/default/
```

---

## 4.5 ACCESSIBILITY VALIDATION

### axe DevTools Audit

1. Install axe DevTools browser extension
2. Navigate to each LWC component page
3. Run axe scan
4. Document any violations
5. Fix critical/serious issues

### Accessibility Checklist

| Check | Validation | Status |
|-------|------------|--------|
| All images have alt text | Manual inspection | ☐ |
| Form inputs have labels | axe scan | ☐ |
| Color contrast 4.5:1 | axe scan | ☐ |
| Keyboard navigation works | Tab through UI | ☐ |
| Focus indicators visible | Keyboard test | ☐ |
| ARIA attributes present | axe scan | ☐ |
| Screen reader compatible | VoiceOver/NVDA test | ☐ |

### WCAG 2.1 AA Requirements

- **Perceivable:** Text alternatives, captions, adaptable content
- **Operable:** Keyboard accessible, enough time, no seizures
- **Understandable:** Readable, predictable, input assistance
- **Robust:** Compatible with assistive technologies

---

## 4.6 GOVERNOR LIMIT STRESS TESTING

### Bulk Data Tests

```apex
@IsTest
static void testBulkProcessing() {
    // Create 200 records (Salesforce trigger batch size)
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
        accounts.add(new Account(Name = 'Test ' + i));
    }
    insert accounts;

    // Create 200 related records
    List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();
    for (Integer i = 0; i < 200; i++) {
        gaps.add(new Compliance_Gap__c(
            Account__c = accounts[i].Id,
            Status__c = 'OPEN',
            Severity__c = 'HIGH'
        ));
    }

    Test.startTest();
    insert gaps;
    Test.stopTest();

    // Verify no governor limit exceptions
    System.assertEquals(200, [SELECT COUNT() FROM Compliance_Gap__c]);
}
```

### Governor Limit Monitoring

```apex
// Add to test classes
@IsTest
static void testGovernorLimits() {
    Test.startTest();

    // Call method being tested
    MyService.processRecords(testRecords);

    Test.stopTest();

    // Log governor stats
    System.debug('SOQL queries used: ' + Limits.getQueries());
    System.debug('DML statements used: ' + Limits.getDmlStatements());
    System.debug('CPU time used: ' + Limits.getCpuTime());
    System.debug('Heap size used: ' + Limits.getHeapSize());

    // Assert reasonable limits
    System.assert(Limits.getQueries() < 50, 'Too many SOQL queries');
    System.assert(Limits.getDmlStatements() < 50, 'Too many DML statements');
}
```

### Stress Test Scenarios

| Scenario | Records | Expected Result |
|----------|---------|-----------------|
| Insert 200 gaps | 200 | No errors |
| Update 200 gaps | 200 | No errors |
| Delete 200 gaps | 200 | No errors |
| Complex query | 10,000 | < 100 SOQL |
| Report generation | 5,000 | < 30 seconds |

---

## 4.7 MOBILE RESPONSIVENESS

### Device Testing Matrix

| Device | OS | Browser | Status |
|--------|-----|---------|--------|
| iPhone 14 | iOS 17 | Safari | ☐ |
| iPhone 12 | iOS 16 | Safari | ☐ |
| Samsung S23 | Android 14 | Chrome | ☐ |
| Samsung S21 | Android 13 | Chrome | ☐ |
| iPad Pro 12.9" | iPadOS 17 | Safari | ☐ |
| iPad 10.2" | iPadOS 16 | Safari | ☐ |

### Mobile Checklist

| Check | Status |
|-------|--------|
| Dashboard renders correctly | ☐ |
| Charts display properly | ☐ |
| Buttons are tappable (44px minimum) | ☐ |
| Forms work on touch | ☐ |
| Horizontal scrolling prevented | ☐ |
| Text readable without zoom | ☐ |
| Navigation works | ☐ |

---

## 4.8 INTEGRATION TESTING

### End-to-End Test Scenarios

#### Scenario 1: New User Onboarding
1. Assign Prometheion_User permission set
2. Access Prometheion app
3. View dashboard
4. Select HIPAA framework
5. View gaps
6. Expected: All views load without errors

#### Scenario 2: Gap Remediation
1. Create new compliance gap
2. Assign to user
3. Add remediation notes
4. Upload evidence
5. Mark as remediated
6. Expected: Gap status updates, evidence attached

#### Scenario 3: Report Generation
1. Navigate to Reports
2. Select date range (last 30 days)
3. Select all frameworks
4. Generate PDF
5. Expected: Report downloads within 30 seconds

#### Scenario 4: AI Copilot
1. Open Copilot
2. Ask: "What are our critical HIPAA gaps?"
3. Click suggested action
4. Expected: Navigates to filtered gap list

#### Scenario 5: Scheduled Job
1. Run WeeklyScorecardScheduler manually
2. Check Integration_Error__c for errors
3. Verify Slack/Teams notification sent
4. Expected: No errors, notification received

---

## 4.9 FINAL REVIEW CHECKLIST

### Code Quality

- [ ] All Apex classes compile
- [ ] All LWC components compile
- [ ] No ESLint errors
- [ ] No PMD critical/high issues
- [ ] Code comments present for complex logic
- [ ] Consistent naming conventions

### Documentation

- [ ] Installation Guide reviewed
- [ ] User Guide reviewed
- [ ] Admin Guide reviewed
- [ ] API Reference reviewed
- [ ] All screenshots current
- [ ] All links working

### AppExchange Listing

- [ ] Title optimized for search
- [ ] Description compelling and accurate
- [ ] All 10+ screenshots uploaded
- [ ] Demo video uploaded
- [ ] Pricing configured
- [ ] Support information complete
- [ ] Privacy policy link added
- [ ] Terms of service link added

### Package

- [ ] Package version correct (3.0.0)
- [ ] Namespace configured (if applicable)
- [ ] Dependencies listed
- [ ] Installation key set (if applicable)

---

## 4.10 APPEXCHANGE SUBMISSION

### Step 1: Create Package Version

```bash
# Create new package version
sfdx force:package:version:create \
  --package "Prometheion" \
  --installationkey <key> \
  --wait 30 \
  --codecoverage

# Promote to released
sfdx force:package:version:promote \
  --package "Prometheion@3.0.0-1"
```

### Step 2: Security Review

1. Log in to Partner Community
2. Navigate to Publishing > Security Review
3. Submit package for review
4. Upload security questionnaire
5. Wait for approval (1-2 weeks)

### Step 3: Listing Submission

1. Navigate to Publishing > Listings
2. Create/Update listing
3. Fill all required fields
4. Upload screenshots and video
5. Submit for review

### Step 4: Post-Submission

- [ ] Monitor email for reviewer questions
- [ ] Respond within 24 hours
- [ ] Address any feedback immediately
- [ ] Track approval status in Partner Portal

---

## 4.11 ROLLBACK PLAN

### If Submission Rejected

1. **Document feedback** - Capture all reviewer comments
2. **Prioritize fixes** - Critical issues first
3. **Fix and retest** - Apply fixes, run full test suite
4. **Resubmit** - Create new package version, resubmit

### Common Rejection Reasons

| Reason | Resolution |
|--------|------------|
| Test coverage < 75% | Add missing tests |
| Security vulnerability | Apply security fixes from Phase 1 |
| Accessibility failure | Apply accessibility fixes from Phase 1 |
| Documentation incomplete | Complete Phase 3 docs |
| Governor limit issues | Optimize queries/DML |

---

## 4.12 SUCCESS CRITERIA

### Phase 4 is complete when:

- [ ] All 10 mandatory requirements pass
- [ ] Apex test coverage ≥ 75%
- [ ] LWC Jest coverage ≥ 75%
- [ ] Zero critical/high security issues
- [ ] WCAG 2.1 AA compliant
- [ ] All documentation approved
- [ ] AppExchange listing approved
- [ ] Package promoted to released
- [ ] Security review submitted
- [ ] Listing submitted

---

## SIGN-OFF

| Validation | Owner | Passed | Date |
|------------|-------|--------|------|
| Apex Coverage | Claude Code | ☐ | |
| Jest Coverage | Cursor | ☐ | |
| Security Scan | Claude Code | ☐ | |
| Accessibility | Cursor | ☐ | |
| Integration Tests | Human | ☐ | |
| Mobile Tests | Human | ☐ | |
| Documentation | Human | ☐ | |
| AppExchange Listing | Human | ☐ | |

**Phase 4 Complete:** ☐
**Ready for Submission:** ☐
**Submitted Date:** ____________
**Approval Date:** ____________

---

## CONGRATULATIONS!

When all items are checked, Prometheion is ready for AppExchange!

🎉 **Next Steps:**
1. Monitor security review progress
2. Respond promptly to reviewer questions
3. Prepare launch announcement
4. Notify customers of availability
5. Set up customer support channels
