# PostgreSQL Transactions

```yaml
id: postgresql_06_transactions
topic: PostgreSQL
file_role: Transaction management, isolation levels, and concurrency control
profile: intermediate
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - SQL Basics (02-SQL-BASICS.md)
  - Queries (04-QUERIES.md)
  - Indexes (05-INDEXES.md)
related_topics:
  - Performance (08-PERFORMANCE.md)
  - Replication (10-REPLICATION.md)
embedding_keywords:
  - BEGIN COMMIT ROLLBACK
  - SAVEPOINT
  - isolation level
  - READ COMMITTED SERIALIZABLE
  - MVCC
  - deadlock
  - advisory locks
  - two-phase commit
  - transaction ID
last_reviewed: 2025-11-16
```

## What Are Transactions?

A transaction is a sequence of database operations that are treated as a single unit of work. Transactions follow ACID properties:

- **Atomicity**: All operations succeed or all fail (no partial completion)
- **Consistency**: Database remains in valid state before and after transaction
- **Isolation**: Concurrent transactions don't interfere with each other
- **Durability**: Committed transactions persist even after system crashes

## Basic Transaction Commands

### BEGIN, COMMIT, ROLLBACK

```sql
-- Start transaction
BEGIN;

-- Perform operations
INSERT INTO accounts (user_id, balance) VALUES (1, 1000);
UPDATE accounts SET balance = balance - 100 WHERE user_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE user_id = 2;

-- Commit transaction (make changes permanent)
COMMIT;

-- Or rollback if error (undo all changes)
ROLLBACK;
```

### Alternative Syntax

```sql
-- START TRANSACTION (same as BEGIN)
START TRANSACTION;
  INSERT INTO users (username) VALUES ('john');
COMMIT;

-- END (same as COMMIT)
BEGIN;
  UPDATE users SET status = 'active' WHERE id = 1;
END;

-- ABORT (same as ROLLBACK)
BEGIN;
  DELETE FROM users WHERE id = 999;
ABORT;
```

### Implicit Transactions

```sql
-- Without explicit BEGIN, each statement is auto-committed
INSERT INTO users (username) VALUES ('alice');  -- Auto-committed
UPDATE users SET status = 'active' WHERE id = 1;  -- Auto-committed

-- This is equivalent to:
BEGIN;
  INSERT INTO users (username) VALUES ('alice');
COMMIT;

BEGIN;
  UPDATE users SET status = 'active' WHERE id = 1;
COMMIT;
```

## Savepoints

Savepoints allow partial rollback within a transaction.

```sql
BEGIN;
  INSERT INTO users (username) VALUES ('alice');  -- ID = 100
  SAVEPOINT sp1;

  INSERT INTO users (username) VALUES ('bob');  -- ID = 101
  SAVEPOINT sp2;

  INSERT INTO users (username) VALUES ('charlie');  -- ID = 102

  -- Rollback to sp2 (only charlie is undone)
  ROLLBACK TO sp2;

  -- alice (100) and bob (101) still exist
  -- charlie (102) was undone

  -- Rollback to sp1 (bob is also undone)
  ROLLBACK TO sp1;

  -- Only alice (100) remains

COMMIT;  -- Commit alice
```

### Releasing Savepoints

```sql
BEGIN;
  INSERT INTO users (username) VALUES ('alice');
  SAVEPOINT sp1;

  INSERT INTO users (username) VALUES ('bob');

  -- Release savepoint (can no longer rollback to it)
  RELEASE SAVEPOINT sp1;

  -- This would fail: ROLLBACK TO sp1;
  -- ERROR: savepoint "sp1" does not exist

COMMIT;
```

### Practical Savepoint Example

