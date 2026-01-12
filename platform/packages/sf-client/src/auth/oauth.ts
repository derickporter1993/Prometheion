export interface OAuthConfig {
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  loginUrl?: string;
  scopes?: string[];
}

export interface OAuthTokenResponse {
  accessToken: string;
  refreshToken: string;
  instanceUrl: string;
  id: string; // User info URL
  issuedAt: string;
  tokenType: string;
  signature: string;
}

export interface RefreshTokenResponse {
  accessToken: string;
  instanceUrl: string;
  issuedAt: string;
  tokenType: string;
}

/**
 * Build OAuth authorization URL
 */
export function buildAuthorizationUrl(config: OAuthConfig, state?: string): string {
  const loginUrl = config.loginUrl ?? 'https://login.salesforce.com';
  const scopes = config.scopes ?? ['api', 'refresh_token', 'full'];

  const params = new URLSearchParams({
    response_type: 'code',
    client_id: config.clientId,
    redirect_uri: config.redirectUri,
    scope: scopes.join(' '),
  });

  if (state) {
    params.set('state', state);
  }

  return `${loginUrl}/services/oauth2/authorize?${params.toString()}`;
}

/**
 * Exchange authorization code for tokens
 */
export async function exchangeCodeForTokens(
  config: OAuthConfig,
  code: string
): Promise<OAuthTokenResponse> {
  const loginUrl = config.loginUrl ?? 'https://login.salesforce.com';
  const tokenEndpoint = `${loginUrl}/services/oauth2/token`;

  const response = await fetch(tokenEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: config.clientId,
      client_secret: config.clientSecret,
      redirect_uri: config.redirectUri,
      code,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new OAuthError(`Token exchange failed: ${error}`);
  }

  const data = await response.json();

  return {
    accessToken: data.access_token,
    refreshToken: data.refresh_token,
    instanceUrl: data.instance_url,
    id: data.id,
    issuedAt: data.issued_at,
    tokenType: data.token_type,
    signature: data.signature,
  };
}

/**
 * Refresh an access token
 */
export async function refreshAccessToken(
  config: OAuthConfig,
  refreshToken: string
): Promise<RefreshTokenResponse> {
  const loginUrl = config.loginUrl ?? 'https://login.salesforce.com';
  const tokenEndpoint = `${loginUrl}/services/oauth2/token`;

  const response = await fetch(tokenEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      client_id: config.clientId,
      client_secret: config.clientSecret,
      refresh_token: refreshToken,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new OAuthError(`Token refresh failed: ${error}`);
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
 * Revoke tokens
 */
export async function revokeToken(
  loginUrl: string,
  token: string
): Promise<void> {
  const revokeEndpoint = `${loginUrl}/services/oauth2/revoke`;

  const response = await fetch(revokeEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({ token }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new OAuthError(`Token revocation failed: ${error}`);
  }
}

/**
 * Get user identity from Salesforce
 */
export async function getUserIdentity(
  instanceUrl: string,
  accessToken: string
): Promise<UserIdentity> {
  const response = await fetch(`${instanceUrl}/services/oauth2/userinfo`, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    const error = await response.text();
    throw new OAuthError(`Failed to get user identity: ${error}`);
  }

  const data = await response.json();

  return {
    userId: data.user_id,
    orgId: data.organization_id,
    username: data.preferred_username,
    displayName: data.name,
    email: data.email,
    profileUrl: data.profile,
    pictureUrl: data.picture,
  };
}

export interface UserIdentity {
  userId: string;
  orgId: string;
  username: string;
  displayName: string;
  email: string;
  profileUrl: string;
  pictureUrl?: string;
}

export class OAuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'OAuthError';
  }
}
