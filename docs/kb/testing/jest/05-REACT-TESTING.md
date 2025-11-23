---
id: jest-05-react-testing
topic: jest
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [jest-01-fundamentals, react-basics]
related_topics: [react, testing-library, component-testing]
embedding_keywords: [jest, react, testing-library, component-testing, RTL]
last_reviewed: 2025-11-14
---

# React Component Testing with Jest

## 1. Purpose

This guide provides comprehensive patterns for testing React components using Jest and React Testing Library in the Bloom application. It covers rendering components, simulating user interactions, testing hooks, handling async behavior, and testing Next.js 16 App Router components.

**What You'll Learn:**
- React Testing Library fundamentals (render, screen, queries)
- User event simulation and interaction testing
- Testing custom hooks and Zustand stores
- Async testing patterns (waitFor, findBy)
- Next.js 16 Server vs Client Component testing
- Bloom-specific component testing patterns

**When to Use:**
- Testing React component rendering and display logic
- Verifying user interactions (clicks, form submission, typing)
- Testing conditional rendering and state changes
- Validating accessibility and semantic HTML
- Integration testing between multiple components

**When NOT to Use:**
- End-to-end flows across multiple pages → Use Playwright
- API endpoint testing → Use integration tests
- Performance benchmarking → Use dedicated tools
- Visual regression testing → Use Chromatic/Percy

---

## 2. Mental Model / Problem Statement

### The Testing Philosophy

React Testing Library follows a **user-centric testing philosophy**:

> "The more your tests resemble the way your software is used, the more confidence they can give you."

**Traditional Approach (Implementation-Focused):**
```
Test Component → Test Props → Test State → Test Methods
❌ Brittle: Tests break when refactoring
❌ False confidence: Passing tests, broken UI
❌ Poor user experience validation
```

**RTL Approach (User-Focused):**
```
Render Component → Find Elements (as users do) → Interact → Assert Behavior
✅ Resilient: Tests survive refactoring
✅ High confidence: Tests match user experience
✅ Accessibility validation built-in
```

### The Testing Pyramid in Bloom

```
        /\
       /  \
      / E2E \    ← Playwright (critical paths: workshop flow, export)
     /------\
    /        \
   / Integration \  ← Jest + RTL (component behavior, user interactions)
  /--------------\
 /                \
/ Unit Tests       \  ← Jest (pure functions, utilities, ROI calculations)
--------------------
```

**React Testing Library sits at the Integration layer**, testing how components work together from the user's perspective.

### Key Concepts

**1. Queries (Finding Elements)**
- Query by what users see: roles, labels, text
- Three variants: `getBy*` (sync), `queryBy*` (nullable), `findBy*` (async)
- Priority: role > label > placeholder > text > test ID

**2. User Events**
- Simulate realistic interactions: clicks, typing, form submission
- Two APIs: `userEvent` (realistic, async) vs `fireEvent` (simple, sync)
- Tests should mimic real user behavior

**3. Async Testing**
- Use `findBy*` queries for elements that appear after delay
- Use `waitFor` for complex assertions
- Use `waitForElementToBeRemoved` for disappearing elements

**4. Component Isolation**
- Mock external dependencies (APIs, stores, routers)
- Provide test wrappers for context providers
- Control time with `jest.useFakeTimers()`

---

## 3. Golden Path

### Step 1: Basic Component Test

```typescript
// components/bloom/SessionCard.tsx
"use client";

export function SessionCard({ session }) {
  return (
    <div>
      <h3>{session.id}</h3>
      <span>{session.status}</span>
    </div>
  );
}
```

```typescript
// __tests__/components/bloom/SessionCard.test.tsx
import { render, screen } from '@testing-library/react';
import { SessionCard } from '@/components/bloom/SessionCard';

describe('SessionCard', () => {
  test('renders session details', () => {
    const mockSession = {
      id: 'WS-20251114-A1B2',
      status: 'active',
      startedAt: '2025-11-14T10:00:00Z',
    };

    render(<SessionCard session={mockSession} />);

    // Query by accessible content
    expect(screen.getByText(/A1B2/i)).toBeInTheDocument();
    expect(screen.getByText(/active/i)).toBeInTheDocument();
  });
});
```

