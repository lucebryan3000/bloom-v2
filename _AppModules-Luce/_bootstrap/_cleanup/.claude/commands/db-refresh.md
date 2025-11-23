# Database Refresh Command

Reset the database to a clean state and reseed with test data.

## Usage
```
/db-refresh
```

## What This Does

1. **Stops** any running processes using the database
2. **Removes** WAL and SHM files
3. **Deletes** the existing database file
4. **Runs** Prisma migrations to recreate schema
5. **Seeds** database with test data
6. **Verifies** data integrity

## ⚠️ Warning

This command will **delete all existing data** in the database. Use with caution.

## Steps Executed

```bash
# 1. Remove SQLite auxiliary files
rm -f prisma/bloom.db-wal
rm -f prisma/bloom.db-shm

# 2. Delete database
rm -f prisma/bloom.db

# 3. Run migrations
npx prisma migrate dev --name init

# 4. Generate Prisma client
npx prisma generate

# 5. Seed database
npx prisma db seed

# 6. Verify
npx prisma studio
```

## Seed Data

The command creates test data including:

### Organizations (3)
- **TechCorp** (Technology, Medium)
- **RetailCo** (Retail, Large)
- **ServiceHub** (Services, Small)

### Users (5)
- admin@techcorp.com (admin role)
- user@techcorp.com (user role)
- manager@retailco.com (user role)
- analyst@servicehub.com (user role)
- demo@demo.com (demo role)

### Sample Sessions (2)
- Completed session with full ROI report
- Active session mid-conversation

### Question Templates (17)
- 5 Discovery questions
- 4 Metrics questions
- 3 Validation questions
- 5 Calculation questions

### Industry Benchmarks (25)
- Technology sector benchmarks
- Retail sector benchmarks
- Services sector benchmarks
- Manufacturing benchmarks
- Healthcare benchmarks

## Verification

After refresh, the command verifies:

```sql
-- Check tables created
SELECT name FROM sqlite_master WHERE type='table';

-- Count records
SELECT 'Organizations' as table_name, COUNT(*) as count FROM Organization
UNION ALL
SELECT 'Users', COUNT(*) FROM User
UNION ALL
SELECT 'Sessions', COUNT(*) FROM Session
UNION ALL
SELECT 'QuestionTemplates', COUNT(*) FROM QuestionTemplate
UNION ALL
SELECT 'IndustryBenchmarks', COUNT(*) FROM IndustryBenchmark;
```

Expected counts:
- Organizations: 3
- Users: 5
- Sessions: 2
- QuestionTemplates: 17
- IndustryBenchmarks: 25

## When to Use

Use this command when:
- **Starting fresh** after pulling new schema changes
- **Test data corrupted** and you need clean slate
- **Database locked** errors persist
- **Migration issues** and you want to rebuild
- **Before demos** to ensure clean, predictable data

## What to Do After

After database refresh:

1. **Restart dev server** if running
   ```bash
   # Stop current server (Ctrl+C)
   npm run dev
   ```

2. **Login with test credentials**
   - Email: demo@demo.com
   - Password: demo123 (check seed file for actual password)

3. **Verify in Prisma Studio**
   ```bash
   npx prisma studio
   # Opens at http://localhost:5555
   ```

4. **Test a session**
   - Navigate to `/demo`
   - Start a new Melissa session
   - Verify data saves correctly

## Troubleshooting

### "Database is locked" error
```bash
# Kill any Node processes using the DB
pkill -f "node"

# Then run refresh again
/db-refresh
```

### Migrations fail
```bash
# Reset migrations completely
rm -rf prisma/migrations
npx prisma migrate dev --name init
```

### Seed fails
```bash
# Check the seed script
cat prisma/seed.ts

# Run seed manually with verbose output
npx prisma db seed --verbose
```

## Environment Variables Needed

Ensure `.env.local` has:
```env
DATABASE_URL="file:./bloom.db?mode=wal"
```

## Related Commands

- `/test-melissa` - Test with fresh data after refresh
- `/quick-test` - Verify everything works after refresh
- `/check-progress` - See what phases work with new DB
