# GitHub Repository Setup Instructions

This document explains how to properly configure your GitHub repository to reflect Sentinel's new positioning as a **compliance-first Salesforce configuration drift guardrail**.

---

## 1. Rename the Repository

**Current Name**: `Ops-Gurdian` (or `Sentinel`)
**Recommended Name**: `sentinel-salesforce-compliance-drift-guard`

### Why This Name?

The new name immediately tells visitors:
1. **What it is**: Sentinel (product name)
2. **What platform**: Salesforce
3. **What it does**: Compliance + drift detection
4. **What category**: Guardrail (not a full GRC platform)

### How to Rename

1. Go to your GitHub repository
2. Click **Settings** (top right)
3. Scroll to **General** → **Repository name**
4. Change to: `sentinel-salesforce-compliance-drift-guard`
5. Click **Rename**

**⚠️ Important**: After renaming, update your local git remote:
```bash
git remote set-url origin https://github.com/YOUR_USERNAME/sentinel-salesforce-compliance-drift-guard.git
```

---

## 2. Update Repository Description

**Current Description**: (likely empty or generic)
**New Description**:
```
Compliance-first Salesforce configuration drift guardrail and audit evidence engine for regulated orgs.
```

### How to Update

1. Go to repository homepage
2. Click the **⚙️ Settings** icon next to "About" (top right of sidebar)
3. Paste the new description
4. Click **Save changes**

---

## 3. Add GitHub Topics (Tags)

Topics help people discover your repository. Add these 12 topics:

### Core Topics
- `salesforce`
- `compliance`
- `audit`
- `security`
- `governance`
- `drift-detection`

### Industry Topics
- `nonprofit`
- `regulated-industries`
- `healthcare`

### Compliance Frameworks
- `hipaa`
- `sox`
- `soc2`
- `gdpr`

### How to Add Topics

1. Go to repository homepage
2. Click the **⚙️ Settings** icon next to "About" (top right of sidebar)
3. In the **Topics** field, type each topic and press Enter
4. Click **Save changes**

---

## 4. Update Repository Social Preview Image

A good social preview image makes your repo stand out when shared on Twitter, LinkedIn, etc.

### Recommended Image

Create a 1280x640px image with:
- **Background**: Professional gradient (blue/purple)
- **Logo**: Sentinel logo (if available)
- **Tagline**: "Compliance-first Salesforce drift guardrail"
- **Visual**: Simple diagram showing Salesforce → Sentinel → Audit Report

### How to Add

1. Go to **Settings** → **General**
2. Scroll to **Social preview**
3. Click **Edit** → **Upload an image**
4. Upload your 1280x640px PNG/JPG
5. Click **Save**

**Don't have an image?** Use Canva (free) with template: "GitHub Social Preview"

---

## 5. Add Website URL

If you create a documentation site (e.g., GitHub Pages, GitBook), add it to your repo.

### Recommended Sites

- **GitHub Pages**: `https://YOUR_USERNAME.github.io/sentinel`
- **ReadTheDocs**: `https://sentinel.readthedocs.io`
- **Custom Domain**: `https://sentinel.dev`

### How to Add

1. Go to repository homepage
2. Click the **⚙️ Settings** icon next to "About"
3. Enter **Website** URL
4. Click **Save changes**

---

## 6. Enable GitHub Discussions

GitHub Discussions are great for community engagement (feature requests, Q&A, etc.).

### How to Enable

1. Go to **Settings** → **General**
2. Scroll to **Features**
3. Check ✅ **Discussions**
4. Click **Set up discussions**
5. Choose categories:
   - 💡 Feature Requests
   - 🙋 Q&A
   - 📣 Announcements
   - 🐛 Bug Reports (if not using Issues)

---

## 7. Create Repository Labels

Labels help organize Issues and Pull Requests. Create these custom labels:

### Compliance-Specific Labels

