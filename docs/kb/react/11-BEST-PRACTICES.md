# React Best Practices

```yaml
id: react_11_best_practices
topic: React
file_role: Best practices, patterns, anti-patterns, code quality
profile: advanced
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - All previous files (02-10)
related_topics:
  - TypeScript (../typescript/)
  - Performance (08-PERFORMANCE.md)
  - Testing (10-TESTING.md)
embedding_keywords:
  - react best practices
  - react patterns
  - react anti-patterns
  - code quality
  - clean code
  - react guidelines
last_reviewed: 2025-11-16
```

## Best Practices Overview

**Core Principles:**
1. **Component composition** over complex components
2. **Functional updates** for state
3. **TypeScript** for type safety
4. **Accessibility** in all components
5. **Performance** optimization when needed

## Component Organization

### File Structure

```typescript
// ✅ GOOD - One component per file
// components/UserCard/UserCard.tsx
export function UserCard({ user }: Props) {
  return <div>{user.name}</div>;
}

// components/UserCard/index.ts
export { UserCard } from './UserCard';

// ❌ BAD - Multiple unrelated components in one file
// components/Users.tsx
export function UserCard() {}
export function UserList() {}
export function UserProfile() {}
```

### Component Size

```typescript
// ✅ GOOD - Small, focused components
function UserCard({ user }: Props) {
  return (
    <Card>
      <CardHeader>{user.name}</CardHeader>
      <CardBody>{user.email}</CardBody>
    </Card>
  );
}

// ❌ BAD - God component doing too much
function Dashboard() {
  // 500 lines of code
  // Multiple responsibilities
  // Hard to test
  // Hard to maintain
}
```

## Props and State

### Prop Naming

```typescript
// ✅ GOOD - Clear, descriptive names
interface ButtonProps {
  onClick: () => void;
  disabled?: boolean;
  variant?: 'primary' | 'secondary';
  children: React.ReactNode;
}

// ❌ BAD - Unclear, abbreviated names
interface BtnProps {
  fn: () => void;
  dis?: boolean;
  v?: string;
  c: React.ReactNode;
}
```

### State Initialization

```typescript
// ✅ GOOD - Lazy initialization for expensive operations
const [data, setData] = useState(() => {
  return computeExpensiveValue();
});

// ❌ BAD - Runs on every render
const [data, setData] = useState(computeExpensiveValue());
```

### State Updates

```typescript
// ✅ GOOD - Functional updates
setCount(prev => prev + 1);
setTodos(prev => [...prev, newTodo]);

// ❌ BAD - Direct state reference
setCount(count + 1); // May use stale value
setTodos([...todos, newTodo]); // Breaks in closures
```

## Hooks Best Practices

### Effect Dependencies

```typescript
// ✅ GOOD - All dependencies included
useEffect(() => {
  fetchUser(userId);
}, [userId]);

// ❌ BAD - Missing dependencies
useEffect(() => {
  fetchUser(userId);
}, []); // ESLint warning!

// ✅ GOOD - Extracted function with useCallback
const fetchUser = useCallback((id: number) => {
  // Fetch logic
}, []);

useEffect(() => {
  fetchUser(userId);
}, [userId, fetchUser]);
```

### Custom Hooks

```typescript
// ✅ GOOD - Reusable, focused custom hooks
function useLocalStorage<T>(key: string, initialValue: T) {
  const [value, setValue] = useState<T>(() => {
    const stored = localStorage.getItem(key);
    return stored ? JSON.parse(stored) : initialValue;
  });

  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);

  return [value, setValue] as const;
}

// ❌ BAD - Too generic, tries to do everything
function useData() {
  // 200 lines of mixed logic
  // Multiple responsibilities
  // Hard to reuse
}
```

## TypeScript

### Component Props

```typescript
// ✅ GOOD - Properly typed props
interface UserCardProps {
  user: User;
  onEdit?: (user: User) => void;
  className?: string;
}

function UserCard({ user, onEdit, className }: UserCardProps) {
  return <div className={className}>{user.name}</div>;
}

// ❌ BAD - Using any or missing types
function UserCard({ user, onEdit }: any) {
  return <div>{user.name}</div>;
}
```

