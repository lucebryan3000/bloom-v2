---
id: nextauth-framework-integration
topic: nextauth
file_role: framework
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [nextauth-fundamentals, nextauth-sessions, nextauth-integrations]
related_topics: [nextjs, react, prisma, trpc, react-query]
embedding_keywords: [nextauth, framework-integration, nextjs, prisma, trpc, react-query, patterns]
last_reviewed: 2025-11-16
---

# NextAuth.js - Framework Integration Patterns

Advanced integration patterns and best practices for NextAuth with modern frameworks.

## Overview

This guide provides specific, production-ready integration patterns for NextAuth with popular frameworks. For basic integrations, see [10-INTEGRATIONS.md](./10-INTEGRATIONS.md).

---

## Next.js 13+ App Router Patterns

### Complete Authentication Setup

```typescript
// lib/auth/config.ts
import { NextAuthOptions } from 'next-auth'
import { PrismaAdapter } from '@auth/prisma-adapter'
import { prisma } from '@/lib/db'
import GoogleProvider from 'next-auth/providers/google'
import GitHubProvider from 'next-auth/providers/github'
import EmailProvider from 'next-auth/providers/email'

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma),
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
    GitHubProvider({
      clientId: process.env.GITHUB_CLIENT_ID!,
      clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    }),
    EmailProvider({
      server: process.env.EMAIL_SERVER!,
      from: process.env.EMAIL_FROM!,
    }),
  ],
  pages: {
    signIn: '/auth/signin',
    error: '/auth/error',
  },
  session: {
    strategy: 'database',
    maxAge: 30 * 24 * 60 * 60, // 30 days
  },
  callbacks: {
    async session({ session, user }) {
      session.user.id = user.id
      session.user.role = user.role
      session.user.permissions = user.permissions
      return session
    },
  },
  events: {
    async signIn({ user }) {
      await auditLog('signin', user.id)
    },
    async signOut({ session }) {
      await auditLog('signout', session?.user?.id)
    },
  },
}

// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'
import { authOptions } from '@/lib/auth/config'

const handler = NextAuth(authOptions)

export { handler as GET, handler as POST }
```

### Parallel Server Component Fetching

```typescript
// app/dashboard/page.tsx
import { auth } from '@/app/api/auth/[...nextauth]/route'
import { Suspense } from 'react'

// Parallel data fetching
async function getUserData(userId: string) {
  return await db.user.findUnique({ where: { id: userId } })
}

async function getUserPosts(userId: string) {
  return await db.post.findMany({ where: { authorId: userId } })
}

export default async function DashboardPage() {
  const session = await auth()

  if (!session) {
    redirect('/login')
  }

  // Parallel fetching
  const [userData, userPosts] = await Promise.all([
    getUserData(session.user.id),
    getUserPosts(session.user.id),
  ])

  return (
    <div>
      <h1>Welcome, {userData.name}</h1>
      <Suspense fallback={<PostsSkeleton />}>
        <PostsList posts={userPosts} />
      </Suspense>
    </div>
  )
}
```

### Server Actions with Auth

```typescript
// app/actions/profile.ts
'use server'

import { auth } from '@/app/api/auth/[...nextauth]/route'
import { revalidatePath } from 'next/cache'
import { z } from 'zod'

const updateProfileSchema = z.object({
  name: z.string().min(1).max(100),
  bio: z.string().max(500).optional(),
})

export async function updateProfile(formData: FormData) {
  // 1. Authenticate
  const session = await auth()
  if (!session) {
    throw new Error('Unauthorized')
  }

  // 2. Validate input
  const data = updateProfileSchema.parse({
    name: formData.get('name'),
    bio: formData.get('bio'),
  })

  // 3. Update database
  await db.user.update({
    where: { id: session.user.id },
    data,
  })

  // 4. Revalidate cached pages
  revalidatePath('/profile')
  revalidatePath(`/users/${session.user.id}`)

  return { success: true }
}

// Usage in form
// app/profile/edit/page.tsx
import { updateProfile } from '@/app/actions/profile'

export default function EditProfile() {
  return (
    <form action={updateProfile}>
      <input name="name" placeholder="Name" required />
      <textarea name="bio" placeholder="Bio" />
      <button type="submit">Save</button>
    </form>
  )
}
```

### Route Handlers with Streaming

