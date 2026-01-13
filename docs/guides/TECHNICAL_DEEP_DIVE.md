# Prometheion Technical Deep-Dive: Business Plan Alignment Analysis

## Executive Summary

This document provides a comprehensive technical analysis of Prometheion's current codebase alignment with the business plan, identifying critical gaps, implementation strategies, and architectural recommendations for achieving the vision outlined in the business plan.

**Key Findings:**

- ✅ **Strong Foundation**: Core compliance scoring, AI copilot, and basic monitoring are implemented
- ⚠️ **Critical Gaps**: Missing event intelligence engine, configuration drift guard, evidence engine, and off-platform compute
- 🎯 **Strategic Priority**: Focus on architectural defensibility layers to differentiate from competitors

---

## 1. Event Intelligence Engine (CRITICAL GAP)

### Business Plan Requirement

> "Event Intelligence Engine: Real-time analysis of Salesforce Platform Events, Setup Audit Trail, and Event Monitoring data to detect compliance violations as they happen."

### Current State Analysis

**What Exists:**

- `PrometheionComplianceScorer.calculateConfigDriftScore()` queries `SetupAuditTrail` (lines 254-298)
- Basic polling of `SetupAuditTrail` for last 30 days
- Simple pattern matching on `Action` field (permission, profile, delete keywords)

**What's Missing:**

1. **Real-time event processing** - No Platform Event subscribers
2. **Event Monitoring integration** - No Shield Event Monitoring API calls
3. **Intelligent pattern detection** - No ML/AI-based anomaly detection
4. **Event correlation** - No cross-event analysis (e.g., permission change + user login + data export)
5. **Risk scoring per event** - Static thresholds, not dynamic risk assessment

### Technical Implementation Strategy

#### 1.1 Platform Event Architecture

**Create Custom Platform Events:**

```apex
// force-app/main/default/objects/Compliance_Event__e/Compliance_Event__e.object-meta.xml
// Platform Event for real-time compliance violations
```

**Event Publisher Service:**

```apex
public class PrometheionEventPublisher {
    /**
     * Publish compliance event when Setup Audit Trail change detected
     */
    public static void publishConfigChange(SetupAuditTrail change, Decimal riskScore) {
        Compliance_Event__e event = new Compliance_Event__e(
            Action__c = change.Action,
            User__c = change.CreatedBy,
            Timestamp__c = change.CreatedDate,
            Risk_Score__c = riskScore,
            Entity_Type__c = extractEntityType(change.Action),
            Entity_Id__c = extractEntityId(change.Action),
            Framework_Impact__c = calculateFrameworkImpact(change, riskScore)
        );
        EventBus.publish(event);
    }

    /**
     * Correlate multiple events to detect complex attack patterns
     */
    public static void correlateEvents(List<Compliance_Event__e> events) {
        // Detect: Permission escalation + Data export + Login from new location
        // Pattern: User gets Modify All Data → Exports Account data → Logs in from new IP
        Map<String, List<Compliance_Event__e>> userEvents = groupByUser(events);

        for (String userId : userEvents.keySet()) {
            List<Compliance_Event__e> userEventList = userEvents.get(userId);
            if (detectEscalationPattern(userEventList)) {
                publishCriticalAlert(userId, userEventList);
            }
        }
    }
}
```

#### 1.2 Event Monitoring Integration

**Shield Event Monitoring API Wrapper:**

```apex
public class PrometheionEventMonitoringService {
    private static final String EVENT_MONITORING_API = '/services/data/v62.0/eventMonitoring/';

    /**
     * Query Event Monitoring logs via REST API
     * Requires: Shield Event Monitoring license
     */
    @AuraEnabled(cacheable=false)
    public static List<EventMonitoringLog> queryEventLogs(
        String eventType,
        Datetime startTime,
        Datetime endTime
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:EventMonitoring/v1/query?q=' +
            EncodingUtil.urlEncode(
                'SELECT Id, EventType, LogFile, LogDate FROM EventLogFile ' +
                'WHERE EventType = \'' + eventType + '\' ' +
                'AND LogDate >= ' + startTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' ' +
                'AND LogDate <= ' + endTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),
                'UTF-8'
            )
        );
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return parseEventLogFiles((List<Object>) JSON.deserializeUntyped(res.getBody()));
        }
        throw new EventMonitoringException('Failed to query Event Monitoring: ' + res.getBody());
    }

    /**
     * Analyze Event Monitoring logs for compliance violations
     */
    public static ComplianceViolation analyzeLogFile(String logFileId) {
        // Download CSV log file, parse, and analyze
        // Detect: Unauthorized data access, suspicious API usage, bulk exports
        return null;
    }
}
```

**Supported Event Types:**

- `ApiEvent` - API call patterns
- `LoginEvent` - Authentication anomalies
- `ReportEvent` - Unusual report executions
- `DataExportEvent` - Bulk data exports
- `UriEvent` - Page view patterns

#### 1.3 AI-Powered Anomaly Detection

**Integrate with Claude for Pattern Recognition:**

```apex
public class PrometheionAnomalyDetector {
    /**
     * Use Claude to identify anomalous event patterns
     */
    public static AnomalyResult detectAnomalies(List<Compliance_Event__e> events) {
        // Serialize events to JSON
        String eventsJson = JSON.serializePretty(events);

        // Build prompt for Claude
        String prompt = 'Analyze these Salesforce compliance events and identify anomalies:\n\n' +
            eventsJson + '\n\n' +
            'Look for:\n' +
            '1. Unusual permission escalations\n' +
            '2. Suspicious data access patterns\n' +
            '3. Off-hours configuration changes\n' +
            '4. Rapid-fire permission assignments\n' +
            '5. Cross-framework violations (e.g., HIPAA + SOC2)\n\n' +
            'Return JSON: { "anomalies": [...], "riskScore": 0-100, "recommendation": "..." }';

        // Call Claude
        PrometheionClaudeService.ClaudeResponse response =
            PrometheionClaudeService.askCompliance(prompt, getOrgContext());

        return parseAnomalyResponse(response.content);
    }
}
```

#### 1.4 Real-Time Subscriber

**Platform Event Trigger:**

```apex
trigger ComplianceEventTrigger on Compliance_Event__e (after insert) {
    // Process events in real-time
    PrometheionEventProcessor.processEvents(Trigger.new);
}
```

**Event Processor:**

```apex
public class PrometheionEventProcessor {
    public static void processEvents(List<Compliance_Event__e> events) {
        // 1. Immediate risk scoring
        for (Compliance_Event__e event : events) {
            Decimal riskScore = calculateRiskScore(event);
            event.Risk_Score__c = riskScore;

            // 2. Critical threshold check
            if (riskScore >= 80) {
                sendImmediateAlert(event);
            }
        }

        // 3. Batch correlation analysis
        if (events.size() >= 5) {
            PrometheionEventPublisher.correlateEvents(events);
        }

        // 4. Update compliance graph
        PrometheionGraphIndexer.indexEvents(events);
    }
}
```

### Data Model Requirements

**Custom Objects Needed:**

1. **Compliance_Event\_\_e** (Platform Event)
   - `Action__c` (Text)
   - `User__c` (Lookup to User)
   - `Timestamp__c` (DateTime)
   - `Risk_Score__c` (Number)
   - `Entity_Type__c` (Text)
   - `Entity_Id__c` (Text)
   - `Framework_Impact__c` (Text, multi-select: HIPAA, SOC2, etc.)

2. **Event_Correlation\_\_c** (Custom Object)
   - `User__c` (Lookup)
   - `Event_Sequence__c` (Long Text Area - JSON)
   - `Pattern_Type__c` (Picklist: Escalation, Data_Exfiltration, etc.)
   - `Correlation_Score__c` (Number)
   - `Detected_At__c` (DateTime)

### Integration Points

- **Setup Audit Trail**: Query via SOQL (existing)
- **Event Monitoring**: REST API calls (new)
- **Platform Events**: Custom events + subscribers (new)
- **Claude AI**: Anomaly detection prompts (new)

### Performance Considerations

- **Async Processing**: Use `@future` or Queueable for heavy correlation analysis
- **Batching**: Process events in batches of 100-200
- **Caching**: Cache risk scoring rules in Platform Cache
- **Governor Limits**: Event Monitoring API has rate limits (100 calls/hour)

### Estimated Effort

- **Platform Events Setup**: 16 hours
- **Event Monitoring Integration**: 24 hours
- **Anomaly Detection (Claude)**: 16 hours
- **Event Correlation Logic**: 24 hours
- **Testing & Documentation**: 16 hours
- **Total**: ~96 hours (12 days)

---

## 2. Configuration Drift Guard (CRITICAL GAP)

### Business Plan Requirement

> "Configuration Drift Guard: Tracks every configuration change, compares against approved baselines, and flags unauthorized modifications."

### Current State Analysis

**What Exists:**

- `PrometheionComplianceScorer.calculateConfigDriftScore()` (lines 254-298)
- Basic `SetupAuditTrail` querying
- Simple keyword matching for "high-risk" changes

**What's Missing:**

1. **Baseline snapshots** - No mechanism to store approved configurations
2. **Change approval workflow** - No integration with change management
3. **Drift detection** - No comparison against baselines
4. **Auto-remediation** - No rollback capabilities
5. **Change request tracking** - No link to tickets/approvals

### Technical Implementation Strategy

#### 2.1 Baseline Snapshot System

**Baseline Storage:**

