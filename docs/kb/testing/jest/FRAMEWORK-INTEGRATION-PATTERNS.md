---
id: jest-framework-integration-patterns
topic: jest
file_role: framework
profile: full
difficulty_level: intermediate-to-advanced
kb_version: 3.1
prerequisites: [jest-01-fundamentals]
related_topics: [nextjs, react, prisma, typescript]
embedding_keywords: [jest, nextjs, react, prisma, framework-integration, testing-patterns]
last_reviewed: 2025-11-14
---

# Jest Framework Integration Patterns

## 1. Purpose

Real-world Jest integration patterns for Next.js 16 App Router, React 19, Prisma 5.22, and TypeScript 5.9.3. This file provides comprehensive, production-ready testing patterns for the Bloom project stack and similar applications.

**What you'll learn:**
- Testing Next.js App Router components, routes, and middleware
- React Testing Library best practices for modern React
- Prisma database operation testing with SQLite
- TypeScript-first testing patterns
- Integration patterns between frameworks
- Common pitfalls and solutions

## 2. Next.js 16 App Router Integration

### [NX-01] Testing App Router API Routes

Next.js 16 introduced async params, which affects how you test API routes. Here's the correct approach:

#### Example 1 – Pedagogical: Basic GET Route

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db';

export async function GET(request: NextRequest) {
  const users = await prisma.user.findMany();
  return NextResponse.json(users);
}

// app/api/users/route.test.ts
import { GET } from './route';
import { NextRequest } from 'next/server';
import { prisma } from '@/lib/db';

jest.mock('@/lib/db', () => ({
  prisma: {
    user: {
      findMany: jest.fn(),
    },
  },
}));

describe('GET /api/users', () => {
  it('returns list of users', async () => {
    const mockUsers = [
      { id: '1', name: 'Alice', email: 'alice@example.com' },
      { id: '2', name: 'Bob', email: 'bob@example.com' },
    ];

    (prisma.user.findMany as jest.Mock).mockResolvedValue(mockUsers);

    const request = new NextRequest('http://localhost:3000/api/users');
    const response = await GET(request);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data).toEqual(mockUsers);
    expect(prisma.user.findMany).toHaveBeenCalledTimes(1);
  });
});
```

#### Example 2 – Realistic Synthetic: POST Route with Validation

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { prisma } from '@/lib/db';

const userSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
});

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const validated = userSchema.parse(body);

    const user = await prisma.user.create({
      data: validated,
    });

    return NextResponse.json(user, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      );
    }
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// app/api/users/route.test.ts
import { POST } from './route';
import { NextRequest } from 'next/server';
import { prisma } from '@/lib/db';

jest.mock('@/lib/db');

describe('POST /api/users', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('creates a new user with valid data', async () => {
    const mockUser = {
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    (prisma.user.create as jest.Mock).mockResolvedValue(mockUser);

    const request = new NextRequest('http://localhost:3000/api/users', {
      method: 'POST',
      body: JSON.stringify({
        name: 'Test User',
        email: 'test@example.com',
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(201);
    expect(data).toEqual(mockUser);
    expect(prisma.user.create).toHaveBeenCalledWith({
      data: {
        name: 'Test User',
        email: 'test@example.com',
      },
    });
  });

  it('returns 400 for invalid email', async () => {
    const request = new NextRequest('http://localhost:3000/api/users', {
      method: 'POST',
      body: JSON.stringify({
        name: 'Test User',
        email: 'invalid-email',
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toBe('Validation failed');
    expect(prisma.user.create).not.toHaveBeenCalled();
  });

  it('returns 400 for missing name', async () => {
    const request = new NextRequest('http://localhost:3000/api/users', {
      method: 'POST',
      body: JSON.stringify({
        email: 'test@example.com',
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toBe('Validation failed');
  });
});
```

#### Example 3 – Framework Integration: Dynamic Route with Async Params

