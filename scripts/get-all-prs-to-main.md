# Get All Pull Requests to Main Branch

Script to retrieve and display all pull requests targeting the main branch in the Elaro repository.

## Usage

```bash
./scripts/get-all-prs-to-main.sh [state]
```

### Arguments

- `state` - Filter PRs by state (optional, default: `all`)
  - `open` - Show only open PRs
  - `closed` - Show only closed PRs
  - `all` - Show all PRs (both open and closed)

### Examples

```bash
# Get all PRs (open and closed)
./scripts/get-all-prs-to-main.sh

# Get only open PRs
./scripts/get-all-prs-to-main.sh open

# Get only closed PRs
./scripts/get-all-prs-to-main.sh closed

# Show help
./scripts/get-all-prs-to-main.sh --help
```

## Requirements

One of the following:
- **GitHub CLI (gh)** - Installed and authenticated (recommended)
  - Install: https://cli.github.com/
  - Authenticate: `gh auth login`
  - Also requires: `jq` for JSON parsing
- **GITHUB_TOKEN** - Environment variable with a GitHub personal access token
  - Create token: https://github.com/settings/tokens
  - Set: `export GITHUB_TOKEN=your_token_here`
  - Also requires: `python3` for JSON parsing

## Output

The script displays:
- PR number
- PR state (OPEN/CLOSED)
- PR title
- Author username
- Created date
- Updated date
- Summary count of PRs by state

### Sample Output

```
🔍 Fetching pull requests to main branch...
Repository: derickporter1993/Elaro
State: open

📊 Pull Requests:
==================================
PR #141 - OPEN
  Title: [WIP] Fetch all pull requests to main branch
  Author: copilot[bot]
  Created: 2026-02-02T05:38:21Z
  Updated: 2026-02-02T05:39:15Z

PR #140 - OPEN
  Title: [WIP] Merge and push recent changes to main
  Author: copilot[bot]
  Created: 2026-02-01T03:15:42Z
  Updated: 2026-02-01T03:16:37Z

==================================
Summary:
  Open PRs: 6
  Closed PRs: 24
  Total PRs: 30
```

## Related Scripts

- `close-prs.sh` - Close multiple pull requests
- `monitor-and-merge-pr.sh` - Monitor CI and auto-merge PR

## Troubleshooting

### Error: Neither 'gh' CLI nor GITHUB_TOKEN is available

**Solution**: Install GitHub CLI or set GITHUB_TOKEN:

```bash
# Option 1: Install GitHub CLI (recommended)
# macOS
brew install gh
gh auth login

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
gh auth login

# Option 2: Use personal access token
export GITHUB_TOKEN=ghp_your_token_here
./scripts/get-all-prs-to-main.sh
```

### Error: Invalid state 'xyz'

**Solution**: Use one of the valid states: `open`, `closed`, or `all`

```bash
./scripts/get-all-prs-to-main.sh open
```
