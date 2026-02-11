# Performance Alert Workaround - Production Ready

## Overview

Due to Salesforce Developer Edition custom object limits (28 objects max), the `Performance_Alert__e` platform event cannot be deployed. This document describes the production-ready workaround using `Performance_Alert_History__c` custom object.

## Architecture

### Original Design (Platform Event)
```
PerformanceRuleEngine → Performance_Alert__e → EventBus.publish()
                                              ↓
                                    Trigger/Subscriber → Process Alert
```

### Current Implementation (Custom Object)
```
PerformanceRuleEngine → Performance_Alert_History__c → Database.insert()
                                                      ↓
                                            SlackNotifier (optional)
```

## Components

### 1. Performance_Alert_History__c Object
**Location**: `force-app/main/default/objects/Performance_Alert_History__c/`

**Fields**:
- `Metric__c` (Text, 100) - Performance metric name (CPU, HEAP, SOQL, DML)
- `Value__c` (Number, 18, 4) - Current value that triggered the alert
- `Threshold__c` (Number, 18, 4) - Threshold value that was exceeded
- `Context_Record__c` (Text, 18) - Optional Salesforce record ID for context
- `Stack__c` (LongTextArea, 131072) - Stack trace or additional details

**Status**: ✅ Deployed to Salesforce

### 2. PerformanceAlertPublisher Class
**Location**: `force-app/main/default/classes/PerformanceAlertPublisher.cls`

**Purpose**: Publishes performance alerts to `Performance_Alert_History__c`

**Key Methods**:
```apex
@AuraEnabled
public static void publish(
    String metric, 
    Decimal value, 
    Decimal threshold, 
    String contextRecordId, 
    String stack
)
```

**Features**:
- Rate limiting (100 calls per 60 seconds)
- Input validation
- XSS protection for stack traces
- Automatic Slack notification integration
- Error logging to `Integration_Error__c`

**Status**: ✅ Deployed to Salesforce

### 3. PerformanceRuleEngine Class
**Location**: `force-app/main/default/classes/PerformanceRuleEngine.cls`

**Purpose**: Evaluates governor limits and creates alerts when thresholds are exceeded

**Key Methods**:
```apex
@AuraEnabled
public static EvalResult evaluateAndPublish(
    LimitMetrics.GovernorStats stats,
    String contextRecordId
)
```

**Default Thresholds**:
- CPU: Warn 8000ms, Critical 9000ms
- Heap: Warn 4500KB, Critical 5000KB
- SOQL: Warn 90, Critical 100
- DML: Warn 140, Critical 150

**Status**: ✅ Deployed to Salesforce

### 4. SlackNotifier Class
**Location**: `force-app/main/default/classes/SlackNotifier.cls`

**Purpose**: Sends formatted Slack notifications for performance alerts

**Key Methods**:
```apex
public static void notifyPerformanceAlert(
    String metric, 
    Decimal value, 
    Decimal threshold, 
    String contextRecord
)
```

**Features**:
- Rich Slack Block Kit formatting
- Color-coded severity (🔴 Critical, 🟡 Warning)
- Queueable execution for async processing
- Automatic retry logic

**Status**: ✅ Deployed to Salesforce

## Usage Examples

### Example 1: Manual Alert Publication
```apex
// Publish a performance alert
PerformanceAlertPublisher.publish(
    'CPU',              // metric
    9500,               // value (ms)
    10000,              // threshold (ms)
    '001xx000003Gxxx',  // contextRecordId (optional)
    'Stack trace...'    // stack (optional)
);
```

### Example 2: Automated Governor Limit Monitoring
```apex
// Get current governor stats
LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
stats.cpuMs = Limits.getCpuTime();
stats.heapKb = Limits.getHeapSize() / 1024;
stats.soql = Limits.getQueries();
stats.dml = Limits.getDmlStatements();

// Evaluate and publish alerts if thresholds exceeded
PerformanceRuleEngine.EvalResult result = 
    PerformanceRuleEngine.evaluateAndPublish(stats, 'contextId');

System.debug('Alerts published: ' + result.eventsPublished);
System.debug('Status: ' + result.message);
```

### Example 3: Query Alert History
```apex
// Get recent performance alerts
List<Performance_Alert_History__c> recentAlerts = [
    SELECT Metric__c, Value__c, Threshold__c, CreatedDate
    FROM Performance_Alert_History__c
    WHERE CreatedDate = LAST_N_DAYS:7
    ORDER BY CreatedDate DESC
    LIMIT 100
];

// Analyze CPU alerts
for (Performance_Alert_History__c alert : recentAlerts) {
    if (alert.Metric__c == 'CPU') {
        Decimal percentOfLimit = (alert.Value__c / alert.Threshold__c) * 100;
        System.debug('CPU at ' + percentOfLimit + '% of limit');
    }
}
```

## Testing

