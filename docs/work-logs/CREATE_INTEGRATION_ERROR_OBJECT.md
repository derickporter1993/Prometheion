# Integration_Error\_\_c Object Creation Guide

**Purpose**: Create the Integration_Error\_\_c custom object in Salesforce org

---

## Option 1: Create via Salesforce UI (Recommended)

### Step 1: Create Custom Object

1. Navigate to **Setup** → **Object Manager**
2. Click **Create** → **Custom Object**
3. Fill in details:
   - **Label**: `Integration Error`
   - **Plural Label**: `Integration Errors`
   - **Object Name**: `Integration_Error__c`
   - **Record Name**: `Integration Error Number`
   - **Data Type**: Auto Number
   - **Display Format**: `IE-{00000}`
   - **Starting Number**: `1`
4. Check **Allow Reports**
5. Check **Allow Activities**
6. **Deployment Status**: Deployed
7. Click **Save**

### Step 2: Create Custom Fields

Create the following fields on the Integration_Error\_\_c object:

#### 1. Error_Type\_\_c (Picklist - Required)

- **Field Label**: Error Type
- **Field Name**: Error_Type\_\_c
- **Data Type**: Picklist
- **Values**:
  - SLACK
  - TEAMS
  - EINSTEIN
  - API_CALLOUT
  - OTHER
- **Required**: Yes

#### 2. Error_Message\_\_c (Long Text Area - Required)

- **Field Label**: Error Message
- **Field Name**: Error_Message\_\_c
- **Data Type**: Long Text Area
- **Length**: 32,768
- **Visible Lines**: 3
- **Required**: Yes

#### 3. Stack_Trace\_\_c (Long Text Area)

- **Field Label**: Stack Trace
- **Field Name**: Stack_Trace\_\_c
- **Data Type**: Long Text Area
- **Length**: 32,768
- **Visible Lines**: 5
- **Required**: No

#### 4. Correlation_Id\_\_c (Text)

- **Field Label**: Correlation ID
- **Field Name**: Correlation_Id\_\_c
- **Data Type**: Text
- **Length**: 50
- **Unique**: No
- **Required**: No

#### 5. Context\_\_c (Long Text Area)

- **Field Label**: Context
- **Field Name**: Context\_\_c
- **Data Type**: Long Text Area
- **Length**: 32,768
- **Visible Lines**: 3
- **Required**: No

#### 6. Retry_Count\_\_c (Number)

- **Field Label**: Retry Count
- **Field Name**: Retry_Count\_\_c
- **Data Type**: Number
- **Length**: 3
- **Decimal Places**: 0
- **Default Value**: 0
- **Required**: No

#### 7. Status\_\_c (Picklist - Required)

- **Field Label**: Status
- **Field Name**: Status\_\_c
- **Data Type**: Picklist
- **Values**:
  - NEW (default)
  - RETRYING
  - RESOLVED
  - FAILED
- **Required**: Yes
- **Default**: NEW

#### 8. Timestamp\_\_c (Date/Time - Required)

- **Field Label**: Timestamp
- **Field Name**: Timestamp\_\_c
- **Data Type**: Date/Time
- **Required**: Yes

### Step 3: Set Field-Level Security

For each field, set **Visible** for:

- System Administrator
- Elaro Admin (if exists)

### Step 4: Create Page Layout

1. Edit the **Integration Error Layout**
2. Add all fields to the layout
3. Organize sections:
   - **Error Information**: Error_Type**c, Error_Message**c, Status\_\_c
   - **Technical Details**: Stack_Trace**c, Correlation_Id**c, Context\_\_c
   - **Tracking**: Timestamp**c, Retry_Count**c

### Step 5: Grant Object Permissions

1. Navigate to **Setup** → **Permission Sets** → **Elaro_Admin**
2. Add **Integration_Error\_\_c** object permissions:
   - Read: ✓
   - Create: ✓
   - Edit: ✓
   - Delete: ✓
   - View All: ✓
   - Modify All: ✓

---

## Option 2: Deploy via Metadata (Alternative)

If you prefer to deploy via metadata, the object definition file already exists at:

```
force-app/main/default/objects/Integration_Error__c/Integration_Error__c.object-meta.xml
```

However, you'll need to create individual field metadata files in:

```
force-app/main/default/objects/Integration_Error__c/fields/
```

Then deploy:

```bash
sf project deploy start --source-dir force-app/main/default/objects/Integration_Error__c/
```

---

## After Creating the Object

### Uncomment Error Logging Code

Once the object is created, uncomment the error logging code in these files:

1. **PerformanceAlertPublisher.cls** (lines 65-80)
2. **ElaroGraphIndexer.cls** (lines 137-152)
3. **SlackNotifier.cls** (lines 321-336)

### Redeploy Classes

```bash
sf project deploy start --source-dir force-app/main/default/classes/PerformanceAlertPublisher.cls
sf project deploy start --source-dir force-app/main/default/classes/ElaroGraphIndexer.cls
sf project deploy start --source-dir force-app/main/default/classes/SlackNotifier.cls
```

---

## Verification

After creation, verify the object exists:

```bash
sf project retrieve start --metadata CustomObject:Integration_Error__c
```

This should successfully retrieve the object and all its fields.

---

_Guide created: January 2026_
