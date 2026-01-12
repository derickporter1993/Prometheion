import type {
  MaskingPolicy,
  MaskingRule,
  MaskingStrategy,
  FieldMatcher,
  RuleCondition,
  MaskingPreview,
  MaskingEffectivenessScore,
} from '@platform/types';

import { redact, partialRedact } from './strategies/redact';
import { hash, hashWithFormatHint } from './strategies/hash';
import { fake, fakeDeterministic } from './strategies/fake';
import { fpeEncrypt } from './strategies/fpe';
import { tokenize } from './strategies/tokenize';

export interface FieldInfo {
  sobject: string;
  field: string;
  dataType?: string;
  classification?: string[];
}

export interface RecordData {
  [field: string]: unknown;
}

/**
 * MaskingEngine
 *
 * Applies masking policies to Salesforce records.
 * Handles field matching, rule evaluation, and strategy application.
 */
export class MaskingEngine {
  private policy: MaskingPolicy;
  private ruleCache: Map<string, MaskingRule | null> = new Map();

  constructor(policy: MaskingPolicy) {
    this.policy = policy;
    // Pre-sort rules by priority (lower number = higher priority)
    this.policy.rules.sort((a, b) => a.priority - b.priority);
  }

  /**
   * Mask a single field value
   */
  maskField(
    value: unknown,
    fieldInfo: FieldInfo,
    record?: RecordData
  ): { masked: unknown; strategyUsed: string | null } {
    const rule = this.findMatchingRule(fieldInfo, record);

    if (!rule) {
      return { masked: value, strategyUsed: null };
    }

    const stringValue = value !== null && value !== undefined ? String(value) : null;
    const masked = this.applyStrategy(stringValue, rule.strategy, fieldInfo);

    return { masked, strategyUsed: rule.strategy.type };
  }

  /**
   * Mask an entire record
   */
  maskRecord(
    sobject: string,
    record: RecordData,
    fieldInfos: Map<string, FieldInfo>
  ): {
    maskedRecord: RecordData;
    maskedFields: string[];
  } {
    const maskedRecord: RecordData = {};
    const maskedFields: string[] = [];

    for (const [field, value] of Object.entries(record)) {
      const fieldInfo = fieldInfos.get(field) ?? {
        sobject,
        field,
      };

      const { masked, strategyUsed } = this.maskField(value, fieldInfo, record);
      maskedRecord[field] = masked;

      if (strategyUsed) {
        maskedFields.push(field);
      }
    }

    return { maskedRecord, maskedFields };
  }

  /**
   * Mask a batch of records
   */
  maskRecords(
    sobject: string,
    records: RecordData[],
    fieldInfos: Map<string, FieldInfo>
  ): {
    maskedRecords: RecordData[];
    maskedFieldsCount: number;
    fieldMaskingSummary: Map<string, number>;
  } {
    const maskedRecords: RecordData[] = [];
    const fieldMaskingSummary = new Map<string, number>();
    let maskedFieldsCount = 0;

    for (const record of records) {
      const { maskedRecord, maskedFields } = this.maskRecord(
        sobject,
        record,
        fieldInfos
      );
      maskedRecords.push(maskedRecord);

      for (const field of maskedFields) {
        maskedFieldsCount++;
        fieldMaskingSummary.set(field, (fieldMaskingSummary.get(field) ?? 0) + 1);
      }
    }

    return { maskedRecords, maskedFieldsCount, fieldMaskingSummary };
  }

  /**
   * Generate a preview of masking for sample records
   */
  generatePreview(
    sobject: string,
    sampleRecords: RecordData[],
    fieldInfos: Map<string, FieldInfo>,
    showOriginal: boolean = false
  ): MaskingPreview {
    const samples = sampleRecords.slice(0, 5).map((record) => {
      const recordId = String(record['Id'] ?? 'unknown');
      const fields: MaskingPreview['sampleRecords'][0]['fields'] = [];

      for (const [field, value] of Object.entries(record)) {
        if (field === 'Id') continue;

        const fieldInfo = fieldInfos.get(field) ?? { sobject, field };
        const { masked, strategyUsed } = this.maskField(value, fieldInfo, record);

        if (strategyUsed) {
          fields.push({
            name: field,
            original: showOriginal ? String(value) : undefined,
            masked: String(masked),
            strategy: strategyUsed as MaskingPreview['sampleRecords'][0]['fields'][0]['strategy'],
          });
        }
      }

      return { recordId, fields };
    });

    return { sobject, sampleRecords: samples };
  }

