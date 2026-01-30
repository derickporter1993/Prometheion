# PLAN MODE V3 SKILL OPTIMIZATION - ELARO

## Executive Summary

**Current State:** Elaro v3.0 is production-ready (B+ 86/100) with comprehensive compliance capabilities across 10 frameworks, but faces three challenges: (1) AppExchange readiness blockers (48% test coverage vs 75% required), (2) v1.5 feature velocity (1/5 complete), and (3) competitive differentiation in a crowded GRC market.

**Optimization Strategy:** Three-tier architecture focused on integration moat

1. **Core Engine** (15% of content, 80% of value) - Salesforce-native compliance automation
2. **Enhancement Modules** (plug-in components) - AI remediation, Jira sync, mobile alerts
3. **Output Templates** (role-specific, schema-driven) - Compliance officer, CISO, auditor views

**Key Changes:**

- Collapsed 8 phases → 5 core phases (AppExchange prep becomes Phase 1 gating)
- Created decision tree for Express (AppExchange sprint) vs Deep (v2.0 planning)
- Separated enforcement rules from workflow description
- Built modular schema library (6 required for v3.0, 15 for v2.0)

**Primary Wedge:** `integration_moat` - Deep Salesforce platform integration creates switching costs via:
- 46 custom objects storing compliance history
- Platform Events for immutable audit trails
- Big Objects for 1B+ record compliance graphs
- Shield integration for event monitoring
- Native LWC components (37 deployed)

-----

## 1. CORE SKILL STRUCTURE

### A. Minimal Viable Skill (Elaro Context)

```markdown
# PLAN MODE V3: ELARO STRATEGY → EXECUTION ENGINE

## IDENTITY
You are a planning system for Elaro, an AI-powered compliance automation platform for Salesforce. You produce defensible strategies and execution-ready roadmaps. You optimize for:
- Clarity over cleverness
- Testability over certainty
- Decisions over discussion
- AppExchange-readiness over feature velocity

## CORE WORKFLOW (5 Phases)

**Phase 1: INTAKE** (Context + Constraints)
- Output: ContextInventory + Assumptions + AppExchangeGate
- Checkpoint: Confirm scope, P1 blockers, test coverage status
- Elaro-specific: Load SESSION_CONTEXT.md, check TASK_AUDITOR.md

**Phase 2: STRATEGY** (Brief + Wedge)
- Output: StrategicBrief + WedgeThesis + CompetitiveLandscape
- Checkpoint: Lock ICP (regulated enterprises), North Star (Time-to-Compliance), Primary Wedge (integration_moat)
- Elaro-specific: Map to 10-framework coverage, Claude API differentiation

**Phase 3: OPPORTUNITIES** (Gaps + Prioritization)
- Output: JourneyAndGaps + OpportunityBacklog (ranked)
- Checkpoint: Confirm top 3 opportunities (v1.5 features vs AppExchange prep)
- Elaro-specific: Balance test coverage push vs feature delivery

**Phase 4: ROADMAP** (Execution Plan)
- Output: Roadmap + Backlog + Experiments + RiskRegistry
- Checkpoint: Lock sequencing, run prune pass, verify P1 blocker resolution
- Elaro-specific: 12-week v1.5 timeline, 75% coverage gate

**Phase 5: ACTIVATION** (Ship Tomorrow)
- Output: NextActions48h + NextSprintTickets
- Checkpoint: Final go/no-go for AppExchange submission
- Elaro-specific: sf project deploy preview, test run

## ENFORCEMENT RULES (Non-Negotiable)

1. **Structured Output:** All artifacts conform to strict JSON schemas
2. **Wedge Discipline:** Primary wedge = integration_moat (Salesforce-native lock-in)
3. **Moat Scoring:** Every roadmap item gets moat_strength_score (1-5)
4. **Prune Pass:** Items scoring 1-2 are deferred unless AppExchange-critical
5. **Checkpoint Protocol:** After each phase, emit Checkpoint with decision levers
6. **Assumption Tracking:** Unknown data becomes labeled assumptions with confidence scores
7. **Validation Gates:** No phase proceeds if quality scores < 8/10
8. **AppExchange Gate:** P1 blockers must be resolved before v1.5 features

## 9 WEDGE TAXONOMY (Elaro Focus)
1. time_to_value | 2. data_advantage | 3. workflow_lock_in
4. **integration_moat** ★ | 5. quality_moat | 6. trust_moat
7. community_moat | 8. distribution_moat | 9. economics_moat

**Primary Wedge Justification:**
- 46 custom objects create data gravity
- Platform Events provide immutable compliance trails
- Shield integration requires licensed dependency
- LWC components lock into Lightning Experience
- Big Objects store unlimited compliance history

## OUTPUT MODES
- **Express (30min):** Phases 1-2-4-5 only, max 9 epics, focus on P1 blockers
- **Standard (90min):** All 5 phases, full schema compliance, v1.5 planning
- **Deep (180min):** Add Technical Design + ADRs + v2.0 vision
```

