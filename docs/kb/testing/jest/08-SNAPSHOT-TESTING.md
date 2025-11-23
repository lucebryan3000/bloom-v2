---
id: jest-08-snapshot-testing
topic: jest
file_role: advanced
profile: full
difficulty_level: intermediate-to-advanced
kb_version: 3.1
prerequisites: [jest-01-fundamentals, jest-02-matchers-assertions]
related_topics: [snapshot-testing, regression-testing, component-testing]
embedding_keywords: [jest, snapshot-testing, toMatchSnapshot, toMatchInlineSnapshot, regression-testing, property-matchers, snapshot-update]
last_reviewed: 2025-11-14
---

# Snapshot Testing with Jest

<!-- Query: "How do I use Jest snapshot testing?" -->
<!-- Query: "When should I use toMatchSnapshot?" -->
<!-- Query: "Best practices for snapshot testing" -->

## 1. Purpose

This file covers Jest's snapshot testing feature with a **conservative, pragmatic approach**. Learn:

- **What snapshot testing is** and how it works under the hood
- **When to use snapshots** (component structure, API responses, data structures)
- **When NOT to use snapshots** (and what to use instead)
- **How to update snapshots** safely with `--updateSnapshot`
- **Property matchers** for handling dynamic values (timestamps, IDs)
- **Bloom-specific examples**: ROI report structures, configuration objects
- **Common pitfalls** and how to avoid brittle snapshot tests

**Critical Philosophy**: Snapshots are NOT a replacement for thoughtful assertions. They're a **regression detection tool** for complex outputs where manual assertions would be verbose and unmaintainable.

---

## 2. Mental Model / Problem Statement

<!-- Query: "What is snapshot testing and how does it work?" -->
<!-- Query: "Snapshot testing philosophy and best practices" -->

### 2.1 What is Snapshot Testing?

**Snapshot testing** captures the output of a function or component and saves it to a file. On subsequent test runs, Jest compares the new output against the saved snapshot and fails if they differ.

**The Workflow:**

1. **First run**: Jest creates a snapshot file in `__snapshots__/` directory
2. **Subsequent runs**: Jest compares current output to saved snapshot
3. **On mismatch**: Test fails, and you must decide:
   - Is the change intentional? → Update the snapshot
   - Is the change a bug? → Fix the code

**Snapshot File Example:**

```typescript
// Button.test.tsx
test('renders primary button', () => {
  const { container } = render(<Button variant="primary">Click Me</Button>);
  expect(container.firstChild).toMatchSnapshot();
});
```

**Generated Snapshot File** (`__snapshots__/Button.test.tsx.snap`):

```javascript
exports[`renders primary button 1`] = `
<button
  class="btn-primary"
  type="button"
>
  Click Me
</button>
`;
```

### 2.2 How Snapshots Work Under the Hood

When you call `expect(value).toMatchSnapshot()`:

1. Jest serializes the value to a string representation
2. Computes a hash of the serialized value
3. Compares hash against stored snapshot
4. If mismatch: Shows diff and fails test
5. If `--updateSnapshot` flag: Overwrites old snapshot with new one

**Key Insight**: Snapshots are **plain text files** committed to version control. This means:
- Code reviewers can see snapshot changes in diffs
- Snapshots evolve with your codebase
- Bad snapshots = bad tests (garbage in, garbage out)

### 2.3 The Two Snapshot Approaches

**Approach 1: External Snapshots** (`toMatchSnapshot()`)

```typescript
test('renders complex component', () => {
  const output = renderComponent();
  expect(output).toMatchSnapshot();
});
```

**Pros:**
- Good for large outputs (100+ lines)
- Keeps test files clean
- Single snapshot file per test file