```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db';

// Next.js 16: params is now a Promise
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params; // Must await the params Promise

  const user = await prisma.user.findUnique({
    where: { id },
  });

  if (!user) {
    return NextResponse.json(
      { error: 'User not found' },
      { status: 404 }
    );
  }

  return NextResponse.json(user);
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;

  try {
    await prisma.user.delete({
      where: { id },
    });

    return NextResponse.json({ success: true }, { status: 200 });
  } catch (error) {
    return NextResponse.json(
      { error: 'User not found' },
      { status: 404 }
    );
  }
}

// app/api/users/[id]/route.test.ts
import { GET, DELETE } from './route';
import { NextRequest } from 'next/server';
import { prisma } from '@/lib/db';

jest.mock('@/lib/db');

describe('GET /api/users/[id]', () => {
  it('returns user by id', async () => {
    const mockUser = {
      id: '123',
      name: 'Test User',
      email: 'test@example.com',
    };

    (prisma.user.findUnique as jest.Mock).mockResolvedValue(mockUser);

    const request = new NextRequest('http://localhost:3000/api/users/123');
    // Next.js 16: Pass params as a Promise
    const response = await GET(request, {
      params: Promise.resolve({ id: '123' }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data).toEqual(mockUser);
    expect(prisma.user.findUnique).toHaveBeenCalledWith({
      where: { id: '123' },
    });
  });

  it('returns 404 for non-existent user', async () => {
    (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);

    const request = new NextRequest('http://localhost:3000/api/users/999');
    const response = await GET(request, {
      params: Promise.resolve({ id: '999' }),
    });
    const data = await response.json();

    expect(response.status).toBe(404);
    expect(data.error).toBe('User not found');
  });
});

describe('DELETE /api/users/[id]', () => {
  it('deletes user successfully', async () => {
    (prisma.user.delete as jest.Mock).mockResolvedValue({});

    const request = new NextRequest('http://localhost:3000/api/users/123', {
      method: 'DELETE',
    });
    const response = await DELETE(request, {
      params: Promise.resolve({ id: '123' }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.success).toBe(true);
    expect(prisma.user.delete).toHaveBeenCalledWith({
      where: { id: '123' },
    });
  });

  it('returns 404 when deleting non-existent user', async () => {
    (prisma.user.delete as jest.Mock).mockRejectedValue(new Error('Not found'));

    const request = new NextRequest('http://localhost:3000/api/users/999', {
      method: 'DELETE',
    });
    const response = await DELETE(request, {
      params: Promise.resolve({ id: '999' }),
    });
    const data = await response.json();

    expect(response.status).toBe(404);
    expect(data.error).toBe('User not found');
  });
});
```

### [NX-02] Testing Server Components

Server Components are async by default in the App Router. Testing them requires handling the Promise returned by the component.

#### Example 1 – Pedagogical: Simple Server Component

```typescript
// app/components/UserList.tsx
import { prisma } from '@/lib/db';

export default async function UserList() {
  const users = await prisma.user.findMany();

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}

// app/components/UserList.test.tsx
import { render, screen } from '@testing-library/react';
import UserList from './UserList';
import { prisma } from '@/lib/db';

jest.mock('@/lib/db', () => ({
  prisma: {
    user: {
      findMany: jest.fn(),
    },
  },
}));

describe('UserList', () => {
  it('renders list of users', async () => {
    const mockUsers = [
      { id: '1', name: 'Alice', email: 'alice@example.com' },
      { id: '2', name: 'Bob', email: 'bob@example.com' },
    ];

    (prisma.user.findMany as jest.Mock).mockResolvedValue(mockUsers);

    // Server component returns a Promise
    const UserListResolved = await UserList();
    render(UserListResolved);

    expect(screen.getByText('Alice')).toBeInTheDocument();
    expect(screen.getByText('Bob')).toBeInTheDocument();
  });

  it('renders empty state when no users', async () => {
    (prisma.user.findMany as jest.Mock).mockResolvedValue([]);

    const UserListResolved = await UserList();
    const { container } = render(UserListResolved);

    expect(container.querySelector('ul')).toBeEmptyDOMElement();
  });
});
```

#### Example 2 – Realistic Synthetic: Server Component with Error Handling

```typescript
// app/components/SessionStats.tsx
import { prisma } from '@/lib/db';

export default async function SessionStats() {
  try {
    const stats = await prisma.session.aggregate({
      _count: true,
      _avg: {
        duration: true,
      },
    });

    return (
      <div className="stats">
        <div className="stat">
          <span className="label">Total Sessions</span>
          <span className="value">{stats._count}</span>
        </div>
        <div className="stat">
          <span className="label">Avg Duration</span>
          <span className="value">{Math.round(stats._avg.duration || 0)}m</span>
        </div>
      </div>
    );
  } catch (error) {
    return <div className="error">Failed to load statistics</div>;
  }
}

// app/components/SessionStats.test.tsx
import { render, screen } from '@testing-library/react';
import SessionStats from './SessionStats';
import { prisma } from '@/lib/db';

jest.mock('@/lib/db');

describe('SessionStats', () => {
  it('displays session statistics', async () => {
    const mockStats = {
      _count: 42,
      _avg: {
        duration: 15.5,
      },
    };

    (prisma.session.aggregate as jest.Mock).mockResolvedValue(mockStats);

    const component = await SessionStats();
    render(component);

    expect(screen.getByText('Total Sessions')).toBeInTheDocument();
    expect(screen.getByText('42')).toBeInTheDocument();
    expect(screen.getByText('Avg Duration')).toBeInTheDocument();
    expect(screen.getByText('16m')).toBeInTheDocument(); // Rounded
  });

  it('handles database errors gracefully', async () => {
    (prisma.session.aggregate as jest.Mock).mockRejectedValue(
      new Error('Database error')
    );

    const component = await SessionStats();
    render(component);

    expect(screen.getByText('Failed to load statistics')).toBeInTheDocument();
  });

  it('handles null average duration', async () => {
    const mockStats = {
      _count: 0,
      _avg: {
        duration: null,
      },
    };

    (prisma.session.aggregate as jest.Mock).mockResolvedValue(mockStats);

    const component = await SessionStats();
    render(component);

    expect(screen.getByText('0m')).toBeInTheDocument();
  });
});
```

