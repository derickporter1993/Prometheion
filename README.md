# OpsGuardian

> Enterprise-grade observability and compliance guardrails for Salesforce orgs.  
> **Outcomes:** fewer outages, faster incident triage, cleaner audits, and predictable releases.

[![Build](https://img.shields.io/github/actions/workflow/status/derickporter1993/Ops-Guardian/ci.yml?label=CI)](../../actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Why OpsGuardian

Modern Salesforce programs need **reliable telemetry** (limits, flows, APIs), **policy enforcement** (thresholds & alerts), and **production-safe automation**. OpsGuardian packages these into a **lightweight managed pattern** that you can adopt incrementally—no lock-in, no black boxes.

**Who it’s for**
- **Admins / Platform Owners** — prevent limit breaches, see flow failures, speed root-cause.
- **Sec/GRC** — retention, encryption patterns, audit-ready logs & access controls.
- **DevOps** — pre-flight checks, test coverage views, deploy health, hub-and-spoke ingest.

---

## Feature Highlights

- **Real-time Performance Signals**: CPU/heap/SOQL/DML usage, Flow runs & faults, Async job health.
- **Policy Thresholds**: Simple Custom Metadata (`OG_Policy__mdt`) to define warn/critical limits.
- **Alerts & Routing**: Platform Events → Slack/Webhooks/Jira via plugin interface.
- **Dashboards**: API usage, flow health, deployment/test insights (Lightning app).
- **Hub-and-Spoke**: Optional REST ingest to centralize events from many orgs.
- **Security by Default**: CRUD/FLS checks, `WITH SECURITY_ENFORCED`, Shield-friendly data model.
- **Extensible**: Drop-in plugins; no changes to core package required.

---

## Architecture

  ```mermaid
  flowchart TB
    subgraph "Salesforce Org"
      LWC[OpsGuardian LWCs]
      APEX[Apex Services]
      DATA[(OpsGuardian Data)]
      EVENTS[Platform Events]
      CMDT[OG_Policy__mdt]
      LWC --> APEX
      APEX --> DATA
      APEX --> EVENTS
      APEX --> CMDT
    end

  subgraph "External Systems"
    AI[AI Services]
    SLACK[Slack/Webhooks]
    JIRA[Jira]
    HUB[Central Hub Org]
  end

  APEX -->|Named Credential| AI
  EVENTS --> SLACK
  EVENTS --> JIRA
  APEX <-. REST .-> HUB
```

Optional static fallback image: docs/images/architecture.png

⸻

Requirements
- Salesforce API 63.0+ (tested through 65.0, Winter ’26)
- Salesforce CLI (sf), Dev Hub enabled
- Node.js 18+ (for LWC tests/linting)
- (Recommended) Shield Platform Encryption in production orgs

⸻

Quick Start

**A) Scratch Org (dev sandbox)**

```bash
# 1) Authenticate Dev Hub (one time)
sf org login web --set-default-dev-hub --alias DevHub

# 2) Create a scratch org
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias OG-Dev --duration-days 7 --set-default

# 3) Deploy the project
sf project deploy start

# 4) Assign admin permset and open the org
sf org assign permset --name Command_Center_Admin
sf org open
```

After opening the org, use the App Launcher to pin the API Usage, Flow Execution, Deployment Job, and Performance Alert History tabs (no managed Lightning app is packaged yet).

**B) Sandbox / Production**
- Install the managed package (coming soon). Until then, deploy via `sf project deploy start` to a sandbox.
- Assign `Command_Center_Admin`.
- Configure policies under Setup → Custom Metadata Types → `OG_Policy__mdt`.
- (Optional) Set up Named Credentials for Slack/Webhooks/AI.

⸻

## Configuration

### Policy Thresholds (`OG_Policy__mdt`)

| Field | Type | Example | Purpose |
| --- | --- | --- | --- |
| `CPU_Warn__c` | Number | 5000 | CPU warn (ms) |
| `CPU_Crit__c` | Number | 8000 | CPU critical (ms) |
| `SOQL_Warn__c` | Number | 80 | SOQL warn |
| `SOQL_Crit__c` | Number | 95 | SOQL critical |
| `DML_Warn__c` | Number | 120 | DML rows warn |
| `DML_Crit__c` | Number | 150 | DML rows critical |
| `Retention_Days__c` | Number | 180 | History retention for cleanup |

Tip: create a “Default” record and org/BU-specific overrides as needed.

### Alerts (Slack/Webhook)
1. Setup → Named Credentials → New
   - Name: `Slack_Webhook`
   - URL: Incoming webhook URL
