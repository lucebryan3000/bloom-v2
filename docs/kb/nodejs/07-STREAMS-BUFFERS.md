# Node.js Streams & Buffers

```yaml
id: nodejs_07_streams_buffers
topic: Node.js
file_role: Streams (Readable, Writable, Transform, Duplex), Buffers, piping, backpressure
profile: full
difficulty_level: advanced
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Async Programming (02-ASYNC-PROGRAMMING.md)
  - Event Loop (03-EVENT-LOOP.md)
related_topics:
  - File System (05-FILE-SYSTEM.md)
  - HTTP Networking (06-HTTP-NETWORKING.md)
  - Performance (10-PERFORMANCE.md)
embedding_keywords:
  - nodejs streams
  - readable streams
  - writable streams
  - transform streams
  - buffers
  - pipe
  - backpressure
last_reviewed: 2025-11-17
```

## Streams Overview

**Streams** are collections of data that might not be available all at once and don't have to fit in memory. This makes streams powerful for working with large amounts of data or data coming from an external source one chunk at a time.

**Four Types of Streams:**

1. **Readable** - Read data (e.g., fs.createReadStream())
2. **Writable** - Write data (e.g., fs.createWriteStream())
3. **Duplex** - Both readable and writable (e.g., net.Socket)
4. **Transform** - Duplex streams that modify data (e.g., zlib.createGzip())

**Why use streams?**
- **Memory efficient** - Process large files without loading into memory
- **Time efficient** - Start processing immediately, don't wait for all data
- **Composability** - Chain operations with pipe()

```javascript
// ESM
import { createReadStream, createWriteStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';

// CommonJS
const { createReadStream, createWriteStream } = require('fs');
const { pipeline } = require('stream/promises');
```

## Readable Streams

### Creating Readable Streams

```javascript
import { Readable } from 'node:stream';

// ✅ GOOD - Custom readable stream
class NumberStream extends Readable {
  constructor(max, options) {
    super(options);
    this.max = max;
    this.current = 0;
  }

  _read() {
    if (this.current <= this.max) {
      this.push(`${this.current}\n`);
      this.current++;
    } else {
      this.push(null); // Signal end of stream
    }
  }
}

// Usage
const numbers = new NumberStream(10);
numbers.on('data', chunk => {
  console.log(chunk.toString());
});

numbers.on('end', () => {
  console.log('Stream ended');
});

// ✅ GOOD - Readable.from() for async iterables
const readable = Readable.from(['Hello', 'World', '!']);

for await (const chunk of readable) {
  console.log(chunk);
}
```

### Reading Modes

```javascript
// Mode 1: Flowing mode (event-based)
const stream = createReadStream('file.txt');

stream.on('data', (chunk) => {
  console.log(`Received ${chunk.length} bytes`);
});

stream.on('end', () => {
  console.log('No more data');
});

// Mode 2: Paused mode (pull-based)
stream.on('readable', () => {
  let chunk;
  while ((chunk = stream.read()) !== null) {
    console.log(`Read ${chunk.length} bytes`);
  }
});

// Mode 3: Async iteration (recommended)
for await (const chunk of stream) {
  console.log(`Chunk: ${chunk}`);
}
```

### Readable Stream Events

```javascript
const stream = createReadStream('file.txt');

stream.on('data', (chunk) => {
  // Data chunk available
  console.log('Data:', chunk);
});

stream.on('end', () => {
  // No more data
  console.log('Stream ended');
});

stream.on('error', (err) => {
  // Error occurred
  console.error('Error:', err);
});

stream.on('close', () => {
  // Stream closed (may not happen for all streams)
  console.log('Stream closed');
});

stream.on('pause', () => {
  // Stream paused
  console.log('Stream paused');
});

stream.on('resume', () => {
  // Stream resumed
  console.log('Stream resumed');
});
```

## Writable Streams

### Creating Writable Streams

