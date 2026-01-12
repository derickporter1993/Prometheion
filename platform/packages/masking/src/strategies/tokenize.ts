import type { TokenizeStrategy } from '@platform/types';

/**
 * Tokenization strategy
 *
 * Replaces sensitive data with a token that can be de-tokenized
 * by an external tokenization vault (e.g., HashiCorp Vault, AWS Macie).
 *
 * This is a placeholder implementation. In production:
 * - Integrate with actual tokenization service
 * - Store token mappings securely
 * - Handle token lifecycle (expiry, rotation)
 */

// Simulated token vault (in production, use external service)
const tokenVault = new Map<string, Map<string, string>>();
const reverseVault = new Map<string, Map<string, string>>();

/**
 * Initialize a vault namespace
 */
export function initVault(vaultRef: string): void {
  if (!tokenVault.has(vaultRef)) {
    tokenVault.set(vaultRef, new Map());
    reverseVault.set(vaultRef, new Map());
  }
}

/**
 * Tokenize a value
 * Returns a token that can be used to retrieve the original value
 */
export function tokenize(
  value: string | null | undefined,
  options: Omit<TokenizeStrategy, 'type'>
): string {
  if (value === null || value === undefined) {
    return '';
  }

  const vault = tokenVault.get(options.vaultRef);
  const reverse = reverseVault.get(options.vaultRef);

  if (!vault || !reverse) {
    throw new Error(`Token vault not initialized: ${options.vaultRef}`);
  }

  // Check if value is already tokenized
  const existingToken = vault.get(value);
  if (existingToken) {
    return existingToken;
  }

  // Generate new token
  const token = generateToken();
  vault.set(value, token);
  reverse.set(token, value);

  return token;
}

/**
 * Detokenize a token back to original value
 * Only available to authorized users
 */
export function detokenize(
  token: string,
  options: Omit<TokenizeStrategy, 'type'>
): string | null {
  const reverse = reverseVault.get(options.vaultRef);

  if (!reverse) {
    throw new Error(`Token vault not initialized: ${options.vaultRef}`);
  }

  return reverse.get(token) ?? null;
}

/**
 * Check if a value looks like a token
 */
export function isToken(value: string): boolean {
  return /^TOK_[A-Z0-9]{24}$/.test(value);
}

/**
 * Generate a unique token
 */
function generateToken(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let token = 'TOK_';
  for (let i = 0; i < 24; i++) {
    token += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return token;
}

/**
 * Vault statistics
 */
export function getVaultStats(vaultRef: string): {
  tokenCount: number;
  initialized: boolean;
} {
  const vault = tokenVault.get(vaultRef);
  return {
    tokenCount: vault?.size ?? 0,
    initialized: vault !== undefined,
  };
}

/**
 * Clear vault (for testing)
 */
export function clearVault(vaultRef: string): void {
  tokenVault.get(vaultRef)?.clear();
  reverseVault.get(vaultRef)?.clear();
}
