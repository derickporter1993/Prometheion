# Elaro API Key Setup Guide

**Purpose:** Step-by-step guide to obtain and configure your Anthropic Claude API key for Elaro AI Copilot

## Overview

Elaro's AI Copilot requires an Anthropic Claude API key to function. This guide walks you through:
1. Creating an Anthropic account
2. Generating an API key
3. Configuring it in Salesforce
4. Testing the configuration

---

## Step 1: Create Anthropic Account

### 1.1 Sign Up
1. Go to **https://console.anthropic.com/**
2. Click **Sign Up** or **Get Started**
3. Enter your email address
4. Verify your email (check inbox)
5. Complete account setup

### 1.2 Add Payment Method (Required)
- Anthropic requires a payment method for API access
- Go to **Settings → Billing**
- Add a credit card or payment method
- **Note:** You'll only be charged for actual API usage

**Pricing:** Claude API pricing varies by model:
- Claude 3 Opus: ~$15 per 1M input tokens, ~$75 per 1M output tokens
- Claude 3 Sonnet: ~$3 per 1M input tokens, ~$15 per 1M output tokens
- Claude 3 Haiku: ~$0.25 per 1M input tokens, ~$1.25 per 1M output tokens

**Elaro uses:** Claude 3 Sonnet (default) and Claude 4 Opus (for Deep Analysis)

---

## Step 2: Generate API Key

### 2.1 Navigate to API Keys
1. Log in to **https://console.anthropic.com/**
2. Click your profile/account icon (top right)
3. Select **API Keys** from dropdown
4. Or go directly to: **https://console.anthropic.com/settings/keys**

### 2.2 Create New API Key
1. Click **Create Key** button
2. Enter a name (e.g., "Elaro Salesforce Production")
3. Select permissions:
   - ✅ **Read** (required)
   - ✅ **Write** (required for API calls)
4. Click **Create Key**

### 2.3 Copy API Key
1. **IMPORTANT:** Copy the API key immediately
2. It will look like: `sk-ant-api03-...` (starts with `sk-ant-`)
3. **Save it securely** - you won't be able to see it again!
4. If you lose it, you'll need to create a new key

**Security Best Practices:**
- ✅ Store in password manager
- ✅ Don't commit to version control
- ✅ Don't share in screenshots or emails
- ✅ Rotate keys periodically

---

## Step 3: Configure in Salesforce

### 3.1 Navigate to Custom Metadata Types
1. Log in to your Salesforce org
2. Click **Setup** (gear icon, top right)
3. In Quick Find, type: **Custom Metadata Types**
4. Click **Custom Metadata Types**

### 3.2 Access Elaro Claude Settings
1. Find **Elaro Claude Settings** in the list
2. Click **Elaro Claude Settings**
3. Click **Manage Elaro Claude Settings** button
4. You should see an empty list (or existing records)

### 3.3 Create New Record
1. Click **New** button
2. Fill in the form:

   **Label:**
   ```
   Default
   ```

   **Developer Name:**
   ```
   Default
   ```
   (This auto-populates from Label - must be exactly "Default")

   **API Key:**
   ```
   sk-ant-api03-...your-actual-key-here...
   ```
   (Paste your full API key from Anthropic)

3. Click **Save**

### 3.4 Verify Configuration
1. You should see the "Default" record in the list
2. The API Key field will show as **protected** (masked)
3. You can click **Edit** to verify it's saved (but won't see the full key)

---

## Step 4: Test Configuration

### 4.1 Test via Elaro Copilot
1. Navigate to **Elaro** app
2. Go to **Compliance Hub** tab
3. Scroll to **Elaro Copilot** component
4. Type a test query: `"What is my compliance score?"`
5. Press Enter or click Send

**Expected Results:**
- ✅ Query sends successfully
- ✅ Loading indicator appears
- ✅ Response displays (not an error)
- ✅ Response is relevant to your query

**If Error Occurs:**
- See Troubleshooting section below

### 4.2 Test Deep Analysis (Optional)
1. In Copilot, click **Deep Analysis** button
2. Wait 30-60 seconds for analysis
3. Verify results display with:
   - Executive Summary
   - AI Thinking Process
   - Key Findings
   - Evidence cards

---

## Step 5: Verify API Key is Working

### 5.1 Check Apex Debug Logs
1. Go to **Setup → Debug Logs**
2. Create a new trace flag for your user
3. Set log level to **FINEST** for Apex classes
4. Use Copilot again
5. Check logs for:
   - ✅ No "API key not configured" errors
   - ✅ Successful HTTP callouts to Anthropic
   - ✅ Response received from API

### 5.2 Check Browser Console
1. Open Elaro Copilot
2. Open browser Developer Tools (F12)
3. Go to **Console** tab
4. Send a query
5. Verify:
   - ✅ No JavaScript errors
   - ✅ No network errors
   - ✅ Response received

---

## Troubleshooting

### Issue: "API key not configured" Error

**Symptoms:**
- Copilot shows error message
- No responses from AI
- Error in browser console

**Solutions:**

1. **Verify Custom Metadata Record Exists**
   - Go to Setup → Custom Metadata Types → Elaro Claude Settings
   - Verify "Default" record exists
   - If not, create it (see Step 3)

