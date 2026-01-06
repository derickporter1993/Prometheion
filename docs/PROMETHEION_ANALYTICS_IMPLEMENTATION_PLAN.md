# Prometheion Analytics Components - Implementation Plan

**Version:** 1.0
**Date:** January 3, 2026
**Author:** Derick Porter

## Executive Summary

This document provides a comprehensive implementation plan for the Prometheion Analytics LWC Components suite. The suite includes five production-ready Lightning Web Components designed for secure, dynamic analytics and reporting within the Prometheion platform.

## Components Overview

### 1. Prometheion Dynamic Report Builder
- **Purpose:** Self-service reporting with secure dynamic SOQL
- **Controller:** `PrometheionDynamicReportController`
- **Component:** `prometheionDynamicReportBuilder`
- **Features:**
  - Object and field selection
  - Dynamic filter builder
  - Sortable results
  - Export capabilities
  - Row limit protection

### 2. Prometheion Executive KPI Dashboard
- **Purpose:** Metadata-driven KPIs with RAG (Red/Amber/Green) thresholds
- **Controller:** `PrometheionExecutiveKPIController`
- **Component:** `prometheionExecutiveKPIDashboard`
- **Features:**
  - Custom Metadata Type configuration
  - Real-time KPI refresh
  - Status indicators (Green/Yellow/Red)
  - Target tracking
  - Error isolation

### 3. Prometheion Drill-Down Detail Viewer
- **Purpose:** Click-to-records investigation from KPI metrics
- **Controller:** `PrometheionDrillDownController`
- **Component:** `prometheionDrillDownViewer`
- **Features:**
  - Paginated record display
  - CSV export
  - Sortable columns
  - Record navigation

### 4. Prometheion Comparative Analytics Grid
- **Purpose:** Matrix/heatmap comparisons with governor limit protection
- **Controller:** `PrometheionComparativeAnalyticsController`
- **Component:** `prometheionComparativeAnalytics`
- **Features:**
  - Row/Column dimension selection
  - Aggregate expressions
  - Automatic summary object fallback
  - Benchmark calculations

### 5. Prometheion Trend Analyzer
- **Purpose:** Time-series trend analysis with configurable granularity
- **Controller:** `PrometheionTrendController`
- **Component:** `prometheionTrendAnalyzer`
- **Features:**
  - Multiple granularities (day/week/month/quarter/year)
  - Period-over-period comparisons
  - Trend direction indicators
  - Statistical summaries

## Pre-Deployment Requirements

### 1. Platform Cache Setup (Optional but Recommended)
- **Partition Name:** `local.PrometheionReportCache`
- **Allocation:** Minimum 1MB Org cache
- **Purpose:** Cache field metadata for improved performance
- **Setup Path:** Setup → Platform Cache → New Partition

### 2. Custom Metadata Type Setup
- **Type:** `Executive_KPI__mdt`
- **Required Fields:**
  - `KPI_Name__c` (Text, 80)
  - `Metric_Label__c` (Text, 255)
  - `SOQL_Query__c` (Long Text Area)
  - `Format_Type__c` (Picklist: currency, percent, days, number)
  - `Target_Value__c` (Number)
  - `Green_Threshold__c` (Number)
  - `Yellow_Threshold__c` (Number)
  - `Red_Threshold__c` (Number)
  - `Trend_Direction__c` (Picklist: higher_is_better, lower_is_better)
  - `Sort_Order__c` (Number)
  - `Is_Active__c` (Checkbox)
  - `Description__c` (Long Text Area)

### 3. Object Whitelisting
Update the `ALLOWED_OBJECTS` set in each controller to include objects specific to your org:
- `PrometheionDynamicReportController`
- `PrometheionDrillDownController`
- `PrometheionComparativeAnalyticsController`
- `PrometheionTrendController`

Current default objects:
- Account, Contact, Opportunity, Case, Lead
- Alert__c, API_Usage_Snapshot__c, Deployment_Job__c, Flow_Execution__c, Performance_Alert_History__c

## Deployment Steps

### Step 1: Deploy Apex Classes
```bash
sf project deploy start --source-dir force-app/main/default/classes/Prometheion*Controller*.cls
sf project deploy start --source-dir force-app/main/default/classes/Prometheion*Controller*.cls-meta.xml
```