### Test Classes
All test classes are deployed and passing:

1. **PerformanceAlertPublisherTest** - Tests alert publication
2. **PerformanceRuleEngineTest** - Tests threshold evaluation
3. **SlackNotifierTest** - Tests notification formatting
4. **PerformanceAlertEventTriggerTest** - Tests alert history creation

### Running Tests
```bash
# Run all performance alert tests
sf apex run test --tests PerformanceAlertPublisherTest,PerformanceRuleEngineTest,SlackNotifierTest,PerformanceAlertEventTriggerTest --target-org prod-org

# Run specific test
sf apex run test --tests PerformanceAlertPublisherTest --target-org prod-org
```

## Monitoring & Reporting

### Dashboard Queries

**Alert Volume by Metric**:
```sql
SELECT Metric__c, COUNT(Id) AlertCount
FROM Performance_Alert_History__c
WHERE CreatedDate = LAST_N_DAYS:30
GROUP BY Metric__c
ORDER BY COUNT(Id) DESC
```

**Critical Alerts**:
```sql
SELECT Metric__c, Value__c, Threshold__c, CreatedDate, Context_Record__c
FROM Performance_Alert_History__c
WHERE Value__c >= Threshold__c * 0.95
AND CreatedDate = LAST_N_DAYS:7
ORDER BY CreatedDate DESC
```

**Alert Trends**:
```sql
SELECT DAY_ONLY(CreatedDate) AlertDate, COUNT(Id) AlertCount
FROM Performance_Alert_History__c
WHERE CreatedDate = LAST_N_DAYS:30
GROUP BY DAY_ONLY(CreatedDate)
ORDER BY DAY_ONLY(CreatedDate)
```

## Performance Considerations

### Storage
- **Custom Object**: Uses standard Salesforce storage
- **Retention**: Implement data retention policy (e.g., delete alerts older than 90 days)
- **Archival**: Export historical data to external system if needed

### Scalability
- **Rate Limiting**: Built-in 100 calls/minute limit prevents runaway alert creation
- **Bulk Operations**: `PerformanceRuleEngine` uses bulk DML for multiple alerts
- **Async Processing**: Slack notifications run in Queueable context

### Comparison to Platform Events

| Feature | Platform Event | Custom Object (Current) |
|---------|---------------|------------------------|
| **Storage** | No storage (fire-and-forget) | Persistent storage |
| **Query History** | ❌ Not possible | ✅ Full SOQL access |
| **Reporting** | ❌ Limited | ✅ Reports & Dashboards |
| **Retention** | 24-72 hours | Unlimited (with cleanup) |
| **Limits** | Event delivery limits | Standard object limits |
| **Cost** | Included | Uses data storage |

## Migration Path (Future)

If upgrading to Professional/Enterprise Edition with higher object limits:

1. **Deploy Platform Event**:
   ```bash
   sf project deploy start --source-dir force-app/main/default/objects/Performance_Alert__e
   ```

2. **Update Classes**: Revert to platform event versions (available in git history)

3. **Data Migration**: Export `Performance_Alert_History__c` records if needed

4. **Cleanup**: Delete `Performance_Alert_History__c` object after migration

## Maintenance

### Data Cleanup Job
Create a scheduled Apex job to clean old alerts:

```apex
global class PerformanceAlertCleanupBatch implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date cutoffDate = Date.today().addDays(-90);
        return Database.getQueryLocator([
            SELECT Id FROM Performance_Alert_History__c 
            WHERE CreatedDate < :cutoffDate
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Performance_Alert_History__c> scope) {
        delete scope;
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('Cleanup complete');
    }
}
```

Schedule weekly:
```apex
System.schedule('Weekly Alert Cleanup', '0 0 2 ? * SUN', new PerformanceAlertCleanupBatch());
```

## Support

### Troubleshooting

**Issue**: Alerts not being created
- Check `Integration_Error__c` for error logs
- Verify `Performance_Alert_History__c` object permissions
- Check rate limiting (100 calls/minute)

**Issue**: Slack notifications not sending
- Verify Named Credential `Slack_Webhook` is configured
- Check `Integration_Error__c` for webhook errors
- Ensure Queueable jobs are not at limit

**Issue**: High storage usage
- Implement data retention policy
- Archive old alerts to external system
- Reduce alert frequency by adjusting thresholds

## Conclusion

The `Performance_Alert_History__c` workaround is **production-ready** and provides several advantages over platform events:

✅ **Full query capability** for analysis and reporting  
✅ **Persistent storage** for compliance and auditing  
✅ **Dashboard integration** with standard Salesforce reports  
✅ **No platform event limits** to manage  

This solution is recommended for long-term use, even if org limits are increased in the future.

---

**Last Updated**: January 6, 2026  
**Status**: ✅ Production Ready  
**Deployed Components**: 4/4 Apex Classes, 1/1 Custom Object
