# React Component Patterns

```yaml
id: react_06_patterns
topic: React
file_role: Component patterns, composition, HOCs, render props, compound components
profile: advanced
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - State (02-STATE.md)
  - Hooks (03-HOOKS.md)
  - Context (05-CONTEXT.md)
related_topics:
  - Performance (08-PERFORMANCE.md)
  - Testing (10-TESTING.md)
embedding_keywords:
  - react patterns
  - component composition
  - render props
  - higher order components
  - compound components
  - controlled components
  - container presentational
  - provider pattern
last_reviewed: 2025-11-16
```

## Component Patterns Overview

**Common React Patterns:**
1. **Composition** - Building components from smaller pieces
2. **Controlled Components** - Parent controls component state
3. **Compound Components** - Components that work together
4. **Render Props** - Share logic via function props
5. **Higher-Order Components (HOCs)** - Wrap components with logic
6. **Container/Presentational** - Separate logic from UI
7. **Provider Pattern** - Share data via context
8. **Custom Hooks** - Reusable stateful logic

## Composition

### Component Composition

```typescript
// Build complex UIs from simple pieces
function Card({ children }: { children: React.ReactNode }) {
  return <div className="card">{children}</div>;
}

function CardHeader({ children }: { children: React.ReactNode }) {
  return <div className="card-header">{children}</div>;
}

function CardBody({ children }: { children: React.ReactNode }) {
  return <div className="card-body">{children}</div>;
}

// Usage - compose to build complex UI
function UserCard({ user }: { user: User }) {
  return (
    <Card>
      <CardHeader>
        <h2>{user.name}</h2>
      </CardHeader>
      <CardBody>
        <p>{user.email}</p>
        <p>{user.bio}</p>
      </CardBody>
    </Card>
  );
}
```

### Children as Props

```typescript
function Container({ children }: { children: React.ReactNode }) {
  return (
    <div className="container">
      <div className="content">{children}</div>
    </div>
  );
}

// Multiple children slots
interface LayoutProps {
  sidebar: React.ReactNode;
  content: React.ReactNode;
}

function Layout({ sidebar, content }: LayoutProps) {
  return (
    <div className="layout">
      <aside>{sidebar}</aside>
      <main>{content}</main>
    </div>
  );
}

// Usage
<Layout
  sidebar={<Navigation />}
  content={<Dashboard />}
/>
```

## Controlled Components

### Fully Controlled

```typescript
interface InputProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

function ControlledInput({ value, onChange, placeholder }: InputProps) {
  return (
    <input
      type="text"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
    />
  );
}

// Parent controls the state
function Form() {
  const [name, setName] = useState('');

  return (
    <ControlledInput
      value={name}
      onChange={setName}
      placeholder="Enter name"
    />
  );
}
```

### Controlled with Default

```typescript
interface ToggleProps {
  value?: boolean;
  onChange?: (value: boolean) => void;
  defaultValue?: boolean;
}

function Toggle({ value, onChange, defaultValue = false }: ToggleProps) {
  // Internal state as fallback
  const [internalValue, setInternalValue] = useState(defaultValue);

  // Use controlled value if provided, otherwise use internal
  const isControlled = value !== undefined;
  const currentValue = isControlled ? value : internalValue;

  const handleToggle = () => {
    const newValue = !currentValue;
    if (onChange) {
      onChange(newValue);
    }
    if (!isControlled) {
      setInternalValue(newValue);
    }
  };

  return (
    <button onClick={handleToggle}>
      {currentValue ? 'ON' : 'OFF'}
    </button>
  );
}

// Can be used controlled or uncontrolled
<Toggle value={isOn} onChange={setIsOn} /> // Controlled
<Toggle defaultValue={false} /> // Uncontrolled
```

## Compound Components

### Tab Component Example

