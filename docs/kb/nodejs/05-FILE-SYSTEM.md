# Node.js File System

```yaml
id: nodejs_05_file_system
topic: Node.js
file_role: File system operations, fs module, promises, streams, file I/O
profile: full
difficulty_level: intermediate
kb_version: v3.1
prerequisites:
  - Fundamentals (01-FUNDAMENTALS.md)
  - Async Programming (02-ASYNC-PROGRAMMING.md)
related_topics:
  - Streams (07-STREAMS-BUFFERS.md)
  - Error Handling (08-ERROR-HANDLING.md)
embedding_keywords:
  - nodejs fs
  - file system
  - readFile
  - writeFile
  - fs promises
  - file streams
  - file operations
last_reviewed: 2025-11-17
```

## File System Overview

**Three APIs for file operations:**

1. **Promise-based (`fs/promises`)** - ✅ RECOMMENDED for modern code
2. **Callback-based (`fs`)** - Traditional Node.js API
3. **Synchronous (`fs`)** - ❌ Blocks event loop, avoid in production

```javascript
// ✅ RECOMMENDED - Promise-based (ESM)
import { readFile, writeFile } from 'node:fs/promises';

// ✅ RECOMMENDED - Promise-based (CommonJS)
const { readFile, writeFile } = require('fs').promises;

// ⚠️ Callback-based (legacy)
const fs = require('fs');
fs.readFile('file.txt', (err, data) => {});

// ❌ Synchronous (blocks event loop!)
const fs = require('fs');
const data = fs.readFileSync('file.txt'); // DON'T USE IN PRODUCTION
```

## Reading Files

### Promise-based Reading

```javascript
import { readFile } from 'node:fs/promises';

// ✅ GOOD - Read text file
async function readTextFile() {
  try {
    const data = await readFile('file.txt', 'utf8');
    console.log(data);
  } catch (err) {
    console.error('Error reading file:', err);
  }
}

// ✅ GOOD - Read binary file
async function readBinaryFile() {
  try {
    const buffer = await readFile('image.png'); // Returns Buffer
    console.log(`File size: ${buffer.length} bytes`);
  } catch (err) {
    console.error('Error reading file:', err);
  }
}

// ✅ GOOD - Read JSON file
async function readJSONFile(path) {
  try {
    const data = await readFile(path, 'utf8');
    return JSON.parse(data);
  } catch (err) {
    if (err.code === 'ENOENT') {
      console.error('File not found');
    } else if (err instanceof SyntaxError) {
      console.error('Invalid JSON');
    } else {
      console.error('Error:', err);
    }
    throw err;
  }
}
```

### Callback-based Reading (Legacy)

```javascript
const fs = require('fs');

// ⚠️ Legacy pattern
fs.readFile('file.txt', 'utf8', (err, data) => {
  if (err) {
    console.error('Error:', err);
    return;
  }
  console.log(data);
});
```

## Writing Files

### Promise-based Writing

```javascript
import { writeFile, appendFile } from 'node:fs/promises';

// ✅ GOOD - Write text file
async function writeTextFile(path, content) {
  try {
    await writeFile(path, content, 'utf8');
    console.log('File written successfully');
  } catch (err) {
    console.error('Error writing file:', err);
  }
}

// ✅ GOOD - Write JSON file
async function writeJSONFile(path, data) {
  try {
    const json = JSON.stringify(data, null, 2);
    await writeFile(path, json, 'utf8');
  } catch (err) {
    console.error('Error writing JSON:', err);
  }
}

// ✅ GOOD - Append to file
async function appendToFile(path, content) {
  try {
    await appendFile(path, content + '\n', 'utf8');
  } catch (err) {
    console.error('Error appending:', err);
  }
}

// ✅ GOOD - Atomic write with rename
import { writeFile, rename } from 'node:fs/promises';

async function atomicWrite(path, content) {
  const tempPath = `${path}.tmp`;

  try {
    await writeFile(tempPath, content, 'utf8');
    await rename(tempPath, path); // Atomic operation
  } catch (err) {
    // Clean up temp file on error
    try {
      await unlink(tempPath);
    } catch {}
    throw err;
  }
}
```

### File Permissions and Modes

