# React Event Handling

```yaml
id: react_04_events
topic: React
file_role: Event handling, synthetic events, form events, keyboard/mouse events
profile: intermediate
difficulty_level: beginner
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - State (02-STATE.md)
related_topics:
  - Forms (07-FORMS.md)
  - Hooks (03-HOOKS.md)
  - Performance (08-PERFORMANCE.md)
embedding_keywords:
  - react events
  - event handlers
  - synthetic events
  - onClick
  - onChange
  - onSubmit
  - keyboard events
  - mouse events
  - event propagation
  - preventDefault
last_reviewed: 2025-11-16
```

## Event Handling Overview

React uses **synthetic events** - a cross-browser wrapper around native DOM events.

**Key Concepts:**
1. **Camel case**: Use `onClick` not `onclick`
2. **Pass function**: `onClick={handleClick}` not `onClick={handleClick()}`
3. **Synthetic events**: Normalized across browsers
4. **Event pooling**: Events are reused (nullified after callback)
5. **Prevent default**: Use `e.preventDefault()` not `return false`

## Click Events

### Basic Click Handler

```typescript
function Button() {
  const handleClick = () => {
    console.log('Button clicked');
  };

  return <button onClick={handleClick}>Click Me</button>;
}
```

### Inline Handler

```typescript
function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      {/* ❌ BAD - Creates new function every render */}
      <button onClick={() => setCount(count + 1)}>Increment</button>

      {/* ✅ GOOD for simple cases - functional update */}
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
    </div>
  );
}
```

### Passing Arguments

```typescript
function ItemList() {
  const [items, setItems] = useState(['Item 1', 'Item 2', 'Item 3']);

  const handleDelete = (index: number) => {
    setItems(prev => prev.filter((_, i) => i !== index));
  };

  return (
    <ul>
      {items.map((item, index) => (
        <li key={index}>
          {item}
          {/* Pass arguments with arrow function */}
          <button onClick={() => handleDelete(index)}>Delete</button>
        </li>
      ))}
    </ul>
  );
}
```

### Event Object

```typescript
function LinkButton() {
  const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    e.preventDefault(); // Prevent default behavior
    e.stopPropagation(); // Stop event bubbling

    console.log('Button clicked');
    console.log('Event type:', e.type);
    console.log('Current target:', e.currentTarget);
    console.log('Target:', e.target);
  };

  return <button onClick={handleClick}>Click Me</button>;
}
```

## Form Events

### Input Change

```typescript
function NameInput() {
  const [name, setName] = useState('');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setName(e.target.value);
  };

  return (
    <div>
      <input
        type="text"
        value={name}
        onChange={handleChange}
        placeholder="Enter name"
      />
      <p>Name: {name}</p>
    </div>
  );
}
```

### Form Submit

```typescript
interface FormData {
  username: string;
  email: string;
}

function LoginForm() {
  const [formData, setFormData] = useState<FormData>({
    username: '',
    email: '',
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault(); // Prevent page reload

    console.log('Form submitted:', formData);
    // Submit to API
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        name="username"
        value={formData.username}
        onChange={handleChange}
        placeholder="Username"
      />
      <input
        type="email"
        name="email"
        value={formData.email}
        onChange={handleChange}
        placeholder="Email"
      />
      <button type="submit">Submit</button>
    </form>
  );
}
```

### Controlled vs Uncontrolled

```typescript
// ✅ CONTROLLED - React controls the value
function ControlledInput() {
  const [value, setValue] = useState('');

  return (
    <input
      value={value}
      onChange={(e) => setValue(e.target.value)}
    />
  );
}

// ⚠️ UNCONTROLLED - DOM controls the value
function UncontrolledInput() {
  const inputRef = useRef<HTMLInputElement>(null);

  const handleSubmit = () => {
    console.log(inputRef.current?.value);
  };

  return (
    <div>
      <input ref={inputRef} defaultValue="Initial" />
      <button onClick={handleSubmit}>Submit</button>
    </div>
  );
}
```

## Keyboard Events

### Key Press Detection

```typescript
function SearchInput() {
  const [query, setQuery] = useState('');

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      console.log('Search for:', query);
      // Trigger search
    }

    if (e.key === 'Escape') {
      setQuery(''); // Clear input
    }
  };

  return (
    <input
      type="text"
      value={query}
      onChange={(e) => setQuery(e.target.value)}
      onKeyDown={handleKeyDown}
      placeholder="Press Enter to search"
    />
  );
}
```

### Keyboard Shortcuts

