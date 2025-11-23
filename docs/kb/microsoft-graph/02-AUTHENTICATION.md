# Microsoft Graph - Authentication

```yaml
id: microsoft_graph_02_authentication
topic: Microsoft Graph
file_role: Microsoft Graph authentication, OAuth 2.0, MSAL, permissions, tokens
profile: full
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - 01-FUNDAMENTALS.md
  - OAuth 2.0 concepts
  - Azure AD basics
related_topics:
  - 03-USERS-GROUPS.md
  - 10-SECURITY.md
  - QUICK-REFERENCE.md
embedding_keywords:
  - microsoft graph authentication
  - msal
  - oauth 2.0
  - access tokens
  - delegated permissions
  - application permissions
  - azure ad
last_reviewed: 2025-11-17
```

## Authentication Overview

Microsoft Graph uses **OAuth 2.0** and **OpenID Connect** for authentication and authorization. Every request to Microsoft Graph requires an access token in the `Authorization` header:

```http
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

**Two access scenarios:**
1. **Delegated access** - App acts on behalf of a signed-in user
2. **App-only access** - App runs without a user (background services)

**Official documentation**: https://learn.microsoft.com/en-us/graph/auth/

---

## Permission Types

### 1. Delegated Permissions (Scopes)

Used when a **user is present**. The app calls Microsoft Graph on behalf of the signed-in user.

**Characteristics:**
- Requires user sign-in
- User's permissions determine what app can do
- User can see what permissions app requests
- Lower privilege than application permissions

**Example scopes:**
```javascript
const scopes = [
  'User.Read',           // Read signed-in user's profile
  'Mail.Read',           // Read user's mail
  'Mail.Send',           // Send mail as user
  'Calendars.ReadWrite', // Read and write user's calendars
  'Files.ReadWrite',     // Read and write user's files
];
```

**When to use:**
- Web apps with user sign-in
- Mobile apps
- Single-page applications (SPAs)
- Desktop apps

---

### 2. Application Permissions (App Roles)

Used when **no user is present**. The app calls Microsoft Graph with its own identity.

**Characteristics:**
- No user sign-in required
- Requires admin consent
- App has full access to resource
- Higher privilege than delegated permissions

**Example permissions:**
```javascript
const scopes = [
  'User.Read.All',        // Read all users
  'Mail.Read',            // Read all mailboxes
  'Mail.Send',            // Send mail as any user
  'Calendars.ReadWrite',  // Read/write all calendars
  'Sites.ReadWrite.All',  // Read/write all SharePoint sites
];
```

**When to use:**
- Background services
- Daemon apps
- Server-to-server communication
- Automated tasks without user interaction

---

## Authentication Flows

### 1. Authorization Code Flow (Delegated - Web Apps)

**Best for**: Web applications with a backend server

**Flow:**
```
1. User clicks "Sign in"
2. App redirects to Microsoft login
3. User signs in and consents to permissions
4. Microsoft redirects back with authorization code
5. App exchanges code for access token
6. App uses token to call Microsoft Graph
```

**Implementation (MSAL Node):**

```javascript
import * as msal from '@azure/msal-node';

// Configuration
const config = {
  auth: {
    clientId: 'your-client-id',
    authority: 'https://login.microsoftonline.com/your-tenant-id',
    clientSecret: 'your-client-secret',
  },
  system: {
    loggerOptions: {
      loggerCallback(loglevel, message, containsPii) {
        console.log(message);
      },
      piiLoggingEnabled: false,
      logLevel: msal.LogLevel.Verbose,
    },
  },
};

const pca = new msal.ConfidentialClientApplication(config);

// Get authorization URL
const authCodeUrlParameters = {
  scopes: ['User.Read', 'Mail.Read'],
  redirectUri: 'http://localhost:3000/redirect',
};

const authUrl = await pca.getAuthCodeUrl(authCodeUrlParameters);
// Redirect user to authUrl

