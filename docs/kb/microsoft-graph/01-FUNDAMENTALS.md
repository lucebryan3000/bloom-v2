# Microsoft Graph - Fundamentals

```yaml
id: microsoft_graph_01_fundamentals
topic: Microsoft Graph
file_role: Microsoft Graph fundamentals, core concepts, REST API basics
profile: full
difficulty_level: beginner
kb_version: v3.1
prerequisites:
  - REST API concepts
  - HTTP methods (GET, POST, PUT, DELETE)
  - JSON format
related_topics:
  - 02-AUTHENTICATION.md
  - 03-USERS-GROUPS.md
  - QUICK-REFERENCE.md
embedding_keywords:
  - microsoft graph fundamentals
  - graph api basics
  - microsoft 365 api
  - rest api
  - graph endpoints
last_reviewed: 2025-11-17
```

## What is Microsoft Graph?

**Microsoft Graph** is the gateway to data and intelligence in Microsoft 365. It's a unified programmability model that you can use to access the tremendous amount of data in Microsoft 365, Windows, and Enterprise Mobility + Security.

**Key benefits:**
- **Single endpoint**: Access all Microsoft 365 data through one API
- **Unified experience**: Consistent authentication and programming model
- **Rich data**: Users, groups, mail, calendars, files, teams, and more
- **Intelligence**: AI-powered insights and recommendations
- **Real-time updates**: Webhooks for change notifications

**Official documentation**: https://learn.microsoft.com/en-us/graph/

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Your Application                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTPS Requests
                       │ (Authorization: Bearer {token})
                       ▼
┌─────────────────────────────────────────────────────────────┐
│          Microsoft Graph API Endpoint                        │
│          https://graph.microsoft.com/{version}               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                Microsoft 365 Services                        │
│  ┌───────┐ ┌───────┐ ┌────────┐ ┌───────┐ ┌──────────┐    │
│  │ Users │ │ Mail  │ │ Files  │ │ Teams │ │SharePoint│    │
│  └───────┘ └───────┘ └────────┘ └───────┘ └──────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Concepts

### 1. Unified Endpoint

All Microsoft Graph requests use the same base URL:

```
https://graph.microsoft.com/{version}/{resource}
```

**Versions:**
- `v1.0` - Production-ready, stable APIs (recommended)
- `beta` - Preview APIs, subject to change (not for production)

**Examples:**
```http
GET https://graph.microsoft.com/v1.0/me
GET https://graph.microsoft.com/v1.0/users
GET https://graph.microsoft.com/v1.0/groups
GET https://graph.microsoft.com/beta/security/alerts
```

### 2. Resources

Resources are entities (users, groups, files, etc.) that you can interact with:

| Resource | Endpoint | Description |
|----------|----------|-------------|
| User | `/users/{id}` | User profiles and settings |
| Group | `/groups/{id}` | Groups and memberships |
| Mail | `/me/messages` | Email messages |
| Calendar | `/me/events` | Calendar events |
| Drive | `/me/drive` | OneDrive files |
| Site | `/sites/{id}` | SharePoint sites |
| Team | `/teams/{id}` | Microsoft Teams |

### 3. HTTP Methods

Microsoft Graph uses standard HTTP methods:

```http
GET    /users           # Read resources
POST   /users           # Create resources
PATCH  /users/{id}      # Update resources (partial)
PUT    /users/{id}      # Replace resources (full)
DELETE /users/{id}      # Delete resources
```

### 4. Request Structure

**Basic Request:**
```http
GET https://graph.microsoft.com/v1.0/me
Authorization: Bearer {access-token}
Content-Type: application/json
```

**Request with body (POST):**
```http
POST https://graph.microsoft.com/v1.0/me/messages
Authorization: Bearer {access-token}
Content-Type: application/json

{
  "subject": "Hello World",
  "body": {
    "contentType": "Text",
    "content": "This is a test email"
  },
  "toRecipients": [
    {
      "emailAddress": {
        "address": "user@example.com"
      }
    }
  ]
}
```

