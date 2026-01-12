export interface BulkClientConfig {
  instanceUrl: string;
  accessToken: string;
  apiVersion?: string;
}

export type BulkOperation = 'insert' | 'update' | 'upsert' | 'delete' | 'query';

export type JobState =
  | 'Open'
  | 'UploadComplete'
  | 'InProgress'
  | 'Aborted'
  | 'JobComplete'
  | 'Failed';

export interface BulkJobInfo {
  id: string;
  operation: BulkOperation;
  object: string;
  state: JobState;
  externalIdFieldName?: string;
  createdDate: string;
  systemModstamp: string;
  concurrencyMode: string;
  contentType: string;
  apiVersion: string;
  lineEnding: string;
  columnDelimiter: string;
  numberRecordsProcessed: number;
  numberRecordsFailed: number;
  retries: number;
  totalProcessingTime: number;
  apiActiveProcessingTime: number;
  apexProcessingTime: number;
}

export interface BulkQueryJobInfo extends BulkJobInfo {
  operation: 'query';
}

export interface IngestJobResult {
  id: string;
  success: boolean;
  created: boolean;
  errors?: Array<{ statusCode: string; message: string; fields: string[] }>;
}

/**
 * Salesforce Bulk API 2.0 Client
 */
export class BulkClient {
  private instanceUrl: string;
  private accessToken: string;
  private apiVersion: string;
  private baseUrl: string;

  constructor(config: BulkClientConfig) {
    this.instanceUrl = config.instanceUrl;
    this.accessToken = config.accessToken;
    this.apiVersion = config.apiVersion ?? 'v63.0';
    this.baseUrl = `${this.instanceUrl}/services/data/${this.apiVersion}/jobs`;
  }

  // ==========================================================================
  // INGEST JOBS (Insert, Update, Upsert, Delete)
  // ==========================================================================

  /**
   * Create a new ingest job
   */
  async createIngestJob(params: {
    operation: 'insert' | 'update' | 'upsert' | 'delete';
    object: string;
    externalIdFieldName?: string;
    lineEnding?: 'LF' | 'CRLF';
  }): Promise<BulkJobInfo> {
    const url = `${this.baseUrl}/ingest`;

    const body: Record<string, unknown> = {
      operation: params.operation,
      object: params.object,
      contentType: 'CSV',
      lineEnding: params.lineEnding ?? 'LF',
    };

    if (params.operation === 'upsert' && params.externalIdFieldName) {
      body.externalIdFieldName = params.externalIdFieldName;
    }

    return this.request<BulkJobInfo>(url, {
      method: 'POST',
      body: JSON.stringify(body),
    });
  }