**Key Points:**
- Use `render()` to mount component in test DOM
- Use `screen` queries to find elements
- Use regex (`/text/i`) for case-insensitive matching
- Use `toBeInTheDocument()` matcher from `@testing-library/jest-dom`

---

### Step 2: Testing User Interactions

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('user can pause active session', async () => {
  const user = userEvent.setup();
  const onStatusChange = jest.fn();

  global.fetch = jest.fn().mockResolvedValueOnce({
    ok: true,
    json: async () => ({ status: 'idle' }),
  });

  render(
    <SessionCard
      session={{ id: 'WS-123', status: 'active' }}
      onStatusChange={onStatusChange}
    />
  );

  // Find and click button
  const pauseButton = screen.getByRole('button', { name: /pause/i });
  await user.click(pauseButton);

  // Verify API call
  expect(global.fetch).toHaveBeenCalledWith(
    '/api/sessions/WS-123/pause',
    { method: 'POST' }
  );

  // Verify UI update (async)
  expect(await screen.findByText(/idle/i)).toBeInTheDocument();

  // Verify callback
  expect(onStatusChange).toHaveBeenCalledWith('WS-123', 'idle');
});
```

**Key Points:**
- Use `userEvent.setup()` for realistic event simulation
- Mock `fetch` to control API responses
- Use `await` with `user.*` methods (they return Promises)
- Use `findBy*` for elements that appear after async operations
- Verify side effects: API calls, callbacks, UI updates

---

### Step 3: Testing Forms

```typescript
test('submits message form', async () => {
  const user = userEvent.setup();
  const onSubmit = jest.fn();

  render(<MessageForm onSubmit={onSubmit} />);

  // Fill in form
  await user.type(screen.getByLabelText(/message/i), 'Hello Melissa');

  // Submit form
  await user.click(screen.getByRole('button', { name: /send/i }));

  // Verify submission
  expect(onSubmit).toHaveBeenCalledWith({
    message: 'Hello Melissa',
  });
});

test('shows validation errors', async () => {
  const user = userEvent.setup();
  render(<MessageForm />);

  // Submit empty form
  await user.click(screen.getByRole('button', { name: /send/i }));

  // Verify error message appears
  expect(await screen.findByText(/message is required/i)).toBeInTheDocument();
});
```

---

### Step 4: Testing with Context Providers

```typescript
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

function renderWithProviders(ui: React.ReactElement) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },  // Disable retries in tests
    },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      {ui}
    </QueryClientProvider>
  );
}

test('fetches and displays sessions', async () => {
  global.fetch = jest.fn().mockResolvedValueOnce({
    ok: true,
    json: async () => ({
      sessions: [{ id: 'WS-123', status: 'active' }],
    }),
  });

  renderWithProviders(<SessionList />);

  // Wait for async data to load
  expect(await screen.findByText(/WS-123/i)).toBeInTheDocument();
});
```

---

### Step 5: Testing Custom Hooks

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { useSessionData } from '@/hooks/useSessionData';

test('fetches session data', async () => {
  global.fetch = jest.fn().mockResolvedValueOnce({
    ok: true,
    json: async () => ({ session: { id: 'WS-123' } }),
  });

  const { result } = renderHook(() => useSessionData('WS-123'));

  // Initial state
  expect(result.current.isLoading).toBe(true);

  // Wait for data to load
  await waitFor(() => {
    expect(result.current.isLoading).toBe(false);
  });

  expect(result.current.data).toEqual({ session: { id: 'WS-123' } });
});
```

---

### Step 6: Testing Zustand Stores

```typescript
import { renderHook, act } from '@testing-library/react';
import { useSessionStore } from '@/stores/sessionStore';

test('adds message to store', () => {
  const { result } = renderHook(() => useSessionStore());

  expect(result.current.messages).toHaveLength(0);

  act(() => {
    result.current.addMessage({
      id: '1',
      role: 'user',
      content: 'Hello',
      timestamp: new Date(),
    });
  });

  expect(result.current.messages).toHaveLength(1);
  expect(result.current.messages[0].content).toBe('Hello');
});
```

---

## 4. Variations & Trade-Offs

### Query Variants

**1. getBy* - Synchronous, throws error**
```typescript
// ✅ Use when: Element must exist immediately
const button = screen.getByRole('button');

// ❌ Throws error: Element not found
// ❌ Throws error: Multiple elements found
```