### B. Enhancement Modules (Plug-in Architecture)

|Module                     |When to Enable                    |Adds                                 |Elaro Relevance|
|---------------------------|----------------------------------|-------------------------------------|---------------------|
|**PR/FAQ Generator**       |AppExchange listing or major bet  |Working-backwards narrative          |AppExchange description|
|**Technical Deep Dive**    |Building v1.5 features            |RFC + ADRs + OpsReadiness            |Jira Integration, Mobile Alerts|
|**Scenario Planning**      |High uncertainty or board review  |Lean/Balanced/Aggressive comparison  |Test coverage vs features trade-off|
|**GTM Blueprint**          |AppExchange launch                |Channel strategy + pricing hypothesis|ISV partner program|
|**Metrics Instrumentation**|Post-v1.5 maturity                |Event taxonomy + dashboard specs     |Compliance score analytics|
|**Security Review Module** |AppExchange submission            |CRUD/FLS checklist + test coverage   |P1 blockers resolution|

**Implementation:** Each module has its own schema + validation rules. Core workflow references optional module outputs.

-----

## 2. DECISION TREES & MODE SELECTION

### Mode Selection Logic (Elaro-Specific)

```
START
  ↓
Q1: Is this AppExchange submission planning or feature development?
  → APPEXCHANGE PREP → Express Mode (P1 blockers + test coverage focus)
  → FEATURE DEV → Q2

Q2: What's the planning horizon?
  → 0-30 days (v1.5 sprint) → Express Mode (skip Scenarios, minimal experiments)
  → 30-90 days (v1.5 release) → Standard Mode
  → 90+ days (v2.0 planning) → Deep Mode (enable Scenario Planning)

Q3: Does this involve new Apex classes or LWC components?
  → YES → Enable Technical Deep Dive module
  → NO → Skip to Activation

Q4: Time constraint?
  → < 60 min available → Express Mode (auto-prune to 9 epics max)
  → 60-120 min → Standard Mode
  → 120+ min → Deep Mode

Q5: Are P1 blockers resolved?
  → NO → Block feature work, focus on P1 resolution
  → YES → Proceed with v1.5 planning
```

### Audience-Specific Question Banks (Elaro Context)

**Activation Pattern:** Ask CORE questions (7) first. Then add ROLE questions based on primary audience.

|Core Questions (Always)                   |Compliance Officer Add-ons         |CISO Add-ons                      |Salesforce Admin Add-ons             |
|------------------------------------------|-----------------------------------|----------------------------------|-------------------------------------|
|1. Product one-liner: AI Compliance Brain |8. Which frameworks are priority?  |8. What's the risk tolerance?     |8. Which orgs need deployment?       |
|2. Primary user: Compliance/Security teams|9. Audit timeline?                 |9. Shield license available?      |9. Scratch org or sandbox?           |
|3. Current alternative: Manual audits     |10. Evidence export format?        |10. Integration with SIEM?        |10. Permission set requirements?     |
|4. Riskiest assumption: Test coverage     |11. Report frequency?              |11. Incident response SLA?        |11. Custom object limits?            |
|5. Constraints: 75% coverage, 12 weeks    |                                   |                                  |                                     |
|6. 90-day success: AppExchange published  |                                   |                                  |                                     |
|7. Wedge hypothesis: integration_moat     |                                   |                                  |                                     |

-----

## 3. SCHEMA OPTIMIZATION

### Tiered Schema Library (Elaro-Specific)

**Tier 1: Required (v3.0 AppExchange)**

1. `StrategicBrief` – ICP (regulated enterprises), problem (compliance sprawl), value prop (AI-powered automation), North Star (Time-to-Compliance reduction)
2. `WedgeThesis` – Primary wedge (integration_moat) + proof plan (AppExchange review)
3. `Roadmap` – Phases with epics, dependencies, moat scores, P1 blocker flags
4. `Backlog` – Prioritized items with acceptance criteria, test coverage requirements
5. `RiskRegistry` – Risks with kill criteria (48% → 75% coverage) + leading indicators
6. `Checkpoint` – Phase summary + decision levers + AppExchange gate status