```typescript
interface TabsContextType {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

const TabsContext = createContext<TabsContextType | undefined>(undefined);

function Tabs({ children, defaultTab }: { children: React.ReactNode; defaultTab: string }) {
  const [activeTab, setActiveTab] = useState(defaultTab);

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

function TabList({ children }: { children: React.ReactNode }) {
  return <div className="tab-list">{children}</div>;
}

function Tab({ value, children }: { value: string; children: React.ReactNode }) {
  const context = useContext(TabsContext);
  if (!context) throw new Error('Tab must be used within Tabs');

  const { activeTab, setActiveTab } = context;
  const isActive = activeTab === value;

  return (
    <button
      className={`tab ${isActive ? 'active' : ''}`}
      onClick={() => setActiveTab(value)}
    >
      {children}
    </button>
  );
}

function TabPanel({ value, children }: { value: string; children: React.ReactNode }) {
  const context = useContext(TabsContext);
  if (!context) throw new Error('TabPanel must be used within Tabs');

  const { activeTab } = context;
  if (activeTab !== value) return null;

  return <div className="tab-panel">{children}</div>;
}

// Namespace pattern
Tabs.List = TabList;
Tabs.Tab = Tab;
Tabs.Panel = TabPanel;

// Usage
function App() {
  return (
    <Tabs defaultTab="home">
      <Tabs.List>
        <Tabs.Tab value="home">Home</Tabs.Tab>
        <Tabs.Tab value="profile">Profile</Tabs.Tab>
        <Tabs.Tab value="settings">Settings</Tabs.Tab>
      </Tabs.List>

      <Tabs.Panel value="home">
        <h1>Home Content</h1>
      </Tabs.Panel>
      <Tabs.Panel value="profile">
        <h1>Profile Content</h1>
      </Tabs.Panel>
      <Tabs.Panel value="settings">
        <h1>Settings Content</h1>
      </Tabs.Panel>
    </Tabs>
  );
}
```

## Render Props Pattern

### Basic Render Props

```typescript
interface MouseTrackerProps {
  render: (position: { x: number; y: number }) => React.ReactNode;
}

function MouseTracker({ render }: MouseTrackerProps) {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  const handleMouseMove = (e: React.MouseEvent) => {
    setPosition({ x: e.clientX, y: e.clientY });
  };

  return (
    <div onMouseMove={handleMouseMove} style={{ height: '100vh' }}>
      {render(position)}
    </div>
  );
}

// Usage
<MouseTracker
  render={({ x, y }) => (
    <div>
      Mouse at: {x}, {y}
    </div>
  )}
/>
```

### Children as Function

```typescript
interface DataFetcherProps<T> {
  url: string;
  children: (data: { data: T | null; loading: boolean; error: Error | null }) => React.ReactNode;
}

function DataFetcher<T>({ url, children }: DataFetcherProps<T>) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetch(url)
      .then(res => res.json())
      .then(data => {
        setData(data);
        setLoading(false);
      })
      .catch(err => {
        setError(err);
        setLoading(false);
      });
  }, [url]);

  return <>{children({ data, loading, error })}</>;
}

// Usage
<DataFetcher<User> url="/api/user">
  {({ data, loading, error }) => {
    if (loading) return <div>Loading...</div>;
    if (error) return <div>Error: {error.message}</div>;
    if (!data) return <div>No data</div>;
    return <div>{data.name}</div>;
  }}
</DataFetcher>
```

## Higher-Order Components (HOCs)

### Basic HOC

```typescript
// HOC that adds loading state
function withLoading<P extends object>(
  Component: React.ComponentType<P>
) {
  return function WithLoadingComponent(props: P & { isLoading: boolean }) {
    const { isLoading, ...rest } = props;

    if (isLoading) {
      return <div>Loading...</div>;
    }

    return <Component {...(rest as P)} />;
  };
}

// Usage
function UserList({ users }: { users: User[] }) {
  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}

const UserListWithLoading = withLoading(UserList);

// In parent component
<UserListWithLoading users={users} isLoading={loading} />
```

