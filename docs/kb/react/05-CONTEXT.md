# React Context API

```yaml
id: react_05_context
topic: React
file_role: Context API for sharing state across component tree
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - State (02-STATE.md)
  - Hooks (03-HOOKS.md)
related_topics:
  - Performance (08-PERFORMANCE.md)
  - Zustand (../zustand/)
embedding_keywords:
  - react context
  - context api
  - createContext
  - useContext
  - context provider
  - context consumer
  - global state
  - prop drilling
last_reviewed: 2025-11-16
```

## Context Overview

**Context** provides a way to pass data through the component tree without manually passing props at every level.

**When to use Context:**
- Theme (dark/light mode)
- User authentication
- Language/locale
- Configuration settings
- Data that many components need

**When NOT to use Context:**
- Local component state
- Frequently changing data (use state management library instead)
- Simple prop passing (1-2 levels deep)

## Creating Context

### Basic Context

```typescript
import { createContext, useContext, useState } from 'react';

// 1. Create context with default value
interface ThemeContextType {
  theme: 'light' | 'dark';
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

// 2. Create provider component
export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };

  const value = { theme, toggleTheme };

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
}

// 3. Create custom hook for consuming context
export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
}

// 4. Usage in components
function App() {
  return (
    <ThemeProvider>
      <Page />
    </ThemeProvider>
  );
}

function Page() {
  const { theme, toggleTheme } = useTheme();

  return (
    <div style={{ background: theme === 'dark' ? '#333' : '#fff' }}>
      <button onClick={toggleTheme}>
        Toggle Theme (Current: {theme})
      </button>
    </div>
  );
}
```

## Authentication Context

```typescript
interface User {
  id: string;
  name: string;
  email: string;
}

interface AuthContextType {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Check for existing session on mount
    const checkAuth = async () => {
      try {
        const response = await fetch('/api/auth/me');
        if (response.ok) {
          const userData = await response.json();
          setUser(userData);
        }
      } catch (error) {
        console.error('Auth check failed:', error);
      } finally {
        setIsLoading(false);
      }
    };

    checkAuth();
  }, []);

  const login = async (email: string, password: string) => {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    if (!response.ok) {
      throw new Error('Login failed');
    }

    const userData = await response.json();
    setUser(userData);
  };

  const logout = () => {
    fetch('/api/auth/logout', { method: 'POST' });
    setUser(null);
  };

  const value = { user, login, logout, isLoading };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}

// Usage
function LoginPage() {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await login(email, password);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input value={email} onChange={(e) => setEmail(e.target.value)} />
      <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
      <button type="submit">Login</button>
    </form>
  );
}

function UserProfile() {
  const { user, logout } = useAuth();

  if (!user) return <div>Not logged in</div>;

  return (
    <div>
      <p>Welcome, {user.name}</p>
      <button onClick={logout}>Logout</button>
    </div>
  );
}
```

## Multiple Contexts

### Combining Providers

```typescript
function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <LanguageProvider>
          <Router>
            <Routes />
          </Router>
        </LanguageProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}

// Or create a combined provider
function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider>
      <AuthProvider>
        <LanguageProvider>
          {children}
        </LanguageProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}

function App() {
  return (
    <AppProviders>
      <Router>
        <Routes />
      </Router>
    </AppProviders>
  );
}
```

## Context with Reducer

```typescript
interface State {
  count: number;
  step: number;
}

type Action =
  | { type: 'INCREMENT' }
  | { type: 'DECREMENT' }
  | { type: 'SET_STEP'; step: number }
  | { type: 'RESET' };

interface CounterContextType {
  state: State;
  dispatch: React.Dispatch<Action>;
}

const CounterContext = createContext<CounterContextType | undefined>(undefined);

function counterReducer(state: State, action: Action): State {
  switch (action.type) {
    case 'INCREMENT':
      return { ...state, count: state.count + state.step };
    case 'DECREMENT':
      return { ...state, count: state.count - state.step };
    case 'SET_STEP':
      return { ...state, step: action.step };
    case 'RESET':
      return { count: 0, step: 1 };
    default:
      return state;
  }
}

export function CounterProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(counterReducer, { count: 0, step: 1 });

  return (
    <CounterContext.Provider value={{ state, dispatch }}>
      {children}
    </CounterContext.Provider>
  );
}

export function useCounter() {
  const context = useContext(CounterContext);
  if (!context) {
    throw new Error('useCounter must be used within CounterProvider');
  }
  return context;
}

// Usage
function CounterDisplay() {
  const { state } = useCounter();
  return <div>Count: {state.count}</div>;
}

function CounterControls() {
  const { dispatch } = useCounter();

  return (
    <div>
      <button onClick={() => dispatch({ type: 'INCREMENT' })}>+</button>
      <button onClick={() => dispatch({ type: 'DECREMENT' })}>-</button>
      <button onClick={() => dispatch({ type: 'RESET' })}>Reset</button>
    </div>
  );
}
```

## Performance Optimization

### Split Contexts to Avoid Re-renders

```typescript
// ❌ BAD - All consumers re-render when any value changes
interface AppContextType {
  user: User | null;
  theme: string;
  language: string;
  settings: Settings;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

// ✅ GOOD - Split into separate contexts
const UserContext = createContext<User | null>(null);
const ThemeContext = createContext<string>('light');
const LanguageContext = createContext<string>('en');

// Only components using specific context re-render
function UserProfile() {
  const user = useContext(UserContext); // Only re-renders on user change
  return <div>{user?.name}</div>;
}
```

### Memoize Context Value

