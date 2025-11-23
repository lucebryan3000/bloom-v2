# Node.js Event Loop

```yaml
id: nodejs_03_event_loop
topic: Node.js
file_role: Event loop phases, timers, process.nextTick, setImmediate
profile: full
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Async Programming (02-ASYNC-PROGRAMMING.md)
related_topics:
  - Performance (10-PERFORMANCE.md)
  - Async Programming (02-ASYNC-PROGRAMMING.md)
embedding_keywords:
  - nodejs event loop
  - event loop phases
  - process.nextTick
  - setImmediate
  - timers
  - microtasks
last_reviewed: 2025-11-17
```

## Event Loop Overview

**The Node.js event loop** is what allows Node.js to perform non-blocking I/O operations despite JavaScript being single-threaded — by offloading operations to the system kernel whenever possible.

**Core Concepts:**
1. **Single-threaded** - JavaScript executes on one thread
2. **Non-blocking I/O** - Async operations don't block execution
3. **Event-driven** - Callbacks triggered by events
4. **Libuv** - C library that implements the event loop
5. **Phases** - Event loop operates in distinct phases

## Event Loop Phases

```
   â"Œâ"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"
   â"‚         timers          â"‚ <-- setTimeout/setInterval callbacks
   â""â"€â"€â"€â"€â"€â"€â"€â"€â"€â"¬â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
   â"Œâ"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"´â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"
   â"‚   pending callbacks     â"‚ <-- I/O callbacks deferred to next loop
   â""â"€â"€â"€â"€â"€â"€â"€â"€â"€â"¬â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
   â"Œâ"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"´â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"
   â"‚       idle, prepare      â"‚ <-- Internal use only
   â""â"€â"€â"€â"€â"€â"€â"€â"€â"€â"¬â"€â"€â"€â"€â"€â"€â"€â"€â"€â"¬â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
   â"Œâ"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"´â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"´â"€â"€â"€â"€â"€â"€â"€â"€â"€â"
   â"‚           poll          â"‚ <-- Retrieve new I/O events
   â""â"€â"€â"€â"€â"€â"€â"€â"€â"€â"¬â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
   â"Œâ"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"´â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"
   â"‚         check           â"‚ <-- setImmediate() callbacks
   â""â"€â"€â"€â"€â"€â"€â"€â"€â"€â"¬â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
   â"Œâ"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"´â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"
   â"‚      close callbacks     â"‚ <-- socket.on('close', ...)
   â""â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"˜

Between each phase: process.nextTick() and microtasks (Promises)
```

### Phase Descriptions

**1. Timers Phase**
- Executes callbacks scheduled by `setTimeout()` and `setInterval()`
- Timers specify the threshold after which a callback may be executed
- Not the exact time a callback will be executed
- Limited by system scheduling and other callbacks

**2. Pending Callbacks Phase**
- Executes I/O callbacks deferred to the next loop iteration
- Rare phase, used for system operations

**3. Idle, Prepare Phase**
- Used internally by Node.js
- Not directly accessible to developers

**4. Poll Phase** (Most important)
- Retrieve new I/O events
- Execute I/O-related callbacks (except close, timers, setImmediate)
- Block here when appropriate
- Two main functions:
  - Calculating how long to block and poll for I/O
  - Processing events in the poll queue

**5. Check Phase**
- `setImmediate()` callbacks are invoked here
- Allows execution immediately after the poll phase

**6. Close Callbacks Phase**
- Close event callbacks (e.g., `socket.on('close', ...)`)

## process.nextTick()

**NOT part of the event loop phases** - executes immediately after current operation, before event loop continues.

```javascript
// process.nextTick() executes BEFORE any I/O operations
console.log('1: Script start');

setTimeout(() => console.log('2: setTimeout'), 0);

setImmediate(() => console.log('3: setImmediate'));

process.nextTick(() => console.log('4: nextTick'));

Promise.resolve().then(() => console.log('5: Promise'));

console.log('6: Script end');

// Output order:
// 1: Script start
// 6: Script end
// 4: nextTick  <-- Runs first after synchronous code
// 5: Promise   <-- Microtask queue (Promises)
// 2: setTimeout <-- Timers phase
// 3: setImmediate <-- Check phase
```

