export interface ToolingClientConfig {
  instanceUrl: string;
  accessToken: string;
  apiVersion?: string;
}

export interface FlowDefinition {
  Id: string;
  DeveloperName: string;
  MasterLabel: string;
  ProcessType: string;
  TriggerType?: string;
  TriggerObjectOrEvent?: { QualifiedApiName: string };
  IsActive: boolean;
  VersionNumber: number;
}

export interface ApexTrigger {
  Id: string;
  Name: string;
  TableEnumOrId: string;
  Body: string;
  Status: 'Active' | 'Inactive' | 'Deleted';
  UsageBeforeInsert: boolean;
  UsageAfterInsert: boolean;
  UsageBeforeUpdate: boolean;
  UsageAfterUpdate: boolean;
  UsageBeforeDelete: boolean;
  UsageAfterDelete: boolean;
  UsageAfterUndelete: boolean;
}

export interface WorkflowRule {
  Id: string;
  Name: string;
  TableEnumOrId: string;
  Active: boolean;
  TriggerType: string;
  Description?: string;
}

export interface ValidationRule {
  Id: string;
  EntityDefinitionId: string;
  ValidationName: string;
  Description?: string;
  ErrorConditionFormula: string;
  ErrorMessage: string;
  Active: boolean;
}

export interface RecordType {
  Id: string;
  Name: string;
  DeveloperName: string;
  SobjectType: string;
  IsActive: boolean;
  Description?: string;
}

/**
 * Salesforce Tooling API Client
 * Used for metadata operations like querying flows, triggers, etc.
 */
export class ToolingClient {
  private instanceUrl: string;
  private accessToken: string;
  private apiVersion: string;
  private baseUrl: string;

  constructor(config: ToolingClientConfig) {
    this.instanceUrl = config.instanceUrl;
    this.accessToken = config.accessToken;
    this.apiVersion = config.apiVersion ?? 'v63.0';
    this.baseUrl = `${this.instanceUrl}/services/data/${this.apiVersion}/tooling`;
  }

  /**
   * Execute a Tooling API SOQL query
   */
  async query<T = Record<string, unknown>>(soql: string): Promise<{
    totalSize: number;
    done: boolean;
    records: T[];
  }> {
    const url = `${this.baseUrl}/query?q=${encodeURIComponent(soql)}`;
    return this.request(url);
  }

  /**
   * Get all active Flows/Process Builders for given objects
   */
  async getFlows(sobjects: string[]): Promise<FlowDefinition[]> {
    const soql = `
      SELECT Id, DeveloperName, MasterLabel, ProcessType,
             TriggerType, TriggerObjectOrEvent.QualifiedApiName,
             IsActive, VersionNumber
      FROM FlowDefinitionView
      WHERE TriggerObjectOrEvent.QualifiedApiName IN ('${sobjects.join("','")}')
      AND IsActive = true
    `;

    const result = await this.query<FlowDefinition>(soql);
    return result.records;
  }

  /**
   * Get all Apex Triggers for given objects
   */
  async getTriggers(sobjects: string[]): Promise<ApexTrigger[]> {
    const soql = `
      SELECT Id, Name, TableEnumOrId, Status,
             UsageBeforeInsert, UsageAfterInsert,
             UsageBeforeUpdate, UsageAfterUpdate,
             UsageBeforeDelete, UsageAfterDelete,
             UsageAfterUndelete
      FROM ApexTrigger
      WHERE TableEnumOrId IN ('${sobjects.join("','")}')
      AND Status = 'Active'
    `;

    const result = await this.query<ApexTrigger>(soql);
    return result.records;
  }

  /**
   * Get Workflow Rules for given objects
   */
  async getWorkflowRules(sobjects: string[]): Promise<WorkflowRule[]> {
    const soql = `
      SELECT Id, Name, TableEnumOrId, Active, TriggerType, Description
      FROM WorkflowRule
      WHERE TableEnumOrId IN ('${sobjects.join("','")}')
      AND Active = true
    `;

    const result = await this.query<WorkflowRule>(soql);
    return result.records;
  }

