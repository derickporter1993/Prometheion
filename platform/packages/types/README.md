# @platform/types

Shared TypeScript type definitions for the Prometheion platform packages.

## Installation

This package is part of the Prometheion monorepo:

```bash
npm install
```

## Usage

```typescript
import type {
  ComplianceFramework,
  ComplianceScore,
  MaskingStrategy,
  SalesforceOrg,
  User,
} from "@platform/types";

// Use types in your code
const score: ComplianceScore = {
  framework: "HIPAA",
  score: 85,
  totalChecks: 100,
  passedChecks: 85,
  failedChecks: 15,
};
```

## Available Types

### Compliance

- `ComplianceFramework` - Supported compliance frameworks (HIPAA, SOC2, etc.)
- `ComplianceScore` - Compliance score results
- `ComplianceCheck` - Individual compliance check
- `ComplianceGap` - Identified compliance gap

### Salesforce

- `SalesforceOrg` - Salesforce org connection
- `SObjectDescribe` - SObject metadata
- `FieldDescribe` - Field metadata
- `QueryResult` - SOQL query results

### Masking

- `MaskingStrategy` - Data masking strategies
- `MaskingConfig` - Masking configuration
- `MaskingResult` - Masking operation result

### Common

- `User` - User information
- `AuditLog` - Audit log entry
- `ApiResponse` - Standard API response wrapper

## Development

```bash
# Build
npm run build

# Watch mode
npm run dev

# Type check
npm run typecheck
```

## Related

- [Prometheion](https://github.com/derickporter1993/Prometheion) - Main project
- [@platform/cli](../cli) - CLI tool
- [@platform/masking](../masking) - Data masking library
- [@platform/sf-client](../sf-client) - Salesforce API client
