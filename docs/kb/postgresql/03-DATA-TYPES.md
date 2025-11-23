# PostgreSQL Data Types

```yaml
id: postgresql_03_data_types
topic: PostgreSQL
file_role: Comprehensive coverage of PostgreSQL data types
profile: beginner_to_intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - PostgreSQL Fundamentals (01-FUNDAMENTALS.md)
  - SQL Basics (02-SQL-BASICS.md)
related_topics:
  - Queries (04-QUERIES.md)
  - Indexes (05-INDEXES.md)
  - Performance (08-PERFORMANCE.md)
embedding_keywords:
  - data types
  - INTEGER BIGINT NUMERIC
  - VARCHAR TEXT CHAR
  - JSONB JSON
  - ARRAY
  - TIMESTAMP DATE TIME
  - UUID SERIAL
  - ENUM custom types
  - type casting
last_reviewed: 2025-11-16
```

## PostgreSQL Type System Overview

PostgreSQL has one of the richest type systems among relational databases, supporting:

- **Numeric Types**: INTEGER, BIGINT, NUMERIC, REAL, DOUBLE PRECISION
- **Character Types**: CHAR, VARCHAR, TEXT
- **Binary Types**: BYTEA
- **Date/Time Types**: DATE, TIME, TIMESTAMP, INTERVAL
- **Boolean Type**: BOOLEAN
- **Enumerated Types**: User-defined ENUM
- **Geometric Types**: POINT, LINE, CIRCLE, POLYGON
- **Network Address Types**: INET, CIDR, MACADDR
- **Bit String Types**: BIT, BIT VARYING
- **Text Search Types**: TSVECTOR, TSQUERY
- **UUID Type**: Universally Unique Identifier
- **JSON Types**: JSON, JSONB
- **Arrays**: All types can be arrays
- **Composite Types**: User-defined row types
- **Range Types**: INT4RANGE, TSRANGE, DATERANGE
- **Domain Types**: Custom constrained types
- **XML Type**: XML data
- **HStore**: Key-value pairs

## Numeric Types

### Integer Types

```sql
-- SMALLINT: 2 bytes, -32768 to 32767
CREATE TABLE stats (
  id SMALLINT PRIMARY KEY,
  score SMALLINT
);

-- INTEGER (or INT): 4 bytes, -2147483648 to 2147483647
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  age INTEGER
);

-- BIGINT: 8 bytes, very large numbers
CREATE TABLE events (
  id BIGINT PRIMARY KEY,
  timestamp_ms BIGINT
);

-- SERIAL (auto-incrementing INTEGER)
CREATE TABLE products (
  id SERIAL PRIMARY KEY,        -- Shorthand for INTEGER with auto-increment
  name VARCHAR(255)
);

-- BIGSERIAL (auto-incrementing BIGINT)
CREATE TABLE logs (
  id BIGSERIAL PRIMARY KEY,     -- For tables with billions of rows
  message TEXT
);

-- Usage examples
INSERT INTO users (age) VALUES (25);
SELECT * FROM users WHERE age > 18 AND age < 65;
```

### Decimal Types

```sql
-- NUMERIC(precision, scale): Exact decimal numbers
-- precision = total digits, scale = digits after decimal
CREATE TABLE financial (
  id SERIAL PRIMARY KEY,
  price NUMERIC(10, 2),           -- 10 digits total, 2 after decimal (e.g., 12345678.90)
  tax_rate NUMERIC(5, 4),         -- e.g., 0.0825 (8.25%)
  total NUMERIC(12, 2)
);

-- DECIMAL: Alias for NUMERIC
CREATE TABLE products (
  price DECIMAL(10, 2)
);

-- NUMERIC without precision: unlimited precision
CREATE TABLE scientific_data (
  value NUMERIC                   -- Stores exact decimal values of any size
);

-- Money type (not recommended, use NUMERIC instead)
-- MONEY: 8 bytes, locale-dependent formatting
CREATE TABLE old_prices (
  price MONEY                     -- Avoid: use NUMERIC(10,2) instead
);

-- Usage examples
INSERT INTO financial (price, tax_rate)
VALUES (99.99, 0.0825);

SELECT price * (1 + tax_rate) AS price_with_tax
FROM financial;

-- Precision matters
SELECT 0.1 + 0.2;                       -- NUMERIC: exactly 0.3
SELECT 0.1::FLOAT + 0.2::FLOAT;         -- FLOAT: approximately 0.30000000000000004
```

