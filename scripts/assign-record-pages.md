# Assign Record Pages to Custom Objects

## Step-by-Step Instructions

### 1. Assign Record Pages (via UI)

For each of the 4 new custom objects:

1. **Compliance Evidence**
   - Go to: Setup → Object Manager → Compliance Evidence
   - Click "Lightning Record Pages" in the left sidebar
   - Find "Compliance Evidence Record Page"
   - Click the dropdown (3 dots) → "Set as Org Default"

2. **Compliance Gap**
   - Go to: Setup → Object Manager → Compliance Gap
   - Click "Lightning Record Pages" in the left sidebar
   - Find "Compliance Gap Record Page"
   - Click the dropdown (3 dots) → "Set as Org Default"

3. **Metadata Change**
   - Go to: Setup → Object Manager → Metadata Change
   - Click "Lightning Record Pages" in the left sidebar
   - Find "Metadata Change Record Page"
   - Click the dropdown (3 dots) → "Set as Org Default"

4. **Vendor Compliance**
   - Go to: Setup → Object Manager → Vendor Compliance
   - Click "Lightning Record Pages" in the left sidebar
   - Find "Vendor Compliance Record Page"
   - Click the dropdown (3 dots) → "Set as Org Default"

### 2. Field Visibility (Optional)

If you need to hide specific fields:

1. Go to: Setup → Object Manager → [Object Name]
2. Click "Fields & Relationships"
3. Click on a field
4. Under "Field-Level Security", uncheck profiles/permission sets as needed
5. Click "Save"

**Note:** By default, all fields are visible. Only customize if you need to restrict access.

### 3. Test the Dashboard

1. Go to: App Launcher → Elaro
2. Navigate to the "Elaro Compliance Hub" tab
3. You should see all 9 new components:
   - Compliance Dashboard
   - Framework Selector
   - Compliance Score Card
   - Compliance Gap List
   - Executive KPI Dashboard
   - Compliance Trend Chart
   - Risk Heatmap
   - Compliance Timeline
   - Audit Report Generator

## Quick Links

- Object Manager: `/lightning/setup/ObjectManager/home`
- Compliance Evidence: `/lightning/setup/ObjectManager/Compliance_Evidence__c/Details/view`
- Compliance Gap: `/lightning/setup/ObjectManager/Compliance_Gap__c/Details/view`
- Metadata Change: `/lightning/setup/ObjectManager/Metadata_Change__c/Details/view`
- Vendor Compliance: `/lightning/setup/ObjectManager/Vendor_Compliance__c/Details/view`
- Elaro App: `/lightning/n/Elaro`