### nextTick vs setImmediate

```javascript
// ❌ WRONG - Common confusion
// "nextTick" sounds like it runs next, but it runs NOW

// ✅ CORRECT - Execution order
process.nextTick(() => {
  console.log('nextTick: Runs IMMEDIATELY after current operation');
});

setImmediate(() => {
  console.log('setImmediate: Runs in NEXT event loop iteration (check phase)');
});

// Think of it as:
// - process.nextTick() = "run this RIGHT NOW" (after current JS)
// - setImmediate() = "run this in the next loop iteration"
```

### nextTick Use Cases

```javascript
// ✅ GOOD - Emit events after object is constructed
const EventEmitter = require('events');

class DatabaseConnection extends EventEmitter {
  constructor() {
    super();

    // Allow listeners to be registered before emitting
    process.nextTick(() => {
      this.emit('connected');
    });
  }
}

const db = new DatabaseConnection();
db.on('connected', () => console.log('Database connected!'));

// ✅ GOOD - Handle errors asynchronously
function asyncOperation(callback) {
  if (typeof callback !== 'function') {
    // Make error async to match async path
    process.nextTick(() => {
      throw new TypeError('Callback must be a function');
    });
    return;
  }

  // Actual async operation
  fs.readFile('/path', callback);
}

// ❌ BAD - Recursive nextTick can starve I/O
let count = 0;
function recursiveNextTick() {
  process.nextTick(() => {
    count++;
    if (count < 1000000) {
      recursiveNextTick(); // This will block I/O!
    }
  });
}
```

## Timers (setTimeout, setInterval)

### setTimeout

```javascript
// Basic setTimeout
setTimeout(() => {
  console.log('Executed after ~1000ms');
}, 1000);

// ⚠️ IMPORTANT: Timing is not exact
console.time('timer');
setTimeout(() => {
  console.timeEnd('timer'); // May be 1001ms, 1005ms, etc.
}, 1000);

// Passing arguments
setTimeout((name, age) => {
  console.log(`${name} is ${age} years old`);
}, 1000, 'Alice', 25);

// Clearing timeout
const timeoutId = setTimeout(() => {
  console.log('This will not run');
}, 5000);

clearTimeout(timeoutId);

// ✅ GOOD - Cleanup pattern
class Service {
  constructor() {
    this.timeoutIds = new Set();
  }

  scheduleTask(fn, delay) {
    const id = setTimeout(() => {
      this.timeoutIds.delete(id);
      fn();
    }, delay);

    this.timeoutIds.add(id);
  }

  cleanup() {
    // Clear all pending timeouts
    this.timeoutIds.forEach(id => clearTimeout(id));
    this.timeoutIds.clear();
  }
}
```

### setInterval

```javascript
// Basic setInterval
const intervalId = setInterval(() => {
  console.log('Executed every 1000ms');
}, 1000);

// Stop after 5 seconds
setTimeout(() => {
  clearInterval(intervalId);
}, 5000);

// ❌ BAD - Interval drift (tasks can overlap)
setInterval(async () => {
  await longRunningTask(); // If this takes > 1s, overlaps occur
}, 1000);

// ✅ GOOD - Recursive setTimeout (prevents overlap)
async function scheduleTask() {
  await longRunningTask();

  setTimeout(scheduleTask, 1000); // Schedule next after completion
}
scheduleTask();

// ✅ GOOD - Self-correcting interval
class AccurateInterval {
  constructor(fn, interval) {
    this.fn = fn;
    this.interval = interval;
    this.expected = Date.now() + interval;
    this.timeoutId = null;
  }

  start() {
    this.step();
  }

  step() {
    const drift = Date.now() - this.expected;

    this.fn();

    this.expected += this.interval;
    this.timeoutId = setTimeout(() => this.step(), Math.max(0, this.interval - drift));
  }

  stop() {
    clearTimeout(this.timeoutId);
  }
}

// Usage
const timer = new AccurateInterval(() => {
  console.log('Accurate timing', new Date());
}, 1000);
timer.start();
```

