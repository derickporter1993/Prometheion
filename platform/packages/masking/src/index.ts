/**
 * @platform/masking
 *
 * Pure masking engine for transforming sensitive data
 * Strategies: redact, hash, fake, fpe, tokenize, preserve
 */

// Core engine
export { MaskingEngine, calculateEffectivenessScore } from './engine';
export type { FieldInfo, RecordData } from './engine';

// Individual strategies
export { redact, partialRedact } from './strategies/redact';
export { hash, hashWithFormatHint } from './strategies/hash';
export { fake, fakeDeterministic } from './strategies/fake';
export { fpeEncrypt, fpeDecrypt, registerKey, generateKey } from './strategies/fpe';
export {
  tokenize,
  detokenize,
  initVault,
  isToken,
  getVaultStats,
  clearVault,
} from './strategies/tokenize';

// Re-export types
export type {
  MaskingStrategy,
  MaskingPolicy,
  MaskingRule,
  FieldMatcher,
  MaskingPreview,
  MaskingEffectivenessScore,
} from '@platform/types';

/**
 * Built-in policy templates
 */
export const POLICY_TEMPLATES = {
  PII_STANDARD: {
    name: 'PII Standard',
    description: 'Standard PII masking for common fields',
    rules: [
      {
        id: 'email',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*[Ee]mail.*' },
        strategy: {
          type: 'fake' as const,
          generator: 'email' as const,
        },
        priority: 1,
      },
      {
        id: 'phone',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*[Pp]hone.*' },
        strategy: {
          type: 'fake' as const,
          generator: 'phone' as const,
        },
        priority: 2,
      },
      {
        id: 'name',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*(First|Last|Full).*[Nn]ame.*' },
        strategy: {
          type: 'fake' as const,
          generator: 'name' as const,
        },
        priority: 3,
      },
      {
        id: 'ssn',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*(SSN|Social|TaxId).*' },
        strategy: {
          type: 'redact' as const,
          replacement: 'XXX-XX-XXXX',
        },
        priority: 0,
      },
      {
        id: 'address',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*(Street|Address|Mailing|Billing).*' },
        strategy: {
          type: 'fake' as const,
          generator: 'address' as const,
        },
        priority: 4,
      },
    ],
  },

  PCI_DSS: {
    name: 'PCI-DSS Compliant',
    description: 'Payment card data masking for PCI compliance',
    rules: [
      {
        id: 'card_number',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*(Card|Credit|Debit).*[Nn]umber.*' },
        strategy: {
          type: 'redact' as const,
          replacement: '**** **** **** ****',
        },
        priority: 0,
      },
      {
        id: 'cvv',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*(CVV|CVC|Security.*Code).*' },
        strategy: {
          type: 'redact' as const,
          replacement: '***',
        },
        priority: 0,
      },
      {
        id: 'expiry',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*(Expir|Exp.*Date).*' },
        strategy: {
          type: 'redact' as const,
          replacement: 'XX/XX',
        },
        priority: 1,
      },
    ],
  },

  HIPAA: {
    name: 'HIPAA Compliant',
    description: 'Protected Health Information masking',
    rules: [
      {
        id: 'mrn',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*(MRN|Medical.*Record|Patient.*Id).*' },
        strategy: {
          type: 'hash' as const,
          algorithm: 'sha256' as const,
          deterministic: true,
        },
        priority: 0,
      },
      {
        id: 'dob',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*(DOB|Birth.*Date|Date.*Birth).*' },
        strategy: {
          type: 'fake' as const,
          generator: 'date' as const,
        },
        priority: 1,
      },
      {
        id: 'diagnosis',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*(Diagnosis|Condition|Disease).*' },
        strategy: {
          type: 'redact' as const,
          replacement: '[REDACTED]',
        },
        priority: 2,
      },
    ],
  },

  DETERMINISTIC: {
    name: 'Deterministic Masking',
    description: 'Same input always produces same output (for referential consistency)',
    rules: [
      {
        id: 'email_deterministic',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*[Ee]mail.*' },
        strategy: {
          type: 'hash' as const,
          algorithm: 'sha256' as const,
          deterministic: true,
        },
        priority: 1,
      },
      {
        id: 'name_deterministic',
        matcher: { type: 'pattern' as const, fieldNameRegex: '.*[Nn]ame.*' },
        strategy: {
          type: 'hash' as const,
          algorithm: 'murmur3' as const,
          deterministic: true,
        },
        priority: 2,
      },
    ],
  },
} as const;