```sql
CREATE OR REPLACE FUNCTION import_users(user_data JSON[])
RETURNS TABLE(username TEXT, status TEXT) AS $$
DECLARE
  user_record JSON;
BEGIN
  FOR user_record IN SELECT * FROM unnest(user_data) LOOP
    BEGIN
      -- Try to insert each user
      INSERT INTO users (username, email)
      VALUES (
        user_record->>'username',
        user_record->>'email'
      );

      RETURN QUERY SELECT
        user_record->>'username',
        'success'::TEXT;

    EXCEPTION WHEN OTHERS THEN
      -- If insert fails, rollback this user only
      RETURN QUERY SELECT
        user_record->>'username',
        'failed: ' || SQLERRM;
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

## Isolation Levels

PostgreSQL supports four isolation levels defined by SQL standard:

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Serialization Anomaly |
|-----------------|------------|---------------------|--------------|----------------------|
| **Read Uncommitted*** | Possible | Possible | Possible | Possible |
| **Read Committed** (default) | Not possible | Possible | Possible | Possible |
| **Repeatable Read** | Not possible | Not possible | Not possible† | Possible |
| **Serializable** | Not possible | Not possible | Not possible | Not possible |

*PostgreSQL treats Read Uncommitted as Read Committed
†PostgreSQL's implementation prevents phantom reads even in Repeatable Read

### Read Committed (Default)

Each query sees only data committed before the query began.

```sql
-- Session 1
BEGIN;
SELECT balance FROM accounts WHERE id = 1;  -- 1000

-- Session 2
UPDATE accounts SET balance = 500 WHERE id = 1;
COMMIT;

-- Session 1 (continuing)
SELECT balance FROM accounts WHERE id = 1;  -- 500 (sees new value!)
COMMIT;
```

**Use when:** Most applications (default is usually correct)

**Pros:**
- High concurrency
- Low overhead
- Prevents dirty reads

**Cons:**
- Non-repeatable reads (same query may return different results within transaction)
- Phantom reads (new rows may appear)

### Repeatable Read

All reads within a transaction see a consistent snapshot from transaction start.

```sql
-- Set isolation level
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Or set for entire session
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Example
-- Session 1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE id = 1;  -- 1000

-- Session 2
UPDATE accounts SET balance = 500 WHERE id = 1;
COMMIT;

-- Session 1 (continuing)
SELECT balance FROM accounts WHERE id = 1;  -- Still 1000! (snapshot isolation)
COMMIT;
```

**Use when:**
- Reports that need consistent data
- Calculations across multiple queries
- Avoiding non-repeatable reads

**Pros:**
- Consistent snapshot throughout transaction
- No non-repeatable reads
- No phantom reads (in PostgreSQL's implementation)

**Cons:**
- Higher chance of serialization failures
- Must retry failed transactions

### Serializable

Strongest isolation - transactions appear to execute sequentially.

```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
  -- Your queries here
COMMIT;

-- Example: Prevent concurrent inserts from violating constraint
-- Session 1
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM tickets WHERE event_id = 1;  -- 99 (1 spot left)
INSERT INTO tickets (event_id, user_id) VALUES (1, 100);
-- Slow processing...

-- Session 2 (concurrent)
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM tickets WHERE event_id = 1;  -- 99 (sees same count)
INSERT INTO tickets (event_id, user_id) VALUES (1, 200);
COMMIT;  -- Success!

-- Session 1 (continuing)
COMMIT;
-- ERROR: could not serialize access due to read/write dependencies
-- Must retry transaction
```

**Use when:**
- Financial transactions
- Inventory management
- Any scenario requiring true serializability

**Pros:**
- Strongest consistency guarantees
- No anomalies possible

**Cons:**
- Highest chance of serialization failures
- Lower concurrency
- Must implement retry logic

### Setting Isolation Level

```sql
-- For single transaction
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- or
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- For current session
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Check current isolation level
SHOW transaction_isolation;

-- Default isolation level (in postgresql.conf)
default_transaction_isolation = 'read committed'
```

## MVCC (Multi-Version Concurrency Control)

PostgreSQL uses MVCC to allow high concurrency without read locks.

### How MVCC Works

```sql
-- Every row has hidden columns:
-- xmin: Transaction ID that created the row
-- xmax: Transaction ID that deleted the row (0 if not deleted)