**2. queryBy* - Synchronous, returns null**
```typescript
// ✅ Use when: Asserting element does NOT exist
const error = screen.queryByText(/error/i);
expect(error).not.toBeInTheDocument();

// ❌ Don't use for: Elements that should exist (use getBy*)
```

**3. findBy* - Asynchronous, returns Promise**
```typescript
// ✅ Use when: Element appears after async operation
const message = await screen.findByText(/success/i);

// Default timeout: 1000ms
// Custom timeout:
const element = await screen.findByText(/text/i, {}, { timeout: 5000 });
```

---

### userEvent vs fireEvent

**userEvent (Recommended)**

```typescript
import userEvent from '@testing-library/user-event';

test('realistic user interaction', async () => {
  const user = userEvent.setup();

  // ✅ Simulates full event sequence
  await user.click(button);  // mousedown → focus → mouseup → click

  // ✅ Types one character at a time
  await user.type(input, 'Hello');  // Tests incremental validation

  // ✅ Respects disabled/readonly state
  await user.click(disabledButton);  // Won't fire click event
});
```

**Pros:**
- More realistic browser behavior
- Better for testing user workflows
- Catches edge cases (disabled elements, focus management)

**Cons:**
- Requires `async/await` (more verbose)
- Slightly slower than fireEvent

---

**fireEvent (Simple Cases)**

```typescript
import { fireEvent } from '@testing-library/react';

test('simple click handler', () => {
  const onClick = jest.fn();
  render(<button onClick={onClick}>Click</button>);

  // ✅ Simple, synchronous
  fireEvent.click(screen.getByRole('button'));

  expect(onClick).toHaveBeenCalledTimes(1);
});
```

**Pros:**
- Synchronous (simpler for basic tests)
- Faster execution
- Good for testing event handlers directly

**Cons:**
- Less realistic (single event, not full sequence)
- Doesn't validate disabled/readonly state
- May miss edge cases

**Recommendation:** Use `userEvent` by default, fall back to `fireEvent` for simple cases.

---

### Server Components vs Client Components

**Client Components ("use client")**

```typescript
// components/bloom/SessionCard.tsx
"use client";

export function SessionCard({ session }) {
  const [status, setStatus] = useState(session.status);
  // ... component logic
}

// ✅ CAN test with Jest + RTL
test('renders session card', () => {
  render(<SessionCard session={mockSession} />);
  expect(screen.getByText(/WS-123/i)).toBeInTheDocument();
});
```

**Server Components (default in Next.js 16 App Router)**

```typescript
// app/workshop/page.tsx (Server Component)
export default async function WorkshopPage() {
  const sessions = await fetchSessions();  // Server-side data fetching
  return <SessionList sessions={sessions} />;
}

// ❌ CANNOT test with Jest + RTL (async components not supported)
test('renders workshop page', () => {
  render(<WorkshopPage />);  // ERROR: Cannot use async component
});

// ✅ Test the Client Component instead
test('SessionList renders sessions', () => {
  const mockSessions = [{ id: 'WS-123', status: 'active' }];
  render(<SessionList sessions={mockSessions} />);
  expect(screen.getByText(/WS-123/i)).toBeInTheDocument();
});

// ✅ Test the API endpoint
test('GET /api/sessions returns sessions', async () => {
  const response = await fetch('/api/sessions');
  expect(response.status).toBe(200);
});

// ✅ Test with Playwright E2E
test('workshop page displays sessions', async ({ page }) => {
  await page.goto('/workshop');
  await expect(page.getByText(/WS-123/i)).toBeVisible();
});
```

**Testing Strategy:**
1. **Server Components** → Test API endpoints + E2E with Playwright
2. **Client Components** → Test with Jest + RTL
3. **Hybrid Pages** → Test Client Components in isolation, Server Components via E2E

---

### Mocking Strategies

**1. Mock fetch (API calls)**

```typescript
beforeEach(() => {
  global.fetch = jest.fn();
});

test('handles API error', async () => {
  (global.fetch as jest.Mock).mockRejectedValueOnce(
    new Error('Network error')
  );

  render(<Component />);
  expect(await screen.findByText(/error/i)).toBeInTheDocument();
});
```

**2. Mock Next.js Router**