```typescript
function Editor() {
  const [content, setContent] = useState('');

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    // Ctrl+S or Cmd+S to save
    if ((e.ctrlKey || e.metaKey) && e.key === 's') {
      e.preventDefault();
      console.log('Saving...');
      // Save content
    }

    // Ctrl+B for bold
    if ((e.ctrlKey || e.metaKey) && e.key === 'b') {
      e.preventDefault();
      console.log('Toggle bold');
    }
  };

  return (
    <textarea
      value={content}
      onChange={(e) => setContent(e.target.value)}
      onKeyDown={handleKeyDown}
      placeholder="Type here (Ctrl+S to save)"
    />
  );
}
```

## Mouse Events

### Click, Double Click, Context Menu

```typescript
function InteractiveBox() {
  const handleClick = () => {
    console.log('Single click');
  };

  const handleDoubleClick = () => {
    console.log('Double click');
  };

  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault(); // Prevent default context menu
    console.log('Right click');
  };

  return (
    <div
      onClick={handleClick}
      onDoubleClick={handleDoubleClick}
      onContextMenu={handleContextMenu}
      style={{ width: 200, height: 200, background: 'lightblue' }}
    >
      Click me
    </div>
  );
}
```

### Mouse Position Tracking

```typescript
function MouseTracker() {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    setPosition({
      x: e.clientX,
      y: e.clientY,
    });
  };

  return (
    <div
      onMouseMove={handleMouseMove}
      style={{ width: '100%', height: '100vh' }}
    >
      <p>X: {position.x}, Y: {position.y}</p>
    </div>
  );
}
```

### Hover Events

```typescript
function HoverButton() {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <button
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      style={{
        background: isHovered ? 'blue' : 'gray',
        color: 'white',
      }}
    >
      {isHovered ? 'Hovered!' : 'Hover me'}
    </button>
  );
}
```

## Focus Events

### onFocus and onBlur

```typescript
function ValidatedInput() {
  const [value, setValue] = useState('');
  const [isFocused, setIsFocused] = useState(false);
  const [error, setError] = useState('');

  const handleFocus = () => {
    setIsFocused(true);
    setError('');
  };

  const handleBlur = () => {
    setIsFocused(false);

    // Validate on blur
    if (value.length < 3) {
      setError('Minimum 3 characters');
    }
  };

  return (
    <div>
      <input
        type="text"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        onFocus={handleFocus}
        onBlur={handleBlur}
        style={{ borderColor: error ? 'red' : isFocused ? 'blue' : 'gray' }}
      />
      {error && <span style={{ color: 'red' }}>{error}</span>}
    </div>
  );
}
```

## Event Propagation

### Event Bubbling

```typescript
function EventBubbling() {
  const handleParentClick = () => {
    console.log('Parent clicked');
  };

  const handleChildClick = (e: React.MouseEvent) => {
    console.log('Child clicked');
    // Click bubbles to parent unless stopped
  };

  const handleStopPropagation = (e: React.MouseEvent) => {
    e.stopPropagation(); // Stop event from bubbling
    console.log('Button clicked, not parent');
  };

  return (
    <div onClick={handleParentClick} style={{ padding: 20, background: 'lightgray' }}>
      Parent
      <div onClick={handleChildClick} style={{ padding: 20, background: 'lightblue' }}>
        Child (bubbles to parent)
      </div>
      <button onClick={handleStopPropagation}>
        Button (doesn't bubble)
      </button>
    </div>
  );
}
```

### Event Capturing

```typescript
function EventCapturing() {
  const handleCapturePhase = () => {
    console.log('Capture phase');
  };

  const handleBubblePhase = () => {
    console.log('Bubble phase');
  };

  return (
    <div onClickCapture={handleCapturePhase}>
      <button onClick={handleBubblePhase}>
        Click me
      </button>
    </div>
  );
}
// Logs: "Capture phase" then "Bubble phase"
```

## Checkbox and Radio Events

### Checkbox

```typescript
function TodoItem() {
  const [completed, setCompleted] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setCompleted(e.target.checked);
  };

  return (
    <label>
      <input
        type="checkbox"
        checked={completed}
        onChange={handleChange}
      />
      Task (completed: {completed ? 'Yes' : 'No'})
    </label>
  );
}
```

### Radio Buttons

```typescript
function RadioGroup() {
  const [selected, setSelected] = useState('option1');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSelected(e.target.value);
  };

  return (
    <div>
      <label>
        <input
          type="radio"
          value="option1"
          checked={selected === 'option1'}
          onChange={handleChange}
        />
        Option 1
      </label>
      <label>
        <input
          type="radio"
          value="option2"
          checked={selected === 'option2'}
          onChange={handleChange}
        />
        Option 2
      </label>
      <p>Selected: {selected}</p>
    </div>
  );
}
```

## Select Dropdown

### Single Select