  /**
   * Get Validation Rules for given objects
   */
  async getValidationRules(sobjects: string[]): Promise<ValidationRule[]> {
    const soql = `
      SELECT Id, EntityDefinition.QualifiedApiName, ValidationName,
             Description, ErrorConditionFormula, ErrorMessage, Active
      FROM ValidationRule
      WHERE EntityDefinition.QualifiedApiName IN ('${sobjects.join("','")}')
      AND Active = true
    `;

    const result = await this.query<ValidationRule>(soql);
    return result.records;
  }

  /**
   * Get Record Types for given objects
   */
  async getRecordTypes(sobjects: string[]): Promise<RecordType[]> {
    const soql = `
      SELECT Id, Name, DeveloperName, SobjectType, IsActive, Description
      FROM RecordType
      WHERE SobjectType IN ('${sobjects.join("','")}')
      AND IsActive = true
    `;

    const result = await this.query<RecordType>(soql);
    return result.records;
  }

  /**
   * Get EntityDefinition for schema comparison
   */
  async getEntityDefinitions(sobjects: string[]): Promise<
    Array<{
      QualifiedApiName: string;
      Label: string;
      PluralLabel: string;
      IsCustomSetting: boolean;
      IsCustomizable: boolean;
      KeyPrefix: string;
    }>
  > {
    const soql = `
      SELECT QualifiedApiName, Label, PluralLabel,
             IsCustomSetting, IsCustomizable, KeyPrefix
      FROM EntityDefinition
      WHERE QualifiedApiName IN ('${sobjects.join("','")}')
    `;

    const result = await this.query(soql);
    return result.records as Array<{
      QualifiedApiName: string;
      Label: string;
      PluralLabel: string;
      IsCustomSetting: boolean;
      IsCustomizable: boolean;
      KeyPrefix: string;
    }>;
  }

  /**
   * Get FieldDefinitions for a specific object
   */
  async getFieldDefinitions(sobject: string): Promise<
    Array<{
      QualifiedApiName: string;
      Label: string;
      DataType: string;
      IsCompound: boolean;
      IsFieldHistoryTracked: boolean;
      IsNillable: boolean;
      IsUnique: boolean;
      Precision?: number;
      Scale?: number;
      Length?: number;
      ReferenceTo?: { referenceTo: string[] };
    }>
  > {
    const soql = `
      SELECT QualifiedApiName, Label, DataType, IsCompound,
             IsFieldHistoryTracked, IsNillable, IsUnique,
             Precision, Scale, Length, ReferenceTo
      FROM FieldDefinition
      WHERE EntityDefinition.QualifiedApiName = '${sobject}'
    `;

    const result = await this.query(soql);
    return result.records as Array<{
      QualifiedApiName: string;
      Label: string;
      DataType: string;
      IsCompound: boolean;
      IsFieldHistoryTracked: boolean;
      IsNillable: boolean;
      IsUnique: boolean;
      Precision?: number;
      Scale?: number;
      Length?: number;
      ReferenceTo?: { referenceTo: string[] };
    }>;
  }

  /**
   * Check if org has Shield Platform Encryption enabled
   */
  async hasShieldEncryption(): Promise<boolean> {
    try {
      const soql = `
        SELECT Id FROM EncryptionKeySettings LIMIT 1
      `;
      const result = await this.query(soql);
      return result.totalSize > 0;
    } catch {
      return false;
    }
  }

  /**
   * Get encrypted fields
   */
  async getEncryptedFields(): Promise<
    Array<{
      EntityDefinition: { QualifiedApiName: string };
      QualifiedApiName: string;
      IsEncrypted: boolean;
    }>
  > {
    const soql = `
      SELECT EntityDefinition.QualifiedApiName, QualifiedApiName, IsEncrypted
      FROM FieldDefinition
      WHERE IsEncrypted = true
    `;

    const result = await this.query(soql);
    return result.records as Array<{
      EntityDefinition: { QualifiedApiName: string };
      QualifiedApiName: string;
      IsEncrypted: boolean;
    }>;
  }

  private async request<T>(url: string, options: RequestInit = {}): Promise<T> {
    const response = await fetch(url, {
      ...options,
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
        ...options.headers,
      },
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new ToolingApiError(
        `Tooling API error: ${response.status} ${response.statusText}`,
        response.status,
        errorBody
      );
    }

    return response.json();
  }

  setAccessToken(accessToken: string): void {
    this.accessToken = accessToken;
  }
}

export class ToolingApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public body: string
  ) {
    super(message);
    this.name = 'ToolingApiError';
  }
}
