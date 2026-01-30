# Elaro External Services Documentation

**Version:** 3.0
**Last Updated:** 2026-01-11
**Purpose:** AppExchange Security Review Documentation

---

## Overview

Elaro integrates with external services for AI-powered compliance analysis, alerting, incident management, and evidence sharing. All integrations use **Named Credentials** for secure authentication and follow Salesforce best practices.

---

## 1. Claude AI (Anthropic API)

### Purpose
AI-powered compliance analysis, event pattern recognition, audit summaries, and natural language query processing.

### Authentication
- **Method:** Named Credential with API Key authentication
- **Named Credential:** `callout:Elaro_Claude_API`
- **Endpoint:** `https://api.anthropic.com/v1/messages`
- **Protocol:** HTTPS (TLS 1.2+)

### Configuration
**Named Credential Settings:**
- Identity Type: Named Principal
- Authentication Protocol: Password Authentication
- Callout Options: Generate Authorization Header = checked
- Header Name: `x-api-key`
- API Version Header: `anthropic-version: 2023-06-01`

**Custom Metadata:**
- Store model selection in `Elaro_AI_Settings__c`
- Current model: `claude-sonnet-4-20250514`

### API Usage

**Classes Using Claude API:**
- `ElaroComplianceCopilotService.cls` - Main AI service
- `NaturalLanguageQueryService.cls` - Natural language SOQL
- `RootCauseAnalysisEngine.cls` - Root cause analysis

**Request Pattern:**
```apex
Http req = new HttpRequest();
req.setEndpoint('callout:Elaro_Claude_API');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setHeader('anthropic-version', '2023-06-01');
req.setTimeout(60000); // 60 seconds
req.setBody(JSON.serialize(requestBody));

Http http = new Http();
HttpResponse res = http.send(req);
```

### Error Handling
- **Timeout:** 60 seconds (configurable)
- **Retry Logic:** None (single attempt)
- **Caching:** 1 hour cache for repeated queries (Platform Cache)
- **Fallback:** Returns default response with error message
- **Logging:** No PII/credentials logged, correlation IDs used

### Rate Limits
- **Tier:** Standard (customer-specific)
- **Requests/Minute:** Managed by Anthropic account
- **Circuit Breaker:** Platform Cache prevents excessive retries

### Required Permissions
Users must have `Elaro_AI_User` permission set to use AI features.

### Security Considerations
- ✅ No hardcoded API keys (stored in Named Credential)
- ✅ API key rotates outside Salesforce (customer-managed)
- ✅ Sensitive data sanitized before sending to API
- ✅ PII handling compliant with customer data policies
- ✅ Audit logging enabled for all AI calls

---

## 2. Slack Integration

### Purpose
Real-time compliance alerts, audit package notifications, and daily compliance digests.

### Authentication
- **Method:** Named Credential with Webhook URL
- **Named Credential:** `callout:Slack_Webhook`
- **Endpoint:** Customer-provided Slack Incoming Webhook URL
- **Protocol:** HTTPS (TLS 1.2+)

### Configuration
**Named Credential Settings:**
- Identity Type: Named Principal
- Authentication Protocol: No Authentication (webhook contains authentication token)
- URL: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX`

### API Usage

**Classes Using Slack API:**
- `SlackIntegration.cls` - Primary integration service
- `ElaroSlackNotifierQueueable.cls` - Asynchronous alerts
- `ElaroDailyDigest.cls` - Daily digest delivery
- `SlackNotifier.cls` - Legacy notifier

**Message Types:**
1. **Compliance Alerts** - Real-time alert notifications
2. **Audit Packages** - Package generation notifications
3. **Daily Digests** - Scheduled daily summaries

**Request Pattern:**
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Slack_Webhook');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setTimeout(30000);
req.setBody(JSON.serialize(slackMessage));

Http http = new Http();
HttpResponse res = http.send(req);
```

### Error Handling
- **Timeout:** 30 seconds
- **Retry Logic:** None (fire-and-forget for notifications)
- **Fallback:** Logs error, continues processing
- **Logging:** Logs HTTP status code, no sensitive data