```apex
public class PrometheionBaselineManager {
    /**
     * Create a compliance baseline snapshot
     */
    @AuraEnabled
    public static String createBaseline(String baselineName, String description) {
        Compliance_Baseline__c baseline = new Compliance_Baseline__c(
            Name = baselineName,
            Description__c = description,
            Snapshot_Date__c = Datetime.now(),
            Status__c = 'Active'
        );
        insert baseline;

        // Snapshot current configuration
        snapshotPermissions(baseline.Id);
        snapshotSharingRules(baseline.Id);
        snapshotOWDSettings(baseline.Id);
        snapshotCustomMetadata(baseline.Id);

        return baseline.Id;
    }

    /**
     * Snapshot all permission sets and profiles
     */
    private static void snapshotPermissions(Id baselineId) {
        List<Permission_Set_Snapshot__c> snapshots = new List<Permission_Set_Snapshot__c>();

        // Query all permission sets
        for (PermissionSet ps : [
            SELECT Id, Name, PermissionsModifyAllData, PermissionsViewAllData,
                   (SELECT SobjectType, PermissionsRead, PermissionsCreate,
                           PermissionsEdit, PermissionsDelete
                    FROM ObjectPerms),
                   (SELECT Field, PermissionsRead, PermissionsEdit
                    FROM FieldPerms)
            FROM PermissionSet
            WHERE IsCustom = true
        ]) {
            Permission_Set_Snapshot__c snapshot = new Permission_Set_Snapshot__c(
                Baseline__c = baselineId,
                Permission_Set_Id__c = ps.Id,
                Permission_Set_Name__c = ps.Name,
                Modify_All_Data__c = ps.PermissionsModifyAllData,
                View_All_Data__c = ps.PermissionsViewAllData,
                Object_Permissions_JSON__c = JSON.serialize(ps.ObjectPerms),
                Field_Permissions_JSON__c = JSON.serialize(ps.FieldPerms)
            );
            snapshots.add(snapshot);
        }

        insert snapshots;
    }
}
```

#### 2.2 Drift Detection Engine

**Compare Current State vs Baseline:**

```apex
public class PrometheionDriftDetector {
    /**
     * Detect configuration drift against active baseline
     */
    @AuraEnabled
    public static List<DriftFinding> detectDrift(Id baselineId) {
        Compliance_Baseline__c baseline = [
            SELECT Id, Snapshot_Date__c
            FROM Compliance_Baseline__c
            WHERE Id = :baselineId
        ];

        List<DriftFinding> findings = new List<DriftFinding>();

        // Compare permission sets
        findings.addAll(comparePermissionSets(baselineId));

        // Compare sharing rules
        findings.addAll(compareSharingRules(baselineId));

        // Compare OWD settings
        findings.addAll(compareOWDSettings(baselineId));

        return findings;
    }

    /**
     * Compare current permission sets against baseline
     */
    private static List<DriftFinding> comparePermissionSets(Id baselineId) {
        List<DriftFinding> findings = new List<DriftFinding>();

        // Get baseline snapshots
        Map<Id, Permission_Set_Snapshot__c> baselineSnapshots = new Map<Id, Permission_Set_Snapshot__c>();
        for (Permission_Set_Snapshot__c snap : [
            SELECT Permission_Set_Id__c, Modify_All_Data__c,
                   Object_Permissions_JSON__c, Field_Permissions_JSON__c
            FROM Permission_Set_Snapshot__c
            WHERE Baseline__c = :baselineId
        ]) {
            baselineSnapshots.put(snap.Permission_Set_Id__c, snap);
        }

        // Get current permission sets
        Map<Id, PermissionSet> currentPS = new Map<Id, PermissionSet>([
            SELECT Id, PermissionsModifyAllData, PermissionsViewAllData,
                   (SELECT SobjectType, PermissionsRead, PermissionsCreate,
                           PermissionsEdit, PermissionsDelete
                    FROM ObjectPerms),
                   (SELECT Field, PermissionsRead, PermissionsEdit
                    FROM FieldPerms)
            FROM PermissionSet
            WHERE IsCustom = true
        ]);

        // Compare
        for (Id psId : currentPS.keySet()) {
            PermissionSet current = currentPS.get(psId);
            Permission_Set_Snapshot__c baseline = baselineSnapshots.get(psId);

            if (baseline == null) {
                // New permission set added
                findings.add(new DriftFinding(
                    type = 'PERMISSION_SET_ADDED',
                    entityId = psId,
                    severity = 'MEDIUM',
                    message = 'New permission set "' + current.Name + '" added without baseline approval'
                ));
            } else {
                // Check for changes
                if (current.PermissionsModifyAllData != baseline.Modify_All_Data__c) {
                    findings.add(new DriftFinding(
                        type = 'PERMISSION_ESCALATION',
                        entityId = psId,
                        severity = 'CRITICAL',
                        message = 'Permission set "' + current.Name + '" now has Modify All Data (was ' +
                                 baseline.Modify_All_Data__c + ')'
                    ));
                }

                // Compare object permissions (simplified - full comparison would be more complex)
                Map<String, Object> baselineObjPerms = (Map<String, Object>)
                    JSON.deserializeUntyped(baseline.Object_Permissions_JSON__c);
                // ... detailed comparison logic ...
            }
        }

        return findings;
    }
}
```

#### 2.3 Change Approval Integration

**Jira/ServiceNow Integration:**

```apex
public class PrometheionChangeApprovalService {
    /**
     * Check if a configuration change has an approved change request
     */
    public static Boolean isChangeApproved(String changeTicketId, String entityType, String entityId) {
        // Query custom object that links SetupAuditTrail entries to change tickets
        List<Change_Request__c> changeRequests = [
            SELECT Id, Ticket_ID__c, Status__c, Approved_By__c, Approved_Date__c
            FROM Change_Request__c
            WHERE Ticket_ID__c = :changeTicketId
            AND Entity_Type__c = :entityType
            AND Entity_Id__c = :entityId
            AND Status__c = 'Approved'
            LIMIT 1
        ];

        return !changeRequests.isEmpty();
    }

    /**
     * Create change request via Jira API
     */
    @future(callout=true)
    public static void createChangeRequest(String entityType, String entityId, String changeDescription) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Jira_API/rest/api/3/issue');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> issue = new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'project' => new Map<String, String>{ 'key' => 'COMP' },
                'summary' => 'Configuration Change: ' + entityType + ' - ' + entityId,
                'description' => changeDescription,
                'issuetype' => new Map<String, String>{ 'name' => 'Change Request' }
            }
        };

        req.setBody(JSON.serialize(issue));
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 201) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String ticketKey = (String) response.get('key');

            // Store in Salesforce
            Change_Request__c cr = new Change_Request__c(
                Ticket_ID__c = ticketKey,
                Entity_Type__c = entityType,
                Entity_Id__c = entityId,
                Status__c = 'Pending'
            );
            insert cr;
        }
    }
}
```

#### 2.4 Auto-Remediation (Rollback)

**Rollback Engine:**

```apex
public class PrometheionRollbackEngine {
    /**
     * Rollback a configuration change to baseline state
     */
    @AuraEnabled
    public static RollbackResult rollbackToBaseline(Id driftFindingId) {
        Drift_Finding__c finding = [
            SELECT Id, Entity_Type__c, Entity_Id__c, Baseline__c
            FROM Drift_Finding__c
            WHERE Id = :driftFindingId
        ];

        // Get baseline snapshot
        Permission_Set_Snapshot__c baseline = [
            SELECT Modify_All_Data__c, View_All_Data__c,
                   Object_Permissions_JSON__c, Field_Permissions_JSON__c
            FROM Permission_Set_Snapshot__c
            WHERE Baseline__c = :finding.Baseline__c
            AND Permission_Set_Id__c = :finding.Entity_Id__c
            LIMIT 1
        ];

        // Restore permission set
        PermissionSet ps = [
            SELECT Id FROM PermissionSet
            WHERE Id = :finding.Entity_Id__c
        ];

        // Use Metadata API to update permission set
        // Note: This requires Metadata API callout or Tooling API

        return new RollbackResult(
            success = true,
            message = 'Permission set rolled back to baseline state'
        );
    }
}
```

### Data Model Requirements

1. **Compliance_Baseline\_\_c** (Custom Object)
   - `Name` (Text)
   - `Description__c` (Long Text Area)
   - `Snapshot_Date__c` (DateTime)
   - `Status__c` (Picklist: Active, Archived)
   - `Created_By__c` (Lookup to User)

2. **Permission_Set_Snapshot\_\_c** (Custom Object)
   - `Baseline__c` (Lookup to Compliance_Baseline\_\_c)
   - `Permission_Set_Id__c` (Text)
   - `Permission_Set_Name__c` (Text)
   - `Modify_All_Data__c` (Checkbox)
   - `View_All_Data__c` (Checkbox)
   - `Object_Permissions_JSON__c` (Long Text Area)
   - `Field_Permissions_JSON__c` (Long Text Area)

3. **Drift_Finding\_\_c** (Custom Object)
   - `Baseline__c` (Lookup)
   - `Entity_Type__c` (Picklist)
   - `Entity_Id__c` (Text)
   - `Severity__c` (Picklist: CRITICAL, HIGH, MEDIUM, LOW)
   - `Change_Description__c` (Long Text Area)
   - `Detected_At__c` (DateTime)
   - `Change_Request__c` (Lookup to Change_Request\_\_c)

4. **Change_Request\_\_c** (Custom Object)
   - `Ticket_ID__c` (Text) - Jira/ServiceNow ticket
   - `Entity_Type__c` (Picklist)
   - `Entity_Id__c` (Text)
   - `Status__c` (Picklist: Pending, Approved, Rejected)
   - `Approved_By__c` (Lookup to User)
   - `Approved_Date__c` (DateTime)

### Integration Points

- **Setup Audit Trail**: SOQL queries (existing)
- **Metadata API**: For rollback operations (new)
- **Jira/ServiceNow**: REST API for change requests (new)
- **Platform Events**: Publish drift findings (new)

### Estimated Effort

- **Baseline Snapshot System**: 32 hours
- **Drift Detection Engine**: 40 hours
- **Change Approval Integration**: 24 hours
- **Rollback Engine**: 32 hours
- **Testing & Documentation**: 24 hours
- **Total**: ~152 hours (19 days)

---

## 3. Evidence Engine (CRITICAL GAP)