---

## Authentication Overview

Every request to Microsoft Graph must include an access token:

```http
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

**Two access scenarios:**

### 1. Delegated Access (On behalf of a user)

User signs in, app acts on behalf of user:

```javascript
// User signs in
const authResult = await msalClient.loginPopup({
  scopes: ['User.Read', 'Mail.Send']
});

// Use access token
const accessToken = authResult.accessToken;
```

### 2. App-Only Access (Application permissions)

App runs without a user (background services, automation):

```javascript
// Get app-only token
const credential = new ClientSecretCredential(
  tenantId,
  clientId,
  clientSecret
);

const token = await credential.getToken('https://graph.microsoft.com/.default');
```

---

## Common Operations

### Get Current User Profile

```javascript
// JavaScript SDK
const user = await client.api('/me').get();

console.log(user.displayName);  // "Alice Johnson"
console.log(user.mail);          // "alice@contoso.com"
console.log(user.jobTitle);      // "Software Engineer"
```

**HTTP Request:**
```http
GET https://graph.microsoft.com/v1.0/me
```

**Response:**
```json
{
  "displayName": "Alice Johnson",
  "mail": "alice@contoso.com",
  "jobTitle": "Software Engineer",
  "officeLocation": "Building 1",
  "id": "48d31887-5fad-4d73-a9f5-3c356e68a038"
}
```

### List Users

```javascript
const users = await client.api('/users').get();

users.value.forEach(user => {
  console.log(user.displayName);
});
```

**HTTP Request:**
```http
GET https://graph.microsoft.com/v1.0/users
```

**Response:**
```json
{
  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users",
  "value": [
    {
      "id": "48d31887-5fad-4d73-a9f5-3c356e68a038",
      "displayName": "Alice Johnson",
      "mail": "alice@contoso.com"
    },
    {
      "id": "87d349ed-44d7-43e1-9a83-5f2406dee5bd",
      "displayName": "Bob Smith",
      "mail": "bob@contoso.com"
    }
  ]
}
```

### Get User's Messages

```javascript
const messages = await client
  .api('/me/messages')
  .top(10)
  .get();
```

**HTTP Request:**
```http
GET https://graph.microsoft.com/v1.0/me/messages?$top=10
```

### Create a Calendar Event

```javascript
const event = {
  subject: "Team Meeting",
  start: {
    dateTime: "2025-11-20T10:00:00",
    timeZone: "Pacific Standard Time"
  },
  end: {
    dateTime: "2025-11-20T11:00:00",
    timeZone: "Pacific Standard Time"
  },
  attendees: [
    {
      emailAddress: {
        address: "bob@contoso.com",
        name: "Bob Smith"
      },
      type: "required"
    }
  ]
};

const createdEvent = await client.api('/me/events').post(event);
```

---

## Query Parameters

### $select (Choose properties)

Request only specific properties:

```http
GET /me?$select=displayName,mail,jobTitle
```

```javascript
const user = await client
  .api('/me')
  .select('displayName,mail,jobTitle')
  .get();
```

### $filter (Filter results)

```http
GET /users?$filter=startswith(displayName,'A')
```

```javascript
const users = await client
  .api('/users')
  .filter("startswith(displayName,'A')")
  .get();
```

**Common filter operators:**
- `eq` - Equals: `mail eq 'alice@contoso.com'`
- `ne` - Not equals: `jobTitle ne 'Manager'`
- `startswith` - Starts with: `startswith(displayName,'A')`
- `endswith` - Ends with: `endswith(mail,'@contoso.com')`
- `and` - Logical AND: `jobTitle eq 'Engineer' and officeLocation eq 'Building 1'`
- `or` - Logical OR: `jobTitle eq 'Engineer' or jobTitle eq 'Manager'`

### $orderby (Sort results)

```http
GET /users?$orderby=displayName
```

```javascript
const users = await client
  .api('/users')
  .orderby('displayName')
  .get();