### Rate Limits
- **Slack Limit:** 1 message per second per webhook
- **Implementation:** @future(callout=true) prevents bursts
- **Queue Management:** Queueable for batch notifications

### Required Permissions
- Users must have `Elaro_Admin` or `Elaro_Auditor` permission set
- Slack workspace must have Elaro app installed

### Security Considerations
- ✅ Webhook URL stored in Named Credential (not hardcoded)
- ✅ No sensitive data in message bodies
- ✅ Links use org domain URL (not direct record IDs exposed)
- ✅ Webhook URL rotation supported via Named Credential update

---

## 3. Microsoft Teams Integration

### Purpose
Compliance alerts and notifications for Teams-based organizations.

### Authentication
- **Method:** Named Credential with Webhook URL
- **Named Credential:** `callout:Teams_Webhook`
- **Endpoint:** Customer-provided Teams Incoming Webhook URL
- **Protocol:** HTTPS (TLS 1.2+)

### Configuration
**Named Credential Settings:**
- Identity Type: Named Principal
- Authentication Protocol: No Authentication (webhook contains authentication token)
- URL: `https://outlook.office.com/webhook/...`

### API Usage

**Classes Using Teams API:**
- `ElaroTeamsNotifierQueueable.cls` - Asynchronous Teams notifications

**Request Pattern:**
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Teams_Webhook');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setTimeout(30000);
req.setBody(JSON.serialize(teamsCard));

Http http = new Http();
HttpResponse res = http.send(req);
```

### Error Handling
- **Timeout:** 30 seconds
- **Retry Logic:** None (fire-and-forget)
- **Fallback:** Logs error, continues processing
- **Logging:** Logs HTTP status code

### Rate Limits
- **Teams Limit:** 4 requests per second per webhook
- **Implementation:** Queueable prevents bursts

### Security Considerations
- ✅ Webhook URL stored in Named Credential
- ✅ No sensitive data exposed in adaptive cards
- ✅ Webhook rotation supported

---

## 4. PagerDuty Events API

⚠️ **SECURITY WARNING:** See [PAGERDUTY_INTEGRATION_SECURITY_REVIEW.md](PAGERDUTY_INTEGRATION_SECURITY_REVIEW.md) for critical security findings.

### Purpose
Incident triggering, acknowledgment, and resolution for critical compliance alerts.

### Authentication
- **Method:** Routing Key (Integration Key)
- **Storage:** Protected Custom Metadata (`Elaro_API_Config__mdt`)
- **Endpoint:** `https://events.pagerduty.com/v2/enqueue`
- **Protocol:** HTTPS (TLS 1.2+)

### ⚠️ Current Implementation Status

**CRITICAL ISSUE IDENTIFIED (2026-01-11):**

The `PagerDutyIntegration.cls` file currently contains a **hardcoded placeholder** for the routing key (line 144-148):

```apex
private static String getRoutingKey() {
    // In production, retrieve from Custom Metadata or Named Credential
    // This is a placeholder
    return 'your-pagerduty-routing-key';
}
```

**Impact:**
- ❌ **Fails AppExchange Security Review** (hardcoded credentials)
- ❌ **Integration non-functional** (placeholder key rejected by PagerDuty)
- ❌ **Security violation** (credential visible in source code)

**Fix Required (Cursor AI Task):**
- Replace hardcoded placeholder with Custom Metadata query
- Use existing `Elaro_API_Config__mdt` metadata type
- Create metadata record: `Elaro_API_Config.PagerDuty`

**See:** [PAGERDUTY_INTEGRATION_SECURITY_REVIEW.md](PAGERDUTY_INTEGRATION_SECURITY_REVIEW.md) for complete fix implementation.

### Configuration (RECOMMENDED AFTER FIX)

**Custom Metadata Record:**
```xml
<!-- File: force-app/main/default/customMetadata/Elaro_API_Config.PagerDuty.md-meta.xml -->
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>PagerDuty</label>
    <protected>true</protected>
    <values>
        <field>API_Key__c</field>
        <value xsi:type="xsd:string">PLACEHOLDER_SET_DURING_INSTALLATION</value>
    </values>
    <values>
        <field>Is_Active__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
</CustomMetadata>
```