### Floating-Point Types

```sql
-- REAL: 4 bytes, 6 decimal digits precision
CREATE TABLE measurements (
  id SERIAL PRIMARY KEY,
  temperature REAL
);

-- DOUBLE PRECISION (or FLOAT): 8 bytes, 15 decimal digits precision
CREATE TABLE scientific (
  id SERIAL PRIMARY KEY,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION
);

-- When to use FLOAT vs NUMERIC:
-- - Use NUMERIC for money, accounting (exact precision required)
-- - Use FLOAT for scientific data, coordinates (approximate OK, faster)

-- Usage examples
INSERT INTO scientific (latitude, longitude)
VALUES (40.7128, -74.0060);  -- New York City

-- Range queries
SELECT * FROM measurements
WHERE temperature BETWEEN 20.0 AND 25.0;
```

## Character Types

```sql
-- CHAR(n): Fixed-length, space-padded
CREATE TABLE codes (
  id SERIAL PRIMARY KEY,
  country_code CHAR(2),           -- Always 2 characters (e.g., 'US')
  state_code CHAR(2)              -- Padded with spaces if shorter
);

-- VARCHAR(n): Variable-length with limit
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50),           -- Up to 50 characters
  email VARCHAR(255)
);

-- TEXT: Variable-length, no limit
CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255),
  body TEXT                       -- No length limit
);

-- Performance note: VARCHAR and TEXT have same performance
-- Use VARCHAR(n) only when you want to enforce a length limit

-- Usage examples
INSERT INTO users (username, email)
VALUES ('john_doe', 'john@example.com');

-- Case-sensitive search
SELECT * FROM users WHERE username = 'John_Doe';      -- No match

-- Case-insensitive search
SELECT * FROM users WHERE username ILIKE 'john_doe';  -- Match

-- Pattern matching
SELECT * FROM users WHERE email LIKE '%@gmail.com';

-- Regular expression
SELECT * FROM users WHERE email ~ '^[a-z]+@[a-z]+\.(com|net|org)$';
```

## Date and Time Types

```sql
-- DATE: Date only (no time)
CREATE TABLE events (
  id SERIAL PRIMARY KEY,
  event_date DATE
);

-- TIME: Time only (no date)
CREATE TABLE business_hours (
  id SERIAL PRIMARY KEY,
  open_time TIME,
  close_time TIME
);

-- TIME WITH TIME ZONE
CREATE TABLE scheduled_tasks (
  id SERIAL PRIMARY KEY,
  run_time TIME WITH TIME ZONE
);

-- TIMESTAMP: Date and time (no timezone)
CREATE TABLE logs (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TIMESTAMP WITH TIME ZONE (TIMESTAMPTZ): Date, time, and timezone
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- INTERVAL: Time span
CREATE TABLE subscriptions (
  id SERIAL PRIMARY KEY,
  duration INTERVAL              -- e.g., '1 month', '30 days', '2 hours'
);

-- Usage examples
INSERT INTO events (event_date) VALUES ('2025-11-16');
INSERT INTO business_hours (open_time, close_time) VALUES ('09:00', '17:00');
INSERT INTO users DEFAULT VALUES;

-- Date arithmetic
SELECT NOW() + INTERVAL '7 days';
SELECT NOW() - INTERVAL '1 month';

-- Extract parts
SELECT EXTRACT(YEAR FROM created_at) FROM users;
SELECT DATE_TRUNC('day', created_at) FROM users;

-- Formatting
SELECT TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') FROM users;

-- Best practice: Always use TIMESTAMPTZ for user-generated timestamps
-- Stores in UTC, converts to client timezone
```

## Boolean Type