### Business Plan Requirement

> "Evidence Engine: Automatically collects, organizes, and exports audit evidence required by external auditors (SOC2, HIPAA, ISO 27001)."

### Current State Analysis

**What Exists:**

- `PrometheionComplianceScorer` calculates scores
- Basic risk identification in `getTopRisks()` (lines 380-418)

**What's Missing:**

1. **Evidence collection** - No automated gathering of audit artifacts
2. **Evidence organization** - No structured storage by framework/control
3. **Evidence export** - No PDF/Excel export functionality
4. **Evidence linking** - No connection between findings and evidence
5. **Audit trail export** - No automated Setup Audit Trail exports

### Technical Implementation Strategy

#### 3.1 Evidence Collection Service

**Automated Evidence Gathering:**

```apex
public class PrometheionEvidenceCollector {
    /**
     * Collect all evidence for a specific compliance framework
     */
    @AuraEnabled
    public static EvidenceCollection collectEvidence(String framework, Date startDate, Date endDate) {
        EvidenceCollection collection = new EvidenceCollection();
        collection.framework = framework;
        collection.startDate = startDate;
        collection.endDate = endDate;
        collection.collectedAt = Datetime.now();

        // Collect different evidence types
        collection.setupAuditTrail = collectSetupAuditTrail(startDate, endDate);
        collection.fieldHistoryTracking = collectFieldHistory(startDate, endDate);
        collection.permissionAssignments = collectPermissionAssignments();
        collection.sharingRuleEvidence = collectSharingRules();
        collection.encryptionEvidence = collectEncryptionStatus();
        collection.accessReviewEvidence = collectAccessReviews(startDate, endDate);

        return collection;
    }

    /**
     * Collect Setup Audit Trail entries
     */
    private static List<SetupAuditTrailEvidence> collectSetupAuditTrail(Date startDate, Date endDate) {
        List<SetupAuditTrailEvidence> evidence = new List<SetupAuditTrailEvidence>();

        for (SetupAuditTrail trail : [
            SELECT Action, CreatedBy.Name, CreatedDate, Display, Section, DelegateUser
            FROM SetupAuditTrail
            WHERE CreatedDate >= :startDate
            AND CreatedDate <= :endDate
            ORDER BY CreatedDate DESC
            LIMIT 10000
        ]) {
            evidence.add(new SetupAuditTrailEvidence(
                action = trail.Action,
                user = trail.CreatedBy.Name,
                timestamp = trail.CreatedDate,
                details = trail.Display
            ));
        }

        return evidence;
    }

    /**
     * Collect Field History Tracking evidence
     */
    private static List<FieldHistoryEvidence> collectFieldHistory(Date startDate, Date endDate) {
        List<FieldHistoryEvidence> evidence = new List<FieldHistoryEvidence>();

        // Query FieldHistoryTrackedField to see what's being tracked
        List<FieldDefinition> trackedFields = [
            SELECT QualifiedApiName, EntityDefinition.QualifiedApiName
            FROM FieldDefinition
            WHERE IsFieldHistoryTracked = true
            AND EntityDefinition.QualifiedApiName IN ('Account', 'Contact', 'Opportunity', 'Case')
            LIMIT 100
        ];

        for (FieldDefinition field : trackedFields) {
            evidence.add(new FieldHistoryEvidence(
                objectName = field.EntityDefinition.QualifiedApiName,
                fieldName = field.QualifiedApiName,
                isTracked = true
            ));
        }

        return evidence;
    }

    /**
     * Collect permission assignment evidence
     */
    private static PermissionAssignmentEvidence collectPermissionAssignments() {
        PermissionAssignmentEvidence evidence = new PermissionAssignmentEvidence();

        // Count users with elevated permissions
        evidence.usersWithModifyAll = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE PermissionSet.PermissionsModifyAllData = true
            AND Assignee.IsActive = true
        ];

        evidence.usersWithViewAll = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE PermissionSet.PermissionsViewAllData = true
            AND Assignee.IsActive = true
        ];

        // List all permission sets
        evidence.permissionSets = [
            SELECT Id, Name, Label, Description
            FROM PermissionSet
            WHERE IsCustom = true
            ORDER BY Name
        ];

        return evidence;
    }
}
```

#### 3.2 Evidence Organization by Framework/Control

**Framework-Specific Evidence Mapping:**

```apex
public class PrometheionEvidenceMapper {
    /**
     * Map evidence to specific compliance controls
     */
    public static Map<String, List<EvidenceItem>> mapEvidenceToControls(
        String framework,
        EvidenceCollection collection
    ) {
        Map<String, List<EvidenceItem>> controlEvidence = new Map<String, List<EvidenceItem>>();

        if (framework == 'SOC2') {
            // SOC2 CC6.1 - Logical Access Security
            controlEvidence.put('CC6.1', new List<EvidenceItem>{
                new EvidenceItem(
                    type = 'Permission_Assignment',
                    description = 'Permission set assignments for all users',
                    data = collection.permissionAssignments
                ),
                new EvidenceItem(
                    type = 'Access_Review',
                    description = 'Quarterly access reviews',
                    data = collection.accessReviewEvidence
                )
            });

            // SOC2 CC6.2 - Access Removal
            controlEvidence.put('CC6.2', new List<EvidenceItem>{
                new EvidenceItem(
                    type = 'User_Deactivation',
                    description = 'Deactivated user accounts',
                    data = collectDeactivatedUsers(collection.startDate, collection.endDate)
                )
            });
        } else if (framework == 'HIPAA') {
            // HIPAA §164.308(a)(1) - Security Management Process
            controlEvidence.put('164.308(a)(1)', new List<EvidenceItem>{
                new EvidenceItem(
                    type = 'Risk_Assessment',
                    description = 'Compliance risk assessment',
                    data = PrometheionComplianceScorer.calculateReadinessScore()
                )
            });

            // HIPAA §164.312(a)(1) - Access Control
            controlEvidence.put('164.312(a)(1)', new List<EvidenceItem>{
                new EvidenceItem(
                    type = 'Permission_Assignment',
                    description = 'User access controls',
                    data = collection.permissionAssignments
                )
            });
        }

        return controlEvidence;
    }
}
```

#### 3.3 Evidence Export (PDF/Excel)

**PDF Report Generation:**

```apex
public class PrometheionEvidenceExporter {
    /**
     * Generate PDF audit report
     */
    @AuraEnabled
    public static String generatePDFReport(String framework, Date startDate, Date endDate) {
        // Collect evidence
        EvidenceCollection collection = PrometheionEvidenceCollector.collectEvidence(
            framework, startDate, endDate
        );

        // Map to controls
        Map<String, List<EvidenceItem>> controlEvidence =
            PrometheionEvidenceMapper.mapEvidenceToControls(framework, collection);

        // Generate PDF using Visualforce or external service
        PageReference pdfPage = Page.PrometheionAuditReport;
        pdfPage.getParameters().put('framework', framework);
        pdfPage.getParameters().put('startDate', String.valueOf(startDate));
        pdfPage.getParameters().put('endDate', String.valueOf(endDate));

        Blob pdfBlob = pdfPage.getContentAsPDF();

        // Save as ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = framework + ' Audit Report - ' + Date.today().format(),
            PathOnClient = framework + '_Audit_Report.pdf',
            VersionData = pdfBlob,
            FirstPublishLocationId = UserInfo.getUserId()
        );
        insert cv;

        return cv.Id;
    }

    /**
     * Generate Excel evidence export
     */
    @AuraEnabled
    public static String generateExcelExport(String framework, Date startDate, Date endDate) {
        EvidenceCollection collection = PrometheionEvidenceCollector.collectEvidence(
            framework, startDate, endDate
        );

        // Create Excel using simple CSV format or external library
        String csvContent = 'Framework,Control,Evidence Type,Description,Timestamp\n';

        Map<String, List<EvidenceItem>> controlEvidence =
            PrometheionEvidenceMapper.mapEvidenceToControls(framework, collection);

        for (String control : controlEvidence.keySet()) {
            for (EvidenceItem item : controlEvidence.get(control)) {
                csvContent += framework + ',' + control + ',' + item.type + ',' +
                             item.description + ',' + item.timestamp + '\n';
            }
        }

        // Save as ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = framework + ' Evidence Export - ' + Date.today().format(),
            PathOnClient = framework + '_Evidence.csv',
            VersionData = Blob.valueOf(csvContent),
            FirstPublishLocationId = UserInfo.getUserId()
        );
        insert cv;

        return cv.Id;
    }
}
```

**Visualforce PDF Template:**

```xml
<!-- force-app/main/default/pages/PrometheionAuditReport.page -->
<apex:page controller="PrometheionAuditReportController" renderAs="pdf">
    <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; }
                .header { background-color: #16325c; color: white; padding: 20px; }
                .section { margin: 20px 0; }
                table { width: 100%; border-collapse: collapse; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Prometheion Compliance Audit Report</h1>
                <p>Framework: {!framework}</p>
                <p>Period: {!startDate} to {!endDate}</p>
            </div>

            <apex:repeat value="{!controlEvidence}" var="control">
                <div class="section">
                    <h2>Control: {!control}</h2>
                    <table>
                        <tr>
                            <th>Evidence Type</th>
                            <th>Description</th>
                            <th>Timestamp</th>
                        </tr>
                        <apex:repeat value="{!control.evidenceItems}" var="item">
                            <tr>
                                <td>{!item.type}</td>
                                <td>{!item.description}</td>
                                <td>{!item.timestamp}</td>
                            </tr>
                        </apex:repeat>
                    </table>
                </div>
            </apex:repeat>
        </body>
    </html>
</apex:page>
```

#### 3.4 Evidence Linking to Findings

**Link Evidence to Compliance Findings:**

