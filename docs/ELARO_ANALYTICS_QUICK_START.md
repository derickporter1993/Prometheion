# Elaro Analytics - Quick Start Guide

**Last Updated:** January 3, 2026

## Quick Deployment

### Option 1: Using Deployment Script
```bash
./scripts/deploy-elaro-analytics.sh [org-alias]
```

### Option 2: Manual Deployment
```bash
# Deploy all controllers
sf project deploy start --source-dir force-app/main/default/classes/Elaro*Controller*

# Deploy all test classes
sf project deploy start --source-dir force-app/main/default/classes/Elaro*ControllerTest*

# Run tests
sf apex run test --class-names Elaro*ControllerTest --code-coverage

# Deploy LWC components
sf project deploy start --source-dir force-app/main/default/lwc/elaro*
```

## Essential Configuration

### 1. Create Your First KPI (5 minutes)

1. Go to **Setup → Custom Metadata Types → Executive KPI → Manage Records**
2. Click **New**
3. Fill in:
   - **Developer Name:** `Total_Accounts`
   - **KPI Name:** `total_accounts`
   - **Metric Label:** `Total Accounts`
   - **SOQL Query:** `SELECT COUNT(Id) metricValue FROM Account WHERE CreatedDate = LAST_N_MONTHS:3`
   - **Format Type:** `number`
   - **Target Value:** `1000`
   - **Green Threshold:** `1000`
   - **Yellow Threshold:** `750`
   - **Red Threshold:** `500`
   - **Trend Direction:** `higher_is_better`
   - **Sort Order:** `1`
   - **Is Active:** ✓
4. Click **Save**

### 2. Add Component to Lightning Page (2 minutes)

1. Go to **App Builder** or edit any Lightning page
2. Drag **Elaro Executive KPI Dashboard** from Custom components
3. Save and activate the page

### 3. Test Dynamic Report Builder (3 minutes)

1. Add **Elaro Dynamic Report Builder** to a page
2. Select **Account** object
3. Select **Name** and **CreatedDate** fields
4. Click **Run Report**
5. Verify results display

## Common Use Cases

### Use Case 1: Executive Dashboard
**Components:** Executive KPI Dashboard
**Setup:** Create 5-10 KPI metadata records
**Result:** Real-time KPI monitoring with status indicators

### Use Case 2: Self-Service Reporting
**Components:** Dynamic Report Builder
**Setup:** Add to App page, configure allowed objects
**Result:** Users can create custom reports without admin help

### Use Case 3: Data Analysis
**Components:** Comparative Analytics + Trend Analyzer
**Setup:** Configure for Opportunity or Case objects
**Result:** Matrix views and trend analysis for business insights

## Troubleshooting Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| "Object not authorized" | Add object to `ALLOWED_OBJECTS` in controller |
| "KPI not showing" | Check `Is_Active__c` = true in Custom Metadata |
| "Field not accessible" | Check Field-Level Security in Profile |
| "Query failed" | Check SOQL syntax in Custom Metadata |
| Component not visible | Check component is exposed in `.js-meta.xml` |

## Component Locations

- **Controllers:** `force-app/main/default/classes/Elaro*Controller.cls`
- **LWC Components:** `force-app/main/default/lwc/elaro*`
- **Tests:** `force-app/main/default/classes/Elaro*ControllerTest.cls`
- **Documentation:** `docs/ELARO_ANALYTICS_IMPLEMENTATION_PLAN.md`

## Support

For detailed information, see the full implementation plan:
`docs/ELARO_ANALYTICS_IMPLEMENTATION_PLAN.md`
