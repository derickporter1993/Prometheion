---
name: Merge Solentra into Sentinel
overview: Merge the Solentra repository into Sentinel to create a unified "Prometheion" compliance platform, combining Solentra's AI-powered compliance features (Copilot, Teams integration, threat detection) with Sentinel's advanced analytics components (KPI Dashboard, Matrix Analytics, Trend Analyzer).
todos:
  - id: backup-branch
    content: Create backup branch in Sentinel repo before merge
    status: completed
  - id: add-remote
    content: Add Solentra as git remote and fetch branches
    status: completed
  - id: merge-repos
    content: Merge Solentra into Sentinel with --allow-unrelated-histories
    status: completed
  - id: resolve-apex-conflicts
    content: Resolve conflicts for 21 overlapping Apex classes
    status: completed
  - id: resolve-lwc-conflicts
    content: Resolve conflicts for 7 overlapping LWC components
    status: completed
    dependencies:
      - resolve-apex-conflicts
  - id: resolve-object-conflicts
    content: Resolve conflicts for 7 overlapping custom objects
    status: completed
    dependencies:
      - resolve-lwc-conflicts
  - id: rename-branding
    content: Rename Sentinel_/Solentra_ prefixes to Prometheion_
    status: completed
    dependencies:
      - resolve-object-conflicts
  - id: consolidate-package-json
    content: Merge package.json dependencies from both repos
    status: completed
    dependencies:
      - rename-branding
  - id: update-api-version
    content: Update all metadata to API version 65.0
    status: completed
    dependencies:
      - consolidate-package-json
  - id: deploy-test
    content: Deploy to scratch org and run all Apex tests
    status: completed
    dependencies:
      - update-api-version
  - id: verify-test-coverage
    content: Verify all Apex classes have 80%+ test coverage
    status: completed
    dependencies:
      - deploy-test
  - id: validate-security-practices
    content: Validate all code follows security best practices (WITH SECURITY_ENFORCED, with sharing, etc.)
    status: completed
    dependencies:
      - verify-test-coverage
  - id: code-quality-review
    content: Review code quality and developer best practices compliance
    status: completed
    dependencies:
      - validate-security-practices
  - id: update-docs
    content: Update README with combined documentation
    status: completed
    dependencies:
      - code-quality-review
---

# Merge Solentra + Sentinel into Unified Prometheion Platform

## Analysis Summary

### Repository Comparison

| Aspect | Sentinel (sentinel-code) | Solentra |

|--------|-------------------------|----------|

| **GitHub Remote** | `derickporter1993/Sentinel` | `derickporter1993/Solentra` |

| **Package Name** | prometheion v3.0 | solentra v1.0 |

| **API Version** | 65.0 | 64.0 |

| **Apex Classes** | 41 classes | 50 classes |

| **LWC Components** | 14 components | 14 components |

| **Custom Objects** | 11 objects | 14 objects |

### Overlapping Components (21 Apex Classes, 7 LWCs, 7 Objects)

These exist in BOTH repositories and will need conflict resolution:

**Apex Classes (21 shared):**

- Core monitoring: `AlertHistoryService`, `ApiUsageSnapshot`, `FlowExecutionLogger`, `PerformanceRuleEngine`
- Notifications: `SlackNotifier`
- Metrics: `DeploymentMetrics`, `LimitMetrics`, `FlowExecutionStats`
- Plus their test classes

**LWC Components (7 shared):**

- `apiUsageDashboard`, `deploymentMonitorDashboard`, `flowExecutionMonitor`
- `performanceAlertPanel`, `pollingManager`, `systemMonitorDashboard`

**Custom Objects (7 shared):**

- `Alert__c`, `API_Usage_Snapshot__c`, `CCX_Settings__c`, `Deployment_Job__c`
- `Flow_Execution__c`, `Performance_Alert__e`, `Performance_Alert_History__c`

### Unique to Solentra (to be merged in)

**Apex Classes (29 unique):**