```apex
public class PrometheionEvidenceLinker {
    /**
     * Link evidence to a specific compliance finding
     */
    public static void linkEvidenceToFinding(Id findingId, List<Id> evidenceIds) {
        List<Finding_Evidence__c> links = new List<Finding_Evidence__c>();

        for (Id evidenceId : evidenceIds) {
            links.add(new Finding_Evidence__c(
                Finding__c = findingId,
                Evidence__c = evidenceId,
                Linked_At__c = Datetime.now()
            ));
        }

        insert links;
    }

    /**
     * Auto-link evidence based on framework and control
     */
    public static void autoLinkEvidence(String framework, String control) {
        // Find all findings for this control
        List<Compliance_Finding__c> findings = [
            SELECT Id FROM Compliance_Finding__c
            WHERE Framework__c = :framework
            AND Control__c = :control
        ];

        // Find relevant evidence
        List<Evidence__c> evidence = [
            SELECT Id FROM Evidence__c
            WHERE Framework__c = :framework
            AND Control__c = :control
        ];

        // Create links
        for (Compliance_Finding__c finding : findings) {
            for (Evidence__c ev : evidence) {
                linkEvidenceToFinding(finding.Id, new List<Id>{ ev.Id });
            }
        }
    }
}
```

### Data Model Requirements

1. **Evidence\_\_c** (Custom Object)
   - `Framework__c` (Picklist)
   - `Control__c` (Text) - e.g., "SOC2 CC6.1"
   - `Evidence_Type__c` (Picklist: Setup_Audit_Trail, Field_History, Permission_Assignment, etc.)
   - `Description__c` (Long Text Area)
   - `Data_JSON__c` (Long Text Area) - Serialized evidence data
   - `Collected_At__c` (DateTime)
   - `Content_Version__c` (Lookup to ContentVersion) - For PDF/Excel exports

2. **Finding_Evidence\_\_c** (Junction Object)
   - `Finding__c` (Lookup to Compliance_Finding\_\_c)
   - `Evidence__c` (Lookup to Evidence\_\_c)
   - `Linked_At__c` (DateTime)

3. **Compliance_Finding\_\_c** (Custom Object)
   - `Framework__c` (Picklist)
   - `Control__c` (Text)
   - `Severity__c` (Picklist)
   - `Description__c` (Long Text Area)
   - `Remediation__c` (Long Text Area)

### Integration Points

- **Setup Audit Trail**: SOQL queries (existing)
- **Field History**: SOQL queries (new)
- **ContentVersion**: For PDF/Excel storage (new)
- **Visualforce**: For PDF generation (new)

### Estimated Effort

- **Evidence Collection Service**: 32 hours
- **Evidence Organization/Mapping**: 24 hours
- **PDF/Excel Export**: 32 hours
- **Evidence Linking**: 16 hours
- **Testing & Documentation**: 16 hours
- **Total**: ~120 hours (15 days)

---

## 4. Off-Platform Compute Architecture (THE GOLDEN SPIKE) 🔧

### Strategic Importance

**⚠️ CRITICAL: This is the foundational architecture that unblocks ALL other features.**

The business plan identifies "Gross Margin Risk" from Salesforce governor limits. Building features 1, 2, or 3 in Apex first would require a complete rewrite when limits are hit. **Section 4 must be implemented FIRST** to establish the "Hub-and-Spoke" architecture that all future features will build upon.

**Achievability Assessment: 4/10 (Dangerous Execution Plan)**

- Without off-platform compute: Features 1-3 will hit governor limits and require rewrite
- With off-platform compute: Features 1-3 can be built on AWS from day one

### Business Plan Requirement

> "Off-Platform Compute: Heavy AI analysis runs on external infrastructure to avoid Salesforce governor limits and reduce costs. This architecture enables the Agentforce Control Plane and protects the 70% Gross Margin target."

### Current State Analysis

**What Exists:**

- `PrometheionClaudeService` calls Claude API directly from Apex (synchronous, burns CPU time)
- `ApiUsageSnapshot.cls` polls Salesforce REST API (consumes API calls)
- `PrometheionGraphIndexer.cls` is a stub (no heavy processing yet, but would be built in Apex)
- All processing happens synchronously in Salesforce transactions
- Risk of hitting governor limits on large orgs (10,000+ users, 100+ permission sets)

**What's Missing:**

1. **Push-based event architecture** - Currently polling-based (ApiUsageSnapshot)
2. **Change Data Capture (CDC) integration** - No CDC subscription
3. **Event Relay to AWS** - No connection to external compute
4. **Asynchronous processing** - All processing blocks user transactions
5. **Cost optimization** - All API calls from Salesforce (higher cost, governor limits)

### Architecture Overview: The "Glass Box" Bridge

**Architecture Diagram:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    SALESFORCE ORG (SPOKE)                        │
│                                                                   │
│  ┌──────────────┐         ┌──────────────┐                      │
│  │ SObject      │         │ Setup Audit  │                      │
│  │ Changes      │         │ Trail        │                      │
│  └──────┬───────┘         └──────┬───────┘                      │
│         │                        │                               │
│         │ CDC / Triggers         │ SOQL Query                    │
│         ▼                        ▼                               │
│  ┌──────────────────────────────────────────┐                   │
│  │     Prometheion_Raw_Event__e             │                   │
│  │     (Platform Event - Lightweight)      │                   │
│  └──────────────┬───────────────────────────┘                   │
│                 │                                                │
│                 │ EventBus.publish()                             │
│                 ▼                                                │
│  ┌──────────────────────────────────────────┐                   │
│  │     Salesforce Event Relay               │                   │
│  │     (Zero Apex Code - Native Feature)   │                   │
│  └──────────────┬───────────────────────────┘                   │
└─────────────────┼───────────────────────────────────────────────┘
                  │
                  │ HTTPS (EventBridge API)
                  │
┌─────────────────┼───────────────────────────────────────────────┐
│                 ▼                                                 │
│  ┌──────────────────────────────────────────┐                    │
│  │     Amazon EventBridge                  │                    │
│  │     (Event Router)                      │                    │
│  └──────────────┬───────────────────────────┘                    │
│                 │                                                 │
│                 │ Batch Events (5 min windows)                    │
│                 ▼                                                 │
│  ┌──────────────────────────────────────────┐                    │
│  │     Amazon Kinesis Firehose              │                    │
│  │     (Streaming Data Ingestion)          │                    │
│  └──────────────┬───────────────────────────┘                    │
│                 │                                                 │
│                 │ Write Batches                                  │
│                 ▼                                                 │
│  ┌──────────────────────────────────────────┐                    │
│  │     Amazon S3 Data Lake                  │                    │
│  │     s3://prometheion-events/             │                    │
│  │     - Raw events (immutable)             │                    │
│  │     - Partitioned by date/org           │                    │
│  └──────────────┬───────────────────────────┘                    │
│                 │                                                 │
│                 │ S3 Event Notification                          │
│                 ▼                                                 │
│  ┌──────────────────────────────────────────┐                    │
│  │     AWS Lambda: Event Processor          │                    │
│  │     - Parse events                       │                    │
│  │     - Deduplicate                       │                    │
│  │     - Route to analyzers                 │                    │
│  └──────────────┬───────────────────────────┘                    │
│                 │                                                 │
│                 │ Trigger Analysis                               │
│                 ▼                                                 │
│  ┌──────────────────────────────────────────┐                    │
│  │     AWS Lambda: Compliance Scorer         │                    │
│  │     - Call Claude API                    │                    │
│  │     - Calculate risk scores              │                    │
│  │     - Detect anomalies                   │                    │
│  └──────────────┬───────────────────────────┘                    │
│                 │                                                 │
│                 │ Store Results                                  │
│                 ▼                                                 │
│  ┌──────────────────────────────────────────┐                    │
│  │     Amazon DynamoDB                      │                    │
│  │     - Fast state retrieval               │                    │
│  │     - Last Known Good Config             │                    │
│  │     - Risk scores (TTL: 7 days)          │                    │
│  └──────────────┬───────────────────────────┘                    │
│                 │                                                 │
│                 │ Callback                                       │
│                 ▼                                                 │
│  ┌──────────────────────────────────────────┐                    │
│  │     Salesforce REST API                  │                    │
│  │     POST /services/data/v62.0/           │                    │
│  │     sobjects/Compliance_Score__c/       │                    │
│  └──────────────┬───────────────────────────┘                    │
└─────────────────┼───────────────────────────────────────────────┘
                  │
                  │ OAuth 2.0 (JWT Bearer Token)
                  │