**Tier 2: Standard (v1.5 Planning)**
7. `CompetitiveLandscape` – OwnBackup, Salesforce Shield, Varonis, Egnyte
8. `JourneyAndGaps` – Compliance officer workflow gaps
9. `Experiments` – A/B on AI explanation accuracy
10. `MetricsPlan` – Compliance score trends, remediation velocity

**Tier 3: Deep (v2.0 Vision)**
11. `TechnicalDesignDoc` – Jira webhook architecture, Mobile Alert escalation
12. `ADRs` – Claude API vs OpenAI, Platform Events vs Change Data Capture
13. `OpsReadinessChecklist` – Shield dependency, Named Credential setup
14. `ScenarioComparison` – Lean (AppExchange first) vs Aggressive (v1.5 features)
15. `PlanBundle` – Top-level container with version control

### Schema Enforcement Pattern (Elaro)

```typescript
// Example: Roadmap schema with Elaro-specific validation
interface ElaroRoadmapEpic {
  epic_id: string;
  title: string;
  description: string;
  acceptance_criteria: string[]; // required, min 2
  moat_strength_score: 1 | 2 | 3 | 4 | 5; // required
  primary_wedge_reinforcement: 'integration_moat' | 'data_advantage' | 'trust_moat';
  effort_estimate: "XS" | "S" | "M" | "L" | "XL";
  dependencies: string[]; // epic_ids
  experiments: string[]; // experiment_ids
  mvp_critical: boolean; // gates prune pass

  // Elaro-specific fields
  apex_classes_affected: string[]; // e.g., ['JiraIntegrationService.cls']
  lwc_components_affected: string[]; // e.g., ['jiraIssueCard']
  test_coverage_impact: number; // expected % change
  p1_blocker: boolean; // AppExchange blocking
  compliance_frameworks: string[]; // ['HIPAA', 'SOC2', 'GDPR', ...]
}

// Validation rules
const PRUNE_THRESHOLD = 2;
const MVP_OVERRIDE = true;
const MIN_TEST_COVERAGE = 75; // AppExchange requirement

function shouldPrune(epic: ElaroRoadmapEpic): boolean {
  if (epic.p1_blocker) return false; // Never prune P1 blockers
  return epic.moat_strength_score <= PRUNE_THRESHOLD && !epic.mvp_critical;
}

function validateAppExchangeReadiness(epics: ElaroRoadmapEpic[], currentCoverage: number): boolean {
  const p1Blockers = epics.filter(e => e.p1_blocker && e.status !== 'completed');
  const projectedCoverage = currentCoverage + epics.reduce((sum, e) => sum + e.test_coverage_impact, 0);
  return p1Blockers.length === 0 && projectedCoverage >= MIN_TEST_COVERAGE;
}
```

-----

## 4. QUALITY GATES (Elaro-Specific)

### Automatic Validation (Machine-Checkable)

|Gate                       |Rule                                               |Severity|Elaro Context|
|---------------------------|---------------------------------------------------|--------|-------------------|
|**Schema Compliance**      |All artifacts pass JSON schema validation          |BLOCKING|Standard|
|**Wedge Discipline**       |Primary wedge = integration_moat                   |BLOCKING|Salesforce lock-in|
|**Moat Coverage**          |≥80% of post-prune epics reinforce integration_moat|BLOCKING|Platform stickiness|
|**P1 Blocker Resolution**  |All P1 items resolved before v1.5 features         |BLOCKING|AppExchange gate|
|**Test Coverage Projection**|Projected coverage ≥75% post-implementation       |BLOCKING|AppExchange requirement|
|**Security Enforcement**   |All queries use WITH SECURITY_ENFORCED             |BLOCKING|Salesforce ISV requirement|
|**Experiment Linkage**     |Every phase has ≥1 experiment + ≥1 metric          |WARNING |Validation|
|**Dependency Graph**       |No circular dependencies in backlog                |BLOCKING|Apex/LWC dependencies|
|**Kill Criteria**          |Top 5 risks have defined kill_threshold            |WARNING |Risk management|
|**Acceptance Criteria**    |All epics have ≥2 acceptance criteria              |BLOCKING|Definition of done|

### Self-Scoring Rubric (1-10 scale)

After each phase, score:

- **Clarity:** Can a new Salesforce admin understand this without explanation?
- **Specificity:** Are success criteria measurable (test coverage %, deployment success)?
- **Linkage:** Do outputs trace back to integration_moat wedge?
- **Defensibility:** Is the moat thesis plausible given Salesforce platform capabilities?
- **Testability:** Can we prove/disprove core assumptions in 90 days?
- **Feasibility:** Given 48% current coverage and 12-week timeline, is this executable?

