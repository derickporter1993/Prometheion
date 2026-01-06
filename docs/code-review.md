# Code Review Findings

This document expands the initial review with explicit failure analyses and concrete remediation steps for each finding. Priorities follow P0 (critical), P1 (high), P2 (medium).

## PrometheionReasoningEngine.cls (P0/P1)
- `explainViolation` assumes `Prometheion_AI_Settings__c.getInstance()` is never null, so a missing settings row can cause a null dereference before `Enable_AI_Reasoning__c` is read. **Fix:** add a null-safe accessor that seeds defaults or fails fast with a clear error.
- `callEinsteinPrediction` ignores the model outcome when results exist and always uses the hard-coded policy ID `DEFAULT_POLICY`, never interpreting a non-violation probability. **Fix:** map probabilities to `isViolation`, select a policy by the returned label, and preserve the model confidence for auditability.
- Policy retrieval ignores the `policyId` argument and fetches the first policy for the framework, so adjudications are not tied to the model-selected policy. **Fix:** honor the passed policy ID, enforce a deterministic lookup, and raise an error if it is absent.
- `buildSafeExplanation` can emit raw node metadata without escaping and relies on populated fields. **Fix:** null-safe formatting plus HTML/Markdown escaping to prevent malformed or unsafe strings.
- `logAdjudication` writes a new graph node for every call without duplicate checks, bulk DML handling, or exception handling, and it runs in a `without sharing` class. **Fix:** add idempotent checks using deterministic hashes, bulk upsert with error handling, and enforce sharing or explicit FLS.
- `generateDeterministicHash` invoked from `logAdjudication` relies on `System.now()` inside `PrometheionGraphIndexer`, making adjudication IDs non-deterministic and time-dependent. **Fix:** generate hashes only from stable record attributes (e.g., Id, LastModifiedDate) to prevent duplicate graph nodes.

## PrometheionGraphIndexer.cls (P0/P1)
- `generateDeterministicHash` includes the current time in the input, making IDs unstable. **Fix:** remove time-based inputs and derive the hash solely from record identifiers and immutable fields.
- `indexChange` serializes full PermissionSet/Flow child relationship objects into `Node_Metadata__c`, which can inflate payload size and leak permissions data. **Fix:** serialize a reduced DTO containing only required, non-sensitive fields, and enforce FLS checks before serialization.
- `queryEntityMetadata` silently returns an empty map for unsupported `entityType` values, risking incomplete indexing. **Fix:** throw an exception for unknown types to fail fast and surface misconfigurations.
- Exceptions during graph insertion are wrapped but not logged. **Fix:** add structured logging (correlation ID, entity type, record Id) and propagate actionable error messages.

## PrometheionComplianceScorer.cls (P1)
- The scoring functions issue multiple synchronous COUNT queries per call, risking governor exhaustion. **Fix:** batch queries via aggregates, cache within transaction scope, and add limit guards.
- `calculateEvidenceScore` returns 0 unless there is a graph entry in the last 30 days, but no index on `Timestamp__c` is shown. **Fix:** ensure selective filters, add an index on `Timestamp__c`, or use `ORDER BY Timestamp__c DESC LIMIT 1` to avoid full scans.
- Error handling wraps the entire calculation but provides only the exception message. **Fix:** log failing component names and stack traces to aid debugging.

## PrometheionAISettingsController.cls (P0)
- `getSettings` fabricates an in-memory default record instead of persisting defaults, so callers may operate on unsaved settings. **Fix:** persist an org default row or surface an explicit "no settings" state to callers.
- No CRUD/FLS checks are performed before `upsert`, allowing unauthorized users to modify org-wide AI settings. **Fix:** enforce `with sharing`, check CRUD/FLS, and run inputs through `Security.stripInaccessible` before DML.

## SlackNotifier.cls (P2)
- `@future` calls have no retry/backoff; transient failures are only logged to debug. **Fix:** migrate to Queueable with retry/backoff and centralized error logging.
- Calls rely on the named credential `Slack_Webhook` but do not validate availability, so missing endpoints can throw unhandled exceptions. **Fix:** short-circuit with a clear error when the credential is misconfigured.
- Payload construction uses raw values from `Performance_Alert__e` without truncation; large `Stack__c` strings may exceed Slack limits. **Fix:** truncate or move oversized payloads to attachments/files and validate lengths.
- `notifyFlowPerformance` accepts unvalidated inputs and uses default emoji mapping. **Fix:** validate required fields and emit correlation IDs to aid incident triage.

## PerformanceRuleEngine.cls (P1)
- The rule evaluation trusts org settings without null/format validation; invalid numeric values could throw `NumberFormatException`. **Fix:** add safe parsing with defaults and guardrails for out-of-range values.
- Publishing platform events swallows failures by logging debug only. **Fix:** surface failures to monitoring, return results to callers, and optionally retry transient errors.
- `checkThreshold` duplicates construction logic for warn/crit branches. **Fix:** extract a helper/builder to keep the payloads consistent and reduce maintenance overhead.

## LimitMetrics.cls (P2)
- `fetchGovernorStats` exposes live governor metrics but lacks unit tests and does not surface usage limits (max values), limiting the caller’s ability to calculate headroom. **Fix:** add tests plus a payload that includes both consumed and remaining limits for each metric.

## Immediate Remediation Order
1) **P0 Security/Integrity:** Harden `PrometheionAISettingsController`, add null/ID stability fixes in `PrometheionReasoningEngine` and `PrometheionGraphIndexer`.
2) **P1 Reliability/Performance:** Batch compliance scoring queries, add deterministic hashing and error surfacing in indexing, and improve event publishing in `PerformanceRuleEngine`.
3) **P2 Operational Readiness:** Add retries/backoff for Slack notifications and expand governor metrics/testing.

## Verification Checklist
- [ ] CRUD/FLS enforced on settings and graph metadata writes
- [ ] Deterministic hashing free of time-based inputs
- [ ] Aggregated queries with governor guardrails in compliance scoring
- [ ] Structured logging (correlation IDs) for indexing and event publishing
- [ ] Retry/backoff and payload validation for Slack notifications
- [ ] Unit tests covering null settings, policy selection, and limit metrics