┌─────────────────┼───────────────────────────────────────────────┐
│                 ▼                                                 │
│  ┌──────────────────────────────────────────┐                   │
│  │     Salesforce REST Endpoint              │                   │
│  │     PrometheionScoreCallback              │                   │
│  └──────────────┬───────────────────────────┘                   │
│                 │                                                │
│                 │ Update Records                                │
│                 ▼                                                │
│  ┌──────────────────────────────────────────┐                   │
│  │     Compliance_Score__c                   │                   │
│  │     (Custom Object)                      │                   │
│  └──────────────┬───────────────────────────┘                   │
│                 │                                                │
│                 │ Platform Event                                │
│                 ▼                                                │
│  ┌──────────────────────────────────────────┐                   │
│  │     Prometheion_Score_Result__e         │                   │
│  │     (Platform Event)                     │                   │
│  └──────────────┬───────────────────────────┘                   │
│                 │                                                │
│                 │ Subscribe (LWC)                                │
│                 ▼                                                │
│  ┌──────────────────────────────────────────┐                   │
│  │     prometheionDashboard (LWC)           │                   │
│  │     - Show toast notification            │                   │
│  │     - Update score card                 │                   │
│  └──────────────────────────────────────────┘                   │
└──────────────────────────────────────────────────────────────────┘
```

### Technical Stack Selection

#### 4.1 Ingestion: Salesforce Event Relays (Preferred)

**Why Event Relays over Custom HTTP Callouts:**

| Feature                 | Event Relays                    | Custom HTTP Callout            |
| ----------------------- | ------------------------------- | ------------------------------ |
| **Apex Code Required**  | Zero                            | ~50 lines per event type       |
| **Retry Logic**         | Automatic (exponential backoff) | Manual implementation          |
| **Rate Limiting**       | Handled by Salesforce           | Must implement circuit breaker |
| **Monitoring**          | Native in Setup                 | Custom logging required        |
| **Change Data Capture** | Native integration              | Must poll SetupAuditTrail      |
| **Maintenance**         | Zero (Salesforce managed)       | Ongoing (code updates)         |

**Event Relay Configuration:**

- Setup → Integrations → Event Relays
- Create Event Relay: `Prometheion_AWS_Relay`
- Source: Platform Event `Prometheion_Raw_Event__e`
- Destination: Amazon EventBridge (ARN provided by AWS)

#### 4.2 Compute: AWS Lambda (Python 3.11)

**Why Python:**

- Required for AI/ML libraries (scikit-learn, pandas) for future "Agentforce" features
- Better ecosystem for data processing (vs Node.js)
- Native support for Anthropic SDK

**Lambda Configuration:**

- Runtime: Python 3.11
- Memory: 512 MB (sufficient for Claude API calls)
- Timeout: 5 minutes (300 seconds)
- Reserved Concurrency: 10 (prevent cost spikes)

#### 4.3 Storage: S3 + DynamoDB

**S3 (Data Lake):**

- Purpose: Immutable evidence retention (SOC2 requires 7-year retention)
- Partitioning: `s3://prometheion-events/org-id/YYYY/MM/DD/events.json`
- Lifecycle Policy: Move to Glacier after 90 days, delete after 7 years

**DynamoDB (Fast State):**

- Purpose: Real-time risk scores, last known good configuration
- Partition Key: `org-id`
- Sort Key: `entity-type#entity-id`
- TTL: 7 days (auto-delete old scores)

### Code Refactoring: From Heavy Apex to Lightweight Publisher

#### 4.4 Current State (Problematic Pattern)

**PrometheionGraphIndexer.cls (Current - Would Burn CPU):**

```apex
// ❌ PROBLEM: Heavy processing happens inside the transaction
public static String indexChange(String entityType, String entityId, String framework) {
    // This query burns SOQL limits
    Map<String, Object> metadata = queryEntityMetadata(entityType, entityId);

    // This calculation burns CPU time (could be 5-10 seconds for complex orgs)
    Decimal riskScore = calculateRiskScore(metadata, framework);

    // This insert burns DML limits
    Sentinel_Compliance_Graph__b node = new Sentinel_Compliance_Graph__b(
        Entity_Type__c = entityType,
        Entity_Id__c = entityId,
        Risk_Score__c = riskScore,
        Node_Metadata__c = JSON.serialize(metadata) // Could be 100KB+
    );
    insert node;

    return node.Id;
}
```

**Issues:**

- Blocks user transaction (synchronous)
- Burns CPU time (governor limit: 10,000ms)
- Burns SOQL queries (governor limit: 100)
- Burns DML statements (governor limit: 150)
- No retry logic if processing fails

#### 4.5 Future State (Solution Pattern)

**PrometheionEventPublisher.cls (New - Lightweight):**

```apex
/**
 * PrometheionEventPublisher - Lightweight Event Publisher
 *
 * This class publishes events to AWS via Event Relay.
 * All heavy processing (risk scoring, AI analysis) happens off-platform.
 *
 * @author Prometheion
 * @version 2.0
 */
public with sharing class PrometheionEventPublisher {

    private static final String LOG_PREFIX = '[PrometheionEventPublisher] ';

    /**
     * Publish a configuration change event
     * This is called from triggers or scheduled jobs
     */
    public static void publishConfigChange(
        String entityType,
        String entityId,
        String action,
        String changedBy
    ) {
        try {
            // Lightweight: Only serialize minimal metadata
            Map<String, Object> eventPayload = new Map<String, Object>{
                'entityType' => entityType,
                'entityId' => entityId,
                'action' => action,
                'changedBy' => changedBy,
                'timestamp' => Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),
                'orgId' => UserInfo.getOrganizationId() // Critical for multi-tenant
            };

            // Publish Platform Event (zero CPU cost, async)
            Prometheion_Raw_Event__e event = new Prometheion_Raw_Event__e(
                Payload__c = JSON.serialize(eventPayload),
                Entity_Type__c = entityType,
                Entity_Id__c = entityId,
                Action__c = action,
                Changed_By__c = changedBy,
                Timestamp__c = Datetime.now(),
                Org_ID__c = UserInfo.getOrganizationId()
            );

            Database.SaveResult result = EventBus.publish(event);

            if (!result.isSuccess()) {
                System.debug(LoggingLevel.ERROR, LOG_PREFIX +
                    'Failed to publish event: ' + result.getErrors());
            } else {
                System.debug(LoggingLevel.DEBUG, LOG_PREFIX +
                    'Published event for ' + entityType + ':' + entityId);
            }

        } catch (Exception e) {
            // Don't throw - event publishing failures should not break user transactions
            System.debug(LoggingLevel.ERROR, LOG_PREFIX +
                'Exception publishing event: ' + e.getMessage() +
                ' at line ' + e.getLineNumber());
        }
    }

    /**
     * Publish Setup Audit Trail change
     * Called from scheduled job that polls SetupAuditTrail
     */
    public static void publishAuditTrailChange(SetupAuditTrail trail) {
        publishConfigChange(
            'SetupAuditTrail',
            trail.Id,
            trail.Action,
            trail.CreatedBy.Name
        );
    }

    /**
     * Publish permission set assignment change
     * Called from trigger on PermissionSetAssignment
     */
    public static void publishPermissionChange(Id permissionSetId, Id userId) {
        publishConfigChange(
            'PermissionSetAssignment',
            permissionSetId,
            'ASSIGNED',
            UserInfo.getName()
        );
    }
}
```

**Benefits:**

- ✅ Zero CPU time (EventBus.publish is async)
- ✅ Zero SOQL queries (no metadata fetching)
- ✅ Zero DML statements (Platform Events are not DML)
- ✅ Automatic retry (Event Relay handles retries)
- ✅ Non-blocking (user transaction completes immediately)

#### 4.6 Trigger Integration

**PermissionSetAssignment Trigger:**

```apex
trigger PermissionSetAssignmentTrigger on PermissionSetAssignment (after insert, after delete) {
    if (Trigger.isAfter) {
        for (PermissionSetAssignment psa : Trigger.isInsert ? Trigger.new : Trigger.old) {
            PrometheionEventPublisher.publishPermissionChange(
                psa.PermissionSetId,
                psa.AssigneeId
            );
        }
    }
}
```

**SetupAuditTrail Poller (Scheduled Job):**

```apex
public class PrometheionAuditTrailPoller implements Schedulable {
    public void execute(SchedulableContext ctx) {
        // Query last 5 minutes of changes
        Datetime fiveMinutesAgo = Datetime.now().addMinutes(-5);

        List<SetupAuditTrail> recentChanges = [
            SELECT Id, Action, CreatedBy.Name, CreatedDate
            FROM SetupAuditTrail
            WHERE CreatedDate >= :fiveMinutesAgo
            ORDER BY CreatedDate DESC
            LIMIT 1000
        ];

        for (SetupAuditTrail trail : recentChanges) {
            PrometheionEventPublisher.publishAuditTrailChange(trail);
        }
    }
}
```

### AWS Lambda Implementation

#### 4.7 Event Processor Lambda

**lambda/event_processor.py:**

```python
import json
import boto3
import os
from datetime import datetime
from typing import Dict, List

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
events_table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def lambda_handler(event, context):
    """
    Process events from Kinesis Firehose
    Event structure from EventBridge:
    {
        "source": "salesforce.prometheion",
        "detail-type": "Prometheion Raw Event",
        "detail": {
            "Payload__c": "{...}",
            "Entity_Type__c": "PermissionSet",
            "Entity_Id__c": "0PS...",
            "Action__c": "MODIFIED",
            "Changed_By__c": "John Doe",
            "Timestamp__c": "2025-01-15T10:30:00Z",
            "Org_ID__c": "00D..."
        }
    }
    """
    processed_count = 0
    errors = []

    # EventBridge can send multiple events in one invocation
    for record in event.get('Records', []):
        try:
            # Parse EventBridge record
            event_detail = record['detail']
            payload = json.loads(event_detail['Payload__c'])

            # Deduplicate (check DynamoDB for recent event)
            event_key = f"{payload['orgId']}#{payload['entityType']}#{payload['entityId']}"
            if is_duplicate(event_key, payload['timestamp']):
                continue

            # Route to appropriate analyzer
            if payload['entityType'] == 'PermissionSet':
                route_to_permission_analyzer(payload)
            elif payload['entityType'] == 'SetupAuditTrail':
                route_to_audit_analyzer(payload)
            else:
                route_to_generic_analyzer(payload)

            # Store in DynamoDB for deduplication
            store_event(event_key, payload)
            processed_count += 1

        except Exception as e:
            errors.append({
                'record': record,
                'error': str(e)
            })
            print(f"Error processing record: {e}")

    return {
        'statusCode': 200,
        'body': json.dumps({
            'processed': processed_count,
            'errors': len(errors)
        })
    }

def is_duplicate(event_key: str, timestamp: str) -> bool:
    """Check if we've seen this event in the last 5 minutes"""
    try:
        response = events_table.get_item(
            Key={'EventKey': event_key}
        )
        if 'Item' in response:
            stored_timestamp = response['Item']['Timestamp']
            # Parse timestamps and compare
            stored_dt = datetime.fromisoformat(stored_timestamp.replace('Z', '+00:00'))
            event_dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            time_diff = (event_dt - stored_dt).total_seconds()
            return abs(time_diff) < 300  # 5 minutes
    except Exception as e:
        print(f"Error checking duplicate: {e}")
    return False

def route_to_permission_analyzer(payload: Dict):
    """Invoke permission analyzer Lambda asynchronously"""
    lambda_client = boto3.client('lambda')
    lambda_client.invoke(
        FunctionName=os.environ['PERMISSION_ANALYZER_FUNCTION'],
        InvocationType='Event',  # Async
        Payload=json.dumps(payload)
    )

def route_to_audit_analyzer(payload: Dict):
    """Invoke audit analyzer Lambda asynchronously"""
    lambda_client = boto3.client('lambda')
    lambda_client.invoke(
        FunctionName=os.environ['AUDIT_ANALYZER_FUNCTION'],
        InvocationType='Event',
        Payload=json.dumps(payload)
    )

def route_to_generic_analyzer(payload: Dict):
    """Route to generic compliance analyzer"""
    lambda_client = boto3.client('lambda')
    lambda_client.invoke(
        FunctionName=os.environ['GENERIC_ANALYZER_FUNCTION'],
        InvocationType='Event',
        Payload=json.dumps(payload)
    )

def store_event(event_key: str, payload: Dict):
    """Store event in DynamoDB for deduplication"""
    events_table.put_item(
        Item={
            'EventKey': event_key,
            'Timestamp': payload['timestamp'],
            'Payload': json.dumps(payload),
            'TTL': int(datetime.now().timestamp()) + 604800  # 7 days
        }
    )
```