// After redirect, exchange code for token
const tokenRequest = {
  code: req.query.code,  // From redirect
  scopes: ['User.Read', 'Mail.Read'],
  redirectUri: 'http://localhost:3000/redirect',
};

const response = await pca.acquireTokenByCode(tokenRequest);
const accessToken = response.accessToken;
```

---

### 2. Implicit Flow (Delegated - SPAs) **[DEPRECATED]**

**⚠️ NOT RECOMMENDED** - Use Authorization Code Flow with PKCE instead

**Why deprecated:**
- Access tokens exposed in browser history
- No refresh tokens
- Less secure than PKCE flow

---

### 3. Authorization Code Flow with PKCE (Delegated - SPAs)

**Best for**: Single-page applications (React, Angular, Vue)

**PKCE** (Proof Key for Code Exchange) adds security to public clients (SPAs, mobile apps).

**Implementation (MSAL Browser):**

```javascript
import * as msal from '@azure/msal-browser';

// Configuration
const msalConfig = {
  auth: {
    clientId: 'your-client-id',
    authority: 'https://login.microsoftonline.com/your-tenant-id',
    redirectUri: 'http://localhost:3000',
  },
  cache: {
    cacheLocation: 'localStorage',
    storeAuthStateInCookie: true,
  },
};

const msalInstance = new msal.PublicClientApplication(msalConfig);

// Sign in
const loginRequest = {
  scopes: ['User.Read', 'Mail.Read'],
};

try {
  // Popup sign-in
  const loginResponse = await msalInstance.loginPopup(loginRequest);
  console.log('ID token:', loginResponse.idToken);

  // Get access token
  const tokenResponse = await msalInstance.acquireTokenSilent({
    scopes: ['User.Read'],
    account: loginResponse.account,
  });

  const accessToken = tokenResponse.accessToken;

  // Use token with Microsoft Graph
  const user = await fetch('https://graph.microsoft.com/v1.0/me', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  }).then(r => r.json());

} catch (error) {
  console.error('Authentication failed:', error);

  // If silent acquisition fails, fall back to interactive
  if (error instanceof msal.InteractionRequiredAuthError) {
    const tokenResponse = await msalInstance.acquireTokenPopup({
      scopes: ['User.Read'],
    });
    const accessToken = tokenResponse.accessToken;
  }
}
```

**Redirect flow (alternative to popup):**

```javascript
// Use redirect instead of popup
await msalInstance.loginRedirect(loginRequest);

// Handle redirect response
msalInstance.handleRedirectPromise().then(response => {
  if (response) {
    const accessToken = response.accessToken;
  }
});
```

---

### 4. Client Credentials Flow (App-Only)

**Best for**: Background services, daemons, server-to-server apps

**Flow:**
```
1. App requests token using client ID + secret
2. Microsoft identity platform validates credentials
3. Returns access token
4. App uses token to call Microsoft Graph
```

**Implementation (MSAL Node):**

```javascript
import * as msal from '@azure/msal-node';

// Configuration
const config = {
  auth: {
    clientId: 'your-client-id',
    authority: 'https://login.microsoftonline.com/your-tenant-id',
    clientSecret: 'your-client-secret',
  },
};

const cca = new msal.ConfidentialClientApplication(config);

// Get token
const tokenRequest = {
  scopes: ['https://graph.microsoft.com/.default'],
};

const response = await cca.acquireTokenByClientCredential(tokenRequest);
const accessToken = response.accessToken;

// Use token
const users = await fetch('https://graph.microsoft.com/v1.0/users', {
  headers: {
    Authorization: `Bearer ${accessToken}`,
  },
}).then(r => r.json());
```

**Using Azure SDK (alternative):**

```javascript
import { ClientSecretCredential } from '@azure/identity';
import { Client } from '@microsoft/microsoft-graph-client';
import { TokenCredentialAuthenticationProvider } from '@microsoft/microsoft-graph-client/authProviders/azureTokenCredentials';

const credential = new ClientSecretCredential(
  'tenant-id',
  'client-id',
  'client-secret'
);

