# Elaro Testing Checklist

**Date:** December 18, 2025  
**Purpose:** Complete step-by-step guide to configure and test Elaro

## Pre-Testing Setup (Required)

### Step 1: Verify Deployment ✅
- [ ] All Apex classes deployed successfully
- [ ] All Lightning Web Components deployed successfully
- [ ] Custom Metadata Type `Elaro_Claude_Settings__mdt` exists
- [ ] Permission Set `Elaro_Admin` exists
- [ ] Application `Elaro` exists
- [ ] Tab `Elaro_Compliance_Hub` exists
- [ ] FlexiPage `Elaro_Compliance_Hub` exists

**Verification:**
```bash
# Check deployment status
cd /Users/derickporter/salesforce-projects/Solentra
sf project deploy start --dry-run -o prod-org
```

### Step 2: Configure Claude API Key (Required for AI Features)

1. **Obtain API Key**
   - [ ] Sign up at https://console.anthropic.com/
   - [ ] Navigate to API Keys section
   - [ ] Create new API key
   - [ ] Copy key (save securely - won't be visible again)

2. **Create Custom Metadata Record**
   - [ ] Navigate to: **Setup → Custom Metadata Types**
   - [ ] Click **Elaro Claude Settings**
   - [ ] Click **Manage Elaro Claude Settings**
   - [ ] Click **New**
   - [ ] Fill in:
     - **Label:** `Default`
     - **Developer Name:** `Default` (auto-filled)
     - **API Key:** Paste your Anthropic API key
   - [ ] Click **Save**

3. **Verify Configuration**
   - [ ] Navigate back to Custom Metadata Types
   - [ ] Verify "Default" record exists
   - [ ] API Key field should show as protected/masked

**Note:** Without this step, AI Copilot will show "API key not configured" errors.

### Step 3: Assign Permission Sets

1. **Assign Elaro Admin**
   - [ ] Navigate to: **Setup → Users → Permission Sets**
   - [ ] Find **Elaro Admin**
   - [ ] Click **Elaro Admin**
   - [ ] Click **Manage Assignments**
   - [ ] Click **Add Assignments**
   - [ ] Select users who need access (start with yourself)
   - [ ] Click **Assign**
   - [ ] Click **Done**

2. **Verify Assignment**
   - [ ] Log in as assigned user
   - [ ] Check App Launcher for "Elaro" app
   - [ ] Verify app appears in available apps

### Step 4: Verify Application Access

1. **Access Elaro App**
   - [ ] Click **App Launcher** (9-dot menu)
   - [ ] Search for **Elaro**
   - [ ] Click **Elaro** app
   - [ ] Verify app opens without errors

2. **Verify Tab Access**
   - [ ] In Elaro app, verify **Compliance Hub** tab appears
   - [ ] Click **Compliance Hub** tab
   - [ ] Verify page loads (may show loading state initially)

---

## Testing Phase 1: Compliance Dashboard

### Test 1.1: Dashboard Load & Display

**Test Steps:**
1. [ ] Navigate to **Elaro → Compliance Hub**
2. [ ] Wait for dashboard to load (should show loading spinner initially)
3. [ ] Verify dashboard displays without errors

**Expected Results:**
- ✅ Dashboard loads within 5-10 seconds
- ✅ No error messages in browser console
- ✅ No Apex errors in debug logs
- ✅ Overall compliance score displays (0-100)
- ✅ Score rating badge displays (Excellent/Good/Fair/Critical)

**Verification:**
- Open browser Developer Tools (F12)
- Check Console tab for errors
- Check Network tab for failed requests

### Test 1.2: Overall Score Display

**Test Steps:**
1. [ ] Verify overall score displays in center ring
2. [ ] Verify score is between 0-100
3. [ ] Verify rating badge displays below score
4. [ ] Verify "Last updated" timestamp displays

**Expected Results:**
- ✅ Score ring displays with gradient colors
- ✅ Score value is visible and readable
- ✅ Rating badge has appropriate color (green/yellow/red)
- ✅ Last updated time shows current time

### Test 1.3: Framework Scores

**Test Steps:**
1. [ ] Verify Framework Compliance section displays
2. [ ] Verify all 5 frameworks show:
   - HIPAA
   - SOC 2
   - NIST
   - FedRAMP
   - GDPR
3. [ ] Verify each framework shows:
   - Framework name
   - Score percentage (0-100%)
   - Progress bar

**Expected Results:**
- ✅ All 5 frameworks display
- ✅ Each framework has a score (may be 0 if no data)
- ✅ Progress bars are visible and colored appropriately
- ✅ Scores are formatted as percentages

### Test 1.4: Score Breakdown (Factors)

**Test Steps:**
1. [ ] Scroll to Score Breakdown section
2. [ ] Verify factors display in grid layout
3. [ ] Verify each factor shows:
   - Factor name
   - Status badge (Excellent/Good/Warning/Critical)
   - Score (X/100)
   - Progress bar
   - Detail description
   - Weight percentage
   - Contribution score

**Expected Results:**
- ✅ Multiple factors display (Permission Sprawl, Documentation, etc.)
- ✅ Status badges have appropriate colors
- ✅ Progress bars are visible
- ✅ All information is readable

### Test 1.5: Top Risks Section

**Test Steps:**
1. [ ] Scroll to Top Risks section (if risks exist)
2. [ ] Verify risks display in list format
3. [ ] Verify each risk shows:
   - Severity badge (Critical/High/Medium/Low)
   - Risk title
   - Risk description
   - Framework tag
   - "View Details" button

**Expected Results:**
- ✅ Risks display (or "No risks" message if none exist)
- ✅ Severity badges are color-coded
- ✅ Risk information is readable
- ✅ "View Details" buttons are clickable

**Note:** If no risks exist, this section may not display.

### Test 1.6: Refresh Functionality

**Test Steps:**
1. [ ] Click **Refresh** button in header
2. [ ] Verify loading spinner appears
3. [ ] Verify dashboard refreshes
4. [ ] Verify "Last updated" timestamp updates
5. [ ] Verify scores recalculate

**Expected Results:**
- ✅ Refresh button is clickable
- ✅ Loading state displays during refresh
- ✅ Data updates after refresh
- ✅ No errors occur during refresh

### Test 1.7: Quick Actions

**Test Steps:**
1. [ ] Scroll to bottom of dashboard
2. [ ] Verify "Generate SOC2 Report" button displays
3. [ ] Verify "Generate HIPAA Report" button displays
4. [ ] Click each button
5. [ ] Verify toast message appears ("Coming Soon")

**Expected Results:**
- ✅ Both action buttons display
- ✅ Buttons are clickable
- ✅ Toast notifications appear
- ✅ No errors occur

---

## Testing Phase 2: AI Copilot

### Test 2.1: Copilot Component Load

**Test Steps:**
1. [ ] In Compliance Hub, scroll to Elaro Copilot component
2. [ ] Verify copilot component loads
3. [ ] Verify welcome message displays

**Expected Results:**
- ✅ Copilot component renders
- ✅ Welcome section displays with:
  - Elaro logo/icon
  - "How can I help with compliance today?" heading
  - Subtitle text
  - Quick command buttons grid

### Test 2.2: Quick Commands

**Test Steps:**
1. [ ] Verify 6 quick command buttons display:
   - "Why did my score drop?"
   - "Show me risky Flows"
   - "Generate HIPAA evidence"
   - "Who has elevated access?"
   - "SOC2 compliance status"
   - "Show recent violations"
2. [ ] Click each quick command button
3. [ ] Verify query is sent to Copilot

**Expected Results:**
- ✅ All 6 quick commands display
- ✅ Buttons are clickable
- ✅ Clicking sends query to Copilot
- ✅ Loading state appears
- ✅ Response displays (or error if API key not configured)

### Test 2.3: Manual Query Input

**Test Steps:**
1. [ ] Type a query in the input field (e.g., "What is my compliance score?")
2. [ ] Press Enter or click Send button
3. [ ] Verify query appears in chat
4. [ ] Verify loading indicator appears
5. [ ] Verify response displays

**Expected Results:**
- ✅ Input field accepts text
- ✅ Send button is clickable
- ✅ User message appears in chat
- ✅ Loading indicator shows
- ✅ Response displays (or error message)

**Error Cases to Test:**
- [ ] Empty query (should not send)
- [ ] Very long query (should handle gracefully)
- [ ] Special characters (should handle correctly)

### Test 2.4: API Key Configuration Test

**Without API Key:**
- [ ] Send a query
- [ ] Verify error message displays: "API key not configured"
- [ ] Verify error is user-friendly

**With API Key:**
- [ ] Send a query
- [ ] Verify response displays
- [ ] Verify response is relevant to query
- [ ] Verify response includes compliance information

### Test 2.5: Deep Analysis Feature

**Test Steps:**
1. [ ] Click **Deep Analysis** button
2. [ ] Verify analysis starts
3. [ ] Verify loading indicator appears
4. [ ] Wait for analysis to complete (30-60 seconds)
5. [ ] Verify results display with:
   - Executive Summary
   - AI Thinking Process
   - Key Findings
   - Evidence cards
   - Action buttons

**Expected Results:**
- ✅ Deep Analysis button is clickable
- ✅ Analysis runs successfully
- ✅ Results display in structured format
- ✅ All sections are readable
- ✅ Evidence cards show risk scores

**Note:** Requires valid API key and may take 30-60 seconds.

### Test 2.6: Chat History

**Test Steps:**
1. [ ] Send multiple queries
2. [ ] Verify all messages display in chat
3. [ ] Verify user messages appear on right
4. [ ] Verify assistant messages appear on left
5. [ ] Verify timestamps display (if implemented)
6. [ ] Scroll through chat history

**Expected Results:**
- ✅ All messages persist in chat
- ✅ Messages are properly formatted
- ✅ Chat scrolls correctly
- ✅ No messages disappear

### Test 2.7: Clear Chat

**Test Steps:**
1. [ ] Send several queries
2. [ ] Click **Clear Chat** button (trash icon in header)
3. [ ] Verify all messages are cleared
4. [ ] Verify welcome screen reappears

**Expected Results:**
- ✅ Clear Chat button works
- ✅ All messages are removed
- ✅ Welcome screen displays
- ✅ Can start new conversation

### Test 2.8: Error Handling

**Test Cases:**
- [ ] Send query with API key not configured
- [ ] Send query with invalid API key
- [ ] Send query during network error
- [ ] Send query that times out

**Expected Results:**
- ✅ Error messages are user-friendly
- ✅ Errors don't crash the component
- ✅ User can retry after error
- ✅ Error details logged for debugging

---

## Testing Phase 3: Integration & Edge Cases

### Test 3.1: Multiple Users

**Test Steps:**
1. [ ] Assign permission set to multiple users
2. [ ] Each user logs in
3. [ ] Each user accesses Elaro
4. [ ] Each user tests dashboard and copilot

**Expected Results:**
- ✅ All users can access Elaro
- ✅ Each user sees their own compliance data
- ✅ No permission errors
- ✅ No data leakage between users

### Test 3.2: Browser Compatibility

**Test Browsers:**
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)

