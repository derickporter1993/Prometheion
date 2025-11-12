# OpsGuardian — Prettier Extras (Husky + Auto-fix)

**Date:** November 03, 2025

## Contents
- `package.json.patch` — adds **husky** + **lint-staged** and a `prepare` script
- `.husky/pre-commit` — runs Prettier on staged files
- `.github/workflows/format-on-pr.yml` — optional **auto-format** on PRs (uses `pull_request_target`)
- `.husky/_/husky.sh` — husky helper

## Usage
1. Apply the `package.json.patch` (or add deps/scripts manually).
2. Install and create hooks:
   ```bash
   npm i -D husky lint-staged
   npx husky init
   # Replace the generated pre-commit with the one in this pack
   cp -f .husky/pre-commit .husky/pre-commit
   chmod +x .husky/pre-commit
   ```
3. (Optional) Enable **format-on-pr.yml** for automatic formatting commits on PRs.
   - This workflow has `contents: write` permissions and pushes a commit to the PR branch **only if the branch is in this repo** (no forks).

## Notes
- Keep your main CI formatting step as `--check` to enforce standards.
- Husky keeps contributors from pushing unformatted code.
