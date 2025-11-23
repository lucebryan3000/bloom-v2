# PostgreSQL Queries (Advanced)

```yaml
id: postgresql_04_queries
topic: PostgreSQL
file_role: Advanced querying techniques (JOINs, subqueries, CTEs, window functions)
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - SQL Basics (02-SQL-BASICS.md)
  - Data Types (03-DATA-TYPES.md)
related_topics:
  - Indexes (05-INDEXES.md)
  - Transactions (06-TRANSACTIONS.md)
  - Performance (08-PERFORMANCE.md)
embedding_keywords:
  - JOIN INNER LEFT RIGHT FULL OUTER
  - subquery
  - CTE WITH clause
  - window functions
  - ROW_NUMBER RANK LAG LEAD
  - LATERAL JOIN
  - recursive CTE
  - UNION INTERSECT EXCEPT
last_reviewed: 2025-11-16
```

## JOINs

JOINs combine rows from two or more tables based on related columns.

### INNER JOIN

Returns rows when there's a match in both tables.

```sql
-- Get users with their posts
SELECT
  users.username,
  posts.title,
  posts.created_at
FROM users
INNER JOIN posts ON posts.user_id = users.id;

-- Shorthand (JOIN defaults to INNER JOIN)
SELECT u.username, p.title
FROM users u
JOIN posts p ON p.user_id = u.id;

-- Multiple JOINs
SELECT
  u.username,
  p.title,
  c.body AS comment
FROM users u
JOIN posts p ON p.user_id = u.id
JOIN comments c ON c.post_id = p.id;

-- JOIN with WHERE
SELECT u.username, p.title
FROM users u
JOIN posts p ON p.user_id = u.id
WHERE p.status = 'published'
  AND u.role = 'admin';
```

### LEFT JOIN (LEFT OUTER JOIN)

Returns all rows from the left table, and matching rows from the right table. If no match, NULL values for right table columns.

```sql
-- Get all users, including those with no posts
SELECT
  u.username,
  COUNT(p.id) AS post_count
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
GROUP BY u.id, u.username;

-- Find users with no posts
SELECT u.username
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
WHERE p.id IS NULL;

-- Multiple LEFT JOINs
SELECT
  u.username,
  COUNT(DISTINCT p.id) AS post_count,
  COUNT(DISTINCT c.id) AS comment_count
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
LEFT JOIN comments c ON c.user_id = u.id
GROUP BY u.id, u.username;
```

### RIGHT JOIN (RIGHT OUTER JOIN)

Returns all rows from the right table, and matching rows from the left table.

```sql
-- Get all posts, including those without authors (orphaned)
SELECT
  p.title,
  u.username
FROM users u
RIGHT JOIN posts p ON p.user_id = u.id;

-- Equivalent LEFT JOIN (more commonly used)
SELECT
  p.title,
  u.username
FROM posts p
LEFT JOIN users u ON p.user_id = u.id;
```

### FULL OUTER JOIN

Returns all rows from both tables, with NULLs where there's no match.

```sql
-- Get all users and all posts (even if no match)
SELECT
  u.username,
  p.title
FROM users u
FULL OUTER JOIN posts p ON p.user_id = u.id;

-- Find unmatched rows from either table
SELECT
  u.username,
  p.title
FROM users u
FULL OUTER JOIN posts p ON p.user_id = u.id
WHERE u.id IS NULL OR p.id IS NULL;
```

### CROSS JOIN

Cartesian product - every row from first table with every row from second table.

```sql
-- Get all combinations of sizes and colors
SELECT
  sizes.name AS size,
  colors.name AS color
FROM sizes
CROSS JOIN colors;

-- Alternative syntax (implicit CROSS JOIN)
SELECT sizes.name, colors.name
FROM sizes, colors;

-- Practical use: Generate calendar
SELECT
  date_series.date,
  users.username
FROM generate_series('2025-11-01'::DATE, '2025-11-30'::DATE, '1 day'::INTERVAL) AS date_series(date)
CROSS JOIN users
WHERE users.role = 'admin';
```

### SELF JOIN