**Expected Results:**
- ✅ All components render correctly
- ✅ No JavaScript errors
- ✅ Styling is consistent
- ✅ Functionality works in all browsers

### Test 3.3: Mobile Responsiveness

**Test Steps:**
1. [ ] Open Elaro on mobile device
2. [ ] Or resize browser to mobile width
3. [ ] Test dashboard display
4. [ ] Test copilot interface

**Expected Results:**
- ✅ Layout adapts to mobile screen
- ✅ Text is readable
- ✅ Buttons are clickable
- ✅ No horizontal scrolling needed

### Test 3.4: Performance

**Test Steps:**
1. [ ] Measure dashboard load time
2. [ ] Measure copilot response time
3. [ ] Test with large datasets
4. [ ] Monitor browser console for warnings

**Expected Results:**
- ✅ Dashboard loads in < 5 seconds
- ✅ Copilot responds in < 10 seconds (with API)
- ✅ No performance warnings
- ✅ Smooth scrolling and interactions

### Test 3.5: Governor Limits

**Test Steps:**
1. [ ] Monitor Apex debug logs
2. [ ] Check SOQL query counts
3. [ ] Check DML statement counts
4. [ ] Verify no governor limit errors

**Expected Results:**
- ✅ SOQL queries stay under limit (100)
- ✅ DML statements stay under limit (150)
- ✅ CPU time stays under limit (10,000ms)
- ✅ Heap size stays under limit (6MB)