```

### $top (Limit results)

```http
GET /users?$top=10
```

```javascript
const users = await client
  .api('/users')
  .top(10)
  .get();
```

### $skip (Skip results)

```http
GET /users?$skip=20
```

```javascript
const users = await client
  .api('/users')
  .skip(20)
  .get();
```

### $expand (Include related resources)

```http
GET /me?$expand=manager
```

```javascript
const user = await client
  .api('/me')
  .expand('manager')
  .get();

console.log(user.manager.displayName);
```

### $count (Get count)

```http
GET /users?$count=true
```

```javascript
const result = await client
  .api('/users')
  .count()
  .get();

console.log(result['@odata.count']);  // Total number of users
```

### Combining Query Parameters

```javascript
const users = await client
  .api('/users')
  .select('displayName,mail,jobTitle')
  .filter("startswith(displayName,'A')")
  .orderby('displayName')
  .top(10)
  .get();
```

**HTTP Request:**
```http
GET /users?$select=displayName,mail,jobTitle&$filter=startswith(displayName,'A')&$orderby=displayName&$top=10
```

---

## Pagination

Microsoft Graph returns large result sets in pages. Use `@odata.nextLink` to get the next page:

```javascript
let allUsers = [];
let users = await client.api('/users').get();

while (users) {
  allUsers.push(...users.value);

  if (users['@odata.nextLink']) {
    // Get next page
    users = await client.api(users['@odata.nextLink']).get();
  } else {
    break;
  }
}

console.log(`Total users: ${allUsers.length}`);
```

**Response with pagination:**
```json
{
  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users",
  "@odata.nextLink": "https://graph.microsoft.com/v1.0/users?$skiptoken=X'445345....'",
  "value": [
    { "displayName": "User 1" },
    { "displayName": "User 2" }
  ]
}
```

---

## Error Handling

Microsoft Graph returns standard HTTP status codes:

| Code | Meaning | Common Causes |
|------|---------|---------------|
| 200 | OK | Request succeeded |
| 201 | Created | Resource created successfully |
| 204 | No Content | Delete succeeded |
| 400 | Bad Request | Invalid request syntax |
| 401 | Unauthorized | Missing or invalid access token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Service temporarily unavailable |

**Error Response Format:**
```json
{
  "error": {
    "code": "InvalidAuthenticationToken",
    "message": "Access token is empty.",
    "innerError": {
      "date": "2025-11-17T10:30:00",
      "request-id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "client-request-id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    }
  }
}
```

**Error Handling Example:**
```javascript
try {
  const user = await client.api('/users/invalid-id').get();
} catch (error) {
  if (error.statusCode === 404) {
    console.error('User not found');
  } else if (error.statusCode === 401) {
    console.error('Unauthorized - refresh token');
  } else if (error.statusCode === 429) {
    const retryAfter = error.headers.get('retry-after');
    console.error(`Rate limited. Retry after ${retryAfter} seconds`);
  } else {
    console.error(`Error: ${error.message}`);
  }
}
```

---

## Rate Limiting

Microsoft Graph implements throttling to ensure service reliability:

**Limits:**
- Vary by resource and operation
- Typical: ~2000-4000 requests per minute per app
- Includes header: `RateLimit-Limit`, `RateLimit-Remaining`

**Response when throttled:**
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60
```

**Best Practices:**
1. Implement exponential backoff
2. Use batch requests to reduce calls
3. Use delta queries for incremental changes
4. Cache results when possible
5. Monitor `RateLimit-Remaining` header

**Retry Logic:**
```javascript
async function retryRequest(apiCall, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await apiCall();
    } catch (error) {
      if (error.statusCode === 429) {
        const retryAfter = error.headers.get('retry-after') || Math.pow(2, i);
        console.log(`Rate limited. Retrying after ${retryAfter} seconds...`);
        await sleep(retryAfter * 1000);
      } else {
        throw error;
      }
    }
  }
  throw new Error('Max retries exceeded');
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Usage
const user = await retryRequest(() => client.api('/me').get());
```