Join a table to itself.

```sql
-- Get employees and their managers (manager_id references same table)
SELECT
  e.name AS employee,
  m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;

-- Find users in the same city
SELECT
  u1.username AS user1,
  u2.username AS user2,
  u1.city
FROM users u1
JOIN users u2 ON u1.city = u2.city AND u1.id < u2.id;
```

### JOIN with USING

When join columns have the same name in both tables.

```sql
-- Instead of: ON posts.user_id = users.id
SELECT u.username, p.title
FROM users u
JOIN posts p USING (user_id);

-- Multiple columns
SELECT *
FROM table1
JOIN table2 USING (col1, col2);
```

### LATERAL JOIN

Allows subquery to reference columns from preceding FROM items.

```sql
-- Get each user's 3 most recent posts
SELECT
  u.username,
  p.title,
  p.created_at
FROM users u
CROSS JOIN LATERAL (
  SELECT title, created_at
  FROM posts
  WHERE posts.user_id = u.id
  ORDER BY created_at DESC
  LIMIT 3
) p;

-- Get each product and its category's top seller
SELECT
  p.name,
  top.name AS top_seller
FROM products p
CROSS JOIN LATERAL (
  SELECT name
  FROM products
  WHERE category_id = p.category_id
  ORDER BY sales DESC
  LIMIT 1
) top;
```

## Subqueries

### Scalar Subqueries

Returns a single value.

```sql
-- Get users who have more posts than average
SELECT username
FROM users
WHERE (
  SELECT COUNT(*) FROM posts WHERE posts.user_id = users.id
) > (
  SELECT AVG(post_count)
  FROM (SELECT COUNT(*) AS post_count FROM posts GROUP BY user_id) AS counts
);

-- Get each post with author's total post count
SELECT
  title,
  (SELECT COUNT(*) FROM posts p WHERE p.user_id = posts.user_id) AS author_post_count
FROM posts;
```

### IN / NOT IN Subqueries

```sql
-- Get users who have posted
SELECT username
FROM users
WHERE id IN (SELECT DISTINCT user_id FROM posts);

-- Get users who haven't posted
SELECT username
FROM users
WHERE id NOT IN (SELECT user_id FROM posts WHERE user_id IS NOT NULL);

-- Note: Be careful with NULL in NOT IN
-- Use NOT EXISTS instead for safety
SELECT username
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM posts p WHERE p.user_id = u.id);
```

### EXISTS / NOT EXISTS

```sql
-- Get users who have at least one published post
SELECT username
FROM users u
WHERE EXISTS (
  SELECT 1 FROM posts p
  WHERE p.user_id = u.id AND p.status = 'published'
);

-- Get users with no comments
SELECT username
FROM users u
WHERE NOT EXISTS (
  SELECT 1 FROM comments c WHERE c.user_id = u.id
);

-- EXISTS is often faster than IN for large datasets
```

### Correlated Subqueries

Subquery that references columns from the outer query.

```sql
-- Get each user's most recent post
SELECT
  u.username,
  (
    SELECT p.title
    FROM posts p
    WHERE p.user_id = u.id
    ORDER BY p.created_at DESC
    LIMIT 1
  ) AS latest_post
FROM users u;

-- Get posts with above-average likes for that user
SELECT title, likes
FROM posts p1
WHERE likes > (
  SELECT AVG(likes)
  FROM posts p2
  WHERE p2.user_id = p1.user_id
);
```

### FROM Subqueries (Derived Tables)

```sql
-- Get users with their post counts (only those with posts)
SELECT username, post_count
FROM (
  SELECT
    u.username,
    COUNT(p.id) AS post_count
  FROM users u
  JOIN posts p ON p.user_id = u.id
  GROUP BY u.id, u.username
) AS user_stats
WHERE post_count > 10;

-- Multi-level aggregation
SELECT
  AVG(daily_sales) AS avg_daily_sales
FROM (
  SELECT
    DATE(created_at) AS sale_date,
    SUM(amount) AS daily_sales
  FROM orders
  GROUP BY DATE(created_at)
) AS daily_totals;
```