```javascript
import { Writable } from 'node:stream';

// ✅ GOOD - Custom writable stream
class ConsoleStream extends Writable {
  _write(chunk, encoding, callback) {
    console.log(`Writing: ${chunk.toString()}`);
    callback(); // Signal write complete
  }

  _writev(chunks, callback) {
    // Optional: write multiple chunks at once
    chunks.forEach(({ chunk }) => {
      console.log(`Batch write: ${chunk.toString()}`);
    });
    callback();
  }

  _final(callback) {
    // Called before stream closes
    console.log('Stream finishing');
    callback();
  }
}

// Usage
const console Stream = new ConsoleStream();
consoleStream.write('Hello\n');
consoleStream.write('World\n');
consoleStream.end(); // Finish writing
```

### Writing to Streams

```javascript
import { createWriteStream } from 'node:fs';

const stream = createWriteStream('output.txt');

// ✅ GOOD - Check backpressure
function writeMillionTimes(stream, data, encoding) {
  let i = 1000000;

  write();

  function write() {
    let ok = true;

    while (i > 0 && ok) {
      i--;

      if (i === 0) {
        // Last write
        stream.write(data, encoding);
      } else {
        // See if we should continue, or wait for drain
        ok = stream.write(data, encoding);
      }
    }

    if (i > 0) {
      // Buffer is full, wait for drain
      stream.once('drain', write);
    }
  }
}

writeMillionTimes(stream, 'simple', 'utf8');

stream.end(); // Finish writing
```

### Writable Stream Events

```javascript
const stream = createWriteStream('file.txt');

stream.on('drain', () => {
  // Internal buffer emptied, safe to write more
  console.log('Drain - ready for more data');
});

stream.on('finish', () => {
  // All data written
  console.log('All data written');
});

stream.on('error', (err) => {
  // Error occurred
  console.error('Error:', err);
});

stream.on('close', () => {
  // Stream closed
  console.log('Stream closed');
});

stream.on('pipe', (src) => {
  // Source stream piped to this writable
  console.log('Pipe event');
});

stream.on('unpipe', (src) => {
  // Source stream unpiped
  console.log('Unpipe event');
});
```

## Backpressure Handling

```javascript
// ❌ BAD - Ignore backpressure (memory issues)
function badWrite(readable, writable) {
  readable.on('data', (chunk) => {
    writable.write(chunk); // Ignores return value!
  });
}

// ✅ GOOD - Handle backpressure
function goodWrite(readable, writable) {
  readable.on('data', (chunk) => {
    const canContinue = writable.write(chunk);

    if (!canContinue) {
      // Pause reading until drain
      readable.pause();
    }
  });

  writable.on('drain', () => {
    // Resume reading
    readable.resume();
  });
}

// ✅ BETTER - Use pipe (handles backpressure automatically)
readable.pipe(writable);

// ✅ BEST - Use pipeline (handles errors too)
import { pipeline } from 'node:stream/promises';

await pipeline(readable, writable);
```

## Transform Streams

### Creating Transform Streams

```javascript
import { Transform } from 'node:stream';

// ✅ GOOD - Uppercase transform
class UpperCaseTransform extends Transform {
  _transform(chunk, encoding, callback) {
    const upperChunk = chunk.toString().toUpperCase();
    this.push(upperChunk);
    callback();
  }
}

// Usage
const upperCase = new UpperCaseTransform();

process.stdin
  .pipe(upperCase)
  .pipe(process.stdout);

// ✅ GOOD - CSV to JSON transform
class CSVToJSON extends Transform {
  constructor(options) {
    super({ ...options, objectMode: true });
    this.headers = null;
  }

  _transform(chunk, encoding, callback) {
    const lines = chunk.toString().split('\n');

    lines.forEach(line => {
      if (!line.trim()) return;

      if (!this.headers) {
        this.headers = line.split(',');
      } else {
        const values = line.split(',');
        const obj = {};

        this.headers.forEach((header, index) => {
          obj[header] = values[index];
        });

        this.push(obj);
      }
    });

    callback();
  }
}
```

### Common Transform Patterns