-- Example
CREATE TABLE accounts (id INTEGER, balance INTEGER);
INSERT INTO accounts VALUES (1, 1000);

-- Check internal columns
SELECT xmin, xmax, * FROM accounts;
-- xmin | xmax | id | balance
-- 1000 |    0 |  1 |    1000

-- Update creates new version
UPDATE accounts SET balance = 500 WHERE id = 1;

SELECT xmin, xmax, * FROM accounts;
-- xmin | xmax | id | balance
-- 1001 |    0 |  1 |     500

-- Old version (xmin=1000, xmax=1001) is kept for concurrent transactions
-- VACUUM removes old versions when no longer needed
```

### MVCC Benefits

**No read locks**: Readers never block writers, writers never block readers

```sql
-- Session 1
BEGIN;
SELECT * FROM accounts WHERE id = 1;  -- Reads version 1

-- Session 2 (concurrent)
UPDATE accounts SET balance = 500 WHERE id = 1;  -- Writes version 2
COMMIT;

-- Session 1 still sees version 1
SELECT * FROM accounts WHERE id = 1;  -- Same result as first query
COMMIT;
```

**High concurrency**: Multiple transactions can read and write simultaneously

## Locking

### Row-Level Locks

```sql
-- FOR UPDATE: Exclusive lock (prevents other updates)
BEGIN;
SELECT * FROM accounts WHERE id = 1 FOR UPDATE;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
COMMIT;

-- Other sessions trying to SELECT FOR UPDATE will wait

-- FOR SHARE: Shared lock (allows other reads, prevents updates)
BEGIN;
SELECT * FROM accounts WHERE id = 1 FOR SHARE;
-- Other sessions can also SELECT FOR SHARE
-- But UPDATE will wait until this transaction commits
COMMIT;

-- FOR NO KEY UPDATE: Like FOR UPDATE but allows foreign key references
BEGIN;
SELECT * FROM users WHERE id = 1 FOR NO KEY UPDATE;
-- Other transactions can still reference this user via foreign key
COMMIT;

-- FOR KEY SHARE: Weakest lock
BEGIN;
SELECT * FROM users WHERE id = 1 FOR KEY SHARE;
-- Only blocks FOR UPDATE, allows everything else
COMMIT;

-- NOWAIT: Don't wait for lock, fail immediately
SELECT * FROM accounts WHERE id = 1 FOR UPDATE NOWAIT;
-- ERROR: could not obtain lock on row in relation "accounts"

-- SKIP LOCKED: Skip locked rows
SELECT * FROM tasks WHERE status = 'pending'
ORDER BY created_at
LIMIT 10
FOR UPDATE SKIP LOCKED;
-- Returns only unlocked rows (useful for job queues)
```

### Table-Level Locks

```sql
-- LOCK TABLE (explicit table lock)
BEGIN;
LOCK TABLE accounts IN ACCESS EXCLUSIVE MODE;
-- No one else can read or write accounts table
UPDATE accounts SET balance = balance * 1.05;
COMMIT;

-- Lock modes (from least to most restrictive):
-- ACCESS SHARE (SELECT)
-- ROW SHARE (SELECT FOR UPDATE)
-- ROW EXCLUSIVE (INSERT, UPDATE, DELETE)
-- SHARE UPDATE EXCLUSIVE (VACUUM, CREATE INDEX CONCURRENTLY)
-- SHARE (CREATE INDEX)
-- SHARE ROW EXCLUSIVE
-- EXCLUSIVE
-- ACCESS EXCLUSIVE (DROP TABLE, TRUNCATE, VACUUM FULL)

-- Check current locks
SELECT
  locktype,
  relation::regclass,
  mode,
  granted,
  pid
FROM pg_locks
WHERE relation = 'accounts'::regclass;
```

### Advisory Locks

Application-level locks using arbitrary integers.

```sql
-- Session-level advisory lock
SELECT pg_advisory_lock(12345);
-- Do work...
SELECT pg_advisory_unlock(12345);

