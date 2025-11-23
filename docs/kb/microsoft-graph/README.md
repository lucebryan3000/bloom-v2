# Microsoft Graph Knowledge Base

```yaml
id: microsoft_graph_readme
topic: Microsoft Graph
file_role: Overview and entry point for Microsoft Graph KB
profile: full
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - JavaScript or TypeScript basics
  - REST API concepts
  - OAuth 2.0 basics
related_topics:
  - Azure (../azure/)
  - PowerShell (../powershell/)
  - TypeScript (../typescript/)
  - Node.js (../nodejs/)
embedding_keywords:
  - microsoft graph
  - graph api
  - microsoft 365
  - azure ad
  - oauth
  - rest api
last_reviewed: 2025-11-17
```

## Welcome to Microsoft Graph KB

Comprehensive knowledge base for **Microsoft Graph API** - the unified gateway to data and intelligence in Microsoft 365, Windows, and Enterprise Mobility + Security.

**Total Content**: 14 files, ~11,000+ lines of production-ready patterns

---

## What is Microsoft Graph?

**Microsoft Graph** is a RESTful web API that enables you to access Microsoft Cloud service resources. After you register your app and get authentication tokens for a user or service, you can make requests to the Microsoft Graph API.

**Key capabilities:**
- **Unified endpoint**: Single endpoint (`https://graph.microsoft.com`) to access data across Microsoft 365
- **Rich data**: Access users, groups, mail, calendars, files, teams, and more
- **Intelligence**: AI-powered insights and recommendations
- **Webhooks**: Real-time change notifications
- **Batching**: Combine multiple requests into a single call

---

## 📚 Documentation Structure (11-Part Series)

### **Quick Navigation**
- **[INDEX.md](./INDEX.md)** - Complete index with learning paths (start here!)
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Cheat sheet for quick lookups
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Integration patterns

### **Core Topics (11 Files)**