**Rule:** If ANY score < 8, either revise that section or escalate to human checkpoint.

### Elaro-Specific Quality Checks

```apex
// Quality gate validation (conceptual Apex)
public class ElaroPlanValidator {

    public static ValidationResult validatePhase(PlanPhase phase) {
        ValidationResult result = new ValidationResult();

        // P1 Blocker Gate
        if (phase.phaseNumber > 3 && hasUnresolvedP1Blockers()) {
            result.addBlocker('P1 blockers must be resolved before Phase 4');
        }

        // Test Coverage Gate
        Decimal currentCoverage = getCurrentTestCoverage(); // 48%
        Decimal projectedCoverage = calculateProjectedCoverage(phase.epics);
        if (projectedCoverage < 75) {
            result.addBlocker('Projected coverage ' + projectedCoverage + '% below 75% threshold');
        }

        // Security Gate
        for (Epic epic : phase.epics) {
            if (epic.apex_classes_affected != null) {
                for (String cls : epic.apex_classes_affected) {
                    if (!hasSecurityEnforced(cls)) {
                        result.addBlocker(cls + ' missing WITH SECURITY_ENFORCED');
                    }
                }
            }
        }

        return result;
    }
}
```

-----

## 5. CHECKPOINT PROTOCOL (Elaro Context)

### Checkpoint Object Schema

```json
{
  "phase_number": 2,
  "phase_name": "STRATEGY",
  "outputs_generated": ["StrategicBrief", "WedgeThesis", "CompetitiveLandscape"],
  "decisions_made": [
    {"decision": "Primary wedge = integration_moat", "locked": true},
    {"decision": "North Star = Time-to-Compliance reduction", "locked": true},
    {"decision": "ICP = Regulated enterprises (healthcare, finance)", "locked": false}
  ],
  "assumptions_added": [
    {"assumption": "AppExchange security review takes 4-6 weeks", "confidence": 0.8, "impacts": ["Roadmap.Phase1"]},
    {"assumption": "Test coverage can reach 75% with 3 weeks effort", "confidence": 0.6, "impacts": ["Roadmap.Phase2", "Roadmap.Phase3"]},
    {"assumption": "Claude API rate limits support production load", "confidence": 0.9, "impacts": ["v1.5.AIExplanations"]}
  ],
  "elaro_specific": {
    "p1_blockers_remaining": 4,
    "current_test_coverage": 48,
    "projected_test_coverage": 78,
    "apex_classes_affected": 12,
    "lwc_components_affected": 5
  },
  "open_questions": [
    "Should we prioritize Jira integration over Mobile Alerts for v1.5?",
    "Is 75% coverage achievable without adding bulk test classes?"
  ],
  "quality_scores": {
    "clarity": 9,
    "specificity": 8,
    "linkage": 10,
    "defensibility": 8,
    "testability": 9,
    "feasibility": 7
  },
  "decision_levers": [
    "Defer v1.5 AI Explanations to v1.6 to hit coverage target",
    "Add dedicated test coverage sprint (2 weeks) before features",
    "Reduce Phase 1 scope by 30% (defer Mobile Alerts to v1.6)",
    "Switch to Scenario A (AppExchange-first, features-second)"
  ],
  "recommended_next_step": "Proceed to Phase 3 with AppExchange-first scenario"
}
```

### User Edit Protocol (Structured Steering)

Instead of vague instructions like "prioritize differently," users submit:

```json
{
  "edit_type": "reduce_scope",
  "parameters": {
    "target_reduction_pct": 30,
    "preserve_wedge_strength": true,
    "defer_criteria": "moat_score <= 3 AND !p1_blocker",
    "elaro_specific": {
      "preserve_frameworks": ["HIPAA", "SOC2", "GDPR"],
      "defer_frameworks": ["GLBA", "ISO27001"],
      "prioritize_coverage": true
    }
  }
}
```

**Supported Edit Types:**

- `replace_wedge` – Change primary wedge (rarely needed for Elaro)
- `reduce_scope` – Auto-prune by percentage, preserve P1 blockers
- `switch_scenario` – Load AppExchange-first/Features-first preset
- `change_icp` – Re-evaluate framework priority (e.g., drop GLBA)
- `lock_decision` – Make a decision irreversible for remainder of plan
- `challenge_assumption` – Replace test coverage assumption with actual data
- `prioritize_coverage` – Shift focus to test coverage over features

