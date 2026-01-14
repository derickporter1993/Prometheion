# LWC Jest Test Coverage Improvement Plan

**Priority:** P1 (Critical for AppExchange)  
**Estimated Time:** 2 hours for audit + implementation  
**Status:** 🚧 IN PROGRESS  
**Last Updated:** January 10, 2026

---

## Current Status

### Test Coverage Audit Results

| Metric | Current | Target | Gap |
|--------|---------|--------|-----|
| **Total Components** | 34 | 34 | - |
| **Components with Tests** | 6 (18%) | 34 (100%) | 28 components |
| **Code Coverage** | 0% | 75%+ | 75 points |
| **Tests Passing** | 168 | 168+ | - |

### Components with Tests (6/34)

✅ `prometheionDashboard` - Tests exist, passing  
✅ `prometheionAuditWizard` - Tests exist, passing  
✅ `prometheionEventExplorer` - Tests exist, passing  
✅ `prometheionCopilot` - Tests exist, passing  
✅ `complianceCopilot` - Tests exist, passing  
✅ `controlMappingMatrix` - Tests exist, passing  

### Components Without Tests (28/34)

🔴 **High Priority (Core Components):**
- `apiUsageDashboard` (75 lines)
- `systemMonitorDashboard` (54 lines)
- `complianceDashboard` (38 lines)
- `complianceScoreCard` (98 lines)
- `complianceGapList` (17 lines)
- `auditReportGenerator` (79 lines)
- `performanceAlertPanel` (85 lines)
- `flowExecutionMonitor` (37 lines)

🟡 **Medium Priority (Supporting Components):**
- `complianceTimeline` (35 lines)
- `complianceTrendChart` (25 lines)
- `deploymentMonitorDashboard` (39 lines)
- `executiveKpiDashboard` (52 lines)
- `frameworkSelector` (41 lines)
- `prometheionAiSettings` (74 lines)
- `prometheionAuditPackageBuilder` (80 lines)
- `prometheionReadinessScore` (183 lines)
- `prometheionROICalculator` (153 lines)

🟢 **Lower Priority (Auxiliary Components):**
- `prometheionComparativeAnalytics` (164 lines)
- `prometheionDrillDownViewer` (147 lines)
- `prometheionDynamicReportBuilder` (288 lines)
- `prometheionEventMonitor` (68 lines)
- `prometheionExecutiveKPIDashboard` (82 lines)
- `prometheionScoreListener` (102 lines)
- `prometheionTrendAnalyzer` (168 lines)
- `riskHeatmap` (31 lines)

---

## Implementation Strategy

### Phase 1: Establish Testing Pattern (30 min)

**Goal:** Create a comprehensive test template based on existing successful tests

**Actions:**
1. Analyze existing test patterns from `prometheionDashboard.test.js`
2. Document wire adapter mocking strategy
3. Create reusable test utilities if needed
4. Identify common test patterns (wire adapters, navigation, toast events)

**Deliverable:** Test template and patterns documentation

### Phase 2: Add Tests for High Priority Components (60 min)

**Priority Order:**
1. `apiUsageDashboard` - API usage tracking (high visibility)
2. `systemMonitorDashboard` - Governor limits monitoring (critical)
3. `complianceDashboard` - Main compliance view (core feature)
4. `complianceScoreCard` - Score display (user-facing)
5. `complianceGapList` - Gap listing (simple, good starter)
6. `auditReportGenerator` - Report generation (important feature)
7. `performanceAlertPanel` - Alert display (real-time)
8. `flowExecutionMonitor` - Flow monitoring (automation)

**Test Coverage Goals Per Component:**
- **Minimum:** 60% statement coverage
- **Target:** 75%+ statement coverage
- **Ideal:** 80%+ statement coverage

**Test Types Per Component:**
- ✅ Rendering tests (component mounts correctly)
- ✅ Wire adapter data handling (success/error paths)
- ✅ User interactions (button clicks, selections)
- ✅ Computed properties/getters
- ✅ Navigation events
- ✅ Toast notifications
- ✅ Error handling
- ✅ Loading states

### Phase 3: Add Tests for Medium Priority Components (30 min)