## CTEs (Common Table Expressions)

CTEs improve readability and allow recursive queries.

### Basic CTEs

```sql
-- Single CTE
WITH active_users AS (
  SELECT id, username
  FROM users
  WHERE status = 'active'
)
SELECT u.username, COUNT(p.id) AS post_count
FROM active_users u
LEFT JOIN posts p ON p.user_id = u.id
GROUP BY u.id, u.username;

-- Multiple CTEs
WITH
  active_users AS (
    SELECT id, username FROM users WHERE status = 'active'
  ),
  recent_posts AS (
    SELECT * FROM posts WHERE created_at > NOW() - INTERVAL '30 days'
  )
SELECT
  u.username,
  COUNT(p.id) AS recent_post_count
FROM active_users u
LEFT JOIN recent_posts p ON p.user_id = u.id
GROUP BY u.id, u.username;
```

### Recursive CTEs

```sql
-- Generate series of numbers 1-10
WITH RECURSIVE numbers AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM numbers WHERE n < 10
)
SELECT * FROM numbers;

-- Organizational hierarchy (tree traversal)
WITH RECURSIVE employee_hierarchy AS (
  -- Base case: top-level employees
  SELECT id, name, manager_id, 1 AS level, name AS path
  FROM employees
  WHERE manager_id IS NULL

  UNION ALL

  -- Recursive case: employees under current level
  SELECT
    e.id,
    e.name,
    e.manager_id,
    eh.level + 1,
    eh.path || ' > ' || e.name
  FROM employees e
  JOIN employee_hierarchy eh ON e.manager_id = eh.id
)
SELECT * FROM employee_hierarchy
ORDER BY level, path;

-- Find all descendants of a specific user (e.g., comment thread)
WITH RECURSIVE comment_thread AS (
  SELECT id, parent_id, body, 1 AS depth
  FROM comments
  WHERE id = 100  -- Root comment

  UNION ALL

  SELECT c.id, c.parent_id, c.body, ct.depth + 1
  FROM comments c
  JOIN comment_thread ct ON c.parent_id = ct.id
)
SELECT * FROM comment_thread
ORDER BY depth;
```

## Window Functions

Window functions perform calculations across rows related to the current row.

### Basic Window Functions

```sql
-- ROW_NUMBER: Unique sequential number
SELECT
  username,
  created_at,
  ROW_NUMBER() OVER (ORDER BY created_at) AS row_num
FROM users;

-- RANK: Rank with gaps for ties
SELECT
  username,
  score,
  RANK() OVER (ORDER BY score DESC) AS rank
FROM users;
-- Scores: 100, 95, 95, 90 → Ranks: 1, 2, 2, 4

-- DENSE_RANK: Rank without gaps
SELECT
  username,
  score,
  DENSE_RANK() OVER (ORDER BY score DESC) AS rank
FROM users;
-- Scores: 100, 95, 95, 90 → Ranks: 1, 2, 2, 3

-- NTILE: Divide rows into N buckets
SELECT
  username,
  score,
  NTILE(4) OVER (ORDER BY score DESC) AS quartile
FROM users;
```

### PARTITION BY

Divide rows into groups and apply window function to each group separately.

```sql
-- Row number within each category
SELECT
  category,
  product_name,
  price,
  ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) AS rank_in_category
FROM products;

-- Rank users by score within each department
SELECT
  department,
  username,
  score,
  RANK() OVER (PARTITION BY department ORDER BY score DESC) AS dept_rank
FROM employees;

-- Get top 3 products per category
WITH ranked_products AS (
  SELECT
    category,
    product_name,
    price,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) AS rank
  FROM products
)
SELECT category, product_name, price
FROM ranked_products
WHERE rank <= 3;
```

### Aggregate Window Functions

```sql
-- Running total
SELECT
  date,
  amount,
  SUM(amount) OVER (ORDER BY date) AS running_total
FROM sales;

-- Moving average (3-day window)
SELECT
  date,
  amount,
  AVG(amount) OVER (
    ORDER BY date
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS moving_avg_3day
FROM sales;

-- Cumulative count
SELECT
  username,
  created_at,
  COUNT(*) OVER (ORDER BY created_at) AS cumulative_users
FROM users;

-- Percentage of total
SELECT
  product,
  sales,
  sales * 100.0 / SUM(sales) OVER () AS pct_of_total
FROM product_sales;
```