### Step 2: Deploy Test Classes
```bash
sf project deploy start --source-dir force-app/main/default/classes/Prometheion*ControllerTest.cls
sf project deploy start --source-dir force-app/main/default/classes/Prometheion*ControllerTest.cls-meta.xml
```

### Step 3: Run Tests
```bash
sf apex run test --class-names PrometheionDynamicReportControllerTest,PrometheionExecutiveKPIControllerTest,PrometheionDrillDownControllerTest,PrometheionComparativeAnalyticsControllerTest,PrometheionTrendControllerTest --result-format human --code-coverage
```

### Step 4: Deploy LWC Components
```bash
sf project deploy start --source-dir force-app/main/default/lwc/prometheion*
```

### Step 5: Verify Deployment
- Navigate to Setup → Custom Code → Lightning Components
- Verify all 5 components are listed and exposed
- Check for any deployment errors

## Post-Deployment Configuration

### 1. Create KPI Metadata Records
Navigate to Setup → Custom Metadata Types → Executive KPI → Manage Records

**Example KPI Record:**
```
Developer Name: Total_Accounts
KPI Name: total_accounts
Metric Label: Total Accounts
SOQL Query: SELECT COUNT(Id) metricValue FROM Account WHERE CreatedDate = LAST_N_MONTHS:3
Format Type: number
Target Value: 1000
Green Threshold: 1000
Yellow Threshold: 750
Red Threshold: 500
Trend Direction: higher_is_better
Sort Order: 1
Is Active: true
Description: Total number of accounts created in last 3 months
```

### 2. Configure Platform Cache (Optional)
1. Setup → Platform Cache → New Partition
2. Name: `PrometheionReportCache`
3. Allocate at least 1MB to Org cache
4. Save

### 3. Add Components to Lightning Pages
1. Navigate to the desired Lightning App Page, Record Page, or Home Page
2. Edit the page
3. Add components from the Custom section:
   - Prometheion Dynamic Report Builder
   - Prometheion Executive KPI Dashboard
   - Prometheion Drill-Down Viewer
   - Prometheion Comparative Analytics
   - Prometheion Trend Analyzer
4. Configure component properties as needed
5. Activate the page

## Security Configuration

### Profile/Permission Set Setup
Ensure users have appropriate access:

1. **Object Permissions:**
   - Read access to objects in `ALLOWED_OBJECTS`
   - Field-level security for fields used in reports

2. **Apex Class Access:**
   - All Prometheion*Controller classes should be accessible
   - Test classes can be excluded from user profiles

3. **Platform Cache (if used):**
   - Users need access to Platform Cache partition

### Sharing Rules (if applicable)
- Configure sharing rules for objects if data visibility needs to be restricted
- Components respect `WITH SECURITY_ENFORCED` and `with sharing` keywords

## Usage Guidelines

### Dynamic Report Builder
1. Select an object from the dropdown
2. Wait for fields to load
3. Select fields to include in the report
4. (Optional) Add filters
5. (Optional) Configure sorting
6. Set maximum rows (default: 1000, max: 10000)
7. Click "Run Report"

### Executive KPI Dashboard
1. Component automatically loads active KPIs from Custom Metadata
2. KPIs display with status indicators (Green/Yellow/Red)
3. Click on a KPI to drill down (if configured)

### Drill-Down Viewer
1. Typically used as a child component
2. Receives context JSON from parent component
3. Displays paginated records
4. Supports CSV export

### Comparative Analytics
1. Select object
2. Choose row dimension field
3. Choose column dimension field
4. Enter aggregate expression (e.g., `SUM(Amount)`)
5. Click "Generate Matrix"

### Trend Analyzer
1. Select object
2. Choose date field
3. Choose metric field
4. Select granularity (day/week/month/quarter/year)
5. Set months back (1-36)
6. Click "Analyze Trend"

## Troubleshooting

### Common Issues

**"Object not authorized"**
- **Solution:** Add the object to `ALLOWED_OBJECTS` in the relevant controller
- **Location:** Controller class, line ~19-29

**"Field not accessible"**
- **Solution:** Verify FLS (Field-Level Security) settings
- **Check:** Profile/Permission Set → Object Settings → Field Permissions

**"Query failed"**
- **Solution:** Check debug logs for detailed error
- **Common causes:** Invalid SOQL syntax, governor limits, data volume

**"Cache not working"**
- **Solution:** Verify Platform Cache partition exists and is allocated
- **Check:** Setup → Platform Cache → Partitions