-----

## 6. PRUNE PASS IMPLEMENTATION (Elaro)

### Algorithm

```python
def prune_roadmap(epics: List[ElaroEpic], wedge: str = 'integration_moat') -> PruneReport:
    """
    Remove low-moat-strength items that aren't MVP-critical or P1 blockers.
    Return both pruned roadmap and audit trail.
    """
    kept = []
    deferred = []

    for epic in epics:
        # Never prune P1 blockers
        if epic.p1_blocker:
            kept.append(epic)
            continue

        # Never prune if AppExchange-critical
        if epic.appexchange_critical:
            kept.append(epic)
            continue

        if epic.moat_strength_score <= 2 and not epic.mvp_critical:
            deferred.append({
                "epic": epic,
                "reason": f"Low moat strength ({epic.moat_strength_score}) and not MVP-critical",
                "re_add_trigger": f"When {wedge} advantage is established via AppExchange, revisit",
                "elaro_context": {
                    "apex_classes": epic.apex_classes_affected,
                    "test_coverage_saved": epic.estimated_test_effort_hours
                }
            })
        else:
            kept.append(epic)

    # Validate remaining epics reinforce wedge
    wedge_coverage = sum(1 for e in kept if e.primary_wedge_reinforcement == wedge) / len(kept)

    # Calculate projected test coverage impact
    coverage_impact = sum(e.test_coverage_impact for e in kept)

    return PruneReport(
        kept_epics=kept,
        deferred_epics=deferred,
        wedge_coverage=wedge_coverage,  # Must be >= 0.80
        projected_coverage_delta=coverage_impact,
        summary=f"Pruned {len(deferred)}/{len(epics)} items, {wedge_coverage:.0%} reinforce {wedge}, +{coverage_impact}% coverage projected"
    )
```

### Prune Pass Output Example (Elaro v1.5)

**Before Prune:** 15 epics
**After Prune:** 9 epics (6 deferred)
**Current Coverage:** 48%
**Projected Coverage (Post-Prune):** 76%

|Deferred Epic               |Moat Score|P1 Blocker?|Reason                             |Re-add Trigger                        |
|----------------------------|----------|-----------|-----------------------------------|--------------------------------------|
|Advanced Analytics Dashboard|2         |No         |Does not reinforce integration_moat|After AppExchange approval            |
|Custom Branding Options     |1         |No         |Pure feature parity, no moat value |Customer asks from 3+ enterprise deals|
|GLBA Framework Enhancement  |2         |No         |Low-priority framework             |When GLBA customer acquired           |
|ISO27001 Deep Integration   |2         |No         |Duplicate of SOC2 controls         |Post-v1.5 enhancement                 |
|Offline Evidence Export     |1         |No         |Edge case, low usage expected      |Customer feedback indicates need      |
|Multi-Org Dashboard         |2         |No         |Scope creep, defer to v2.0         |Enterprise tier request               |

**Kept Epics (P1 Priority):**
1. Trigger Recursion Guards (P1 BLOCKER) - Moat: 5
2. Bulk Test Coverage (P1 BLOCKER) - Moat: 4
3. Framework Validation (P1 BLOCKER) - Moat: 4
4. AI Change Explanations (v1.5 CORE) - Moat: 5
5. Suggested Fixes (v1.5 CORE) - Moat: 5
6. Jira Integration (v1.5 CORE) - Moat: 4
7. Report Scheduler UI (v1.5 CORE) - Moat: 4
8. Mobile Alerts (v1.5 CORE) - Moat: 3
9. LWC Test Coverage (P1 ADJACENT) - Moat: 4

-----

## 7. EXPRESS MODE SPECIFICATION (Elaro 30-Minute Path)

### Input Template (10 questions max)

```markdown
1. Product one-liner: AI Compliance Brain for Salesforce
2. Primary user: Compliance officers, CISOs, Salesforce admins at regulated enterprises
3. Core problem: Manual compliance audits take weeks, drift goes undetected
4. Current alternative: Spreadsheets, manual Shield review, consultant audits
5. Wedge hypothesis: integration_moat (Salesforce-native with 46 custom objects)
6. 90-day success metric: AppExchange published + 5 pilot customers
7. Team size + roles: 2 devs (Cursor + Claude), 1 PM, 1 QA
8. Budget constraint: $0 (bootstrap), Claude API credits only
9. Hard blockers: 48% test coverage (need 75%), 4 P1 items remaining
10. Riskiest assumption: Can achieve 75% coverage in 3 weeks
```

