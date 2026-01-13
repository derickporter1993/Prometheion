# Backend Phase 1 Backlog

## backend-001: Create TriggerRecursionGuard.cls
- **Owner:** claude_code → cursor
- **Status:** pending
- **Estimated:** 20 min
- **Dependencies:** none
- **Description:** Implement static Set-based recursion guard for trigger safety

## backend-002: Create 2 Missing Trigger Handlers
- **Owner:** claude_code → cursor  
- **Status:** pending
- **Estimated:** 30 min
- **Dependencies:** backend-001
- **Description:** Create LeadTriggerHandler and OpportunityTriggerHandler following repo patterns

## backend-003: Add Recursion Guards to 5 Triggers
- **Owner:** cursor
- **Status:** pending
- **Estimated:** 20 min
- **Dependencies:** backend-001, backend-002
- **Description:** Integrate TriggerRecursionGuard into all trigger handlers

## backend-004: WITH SECURITY_ENFORCED (3 methods)
- **Owner:** claude_code → cursor
- **Status:** pending
- **Estimated:** 45 min
- **Dependencies:** none
- **Description:** Add WITH SECURITY_ENFORCED to SOQL queries in 3 methods

## backend-005: CRUD Checks (3 DML operations)
- **Owner:** claude_code → cursor
- **Status:** pending
- **Estimated:** 45 min
- **Dependencies:** none
- **Description:** Add CRUD/FLS security checks before DML operations

## backend-006: ApiUsageSnapshot (timeout + CRUD)
- **Owner:** claude_code → cursor
- **Status:** pending
- **Estimated:** 30 min
- **Dependencies:** none
- **Description:** Fix timeout warning and add CRUD checks in ApiUsageSnapshot

# Frontend Phase 1 Backlog

## frontend-001: aria-hidden on 3 Icons
- **Owner:** cursor
- **Status:** pending
- **Estimated:** 15 min
- **Dependencies:** none
- **Description:** Add aria-hidden="true" to decorative SVG icons

## frontend-002: Loading States (3-4 components)
- **Owner:** claude_code → cursor
- **Status:** pending
- **Estimated:** 60 min
- **Dependencies:** none
- **Description:** Implement loading states in async components

## frontend-003: Jest Tests (2 components)
- **Owner:** claude_code → cursor
- **Status:** pending
- **Estimated:** 90 min
- **Dependencies:** frontend-002
- **Description:** Write comprehensive Jest tests for key components