### [NX-03] Testing Server Actions

Server Actions are async functions that can be called from client components. They require special handling in tests.

#### Example 1 – Pedagogical: Simple Server Action

```typescript
// app/actions/users.ts
'use server';

import { prisma } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function createUser(formData: FormData) {
  const name = formData.get('name') as string;
  const email = formData.get('email') as string;

  const user = await prisma.user.create({
    data: { name, email },
  });

  revalidatePath('/users');

  return user;
}

// app/actions/users.test.ts
import { createUser } from './users';
import { prisma } from '@/lib/db';
import { revalidatePath } from 'next/cache';

jest.mock('@/lib/db');
jest.mock('next/cache', () => ({
  revalidatePath: jest.fn(),
}));

describe('createUser', () => {
  it('creates a new user from form data', async () => {
    const mockUser = {
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
    };

    (prisma.user.create as jest.Mock).mockResolvedValue(mockUser);

    const formData = new FormData();
    formData.append('name', 'Test User');
    formData.append('email', 'test@example.com');

    const result = await createUser(formData);

    expect(result).toEqual(mockUser);
    expect(prisma.user.create).toHaveBeenCalledWith({
      data: {
        name: 'Test User',
        email: 'test@example.com',
      },
    });
    expect(revalidatePath).toHaveBeenCalledWith('/users');
  });
});
```

#### Example 2 – Framework Integration: Complex Server Action with Validation

```typescript
// app/actions/sessions.ts
'use server';

import { prisma } from '@/lib/db';
import { z } from 'zod';
import { revalidatePath } from 'next/cache';

const sessionSchema = z.object({
  organizationId: z.string().cuid(),
  title: z.string().min(1).max(200),
  description: z.string().optional(),
});

export async function createSession(formData: FormData) {
  const data = {
    organizationId: formData.get('organizationId') as string,
    title: formData.get('title') as string,
    description: (formData.get('description') as string) || undefined,
  };

  try {
    const validated = sessionSchema.parse(data);

    const session = await prisma.session.create({
      data: {
        ...validated,
        status: 'PENDING',
        createdAt: new Date(),
      },
      include: {
        organization: true,
      },
    });

    revalidatePath('/sessions');

    return { success: true, session };
  } catch (error) {
    if (error instanceof z.ZodError) {
      return {
        success: false,
        error: 'Validation failed',
        details: error.errors,
      };
    }

    return {
      success: false,
      error: 'Failed to create session',
    };
  }
}

// app/actions/sessions.test.ts
import { createSession } from './sessions';
import { prisma } from '@/lib/db';
import { revalidatePath } from 'next/cache';

jest.mock('@/lib/db');
jest.mock('next/cache');

describe('createSession', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('creates a session with valid data', async () => {
    const mockSession = {
      id: 'session-1',
      organizationId: 'org-1',
      title: 'Test Session',
      description: 'Test description',
      status: 'PENDING',
      createdAt: new Date(),
      organization: {
        id: 'org-1',
        name: 'Test Org',
      },
    };

    (prisma.session.create as jest.Mock).mockResolvedValue(mockSession);

    const formData = new FormData();
    formData.append('organizationId', 'org-1');
    formData.append('title', 'Test Session');
    formData.append('description', 'Test description');

    const result = await createSession(formData);

    expect(result.success).toBe(true);
    expect(result.session).toEqual(mockSession);
    expect(revalidatePath).toHaveBeenCalledWith('/sessions');
  });

  it('validates organization ID format', async () => {
    const formData = new FormData();
    formData.append('organizationId', 'invalid-id');
    formData.append('title', 'Test Session');

    const result = await createSession(formData);

    expect(result.success).toBe(false);
    expect(result.error).toBe('Validation failed');
    expect(result.details).toBeDefined();
    expect(prisma.session.create).not.toHaveBeenCalled();
  });

  it('validates title is required', async () => {
    const formData = new FormData();
    formData.append('organizationId', 'clabcdef123456789');

    const result = await createSession(formData);

    expect(result.success).toBe(false);
    expect(result.error).toBe('Validation failed');
  });

  it('handles database errors', async () => {
    (prisma.session.create as jest.Mock).mockRejectedValue(
      new Error('Database error')
    );

    const formData = new FormData();
    formData.append('organizationId', 'clabcdef123456789');
    formData.append('title', 'Test Session');

    const result = await createSession(formData);

    expect(result.success).toBe(false);
    expect(result.error).toBe('Failed to create session');
  });
});
```

### [NX-04] Testing Middleware

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const isAuthenticated = request.cookies.get('session')?.value;

  // Redirect to login if not authenticated
  if (!isAuthenticated && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // Add custom header
  const response = NextResponse.next();
  response.headers.set('x-custom-header', 'value');

  return response;
}

export const config = {
  matcher: ['/dashboard/:path*'],
};

