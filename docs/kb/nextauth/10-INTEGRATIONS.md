---
id: nextauth-integrations
topic: nextauth
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [nextauth-fundamentals, nextauth-providers, nextauth-sessions]
related_topics: [nextjs, react, prisma, drizzle, tRPC]
embedding_keywords: [nextauth, integrations, nextjs, prisma, drizzle, trpc, react-query, express]
last_reviewed: 2025-11-16
---

# NextAuth.js - Framework Integrations

Comprehensive integration patterns for NextAuth with popular frameworks and libraries.

## Overview

NextAuth.js integrates seamlessly with modern web frameworks, ORMs, and libraries. This guide covers integration patterns for Next.js App Router, Prisma, Drizzle, tRPC, React Query, and more.

---

## Next.js App Router Integration

Complete integration with Next.js 13+ App Router.

### Basic Setup

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'
import type { NextAuthOptions } from 'next-auth'
import GoogleProvider from 'next-auth/providers/google'

export const authOptions: NextAuthOptions = {
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],
  pages: {
    signIn: '/login',
    error: '/error',
  },
  callbacks: {
    async session({ session, token }) {
      session.user.id = token.sub!
      return session
    },
  },
}

const handler = NextAuth(authOptions)

export { handler as GET, handler as POST }
```

### Server Components

```typescript
// app/dashboard/page.tsx
import { getServerSession } from 'next-auth'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'
import { redirect } from 'next/navigation'

export default async function DashboardPage() {
  const session = await getServerSession(authOptions)

  if (!session) {
    redirect('/login')
  }

  return (
    <div>
      <h1>Welcome, {session.user.name}</h1>
      <p>Email: {session.user.email}</p>
    </div>
  )
}
```

### Client Components

```typescript
// app/profile/page.tsx
'use client'

import { useSession } from 'next-auth/react'
import { redirect } from 'next/navigation'

export default function ProfilePage() {
  const { data: session, status } = useSession({
    required: true,
    onUnauthenticated() {
      redirect('/login')
    },
  })

  if (status === 'loading') {
    return <div>Loading...</div>
  }

  return (
    <div>
      <h1>{session.user.name}</h1>
      <img src={session.user.image} alt="Profile" />
    </div>
  )
}
```

### API Routes

```typescript
// app/api/profile/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions)

  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // Fetch user data
  const user = await db.user.findUnique({
    where: { id: session.user.id },
  })

  return NextResponse.json({ user })
}

export async function PATCH(req: NextRequest) {
  const session = await getServerSession(authOptions)

  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const body = await req.json()

  const updated = await db.user.update({
    where: { id: session.user.id },
    data: body,
  })

  return NextResponse.json({ user: updated })
}
```

### Server Actions

```typescript
// app/actions/profile.ts
'use server'

import { getServerSession } from 'next-auth'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'
import { revalidatePath } from 'next/cache'

export async function updateProfile(formData: FormData) {
  const session = await getServerSession(authOptions)

  if (!session) {
    throw new Error('Unauthorized')
  }

  const name = formData.get('name') as string
  const bio = formData.get('bio') as string

  await db.user.update({
    where: { id: session.user.id },
    data: { name, bio },
  })

  revalidatePath('/profile')

  return { success: true }
}

// app/profile/edit/page.tsx
import { updateProfile } from '@/app/actions/profile'

export default function EditProfile() {
  return (
    <form action={updateProfile}>
      <input name="name" placeholder="Name" />
      <textarea name="bio" placeholder="Bio" />
      <button type="submit">Save</button>
    </form>
  )
}
```

---

## Prisma Integration

NextAuth with Prisma ORM for database persistence.

### Schema Setup

```prisma
// prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String? @db.Text
  access_token      String? @db.Text
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String? @db.Text
  session_state     String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
  @@index([userId])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
}

model User {
  id            String    @id @default(cuid())
  name          String?
  email         String?   @unique
  emailVerified DateTime?
  image         String?
  accounts      Account[]
  sessions      Session[]
}

