import type { RedactStrategy } from '@platform/types';

/**
 * Redact strategy: Replaces value with a fixed replacement string
 */
export function redact(
  value: string | null | undefined,
  options: Omit<RedactStrategy, 'type'>
): string {
  if (value === null || value === undefined) {
    return '';
  }

  const replacement = options.replacement ?? '[REDACTED]';
  return replacement;
}

/**
 * Partial redact: Keeps first/last N characters visible
 */
export function partialRedact(
  value: string | null | undefined,
  options: { keepFirst?: number; keepLast?: number; maskChar?: string }
): string {
  if (value === null || value === undefined || value.length === 0) {
    return '';
  }

  const keepFirst = options.keepFirst ?? 0;
  const keepLast = options.keepLast ?? 0;
  const maskChar = options.maskChar ?? '*';

  if (keepFirst + keepLast >= value.length) {
    return value;
  }

  const prefix = value.slice(0, keepFirst);
  const suffix = value.slice(-keepLast || undefined);
  const masked = maskChar.repeat(value.length - keepFirst - keepLast);

  return `${prefix}${masked}${keepLast > 0 ? suffix : ''}`;
}
