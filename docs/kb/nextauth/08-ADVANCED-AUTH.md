---
id: nextauth-08-advanced-auth
topic: nextauth
file_role: advanced
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [nextauth-fundamentals, nextauth-sessions, nextauth-callbacks]
related_topics: [2fa, oauth-advanced, custom-providers]
embedding_keywords: [nextauth, 2fa, multi-factor, oauth-advanced, custom-auth]
last_reviewed: 2025-11-16
---

# NextAuth.js - Advanced Authentication

## Purpose

Advanced authentication patterns including two-factor authentication (2FA), magic links, social account linking, custom OAuth flows, and enterprise authentication.

## Table of Contents

1. [Two-Factor Authentication](#two-factor-authentication)
2. [Magic Links](#magic-links)
3. [Account Linking](#account-linking)
4. [Custom OAuth Flows](#custom-oauth-flows)
5. [Enterprise Authentication](#enterprise-authentication)
6. [Advanced Patterns](#advanced-patterns)

---

## Two-Factor Authentication

### TOTP-Based 2FA

```typescript
// lib/2fa/totp.ts
import { authenticator } from 'otplib'
import QRCode from 'qrcode'

export async function generate2FASecret(email: string) {
  const secret = authenticator.generateSecret()

  // Generate QR code
  const otpauth = authenticator.keyuri(email, 'YourApp', secret)
  const qrCode = await QRCode.toDataURL(otpauth)

  return { secret, qrCode }
}

export function verify2FAToken(token: string, secret: string): boolean {
  return authenticator.verify({ token, secret })
}

// app/actions/2fa.ts
'use server'

import { requireAuth } from '@/lib/auth/protect'

export async function enable2FA() {
  const session = await requireAuth()

  // Generate secret
  const { secret, qrCode } = await generate2FASecret(session.user.email)

  // Save secret to database (encrypted)
  await db.user.update({
    where: { id: session.user.id },
    data: {
      twoFactorSecret: encrypt(secret),
      twoFactorEnabled: false, // Not enabled until verified
    },
  })

  return { qrCode }
}

export async function verify2FA(token: string) {
  const session = await requireAuth()

  const user = await db.user.findUnique({
    where: { id: session.user.id },
    select: { twoFactorSecret: true },
  })

  if (!user?.twoFactorSecret) {
    throw new Error('2FA not set up')
  }

  const secret = decrypt(user.twoFactorSecret)
  const isValid = verify2FAToken(token, secret)

  if (!isValid) {
    throw new Error('Invalid 2FA code')
  }

  // Enable 2FA
  await db.user.update({
    where: { id: session.user.id },
    data: { twoFactorEnabled: true },
  })

  return { success: true }
}
```

### 2FA Flow with Callbacks

```typescript
// app/api/auth/[...nextauth]/route.ts
callbacks: {
  async signIn({ user, account }) {
    // Check if user has 2FA enabled
    const dbUser = await db.user.findUnique({
      where: { id: user.id },
      select: { twoFactorEnabled: true },
    })

    if (dbUser?.twoFactorEnabled) {
      // Redirect to 2FA verification page
      return '/auth/verify-2fa'
    }

    return true
  },

  async jwt({ token, user, trigger, session }) {
    if (trigger === 'update' && session?.twoFactorVerified) {
      // User completed 2FA verification
      token.twoFactorVerified = true
    }

    return token
  }
}

// app/auth/verify-2fa/page.tsx
'use client'

import { useState } from 'react'
import { useSession } from 'next-auth/react'
import { useRouter } from 'next/navigation'

export default function Verify2FAPage() {
  const [code, setCode] = useState('')
  const { update } = useSession()
  const router = useRouter()

  const handleVerify = async () => {
    const response = await fetch('/api/auth/verify-2fa', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code }),
    })

    if (response.ok) {
      // Update session with 2FA verified
      await update({ twoFactorVerified: true })
      router.push('/dashboard')
    }
  }

  return (
    <div>
      <h1>Verify 2FA</h1>
      <input
        type="text"
        value={code}
        onChange={(e) => setCode(e.value)}
        placeholder="Enter 6-digit code"
      />
      <button onClick={handleVerify}>Verify</button>
    </div>
  )
}
```

### SMS-Based 2FA

```typescript
// lib/2fa/sms.ts
import { Twilio } from 'twilio'

const client = new Twilio(
  process.env.TWILIO_ACCOUNT_SID!,
  process.env.TWILIO_AUTH_TOKEN!
)

export async function sendSMS2FA(phoneNumber: string, code: string) {
  await client.messages.create({
    body: `Your verification code is: ${code}`,
    to: phoneNumber,
    from: process.env.TWILIO_PHONE_NUMBER!,
  })
}

export function generate2FACode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString()
}

// app/actions/sms-2fa.ts
'use server'

export async function send2FACode() {
  const session = await requireAuth()

  const user = await db.user.findUnique({
    where: { id: session.user.id },
    select: { phoneNumber: true },
  })

  if (!user?.phoneNumber) {
    throw new Error('Phone number not set')
  }

  const code = generate2FACode()

  // Store code in database (with expiry)
  await db.verificationCode.create({
    data: {
      userId: session.user.id,
      code,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000), // 5 minutes
    },
  })

  await sendSMS2FA(user.phoneNumber, code)

  return { success: true }
}
```

---

## Magic Links

### Email Magic Link Implementation

```typescript
// app/api/auth/magic-link/route.ts
import { randomBytes } from 'crypto'
import { sendEmail } from '@/lib/email'

export async function POST(request: Request) {
  const { email } = await request.json()

  // Generate token
  const token = randomBytes(32).toString('hex')

  // Store token
  await db.verificationToken.create({
    data: {
      identifier: email,
      token,
      expires: new Date(Date.now() + 15 * 60 * 1000), // 15 minutes
    },
  })

  // Send magic link
  const magicLink = `${process.env.NEXTAUTH_URL}/auth/verify?token=${token}&email=${email}`

  await sendEmail({
    to: email,
    subject: 'Your magic link',
    html: `
      <h1>Sign in to YourApp</h1>
      <p>Click the link below to sign in:</p>
      <a href="${magicLink}">Sign In</a>
      <p>This link will expire in 15 minutes.</p>
    `,
  })

  return Response.json({ success: true })
}

// app/auth/verify/page.tsx
import { redirect } from 'next/navigation'
import { signIn } from 'next-auth/react'

export default async function VerifyPage({
  searchParams,
}: {
  searchParams: { token?: string; email?: string }
}) {
  const { token, email } = searchParams

  if (!token || !email) {
    redirect('/auth/signin')
  }

  // Verify token
  const verification = await db.verificationToken.findUnique({
    where: {
      identifier_token: {
        identifier: email,
        token,
      },
    },
  })

  if (!verification || verification.expires < new Date()) {
    redirect('/auth/error?error=InvalidToken')
  }

  // Delete token (one-time use)
  await db.verificationToken.delete({
    where: {
      identifier_token: {
        identifier: email,
        token,
      },
    },
  })

  // Sign in user
  await signIn('email', { email, callbackUrl: '/dashboard' })
}
```

---

## Account Linking

### Link Social Accounts

```typescript
// app/api/auth/link-account/route.ts
import { getServerSession } from 'next-auth'

export async function POST(request: Request) {
  const session = await getServerSession(authOptions)

  if (!session) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { provider, accountId } = await request.json()

  // Check if account already linked
  const existing = await db.account.findFirst({
    where: {
      provider,
      providerAccountId: accountId,
    },
  })

  if (existing && existing.userId !== session.user.id) {
    return Response.json(
      { error: 'Account already linked to another user' },
      { status: 400 }
    )
  }

  // Link account
  await db.account.create({
    data: {
      userId: session.user.id,
      provider,
      providerAccountId: accountId,
      type: 'oauth',
    },
  })

  return Response.json({ success: true })
}
```

### Unlink Social Accounts

```typescript
// app/actions/unlink-account.ts
'use server'

export async function unlinkAccount(provider: string) {
  const session = await requireAuth()

  // Ensure user has at least one authentication method remaining
  const accounts = await db.account.findMany({
    where: { userId: session.user.id },
  })

  if (accounts.length === 1) {
    throw new Error('Cannot unlink last authentication method')
  }

  // Unlink account
  await db.account.deleteMany({
    where: {
      userId: session.user.id,
      provider,
    },
  })

  return { success: true }
}
```

---

## Custom OAuth Flows

### Custom Authorization URL

```typescript
{
  id: 'custom-oauth',
  name: 'Custom OAuth Provider',
  type: 'oauth',
  authorization: {
    url: 'https://provider.com/oauth/authorize',
    params: {
      scope: 'openid email profile',
      response_type: 'code',
      // Add custom parameters
      prompt: 'consent',
      access_type: 'offline',
    }
  },
  token: 'https://provider.com/oauth/token',
  userinfo: {
    url: 'https://provider.com/oauth/userinfo',
    async request({ tokens, provider }) {
      // Custom userinfo request
      const response = await fetch(provider.userinfo.url, {
        headers: {
          Authorization: `Bearer ${tokens.access_token}`,
          'Custom-Header': 'value',
        },
      })

      return await response.json()
    }
  },
  clientId: process.env.CUSTOM_CLIENT_ID,
  clientSecret: process.env.CUSTOM_CLIENT_SECRET,
  profile(profile) {
    return {
      id: profile.sub,
      name: profile.name,
      email: profile.email,
      image: profile.picture,
      // Custom fields
      customField: profile.custom_field,
    }
  },
}
```

### PKCE Flow

```typescript
{
  id: 'pkce-provider',
  name: 'PKCE Provider',
  type: 'oauth',
  authorization: {
    url: 'https://provider.com/oauth/authorize',
    params: {
      response_type: 'code',
      // Enable PKCE
      code_challenge_method: 'S256',
    }
  },
  token: {
    url: 'https://provider.com/oauth/token',
    async request({ provider, params, checks, client }) {
      // PKCE token exchange
      const response = await fetch(provider.token.url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          grant_type: 'authorization_code',
          code: params.code!,
          redirect_uri: params.redirect_uri!,
          client_id: provider.clientId!,
          // PKCE verifier
          code_verifier: checks.code_verifier!,
        }),
      })

      return await response.json()
    }
  },
  // ...
}
```

---

## Enterprise Authentication

### SAML Integration

```typescript
import SamlProvider from 'next-auth/providers/saml'

SamlProvider({
  id: 'saml',
  name: 'Corporate SSO',
  issuer: process.env.SAML_ISSUER!,
  cert: process.env.SAML_CERT!,
  idpMetadata: process.env.SAML_IDP_METADATA!,
})
```

### Multi-Tenant SSO

```typescript
// Dynamic provider based on tenant
async function getProviderForTenant(tenantId: string) {
  const tenant = await db.tenant.findUnique({
    where: { id: tenantId },
    select: { ssoProvider: true, ssoConfig: true },
  })

  if (!tenant?.ssoProvider) {
    return null
  }

  switch (tenant.ssoProvider) {
    case 'saml':
      return SamlProvider({
        id: `saml-${tenantId}`,
        ...tenant.ssoConfig,
      })

    case 'oidc':
      return {
        id: `oidc-${tenantId}`,
        type: 'oidc',
        ...tenant.ssoConfig,
      }

    default:
      return null
  }
}

// Usage in sign-in flow
export async function POST(request: Request) {
  const { email } = await request.json()

  // Determine tenant from email domain
  const domain = email.split('@')[1]
  const tenant = await db.tenant.findFirst({
    where: { domain },
  })

  if (tenant) {
    const provider = await getProviderForTenant(tenant.id)
    if (provider) {
      // Redirect to tenant-specific SSO
      return Response.json({
        redirect: `/api/auth/signin/${provider.id}`,
      })
    }
  }

  // Fallback to standard authentication
  return Response.json({ provider: 'credentials' })
}
```

---

## Advanced Patterns

### Session Rotation

```typescript
callbacks: {
  async jwt({ token, user, trigger }) {
    // Rotate session ID periodically
    if (trigger === 'update') {
      const lastRotation = token.lastRotation as number || 0
      const rotationInterval = 60 * 60 * 1000 // 1 hour

      if (Date.now() - lastRotation > rotationInterval) {
        token.sessionId = crypto.randomUUID()
        token.lastRotation = Date.now()
      }
    }

    if (user) {
      token.sessionId = crypto.randomUUID()
      token.lastRotation = Date.now()
    }

    return token
  }
}
```

### Device Fingerprinting

```typescript
// lib/security/fingerprint.ts
import { headers } from 'next/headers'
import { createHash } from 'crypto'

export async function getDeviceFingerprint(): Promise<string> {
  const headersList = await headers()

  const components = [
    headersList.get('user-agent'),
    headersList.get('accept-language'),
    headersList.get('sec-ch-ua'),
    headersList.get('sec-ch-ua-platform'),
  ]

  const fingerprint = components.join('|')

  return createHash('sha256').update(fingerprint).digest('hex')
}

// Usage
callbacks: {
  async signIn({ user }) {
    const fingerprint = await getDeviceFingerprint()

    // Store fingerprint
    await db.session.create({
      data: {
        userId: user.id,
        fingerprint,
        createdAt: new Date(),
      },
    })

    return true
  }
}
```

### Adaptive Authentication

```typescript
// lib/security/risk-score.ts
export async function calculateRiskScore(userId: string): Promise<number> {
  let risk = 0

  // Check login history
  const recentLogins = await db.loginHistory.count({
    where: {
      userId,
      createdAt: { gt: new Date(Date.now() - 24 * 60 * 60 * 1000) },
    },
  })

  if (recentLogins > 10) risk += 30 // Unusual activity

  // Check location
  const lastLocation = await db.loginHistory.findFirst({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    select: { country: true },
  })

  const currentCountry = await getCurrentCountry()

  if (lastLocation?.country !== currentCountry) {
    risk += 40 // Different location
  }

  // Check device
  const knownDevice = await db.device.findFirst({
    where: {
      userId,
      fingerprint: await getDeviceFingerprint(),
    },
  })

  if (!knownDevice) risk += 30 // New device

  return risk
}

// Usage
callbacks: {
  async signIn({ user }) {
    const riskScore = await calculateRiskScore(user.id)

    if (riskScore > 50) {
      // High risk - require 2FA
      return '/auth/verify-2fa'
    }

    return true
  }
}
```

---

## Best Practices

### 1. Security First

```typescript
// ✅ Good - Secure token generation
import { randomBytes } from 'crypto'
const token = randomBytes(32).toString('hex')

// ❌ Bad - Weak tokens
const token = Math.random().toString(36)
```

### 2. Expiring Tokens

```typescript
// ✅ Good - Time-limited tokens
await db.verificationToken.create({
  data: {
    token,
    expires: new Date(Date.now() + 15 * 60 * 1000), // 15 minutes
  },
})
```

### 3. One-Time Use

```typescript
// ✅ Good - Delete after use
await db.verificationToken.delete({
  where: { token },
})
```

---

## AI Pair Programming Notes

**When to load this file:**
- Implementing 2FA
- Adding magic link authentication
- Linking social accounts
- Custom OAuth flows
- Enterprise SSO

**Typical questions:**
- "How do I add 2FA?" → See Two-Factor Authentication
- "How do I implement magic links?" → See Magic Links
- "How do I link social accounts?" → See Account Linking
- "How do I integrate SAML?" → See Enterprise Authentication

**Next steps:**
- [09-SECURITY.md](./09-SECURITY.md) - Security best practices
- [05-CALLBACKS.md](./05-CALLBACKS.md) - Callback patterns
- [11-CONFIG-OPERATIONS.md](./11-CONFIG-OPERATIONS.md) - Production operations

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