```sql
-- BOOLEAN: true, false, or null
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  is_active BOOLEAN DEFAULT true,
  email_verified BOOLEAN DEFAULT false,
  is_admin BOOLEAN
);

-- Boolean literals
INSERT INTO users (is_active, email_verified) VALUES (true, false);
INSERT INTO users (is_active, email_verified) VALUES ('yes', 'no');    -- Also valid
INSERT INTO users (is_active, email_verified) VALUES ('1', '0');        -- Also valid
INSERT INTO users (is_active, email_verified) VALUES ('t', 'f');        -- Also valid

-- Usage in queries
SELECT * FROM users WHERE is_active = true;
SELECT * FROM users WHERE is_active;                -- Shorthand for = true
SELECT * FROM users WHERE NOT is_active;            -- Shorthand for = false

-- NULL handling
SELECT * FROM users WHERE is_admin IS NULL;
SELECT * FROM users WHERE is_admin IS NOT NULL;

-- Boolean operations
SELECT * FROM users WHERE is_active AND email_verified;
SELECT * FROM users WHERE is_active OR is_admin;
SELECT * FROM users WHERE is_active AND NOT is_admin;
```

## UUID Type

```sql
-- UUID: Universally Unique Identifier (128-bit)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username VARCHAR(50)
);

-- Alternative: gen_random_uuid() (built-in, no extension needed in PG 13+)
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255)
);

-- Usage examples
INSERT INTO users (username) VALUES ('john_doe');    -- id auto-generated

-- Explicit UUID
INSERT INTO posts (id, title)
VALUES ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'My Post');

-- Benefits of UUID over SERIAL:
-- - Globally unique (can merge databases)
-- - Non-sequential (security: can't guess next ID)
-- - Can be generated client-side
-- Downsides:
-- - Larger (16 bytes vs 4 bytes for INTEGER)
-- - Slower indexing than SERIAL
-- - Less human-readable
```

## ENUM Types

```sql
-- Create ENUM type
CREATE TYPE user_role AS ENUM ('user', 'moderator', 'admin');
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled');

-- Use ENUM in table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50),
  role user_role DEFAULT 'user'
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  status order_status DEFAULT 'pending'
);

-- Insert with ENUM
INSERT INTO users (username, role) VALUES ('john', 'admin');
INSERT INTO orders (status) VALUES ('processing');

-- Query with ENUM
SELECT * FROM users WHERE role = 'admin';

-- ENUM comparison (follows definition order)
SELECT * FROM orders WHERE status < 'delivered';   -- pending, processing, shipped

-- Alter ENUM (add value)
ALTER TYPE order_status ADD VALUE 'refunded' AFTER 'delivered';

-- Cannot remove ENUM values or reorder
-- To modify: create new ENUM, migrate data, drop old ENUM

-- ENUM vs VARCHAR with CHECK constraint:
-- ENUM pros: Type safety, ordered comparisons, smaller storage
-- ENUM cons: Harder to modify, not portable to other databases
-- Use ENUM when: Values are truly fixed and rarely change
```

## JSON Types

