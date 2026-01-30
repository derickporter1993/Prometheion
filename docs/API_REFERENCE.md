# Elaro API Reference

## Overview

This document provides a comprehensive reference for all Elaro APIs, including REST endpoints and Apex controllers accessible from Lightning Web Components.

---

## REST Endpoints

### POST /services/apexrest/elaro/score/callback

Receives compliance scores from external systems (e.g., AWS Lambda) and updates the `Compliance_Score__c` records. Also publishes Platform Events for real-time UI updates.

**URL:** `/services/apexrest/elaro/score/callback`

**Method:** `POST`

**Authentication:** API Key (header)

#### Request Headers

| Header | Required | Description |
|--------|----------|-------------|
| `X-Elaro-Api-Key` | Yes | API key configured in `Elaro_API_Config__mdt` |
| `Content-Type` | Yes | Must be `application/json` |

#### Request Body

```json
{
  "orgId": "00Dxx0000001234AAA",
  "entityType": "PERMISSION_SET",
  "entityId": "0PSxx0000001234AAA",
  "riskScore": 7.5,
  "frameworkScores": {
    "HIPAA": 85.0,
    "SOC2": 90.0,
    "GDPR": 78.5,
    "PCI_DSS": 92.0
  },
  "findings": [
    "Excessive permissions detected on Permission Set",
    "Missing audit trail for sensitive operations",
    "Password policy does not meet HIPAA requirements"
  ],
  "s3Key": "scores/2025/01/org-12345-score.json"
}
```

#### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `orgId` | String | Yes | Salesforce Organization ID (18-char) |
| `entityType` | String | Yes | Type of entity scored: `PERMISSION_SET`, `PROFILE`, `USER`, `ORG` |
| `entityId` | String | Yes | Salesforce ID of the entity being scored |
| `riskScore` | Decimal | Yes | Overall risk score (0.0-10.0, higher = more risk) |
| `frameworkScores` | Object | No | Map of framework names to compliance scores (0-100) |
| `findings` | Array | No | List of compliance findings as strings |
| `s3Key` | String | No | Reference to detailed report in external storage |

#### Response (Success - 200)

```json
{
  "success": true,
  "scoreId": "a00xx0000001234AAA"
}
```

#### Response (Validation Error - 400)

```json
{
  "success": false,
  "error": "Failed to upsert Compliance_Score__c record",
  "details": "Field value too long: Findings__c (FIELD_CUSTOM_VALIDATION_EXCEPTION)"
}
```

#### Response (Unauthorized - 401)

```json
{
  "success": false,
  "error": "Unauthorized"
}
```

#### Response (Server Error - 500)

```json
{
  "success": false,
  "error": "An internal error occurred"
}
```

#### Risk Level Calculation

The endpoint automatically calculates risk level based on score:

| Risk Score | Risk Level |
|------------|------------|
| 8.0 - 10.0 | CRITICAL |
| 6.0 - 7.9 | HIGH |
| 4.0 - 5.9 | MEDIUM |
| 0.0 - 3.9 | LOW |

#### Platform Event

Upon successful score update, a `Elaro_Score_Result__e` Platform Event is published with:

```json
{
  "Org_ID__c": "00Dxx0000001234AAA",
  "Score_ID__c": "a00xx0000001234AAA",
  "Overall_Score__c": 7.5,
  "Framework_Scores__c": "{\"HIPAA\":85.0,\"SOC2\":90.0}",
  "Risk_Level__c": "HIGH"
}
```

---

## Apex Controllers (@AuraEnabled)

### ComplianceDashboardController

Dashboard backend for compliance metrics and visualization.

#### getDashboardSummary()

Returns a comprehensive summary of compliance status across all frameworks.

```apex
@AuraEnabled(cacheable=false)
public static DashboardSummary getDashboardSummary()
```

**Returns:** `DashboardSummary`

```json
{
  "lastUpdated": "2025-01-08T10:30:00.000Z",
  "frameworks": [
    {
      "framework": "HIPAA",
      "score": 85.0,
      "status": "PARTIALLY_COMPLIANT",
      "totalPolicies": 45,
      "compliantPolicies": 38,
      "gapCount": 7
    },
    {
      "framework": "SOC2",
      "score": 92.0,
      "status": "COMPLIANT",
      "totalPolicies": 64,
      "compliantPolicies": 59,
      "gapCount": 5
    }
  ],
  "recentGaps": [...],
  "recentEvidence": [...]
}
```

#### getFrameworkDashboard(String framework)

Returns detailed dashboard data for a specific compliance framework.