-- Transaction-level advisory lock (auto-released on commit)
BEGIN;
SELECT pg_advisory_xact_lock(12345);
-- Do work...
COMMIT;  -- Lock automatically released

-- Try lock without waiting
SELECT pg_try_advisory_lock(12345);  -- Returns true if acquired, false if not

-- Use case: Ensure only one background job runs
CREATE OR REPLACE FUNCTION process_pending_orders()
RETURNS VOID AS $$
BEGIN
  -- Try to acquire lock
  IF NOT pg_try_advisory_lock(hashtext('process_orders')) THEN
    RAISE NOTICE 'Another process is already running';
    RETURN;
  END IF;

  -- Process orders
  UPDATE orders SET status = 'processing'
  WHERE status = 'pending';

  -- Lock automatically released when function exits
  PERFORM pg_advisory_unlock(hashtext('process_orders'));
END;
$$ LANGUAGE plpgsql;
```

## Deadlocks

A deadlock occurs when two transactions wait for each other to release locks.

### Example Deadlock

```sql
-- Session 1
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;  -- Locks account 1

-- Session 2
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 2;  -- Locks account 2

-- Session 1 (continuing)
UPDATE accounts SET balance = balance + 100 WHERE id = 2;  -- Waits for account 2

-- Session 2 (continuing)
UPDATE accounts SET balance = balance + 100 WHERE id = 1;  -- Waits for account 1

-- DEADLOCK! PostgreSQL detects and aborts one transaction:
-- ERROR: deadlock detected
-- DETAIL: Process 1234 waits for ShareLock on transaction 5678;
--         blocked by process 5678.
--         Process 5678 waits for ShareLock on transaction 1234;
--         blocked by process 1234.
```

### Preventing Deadlocks

```sql
-- 1. Always access tables/rows in the same order
-- Good:
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = LEAST(1, 2);
UPDATE accounts SET balance = balance + 100 WHERE id = GREATEST(1, 2);
COMMIT;

-- 2. Use SELECT FOR UPDATE to lock rows upfront
BEGIN;
SELECT * FROM accounts WHERE id IN (1, 2) ORDER BY id FOR UPDATE;
-- Now update in any order
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

-- 3. Keep transactions short
-- Bad: Long-running transaction
BEGIN;
-- Complex calculations...
-- Sleep...
UPDATE accounts SET balance = 500;
COMMIT;

-- Good: Do calculations outside transaction
-- Calculate new_balance
BEGIN;
UPDATE accounts SET balance = 500;
COMMIT;

-- 4. Set lock timeout
SET lock_timeout = '5s';
BEGIN;
UPDATE accounts SET balance = 500 WHERE id = 1;
-- If waits more than 5 seconds:
-- ERROR: canceling statement due to lock timeout
COMMIT;
```

### Detecting Deadlocks

```sql
-- Check for blocking queries
SELECT
  blocked_locks.pid AS blocked_pid,
  blocked_activity.usename AS blocked_user,
  blocking_locks.pid AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_statement,
  blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
  ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
  AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
  AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
  AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
  AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
  AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
  AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

## Two-Phase Commit

Two-phase commit enables distributed transactions across multiple databases.

```sql
-- Prepare transaction (phase 1)
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
PREPARE TRANSACTION 'transfer_123';

-- On another database:
BEGIN;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
PREPARE TRANSACTION 'transfer_123';

-- Commit both (phase 2)
COMMIT PREPARED 'transfer_123';

-- Or rollback both
ROLLBACK PREPARED 'transfer_123';

-- Check prepared transactions
SELECT * FROM pg_prepared_xacts;

-- Note: Two-phase commit is rarely needed
-- Most applications use logical replication or saga pattern instead
```

## Transaction Best Practices

### 1. Keep Transactions Short

```sql
-- Bad: Long transaction
BEGIN;
SELECT * FROM orders;  -- Returns 1 million rows
-- Process in application...
-- Send emails...
UPDATE orders SET status = 'processed';
COMMIT;

-- Good: Short transaction
-- Process data outside transaction
BEGIN;
UPDATE orders SET status = 'processed' WHERE id IN (...);
COMMIT;
```

