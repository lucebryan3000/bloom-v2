# React Performance Optimization

```yaml
id: react_08_performance
topic: React
file_role: Performance optimization, memoization, code splitting, profiling
profile: advanced
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - State (02-STATE.md)
  - Hooks (03-HOOKS.md)
related_topics:
  - Patterns (06-PATTERNS.md)
  - Context (05-CONTEXT.md)
  - React 19 (09-REACT-19.md)
embedding_keywords:
  - react performance
  - react optimization
  - useMemo
  - useCallback
  - React.memo
  - code splitting
  - lazy loading
  - profiler
  - virtualization
  - re-renders
last_reviewed: 2025-11-16
```

## Performance Overview

**Key Optimization Techniques:**
1. **Memoization** - Cache expensive calculations
2. **Code splitting** - Load code on demand
3. **Virtualization** - Render only visible items
4. **Lazy loading** - Defer loading of components
5. **Profiling** - Measure and identify bottlenecks

## Preventing Re-renders

### React.memo

```typescript
// ❌ Child re-renders every time parent renders
function Child({ name }: { name: string }) {
  console.log('Child rendered');
  return <div>{name}</div>;
}

// ✅ Child only re-renders if props change
const Child = memo(({ name }: { name: string }) => {
  console.log('Child rendered');
  return <div>{name}</div>;
});

// Usage
function Parent() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <button onClick={() => setCount(c => c + 1)}>Count: {count}</button>
      <Child name="Alice" /> {/* Won't re-render when count changes */}
    </div>
  );
}
```

### Custom Comparison

```typescript
interface UserProps {
  user: { id: number; name: string; metadata: object };
}

// Only re-render if id or name changes (ignore metadata)
const User = memo(
  ({ user }: UserProps) => {
    return <div>{user.name}</div>;
  },
  (prevProps, nextProps) => {
    return (
      prevProps.user.id === nextProps.user.id &&
      prevProps.user.name === nextProps.user.name
    );
  }
);
```

## useMemo

### Expensive Calculations

```typescript
function SearchResults({ query, items }: Props) {
  // ❌ Recalculates on every render
  const filteredItems = items.filter(item =>
    item.name.toLowerCase().includes(query.toLowerCase())
  );

  // ✅ Only recalculates when query or items change
  const filteredItems = useMemo(() => {
    console.log('Filtering items...');
    return items.filter(item =>
      item.name.toLowerCase().includes(query.toLowerCase())
    );
  }, [query, items]);

  return <ItemList items={filteredItems} />;
}
```

### Referential Equality

```typescript
function Parent() {
  const [count, setCount] = useState(0);

  // ❌ Creates new object every render
  const config = { theme: 'dark', size: 'large' };

  // ✅ Stable reference
  const config = useMemo(() => ({
    theme: 'dark',
    size: 'large',
  }), []);

  return <Child config={config} />;
}

const Child = memo(({ config }: { config: object }) => {
  return <div>{config.theme}</div>;
});
```

## useCallback

### Memoizing Functions

```typescript
function SearchInput({ onSearch }: { onSearch: (query: string) => void }) {
  const [query, setQuery] = useState('');

  // ❌ Creates new function every render
  const handleClick = () => {
    onSearch(query);
  };

  // ✅ Stable function reference
  const handleClick = useCallback(() => {
    onSearch(query);
  }, [query, onSearch]);

  return (
    <div>
      <input value={query} onChange={(e) => setQuery(e.target.value)} />
      <button onClick={handleClick}>Search</button>
    </div>
  );
}
```

### Event Handlers

```typescript
function TodoList() {
  const [todos, setTodos] = useState<Todo[]>([]);

  // ❌ New function for each todo
  return (
    <ul>
      {todos.map(todo => (
        <li key={todo.id}>
          {todo.text}
          <button onClick={() => handleDelete(todo.id)}>Delete</button>
        </li>
      ))}
    </ul>
  );

  // ✅ Memoized handler
  const handleDelete = useCallback((id: string) => {
    setTodos(prev => prev.filter(t => t.id !== id));
  }, []);

  return (
    <ul>
      {todos.map(todo => (
        <TodoItem
          key={todo.id}
          todo={todo}
          onDelete={handleDelete}
        />
      ))}
    </ul>
  );
}

const TodoItem = memo(({ todo, onDelete }: Props) => {
  return (
    <li>
      {todo.text}
      <button onClick={() => onDelete(todo.id)}>Delete</button>
    </li>
  );
});
```

