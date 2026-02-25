# ELARO TEAM 1 — AGENT BUILD PROMPTS

> **Instructions**: Read CLAUDE.md first (it contains all coding standards).
> Then execute these agent prompts in order. Each agent builds one workstream.
> Team 1 owns the sovereign infrastructure layer: async framework, compliance modules,
> rule engine, orchestration, and EU regulatory bundles.
> After completing each agent, run `sf scanner run` and `sf apex run test` before proceeding.

---

## AGENT 1: WS6 — STEP-BASED ASYNC FRAMEWORK (Q1, Weeks 1-8)

**Package**: Main Elaro 2GP
**Directory**: `force-app/main/default/`
**Priority**: HIGHEST — everything else depends on this

### What This Is

A modular async processing framework replacing Batch Apex with Cursors + Queueable (Spring '26 GA).
All future compliance scans, rule evaluations, and data processing run through this framework.

### Build Order

1. Interfaces and abstract classes (Step, CursorStep, ComputeStep, DMLStep, CalloutStep)
2. StepContext and StepProcessor
3. Transaction Finalizer
4. FlowStep and NoOpStep
5. StepLog\_\_e Platform Event
6. Test classes (test each Step in isolation)
7. Feature flag Custom Setting
8. Batch migration utilities

### Core Framework Classes

**1. Step.cls** (Interface)

```apex
/**
 * Contract for all executable steps in the Elaro async processing framework.
 * Each step represents a discrete unit of work that can be composed into workflows.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 */
public interface Step {
    void execute(StepContext ctx);
    void finalize(StepContext ctx);
    String getName();
    Boolean shouldRestart();
}
```

**2. CursorStep.cls** (Abstract Class)

```apex
/**
 * Abstract step that wraps Database.getCursor() for processing large datasets.
 * Subclasses implement getCursorQuery() and innerExecute(List<SObject>).
 * The framework handles cursor creation, position tracking, and re-enqueueing.
 *
 * Uses a virtual Cursor wrapper to enable test mocking via CursorLike subclass.
 * NEVER instantiate real cursors in unit tests.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 * @see Step
 * @see StepProcessor
 */
public abstract inherited sharing class CursorStep implements Step {
    // Cursor limits: 50M rows/cursor, 10 fetch/txn, 10K instances/day
    // Max 2,000 records per fetch(). Each fetch counts against SOQL query limit.

    public abstract String getCursorQuery();
    public abstract Map<String, Object> getCursorBinds();
    public abstract void innerExecute(List<SObject> records, StepContext ctx);

    // Virtual cursor wrapper for testability
    public virtual class CursorWrapper {
        private Database.Cursor realCursor;
        public virtual List<SObject> fetch(Integer position, Integer count) {
            return realCursor.fetch(position, count);
        }
        public virtual Integer getNumRecords() {
            return realCursor.getNumRecords();
        }
    }

    // Test mock
    public class CursorLike extends CursorWrapper {
        private List<SObject> testData;
        public CursorLike(List<SObject> data) { this.testData = data; }
        public override List<SObject> fetch(Integer position, Integer count) {
            Integer endPos = Math.min(position + count, testData.size());
            List<SObject> chunk = new List<SObject>();
            for (Integer i = position; i < endPos; i++) chunk.add(testData[i]);
            return chunk;
        }
        public override Integer getNumRecords() { return testData.size(); }
    }

    public void execute(StepContext ctx) {
        // Create cursor from query, process chunk, update position in ctx
    }

    public abstract void finalize(StepContext ctx);
    public abstract String getName();
    public Boolean shouldRestart() { return true; } // Default: restart if more records
}
```

**3. ComputeStep.cls** (Abstract) — Non-query computational steps

```apex
public abstract inherited sharing class ComputeStep implements Step {
    public abstract Object compute(StepContext ctx);
    // execute() calls compute() and stores result in ctx
}
```

**4. DMLStep.cls** (Abstract) — DML operations with auto-chunking

```apex
public abstract inherited sharing class DMLStep implements Step {
    // Auto-chunks records into batches of 200 for DML
    // Always uses 'insert as user', 'update as user' etc.
    public abstract List<SObject> getRecordsToProcess(StepContext ctx);
    public abstract void processBatch(List<SObject> batch, StepContext ctx);
}
```

**5. CalloutStep.cls** (Abstract) — HTTP callouts that respect callout-after-DML

```apex
public abstract inherited sharing class CalloutStep implements Step {
    // Defers callout to Finalizer context if DML occurred earlier in chain
    // Uses Transaction Finalizer pattern from CLAUDE.md
    public abstract HttpRequest buildRequest(StepContext ctx);
    public abstract void handleResponse(HttpResponse res, StepContext ctx);
}
```

**6. StepContext.cls** — Carries state between steps

```apex
/**
 * Serializable context object passed between steps in a workflow.
 * Stores cursor position, execution metrics, error history, and arbitrary state.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 */
public inherited sharing class StepContext {
    public Map<String, Object> state { get; set; }
    public Integer cursorPosition { get; set; }
    public Integer currentStepIndex { get; set; }
    public List<StepExecutionMetric> metrics { get; set; }
    public List<String> errorHistory { get; set; }
    public Id workflowId { get; set; }

    public StepContext() {
        this.state = new Map<String, Object>();
        this.cursorPosition = 0;
        this.currentStepIndex = 0;
        this.metrics = new List<StepExecutionMetric>();
        this.errorHistory = new List<String>();
    }

    // Convenience typed getters
    public Object get(String key) { return state.get(key); }
    public void put(String key, Object value) { state.put(key, value); }
    public String getString(String key) { return (String) state.get(key) ?? ''; }
    public Integer getInteger(String key) { return (Integer) state.get(key) ?? 0; }
}
```

**7. StepProcessor.cls** — Queueable + Finalizer orchestrator

```apex
/**
 * Core orchestrator that executes a sequence of Steps as Queueable jobs.
 * Implements System.Queueable and System.Finalizer for retry and error handling.
 *
 * On SUCCESS: advances to next step or restarts current step (if shouldRestart()).
 * On UNHANDLED_EXCEPTION: logs error, halts (configurable retry count).
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 */
public inherited sharing class StepProcessor implements Queueable, Finalizer {
    private List<Step> steps;
    private StepContext ctx;
    private Integer maxRetries;

    public StepProcessor(List<Step> steps, StepContext ctx) {
        this.steps = steps;
        this.ctx = ctx;
        this.maxRetries = 3;
    }

    public void execute(QueueableContext qCtx) {
        System.attachFinalizer(this);

        // Check circuit breakers before executing
        if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs() - 1) {
            ElaroLogger.error('StepProcessor', 'Queueable limit approaching, halting', '');
            return;
        }

        Step current = steps[ctx.currentStepIndex];
        Long startTime = System.currentTimeMillis();

        current.execute(ctx);

        // Log execution metric
        ctx.metrics.add(new StepExecutionMetric(
            current.getName(), System.currentTimeMillis() - startTime, true
        ));

        // Publish StepLog__e (Publish Immediately — survives rollback)
        publishStepLog(current.getName(), true, null);
    }

    public void execute(FinalizerContext fCtx) {
        if (fCtx.getResult() == ParentJobResult.SUCCESS) {
            Step current = steps[ctx.currentStepIndex];
            if (current.shouldRestart()) {
                // Re-enqueue for more records (cursor processing)
                enqueueNext();
            } else {
                current.finalize(ctx);
                ctx.currentStepIndex++;
                if (ctx.currentStepIndex < steps.size()) {
                    ctx.cursorPosition = 0;
                    enqueueNext();
                }
            }
        } else if (fCtx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
            String error = fCtx.getException()?.getMessage() ?? 'Unknown error';
            ctx.errorHistory.add(error);
            ElaroLogger.error('StepProcessor.Finalizer', error, '');
            publishStepLog(steps[ctx.currentStepIndex].getName(), false, error);

            // Retry with exponential backoff if under max retries
            // Use AsyncOptions.setMinimumQueueableDelayInMinutes() for backoff
        }
    }

    // Use AsyncOptions for duplicate prevention
    private void enqueueNext() {
        AsyncOptions options = new AsyncOptions();
        options.setMaximumQueueableStackDepth(10);
        System.enqueueJob(this, options);
    }
}
```

**8. StepExecutionMetric.cls** — Wrapper for execution tracking

`stepName` (String), `executionTimeMs` (Long), `success` (Boolean), `errorMessage` (String), `recordsProcessed` (Integer)

**9. FlowStep.cls** — Wraps Flow.Interview for declarative steps

```apex
public inherited sharing class FlowStep implements Step {
    private String flowApiName;
    public FlowStep(String flowApiName) { this.flowApiName = flowApiName; }
    public void execute(StepContext ctx) {
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.putAll(ctx.state);
        Flow.Interview flow = Flow.Interview.createInterview(flowApiName, inputs);
        flow.start();
    }
}
```

**10. NoOpStep.cls** — Null object pattern for feature-flagged steps

```apex
public inherited sharing class NoOpStep implements Step {
    public void execute(StepContext ctx) { /* intentionally empty */ }
    public void finalize(StepContext ctx) { /* intentionally empty */ }
    public String getName() { return 'NoOp'; }
    public Boolean shouldRestart() { return false; }
}
```

### Platform Event

**11. StepLog\_\_e** (`force-app/main/default/objects/`)

- `Step_Name__c` (Text 80)
- `Execution_Time_Ms__c` (Number)
- `Success__c` (Checkbox)
- `Error_Message__c` (Text Area 1000)
- `Records_Processed__c` (Number)
- `Workflow_Id__c` (Text 18)
- `Timestamp__c` (DateTime)

### Feature Flag

**12. Elaro_Async_Framework_Flags\_\_c** (Hierarchy Custom Setting)

- `Use_New_Async_Framework__c` (Checkbox, default true)
- `Max_Retry_Count__c` (Number, default 3)
- `Max_Cursor_Fetch_Size__c` (Number, default 200)

### Test Classes

13. **StepProcessorTest.cls** — Test step sequencing, re-enqueue, error handling, finalizer
14. **CursorStepTest.cls** — Test using CursorLike mock, test position tracking, test empty data
15. **DMLStepTest.cls** — Test auto-chunking, test 'as user' enforcement
16. **CalloutStepTest.cls** — Test with HttpCalloutMock, test DML-before-callout deferral
17. **ComputeStepTest.cls** — Test state passing, result storage
18. **FlowStepTest.cls** — Test Flow.Interview invocation
19. **StepContextTest.cls** — Test serialization, typed getters, state manipulation

### Permission Sets

`Elaro_Async_Admin.permissionset-meta.xml`: Access to Custom Setting, StepLog\_\_e subscribe

### Batch Migration Pattern (for Agents 2+)

When migrating existing batch classes, follow this pattern:

```apex
// OLD: Batch Apex
public class ComplianceScanBatch implements Database.Batchable<SObject> { ... }

// NEW: CursorStep (mark old class @Deprecated)
/**
 * @deprecated Use ComplianceScanCursorStep with StepProcessor instead
 */
public class ComplianceScanBatch implements Database.Batchable<SObject> { ... }

public class ComplianceScanCursorStep extends CursorStep {
    public override String getCursorQuery() {
        return 'SELECT Id, Status__c FROM Compliance_Finding__c WHERE Status__c = :status WITH USER_MODE';
    }
    public override Map<String, Object> getCursorBinds() {
        return new Map<String, Object>{ 'status' => 'Active' };
    }
    public override void innerExecute(List<SObject> records, StepContext ctx) {
        // Migrated from old execute() method
    }
}
```

Cannot delete `@Deprecated` classes from released managed packages. Use feature flag to toggle.

---

## AGENT 2: WS1 — CMMC 2.0 MODULE (Q1-Q2, Weeks 2-16)

**Package**: Main Elaro 2GP
**Priority**: HIGH — defense industrial base customers waiting

### Custom Objects (10)

**1. CMMC_Domain\_\_c** — 14 control families (AC, AT, AU, CM, IA, IR, MA, MP, PE, PS, RA, RE, SC, SI)

- `Domain_Code__c` (Text 5 — e.g., 'AC')
- `Domain_Name__c` (Text 80 — e.g., 'Access Control')
- `Domain_Description__c` (Long Text Area 2000)
- `Practice_Count__c` (Rollup Summary — count of CMMC_Practice\_\_c)

**2. CMMC_Practice\_\_c** — 110 L2 + 17 L1 practices

- `CMMC_Domain__c` (Master-Detail)
- `Practice_Code__c` (Text 20 — e.g., 'AC.L2-3.1.1')
- `Practice_Description__c` (Long Text Area 5000)
- `CMMC_Level__c` (Picklist: L1/L2/L3)
- `SPRS_Weight__c` (Number: 1, 3, or 5)
- `POA_M_Eligible__c` (Formula Checkbox: SPRS_Weight\_\_c = 1)
- `NIST_171_Reference__c` (Text 20 — e.g., '3.1.1')
- `Assessment_Objectives__c` (Long Text Area 10000)
- `Discussion__c` (Long Text Area 10000)

**3. CMMC_Assessment\_\_c**

- `Assessment_Type__c` (Picklist: L1_Self/L2_Self/L2_C3PAO/L3_DIBCAC)
- `Organization__c` (Lookup Account)
- `SPRS_Score__c` (Number — calculated -203 to 110)
- `Certification_Status__c` (Picklist: Not_Started/In_Progress/Conditional/Certified/Lapsed)
- `Certificate_Expiration__c` (Date — 3-year validity from certification)
- `CMMC_UID__c` (Text 40 — unique identifier)
- `Assessment_Date__c` (Date)
- `Assessor__c` (Lookup User)

**4. CMMC_Practice_Result\_\_c** (junction)

- `CMMC_Assessment__c` (Master-Detail)
- `CMMC_Practice__c` (Master-Detail)
- `Result__c` (Picklist: MET/NOT_MET/NA)
- `Evidence_Notes__c` (Long Text Area 5000)
- `Assessor_Comments__c` (Long Text Area 5000)

**5. POA_M\_\_c** (Plan of Action & Milestones)

- `CMMC_Practice_Result__c` (Lookup)
- `Description__c` (Long Text Area 5000)
- `Milestone_Date__c` (Date)
- `Days_Remaining__c` (Formula Number: Milestone_Date - TODAY())
- `Is_Overdue__c` (Formula Checkbox: Days_Remaining < 0)
- `Status__c` (Picklist: Open/In_Progress/Completed/Overdue)
- `180_Day_Deadline__c` (Date — max remediation window)

**6. SSP\_\_c** (System Security Plan)

- `CMMC_Assessment__c` (Lookup)
- `System_Name__c` (Text 80)
- `System_Description__c` (Long Text Area 10000)
- `CUI_Data_Flows__c` (Long Text Area 10000)
- `System_Boundary__c` (Long Text Area 5000)
- `Version__c` (Text 10)
- `Last_Updated__c` (Date)

**7. Evidence\_\_c** (shared across frameworks)

- `Related_Practice__c` (Lookup CMMC_Practice_Result\_\_c)
- `File_Name__c` (Text 255)
- `File_Size__c` (Number)
- `Hash_Value__c` (Text 64 — SHA-256 for integrity verification)
- `Upload_Date__c` (DateTime)
- `Uploaded_By__c` (Lookup User)
- `Content_Version_Id__c` (Text 18 — reference to ContentVersion)

**8. C3PAO_Assessment_Tracker\_\_c**

- `CMMC_Assessment__c` (Master-Detail)
- `Phase__c` (Picklist: Pre_Assessment/Assessment/Post_Assessment/Adjudication)
- `Phase_Start_Date__c` (Date)
- `Phase_End_Date__c` (Date)
- `C3PAO_Organization__c` (Text 80)
- `Lead_Assessor__c` (Text 80)

**9. CMMC_NIST53_Mapping\_\_c** (junction to existing NIST 800-53 controls)

- `CMMC_Practice__c` (Lookup)
- `NIST_Control__c` (Lookup — to existing control objects)
- `Coverage_Type__c` (Picklist: Full/Partial/Supplemental)

### Custom Metadata

**10. CMMC_Control_Definition\_\_mdt** — All 110 L2 + 17 L1 practice definitions

**11. SPRS_Weight_Config\_\_mdt** — Weight assignments per practice

### Apex Classes

**12. CMMCComplianceService.cls** (inherited sharing)

- Implements `IComplianceModule`
- Register in `ComplianceServiceFactory`
- Methods: `assessCompliance()`, `calculateSPRSScore()`, `getAssessmentStatus()`

**13. SPRSScoreCalculator.cls** (inherited sharing)

- Calculate SPRS score: Start at 110, subtract weight for each NOT_MET practice
- Range: -203 (all 110 L2 practices NOT_MET with max weights) to 110 (all MET)
- POA&M practices (weight=1) can reduce penalty if documented

**14. CMMCAssessmentController.cls** (with sharing)

- `@AuraEnabled getAssessment(Id assessmentId)`
- `@AuraEnabled getPracticeResults(Id assessmentId)`
- `@AuraEnabled updatePracticeResult(Id resultId, String result, String notes)`
- `@AuraEnabled calculateScore(Id assessmentId)`

**15. CMMCDashboardController.cls** (with sharing)

- `@AuraEnabled getOverview()`: Domain-level compliance heat map
- `@AuraEnabled getPOAMs()`: Overdue and upcoming milestones
- `@AuraEnabled getC3PAOStatus(Id assessmentId)`: Assessment phase tracking

### LWC Components

16. **cmmcDashboard** — Domain heat map, SPRS score, POA&M tracker
17. **cmmcPracticeGrid** — 14-domain x practices grid with MET/NOT_MET/NA status
18. **cmmcSPRSGauge** — SPRS score visualization (-203 to 110)
19. **cmmcPOAMTracker** — POA&M list with deadline countdown, overdue highlights
20. **cmmcAssessmentView** — Single assessment detail with practice results

### Test Classes

21. **CMMCComplianceServiceTest.cls**
22. **SPRSScoreCalculatorTest.cls** — Test full range (-203 to 110), POA&M adjustments
23. **CMMCAssessmentControllerTest.cls**
24. **CMMCDashboardControllerTest.cls**

### Permission Sets

- `Elaro_CMMC_Admin.permissionset-meta.xml`
- `Elaro_CMMC_User.permissionset-meta.xml`
- `Elaro_CMMC_Assessor.permissionset-meta.xml` — C3PAO assessor access

---

## AGENT 3: WS3 — RULE ENGINE + ORCHESTRATION (Q2-Q3, Weeks 12-24)

**Package**: Main Elaro 2GP
**Dependency**: Async Framework (Agent 1) must be complete

### Custom Metadata Types

**1. Compliance_Rule\_\_mdt** (500-800+ rules across all frameworks)

- `Rule_Name__c` (Text 80)
- `Framework__c` (Text 40)
- `Rule_Query__c` (Long Text Area 5000 — SOQL template with bind placeholders)
- `Expected_Result__c` (Text 255)
- `Comparison_Operator__c` (Picklist: Equals/NotEquals/GreaterThan/LessThan/Contains/IsNull/IsNotNull)
- `Severity__c` (Picklist: Critical/High/Medium/Low/Informational)
- `Control_Reference__c` (Text 80)
- `Remediation_Reference__c` (Text 80 — link to Compliance_Remediation\_\_mdt)
- `Is_Active__c` (Checkbox)
- `Evaluation_Order__c` (Number)

**2. Compliance_Remediation\_\_mdt** (300-500+ remediation instructions)

- `Remediation_Name__c` (Text 80)
- `Fix_Description__c` (Long Text Area 5000)
- `Fix_Type__c` (Picklist: Manual/Auto_Remediation/Flow/Metadata_Deploy)
- `Auto_Fix_Metadata__c` (Long Text Area 10000 — JSON metadata for auto-remediation)
- `Verification_Query__c` (Long Text Area 2000 — SOQL to verify fix was applied)

**3. Compliance_Workflow_Template\_\_mdt** (15-25 workflow definitions)

- `Workflow_Name__c` (Text 80)
- `Framework__c` (Text 40)
- `Step_Order__c` (Number)
- `Step_Class_Name__c` (Text 80 — fully qualified Apex class name implementing Step)
- `Step_Config__c` (Long Text Area 5000 — JSON configuration for the step)
- `Is_Required__c` (Checkbox)

### Apex Classes

**4. ComplianceRuleEvaluator.cls** (inherited sharing, CursorStep)

- Loads rules from `Compliance_Rule__mdt` (cached in Platform Cache, 60-min TTL)
- For each rule: builds SOQL from `Rule_Query__c` using `Database.queryWithBinds()`
- Compares result against `Expected_Result__c` using `Comparison_Operator__c`
- Creates `Compliance_Finding__c` records for failures
- NEVER does DML during evaluation — collects findings, then DMLStep writes them
- MUST be idempotent: same rule + same org state = same result

**5. ComplianceOrchestrationEngine.cls** (inherited sharing)

- Reads `Compliance_Workflow_Template__mdt`
- Instantiates Step classes by name using `Type.forName()`
- Passes to `StepProcessor` for execution
- Methods: `runWorkflow(String workflowName)`, `getWorkflowStatus(Id workflowId)`

**6. RemediationService.cls** (inherited sharing)

- Reads `Compliance_Remediation__mdt` for a given finding
- For Auto_Remediation: generates metadata changes
- For Metadata_Deploy: uses `SelfHealingDeployer` (below)
- For Manual: returns instructions to user

**7. SelfHealingDeployer.cls** (without sharing — SECURITY: system context required to deploy metadata via Metadata API; requires explicit admin approval before execution)

- Generates Metadata API deploy packages from `Compliance_Remediation__mdt` instructions
- Creates `Remediation_Deployment__c` record with before/after values
- Requires Approval Process completion before deployment executes
- Uses Metadata API via HttpRequest (SOAP or REST)

**8. ComplianceScoreAggregator.cls** (inherited sharing, CursorStep)

- Aggregates findings across frameworks
- Calculates composite scores per framework
- Updates compliance dashboards

**9. RuleEngineController.cls** (with sharing)

- `@AuraEnabled evaluateFramework(String framework)`: Triggers full evaluation
- `@AuraEnabled getFindings(String framework, String severity)`: Returns findings
- `@AuraEnabled getRemediationPlan(Id findingId)`: Returns remediation instructions
- `@AuraEnabled approveRemediation(Id deploymentId)`: Triggers auto-fix

### Test Classes

10. **ComplianceRuleEvaluatorTest.cls** — Test rule evaluation logic, idempotency, bind variable handling
11. **ComplianceOrchestrationEngineTest.cls** — Test workflow sequencing, Type.forName() resolution
12. **RemediationServiceTest.cls** — Test all fix types
13. **SelfHealingDeployerTest.cls** — Test metadata generation, approval enforcement
14. **ComplianceScoreAggregatorTest.cls** — Test aggregation across frameworks

### Permission Sets

- `Elaro_Rule_Engine_Admin.permissionset-meta.xml`
- `Elaro_Rule_Engine_User.permissionset-meta.xml`

---

## AGENT 4: WS1 BATCH MIGRATION (Q2, Weeks 12-20)

**Package**: Main Elaro 2GP
**Dependency**: Async Framework (Agent 1) complete

### Task

Migrate ~15-20 existing Batch Apex classes to CursorStep subclasses.

### Migration Pattern Per Class

1. Create new `[ClassName]CursorStep extends CursorStep`
2. Extract `start()` query into `getCursorQuery()` and `getCursorBinds()`
3. Extract `execute()` logic into `innerExecute(List<SObject>, StepContext)`
4. Extract `finish()` logic into `finalize(StepContext)`
5. For `Database.Stateful`: move state to instance variables on the Step class
6. For chained batches: model chain as sequential steps in `StepProcessor.setSteps()`
7. Add `@Deprecated` annotation to old batch class (CANNOT delete from released managed package)
8. Add `Use_New_Async_Framework__c` Custom Setting check as feature flag toggle
9. Write test class using `CursorLike` mock
10. Verify governor limits stay within subscriber org profiles

### Circuit Breakers (REQUIRED in every CursorStep)

```apex
// Check before processing
if (Limits.getQueries() >= Limits.getLimitQueries() - 5) {
    ctx.put('needsRestart', true);
    return; // Will re-enqueue via StepProcessor
}
if (Limits.getCpuTime() >= Limits.getLimitCpuTime() - 2000) {
    ctx.put('needsRestart', true);
    return;
}
```

### Design for Subscriber Org Limits

- Subscriber orgs have different governor limit profiles than dev orgs
- Test with 500+ rules, 1000+ controls, 10K+ findings
- Exponential backoff for retries (`AsyncOptions.setMinimumQueueableDelayInMinutes`)
- Queueable daily limit: 250K async executions per org

---

## AGENT 5: WS7 — NIS2 + DORA EU BUNDLE MVP (Q4, Weeks 42-52)

**Package**: Main Elaro 2GP
**Dependency**: Rule Engine and Orchestration (Agent 3) complete

### Custom Objects

**1. NIS2_Entity_Classification\_\_c**

- `Organization__c` (Lookup Account)
- `Entity_Type__c` (Picklist: Essential/Important)
- `Sector__c` (Picklist per NIS2 Annex I/II)
- `Employee_Count__c` (Number)
- `Annual_Turnover_EUR__c` (Currency)
- `Classification_Rationale__c` (Long Text Area 5000)

**2. NIS2_Incident_Report\_\_c**

- `Classification__c` (Lookup NIS2_Entity_Classification\_\_c)
- `Stage__c` (Picklist: Early_Warning/Notification/Final_Report)
- `Early_Warning_Deadline__c` (DateTime — detection + 24hr)
- `Notification_Deadline__c` (DateTime — detection + 72hr)
- `Final_Report_Deadline__c` (DateTime — detection + 1 month)
- `Is_Early_Warning_Submitted__c` (Checkbox)
- `Is_Notification_Submitted__c` (Checkbox)
- `Is_Final_Report_Submitted__c` (Checkbox)

**3. ICT_Third_Party_Provider\_\_c** (DORA register)

- `Provider_Name__c` (Text 80)
- `LEI__c` (Text 20 — Legal Entity Identifier)
- `Criticality__c` (Picklist: Critical/Important/Standard)
- `Concentration_Risk_Score__c` (Number 0-100)
- `Exit_Strategy_Status__c` (Picklist: Documented/In_Progress/Not_Started)
- `Sub_Outsourcing_Chain__c` (Long Text Area 5000)

**4. ICT_Service_Contract\_\_c** (DORA Article 30)

- `Provider__c` (Master-Detail ICT_Third_Party_Provider\_\_c)
- `Contract_Start__c` (Date)
- `Contract_End__c` (Date)
- `SLA_Terms__c` (Long Text Area 5000)
- `Data_Location__c` (Text 255)
- `Audit_Rights__c` (Checkbox)
- `Termination_Provisions__c` (Long Text Area 5000)

**5. Resilience_Test\_\_c** (DORA testing program)

- `Test_Type__c` (Picklist: TLPT/Scenario/Vulnerability/Penetration)
- `Test_Date__c` (Date)
- `Next_Test_Date__c` (Date)
- `Results_Summary__c` (Long Text Area 5000)
- `Critical_Findings_Count__c` (Number)

### Key Architecture Decision

DORA is lex specialis to NIS2 for financial entities. When both apply, DORA takes precedence.
Build shared control library with `Framework_Priority__c` field so rule engine evaluates
DORA-specific requirements first for financial entities, NIS2 for others.

### Apex Classes

**6. NIS2ComplianceService.cls** (inherited sharing) — implements `IComplianceModule`

**7. DORAComplianceService.cls** (inherited sharing) — implements `IComplianceModule`

**8. NIS2IncidentWorkflowService.cls** (inherited sharing)

- Define NIS2_Incident_Response workflow template for Orchestration Engine:
  Step 1: ClassifyIncident, Step 2: PublishEarlyWarning (24hr),
  Step 3: SubmitNotification (72hr), Step 4: CompileFinalReport (1 month)
- Deadline enforcement via scheduled Queueable checking overdue records

**9. DORARegisterController.cls** (with sharing)

- `@AuraEnabled getProviders()`: ICT provider list
- `@AuraEnabled getConcentrationRisk()`: Risk analysis across providers
- `@AuraEnabled getContractCompliance()`: Article 30 compliance status

### LWC Components

10. **nis2Dashboard** — Entity classification, incident tracking, staged reporting
11. **doraRegister** — ICT provider list with concentration risk visualization
12. **doraContractTracker** — Article 30 contractual compliance
13. **nis2IncidentTimeline** — 24hr/72hr/1-month staged timeline

### Test Classes

14. **NIS2ComplianceServiceTest.cls**
15. **DORAComplianceServiceTest.cls**
16. **NIS2IncidentWorkflowServiceTest.cls** — Test deadline calculations, staged progression

### Permission Sets

- `Elaro_NIS2_Admin.permissionset-meta.xml`
- `Elaro_NIS2_User.permissionset-meta.xml`
- `Elaro_DORA_Admin.permissionset-meta.xml`
- `Elaro_DORA_User.permissionset-meta.xml`

---

## AGENT 6: INTEGRATION WITH TEAM 2 + FINAL QA (Weeks 47-52)

### Integration Tasks

1. Expose Step interface + StepProcessor API for Team 2 ConfigDriftDetector
2. Expose Compliance_Rule\_\_mdt schema for Team 2 Assessment Wizard auto-scan steps
3. Expose ComplianceOrchestrationEngine for Team 2 Command Center one-click workflows
4. Verify CMMC data model consumed correctly by Team 2 Assessment Wizards

### API Version Upgrade

- Upgrade all existing v65.0 classes to v66.0
- Re-run full test suite after upgrade
- Verify no breaking changes from v65.0 access modifier requirement

### Final Quality Gates

```bash
# Full scan
sf scanner run --target force-app --format table --severity-threshold 1

# All tests with coverage
sf apex run test --target-org elaro-dev --test-level RunLocalTests --code-coverage --wait 30

# Jest tests
npm run test:unit

# Verify per-class coverage
sf apex run test --target-org elaro-dev --test-level RunLocalTests --code-coverage --result-format json
```

### Team 1 Handoff Checkpoints (deliver to Team 2)

- **Week 4**: Step interface + StepProcessor API finalized
- **Week 8**: Async Framework complete and tested
- **Week 12**: CMMC data model frozen (no schema changes after this)
- **Week 17**: Orchestration Engine + Workflow Templates available
- **Week 22**: Rule Engine + Compliance_Rule\_\_mdt schema stable