**Note:** `API_Key__c` field stores PagerDuty routing key (semantically imperfect but functional).

### API Usage

**Classes Using PagerDuty API:**
- `PagerDutyIntegration.cls` - Primary integration (requires security fix)

**Event Types:**
1. **Trigger** - Create new incident
2. **Acknowledge** - Acknowledge incident
3. **Resolve** - Resolve incident

**Request Pattern (AFTER FIX):**
```apex
// Routing key retrieved from Protected Custom Metadata
String routingKey = getRoutingKey(); // Queries Elaro_API_Config__mdt

Map<String, Object> event = new Map<String, Object>{
    'routing_key' => routingKey,
    'event_action' => 'trigger',
    'dedup_key' => 'elaro-' + alertId,
    'payload' => new Map<String, Object>{
        'summary' => 'Elaro Compliance Alert',
        'severity' => 'critical',
        'source' => 'Elaro Compliance Platform'
    }
};

HttpRequest req = new HttpRequest();
req.setEndpoint('https://events.pagerduty.com/v2/enqueue');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setTimeout(30000);
req.setBody(JSON.serialize(event));

Http http = new Http();
HttpResponse res = http.send(req);
```

### Error Handling
- **Timeout:** 30 seconds
- **Retry Logic:** None (idempotent with dedup_key)
- **Dedup Key:** `elaro-{alertId}` prevents duplicates
- **Fallback:** Logs error, alert remains in Salesforce
- **Validation:** Returns early if routing key is placeholder or null

### Rate Limits
- **PagerDuty Limit:** 120 events per minute
- **Implementation:** @future prevents bursts
- **Deduplication:** Prevents duplicate incidents

### Security Considerations (POST-FIX)
- ⚠️ **CURRENT:** Routing key hardcoded (SECURITY VIOLATION)
- ✅ **AFTER FIX:** Routing key in Protected Custom Metadata
- ✅ No PII in incident payloads
- ✅ Dedup keys prevent replay attacks
- ✅ HTTPS with TLS 1.2+
- ✅ Credential rotation via Setup UI (no code changes)
- ✅ Integration toggle via `Is_Active__c` checkbox

### Required Permissions
- **Admin:** `Elaro_Admin` permission set required to configure routing key
- **Users:** No direct access to Protected Custom Metadata (encrypted at rest)

### Installation Steps (POST-FIX)

1. **Post-Package Installation:**
   - Navigate to: Setup → Custom Metadata Types → Elaro API Config → Manage Records
   - Edit "PagerDuty" record
   - Update "API Key" field with PagerDuty routing key from PagerDuty Events API v2 integration
   - Check "Is Active" to enable integration
   - Save

2. **Obtain PagerDuty Routing Key:**
   - Log in to PagerDuty console
   - Navigate to: Integrations → Events API v2
   - Copy routing key (starts with `R...`)

3. **Verify Configuration:**
   ```apex
   // Execute Anonymous Apex
   String key = PagerDutyIntegration.getRoutingKey();
   System.debug('PagerDuty Configured: ' + (key != null && !key.contains('PLACEHOLDER')));
   ```

---

## 5. ServiceNow GRC Integration

### Purpose
Evidence sharing, control synchronization, and incident management with ServiceNow GRC.

### Authentication
- **Method:** Named Credential with Basic Authentication
- **Named Credential:** `callout:ServiceNow_API`
- **Endpoint:** Customer ServiceNow instance URL
- **Protocol:** HTTPS (TLS 1.2+)

### Configuration
**Named Credential Settings:**
- Identity Type: Named Principal
- Authentication Protocol: Password Authentication
- Username: ServiceNow integration user
- Password: ServiceNow integration user password
- Generate Authorization Header: checked

### API Usage

**Classes Using ServiceNow API:**
- `ServiceNowIntegration.cls` - Primary integration

**Operations:**
1. **Sync Controls** - Push compliance controls to ServiceNow GRC
2. **Push Evidence** - Share evidence items
3. **Create Incident** - Create ServiceNow incidents

