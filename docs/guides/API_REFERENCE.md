# Elaro API Reference

Complete API documentation for Elaro Apex classes and Lightning Web Components.

## Table of Contents

- [ElaroComplianceScorer](#elarocompliancescorer)
- [ElaroComplianceCopilot](#elarocompliancecopilot)
- [ElaroClaudeService](#elaroclaudeservice)
- [ElaroQuickActionsService](#elaroquickactionsservice)
- [ElaroEmailDigestService](#elaroemaildigestservice)
- [ElaroComplianceChecklistService](#elarocompliancechecklistservice)
- [ElaroConstants](#elaroconstants)

---

## ElaroComplianceScorer

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
ElaroComplianceScorer.ScoreResult result =
    ElaroComplianceScorer.calculateReadinessScore();
System.debug('Overall Score: ' + result.overallScore);
System.debug('Rating: ' + result.rating);
```

**Caching:** Results are cached for 5 minutes in Platform Cache partition `local.ElaroCompliance`

---

## ElaroComplianceCopilot

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
ElaroComplianceCopilot.CopilotResponse response =
    ElaroComplianceCopilot.askCopilot('What are our top compliance risks?');
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
ElaroComplianceCopilot.CopilotResponse analysis =
    ElaroComplianceCopilot.deepAnalysis('HIPAA compliance');
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

## ElaroClaudeService

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

**Note:** This is an internal service method. Use `ElaroComplianceCopilot.askCopilot()` for public API.

---

## ElaroQuickActionsService

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
ElaroQuickActionsService.revokeModifyAllData(userIds);
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
Integer deactivated = ElaroQuickActionsService.deactivateInactiveUsers(90);
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

## ElaroEmailDigestService

Service for sending weekly compliance summary emails.

### Methods

#### `sendWeeklyDigest()`

Sends weekly compliance digest to all Elaro Admin users.

**Signature:**

```apex
@InvocableMethod(label='Send Weekly Compliance Digest'
                 description='Sends a weekly compliance summary email to Elaro administrators.')
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
System.schedule('Elaro Weekly Digest', cronExp,
    new ElaroEmailDigestScheduler());
```

---

## ElaroComplianceChecklistService

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
List<ElaroComplianceChecklistService.ChecklistItem> items =
    ElaroComplianceChecklistService.getComplianceChecklist('HIPAA');
for (ElaroComplianceChecklistService.ChecklistItem item : items) {
    System.debug(item.title + ': ' + (item.completed ? 'Complete' : 'Incomplete'));
}
```

---

## ElaroConstants

Centralized constants for the Elaro application.

### Framework Constants

```apex
ElaroConstants.FRAMEWORK_HIPAA      // "HIPAA"
ElaroConstants.FRAMEWORK_SOC2       // "SOC2"
ElaroConstants.FRAMEWORK_NIST       // "NIST"
ElaroConstants.FRAMEWORK_FEDRAMP    // "FedRAMP"
ElaroConstants.FRAMEWORK_GDPR       // "GDPR"
ElaroConstants.FRAMEWORK_ISO27001   // "ISO27001"
ElaroConstants.FRAMEWORK_PCI_DSS    // "PCI_DSS"
```

### Severity Constants

```apex
ElaroConstants.SEVERITY_CRITICAL    // "CRITICAL"
ElaroConstants.SEVERITY_HIGH         // "HIGH"
ElaroConstants.SEVERITY_MEDIUM      // "MEDIUM"
ElaroConstants.SEVERITY_LOW          // "LOW"
```

### Rating Constants

```apex
ElaroConstants.RATING_CRITICAL      // "CRITICAL"
ElaroConstants.RATING_HIGH          // "HIGH"
ElaroConstants.RATING_MEDIUM        // "MEDIUM"
ElaroConstants.RATING_LOW           // "LOW"
ElaroConstants.RATING_EXCELLENT     // "EXCELLENT"
```

### Query Limit Constants

```apex
ElaroConstants.LIMIT_AUDIT_RECENT      // 50
ElaroConstants.LIMIT_SCORE_CHANGE      // 100
ElaroConstants.LIMIT_RISKY_FLOWS       // 20
ElaroConstants.LIMIT_VIOLATIONS        // 200
ElaroConstants.LIMIT_ELEVATED_USERS    // 100
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
    ElaroComplianceScorer.ScoreResult result =
        ElaroComplianceScorer.calculateReadinessScore();
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
4. **Governor Limits**: Be aware of SOQL query limits (see ElaroConstants)
5. **Sharing Rules**: All classes use `with sharing` - respect org sharing model

---

## Version

API Version: 64.0  
Elaro Version: 1.5.0