```typescript
import { useRouter } from 'next/navigation';

jest.mock('next/navigation', () => ({
  useRouter: jest.fn(),
}));

test('navigates on button click', async () => {
  const mockPush = jest.fn();
  (useRouter as jest.Mock).mockReturnValue({ push: mockPush });

  const user = userEvent.setup();
  render(<NavigationButton />);

  await user.click(screen.getByRole('button'));

  expect(mockPush).toHaveBeenCalledWith('/workshop');
});
```

**3. Mock Zustand Stores**

```typescript
jest.mock('@/stores/sessionStore', () => ({
  useSessionStore: jest.fn(),
}));

test('displays messages from store', () => {
  (useSessionStore as jest.Mock).mockReturnValue({
    messages: [{ id: '1', content: 'Test message' }],
    isLoading: false,
  });

  render(<ChatInterface />);
  expect(screen.getByText(/Test message/i)).toBeInTheDocument();
});
```

---

## 5. Examples

### Example 1: SessionCard Component (Full Test Suite)

```typescript
// __tests__/components/bloom/SessionCard.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { SessionCard } from '@/components/bloom/SessionCard';

describe('SessionCard', () => {
  const mockSession = {
    id: 'WS-20251114-A1B2',
    startedAt: '2025-11-14T10:00:00Z',
    status: 'active' as const,
    responseCount: 5,
  };

  beforeEach(() => {
    global.fetch = jest.fn();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    test('renders session ID in display format', () => {
      render(<SessionCard session={mockSession} />);
      expect(screen.getByText(/A1B2/i)).toBeInTheDocument();
    });

    test('renders response count', () => {
      render(<SessionCard session={mockSession} />);
      expect(screen.getByText(/5 responses/i)).toBeInTheDocument();
    });

    test('renders status badge with correct color', () => {
      render(<SessionCard session={mockSession} />);
      const badge = screen.getByText(/active/i);
      expect(badge).toHaveClass('bg-green-100');
    });

    test('formats relative time correctly', () => {
      const recentSession = {
        ...mockSession,
        startedAt: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
      };

      render(<SessionCard session={recentSession} />);
      expect(screen.getByText(/5m ago/i)).toBeInTheDocument();
    });
  });

  describe('User Interactions', () => {
    test('user can pause active session', async () => {
      const user = userEvent.setup();
      const onStatusChange = jest.fn();

      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => ({ status: 'idle' }),
      });

      render(
        <SessionCard
          session={mockSession}
          onStatusChange={onStatusChange}
        />
      );

      // Click pause button
      const pauseButton = screen.getByRole('button', { name: /pause/i });
      await user.click(pauseButton);

      // Verify API call
      expect(global.fetch).toHaveBeenCalledWith(
        '/api/sessions/WS-20251114-A1B2/pause',
        { method: 'POST' }
      );

      // Verify UI updates
      await waitFor(() => {
        expect(screen.getByText(/idle/i)).toBeInTheDocument();
      });

      // Verify callback
      expect(onStatusChange).toHaveBeenCalledWith('WS-20251114-A1B2', 'idle');
    });

    test('user can resume idle session', async () => {
      const user = userEvent.setup();
      const idleSession = { ...mockSession, status: 'idle' as const };

      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => ({ status: 'active' }),
      });

      render(<SessionCard session={idleSession} />);

      await user.click(screen.getByRole('button', { name: /resume/i }));

      expect(global.fetch).toHaveBeenCalledWith(
        '/api/sessions/WS-20251114-A1B2/resume',
        { method: 'POST' }
      );

      expect(await screen.findByText(/active/i)).toBeInTheDocument();
    });

    test('disables button while loading', async () => {
      const user = userEvent.setup();

      (global.fetch as jest.Mock).mockImplementationOnce(
        () => new Promise((resolve) => setTimeout(resolve, 1000))
      );

      render(<SessionCard session={mockSession} />);

      const pauseButton = screen.getByRole('button', { name: /pause/i });
      await user.click(pauseButton);

      expect(pauseButton).toBeDisabled();
    });
  });

  describe('Error Handling', () => {
    test('displays error message on API failure', async () => {
      const user = userEvent.setup();

      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: false,
        json: async () => ({ message: 'Session not found' }),
      });

      render(<SessionCard session={mockSession} />);

      await user.click(screen.getByRole('button', { name: /pause/i }));

      expect(
        await screen.findByText(/session not found/i)
      ).toBeInTheDocument();
    });

    test('handles network errors gracefully', async () => {
      const user = userEvent.setup();

      (global.fetch as jest.Mock).mockRejectedValueOnce(
        new Error('Network error')
      );

      render(<SessionCard session={mockSession} />);

      await user.click(screen.getByRole('button', { name: /pause/i }));

      expect(
        await screen.findByText(/failed to pause session/i)
      ).toBeInTheDocument();
    });
  });

  describe('Conditional Rendering', () => {
    test('shows pause button for active sessions', () => {
      render(<SessionCard session={{ ...mockSession, status: 'active' }} />);
      expect(screen.getByRole('button', { name: /pause/i })).toBeInTheDocument();
    });

    test('shows resume button for idle sessions', () => {
      render(<SessionCard session={{ ...mockSession, status: 'idle' }} />);
      expect(screen.getByRole('button', { name: /resume/i })).toBeInTheDocument();
    });

    test('shows export button only for completed sessions', () => {
      const { rerender } = render(<SessionCard session={mockSession} />);

      expect(
        screen.queryByRole('button', { name: /export/i })
      ).not.toBeInTheDocument();

      rerender(
        <SessionCard session={{ ...mockSession, status: 'completed' }} />
      );

      expect(
        screen.getByRole('button', { name: /export/i })
      ).toBeInTheDocument();
    });
  });
});
```