model VerificationToken {
  identifier String
  token      String   @unique
  expires    DateTime

  @@unique([identifier, token])
}
```

### NextAuth Configuration

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'
import { PrismaAdapter } from '@auth/prisma-adapter'
import { PrismaClient } from '@prisma/client'
import GoogleProvider from 'next-auth/providers/google'

const prisma = new PrismaClient()

export const authOptions = {
  adapter: PrismaAdapter(prisma),
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],
  session: {
    strategy: 'database',
    maxAge: 30 * 24 * 60 * 60, // 30 days
    updateAge: 24 * 60 * 60, // 24 hours
  },
}

const handler = NextAuth(authOptions)
export { handler as GET, handler as POST }
```

### Extended User Model

```prisma
// Extended User model with custom fields
model User {
  id            String    @id @default(cuid())
  name          String?
  email         String?   @unique
  emailVerified DateTime?
  image         String?
  role          Role      @default(USER)
  bio           String?
  accounts      Account[]
  sessions      Session[]
  posts         Post[]

  @@index([email])
}

enum Role {
  USER
  ADMIN
  MODERATOR
}

model Post {
  id        String   @id @default(cuid())
  title     String
  content   String
  published Boolean  @default(false)
  authorId  String
  author    User     @relation(fields: [authorId], references: [id])
  createdAt DateTime @default(now())

  @@index([authorId])
}
```

### Callbacks with Prisma

```typescript
// app/api/auth/[...nextauth]/route.ts
import { PrismaAdapter } from '@auth/prisma-adapter'
import { prisma } from '@/lib/db'

export const authOptions = {
  adapter: PrismaAdapter(prisma),
  callbacks: {
    async session({ session, user }) {
      // Add custom fields from database
      session.user.id = user.id
      session.user.role = user.role
      session.user.bio = user.bio

      return session
    },
    async signIn({ user, account, profile }) {
      // Update user profile from OAuth
      if (account?.provider === 'google' && profile) {
        await prisma.user.update({
          where: { id: user.id },
          data: {
            name: profile.name,
            image: profile.image,
          },
        })
      }

      return true
    },
  },
}
```

---

## Drizzle ORM Integration

NextAuth with Drizzle ORM.

### Schema Definition

```typescript
// db/schema.ts
import {
  pgTable,
  text,
  timestamp,
  integer,
  primaryKey,
} from 'drizzle-orm/pg-core'
import { relations } from 'drizzle-orm'

export const users = pgTable('users', {
  id: text('id').primaryKey(),
  name: text('name'),
  email: text('email').notNull().unique(),
  emailVerified: timestamp('email_verified', { mode: 'date' }),
  image: text('image'),
})

export const accounts = pgTable(
  'accounts',
  {
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    type: text('type').notNull(),
    provider: text('provider').notNull(),
    providerAccountId: text('provider_account_id').notNull(),
    refresh_token: text('refresh_token'),
    access_token: text('access_token'),
    expires_at: integer('expires_at'),
    token_type: text('token_type'),
    scope: text('scope'),
    id_token: text('id_token'),
    session_state: text('session_state'),
  },
  (account) => ({
    compoundKey: primaryKey({
      columns: [account.provider, account.providerAccountId],
    }),
  })
)

export const sessions = pgTable('sessions', {
  sessionToken: text('session_token').primaryKey(),
  userId: text('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  expires: timestamp('expires', { mode: 'date' }).notNull(),
})

export const verificationTokens = pgTable(
  'verification_tokens',
  {
    identifier: text('identifier').notNull(),
    token: text('token').notNull(),
    expires: timestamp('expires', { mode: 'date' }).notNull(),
  },
  (vt) => ({
    compoundKey: primaryKey({ columns: [vt.identifier, vt.token] }),
  })
)

// Relations
export const usersRelations = relations(users, ({ many }) => ({
  accounts: many(accounts),
  sessions: many(sessions),
}))

export const accountsRelations = relations(accounts, ({ one }) => ({
  user: one(users, {
    fields: [accounts.userId],
    references: [users.id],
  }),
}))

export const sessionsRelations = relations(sessions, ({ one }) => ({
  user: one(users, {
    fields: [sessions.userId],
    references: [users.id],
  }),
}))
```