### LAG and LEAD

```sql
-- LAG: Access previous row
SELECT
  date,
  amount,
  LAG(amount, 1) OVER (ORDER BY date) AS prev_day_amount,
  amount - LAG(amount, 1) OVER (ORDER BY date) AS day_over_day_change
FROM sales;

-- LEAD: Access next row
SELECT
  date,
  amount,
  LEAD(amount, 1) OVER (ORDER BY date) AS next_day_amount
FROM sales;

-- LAG with PARTITION BY
SELECT
  user_id,
  action_date,
  action_type,
  LAG(action_date, 1) OVER (PARTITION BY user_id ORDER BY action_date) AS prev_action_date
FROM user_actions;
```

### FIRST_VALUE and LAST_VALUE

```sql
-- FIRST_VALUE: First value in window
SELECT
  date,
  amount,
  FIRST_VALUE(amount) OVER (ORDER BY date) AS first_day_amount
FROM sales;

-- LAST_VALUE: Last value in window (careful with default frame!)
SELECT
  date,
  amount,
  LAST_VALUE(amount) OVER (
    ORDER BY date
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  ) AS last_day_amount
FROM sales;

-- Compare each day to first day
SELECT
  date,
  amount,
  amount - FIRST_VALUE(amount) OVER (ORDER BY date) AS change_since_start
FROM sales;
```

### Window Frames

Control which rows are included in the window.

```sql
-- Default frame: RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
SELECT
  date,
  SUM(amount) OVER (ORDER BY date)  -- Running total
FROM sales;

-- ROWS vs RANGE:
-- ROWS: Physical offset (number of rows)
-- RANGE: Logical offset (values within range)

-- 3-row moving average
SELECT
  date,
  AVG(amount) OVER (
    ORDER BY date
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  )
FROM sales;

-- Between specific offsets
SELECT
  date,
  AVG(amount) OVER (
    ORDER BY date
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
  )
FROM sales;

-- UNBOUNDED
SELECT
  date,
  SUM(amount) OVER (
    ORDER BY date
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  ) AS total_sum
FROM sales;
```

## Set Operations

### UNION

Combines results from multiple queries, removing duplicates.

```sql
-- Get all unique usernames from users and archived_users
SELECT username FROM users
UNION
SELECT username FROM archived_users;

-- UNION ALL: Keep duplicates (faster)
SELECT username FROM users
UNION ALL
SELECT username FROM archived_users;

-- Must have same number of columns and compatible types
SELECT id, username, 'active' AS status FROM users
UNION ALL
SELECT id, username, 'archived' AS status FROM archived_users;
```

### INTERSECT

Returns rows present in both queries.

```sql
-- Get users who are both authors and commenters
SELECT user_id FROM posts
INTERSECT
SELECT user_id FROM comments;
```

### EXCEPT

Returns rows from first query that aren't in second query.

```sql
-- Get users who posted but never commented
SELECT user_id FROM posts
EXCEPT
SELECT user_id FROM comments;

-- Get products never ordered
SELECT id FROM products
EXCEPT
SELECT product_id FROM order_items;
```

## Advanced Patterns

### Pagination

```sql
-- Basic pagination (page 3, 20 per page)
SELECT *
FROM posts
ORDER BY created_at DESC
LIMIT 20 OFFSET 40;

-- Better pagination with keyset (cursor-based)
-- Much faster for large offsets
SELECT *
FROM posts
WHERE created_at < '2025-11-16 10:00:00'  -- Last created_at from previous page
ORDER BY created_at DESC
LIMIT 20;

-- Handle ties (multiple rows with same created_at)
SELECT *
FROM posts
WHERE (created_at, id) < ('2025-11-16 10:00:00', 12345)
ORDER BY created_at DESC, id DESC
LIMIT 20;
```