- AI Copilot: `SolentraComplianceCopilot`, `PrometheionChangeAdvisor`, `PrometheionRemediationEngine`
- Threat Detection: `PrometheionSalesforceThreatDetector`, `PrometheionAuditTrailPoller`
- Notifications: `TeamsNotifier`, `WeeklyScorecardScheduler`
- Event Processing: `PrometheionEventPublisher`, `PrometheionScoreCallback`
- Constants: `SolentraConstants`
- Legacy Sentinel: `SentinelGraphIndexer`, `SentinelReasoningEngine`, `SentinelLegalDocumentGenerator`

**LWC Components (7 unique):**

- `complianceCopilot`, `solentraCopilot`, `solentraDashboard`
- `prometheionROICalculator`, `prometheionScoreListener`
- `sentinelAiSettings`, `sentinelReadinessScore`

**Custom Objects (7 unique):**

- `Compliance_Policy__mdt`, `Compliance_Score__c`
- `Sentinel_AI_Settings__c`, `Sentinel_Alert_Event__e`, `Sentinel_Compliance_Graph__b`
- `Solentra_Compliance_Graph__b`, `Solentra_Settings__c`

### Unique to Sentinel (already present)

**Apex Classes (20 unique):**

- Analytics Controllers: `PrometheionDynamicReportController`, `PrometheionExecutiveKPIController`
- Matrix/Drill-down: `PrometheionMatrixController`, `PrometheionDrillDownController`
- Trends: `PrometheionTrendController`
- AI: `PrometheionReasoningEngine`, `PrometheionGraphIndexer`
- Plus their test classes

**LWC Components (7 unique):**

- `prometheionAiSettings`, `prometheionComparativeAnalytics`, `prometheionDrillDownViewer`
- `prometheionDynamicReportBuilder`, `prometheionExecutiveKPIDashboard`
- `prometheionReadinessScore`, `prometheionTrendAnalyzer`

**Custom Objects (4 unique):**

- `Executive_KPI__mdt`, `Prometheion_AI_Settings__c`
- `Prometheion_Alert_Event__e`, `Prometheion_Compliance_Graph__b`

---

## Quality Standards (Required)

All merged code must meet these standards as of January 3, 2026:

### Test Coverage Requirements

- **Minimum 80% coverage** for all Apex classes
- Test all positive, negative, and edge cases
- Include governor limit testing
- Use `@TestSetup` for efficient test data
- Mock all external callouts

### Security Best Practices

- **WITH SECURITY_ENFORCED** on all SOQL queries
- **with sharing** on all Apex classes (unless explicitly `without sharing`)
- **Security.stripInaccessible()** before DML operations
- Input validation and SOQL injection prevention
- Object/field/operator whitelisting for dynamic queries
- Protected Custom Metadata for sensitive data (API keys)

### Code Quality Standards

- Follow Salesforce Apex Style Guide
- Meaningful variable and method names
- Comprehensive documentation for public methods
- Proper error handling with user-friendly messages
- No hardcoded values (use Custom Settings/Metadata)
- Bulkified code (no SOQL/DML in loops)

### Developer Best Practices