```sql
-- JSON: Stores JSON text, re-parses on each access
-- JSONB: Stores parsed JSON binary, faster queries, larger storage

-- Prefer JSONB for most use cases (faster queries, supports indexing)
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50),
  settings JSONB DEFAULT '{}'::JSONB,
  metadata JSONB
);

-- Insert JSON
INSERT INTO users (username, settings) VALUES
  ('john', '{"theme": "dark", "notifications": true}');

INSERT INTO users (username, metadata) VALUES
  ('jane', '{"age": 28, "city": "NYC", "interests": ["coding", "gaming"]}');

-- Query JSON fields
SELECT settings->>'theme' AS theme FROM users WHERE username = 'john';
-- Result: 'dark'

SELECT metadata->'interests' FROM users WHERE username = 'jane';
-- Result: ["coding", "gaming"]

SELECT metadata->>'age' FROM users WHERE username = 'jane';
-- Result: '28' (text)

SELECT (metadata->>'age')::INTEGER AS age FROM users WHERE username = 'jane';
-- Result: 28 (integer)

-- JSON operators
-- -> : Get JSON object field (returns JSON)
-- ->> : Get JSON object field (returns text)
-- #> : Get JSON object at path (returns JSON)
-- #>> : Get JSON object at path (returns text)

SELECT metadata->'interests'->0 FROM users;          -- First interest (JSON)
SELECT metadata->'interests'->>0 FROM users;         -- First interest (text)
SELECT metadata#>'{interests,0}' FROM users;         -- Same as above
SELECT metadata#>>'{interests,0}' FROM users;        -- Same as above (text)

-- JSON functions
SELECT jsonb_array_length(metadata->'interests') FROM users;
SELECT jsonb_object_keys(settings) FROM users;

-- WHERE clauses with JSON
SELECT * FROM users WHERE settings->>'theme' = 'dark';
SELECT * FROM users WHERE metadata->>'age' > '25';
SELECT * FROM users WHERE metadata->'interests' ? 'coding';    -- Contains key/element
SELECT * FROM users WHERE metadata->'interests' @> '["coding"]'; -- Contains value

-- Update JSON
UPDATE users
SET settings = jsonb_set(settings, '{theme}', '"light"')
WHERE username = 'john';

-- Add new key
UPDATE users
SET settings = settings || '{"language": "en"}'::JSONB
WHERE username = 'john';

-- Remove key
UPDATE users
SET settings = settings - 'language'
WHERE username = 'john';

-- Index JSONB for performance
CREATE INDEX idx_settings_theme ON users ((settings->>'theme'));
CREATE INDEX idx_metadata_gin ON users USING GIN (metadata);
```

## Array Types

```sql
-- Any data type can be an array
CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255),
  tags TEXT[],                    -- Array of text
  view_counts INTEGER[],          -- Array of integers
  metadata JSONB[]                -- Array of JSONB
);

-- Insert arrays
INSERT INTO posts (title, tags) VALUES
  ('Post 1', ARRAY['postgresql', 'databases', 'sql']),
  ('Post 2', '{tutorial, beginner, coding}');         -- Alternative syntax

-- Array indexing (1-based!)
SELECT tags[1] FROM posts;                            -- First tag
SELECT tags[1:2] FROM posts;                          -- First two tags
SELECT tags[2:] FROM posts;                           -- From second tag onward

-- Array functions
SELECT array_length(tags, 1) FROM posts;              -- Length of array
SELECT array_append(tags, 'new_tag') FROM posts;     -- Add element
SELECT array_prepend('new_tag', tags) FROM posts;    -- Add to beginning
SELECT array_cat(tags, ARRAY['tag1', 'tag2']) FROM posts; -- Concatenate arrays

-- Array operators
SELECT * FROM posts WHERE 'postgresql' = ANY(tags);   -- Contains element
SELECT * FROM posts WHERE tags @> ARRAY['postgresql']; -- Contains all elements
SELECT * FROM posts WHERE tags && ARRAY['sql', 'databases']; -- Overlaps

-- Array aggregation
SELECT array_agg(username) FROM users;                -- Collect all usernames into array

-- Unnest array (convert to rows)
SELECT unnest(tags) AS tag FROM posts WHERE id = 1;

-- Multi-dimensional arrays
CREATE TABLE game_boards (
  id SERIAL PRIMARY KEY,
  board INTEGER[][]                                   -- 2D array
);

INSERT INTO game_boards (board) VALUES
  ('{{1,2,3},{4,5,6},{7,8,9}}');

-- Index arrays for performance
CREATE INDEX idx_posts_tags ON posts USING GIN (tags);
```

## Range Types

