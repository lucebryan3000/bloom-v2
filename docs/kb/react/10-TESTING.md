# React Testing

```yaml
id: react_10_testing
topic: React
file_role: Testing React components with React Testing Library, Jest
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - State (02-STATE.md)
  - Hooks (03-HOOKS.md)
  - Events (04-EVENTS.md)
related_topics:
  - Patterns (06-PATTERNS.md)
  - Testing (../testing/)
  - Jest (../jest-app-testing/)
embedding_keywords:
  - react testing
  - react testing library
  - jest react
  - testing components
  - testing hooks
  - testing forms
  - user events
  - mocking
last_reviewed: 2025-11-16
```

## Testing Overview

**Testing Tools:**
1. **Jest** - Test runner and assertion library
2. **React Testing Library** - Component testing utilities
3. **@testing-library/user-event** - Simulate user interactions
4. **@testing-library/react-hooks** - Test custom hooks
5. **MSW** - Mock Service Worker for API mocking

## Basic Component Testing

### Simple Component

```typescript
// Button.tsx
export function Button({ onClick, children }: Props) {
  return <button onClick={onClick}>{children}</button>;
}

// Button.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from './Button';

describe('Button', () => {
  it('renders button text', () => {
    render(<Button onClick={() => {}}>Click me</Button>);

    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('calls onClick when clicked', async () => {
    const handleClick = jest.fn();
    const user = userEvent.setup();

    render(<Button onClick={handleClick}>Click me</Button>);

    await user.click(screen.getByRole('button'));

    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

### Component with State

```typescript
// Counter.tsx
export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
      <button onClick={() => setCount(c => c - 1)}>Decrement</button>
    </div>
  );
}

// Counter.test.tsx
describe('Counter', () => {
  it('increments count', async () => {
    const user = userEvent.setup();
    render(<Counter />);

    expect(screen.getByText('Count: 0')).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: 'Increment' }));

    expect(screen.getByText('Count: 1')).toBeInTheDocument();
  });

  it('decrements count', async () => {
    const user = userEvent.setup();
    render(<Counter />);

    await user.click(screen.getByRole('button', { name: 'Decrement' }));

    expect(screen.getByText('Count: -1')).toBeInTheDocument();
  });
});
```

## Testing Forms

### Form Submission

```typescript
// ContactForm.tsx
export function ContactForm({ onSubmit }: Props) {
  const [formData, setFormData] = useState({ name: '', email: '' });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        name="name"
        value={formData.name}
        onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
        placeholder="Name"
      />
      <input
        name="email"
        value={formData.email}
        onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
        placeholder="Email"
      />
      <button type="submit">Submit</button>
    </form>
  );
}

// ContactForm.test.tsx
describe('ContactForm', () => {
  it('submits form with user input', async () => {
    const handleSubmit = jest.fn();
    const user = userEvent.setup();

    render(<ContactForm onSubmit={handleSubmit} />);

    await user.type(screen.getByPlaceholderText('Name'), 'Alice');
    await user.type(screen.getByPlaceholderText('Email'), 'alice@example.com');
    await user.click(screen.getByRole('button', { name: 'Submit' }));

    expect(handleSubmit).toHaveBeenCalledWith({
      name: 'Alice',
      email: 'alice@example.com',
    });
  });
});
```

### Form Validation

```typescript
// ValidatedForm.tsx
export function ValidatedForm({ onSubmit }: Props) {
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!email.includes('@')) {
      setError('Invalid email');
      return;
    }

    setError('');
    onSubmit(email);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input value={email} onChange={(e) => setEmail(e.target.value)} />
      {error && <span role="alert">{error}</span>}
      <button type="submit">Submit</button>
    </form>
  );
}