### HOC with Props Manipulation

```typescript
// HOC that injects props
interface InjectedProps {
  currentUser: User | null;
}

function withAuth<P extends InjectedProps>(
  Component: React.ComponentType<P>
) {
  return function WithAuthComponent(props: Omit<P, keyof InjectedProps>) {
    const { user } = useAuth(); // Custom hook

    if (!user) {
      return <div>Please log in</div>;
    }

    return <Component {...(props as P)} currentUser={user} />;
  };
}

// Usage
interface ProfileProps extends InjectedProps {
  showEmail: boolean;
}

function Profile({ currentUser, showEmail }: ProfileProps) {
  return (
    <div>
      <h1>{currentUser.name}</h1>
      {showEmail && <p>{currentUser.email}</p>}
    </div>
  );
}

const ProtectedProfile = withAuth(Profile);

// Use without passing currentUser (injected by HOC)
<ProtectedProfile showEmail={true} />
```

## Container/Presentational Pattern

### Separation of Concerns

```typescript
// Presentational - UI only, no logic
interface UserListUIProps {
  users: User[];
  onDelete: (id: string) => void;
  loading: boolean;
}

function UserListUI({ users, onDelete, loading }: UserListUIProps) {
  if (loading) return <div>Loading...</div>;

  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>
          {user.name}
          <button onClick={() => onDelete(user.id)}>Delete</button>
        </li>
      ))}
    </ul>
  );
}

// Container - logic only
function UserListContainer() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUsers().then(data => {
      setUsers(data);
      setLoading(false);
    });
  }, []);

  const handleDelete = async (id: string) => {
    await deleteUser(id);
    setUsers(prev => prev.filter(u => u.id !== id));
  };

  return <UserListUI users={users} onDelete={handleDelete} loading={loading} />;
}
```

## Custom Hook Pattern

### Extract Reusable Logic

```typescript
// Custom hook for form handling
function useForm<T>(initialValues: T) {
  const [values, setValues] = useState<T>(initialValues);
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({});

  const handleChange = (field: keyof T) => (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    setValues(prev => ({
      ...prev,
      [field]: e.target.value,
    }));
    // Clear error when user types
    setErrors(prev => ({
      ...prev,
      [field]: undefined,
    }));
  };

  const validate = (validationRules: Partial<Record<keyof T, (value: any) => string | undefined>>) => {
    const newErrors: Partial<Record<keyof T, string>> = {};
    let isValid = true;

    Object.keys(validationRules).forEach((key) => {
      const field = key as keyof T;
      const rule = validationRules[field];
      if (rule) {
        const error = rule(values[field]);
        if (error) {
          newErrors[field] = error;
          isValid = false;
        }
      }
    });

    setErrors(newErrors);
    return isValid;
  };

  const reset = () => {
    setValues(initialValues);
    setErrors({});
  };

  return { values, errors, handleChange, validate, reset };
}

// Usage
function SignupForm() {
  const { values, errors, handleChange, validate, reset } = useForm({
    username: '',
    email: '',
    password: '',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const isValid = validate({
      username: (val) => !val ? 'Username required' : undefined,
      email: (val) => !val.includes('@') ? 'Invalid email' : undefined,
      password: (val) => val.length < 6 ? 'Min 6 characters' : undefined,
    });

    if (isValid) {
      console.log('Submit:', values);
      reset();
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input value={values.username} onChange={handleChange('username')} />
      {errors.username && <span>{errors.username}</span>}

      <input value={values.email} onChange={handleChange('email')} />
      {errors.email && <span>{errors.email}</span>}

      <input type="password" value={values.password} onChange={handleChange('password')} />
      {errors.password && <span>{errors.password}</span>}

      <button type="submit">Sign Up</button>
    </form>
  );
}
```

## State Reducer Pattern

### Complex State Logic

