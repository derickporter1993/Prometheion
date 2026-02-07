# Elaro - Claude.ai Project Context

Upload this file to a Claude.ai Project to give Claude full context about the Elaro codebase.

**Last Updated**: 2026-02-07
**Repo**: github.com/derickporter1993/Elaro (branch: main)

---

## Project Overview

**Elaro** is an AI-powered compliance and governance platform for Salesforce v3.0 Enterprise Edition. It provides configuration drift detection, audit evidence automation, and multi-framework compliance scoring for regulated organizations.

**Company**: Solentra ("Solutions Within")
**Target**: Healthcare, government, financial services, nonprofits on Salesforce
**Goal**: AppExchange listing

### Supported Compliance Frameworks
HIPAA, SOC2, NIST, FedRAMP, GDPR, SOX, PCI-DSS, CCPA, GLBA, ISO 27001

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Backend | Apex (Salesforce API v65.0) |
| Frontend | Lightning Web Components (LWC) |
| Testing | Jest (LWC) + Apex Test Classes |
| Linting | ESLint v9 with LWC plugin |
| Formatting | Prettier |
| Monorepo | Turborepo (platform/) |
| CI/CD | GitHub Actions |
| Node.js | v20.0.0+ |

---

## Codebase Scale

| Metric | Count |
|--------|-------|
| Apex production classes | 122 |
| Apex test classes | 89 |
| LWC components | 42 |
| Custom objects | 53 |
| Jest test suites | 41 (659 tests) |
| Lint warnings | 0 |

---

## Project Structure

```
elaro/
├── force-app/main/default/     # Salesforce source
│   ├── classes/                # Apex (122 prod + 89 test)
│   ├── lwc/                    # Lightning Web Components (42)
│   ├── objects/                # Custom objects (53)
│   ├── triggers/               # Apex triggers (5)
│   └── permissionsets/         # Permission sets (5)
├── platform/                   # TypeScript monorepo (Turborepo)
│   └── packages/
│       ├── cli/                # elaro CLI
│       ├── sf-client/          # Salesforce API client
│       ├── types/              # Shared TypeScript types
│       └── masking/            # Data masking utilities
├── docs/                       # Documentation + audit reports
│   └── audit/                  # Security, quality, LWC, architecture audits
├── scripts/                    # Automation scripts
└── specs/                      # Feature specifications
```

---

## Architecture

### Layered Pattern
```
PRESENTATION  →  42 LWC Components
     ↓
CONTROLLER    →  13 @AuraEnabled controllers
     ↓
SERVICE       →  ComplianceServiceBase (abstract)
                 ├── ElaroHIPAAComplianceService
                 ├── ElaroSOC2ComplianceService
                 ├── ElaroGDPRComplianceService
                 ├── ElaroCCPAComplianceService
                 ├── ElaroPCIDSSComplianceService
                 ├── ElaroGLBAPrivacyNoticeService
                 └── ElaroISO27001AccessReviewService
     ↓
UTILITY       →  ElaroSecurityUtils, ElaroLogger, ElaroTestDataFactory
```

### Key Design Patterns
- **Service Factory**: `ComplianceServiceFactory` for framework service locator
- **Abstract Base**: `ComplianceServiceBase` with shared logging, audit, error handling
- **Interface Contracts**: `IAccessControlService`, `IBreachNotificationService`, etc.
- **Queueable Async**: Slack notifications, batch operations via Queueable classes
- **Central Security**: `ElaroSecurityUtils.validateCRUDAccess()` for all CRUD/FLS checks

### Key Custom Objects

| Object | Purpose |
|--------|---------|
| `Compliance_Score__c` | Framework compliance scores |
| `Compliance_Gap__c` | Gap tracking & remediation |
| `Compliance_Evidence__c` | Audit evidence records |
| `API_Usage_Snapshot__c` | API limit monitoring |
| `Elaro_Audit_Log__c` | Audit trail |
| `Elora_AI_Settings__c` | AI configuration *(API name is legacy "Elora")* |
| `Elaro_Compliance_Graph__b` | Big Object for graph data |

### Key LWC Components

| Component | Purpose |
|-----------|---------|
| `elaroDashboard` | Main compliance dashboard |
| `complianceCopilot` | AI compliance assistant |
| `systemMonitorDashboard` | Governor limits monitoring |
| `apiUsageDashboard` | API usage tracking |
| `flowExecutionMonitor` | Flow performance tracking |
| `performanceAlertPanel` | Real-time alerts |
| `complianceGraphViewer` | Interactive compliance graph (SVG) |
| `controlMappingMatrix` | Cross-framework control mapping |

---

## Development Commands

```bash
npm run fmt              # Format with Prettier
npm run lint             # ESLint (max 3 warnings)
npm run test:unit        # Jest tests (41 suites, 659 tests)
npm run precommit        # fmt:check + lint + test:unit
```

---

## Critical Rules

### Security (MANDATORY for AppExchange)
- ALL SOQL → `WITH SECURITY_ENFORCED`
- ALL classes → `with sharing` (document exceptions)
- ALL DML → `ElaroSecurityUtils.validateCRUDAccess()` first
- NEVER put SOQL/DML inside loops (bulkify)
- NEVER use `innerHTML` in LWC (XSS risk)

