# React Hooks

```yaml
id: react_03_hooks
topic: React
file_role: React hooks - useEffect, useRef, useMemo, useCallback, custom hooks
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - State (02-STATE.md)
related_topics:
  - Performance (08-PERFORMANCE.md)
  - React 19 Features (09-REACT-19.md)
  - Testing (10-TESTING.md)
embedding_keywords:
  - react hooks
  - useEffect
  - useRef
  - useMemo
  - useCallback
  - custom hooks
  - useLayoutEffect
  - useImperativeHandle
  - useReducer
last_reviewed: 2025-11-16
```

## Hooks Overview

**Hooks** let you use state and other React features in functional components.

**Built-in Hooks:**
1. **useState** - Add state to components
2. **useEffect** - Perform side effects
3. **useRef** - Reference DOM elements or persist values
4. **useMemo** - Memoize expensive calculations
5. **useCallback** - Memoize functions
6. **useReducer** - Alternative to useState for complex state
7. **useContext** - Access context values
8. **useLayoutEffect** - Synchronous effects before paint
9. **useImperativeHandle** - Customize ref exposure
10. **useId** - Generate unique IDs (React 18+)

**Hook Rules:**
- ✅ Call hooks at the top level (not in loops/conditions)
- ✅ Call hooks from React functions only
- ❌ Never call hooks inside conditions or loops

## useEffect

### Basic Usage

```typescript
import { useEffect } from 'react';

function Component() {
  useEffect(() => {
    // Effect code runs after render
    console.log('Component rendered');
  });

  return <div>Hello</div>;
}
```

### Dependencies Array

```typescript
function User({ userId }: Props) {
  const [user, setUser] = useState<User | null>(null);

  // Run once on mount (empty dependency array)
  useEffect(() => {
    console.log('Component mounted');
  }, []);

  // Run when userId changes
  useEffect(() => {
    fetchUser(userId).then(setUser);
  }, [userId]);

  // Run on every render (no dependency array)
  useEffect(() => {
    console.log('Every render');
  });

  return <div>{user?.name}</div>;
}
```

### Cleanup Function

```typescript
function Timer() {
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setSeconds(s => s + 1);
    }, 1000);

    // Cleanup function - runs before next effect and on unmount
    return () => {
      clearInterval(interval);
    };
  }, []); // Empty array - effect runs once

  return <div>Seconds: {seconds}</div>;
}
```

### Data Fetching Pattern

```typescript
function UserProfile({ userId }: Props) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;

    const fetchUser = async () => {
      try {
        setLoading(true);
        const data = await api.getUser(userId);

        if (!cancelled) {
          setUser(data);
          setError(null);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err as Error);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    fetchUser();

    // Cleanup - prevent state updates if component unmounts
    return () => {
      cancelled = true;
    };
  }, [userId]);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  if (!user) return <div>User not found</div>;

  return <div>{user.name}</div>;
}
```

### Event Listeners

```typescript
function WindowSize() {
  const [size, setSize] = useState({ width: 0, height: 0 });

  useEffect(() => {
    const handleResize = () => {
      setSize({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    };

    // Set initial size
    handleResize();

    // Add listener
    window.addEventListener('resize', handleResize);

    // Cleanup - remove listener
    return () => {
      window.removeEventListener('resize', handleResize);
    };
  }, []);

  return <div>{size.width} x {size.height}</div>;
}
```

## useRef

### DOM References

```typescript
function TextInput() {
  const inputRef = useRef<HTMLInputElement>(null);

  const focusInput = () => {
    inputRef.current?.focus();
  };

  return (
    <div>
      <input ref={inputRef} type="text" />
      <button onClick={focusInput}>Focus Input</button>
    </div>
  );
}
```

### Persisting Values (Without Re-renders)

```typescript
function Timer() {
  const [count, setCount] = useState(0);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  const start = () => {
    if (intervalRef.current) return; // Already running

    intervalRef.current = setInterval(() => {
      setCount(c => c + 1);
    }, 1000);
  };

  const stop = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
  };

  useEffect(() => {
    // Cleanup on unmount
    return () => stop();
  }, []);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={start}>Start</button>
      <button onClick={stop}>Stop</button>
    </div>
  );
}
```

### Previous Value Pattern

```typescript
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();

  useEffect(() => {
    ref.current = value;
  }, [value]);

  return ref.current;
}

// Usage
function Counter() {
  const [count, setCount] = useState(0);
  const prevCount = usePrevious(count);

  return (
    <div>
      <p>Current: {count}</p>
      <p>Previous: {prevCount}</p>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
    </div>
  );
}
```

## useMemo

### Expensive Calculations