---

### Example 2: ChatInterface Component

```typescript
// __tests__/components/bloom/ChatInterface.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ChatInterface } from '@/components/bloom/ChatInterface';
import { useSessionStore } from '@/stores/sessionStore';

jest.mock('@/stores/sessionStore');

describe('ChatInterface', () => {
  const mockStore = {
    messages: [],
    isLoading: false,
    currentPhase: 'greeting',
    progress: 0,
    sessionState: 'ephemeral',
    addMessage: jest.fn(),
    setLoading: jest.fn(),
    setError: jest.fn(),
    commitSession: jest.fn(),
  };

  beforeEach(() => {
    (useSessionStore as unknown as jest.Mock).mockReturnValue(mockStore);
    global.fetch = jest.fn();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('renders chat interface', () => {
    render(<ChatInterface sessionId="WS-123" />);

    expect(screen.getByRole('textbox')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /send/i })).toBeInTheDocument();
  });

  test('user can send message', async () => {
    const user = userEvent.setup();

    (global.fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ message: 'AI response' }),
    });

    render(<ChatInterface sessionId="WS-123" />);

    const input = screen.getByRole('textbox');
    await user.type(input, 'Hello Melissa');

    await user.click(screen.getByRole('button', { name: /send/i }));

    expect(mockStore.addMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        role: 'user',
        content: 'Hello Melissa',
      })
    );
  });

  test('commits ephemeral session on first message', async () => {
    const user = userEvent.setup();

    mockStore.commitSession.mockResolvedValueOnce(undefined);
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ message: 'AI response' }),
    });

    render(<ChatInterface sessionId="WS-123" />);

    await user.type(screen.getByRole('textbox'), 'First message');
    await user.click(screen.getByRole('button', { name: /send/i }));

    expect(mockStore.commitSession).toHaveBeenCalledTimes(1);
  });

  test('disables input while loading', () => {
    (useSessionStore as unknown as jest.Mock).mockReturnValue({
      ...mockStore,
      isLoading: true,
    });

    render(<ChatInterface sessionId="WS-123" />);

    expect(screen.getByRole('textbox')).toBeDisabled();
    expect(screen.getByRole('button', { name: /send/i })).toBeDisabled();
  });

  test('displays messages from store', () => {
    (useSessionStore as unknown as jest.Mock).mockReturnValue({
      ...mockStore,
      messages: [
        {
          id: '1',
          role: 'assistant',
          content: 'Hello! How can I help?',
          timestamp: new Date(),
        },
        {
          id: '2',
          role: 'user',
          content: 'I need help with ROI',
          timestamp: new Date(),
        },
      ],
    });

    render(<ChatInterface sessionId="WS-123" />);

    expect(screen.getByText(/Hello! How can I help?/i)).toBeInTheDocument();
    expect(screen.getByText(/I need help with ROI/i)).toBeInTheDocument();
  });
});
```

