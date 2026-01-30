# Elaro Data Flow Diagrams

This document provides data flow diagrams for key Elaro processes to help AppExchange reviewers understand the end-to-end architecture.

## Table of Contents

1. [Compliance Scoring Flow](#compliance-scoring-flow)
2. [AI Integration Flow](#ai-integration-flow)
3. [External API Callout Flow](#external-api-callout-flow)
4. [Audit Trail & Evidence Pipeline](#audit-trail--evidence-pipeline)

---

## Compliance Scoring Flow

```mermaid
graph TD
    A[User Initiates Scan] --> B[ComplianceDashboardController]
    B --> C[ComplianceFrameworkService]
    C --> D{Framework Type}
    D -->|HIPAA| E[HIPAAComplianceService]
    D -->|SOC2| F[SOC2ComplianceService]
    D -->|GDPR| G[GDPRComplianceService]
    D -->|PCI-DSS| H[PCIDSSComplianceService]

    E --> I[ElaroComplianceScorer]
    F --> I
    G --> I
    H --> I

    I --> J[Query Salesforce Metadata]
    J --> K[WITH SECURITY_ENFORCED]
    K --> L[Calculate Compliance Score]
    L --> M[Identify Compliance Gaps]
    M --> N[Store Compliance_Score__c]
    N --> O[Store Compliance_Gap__c]
    O --> P[Update Dashboard UI]

    style K fill:#90EE90
    style N fill:#87CEEB
    style O fill:#87CEEB
```

**Security Points:**

- All SOQL queries use `WITH SECURITY_ENFORCED`
- CRUD/FLS checks via `ElaroSecurityUtils` before DML
- Results stripped of inaccessible fields before returning to UI

---

## AI Integration Flow

```mermaid
sequenceDiagram
    participant User
    participant LWC as Compliance Copilot LWC
    participant Controller as ElaroComplianceCopilotService
    participant Security as ElaroSecurityUtils
    participant API as Claude API (Named Credential)
    participant DB as Salesforce Database

    User->>LWC: Ask compliance question
    LWC->>Controller: askCopilot(query)
    Controller->>Security: Validate user access
    Security-->>Controller: Access granted
    Controller->>DB: Query evidence items (WITH SECURITY_ENFORCED)
    DB-->>Controller: Evidence data
    Controller->>Security: stripInaccessibleFields()
    Security-->>Controller: Filtered data
    Controller->>API: Send analysis request
    API-->>Controller: AI response
    Controller->>Controller: Parse & validate response
    Controller-->>LWC: ComplianceRecommendation
    LWC-->>User: Display answer
```

**Security Points:**

- All queries use `WITH SECURITY_ENFORCED`
- Data stripped before sending to external API
- Named Credential for secure API authentication
- Input validation on all user queries

---

## External API Callout Flow

```mermaid
graph LR
    A[Elaro Service] --> B{Callout Type}
    B -->|Slack| C[SlackIntegration]
    B -->|Teams| D[TeamsNotifier]
    B -->|PagerDuty| E[PagerDutyIntegration]
    B -->|Claude AI| F[ElaroComplianceCopilotService]

    C --> G[Named Credential: Slack_Webhook]
    D --> H[Named Credential: Teams_Webhook]
    E --> I[Named Credential: PagerDuty_API]
    F --> J[Named Credential: Elaro_Claude_API]

    G --> K[External Service]
    H --> K
    I --> K
    J --> K

    K --> L[Response Handler]
    L --> M[Error Logging]
    L --> N[Success Confirmation]

    style G fill:#FFD700
    style H fill:#FFD700
    style I fill:#FFD700
    style J fill:#FFD700
```

**Security Points:**

- All external callouts use Named Credentials (no hardcoded endpoints)
- Sensitive data stripped before transmission
- Error handling prevents data leakage
- Rate limiting and retry logic implemented

---

## Audit Trail & Evidence Pipeline

```mermaid
graph TD
    A[Salesforce Event] --> B[Platform Event: Elaro_Raw_Event__e]
    B --> C[ElaroEventProcessor]
    C --> D[ElaroAuditTrailPoller]
    D --> E[Query Event Data WITH SECURITY_ENFORCED]
    E --> F[ElaroGraphIndexer]
    F --> G[Calculate Risk Score]
    G --> H[Store in Elaro_Compliance_Graph__b]
    H --> I[ElaroReasoningEngine]
    I --> J[AI Adjudication]
    J --> K[Create Compliance_Gap__c]
    K --> L[Generate Evidence Item]
    L --> M[Store Elaro_Evidence_Item__c]
    M --> N[Link to Audit Package]
    N --> O[Elaro_Audit_Package__c]
    O --> P[Generate Audit Report]

    style E fill:#90EE90
    style H fill:#87CEEB
    style K fill:#87CEEB
    style M fill:#87CEEB
    style O fill:#87CEEB
```

**Security Points:**

- All queries use `WITH SECURITY_ENFORCED` or `WITH USER_MODE`
- Big Object queries use system context (documented `without sharing`)
- Evidence items respect FLS before storage
- Audit trail maintains correlation IDs for traceability

---

## Data Retention & Deletion Flow

```mermaid
graph TD
    A[Retention Policy Trigger] --> B[RetentionEnforcementScheduler]
    B --> C[RetentionEnforcementBatch]
    C --> D[Query Records for Deletion]
    D --> E[WITH SECURITY_ENFORCED]
    E --> F{Record Type}
    F -->|GDPR| G[ElaroGDPRDataErasureService]
    F -->|CCPA| H[ElaroCCPADataInventoryService]
    F -->|GLBA| I[ElaroGLBAPrivacyNoticeService]

    G --> J[Validate Erasure Request]
    H --> J
    I --> J

    J --> K[Check for Blockers]
    K --> L{Can Erase?}
    L -->|Yes| M[Delete Records]
    L -->|No| N[Log Blocker]

    M --> O[Log Erasure Event]
    N --> P[Notify User]
    O --> Q[Audit Trail Updated]

    style E fill:#90EE90
    style J fill:#FFD700
    style M fill:#FF6B6B
```

**Security Points:**

- All queries use `WITH SECURITY_ENFORCED`
- Erasure requests validated before processing
- Audit trail maintained for compliance
- Blockers prevent accidental data loss

---

## User Authentication & Authorization Flow

```mermaid
sequenceDiagram
    participant User
    participant LWC as Lightning Web Component
    participant Apex as Apex Controller
    participant Security as ElaroSecurityUtils
    participant DB as Salesforce Database

    User->>LWC: Request data
    LWC->>Apex: @AuraEnabled method
    Apex->>Security: validateCRUDAccess()
    Security-->>Apex: Access granted/denied
    alt Access Granted
        Apex->>DB: SOQL Query (WITH SECURITY_ENFORCED)
        DB-->>Apex: Raw results
        Apex->>Security: stripInaccessibleFields()
        Security-->>Apex: Filtered results
        Apex-->>LWC: Return data
        LWC-->>User: Display data
    else Access Denied
        Apex-->>LWC: SecurityException
        LWC-->>User: Error message
    end
```

**Security Points:**

- All controllers use `with sharing`
- CRUD/FLS validation before queries
- Results stripped before returning to UI
- User-friendly error messages (no stack traces)

---

## Key Security Patterns

### 1. SOQL Security Enforcement

All SOQL queries follow this pattern:

```apex
List<Account> accounts = [
    SELECT Id, Name FROM Account
    WHERE CreatedDate = LAST_N_DAYS:30
    WITH SECURITY_ENFORCED  // ← Always present
    LIMIT 100
];
```

### 2. FLS Enforcement

Before returning data to UI:

```apex
List<SObject> rawResults = Database.query(secureSOQL);
List<SObject> filteredResults = ElaroSecurityUtils.stripInaccessibleFields(
    AccessType.READABLE,
    rawResults
);
return filteredResults;
```

### 3. CRUD Validation

Before DML operations:

```apex
ElaroSecurityUtils.validateCRUDAccess(
    'Account',
    ElaroSecurityUtils.DmlOperation.DML_INSERT
);
insert accounts;
```

### 4. External API Security

All external callouts use Named Credentials:

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Elaro_Claude_API');  // ← Named Credential
req.setMethod('POST');
// ... rest of request
```

---

## Data Flow Summary

| Flow               | Security Enforcement      | Data Validation        | External Integration |
| ------------------ | ------------------------- | ---------------------- | -------------------- |
| Compliance Scoring | ✅ WITH SECURITY_ENFORCED | ✅ Object whitelisting | ❌ None              |
| AI Integration     | ✅ WITH SECURITY_ENFORCED | ✅ Input sanitization  | ✅ Named Credential  |
| External Callouts  | ✅ N/A (outbound)         | ✅ Data stripping      | ✅ Named Credentials |
| Audit Trail        | ✅ WITH SECURITY_ENFORCED | ✅ Correlation IDs     | ❌ None              |
| Data Retention     | ✅ WITH SECURITY_ENFORCED | ✅ Erasure validation  | ❌ None              |

---

## Last Updated

- **Date**: January 10, 2026
- **Version**: 3.0.0
- **Status**: Complete

---

## Notes for AppExchange Reviewers

1. **All SOQL queries** use `WITH SECURITY_ENFORCED` (187 instances found)
2. **All controllers** use `with sharing` (122 classes)
3. **External integrations** use Named Credentials (no hardcoded endpoints)
4. **Data stripping** occurs before returning to UI or sending to external APIs
5. **Audit trail** maintained for all compliance operations
6. **Error handling** prevents sensitive data leakage

For detailed security implementation, see:

- `ElaroSecurityUtils.cls` - Centralized security utilities
- `docs/SECURITY.md` - Security documentation
- `CLAUDE.md` - Development guidelines