```javascript
import { writeFile, chmod } from 'node:fs/promises';

// Write file with specific permissions
await writeFile('script.sh', '#!/bin/bash\necho "Hello"', {
  encoding: 'utf8',
  mode: 0o755, // rwxr-xr-x
});

// Change permissions after creation
await chmod('file.txt', 0o644); // rw-r--r--

// Common modes:
// 0o644 - rw-r--r-- (owner can write, others can read)
// 0o755 - rwxr-xr-x (owner can execute, others can read/execute)
// 0o600 - rw------- (owner only)
```

## Directory Operations

### Creating Directories

```javascript
import { mkdir, access } from 'node:fs/promises';
import { constants } from 'node:fs';

// ✅ GOOD - Create directory (recursive)
async function ensureDir(path) {
  try {
    await mkdir(path, { recursive: true });
  } catch (err) {
    console.error('Error creating directory:', err);
  }
}

// Check if directory exists
async function dirExists(path) {
  try {
    await access(path, constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

// Create directory only if it doesn't exist
async function createDirIfNotExists(path) {
  if (!(await dirExists(path))) {
    await mkdir(path, { recursive: true });
  }
}
```

### Reading Directories

```javascript
import { readdir, stat } from 'node:fs/promises';
import { join } from 'node:path';

// ✅ GOOD - List files in directory
async function listFiles(dirPath) {
  try {
    const files = await readdir(dirPath);
    return files;
  } catch (err) {
    console.error('Error reading directory:', err);
    return [];
  }
}

// ✅ GOOD - List files with details
async function listFilesWithDetails(dirPath) {
  try {
    const files = await readdir(dirPath, { withFileTypes: true });

    return files.map(file => ({
      name: file.name,
      isDirectory: file.isDirectory(),
      isFile: file.isFile(),
      isSymlink: file.isSymbolicLink(),
    }));
  } catch (err) {
    console.error('Error:', err);
    return [];
  }
}

// ✅ GOOD - Recursive directory traversal
async function* walkDirectory(dir) {
  const entries = await readdir(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = join(dir, entry.name);

    if (entry.isDirectory()) {
      yield* walkDirectory(fullPath); // Recursive
    } else {
      yield fullPath;
    }
  }
}

// Usage
for await (const filePath of walkDirectory('./src')) {
  console.log(filePath);
}
```

### Deleting Files and Directories

```javascript
import { unlink, rm, rmdir } from 'node:fs/promises';

// ✅ GOOD - Delete file
async function deleteFile(path) {
  try {
    await unlink(path);
    console.log('File deleted');
  } catch (err) {
    if (err.code === 'ENOENT') {
      console.log('File does not exist');
    } else {
      console.error('Error deleting file:', err);
    }
  }
}

// ✅ GOOD - Delete empty directory
async function deleteEmptyDir(path) {
  try {
    await rmdir(path);
  } catch (err) {
    console.error('Error deleting directory:', err);
  }
}

// ✅ GOOD - Delete directory recursively (Node.js 14+)
async function deleteDirectory(path) {
  try {
    await rm(path, { recursive: true, force: true });
    console.log('Directory deleted');
  } catch (err) {
    console.error('Error deleting directory:', err);
  }
}
```

## File Information

### Getting File Stats

```javascript
import { stat, lstat } from 'node:fs/promises';

// ✅ GOOD - Get file information
async function getFileInfo(path) {
  try {
    const stats = await stat(path);

    return {
      size: stats.size,
      created: stats.birthtime,
      modified: stats.mtime,
      accessed: stats.atime,
      isFile: stats.isFile(),
      isDirectory: stats.isDirectory(),
      isSymlink: stats.isSymbolicLink(),
      permissions: stats.mode,
    };
  } catch (err) {
    console.error('Error getting file info:', err);
    return null;
  }
}

// Check file size
async function getFileSize(path) {
  const stats = await stat(path);
  return stats.size;
}

// Check if file was modified recently
async function wasModifiedRecently(path, hours = 24) {
  const stats = await stat(path);
  const modifiedTime = stats.mtime.getTime();
  const threshold = Date.now() - (hours * 60 * 60 * 1000);

  return modifiedTime > threshold;
}
```

### Checking File Existence