2. Use the provided notifier (see Plugins) or your own.

⸻

## Using OpsGuardian

### Dashboards (via tabs/App Launcher)
- API Usage
- Flow Health
- System Performance
- Deploy/Test Monitor
- Performance Alerts

### Investigate Critical Events (SOQL)

```sql
SELECT Event_Type__c, Severity__c, Message__c, Timestamp__c, Correlation_Id__c
FROM OpsGuardian_History__c
WHERE Severity__c = 'Critical'
ORDER BY Timestamp__c DESC
LIMIT 50
```

### REST Ingest (Hub-and-Spoke)
- Endpoint: `/services/apexrest/og/v1/ingest`
- Auth: JWT Bearer via Named Credential

**Body**

```json
{
  "type": "CPU",
  "message": "CPU limit exceeded",
  "severity": "Critical",
  "timestamp": "2025-01-15T10:30:00Z",
  "correlationId": "a1b2c3d4"
}
```

**cURL**

```bash
curl -X POST "$SF_URL/services/apexrest/og/v1/ingest" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"type":"CPU","message":"CPU limit exceeded","severity":"Critical","timestamp":"2025-01-15T10:30:00Z"}'
```

Responses: 201 OK • 400 Invalid • 401 Unauthorized • 429 Rate limited (with Retry-After)

⸻

## Plugin SDK

Create an outbound integration by implementing a simple interface and registering it via Custom Metadata (`OG_Plugin_Config__mdt`).

```apex
public interface OG_Plugin {
    void send(OpsGuardian_History__c eventRec);
    Boolean supports(String eventType, String severity);
}

public class SlackPlugin implements OG_Plugin {
    public void send(OpsGuardian_History__c evt) {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:Slack_Webhook');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(evt));
        new Http().send(req);
    }
    public Boolean supports(String type, String severity) {
        return severity == 'Critical';
    }
}
```

Register via `OG_Plugin_Config__mdt` with `Class_Name__c = SlackPlugin`.

⸻

## Security & Compliance

### STRIDE at a Glance

| Threat | Control |
| --- | --- |
| Spoofing | JWT validation, audience checks |
| Tampering | `WITH SECURITY_ENFORCED`, `Security.stripInaccessible` |
| Repudiation | Append-only logs, correlation IDs |
| Information Disclosure | CRUD/FLS, Shield encryption at rest |
| DoS | 429 w/ Retry-After, platform cache, governor safeguards |
| Elevation of Privilege | Least-privilege perm sets, with sharing classes |

### Data Privacy
- Encryption: TLS 1.2/1.3 in transit; Shield at rest (if enabled).
- Retention: Default 180 days (configurable).
- Erasure: Admin-triggered anonymization Flow included.

Report security issues via GitHub Security Advisories. Please do not open public issues for vulnerabilities.

⸻

## Performance (reference env)

| Scenario | P50 | P95 | Notes |
| --- | --- | --- | --- |
| Ingest API (per request) | 90ms | 180ms | Queueable insert |
| Dashboard refresh | 600ms | 1200ms | Indexed queries + LDS cache |
| Risk scoring (1K records) | 120ms | 250ms | Baseline heuristic |

Test org: Enterprise Edition, ~1M history rows, ~10k events/hour.

⸻

## Development

If your repository is still named Ops-Gurdian, adjust the URL below.

```bash
# Clone
git clone https://github.com/derickporter1993/Ops-Guardian.git
cd Ops-Guardian

# Node deps (LWC/Jest/Eslint)
npm install

# Run tests & linters
npm test
npm run lint
npm run fmt

# Apex tests & coverage
sf apex run test --test-level RunLocalTests --code-coverage --result-format human

# Static analysis
sf scanner run --target force-app --format table
```

**Branching & Commits**
- `main`: release branch
- `dev`: integration branch
- Feature branches: `feat/<key>-short-desc`
- Conventional commits (`feat:`, `fix:`, `chore:`, `docs:`…)

⸻

## Roadmap
- AppExchange listing (managed package)
- Multi-language dashboards (ES/FR/DE)
- Anomaly detection (ML)
- Observability exports (Grafana/Datadog)
- Custom report builder
- Mobile (Salesforce Mobile SDK)

⸻

## Support
- Bugs/requests: GitHub Issues
- Security: Security Advisories
- Discussions: GitHub Discussions (if enabled)

⸻

## License & Notices

MIT © Derick Brian Porter.  
Salesforce and related marks are trademarks of salesforce.com, inc. OpsGuardian is an independent project and not an official Salesforce product.

---
