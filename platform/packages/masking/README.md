# @platform/masking

Data masking library for Prometheion - provides multiple strategies for anonymizing sensitive data.

## Installation

This package is part of the Prometheion monorepo:

```bash
npm install
```

## Usage

```typescript
import { MaskingEngine, MaskingStrategy } from "@platform/masking";

// Create masking engine
const engine = new MaskingEngine();

// Mask sensitive data
const masked = engine.mask("John Doe", MaskingStrategy.REDACT);
// Result: '********'

const fakeData = engine.mask("john@example.com", MaskingStrategy.FAKE);
// Result: 'fake_user_123@example.com'
```

## Strategies

| Strategy   | Description                    |
| ---------- | ------------------------------ |
| `REDACT`   | Replace with asterisks         |
| `FAKE`     | Generate realistic fake data   |
| `HASH`     | One-way hash (murmurhash)      |
| `FPE`      | Format-preserving encryption   |
| `TOKENIZE` | Replace with reversible tokens |

## API

### MaskingEngine

```typescript
class MaskingEngine {
  mask(value: string, strategy: MaskingStrategy): string;
  unmask(token: string): string | null; // Only for TOKENIZE strategy
}
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