---

## Best Practices

### 1. Use Specific Permissions

```javascript
// ✅ GOOD - Request only what you need
const scopes = ['User.Read', 'Mail.Send'];

// ❌ BAD - Requesting too many permissions
const scopes = ['User.ReadWrite.All', 'Mail.ReadWrite'];
```

### 2. Use $select to Request Only Needed Properties

```javascript
// ✅ GOOD - Request only needed properties
const user = await client
  .api('/me')
  .select('displayName,mail')
  .get();

// ❌ BAD - Request all properties
const user = await client.api('/me').get();
```

### 3. Use Batch Requests for Multiple Operations

```javascript
// ✅ GOOD - Single batch request
const batch = {
  requests: [
    { id: '1', method: 'GET', url: '/me' },
    { id: '2', method: 'GET', url: '/me/messages' },
  ]
};

const response = await client.api('/$batch').post(batch);

// ❌ BAD - Multiple individual requests
const user = await client.api('/me').get();
const messages = await client.api('/me/messages').get();
```

### 4. Implement Proper Error Handling

```javascript
// ✅ GOOD - Handle errors gracefully
try {
  const user = await client.api('/users/invalid').get();
} catch (error) {
  console.error(`Error ${error.statusCode}: ${error.message}`);
}

// ❌ BAD - No error handling
const user = await client.api('/users/invalid').get();
```

### 5. Use Delta Queries for Large Datasets

```javascript
// ✅ GOOD - Use delta query
let users = await client.api('/users/delta').get();

// Store deltaLink for next sync
const deltaLink = users['@odata.deltaLink'];

// ❌ BAD - Fetch all users every time
const users = await client.api('/users').get();
```

---

## Common Patterns

### Pattern 1: Fetching User Profile

```javascript
async function getUserProfile() {
  try {
    const user = await client
      .api('/me')
      .select('displayName,mail,jobTitle,officeLocation')
      .get();

    return user;
  } catch (error) {
    console.error('Error fetching user profile:', error);
    throw error;
  }
}
```

### Pattern 2: Searching Users

```javascript
async function searchUsers(searchTerm) {
  try {
    const users = await client
      .api('/users')
      .filter(`startswith(displayName,'${searchTerm}') or startswith(mail,'${searchTerm}')`)
      .select('id,displayName,mail,jobTitle')
      .top(20)
      .get();

    return users.value;
  } catch (error) {
    console.error('Error searching users:', error);
    return [];
  }
}
```

### Pattern 3: Handling Pagination

```javascript
async function getAllUsers() {
  let allUsers = [];
  let response = await client.api('/users').top(100).get();

  while (response) {
    allUsers.push(...response.value);

    if (response['@odata.nextLink']) {
      response = await client.api(response['@odata.nextLink']).get();
    } else {
      break;
    }
  }

  return allUsers;
}
```

---

## AI Pair Programming Notes

**When working with Microsoft Graph:**

1. **Always use v1.0 for production** - Beta endpoints may change
2. **Request minimal permissions** - Follow principle of least privilege
3. **Use $select** - Only request properties you need
4. **Implement retry logic** - Handle 429 rate limiting
5. **Cache access tokens** - Reduce authentication calls
6. **Use batch requests** - Combine multiple operations
7. **Handle errors gracefully** - Check status codes
8. **Use delta queries** - For incremental sync of large datasets

**Common mistakes:**
- Not handling pagination (missing `@odata.nextLink`)
- Requesting too many permissions
- Not implementing retry logic for rate limits
- Fetching all properties when only a few are needed
- Using beta endpoints in production

---

**Next**: [02-AUTHENTICATION.md](./02-AUTHENTICATION.md) - OAuth, MSAL, tokens, permissions

---

**Last Updated**: November 17, 2025
**Microsoft Graph Version**: v1.0
**Status**: Production-Ready ✅
