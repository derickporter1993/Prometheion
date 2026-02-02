# Pull Request Auto-Merge Documentation

## Quick Summary

**Problem**: Open PRs weren't being automatically merged to main  
**Root Cause**: No auto-merge automation existed  
**Solution**: Added two workflows:
1. `auto-merge-pr.yml` - Automatically merges PRs when checks pass
2. `pr-status-monitor.yml` - Provides hourly PR status reports

**Impact**: PRs now merge automatically, reducing manual work and improving developer experience.

---

## Problem

Open pull requests were not being automatically merged to the `main` branch, resulting in a backlog of approved PRs.

## Root Cause

The repository lacked an automated merge workflow. While CI/CD checks were running, there was no automation to merge PRs once all checks passed and approvals were granted.

## Solution

We've implemented two GitHub Actions workflows to automate PR merging and monitoring:

### 1. Auto-Merge Workflow (`.github/workflows/auto-merge-pr.yml`)

**Purpose**: Automatically merge pull requests when they meet all requirements.

**Triggers**:
- When a PR is opened, synchronized, or reopened
- When a PR review is submitted
- When check suites complete
- On status updates

**How it works**:
1. Monitors PR events and status check completions
2. Checks if the PR is in a mergeable state:
   - All required checks must pass
   - No merge conflicts
   - Not a draft PR
   - Review requirements met (if any)
3. If all conditions are met, automatically merges using squash merge
4. Deletes the source branch after merge

**Enable auto-merge for a PR manually**:
```bash
gh pr merge <PR_NUMBER> --squash --auto --delete-branch
```

### 2. PR Status Monitor (`.github/workflows/pr-status-monitor.yml`)

**Purpose**: Provides visibility into the status of all open PRs.

**Triggers**:
- Runs hourly via cron schedule
- Can be manually triggered via GitHub Actions UI

**What it reports**:
- Total number of open PRs
- PRs categorized by status:
  - ✅ Ready to merge
  - 🔒 Needs review
  - ⏳ Checks pending
  - ❌ Checks failing
  - ⚠️ Has conflicts
  - 📝 Draft PRs

**View the report**:
1. Go to the Actions tab in GitHub
2. Select "PR Status Monitor" workflow
3. View the latest run logs

## Branch Protection Rules

The auto-merge workflow respects all branch protection rules configured on the `main` branch, including:
- Required status checks
- Required reviews
- Required signatures
- Linear history requirements

If PRs are blocked despite passing checks, verify branch protection settings in repository Settings > Branches > main.

## Manual Merge Process

If auto-merge is not desired or a PR requires manual intervention:

```bash
# View PR status
gh pr view <PR_NUMBER>

# Check PR checks status
gh pr checks <PR_NUMBER>

# Merge manually
gh pr merge <PR_NUMBER> --squash --delete-branch
```

## Troubleshooting

### PRs showing as "blocked"

**Possible causes**:
1. **Required reviews not approved**: Check if branch protection requires approvals
2. **Required checks not passing**: View the PR's checks tab
3. **Merge conflicts**: Resolve conflicts in the PR branch
4. **Draft status**: Convert to ready for review

**Debug steps**:
```bash
# Check PR mergeable state
gh pr view <PR_NUMBER> --json mergeable,mergeStateStatus,reviewDecision

# List required status checks
gh api repos/{owner}/{repo}/branches/main/protection/required_status_checks

# View branch protection rules
gh api repos/{owner}/{repo}/branches/main/protection
```

### Auto-merge not triggering

**Possible causes**:
1. Workflow permissions insufficient (check Settings > Actions > General > Workflow permissions)
2. PR is a draft
3. Branch protection rules block auto-merge
4. Required checks still pending

**Resolution**:
- Ensure workflow has `write` permissions for `contents` and `pull-requests`
- Mark PR as ready for review if it's a draft
- Wait for all required checks to complete

## Monitoring and Maintenance

### View auto-merge activity
```bash
# List recent workflow runs
gh run list --workflow=auto-merge-pr.yml --limit 10

# View specific run details
gh run view <RUN_ID>
```

### Manually trigger PR status report
```bash
gh workflow run pr-status-monitor.yml
```

## Best Practices

1. **Keep PRs small**: Smaller PRs merge faster and have fewer conflicts
2. **Keep branches updated**: Regularly sync feature branches with main
3. **Enable auto-merge**: Use `gh pr merge --auto` for eligible PRs
4. **Monitor status**: Check the PR Status Monitor weekly
5. **Address failing checks**: Fix failing checks promptly to unblock merges

## Workflow Permissions

The workflows require the following permissions:
- `contents: write` - To merge PRs and delete branches
- `pull-requests: write` - To update PR status and merge
- `checks: read` - To read check suite status

These are configured in the workflow files and should be granted via the repository's Actions settings.

## Related Files

- `.github/workflows/auto-merge-pr.yml` - Auto-merge workflow
- `.github/workflows/pr-status-monitor.yml` - Status monitoring workflow
- `.github/workflows/prometheion-ci.yml` - CI/CD checks
- `.github/workflows/codeql.yml` - Security scanning
- `scripts/monitor-and-merge-pr.sh` - Manual merge script (legacy)

## Migration from Manual Process

Previously, PRs were merged manually using:
- Direct `git` commands following `.git-workflow.md`
- Shell script `scripts/monitor-and-merge-pr.sh`

The new automated workflows replace this manual process while maintaining the same merge strategy (squash merge).

## Configuration Options

### Customize auto-merge behavior

Edit `.github/workflows/auto-merge-pr.yml` to change:
- Merge strategy (default: squash)
- Branch deletion after merge (default: enabled)
- Auto-merge conditions (default: all checks pass, not draft, no conflicts)

### Adjust monitoring frequency

Edit `.github/workflows/pr-status-monitor.yml` cron schedule:
```yaml
schedule:
  - cron: '0 */4 * * *'  # Every 4 hours instead of hourly
```

## Support

For issues or questions about PR auto-merge:
1. Check the Actions tab for workflow run logs
2. Review this documentation
3. Open an issue with details about the blocked PR