### Event Handlers

```typescript
// ✅ GOOD - Properly typed events
function handleClick(e: React.MouseEvent<HTMLButtonElement>) {
  console.log(e.currentTarget.value);
}

function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
  console.log(e.target.value);
}

// ❌ BAD - Using any
function handleClick(e: any) {
  console.log(e.target.value);
}
```

## Performance

### Memoization

```typescript
// ✅ GOOD - Memoize expensive calculations
const filteredUsers = useMemo(() => {
  return users.filter(u => u.active);
}, [users]);

// ❌ BAD - Unnecessary memoization
const userName = useMemo(() => user.name, [user]); // Too simple!

// ✅ GOOD - Memoize callbacks passed to children
const handleDelete = useCallback((id: string) => {
  setUsers(prev => prev.filter(u => u.id !== id));
}, []);

// ❌ BAD - New function every render
const handleDelete = (id: string) => {
  setUsers(prev => prev.filter(u => u.id !== id));
};
```

### Component Memoization

```typescript
// ✅ GOOD - Memo for expensive components
const UserList = memo(({ users }: Props) => {
  return (
    <ul>
      {users.map(user => <li key={user.id}>{user.name}</li>)}
    </ul>
  );
});

// ❌ BAD - Memo on simple components
const Title = memo(({ text }: Props) => <h1>{text}</h1>); // Overkill!
```

## Accessibility

### Semantic HTML

```typescript
// ✅ GOOD - Semantic elements
function Navigation() {
  return (
    <nav>
      <ul>
        <li><a href="/">Home</a></li>
        <li><a href="/about">About</a></li>
      </ul>
    </nav>
  );
}

// ❌ BAD - Generic div soup
function Navigation() {
  return (
    <div>
      <div onClick={() => navigate('/')}>Home</div>
      <div onClick={() => navigate('/about')}>About</div>
    </div>
  );
}
```

### ARIA Labels

```typescript
// ✅ GOOD - Accessible form
function LoginForm() {
  return (
    <form>
      <label htmlFor="email">Email</label>
      <input id="email" type="email" aria-required="true" />

      <label htmlFor="password">Password</label>
      <input id="password" type="password" aria-required="true" />

      <button type="submit">Log In</button>
    </form>
  );
}

// ❌ BAD - No labels or ARIA
function LoginForm() {
  return (
    <form>
      <input type="email" placeholder="Email" />
      <input type="password" placeholder="Password" />
      <div onClick={handleLogin}>Log In</div>
    </form>
  );
}
```

## Error Handling

### Error Boundaries

```typescript
// ✅ GOOD - Error boundary for sections
function App() {
  return (
    <div>
      <ErrorBoundary fallback={<ErrorFallback />}>
        <Dashboard />
      </ErrorBoundary>

      <ErrorBoundary fallback={<ErrorFallback />}>
        <Sidebar />
      </ErrorBoundary>
    </div>
  );
}

// ErrorBoundary component (class component required)
class ErrorBoundary extends React.Component<Props, State> {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('Error caught:', error, info);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }
    return this.props.children;
  }
}
```

### Async Error Handling

```typescript
// ✅ GOOD - Handle errors in async operations
async function fetchData() {
  try {
    setLoading(true);
    setError(null);

    const response = await fetch('/api/data');
    if (!response.ok) {
      throw new Error('Failed to fetch');
    }

    const data = await response.json();
    setData(data);
  } catch (error) {
    setError(error instanceof Error ? error.message : 'Unknown error');
  } finally {
    setLoading(false);
  }
}

// ❌ BAD - No error handling
async function fetchData() {
  const response = await fetch('/api/data');
  const data = await response.json();
  setData(data); // What if this fails?
}
```

## Code Quality

### Avoid Magic Numbers

```typescript
// ✅ GOOD - Named constants
const MAX_USERNAME_LENGTH = 20;
const MIN_PASSWORD_LENGTH = 8;
const DEBOUNCE_DELAY_MS = 500;

function validateForm(username: string, password: string) {
  if (username.length > MAX_USERNAME_LENGTH) {
    return 'Username too long';
  }
  if (password.length < MIN_PASSWORD_LENGTH) {
    return 'Password too short';
  }
}

// ❌ BAD - Magic numbers
function validateForm(username: string, password: string) {
  if (username.length > 20) {
    return 'Username too long';
  }
  if (password.length < 8) {
    return 'Password too short';
  }
}
```