```typescript
// app/api/notifications/route.ts
import { auth } from '@/app/api/auth/[...nextauth]/route'
import { NextResponse } from 'next/server'

export async function GET(req: Request) {
  const session = await auth()

  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // Streaming response
  const encoder = new TextEncoder()

  const stream = new ReadableStream({
    async start(controller) {
      const notifications = await db.notification.findMany({
        where: { userId: session.user.id },
        orderBy: { createdAt: 'desc' },
      })

      for (const notification of notifications) {
        const chunk = encoder.encode(JSON.stringify(notification) + '\n')
        controller.enqueue(chunk)
      }

      controller.close()
    },
  })

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/plain; charset=utf-8',
      'Cache-Control': 'no-cache',
    },
  })
}
```

---

## Prisma Advanced Patterns

### Extended User Model with Relations

```prisma
// prisma/schema.prisma
model User {
  id            String    @id @default(cuid())
  name          String?
  email         String?   @unique
  emailVerified DateTime?
  image         String?
  role          Role      @default(USER)
  permissions   String[]  @default([])

  // NextAuth required
  accounts      Account[]
  sessions      Session[]

  // App-specific
  profile       Profile?
  posts         Post[]
  comments      Comment[]
  memberships   Membership[]

  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  @@index([email])
  @@index([role])
}

model Profile {
  id        String   @id @default(cuid())
  userId    String   @unique
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  bio       String?
  website   String?
  location  String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post {
  id        String    @id @default(cuid())
  title     String
  content   String    @db.Text
  published Boolean   @default(false)
  authorId  String
  author    User      @relation(fields: [authorId], references: [id], onDelete: Cascade)
  comments  Comment[]
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt

  @@index([authorId])
  @@index([published])
}

model Comment {
  id        String   @id @default(cuid())
  content   String
  postId    String
  post      Post     @relation(fields: [postId], references: [id], onDelete: Cascade)
  authorId  String
  author    User     @relation(fields: [authorId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())

  @@index([postId])
  @@index([authorId])
}

enum Role {
  USER
  MODERATOR
  ADMIN
}
```

### Session with Relations

```typescript
// lib/auth/config.ts
callbacks: {
  async session({ session, user }) {
    // Include full user with relations
    const fullUser = await prisma.user.findUnique({
      where: { id: user.id },
      include: {
        profile: true,
        memberships: {
          include: {
            organization: true,
          },
        },
      },
    })

    if (fullUser) {
      session.user.id = fullUser.id
      session.user.role = fullUser.role
      session.user.permissions = fullUser.permissions
      session.user.profile = fullUser.profile
      session.user.organizations = fullUser.memberships.map(m => m.organization)
    }

    return session
  },
}
```

### Optimistic Updates with Prisma

```typescript
// lib/api/posts.ts
import { prisma } from '@/lib/db'
import { revalidatePath } from 'next/cache'

export async function createPost(
  userId: string,
  data: { title: string; content: string }
) {
  const post = await prisma.post.create({
    data: {
      ...data,
      authorId: userId,
    },
    include: {
      author: {
        select: {
          id: true,
          name: true,
          image: true,
        },
      },
    },
  })

  // Revalidate affected pages
  revalidatePath('/posts')
  revalidatePath(`/users/${userId}/posts`)

  return post
}

export async function updatePost(
  postId: string,
  userId: string,
  data: Partial<{ title: string; content: string; published: boolean }>
) {
  // Verify ownership
  const post = await prisma.post.findFirst({
    where: { id: postId, authorId: userId },
  })

  if (!post) {
    throw new Error('Post not found or unauthorized')
  }

  const updated = await prisma.post.update({
    where: { id: postId },
    data,
  })

  revalidatePath(`/posts/${postId}`)

  return updated
}
```

---

## tRPC Production Patterns

### Complete tRPC Setup

```typescript
// server/trpc/trpc.ts
import { initTRPC, TRPCError } from '@trpc/server'
import { auth } from '@/app/api/auth/[...nextauth]/route'
import superjson from 'superjson'

interface Context {
  session: Awaited<ReturnType<typeof auth>> | null
}

const t = initTRPC.context<Context>().create({
  transformer: superjson,
  errorFormatter({ shape }) {
    return shape
  },
})

export const router = t.router
export const publicProcedure = t.procedure

// Middleware: Require authentication
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

// Middleware: Require specific role
const hasRole = (role: string) =>
  t.middleware(({ ctx, next }) => {
    if (!ctx.session?.user) {
      throw new TRPCError({ code: 'UNAUTHORIZED' })
    }

    if (ctx.session.user.role !== role) {
      throw new TRPCError({ code: 'FORBIDDEN' })
    }

    return next({
      ctx: {
        session: ctx.session,
      },
    })
  })

// Middleware: Require any of the permissions
const hasPermission = (permissions: string[]) =>
  t.middleware(({ ctx, next }) => {
    if (!ctx.session?.user) {
      throw new TRPCError({ code: 'UNAUTHORIZED' })
    }

    const userPermissions = ctx.session.user.permissions || []
    const hasPermission = permissions.some(p => userPermissions.includes(p))

    if (!hasPermission) {
      throw new TRPCError({ code: 'FORBIDDEN' })
    }

    return next({
      ctx: {
        session: ctx.session,
      },
    })
  })

export const protectedProcedure = t.procedure.use(isAuthed)
export const adminProcedure = t.procedure.use(hasRole('admin'))
export const moderatorProcedure = t.procedure.use(hasRole('moderator'))
```

