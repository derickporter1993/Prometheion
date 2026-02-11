# Quick Test Guide - Framework Filtering & Drill-Down

## ✅ Dashboard Successfully Deployed!

The `elaroDashboard` component is now deployed and ready to test.

---

## 🚀 Access Methods

### Option 1: Minimal Compliance Hub Page (Recommended)

1. **App Launcher** → Search **"Elaro Compliance Hub Minimal"**
2. Or use direct URL: `https://[your-instance].salesforce.com/lightning/n/Elaro_Compliance_Hub_Minimal`

### Option 2: Add Component to Any Lightning Page

1. Navigate to any Lightning App Page or Home Page
2. Click **⚙️ Settings** → **Edit Page**
3. In the component palette, search for **"Elaro Dashboard"**
4. Drag it onto the page
5. Click **Save** → **Activate**

### Option 3: Test in Developer Console

1. Open **Developer Console** (Setup → Developer Console)
2. Go to **File** → **New** → **Lightning Component**
3. Use component: `c:elaroDashboard`

---

## 🧪 Testing Framework Filtering

### Step 1: Verify All 10 Frameworks Display

1. Open the dashboard
2. In the **"Framework Compliance"** section, you should see:
   - A dropdown labeled **"Filter by Framework"**
   - 10 framework cards in a grid below

### Step 2: Test Filter Dropdown

1. Click the **"Filter by Framework"** dropdown
2. You should see 11 options:
   - All Frameworks
   - HIPAA
   - SOC 2
   - NIST
   - FedRAMP
   - GDPR
   - SOX
   - PCI-DSS
   - CCPA
   - GLBA
   - ISO 27001

3. **Test each filter:**
   - Select **"HIPAA"** → Only HIPAA card should show
   - Select **"SOC 2"** → Only SOC 2 card should show
   - Select **"All Frameworks"** → All 10 cards should show

---

## 🔍 Testing Drill-Down Views

### Step 1: Click a Framework Card

1. With **"All Frameworks"** selected, click any framework card (e.g., **HIPAA**)
2. The view should change to show:
   - **"← Back to All Frameworks"** button at the top
   - Large framework detail card with:
     - Framework name (e.g., "HIPAA")
     - Framework description
     - Large score display (e.g., "85%")
     - Progress bar visualization

### Step 2: Test Navigation

1. Click **"← Back to All Frameworks"**
2. You should return to the grid view with all 10 frameworks

### Step 3: Test Framework-Specific Risks

1. Click on a framework (e.g., **SOX**)
2. Scroll to **"Top Risks"** section
3. Risks should be filtered to show only SOX-related risks
4. Return to "All Frameworks" to see all risks

---

## ✅ Verification Checklist

- [ ] Dashboard loads without errors
- [ ] All 10 framework cards are visible
- [ ] Framework filter dropdown works
- [ ] Each framework can be filtered individually
- [ ] Framework cards are clickable
- [ ] Drill-down view shows framework details
- [ ] "Back to All Frameworks" button works
- [ ] Framework-specific risk filtering works
- [ ] Scores display correctly (0-100%)
- [ ] Progress bars show correct colors

---

## 🐛 Troubleshooting

### If Dashboard Doesn't Load:

```bash
# Check for Apex errors
sf apex get log --target-org prod-org --number 5

# Verify component is deployed
sf project deploy report --job-id [deploy-id] --target-org prod-org
```

### If Filter Doesn't Work:

- Open browser **Developer Tools** (F12)
- Check **Console** tab for JavaScript errors
- Verify `ElaroComplianceScorer.calculateReadinessScore` is returning data

### If Scores Don't Show:

- The dashboard needs compliance data to calculate scores
- Run a compliance scan first, or scores will show as 0%
- Check that `calculateReadinessScore` Apex method is working

---

## 📊 Expected Framework Colors

When viewing all frameworks, you should see these colors:

- **HIPAA**: Indigo (#6366f1)
- **SOC 2**: Purple (#8b5cf6)
- **NIST**: Purple (#a855f7)
- **FedRAMP**: Cyan (#22d3ee)
- **GDPR**: Green (#10b981)
- **SOX**: Amber (#f59e0b)
- **PCI-DSS**: Red (#ef4444)
- **CCPA**: Cyan (#06b6d4)
- **GLBA**: Green (#84cc16)
- **ISO 27001**: Purple (#8b5cf6)

---

## 🎯 Quick Test Script

```bash
# 1. Open the minimal page
sf org open --target-org prod-org --path "lightning/n/Elaro_Compliance_Hub_Minimal"

# 2. Verify policies are active
sf data query --query "SELECT COUNT() FROM Compliance_Policy__mdt WHERE Is_Active__c = true" --target-org prod-org

# 3. Check dashboard component
sf project list metadata --metadata-type LightningComponentBundle --target-org prod-org | grep elaroDashboard
```

---

## ✨ Success Indicators

You'll know everything is working when:

1. ✅ Dashboard loads with framework cards
2. ✅ Filter dropdown shows all 11 options
3. ✅ Clicking a card shows drill-down view
4. ✅ "Back" button returns to grid
5. ✅ Risks filter by selected framework
6. ✅ All 10 frameworks have unique colors

**Happy Testing!** 🚀