#### 4.8 Compliance Scorer Lambda

**lambda/compliance_scorer.py:**

```python
import json
import os
import requests
import boto3
from typing import Dict

dynamodb = boto3.resource('dynamodb')
scores_table = dynamodb.Table(os.environ['SCORES_TABLE'])

def lambda_handler(event, context):
    """
    Analyze compliance event and calculate risk score
    Calls Claude API for AI-powered analysis
    """
    payload = json.loads(event['Payload']) if isinstance(event, str) else event

    entity_type = payload['entityType']
    entity_id = payload['entityId']
    org_id = payload['orgId']

    # Call Claude API for risk analysis
    claude_response = call_claude_risk_analysis(payload)

    # Extract risk score from Claude response
    risk_score = extract_risk_score(claude_response)
    framework_scores = extract_framework_scores(claude_response)

    # Store in DynamoDB
    store_score(org_id, entity_type, entity_id, risk_score, framework_scores)

    # Callback to Salesforce
    callback_salesforce(org_id, entity_type, entity_id, risk_score, framework_scores)

    return {
        'statusCode': 200,
        'body': json.dumps({
            'riskScore': risk_score,
            'frameworkScores': framework_scores
        })
    }

def call_claude_risk_analysis(payload: Dict) -> Dict:
    """Call Anthropic Claude API for risk analysis"""
    url = 'https://api.anthropic.com/v1/messages'
    headers = {
        'x-api-key': os.environ['ANTHROPIC_API_KEY'],
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json'
    }

    prompt = build_risk_analysis_prompt(payload)

    request_payload = {
        'model': 'claude-sonnet-4-20250514',  # Use Sonnet for speed
        'max_tokens': 4096,
        'messages': [{
            'role': 'user',
            'content': prompt
        }]
    }

    response = requests.post(url, headers=headers, json=request_payload, timeout=60)
    response.raise_for_status()
    return response.json()

def build_risk_analysis_prompt(payload: Dict) -> str:
    """Build prompt for Claude risk analysis"""
    return f"""Analyze this Salesforce configuration change for compliance risks:

Entity Type: {payload['entityType']}
Entity ID: {payload['entityId']}
Action: {payload['action']}
Changed By: {payload['changedBy']}
Timestamp: {payload['timestamp']}

Evaluate this change against:
- HIPAA (Security Rule 45 CFR 164)
- SOC 2 (Trust Services Criteria CC6)
- NIST 800-53 (Access Control AC-2)
- GDPR (Article 32 - Security of Processing)

Return JSON:
{{
    "riskScore": <0-100>,
    "frameworkScores": {{
        "HIPAA": <0-100>,
        "SOC2": <0-100>,
        "NIST": <0-100>,
        "GDPR": <0-100>
    }},
    "findings": [
        {{
            "severity": "CRITICAL|HIGH|MEDIUM|LOW",
            "title": "...",
            "description": "...",
            "framework": "HIPAA|SOC2|NIST|GDPR",
            "remediation": "..."
        }}
    ]
}}"""

def extract_risk_score(claude_response: Dict) -> float:
    """Extract risk score from Claude JSON response"""
    content = claude_response['content'][0]['text']
    parsed = json.loads(content)
    return float(parsed.get('riskScore', 50))

def extract_framework_scores(claude_response: Dict) -> Dict:
    """Extract framework scores from Claude response"""
    content = claude_response['content'][0]['text']
    parsed = json.loads(content)
    return parsed.get('frameworkScores', {})

def store_score(org_id: str, entity_type: str, entity_id: str,
                risk_score: float, framework_scores: Dict):
    """Store score in DynamoDB"""
    scores_table.put_item(
        Item={
            'PK': f"{org_id}#{entity_type}#{entity_id}",
            'SK': 'SCORE',
            'RiskScore': risk_score,
            'FrameworkScores': json.dumps(framework_scores),
            'Timestamp': datetime.utcnow().isoformat(),
            'TTL': int(datetime.now().timestamp()) + 604800  # 7 days
        }
    )

def callback_salesforce(org_id: str, entity_type: str, entity_id: str,
                       risk_score: float, framework_scores: Dict):
    """Send results back to Salesforce via REST API"""
    sf_url = os.environ['SALESFORCE_INSTANCE_URL']
    sf_token = get_salesforce_token(org_id)

    # Create or update Compliance_Score__c record
    rest_url = f"{sf_url}/services/data/v62.0/sobjects/Compliance_Score__c"
    headers = {
        'Authorization': f'Bearer {sf_token}',
        'Content-Type': 'application/json'
    }

    payload = {
        'Org_ID__c': org_id,
        'Entity_Type__c': entity_type,
        'Entity_Id__c': entity_id,
        'Risk_Score__c': risk_score,
        'Framework_Scores_JSON__c': json.dumps(framework_scores),
        'Calculated_At__c': datetime.utcnow().isoformat()
    }

    # Upsert by external ID
    upsert_url = f"{rest_url}/Org_ID__c/{org_id}/Entity_Type__c/{entity_type}/Entity_Id__c/{entity_id}"
    response = requests.patch(upsert_url, headers=headers, json=payload)
    response.raise_for_status()

    # Publish Platform Event to notify UI
    publish_score_event(org_id, entity_type, entity_id, risk_score)

def get_salesforce_token(org_id: str) -> str:
    """Get OAuth token for Salesforce org (JWT Bearer flow)"""
    # Implementation: Use stored credentials in AWS Secrets Manager
    secrets_client = boto3.client('secretsmanager')
    secret = secrets_client.get_secret_value(SecretId=f'prometheion/sf-oauth/{org_id}')
    credentials = json.loads(secret['SecretString'])

    # Exchange JWT for access token (standard OAuth 2.0 flow)
    # ... (implementation details)
    return credentials['access_token']

def publish_score_event(org_id: str, entity_type: str, entity_id: str, risk_score: float):
    """Publish Platform Event to notify LWC components"""
    # This would be done via Salesforce REST API
    # POST /services/data/v62.0/sobjects/Prometheion_Score_Result__e/
    pass
```

### The Callback Pattern: Async Results in LWC

#### 4.9 Platform Event for Results

**Prometheion_Score_Result\_\_e (Platform Event):**

```xml
<!-- force-app/main/default/objects/Prometheion_Score_Result__e/Prometheion_Score_Result__e.object-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Prometheion Score Result</label>
    <pluralLabel>Prometheion Score Results</pluralLabel>
    <description>Platform Event for compliance score results from AWS</description>
    <eventType>HighVolume</eventType>
    <fields>
        <fullName>Org_ID__c</fullName>
        <label>Org ID</label>
        <type>Text</type>
        <length>18</length>
    </fields>
    <fields>
        <fullName>Entity_Type__c</fullName>
        <label>Entity Type</label>
        <type>Text</type>
        <length>50</length>
    </fields>
    <fields>
        <fullName>Entity_Id__c</fullName>
        <label>Entity ID</label>
        <type>Text</type>
        <length>18</length>
    </fields>
    <fields>
        <fullName>Risk_Score__c</fullName>
        <label>Risk Score</label>
        <type>Number</type>
        <precision>5</precision>
        <scale>2</scale>
    </fields>
    <fields>
        <fullName>Framework_Scores_JSON__c</fullName>
        <label>Framework Scores JSON</label>
        <type>LongTextArea</type>
        <length>32000</length>
    </fields>
</CustomObject>
```

#### 4.10 LWC Event Listener

**prometheionScoreListener.js:**

```javascript
import { LightningElement, wire } from "lwc";
import { subscribe, unsubscribe, onError, setDebugFlag } from "lightning/empApi";

export default class PrometheionScoreListener extends LightningElement {
  subscription = {};
  isListening = false;

  connectedCallback() {
    this.registerErrorListener();
    this.subscribeToScoreEvents();
  }

  disconnectedCallback() {
    this.unsubscribeFromScoreEvents();
  }

  registerErrorListener() {
    onError((error) => {
      console.error("Subscription error: ", JSON.stringify(error));
    });
  }

  subscribeToScoreEvents() {
    const messageCallback = (response) => {
      console.log("Score result received: ", JSON.stringify(response));

      const eventPayload = response.data.payload;
      this.handleScoreResult(eventPayload);
    };

    subscribe("/event/Prometheion_Score_Result__e", -1, messageCallback).then((response) => {
      console.log("Subscription request sent: ", JSON.stringify(response));
      this.subscription = response;
      this.isListening = true;
    });
  }

  unsubscribeFromScoreEvents() {
    unsubscribe(this.subscription, (response) => {
      console.log("Unsubscribed: ", JSON.stringify(response));
      this.isListening = false;
    });
  }

  handleScoreResult(payload) {
    // Show toast notification
    this.dispatchEvent(
      new CustomEvent("scoreresult", {
        detail: {
          entityType: payload.Entity_Type__c,
          entityId: payload.Entity_Id__c,
          riskScore: payload.Risk_Score__c,
          frameworkScores: JSON.parse(payload.Framework_Scores_JSON__c),
        },
        bubbles: true,
        composed: true,
      })
    );
  }
}
```