```javascript
import { access, stat } from 'node:fs/promises';
import { constants } from 'node:fs';

// ✅ GOOD - Check if file exists
async function fileExists(path) {
  try {
    await access(path, constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

// Check if file is readable
async function isReadable(path) {
  try {
    await access(path, constants.R_OK);
    return true;
  } catch {
    return false;
  }
}

// Check if file is writable
async function isWritable(path) {
  try {
    await access(path, constants.W_OK);
    return true;
  } catch {
    return false;
  }
}

// ❌ DON'T USE - fs.existsSync() is synchronous
// if (fs.existsSync(path)) { } // Blocks event loop!

// ✅ USE - async access instead
if (await fileExists(path)) { }
```

## File Operations

### Copying Files

```javascript
import { copyFile, cp } from 'node:fs/promises';
import { constants } from 'node:fs';

// ✅ GOOD - Copy single file
async function copy(src, dest) {
  try {
    await copyFile(src, dest);
    console.log('File copied');
  } catch (err) {
    console.error('Error copying file:', err);
  }
}

// Copy with overwrite protection
async function safeCopy(src, dest) {
  try {
    await copyFile(src, dest, constants.COPYFILE_EXCL); // Fail if exists
  } catch (err) {
    if (err.code === 'EEXIST') {
      console.error('Destination already exists');
    } else {
      console.error('Error:', err);
    }
  }
}

// ✅ GOOD - Copy directory recursively (Node.js 16+)
async function copyDirectory(src, dest) {
  try {
    await cp(src, dest, { recursive: true });
  } catch (err) {
    console.error('Error copying directory:', err);
  }
}
```

### Moving/Renaming Files

```javascript
import { rename, copyFile, unlink } from 'node:fs/promises';

// ✅ GOOD - Rename/move file
async function moveFile(src, dest) {
  try {
    await rename(src, dest);
  } catch (err) {
    if (err.code === 'EXDEV') {
      // Cross-device move - copy then delete
      await copyFile(src, dest);
      await unlink(src);
    } else {
      throw err;
    }
  }
}
```

## File Streams

### Reading Large Files with Streams

```javascript
import { createReadStream } from 'node:fs';

// ✅ GOOD - Read large file without loading into memory
function readLargeFile(path) {
  const stream = createReadStream(path, { encoding: 'utf8' });

  stream.on('data', (chunk) => {
    console.log(`Received ${chunk.length} bytes`);
    // Process chunk
  });

  stream.on('end', () => {
    console.log('Finished reading file');
  });

  stream.on('error', (err) => {
    console.error('Error reading file:', err);
  });
}

// ✅ GOOD - Read file line by line
import { createReadStream } from 'node:fs';
import { createInterface } from 'node:readline';

async function processFileLineByLine(path) {
  const fileStream = createReadStream(path);
  const rl = createInterface({
    input: fileStream,
    crlfDelay: Infinity,
  });

  for await (const line of rl) {
    console.log(`Line: ${line}`);
    // Process each line
  }
}
```

### Writing Large Files with Streams

```javascript
import { createWriteStream } from 'node:fs';

// ✅ GOOD - Write large file with stream
async function writeLargeFile(path, data) {
  const stream = createWriteStream(path);

  return new Promise((resolve, reject) => {
    stream.on('finish', resolve);
    stream.on('error', reject);

    for (const chunk of data) {
      if (!stream.write(chunk)) {
        // Wait for drain event if buffer is full
        await new Promise(resolve => stream.once('drain', resolve));
      }
    }

    stream.end();
  });
}

// ✅ GOOD - Append to file with stream
function appendWithStream(path, content) {
  const stream = createWriteStream(path, { flags: 'a' }); // 'a' = append

  stream.write(content);
  stream.end();

  return new Promise((resolve, reject) => {
    stream.on('finish', resolve);
    stream.on('error', reject);
  });
}
```

### Piping Streams

```javascript
import { createReadStream, createWriteStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';
import { createGzip } from 'node:zlib';

// ✅ GOOD - Copy file with streams (efficient)
async function copyWithStream(src, dest) {
  const readStream = createReadStream(src);
  const writeStream = createWriteStream(dest);

  await pipeline(readStream, writeStream);
}

// ✅ GOOD - Compress file
async function compressFile(src, dest) {
  const readStream = createReadStream(src);
  const gzip = createGzip();
  const writeStream = createWriteStream(dest);

  await pipeline(readStream, gzip, writeStream);
}

// ✅ GOOD - Transform file content
import { Transform } from 'node:stream';

async function transformFile(src, dest) {
  const readStream = createReadStream(src, 'utf8');
  const writeStream = createWriteStream(dest);

  const uppercase = new Transform({
    transform(chunk, encoding, callback) {
      this.push(chunk.toString().toUpperCase());
      callback();
    },
  });

  await pipeline(readStream, uppercase, writeStream);
}
```

