import { createCipheriv, createDecipheriv, randomBytes, scryptSync } from 'crypto';
import type { FpeStrategy } from '@platform/types';

/**
 * Format-Preserving Encryption (FPE) strategy
 *
 * Uses AES-based encryption that maintains the format of the input.
 * For production use, consider a proper FPE library like node-fpe or ff3-1.
 *
 * Key management:
 * - keyId references a key stored in the secrets vault
 * - Keys should be rotated periodically
 * - Decryption is possible for authorized users
 */

// Simulated key store (in production, use KMS/Vault)
const keyStore = new Map<string, Buffer>();

export function registerKey(keyId: string, key: Buffer): void {
  keyStore.set(keyId, key);
}

export function generateKey(keyId: string, passphrase: string): void {
  const salt = randomBytes(16);
  const key = scryptSync(passphrase, salt, 32);
  keyStore.set(keyId, key);
}

/**
 * Format-preserving encrypt
 * Maintains character set and length of original
 */
export function fpeEncrypt(
  value: string | null | undefined,
  options: Omit<FpeStrategy, 'type'>
): string {
  if (value === null || value === undefined || value.length === 0) {
    return '';
  }

  const key = keyStore.get(options.keyId);
  if (!key) {
    throw new Error(`FPE key not found: ${options.keyId}`);
  }

  if (options.preserveFormat) {
    return formatPreservingEncrypt(value, key);
  }

  // Non-format-preserving fallback
  return simpleEncrypt(value, key);
}

/**
 * Format-preserving decrypt (for authorized users)
 */
export function fpeDecrypt(
  encryptedValue: string,
  options: Omit<FpeStrategy, 'type'>
): string {
  const key = keyStore.get(options.keyId);
  if (!key) {
    throw new Error(`FPE key not found: ${options.keyId}`);
  }

  if (options.preserveFormat) {
    return formatPreservingDecrypt(encryptedValue, key);
  }

  return simpleDecrypt(encryptedValue, key);
}

/**
 * Simple AES encryption (base64 output)
 */
function simpleEncrypt(value: string, key: Buffer): string {
  const iv = randomBytes(16);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return Buffer.concat([iv, authTag, encrypted]).toString('base64');
}

function simpleDecrypt(encrypted: string, key: Buffer): string {
  const buffer = Buffer.from(encrypted, 'base64');
  const iv = buffer.subarray(0, 16);
  const authTag = buffer.subarray(16, 32);
  const encryptedText = buffer.subarray(32);
  const decipher = createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(authTag);
  return decipher.update(encryptedText) + decipher.final('utf8');
}

/**
 * Format-preserving encryption
 *
 * This is a simplified implementation. For production:
 * - Use FF1 or FF3-1 algorithm (NIST SP 800-38G)
 * - Consider libraries like `node-fpe` or `ff3`
 */
function formatPreservingEncrypt(value: string, key: Buffer): string {
  const result: string[] = [];

  for (let i = 0; i < value.length; i++) {
    const char = value[i];
    if (!char) continue;

    if (/[a-z]/.test(char)) {
      result.push(encryptChar(char, key, i, 'a', 26));
    } else if (/[A-Z]/.test(char)) {
      result.push(encryptChar(char, key, i, 'A', 26));
    } else if (/[0-9]/.test(char)) {
      result.push(encryptChar(char, key, i, '0', 10));
    } else {
      // Preserve non-alphanumeric characters
      result.push(char);
    }
  }

  return result.join('');
}

function formatPreservingDecrypt(encrypted: string, key: Buffer): string {
  const result: string[] = [];

  for (let i = 0; i < encrypted.length; i++) {
    const char = encrypted[i];
    if (!char) continue;

    if (/[a-z]/.test(char)) {
      result.push(decryptChar(char, key, i, 'a', 26));
    } else if (/[A-Z]/.test(char)) {
      result.push(decryptChar(char, key, i, 'A', 26));
    } else if (/[0-9]/.test(char)) {
      result.push(decryptChar(char, key, i, '0', 10));
    } else {
      result.push(char);
    }
  }

  return result.join('');
}

function encryptChar(
  char: string,
  key: Buffer,
  position: number,
  base: string,
  range: number
): string {
  const offset = char.charCodeAt(0) - base.charCodeAt(0);
  const keyByte = key[position % key.length] ?? 0;
  const encrypted = (offset + keyByte) % range;
  return String.fromCharCode(base.charCodeAt(0) + encrypted);
}

function decryptChar(
  char: string,
  key: Buffer,
  position: number,
  base: string,
  range: number
): string {
  const offset = char.charCodeAt(0) - base.charCodeAt(0);
  const keyByte = key[position % key.length] ?? 0;
  const decrypted = (offset - keyByte + range) % range;
  return String.fromCharCode(base.charCodeAt(0) + decrypted);
}