// middleware.test.ts
import { middleware } from './middleware';
import { NextRequest } from 'next/server';

describe('middleware', () => {
  it('allows authenticated users to access dashboard', () => {
    const request = new NextRequest('http://localhost:3000/dashboard', {
      headers: {
        cookie: 'session=valid-token',
      },
    });

    const response = middleware(request);

    expect(response?.status).not.toBe(307); // Not a redirect
    expect(response?.headers.get('x-custom-header')).toBe('value');
  });

  it('redirects unauthenticated users to login', () => {
    const request = new NextRequest('http://localhost:3000/dashboard', {
      headers: {
        cookie: '',
      },
    });

    const response = middleware(request);

    expect(response?.status).toBe(307);
    expect(response?.headers.get('location')).toBe('http://localhost:3000/login');
  });

  it('allows access to non-protected routes', () => {
    const request = new NextRequest('http://localhost:3000/public', {
      headers: {
        cookie: '',
      },
    });

    const response = middleware(request);

    expect(response?.headers.get('x-custom-header')).toBe('value');
  });
});
```

## 3. React 19 Testing Library Integration

### [RT-01] Testing Client Components with User Interactions

#### Example 1 – Pedagogical: Button Click

```typescript
// components/Counter.tsx
'use client';

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
      <button onClick={() => setCount(count - 1)}>Decrement</button>
      <button onClick={() => setCount(0)}>Reset</button>
    </div>
  );
}

// components/Counter.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Counter } from './Counter';

describe('Counter', () => {
  it('increments count when increment button is clicked', async () => {
    const user = userEvent.setup();
    render(<Counter />);

    expect(screen.getByText('Count: 0')).toBeInTheDocument();

    await user.click(screen.getByText('Increment'));

    expect(screen.getByText('Count: 1')).toBeInTheDocument();
  });

  it('decrements count when decrement button is clicked', async () => {
    const user = userEvent.setup();
    render(<Counter />);

    await user.click(screen.getByText('Increment'));
    await user.click(screen.getByText('Increment'));
    await user.click(screen.getByText('Decrement'));

    expect(screen.getByText('Count: 1')).toBeInTheDocument();
  });

  it('resets count to zero', async () => {
    const user = userEvent.setup();
    render(<Counter />);

    await user.click(screen.getByText('Increment'));
    await user.click(screen.getByText('Increment'));
    await user.click(screen.getByText('Reset'));

    expect(screen.getByText('Count: 0')).toBeInTheDocument();
  });
});
```

#### Example 2 – Realistic Synthetic: Form with Validation

```typescript
// components/UserForm.tsx
'use client';

import { useState } from 'react';

interface UserFormProps {
  onSubmit: (data: { name: string; email: string }) => Promise<void>;
}

export function UserForm({ onSubmit }: UserFormProps) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const validate = () => {
    const newErrors: Record<string, string> = {};

    if (!name.trim()) {
      newErrors.name = 'Name is required';
    }

    if (!email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      newErrors.email = 'Email is invalid';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validate()) {
      return;
    }

    setIsSubmitting(true);
    try {
      await onSubmit({ name, email });
      setName('');
      setEmail('');
      setErrors({});
    } catch (error) {
      setErrors({ submit: 'Failed to submit form' });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="name">Name</label>
        <input
          id="name"
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          aria-invalid={!!errors.name}
        />
        {errors.name && <span className="error">{errors.name}</span>}
      </div>

      <div>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          aria-invalid={!!errors.email}
        />
        {errors.email && <span className="error">{errors.email}</span>}
      </div>

      {errors.submit && <div className="error">{errors.submit}</div>}

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Submitting...' : 'Submit'}
      </button>
    </form>
  );
}

// components/UserForm.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { UserForm } from './UserForm';