## Watch Files and Directories

```javascript
import { watch } from 'node:fs/promises';
import { watch as watchCallback } from 'node:fs';

// ✅ GOOD - Watch file for changes (async iterator)
async function watchFile(path) {
  try {
    const watcher = watch(path);

    for await (const event of watcher) {
      console.log(`Event: ${event.eventType}, File: ${event.filename}`);
    }
  } catch (err) {
    console.error('Error watching file:', err);
  }
}

// Watch with callback (legacy)
const watcher = watchCallback('file.txt', (eventType, filename) => {
  console.log(`Event: ${eventType}, File: ${filename}`);
});

// Stop watching
watcher.close();

// ✅ GOOD - Watch directory
async function watchDirectory(path) {
  const watcher = watch(path, { recursive: true });

  for await (const event of watcher) {
    console.log(`${event.eventType}: ${event.filename}`);

    if (event.eventType === 'rename') {
      console.log('File renamed or deleted');
    } else if (event.eventType === 'change') {
      console.log('File modified');
    }
  }
}
```

## Common Patterns

### Safe File Updates

```javascript
import { writeFile, rename, unlink } from 'node:fs/promises';

// ✅ GOOD - Atomic file update
async function safeUpdate(path, content) {
  const tempPath = `${path}.tmp`;
  const backupPath = `${path}.backup`;

  try {
    // Write to temp file
    await writeFile(tempPath, content, 'utf8');

    // Create backup of original
    try {
      await rename(path, backupPath);
    } catch (err) {
      if (err.code !== 'ENOENT') throw err;
    }

    // Move temp to final location (atomic)
    await rename(tempPath, path);

    // Delete backup
    try {
      await unlink(backupPath);
    } catch {}
  } catch (err) {
    // Cleanup on error
    try {
      await unlink(tempPath);
    } catch {}

    throw err;
  }
}
```

### Batch File Processing

```javascript
import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';

// ✅ GOOD - Process files in batches
async function processBatch(dirPath, batchSize = 10) {
  const files = await readdir(dirPath);

  for (let i = 0; i < files.length; i += batchSize) {
    const batch = files.slice(i, i + batchSize);

    const results = await Promise.all(
      batch.map(async (file) => {
        const path = join(dirPath, file);
        const content = await readFile(path, 'utf8');
        return { file, content };
      })
    );

    console.log(`Processed ${results.length} files`);
  }
}
```

## AI Pair Programming Notes

**When working with files:**

1. **Use fs/promises** - Modern promise-based API
2. **Never use sync methods** in production (blocks event loop)
3. **Use streams for large files** - Don't load everything into memory
4. **Always handle errors** - Files may not exist, permissions may be denied
5. **Check error codes** - Use err.code to handle specific errors (ENOENT, EACCES, etc.)
6. **Use recursive: true** for mkdir to create parent directories
7. **Use pipeline()** for streams - Proper error handling and cleanup
8. **Atomic writes** - Write to temp file, then rename
9. **Close file handles** - Always close streams when done
10. **Watch performance** - Monitor memory usage with large files

**Common file system mistakes:**
- Using synchronous methods (readFileSync, etc.)
- Not handling ENOENT (file not found) errors
- Loading large files into memory
- Not closing file handles/streams
- Race conditions with file existence checks
- Not using recursive: true for nested directories
- Forgetting to specify encoding (defaults to Buffer)
- Not using pipeline() for stream error handling
- Memory leaks from unclosed watchers
- Cross-platform path issues (use path.join, not string concat)

## Next Steps

1. **07-STREAMS-BUFFERS.md** - Deep dive into streams and buffers
2. **08-ERROR-HANDLING.md** - Error handling patterns
3. **06-HTTP-NETWORKING.md** - HTTP servers and networking

## Additional Resources

- File System API: https://nodejs.org/api/fs.html
- fs/promises: https://nodejs.org/api/fs.html#promises-api
- Streams: https://nodejs.org/api/stream.html
- Path Module: https://nodejs.org/api/path.html
- File System Tutorial: https://nodejs.dev/en/learn/the-nodejs-fs-module/