---

### Example 3: Testing Custom Hook with React Query

```typescript
// __tests__/hooks/useSessionData.test.tsx
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useSessionData } from '@/hooks/useSessionData';

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
    },
  });

  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}

describe('useSessionData', () => {
  beforeEach(() => {
    global.fetch = jest.fn();
  });

  test('fetches session data successfully', async () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        session: { id: 'WS-123', status: 'active' },
      }),
    });

    const { result } = renderHook(() => useSessionData('WS-123'), {
      wrapper: createWrapper(),
    });

    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data).toEqual({
      session: { id: 'WS-123', status: 'active' },
    });
  });

  test('handles API errors', async () => {
    (global.fetch as jest.Mock).mockRejectedValueOnce(
      new Error('Network error')
    );

    const { result } = renderHook(() => useSessionData('WS-123'), {
      wrapper: createWrapper(),
    });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });

    expect(result.current.error).toEqual(
      expect.objectContaining({ message: 'Network error' })
    );
  });
});
```

---

## 6. Common Pitfalls

### ❌ Pitfall 1: Testing Implementation Details

```typescript
// ❌ BAD: Testing internal state
test('increments counter state', () => {
  const { container } = render(<Counter />);
  const component = container.firstChild as any;

  // DON'T DO THIS - accessing React internals
  expect(component.__reactInternalState.count).toBe(0);
});

// ✅ GOOD: Test observable behavior
test('displays incremented count', async () => {
  const user = userEvent.setup();
  render(<Counter />);

  expect(screen.getByText('Count: 0')).toBeInTheDocument();

  await user.click(screen.getByRole('button', { name: /increment/i }));

  expect(screen.getByText('Count: 1')).toBeInTheDocument();
});
```

---

### ❌ Pitfall 2: Not Waiting for Async Updates

```typescript
// ❌ BAD: Not waiting for async state updates
test('shows error message', () => {
  render(<Form />);
  fireEvent.click(screen.getByRole('button'));

  // May fail flakily - error appears after async validation
  expect(screen.getByText(/error/i)).toBeInTheDocument();
});

// ✅ GOOD: Wait for async updates
test('shows error message', async () => {
  const user = userEvent.setup();
  render(<Form />);

  await user.click(screen.getByRole('button'));

  // Wait for error to appear
  expect(await screen.findByText(/error/i)).toBeInTheDocument();
});
```

---

### ❌ Pitfall 3: Overusing Snapshots

```typescript
// ❌ BAD: Snapshot everything
test('renders correctly', () => {
  const { container } = render(<SessionCard session={mockSession} />);
  expect(container).toMatchSnapshot();  // Brittle, hard to review
});

// ✅ GOOD: Test specific behavior
test('shows pause button for active session', () => {
  render(<SessionCard session={{ ...mockSession, status: 'active' }} />);
  expect(screen.getByRole('button', { name: /pause/i })).toBeInTheDocument();
});

test('shows resume button for idle session', () => {
  render(<SessionCard session={{ ...mockSession, status: 'idle' }} />);
  expect(screen.getByRole('button', { name: /resume/i })).toBeInTheDocument();
});
```

---

### ❌ Pitfall 4: Using Container Queries

```typescript
// ❌ BAD: Non-semantic queries
test('finds button', () => {
  const { container } = render(<Component />);
  const button = container.querySelector('.btn-primary');
  expect(button).toBeTruthy();
});

// ✅ GOOD: Accessible queries
test('finds button', () => {
  render(<Component />);
  expect(screen.getByRole('button', { name: /submit/i })).toBeInTheDocument();
});
```

---

### ❌ Pitfall 5: Not Mocking External Dependencies

```typescript
// ❌ BAD: No mocking, test calls real API
test('fetches sessions', async () => {
  render(<SessionList />);
  // This will make a real network request and fail in CI
});

// ✅ GOOD: Mock fetch
test('fetches sessions', async () => {
  global.fetch = jest.fn().mockResolvedValueOnce({
    ok: true,
    json: async () => ({ sessions: [{ id: 'WS-123' }] }),
  });

  render(<SessionList />);

  expect(await screen.findByText(/WS-123/i)).toBeInTheDocument();
});
```

---

### ❌ Pitfall 6: Testing Third-Party Libraries