### 2. Handle Serialization Failures

```python
# Python example with retry logic
import psycopg2
from psycopg2 import OperationalError

def transfer_money(from_account, to_account, amount, max_retries=3):
    for attempt in range(max_retries):
        try:
            with conn.cursor() as cur:
                cur.execute("BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE")
                cur.execute(
                    "UPDATE accounts SET balance = balance - %s WHERE id = %s",
                    (amount, from_account)
                )
                cur.execute(
                    "UPDATE accounts SET balance = balance + %s WHERE id = %s",
                    (amount, to_account)
                )
                cur.execute("COMMIT")
                return True
        except OperationalError as e:
            if "could not serialize" in str(e):
                # Retry transaction
                conn.rollback()
                continue
            else:
                raise
    return False
```

### 3. Use Appropriate Isolation Level

```sql
-- Read Committed: Most applications (default)
BEGIN;  -- Implicitly READ COMMITTED
SELECT * FROM products WHERE id = 1;
COMMIT;

-- Repeatable Read: Reports, analytics
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM orders WHERE created_at >= '2025-01-01';
SELECT SUM(total) FROM orders WHERE created_at >= '2025-01-01';
COMMIT;

-- Serializable: Financial transactions, inventory
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT stock FROM products WHERE id = 1;
-- Check stock > 0
UPDATE products SET stock = stock - 1 WHERE id = 1;
INSERT INTO orders (product_id, quantity) VALUES (1, 1);
COMMIT;
```

### 4. Explicit Locking When Needed

```sql
-- Use FOR UPDATE for critical sections
BEGIN;
SELECT balance FROM accounts WHERE id = 1 FOR UPDATE;
-- Calculate new balance
UPDATE accounts SET balance = 500 WHERE id = 1;
COMMIT;

-- Use SKIP LOCKED for job queues
SELECT * FROM jobs
WHERE status = 'pending'
ORDER BY created_at
LIMIT 1
FOR UPDATE SKIP LOCKED;
```

### 5. Set Timeouts

```sql
-- Statement timeout (abort long-running queries)
SET statement_timeout = '30s';

-- Lock timeout (abort if can't acquire lock)
SET lock_timeout = '5s';

-- Idle in transaction timeout (abort idle transactions)
SET idle_in_transaction_session_timeout = '10min';
```

## AI Pair Programming Notes

**When working with transactions in pair programming:**

1. **Always show BEGIN/COMMIT**: Never show bare UPDATE/DELETE without transaction context
2. **Explain isolation level choice**: Clarify why you're using READ COMMITTED vs REPEATABLE READ
3. **Show retry logic**: Serialization failures require application-level retries
4. **Demonstrate deadlock prevention**: Always lock resources in same order
5. **Use FOR UPDATE examples**: Show when explicit locking is needed
6. **Explain MVCC benefits**: Readers don't block writers
7. **Show savepoint usage**: Partial rollback within transactions
8. **Mention lock timeouts**: Prevent hanging transactions
9. **Discuss transaction scope**: What operations should be in same transaction
10. **Show monitoring queries**: How to detect locks and deadlocks

**Common transaction mistakes to catch:**
- Missing BEGIN/COMMIT (relying on autocommit)
- Long-running transactions holding locks
- No retry logic for serialization failures
- Accessing resources in different order (deadlock risk)
- Using wrong isolation level
- Not handling errors properly (leaving transaction open)
- Forgetting ROLLBACK in error handlers

## Next Steps

1. **07-PERFORMANCE.md** - Query optimization and performance tuning
2. **08-PERFORMANCE.md** - Advanced performance topics
3. **10-REPLICATION.md** - Replication and high availability

## Additional Resources

- Transaction Isolation: https://www.postgresql.org/docs/current/transaction-iso.html
- MVCC: https://www.postgresql.org/docs/current/mvcc.html
- Locking: https://www.postgresql.org/docs/current/explicit-locking.html
- Deadlocks: https://wiki.postgresql.org/wiki/Lock_Monitoring
