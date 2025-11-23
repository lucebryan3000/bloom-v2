# React State Management

```yaml
id: react_02_state
topic: React
file_role: State management, useState hook, and state patterns
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
related_topics:
  - Hooks (03-HOOKS.md)
  - Context (05-CONTEXT.md)
  - Performance (08-PERFORMANCE.md)
  - Zustand (../zustand/)
embedding_keywords:
  - react state
  - useState
  - state management
  - react state patterns
  - derived state
  - lifting state up
  - state initialization
  - functional updates
last_reviewed: 2025-11-16
```

## State Overview

**State** is data that changes over time in your component. When state changes, React re-renders the component.

**Key Concepts:**
1. **useState hook**: Add state to functional components
2. **State is local**: Each component instance has its own state
3. **State updates are asynchronous**: Don't rely on immediate updates
4. **Immutability**: Never mutate state directly
5. **Derived state**: Calculate values from state instead of storing duplicates

## useState Hook

### Basic Usage

```typescript
import { useState } from 'react';

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  );
}
```

### Type Annotations

```typescript
// Inferred type
const [name, setName] = useState('Alice');
// Type: string

// Explicit type
const [user, setUser] = useState<User | null>(null);

// With interface
interface User {
  id: number;
  name: string;
  email: string;
}

const [users, setUsers] = useState<User[]>([]);
```

### State Initialization

```typescript
// Simple initialization
const [count, setCount] = useState(0);

// Lazy initialization (expensive computation)
const [data, setData] = useState(() => {
  const initialData = computeExpensiveValue();
  return initialData;
});

// ❌ BAD - Runs every render
const [data, setData] = useState(computeExpensiveValue());

// ✅ GOOD - Runs only once
const [data, setData] = useState(() => computeExpensiveValue());
```

## State Updates

### Functional Updates

```typescript
function Counter() {
  const [count, setCount] = useState(0);

  // ❌ BAD - May use stale state
  const handleIncrement = () => {
    setCount(count + 1);
    setCount(count + 1); // Only increments by 1!
  };

  // ✅ GOOD - Uses previous state
  const handleIncrement = () => {
    setCount(prev => prev + 1);
    setCount(prev => prev + 1); // Increments by 2
  };

  return <button onClick={handleIncrement}>Count: {count}</button>;
}
```

### Batching Updates

```typescript
function Form() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');

  const handleSubmit = () => {
    // React 18+: Automatic batching
    setName('Alice');
    setEmail('alice@example.com');
    // Only triggers ONE re-render
  };

  // Inside promises/callbacks - still batched in React 18+
  const handleAsync = async () => {
    const data = await fetchData();
    setName(data.name);
    setEmail(data.email);
    // Only ONE re-render
  };

  return (
    <form onSubmit={handleSubmit}>
      <input value={name} onChange={(e) => setName(e.target.value)} />
      <input value={email} onChange={(e) => setEmail(e.target.value)} />
    </form>
  );
}
```

## Object and Array State

### Objects

```typescript
interface User {
  name: string;
  email: string;
  age: number;
}

function UserProfile() {
  const [user, setUser] = useState<User>({
    name: 'Alice',
    email: 'alice@example.com',
    age: 30,
  });

  // ❌ BAD - Mutates state
  const updateName = (newName: string) => {
    user.name = newName; // Direct mutation!
    setUser(user);
  };

  // ✅ GOOD - Creates new object
  const updateName = (newName: string) => {
    setUser({ ...user, name: newName });
  };

  // ✅ GOOD - Functional update with spread
  const updateEmail = (newEmail: string) => {
    setUser(prev => ({ ...prev, email: newEmail }));
  };

  return (
    <div>
      <input value={user.name} onChange={(e) => updateName(e.target.value)} />
      <input value={user.email} onChange={(e) => updateEmail(e.target.value)} />
    </div>
  );
}
```

### Arrays