```javascript
import { Transform } from 'node:stream';

// Filter transform
class FilterTransform extends Transform {
  constructor(predicate, options) {
    super({ ...options, objectMode: true });
    this.predicate = predicate;
  }

  _transform(chunk, encoding, callback) {
    if (this.predicate(chunk)) {
      this.push(chunk);
    }
    callback();
  }
}

// Map transform
class MapTransform extends Transform {
  constructor(mapper, options) {
    super({ ...options, objectMode: true });
    this.mapper = mapper;
  }

  _transform(chunk, encoding, callback) {
    try {
      const mapped = this.mapper(chunk);
      this.push(mapped);
      callback();
    } catch (err) {
      callback(err);
    }
  }
}

// Usage
const numbers = Readable.from([1, 2, 3, 4, 5]);

const filter = new FilterTransform(n => n % 2 === 0); // Even numbers only
const map = new MapTransform(n => n * 2); // Double them

pipeline(
  numbers,
  filter,
  map,
  async function* (source) {
    for await (const num of source) {
      console.log(num); // 4, 8
    }
  }
);
```

## Piping Streams

### Basic Piping

```javascript
import { createReadStream, createWriteStream } from 'node:fs';

// ✅ GOOD - Copy file with pipe
createReadStream('input.txt')
  .pipe(createWriteStream('output.txt'));

// ✅ GOOD - Chain multiple pipes
import { createGzip } from 'node:zlib';

createReadStream('file.txt')
  .pipe(createGzip())
  .pipe(createWriteStream('file.txt.gz'));

// ❌ BAD - No error handling with pipe
readable.pipe(writable); // What if error?

// ✅ GOOD - Handle errors
readable.pipe(writable);

readable.on('error', err => console.error('Read error:', err));
writable.on('error', err => console.error('Write error:', err));
```

### Pipeline (Recommended)

```javascript
import { pipeline } from 'node:stream/promises';
import { createReadStream, createWriteStream } from 'node:fs';
import { createGzip } from 'node:zlib';

// ✅ BEST - Use pipeline for error handling and cleanup
try {
  await pipeline(
    createReadStream('input.txt'),
    createGzip(),
    createWriteStream('input.txt.gz')
  );
  console.log('Pipeline succeeded');
} catch (err) {
  console.error('Pipeline failed:', err);
}

// Multiple transforms
await pipeline(
  createReadStream('data.csv'),
  new CSVToJSON(),
  new FilterTransform(row => row.age > 18),
  new MapTransform(row => ({ ...row, adult: true })),
  createWriteStream('adults.json')
);
```

## Buffers

### Creating Buffers

```javascript
// ✅ GOOD - Create buffers
const buf1 = Buffer.from('Hello', 'utf8');
const buf2 = Buffer.from([72, 101, 108, 108, 111]); // ASCII codes
const buf3 = Buffer.alloc(10); // Allocate 10 bytes (filled with zeros)
const buf4 = Buffer.allocUnsafe(10); // Faster but may contain old data

console.log(buf1.toString()); // 'Hello'
console.log(buf1.length); // 5 bytes
console.log(buf1[0]); // 72 (ASCII code for 'H')
```

### Buffer Operations

```javascript
// Reading
const buf = Buffer.from('Hello World');

console.log(buf.toString('utf8')); // 'Hello World'
console.log(buf.toString('hex')); // '48656c6c6f20576f726c64'
console.log(buf.toString('base64')); // 'SGVsbG8gV29ybGQ='

// Writing
const buf = Buffer.alloc(11);
buf.write('Hello', 0, 5, 'utf8');
buf.write(' World', 5, 6, 'utf8');
console.log(buf.toString()); // 'Hello World'

// Slicing (creates view, not copy)
const slice = buf.slice(0, 5);
console.log(slice.toString()); // 'Hello'

// Copying
const copy = Buffer.alloc(5);
buf.copy(copy, 0, 0, 5);

// Concatenating
const buf1 = Buffer.from('Hello');
const buf2 = Buffer.from(' World');
const combined = Buffer.concat([buf1, buf2]);
console.log(combined.toString()); // 'Hello World'

// Comparing
const buf1 = Buffer.from('ABC');
const buf2 = Buffer.from('BCD');
console.log(buf1.compare(buf2)); // -1 (buf1 < buf2)
```