- Consistent naming conventions (Prometheion prefix)
- DRY principle (Don't Repeat Yourself)
- Single Responsibility Principle
- Proper separation of concerns
- Version control best practices (meaningful commits)

---

## Recommended Approach: Merge Solentra INTO Sentinel

**Why Sentinel as the base:**

1. Sentinel uses API v65.0 (newer) vs Solentra's v64.0
2. Sentinel has more developed analytics (KPI, Matrix, Trends)
3. Sentinel already has "Prometheion" branding throughout
4. Sentinel is more actively developed (more branches, recent changes)

---

## Merge Strategy

### Phase 1: Pre-Merge Preparation

1. Create backup branch in Sentinel
2. Standardize naming to "Prometheion" brand
3. Resolve naming conflicts (Sentinel/Solentra prefixes -> Prometheion)

### Phase 2: Merge Execution

1. Add Solentra as git remote
2. Merge with `--allow-unrelated-histories`
3. Resolve conflicts for 21 overlapping Apex classes
4. Resolve conflicts for 7 overlapping LWCs
5. Resolve conflicts for 7 overlapping Objects

### Phase 3: Post-Merge Cleanup

1. Rename all "Sentinel*" and "Solentra*" prefixes to "Prometheion\_"
2. Update all references in code
3. Consolidate duplicate functionality
4. Update API version to 65.0
5. Merge package.json dependencies
6. Update README with combined documentation

### Phase 4: Quality Validation

1. **Deploy & Test**
   - Deploy to scratch org
   - Run all Apex tests with code coverage
   - Verify 80%+ coverage on all classes

2. **Security Audit**
   - Verify `WITH SECURITY_ENFORCED` on all SOQL
   - Check `with sharing` on all classes
   - Validate input sanitization
   - Review FLS/CRUD enforcement

3. **Code Quality Review**
   - Check naming conventions (Prometheion prefix)
   - Verify bulkification (no SOQL in loops)
   - Review error handling
   - Validate documentation

4. **Functional Testing**
   - Test LWC functionality
   - Validate AI Copilot integration
   - Test all analytics dashboards
   - Verify notifications (Slack/Teams)

---

## Conflict Resolution Strategy

For the 21 overlapping Apex classes, compare and choose:

- Use Sentinel version if it has newer code/fixes
- Use Solentra version if it has additional features
- Merge features from both if significantly different

Key files to compare:

- [SlackNotifier.cls](force-app/main/default/classes/SlackNotifier.cls) - has known issues in Sentinel
- [PerformanceRuleEngine.cls](force-app/main/default/classes/PerformanceRuleEngine.cls) - CCX_Settings dependency

---

## Post-Merge Unified Structure

```
prometheion/
  force-app/main/default/
    classes/
      # Core Monitoring (from both)
      AlertHistoryService.cls
      ApiUsageSnapshot.cls
      FlowExecutionLogger.cls
      PerformanceRuleEngine.cls

      # AI & Compliance (from Solentra)
      PrometheionComplianceCopilot.cls
      PrometheionChangeAdvisor.cls
      PrometheionRemediationEngine.cls
      PrometheionSalesforceThreatDetector.cls

      # Analytics (from Sentinel)
      PrometheionDynamicReportController.cls
      PrometheionExecutiveKPIController.cls
      PrometheionMatrixController.cls
      PrometheionTrendController.cls

      # Notifications (merged)
      SlackNotifier.cls
      TeamsNotifier.cls

    lwc/
      # Core dashboards (from both)
      apiUsageDashboard/
      systemMonitorDashboard/

      # AI Copilot (from Solentra)
      prometheionCopilot/  # renamed from solentraCopilot

      # Analytics (from Sentinel)
      prometheionExecutiveKPIDashboard/
      prometheionDynamicReportBuilder/
      prometheionTrendAnalyzer/

    objects/
      # Unified Prometheion objects
      Prometheion_AI_Settings__c/
      Prometheion_Compliance_Graph__b/
      Compliance_Policy__mdt/
      Compliance_Score__c/
      Executive_KPI__mdt/
```

---

## Next Steps

To proceed, switch to **Agent mode** and I will:

1. **Backup & Prepare**
   - Create backup branch in Sentinel
   - Add Solentra as remote

2. **Execute Merge**
   - Merge with `--allow-unrelated-histories`
   - Resolve all 35 component conflicts intelligently
   - Preserve best features from both repos

3. **Quality Assurance**
   - Ensure 80%+ test coverage on ALL classes
   - Apply 2026 security best practices
   - Follow Salesforce coding standards
   - Bulkify all code

4. **Branding & Cleanup**
   - Rename to Prometheion branding
   - Consolidate dependencies
   - Update to API v65.0

5. **Validation**
   - Deploy to scratch org
   - Run comprehensive test suite
   - Verify security compliance
   - Functional testing of all features

**Quality Guarantee**: All code will meet or exceed 80% test coverage and follow current Salesforce security best practices.
