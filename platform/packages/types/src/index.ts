/**
 * @platform/types
 *
 * Shared TypeScript types for the Salesforce DevOps Platform
 * Covers: Organizations, Workspaces, Orgs, Sync, Jobs, Masking, Audit
 */

// =============================================================================
// ORGANIZATION & WORKSPACE (Multi-tenancy)
// =============================================================================

export interface Organization {
  id: string;
  name: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Workspace {
  id: string;
  organizationId?: string;
  name: string;
  createdAt: Date;
  updatedAt: Date;
}

export type Role = 'owner' | 'admin' | 'operator' | 'viewer';

export type Permission =
  | 'orgs:connect'
  | 'orgs:disconnect'
  | 'orgs:health'
  | 'sync:plan'
  | 'sync:execute'
  | 'sync:execute:production'
  | 'policies:view'
  | 'policies:edit'
  | 'audit:view'
  | 'approvals:request'
  | 'approvals:decide';

export interface WorkspaceMember {
  id: string;
  workspaceId: string;
  userId: string;
  email: string;
  role: Role;
  permissions: Permission[];
  createdAt: Date;
}

// =============================================================================
// ORG CONNECTION
// =============================================================================

export type OrgType = 'production' | 'sandbox' | 'developer' | 'scratch';

export type AuthMethod = 'jwt_bearer' | 'web_oauth';

export type HealthStatus = 'healthy' | 'degraded' | 'unhealthy' | 'unknown';

export interface OrgConnection {
  id: string;
  workspaceId: string;
  alias: string;
  orgId: string;
  orgType: OrgType;
  instanceUrl: string;
  loginUrl: string;
  credentialRef: string; // Reference to secrets vault
  authMethod: AuthMethod;
  lastHealthCheck?: Date;
  healthStatus: HealthStatus;
  createdAt: Date;
  updatedAt: Date;
}

export interface OrgHealthScore {
  orgId: string;
  overallScore: number; // 0-100
  apiLimits: {
    dailyApiCalls: { used: number; limit: number; percentage: number };
    bulkApiBatches: { used: number; limit: number; percentage: number };
  };
  authStatus: {
    isValid: boolean;
    expiresAt?: Date;
    daysUntilExpiry?: number;
  };
  bulkApiEnabled: boolean;
  toolingApiEnabled: boolean;
  warnings: string[];
  checkedAt: Date;
}

// =============================================================================
// COMPATIBILITY ANALYZER
// =============================================================================

export interface CompatibilityIssue {
  severity: 'error' | 'warning' | 'info';
  category:
    | 'record_type'
    | 'picklist_value'
    | 'validation_rule'
    | 'currency'
    | 'owner'
    | 'person_account'
    | 'shield_encryption'
    | 'formula_field';
  sobject: string;
  field?: string;
  message: string;
  remediation: string;
}

export interface CompatibilityAnalysis {
  id: string;
  sourceOrgId: string;
  targetOrgId: string;
  status: 'passed' | 'warnings' | 'failed';
  issues: CompatibilityIssue[];
  analyzedAt: Date;
}

// =============================================================================
// AUTOMATION IMPACT SCANNER
// =============================================================================

export interface AutomationItem {
  type: 'trigger' | 'flow' | 'process_builder' | 'workflow_rule';
  name: string;
  sobject: string;
  events: string[]; // 'before_insert', 'after_update', etc.
  isActive: boolean;
}

export interface AutomationScan {
  sobject: string;
  triggers: AutomationItem[];
  flows: AutomationItem[];
  processBuilders: AutomationItem[];
  workflowRules: AutomationItem[];
  risk: 'none' | 'low' | 'medium' | 'high';
  recommendation: string;
}

export interface AutomationScanResult {
  id: string;
  targetOrgId: string;
  sobjects: string[];
  scans: AutomationScan[];
  overallRisk: 'none' | 'low' | 'medium' | 'high';
  scannedAt: Date;
}

// =============================================================================
// MASKING POLICIES
// =============================================================================

export type MaskingStrategyType =
  | 'redact'
  | 'hash'
  | 'fake'
  | 'fpe'
  | 'tokenize'
  | 'preserve';

export interface RedactStrategy {
  type: 'redact';
  replacement?: string;
}

export interface HashStrategy {
  type: 'hash';
  algorithm: 'sha256' | 'murmur3';
  salt?: string;
  deterministic: boolean;
}

export interface FakeStrategy {
  type: 'fake';
  generator:
    | 'name'
    | 'first_name'
    | 'last_name'
    | 'email'
    | 'phone'
    | 'address'
    | 'city'
    | 'state'
    | 'zip'
    | 'country'
    | 'company'
    | 'ssn'
    | 'date'
    | 'number'
    | 'text';
  locale?: string;
}

export interface FpeStrategy {
  type: 'fpe';
  keyId: string;
  preserveFormat: boolean;
}

export interface TokenizeStrategy {
  type: 'tokenize';
  vaultRef: string;
}

export interface PreserveStrategy {
  type: 'preserve';
}

export type MaskingStrategy =
  | RedactStrategy
  | HashStrategy
  | FakeStrategy
  | FpeStrategy
  | TokenizeStrategy
  | PreserveStrategy;

export type FieldMatcherType = 'exact' | 'pattern' | 'data_type' | 'classification';

export interface ExactFieldMatcher {
  type: 'exact';
  sobject: string;
  field: string;
}

export interface PatternFieldMatcher {
  type: 'pattern';
  fieldNameRegex: string;
}

export interface DataTypeFieldMatcher {
  type: 'data_type';
  sfType: 'email' | 'phone' | 'url' | 'textarea' | 'string' | 'address';
}

export interface ClassificationFieldMatcher {
  type: 'classification';
  tag: string; // e.g., 'pii', 'pci', 'hipaa'
}

export type FieldMatcher =
  | ExactFieldMatcher
  | PatternFieldMatcher
  | DataTypeFieldMatcher
  | ClassificationFieldMatcher;

export interface MaskingRule {
  id: string;
  matcher: FieldMatcher;
  strategy: MaskingStrategy;
  priority: number;
  conditions?: RuleCondition[];
}

export interface RuleCondition {
  field: string;
  operator: 'equals' | 'not_equals' | 'contains' | 'matches';
  value: string;
}

export interface MaskingPolicy {
  id: string;
  workspaceId: string;
  name: string;
  description?: string;
  version: number;
  rules: MaskingRule[];
  isDefault: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface MaskingPolicyVersion {
  id: string;
  policyId: string;
  version: number;
  rules: MaskingRule[];
  createdBy: string;
  createdAt: Date;
  changeNote?: string;
}

export interface MaskingPreview {
  sobject: string;
  sampleRecords: Array<{
    recordId: string;
    fields: Array<{
      name: string;
      original?: string; // Only for admins
      masked: string;
      strategy: MaskingStrategyType;
    }>;
  }>;
}

export interface MaskingEffectivenessScore {
  policyId: string;
  score: number; // 0-100
  piiFieldsIdentified: number;
  piiFieldsMasked: number;
  gaps: Array<{
    sobject: string;
    field: string;
    reason: string;
    suggestedStrategy: MaskingStrategyType;
  }>;
  comparedToPeers?: {
    percentile: number;
    benchmark: number;
  };
  calculatedAt: Date;
}

// =============================================================================
// SYNC PLANS
// =============================================================================

export type SyncMode = 'prod_subset_masked' | 'sandbox_delta' | 'synthetic_seed';

export type ConflictStrategy =
  | 'source_wins'
  | 'target_wins'
  | 'fail_on_conflict'
  | 'merge_fields';

export type OwnerMappingStrategy =
  | 'match_by_email'
  | 'map_to_default'
  | 'preserve_original'
  | 'fail_if_missing';

export interface ObjectConfig {
  sobject: string;
  filters?: string; // SOQL WHERE clause
  sampling?: {
    type: 'all' | 'random' | 'recent';
    limit?: number;
    orderBy?: string;
  };
  identityStrategy: {
    type: 'external_id' | 'mapping_table';
    externalIdField?: string;
  };
  fieldSelection: {
    type: 'all' | 'selected';
    fields?: string[];
    excludeFields?: string[];
  };
  deferredFields?: string[]; // For multi-pass insertion (circular refs)
}

export interface SyncOptions {
  conflictStrategy: ConflictStrategy;
  conflictThreshold?: number; // Abort if conflicts exceed N
  ownerMapping: OwnerMappingStrategy;
  defaultOwnerId?: string;
  runMode: 'live' | 'dry_run' | 'shadow';
  timeWindow?: {
    startHour: number;
    endHour: number;
    timezone: string;
  };
  apiQuotaGuard?: {
    maxPercentage: number;
    skipIfExceeded: boolean;
  };
  enableSnapshot: boolean;
  snapshotRetentionDays?: number;
}

export interface SyncPlan {
  id: string;
  workspaceId: string;
  name?: string;
  mode: SyncMode;
  sourceOrgId: string;
  targetOrgId: string;
  policyId?: string;
  objects: ObjectConfig[];
  options: SyncOptions;
  estimates?: SyncEstimate;
  graphData?: DependencyGraph;
  createdAt: Date;
  updatedAt: Date;
}

// =============================================================================
// SYNC ESTIMATES & GRAPHS
// =============================================================================

export interface SyncEstimate {
  extractionBatches: number;
  loadBatches: number;
  apiCallsRequired: number;
  estimatedDurationMinutes: {
    min: number;
    max: number;
    confidence: 'low' | 'medium' | 'high';
  };
  recordCounts: {
    sobject: string;
    sourceCount: number;
    filteredCount: number;
    sampledCount: number;
  }[];
  governorLimitUsage: {
    dailyApiCalls: { current: number; limit: number; projected: number };
    bulkApiBatches: { current: number; limit: number; projected: number };
  };
  maskedFieldsCount: number;
  warnings: string[];
  estimatedAt: Date;
}

export interface DependencyNode {
  sobject: string;
  insertionPass: number;
  deferredFields: string[];
  dependencies: string[];
  dependents: string[];
}

export interface DependencyGraph {
  nodes: DependencyNode[];
  edges: Array<{
    from: string;
    to: string;
    relationship: string;
    isCircular: boolean;
  }>;
  insertionPasses: number;
  hasCircularReferences: boolean;
}

// =============================================================================
// NATIVE REFRESH COMPARISON
// =============================================================================

export interface NativeRefreshComparison {
  nativeRefresh: {
    estimatedDuration: string;
    recordsCopied: number;
    piiExposed: number;
    targetConfigDestroyed: boolean;
    source: 'user_input' | 'industry_average';
  };
  ourSync: {
    estimatedDuration: string;
    recordsCopied: number;
    piiMasked: number;
    targetConfigPreserved: boolean;
  };
  savings: {
    timeSaved: string;
    recordsAvoided: number;
    piiProtected: number;
  };
  generatedAt: Date;
}

// =============================================================================
// JOBS
// =============================================================================

export type JobStatus =
  | 'pending'
  | 'queued'
  | 'running'
  | 'completed'
  | 'failed'
  | 'cancelled';

export interface JobProgress {
  phase: 'extracting' | 'transforming' | 'loading' | 'finalizing';
  currentObject?: string;
  currentPass?: number;
  totalPasses?: number;
  objectsCompleted: number;
  objectsTotal: number;
  recordsProcessed: number;
  recordsTotal: number;
  percentage: number;
}

export interface JobSummary {
  recordsExtracted: number;
  recordsTransformed: number;
  recordsLoaded: number;
  recordsFailed: number;
  objectResults: Array<{
    sobject: string;
    extracted: number;
    loaded: number;
    failed: number;
    errors?: string[];
  }>;
  apiCallsUsed: number;
  duration: {
    extraction: number;
    transformation: number;
    loading: number;
    total: number;
  };
  maskedFieldsCount: number;
}

export interface JobArtifacts {
  logs?: string; // URL to log file
  report?: string; // URL to sync report
  diffReport?: string; // URL to delta diff report (sandbox_delta mode)
  shadowOutput?: string; // URL to shadow mode output
  snapshotPackage?: string; // URL to pre-sync snapshot
  mappingTable?: string; // URL to ID mapping CSV
}

export interface Job {
  id: string;
  workspaceId: string;
  planId: string;
  status: JobStatus;
  progress?: JobProgress;
  summary?: JobSummary;
  errorInfo?: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
    failedAt?: string;
  };
  artifacts?: JobArtifacts;
  apiUsage: {
    calls: number;
    bulkBatches: number;
  };
  startedAt?: Date;
  completedAt?: Date;
  createdAt: Date;
  cancelledBy?: string;
  cancelledAt?: Date;
}

// =============================================================================
// APPROVALS
// =============================================================================

export type ApprovalTrigger =
  | 'prod_source'
  | 'record_threshold'
  | 'pii_policy_change'
  | 'manual';

export type ApprovalRule = 'single_approver' | 'two_person';

export interface ApprovalPolicy {
  id: string;
  workspaceId: string;
  name: string;
  triggers: ApprovalTrigger[];
  recordThreshold?: number;
  rule: ApprovalRule;
  approverRoles: Role[];
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export type ApprovalStatus = 'pending' | 'approved' | 'rejected' | 'expired';

export interface ApprovalRequest {
  id: string;
  workspaceId: string;
  policyId: string;
  jobId?: string;
  planId?: string;
  trigger: ApprovalTrigger;
  status: ApprovalStatus;
  requestedBy: string;
  requestedAt: Date;
  decisions: ApprovalDecision[];
  expiresAt?: Date;
}

export interface ApprovalDecision {
  id: string;
  requestId: string;
  decidedBy: string;
  decision: 'approved' | 'rejected';
  comment?: string;
  decidedAt: Date;
}

// =============================================================================
// AUDIT
// =============================================================================

export type AuditAction =
  | 'org.connected'
  | 'org.disconnected'
  | 'org.health_checked'
  | 'policy.created'
  | 'policy.updated'
  | 'policy.deleted'
  | 'plan.created'
  | 'plan.updated'
  | 'job.started'
  | 'job.completed'
  | 'job.failed'
  | 'job.cancelled'
  | 'approval.requested'
  | 'approval.decided'
  | 'secret.accessed'
  | 'secret.rotated'
  | 'member.invited'
  | 'member.removed'
  | 'compatibility.analyzed'
  | 'automation.scanned';

export interface AuditEntry {
  id: string;
  workspaceId: string;
  action: AuditAction;
  actorId: string;
  actorEmail: string;
  resourceType: string;
  resourceId: string;
  metadata?: Record<string, unknown>;
  ipAddress?: string;
  userAgent?: string;
  createdAt: Date;
}

export interface ComplianceTimeline {
  workspaceId: string;
  period: {
    start: Date;
    end: Date;
  };
  maskingCoverage: Array<{
    date: Date;
    score: number;
    piiFieldsTotal: number;
    piiFieldsMasked: number;
  }>;
  policyChanges: Array<{
    date: Date;
    policyId: string;
    policyName: string;
    changeType: 'created' | 'updated' | 'deleted';
    changedBy: string;
  }>;
  syncJobs: Array<{
    date: Date;
    jobId: string;
    mode: SyncMode;
    recordsProcessed: number;
    status: JobStatus;
  }>;
}

// =============================================================================
// API USAGE TRACKING
// =============================================================================

export interface ApiUsageRecord {
  id: string;
  workspaceId: string;
  orgId: string;
  jobId?: string;
  apiCalls: number;
  bulkBatches: number;
  recordedAt: Date;
}

export interface ApiUsageSummary {
  orgId: string;
  period: 'day' | 'week' | 'month';
  totalCalls: number;
  totalBulkBatches: number;
  byJob: Array<{
    jobId: string;
    calls: number;
    bulkBatches: number;
    date: Date;
  }>;
  projection: {
    estimatedMonthlyUsage: number;
    limitPercentage: number;
    warning?: string;
  };
}

// =============================================================================
// TEMPLATES
// =============================================================================

export type TemplateCategory = 'sales_cloud' | 'service_cloud' | 'platform' | 'custom';

export interface SyncTemplate {
  id: string;
  name: string;
  description: string;
  category: TemplateCategory;
  objects: ObjectConfig[];
  defaultPolicyId?: string;
  isPublic: boolean;
  isCurated: boolean; // Official templates
  createdBy?: string;
  usageCount: number;
  rating?: number;
  createdAt: Date;
  updatedAt: Date;
}

// =============================================================================
// PORTFOLIO (Multi-org view)
// =============================================================================

export interface PortfolioOrgSummary {
  orgId: string;
  alias: string;
  orgType: OrgType;
  healthScore: number;
  healthStatus: HealthStatus;
  sandboxCount: number;
  lastSyncAt?: Date;
  lastSyncStatus?: JobStatus;
  apiQuotaUsedPercentage: number;
  warnings: string[];
}

export interface PortfolioSummary {
  organizationId: string;
  productionOrgs: PortfolioOrgSummary[];
  totalSandboxes: number;
  overallHealthScore: number;
  activeJobs: number;
  recentSyncs: Array<{
    jobId: string;
    sourceAlias: string;
    targetAlias: string;
    status: JobStatus;
    completedAt?: Date;
  }>;
  alerts: Array<{
    orgId: string;
    type: 'api_quota' | 'auth_expiry' | 'health_degraded';
    message: string;
    severity: 'warning' | 'critical';
  }>;
}

// =============================================================================
// SSE EVENTS
// =============================================================================

export type JobProgressEventType = 'progress' | 'log' | 'error' | 'complete';

export interface JobProgressEvent {
  type: JobProgressEventType;
  timestamp: Date;
  data:
    | JobProgress
    | { level: 'info' | 'warn' | 'error'; message: string }
    | { status: 'completed' | 'failed'; summary: JobSummary }
    | { code: string; message: string };
}

// =============================================================================
// DRIFT CHECK (MVP-Adjacent)
// =============================================================================

export interface DriftItem {
  category: 'profile' | 'permission_set' | 'custom_setting' | 'org_setting' | 'metadata_count';
  name: string;
  sourceValue: string | number | boolean;
  targetValue: string | number | boolean;
  severity: 'info' | 'warning' | 'critical';
}

export interface DriftCheckResult {
  id: string;
  sourceOrgId: string;
  targetOrgId: string;
  status: 'no_drift' | 'minor_drift' | 'significant_drift';
  driftItems: DriftItem[];
  checkedAt: Date;
}

// =============================================================================
// ID MAPPING (For referential integrity)
// =============================================================================

export interface IdMapping {
  id: string;
  jobId: string;
  sobject: string;
  sourceId: string;
  targetId: string;
  createdAt: Date;
}