```typescript
export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState('light');

  // ❌ BAD - Creates new object every render
  const value = { theme, setTheme };

  // ✅ GOOD - Stable reference
  const value = useMemo(() => ({ theme, setTheme }), [theme]);

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
}
```

### Separate State and Dispatch

```typescript
const TodoStateContext = createContext<Todo[]>([]);
const TodoDispatchContext = createContext<React.Dispatch<TodoAction> | undefined>(undefined);

export function TodoProvider({ children }: { children: React.ReactNode }) {
  const [todos, dispatch] = useReducer(todoReducer, []);

  return (
    <TodoStateContext.Provider value={todos}>
      <TodoDispatchContext.Provider value={dispatch}>
        {children}
      </TodoDispatchContext.Provider>
    </TodoStateContext.Provider>
  );
}

// Hooks
export function useTodos() {
  return useContext(TodoStateContext);
}

export function useTodoDispatch() {
  const context = useContext(TodoDispatchContext);
  if (!context) {
    throw new Error('useTodoDispatch must be used within TodoProvider');
  }
  return context;
}

// Components only re-render based on what they use
function TodoList() {
  const todos = useTodos(); // Re-renders when todos change
  return <ul>{todos.map(todo => <li key={todo.id}>{todo.text}</li>)}</ul>;
}

function AddTodo() {
  const dispatch = useTodoDispatch(); // Never re-renders from state changes
  const [text, setText] = useState('');

  return (
    <form onSubmit={(e) => {
      e.preventDefault();
      dispatch({ type: 'ADD', text });
      setText('');
    }}>
      <input value={text} onChange={(e) => setText(e.target.value)} />
    </form>
  );
}
```

## Context with LocalStorage

```typescript
interface Settings {
  notifications: boolean;
  darkMode: boolean;
  language: string;
}

const SettingsContext = createContext<{
  settings: Settings;
  updateSettings: (updates: Partial<Settings>) => void;
} | undefined>(undefined);

export function SettingsProvider({ children }: { children: React.ReactNode }) {
  const [settings, setSettings] = useState<Settings>(() => {
    // Load from localStorage on mount
    const stored = localStorage.getItem('settings');
    return stored ? JSON.parse(stored) : {
      notifications: true,
      darkMode: false,
      language: 'en',
    };
  });

  const updateSettings = useCallback((updates: Partial<Settings>) => {
    setSettings(prev => {
      const newSettings = { ...prev, ...updates };
      localStorage.setItem('settings', JSON.stringify(newSettings));
      return newSettings;
    });
  }, []);

  const value = useMemo(() => ({ settings, updateSettings }), [settings, updateSettings]);

  return (
    <SettingsContext.Provider value={value}>
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings() {
  const context = useContext(SettingsContext);
  if (!context) {
    throw new Error('useSettings must be used within SettingsProvider');
  }
  return context;
}
```

## TypeScript Patterns

### Strict Context Types

```typescript
// Pattern 1: Context with undefined (requires null check)
const UserContext = createContext<User | undefined>(undefined);

export function useUser() {
  const context = useContext(UserContext);
  if (!context) {
    throw new Error('useUser must be used within UserProvider');
  }
  return context;
}

// Pattern 2: Context with null as default
const UserContext = createContext<User | null>(null);

export function useUser() {
  const user = useContext(UserContext);
  if (!user) {
    throw new Error('useUser must be used within UserProvider');
  }
  return user;
}

// Pattern 3: Non-null assertion (requires provider always exists)
const UserContext = createContext<User>(null!);

export function useUser() {
  return useContext(UserContext);
}
```

## Context vs Props vs State Management

```typescript
// ✅ Props - Component communication (1-2 levels)
function Parent() {
  const [count, setCount] = useState(0);
  return <Child count={count} onIncrement={() => setCount(c => c + 1)} />;
}

// ✅ Context - Theme, auth, config (doesn't change often)
function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <Routes />
      </AuthProvider>
    </ThemeProvider>
  );
}

// ✅ State Management (Zustand/Redux) - Complex, frequently changing state
import { create } from 'zustand';

const useStore = create((set) => ({
  todos: [],
  addTodo: (todo) => set((state) => ({ todos: [...state.todos, todo] })),
}));
```

## AI Pair Programming Notes

**When using React Context:**

1. **Split contexts**: Separate concerns to avoid unnecessary re-renders
2. **Memoize values**: Use useMemo for context values with objects/arrays
3. **Custom hooks**: Always create useContext wrapper hooks
4. **Error handling**: Throw error if context used outside provider
5. **TypeScript**: Use strict types, avoid `any`
6. **Performance**: Consider state management library for frequent updates
7. **Default values**: Provide meaningful defaults or undefined
8. **Provider placement**: Put providers as high as needed, not higher
9. **Separate state/dispatch**: Split context for better performance
10. **LocalStorage**: Sync with localStorage for persistent settings

**Common context mistakes:**
- Not memoizing context values (causes re-renders)
- Using context for frequently changing state
- Creating one massive context instead of splitting
- Not providing custom hooks for consuming context
- Missing error handling in context hooks
- Placing providers too high in tree
- Not splitting state and dispatch contexts
- Using context when props would be simpler
- Forgetting to wrap app with providers
- Not typing context properly in TypeScript

## Next Steps

1. **06-PATTERNS.md** - Component patterns and composition
2. **08-PERFORMANCE.md** - Optimizing context and re-renders
3. **Zustand KB** - Alternative state management

## Additional Resources

- React Context: https://react.dev/reference/react/createContext
- useContext Hook: https://react.dev/reference/react/useContext
- Context Patterns: https://react.dev/learn/passing-data-deeply-with-context
- Context Performance: https://react.dev/reference/react/memo#minimizing-props-changes