  /**
   * Find the matching rule for a field
   */
  private findMatchingRule(
    fieldInfo: FieldInfo,
    record?: RecordData
  ): MaskingRule | null {
    const cacheKey = `${fieldInfo.sobject}.${fieldInfo.field}`;

    // Check cache (only for non-conditional rules)
    if (!record && this.ruleCache.has(cacheKey)) {
      return this.ruleCache.get(cacheKey) ?? null;
    }

    for (const rule of this.policy.rules) {
      if (this.matchesField(rule.matcher, fieldInfo)) {
        // Check conditions if present
        if (rule.conditions && record) {
          if (!this.evaluateConditions(rule.conditions, record)) {
            continue;
          }
        }

        // Cache if no conditions
        if (!rule.conditions) {
          this.ruleCache.set(cacheKey, rule);
        }

        return rule;
      }
    }

    this.ruleCache.set(cacheKey, null);
    return null;
  }

  /**
   * Check if a field matches a matcher
   */
  private matchesField(matcher: FieldMatcher, fieldInfo: FieldInfo): boolean {
    switch (matcher.type) {
      case 'exact':
        return (
          matcher.sobject === fieldInfo.sobject && matcher.field === fieldInfo.field
        );

      case 'pattern':
        return new RegExp(matcher.fieldNameRegex, 'i').test(fieldInfo.field);

      case 'data_type':
        return fieldInfo.dataType === matcher.sfType;

      case 'classification':
        return fieldInfo.classification?.includes(matcher.tag) ?? false;

      default:
        return false;
    }
  }

  /**
   * Evaluate rule conditions against record data
   */
  private evaluateConditions(
    conditions: RuleCondition[],
    record: RecordData
  ): boolean {
    return conditions.every((condition) => {
      const value = String(record[condition.field] ?? '');

      switch (condition.operator) {
        case 'equals':
          return value === condition.value;
        case 'not_equals':
          return value !== condition.value;
        case 'contains':
          return value.includes(condition.value);
        case 'matches':
          return new RegExp(condition.value).test(value);
        default:
          return false;
      }
    });
  }

  /**
   * Apply a masking strategy to a value
   */
  private applyStrategy(
    value: string | null,
    strategy: MaskingStrategy,
    fieldInfo: FieldInfo
  ): string {
    switch (strategy.type) {
      case 'redact':
        return redact(value, strategy);

      case 'hash':
        // Use format hint for email/phone fields
        if (fieldInfo.dataType === 'email') {
          return hashWithFormatHint(value, { ...strategy, formatHint: 'email' });
        }
        if (fieldInfo.dataType === 'phone') {
          return hashWithFormatHint(value, { ...strategy, formatHint: 'phone' });
        }
        return hash(value, strategy);

      case 'fake':
        return fake(value, strategy);

      case 'fpe':
        return fpeEncrypt(value, strategy);

      case 'tokenize':
        return tokenize(value, strategy);

      case 'preserve':
        return value ?? '';

      default:
        return value ?? '';
    }
  }

  /**
   * Get the current policy
   */
  getPolicy(): MaskingPolicy {
    return this.policy;
  }

  /**
   * Clear the rule cache
   */
  clearCache(): void {
    this.ruleCache.clear();
  }
}

/**
 * Calculate masking effectiveness score
 */
export function calculateEffectivenessScore(
  policy: MaskingPolicy,
  piiFields: FieldInfo[]
): MaskingEffectivenessScore {
  const engine = new MaskingEngine(policy);
  const gaps: MaskingEffectivenessScore['gaps'] = [];
  let maskedCount = 0;

  for (const field of piiFields) {
    const rule = engine['findMatchingRule'](field);

    if (rule && rule.strategy.type !== 'preserve') {
      maskedCount++;
    } else {
      gaps.push({
        sobject: field.sobject,
        field: field.field,
        reason: rule ? 'Preserve strategy used' : 'No matching rule',
        suggestedStrategy: suggestStrategy(field),
      });
    }
  }

  const score =
    piiFields.length > 0 ? Math.round((maskedCount / piiFields.length) * 100) : 100;

  return {
    policyId: policy.id,
    score,
    piiFieldsIdentified: piiFields.length,
    piiFieldsMasked: maskedCount,
    gaps,
    calculatedAt: new Date(),
  };
}

/**
 * Suggest a masking strategy based on field info
 */
function suggestStrategy(field: FieldInfo): MaskingEffectivenessScore['gaps'][0]['suggestedStrategy'] {
  const fieldLower = field.field.toLowerCase();

  if (fieldLower.includes('email')) return 'fake';
  if (fieldLower.includes('phone')) return 'fake';
  if (fieldLower.includes('ssn') || fieldLower.includes('social')) return 'redact';
  if (fieldLower.includes('name')) return 'fake';
  if (fieldLower.includes('address')) return 'fake';
  if (field.dataType === 'email') return 'fake';
  if (field.dataType === 'phone') return 'fake';

  return 'hash';
}