## setImmediate

**Executes in the check phase** - after poll phase completes.

```javascript
// setImmediate vs setTimeout(0)
setImmediate(() => {
  console.log('setImmediate');
});

setTimeout(() => {
  console.log('setTimeout');
}, 0);

// Order is non-deterministic when called from main module
// But deterministic when called within I/O cycle

// ✅ DETERMINISTIC - Inside I/O cycle
const fs = require('fs');

fs.readFile(__filename, () => {
  // Inside poll phase

  setTimeout(() => {
    console.log('timeout'); // Second
  }, 0);

  setImmediate(() => {
    console.log('immediate'); // First (check phase is next)
  });
});

// Output: immediate, timeout (always)
```

### setImmediate Use Cases

```javascript
// ✅ GOOD - Break up long computations
function processLargeArray(array) {
  let index = 0;

  function processChunk() {
    const chunkSize = 1000;
    const end = Math.min(index + chunkSize, array.length);

    for (; index < end; index++) {
      // Process array[index]
      array[index] = array[index] * 2;
    }

    if (index < array.length) {
      // Schedule next chunk, allowing I/O to process
      setImmediate(processChunk);
    }
  }

  processChunk();
}

// ✅ GOOD - Recursive file processing
function processDirectory(dir, callback) {
  fs.readdir(dir, (err, files) => {
    if (err) return callback(err);

    let pending = files.length;
    if (pending === 0) return callback(null);

    files.forEach(file => {
      // Use setImmediate to prevent stack overflow
      setImmediate(() => {
        const filePath = path.join(dir, file);

        fs.stat(filePath, (err, stats) => {
          if (stats && stats.isDirectory()) {
            processDirectory(filePath, () => {
              if (--pending === 0) callback(null);
            });
          } else {
            if (--pending === 0) callback(null);
          }
        });
      });
    });
  });
}
```

## Microtasks (Promises)

**Microtasks execute between event loop phases**, after each phase completes.

```javascript
// Execution order demonstration
console.log('1: Sync');

setTimeout(() => console.log('2: Timer'), 0);

Promise.resolve()
  .then(() => console.log('3: Promise 1'))
  .then(() => console.log('4: Promise 2'));

process.nextTick(() => console.log('5: nextTick 1'));
process.nextTick(() => console.log('6: nextTick 2'));

console.log('7: Sync end');

// Output:
// 1: Sync
// 7: Sync end
// 5: nextTick 1    <-- nextTick queue first
// 6: nextTick 2
// 3: Promise 1     <-- Microtask queue (Promises)
// 4: Promise 2
// 2: Timer         <-- Timers phase

// Between EVERY phase:
// 1. Process ALL nextTick callbacks
// 2. Process ALL microtasks (Promises)
// 3. Continue to next phase
```

### Microtask Queue vs Macrotask Queue

```javascript
// Microtasks: process.nextTick(), Promises
// Macrotasks: setTimeout, setInterval, setImmediate, I/O

// Microtasks have priority - all processed before next macrotask
Promise.resolve().then(() => {
  console.log('Promise 1');

  Promise.resolve().then(() => {
    console.log('Promise 2');
  });
});

setTimeout(() => {
  console.log('Timeout');
}, 0);

// Output:
// Promise 1
// Promise 2  <-- Nested promise runs before timeout
// Timeout
```

## Event Loop Blocking

### Identifying Blocking Code