describe('UserForm', () => {
  const mockSubmit = jest.fn();

  beforeEach(() => {
    mockSubmit.mockClear();
  });

  it('submits form with valid data', async () => {
    const user = userEvent.setup();
    mockSubmit.mockResolvedValue(undefined);

    render(<UserForm onSubmit={mockSubmit} />);

    await user.type(screen.getByLabelText('Name'), 'John Doe');
    await user.type(screen.getByLabelText('Email'), 'john@example.com');
    await user.click(screen.getByText('Submit'));

    await waitFor(() => {
      expect(mockSubmit).toHaveBeenCalledWith({
        name: 'John Doe',
        email: 'john@example.com',
      });
    });
  });

  it('shows validation error for empty name', async () => {
    const user = userEvent.setup();
    render(<UserForm onSubmit={mockSubmit} />);

    await user.type(screen.getByLabelText('Email'), 'john@example.com');
    await user.click(screen.getByText('Submit'));

    expect(screen.getByText('Name is required')).toBeInTheDocument();
    expect(mockSubmit).not.toHaveBeenCalled();
  });

  it('shows validation error for invalid email', async () => {
    const user = userEvent.setup();
    render(<UserForm onSubmit={mockSubmit} />);

    await user.type(screen.getByLabelText('Name'), 'John Doe');
    await user.type(screen.getByLabelText('Email'), 'invalid-email');
    await user.click(screen.getByText('Submit'));

    expect(screen.getByText('Email is invalid')).toBeInTheDocument();
    expect(mockSubmit).not.toHaveBeenCalled();
  });

  it('shows submit error message', async () => {
    const user = userEvent.setup();
    mockSubmit.mockRejectedValue(new Error('Network error'));

    render(<UserForm onSubmit={mockSubmit} />);

    await user.type(screen.getByLabelText('Name'), 'John Doe');
    await user.type(screen.getByLabelText('Email'), 'john@example.com');
    await user.click(screen.getByText('Submit'));

    await waitFor(() => {
      expect(screen.getByText('Failed to submit form')).toBeInTheDocument();
    });
  });

  it('disables submit button while submitting', async () => {
    const user = userEvent.setup();
    mockSubmit.mockImplementation(() => new Promise((resolve) => setTimeout(resolve, 100)));

    render(<UserForm onSubmit={mockSubmit} />);

    await user.type(screen.getByLabelText('Name'), 'John Doe');
    await user.type(screen.getByLabelText('Email'), 'john@example.com');

    const submitButton = screen.getByText('Submit');
    await user.click(submitButton);

    expect(screen.getByText('Submitting...')).toBeInTheDocument();
    expect(submitButton).toBeDisabled();

    await waitFor(() => {
      expect(screen.getByText('Submit')).toBeInTheDocument();
    });
  });

  it('clears form after successful submission', async () => {
    const user = userEvent.setup();
    mockSubmit.mockResolvedValue(undefined);

    render(<UserForm onSubmit={mockSubmit} />);

    const nameInput = screen.getByLabelText('Name') as HTMLInputElement;
    const emailInput = screen.getByLabelText('Email') as HTMLInputElement;

    await user.type(nameInput, 'John Doe');
    await user.type(emailInput, 'john@example.com');
    await user.click(screen.getByText('Submit'));

    await waitFor(() => {
      expect(nameInput.value).toBe('');
      expect(emailInput.value).toBe('');
    });
  });
});
```

### [RT-02] Testing Custom Hooks

```typescript
// hooks/useLocalStorage.ts
import { useState, useEffect } from 'react';

export function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    if (typeof window === 'undefined') {
      return initialValue;
    }

    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(error);
      return initialValue;
    }
  });

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);

      if (typeof window !== 'undefined') {
        window.localStorage.setItem(key, JSON.stringify(valueToStore));
      }
    } catch (error) {
      console.error(error);
    }
  };

  return [storedValue, setValue] as const;
}

// hooks/useLocalStorage.test.ts
import { renderHook, act } from '@testing-library/react';
import { useLocalStorage } from './useLocalStorage';

describe('useLocalStorage', () => {
  beforeEach(() => {
    localStorage.clear();
    jest.clearAllMocks();
  });

  it('returns initial value when no stored value exists', () => {
    const { result } = renderHook(() => useLocalStorage('test-key', 'initial'));

    expect(result.current[0]).toBe('initial');
  });

  it('returns stored value when it exists', () => {
    localStorage.setItem('test-key', JSON.stringify('stored value'));

    const { result } = renderHook(() => useLocalStorage('test-key', 'initial'));

    expect(result.current[0]).toBe('stored value');
  });

  it('updates stored value', () => {
    const { result } = renderHook(() => useLocalStorage('test-key', 'initial'));

    act(() => {
      result.current[1]('updated value');
    });

    expect(result.current[0]).toBe('updated value');
    expect(localStorage.getItem('test-key')).toBe(JSON.stringify('updated value'));
  });

  it('updates value using function', () => {
    const { result } = renderHook(() => useLocalStorage('test-key', 10));

    act(() => {
      result.current[1]((prev) => prev + 5);
    });

    expect(result.current[0]).toBe(15);
  });

  it('handles complex objects', () => {
    const initialValue = { name: 'Test', count: 0 };
    const { result } = renderHook(() => useLocalStorage('test-key', initialValue));

    act(() => {
      result.current[1]({ name: 'Updated', count: 5 });
    });

    expect(result.current[0]).toEqual({ name: 'Updated', count: 5 });
    expect(JSON.parse(localStorage.getItem('test-key')!)).toEqual({
      name: 'Updated',
      count: 5,
    });
  });

  it('handles localStorage errors gracefully', () => {
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
    jest.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new Error('QuotaExceededError');
    });

    const { result } = renderHook(() => useLocalStorage('test-key', 'initial'));

    act(() => {
      result.current[1]('new value');
    });

    expect(consoleErrorSpy).toHaveBeenCalled();

    consoleErrorSpy.mockRestore();
  });
});
```

### [RT-03] Testing Context Providers

```typescript
// contexts/ThemeContext.tsx
'use client';

import { createContext, useContext, useState, ReactNode } from 'react';

type Theme = 'light' | 'dark';

interface ThemeContextType {
  theme: Theme;
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('light');