```apex
@AuraEnabled(cacheable=false)
public static FrameworkDashboardData getFrameworkDashboard(String framework)
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `framework` | String | Yes | Framework name (e.g., `HIPAA`, `SOC2`, `GDPR`) |

**Returns:** `FrameworkDashboardData`

```json
{
  "framework": "HIPAA",
  "evaluation": {
    "overallScore": 85.0,
    "status": "PARTIALLY_COMPLIANT",
    "totalPolicies": 45,
    "compliantPolicies": 38,
    "gaps": [...]
  },
  "gaps": [...],
  "evidence": [...]
}
```

**Throws:** `IllegalArgumentException` if framework is blank

---

### ElaroExecutiveKPIController

Metadata-driven KPI dashboard with real-time Platform Event refresh.

#### getKPIMetrics(String metadataRecordIds)

Returns all active KPI metrics configured in Custom Metadata.

```apex
@AuraEnabled(cacheable=true)
public static List<KPIMetric> getKPIMetrics(String metadataRecordIds)
```

**Returns:** `List<KPIMetric>`

```json
[
  {
    "kpiName": "compliance_score",
    "label": "Overall Compliance Score",
    "description": "Average compliance score across all frameworks",
    "currentValue": 87.5,
    "targetValue": 90.0,
    "greenThreshold": 85.0,
    "yellowThreshold": 70.0,
    "redThreshold": 50.0,
    "formatType": "percentage",
    "trendDirection": "higher_is_better",
    "status": "green",
    "percentOfTarget": 97.2,
    "hasError": false
  }
]
```

#### getKPIByName(String kpiName)

Returns a single KPI metric by name (for real-time refresh).

```apex
@AuraEnabled
public static KPIMetric getKPIByName(String kpiName)
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `kpiName` | String | Yes | The unique KPI name from Custom Metadata |

**Returns:** `KPIMetric`

**Throws:** `AuraHandledException` if KPI not found

---

### ElaroComplianceScorer

Calculates real-time compliance scores across frameworks.

#### calculateReadinessScore()

Calculates the overall compliance readiness score.

```apex
@AuraEnabled(cacheable=false)
public static ScoreResult calculateReadinessScore()
```

**Returns:** `ScoreResult`

```json
{
  "overallScore": 86.5,
  "rating": "B+",
  "frameworkScores": {
    "HIPAA": 85.0,
    "SOC2": 92.0,
    "GDPR": 78.5,
    "PCI_DSS": 90.0
  },
  "factors": [
    {
      "name": "Access Controls",
      "score": 85.0,
      "status": "GOOD"
    },
    {
      "name": "Data Protection",
      "score": 78.0,
      "status": "NEEDS_IMPROVEMENT"
    }
  ],
  "topRisks": [
    {
      "title": "Password Policy Gap",
      "severity": "HIGH",
      "description": "Password expiration not enforced",
      "framework": "HIPAA"
    }
  ]
}
```

---

### ElaroComplianceCopilot

AI-powered natural language interface for compliance queries.

#### askQuestion(String question)

Processes a natural language question about compliance.

```apex
@AuraEnabled
public static CopilotResponse askQuestion(String question)
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `question` | String | Yes | Natural language question (max 1000 chars) |

**Example Questions:**
- "What are our critical HIPAA gaps?"
- "Show me SOC2 evidence from last month"
- "What's our PCI-DSS readiness?"
- "Who owns the most compliance gaps?"

**Returns:** `CopilotResponse`

```json
{
  "answer": "You have 3 critical HIPAA gaps...",
  "suggestedActions": [
    {
      "label": "View HIPAA Gaps",
      "type": "navigation",
      "target": "/lightning/n/Elaro_Gaps?framework=HIPAA"
    }
  ],
  "relatedRecords": [
    {
      "id": "a00xx0000001234AAA",
      "name": "GAP-0001",
      "type": "Compliance_Gap__c"
    }
  ]
}
```

---

### ElaroDrillDownController

Provides drill-down functionality for compliance metrics.

#### getDrillDownData(String metricType, String framework, String timeRange)

Returns detailed drill-down data for a specific metric.

```apex
@AuraEnabled(cacheable=true)
public static DrillDownResult getDrillDownData(String metricType, String framework, String timeRange)
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `metricType` | String | Yes | Type: `GAPS`, `EVIDENCE`, `SCORE`, `USERS` |
| `framework` | String | No | Filter by framework (null = all frameworks) |
| `timeRange` | String | No | Filter by time: `TODAY`, `WEEK`, `MONTH`, `QUARTER`, `YEAR` |

**Returns:** `DrillDownResult`

---

### ElaroTrendController

Provides trend analysis data for compliance scores.

#### getTrendData(String framework, Integer months)

Returns historical trend data for compliance scores.

```apex
@AuraEnabled(cacheable=true)
public static List<TrendDataPoint> getTrendData(String framework, Integer months)
```

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `framework` | String | No | All | Filter by framework |
| `months` | Integer | No | 12 | Number of months of history |

**Returns:** `List<TrendDataPoint>`

```json
[
  {
    "month": "2024-12",
    "score": 82.5,
    "gapCount": 12,
    "evidenceCount": 45
  },
  {
    "month": "2025-01",
    "score": 86.5,
    "gapCount": 8,
    "evidenceCount": 52
  }
]
```

---

### AuditReportController

Generates audit-ready compliance reports.

#### generateReport(ReportRequest request)

Generates a compliance audit report.

```apex
@AuraEnabled
public static ReportResult generateReport(ReportRequest request)
```