const authProvider = new TokenCredentialAuthenticationProvider(credential, {
  scopes: ['https://graph.microsoft.com/.default'],
});

const client = Client.initWithMiddleware({ authProvider });

const users = await client.api('/users').get();
```

---

### 5. On-Behalf-Of Flow (Delegated - Middle Tier)

**Best for**: Middle-tier services that call Microsoft Graph on behalf of a user

**Scenario**: Web API needs to call Microsoft Graph with user's identity

**Implementation:**

```javascript
const tokenRequest = {
  oboAssertion: req.headers.authorization.split(' ')[1],  // User's token
  scopes: ['User.Read', 'Mail.Read'],
};

const response = await cca.acquireTokenOnBehalfOf(tokenRequest);
const accessToken = response.accessToken;
```

---

### 6. Device Code Flow (Delegated - Devices without Browser)

**Best for**: Devices with limited input (IoT, CLI tools)

**Flow:**
```
1. App requests device code
2. User visits URL on another device
3. User enters code and signs in
4. App polls for token
5. Returns access token when user completes sign-in
```

**Implementation:**

```javascript
const deviceCodeRequest = {
  scopes: ['User.Read'],
  deviceCodeCallback: (response) => {
    console.log(response.message);
    // User sees: "To sign in, use a web browser to open https://microsoft.com/devicelogin and enter the code ABCD1234"
  },
};

const response = await pca.acquireTokenByDeviceCode(deviceCodeRequest);
const accessToken = response.accessToken;
```

---

## App Registration (Azure Portal)

### Step 1: Register Application

1. Go to **Azure Portal** → **Azure Active Directory** → **App registrations**
2. Click **New registration**
3. Enter:
   - **Name**: Your app name
   - **Supported account types**: Choose who can use your app
   - **Redirect URI**: Where Microsoft redirects after sign-in

### Step 2: Configure Permissions

1. Go to **API permissions** → **Add a permission** → **Microsoft Graph**
2. Choose permission type:
   - **Delegated permissions** - For apps with signed-in users
   - **Application permissions** - For apps without users
3. Select specific permissions
4. Click **Grant admin consent** (required for application permissions)

**Common delegated permissions:**
- `User.Read` - Read signed-in user's profile
- `Mail.Read` - Read user's mail
- `Mail.Send` - Send mail as user
- `Calendars.ReadWrite` - Read/write user's calendars
- `Files.ReadWrite` - Read/write user's files

**Common application permissions:**
- `User.Read.All` - Read all users' profiles
- `Mail.Read` - Read mail in all mailboxes
- `Mail.Send` - Send mail as any user
- `Sites.ReadWrite.All` - Read/write all site collections

### Step 3: Create Client Secret (for confidential apps)

1. Go to **Certificates & secrets** → **New client secret**
2. Enter description and expiration
3. Copy secret value (only shown once!)

### Step 4: Note Application Details

Save these values:
- **Application (client) ID**: Unique app identifier
- **Directory (tenant) ID**: Your Azure AD tenant
- **Client secret**: For confidential apps
- **Redirect URI**: Where to send users after sign-in

---

## Token Management

### Access Tokens

Access tokens are short-lived (default: 1 hour) JWT tokens:

```
eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik1yNS1BVWliZk...
```

**Decoded token structure:**
```json
{
  "aud": "https://graph.microsoft.com",
  "iss": "https://sts.windows.net/{tenant}/",
  "iat": 1700000000,
  "exp": 1700003600,
  "scp": "User.Read Mail.Read",
  "sub": "user-object-id",
  "tid": "tenant-id"
}
```

**Key claims:**
- `aud` - Audience (must be `https://graph.microsoft.com`)
- `exp` - Expiration time (Unix timestamp)
- `scp` - Scopes (delegated permissions)
- `roles` - Roles (application permissions)

---

### Refresh Tokens

Refresh tokens allow you to get new access tokens without user interaction:

**Characteristics:**
- Long-lived (90 days by default, can be extended)
- Used to get new access tokens
- Revoked when user changes password or revokes consent