2. **Verify Developer Name is "Default"**
   - The code looks for `Elaro_Claude_Settings__mdt.getInstance('Default')`
   - Developer Name must be exactly "Default" (case-sensitive)
   - Edit the record and verify Developer Name

3. **Verify API Key is Populated**
   - Edit the "Default" record
   - Verify API Key field has a value
   - Re-save if needed

4. **Check Apex Debug Logs**
   - Setup → Debug Logs
   - Look for errors in `ElaroClaudeService`
   - Check for "Custom Metadata not available" warnings

5. **Verify API Key Format**
   - Should start with `sk-ant-`
   - Should be long (50+ characters)
   - No extra spaces or line breaks

### Issue: "Invalid API Key" Error

**Symptoms:**
- API key is configured but requests fail
- HTTP 401 errors in logs
- "Authentication failed" messages

**Solutions:**

1. **Verify API Key is Valid**
   - Go to Anthropic Console
   - Check if key is active
   - Verify key hasn't been revoked
   - Create a new key if needed

2. **Check API Key Permissions**
   - In Anthropic Console, verify key has Read/Write permissions
   - Regenerate key if permissions are wrong

3. **Verify No Extra Characters**
   - Copy API key again from Anthropic
   - Paste into Salesforce (no spaces before/after)
   - Save and test again

### Issue: "Rate Limit Exceeded" Error

**Symptoms:**
- Some requests work, others fail
- HTTP 429 errors
- "Too many requests" messages

**Solutions:**

1. **Check API Usage**
   - Go to Anthropic Console → Usage
   - Check current usage vs limits
   - Verify billing is set up

2. **Implement Rate Limiting**
   - Add delays between requests
   - Cache responses when possible
   - Use Platform Cache for frequent queries

3. **Upgrade Plan** (if needed)
   - Check Anthropic pricing plans
   - Upgrade if hitting free tier limits

### Issue: Custom Metadata Not Found

**Symptoms:**
- "Custom Metadata not available" in logs
- API key lookup fails
- Fallback to null

**Solutions:**

1. **Verify Custom Metadata Type is Deployed**
   ```bash
   # Check if deployed
   sf project deploy start --dry-run -o prod-org
   ```

2. **Redeploy Custom Metadata Type**
   ```bash
   # Deploy just the Custom Metadata Type
   sf project deploy start --source-dir force-app/main/default/objects/Elaro_Claude_Settings__mdt -o prod-org
   ```

3. **Check API Version**
   - Verify Custom Metadata Type uses compatible API version
   - Check `ElaroClaudeService` API version matches

---

## Security Best Practices

### ✅ DO:
- Store API key in Custom Metadata (not hardcoded)
- Use Protected Custom Metadata fields
- Rotate keys periodically (every 90 days)
- Monitor API usage in Anthropic Console
- Set up billing alerts
- Use different keys for dev/prod orgs

### ❌ DON'T:
- Commit API keys to version control
- Share keys in emails or Slack
- Use same key across multiple orgs
- Leave keys in debug logs
- Hardcode keys in Apex classes

---

## Alternative: Using Named Credentials (Advanced)

For enhanced security, you can use Salesforce Named Credentials instead of Custom Metadata:

### Benefits:
- ✅ More secure (encrypted at rest)
- ✅ Can use OAuth flows
- ✅ Better for enterprise deployments

### Setup:
1. Setup → Named Credentials
2. Create new Named Credential
3. Name: `Anthropic_API`
4. URL: `https://api.anthropic.com`
5. Identity Type: Named Principal
6. Authentication Protocol: Password Authentication
7. Username: Your API key
8. Update `ElaroClaudeService` to use Named Credential

**Note:** This requires code changes to `ElaroClaudeService.cls`

---

## Testing Without API Key

If you want to test Elaro **without** an API key:

### What Works:
- ✅ Compliance Dashboard (all features)
- ✅ Compliance Score calculation
- ✅ Framework scores
- ✅ Score breakdown
- ✅ Top risks
- ✅ Refresh functionality

### What Doesn't Work:
- ❌ AI Copilot queries
- ❌ Deep Analysis
- ❌ AI-generated evidence
- ❌ AI recommendations

**Error Message:** Copilot will show "API key not configured" when you try to use it.

---

## Quick Reference

### API Key Format
```
sk-ant-api03-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Custom Metadata Record
- **Type:** Elaro_Claude_Settings__mdt
- **Developer Name:** Default (required)
- **Field:** API_Key__c
- **Value:** Your Anthropic API key

### Test Query
```
"What is my compliance score?"
```

### Verification Steps
1. ✅ Custom Metadata record exists
2. ✅ Developer Name = "Default"
3. ✅ API Key field populated
4. ✅ Copilot responds (not error)
5. ✅ Debug logs show successful callouts

---

## Support Resources

- **Anthropic Console:** https://console.anthropic.com/
- **Anthropic API Docs:** https://docs.anthropic.com/
- **Anthropic Pricing:** https://www.anthropic.com/pricing
- **Salesforce Custom Metadata:** https://help.salesforce.com/s/articleView?id=sf.custommetadatatypes_overview.htm

---

## Next Steps

After configuring API key:
1. ✅ Test basic Copilot queries
2. ✅ Test Deep Analysis feature
3. ✅ Review API usage in Anthropic Console
4. ✅ Set up billing alerts
5. ✅ Document key rotation schedule

---

**Last Updated:** December 18, 2025  
**Version:** 1.0