```typescript
// ❌ BAD: Testing that React Query works
test('useQuery fetches data', async () => {
  const { result } = renderHook(() => useQuery(['session'], fetchSession));

  await waitFor(() => {
    expect(result.current.isSuccess).toBe(true);  // Testing library internals
  });
});

// ✅ GOOD: Test your component's behavior
test('component displays fetched data', async () => {
  global.fetch = jest.fn().mockResolvedValueOnce({
    ok: true,
    json: async () => ({ session: { id: 'WS-123' } }),
  });

  render(<SessionDetails sessionId="WS-123" />);

  expect(await screen.findByText(/WS-123/i)).toBeInTheDocument();
});
```

---

## 7. AI Pair Programming Notes

### When to Load This Document

**Load when:**
- User asks to "test a React component"
- User mentions "React Testing Library" or "RTL"
- User needs to test user interactions (clicks, forms, typing)
- User wants to test hooks or Zustand stores
- Debugging flaky component tests

**Co-load with:**
- `FRAMEWORK-INTEGRATION-PATTERNS.md` (React section) - Detailed testing patterns
- `04-ASYNC-TESTING.md` - Async utilities deep dive
- `03-MOCKING-SPIES.md` - Mocking strategies

### Critical for Bloom

**High-Priority Components to Test:**
1. `SessionCard` - Session management UI (pause, resume, export)
2. `ChatInterface` - Workshop conversation flow
3. `MessageBubble` - Chat message rendering
4. `InputField` - User input with file upload
5. `QuickPromptButtons` - Context form submission

**Zustand Stores:**
- `sessionStore` - Session state machine (ephemeral → active)
- `brandingStore` - Branding settings
- `monitoringStore` - Health metrics

**Custom Hooks:**
- `useSessionData` - React Query wrapper
- Any hooks that manage complex state or side effects

### Testing Workflow

1. **Start with Component Test**
   ```bash
   npm test SessionCard
   ```

2. **Run in Watch Mode** (TDD)
   ```bash
   npm test -- --watch SessionCard
   ```

3. **Check Coverage**
   ```bash
   npm test -- --coverage --collectCoverageFrom="components/bloom/SessionCard.tsx"
   ```

4. **Debug Failing Test**
   ```typescript
   // Add screen.debug() to see DOM
   render(<Component />);
   screen.debug();  // Prints DOM to console
   ```

### Quick Reference: Query Priority

1. `getByRole` - **ALWAYS TRY FIRST**
2. `getByLabelText` - Forms with labels
3. `getByPlaceholderText` - Input placeholders
4. `getByText` - Text content
5. `getByTestId` - **LAST RESORT**

### Common Bloom Patterns

**Pattern 1: Testing API Integration**
```typescript
global.fetch = jest.fn().mockResolvedValueOnce({
  ok: true,
  json: async () => ({ data: 'value' }),
});
```

**Pattern 2: Testing Zustand Store**
```typescript
jest.mock('@/stores/sessionStore', () => ({
  useSessionStore: jest.fn(() => ({ messages: [], addMessage: jest.fn() })),
}));
```

**Pattern 3: Testing Next.js Navigation**
```typescript
import { useRouter } from 'next/navigation';
jest.mock('next/navigation');

(useRouter as jest.Mock).mockReturnValue({ push: jest.fn() });
```

### AI Assistant Checklist

When helping test a component:

- [ ] Use `userEvent` over `fireEvent` (more realistic)
- [ ] Use `findBy*` for async elements
- [ ] Mock `fetch` and external dependencies
- [ ] Query by role/label, not test IDs
- [ ] Test user behavior, not implementation
- [ ] Verify: API calls, UI updates, callbacks
- [ ] Handle loading and error states
- [ ] Test accessibility (roles, labels, ARIA)

---

**Related Documentation:**
- [Jest Fundamentals](./01-FUNDAMENTALS.md) - Jest basics and setup
- [Async Testing](./04-ASYNC-TESTING.md) - Promises, timers, waitFor
- [Mocking & Spies](./03-MOCKING-SPIES.md) - Mocking strategies
- [Framework Integration](./FRAMEWORK-INTEGRATION-PATTERNS.md) - React patterns
- [Playwright E2E](../playwright/) - End-to-end testing

**Last Updated:** 2025-11-14