| # | Topic | File | Focus | Lines |
|---|-------|------|-------|-------|
| 1 | **Fundamentals** | [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Overview, concepts, getting started | ~800 |
| 2 | **Authentication** | [02-AUTHENTICATION.md](./02-AUTHENTICATION.md) | OAuth, MSAL, tokens, permissions | ~900 |
| 3 | **Users & Groups** | [03-USERS-GROUPS.md](./03-USERS-GROUPS.md) | User management, group operations | ~750 |
| 4 | **Mail & Calendar** | [04-MAIL-CALENDAR.md](./04-MAIL-CALENDAR.md) | Outlook integration, emails, events | ~800 |
| 5 | **Files & Drives** | [05-FILES-DRIVES.md](./05-FILES-DRIVES.md) | OneDrive, SharePoint files | ~750 |
| 6 | **Teams** | [06-TEAMS.md](./06-TEAMS.md) | Microsoft Teams integration | ~700 |
| 7 | **SharePoint** | [07-SHAREPOINT.md](./07-SHAREPOINT.md) | SharePoint sites, lists, content | ~700 |
| 8 | **Batching & Delta** | [08-BATCHING-DELTA.md](./08-BATCHING-DELTA.md) | Batch requests, delta queries | ~650 |
| 9 | **Webhooks** | [09-WEBHOOKS.md](./09-WEBHOOKS.md) | Change notifications, subscriptions | ~700 |
| 10 | **Security** | [10-SECURITY.md](./10-SECURITY.md) | Best practices, rate limiting, errors | ~750 |
| 11 | **SDKs & Tools** | [11-SDKS-TOOLS.md](./11-SDKS-TOOLS.md) | SDKs (JS, Python, .NET), tools | ~800 |

### **Navigation Files**

- **[INDEX.md](./INDEX.md)** - Problem-based navigation
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Quick syntax reference
- **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** - Framework integration

**Total**: ~11,000+ lines of production-ready Microsoft Graph patterns

---

## 🚀 Getting Started

### Prerequisites

```bash
# Install Microsoft Graph SDK
npm install @microsoft/microsoft-graph-client
npm install @azure/msal-node

# Or Python
pip install msgraph-core
pip install msal
```

### Quick Start Example (JavaScript)

```javascript
import { Client } from '@microsoft/microsoft-graph-client';
import { TokenCredentialAuthenticationProvider } from '@microsoft/microsoft-graph-client/authProviders/azureTokenCredentials';
import { ClientSecretCredential } from '@azure/identity';

// Authentication
const credential = new ClientSecretCredential(
  'tenant-id',
  'client-id',
  'client-secret'
);

const authProvider = new TokenCredentialAuthenticationProvider(credential, {
  scopes: ['https://graph.microsoft.com/.default'],
});

// Create Graph client
const client = Client.initWithMiddleware({ authProvider });

// Get user profile
const user = await client.api('/me').get();
console.log(user);

// Get user's messages
const messages = await client.api('/me/messages').get();
console.log(messages.value);
```

---

## 📋 Common Tasks

### "I need to authenticate my app"
1. Read: **[02-AUTHENTICATION.md](./02-AUTHENTICATION.md)** - OAuth, MSAL, tokens
2. Quick: **[QUICK-REFERENCE.md - Authentication](./QUICK-REFERENCE.md#authentication)**

### "I need to access user data"
1. Read: **[03-USERS-GROUPS.md](./03-USERS-GROUPS.md)** - User operations
2. Examples: **[QUICK-REFERENCE.md - Users](./QUICK-REFERENCE.md#users)**

### "I need to send emails"
1. Read: **[04-MAIL-CALENDAR.md](./04-MAIL-CALENDAR.md)** - Mail operations
2. Quick: **[QUICK-REFERENCE.md - Mail](./QUICK-REFERENCE.md#mail)**

### "I need to access files"
1. Read: **[05-FILES-DRIVES.md](./05-FILES-DRIVES.md)** - OneDrive/SharePoint
2. Examples: **[QUICK-REFERENCE.md - Files](./QUICK-REFERENCE.md#files)**

### "I need Teams integration"
1. Read: **[06-TEAMS.md](./06-TEAMS.md)** - Teams API
2. Quick: **[QUICK-REFERENCE.md - Teams](./QUICK-REFERENCE.md#teams)**

### "I need change notifications"
1. Read: **[09-WEBHOOKS.md](./09-WEBHOOKS.md)** - Webhooks
2. Examples: **[QUICK-REFERENCE.md - Webhooks](./QUICK-REFERENCE.md#webhooks)**

---

## 🎯 Key Concepts

### 1. **Unified Endpoint**
```
https://graph.microsoft.com/v1.0/me
https://graph.microsoft.com/v1.0/users
https://graph.microsoft.com/v1.0/groups
```

### 2. **Permissions (Scopes)**
```javascript
// Delegated permissions (user context)
const scopes = ['User.Read', 'Mail.Send', 'Files.ReadWrite'];

// Application permissions (app-only context)
const scopes = ['User.Read.All', 'Mail.Send'];
```

### 3. **Common Patterns**

**Get user profile:**
```javascript
const user = await client.api('/me').get();
```

**Query with filtering:**
```javascript
const users = await client
  .api('/users')
  .filter("startswith(displayName, 'A')")
  .top(10)
  .get();
```

**Batch requests:**
```javascript
const batch = {
  requests: [
    { id: '1', method: 'GET', url: '/me' },
    { id: '2', method: 'GET', url: '/me/messages' },
  ]
};

const response = await client.api('/$batch').post(batch);
```

---

## 📚 Learning Paths

### Path 1: Beginner (New to Microsoft Graph)

**Goal**: Make your first Graph API call

**Files**:
1. [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) - Overview and concepts
2. [02-AUTHENTICATION.md](./02-AUTHENTICATION.md) - Authentication setup
3. [03-USERS-GROUPS.md](./03-USERS-GROUPS.md) - Basic user operations

**Time**: 4-6 hours | **Outcome**: Authenticate and retrieve user data

---

### Path 2: Intermediate (Building integrations)

**Goal**: Build production-ready integrations

**Files**:
1. [04-MAIL-CALENDAR.md](./04-MAIL-CALENDAR.md) - Email and calendar
2. [05-FILES-DRIVES.md](./05-FILES-DRIVES.md) - File operations
3. [06-TEAMS.md](./06-TEAMS.md) - Teams integration
4. [08-BATCHING-DELTA.md](./08-BATCHING-DELTA.md) - Optimization
5. [10-SECURITY.md](./10-SECURITY.md) - Security best practices

**Time**: 8-12 hours | **Outcome**: Build complete Microsoft 365 integrations

---

### Path 3: Advanced (Enterprise scale)

**Goal**: Production-grade enterprise solutions

**Files**:
1. [09-WEBHOOKS.md](./09-WEBHOOKS.md) - Real-time notifications
2. [10-SECURITY.md](./10-SECURITY.md) - Security and compliance
3. [11-SDKS-TOOLS.md](./11-SDKS-TOOLS.md) - Advanced SDK usage
4. [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Integration patterns

**Time**: 12-16 hours | **Outcome**: Enterprise-scale Graph applications

---

## 🔧 API Versions

**v1.0** (Production):
- Stable, generally available APIs
- Recommended for all production apps
- Endpoint: `https://graph.microsoft.com/v1.0`

**beta** (Preview):
- Preview APIs, subject to change
- Not recommended for production
- Endpoint: `https://graph.microsoft.com/beta`

---

## ⚠️ Common Issues & Solutions

### "401 Unauthorized"
**Cause**: Invalid or expired token
**Fix**: Refresh your access token or check permissions

```javascript
// Ensure scopes are correct
const scopes = ['User.Read', 'Mail.Send'];
const token = await getAccessToken(scopes);
```

### "403 Forbidden"
**Cause**: Insufficient permissions
**Fix**: Add required permissions in Azure AD

```javascript
// Check required permissions in error response
// Add permission in Azure Portal -> App registrations -> API permissions
```

### "429 Too Many Requests"
**Cause**: Rate limit exceeded
**Fix**: Implement retry logic with exponential backoff

```javascript
// Use retry-after header
if (response.status === 429) {
  const retryAfter = response.headers.get('retry-after');
  await sleep(retryAfter * 1000);
}
```

### "404 Not Found"
**Cause**: Resource doesn't exist or wrong endpoint
**Fix**: Verify endpoint and resource ID

```javascript
// Check resource exists
const user = await client.api(`/users/${userId}`).get();
```

---

## 📊 Performance Tips

1. **Use batch requests** for multiple operations
2. **Implement delta queries** for incremental changes
3. **Use `$select`** to request only needed properties
4. **Cache tokens** to reduce authentication calls
5. **Use webhooks** instead of polling

---

## 🌐 External Resources

- **Official Docs**: https://learn.microsoft.com/en-us/graph/
- **Graph Explorer**: https://developer.microsoft.com/en-us/graph/graph-explorer
- **SDK Documentation**: https://learn.microsoft.com/en-us/graph/sdks/sdks-overview
- **Samples**: https://github.com/microsoftgraph
- **Postman Collection**: https://www.postman.com/microsoftgraph

---

## 🚀 Next Steps

1. **Getting started?** → Start with [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md)
2. **Need quick reference?** → See [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
3. **Building an app?** → Reference [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
4. **Hit a problem?** → Check [10-SECURITY.md](./10-SECURITY.md) troubleshooting

---

**Last Updated**: November 17, 2025
**API Version**: v1.0 (stable)
**Status**: Production-Ready ✅