**"KPI not displaying"**
- **Solution:** Verify Custom Metadata record exists and `Is_Active__c` is true
- **Check:** Setup → Custom Metadata Types → Executive KPI → Manage Records

### Debug Logs
Enable debug logs for:
- Apex Class: `Prometheion*Controller`
- Log Level: `DEBUG` for all categories
- Duration: 24 hours

## Performance Considerations

### Governor Limits
- **SOQL Queries:** All queries use `WITH SECURITY_ENFORCED`
- **Row Limits:** Configurable per component (defaults vary)
- **Pagination:** Drill-Down Viewer uses pagination (50 records/page)
- **Caching:** Field metadata cached for 24 hours

### Best Practices
1. **Use Platform Cache** for field metadata to reduce describe calls
2. **Limit row counts** in Dynamic Report Builder (recommended: < 5000 rows)
3. **Use summary objects** for Comparative Analytics with large datasets
4. **Set appropriate date ranges** in Trend Analyzer (recommended: < 24 months)

## Testing

### Unit Test Coverage
All controllers have corresponding test classes:
- `PrometheionDynamicReportControllerTest`
- `PrometheionExecutiveKPIControllerTest`
- `PrometheionDrillDownControllerTest`
- `PrometheionComparativeAnalyticsControllerTest`
- `PrometheionTrendControllerTest`

### Test Execution
```bash
# Run all tests
sf apex run test --class-names Prometheion*ControllerTest --result-format human

# Run with code coverage
sf apex run test --class-names Prometheion*ControllerTest --code-coverage --result-format human
```

### Target Coverage
- Minimum: 75% code coverage
- Recommended: 90%+ code coverage

## Maintenance

### Regular Tasks
1. **Monthly:** Review KPI Custom Metadata records for accuracy
2. **Quarterly:** Review object whitelists and add new objects as needed
3. **Annually:** Review and update security settings

### Updates
- All components use API Version 65.0
- Update API version as Salesforce releases new versions
- Test thoroughly after API version updates

## Support and Documentation

### Additional Resources
- Salesforce LWC Documentation: https://developer.salesforce.com/docs/component-library
- Apex Security Best Practices: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_security_sharing_chapter.htm

### Contact
For issues or questions, contact the Prometheion development team.

## Appendix A: Component File Structure

```
force-app/main/default/
├── classes/
│   ├── PrometheionDynamicReportController.cls
│   ├── PrometheionDynamicReportController.cls-meta.xml
│   ├── PrometheionExecutiveKPIController.cls
│   ├── PrometheionExecutiveKPIController.cls-meta.xml
│   ├── PrometheionDrillDownController.cls
│   ├── PrometheionDrillDownController.cls-meta.xml
│   ├── PrometheionComparativeAnalyticsController.cls
│   ├── PrometheionComparativeAnalyticsController.cls-meta.xml
│   ├── PrometheionTrendController.cls
│   ├── PrometheionTrendController.cls-meta.xml
│   └── [Test classes...]
└── lwc/
    ├── prometheionDynamicReportBuilder/
    ├── prometheionExecutiveKPIDashboard/
    ├── prometheionDrillDownViewer/
    ├── prometheionComparativeAnalytics/
    └── prometheionTrendAnalyzer/
```

## Appendix B: API Reference

### PrometheionDynamicReportController
- `getAvailableObjects()` - Returns list of allowed objects
- `getFieldMetadata(String objectApiName)` - Returns field metadata for object
- `executeReport(String reportConfigJson)` - Executes dynamic report query

### PrometheionExecutiveKPIController
- `getKPIMetrics(String metadataRecordIds)` - Returns all active KPIs
- `getKPIByName(String kpiName)` - Returns single KPI for refresh

### PrometheionDrillDownController
- `getRecords(String contextJson)` - Returns paginated records
- `exportToCSV(String contextJson)` - Exports records to CSV

### PrometheionComparativeAnalyticsController
- `getDimensionFields(String objectApiName)` - Returns groupable fields
- `executeMatrixQuery(String configJson)` - Executes matrix query

### PrometheionTrendController
- `getTimeSeries(...)` - Returns time-series trend data
- `getDateFields(String objectApiName)` - Returns date fields
- `getMetricFields(String objectApiName)` - Returns metric fields

---

**Document Version:** 1.0
**Last Updated:** January 3, 2026
**Next Review:** April 3, 2026
