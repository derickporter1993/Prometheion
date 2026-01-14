# @platform/cli

Prometheion CLI - Command-line interface for the AI Compliance Brain for Salesforce.

## Installation

This package is part of the Prometheion monorepo. From the platform directory:

```bash
cd platform
npm install
npm run build
```

## Usage

```bash
# Check project and org status
prometheion status

# Run compliance scan
prometheion scan --framework hipaa

# Deploy to Salesforce org
prometheion deploy --validate

# Run tests
prometheion test --apex

# Manage orgs
prometheion org list
prometheion org login
```

## Commands

| Command  | Description                                 |
| -------- | ------------------------------------------- |
| `status` | Check Prometheion project and org status    |
| `scan`   | Run compliance scans against Salesforce org |
| `deploy` | Deploy Prometheion to Salesforce org        |
| `test`   | Run Apex and LWC tests                      |
| `org`    | Manage Salesforce org connections           |
| `config` | Manage CLI configuration                    |

## Development

```bash
# Build
npm run build

# Watch mode
npm run dev

# Run tests
npm run test

# Type check
npm run typecheck
```

## Related

- [Prometheion](https://github.com/derickporter1993/Prometheion) - Main project
- [@platform/sf-client](../sf-client) - Salesforce API client
- [@platform/types](../types) - Shared TypeScript types