**Cons:**
- Snapshot is in separate file (less obvious what's being tested)
- Harder to review in isolation

**Approach 2: Inline Snapshots** (`toMatchInlineSnapshot()`)

```typescript
test('formats user name', () => {
  expect(formatName('john', 'doe')).toMatchInlineSnapshot(`"John Doe"`);
});
```

**Pros:**
- Snapshot embedded in test file (more readable)
- Obvious what's being tested
- Better for code review

**Cons:**
- Can clutter test files with large snapshots
- Harder to diff changes visually

**Bloom Guideline**: Use inline snapshots for small outputs (< 20 lines), external snapshots for larger structures.

### 2.4 When Snapshots Make Sense

✅ **Good Use Cases:**

1. **Component structure regression** (catch unintended DOM changes)
2. **API response contracts** (detect breaking changes in API shape)
3. **Configuration objects** (ensure settings don't drift)
4. **Complex data structures** (where manual assertions would be 50+ lines)
5. **Code generation output** (CLI tools, template generators)

❌ **Bad Use Cases:**

1. **Dynamic data** (timestamps, UUIDs, random values) → Use property matchers
2. **Simple values** (strings, numbers) → Use explicit assertions like `toBe()`
3. **Business logic** (calculations, transformations) → Use specific assertions
4. **Behavior testing** (user interactions, state changes) → Use behavioral assertions
5. **Anything that changes frequently** → Snapshots will thrash, becoming noise

### 2.5 The Snapshot Problem: Blind Approval

**Critical Warning**: Snapshots are ONLY as good as their initial creation and updates.

**The Danger:**

```bash
# Test fails after code change
npm test

# Developer sees massive diff, doesn't review carefully
npm test -- --updateSnapshot

# Bad snapshot committed to repo
git commit -m "Update snapshots"
```

**This is how bugs slip through**. A snapshot test that passes with a broken snapshot is worse than no test at all—it gives false confidence.

**Solution**: ALWAYS review snapshot diffs carefully before updating. Ask:
- Does this change make sense?
- Is the new snapshot correct?
- Should I add explicit assertions instead?

---

## 3. Golden Path

<!-- Query: "Recommended approach for Jest snapshot testing" -->
<!-- Query: "Best practices for snapshot testing in Jest" -->

### 3.1 Basic Snapshot Testing

**Simple Value Snapshot:**

```typescript
import { generateConfig } from '@/lib/config/generator';

test('generates default configuration', () => {
  const config = generateConfig();
  expect(config).toMatchInlineSnapshot(`
    {
      "appName": "Bloom",
      "version": "1.0.0",
      "environment": "production",
      "features": {
        "aiEnabled": true,
        "exportFormats": ["pdf", "excel", "json"]
      }
    }
  `);
});
```

**Component Snapshot:**

```typescript
import { render } from '@testing-library/react';
import { Badge } from '@/components/ui/badge';

test('renders success badge', () => {
  const { container } = render(<Badge variant="success">Active</Badge>);
  expect(container.firstChild).toMatchSnapshot();
});
```

### 3.2 Property Matchers for Dynamic Values

Use **property matchers** when snapshots contain dynamic values:

```typescript
test('creates session with dynamic ID and timestamp', () => {
  const session = createSession({ userId: 'test-user' });

  expect(session).toMatchSnapshot({
    id: expect.any(String),              // Matches any string
    createdAt: expect.any(Date),         // Matches any Date
    userId: expect.stringMatching(/^test-/), // Matches pattern
  });
});
```

**Generated Snapshot:**

```javascript
exports[`creates session with dynamic ID and timestamp 1`] = `
{
  "id": Any<String>,
  "createdAt": Any<Date>,
  "userId": StringMatching /^test-/,
  "status": "active",
  "responseCount": 0
}
`;
```

**Common Property Matchers:**

```typescript
expect.any(Number)               // Any number
expect.any(String)               // Any string
expect.any(Date)                 // Any Date object
expect.any(Array)                // Any array
expect.any(Object)               // Any object
expect.stringMatching(/regex/)   // String matching regex
expect.stringContaining('text')  // String containing substring
expect.arrayContaining([1, 2])   // Array containing elements
expect.objectContaining({ a: 1 }) // Object with subset of properties
```

### 3.3 Updating Snapshots Safely

**Interactive Update** (Recommended):

```bash
# Run tests in watch mode
npm test -- --watch

# When snapshot fails:
# - Press 'i' to inspect diff
# - Press 'u' to update failing snapshot
# - Press 'a' to update all snapshots
```

**Command Line Update:**

```bash
# Update all snapshots
npm test -- --updateSnapshot

# Update snapshots for specific file
npm test Button.test.tsx --updateSnapshot

# Short form
npm test -- -u
```

**Best Practice Workflow:**

1. Test fails with snapshot mismatch
2. Review the diff carefully:
   ```
   - Expected
   + Received

   - <button class="btn-primary">
   + <button class="btn-secondary">
   ```
3. Verify the change is intentional
4. Update snapshot: `npm test -- -u`
5. Review the snapshot file diff in version control
6. Commit with clear message: `"Update Button snapshot: changed variant prop"`

**⚠️ NEVER blindly run `-u` without reviewing diffs first.**

### 3.4 Snapshot Naming and Organization

**Default Naming:**

Jest names snapshots based on test hierarchy:

```typescript
describe('Button component', () => {
  describe('variants', () => {
    test('renders primary variant', () => {
      expect(button).toMatchSnapshot();
      // Snapshot name: "Button component variants renders primary variant 1"
    });
  });
});
```

**Custom Snapshot Names:**

```typescript
test('renders button variants', () => {
  const primary = <Button variant="primary">Click</Button>;
  const secondary = <Button variant="secondary">Cancel</Button>;

  expect(primary).toMatchSnapshot('primary variant');
  expect(secondary).toMatchSnapshot('secondary variant');
});
```

**Generated Snapshots:**

```javascript
exports[`renders button variants primary variant 1`] = `...`;
exports[`renders button variants secondary variant 1`] = `...`;
```

### 3.5 Snapshot File Location

Jest automatically creates `__snapshots__/` directories next to test files:

```
components/
├── Button/
│   ├── Button.tsx
│   ├── Button.test.tsx
│   └── __snapshots__/
│       └── Button.test.tsx.snap
```

**Important**: Always commit `__snapshots__/` directories to version control.

### 3.6 Snapshot Size Guidelines

**Small Snapshots (< 20 lines)**: Use `toMatchInlineSnapshot()`

```typescript
test('formats currency', () => {
  expect(formatCurrency(1234.56)).toMatchInlineSnapshot(`"$1,234.56"`);
});
```

**Medium Snapshots (20-100 lines)**: Use `toMatchSnapshot()` with descriptive names

```typescript
test('renders session summary card', () => {
  const { container } = render(<SessionSummaryCard session={mockSession} />);
  expect(container).toMatchSnapshot('session summary card');
});
```

**Large Snapshots (100+ lines)**: Consider alternatives

```typescript
// ❌ AVOID: 500-line component snapshot
expect(massiveComponent).toMatchSnapshot();

// ✅ BETTER: Test specific behaviors
expect(screen.getByText('Session Active')).toBeInTheDocument();
expect(screen.getByRole('button', { name: 'Export' })).toBeEnabled();
```

**Bloom Guideline**: If snapshot > 100 lines, ask "Should I test this differently?"

---

## 4. Variations & Trade-Offs

<!-- Query: "When to use toMatchSnapshot vs explicit assertions" -->
<!-- Query: "Snapshot testing trade-offs and alternatives" -->

### 4.1 Snapshot vs. Explicit Assertions

**Scenario: Simple Value**

```typescript
// ❌ OVERKILL: Snapshot for simple value
expect(sum(2, 3)).toMatchInlineSnapshot(`5`);

// ✅ BETTER: Explicit assertion
expect(sum(2, 3)).toBe(5);
```

**Trade-Off**: Snapshots add noise for simple values. Use explicit assertions.

---

**Scenario: Complex Object**

```typescript
// ❌ VERBOSE: Manual assertions for complex object
const result = calculateROI(inputs);
expect(result.annualSavings).toBe(156000);
expect(result.totalROI).toBeCloseTo(636, 0);
expect(result.paybackPeriod).toBeCloseTo(3.85, 2);
expect(result.confidenceScore).toBe(100);
expect(result.breakdown.labor).toBe(130000);
expect(result.breakdown.overhead).toBe(26000);
// ... 20 more assertions

// ✅ CLEANER: Snapshot with property matchers
expect(result).toMatchSnapshot({
  id: expect.any(String),
  createdAt: expect.any(Date),
});
```

**Trade-Off**: Snapshots are more maintainable for complex structures.

---

### 4.2 External vs. Inline Snapshots

**External Snapshots** (`toMatchSnapshot()`):

```typescript
test('renders ROI report', () => {
  const report = generateROIReport(session);
  expect(report).toMatchSnapshot();
});
```

**Pros:**
- Keeps test files clean
- Good for large outputs
- One snapshot file per test file

**Cons:**
- Harder to review (separate file)
- Less obvious what's being tested

---

**Inline Snapshots** (`toMatchInlineSnapshot()`):

```typescript
test('formats percentage', () => {
  expect(formatPercentage(0.6234)).toMatchInlineSnapshot(`"62.34%"`);
});
```

**Pros:**
- Self-documenting (snapshot visible in test)
- Easier code review
- No separate file to manage

**Cons:**
- Can clutter test files
- Harder to diff large snapshots

**Bloom Guideline**: Use inline for < 20 lines, external for larger snapshots.

---

### 4.3 Full Snapshots vs. Partial Snapshots

**Full Component Snapshot:**

```typescript
test('renders session card', () => {
  const { container } = render(<SessionCard session={mockSession} />);
  expect(container).toMatchSnapshot();
});
```

**Pros**: Catches all structural changes
**Cons**: Brittle, breaks often on minor changes

---

**Partial Snapshot (Specific Elements):**

```typescript
test('renders session card title and status', () => {
  const { getByTestId } = render(<SessionCard session={mockSession} />);
  expect(getByTestId('session-title')).toMatchInlineSnapshot(`
    <h3 data-testid="session-title">
      Workshop Session
    </h3>
  `);
});
```

**Pros**: More focused, less brittle
**Cons**: Misses changes outside tested elements

**Trade-Off**: Full snapshots catch more, but create maintenance burden. Use partial snapshots for critical elements.

---

### 4.4 Snapshot Testing for APIs

**API Response Snapshot:**

```typescript
test('GET /api/sessions returns session list', async () => {
  const response = await fetch('/api/sessions');
  const data = await response.json();

  expect(data).toMatchSnapshot({
    sessions: [
      {
        id: expect.any(String),
        createdAt: expect.any(String),
        updatedAt: expect.any(String),
      }
    ],
    meta: {
      timestamp: expect.any(String),
    }
  });
});
```

**Pros**: Detects breaking API changes
**Cons**: Can be noisy if API evolves frequently

**Alternative: JSON Schema Validation**

```typescript
import Ajv from 'ajv';

test('GET /api/sessions matches schema', async () => {
  const response = await fetch('/api/sessions');
  const data = await response.json();

  const schema = {
    type: 'object',
    properties: {
      sessions: { type: 'array' },
      meta: { type: 'object' }
    },
    required: ['sessions', 'meta']
  };

  const ajv = new Ajv();
  const validate = ajv.compile(schema);
  expect(validate(data)).toBe(true);
});
```

**Trade-Off**: Snapshots are simpler, schemas are more precise about structure.

---

## 5. Examples

<!-- Query: "Jest snapshot testing examples" -->
<!-- Query: "Real-world snapshot testing examples" -->

### Example 1 – Pedagogical: Basic Inline Snapshot

**Scenario**: Learn the fundamentals with a simple function snapshot.

```typescript
// lib/utils/format.ts
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(amount);
}

// __tests__/lib/utils/format.test.ts
import { formatCurrency } from '@/lib/utils/format';

describe('formatCurrency()', () => {
  test('formats positive amounts', () => {
    expect(formatCurrency(1234.56)).toMatchInlineSnapshot(`"$1,234.56"`);
  });

  test('formats zero', () => {
    expect(formatCurrency(0)).toMatchInlineSnapshot(`"$0.00"`);
  });

  test('formats negative amounts', () => {
    expect(formatCurrency(-500)).toMatchInlineSnapshot(`"-$500.00"`);
  });

  test('formats large amounts with commas', () => {
    expect(formatCurrency(1000000)).toMatchInlineSnapshot(`"$1,000,000.00"`);
  });
});
```

**Learning Points:**
1. Inline snapshots keep test and expectation together
2. Multiple snapshots in one test file
3. Jest automatically fills in the snapshot value on first run
4. Good for testing formatting functions with predictable output

**First Run Behavior:**

```bash
# First run: Jest creates inline snapshots
npm test format.test.ts

# Output:
✓ formats positive amounts
  Snapshot written.
```

Jest automatically inserts the snapshot value into your test file.

---

### Example 2 – Realistic Synthetic: ROI Report Structure

**Scenario**: Test a complex ROI report object with dynamic and static fields.

```typescript
// lib/reports/roi-generator.ts
export interface ROIReport {
  id: string;
  sessionId: string;
  createdAt: Date;
  metrics: {
    annualSavings: number;
    totalROI: number;
    paybackPeriod: number;
    confidenceScore: number;
  };
  inputs: {
    weeklyHours: number;
    teamSize: number;
    hourlyRate: number;
    automationPercentage: number;
  };
  breakdown: {
    labor: number;
    overhead: number;
    implementation: number;
  };
  recommendations: string[];
}

export function generateROIReport(sessionId: string, inputs: any): ROIReport {
  // Complex calculation logic...
  return {
    id: `ROI-${Date.now()}`,
    sessionId,
    createdAt: new Date(),
    metrics: {
      annualSavings: 156000,
      totalROI: 636,
      paybackPeriod: 3.85,
      confidenceScore: 100
    },
    inputs,
    breakdown: {
      labor: 130000,
      overhead: 26000,
      implementation: 50000
    },
    recommendations: [
      'High confidence in ROI calculation',
      'Payback period under 4 months is excellent',
      'Consider phased implementation approach'
    ]
  };
}

// __tests__/lib/reports/roi-generator.test.ts
import { generateROIReport } from '@/lib/reports/roi-generator';

describe('generateROIReport()', () => {
  const inputs = {
    weeklyHours: 20,
    teamSize: 5,
    hourlyRate: 50,
    automationPercentage: 60,
    implementationCost: 50000,
    timeframe: 36
  };

  test('generates complete ROI report structure', () => {
    const report = generateROIReport('WS-TEST-123', inputs);

    // Use property matchers for dynamic fields
    expect(report).toMatchSnapshot({
      id: expect.stringMatching(/^ROI-\d+$/),  // Matches "ROI-1234567890"
      createdAt: expect.any(Date),             // Any Date object
    });
  });

  test('includes all required sections', () => {
    const report = generateROIReport('WS-TEST-456', inputs);

    // Snapshot just the static structure
    expect({
      hasMetrics: 'metrics' in report,
      hasInputs: 'inputs' in report,
      hasBreakdown: 'breakdown' in report,
      hasRecommendations: 'recommendations' in report,
      metricsKeys: Object.keys(report.metrics).sort(),
      breakdownKeys: Object.keys(report.breakdown).sort()
    }).toMatchInlineSnapshot(`
      {
        "hasMetrics": true,
        "hasInputs": true,
        "hasBreakdown": true,
        "hasRecommendations": true,
        "metricsKeys": [
          "annualSavings",
          "confidenceScore",
          "paybackPeriod",
          "totalROI"
        ],
        "breakdownKeys": [
          "implementation",
          "labor",
          "overhead"
        ]
      }
    `);
  });

  test('generates recommendations based on metrics', () => {
    const report = generateROIReport('WS-TEST-789', inputs);

    // Snapshot only the recommendations array
    expect(report.recommendations).toMatchSnapshot();
  });
});
```

**Generated External Snapshot** (`__snapshots__/roi-generator.test.ts.snap`):

```javascript
exports[`generateROIReport() generates complete ROI report structure 1`] = `
{
  "id": StringMatching /^ROI-\\d+$/,
  "sessionId": "WS-TEST-123",
  "createdAt": Any<Date>,
  "metrics": {
    "annualSavings": 156000,
    "totalROI": 636,
    "paybackPeriod": 3.85,
    "confidenceScore": 100
  },
  "inputs": {
    "weeklyHours": 20,
    "teamSize": 5,
    "hourlyRate": 50,
    "automationPercentage": 60,
    "implementationCost": 50000,
    "timeframe": 36
  },
  "breakdown": {
    "labor": 130000,
    "overhead": 26000,
    "implementation": 50000
  },
  "recommendations": [
    "High confidence in ROI calculation",
    "Payback period under 4 months is excellent",
    "Consider phased implementation approach"
  ]
}
`;

exports[`generateROIReport() generates recommendations based on metrics 1`] = `
[
  "High confidence in ROI calculation",
  "Payback period under 4 months is excellent",
  "Consider phased implementation approach"
]
`;
```

**Learning Points:**
1. Property matchers handle dynamic values (IDs, timestamps)
2. Snapshot complex nested objects without verbose assertions
3. Can snapshot entire object or specific parts
4. Good for detecting unintended changes to data structures

---

### Example 3 – Framework Integration: React Component Snapshot

**Scenario**: Test a Bloom UI component's structure and variants.

```typescript
// components/ui/badge.tsx
import { type VariantProps, cva } from 'class-variance-authority';

const badgeVariants = cva(
  'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground',
        success: 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300',
        warning: 'bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300',
        error: 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-300'
      }
    },
    defaultVariants: {
      variant: 'default'
    }
  }
);

export interface BadgeProps extends VariantProps<typeof badgeVariants> {
  children: React.ReactNode;
}

export function Badge({ variant, children }: BadgeProps) {
  return (
    <span className={badgeVariants({ variant })}>
      {children}
    </span>
  );
}

// __tests__/components/ui/badge.test.tsx
import { render } from '@testing-library/react';
import { Badge } from '@/components/ui/badge';

describe('Badge Component', () => {
  test('renders default variant', () => {
    const { container } = render(<Badge>Default</Badge>);
    expect(container.firstChild).toMatchInlineSnapshot(`
      <span
        class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold bg-primary text-primary-foreground"
      >
        Default
      </span>
    `);
  });

  test('renders success variant', () => {
    const { container } = render(<Badge variant="success">Active</Badge>);
    expect(container.firstChild).toMatchInlineSnapshot(`
      <span
        class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300"
      >
        Active
      </span>
    `);
  });

  test('renders warning variant', () => {
    const { container } = render(<Badge variant="warning">Pending</Badge>);
    expect(container.firstChild).toMatchInlineSnapshot(`
      <span
        class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300"
      >
        Pending
      </span>
    `);
  });

  test('renders error variant', () => {
    const { container } = render(<Badge variant="error">Failed</Badge>);
    expect(container.firstChild).toMatchInlineSnapshot(`
      <span
        class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-300"
      >
        Failed
      </span>
    `);
  });

  test('renders all variants together', () => {
    const { container } = render(
      <div>
        <Badge>Default</Badge>
        <Badge variant="success">Success</Badge>
        <Badge variant="warning">Warning</Badge>
        <Badge variant="error">Error</Badge>
      </div>
    );

    // Snapshot the entire collection
    expect(container).toMatchSnapshot('all badge variants');
  });
});
```

**Learning Points:**
1. Inline snapshots are perfect for small component structures
2. Each variant gets its own snapshot for clarity
3. Snapshots catch CSS class changes (useful for design system components)
4. Can combine multiple components in one snapshot

**When to Update These Snapshots:**
- Intentional design system changes (new classes, variants)
- Dark mode class additions
- Tailwind config updates affecting utilities

**When NOT to Update:**
- Snapshot fails after unrelated code change (investigate why)
- Classes disappear unexpectedly (likely a bug)

---

## 6. Common Pitfalls

<!-- Query: "Snapshot testing mistakes and anti-patterns" -->
<!-- Query: "How to avoid brittle snapshot tests" -->

### Pitfall 1: Blindly Updating Snapshots

❌ **WRONG:**

```bash
# Test fails
npm test

# Developer doesn't review diff
npm test -- -u

# Commits broken snapshot
git commit -m "Fix tests"
```

✅ **CORRECT:**

```bash
# Test fails
npm test

# Review the diff carefully:
# - Expected: <button class="btn-primary">
# + Received: <button class="btn-danger">

# Investigate: Why did the class change?
# - Is this intentional? → Update snapshot
# - Is this a bug? → Fix the code

# Only update if change is correct
npm test -- -u
```

**Why**: Blind updates propagate bugs. Always review snapshot diffs.

---

### Pitfall 2: Snapshotting Dynamic Values Without Property Matchers

❌ **WRONG:**

```typescript
test('creates session', () => {
  const session = createSession();
  expect(session).toMatchSnapshot(); // FAILS every run (timestamps, IDs change)
});
```

✅ **CORRECT:**

```typescript
test('creates session', () => {
  const session = createSession();
  expect(session).toMatchSnapshot({
    id: expect.any(String),
    createdAt: expect.any(Date),
    updatedAt: expect.any(Date)
  });
});
```

**Why**: Dynamic values make snapshots flaky. Use property matchers.

---

### Pitfall 3: Over-Reliance on Snapshots

❌ **WRONG:**

```typescript
test('calculates ROI', () => {
  const result = calculateROI(inputs);
  expect(result).toMatchSnapshot(); // What are we testing?
});
```

✅ **CORRECT:**

```typescript
test('calculates ROI correctly', () => {
  const result = calculateROI(inputs);

  // Explicit assertions for critical values
  expect(result.annualSavings).toBe(156000);
  expect(result.totalROI).toBeCloseTo(636, 0);
  expect(result.paybackPeriod).toBeGreaterThan(0);

  // Snapshot for structure verification (optional)
  expect(result).toMatchSnapshot({
    id: expect.any(String),
    createdAt: expect.any(Date)
  });
});
```

**Why**: Snapshots don't document intent. Use explicit assertions for business logic.

---

### Pitfall 4: Snapshots with Randomness

❌ **WRONG:**

```typescript
test('generates random ID', () => {
  const id = generateRandomId();
  expect(id).toMatchSnapshot(); // Different every run!
});
```

✅ **CORRECT:**

```typescript
test('generates random ID with correct format', () => {
  const id = generateRandomId();
  expect(id).toMatch(/^[A-Z]{3}-\d{6}$/); // Test the pattern, not exact value
});
```

**Why**: Snapshots of random values are useless.

---

### Pitfall 5: Giant Component Snapshots

❌ **WRONG:**

```typescript
test('renders dashboard page', () => {
  const { container } = render(<DashboardPage />);
  expect(container).toMatchSnapshot(); // 800-line snapshot!
});
```

✅ **CORRECT:**

```typescript
test('renders dashboard with key sections', () => {
  render(<DashboardPage />);

  // Test specific behaviors, not entire structure
  expect(screen.getByText('Active Sessions')).toBeInTheDocument();
  expect(screen.getByText('ROI Summary')).toBeInTheDocument();
  expect(screen.getByRole('button', { name: 'Export Report' })).toBeEnabled();
});
```

**Why**: Giant snapshots are brittle and hard to review.

---

### Pitfall 6: Forgetting to Commit Snapshot Files

❌ **WRONG:**

```bash
# Developer adds test with snapshot
git add MyComponent.test.tsx

# Forgets to add snapshot file
git commit

# CI fails for other developers
```

✅ **CORRECT:**

```bash
git add MyComponent.test.tsx
git add __snapshots__/MyComponent.test.tsx.snap  # Always commit snapshots!
git commit
```

**Why**: Snapshots are part of the test. They must be in version control.

---

### Pitfall 7: Snapshots for Business Logic

❌ **WRONG:**

```typescript
test('calculates discount', () => {
  expect(calculateDiscount(100, 0.2)).toMatchInlineSnapshot(`20`);
});
```

✅ **CORRECT:**

```typescript
test('calculates discount correctly', () => {
  expect(calculateDiscount(100, 0.2)).toBe(20);
  expect(calculateDiscount(50, 0.1)).toBe(5);
  expect(calculateDiscount(0, 0.5)).toBe(0);
});
```

**Why**: Explicit assertions document expected behavior better than snapshots.

---

## 7. AI Pair Programming Notes

<!-- Query: "Using snapshot testing with AI coding assistants" -->
<!-- Query: "Best practices for AI-generated snapshot tests" -->

### When to Load This File

Load `08-SNAPSHOT-TESTING.md` when:
- Testing component structure regression
- Verifying API response contracts
- Working with complex data structures
- Deciding between snapshots vs. explicit assertions
- Reviewing snapshot test failures
- Setting up snapshot tests for new features

### Combine With

**For Complete Testing Knowledge:**
- `01-FUNDAMENTALS.md` – Core Jest concepts and test structure
- `02-MATCHERS-ASSERTIONS.md` – Alternative explicit assertions
- `05-REACT-TESTING.md` – Component testing strategies

**For Specific Scenarios:**
- `06-API-TESTING.md` – API response snapshots vs. schema validation
- `FRAMEWORK-INTEGRATION-PATTERNS.md` – Next.js/React integration

### AI Prompt Templates

**Generate Snapshot Test:**

```
Load docs/kb/testing/jest/08-SNAPSHOT-TESTING.md.

Generate a snapshot test for this component:
[paste component code]

Requirements:
- Use toMatchInlineSnapshot for small outputs
- Use property matchers for dynamic values (IDs, timestamps)
- Add descriptive test names
- Include multiple variants if applicable
```

**Review Snapshot Test Quality:**

```
Load docs/kb/testing/jest/08-SNAPSHOT-TESTING.md.

Review this snapshot test:
[paste test code]

Check for:
- Appropriate use of snapshots (not for simple values or business logic)
- Property matchers for dynamic values
- Snapshot size (recommend inline vs. external)
- Missing explicit assertions for critical behavior
```

### What AI Should Avoid

**Anti-Patterns:**
- Generating snapshots for simple values (use `toBe()` instead)
- Snapshots without property matchers for timestamps/IDs
- Giant snapshots (> 100 lines) without justification
- Snapshots for business logic calculations

**Bloom-Specific Avoidance:**
- Never commit `.only()` or `.skip()` in snapshot tests
- Don't snapshot entire pages (test specific components)
- Always use property matchers for `createdAt`, `updatedAt`, `id` fields
- Don't use snapshots for ROI calculations (use explicit assertions)

### Verification Checklist for AI-Generated Snapshot Tests

Before accepting AI-generated snapshot tests:

- [ ] Snapshots are appropriate (not simple values or business logic)
- [ ] Property matchers used for dynamic fields (IDs, timestamps)
- [ ] Snapshot size is reasonable (< 100 lines, or justified)
- [ ] Inline snapshots used for small outputs (< 20 lines)
- [ ] Test names are descriptive ("renders success variant", not "test 1")
- [ ] Critical behavior has explicit assertions (not just snapshots)
- [ ] No hardcoded timestamps or IDs in snapshots
- [ ] Snapshot files will be committed to version control

---

## Last Updated

2025-11-14

**Changelog:**
- Comprehensive snapshot testing guide created per v3.1 playbook
- Added conservative approach emphasizing when NOT to use snapshots
- Included property matchers for dynamic values
- Added Bloom-specific examples (ROI reports, Badge component)
- Documented external vs. inline snapshot trade-offs
- Added 7 common pitfalls with ❌/✅ examples
- Integrated AI pair programming best practices

**Next Steps:**
- See `01-FUNDAMENTALS.md` for core Jest concepts
- See `02-MATCHERS-ASSERTIONS.md` for explicit assertion alternatives
- See `05-REACT-TESTING.md` for component testing strategies
- See `QUICK-REFERENCE.md` for snapshot testing syntax reference

**Contributing:**
If you discover new snapshot testing patterns, anti-patterns, or best practices, update this file and increment `last_reviewed` date.
