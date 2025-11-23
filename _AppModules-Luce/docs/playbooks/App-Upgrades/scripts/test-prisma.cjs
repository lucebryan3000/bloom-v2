#!/usr/bin/env node
// test-prisma.cjs - Test Prisma database connectivity and operations
// Usage: node _AppModules-Luce/playbooks/App-Upgrades/scripts/test-prisma.cjs (from project root)

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  log: ['error', 'warn'],
});

async function main() {
  console.log('=== Prisma Database Test ===\n');

  // Test 1: Database connection
  console.log('Test 1: Database Connection');
  try {
    await prisma.$connect();
    console.log('✅ Database connection: SUCCESS');
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    process.exit(1);
  }

  // Test 2: Simple query
  console.log('\nTest 2: Simple Query');
  try {
    const orgCount = await prisma.organization.count();
    console.log(`✅ Organization count: ${orgCount}`);
  } catch (error) {
    console.error('❌ Query failed:', error.message);
    process.exit(1);
  }

  // Test 3: Session count
  console.log('\nTest 3: Session Count');
  try {
    const sessionCount = await prisma.session.count();
    console.log(`✅ Session count: ${sessionCount}`);
  } catch (error) {
    console.error('❌ Session count failed:', error.message);
    process.exit(1);
  }

  // Test 4: User count
  console.log('\nTest 4: User Count');
  try {
    const userCount = await prisma.user.count();
    console.log(`✅ User count: ${userCount}`);
  } catch (error) {
    console.error('❌ User count failed:', error.message);
    process.exit(1);
  }

  // Test 5: Complex query with relations
  console.log('\nTest 5: Complex Query (Sessions with Organization)');
  try {
    const sessions = await prisma.session.findMany({
      take: 5,
      include: {
        organization: {
          select: {
            name: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
    console.log(`✅ Retrieved ${sessions.length} sessions with organization data`);
    if (sessions.length > 0) {
      console.log(`   Latest session: ${sessions[0].id.substring(0, 8)}...`);
      console.log(`   Organization: ${sessions[0].organization?.name || 'N/A'}`);
    }
  } catch (error) {
    console.error('❌ Complex query failed:', error.message);
    process.exit(1);
  }

  // Test 6: Transaction support
  console.log('\nTest 6: Transaction Support');
  try {
    const result = await prisma.$transaction([
      prisma.organization.count(),
      prisma.session.count(),
      prisma.user.count(),
    ]);
    console.log('✅ Transaction executed successfully');
    console.log(`   Results: Organizations=${result[0]}, Sessions=${result[1]}, Users=${result[2]}`);
  } catch (error) {
    console.error('❌ Transaction failed:', error.message);
    process.exit(1);
  }

  // Test 7: Schema introspection
  console.log('\nTest 7: Schema Introspection');
  try {
    // Check if all main models are accessible
    const models = ['organization', 'session', 'user', 'roiReport'];
    for (const model of models) {
      if (prisma[model]) {
        console.log(`✅ Model '${model}': ACCESSIBLE`);
      } else {
        console.log(`⚠️  Model '${model}': NOT FOUND`);
      }
    }
  } catch (error) {
    console.error('❌ Schema introspection failed:', error.message);
    process.exit(1);
  }

  console.log('\n=== All Prisma tests passed! ✅ ===');
  console.log('\nDatabase is ready for upgrades.');
  console.log('Remember to run migrations after Prisma version changes:');
  console.log('  npx prisma migrate dev');
  console.log('  npx prisma generate');
}

main()
  .catch((error) => {
    console.error('\n❌ Test suite failed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