```typescript
function CountrySelect() {
  const [country, setCountry] = useState('usa');

  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setCountry(e.target.value);
  };

  return (
    <select value={country} onChange={handleChange}>
      <option value="usa">USA</option>
      <option value="canada">Canada</option>
      <option value="mexico">Mexico</option>
    </select>
  );
}
```

### Multiple Select

```typescript
function MultiSelect() {
  const [selected, setSelected] = useState<string[]>([]);

  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const options = Array.from(e.target.selectedOptions);
    const values = options.map(option => option.value);
    setSelected(values);
  };

  return (
    <select multiple value={selected} onChange={handleChange}>
      <option value="option1">Option 1</option>
      <option value="option2">Option 2</option>
      <option value="option3">Option 3</option>
    </select>
  );
}
```

## File Upload

### File Input

```typescript
function FileUpload() {
  const [file, setFile] = useState<File | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files && files.length > 0) {
      setFile(files[0]);
    }
  };

  const handleSubmit = async () => {
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);

    // Upload to server
    await fetch('/api/upload', {
      method: 'POST',
      body: formData,
    });
  };

  return (
    <div>
      <input type="file" onChange={handleChange} />
      {file && <p>Selected: {file.name}</p>}
      <button onClick={handleSubmit} disabled={!file}>
        Upload
      </button>
    </div>
  );
}
```

## Drag and Drop

### Basic Drag and Drop

```typescript
function DragAndDrop() {
  const [isDragging, setIsDragging] = useState(false);

  const handleDragEnter = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault(); // Required to allow drop
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);

    const files = Array.from(e.dataTransfer.files);
    console.log('Dropped files:', files);
  };

  return (
    <div
      onDragEnter={handleDragEnter}
      onDragLeave={handleDragLeave}
      onDragOver={handleDragOver}
      onDrop={handleDrop}
      style={{
        width: 300,
        height: 200,
        border: `2px dashed ${isDragging ? 'blue' : 'gray'}`,
        background: isDragging ? 'lightblue' : 'white',
      }}
    >
      Drop files here
    </div>
  );
}
```

## Event Patterns

### Debounced Input

```typescript
function DebouncedSearch() {
  const [query, setQuery] = useState('');
  const [debouncedQuery, setDebouncedQuery] = useState('');

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedQuery(query);
    }, 500);

    return () => clearTimeout(timer);
  }, [query]);

  useEffect(() => {
    if (debouncedQuery) {
      console.log('Search for:', debouncedQuery);
      // API call
    }
  }, [debouncedQuery]);

  return (
    <input
      type="text"
      value={query}
      onChange={(e) => setQuery(e.target.value)}
      placeholder="Search (debounced)"
    />
  );
}
```

### Throttled Scroll

```typescript
function ScrollTracker() {
  const [scrollY, setScrollY] = useState(0);
  const lastUpdate = useRef(0);

  useEffect(() => {
    const handleScroll = () => {
      const now = Date.now();
      if (now - lastUpdate.current >= 100) { // Throttle to 100ms
        setScrollY(window.scrollY);
        lastUpdate.current = now;
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return <div>Scroll Y: {scrollY}</div>;
}
```

## AI Pair Programming Notes

**When handling React events:**

1. **Use camelCase**: onClick, onChange, onSubmit (not onclick)
2. **Pass function reference**: onClick={handleClick} not onClick={handleClick()}
3. **Type events properly**: Use React.MouseEvent, React.ChangeEvent, etc.
4. **Prevent default**: Use e.preventDefault() for forms, links
5. **Stop propagation**: Use e.stopPropagation() when needed
6. **Controlled components**: Prefer controlled over uncontrolled
7. **Extract handlers**: Move complex logic out of JSX
8. **Cleanup listeners**: Remove event listeners in useEffect cleanup
9. **Debounce/throttle**: For expensive operations (search, scroll)
10. **Accessibility**: Add keyboard handlers for mouse interactions

**Common event mistakes:**
- Calling handler instead of passing reference: onClick={handleClick()}
- Not preventing default on form submit
- Missing event types in TypeScript
- Not cleaning up global event listeners
- Using index as key with event handlers
- Not stopping propagation when needed
- Forgetting checked property for checkboxes
- Not handling null/undefined in file inputs
- Missing onChange with value prop (controlled inputs)
- Creating new functions every render (performance)

## Next Steps

1. **07-FORMS.md** - Advanced form patterns and validation
2. **08-PERFORMANCE.md** - Optimizing event handlers
3. **10-TESTING.md** - Testing components with events

## Additional Resources

- React Events: https://react.dev/learn/responding-to-events
- Synthetic Events: https://react.dev/reference/react-dom/components/common#react-event-object
- Form Events: https://react.dev/reference/react-dom/components/input
- Event Handler Naming: https://react.dev/learn/responding-to-events#naming-event-handler-props