  /**
   * Upload CSV data to a job
   */
  async uploadJobData(jobId: string, csvData: string): Promise<void> {
    const url = `${this.baseUrl}/ingest/${jobId}/batches`;

    await fetch(url, {
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
        'Content-Type': 'text/csv',
      },
      body: csvData,
    });
  }

  /**
   * Close job and start processing
   */
  async closeJob(jobId: string): Promise<BulkJobInfo> {
    const url = `${this.baseUrl}/ingest/${jobId}`;

    return this.request<BulkJobInfo>(url, {
      method: 'PATCH',
      body: JSON.stringify({ state: 'UploadComplete' }),
    });
  }

  /**
   * Abort a job
   */
  async abortJob(jobId: string): Promise<BulkJobInfo> {
    const url = `${this.baseUrl}/ingest/${jobId}`;

    return this.request<BulkJobInfo>(url, {
      method: 'PATCH',
      body: JSON.stringify({ state: 'Aborted' }),
    });
  }

  /**
   * Get job status
   */
  async getJobInfo(jobId: string): Promise<BulkJobInfo> {
    const url = `${this.baseUrl}/ingest/${jobId}`;
    return this.request<BulkJobInfo>(url);
  }

  /**
   * Get successful results
   */
  async getSuccessfulResults(jobId: string): Promise<string> {
    const url = `${this.baseUrl}/ingest/${jobId}/successfulResults`;
    return this.requestText(url);
  }

  /**
   * Get failed results
   */
  async getFailedResults(jobId: string): Promise<string> {
    const url = `${this.baseUrl}/ingest/${jobId}/failedResults`;
    return this.requestText(url);
  }

  /**
   * Get unprocessed records
   */
  async getUnprocessedRecords(jobId: string): Promise<string> {
    const url = `${this.baseUrl}/ingest/${jobId}/unprocessedrecords`;
    return this.requestText(url);
  }

  /**
   * Delete a job
   */
  async deleteJob(jobId: string): Promise<void> {
    const url = `${this.baseUrl}/ingest/${jobId}`;
    await this.request(url, { method: 'DELETE' });
  }

  /**
   * Poll job until complete
   */
  async waitForJobCompletion(
    jobId: string,
    options?: {
      pollIntervalMs?: number;
      timeoutMs?: number;
      onProgress?: (info: BulkJobInfo) => void;
    }
  ): Promise<BulkJobInfo> {
    const pollInterval = options?.pollIntervalMs ?? 2000;
    const timeout = options?.timeoutMs ?? 600000; // 10 minutes default
    const startTime = Date.now();

    while (true) {
      const info = await this.getJobInfo(jobId);

      if (options?.onProgress) {
        options.onProgress(info);
      }

      if (info.state === 'JobComplete' || info.state === 'Failed' || info.state === 'Aborted') {
        return info;
      }

      if (Date.now() - startTime > timeout) {
        throw new BulkApiError(`Job ${jobId} timed out after ${timeout}ms`);
      }

      await new Promise((resolve) => setTimeout(resolve, pollInterval));
    }
  }

  // ==========================================================================
  // QUERY JOBS
  // ==========================================================================

  /**
   * Create a query job
   */
  async createQueryJob(soql: string): Promise<BulkQueryJobInfo> {
    const url = `${this.baseUrl}/query`;

    return this.request<BulkQueryJobInfo>(url, {
      method: 'POST',
      body: JSON.stringify({
        operation: 'query',
        query: soql,
        contentType: 'CSV',
        columnDelimiter: 'COMMA',
        lineEnding: 'LF',
      }),
    });
  }

  /**
   * Get query job status
   */
  async getQueryJobInfo(jobId: string): Promise<BulkQueryJobInfo> {
    const url = `${this.baseUrl}/query/${jobId}`;
    return this.request<BulkQueryJobInfo>(url);
  }

  /**
   * Get query results
   */
  async getQueryResults(
    jobId: string,
    locator?: string,
    maxRecords?: number
  ): Promise<{
    data: string;
    locator?: string;
    numberOfRecords: number;
  }> {
    let url = `${this.baseUrl}/query/${jobId}/results`;
    const params = new URLSearchParams();

    if (locator) params.set('locator', locator);
    if (maxRecords) params.set('maxRecords', maxRecords.toString());

    if (params.toString()) {
      url += `?${params.toString()}`;
    }

    const response = await fetch(url, {
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
        Accept: 'text/csv',
      },
    });

    if (!response.ok) {
      throw new BulkApiError(`Failed to get query results: ${response.statusText}`);
    }

    const data = await response.text();
    const resultLocator = response.headers.get('Sforce-Locator');
    const numberOfRecords = parseInt(
      response.headers.get('Sforce-NumberOfRecords') ?? '0',
      10
    );

    return {
      data,
      locator: resultLocator && resultLocator !== 'null' ? resultLocator : undefined,
      numberOfRecords,
    };
  }

  /**
   * Get all query results (handles pagination)
   */
  async getAllQueryResults(jobId: string): Promise<string[]> {
    const results: string[] = [];
    let locator: string | undefined;

    do {
      const { data, locator: nextLocator } = await this.getQueryResults(
        jobId,
        locator,
        50000
      );
      results.push(data);
      locator = nextLocator;
    } while (locator);

    return results;
  }

  /**
   * Abort a query job
   */
  async abortQueryJob(jobId: string): Promise<BulkQueryJobInfo> {
    const url = `${this.baseUrl}/query/${jobId}`;

    return this.request<BulkQueryJobInfo>(url, {
      method: 'PATCH',
      body: JSON.stringify({ state: 'Aborted' }),
    });
  }

  /**
   * Poll query job until complete
   */
  async waitForQueryJobCompletion(
    jobId: string,
    options?: {
      pollIntervalMs?: number;
      timeoutMs?: number;
      onProgress?: (info: BulkQueryJobInfo) => void;
    }
  ): Promise<BulkQueryJobInfo> {
    const pollInterval = options?.pollIntervalMs ?? 2000;
    const timeout = options?.timeoutMs ?? 600000;
    const startTime = Date.now();

    while (true) {
      const info = await this.getQueryJobInfo(jobId);

      if (options?.onProgress) {
        options.onProgress(info);
      }

      if (info.state === 'JobComplete' || info.state === 'Failed' || info.state === 'Aborted') {
        return info;
      }

      if (Date.now() - startTime > timeout) {
        throw new BulkApiError(`Query job ${jobId} timed out after ${timeout}ms`);
      }

      await new Promise((resolve) => setTimeout(resolve, pollInterval));
    }
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

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
      throw new BulkApiError(
        `Bulk API error: ${response.status} ${response.statusText} - ${errorBody}`
      );
    }

    if (response.status === 204) {
      return undefined as T;
    }

    return response.json();
  }

  private async requestText(url: string): Promise<string> {
    const response = await fetch(url, {
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
        Accept: 'text/csv',
      },
    });

    if (!response.ok) {
      throw new BulkApiError(
        `Bulk API error: ${response.status} ${response.statusText}`
      );
    }

    return response.text();
  }

  /**
   * Update access token
   */
  setAccessToken(accessToken: string): void {
    this.accessToken = accessToken;
  }
}

export class BulkApiError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'BulkApiError';
  }
}