  const toggleTheme = () => {
    setTheme((prevTheme) => (prevTheme === 'light' ? 'dark' : 'light'));
  };

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (context === undefined) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
}

// contexts/ThemeContext.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderHook, act } from '@testing-library/react';
import { ThemeProvider, useTheme } from './ThemeContext';

describe('ThemeContext', () => {
  it('provides default theme', () => {
    const { result } = renderHook(() => useTheme(), {
      wrapper: ThemeProvider,
    });

    expect(result.current.theme).toBe('light');
  });

  it('toggles theme', () => {
    const { result } = renderHook(() => useTheme(), {
      wrapper: ThemeProvider,
    });

    act(() => {
      result.current.toggleTheme();
    });

    expect(result.current.theme).toBe('dark');

    act(() => {
      result.current.toggleTheme();
    });

    expect(result.current.theme).toBe('light');
  });

  it('throws error when used outside provider', () => {
    // Suppress console.error for this test
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();

    expect(() => {
      renderHook(() => useTheme());
    }).toThrow('useTheme must be used within a ThemeProvider');

    consoleErrorSpy.mockRestore();
  });

  it('provides theme to child components', async () => {
    const user = userEvent.setup();

    function TestComponent() {
      const { theme, toggleTheme } = useTheme();
      return (
        <div>
          <span>Current theme: {theme}</span>
          <button onClick={toggleTheme}>Toggle</button>
        </div>
      );
    }

    render(
      <ThemeProvider>
        <TestComponent />
      </ThemeProvider>
    );

    expect(screen.getByText('Current theme: light')).toBeInTheDocument();

    await user.click(screen.getByText('Toggle'));

    expect(screen.getByText('Current theme: dark')).toBeInTheDocument();
  });
});
```

## 4. Prisma 5.22 + SQLite Integration

### [PR-01] Mocking Prisma Client

#### Example 1 – Pedagogical: Basic Mock Setup

```typescript
// lib/db/__mocks__/index.ts
import { PrismaClient } from '@prisma/client';
import { mockDeep, mockReset, DeepMockProxy } from 'jest-mock-extended';

export const prisma = mockDeep<PrismaClient>();

beforeEach(() => {
  mockReset(prisma);
});

// lib/services/userService.ts
import { prisma } from '@/lib/db';

export async function getUserById(id: string) {
  return prisma.user.findUnique({
    where: { id },
  });
}

export async function getAllUsers() {
  return prisma.user.findMany();
}

// lib/services/userService.test.ts
import { getUserById, getAllUsers } from './userService';
import { prisma } from '@/lib/db';

jest.mock('@/lib/db');

describe('UserService', () => {
  describe('getUserById', () => {
    it('returns user by id', async () => {
      const mockUser = {
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      (prisma.user.findUnique as jest.Mock).mockResolvedValue(mockUser);

      const result = await getUserById('1');

      expect(result).toEqual(mockUser);
      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { id: '1' },
      });
    });

    it('returns null for non-existent user', async () => {
      (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);

      const result = await getUserById('999');

      expect(result).toBeNull();
    });
  });

  describe('getAllUsers', () => {
    it('returns all users', async () => {
      const mockUsers = [
        { id: '1', name: 'User 1', email: 'user1@example.com' },
        { id: '2', name: 'User 2', email: 'user2@example.com' },
      ];

      (prisma.user.findMany as jest.Mock).mockResolvedValue(mockUsers);

      const result = await getAllUsers();

      expect(result).toEqual(mockUsers);
      expect(prisma.user.findMany).toHaveBeenCalledTimes(1);
    });
  });
});
```

#### Example 2 – Realistic Synthetic: Testing with Relations

```typescript
// lib/services/sessionService.ts
import { prisma } from '@/lib/db';

export async function getSessionWithDetails(sessionId: string) {
  return prisma.session.findUnique({
    where: { id: sessionId },
    include: {
      organization: true,
      messages: {
        orderBy: { createdAt: 'asc' },
      },
    },
  });
}

export async function createSessionWithOrganization(data: {
  title: string;
  organizationId: string;
}) {
  return prisma.session.create({
    data: {
      title: data.title,
      status: 'PENDING',
      organization: {
        connect: { id: data.organizationId },
      },
    },
    include: {
      organization: true,
    },
  });
}

// lib/services/sessionService.test.ts
import { getSessionWithDetails, createSessionWithOrganization } from './sessionService';
import { prisma } from '@/lib/db';

jest.mock('@/lib/db');