| Label | Color | Description |
|-------|-------|-------------|
| `compliance` | `#0052CC` | Compliance-related issues |
| `drift-detection` | `#5319E7` | Configuration drift features |
| `audit-evidence` | `#00875A` | Audit trail and evidence export |
| `hipaa` | `#FF5630` | HIPAA compliance features |
| `sox` | `#FF5630` | SOX compliance features |
| `soc2` | `#FF5630` | SOC 2 compliance features |
| `gdpr` | `#FF5630` | GDPR compliance features |

### Standard Labels (keep existing)

- `bug`
- `enhancement`
- `documentation`
- `good first issue`
- `help wanted`

### How to Add Labels

1. Go to **Issues** → **Labels**
2. Click **New label**
3. Enter name, color (hex code), and description
4. Click **Create label**

---

## 8. Update README Badges

Already done in the new README, but verify these badges work:

```markdown
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Salesforce API](https://img.shields.io/badge/Salesforce-v62.0+-blue.svg)](https://developer.salesforce.com)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-success.svg)](.github/workflows)
```

### Optional Badges to Add

- **Code Coverage**: `[![Coverage](https://img.shields.io/codecov/c/github/YOUR_USERNAME/sentinel)](https://codecov.io)`
- **Issues**: `[![GitHub issues](https://img.shields.io/github/issues/YOUR_USERNAME/sentinel)](https://github.com/YOUR_USERNAME/sentinel/issues)`
- **Contributors**: `[![Contributors](https://img.shields.io/github/contributors/YOUR_USERNAME/sentinel)](https://github.com/YOUR_USERNAME/sentinel/graphs/contributors)`

---

## 9. Create Issue Templates

Help users report bugs and request features with templates.

### Bug Report Template

Already exists at `.github/ISSUE_TEMPLATE/bug_report.md` (updated to reference Sentinel).

### Feature Request Template

Create `.github/ISSUE_TEMPLATE/feature_request.md`:

```markdown
---
name: Feature Request
about: Suggest a feature for Sentinel
labels: enhancement
---

**Problem Statement**
Describe the compliance/drift detection problem you're trying to solve.

**Proposed Solution**
How would you solve this problem?

**Who Benefits?**
- [ ] Compliance teams
- [ ] Auditors
- [ ] Salesforce admins
- [ ] Developers
- [ ] Other: _______

**Compliance Framework**
Which compliance framework is this related to?
- [ ] HIPAA
- [ ] SOC 2
- [ ] GDPR
- [ ] SOX
- [ ] Other: _______

**Additional Context**
Add any other context, screenshots, or examples.
```

---

## 10. Create CONTRIBUTING.md

Help contributors understand how to contribute.

### Sample CONTRIBUTING.md

Create `CONTRIBUTING.md` at repository root:

```markdown
# Contributing to Sentinel

Thank you for your interest in contributing to Sentinel!

## Ways to Contribute

- 🐛 Report bugs via [GitHub Issues](https://github.com/YOUR_USERNAME/sentinel/issues)
- 💡 Suggest features via [GitHub Discussions](https://github.com/YOUR_USERNAME/sentinel/discussions)
- 📖 Improve documentation
- 🧪 Add test coverage
- 🔧 Fix bugs or implement features

## Development Setup

See [README.md](README.md#development) for setup instructions.

## Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run tests: `npm run lint && npm run fmt:check`
5. Commit with clear message: `git commit -m "feat: add drift detection for sharing rules"`
6. Push to your fork: `git push origin feature/my-feature`
7. Open a Pull Request

## Code Style

- Follow existing code patterns
- Add tests for new features
- Update documentation
- Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`

## Priority Areas for v1

- Additional compliance framework support (ISO 27001, FedRAMP)
- Improved drift detection rules
- Test coverage for edge cases
- Documentation improvements

## Questions?