```typescript
function TodoList() {
  const [todos, setTodos] = useState<string[]>([]);

  // Add item
  const addTodo = (todo: string) => {
    setTodos(prev => [...prev, todo]);
  };

  // Remove item
  const removeTodo = (index: number) => {
    setTodos(prev => prev.filter((_, i) => i !== index));
  };

  // Update item
  const updateTodo = (index: number, newText: string) => {
    setTodos(prev =>
      prev.map((todo, i) => (i === index ? newText : todo))
    );
  };

  // ❌ BAD - Mutates array
  const badAdd = (todo: string) => {
    todos.push(todo); // Mutation!
    setTodos(todos);
  };

  return (
    <ul>
      {todos.map((todo, index) => (
        <li key={index}>
          {todo}
          <button onClick={() => removeTodo(index)}>Delete</button>
        </li>
      ))}
    </ul>
  );
}
```

### Nested State

```typescript
interface Address {
  street: string;
  city: string;
  country: string;
}

interface User {
  name: string;
  address: Address;
}

function UserForm() {
  const [user, setUser] = useState<User>({
    name: 'Alice',
    address: {
      street: '123 Main St',
      city: 'Boston',
      country: 'USA',
    },
  });

  // Update nested property
  const updateCity = (newCity: string) => {
    setUser(prev => ({
      ...prev,
      address: {
        ...prev.address,
        city: newCity,
      },
    }));
  };

  return (
    <input
      value={user.address.city}
      onChange={(e) => updateCity(e.target.value)}
    />
  );
}
```

## Derived State

```typescript
function ShoppingCart() {
  const [items, setItems] = useState<CartItem[]>([]);

  // ❌ BAD - Storing derived state
  const [total, setTotal] = useState(0);
  const [itemCount, setItemCount] = useState(0);

  // Need to keep in sync manually
  const addItem = (item: CartItem) => {
    setItems(prev => [...prev, item]);
    setTotal(prev => prev + item.price); // Easy to forget!
    setItemCount(prev => prev + 1);
  };

  // ✅ GOOD - Calculate derived values
  const total = items.reduce((sum, item) => sum + item.price, 0);
  const itemCount = items.length;

  return (
    <div>
      <p>Items: {itemCount}</p>
      <p>Total: ${total.toFixed(2)}</p>
    </div>
  );
}
```

## Lifting State Up

```typescript
// Shared state lives in parent component
function TemperatureConverter() {
  const [celsius, setCelsius] = useState(0);

  return (
    <div>
      <CelsiusInput value={celsius} onChange={setCelsius} />
      <FahrenheitInput value={celsius} onChange={setCelsius} />
      <BoilingVerdict celsius={celsius} />
    </div>
  );
}

function CelsiusInput({ value, onChange }: Props) {
  return (
    <input
      type="number"
      value={value}
      onChange={(e) => onChange(Number(e.target.value))}
    />
  );
}

function FahrenheitInput({ value, onChange }: Props) {
  const fahrenheit = value * 9 / 5 + 32;

  const handleChange = (f: number) => {
    const c = (f - 32) * 5 / 9;
    onChange(c);
  };

  return (
    <input
      type="number"
      value={fahrenheit}
      onChange={(e) => handleChange(Number(e.target.value))}
    />
  );
}

function BoilingVerdict({ celsius }: { celsius: number }) {
  if (celsius >= 100) {
    return <p>The water would boil.</p>;
  }
  return <p>The water would not boil.</p>;
}
```

## State Patterns

### Toggle State

```typescript
function ToggleButton() {
  const [isOn, setIsOn] = useState(false);

  // Simple toggle
  const toggle = () => setIsOn(!isOn);

  // Safer toggle (functional update)
  const safeToggle = () => setIsOn(prev => !prev);

  return (
    <button onClick={safeToggle}>
      {isOn ? 'ON' : 'OFF'}
    </button>
  );
}
```

### Form State

```typescript
interface FormData {
  username: string;
  email: string;
  password: string;
}

function SignupForm() {
  const [formData, setFormData] = useState<FormData>({
    username: '',
    email: '',
    password: '',
  });

  // Generic change handler
  const handleChange = (field: keyof FormData) => (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    setFormData(prev => ({
      ...prev,
      [field]: e.target.value,
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log(formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={formData.username}
        onChange={handleChange('username')}
        placeholder="Username"
      />
      <input
        value={formData.email}
        onChange={handleChange('email')}
        placeholder="Email"
      />
      <input
        type="password"
        value={formData.password}
        onChange={handleChange('password')}
        placeholder="Password"
      />
      <button type="submit">Sign Up</button>
    </form>
  );
}
```

