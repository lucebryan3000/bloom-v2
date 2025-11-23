---
id: nextauth-02-providers
topic: nextauth
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [nextauth-fundamentals]
related_topics: [oauth, authentication, providers]
embedding_keywords: [nextauth, providers, oauth, google, github, credentials]
last_reviewed: 2025-11-16
---

# NextAuth.js - Authentication Providers

## Purpose

Comprehensive guide to configuring and using authentication providers in NextAuth.js including OAuth providers (Google, GitHub, etc.), credentials, email magic links, and custom providers.

## Table of Contents

1. [Provider Basics](#provider-basics)
2. [OAuth Providers](#oauth-providers)
3. [Credentials Provider](#credentials-provider)
4. [Email Provider](#email-provider)
5. [Custom Providers](#custom-providers)
6. [Provider Configuration](#provider-configuration)

---

## Provider Basics

### What are Providers?

Providers are authentication methods that NextAuth.js supports out of the box.

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'
import GoogleProvider from 'next-auth/providers/google'
import GitHubProvider from 'next-auth/providers/github'

export const authOptions = {
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
    GitHubProvider({
      clientId: process.env.GITHUB_ID!,
      clientSecret: process.env.GITHUB_SECRET!,
    }),
  ],
}

const handler = NextAuth(authOptions)
export { handler as GET, handler as POST }
```

### Provider Types

```typescript
// OAuth Providers (recommended for most use cases)
- Google, GitHub, Facebook, Twitter, etc.
- 75+ built-in providers
- Secure, battle-tested
- No password management

// Credentials Provider (username/password)
- Custom authentication logic
- Requires session strategy: 'jwt'
- You manage passwords (hashing, security)
- More control, more responsibility

// Email Provider (magic links)
- Passwordless authentication
- Send login links via email
- No password management
- Requires email sending service

// Custom Providers
- Build your own OAuth provider
- Integrate proprietary systems
- Full control over flow
```

---

## OAuth Providers

### Google Provider

```typescript
import GoogleProvider from 'next-auth/providers/google'

GoogleProvider({
  clientId: process.env.GOOGLE_CLIENT_ID!,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
  authorization: {
    params: {
      prompt: "consent",
      access_type: "offline",
      response_type: "code"
    }
  }
})
```

**Setup Steps:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URI: `http://localhost:3000/api/auth/callback/google`
6. Save Client ID and Client Secret to `.env.local`

```env
GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret
```

### GitHub Provider

```typescript
import GitHubProvider from 'next-auth/providers/github'

GitHubProvider({
  clientId: process.env.GITHUB_ID!,
  clientSecret: process.env.GITHUB_SECRET!,
  // Request additional scopes
  authorization: {
    params: {
      scope: 'read:user user:email'
    }
  }
})
```

**Setup Steps:**
1. Go to GitHub Settings → Developer settings → OAuth Apps
2. Click "New OAuth App"
3. Set Homepage URL: `http://localhost:3000`
4. Set Authorization callback URL: `http://localhost:3000/api/auth/callback/github`
5. Save Client ID and Client Secret

```env
GITHUB_ID=your_github_client_id
GITHUB_SECRET=your_github_client_secret
```

### Facebook Provider

```typescript
import FacebookProvider from 'next-auth/providers/facebook'

FacebookProvider({
  clientId: process.env.FACEBOOK_CLIENT_ID!,
  clientSecret: process.env.FACEBOOK_CLIENT_SECRET!,
})
```

### Twitter Provider

```typescript
import TwitterProvider from 'next-auth/providers/twitter'

TwitterProvider({
  clientId: process.env.TWITTER_CLIENT_ID!,
  clientSecret: process.env.TWITTER_CLIENT_SECRET!,
  version: "2.0", // Use OAuth 2.0
})
```

### Discord Provider

```typescript
import DiscordProvider from 'next-auth/providers/discord'

DiscordProvider({
  clientId: process.env.DISCORD_CLIENT_ID!,
  clientSecret: process.env.DISCORD_CLIENT_SECRET!,
})
```

### Microsoft (Azure AD) Provider

```typescript
import AzureADProvider from 'next-auth/providers/azure-ad'

AzureADProvider({
  clientId: process.env.AZURE_AD_CLIENT_ID!,
  clientSecret: process.env.AZURE_AD_CLIENT_SECRET!,
  tenantId: process.env.AZURE_AD_TENANT_ID!,
})
```

### Okta Provider

```typescript
import OktaProvider from 'next-auth/providers/okta'

OktaProvider({
  clientId: process.env.OKTA_CLIENT_ID!,
  clientSecret: process.env.OKTA_CLIENT_SECRET!,
  issuer: process.env.OKTA_ISSUER!, // https://your-domain.okta.com
})
```

---

## Credentials Provider

### Basic Credentials Authentication

```typescript
import CredentialsProvider from 'next-auth/providers/credentials'
import bcrypt from 'bcryptjs'

CredentialsProvider({
  name: 'Credentials',
  credentials: {
    email: { label: "Email", type: "email", placeholder: "you@example.com" },
    password: { label: "Password", type: "password" }
  },
  async authorize(credentials, req) {
    if (!credentials?.email || !credentials?.password) {
      throw new Error('Missing credentials')
    }

    // Find user in database
    const user = await db.user.findUnique({
      where: { email: credentials.email }
    })

    if (!user) {
      throw new Error('No user found')
    }

    // Verify password
    const isValid = await bcrypt.compare(credentials.password, user.password)

    if (!isValid) {
      throw new Error('Invalid password')
    }

    // Return user object (will be encoded in JWT)
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    }
  }
})
```

**Important Notes:**
- Credentials provider REQUIRES `session: { strategy: 'jwt' }`
- You are responsible for password hashing and security
- No automatic CSRF protection
- Consider using OAuth providers instead when possible

### With Custom Fields

```typescript
CredentialsProvider({
  name: 'Credentials',
  credentials: {
    username: { label: "Username", type: "text" },
    password: { label: "Password", type: "password" },
    rememberMe: { label: "Remember me", type: "checkbox" }
  },
  async authorize(credentials) {
    const user = await authenticateUser(credentials)

    if (user) {
      return {
        id: user.id,
        email: user.email,
        name: user.name,
      }
    }

    return null
  }
})
```

### Password Hashing

```typescript
import bcrypt from 'bcryptjs'

// Register new user
export async function registerUser(email: string, password: string) {
  // Hash password
  const hashedPassword = await bcrypt.hash(password, 12)

  // Save to database
  const user = await db.user.create({
    data: {
      email,
      password: hashedPassword,
    }
  })

  return user
}

// Verify password
export async function verifyPassword(plainPassword: string, hashedPassword: string) {
  return await bcrypt.compare(plainPassword, hashedPassword)
}
```

---

## Email Provider

### Basic Email (Magic Link)

```typescript
import EmailProvider from 'next-auth/providers/email'

EmailProvider({
  server: {
    host: process.env.EMAIL_SERVER_HOST,
    port: process.env.EMAIL_SERVER_PORT,
    auth: {
      user: process.env.EMAIL_SERVER_USER,
      pass: process.env.EMAIL_SERVER_PASSWORD
    }
  },
  from: process.env.EMAIL_FROM
})
```

**Environment Variables:**
```env
EMAIL_SERVER_HOST=smtp.example.com
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER=your_username
EMAIL_SERVER_PASSWORD=your_password
EMAIL_FROM=noreply@example.com
```

### Using Nodemailer

```typescript
import EmailProvider from 'next-auth/providers/email'
import nodemailer from 'nodemailer'

EmailProvider({
  server: {
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT),
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASSWORD,
    },
  },
  from: process.env.EMAIL_FROM,
})
```

### Using SendGrid

```typescript
import EmailProvider from 'next-auth/providers/email'
import { createTransport } from 'nodemailer'

EmailProvider({
  server: {
    host: 'smtp.sendgrid.net',
    port: 587,
    auth: {
      user: 'apikey',
      pass: process.env.SENDGRID_API_KEY,
    },
  },
  from: process.env.EMAIL_FROM,
})
```

### Custom Email Template

```typescript
EmailProvider({
  server: process.env.EMAIL_SERVER,
  from: process.env.EMAIL_FROM,
  sendVerificationRequest({
    identifier: email,
    url,
    provider,
  }) {
    return sendCustomEmail({ email, url })
  },
})

async function sendCustomEmail({ email, url }: { email: string; url: string }) {
  const { host } = new URL(url)

  const transport = createTransport(provider.server)

  await transport.sendMail({
    to: email,
    from: provider.from,
    subject: `Sign in to ${host}`,
    text: `Sign in to ${host}\n${url}\n\n`,
    html: `
      <div style="font-family: Arial, sans-serif;">
        <h1>Sign in to ${host}</h1>
        <p>Click the link below to sign in:</p>
        <a href="${url}" style="background: #0070f3; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          Sign In
        </a>
      </div>
    `,
  })
}
```

---

## Custom Providers

### Custom OAuth Provider

```typescript
{
  id: "custom-oauth",
  name: "Custom OAuth Provider",
  type: "oauth",
  authorization: {
    url: "https://provider.com/oauth/authorize",
    params: {
      scope: "openid email profile",
      response_type: "code",
    }
  },
  token: "https://provider.com/oauth/token",
  userinfo: "https://provider.com/oauth/userinfo",
  clientId: process.env.CUSTOM_CLIENT_ID,
  clientSecret: process.env.CUSTOM_CLIENT_SECRET,
  profile(profile) {
    return {
      id: profile.sub,
      name: profile.name,
      email: profile.email,
      image: profile.picture,
    }
  },
}
```

### OIDC Provider

```typescript
{
  id: "custom-oidc",
  name: "Custom OIDC",
  type: "oidc",
  issuer: "https://your-issuer.com",
  clientId: process.env.OIDC_CLIENT_ID,
  clientSecret: process.env.OIDC_CLIENT_SECRET,
}
```

---

## Provider Configuration

### Multiple Providers

```typescript
export const authOptions = {
  providers: [
    // OAuth providers
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
    GitHubProvider({
      clientId: process.env.GITHUB_ID!,
      clientSecret: process.env.GITHUB_SECRET!,
    }),

    // Credentials
    CredentialsProvider({
      name: 'Email & Password',
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" }
      },
      async authorize(credentials) {
        // Your auth logic
      }
    }),

    // Email magic link
    EmailProvider({
      server: process.env.EMAIL_SERVER,
      from: process.env.EMAIL_FROM,
    }),
  ],
  session: {
    strategy: 'jwt', // Required for credentials provider
  },
}
```

### Provider Priority

```typescript
// Providers are shown in the order they appear
providers: [
  GoogleProvider({ /* ... */ }),    // Shown first
  GitHubProvider({ /* ... */ }),    // Shown second
  CredentialsProvider({ /* ... */ }), // Shown last
]
```

### Conditional Providers

```typescript
const providers = [
  GoogleProvider({
    clientId: process.env.GOOGLE_CLIENT_ID!,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
  }),
]

// Add GitHub only in production
if (process.env.NODE_ENV === 'production') {
  providers.push(
    GitHubProvider({
      clientId: process.env.GITHUB_ID!,
      clientSecret: process.env.GITHUB_SECRET!,
    })
  )
}

export const authOptions = {
  providers,
}
```

---

## Best Practices

### 1. Use Environment Variables

```typescript
// ✅ Good - Secure
GoogleProvider({
  clientId: process.env.GOOGLE_CLIENT_ID!,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
})

// ❌ Bad - Exposed secrets
GoogleProvider({
  clientId: "123456789.apps.googleusercontent.com",
  clientSecret: "your-secret-here",
})
```

### 2. Validate Provider Responses

```typescript
GoogleProvider({
  clientId: process.env.GOOGLE_CLIENT_ID!,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
  profile(profile) {
    // Validate and transform profile data
    return {
      id: profile.sub,
      name: profile.name || 'Unknown',
      email: profile.email,
      image: profile.picture,
      // Add custom fields
      emailVerified: profile.email_verified,
    }
  },
})
```

### 3. Handle Provider Errors

```typescript
callbacks: {
  async signIn({ user, account, profile }) {
    if (account?.provider === 'google') {
      // Verify email is from allowed domain
      if (!user.email?.endsWith('@company.com')) {
        return false // Deny sign in
      }
    }
    return true
  }
}
```

---

## AI Pair Programming Notes

**When to load this file:**
- Setting up authentication providers
- Configuring OAuth (Google, GitHub, etc.)
- Implementing credentials authentication
- Adding email magic links
- Creating custom providers

**Typical questions:**
- "How do I add Google authentication?" → See OAuth Providers → Google Provider
- "How do I implement username/password login?" → See Credentials Provider
- "How do I send magic links?" → See Email Provider
- "How do I create a custom OAuth provider?" → See Custom Providers

**Next steps:**
- [03-SESSIONS.md](./03-SESSIONS.md) - Session management
- [04-JWT-VS-DATABASE.md](./04-JWT-VS-DATABASE.md) - Session strategies
- [10-INTEGRATIONS.md](./10-INTEGRATIONS.md) - Framework integrations

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