### Buffer and String Encoding

```javascript
// Supported encodings
const encodings = [
  'utf8',      // Default
  'utf16le',
  'latin1',
  'base64',
  'hex',
  'ascii',
  'binary',
  'ucs2',
];

const text = 'Hello 👋';

// UTF-8 encoding (supports emoji)
const buf = Buffer.from(text, 'utf8');
console.log(buf.length); // 10 bytes (emoji takes 4 bytes)

// Base64 encoding
const base64 = buf.toString('base64');
console.log(base64); // 'SGVsbG8g8J+Riw=='

const decoded = Buffer.from(base64, 'base64');
console.log(decoded.toString('utf8')); // 'Hello 👋'
```

## Object Mode Streams

```javascript
import { Transform, Writable } from 'node:stream';

// ✅ GOOD - Object mode streams
const objectStream = new Transform({
  objectMode: true,

  transform(obj, encoding, callback) {
    // Process JavaScript objects directly
    this.push({
      ...obj,
      processed: true,
      timestamp: Date.now(),
    });
    callback();
  },
});

// Usage
Readable.from([
  { id: 1, name: 'Alice' },
  { id: 2, name: 'Bob' },
])
  .pipe(objectStream)
  .pipe(new Writable({
    objectMode: true,
    write(obj, encoding, callback) {
      console.log(obj);
      callback();
    },
  }));
```

## Stream Performance

### highWaterMark Tuning

```javascript
// Default highWaterMark is 16KB for streams

// ✅ GOOD - Increase for large files
const largeFileStream = createReadStream('large-file.dat', {
  highWaterMark: 64 * 1024, // 64KB chunks
});

// ✅ GOOD - Decrease for low memory
const lowMemoryStream = createReadStream('file.txt', {
  highWaterMark: 4 * 1024, // 4KB chunks
});
```

### Destroying Streams

```javascript
// ✅ GOOD - Cleanup streams
const stream = createReadStream('file.txt');

// Destroy stream (stop reading, release resources)
stream.destroy();

// Destroy with error
stream.destroy(new Error('Something went wrong'));

// Check if destroyed
if (stream.destroyed) {
  console.log('Stream destroyed');
}

// Listen for destroy event
stream.on('close', () => {
  console.log('Stream destroyed');
});
```

## AI Pair Programming Notes

**When working with streams:**

1. **Use pipeline()** - Better error handling than pipe()
2. **Handle backpressure** - Don't ignore write() return value
3. **Object mode for objects** - Set objectMode: true for non-buffer data
4. **Use async iterators** - Modern, clean way to consume streams
5. **Tune highWaterMark** - For performance with large files
6. **Always destroy streams** - Release resources when done
7. **Buffer encoding matters** - Specify encoding explicitly
8. **Use streams for large data** - Don't load everything into memory
9. **Pipeline over pipe** - Promise-based, better error handling
10. **Transform for processing** - Don't write custom readable/writable unless needed

**Common stream mistakes:**
- Ignoring backpressure (causes memory issues)
- Not handling stream errors
- Using pipe() without error handlers
- Not destroying streams (resource leaks)
- Loading large files into memory instead of streaming
- Mutating buffers (use copy/slice carefully)
- Not specifying encoding (defaults to buffer)
- Forgetting objectMode for non-buffer streams
- Using readFileSync/writeFileSync for large files
- Creating too many intermediate buffers

## Next Steps

1. **08-ERROR-HANDLING.md** - Error handling patterns
2. **10-PERFORMANCE.md** - Performance optimization
3. **05-FILE-SYSTEM.md** - Review file streams

## Additional Resources

- Stream API: https://nodejs.org/api/stream.html
- Buffer API: https://nodejs.org/api/buffer.html
- Stream Handbook: https://github.com/substack/stream-handbook
- Stream Tutorial: https://nodejs.dev/en/learn/nodejs-streams/
- Pipeline: https://nodejs.org/api/stream.html#streampipelinesource-transforms-destination-callback