```typescript
function FilteredList({ items, filter }: Props) {
  // ❌ BAD - Recalculates every render
  const filteredItems = items.filter(item =>
    item.name.toLowerCase().includes(filter.toLowerCase())
  );

  // ✅ GOOD - Only recalculates when items or filter changes
  const filteredItems = useMemo(() => {
    return items.filter(item =>
      item.name.toLowerCase().includes(filter.toLowerCase())
    );
  }, [items, filter]);

  return (
    <ul>
      {filteredItems.map(item => (
        <li key={item.id}>{item.name}</li>
      ))}
    </ul>
  );
}
```

### Referential Equality

```typescript
function ParentComponent() {
  const [count, setCount] = useState(0);

  // ❌ BAD - Creates new object every render
  const config = { theme: 'dark', size: 'large' };

  // ✅ GOOD - Stable reference
  const config = useMemo(() => ({
    theme: 'dark',
    size: 'large',
  }), []);

  return <ChildComponent config={config} />;
}

// Child only re-renders if config changes
const ChildComponent = memo(({ config }: Props) => {
  return <div>{config.theme}</div>;
});
```

## useCallback

### Memoizing Functions

```typescript
function SearchInput({ onSearch }: Props) {
  const [query, setQuery] = useState('');

  // ❌ BAD - Creates new function every render
  const handleSearch = () => {
    onSearch(query);
  };

  // ✅ GOOD - Stable function reference
  const handleSearch = useCallback(() => {
    onSearch(query);
  }, [query, onSearch]);

  return (
    <div>
      <input value={query} onChange={(e) => setQuery(e.target.value)} />
      <button onClick={handleSearch}>Search</button>
    </div>
  );
}
```

### With Child Components

```typescript
function TodoList() {
  const [todos, setTodos] = useState<Todo[]>([]);

  // Memoized callback - doesn't recreate unless setTodos changes
  const handleToggle = useCallback((id: string) => {
    setTodos(prev =>
      prev.map(todo =>
        todo.id === id ? { ...todo, completed: !todo.completed } : todo
      )
    );
  }, []); // setTodos is stable, so empty deps

  return (
    <ul>
      {todos.map(todo => (
        <TodoItem
          key={todo.id}
          todo={todo}
          onToggle={handleToggle}
        />
      ))}
    </ul>
  );
}

// Child only re-renders if todo changes (not if parent re-renders)
const TodoItem = memo(({ todo, onToggle }: Props) => {
  return (
    <li onClick={() => onToggle(todo.id)}>
      {todo.text}
    </li>
  );
});
```

## useReducer

### Complex State Logic

```typescript
interface State {
  count: number;
  step: number;
}

type Action =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'setStep'; step: number }
  | { type: 'reset' };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'increment':
      return { ...state, count: state.count + state.step };
    case 'decrement':
      return { ...state, count: state.count - state.step };
    case 'setStep':
      return { ...state, step: action.step };
    case 'reset':
      return { count: 0, step: 1 };
    default:
      return state;
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, { count: 0, step: 1 });

  return (
    <div>
      <p>Count: {state.count}</p>
      <p>Step: {state.step}</p>
      <button onClick={() => dispatch({ type: 'increment' })}>+</button>
      <button onClick={() => dispatch({ type: 'decrement' })}>-</button>
      <button onClick={() => dispatch({ type: 'reset' })}>Reset</button>
      <input
        type="number"
        value={state.step}
        onChange={(e) => dispatch({ type: 'setStep', step: Number(e.target.value) })}
      />
    </div>
  );
}
```

### Form State with useReducer

```typescript
interface FormState {
  username: string;
  email: string;
  password: string;
  errors: Record<string, string>;
}

type FormAction =
  | { type: 'setField'; field: string; value: string }
  | { type: 'setError'; field: string; error: string }
  | { type: 'reset' };

function formReducer(state: FormState, action: FormAction): FormState {
  switch (action.type) {
    case 'setField':
      return {
        ...state,
        [action.field]: action.value,
        errors: { ...state.errors, [action.field]: '' },
      };
    case 'setError':
      return {
        ...state,
        errors: { ...state.errors, [action.field]: action.error },
      };
    case 'reset':
      return {
        username: '',
        email: '',
        password: '',
        errors: {},
      };
    default:
      return state;
  }
}

function SignupForm() {
  const [state, dispatch] = useReducer(formReducer, {
    username: '',
    email: '',
    password: '',
    errors: {},
  });

  const handleChange = (field: string) => (e: React.ChangeEvent<HTMLInputElement>) => {
    dispatch({ type: 'setField', field, value: e.target.value });
  };

  return (
    <form>
      <input value={state.username} onChange={handleChange('username')} />
      {state.errors.username && <span>{state.errors.username}</span>}
    </form>
  );
}
```

## useLayoutEffect

### Measuring DOM Before Paint

```typescript
function Tooltip({ children }: Props) {
  const [tooltipHeight, setTooltipHeight] = useState(0);
  const tooltipRef = useRef<HTMLDivElement>(null);

  // ✅ useLayoutEffect - Runs synchronously before browser paint
  useLayoutEffect(() => {
    if (tooltipRef.current) {
      const { height } = tooltipRef.current.getBoundingClientRect();
      setTooltipHeight(height);
    }
  }, [children]);

  return (
    <div
      ref={tooltipRef}
      style={{ transform: `translateY(-${tooltipHeight}px)` }}
    >
      {children}
    </div>
  );
}
```