### Pivot Tables (Crosstab)

```sql
-- Install tablefunc extension
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Pivot: Convert rows to columns
SELECT *
FROM crosstab(
  'SELECT user_id, action_type, COUNT(*)
   FROM user_actions
   GROUP BY user_id, action_type
   ORDER BY 1, 2',
  'SELECT DISTINCT action_type FROM user_actions ORDER BY 1'
) AS ct(user_id INTEGER, login BIGINT, logout BIGINT, purchase BIGINT);

-- Manual pivot with CASE
SELECT
  user_id,
  COUNT(CASE WHEN action_type = 'login' THEN 1 END) AS logins,
  COUNT(CASE WHEN action_type = 'logout' THEN 1 END) AS logouts,
  COUNT(CASE WHEN action_type = 'purchase' THEN 1 END) AS purchases
FROM user_actions
GROUP BY user_id;
```

### DISTINCT ON

Get first row per group (PostgreSQL-specific).

```sql
-- Get each user's most recent post
SELECT DISTINCT ON (user_id)
  user_id,
  title,
  created_at
FROM posts
ORDER BY user_id, created_at DESC;

-- Get highest-priced product per category
SELECT DISTINCT ON (category)
  category,
  product_name,
  price
FROM products
ORDER BY category, price DESC;

-- Multiple DISTINCT ON columns
SELECT DISTINCT ON (category, brand)
  category,
  brand,
  product_name,
  price
FROM products
ORDER BY category, brand, price DESC;
```

### Conditional Aggregation

```sql
-- Count users by status
SELECT
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE status = 'active') AS active,
  COUNT(*) FILTER (WHERE status = 'inactive') AS inactive,
  COUNT(*) FILTER (WHERE status = 'banned') AS banned
FROM users;

-- Sum with conditions
SELECT
  SUM(amount) AS total_sales,
  SUM(amount) FILTER (WHERE status = 'completed') AS completed_sales,
  SUM(amount) FILTER (WHERE status = 'pending') AS pending_sales
FROM orders;

-- Alternative: CASE inside aggregation
SELECT
  SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) AS completed_sales
FROM orders;
```

## AI Pair Programming Notes

**When working with advanced queries in pair programming:**

1. **Explain JOIN types visually**: Draw Venn diagrams for INNER/LEFT/RIGHT/FULL joins
2. **Show execution order**: CTEs execute before main query, subqueries depend on context
3. **Demonstrate window function frames**: Explain ROWS vs RANGE, PRECEDING vs FOLLOWING
4. **Use EXPLAIN**: Always show query plans for complex queries
5. **Prefer CTEs over subqueries**: More readable, can be referenced multiple times
6. **Show LATERAL JOIN use cases**: When you need correlated subqueries in FROM clause
7. **Explain DISTINCT ON**: PostgreSQL-specific, powerful alternative to window functions
8. **Demonstrate pagination**: Show both OFFSET (simple) and keyset (performant)
9. **Use EXISTS over IN**: Better performance, handles NULL correctly
10. **Show recursive CTE limits**: Set max recursion depth to prevent infinite loops

**Common query mistakes to catch:**
- Using SELECT * in production (list columns explicitly)
- Missing WHERE in correlated subqueries (Cartesian product!)
- Not handling NULL in NOT IN (use NOT EXISTS)
- Using OFFSET for large offsets (use keyset pagination)
- Forgetting window frame specification (LAST_VALUE issues)
- Self-join without preventing duplicate pairs (use `a.id < b.id`)

## Next Steps

1. **05-INDEXES.md** - Optimize these queries with proper indexes
2. **06-TRANSACTIONS.md** - Ensure data consistency with transactions
3. **08-PERFORMANCE.md** - Query optimization techniques and EXPLAIN

## Additional Resources

- Window Functions Tutorial: https://www.postgresqltutorial.com/postgresql-window-function/
- CTE Documentation: https://www.postgresql.org/docs/current/queries-with.html
- JOIN Performance: https://wiki.postgresql.org/wiki/Don%27t_Do_This#Don.27t_use_NOT_IN
