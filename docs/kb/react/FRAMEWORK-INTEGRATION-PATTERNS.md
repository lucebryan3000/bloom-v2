---
id: react-patterns
topic: react
file_role: patterns
profile: full
difficulty_level: intermediate-advanced
kb_version: 3.1
prerequisites: [react-basics, javascript]
related_topics: [nextjs, typescript, ui]
embedding_keywords: [patterns, examples, integration, best-practices, react-patterns]
last_reviewed: 2025-11-13
---

# React Framework Integration Patterns

**Purpose**: Production-ready React patterns and integration examples.

---

## 📋 Table of Contents

1. [Component Patterns](#component-patterns)
2. [State Management](#state-management)
3. [Custom Hooks](#custom-hooks)
4. [Performance Optimization](#performance-optimization)
5. [TypeScript Integration](#typescript-integration)

---

## Component Patterns

### Pattern 1: Functional Component with Props

```tsx
interface ButtonProps {
 label: string;
 onClick: => void;
 variant?: 'primary' | 'secondary';
}

export function Button({ label, onClick, variant = 'primary' }: ButtonProps) {
 return (
 <button
 className={`btn btn-${variant}`}
 onClick={onClick}
 >
 {label}
 </button>
 );
}
```

### Pattern 2: Component with Children

```tsx
interface CardProps {
 title: string;
 children: React.ReactNode;
}

export function Card({ title, children }: CardProps) {
 return (
 <div className="card">
 <h2>{title}</h2>
 <div className="card-content">{children}</div>
 </div>
 );
}
```

---

## State Management

### Pattern 3: useState Hook

```tsx
export function Counter {
 const [count, setCount] = useState(0);

 return (
 <div>
 <p>Count: {count}</p>
 <button onClick={ => setCount(count + 1)}>Increment</button>
 </div>
 );
}
```

### Pattern 4: useReducer for Complex State

```tsx
type State = { count: number; step: number };
type Action = { type: 'increment' } | { type: 'decrement' } | { type: 'setStep'; step: number };

function reducer(state: State, action: Action): State {
 switch (action.type) {
 case 'increment':
 return {...state, count: state.count + state.step };
 case 'decrement':
 return {...state, count: state.count - state.step };
 case 'setStep':
 return {...state, step: action.step };
 default:
 return state;
 }
}

export function AdvancedCounter {
 const [state, dispatch] = useReducer(reducer, { count: 0, step: 1 });

 return (
 <div>
 <p>Count: {state.count}</p>
 <button onClick={ => dispatch({ type: 'increment' })}>+{state.step}</button>
 <button onClick={ => dispatch({ type: 'decrement' })}>-{state.step}</button>
 </div>
 );
}
```

---

## Custom Hooks

### Pattern 5: useLocalStorage Hook

```tsx
function useLocalStorage<T>(key: string, initialValue: T) {
 const [value, setValue] = useState<T>( => {
 const stored = localStorage.getItem(key);
 return stored ? JSON.parse(stored): initialValue;
 });

 useEffect( => {
 localStorage.setItem(key, JSON.stringify(value));
 }, [key, value]);

 return [value, setValue] as const;
}
```

### Pattern 6: useFetch Hook

```tsx
function useFetch<T>(url: string) {
 const [data, setData] = useState<T | null>(null);
 const [loading, setLoading] = useState(true);
 const [error, setError] = useState<Error | null>(null);

 useEffect( => {
 fetch(url)
.then(res => res.json)
.then(setData)
.catch(setError)
.finally( => setLoading(false));
 }, [url]);

 return { data, loading, error };
}
```

---

## Performance Optimization

### Pattern 7: useMemo

```tsx
export function ExpensiveComponent({ items }: { items: number[] }) {
 const sum = useMemo( => {
 return items.reduce((acc, val) => acc + val, 0);
 }, [items]);

 return <div>Sum: {sum}</div>;
}
```

### Pattern 8: useCallback

```tsx
export function ParentComponent {
 const [count, setCount] = useState(0);

 const handleClick = useCallback( => {
 setCount(c => c + 1);
 }, []);

 return <ChildComponent onClick={handleClick} />;
}
```

---

## TypeScript Integration

### Pattern 9: Typed Event Handlers

```tsx
export function Form {
 const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
 e.preventDefault;
 // Handle submit
 };

 const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
 console.log(e.target.value);
 };

 return (
 <form onSubmit={handleSubmit}>
 <input onChange={handleChange} />
 </form>
 );
}
```

---

## Best Practices

1. **Use Functional Components**: Prefer functions over classes
2. **TypeScript**: Always type your props and state
3. **Custom Hooks**: Extract reusable logic into custom hooks
4. **Memoization**: Use useMemo/useCallback for expensive operations
5. **Component Composition**: Build complex UIs from small, reusable components

---

## Related Files

- **Quick Syntax**: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- **Overview**: [README.md](./README.md)
- **Navigation**: [INDEX.md](./INDEX.md)

---

**All examples are production-ready patterns. Adapt them to your project needs!**
