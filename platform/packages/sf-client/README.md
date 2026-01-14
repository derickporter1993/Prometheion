# @platform/sf-client

Salesforce API client library for Prometheion - provides typed clients for REST, Tooling, and Bulk APIs.

## Installation

This package is part of the Prometheion monorepo:

```bash
npm install
```

## Usage

### REST API Client

```typescript
import { RestClient, authenticateWithJwt } from "@platform/sf-client";

// Authenticate
const auth = await authenticateWithJwt({
  clientId: "your-connected-app-id",
  username: "user@example.com",
  privateKey: "-----BEGIN RSA PRIVATE KEY-----...",
});

// Create client
const client = new RestClient({
  instanceUrl: auth.instanceUrl,
  accessToken: auth.accessToken,
});

// Query records
const results = await client.query<Account>("SELECT Id, Name FROM Account LIMIT 10");

// CRUD operations
await client.createRecord("Account", { Name: "New Account" });
await client.updateRecord("Account", "recordId", { Name: "Updated" });
await client.deleteRecord("Account", "recordId");
```

### Tooling API Client

```typescript
import { ToolingClient } from "@platform/sf-client";

const tooling = new ToolingClient({
  instanceUrl: auth.instanceUrl,
  accessToken: auth.accessToken,
});

// Get flows for objects
const flows = await tooling.getFlows(["Account", "Contact"]);

// Get triggers
const triggers = await tooling.getTriggers(["Account"]);

// Get validation rules
const rules = await tooling.getValidationRules(["Account"]);
```

### Bulk API Client

```typescript
import { BulkClient } from "@platform/sf-client";

const bulk = new BulkClient({
  instanceUrl: auth.instanceUrl,
  accessToken: auth.accessToken,
});

// Create bulk job
const job = await bulk.createIngestJob({
  operation: "insert",
  object: "Account",
});

// Upload CSV data
await bulk.uploadJobData(job.id, csvData);
await bulk.closeJob(job.id);

// Wait for completion
const result = await bulk.waitForJobCompletion(job.id);
```

## Authentication

### JWT Bearer Flow (Recommended)

```typescript
import { authenticateWithJwt } from "@platform/sf-client";

const auth = await authenticateWithJwt({
  clientId: "connected-app-consumer-key",
  username: "user@example.com",
  privateKey: privateKeyPem,
  loginUrl: "https://login.salesforce.com", // or test.salesforce.com
});
```

### OAuth Web Flow

```typescript
import { buildAuthorizationUrl, exchangeCodeForTokens } from "@platform/sf-client";

// Build auth URL
const authUrl = buildAuthorizationUrl({
  clientId: "your-client-id",
  clientSecret: "your-client-secret",
  redirectUri: "https://your-app.com/callback",
});

// Exchange code for tokens
const tokens = await exchangeCodeForTokens(config, authorizationCode);
```

## Development

```bash
# Build
npm run build

# Watch mode
npm run dev

# Run tests
npm run test
npm run test:watch

# Type check
npm run typecheck
```

## Related

- [Prometheion](https://github.com/derickporter1993/Prometheion) - Main project
- [@platform/types](../types) - Shared TypeScript types