**Request:**

```json
{
  "reportType": "EXECUTIVE_SUMMARY",
  "frameworks": ["HIPAA", "SOC2"],
  "startDate": "2024-01-01",
  "endDate": "2024-12-31",
  "includeEvidence": true,
  "includeGaps": true
}
```

**Report Types:**
- `EXECUTIVE_SUMMARY` - High-level overview for executives
- `DETAILED_GAP_ANALYSIS` - Comprehensive gap report
- `EVIDENCE_COLLECTION` - All evidence organized by framework
- `AUDIT_PACKAGE` - Complete package for auditors

**Returns:** `ReportResult`

```json
{
  "reportId": "a01xx0000001234AAA",
  "status": "COMPLETED",
  "downloadUrl": "/sfc/servlet.shepherd/document/download/069xx...",
  "generatedAt": "2025-01-08T10:30:00.000Z",
  "pageCount": 45
}
```

---

### ElaroGDPRDataErasureService

Handles GDPR Right to Erasure (Article 17) requests.

#### initiateErasure(Id contactId, String reason)

Initiates a GDPR data erasure request.

```apex
@AuraEnabled
public static ErasureResult initiateErasure(Id contactId, String reason)
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `contactId` | Id | Yes | Contact to erase |
| `reason` | String | Yes | Legal basis for erasure |

**Returns:** `ErasureResult`

```json
{
  "success": true,
  "requestId": "a02xx0000001234AAA",
  "status": "PENDING",
  "estimatedCompletion": "2025-01-09T10:30:00.000Z"
}
```

---

### ElaroISO27001AccessReviewService

Manages ISO 27001 access reviews.

#### initiateQuarterlyReviews()

Creates quarterly access review records for all active users.

```apex
@AuraEnabled
public static List<Access_Review__c> initiateQuarterlyReviews()
```

**Returns:** `List<Access_Review__c>` - Created review records

#### getReviewMetrics()

Returns metrics about access review completion.

```apex
@AuraEnabled(cacheable=true)
public static ReviewMetrics getReviewMetrics()
```

**Returns:** `ReviewMetrics`

```json
{
  "reviewsThisQuarter": 156,
  "completionRate": 85.5,
  "overdueCount": 12,
  "privilegedUsersCount": 8,
  "dormantAccountsCount": 3
}
```

---

## Data Types

### Common Response Types

#### AuraEnabled Response Pattern

All @AuraEnabled methods follow this error handling pattern:

```javascript
// Success
return { success: true, data: {...} };

// Error (throws AuraHandledException)
throw new AuraHandledException('Error message');
```

#### Pagination Pattern

Methods returning large datasets support pagination:

```apex
@AuraEnabled
public static PagedResult getRecords(Integer pageNumber, Integer pageSize)
```

```json
{
  "records": [...],
  "totalRecords": 1250,
  "pageNumber": 1,
  "pageSize": 50,
  "totalPages": 25,
  "hasMore": true
}
```

---

## Error Handling

### HTTP Status Codes (REST)

| Code | Meaning | When Used |
|------|---------|-----------|
| 200 | Success | Request completed successfully |
| 400 | Bad Request | Validation error, malformed request |
| 401 | Unauthorized | Missing or invalid API key |
| 403 | Forbidden | User lacks permission |
| 404 | Not Found | Resource doesn't exist |
| 500 | Server Error | Unexpected error |

### AuraHandledException (LWC)

Controllers throw `AuraHandledException` for user-facing errors:

```apex
throw new AuraHandledException('Contact not found: ' + contactId);
```

In LWC:

```javascript
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

try {
    const result = await getData();
} catch (error) {
    this.dispatchEvent(new ShowToastEvent({
        title: 'Error',
        message: error.body.message,
        variant: 'error'
    }));
}
```

---

## Rate Limits

### API Limits

- REST endpoints respect Salesforce API limits
- Consider using Platform Events for high-volume integrations
- Batch operations limited to 200 records per transaction

### Caching

Methods marked `cacheable=true` are cached for 30 seconds:

```apex
@AuraEnabled(cacheable=true)
public static List<KPIMetric> getKPIMetrics()
```

Use `refreshApex()` in LWC to invalidate cache:

```javascript
import { refreshApex } from '@salesforce/apex';
await refreshApex(this.wiredResult);
```

---

## Security

### FLS/CRUD Enforcement

All queries use `WITH SECURITY_ENFORCED`:

```apex
SELECT Id, Name FROM Account WITH SECURITY_ENFORCED
```

### Input Validation

All string inputs are sanitized:

```apex
String sanitizedInput = input.replaceAll('[^a-zA-Z0-9_]+', '');
```

### API Key Configuration

Configure API keys in Custom Metadata:

1. Navigate to Setup > Custom Metadata Types
2. Find `Elaro_API_Config__mdt`
3. Create a record with `DeveloperName = 'Default'`
4. Set `API_Key__c` and `Is_Active__c = true`

---

## Versioning

Current API Version: **1.0**

The API follows semantic versioning. Breaking changes will increment the major version.