**Getting a refresh token:**

```javascript
const loginResponse = await msalInstance.loginPopup({
  scopes: ['User.Read', 'offline_access'],  // offline_access = refresh token
});

// MSAL automatically handles refresh tokens
```

**Using refresh token to get new access token:**

```javascript
// MSAL handles this automatically with acquireTokenSilent
const tokenResponse = await msalInstance.acquireTokenSilent({
  scopes: ['User.Read'],
  account: currentAccount,
});

// If silent acquisition fails, fall back to interactive
```

---

### Token Caching

**MSAL automatically caches tokens** in memory, session storage, or local storage.

**Best practices:**
1. Always try `acquireTokenSilent` first
2. Fall back to interactive methods if silent fails
3. Clear cache on sign-out

```javascript
// Get token silently (uses cache)
try {
  const response = await msalInstance.acquireTokenSilent({
    scopes: ['User.Read'],
    account: currentAccount,
  });
  const accessToken = response.accessToken;
} catch (error) {
  if (error instanceof msal.InteractionRequiredAuthError) {
    // Token expired or not in cache - need user interaction
    const response = await msalInstance.acquireTokenPopup({
      scopes: ['User.Read'],
    });
    const accessToken = response.accessToken;
  }
}
```

---

### Token Validation

**Never validate tokens yourself in production** - use Microsoft libraries.

**For debugging, check:**
1. Token not expired: `exp` > current time
2. Correct audience: `aud` = `https://graph.microsoft.com`
3. Required scopes present: `scp` or `roles` contains needed permissions

---

## Permission Consent

### User Consent

**Static consent** - Request all permissions at sign-in:

```javascript
const loginRequest = {
  scopes: ['User.Read', 'Mail.Read', 'Calendars.ReadWrite'],
};

await msalInstance.loginPopup(loginRequest);
```

**Incremental consent** - Request permissions as needed:

```javascript
// Initial sign-in - minimal permissions
await msalInstance.loginPopup({ scopes: ['User.Read'] });

// Later, request additional permission
const tokenResponse = await msalInstance.acquireTokenPopup({
  scopes: ['Mail.Read'],  // User consents to new permission
});
```

**Dynamic consent** - Request permissions based on user actions:

```javascript
function sendEmail() {
  // Request Mail.Send only when user tries to send email
  const tokenResponse = await msalInstance.acquireTokenPopup({
    scopes: ['Mail.Send'],
  });
}
```

---

### Admin Consent

Some permissions require **admin consent**:
- All application permissions
- High-privilege delegated permissions

**Admin consent flow:**

```javascript
const adminConsentUrl = `https://login.microsoftonline.com/{tenant}/adminconsent?client_id={client-id}&redirect_uri={redirect-uri}`;

// Admin visits this URL and grants consent for entire organization
```

**Check if admin consent granted:**

```javascript
const authResponse = await msalInstance.loginPopup({
  scopes: ['User.Read.All'],  // Requires admin consent
});

// If admin hasn't consented, user will see error
```

---

## Security Best Practices

### 1. Use Least Privilege Permissions

```javascript
// ✅ GOOD - Request only what you need
const scopes = ['User.Read', 'Mail.Send'];

// ❌ BAD - Requesting too many permissions
const scopes = ['User.ReadWrite.All', 'Mail.ReadWrite', 'Files.ReadWrite.All'];
```

### 2. Store Secrets Securely

```javascript
// ✅ GOOD - Use environment variables
const clientSecret = process.env.CLIENT_SECRET;

// ❌ BAD - Hardcoded secret
const clientSecret = 'abc123secret';
```

### 3. Validate Redirect URIs

```javascript
// ✅ GOOD - Whitelist redirect URIs in Azure Portal
const config = {
  auth: {
    redirectUri: 'https://yourdomain.com/callback',  // Must match Azure Portal
  },
};

// ❌ BAD - Dynamic redirect URIs
const redirectUri = req.query.redirect;  // Security risk!
```

### 4. Use HTTPS in Production

```javascript
// ✅ GOOD - HTTPS redirect URI
redirectUri: 'https://yourdomain.com/callback'

