# Prometheion API Reference

Complete API documentation for Prometheion Apex classes and Lightning Web Components.

## Table of Contents

- [PrometheionComplianceScorer](#prometheioncompliancescorer)
- [PrometheionComplianceCopilot](#prometheioncompliancecopilot)
- [PrometheionClaudeService](#prometheionclaudeservice)
- [PrometheionQuickActionsService](#prometheionquickactionsservice)
- [PrometheionEmailDigestService](#prometheionemaildigestservice)
- [PrometheionComplianceChecklistService](#prometheioncompliancechecklistservice)
- [PrometheionConstants](#prometheionconstants)

---

## PrometheionComplianceScorer

Calculates comprehensive compliance scores across multiple frameworks.

### Methods

#### `calculateReadinessScore()`

Calculates overall compliance readiness score with framework-specific breakdowns.

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static ScoreResult calculateReadinessScore()
```

**Returns:** `ScoreResult` object

**ScoreResult Properties:**

- `overallScore` (Decimal): Overall score 0-100
- `rating` (String): CRITICAL, HIGH, MEDIUM, LOW, or EXCELLENT
- `frameworkScores` (Map<String, Decimal>): Framework-specific scores
- `topRisks` (List<Risk>): Top compliance risks
- `factors` (Map<String, Decimal>): Scoring factors breakdown

**Example:**

```apex
PrometheionComplianceScorer.ScoreResult result =
    PrometheionComplianceScorer.calculateReadinessScore();
System.debug('Overall Score: ' + result.overallScore);
System.debug('Rating: ' + result.rating);
```

**Caching:** Results are cached for 5 minutes in Platform Cache partition `local.PrometheionCompliance`

---

## PrometheionComplianceCopilot

Natural language AI interface for compliance queries.

### Methods

#### `askCopilot(String query)`

Processes natural language compliance queries using Claude AI.

**Signature:**

```apex
@AuraEnabled
public static CopilotResponse askCopilot(String query)
```

**Parameters:**

- `query` (String): Natural language question about compliance

**Returns:** `CopilotResponse` object

**CopilotResponse Properties:**

- `answer` (String): AI-generated response
- `confidence` (Decimal): Confidence score 0.0-1.0
- `queryType` (String): Classification (SCORE, RISK, USER_ACCESS, etc.)
- `suggestedActions` (List<String>): Recommended actions

**Example:**

```apex
PrometheionComplianceCopilot.CopilotResponse response =
    PrometheionComplianceCopilot.askCopilot('What are our top compliance risks?');
System.debug('Answer: ' + response.answer);
System.debug('Confidence: ' + response.confidence);
```

#### `deepAnalysis(String topic)`

Performs deep compliance analysis on a specific topic.

**Signature:**

```apex
@AuraEnabled
public static CopilotResponse deepAnalysis(String topic)
```

**Parameters:**

- `topic` (String): Topic to analyze (e.g., "HIPAA compliance", "permission sprawl")

**Returns:** `CopilotResponse` with detailed analysis

**Example:**

```apex
PrometheionComplianceCopilot.CopilotResponse analysis =
    PrometheionComplianceCopilot.deepAnalysis('HIPAA compliance');
```

#### `getQuickCommands()`

Returns list of available quick commands for the copilot.

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<String> getQuickCommands()
```

**Returns:** List of command strings

---

## PrometheionClaudeService

Integration service for Anthropic Claude API.

### Methods

#### `askCompliance(String query, String orgContext)`

Sends compliance query to Claude API.

**Signature:**

```apex
public static ClaudeResponse askCompliance(String query, String orgContext)
```

**Parameters:**

- `query` (String): User's question
- `orgContext` (String): Organization context information

**Returns:** `ClaudeResponse` object

**ClaudeResponse Properties:**

- `success` (Boolean): Whether request succeeded
- `content` (String): Claude's response text
- `errorMessage` (String): Error message if failed

**Note:** This is an internal service method. Use `PrometheionComplianceCopilot.askCopilot()` for public API.

---

## PrometheionQuickActionsService

One-click remediation actions for compliance violations.

### Methods

#### `revokeModifyAllData(List<Id> userIds)`

Revokes Modify All Data permission from specified users.

**Signature:**

```apex
@AuraEnabled
public static void revokeModifyAllData(List<Id> userIds)
```

**Parameters:**

- `userIds` (List<Id>): List of User IDs

**Throws:** `AuraHandledException` if operation fails

**Example:**

```apex
List<Id> userIds = new List<Id>{'005xx000000abc', '005xx000000def'};
PrometheionQuickActionsService.revokeModifyAllData(userIds);
```

#### `deactivateInactiveUsers(Integer daysInactive)`

Deactivates users inactive for specified number of days.

**Signature:**

```apex
@AuraEnabled
public static Integer deactivateInactiveUsers(Integer daysInactive)
```

**Parameters:**

- `daysInactive` (Integer): Number of days of inactivity threshold

**Returns:** Number of users deactivated

**Example:**

```apex
Integer deactivated = PrometheionQuickActionsService.deactivateInactiveUsers(90);
System.debug('Deactivated ' + deactivated + ' users');
```

#### `removePermissionSetAssignment(Id assignmentId)`

Removes a specific permission set assignment.

**Signature:**

```apex
@AuraEnabled
public static void removePermissionSetAssignment(Id assignmentId)
```

**Parameters:**

- `assignmentId` (Id): PermissionSetAssignment ID

**Throws:** `AuraHandledException` if operation fails

---

## PrometheionEmailDigestService

Service for sending weekly compliance summary emails.

### Methods

#### `sendWeeklyDigest()`

Sends weekly compliance digest to all Prometheion Admin users.

**Signature:**

```apex
@InvocableMethod(label='Send Weekly Compliance Digest'
                 description='Sends a weekly compliance summary email to Prometheion administrators.')
public static void sendWeeklyDigest()
```

**Usage:** Can be called from:

- Flow Builder (Invocable Method)
- Apex Scheduler
- Anonymous Apex

**Example (Scheduled):**

```apex
// Schedule weekly digest (every Monday at 9 AM)
String cronExp = '0 0 9 ? * MON';
System.schedule('Prometheion Weekly Digest', cronExp,
    new PrometheionEmailDigestScheduler());
```

---

## PrometheionComplianceChecklistService

Provides compliance checklist items for each framework.

### Methods

#### `getComplianceChecklist(String framework)`

Returns checklist items for specified framework.

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<ChecklistItem> getComplianceChecklist(String framework)
```

**Parameters:**

- `framework` (String): Framework name (HIPAA, SOC2, NIST, FedRAMP, GDPR)

**Returns:** List of `ChecklistItem` objects

**ChecklistItem Properties:**

- `id` (String): Unique identifier
- `title` (String): Checklist item title
- `description` (String): Detailed description
- `completed` (Boolean): Whether item is completed
- `severity` (String): CRITICAL, HIGH, MEDIUM, or LOW
- `remediation` (String): Remediation steps

**Example:**

```apex
List<PrometheionComplianceChecklistService.ChecklistItem> items =
    PrometheionComplianceChecklistService.getComplianceChecklist('HIPAA');
for (PrometheionComplianceChecklistService.ChecklistItem item : items) {
    System.debug(item.title + ': ' + (item.completed ? 'Complete' : 'Incomplete'));
}
```

---

## PrometheionConstants

Centralized constants for the Prometheion application.

### Framework Constants

```apex
PrometheionConstants.FRAMEWORK_HIPAA      // "HIPAA"
PrometheionConstants.FRAMEWORK_SOC2       // "SOC2"
PrometheionConstants.FRAMEWORK_NIST       // "NIST"
PrometheionConstants.FRAMEWORK_FEDRAMP    // "FedRAMP"
PrometheionConstants.FRAMEWORK_GDPR       // "GDPR"
PrometheionConstants.FRAMEWORK_ISO27001   // "ISO27001"
PrometheionConstants.FRAMEWORK_PCI_DSS    // "PCI_DSS"
```

### Severity Constants

```apex
PrometheionConstants.SEVERITY_CRITICAL    // "CRITICAL"
PrometheionConstants.SEVERITY_HIGH         // "HIGH"
PrometheionConstants.SEVERITY_MEDIUM      // "MEDIUM"
PrometheionConstants.SEVERITY_LOW          // "LOW"
```

### Rating Constants

```apex
PrometheionConstants.RATING_CRITICAL      // "CRITICAL"
PrometheionConstants.RATING_HIGH          // "HIGH"
PrometheionConstants.RATING_MEDIUM        // "MEDIUM"
PrometheionConstants.RATING_LOW           // "LOW"
PrometheionConstants.RATING_EXCELLENT     // "EXCELLENT"
```

### Query Limit Constants

```apex
PrometheionConstants.LIMIT_AUDIT_RECENT      // 50
PrometheionConstants.LIMIT_SCORE_CHANGE      // 100
PrometheionConstants.LIMIT_RISKY_FLOWS       // 20
PrometheionConstants.LIMIT_VIOLATIONS        // 200
PrometheionConstants.LIMIT_ELEVATED_USERS    // 100
```

### Utility Methods

#### `getRatingFromScore(Decimal score)`

Converts numeric score to rating string.

**Signature:**

```apex
public static String getRatingFromScore(Decimal score)
```

**Returns:** Rating constant based on score thresholds

---

## Error Handling

All methods throw `AuraHandledException` for user-facing errors. Check debug logs for detailed error information.

**Example Error Handling:**

```apex
try {
    PrometheionComplianceScorer.ScoreResult result =
        PrometheionComplianceScorer.calculateReadinessScore();
} catch (AuraHandledException e) {
    System.debug('Error: ' + e.getMessage());
    // Handle error appropriately
}
```

---

## Best Practices

1. **Use Cached Methods**: Methods marked `cacheable=true` leverage Platform Cache
2. **Batch Operations**: Use bulkified methods for multiple records
3. **Error Handling**: Always wrap calls in try-catch blocks
4. **Governor Limits**: Be aware of SOQL query limits (see PrometheionConstants)
5. **Sharing Rules**: All classes use `with sharing` - respect org sharing model

---

## Version

API Version: 64.0  
Prometheion Version: 1.5.0
