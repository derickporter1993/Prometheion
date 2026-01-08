# How to Access the Prometheion Compliance Dashboard

## ✅ Dashboard is Now Deployed and Accessible!

---

## 🚀 Access Methods

### Method 1: Via Prometheion App (Recommended)
1. Click the **App Launcher** (9-dot menu) in the top-left corner
2. Search for **"Prometheion"**
3. Click on **Prometheion** app
4. You should see a new tab: **"Compliance Dashboard"**
5. Click the **"Compliance Dashboard"** tab

### Method 2: Direct Tab Access
1. Click the **App Launcher**
2. Search for **"Compliance Dashboard"**
3. Click on it directly

### Method 3: Via Setup (If tab not visible)
1. Go to **Setup** → **Lightning App Builder**
2. Search for **"Prometheion Compliance Hub Minimal"**
3. Click **Edit**
4. The dashboard component should be visible on the page
5. Click **Save** → **Activate**

---

## 🧪 Testing the Framework Features

Once you're on the Compliance Dashboard page:

### 1. Verify All 10 Frameworks
- You should see **10 framework cards** in a grid layout
- Each card shows: Framework name, score percentage, progress bar

### 2. Test Framework Filter
- Look for **"Filter by Framework"** dropdown above the cards
- Select different frameworks to filter the view
- Select **"All Frameworks"** to show all 10

### 3. Test Drill-Down
- **Click any framework card** (e.g., HIPAA)
- You should see:
  - **"← Back to All Frameworks"** button
  - Large framework detail view with description and score
- Click **"Back"** to return to grid view

### 4. Test Risk Filtering
- Click a framework (e.g., SOX)
- Scroll to **"Top Risks"** section
- Risks should be filtered to that framework only

---

## 📋 Quick Checklist

- [ ] Prometheion app is accessible
- [ ] "Compliance Dashboard" tab appears
- [ ] Dashboard loads without errors
- [ ] All 10 framework cards are visible
- [ ] Framework filter dropdown works
- [ ] Framework cards are clickable
- [ ] Drill-down views work
- [ ] "Back" button works
- [ ] Risk filtering works

---

## 🔧 If Tab Doesn't Appear

### Option A: Add Tab Manually
1. **Setup** → **App Manager**
2. Find **Prometheion** app
3. Click **▼** → **Edit**
4. Go to **Navigation Items**
5. Find **"Compliance Dashboard"** in Available Items
6. Move it to **Selected Items**
7. Click **Save**

### Option B: Use Lightning App Builder
1. **Setup** → **Lightning App Builder**
2. Click **New** → **App Page**
3. Name it: **"Compliance Dashboard"**
4. Drag **"Prometheion Dashboard"** component onto the page
5. Click **Save** → **Activate**
6. Assign to Prometheion app navigation

---

## 🎯 Expected Frameworks

When viewing the dashboard, you should see these 10 frameworks:

1. **HIPAA** (Indigo)
2. **SOC 2** (Purple)
3. **NIST** (Purple)
4. **FedRAMP** (Cyan)
5. **GDPR** (Green)
6. **SOX** (Amber)
7. **PCI-DSS** (Red)
8. **CCPA** (Cyan)
9. **GLBA** (Green)
10. **ISO 27001** (Purple)

---

## ✅ Verification

All 30 compliance policies are active and deployed. The dashboard should now be accessible through the Prometheion app!

**Next Step:** Open the Prometheion app and click the "Compliance Dashboard" tab to test the framework filtering and drill-down features.