// ValidatedForm.test.tsx
describe('ValidatedForm', () => {
  it('shows error for invalid email', async () => {
    const user = userEvent.setup();
    render(<ValidatedForm onSubmit={jest.fn()} />);

    await user.type(screen.getByRole('textbox'), 'invalid-email');
    await user.click(screen.getByRole('button', { name: 'Submit' }));

    expect(screen.getByRole('alert')).toHaveTextContent('Invalid email');
  });

  it('submits with valid email', async () => {
    const handleSubmit = jest.fn();
    const user = userEvent.setup();

    render(<ValidatedForm onSubmit={handleSubmit} />);

    await user.type(screen.getByRole('textbox'), 'alice@example.com');
    await user.click(screen.getByRole('button', { name: 'Submit' }));

    expect(screen.queryByRole('alert')).not.toBeInTheDocument();
    expect(handleSubmit).toHaveBeenCalledWith('alice@example.com');
  });
});
```

## Testing Async Components

### Data Fetching

```typescript
// UserProfile.tsx
export function UserProfile({ userId }: Props) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/users/${userId}`)
      .then(res => res.json())
      .then(data => {
        setUser(data);
        setLoading(false);
      });
  }, [userId]);

  if (loading) return <div>Loading...</div>;
  if (!user) return <div>User not found</div>;

  return <div>{user.name}</div>;
}

// UserProfile.test.tsx
import { waitFor } from '@testing-library/react';

describe('UserProfile', () => {
  beforeEach(() => {
    global.fetch = jest.fn();
  });

  it('shows loading state', () => {
    (global.fetch as jest.Mock).mockImplementation(
      () => new Promise(() => {}) // Never resolves
    );

    render(<UserProfile userId={1} />);

    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  it('shows user data after loading', async () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      json: async () => ({ id: 1, name: 'Alice' }),
    });

    render(<UserProfile userId={1} />);

    await waitFor(() => {
      expect(screen.getByText('Alice')).toBeInTheDocument();
    });
  });

  it('shows not found message', async () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      json: async () => null,
    });

    render(<UserProfile userId={999} />);

    await waitFor(() => {
      expect(screen.getByText('User not found')).toBeInTheDocument();
    });
  });
});
```

## Testing Custom Hooks

### Hook Testing

```typescript
// useCounter.ts
export function useCounter(initialValue = 0) {
  const [count, setCount] = useState(initialValue);

  const increment = () => setCount(c => c + 1);
  const decrement = () => setCount(c => c - 1);
  const reset = () => setCount(initialValue);

  return { count, increment, decrement, reset };
}

// useCounter.test.ts
import { renderHook, act } from '@testing-library/react';

describe('useCounter', () => {
  it('initializes with default value', () => {
    const { result } = renderHook(() => useCounter());

    expect(result.current.count).toBe(0);
  });

  it('initializes with custom value', () => {
    const { result } = renderHook(() => useCounter(10));

    expect(result.current.count).toBe(10);
  });

  it('increments count', () => {
    const { result } = renderHook(() => useCounter());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('resets to initial value', () => {
    const { result } = renderHook(() => useCounter(5));

    act(() => {
      result.current.increment();
      result.current.increment();
    });

    expect(result.current.count).toBe(7);

    act(() => {
      result.current.reset();
    });

    expect(result.current.count).toBe(5);
  });
});
```

## Testing Context

### Context Provider

```typescript
// ThemeContext.tsx
const ThemeContext = createContext<{ theme: string; toggleTheme: () => void } | undefined>(undefined);

export function ThemeProvider({ children }: Props) {
  const [theme, setTheme] = useState('light');

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) throw new Error('useTheme must be used within ThemeProvider');
  return context;
}

// ThemeButton.tsx
export function ThemeButton() {
  const { theme, toggleTheme } = useTheme();

  return (
    <button onClick={toggleTheme}>
      Current theme: {theme}
    </button>
  );
}

// ThemeButton.test.tsx
describe('ThemeButton', () => {
  const renderWithProvider = (ui: React.ReactElement) => {
    return render(
      <ThemeProvider>
        {ui}
      </ThemeProvider>
    );
  };

  it('shows current theme', () => {
    renderWithProvider(<ThemeButton />);

    expect(screen.getByText(/Current theme: light/)).toBeInTheDocument();
  });

  it('toggles theme on click', async () => {
    const user = userEvent.setup();
    renderWithProvider(<ThemeButton />);

    expect(screen.getByText(/Current theme: light/)).toBeInTheDocument();

    await user.click(screen.getByRole('button'));

    expect(screen.getByText(/Current theme: dark/)).toBeInTheDocument();
  });
});
```