### NextAuth Configuration

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'
import { DrizzleAdapter } from '@auth/drizzle-adapter'
import { db } from '@/db'

export const authOptions = {
  adapter: DrizzleAdapter(db),
  providers: [
    // Your providers
  ],
  session: {
    strategy: 'database',
  },
}

const handler = NextAuth(authOptions)
export { handler as GET, handler as POST }
```

---

## tRPC Integration

Type-safe API calls with tRPC and NextAuth.

### tRPC Context with Session

```typescript
// server/trpc/context.ts
import { getServerSession } from 'next-auth'
import { authOptions } from '@/app/api/auth/[...nextauth]/route'

export async function createContext() {
  const session = await getServerSession(authOptions)

  return {
    session,
  }
}

export type Context = Awaited<ReturnType<typeof createContext>>
```

### Protected Procedures

```typescript
// server/trpc/trpc.ts
import { initTRPC, TRPCError } from '@trpc/server'
import { Context } from './context'

const t = initTRPC.context<Context>().create()

export const router = t.router
export const publicProcedure = t.procedure

// Middleware to check authentication
const isAuthed = t.middleware(({ ctx, next }) => {
  if (!ctx.session?.user) {
    throw new TRPCError({ code: 'UNAUTHORIZED' })
  }

  return next({
    ctx: {
      session: ctx.session,
    },
  })
})

// Protected procedure
export const protectedProcedure = t.procedure.use(isAuthed)

// Role-based procedure
const isAdmin = t.middleware(({ ctx, next }) => {
  if (!ctx.session?.user || ctx.session.user.role !== 'ADMIN') {
    throw new TRPCError({ code: 'FORBIDDEN' })
  }

  return next({
    ctx: {
      session: ctx.session,
    },
  })
})

export const adminProcedure = t.procedure.use(isAdmin)
```

### tRPC Router

```typescript
// server/trpc/routers/user.ts
import { z } from 'zod'
import { router, publicProcedure, protectedProcedure, adminProcedure } from '../trpc'

export const userRouter = router({
  // Public endpoint
  getById: publicProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ input }) => {
      return await db.user.findUnique({
        where: { id: input.id },
        select: { id: true, name: true, image: true },
      })
    }),

  // Protected endpoint
  getCurrent: protectedProcedure.query(async ({ ctx }) => {
    return await db.user.findUnique({
      where: { id: ctx.session.user.id },
    })
  }),

  // Update current user
  update: protectedProcedure
    .input(
      z.object({
        name: z.string().optional(),
        bio: z.string().optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      return await db.user.update({
        where: { id: ctx.session.user.id },
        data: input,
      })
    }),

  // Admin-only endpoint
  delete: adminProcedure
    .input(z.object({ id: z.string() }))
    .mutation(async ({ input }) => {
      return await db.user.delete({
        where: { id: input.id },
      })
    }),
})
```

### Client-Side Usage

```typescript
// app/profile/page.tsx
'use client'

import { trpc } from '@/lib/trpc'

export default function ProfilePage() {
  const { data: user, isLoading } = trpc.user.getCurrent.useQuery()

  const updateMutation = trpc.user.update.useMutation({
    onSuccess: () => {
      // Invalidate and refetch
      utils.user.getCurrent.invalidate()
    },
  })

  if (isLoading) return <div>Loading...</div>

  return (
    <div>
      <h1>{user?.name}</h1>
      <button
        onClick={() =>
          updateMutation.mutate({ name: 'New Name' })
        }
      >
        Update Name
      </button>
    </div>
  )
}
```

---

## React Query Integration

Optimistic updates and caching with React Query.

### Setup

```typescript
// app/providers.tsx
'use client'

import { SessionProvider } from 'next-auth/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactNode } from 'react'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      cacheTime: 10 * 60 * 1000, // 10 minutes
    },
  },
})

export function Providers({ children }: { children: ReactNode }) {
  return (
    <SessionProvider>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </SessionProvider>
  )
}
```

### Protected Queries

```typescript
// hooks/useUser.ts
import { useQuery } from '@tanstack/react-query'
import { useSession } from 'next-auth/react'