**prometheionDashboard.js (Updated):**

```javascript
import { LightningElement, wire, track } from "lwc";
import getComplianceScore from "@salesforce/apex/PrometheionComplianceScorer.calculateReadinessScore";
import PrometheionScoreListener from "c/prometheionScoreListener";

export default class PrometheionDashboard extends LightningElement {
  @track score = null;
  @track loading = true;
  scoreListener;

  connectedCallback() {
    // Load initial score
    this.loadScore();

    // Subscribe to real-time score updates
    this.scoreListener = this.template.querySelector("c-prometheion-score-listener");
    this.template.addEventListener("scoreresult", this.handleScoreUpdate.bind(this));
  }

  @wire(getComplianceScore)
  wiredScore({ data, error }) {
    if (data) {
      this.score = data;
      this.loading = false;
    } else if (error) {
      console.error("Error loading score: ", error);
      this.loading = false;
    }
  }

  handleScoreUpdate(event) {
    const result = event.detail;

    // Show toast notification
    this.showToast(
      "Compliance Score Updated",
      `Risk Score: ${result.riskScore} for ${result.entityType}`,
      result.riskScore >= 70 ? "warning" : "success"
    );

    // Refresh score card
    this.loadScore();
  }

  loadScore() {
    // Trigger wire adapter refresh
    refreshApex(this.wiredScore);
  }

  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(evt);
  }
}
```

### Cost Optimization Analysis

#### 4.11 Cost Comparison

**Current Architecture (100% Apex):**

| Component               | Cost per 1M Events       | Notes                          |
| ----------------------- | ------------------------ | ------------------------------ |
| **Salesforce CPU Time** | $0 (included in license) | But hits governor limits       |
| **Claude API Calls**    | $15                      | From Salesforce (synchronous)  |
| **API Callouts**        | $0 (included)            | But counts toward daily limits |
| **Total**               | **$15**                  | **Limited by governor limits** |

**Off-Platform Architecture (Hub-and-Spoke):**

| Component                  | Cost per 1M Events | Notes                                         |
| -------------------------- | ------------------ | --------------------------------------------- |
| **Salesforce Event Relay** | $0                 | Native feature, no code                       |
| **Amazon EventBridge**     | $1.00              | First 1M events free, then $1/M               |
| **Kinesis Firehose**       | $0.029             | $0.029 per GB ingested                        |
| **S3 Storage**             | $0.023             | $0.023 per GB/month                           |
| **Lambda Compute**         | $0.20              | 512 MB, 1 second avg, $0.0000166667/GB-second |
| **DynamoDB**               | $0.25              | On-demand pricing                             |
| **Claude API Calls**       | $15                | From Lambda (same cost)                       |
| **Total**                  | **$16.50**         | **Unlimited scalability**                     |

**Margin Impact:**

- **Current**: Hits governor limits → Customer churn → Lost revenue
- **Off-Platform**: Scales infinitely → Retains enterprise customers → Protects 70% Gross Margin

#### 4.12 Governor Limit Protection

**Before (Apex):**

```
User changes Permission Set
  → Trigger fires
  → Query metadata (1 SOQL)
  → Calculate risk score (5 seconds CPU)
  → Call Claude API (2 seconds CPU)
  → Insert record (1 DML)
  → Total: 7 seconds CPU, 1 SOQL, 1 DML
  → ❌ HITS LIMIT on orgs with 100+ permission sets
```

**After (Off-Platform):**

```
User changes Permission Set
  → Trigger fires
  → Publish Platform Event (0 CPU, 0 SOQL, 0 DML)
  → Event Relay → AWS
  → Lambda processes (unlimited time)
  → Callback updates Salesforce
  → ✅ NO GOVERNOR LIMITS
```

### Phase 1 Implementation Plan

#### 4.13 Week 1-2: Foundation Setup

**Day 1-3: AWS Infrastructure**

- [ ] Create AWS account (if needed)
- [ ] Set up Terraform for infrastructure as code
- [ ] Deploy EventBridge, Kinesis Firehose, S3 bucket
- [ ] Create IAM roles and policies
- [ ] Set up DynamoDB tables

**Day 4-5: Salesforce Event Relay**

- [ ] Create Platform Event: `Prometheion_Raw_Event__e`
- [ ] Configure Event Relay in Salesforce Setup
- [ ] Test event publishing (manual test)

**Day 6-7: Lambda Stub**

- [ ] Create Python Lambda function (stub)
- [ ] Deploy to AWS
- [ ] Test EventBridge → Lambda connection
- [ ] Verify events are received

**Day 8-10: Basic Callback**

- [ ] Create `Compliance_Score__c` custom object
- [ ] Create REST endpoint: `PrometheionScoreCallback`
- [ ] Implement OAuth 2.0 JWT Bearer flow
- [ ] Test Lambda → Salesforce callback

#### 4.14 Week 3-4: Event Publisher Refactoring

**Day 11-14: Refactor Apex Code**

- [ ] Create `PrometheionEventPublisher.cls`
- [ ] Update triggers to use publisher
- [ ] Create scheduled job for SetupAuditTrail polling
- [ ] Remove heavy processing from existing classes

**Day 15-17: Lambda Implementation**

- [ ] Implement event processor Lambda
- [ ] Implement compliance scorer Lambda
- [ ] Add Claude API integration
- [ ] Add error handling and retries

**Day 18-20: Testing & Documentation**

- [ ] End-to-end testing
- [ ] Load testing (1000+ events)
- [ ] Document architecture
- [ ] Create runbook for operations

### Data Model Requirements

1. **Prometheion_Raw_Event\_\_e** (Platform Event)
   - `Payload__c` (Long Text Area) - JSON event data
   - `Entity_Type__c` (Text)
   - `Entity_Id__c` (Text)
   - `Action__c` (Text)
   - `Changed_By__c` (Text)
   - `Timestamp__c` (DateTime)
   - `Org_ID__c` (Text) - Critical for multi-tenant

2. **Prometheion_Score_Result\_\_e** (Platform Event)
   - `Org_ID__c` (Text)
   - `Entity_Type__c` (Text)
   - `Entity_Id__c` (Text)
   - `Risk_Score__c` (Number)
   - `Framework_Scores_JSON__c` (Long Text Area)

3. **Compliance_Score\_\_c** (Custom Object)
   - `Org_ID__c` (Text, External ID)
   - `Entity_Type__c` (Text, External ID)
   - `Entity_Id__c` (Text, External ID)
   - `Risk_Score__c` (Number)
   - `Framework_Scores_JSON__c` (Long Text Area)
   - `Calculated_At__c` (DateTime)

### Integration Points

- **Salesforce Event Relay**: Native integration (zero code)
- **Amazon EventBridge**: Event routing (AWS managed)
- **Kinesis Firehose**: Streaming ingestion (AWS managed)
- **S3**: Data lake storage (AWS managed)
- **Lambda**: Compute (AWS managed)
- **DynamoDB**: Fast state retrieval (AWS managed)
- **Salesforce REST API**: Callback endpoint (custom Apex)

### Estimated Effort

- **AWS Infrastructure Setup**: 24 hours
- **Salesforce Event Relay Configuration**: 8 hours
- **Lambda Development**: 32 hours
- **Apex Refactoring**: 16 hours
- **Callback Implementation**: 16 hours
- **Testing & Documentation**: 24 hours
- **Total**: ~120 hours (15 days / 3 weeks)

### Success Criteria

**Phase 1 Complete When:**

1. ✅ Events flow from Salesforce → AWS S3 (verified in S3 console)
2. ✅ Lambda processes events and calls Claude API
3. ✅ Results callback to Salesforce and update `Compliance_Score__c`
4. ✅ LWC components receive real-time updates via Platform Events
5. ✅ Zero governor limit errors in production
6. ✅ End-to-end latency < 30 seconds (event → result)

### Next Steps After Phase 1

Once the EventBridge connection is established:

1. **Build Event Intelligence Engine** (Section 1) on AWS Lambda
2. **Build Configuration Drift Guard** (Section 2) using S3 data lake
3. **Build Evidence Engine** (Section 3) using DynamoDB + S3
4. **All features built off-platform from day one** ✅

---

## 5. Partner Edition & Audit Authority (STRATEGIC GAPS)

### Business Plan Requirement

> "Partner Edition: White-label compliance monitoring for Salesforce implementation partners. Audit Authority: Third-party audit firm integration for automated audit evidence submission."

### Current State Analysis

**What Exists:**

- Single-org focused implementation
- No multi-tenant architecture
- No partner/reseller capabilities

**What's Missing:**

1. **Multi-tenant architecture** - No org isolation
2. **White-labeling** - No branding customization
3. **Partner portal** - No reseller dashboard
4. **Audit firm integration** - No third-party API
5. **Billing integration** - No usage-based billing

### Technical Implementation Strategy

#### 5.1 Multi-Tenant Architecture

**Org Isolation:**

```apex
public class PrometheionTenantManager {
    /**
     * Get current tenant context
     */
    public static String getCurrentTenant() {
        // For Partner Edition, tenant = Org ID
        // For managed package, tenant = Subscriber Org ID
        return UserInfo.getOrganizationId();
    }

    /**
     * Ensure data isolation between tenants
     */
    public static void enforceTenantIsolation(String tenantId) {
        // All queries must include tenant filter
        // Example: WHERE Tenant__c = :tenantId
    }
}
```