Ask in [GitHub Discussions](https://github.com/YOUR_USERNAME/sentinel/discussions).
```

---

## 11. Add LICENSE File

Confirm you have a LICENSE file (MIT is recommended for open-source projects).

### How to Add

If `LICENSE` doesn't exist:

1. Go to repository homepage
2. Click **Add file** → **Create new file**
3. Name it `LICENSE`
4. Click **Choose a license template**
5. Select **MIT License**
6. Click **Review and submit**
7. Commit the file

---

## 12. Create Security Policy

Add a SECURITY.md file to explain how to report security vulnerabilities.

### Sample SECURITY.md

Create `SECURITY.md` at repository root:

```markdown
# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Sentinel, please **DO NOT** open a public GitHub issue.

Instead, email: **security@sentinel.dev** (or your email)

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if available)

We will respond within **48 hours** and provide a timeline for a fix.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | ✅ Yes    |
| < 1.0   | ❌ No     |

## Security Best Practices

When deploying Sentinel:
- Use Named Credentials for API keys (never hardcode)
- Enable Shield Platform Encryption for sensitive data
- Restrict Sentinel_Admin permission set to authorized users only
- Review Sentinel's audit trail regularly
```

---

## 13. Enable Security Features

GitHub offers free security scanning for public repos.

### How to Enable

1. Go to **Settings** → **Security & analysis**
2. Enable:
   - ✅ **Dependency graph**
   - ✅ **Dependabot alerts**
   - ✅ **Dependabot security updates**
   - ✅ **Secret scanning** (if available)

---

## 14. Pin Important Issues

Pin 3-5 key issues/discussions to the top of your Issues/Discussions page.

### Recommended Pins

1. **"Welcome! Start here"** — Introduction to Sentinel
2. **"v1 Roadmap"** — Link to ROADMAP.md
3. **"Feature Requests"** — Link to Discussions
4. **"Known Issues"** — List of current bugs/limitations

### How to Pin

1. Go to **Issues** or **Discussions**
2. Open the issue/discussion you want to pin
3. Click **Pin issue** (right sidebar)
4. Repeat for up to 3 items

---

## 15. Update GitHub Actions Badge

If your CI/CD workflow is named something other than `ci.yml`, update the badge in README.

### Current Badge

```markdown
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-success.svg)](.github/workflows)
```

### Dynamic Badge (shows actual CI status)

```markdown
[![CI](https://github.com/YOUR_USERNAME/sentinel/workflows/CI/badge.svg)](https://github.com/YOUR_USERNAME/sentinel/actions)
```

Replace `YOUR_USERNAME` and ensure workflow name matches (`.github/workflows/ci.yml`).

---

## Checklist

Use this checklist to ensure everything is configured:

- [ ] Repository renamed to `sentinel-salesforce-compliance-drift-guard`
- [ ] Description updated
- [ ] Topics added (12 total)
- [ ] Social preview image uploaded (optional)
- [ ] Website URL added (if applicable)
- [ ] GitHub Discussions enabled
- [ ] Custom labels created (compliance, drift-detection, etc.)
- [ ] README badges updated
- [ ] Issue templates created (bug report, feature request)
- [ ] CONTRIBUTING.md created
- [ ] LICENSE file exists (MIT recommended)
- [ ] SECURITY.md created
- [ ] Security features enabled (Dependabot, secret scanning)
- [ ] Important issues pinned
- [ ] GitHub Actions badge updated

---

## After Setup

Once everything is configured:

1. **Share on social media**:
   - Twitter: "Just repositioned Sentinel as a Salesforce compliance drift guardrail! [link]"
   - LinkedIn: Post about solving audit readiness for regulated orgs
   - Reddit: r/salesforce, r/compliance

2. **Add to directories**:
   - Awesome Salesforce: https://github.com/mailtoharshit/awesome-salesforce
   - Salesforce Developer Resources

3. **Create demo video**:
   - Record 2-minute demo showing:
     1. Installation
     2. First compliance scan
     3. Sample report
   - Upload to YouTube
   - Add to README

4. **Write launch blog post**:
   - "How Sentinel Makes Your Salesforce Org Audit-Ready in 24 Hours"
   - Include sample report, installation guide, and roadmap

---

**Questions?** Open a GitHub Discussion or contact the maintainers.

*Last Updated: 2025-01-24*