### Express Output Bundle (Elaro)

1. **StrategicBrief** (1 page)
   - ICP: Regulated enterprises (healthcare, finance, government)
   - Problem: Compliance sprawl across 10 frameworks
   - Value Prop: AI-powered compliance automation with Salesforce-native integration
   - North Star: Time-to-Compliance < 1 hour (from 4+ hours)

2. **CompetitiveLandscape** + wedge selection (1 page)
   - Competitors: OwnBackup (backup focus), Varonis (data security), Salesforce Shield (raw events)
   - Differentiation: AI copilot + multi-framework scoring + evidence automation
   - Wedge: integration_moat (46 objects, Platform Events, Big Objects)

3. **90-Day Roadmap** (max 9 epics, 3 per phase)
   - Phase 1 (Days 1-30): P1 Blocker Resolution + Test Coverage
   - Phase 2 (Days 31-60): AppExchange Submission + v1.5 Core Features
   - Phase 3 (Days 61-90): Pilot Customers + Mobile Alerts

4. **Top 5 Risks** + kill criteria
   - R1: Test coverage stalls at 60% → Kill if <70% by Day 21
   - R2: AppExchange rejection → Kill if security review fails twice
   - R3: Claude API costs exceed budget → Kill if >$500/month
   - R4: Jira integration complexity → Kill if >3 weeks effort
   - R5: No pilot customers → Kill if <3 prospects by Day 60

5. **3 Experiments** (one per phase)
   - E1: Bulk test generation with AI assistance (validate coverage assumption)
   - E2: AppExchange listing A/B test (description variants)
   - E3: AI explanation accuracy survey (>90% satisfaction target)

6. **NextActions48h** (first sprint)
   - Add TriggerRecursionGuard to 3 triggers
   - Add bulk tests to ElaroComplianceScorerTest.cls
   - Deploy to scratch org and run sf apex run test

**Time Budget:**

- Intake: 5 min (load SESSION_CONTEXT.md)
- Strategy: 10 min (confirm wedge, ICP)
- Roadmap: 10 min (9 epics max)
- Validation + Output: 5 min (AppExchange gate check)

**Constraints:**

- No scenario planning (single path: AppExchange-first)
- No technical deep dive (defer Jira RFC to Standard mode)
- No GTM blueprint (defer to post-AppExchange)
- Experiments must be concierge or internal (no A/B tests with customers yet)

-----

## 8. ELARO MODE DEFAULTS

When `project_type == "salesforce_isv"`, auto-enable:

### Mandatory Outputs

1. **AppExchange Readiness Checklist** (P1 blockers, test coverage, security)
2. **Wedge Thesis** (integration_moat) + proof plan (custom object count, Platform Events)
3. **Distribution Reality Check** (AppExchange discovery, ISV partner program, direct sales)
4. **Pricing Power Hypothesis** (per-user, per-org, enterprise tiers)
5. **Risk Registry** with kill criteria (coverage thresholds, rejection scenarios)
6. **Scenario Comparison** (AppExchange-first vs Features-first)

### Enhanced Questions (Salesforce ISV Context)

- What's the current test coverage? (48% - need 75%)
- P1 blockers remaining? (4 items: 3 triggers, 1 framework validation)
- Shield license required? (Optional but recommended)
- Named Credentials configured? (Slack, Teams, Claude API, Jira)
- Scratch org or sandbox for testing? (Scratch org: elaro-dev)
- Package namespace? (None - unmanaged for now)

### Validation Emphasis

- Every Apex class must have WITH SECURITY_ENFORCED or WITH USER_MODE
- All LWC components must have Jest test coverage
- P1 blockers must be resolved before v1.5 feature work
- Test coverage must be validated with `sf apex run test --test-level RunLocalTests`

-----

## 9. DUAL OUTPUT RECOMMENDATION (Elaro)

**JSON + Human-Readable** is the optimal path. Here's why:

### Architecture

```
PlanBundle (JSON)
    ↓
Renderer (context-aware)
    ↓
Output Formats:
- Compliance Officer Summary (1-pager for compliance team)
- CISO Risk Brief (security-focused view)
- Dev Sprint Tickets (Jira/Linear import)
- Salesforce Admin Guide (deployment steps)
- SESSION_CONTEXT.md Update (next session handoff)
```

### Implementation Pattern (Elaro-Specific)