---

## Testing Phase 4: Data Validation

### Test 4.1: Compliance Score Calculation

**Test Steps:**
1. [ ] Review score calculation logic
2. [ ] Verify score factors are weighted correctly
3. [ ] Verify framework scores are calculated correctly
4. [ ] Compare scores with manual calculation

**Expected Results:**
- ✅ Scores match expected values
- ✅ Weighting is applied correctly
- ✅ Framework scores are accurate
- ✅ Overall score is weighted average

### Test 4.2: Permission Sprawl Detection

**Test Steps:**
1. [ ] Review permission sets in org
2. [ ] Verify permission sprawl score reflects actual state
3. [ ] Check for users with Modify All Data
4. [ ] Check for users with View All Data

**Expected Results:**
- ✅ Permission sprawl score is accurate
- ✅ Elevated permissions are detected
- ✅ Score reflects actual risk level

### Test 4.3: Documentation Score

**Test Steps:**
1. [ ] Review permission sets with descriptions
2. [ ] Verify documentation score reflects documented vs undocumented
3. [ ] Check that documented permission sets increase score

**Expected Results:**
- ✅ Documentation score is accurate
- ✅ Documented permission sets are counted
- ✅ Undocumented permission sets reduce score

---

## Post-Testing Checklist

### Documentation
- [ ] Document any bugs found
- [ ] Document any performance issues
- [ ] Document any user experience issues
- [ ] Create bug reports for critical issues

