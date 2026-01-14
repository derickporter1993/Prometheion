# Code Analyzer Execution Instructions

**Purpose**: Run Salesforce Code Analyzer to identify security vulnerabilities before AppExchange submission.

---

## Prerequisites

1. Salesforce CLI installed (`sf` command available)
2. Authenticated Salesforce org (scratch org, sandbox, or production)
3. Code Analyzer plugin installed

---

## Installation

If Code Analyzer is not installed:

```bash
sf plugins install @salesforce/sfdx-scanner
```

---

## Execution

### Step 1: Run Code Analyzer

```bash
# Run analyzer on all Apex and LWC code
sf code-analyzer run --target force-app/ --outfile security-report.html

# Or run with specific categories
sf code-analyzer run --target force-app/ --category security --outfile security-report.html
```

### Step 2: Review Findings

Open `security-report.html` in a browser to review:
- Critical findings (must fix)
- High severity findings (should fix)
- Medium/Low findings (review and fix if applicable)

### Step 3: Document Suppressions

If any findings need to be suppressed (false positives), create `CODE_ANALYZER_SUPPRESSIONS.md`:

```markdown
# Code Analyzer Suppressions

## Suppression Justifications

### Finding: [Rule Name] - [File Path]
**Severity**: [Critical/High/Medium/Low]  
**Justification**: [Why this is a false positive or acceptable risk]  
**Approved By**: [Name/Date]
```

---

## Expected Results

**Target**: Zero critical findings  
**Acceptable**: High severity findings documented with justification

---

## Integration with CI/CD

Add to `.github/workflows/`:

```yaml
- name: Run Code Analyzer
  run: |
    sf code-analyzer run --target force-app/ --category security --outfile security-report.html
    # Fail build on critical findings
    if grep -q "severity: critical" security-report.html; then
      echo "❌ Critical security findings detected"
      exit 1
    fi
```

---

## Next Steps After Analysis

1. Fix all critical findings
2. Review and fix high severity findings
3. Document any suppressions
4. Update SECURITY_REVIEW_CHECKLIST.md with results
5. Re-run analyzer to verify fixes

---

*Instructions generated: January 2026*