### List State with CRUD Operations

```typescript
interface Todo {
  id: string;
  text: string;
  completed: boolean;
}

function TodoApp() {
  const [todos, setTodos] = useState<Todo[]>([]);

  // Create
  const addTodo = (text: string) => {
    const newTodo: Todo = {
      id: crypto.randomUUID(),
      text,
      completed: false,
    };
    setTodos(prev => [...prev, newTodo]);
  };

  // Read (derived)
  const activeTodos = todos.filter(t => !t.completed);
  const completedTodos = todos.filter(t => t.completed);

  // Update
  const toggleTodo = (id: string) => {
    setTodos(prev =>
      prev.map(todo =>
        todo.id === id
          ? { ...todo, completed: !todo.completed }
          : todo
      )
    );
  };

  // Delete
  const deleteTodo = (id: string) => {
    setTodos(prev => prev.filter(todo => todo.id !== id));
  };

  return (
    <div>
      <h2>Active: {activeTodos.length}</h2>
      <h2>Completed: {completedTodos.length}</h2>
      {todos.map(todo => (
        <TodoItem
          key={todo.id}
          todo={todo}
          onToggle={toggleTodo}
          onDelete={deleteTodo}
        />
      ))}
    </div>
  );
}
```

### Previous State Pattern

```typescript
function ValueTracker() {
  const [value, setValue] = useState(0);
  const [prevValue, setPrevValue] = useState<number | null>(null);

  const handleChange = (newValue: number) => {
    setPrevValue(value);
    setValue(newValue);
  };

  return (
    <div>
      <p>Current: {value}</p>
      <p>Previous: {prevValue ?? 'N/A'}</p>
      <button onClick={() => handleChange(value + 1)}>Increment</button>
    </div>
  );
}
```

## State Management Libraries

### When to Use External State Management

```typescript
// ✅ GOOD - Local state for simple components
function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}

// ✅ GOOD - Context for theme/auth (doesn't change often)
const ThemeContext = createContext<Theme>('light');

// ⚠️ CONSIDER - Zustand/Redux for complex state
// - Shared across many components
// - Frequent updates
// - Complex logic
import { create } from 'zustand';

interface Store {
  count: number;
  increment: () => void;
}

const useStore = create<Store>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}));
```

## AI Pair Programming Notes

**When working with React state:**

1. **Use functional updates**: When next state depends on previous state
2. **Don't mutate state**: Always create new objects/arrays
3. **Derive when possible**: Calculate values instead of storing duplicates
4. **Lift state up**: Share state between components via common parent
5. **Lazy initialization**: Use function for expensive initial state
6. **Batch updates**: React 18+ automatically batches in most cases
7. **Type your state**: Use TypeScript for type safety
8. **Avoid over-optimization**: Don't prematurely optimize state structure
9. **Consider external libraries**: For complex global state
10. **Keep state minimal**: Only store what can't be calculated

**Common state mistakes:**
- Mutating state directly instead of using setState
- Using stale state in closures (fix with functional updates)
- Storing derived state instead of calculating it
- Not lifting state up when needed
- Over-using global state for local concerns
- Missing keys in lists (causes re-render issues)
- Updating state during render (causes infinite loops)
- Not initializing state with proper types
- Forgetting functional updates in async operations
- Using index as key in dynamic lists

## Next Steps

1. **03-HOOKS.md** - useEffect and other React hooks
2. **05-CONTEXT.md** - Share state across component tree
3. **08-PERFORMANCE.md** - Optimize state updates and re-renders
4. **Zustand KB** - External state management library

## Additional Resources

- React Docs - State: https://react.dev/learn/state-a-components-memory
- useState Hook: https://react.dev/reference/react/useState
- Choosing State Structure: https://react.dev/learn/choosing-the-state-structure
- React 18 Automatic Batching: https://react.dev/blog/2022/03/08/react-18-upgrade-guide#automatic-batching
