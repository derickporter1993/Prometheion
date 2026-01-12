import jwt from 'jsonwebtoken';

export interface JwtAuthConfig {
  clientId: string;
  username: string;
  privateKey: string;
  loginUrl?: string; // defaults to https://login.salesforce.com
  tokenEndpoint?: string;
}

export interface TokenResponse {
  accessToken: string;
  instanceUrl: string;
  issuedAt: string;
  tokenType: string;
  expiresIn?: number;
}

/**
 * Authenticate using JWT Bearer flow
 * Recommended for service-to-service authentication
 */
export async function authenticateWithJwt(
  config: JwtAuthConfig
): Promise<TokenResponse> {
  const loginUrl = config.loginUrl ?? 'https://login.salesforce.com';
  const tokenEndpoint = config.tokenEndpoint ?? `${loginUrl}/services/oauth2/token`;

  // Create JWT assertion
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: config.clientId,
    sub: config.username,
    aud: loginUrl,
    exp: now + 300, // 5 minutes
  };

  const assertion = jwt.sign(payload, config.privateKey, { algorithm: 'RS256' });

  // Exchange JWT for access token
  const response = await fetch(tokenEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new AuthenticationError(`JWT authentication failed: ${error}`);
  }

  const data = await response.json();

  return {
    accessToken: data.access_token,
    instanceUrl: data.instance_url,
    issuedAt: data.issued_at,
    tokenType: data.token_type,
  };
}

/**
 * Validate JWT configuration
 */
export function validateJwtConfig(config: JwtAuthConfig): string[] {
  const errors: string[] = [];

  if (!config.clientId) {
    errors.push('clientId is required');
  }

  if (!config.username) {
    errors.push('username is required');
  }

  if (!config.privateKey) {
    errors.push('privateKey is required');
  } else if (!config.privateKey.includes('BEGIN') || !config.privateKey.includes('PRIVATE KEY')) {
    errors.push('privateKey must be a valid PEM-formatted RSA private key');
  }

  return errors;
}

export class AuthenticationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AuthenticationError';
  }
}
