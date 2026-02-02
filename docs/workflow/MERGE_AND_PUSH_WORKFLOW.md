# Merge and Push Workflow

**Created:** 2026-02-02  
**Purpose:** Document the standard merge and push workflow for this repository

## Overview

This document describes the process for merging feature branches and pushing changes to the Prometheion repository.

## Standard Workflow

### 1. Feature Branch Development
- Create a feature branch from `main`
- Make your changes
- Commit changes with descriptive messages
- Push changes to remote

### 2. Merging Process
- Ensure all tests pass
- Ensure code quality checks pass
- Create a pull request to `main`
- Get code review approval
- Merge PR into `main`

### 3. Push to Remote
- Changes are automatically pushed when using `report_progress` tool
- Manual pushes use `git push origin <branch-name>`

## Current Branch

This document was created on the `copilot/merge-and-push-changes` branch as part of understanding and documenting the merge and push workflow.

## Related Documentation

- `.git-workflow.md` - Git workflow guidelines
- `docs/guides/CONTRIBUTING.md` - Contributing guidelines
- `.github/` - GitHub Actions and workflows

## Notes

- This repository uses a standard Git workflow
- All changes should go through pull requests for code review
- The `report_progress` tool automates commit and push operations
