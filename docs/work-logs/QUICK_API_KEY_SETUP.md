# Quick API Key Setup - 5 Minutes

**Fastest way to get Elaro AI Copilot working**

## ⚡ Quick Steps (5 minutes)

### 1. Get API Key (2 minutes)
1. Go to **https://console.anthropic.com/**
2. Sign up or log in
3. Click **API Keys** (top right)
4. Click **Create Key**
5. Name it: `Elaro`
6. **Copy the key** (starts with `sk-ant-`)
7. **Save it** - you won't see it again!

### 2. Configure in Salesforce (2 minutes)
1. In Salesforce: **Setup** → Search **Custom Metadata Types**
2. Click **Elaro Claude Settings**
3. Click **Manage Elaro Claude Settings**
4. Click **New**
5. Fill in:
   - **Label:** `Default`
   - **API Key:** Paste your key
6. Click **Save**

### 3. Test (1 minute)
1. Open **Elaro** app
2. Go to **Compliance Hub**
3. In Copilot, type: `"What is my compliance score?"`
4. Press Enter
5. ✅ Should get a response!

---

## 🎯 What You Need

- ✅ Anthropic account (free to sign up)
- ✅ Payment method (for API usage - pay per use)
- ✅ Salesforce admin access
- ✅ 5 minutes

---

## 💰 Cost Estimate

**Typical Usage:**
- Simple queries: ~$0.01-0.05 each
- Deep Analysis: ~$0.10-0.50 each
- Monthly estimate: $10-50 for moderate use

**Free Tier:** None (pay per use)

---

## ❌ Troubleshooting

### "API key not configured"
→ Check Custom Metadata record exists with Developer Name = "Default"

### "Invalid API key"
→ Copy key again from Anthropic Console, paste fresh

### "Rate limit exceeded"
→ Check Anthropic Console → Usage, verify billing setup

---

## 📚 Full Guide

For detailed instructions, see **API_KEY_SETUP.md**

---

**Ready? Start with Step 1 above!** ⚡

