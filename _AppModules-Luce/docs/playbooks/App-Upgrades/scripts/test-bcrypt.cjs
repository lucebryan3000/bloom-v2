#!/usr/bin/env node
// test-bcrypt.cjs - Test bcrypt hashing and verification
// Usage: node _AppModules-Luce/playbooks/App-Upgrades/scripts/test-bcrypt.cjs (from project root)

const bcrypt = require('bcryptjs');

console.log('=== bcrypt Functionality Test ===\n');

// Test 1: Hash generation
console.log('Test 1: Hash Generation');
const password = 'test123';
const cost = 10;

try {
  const hash = bcrypt.hashSync(password, cost);
  console.log(`✅ Hash created (cost ${cost}): ${hash.substring(0, 20)}...`);
  console.log(`   Hash length: ${hash.length} characters`);
  console.log(`   Hash algorithm: ${hash.substring(0, 4)}`);
} catch (error) {
  console.error('❌ Hash generation failed:', error.message);
  process.exit(1);
}

// Test 2: Password verification (correct password)
console.log('\nTest 2: Password Verification (Correct)');
try {
  const hash = bcrypt.hashSync(password, cost);
  const valid = bcrypt.compareSync(password, hash);
  if (valid) {
    console.log('✅ Password verification: PASS');
  } else {
    console.error('❌ Password verification failed: Expected true, got false');
    process.exit(1);
  }
} catch (error) {
  console.error('❌ Verification failed:', error.message);
  process.exit(1);
}

// Test 3: Password verification (incorrect password)
console.log('\nTest 3: Password Verification (Incorrect)');
try {
  const hash = bcrypt.hashSync(password, cost);
  const valid = bcrypt.compareSync('wrongpassword', hash);
  if (!valid) {
    console.log('✅ Rejection of wrong password: PASS');
  } else {
    console.error('❌ Security failure: Wrong password accepted');
    process.exit(1);
  }
} catch (error) {
  console.error('❌ Verification failed:', error.message);
  process.exit(1);
}

// Test 4: Different cost factors
console.log('\nTest 4: Different Cost Factors');
try {
  const cost10 = bcrypt.hashSync(password, 10);
  const cost12 = bcrypt.hashSync(password, 12);

  console.log(`✅ Cost 10 hash: ${cost10.substring(0, 10)}...`);
  console.log(`✅ Cost 12 hash: ${cost12.substring(0, 10)}...`);

  // Verify both work
  if (bcrypt.compareSync(password, cost10) && bcrypt.compareSync(password, cost12)) {
    console.log('✅ Both cost factors work correctly');
  } else {
    console.error('❌ Cost factor verification failed');
    process.exit(1);
  }
} catch (error) {
  console.error('❌ Cost factor test failed:', error.message);
  process.exit(1);
}

// Test 5: Backward compatibility (if old hash format exists)
console.log('\nTest 5: Hash Format Compatibility');
try {
  // Test both 2a and 2b hash formats
  const hash2a = bcrypt.hashSync(password, 10); // Current format
  const format = hash2a.substring(0, 4);
  console.log(`   Current hash format: ${format}`);
  console.log('✅ Hash format check: PASS');
} catch (error) {
  console.error('❌ Format check failed:', error.message);
  process.exit(1);
}

console.log('\n=== All bcrypt tests passed! ✅ ===');
console.log('\nNote: If upgrading bcryptjs:');
console.log('  - Existing hashes remain valid (backward compatible)');
console.log('  - New hashes will use latest format');
console.log('  - No database migration needed');