export function useUser() {
  const { data: session, status } = useSession()

  return useQuery({
    queryKey: ['user', session?.user?.id],
    queryFn: async () => {
      const res = await fetch('/api/user')
      if (!res.ok) throw new Error('Failed to fetch user')
      return res.json()
    },
    enabled: status === 'authenticated',
  })
}

// hooks/useUpdateUser.ts
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useSession } from 'next-auth/react'

export function useUpdateUser() {
  const queryClient = useQueryClient()
  const { data: session } = useSession()

  return useMutation({
    mutationFn: async (data: Partial<User>) => {
      const res = await fetch('/api/user', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      })

      if (!res.ok) throw new Error('Failed to update user')
      return res.json()
    },
    onMutate: async (newData) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['user', session?.user?.id] })

      // Snapshot previous value
      const previous = queryClient.getQueryData(['user', session?.user?.id])

      // Optimistically update
      queryClient.setQueryData(['user', session?.user?.id], (old: any) => ({
        ...old,
        ...newData,
      }))

      return { previous }
    },
    onError: (err, newData, context) => {
      // Rollback on error
      queryClient.setQueryData(
        ['user', session?.user?.id],
        context?.previous
      )
    },
    onSettled: () => {
      // Refetch after mutation
      queryClient.invalidateQueries({ queryKey: ['user', session?.user?.id] })
    },
  })
}
```

---

## Express.js Integration

NextAuth can work with Express backends.

### Express Setup

```typescript
// server.ts
import express from 'express'
import session from 'express-session'
import passport from 'passport'
import { Strategy as GoogleStrategy } from 'passport-google-oauth20'

const app = express()

// Session middleware
app.use(
  session({
    secret: process.env.SESSION_SECRET!,
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === 'production',
      httpOnly: true,
      maxAge: 24 * 60 * 60 * 1000, // 24 hours
    },
  })
)

// Passport setup
passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      callbackURL: '/auth/google/callback',
    },
    async (accessToken, refreshToken, profile, done) => {
      // Find or create user
      let user = await db.user.findUnique({
        where: { email: profile.emails?.[0].value },
      })

      if (!user) {
        user = await db.user.create({
          data: {
            email: profile.emails?.[0].value!,
            name: profile.displayName,
            image: profile.photos?.[0].value,
          },
        })
      }

      done(null, user)
    }
  )
)

passport.serializeUser((user: any, done) => {
  done(null, user.id)
})

passport.deserializeUser(async (id: string, done) => {
  const user = await db.user.findUnique({ where: { id } })
  done(null, user)
})

app.use(passport.initialize())
app.use(passport.session())

// Routes
app.get('/auth/google', passport.authenticate('google', { scope: ['profile', 'email'] }))

app.get(
  '/auth/google/callback',
  passport.authenticate('google', { failureRedirect: '/login' }),
  (req, res) => {
    res.redirect('/dashboard')
  }
)

// Protected route middleware
function requireAuth(req: express.Request, res: express.Response, next: express.NextFunction) {
  if (req.isAuthenticated()) {
    return next()
  }
  res.status(401).json({ error: 'Unauthorized' })
}

app.get('/api/profile', requireAuth, (req, res) => {
  res.json({ user: req.user })
})

app.listen(3000, () => console.log('Server running on port 3000'))
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Integrating NextAuth with Next.js App Router
- Setting up NextAuth with Prisma or Drizzle
- Building type-safe APIs with tRPC
- Need React Query patterns with auth
- Integrating with Express backends

**Common starting points:**
- Next.js integration: See Next.js App Router Integration section
- Database setup: See Prisma Integration or Drizzle ORM Integration
- Type-safe APIs: See tRPC Integration section
- Optimistic updates: See React Query Integration section

**Typical questions:**
- "How do I use NextAuth with Prisma?" → See Prisma Integration section
- "How do I protect tRPC procedures?" → See tRPC Integration section
- "How do I use NextAuth in Server Components?" → See Next.js App Router Integration
- "How do I implement optimistic updates?" → See React Query Integration

**Related topics:**
- Session management: See `03-SESSIONS.md`
- Middleware patterns: See `06-MIDDLEWARE.md`
- Protected routes: See `07-PROTECTED-ROUTES.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