### tRPC Router with Pagination

```typescript
// server/trpc/routers/posts.ts
import { router, publicProcedure, protectedProcedure } from '../trpc'
import { z } from 'zod'
import { TRPCError } from '@trpc/server'

export const postsRouter = router({
  // Public: List posts with pagination
  list: publicProcedure
    .input(
      z.object({
        limit: z.number().min(1).max(100).default(10),
        cursor: z.string().optional(),
        published: z.boolean().default(true),
      })
    )
    .query(async ({ input }) => {
      const posts = await prisma.post.findMany({
        take: input.limit + 1,
        where: { published: input.published },
        cursor: input.cursor ? { id: input.cursor } : undefined,
        orderBy: { createdAt: 'desc' },
        include: {
          author: {
            select: {
              id: true,
              name: true,
              image: true,
            },
          },
        },
      })

      let nextCursor: string | undefined = undefined
      if (posts.length > input.limit) {
        const nextItem = posts.pop()
        nextCursor = nextItem!.id
      }

      return {
        posts,
        nextCursor,
      }
    }),

  // Protected: Create post
  create: protectedProcedure
    .input(
      z.object({
        title: z.string().min(1).max(200),
        content: z.string().min(1),
        published: z.boolean().default(false),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const post = await prisma.post.create({
        data: {
          ...input,
          authorId: ctx.session.user.id,
        },
        include: {
          author: {
            select: {
              id: true,
              name: true,
              image: true,
            },
          },
        },
      })

      return post
    }),

  // Protected: Update own post
  update: protectedProcedure
    .input(
      z.object({
        id: z.string(),
        title: z.string().min(1).max(200).optional(),
        content: z.string().min(1).optional(),
        published: z.boolean().optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const { id, ...data } = input

      // Verify ownership
      const post = await prisma.post.findFirst({
        where: {
          id,
          authorId: ctx.session.user.id,
        },
      })

      if (!post) {
        throw new TRPCError({
          code: 'NOT_FOUND',
          message: 'Post not found or unauthorized',
        })
      }

      const updated = await prisma.post.update({
        where: { id },
        data,
      })

      return updated
    }),

  // Protected: Delete own post
  delete: protectedProcedure
    .input(z.object({ id: z.string() }))
    .mutation(async ({ ctx, input }) => {
      const post = await prisma.post.findFirst({
        where: {
          id: input.id,
          authorId: ctx.session.user.id,
        },
      })

      if (!post) {
        throw new TRPCError({
          code: 'NOT_FOUND',
          message: 'Post not found or unauthorized',
        })
      }

      await prisma.post.delete({
        where: { id: input.id },
      })

      return { success: true }
    }),
})
```

### Client-Side Usage with React Query

```typescript
// app/posts/page.tsx
'use client'

import { trpc } from '@/lib/trpc/client'

export default function PostsPage() {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isLoading,
  } = trpc.posts.list.useInfiniteQuery(
    { limit: 10 },
    {
      getNextPageParam: (lastPage) => lastPage.nextCursor,
    }
  )

  const createMutation = trpc.posts.create.useMutation({
    onSuccess: () => {
      // Invalidate and refetch
      utils.posts.list.invalidate()
    },
  })

  if (isLoading) return <div>Loading...</div>

  return (
    <div>
      <h1>Posts</h1>

      {data?.pages.map((page, i) => (
        <div key={i}>
          {page.posts.map((post) => (
            <PostCard key={post.id} post={post} />
          ))}
        </div>
      ))}

      {hasNextPage && (
        <button
          onClick={() => fetchNextPage()}
          disabled={isFetchingNextPage}
        >
          {isFetchingNextPage ? 'Loading...' : 'Load More'}
        </button>
      )}

      <button
        onClick={() =>
          createMutation.mutate({
            title: 'New Post',
            content: 'Content',
          })
        }
      >
        Create Post
      </button>
    </div>
  )
}
```