## Custom Hooks

### useLocalStorage

```typescript
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
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
      window.localStorage.setItem(key, JSON.stringify(valueToStore));
    } catch (error) {
      console.error(error);
    }
  };

  return [storedValue, setValue] as const;
}

// Usage
function App() {
  const [name, setName] = useLocalStorage('name', 'Alice');

  return (
    <input
      value={name}
      onChange={(e) => setName(e.target.value)}
    />
  );
}
```

### useDebounce

```typescript
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

// Usage
function SearchInput() {
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearchTerm = useDebounce(searchTerm, 500);

  useEffect(() => {
    if (debouncedSearchTerm) {
      // API call with debounced value
      searchAPI(debouncedSearchTerm);
    }
  }, [debouncedSearchTerm]);

  return (
    <input
      value={searchTerm}
      onChange={(e) => setSearchTerm(e.target.value)}
      placeholder="Search..."
    />
  );
}
```

### useFetch

```typescript
interface FetchState<T> {
  data: T | null;
  loading: boolean;
  error: Error | null;
}

function useFetch<T>(url: string) {
  const [state, setState] = useState<FetchState<T>>({
    data: null,
    loading: true,
    error: null,
  });

  useEffect(() => {
    let cancelled = false;

    const fetchData = async () => {
      try {
        setState({ data: null, loading: true, error: null });
        const response = await fetch(url);

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const json = await response.json();

        if (!cancelled) {
          setState({ data: json, loading: false, error: null });
        }
      } catch (error) {
        if (!cancelled) {
          setState({ data: null, loading: false, error: error as Error });
        }
      }
    };

    fetchData();

    return () => {
      cancelled = true;
    };
  }, [url]);

  return state;
}

// Usage
function UserProfile({ userId }: Props) {
  const { data, loading, error } = useFetch<User>(`/api/users/${userId}`);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  if (!data) return <div>No data</div>;

  return <div>{data.name}</div>;
}
```

### useWindowSize

```typescript
function useWindowSize() {
  const [windowSize, setWindowSize] = useState({
    width: window.innerWidth,
    height: window.innerHeight,
  });

  useEffect(() => {
    const handleResize = () => {
      setWindowSize({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return windowSize;
}

// Usage
function ResponsiveComponent() {
  const { width } = useWindowSize();

  return (
    <div>
      {width < 768 ? <MobileView /> : <DesktopView />}
    </div>
  );
}
```

### useToggle

```typescript
function useToggle(initialValue = false): [boolean, () => void] {
  const [value, setValue] = useState(initialValue);

  const toggle = useCallback(() => {
    setValue(v => !v);
  }, []);

  return [value, toggle];
}

// Usage
function Modal() {
  const [isOpen, toggleOpen] = useToggle(false);

  return (
    <div>
      <button onClick={toggleOpen}>Open Modal</button>
      {isOpen && (
        <div className="modal">
          <button onClick={toggleOpen}>Close</button>
        </div>
      )}
    </div>
  );
}
```

## AI Pair Programming Notes

**When using React hooks:**

1. **Follow Rules of Hooks**: Always at top level, only in React functions
2. **useEffect cleanup**: Always cleanup subscriptions, timers, listeners
3. **Dependency arrays**: Include all used values, use ESLint plugin
4. **useMemo/useCallback**: Only for expensive operations or referential equality
5. **useRef for persistence**: Values that don't trigger re-renders
6. **useReducer for complex state**: When useState becomes unwieldy
7. **Custom hooks**: Extract reusable logic, start with "use" prefix
8. **Avoid premature optimization**: Don't useMemo/useCallback everything
9. **Type your hooks**: Use TypeScript for type safety
10. **Test custom hooks**: Use @testing-library/react-hooks

**Common hook mistakes:**
- Missing dependencies in useEffect (use ESLint exhaustive-deps)
- Not cleaning up effects (memory leaks)
- Using index as key in lists
- Mutating ref values during render
- Over-using useMemo/useCallback (premature optimization)
- Calling hooks conditionally
- Not canceling async operations on unmount
- Infinite loops from missing dependencies
- Using useEffect when useLayoutEffect is needed
- Not using functional updates in closures

## Next Steps

1. **04-EVENTS.md** - Event handling and forms
2. **08-PERFORMANCE.md** - Optimizing with hooks
3. **10-TESTING.md** - Testing components with hooks

## Additional Resources

- React Hooks API: https://react.dev/reference/react
- useEffect Guide: https://react.dev/learn/synchronizing-with-effects
- Custom Hooks: https://react.dev/learn/reusing-logic-with-custom-hooks
- Rules of Hooks: https://react.dev/reference/rules/rules-of-hooks