### Extract Complex Logic

```typescript
// ✅ GOOD - Extracted functions
function isValidEmail(email: string): boolean {
  return /\S+@\S+\.\S+/.test(email);
}

function isStrongPassword(password: string): boolean {
  return password.length >= 8 && /[A-Z]/.test(password) && /[0-9]/.test(password);
}

function validateForm(email: string, password: string) {
  if (!isValidEmail(email)) {
    return 'Invalid email';
  }
  if (!isStrongPassword(password)) {
    return 'Weak password';
  }
}

// ❌ BAD - Inline complex logic
function validateForm(email: string, password: string) {
  if (!/\S+@\S+\.\S+/.test(email)) {
    return 'Invalid email';
  }
  if (password.length < 8 || !/[A-Z]/.test(password) || !/[0-9]/.test(password)) {
    return 'Weak password';
  }
}
```

## Common Anti-Patterns

### 1. Prop Drilling

```typescript
// ❌ BAD - Prop drilling through many levels
function App() {
  const [user, setUser] = useState(null);
  return <Dashboard user={user} setUser={setUser} />;
}

function Dashboard({ user, setUser }: Props) {
  return <Sidebar user={user} setUser={setUser} />;
}

function Sidebar({ user, setUser }: Props) {
  return <UserProfile user={user} setUser={setUser} />;
}

// ✅ GOOD - Use context
const UserContext = createContext(null);

function App() {
  const [user, setUser] = useState(null);
  return (
    <UserContext.Provider value={{ user, setUser }}>
      <Dashboard />
    </UserContext.Provider>
  );
}

function UserProfile() {
  const { user, setUser } = useContext(UserContext);
  return <div>{user?.name}</div>;
}
```

### 2. Mutating State

```typescript
// ❌ BAD - Mutating state directly
const handleAdd = () => {
  users.push(newUser); // Direct mutation!
  setUsers(users);
};

// ✅ GOOD - Create new array
const handleAdd = () => {
  setUsers([...users, newUser]);
};
```

### 3. Inline Object/Array Creation

```typescript
// ❌ BAD - Creates new object every render
<UserList config={{ theme: 'dark', size: 'large' }} />

// ✅ GOOD - Stable reference
const config = useMemo(() => ({ theme: 'dark', size: 'large' }), []);
<UserList config={config} />
```

## AI Pair Programming Notes

**When writing React code:**

1. **Component size**: Keep components small and focused
2. **TypeScript**: Always use TypeScript for type safety
3. **Functional updates**: Use for state that depends on previous value
4. **Custom hooks**: Extract reusable logic
5. **Accessibility**: Use semantic HTML and ARIA labels
6. **Error handling**: Handle errors in async operations
7. **Memoization**: Use when needed, not by default
8. **Testing**: Write tests for critical functionality
9. **Code quality**: Extract complex logic, avoid magic numbers
10. **Context**: Use for global state, avoid prop drilling

**Avoid these anti-patterns:**
- God components (doing too much)
- Prop drilling (passing props through many levels)
- Mutating state directly
- Missing dependencies in useEffect
- Using index as key in dynamic lists
- Inline object/array creation passed as props
- Not handling loading/error states
- Over-using memo/useMemo/useCallback
- Ignoring accessibility
- Not using TypeScript

## Next Steps

1. **Practice** - Build projects applying these patterns
2. **Review** - Code review for best practices
3. **Refactor** - Improve existing code
4. **Learn** - Stay updated with React ecosystem

## Additional Resources

- React Docs: https://react.dev/learn
- TypeScript React Cheatsheet: https://react-typescript-cheatsheet.netlify.app/
- React Patterns: https://reactpatterns.com/
- Accessibility: https://www.w3.org/WAI/ARIA/apg/
- ESLint React Plugin: https://github.com/jsx-eslint/eslint-plugin-react