---

## React Query Integration

### Setup with NextAuth

```typescript
// app/providers.tsx
'use client'

import { SessionProvider } from 'next-auth/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000, // 1 minute
            cacheTime: 5 * 60 * 1000, // 5 minutes
            retry: 3,
          },
        },
      })
  )

  return (
    <SessionProvider>
      <QueryClientProvider client={queryClient}>
        {children}
        <ReactQueryDevtools initialIsOpen={false} />
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
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

// hooks/useUserPosts.ts
export function useUserPosts(userId?: string) {
  const { data: session } = useSession()

  return useQuery({
    queryKey: ['posts', userId || session?.user?.id],
    queryFn: async () => {
      const id = userId || session?.user?.id
      const res = await fetch(`/api/users/${id}/posts`)
      if (!res.ok) throw new Error('Failed to fetch posts')
      return res.json()
    },
    enabled: !!userId || !!session?.user?.id,
  })
}
```

### Optimistic Updates

```typescript
// hooks/useUpdateProfile.ts
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useSession } from 'next-auth/react'

interface UpdateProfileData {
  name?: string
  bio?: string
  image?: string
}

export function useUpdateProfile() {
  const queryClient = useQueryClient()
  const { data: session } = useSession()

  return useMutation({
    mutationFn: async (data: UpdateProfileData) => {
      const res = await fetch('/api/user', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      })

      if (!res.ok) throw new Error('Failed to update profile')
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

// Usage
function ProfileForm() {
  const { data: user } = useUser()
  const updateMutation = useUpdateProfile()

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)

    await updateMutation.mutateAsync({
      name: formData.get('name') as string,
      bio: formData.get('bio') as string,
    })
  }

  return (
    <form onSubmit={handleSubmit}>
      <input name="name" defaultValue={user?.name} />
      <textarea name="bio" defaultValue={user?.bio} />
      <button type="submit" disabled={updateMutation.isLoading}>
        {updateMutation.isLoading ? 'Saving...' : 'Save'}
      </button>
    </form>
  )
}
```

---

## TypeScript Best Practices

### Type-Safe Session

```typescript
// types/next-auth.d.ts
import { DefaultSession, DefaultUser } from 'next-auth'
import { JWT, DefaultJWT } from 'next-auth/jwt'

declare module 'next-auth' {
  interface Session {
    user: {
      id: string
      role: 'USER' | 'MODERATOR' | 'ADMIN'
      permissions: string[]
    } & DefaultSession['user']
  }

  interface User extends DefaultUser {
    role: 'USER' | 'MODERATOR' | 'ADMIN'
    permissions: string[]
  }
}

declare module 'next-auth/jwt' {
  interface JWT extends DefaultJWT {
    id: string
    role: 'USER' | 'MODERATOR' | 'ADMIN'
    permissions: string[]
  }
}
```

### Utility Functions with Types

```typescript
// lib/auth/utils.ts
import { Session } from 'next-auth'

export function hasRole(session: Session | null, role: string): boolean {
  return session?.user?.role === role
}

export function hasPermission(
  session: Session | null,
  permission: string
): boolean {
  return session?.user?.permissions?.includes(permission) || false
}

export function isAdmin(session: Session | null): boolean {
  return hasRole(session, 'ADMIN')
}

export function isModerator(session: Session | null): boolean {
  return hasRole(session, 'MODERATOR') || isAdmin(session)
}

// Usage with type safety
const session = await auth()

if (isAdmin(session)) {
  // TypeScript knows session.user.role === 'ADMIN'
}
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Building production NextAuth integrations
- Need framework-specific patterns
- Integrating with Prisma, tRPC, React Query
- Building type-safe authentication
- Optimizing authentication performance

**Common starting points:**
- Next.js patterns: See Next.js 13+ App Router Patterns section
- Prisma integration: See Prisma Advanced Patterns section
- tRPC integration: See tRPC Production Patterns section
- Type safety: See TypeScript Best Practices section

**Typical questions:**
- "How do I use NextAuth with Server Actions?" → Next.js 13+ App Router Patterns
- "How do I implement optimistic updates?" → React Query Integration
- "How do I add custom fields to session?" → TypeScript Best Practices
- "How do I implement role-based access in tRPC?" → tRPC Production Patterns

**Related topics:**
- Basic integrations: See `10-INTEGRATIONS.md`
- Session management: See `03-SESSIONS.md`
- Security patterns: See `09-SECURITY.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