```javascript
// ❌ BAD - Blocks event loop
function blockingOperation() {
  const start = Date.now();
  while (Date.now() - start < 5000) {
    // CPU-intensive loop for 5 seconds
    // Event loop is BLOCKED - no I/O, no timers
  }
  console.log('Done blocking');
}

// ❌ BAD - Synchronous file I/O blocks
const fs = require('fs');
const data = fs.readFileSync('/large/file.txt', 'utf8'); // BLOCKS

// ✅ GOOD - Async file I/O doesn't block
fs.readFile('/large/file.txt', 'utf8', (err, data) => {
  // Event loop continues while reading
});

// ✅ GOOD - Promise-based async
const data = await fs.promises.readFile('/large/file.txt', 'utf8');
```

### Breaking Up Blocking Operations

```javascript
// ✅ GOOD - Use setImmediate to yield
function processHugeArray(array, callback) {
  let index = 0;

  function doChunk() {
    const chunkSize = 1000;
    const end = Math.min(index + chunkSize, array.length);

    for (; index < end; index++) {
      // CPU-intensive work
      array[index] = expensiveCalculation(array[index]);
    }

    if (index < array.length) {
      // Yield to event loop
      setImmediate(doChunk);
    } else {
      callback();
    }
  }

  doChunk();
}

// ✅ GOOD - Worker threads for CPU-heavy work
const { Worker } = require('worker_threads');

function runHeavyComputation(data) {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./heavy-computation.js');

    worker.on('message', resolve);
    worker.on('error', reject);
    worker.on('exit', (code) => {
      if (code !== 0) reject(new Error(`Worker stopped with code ${code}`));
    });

    worker.postMessage(data);
  });
}
```

## Monitoring Event Loop

### Event Loop Lag Detection

```javascript
// Measure event loop lag
class EventLoopMonitor {
  constructor(threshold = 100) {
    this.threshold = threshold;
    this.expected = Date.now();
  }

  start() {
    this.check();
  }

  check() {
    const now = Date.now();
    const lag = now - this.expected;

    if (lag > this.threshold) {
      console.warn(`Event loop lag: ${lag}ms`);
    }

    this.expected = now + 1000;
    setTimeout(() => this.check(), 1000);
  }
}

const monitor = new EventLoopMonitor(50);
monitor.start();
```

## AI Pair Programming Notes

**When working with the event loop:**

1. **Prefer async operations** - Never use synchronous I/O in production
2. **Understand phase order** - Know when callbacks execute
3. **Use nextTick sparingly** - Can starve I/O if overused
4. **Use setImmediate for long tasks** - Break up CPU-intensive work
5. **Monitor event loop lag** - Detect blocking operations
6. **Avoid blocking operations** - Use worker threads for CPU work
7. **Be careful with recursion** - Use setImmediate to prevent stack overflow
8. **Clean up timers** - Always clear timeouts/intervals when done
9. **Promises are microtasks** - Execute between phases
10. **Don't block in main thread** - Offload heavy computation

**Common event loop mistakes:**
- Using synchronous file operations (readFileSync, etc.)
- Recursive process.nextTick() calls
- Long-running synchronous computations
- Not clearing timers/intervals
- Expecting exact timing from setTimeout/setInterval
- Confusing nextTick vs setImmediate
- Blocking event loop with CPU-intensive work
- Not yielding to I/O in long loops
- Memory leaks from uncancelled timers
- Not understanding microtask vs macrotask priority

## Next Steps

1. **04-MODULES.md** - Module systems and imports
2. **10-PERFORMANCE.md** - Performance optimization
3. **02-ASYNC-PROGRAMMING.md** - Review async patterns

## Additional Resources

- Official Event Loop Guide: https://nodejs.org/en/docs/guides/event-loop-timers-and-nexttick
- Understanding process.nextTick(): https://nodejs.org/en/learn/asynchronous-work/understanding-processnexttick
- Event Loop Visualization: http://latentflip.com/loupe/
- Node.js Event Loop Deep Dive: https://blog.insiderattack.net/event-loop-and-the-big-picture-nodejs-event-loop-part-1-1cb67a182810
