export interface RestClientConfig {
  instanceUrl: string;
  accessToken: string;
  apiVersion?: string;
}

export interface QueryResult<T = Record<string, unknown>> {
  totalSize: number;
  done: boolean;
  nextRecordsUrl?: string;
  records: T[];
}

export interface DescribeResult {
  name: string;
  label: string;
  labelPlural: string;
  keyPrefix: string;
  custom: boolean;
  createable: boolean;
  updateable: boolean;
  deletable: boolean;
  queryable: boolean;
  fields: FieldDescribe[];
  childRelationships: ChildRelationship[];
}

export interface FieldDescribe {
  name: string;
  label: string;
  type: string;
  length: number;
  precision?: number;
  scale?: number;
  custom: boolean;
  createable: boolean;
  updateable: boolean;
  nillable: boolean;
  unique: boolean;
  externalId: boolean;
  encrypted: boolean;
  referenceTo?: string[];
  relationshipName?: string;
  picklistValues?: PicklistValue[];
}

export interface PicklistValue {
  value: string;
  label: string;
  active: boolean;
  defaultValue: boolean;
}

export interface ChildRelationship {
  childSObject: string;
  field: string;
  relationshipName: string;
  cascadeDelete: boolean;
}

/**
 * Salesforce REST API Client
 */
export class RestClient {
  private instanceUrl: string;
  private accessToken: string;
  private apiVersion: string;
  private baseUrl: string;

  constructor(config: RestClientConfig) {
    this.instanceUrl = config.instanceUrl;
    this.accessToken = config.accessToken;
    this.apiVersion = config.apiVersion ?? 'v63.0';
    this.baseUrl = `${this.instanceUrl}/services/data/${this.apiVersion}`;
  }

  /**
   * Execute a SOQL query
   */
  async query<T = Record<string, unknown>>(soql: string): Promise<QueryResult<T>> {
    const url = `${this.baseUrl}/query?q=${encodeURIComponent(soql)}`;
    return this.request<QueryResult<T>>(url);
  }

  /**
   * Get next page of query results
   */
  async queryMore<T = Record<string, unknown>>(
    nextRecordsUrl: string
  ): Promise<QueryResult<T>> {
    const url = `${this.instanceUrl}${nextRecordsUrl}`;
    return this.request<QueryResult<T>>(url);
  }

  /**
   * Execute query and return all records (handles pagination)
   */
  async queryAll<T = Record<string, unknown>>(soql: string): Promise<T[]> {
    const allRecords: T[] = [];
    let result = await this.query<T>(soql);
    allRecords.push(...result.records);

    while (!result.done && result.nextRecordsUrl) {
      result = await this.queryMore<T>(result.nextRecordsUrl);
      allRecords.push(...result.records);
    }

    return allRecords;
  }

  /**
   * Describe an sObject
   */
  async describe(sobject: string): Promise<DescribeResult> {
    const url = `${this.baseUrl}/sobjects/${sobject}/describe`;
    return this.request<DescribeResult>(url);
  }

  /**
   * Get list of all sObjects
   */
  async describeGlobal(): Promise<{
    encoding: string;
    maxBatchSize: number;
    sobjects: Array<{
      name: string;
      label: string;
      keyPrefix: string;
      custom: boolean;
      createable: boolean;
      queryable: boolean;
    }>;
  }> {
    const url = `${this.baseUrl}/sobjects`;
    return this.request(url);
  }

  /**
   * Get a single record
   */
  async getRecord<T = Record<string, unknown>>(
    sobject: string,
    id: string,
    fields?: string[]
  ): Promise<T> {
    let url = `${this.baseUrl}/sobjects/${sobject}/${id}`;
    if (fields && fields.length > 0) {
      url += `?fields=${fields.join(',')}`;
    }
    return this.request<T>(url);
  }

  /**
   * Create a record
   */
  async createRecord(
    sobject: string,
    data: Record<string, unknown>
  ): Promise<{ id: string; success: boolean; errors: string[] }> {
    const url = `${this.baseUrl}/sobjects/${sobject}`;
    return this.request(url, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Update a record
   */
  async updateRecord(
    sobject: string,
    id: string,
    data: Record<string, unknown>
  ): Promise<void> {
    const url = `${this.baseUrl}/sobjects/${sobject}/${id}`;
    await this.request(url, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Upsert a record using external ID
   */
  async upsertRecord(
    sobject: string,
    externalIdField: string,
    externalIdValue: string,
    data: Record<string, unknown>
  ): Promise<{ id: string; success: boolean; created: boolean }> {
    const url = `${this.baseUrl}/sobjects/${sobject}/${externalIdField}/${externalIdValue}`;
    return this.request(url, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Delete a record
   */
  async deleteRecord(sobject: string, id: string): Promise<void> {
    const url = `${this.baseUrl}/sobjects/${sobject}/${id}`;
    await this.request(url, { method: 'DELETE' });
  }

  /**
   * Get org limits
   */
  async getLimits(): Promise<Record<string, { Max: number; Remaining: number }>> {
    const url = `${this.baseUrl}/limits`;
    return this.request(url);
  }

  /**
   * Get API version info
   */
  async getVersions(): Promise<
    Array<{ label: string; url: string; version: string }>
  > {
    const url = `${this.instanceUrl}/services/data`;
    return this.request(url);
  }

  /**
   * Make authenticated request
   */
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
      throw new RestApiError(
        `Salesforce API error: ${response.status} ${response.statusText}`,
        response.status,
        errorBody
      );
    }

    // Handle 204 No Content
    if (response.status === 204) {
      return undefined as T;
    }

    return response.json();
  }

  /**
   * Update access token (for token refresh)
   */
  setAccessToken(accessToken: string): void {
    this.accessToken = accessToken;
  }
}

export class RestApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public body: string
  ) {
    super(message);
    this.name = 'RestApiError';
  }
}
