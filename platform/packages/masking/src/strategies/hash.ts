import { createHash } from 'crypto';
import murmurhash from 'murmurhash';
import type { HashStrategy } from '@platform/types';

/**
 * Hash strategy: Produces deterministic or random hash of input
 * Deterministic mode ensures same input always produces same output
 * across runs (useful for referential consistency)
 */
export function hash(
  value: string | null | undefined,
  options: Omit<HashStrategy, 'type'>
): string {
  if (value === null || value === undefined) {
    return '';
  }

  const input = options.deterministic
    ? value
    : `${value}-${Date.now()}-${Math.random()}`;

  const salted = options.salt ? `${input}${options.salt}` : input;

  if (options.algorithm === 'murmur3') {
    // MurmurHash3 - fast, good distribution, 32-bit
    const hashValue = murmurhash.v3(salted);
    return hashValue.toString(16).padStart(8, '0');
  }

  // SHA-256 - cryptographic, 256-bit
  const hashBuffer = createHash('sha256').update(salted).digest('hex');
  // Return first 16 chars for readability
  return hashBuffer.slice(0, 16);
}

/**
 * Deterministic hash that maintains format hints
 * e.g., email stays email-like: abc123@masked.example.com
 */
export function hashWithFormatHint(
  value: string | null | undefined,
  options: Omit<HashStrategy, 'type'> & { formatHint?: 'email' | 'phone' }
): string {
  if (value === null || value === undefined) {
    return '';
  }

  const baseHash = hash(value, options);

  switch (options.formatHint) {
    case 'email':
      return `${baseHash}@masked.example.com`;
    case 'phone':
      return `555-${baseHash.slice(0, 3)}-${baseHash.slice(3, 7)}`;
    default:
      return baseHash;
  }
}