describe('SessionService', () => {
  describe('getSessionWithDetails', () => {
    it('returns session with organization and messages', async () => {
      const mockSession = {
        id: 'session-1',
        title: 'Test Session',
        status: 'ACTIVE',
        organization: {
          id: 'org-1',
          name: 'Test Organization',
        },
        messages: [
          { id: 'msg-1', content: 'Hello', createdAt: new Date('2025-01-01') },
          { id: 'msg-2', content: 'World', createdAt: new Date('2025-01-02') },
        ],
      };

      (prisma.session.findUnique as jest.Mock).mockResolvedValue(mockSession);

      const result = await getSessionWithDetails('session-1');

      expect(result).toEqual(mockSession);
      expect(prisma.session.findUnique).toHaveBeenCalledWith({
        where: { id: 'session-1' },
        include: {
          organization: true,
          messages: {
            orderBy: { createdAt: 'asc' },
          },
        },
      });
    });
  });

  describe('createSessionWithOrganization', () => {
    it('creates session and connects to organization', async () => {
      const mockSession = {
        id: 'session-1',
        title: 'New Session',
        status: 'PENDING',
        organization: {
          id: 'org-1',
          name: 'Test Organization',
        },
      };

      (prisma.session.create as jest.Mock).mockResolvedValue(mockSession);

      const result = await createSessionWithOrganization({
        title: 'New Session',
        organizationId: 'org-1',
      });

      expect(result).toEqual(mockSession);
      expect(prisma.session.create).toHaveBeenCalledWith({
        data: {
          title: 'New Session',
          status: 'PENDING',
          organization: {
            connect: { id: 'org-1' },
          },
        },
        include: {
          organization: true,
        },
      });
    });
  });
});
```

### [PR-02] Testing Transactions

```typescript
// lib/services/transferService.ts
import { prisma } from '@/lib/db';

export async function transferCredits(
  fromUserId: string,
  toUserId: string,
  amount: number
) {
  return prisma.$transaction(async (tx) => {
    // Deduct from sender
    const sender = await tx.user.update({
      where: { id: fromUserId },
      data: { credits: { decrement: amount } },
    });

    if (sender.credits < 0) {
      throw new Error('Insufficient credits');
    }

    // Add to receiver
    const receiver = await tx.user.update({
      where: { id: toUserId },
      data: { credits: { increment: amount } },
    });

    // Create transfer record
    await tx.transfer.create({
      data: {
        fromUserId,
        toUserId,
        amount,
      },
    });

    return { sender, receiver };
  });
}

// lib/services/transferService.test.ts
import { transferCredits } from './transferService';
import { prisma } from '@/lib/db';
import { mockDeep } from 'jest-mock-extended';

jest.mock('@/lib/db');

describe('transferCredits', () => {
  it('transfers credits between users', async () => {
    const mockTx = mockDeep<typeof prisma>();

    const mockSender = { id: 'user-1', credits: 50 };
    const mockReceiver = { id: 'user-2', credits: 150 };

    mockTx.user.update
      .mockResolvedValueOnce(mockSender as any)
      .mockResolvedValueOnce(mockReceiver as any);

    mockTx.transfer.create.mockResolvedValue({
      id: 'transfer-1',
      fromUserId: 'user-1',
      toUserId: 'user-2',
      amount: 50,
    } as any);

    (prisma.$transaction as jest.Mock).mockImplementation(async (callback) => {
      return callback(mockTx);
    });

    const result = await transferCredits('user-1', 'user-2', 50);

    expect(result.sender.credits).toBe(50);
    expect(result.receiver.credits).toBe(150);
  });

  it('throws error for insufficient credits', async () => {
    const mockTx = mockDeep<typeof prisma>();

    mockTx.user.update.mockResolvedValueOnce({
      id: 'user-1',
      credits: -50, // Negative after deduction
    } as any);

    (prisma.$transaction as jest.Mock).mockImplementation(async (callback) => {
      return callback(mockTx);
    });

    await expect(transferCredits('user-1', 'user-2', 150)).rejects.toThrow(
      'Insufficient credits'
    );
  });
});
```

## 5. TypeScript 5.9.3 Type-Safe Testing

### [TS-01] Generic Test Utilities

```typescript
// test/utils/factories.ts
import { User, Session } from '@prisma/client';

type Factory<T> = (overrides?: Partial<T>) => T;

export const createMockUser: Factory<User> = (overrides = {}) => ({
  id: 'user-1',
  name: 'Test User',
  email: 'test@example.com',
  createdAt: new Date('2025-01-01'),
  updatedAt: new Date('2025-01-01'),
  ...overrides,
});

export const createMockSession: Factory<Session> = (overrides = {}) => ({
  id: 'session-1',
  organizationId: 'org-1',
  title: 'Test Session',
  description: null,
  status: 'PENDING',
  createdAt: new Date('2025-01-01'),
  updatedAt: new Date('2025-01-01'),
  ...overrides,
});

// Usage in tests
import { createMockUser, createMockSession } from '@/test/utils/factories';

test('example', () => {
  const user = createMockUser({ name: 'Custom Name' });
  const session = createMockSession({ status: 'ACTIVE' });

  expect(user.name).toBe('Custom Name');
  expect(session.status).toBe('ACTIVE');
});
```

### [TS-02] Type-Safe Mock Functions

```typescript
// test/utils/mockFunctions.ts
export function createMockFunction<T extends (...args: any[]) => any>(): jest.MockedFunction<T> {
  return jest.fn() as jest.MockedFunction<T>;
}