**Custom Object with Tenant Field:**

```xml
<!-- All custom objects need Tenant__c field -->
<fields>
    <fullName>Tenant__c</fullName>
    <label>Tenant</label>
    <type>Text</type>
    <length>18</length>
    <required>true</required>
</fields>
```

#### 5.2 White-Labeling

**Branding Customization:**

```apex
public class PrometheionBrandingService {
    /**
     * Get branding for current tenant
     */
    @AuraEnabled(cacheable=true)
    public static BrandingConfig getBranding() {
        String tenantId = PrometheionTenantManager.getCurrentTenant();

        // Query tenant branding settings
        Tenant_Branding__c branding = [
            SELECT Logo_URL__c, Primary_Color__c, Secondary_Color__c,
                   Product_Name__c, Support_Email__c
            FROM Tenant_Branding__c
            WHERE Tenant__c = :tenantId
            LIMIT 1
        ];

        if (branding != null) {
            return new BrandingConfig(
                logoUrl = branding.Logo_URL__c,
                primaryColor = branding.Primary_Color__c,
                secondaryColor = branding.Secondary_Color__c,
                productName = branding.Product_Name__c,
                supportEmail = branding.Support_Email__c
            );
        }

        // Default Prometheion branding
        return new BrandingConfig(
            logoUrl = '/resource/PrometheionLogo',
            primaryColor = '#16325c',
            secondaryColor = '#00a1e0',
            productName = 'Prometheion',
            supportEmail = 'support@prometheion.com'
        );
    }
}
```

**LWC Component with Dynamic Branding:**

```javascript
// prometheionDashboard.js
import { LightningElement, wire } from "lwc";
import getBranding from "@salesforce/apex/PrometheionBrandingService.getBranding";

export default class PrometheionDashboard extends LightningElement {
  @wire(getBranding) branding;

  get logoUrl() {
    return this.branding?.data?.logoUrl || "/resource/PrometheionLogo";
  }

  get primaryColor() {
    return this.branding?.data?.primaryColor || "#16325c";
  }
}
```

#### 5.3 Partner Portal

**Partner Dashboard:**

```apex
public class PrometheionPartnerPortal {
    /**
     * Get all orgs managed by this partner
     */
    @AuraEnabled(cacheable=true)
    public static List<PartnerOrg> getPartnerOrgs() {
        String partnerId = UserInfo.getUserId(); // Or from custom field

        List<Partner_Org__c> orgs = [
            SELECT Id, Name, Org_Id__c, Status__c, Last_Scan_Date__c,
                   Compliance_Score__c, Framework__c
            FROM Partner_Org__c
            WHERE Partner__c = :partnerId
            ORDER BY Last_Scan_Date__c DESC
        ];

        List<PartnerOrg> result = new List<PartnerOrg>();
        for (Partner_Org__c org : orgs) {
            result.add(new PartnerOrg(
                id = org.Id,
                name = org.Name,
                orgId = org.Org_Id__c,
                status = org.Status__c,
                lastScan = org.Last_Scan_Date__c,
                score = org.Compliance_Score__c,
                framework = org.Framework__c
            ));
        }

        return result;
    }
}
```

#### 5.4 Audit Firm Integration

**REST API for Audit Firms:**

```apex
@RestResource(urlMapping='/prometheion/audit/*')
global class PrometheionAuditAPI {
    /**
     * Public API for audit firms to retrieve evidence
     */
    @HttpGet
    global static void getAuditEvidence() {
        RestRequest req = RestContext.request;
        String framework = req.params.get('framework');
        String orgId = req.params.get('orgId');
        String apiKey = req.headers.get('X-API-Key');

        // Authenticate audit firm
        if (!authenticateAuditFirm(apiKey)) {
            RestContext.response.statusCode = 401;
            RestContext.response.responseBody = Blob.valueOf('Unauthorized');
            return;
        }

        // Collect evidence
        EvidenceCollection evidence = PrometheionEvidenceCollector.collectEvidence(
            framework,
            Date.today().addDays(-180),
            Date.today()
        );

        // Return JSON
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(evidence));
    }

    private static Boolean authenticateAuditFirm(String apiKey) {
        // Check against Audit_Firm__c custom object
        List<Audit_Firm__c> firms = [
            SELECT Id FROM Audit_Firm__c
            WHERE API_Key__c = :apiKey
            AND Status__c = 'Active'
            LIMIT 1
        ];

        return !firms.isEmpty();
    }
}
```

### Data Model Requirements

1. **Tenant_Branding\_\_c** (Custom Object)
   - `Tenant__c` (Text)
   - `Logo_URL__c` (URL)
   - `Primary_Color__c` (Text)
   - `Secondary_Color__c` (Text)
   - `Product_Name__c` (Text)
   - `Support_Email__c` (Email)

2. **Partner_Org\_\_c** (Custom Object)
   - `Partner__c` (Lookup to User)
   - `Org_Id__c` (Text)
   - `Status__c` (Picklist: Active, Inactive, Suspended)
   - `Last_Scan_Date__c` (DateTime)
   - `Compliance_Score__c` (Number)

3. **Audit_Firm\_\_c** (Custom Object)
   - `Name` (Text)
   - `API_Key__c` (Text, encrypted)
   - `Status__c` (Picklist: Active, Inactive)
   - `Contact_Email__c` (Email)

### Estimated Effort

- **Multi-Tenant Architecture**: 40 hours
- **White-Labeling**: 24 hours
- **Partner Portal**: 32 hours
- **Audit Firm API**: 24 hours
- **Testing & Documentation**: 24 hours
- **Total**: ~144 hours (18 days)

---

## 6. Implementation Roadmap

### Phase 1: Critical Gaps (Months 1-3)

**Priority: Event Intelligence Engine**

- Week 1-2: Platform Events setup
- Week 3-4: Event Monitoring integration
- Week 5-6: Anomaly detection (Claude)
- Week 7-8: Event correlation logic
- Week 9-10: Testing & documentation

**Priority: Configuration Drift Guard**

- Week 11-12: Baseline snapshot system
- Week 13-14: Drift detection engine
- Week 15-16: Change approval integration
- Week 17-18: Rollback engine
- Week 19-20: Testing & documentation

### Phase 2: Evidence & Compute (Months 4-5)

**Priority: Evidence Engine**

- Week 21-22: Evidence collection service
- Week 23-24: Evidence organization/mapping
- Week 25-26: PDF/Excel export
- Week 27-28: Evidence linking
- Week 29-30: Testing & documentation

**Priority: Off-Platform Compute**

- Week 31-32: AWS Lambda setup
- Week 33-34: Salesforce integration
- Week 35-36: Callback handler
- Week 37-38: Testing & documentation

### Phase 3: Strategic Features (Months 6-8)

**Priority: Partner Edition & Audit Authority**

- Week 39-40: Multi-tenant architecture
- Week 41-42: White-labeling
- Week 43-44: Partner portal
- Week 45-46: Audit firm API
- Week 47-48: Testing & documentation

---

## 7. Technical Risks & Mitigation

### Risk 1: Governor Limits on Large Orgs

**Mitigation:**

- Implement off-platform compute (AWS Lambda)
- Use Platform Cache aggressively
- Batch processing for large datasets
- Async processing with Queueable

### Risk 2: Event Monitoring API Rate Limits

**Mitigation:**

- Implement exponential backoff
- Cache event log queries
- Batch event processing
- Use Platform Events for real-time needs

### Risk 3: Claude API Costs

**Mitigation:**

- Cache AI responses in Platform Cache
- Use Sonnet for simple queries, Opus only for deep analysis
- Batch multiple queries into single API call
- Implement usage quotas per tenant

### Risk 4: Data Privacy (Multi-Tenant)

**Mitigation:**

- Enforce tenant isolation at database level
- Use `WITH SECURITY_ENFORCED` on all queries
- Encrypt sensitive data (Shield Platform Encryption)
- Regular security audits

### Risk 5: Rollback Complexity

**Mitigation:**

- Start with read-only drift detection
- Implement rollback for simple changes first (permission sets)
- Use Metadata API for complex rollbacks
- Require manual approval for rollbacks

---

## 8. Success Metrics

### Technical Metrics

- **Event Processing Latency**: < 5 seconds from event to alert
- **Drift Detection Accuracy**: > 95% true positive rate
- **Evidence Collection Time**: < 2 minutes for full org scan
- **Off-Platform Job Completion**: < 5 minutes for complex analysis
- **API Uptime**: > 99.9% availability

### Business Metrics

- **Time to Compliance**: Reduce from 6 months to 2 months
- **Audit Preparation Time**: Reduce from 40 hours to 4 hours
- **False Positive Rate**: < 5% for compliance alerts
- **Customer Satisfaction**: > 4.5/5.0 rating

---

## 9. Conclusion

This technical deep-dive identifies the critical gaps between Prometheion's current implementation and the business plan vision. The most critical gaps are:

1. **Event Intelligence Engine** - Real-time compliance violation detection
2. **Configuration Drift Guard** - Baseline comparison and rollback
3. **Evidence Engine** - Automated audit evidence collection
4. **Off-Platform Compute** - Scalable AI analysis infrastructure

Implementing these features will transform Prometheion from a compliance scoring tool into a comprehensive compliance platform that differentiates through architectural defensibility and automation.

**Next Steps:**

1. Review and prioritize gaps with stakeholders
2. Create detailed user stories for Phase 1
3. Set up development environment (AWS, Salesforce DX)
4. Begin implementation of Event Intelligence Engine

---

## Appendix: Code Examples Repository

All code examples in this document are available in:

- `force-app/main/default/classes/PrometheionEventIntelligence/`
- `force-app/main/default/classes/PrometheionDriftGuard/`
- `force-app/main/default/classes/PrometheionEvidenceEngine/`
- `force-app/main/default/classes/PrometheionOffPlatform/`
- `aws-lambda/prometheion-analyzer/`