```sql
-- Built-in range types:
-- INT4RANGE, INT8RANGE, NUMRANGE, TSRANGE, TSTZRANGE, DATERANGE

CREATE TABLE room_bookings (
  id SERIAL PRIMARY KEY,
  room_id INTEGER,
  guest_name VARCHAR(100),
  booked_during TSTZRANGE                            -- Timestamp range
);

CREATE TABLE discount_periods (
  id SERIAL PRIMARY KEY,
  discount_percent NUMERIC(5, 2),
  valid_during DATERANGE                             -- Date range
);

-- Insert ranges
INSERT INTO room_bookings (room_id, guest_name, booked_during) VALUES
  (101, 'John Doe', '[2025-11-16 14:00, 2025-11-16 16:00)');
  -- '[' = inclusive, ')' = exclusive

INSERT INTO discount_periods (discount_percent, valid_during) VALUES
  (20, '[2025-11-01, 2025-11-30]');

-- Range operators
SELECT * FROM room_bookings WHERE booked_during @> NOW()::TIMESTAMPTZ;     -- Contains
SELECT * FROM room_bookings
WHERE booked_during && '[2025-11-16 15:00, 2025-11-16 17:00)'::TSTZRANGE; -- Overlaps

-- Range functions
SELECT lower(valid_during) FROM discount_periods;    -- Start date
SELECT upper(valid_during) FROM discount_periods;    -- End date
SELECT isempty(valid_during) FROM discount_periods;  -- Is empty range

-- Prevent overlapping bookings (exclusion constraint)
CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE room_bookings
ADD CONSTRAINT no_overlapping_bookings
EXCLUDE USING GIST (room_id WITH =, booked_during WITH &&);
```

## Custom Types

### Composite Types

```sql
-- Define composite type
CREATE TYPE address AS (
  street VARCHAR(255),
  city VARCHAR(100),
  state CHAR(2),
  zip_code VARCHAR(10)
);

CREATE TABLE companies (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255),
  office_address address
);

-- Insert composite type
INSERT INTO companies (name, office_address) VALUES
  ('Acme Corp', ROW('123 Main St', 'New York', 'NY', '10001'));

-- Query composite fields
SELECT (office_address).city FROM companies;
SELECT (office_address).* FROM companies;

-- Update composite field
UPDATE companies
SET office_address.city = 'Boston'
WHERE id = 1;
```

### Domain Types

```sql
-- Domain: Named constraint on existing type
CREATE DOMAIN email AS VARCHAR(255)
  CHECK (VALUE ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

CREATE DOMAIN us_postal_code AS VARCHAR(10)
  CHECK (VALUE ~ '^\d{5}(-\d{4})?$');

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50),
  email email,                                        -- Domain type
  zip_code us_postal_code
);

-- Valid insert
INSERT INTO users (username, email, zip_code) VALUES
  ('john', 'john@example.com', '12345');

-- Invalid insert (constraint violation)
INSERT INTO users (username, email) VALUES
  ('jane', 'invalid-email');
-- ERROR: value for domain email violates check constraint
```

## Type Casting

```sql
-- Explicit casting with CAST()
SELECT CAST('123' AS INTEGER);
SELECT CAST(NOW() AS DATE);
SELECT CAST(123.45 AS INTEGER);          -- 123 (truncates)

-- PostgreSQL casting shorthand ::
SELECT '123'::INTEGER;
SELECT NOW()::DATE;
SELECT 123.45::INTEGER;

-- Implicit casting
SELECT '123' + 1;                        -- 124 (text cast to integer)

-- Safe casting (returns NULL on error instead of error)
SELECT '123abc'::INTEGER;                -- ERROR
SELECT pg_catalog.pg_typeof('123abc');   -- Get type without casting

-- Numeric to text
SELECT 123::TEXT;
SELECT 123.45::VARCHAR;

-- Text to numeric
SELECT '123'::INTEGER;
SELECT '123.45'::NUMERIC;

-- Date/time casting
SELECT '2025-11-16'::DATE;
SELECT '2025-11-16 14:30:00'::TIMESTAMP;
SELECT NOW()::DATE;
SELECT CURRENT_DATE::TIMESTAMP;

-- JSON casting
SELECT '{"key": "value"}'::JSON;
SELECT '{"key": "value"}'::JSONB;
SELECT row_to_json(ROW(1, 'text'));

-- Array casting
SELECT '{1,2,3}'::INTEGER[];
SELECT ARRAY[1,2,3]::TEXT[];
```

## NULL Handling

