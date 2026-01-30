# Big Object Deployment Guide

## Overview

`Elaro_Compliance_Graph__b` is a Big Object used to store compliance graph nodes for long-term retention and analysis. Big Objects have special deployment requirements and limitations.

## Deployment Options

### 1. Setup UI (Recommended for Initial Creation)

**Steps:**

1. Navigate to **Setup → Big Objects → New**
2. Enter object details:
   - **Label:** Elaro Compliance Graph
   - **Plural Label:** Compliance Graph Nodes
   - **Object Name:** `Elaro_Compliance_Graph__b`
3. Add all required fields (see field list below)
4. Create indexes:
   - **Index Name:** `ElaroGraphIndex`
   - **Fields:**
     - `Graph_Node_Id__c` (DESC)
     - `Timestamp__c` (DESC)
5. Save and activate

**Pros:**

- Visual interface for field and index configuration
- Immediate validation
- No API version dependencies

**Cons:**

- Manual process
- Not suitable for CI/CD automation

### 2. Metadata API (API 47.0+)

**Command:**

```bash
sf project deploy start --metadata BigObject:Elaro_Compliance_Graph__b
```

**Requirements:**

- Salesforce CLI (`sf`) version 1.60.0 or later
- API version 47.0 or later
- Big Object metadata file must be valid

**Pros:**

- Automated deployment
- Version controlled
- CI/CD compatible

**Cons:**

- Index changes may require object recreation
- Some field types have restrictions

**Limitations:**

- Index modifications require deleting and recreating the Big Object
- Cannot modify indexed fields after creation
- Field deletions are not supported

### 3. SFDX Source Push (Scratch Orgs Only)

**Command:**

```bash
sf project deploy start --source-dir force-app/main/default/objects/Elaro_Compliance_Graph__b
```

**Requirements:**

- Scratch org (not available in sandbox/production)
- API version 47.0 or later

**Pros:**

- Simple deployment
- Works with source tracking

**Cons:**

- Scratch orgs only
- Same limitations as Metadata API

## Field Configuration

### Required Fields

| Field API Name            | Type         | Length | Required | Indexed         |
| ------------------------- | ------------ | ------ | -------- | --------------- |
| `Graph_Node_Id__c`        | Text         | 255    | Yes      | Yes (Primary)   |
| `Timestamp__c`            | DateTime     | -      | Yes      | Yes (Secondary) |
| `Entity_Type__c`          | Text         | 50     | No       | No              |
| `Entity_Record_Id__c`     | Text         | 18     | No       | No              |
| `Compliance_Framework__c` | Text         | 50     | No       | No              |
| `Risk_Score__c`           | Number       | 3,1    | No       | No              |
| `Drift_Category__c`       | Text         | 50     | No       | No              |
| `Node_Metadata__c`        | LongTextArea | 131072 | No       | No              |
| `AI_Confidence__c`        | Number       | 5,2    | No       | No              |
| `AI_Explanation__c`       | LongTextArea | 32768  | No       | No              |
| `Human_Adjudicator__c`    | Text         | 18     | No       | No              |
| `Human_Adjudicated__c`    | Checkbox     | -      | No       | No              |
| `Parent_Node_Id__c`       | Text         | 255    | No       | No              |
| `Graph_Version__c`        | Text         | 50     | No       | No              |

### Index Configuration

**Index Name:** `ElaroGraphIndex`

**Fields:**

1. `Graph_Node_Id__c` (DESC) - Primary indexed field
2. `Timestamp__c` (DESC) - Secondary indexed field

**Important Notes:**

- Indexes must be created before data insertion
- Only indexed fields can be used in SOQL WHERE clauses
- Index changes require object recreation (data loss)

## Post-Deployment Steps

### 1. Verify Index Creation

**Via Setup UI:**

1. Navigate to **Setup → Big Objects → Elaro Compliance Graph**
2. Click **Indexes** tab
3. Verify `ElaroGraphIndex` exists with both fields

**Via SOQL:**

```sql
SELECT Graph_Node_Id__c, Timestamp__c
FROM Elaro_Compliance_Graph__b
WHERE Graph_Node_Id__c != null
LIMIT 1
```

### 2. Test Data Insertion

**Apex Test:**

```apex
String nodeId = ElaroGraphIndexer.indexChange(
    'PERMISSION_SET',
    '00e000000000000AAA',
    null,
    'SOC2'
);
System.assertNotEquals(null, nodeId, 'Node ID should be returned');
```

### 3. Verify Queries Work

**Test Query:**

```apex
List<Elaro_Compliance_Graph__b> nodes = [
    SELECT Graph_Node_Id__c, Timestamp__c, Entity_Type__c
    FROM Elaro_Compliance_Graph__b
    WHERE Graph_Node_Id__c = :testNodeId
    AND Timestamp__c >= :startDate
    WITH USER_MODE
];
```

## Important Limitations

### 1. Field Modifications

- **Cannot modify indexed fields** after creation
- Field type changes are not supported
- Field deletions are not supported
- New fields can be added (but not indexed if index already exists)

### 2. Index Modifications

- **Index changes require object recreation**
- All data will be lost during recreation
- Plan indexes carefully before initial deployment

### 3. SOQL Restrictions

- **Only indexed fields** can be used in WHERE clauses
- No ORDER BY on non-indexed fields
- No GROUP BY or aggregate functions
- LIMIT is required (default: 2000, max: 10,000)

### 4. DML Restrictions

- **Insert only** - No UPDATE or DELETE operations
- Batch insert recommended for large volumes
- Maximum 200 records per transaction

## Best Practices

1. **Plan Indexes First**
   - Identify all query patterns before deployment
   - Index fields that will be used in WHERE clauses
   - Consider query performance vs. storage

2. **Test in Scratch Org**
   - Deploy to scratch org first
   - Test all query patterns
   - Verify data insertion works

3. **Document Query Patterns**
   - List all SOQL queries that will be used
   - Ensure all WHERE clause fields are indexed
   - Update documentation if new queries are added

4. **Monitor Storage**
   - Big Objects count toward data storage
   - Plan for long-term retention
   - Consider data archival strategy

5. **Version Control**
   - Keep Big Object metadata in version control
   - Document any manual changes in Setup UI
   - Use deployment scripts for consistency

## Troubleshooting

### Issue: "Field is not indexed" Error

**Solution:**

- Add the field to an index (requires object recreation)
- Or modify query to only use indexed fields

### Issue: "Cannot modify indexed field"

**Solution:**

- Recreate Big Object with new field configuration
- Migrate data before deletion (if possible)
- Update all code references

### Issue: Deployment Fails

**Solution:**

- Verify API version is 47.0 or later
- Check field types are supported (no Formula, Roll-up Summary)
- Ensure indexes reference valid fields
- Review deployment logs for specific errors

## Migration from Existing Data

If migrating from a standard custom object to Big Object:

1. **Export existing data** to CSV or external system
2. **Create Big Object** with same field structure
3. **Create indexes** for query patterns
4. **Import data** using batch Apex or Data Loader
5. **Update code** to use Big Object instead of standard object
6. **Archive old object** after verification period

## References

- [Salesforce Big Objects Documentation](https://help.salesforce.com/s/articleView?id=sf.big_objects.htm)
- [Big Objects Metadata API](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_big_objects.htm)
- [Big Objects SOQL Limitations](https://developer.salesforce.com/docs/atlas.en-us.bigobjects.meta/bigobjects/big_objects_soql_sosl.htm)