```typescript
interface State {
  count: number;
  step: number;
  history: number[];
}

type Action =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'setStep'; step: number }
  | { type: 'undo' }
  | { type: 'reset' };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'increment':
      return {
        ...state,
        count: state.count + state.step,
        history: [...state.history, state.count + state.step],
      };
    case 'decrement':
      return {
        ...state,
        count: state.count - state.step,
        history: [...state.history, state.count - state.step],
      };
    case 'setStep':
      return { ...state, step: action.step };
    case 'undo':
      if (state.history.length === 0) return state;
      const newHistory = state.history.slice(0, -1);
      const lastValue = newHistory[newHistory.length - 1] ?? 0;
      return {
        ...state,
        count: lastValue,
        history: newHistory,
      };
    case 'reset':
      return { count: 0, step: 1, history: [0] };
    default:
      return state;
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, {
    count: 0,
    step: 1,
    history: [0],
  });

  return (
    <div>
      <p>Count: {state.count}</p>
      <button onClick={() => dispatch({ type: 'increment' })}>+</button>
      <button onClick={() => dispatch({ type: 'decrement' })}>-</button>
      <button onClick={() => dispatch({ type: 'undo' })}>Undo</button>
      <button onClick={() => dispatch({ type: 'reset' })}>Reset</button>
    </div>
  );
}
```

## Provider Pattern

### Context Provider with Hooks

```typescript
interface ToastContextType {
  showToast: (message: string, type: 'success' | 'error') => void;
}

const ToastContext = createContext<ToastContextType | undefined>(undefined);

interface Toast {
  id: string;
  message: string;
  type: 'success' | 'error';
}

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const showToast = useCallback((message: string, type: 'success' | 'error') => {
    const id = crypto.randomUUID();
    setToasts(prev => [...prev, { id, message, type }]);

    // Auto-dismiss after 3 seconds
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, 3000);
  }, []);

  return (
    <ToastContext.Provider value={{ showToast }}>
      {children}
      <div className="toast-container">
        {toasts.map(toast => (
          <div key={toast.id} className={`toast toast-${toast.type}`}>
            {toast.message}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within ToastProvider');
  }
  return context;
}

// Usage
function SaveButton() {
  const { showToast } = useToast();

  const handleSave = async () => {
    try {
      await saveData();
      showToast('Saved successfully!', 'success');
    } catch (error) {
      showToast('Save failed', 'error');
    }
  };

  return <button onClick={handleSave}>Save</button>;
}
```

## AI Pair Programming Notes

**When using React patterns:**

1. **Composition over inheritance**: Build with small, composable pieces
2. **Controlled components**: Parent controls state for predictability
3. **Compound components**: Group related components with shared context
4. **Custom hooks**: Extract reusable logic, start with "use"
5. **Render props**: Share logic when hooks aren't appropriate
6. **HOCs sparingly**: Prefer hooks and composition
7. **Container/Presentational**: Separate logic from UI
8. **State reducer**: Use for complex state transitions
9. **Provider pattern**: Share data with context + hooks
10. **Type safety**: Use TypeScript for all patterns

**Common pattern mistakes:**
- Using HOCs when custom hooks would be cleaner
- Not memoizing context values (causes re-renders)
- Overusing render props (hooks are usually better)
- Creating god components instead of composing
- Not separating logic from presentation
- Missing TypeScript types in patterns
- Not providing custom hooks for context
- Compound components without proper context
- State in presentational components
- Not using reducers for complex state

## Next Steps

1. **07-FORMS.md** - Form patterns and validation
2. **08-PERFORMANCE.md** - Optimizing patterns
3. **10-TESTING.md** - Testing component patterns

## Additional Resources

- React Patterns: https://react.dev/learn/thinking-in-react
- Composition: https://react.dev/learn/passing-props-to-a-component#passing-jsx-as-children
- Render Props: https://react.dev/reference/react/cloneElement#passing-data-with-a-render-prop
- Custom Hooks: https://react.dev/learn/reusing-logic-with-custom-hooks