```sql
-- NULL is not equal to anything, including NULL
SELECT NULL = NULL;                      -- Result: NULL (not true!)

-- Use IS NULL / IS NOT NULL
SELECT * FROM users WHERE email IS NULL;
SELECT * FROM users WHERE email IS NOT NULL;

-- COALESCE: Return first non-NULL value
SELECT COALESCE(phone, email, 'No contact') FROM users;

-- NULLIF: Return NULL if two values are equal
SELECT NULLIF(value, 0);                 -- Returns NULL if value is 0

-- Default value for NULL
SELECT COALESCE(phone, 'N/A') AS phone FROM users;

-- NULL in aggregates (ignored)
SELECT AVG(age) FROM users;              -- Ignores NULL ages
SELECT COUNT(*) FROM users;              -- Counts NULL rows
SELECT COUNT(phone) FROM users;          -- Ignores NULL phones
```

## Type Comparison

| Type | Storage Size | Range | Use Case |
|------|-------------|-------|----------|
| **SMALLINT** | 2 bytes | -32,768 to 32,767 | Small integers |
| **INTEGER** | 4 bytes | -2B to 2B | Most integers |
| **BIGINT** | 8 bytes | -9 quintillion to 9 quintillion | Very large numbers |
| **NUMERIC(p,s)** | Variable | Unlimited | Exact decimals (money) |
| **REAL** | 4 bytes | 6 decimal digits precision | Approximate floats |
| **DOUBLE PRECISION** | 8 bytes | 15 decimal digits precision | Scientific data |
| **CHAR(n)** | Fixed | Fixed length | Fixed codes (US, NY) |
| **VARCHAR(n)** | Variable | Up to n chars | Limited text |
| **TEXT** | Variable | Unlimited | Long text |
| **DATE** | 4 bytes | 4713 BC to 5874897 AD | Date only |
| **TIMESTAMP** | 8 bytes | Same as DATE | Date + time |
| **TIMESTAMPTZ** | 8 bytes | Same as DATE | Date + time + timezone |
| **BOOLEAN** | 1 byte | true/false/null | Binary flags |
| **UUID** | 16 bytes | 128-bit unique ID | Distributed IDs |
| **JSON** | Variable | Text-based | JSON data (slower) |
| **JSONB** | Variable | Binary JSON | JSON data (faster) |

## AI Pair Programming Notes

**When discussing data types in pair programming:**

1. **Always specify types explicitly**: `NUMERIC(10,2)` not just `NUMERIC`
2. **Recommend TIMESTAMPTZ over TIMESTAMP**: Always store timezone-aware timestamps
3. **Prefer JSONB over JSON**: Better performance, supports indexing
4. **Use SERIAL for auto-increment**: Simpler than manually managing sequences
5. **Explain NUMERIC vs FLOAT**: Money = NUMERIC, coordinates = FLOAT
6. **Show NULL handling**: `IS NULL`, `COALESCE`, `NULLIF` patterns
7. **Demonstrate type casting**: Both `CAST()` and `::` syntax
8. **Discuss array indexing**: PostgreSQL arrays are 1-based (not 0-based!)
9. **Explain ENUM tradeoffs**: Hard to modify vs type safety
10. **Show JSON operators**: `->` vs `->>`, `@>`, `?`, indexing

**Common type mistakes to catch:**
- Using VARCHAR for fixed-length codes (use CHAR)
- Using TIMESTAMP without timezone for user data (use TIMESTAMPTZ)
- Using TEXT when length limit is desired (use VARCHAR(n))
- Using INTEGER for huge IDs (use BIGINT or UUID)
- Storing money as FLOAT (use NUMERIC(10,2))
- Not indexing JSONB fields for queries (use GIN index)

## Next Steps

1. **04-QUERIES.md** - Master SELECT, JOIN, subqueries with these types
2. **05-INDEXES.md** - Index strategies for different data types
3. **08-PERFORMANCE.md** - Type-specific performance optimizations

## Additional Resources

- PostgreSQL Data Types Docs: https://www.postgresql.org/docs/current/datatype.html
- JSON Functions: https://www.postgresql.org/docs/current/functions-json.html
- Array Functions: https://www.postgresql.org/docs/current/functions-array.html