```typescript
interface ElaroRenderConfig {
  audience: "compliance_officer" | "ciso" | "salesforce_admin" | "dev" | "exec";
  format: "markdown" | "jira_tickets" | "session_context" | "json";
  depth: "summary" | "standard" | "detailed";
  sections: string[]; // Which artifacts to include
  elaro_specific: {
    include_apex_impact: boolean;
    include_lwc_impact: boolean;
    include_test_coverage: boolean;
    include_p1_status: boolean;
  }
}

function renderPlan(bundle: PlanBundle, config: ElaroRenderConfig): Output {
  // Select appropriate template
  // Filter to requested sections
  // Apply audience-specific language (compliance vs technical)
  // Format for target system
  // Update SESSION_CONTEXT.md if needed
}
```

### Example: Same Plan, 3 Audiences

**For Compliance Officer (Email Format):**

> Elaro v1.5 targets integration_moat wedge with AI-powered remediation. Phase 1 resolves 4 AppExchange blockers + achieves 75% test coverage in 30 days. Top risk: Coverage stalls at 60% (kill if <70% by Day 21). Next actions: Trigger guards this week, bulk tests next week.

**For CISO (Risk Brief):**

> Security posture: B+ (86/100). P1 blockers: 4 remaining (trigger recursion, bulk tests). All queries use WITH SECURITY_ENFORCED. Shield integration optional but recommended. Kill criteria: AppExchange rejection, Claude API budget exceeded.

**For Salesforce Admin (SESSION_CONTEXT.md Update):**

```markdown
## Quick Status (Updated 2026-01-13)
| Area | Status | Details |
|------|--------|---------|
| Core v3.0 | COMPLETE | All 10 compliance frameworks |
| Security | APPROVED | CRUD/FLS, no injection vulnerabilities |
| Test Coverage | 48% → 75% target | Need 27% improvement |
| P1 Blockers | 4 remaining | 3 triggers + 1 framework validation |
| v1.5 Features | 1/5 done | Report Scheduler complete |

## Next Actions (This Sprint)
1. Add TriggerRecursionGuard to 3 triggers
2. Add bulk tests (200+ records) to 4 test classes
3. Run sf apex run test --test-level RunLocalTests
```

-----

## 10. IMPLEMENTATION ROADMAP (Elaro v1.5)

### Week 1-2: P1 Blocker Resolution (AppExchange Gate)

- [x] Input validation - ElaroGraphIndexer.cls ✅
- [x] Input validation - PerformanceAlertPublisher.cls ✅
- [x] Input validation - FlowExecutionLogger.cls ✅
- [x] USER_MODE - ElaroComplianceScorer.cls ✅
- [x] USER_MODE - ElaroGraphIndexer.cls ✅
- [x] USER_MODE - EvidenceCollectionService.cls ✅
- [x] USER_MODE - ComplianceDashboardController.cls ✅
- [ ] Recursion guard - PerformanceAlertEventTrigger
- [ ] Recursion guard - ElaroPCIAccessAlertTrigger
- [ ] Recursion guard - ElaroEventCaptureTrigger
- [ ] Framework validation - Add to remaining service classes

### Week 3-4: Test Coverage Push (48% → 75%)

- [ ] Bulk tests - ElaroComplianceScorerTest.cls (200+ records)
- [ ] Bulk tests - ElaroGraphIndexerTest.cls (200+ records)
- [ ] Bulk tests - EvidenceCollectionServiceTest.cls (200+ records)
- [ ] Bulk tests - PerformanceAlertPublisherTest.cls (200+ records)
- [ ] LWC tests - 28 components need Jest coverage

### Week 5-7: v1.5 Core Features (AI Explanations + Suggested Fixes)

- [ ] AIExplanationService.cls
- [ ] AIExplanationPromptBuilder.cls
- [ ] FixCodeGeneratorService.cls
- [ ] RemediationTemplateService.cls
- [ ] lwc/aiExplanationCard/
- [ ] lwc/fixSuggestionCard/

### Week 8-9: Jira Integration

- [ ] JiraIntegrationService.cls
- [ ] JiraWebhookHandler.cls
- [ ] lwc/jiraIssueCard/
- [ ] lwc/jiraCreateModal/

### Week 10: Report Scheduler UI

- [ ] lwc/reportSchedulerConfig/ (UI for existing scheduler)

### Week 11-12: Mobile Alerts + AppExchange Submission

- [ ] MobileAlertPublisher.cls
- [ ] MobileAlertEscalator.cls
- [ ] OnCallScheduleService.cls
- [ ] AppExchange package upload
- [ ] Security review submission

-----

## CRITICAL DECISIONS REQUIRED (Elaro)

### 1. AppExchange-First vs Features-First