// ❌ BAD - HTTP (except localhost for dev)
redirectUri: 'http://yourdomain.com/callback'
```

### 5. Implement Token Expiration Handling

```javascript
// ✅ GOOD - Handle token expiration
try {
  const response = await msalInstance.acquireTokenSilent(request);
} catch (error) {
  if (error instanceof msal.InteractionRequiredAuthError) {
    await msalInstance.acquireTokenPopup(request);
  }
}

// ❌ BAD - No expiration handling
const response = await msalInstance.acquireTokenSilent(request);
```

### 6. Clear Tokens on Sign-Out

```javascript
// ✅ GOOD - Clear cache on sign-out
await msalInstance.logoutPopup({
  account: currentAccount,
});

// ❌ BAD - Leave tokens in cache
// No sign-out logic
```

---

## Common Patterns

### Pattern 1: Initialize MSAL (SPA)

```javascript
import * as msal from '@azure/msal-browser';

const msalConfig = {
  auth: {
    clientId: process.env.REACT_APP_CLIENT_ID,
    authority: `https://login.microsoftonline.com/${process.env.REACT_APP_TENANT_ID}`,
    redirectUri: window.location.origin,
  },
  cache: {
    cacheLocation: 'localStorage',
    storeAuthStateInCookie: true,
  },
};

export const msalInstance = new msal.PublicClientApplication(msalConfig);

// Initialize
await msalInstance.initialize();
```

### Pattern 2: Acquire Token (Web API)

```javascript
async function getGraphToken(req, res) {
  try {
    const tokenResponse = await cca.acquireTokenByCode({
      code: req.query.code,
      scopes: ['User.Read'],
      redirectUri: 'http://localhost:3000/redirect',
    });

    return tokenResponse.accessToken;
  } catch (error) {
    console.error('Token acquisition failed:', error);
    throw error;
  }
}
```

### Pattern 3: Background Service

```javascript
import { ClientSecretCredential } from '@azure/identity';

async function getAppOnlyToken() {
  const credential = new ClientSecretCredential(
    process.env.TENANT_ID,
    process.env.CLIENT_ID,
    process.env.CLIENT_SECRET
  );

  const token = await credential.getToken('https://graph.microsoft.com/.default');
  return token.token;
}
```

---

## Troubleshooting

### "AADSTS65001: The user or administrator has not consented"

**Cause**: Missing permissions or consent

**Solution**:
1. Ensure permissions added in Azure Portal
2. Grant admin consent for application permissions
3. User must consent for delegated permissions

---

### "AADSTS70011: The provided request must include a 'scope' input parameter"

**Cause**: Missing scopes in token request

**Solution**:
```javascript
// Add scopes to request
const tokenRequest = {
  scopes: ['https://graph.microsoft.com/.default'],
};
```

---

### "Invalid client secret"

**Cause**: Wrong client secret or expired

**Solution**:
1. Generate new secret in Azure Portal
2. Update environment variable
3. Ensure secret not expired

---

## AI Pair Programming Notes

**When implementing authentication:**

1. **Use MSAL libraries** - Don't implement OAuth yourself
2. **Choose correct flow** - Based on app type (SPA, web app, daemon)
3. **Request minimal permissions** - Least privilege principle
4. **Handle token expiration** - Always try silent acquisition first
5. **Secure client secrets** - Use environment variables
6. **Grant admin consent** - Required for application permissions
7. **Clear tokens on sign-out** - Security best practice

**Common mistakes:**
- Using implicit flow (deprecated - use PKCE instead)
- Hardcoding client secrets
- Not handling token expiration
- Requesting too many permissions
- Not validating redirect URIs

---

**Next**: [03-USERS-GROUPS.md](./03-USERS-GROUPS.md) - User management, group operations

---

**Last Updated**: November 17, 2025
**MSAL Version**: Latest stable
**Status**: Production-Ready ✅