### Configuration Verification
- [ ] API key is configured correctly
- [ ] Permission sets are assigned correctly
- [ ] Application is accessible to all users
- [ ] All components are deployed

### User Acceptance
- [ ] Get feedback from compliance team
- [ ] Get feedback from security team
- [ ] Get feedback from executives
- [ ] Address any concerns

---

## Troubleshooting Guide

### Issue: Dashboard doesn't load
**Solutions:**
1. Check browser console for errors
2. Check Apex debug logs
3. Verify `ElaroComplianceScorer` is deployed
4. Verify user has permission set assigned

### Issue: Copilot shows "API key not configured"
**Solutions:**
1. Verify Custom Metadata record exists
2. Verify Developer Name is "Default"
3. Verify API Key field is populated
4. Check Apex debug logs for errors

### Issue: Permission denied errors
**Solutions:**
1. Assign Elaro Admin permission set
2. Verify user has access to Elaro app
3. Check object-level permissions
4. Check field-level permissions

### Issue: Scores are 0 or incorrect
**Solutions:**
1. Check if org has permission sets
2. Verify permission sets have descriptions
3. Check Apex debug logs for calculation errors
4. Verify SOQL queries are executing correctly

---

## Success Criteria

✅ **All tests pass:**
- Dashboard loads and displays correctly
- All components render without errors
- AI Copilot responds to queries (with API key)
- All functionality works as expected
- No critical bugs found
- Performance is acceptable

✅ **Ready for production:**
- All configuration complete
- All users have access
- All features tested
- Documentation complete
- User training scheduled

---

**Last Updated:** December 18, 2025  
**Version:** 1.0