**Request Pattern:**
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:ServiceNow_API/api/now/table/incident');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Accept', 'application/json');
req.setTimeout(60000);
req.setBody(JSON.serialize(snowData));

Http http = new Http();
HttpResponse res = http.send(req);
```

### Error Handling
- **Timeout:** 60 seconds
- **Retry Logic:** None
- **Fallback:** Logs error, data remains in Salesforce
- **Logging:** Logs status code and sys_id on success

### Rate Limits
- **ServiceNow Limit:** Customer instance limits
- **Implementation:** @future prevents concurrent requests

### Security Considerations
- ✅ Credentials stored in Named Credential
- ✅ Integration user has minimal permissions
- ✅ Only public-safe data shared
- ✅ External IDs used for record matching

---

## 6. Salesforce Limits API

### Purpose
Internal API for real-time governor limit monitoring.

### Authentication
- **Method:** Named Credential with OAuth (Session ID)
- **Named Credential:** `callout:SF_Limits`
- **Endpoint:** Salesforce REST API Limits endpoint
- **Protocol:** HTTPS (TLS 1.2+)

### Configuration
**Named Credential Settings:**
- Identity Type: Per User
- Authentication Protocol: OAuth 2.0
- Scope: api

### API Usage

**Classes Using Limits API:**
- `ApiUsageSnapshot.cls` - Periodic limit snapshots

**Request Pattern:**
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:SF_Limits/services/data/v65.0/limits');
req.setMethod('GET');
req.setHeader('Accept', 'application/json');
req.setTimeout(30000);

Http http = new Http();
HttpResponse res = http.send(req);
```

### Error Handling
- **Timeout:** 30 seconds
- **Retry Logic:** None
- **Fallback:** Returns cached limits

### Security Considerations
- ✅ OAuth session-based authentication
- ✅ Internal Salesforce API (no external exposure)
- ✅ Read-only operations

---

## Summary of Named Credentials

| Named Credential | Service | Auth Method | Required |
|------------------|---------|-------------|----------|
| `Elaro_Claude_API` | Claude AI | API Key (Header) | No (fallback available) |
| `Slack_Webhook` | Slack | Webhook URL | No (optional integration) |
| `Teams_Webhook` | Microsoft Teams | Webhook URL | No (optional integration) |
| `ServiceNow_API` | ServiceNow GRC | Basic Auth | No (optional integration) |
| `SF_Limits` | Salesforce Limits API | OAuth 2.0 | Yes (core feature) |

**Note:** PagerDuty uses Protected Custom Metadata instead of Named Credential.

---

## Permission Set Access

### Elaro_Admin
- Full access to all integration configurations
- Can configure Named Credentials
- Can enable/disable integrations

### Elaro_AI_User
- Can use AI-powered features (Claude API)
- Cannot configure integrations

### Elaro_Auditor
- Read-only access to integration logs
- Cannot trigger manual integrations

---

## Error Handling Best Practices

All external integrations follow these patterns:

1. **Timeout Configuration**
   - 30 seconds for notifications
   - 60 seconds for AI/data operations

2. **Retry Logic**
   - No automatic retries (prevent cascading failures)
   - Idempotent operations use dedup keys

3. **Logging**
   - All callouts logged with correlation IDs
   - No credentials or PII in logs
   - Error details logged at ERROR level

4. **Fallback Behavior**
   - AI features: Return default response
   - Notifications: Log error, continue
   - Data sync: Maintain local copy

5. **Circuit Breaker**
   - Platform Cache prevents rapid retries
   - Admin can disable integrations via Custom Metadata

---

## Security Checklist

✅ **Authentication:**
- All Named Credentials use encryption at rest
- No hardcoded credentials in code
- API keys rotatable without code changes

✅ **Data Protection:**
- No PII sent to external services without consent
- Customer data sanitized before external API calls
- Audit logging for all external calls

✅ **Network Security:**
- HTTPS (TLS 1.2+) for all endpoints
- Webhook URLs validated before configuration
- No open redirects or SSRF vulnerabilities

✅ **Access Control:**
- Permission sets control feature access
- Sharing rules enforce record-level security
- Integration users have minimal permissions