## Code Splitting

### React.lazy

```typescript
import { lazy, Suspense } from 'react';

// ❌ Loads immediately
import Dashboard from './Dashboard';

// ✅ Loads when needed
const Dashboard = lazy(() => import('./Dashboard'));

function App() {
  const [showDashboard, setShowDashboard] = useState(false);

  return (
    <div>
      <button onClick={() => setShowDashboard(true)}>
        Show Dashboard
      </button>

      {showDashboard && (
        <Suspense fallback={<div>Loading...</div>}>
          <Dashboard />
        </Suspense>
      )}
    </div>
  );
}
```

### Route-based Code Splitting

```typescript
import { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';

const Home = lazy(() => import('./pages/Home'));
const About = lazy(() => import('./pages/About'));
const Dashboard = lazy(() => import('./pages/Dashboard'));

function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<div>Loading...</div>}>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/about" element={<About />} />
          <Route path="/dashboard" element={<Dashboard />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}
```

## Virtualization

### react-window

```typescript
import { FixedSizeList } from 'react-window';

function VirtualizedList({ items }: { items: string[] }) {
  const Row = ({ index, style }: { index: number; style: React.CSSProperties }) => (
    <div style={style}>
      {items[index]}
    </div>
  );

  return (
    <FixedSizeList
      height={600}
      itemCount={items.length}
      itemSize={35}
      width="100%"
    >
      {Row}
    </FixedSizeList>
  );
}

// Renders only visible rows, not all 10,000
<VirtualizedList items={Array.from({ length: 10000 }, (_, i) => `Item ${i}`)} />
```

### Variable Height Virtualization

```typescript
import { VariableSizeList } from 'react-window';

function VariableList({ items }: { items: Item[] }) {
  const getItemSize = (index: number) => {
    // Return height based on content
    return items[index].longContent ? 100 : 50;
  };

  const Row = ({ index, style }: any) => (
    <div style={style}>
      {items[index].content}
    </div>
  );

  return (
    <VariableSizeList
      height={600}
      itemCount={items.length}
      itemSize={getItemSize}
      width="100%"
    >
      {Row}
    </VariableSizeList>
  );
}
```

## Profiling

### React DevTools Profiler

```typescript
// Enable profiling in production build
// package.json
{
  "scripts": {
    "build:profile": "react-scripts build --profile"
  }
}

// Profile specific component
import { Profiler } from 'react';

function App() {
  const onRender = (
    id: string,
    phase: 'mount' | 'update',
    actualDuration: number,
    baseDuration: number,
    startTime: number,
    commitTime: number
  ) => {
    console.log(`${id} (${phase}) took ${actualDuration}ms`);
  };

  return (
    <Profiler id="App" onRender={onRender}>
      <Dashboard />
    </Profiler>
  );
}
```

## Optimizing Context

### Split Contexts

```typescript
// ❌ All consumers re-render when any value changes
const AppContext = createContext({ user: null, theme: 'light', settings: {} });

// ✅ Split into separate contexts
const UserContext = createContext(null);
const ThemeContext = createContext('light');
const SettingsContext = createContext({});

// Components only re-render for what they use
function UserProfile() {
  const user = useContext(UserContext); // Only re-renders on user change
  return <div>{user?.name}</div>;
}

function ThemeToggle() {
  const theme = useContext(ThemeContext); // Only re-renders on theme change
  return <button>{theme}</button>;
}
```

### Memoize Context Values

```typescript
function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState('light');

  // ❌ Creates new object every render
  const value = { theme, setTheme };

  // ✅ Stable reference
  const value = useMemo(() => ({ theme, setTheme }), [theme]);

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
}
```

## Debouncing and Throttling

### Debounced Search

