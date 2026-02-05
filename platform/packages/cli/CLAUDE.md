# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the `@platform/cli` package - a CLI tool for Elaro, providing compliance scanning, deployment, and org management for Salesforce. It's part of a Turborepo monorepo at `/platform`.

## Commands

```bash
# Build
npm run build          # Compile TypeScript to dist/

# Development
npm run dev            # Watch mode compilation

# Testing
npm run test           # Run vitest tests
npm run typecheck      # Type check without emitting

# Run CLI locally
npm run start          # Run compiled CLI
node dist/index.js     # Direct execution
```

From monorepo root (`/platform`):
```bash
npm run build -- --filter=@platform/cli   # Build only CLI
npm run typecheck -- --filter=@platform/cli
```

## Architecture

```
src/
├── index.ts           # Entry point, registers all commands with Commander
└── commands/
    ├── config.ts      # ~/.elaro/config.json management
    ├── deploy.ts      # sf project deploy wrapper
    ├── org.ts         # Org management (list, login, create, delete, open)
    ├── scan.ts        # Compliance scanning (HIPAA, SOC2, NIST, etc.)
    ├── status.ts      # Project and org status display
    └── test.ts        # Apex and LWC test runner
```

Each command file exports a single `Command` instance that gets registered in `index.ts`.

## Key Dependencies

- **commander** - CLI framework
- **chalk** - Terminal styling
- **ora** - Spinners for async operations

## TypeScript Configuration

Extends `../../tsconfig.base.json` with strict settings including:
- `noUncheckedIndexedAccess: true` - Array access returns `T | undefined`
- `strictNullChecks: true`
- `noImplicitReturns: true`

Uses ESM (`"type": "module"`) with NodeNext module resolution.

## Adding a New Command

1. Create `src/commands/mycommand.ts` exporting a `Command` instance
2. Import and register in `src/index.ts` via `program.addCommand()`
3. Follow existing patterns: interfaces for options/results, async action handlers, ora spinners, chalk output