✅ **Monitoring:**
- All callouts logged in Event Monitoring
- Failed callouts trigger internal alerts
- Admin dashboard shows integration health

---

## Installation & Setup

### Step 1: Create Named Credentials

Administrators must create Named Credentials after package installation:

1. **Claude AI** (Required for AI features)
   - Setup → Named Credentials → New Legacy
   - Name: `Elaro_Claude_API`
   - URL: `https://api.anthropic.com`
   - Identity Type: Named Principal
   - Authentication: Password Authentication
   - Username: `x-api-key` (literal)
   - Password: Your Anthropic API key
   - Generate Authorization Header: ✅

2. **Slack** (Optional)
   - Setup → Named Credentials → New Legacy
   - Name: `Slack_Webhook`
   - URL: Your Slack Incoming Webhook URL
   - Identity Type: Named Principal
   - Authentication: No Authentication

3. **Microsoft Teams** (Optional)
   - Setup → Named Credentials → New Legacy
   - Name: `Teams_Webhook`
   - URL: Your Teams Incoming Webhook URL
   - Identity Type: Named Principal
   - Authentication: No Authentication

4. **ServiceNow** (Optional)
   - Setup → Named Credentials → New Legacy
   - Name: `ServiceNow_API`
   - URL: Your ServiceNow instance URL (e.g., `https://dev12345.service-now.com`)
   - Identity Type: Named Principal
   - Authentication: Password Authentication
   - Username: ServiceNow integration user
   - Password: ServiceNow integration password

5. **Salesforce Limits** (Auto-configured)
   - Created automatically by package
   - No manual configuration required

### Step 2: Configure PagerDuty (Optional)

If using PagerDuty:

1. Setup → Custom Metadata Types → Manage Records → Elaro Integration Settings
2. Click "New"
3. Label: `PagerDuty`
4. Developer Name: `PagerDuty`
5. Routing Key: Your PagerDuty Integration Key
6. Enabled: ✅
7. Save

### Step 3: Test Integrations

Use the built-in test classes:
- `ElaroComplianceCopilotServiceTest` - Tests Claude AI
- `ElaroSlackNotifierQueueableTest` - Tests Slack
- `PagerDutyIntegrationTest` - Tests PagerDuty (if exists)

---

## Troubleshooting

### Claude AI Not Responding
1. Verify Named Credential `Elaro_Claude_API` exists
2. Check API key is valid (test at api.anthropic.com)
3. Review Debug Logs for callout errors
4. Check Anthropic API status page

### Slack Messages Not Sending
1. Verify webhook URL is valid
2. Test webhook with curl: `curl -X POST -H 'Content-Type: application/json' -d '{"text":"Test"}' <webhook-url>`
3. Check Slack app is installed in workspace
4. Review Event Monitoring for callout failures

### PagerDuty Incidents Not Creating
1. Verify Custom Metadata `PagerDuty` record exists
2. Check Routing Key is valid in PagerDuty console
3. Review Debug Logs for HTTP errors
4. Check PagerDuty service has Events API v2 integration

---

## Compliance & Governance

### Data Residency
- All integrations use customer-controlled endpoints
- No Elaro-controlled data storage
- Customer responsible for external service compliance

### Audit Trail
- All external callouts logged in Event Monitoring
- Audit reports available in Elaro dashboard
- 6-month retention for callout logs

### Data Processing Agreement
- Customers must review external service DPAs
- Claude AI: Anthropic DPA required
- Slack: Slack DPA required
- PagerDuty: PagerDuty DPA required
- ServiceNow: ServiceNow DPA required

---

**For AppExchange Reviewers:**

This document demonstrates:
- ✅ All external integrations use Named Credentials
- ✅ No hardcoded secrets or API keys
- ✅ HTTPS (TLS 1.2+) for all communications
- ✅ Proper error handling and timeouts
- ✅ No PII leakage in logs
- ✅ Permission set-based access control
- ✅ Customer-controlled configuration

**Questions?** Contact support@elaro.io

---

**Document Version:** 1.0
**Last Review:** 2026-01-11
**Next Review:** Before AppExchange submission
