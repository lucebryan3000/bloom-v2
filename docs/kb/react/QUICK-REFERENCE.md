---
id: react-quick-reference
topic: react
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: ['javascript', 'html', 'css']
related_topics: ['javascript', 'nextjs', 'ui']
embedding_keywords: [react, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-13
---

# React Quick Reference

**One-page cheat sheet for React 19 development**

---

## Components

### Function Component
```tsx
interface Props {
 title: string;
 count?: number;
}

export function MyComponent({ title, count = 0 }: Props) {
 return <h1>{title}: {count}</h1>;
}
```

### With Children
```tsx
interface Props {
 children: React.ReactNode;
}

export function Container({ children }: Props) {
 return <div className="container">{children}</div>;
}
```

---

## State

### useState
```tsx
const [count, setCount] = useState(0);
const [user, setUser] = useState<User | null>(null);

// Update
setCount(5);
setCount(prev => prev + 1); // Functional update

// Object state
setUser({ id: 1, name: 'Alice' });
setUser(prev => ({...prev, name: 'Bob' }));
```

### useReducer
```tsx
type State = { count: number };
type Action = { type: 'increment' } | { type: 'decrement' };

const reducer = (state: State, action: Action) => {
 switch (action.type) {
 case 'increment': return { count: state.count + 1 };
 case 'decrement': return { count: state.count - 1 };
 }
};

const [state, dispatch] = useReducer(reducer, { count: 0 });
```

---

## Effects

### useEffect
```tsx
// Run once on mount
useEffect( => {
 console.log('Mounted');
 return => console.log('Cleanup');
}, []);

// Run when deps change
useEffect( => {
 fetchData(userId);
}, [userId]);

// Async effect
useEffect( => {
 async function loadData {
 const data = await fetchData;
 setData(data);
 }
 loadData;
}, []);
```

### useLayoutEffect
```tsx
useLayoutEffect( => {
 // Runs synchronously after DOM mutations
 const box = ref.current?.getBoundingClientRect;
}, []);
```

---

## Refs

### useRef
```tsx
const inputRef = useRef<HTMLInputElement>(null);
const countRef = useRef(0); // Mutable value that persists

// Access DOM element
inputRef.current?.focus;

// Store mutable value
countRef.current += 1;
```

### forwardRef
```tsx
const Input = forwardRef<HTMLInputElement, Props>(
 ({ label }, ref) => {
 return <input ref={ref} aria-label={label} />;
 }
);
```

---

## Memoization

### useMemo
```tsx
const expensiveValue = useMemo( => {
 return computeExpensiveValue(a, b);
}, [a, b]);
```

### useCallback
```tsx
const handleClick = useCallback( => {
 doSomething(id);
}, [id]);
```

### memo
```tsx
const MemoizedComponent = memo(function Component({ name }: Props) {
 return <div>{name}</div>;
});
```

---

## Context

### Create Context
```tsx
const ThemeContext = createContext<'light' | 'dark'>('light');
```

### Provider
```tsx
function App {
 const [theme, setTheme] = useState<'light' | 'dark'>('light');

 return (
 <ThemeContext.Provider value={theme}>
 <Content />
 </ThemeContext.Provider>
 );
}
```

### Consumer
```tsx
function ThemedButton {
 const theme = useContext(ThemeContext);
 return <button className={theme}>Click</button>;
}
```

---

## Events

### Common Events
```tsx
function Form {
 const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
 e.preventDefault;
 // Handle submit
 };

 const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
 setValue(e.target.value);
 };

 const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
 console.log('Clicked');
 };

 return (
 <form onSubmit={handleSubmit}>
 <input onChange={handleChange} />
 <button onClick={handleClick}>Submit</button>
 </form>
 );
}
```

---

## Forms

### Controlled Input
```tsx
const [value, setValue] = useState('');

<input
 value={value}
 onChange={(e) => setValue(e.target.value)}
/>
```

### Form with Validation
```tsx
const [form, setForm] = useState({ email: '', password: '' });
const [errors, setErrors] = useState<Record<string, string>>({});

const handleSubmit = (e: React.FormEvent) => {
 e.preventDefault;

 const newErrors: Record<string, string> = {};
 if (!form.email) newErrors.email = 'Required';
 if (form.password.length < 8) newErrors.password = 'Too short';

 if (Object.keys(newErrors).length > 0) {
 setErrors(newErrors);
 return;
 }

 // Submit form
};
```

---

## React 19 Features

### useActionState
```tsx
'use client';

import { useActionState } from 'react';

function Form {
 const [state, formAction, isPending] = useActionState(
 async (prevState, formData) => {
 const name = formData.get('name');
 return { message: `Hello ${name}` };
 },
 { message: '' }
 );

 return (
 <form action={formAction}>
 <input name="name" />
 <button disabled={isPending}>Submit</button>
 {state.message && <p>{state.message}</p>}
 </form>
 );
}
```

### useOptimistic
```tsx
import { useOptimistic } from 'react';

function Todos({ todos }: Props) {
 const [optimisticTodos, addOptimistic] = useOptimistic(
 todos,
 (state, newTodo: Todo) => [...state, newTodo]
 );

 async function addTodo(formData: FormData) {
 const newTodo = { id: Date.now, text: formData.get('text') as string };
 addOptimistic(newTodo);
 await saveTodo(newTodo);
 }

 return (
 <form action={addTodo}>
 <input name="text" />
 <button type="submit">Add</button>
 <ul>
 {optimisticTodos.map(todo => (
 <li key={todo.id}>{todo.text}</li>
 ))}
 </ul>
 </form>
 );
}
```

### use (Resource Loading)
```tsx
import { use } from 'react';

function User({ userPromise }: { userPromise: Promise<User> }) {
 const user = use(userPromise); // Suspend until resolved

 return <div>{user.name}</div>;
}
```

---

## Custom Hooks

### Basic Pattern
```tsx
function useCounter(initialValue = 0) {
 const [count, setCount] = useState(initialValue);

 const increment = useCallback( => {
 setCount(c => c + 1);
 }, []);

 const decrement = useCallback( => {
 setCount(c => c - 1);
 }, []);

 return { count, increment, decrement };
}

// Usage
const { count, increment, decrement } = useCounter(10);
```

### With Async
```tsx
function useAsync<T>(asyncFn: => Promise<T>, deps: any[]) {
 const [state, setState] = useState<{
 loading: boolean;
 data: T | null;
 error: Error | null;
 }>({ loading: true, data: null, error: null });

 useEffect( => {
 let cancelled = false;

 setState({ loading: true, data: null, error: null });

 asyncFn
.then(data => {
 if (!cancelled) {
 setState({ loading: false, data, error: null });
 }
 })
.catch(error => {
 if (!cancelled) {
 setState({ loading: false, data: null, error });
 }
 });

 return => {
 cancelled = true;
 };
 }, deps);

 return state;
}
```

---

## Performance

### Optimization Checklist
```tsx
// 1. Memoize expensive calculations
const result = useMemo( => expensiveCalc(data), [data]);

// 2. Memoize callbacks passed to children
const handler = useCallback( => {}, []);

// 3. Memoize components
const Child = memo(ChildComponent);

// 4. Use keys for lists
{items.map(item => <Item key={item.id} {...item} />)}

// 5. Lazy load components
const Heavy = lazy( => import('./Heavy'));

// 6. Code split
<Suspense fallback={<Loading />}>
 <Heavy />
</Suspense>
```

---

## TypeScript Types

### Common Props
```tsx
interface Props {
 // Primitives
 title: string;
 count: number;
 enabled: boolean;

 // Optional
 subtitle?: string;

 // Children
 children: React.ReactNode;

 // Functions
 onClick: => void;
 onChange: (value: string) => void;

 // Events
 onSubmit: (e: React.FormEvent) => void;

 // Styles
 className?: string;
 style?: React.CSSProperties;

 // Generic objects
 data: Record<string, unknown>;

 // Arrays
 items: string[];
 users: User[];

 // Union types
 status: 'idle' | 'loading' | 'success' | 'error';
}
```

### Component Types
```tsx
// FC (Function Component)
const Component: React.FC<Props> = ({ children }) => {
 return <div>{children}</div>;
};

// Explicit return type
function Component({ title }: Props): JSX.Element {
 return <h1>{title}</h1>;
}

// With generics
function List<T>({ items, render }: {
 items: T[];
 render: (item: T) => React.ReactNode;
}) {
 return <ul>{items.map(render)}</ul>;
}
```

---

## Common Patterns

### Conditional Rendering
```tsx
// If/else
{isLoading ? <Loading />: <Content />}

// Logical AND
{error && <Error message={error} />}

// Nullish coalescing
{data ?? <Empty />}

// Switch/case equivalent
{status === 'loading' && <Loading />}
{status === 'error' && <Error />}
{status === 'success' && <Success />}
```

### Lists
```tsx
// Map
{items.map(item => (
 <Item key={item.id} data={item} />
))}

// Filter
{items.filter(item => item.active).map(item => (
 <Item key={item.id} data={item} />
))}
```

### Fragments
```tsx
// Short syntax
<>
 <Header />
 <Main />
</>

// With key
{items.map(item => (
 <Fragment key={item.id}>
 <dt>{item.term}</dt>
 <dd>{item.description}</dd>
 </Fragment>
))}
```

---

## Testing

### React Testing Library
```tsx
import { render, screen, fireEvent } from '@testing-library/react';

test('renders button', => {
 render(<Button>Click me</Button>);

 const button = screen.getByRole('button', { name: /click me/i });
 expect(button).toBeInTheDocument;
});

test('handles click', => {
 const handleClick = jest.fn;
 render(<Button onClick={handleClick}>Click</Button>);

 fireEvent.click(screen.getByRole('button'));
 expect(handleClick).toHaveBeenCalledTimes(1);
});
```

---

## Best Practices

### ✅ Do
- Use functional components
- Type all props with TypeScript
- Use const for components
- Destructure props
- Use key for lists
- Clean up effects
- Memoize expensive operations
- Use semantic HTML
- Handle errors

### ❌ Don't
- Mutate state directly
- Use index as key
- Call hooks conditionally
- Use inline functions in JSX (when perf matters)
- Forget dependencies in hooks
- Use any type
- Create functions inside render
- Ignore warnings

---

**Quick Tips**:
- Components are just functions
- Props flow down, events flow up
- State is asynchronous
- Effects run after render
- Keys must be stable
- Cleanup prevents leaks

**Last Updated**: November 9, 2025
