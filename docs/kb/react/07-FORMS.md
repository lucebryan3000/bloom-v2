# React Forms

```yaml
id: react_07_forms
topic: React
file_role: Form handling, validation, controlled inputs, form libraries
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - State (02-STATE.md)
  - Events (04-EVENTS.md)
related_topics:
  - Hooks (03-HOOKS.md)
  - Patterns (06-PATTERNS.md)
  - Zod (../zod/)
embedding_keywords:
  - react forms
  - form validation
  - controlled inputs
  - form state
  - react hook form
  - form handling
  - input validation
  - form submission
last_reviewed: 2025-11-16
```

## Forms Overview

**Key Concepts:**
1. **Controlled components** - React controls input value
2. **Uncontrolled components** - DOM controls input value
3. **Form validation** - Client-side and server-side
4. **Form submission** - Handling submit events
5. **Form libraries** - React Hook Form, Formik

## Basic Controlled Form

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

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
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
      <input
        type="password"
        name="password"
        value={formData.password}
        onChange={handleChange}
        placeholder="Password"
      />
      <button type="submit">Sign Up</button>
    </form>
  );
}
```

## Form Validation

### Basic Validation

```typescript
interface FormErrors {
  username?: string;
  email?: string;
  password?: string;
}

function ValidatedForm() {
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
  });
  const [errors, setErrors] = useState<FormErrors>({});
  const [touched, setTouched] = useState<Record<string, boolean>>({});

  const validate = (): boolean => {
    const newErrors: FormErrors = {};

    if (!formData.username) {
      newErrors.username = 'Username is required';
    } else if (formData.username.length < 3) {
      newErrors.username = 'Username must be at least 3 characters';
    }

    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Email is invalid';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 6) {
      newErrors.password = 'Password must be at least 6 characters';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));

    // Clear error when user starts typing
    if (errors[name as keyof FormErrors]) {
      setErrors(prev => ({ ...prev, [name]: undefined }));
    }
  };

  const handleBlur = (e: React.FocusEvent<HTMLInputElement>) => {
    const { name } = e.target;
    setTouched(prev => ({ ...prev, [name]: true }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Mark all fields as touched
    setTouched({
      username: true,
      email: true,
      password: true,
    });

    if (validate()) {
      console.log('Form is valid:', formData);
      // Submit to API
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <input
          type="text"
          name="username"
          value={formData.username}
          onChange={handleChange}
          onBlur={handleBlur}
          placeholder="Username"
        />
        {touched.username && errors.username && (
          <span className="error">{errors.username}</span>
        )}
      </div>

      <div>
        <input
          type="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          onBlur={handleBlur}
          placeholder="Email"
        />
        {touched.email && errors.email && (
          <span className="error">{errors.email}</span>
        )}
      </div>

      <div>
        <input
          type="password"
          name="password"
          value={formData.password}
          onChange={handleChange}
          onBlur={handleBlur}
          placeholder="Password"
        />
        {touched.password && errors.password && (
          <span className="error">{errors.password}</span>
        )}
      </div>

      <button type="submit">Sign Up</button>
    </form>
  );
}
```

### Validation with Zod

```typescript
import { z } from 'zod';

const signupSchema = z.object({
  username: z.string().min(3, 'Username must be at least 3 characters'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});

type SignupFormData = z.infer<typeof signupSchema>;

function ZodValidatedForm() {
  const [formData, setFormData] = useState<SignupFormData>({
    username: '',
    email: '',
    password: '',
  });
  const [errors, setErrors] = useState<Partial<Record<keyof SignupFormData, string>>>({});

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    try {
      const validData = signupSchema.parse(formData);
      console.log('Valid data:', validData);
      setErrors({});
      // Submit to API
    } catch (error) {
      if (error instanceof z.ZodError) {
        const fieldErrors: Partial<Record<keyof SignupFormData, string>> = {};
        error.errors.forEach((err) => {
          const field = err.path[0] as keyof SignupFormData;
          fieldErrors[field] = err.message;
        });
        setErrors(fieldErrors);
      }
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <input name="username" value={formData.username} onChange={handleChange} />
        {errors.username && <span>{errors.username}</span>}
      </div>
      <div>
        <input name="email" value={formData.email} onChange={handleChange} />
        {errors.email && <span>{errors.email}</span>}
      </div>
      <div>
        <input type="password" name="password" value={formData.password} onChange={handleChange} />
        {errors.password && <span>{errors.password}</span>}
      </div>
      <button type="submit">Sign Up</button>
    </form>
  );
}
```

## React Hook Form

### Basic Usage

```typescript
import { useForm } from 'react-hook-form';

interface FormInputs {
  username: string;
  email: string;
  password: string;
}

function HookForm() {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormInputs>();

  const onSubmit = (data: FormInputs) => {
    console.log('Form data:', data);
    // Submit to API
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <input
          {...register('username', {
            required: 'Username is required',
            minLength: {
              value: 3,
              message: 'Username must be at least 3 characters',
            },
          })}
          placeholder="Username"
        />
        {errors.username && <span>{errors.username.message}</span>}
      </div>

      <div>
        <input
          {...register('email', {
            required: 'Email is required',
            pattern: {
              value: /\S+@\S+\.\S+/,
              message: 'Invalid email address',
            },
          })}
          placeholder="Email"
        />
        {errors.email && <span>{errors.email.message}</span>}
      </div>

      <div>
        <input
          type="password"
          {...register('password', {
            required: 'Password is required',
            minLength: {
              value: 6,
              message: 'Password must be at least 6 characters',
            },
          })}
          placeholder="Password"
        />
        {errors.password && <span>{errors.password.message}</span>}
      </div>

      <button type="submit">Sign Up</button>
    </form>
  );
}
```

### React Hook Form with Zod

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  username: z.string().min(3, 'Username must be at least 3 characters'),
  email: z.string().email('Invalid email'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});

type FormData = z.infer<typeof schema>;

function HookFormWithZod() {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const onSubmit = (data: FormData) => {
    console.log('Valid data:', data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <input {...register('username')} />
        {errors.username && <span>{errors.username.message}</span>}
      </div>
      <div>
        <input {...register('email')} />
        {errors.email && <span>{errors.email.message}</span>}
      </div>
      <div>
        <input type="password" {...register('password')} />
        {errors.password && <span>{errors.password.message}</span>}
      </div>
      <button type="submit">Submit</button>
    </form>
  );
}
```

## Form Input Types

### Checkbox

```typescript
function CheckboxForm() {
  const [agreed, setAgreed] = useState(false);

  return (
    <form>
      <label>
        <input
          type="checkbox"
          checked={agreed}
          onChange={(e) => setAgreed(e.target.checked)}
        />
        I agree to terms and conditions
      </label>
    </form>
  );
}
```

### Radio Buttons

```typescript
function RadioForm() {
  const [plan, setPlan] = useState('free');

  return (
    <form>
      <label>
        <input
          type="radio"
          value="free"
          checked={plan === 'free'}
          onChange={(e) => setPlan(e.target.value)}
        />
        Free
      </label>
      <label>
        <input
          type="radio"
          value="pro"
          checked={plan === 'pro'}
          onChange={(e) => setPlan(e.target.value)}
        />
        Pro
      </label>
    </form>
  );
}
```

### Select Dropdown

```typescript
function SelectForm() {
  const [country, setCountry] = useState('usa');

  return (
    <form>
      <select value={country} onChange={(e) => setCountry(e.target.value)}>
        <option value="usa">United States</option>
        <option value="canada">Canada</option>
        <option value="uk">United Kingdom</option>
      </select>
    </form>
  );
}
```

### Textarea

```typescript
function TextareaForm() {
  const [bio, setBio] = useState('');

  return (
    <form>
      <textarea
        value={bio}
        onChange={(e) => setBio(e.target.value)}
        placeholder="Tell us about yourself"
        rows={5}
      />
    </form>
  );
}
```

### File Upload

```typescript
function FileUploadForm() {
  const [file, setFile] = useState<File | null>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files && files.length > 0) {
      setFile(files[0]);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);

    const response = await fetch('/api/upload', {
      method: 'POST',
      body: formData,
    });

    console.log('Upload response:', await response.json());
  };

  return (
    <form onSubmit={handleSubmit}>
      <input type="file" onChange={handleFileChange} accept="image/*" />
      {file && <p>Selected: {file.name}</p>}
      <button type="submit" disabled={!file}>Upload</button>
    </form>
  );
}
```

## Multi-Step Forms

```typescript
function MultiStepForm() {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    // Step 1
    username: '',
    email: '',
    // Step 2
    firstName: '',
    lastName: '',
    // Step 3
    address: '',
    city: '',
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value,
    }));
  };

  const nextStep = () => setStep(prev => prev + 1);
  const prevStep = () => setStep(prev => prev - 1);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log('Final data:', formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      {step === 1 && (
        <div>
          <h2>Step 1: Account</h2>
          <input name="username" value={formData.username} onChange={handleChange} />
          <input name="email" value={formData.email} onChange={handleChange} />
          <button type="button" onClick={nextStep}>Next</button>
        </div>
      )}

      {step === 2 && (
        <div>
          <h2>Step 2: Personal Info</h2>
          <input name="firstName" value={formData.firstName} onChange={handleChange} />
          <input name="lastName" value={formData.lastName} onChange={handleChange} />
          <button type="button" onClick={prevStep}>Back</button>
          <button type="button" onClick={nextStep}>Next</button>
        </div>
      )}

      {step === 3 && (
        <div>
          <h2>Step 3: Address</h2>
          <input name="address" value={formData.address} onChange={handleChange} />
          <input name="city" value={formData.city} onChange={handleChange} />
          <button type="button" onClick={prevStep}>Back</button>
          <button type="submit">Submit</button>
        </div>
      )}
    </form>
  );
}
```

## Form Submission States

```typescript
function AsyncForm() {
  const [formData, setFormData] = useState({ email: '', message: '' });
  const [status, setStatus] = useState<'idle' | 'submitting' | 'success' | 'error'>('idle');
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus('submitting');
    setError(null);

    try {
      const response = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });

      if (!response.ok) {
        throw new Error('Submission failed');
      }

      setStatus('success');
      setFormData({ email: '', message: '' });
    } catch (err) {
      setStatus('error');
      setError(err instanceof Error ? err.message : 'Unknown error');
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={formData.email}
        onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
        disabled={status === 'submitting'}
      />
      <textarea
        value={formData.message}
        onChange={(e) => setFormData(prev => ({ ...prev, message: e.target.value }))}
        disabled={status === 'submitting'}
      />

      <button type="submit" disabled={status === 'submitting'}>
        {status === 'submitting' ? 'Sending...' : 'Send'}
      </button>

      {status === 'success' && <p>Message sent successfully!</p>}
      {status === 'error' && <p>Error: {error}</p>}
    </form>
  );
}
```

## AI Pair Programming Notes

**When building React forms:**

1. **Controlled components**: Always use controlled inputs for predictability
2. **Validation**: Validate on blur and submit, not on every keystroke
3. **Error handling**: Show errors only for touched fields
4. **Form libraries**: Use React Hook Form for complex forms
5. **Schema validation**: Use Zod for type-safe validation
6. **Accessibility**: Label inputs, provide error messages
7. **Submit state**: Handle loading, success, error states
8. **Reset forms**: Clear form after successful submission
9. **Prevent default**: Always `e.preventDefault()` on submit
10. **TypeScript**: Type form data and errors

**Common form mistakes:**
- Not preventing default on form submit
- Validating on every keystroke (annoying UX)
- Showing errors before user touches field
- Not handling submission states (loading, error)
- Missing labels for accessibility
- Not resetting form after success
- Using uncontrolled components without good reason
- Not typing form data in TypeScript
- Missing error handling for API failures
- Not disabling submit button during submission

## Next Steps

1. **08-PERFORMANCE.md** - Optimizing form performance
2. **10-TESTING.md** - Testing forms
3. **Zod KB** - Schema validation library

## Additional Resources

- React Forms: https://react.dev/reference/react-dom/components/input
- React Hook Form: https://react-hook-form.com/
- Zod: https://zod.dev/
- Form Validation: https://react.dev/learn/reacting-to-input-with-state