**Decision:** AppExchange-first (Scenario A)
**Rationale:**
- 48% coverage blocks submission
- P1 blockers create technical debt
- Features without AppExchange = no distribution channel
- Integration moat requires visible marketplace presence

### 2. Test Coverage Strategy

**Option A:** AI-assisted bulk test generation (faster, riskier)
**Option B:** Manual test writing (slower, more reliable)
**Option C:** Hybrid (AI generates, human reviews)

**Recommendation:** Option C (hybrid) - Use Claude to generate bulk test templates, human review for edge cases.

### 3. Jira vs Mobile Alerts Priority

**Decision:** Jira first
**Rationale:**
- Jira integration reinforces integration_moat (workflow lock-in)
- Mobile alerts are nice-to-have, not differentiator
- Compliance teams already use Jira for ticket tracking

### 4. Claude API vs OpenAI for AI Features

**Decision:** Claude API (already integrated)
**Rationale:**
- ElaroComplianceCopilotService already uses Claude
- Rate limiting and caching already implemented
- Named Credential (Elaro_Claude_API) configured
- Switching would delay v1.5 by 2+ weeks

### 5. Version Control for Plans

**Decision:** Every PlanBundle gets:

- `bundle_id` (UUID)
- `version` (semantic versioning matching sfdx-project.json)
- `parent_bundle_id` (if this is a revision)
- `changelog` (what changed from parent)
- `session_context_ref` (links to SESSION_CONTEXT.md commit)

-----

## ANTI-PATTERNS TO PREVENT (Elaro-Specific)

|Anti-Pattern              |Detection                                   |Prevention                                                             |
|--------------------------|--------------------------------------------|-----------------------------------------------------------------------|
|**Feature Creep**         |>12 epics in 90-day plan                    |Hard cap at 9 epics in Express, 15 in Standard                         |
|**Coverage Avoidance**    |Features prioritized over test coverage     |P1 blocker gate: no features until 75% coverage                        |
|**Fake Precision**        |Confidence scores without sf apex run test  |Require actual test run results, not estimates                         |
|**Zombie Experiments**    |Experiments with no decision rules          |Schema requires success_threshold + go/no-go logic                     |
|**Moat Theater**          |All items scored 5/5                        |Flag if >80% items have score ≥4 WITHOUT Salesforce platform dependency|
|**Analysis Paralysis**    |Planning loop >3 hours                      |Time-box Express (30min), Standard (90min), Deep (180min)              |
|**Security Debt**         |New classes without WITH SECURITY_ENFORCED  |Automated lint rule in deployment pipeline                             |
|**Orphan LWCs**           |Components without Jest tests               |Block deployment if LWC test coverage <80%                             |

-----

## FINAL RECOMMENDATIONS (Elaro)

### Start Simple, Enforce Strictly

1. Deploy **Express Mode** first (P1 blockers + test coverage focus)
2. Enforce integration_moat wedge and AppExchange gate religiously
3. Add v1.5 features only after 75% coverage achieved
4. Gather feedback on AI explanation accuracy (>90% satisfaction target)

### Measure Effectiveness

Track these metrics on Plan Mode usage for Elaro:

- Time from intake to first AppExchange submission
- % of plans that pass quality gates on first attempt
- % of roadmap items deferred in prune pass
- Test coverage improvement rate (% per week)
- P1 blocker resolution velocity (items per sprint)
- User-reported "plan survivability" at 30/60/90 days

### Iterate on Checkpoints

The checkpoint + decision lever system is your **highest-leverage** innovation. Double down on making it:

- More specific (not "improve coverage" but "add bulk tests to these 4 specific classes")
- More predictive (use sf apex run test history to recommend which tests to prioritize)
- More automated (detect when coverage stalls and suggest checkpoint)

### Elaro-Specific Success Criteria

| Metric | Current | Target | Timeline |
|--------|---------|--------|----------|
| Test Coverage | 48% | 75% | 4 weeks |
| P1 Blockers | 4 | 0 | 2 weeks |
| v1.5 Features | 1/5 | 5/5 | 12 weeks |
| AppExchange Status | Not submitted | Published | 10 weeks |
| Pilot Customers | 0 | 5 | 12 weeks |

-----

**Next Action:** Start with Express Mode (30min) to resolve P1 blockers and create test coverage sprint plan. Ready to proceed?

---

*Document Version: 1.0*
*Last Updated: 2026-01-13*
*Project: Elaro v3.0 → v1.5*
*Primary Wedge: integration_moat*
*Author: Claude Code (Plan Mode V3)*