**Components (8):**
- `complianceTimeline`, `complianceTrendChart`
- `deploymentMonitorDashboard`, `executiveKpiDashboard`
- `frameworkSelector`, `prometheionAiSettings`
- `prometheionAuditPackageBuilder`, `prometheionReadinessScore`

**Focus:** Essential functionality and critical paths only

### Phase 4: Input Validation Tests (P1 - Separate Task)

**Scope:** Add null/empty/boundary tests to existing tests

**Pattern:**
```javascript
describe('Input Validation', () => {
  it('handles null data gracefully', () => {});
  it('handles empty arrays', () => {});
  it('handles undefined properties', () => {});
  it('handles boundary values', () => {});
});
```

**Components to Enhance:**
- All components with user inputs
- All components with data processing
- Components with numeric inputs (boundary testing)

### Phase 5: Bulk Operation Tests (P1 - Separate Task)

**Scope:** Test components with data lists handling 200+ records

**Pattern:**
```javascript
describe('Bulk Operations', () => {
  it('handles 200+ records efficiently', () => {
    const bulkData = Array.from({ length: 250 }, (_, i) => ({ id: i }));
    // Test rendering, pagination, filtering
  });
});
```

**Components Requiring Bulk Tests:**
- `complianceGapList` - Multiple gaps
- `complianceDashboard` - Multiple frameworks
- `prometheionEventExplorer` - Multiple events
- `apiUsageDashboard` - Multiple API calls
- `auditReportGenerator` - Multiple reports

---

## Test Template Pattern

Based on `prometheionDashboard.test.js`, the standard test structure:

```javascript
/**
 * Jest tests for {componentName} LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Wire adapter data handling
 * - User interactions
 * - Error handling
 * - Accessibility compliance
 */

import { createElement } from "lwc";
import ComponentName from "c/componentName";
import { safeCleanupDom } from "../../__tests__/wireAdapterTestUtils";

// Mock wire adapters (if needed)
jest.mock("@salesforce/apex/Controller.method", () => ({
  default: function MockAdapter(callback) {
    if (new.target) {
      this.callback = callback;
      this.connect = () => {};
      this.disconnect = () => {};
      this.update = () => {};
      return this;
    }
    return Promise.resolve({});
  },
}), { virtual: true });

describe("c-component-name", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    safeCleanupDom();
  });

  describe("Initial Rendering", () => {
    it("renders the component", () => {});
    it("displays data from wire adapter", () => {});
    it("shows loading state initially", () => {});
  });

  describe("User Interactions", () => {
    it("handles button clicks", () => {});
    it("handles selection changes", () => {});
  });

  describe("Error Handling", () => {
    it("handles wire adapter errors gracefully", () => {});
    it("shows error messages", () => {});
  });

  describe("Accessibility", () => {
    it("has proper ARIA labels", () => {});
    it("is keyboard navigable", () => {});
  });
});
```

---

## Success Criteria

### Phase 2 Completion (High Priority)
- ✅ 8 high-priority components have tests
- ✅ Minimum 60% statement coverage per component
- ✅ All tests passing
- ✅ No regression in existing tests

### Overall Completion
- ✅ 34/34 components have tests (100%)
- ✅ Overall code coverage ≥ 75%
- ✅ All 168+ tests passing
- ✅ Input validation tests added to all applicable components
- ✅ Bulk operation tests added where needed

---

## Next Steps

1. **Immediate (Next 30 min):**
   - [ ] Analyze existing test patterns
   - [ ] Create test template
   - [ ] Start with `apiUsageDashboard` (first high-priority component)

2. **Short-term (Next 2 hours):**
   - [ ] Complete Phase 2 (8 high-priority components)
   - [ ] Verify coverage improvement
   - [ ] Run full test suite

3. **Medium-term (Next sprint):**
   - [ ] Complete Phase 3 (medium-priority components)
   - [ ] Add input validation tests
   - [ ] Add bulk operation tests

---

## Notes

- **Existing test infrastructure:** Good - wire adapter utilities exist, mocking patterns established
- **Complexity:** Medium - Most components follow similar patterns, wire adapters well-documented
- **Blockers:** None - All dependencies available, test environment configured
- **Risk:** Low - Tests are additive, won't break existing functionality

---

_Plan created: January 10, 2026_  
_Status: Ready for implementation_