## Mocking

### Mocking Modules

```typescript
// api.ts
export async function fetchUser(id: number) {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

// UserComponent.test.tsx
jest.mock('./api');
import { fetchUser } from './api';

const mockFetchUser = fetchUser as jest.MockedFunction<typeof fetchUser>;

describe('UserComponent', () => {
  it('displays user data', async () => {
    mockFetchUser.mockResolvedValueOnce({
      id: 1,
      name: 'Alice',
    });

    render(<UserComponent userId={1} />);

    await waitFor(() => {
      expect(screen.getByText('Alice')).toBeInTheDocument();
    });
  });
});
```

### Mocking Child Components

```typescript
// Dashboard.test.tsx
jest.mock('./Chart', () => ({
  Chart: () => <div>Mocked Chart</div>,
}));

describe('Dashboard', () => {
  it('renders with mocked chart', () => {
    render(<Dashboard />);

    expect(screen.getByText('Mocked Chart')).toBeInTheDocument();
  });
});
```

## Testing User Interactions

### Keyboard Events

```typescript
describe('SearchInput', () => {
  it('submits on Enter key', async () => {
    const handleSearch = jest.fn();
    const user = userEvent.setup();

    render(<SearchInput onSearch={handleSearch} />);

    await user.type(screen.getByRole('textbox'), 'query');
    await user.keyboard('{Enter}');

    expect(handleSearch).toHaveBeenCalledWith('query');
  });
});
```

### Mouse Events

```typescript
describe('Tooltip', () => {
  it('shows tooltip on hover', async () => {
    const user = userEvent.setup();
    render(<Tooltip text="Hover text">Hover me</Tooltip>);

    expect(screen.queryByText('Hover text')).not.toBeInTheDocument();

    await user.hover(screen.getByText('Hover me'));

    expect(screen.getByText('Hover text')).toBeInTheDocument();
  });
});
```

## Snapshot Testing

```typescript
describe('UserCard', () => {
  it('matches snapshot', () => {
    const { container } = render(
      <UserCard user={{ id: 1, name: 'Alice', email: 'alice@example.com' }} />
    );

    expect(container).toMatchSnapshot();
  });
});
```

## AI Pair Programming Notes

**When testing React:**

1. **Query by role/label**: Prefer `getByRole`, `getByLabelText` over test IDs
2. **User events**: Use `@testing-library/user-event` for realistic interactions
3. **Async testing**: Use `waitFor`, `findBy` queries for async updates
4. **Test behavior**: Test what users see, not implementation
5. **Mock sparingly**: Only mock external dependencies (APIs, modules)
6. **Setup userEvent**: Call `userEvent.setup()` before each test
7. **Context wrappers**: Create render helpers for context providers
8. **Custom hooks**: Use `renderHook` from React Testing Library
9. **Avoid implementation details**: Don't test state directly
10. **Accessibility**: Use semantic queries (role, label, text)

**Common testing mistakes:**
- Using `getByTestId` instead of semantic queries
- Testing implementation details (state, props)
- Not waiting for async updates (missing `waitFor`)
- Mocking too much (makes tests fragile)
- Not cleaning up after tests
- Using wrong query variants (`getBy` vs `findBy` vs `queryBy`)
- Not using `userEvent.setup()` in React 18+
- Testing library internals instead of user behavior
- Missing act() warnings
- Not testing edge cases and error states

## Next Steps

1. **11-BEST-PRACTICES.md** - Testing best practices
2. **Jest KB** - Jest configuration and patterns
3. **Playwright KB** - E2E testing

## Additional Resources

- React Testing Library: https://testing-library.com/react
- Jest: https://jestjs.io/
- Testing Library Queries: https://testing-library.com/docs/queries/about
- User Event: https://testing-library.com/docs/user-event/intro
- Testing Hooks: https://react-hooks-testing-library.com/