// Usage
import { createMockFunction } from '@/test/utils/mockFunctions';

type FetchUser = (id: string) => Promise<User>;

const mockFetchUser = createMockFunction<FetchUser>();
mockFetchUser.mockResolvedValue(createMockUser());

// TypeScript ensures correct types
await mockFetchUser('123'); // ✓ Correct
await mockFetchUser(); // ✗ TypeScript error: Expected 1 argument
```

## 6. Common Pitfalls and Solutions

### Pitfall 1: Not Awaiting Async Params in Next.js 16

**❌ Wrong:**
```typescript
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const { id } = params; // Error: params is a Promise
}
```

**✅ Correct:**
```typescript
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params; // Must await
}
```

### Pitfall 2: Mocking ESM Modules Incorrectly

**❌ Wrong:**
```typescript
jest.mock('./module');
import { function } from './module'; // Hoisting issue
```

**✅ Correct:**
```typescript
jest.mock('./module'); // Hoisting makes this run first

import { function } from './module'; // Now safe
```

### Pitfall 3: Not Resetting Mocks Between Tests

**❌ Wrong:**
```typescript
describe('tests', () => {
  it('test 1', () => {
    mockFn.mockReturnValue('value1');
    // ...
  });

  it('test 2', () => {
    // mockFn still has 'value1' implementation!
  });
});
```

**✅ Correct:**
```typescript
describe('tests', () => {
  beforeEach(() => {
    jest.clearAllMocks(); // or jest.resetAllMocks()
  });

  it('test 1', () => {
    mockFn.mockReturnValue('value1');
  });

  it('test 2', () => {
    // mockFn is clean now
  });
});
```

### Pitfall 4: Testing Implementation Details

**❌ Wrong:**
```typescript
test('counter increments', () => {
  render(<Counter />);
  const button = container.querySelector('.increment-button');
  // Relies on class name
});
```

**✅ Correct:**
```typescript
test('counter increments', () => {
  render(<Counter />);
  const button = screen.getByRole('button', { name: /increment/i });
  // Uses accessible queries
});
```

### Pitfall 5: Not Handling Async Operations in React

**❌ Wrong:**
```typescript
test('loads data', () => {
  render(<AsyncComponent />);
  expect(screen.getByText('Data loaded')).toBeInTheDocument();
  // Fails: data hasn't loaded yet
});
```

**✅ Correct:**
```typescript
test('loads data', async () => {
  render(<AsyncComponent />);
  await screen.findByText('Data loaded'); // Waits for element
  // Or:
  await waitFor(() => {
    expect(screen.getByText('Data loaded')).toBeInTheDocument();
  });
});
```

## 7. AI Pair Programming Notes

### When to Load This File

- **Always load when**: Working on Next.js API routes, React components, or Prisma operations
- **Combine with**:
  - `QUICK-REFERENCE.md` for syntax
  - `05-REACT-TESTING.md` for deep React patterns
  - `06-API-TESTING.md` for API-specific patterns
  - `07-DATABASE-TESTING.md` for database-specific patterns

### Recommended Context Bundles

**Bundle 1: Next.js App Router Testing**
- This file (FRAMEWORK-INTEGRATION-PATTERNS.md)
- 06-API-TESTING.md
- QUICK-REFERENCE.md

**Bundle 2: React Component Testing**
- This file (FRAMEWORK-INTEGRATION-PATTERNS.md)
- 05-REACT-TESTING.md
- QUICK-REFERENCE.md

**Bundle 3: Database Testing**
- This file (FRAMEWORK-INTEGRATION-PATTERNS.md)
- 07-DATABASE-TESTING.md
- QUICK-REFERENCE.md

### Prompt Patterns

```
"Using FRAMEWORK-INTEGRATION-PATTERNS.md, write tests for this Next.js 16 API route with async params."

"Reference the Prisma mocking patterns in FRAMEWORK-INTEGRATION-PATTERNS.md to test this database service."

"Load FRAMEWORK-INTEGRATION-PATTERNS.md and QUICK-REFERENCE.md to test this React component with user interactions."
```

### What to Avoid

- **Don't** mix Server and Client Component patterns
- **Don't** mock Next.js internals (cache, headers) unnecessarily
- **Don't** test Prisma's internal behavior
- **Don't** use outdated Next.js 14/15 patterns
- **Don't** forget to await async params in Next.js 16

### Framework-Specific Best Practices

**Next.js:**
- Always await params in dynamic routes
- Mock data fetching, not Next.js functions
- Test route handlers as pure functions
- Use NextRequest/NextResponse types

**React:**
- Use `userEvent` over `fireEvent`
- Query by role, label, text (in that order)
- Await async operations
- Test behavior, not implementation

**Prisma:**
- Mock at the client level, not query level
- Use `jest-mock-extended` for type safety
- Reset mocks between tests
- Test error cases (not found, validation, etc.)

**TypeScript:**
- Use factory functions for mock data
- Type your mock functions
- Use `satisfies` for partial mocks
- Leverage type inference

## Last Updated

2025-11-14