### LWC
- NEVER quote template bindings: `data={rows}` not `data="{rows}"`
- `@track` is unnecessary for primitives (removed project-wide)
- Always add `disconnectedCallback()` for timer/listener cleanup
- Always add `aria-modal="true"` + `aria-labelledby` on modals

### Testing
- Target 90%+ Apex coverage
- Every production class needs `*Test.cls`
- Every LWC needs `__tests__/<component>.test.js`
- Use `@TestSetup` for shared test data
- Use `{ virtual: true }` for Salesforce module mocks in Jest

---

## Audit Status (2026-02-07)

Full codebase audit completed with 4 parallel agents. All P1 (AppExchange blocking) and P2 (should-fix) issues have been resolved.

### Security Audit — 28 findings (ALL P1/P2 FIXED)
- 3 Critical: Missing SECURITY_ENFORCED on compliance modules (HIPAA, GDPR, FINRA)
- 10 High: BenchmarkingService, ElaroComplianceAlert, missing sharing keywords, HMAC timing attack
- 11 Medium: CronTrigger queries, input validation, exposed SOQL
- 4 Low: Informational

**Fixes applied**: WITH SECURITY_ENFORCED added to 30+ queries across 12 files. 3 sharing keywords added. HMAC timing attack fixed with constant-time comparison. Replay protection headers made mandatory.

### Code Quality Audit — 34 findings (ALL P1/P2 FIXED)
- 2 Critical: SOQL-in-loop in ElaroQuickActionsService and BlockchainVerification
- 6 High: Method length, reserved word usage (`limit` → `dailyLimit`/`maxItems`)
- 15 Medium: System.debug in production (replaced with ElaroLogger), method length
- 11 Low: Magic numbers, dead code stubs

**Fixes applied**: Both critical bulkification issues fixed. System.debug replaced in 5 files. Reserved words renamed. Duplicate query cached.

### LWC Audit — 24 findings (ALL P1/P2 FIXED)
- 1 Critical: complianceGraphViewer innerHTML XSS + missing disconnectedCallback
- 3 High: Missing tests on 6 components
- 12 Medium: @track overuse (241 instances), console.error in production
- 8 Low: CSS !important, hardcoded data

**Fixes applied**: innerHTML → safe DOM removal. disconnectedCallback added with event listener cleanup. @track removed from 31 components. console.error removed. 6 new Jest test files. jiraCreateModal naming collision fixed. Modal accessibility added to 4 components.

### Architecture Audit — Well-layered, minor gaps fixed
- 5 production classes without test classes → 4 new test classes added
- Clean Controller → Service → Utility layering confirmed
- ComplianceServiceBase pattern provides excellent consistency

### Remaining Items (P3/P4 — Nice to Have)
- 9 methods over 50 lines needing decomposition
- 4 dead code stubs (CCPAConsumerRightsService, AnomalyDetectionService, BenchmarkingService)
- 3 magic numbers in AccessReviewScheduler
- Linear search optimization in ComplianceGraphService
- `!important` CSS overrides in controlMappingMatrix

---

## Git Workflow

- Branch naming: `feature/TICKET-description`, `bugfix/TICKET-description`
- Commit format: `type(scope): description` (feat, fix, test, docs, refactor)
- CI runs on push to: main, develop, release/*, claude/*
- Pre-commit hook: fmt:check + lint + test:unit

---

## CI/CD Pipeline

GitHub Actions (`.github/workflows/elaro-ci.yml`):
1. **code-quality** — Format check, linting, security audit
2. **unit-tests** — LWC Jest tests
3. **security-scan** — Salesforce Code Analyzer
4. **validate-metadata** — Directory structure validation
5. **cli-build** — Platform TypeScript build
6. **build-success** — Final deployment readiness

---

## Permission Sets

| Permission Set | Purpose |
|---------------|---------|
| `Elaro_Admin` | Full admin access |
| `Elaro_Auditor` | Read-only audit access |
| `Elaro_User` | Standard user access |
| `Elaro_API_User` | API integration access |

---

## Key Naming Conventions

- **Apex classes**: PascalCase with `Elaro` prefix for custom classes
- **Test classes**: `<ClassName>Test`
- **LWC components**: camelCase folders
- **Custom objects**: Ends with `__c`, mostly `Elaro_` prefixed
- **Note**: `Elora_AI_Settings__c` is the Salesforce API name (legacy); the product is "Elaro"

---

## Useful File Paths

| What | Path |
|------|------|
| Project CLAUDE.md | `/Elaro/CLAUDE.md` |
| Detailed dev guide | `/Elaro/docs/CLAUDE.md` |
| Security audit | `/Elaro/docs/audit/security-audit.md` |
| Code quality audit | `/Elaro/docs/audit/code-quality-audit.md` |
| LWC audit | `/Elaro/docs/audit/lwc-audit.md` |
| Architecture audit | `/Elaro/docs/audit/architecture-audit.md` |
| Jest config | `/Elaro/jest.config.js` |
| ESLint config | `/Elaro/eslint.config.js` |
| CI workflow | `/Elaro/.github/workflows/elaro-ci.yml` |