```typescript
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => clearTimeout(handler);
  }, [value, delay]);

  return debouncedValue;
}

function SearchInput() {
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearchTerm = useDebounce(searchTerm, 500);

  useEffect(() => {
    if (debouncedSearchTerm) {
      // API call only after 500ms of no typing
      searchAPI(debouncedSearchTerm);
    }
  }, [debouncedSearchTerm]);

  return (
    <input
      value={searchTerm}
      onChange={(e) => setSearchTerm(e.target.value)}
    />
  );
}
```

### Throttled Scroll

```typescript
function useThrottle<T>(value: T, delay: number): T {
  const [throttledValue, setThrottledValue] = useState(value);
  const lastRan = useRef(Date.now());

  useEffect(() => {
    const handler = setTimeout(() => {
      if (Date.now() - lastRan.current >= delay) {
        setThrottledValue(value);
        lastRan.current = Date.now();
      }
    }, delay - (Date.now() - lastRan.current));

    return () => clearTimeout(handler);
  }, [value, delay]);

  return throttledValue;
}
```

## Image Optimization

### Lazy Loading Images

```typescript
function LazyImage({ src, alt }: { src: string; alt: string }) {
  const [isLoaded, setIsLoaded] = useState(false);
  const imgRef = useRef<HTMLImageElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && imgRef.current) {
          imgRef.current.src = src;
          setIsLoaded(true);
          observer.disconnect();
        }
      },
      { rootMargin: '100px' }
    );

    if (imgRef.current) {
      observer.observe(imgRef.current);
    }

    return () => observer.disconnect();
  }, [src]);

  return (
    <img
      ref={imgRef}
      alt={alt}
      style={{ opacity: isLoaded ? 1 : 0, transition: 'opacity 0.3s' }}
    />
  );
}
```

## State Updates

### Batching

```typescript
// React 18+ automatically batches
function handleClick() {
  setCount(c => c + 1);
  setFlag(f => !f);
  setData(d => d + 1);
  // Only 1 re-render
}

// Also batched in promises/timeouts (React 18+)
async function handleAsync() {
  const data = await fetchData();
  setUser(data.user);
  setSettings(data.settings);
  // Only 1 re-render
}
```

### Functional Updates

```typescript
// ❌ May use stale state
const handleClick = () => {
  setCount(count + 1);
  setCount(count + 1); // Still only increments by 1
};

// ✅ Always uses current state
const handleClick = () => {
  setCount(c => c + 1);
  setCount(c => c + 1); // Increments by 2
};
```

## AI Pair Programming Notes

**When optimizing React:**

1. **Measure first**: Use React DevTools Profiler before optimizing
2. **memo sparingly**: Only wrap expensive components
3. **useMemo for expensive calculations**: Not for simple operations
4. **useCallback for stable refs**: When passing to memoized children
5. **Code split routes**: Lazy load page-level components
6. **Virtualize long lists**: Use react-window for 100+ items
7. **Debounce inputs**: For search, autocomplete
8. **Split contexts**: Separate frequently vs rarely changing data
9. **Optimize images**: Lazy load, use proper formats
10. **Batch state updates**: React 18+ does this automatically

**Common performance mistakes:**
- Optimizing prematurely (measure first!)
- Wrapping everything in memo/useMemo
- Missing dependencies in useMemo/useCallback
- Not code splitting large components
- Rendering huge lists without virtualization
- Creating new objects/functions in render
- Not memoizing context values
- Using index as key in dynamic lists
- Unnecessary re-renders from context
- Not lazy loading images

## Next Steps

1. **09-REACT-19.md** - React 19 features and improvements
2. **10-TESTING.md** - Testing performance
3. **Profiling Tools** - React DevTools, Chrome DevTools

## Additional Resources

- React Profiler: https://react.dev/reference/react/Profiler
- useMemo: https://react.dev/reference/react/useMemo
- useCallback: https://react.dev/reference/react/useCallback
- React.memo: https://react.dev/reference/react/memo
- Code Splitting: https://react.dev/reference/react/lazy
- react-window: https://github.com/bvaughn/react-window
