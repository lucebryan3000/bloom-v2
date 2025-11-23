---
id: linux-05-shebangs
topic: linux
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [linux-basics]
related_topics: ['unix', 'shell', 'bash']
embedding_keywords: [linux]
last_reviewed: 2025-11-13
---

# 05-SHEBANGS.md - The Magic of Shebang Lines

## Table of Contents
1. [What is a Shebang?](#what-is-a-shebang)
2. [How the Kernel Uses Shebangs](#how-the-kernel-uses-shebangs)
3. [Portable Shebangs](#portable-shebangs)
4. [Hardcoded Shebangs](#hardcoded-shebangs)
5. [When to Use Each Type](#when-to-use-each-type)
6. [Language-Specific Shebangs](#language-specific-shebangs)
7. [Common Shebang Mistakes](#common-shebang-mistakes)
8. [Shebangs with Arguments](#shebangs-with-arguments)
9. [Cross-Platform Considerations](#cross-platform-considerations)
10. [Troubleshooting Shebang Errors](#troubleshooting-shebang-errors)

---

## What is a Shebang?

### Definition

The **shebang** (also called hashbang, pound-bang, or hash-pling) is a special two-character sequence `#!` at the beginning of a script file that tells the operating system which interpreter to use to execute the script.

**Etymology**: "She-bang" comes from "sharp" (#) + "bang" (!), programmer slang for these characters.

### Basic Anatomy

```bash
#!/path/to/interpreter
# Rest of your script
echo "Hello, World!"
```

**Components**:
- `#!` - The literal shebang characters (must be bytes 0x23 0x21)
- `/path/to/interpreter` - Absolute path to the interpreter program
- Optional: Arguments to pass to the interpreter

### ✅ Valid Shebang Examples

```bash
#!/bin/bash
#!/usr/bin/env python3
#!/usr/bin/env node
#!/bin/sh
#!/usr/bin/perl
#!/usr/bin/ruby
```

### ❌ Invalid Shebang Examples

```bash
# !/bin/bash # Space before ! - INVALID
#! /bin/bash # Space after ! - INVALID (works on some systems but not portable)
 #!/bin/bash # Leading whitespace - INVALID
#!/bin/bash # Not first line - INVALID (if comments above)
#/bin/bash # Missing ! - INVALID
```

---

## How the Kernel Uses Shebangs

### Execution Flow

When you execute a script file, here's what happens at the kernel level:

**1. execve System Call**
```c
// What happens when you type./script.sh
execve("./script.sh", argv, envp);
```

**2. Kernel Checks Magic Number**
```
- Reads first 2 bytes of file
- If bytes are #! (0x23 0x21), it's a shebang script
- Otherwise, checks for ELF binary, a.out, etc.
```

**3. Parse Shebang Line**
```
- Extracts interpreter path
- Extracts optional arguments
- Max length varies by OS (typically 127-255 bytes)
```

**4. Re-execute with Interpreter**
```c
// Kernel transforms the call to:
execve("/bin/bash", ["bash", "./script.sh",...original_args], envp);
```

### Example Transformation

**You type**:
```bash
./myscript arg1 arg2
```

**Shebang in myscript**:
```bash
#!/bin/bash
```

**Kernel actually executes**:
```bash
/bin/bash./myscript arg1 arg2
```

### ✅ Understanding Shebang Processing

```bash
#!/bin/bash
# File: debug-shebang.sh
echo "Script: $0"
echo "Args: $@"
echo "Interpreter: $BASH"
```

**Run it**:
```bash
chmod +x debug-shebang.sh
./debug-shebang.sh foo bar
```

**Output**:
```
Script:./debug-shebang.sh
Args: foo bar
Interpreter: /bin/bash
```

### ❌ Common Misunderstanding

```bash
# This does NOT run the shebang if you do:
bash script.sh # Explicitly calling bash ignores shebang

# The shebang ONLY works when executing directly:
./script.sh # This uses the shebang
```

---

## Portable Shebangs

### The env Approach

The **`/usr/bin/env`** approach is the most portable way to write shebangs:

```bash
#!/usr/bin/env bash
```

**Why it's portable**:
- `env` searches for the interpreter in your `$PATH`
- Doesn't assume interpreter location
- Works across different Unix/Linux distributions
- Respects user's environment (important for version managers)

### ✅ Portable Shebang Examples

```bash
#!/usr/bin/env bash
# Works whether bash is in /bin, /usr/bin, /usr/local/bin, etc.

#!/usr/bin/env python3
# Finds python3 wherever it's installed

#!/usr/bin/env node
# Uses user's active Node version (nvm, etc.)

#!/usr/bin/env ruby
# Respects rbenv, rvm, etc.

#!/usr/bin/env perl
# Portable across systems
```

### How env Works

```bash
# When you use:
#!/usr/bin/env python3

# env does this:
# 1. Searches PATH for 'python3'
# 2. Finds first match (e.g., /usr/bin/python3)
# 3. Executes that interpreter with the script
```

### ✅ env Respects Version Managers

```bash
#!/usr/bin/env node
# File: server.js

console.log(process.version);
```

**With nvm**:
```bash
# Set Node version
nvm use 18
./server.js # Uses Node 18

nvm use 20
./server.js # Uses Node 20
```

**Without env (hardcoded)**:
```bash
#!/usr/local/bin/node
# Always uses this specific node, ignoring nvm
```

### ❌ When env Doesn't Help

```bash
#!/usr/bin/env bash
# Still fails if bash isn't in PATH at all

#!/usr/bin/env python
# Fails if python isn't found (Python 2 removed on many systems)
```

### env Location Assumption

**The one assumption**: `/usr/bin/env` must exist

```bash
# This location is standardized by POSIX
# Present on virtually all Unix-like systems
ls -l /usr/bin/env
# -rwxr-xr-x 1 root root 51632 /usr/bin/env
```

---

## Hardcoded Shebangs

### When to Hardcode

Use hardcoded paths when:
1. **System scripts** that require specific interpreter
2. **Security-sensitive** scripts (avoid PATH manipulation)
3. **Container images** with known filesystem layout
4. **Embedded systems** with fixed paths

### ✅ Valid Hardcoded Shebangs

```bash
#!/bin/sh
# POSIX shell - standardized location

#!/bin/bash
# Common on Linux systems

#!/usr/bin/python3
# Debian/Ubuntu standard location

#!/usr/local/bin/python3
# FreeBSD/macOS homebrew standard
```

### Security Advantages

```bash
#!/bin/bash
# File: secure-backup.sh

# This ALWAYS uses /bin/bash
# Cannot be hijacked by PATH manipulation:
# PATH=/tmp/malicious:$PATH./secure-backup.sh
# Still uses /bin/bash, not /tmp/malicious/bash
```

### ❌ Portability Problems

```bash
#!/usr/local/bin/bash
# Fails on systems where bash is in /bin

#!/opt/homebrew/bin/python3
# Only works on ARM Macs with Homebrew

#!/snap/bin/node
# Only works if Node installed via snap
```

### Distribution-Specific Paths

**Linux (Debian/Ubuntu)**:
```bash
#!/usr/bin/python3 # System Python
#!/usr/bin/perl # System Perl
#!/bin/bash # Bash shell
```

**FreeBSD**:
```bash
#!/usr/local/bin/bash # Bash (from ports)
#!/usr/local/bin/python3
```

**macOS**:
```bash
#!/bin/bash # System bash (old version)
#!/usr/bin/python3 # System Python 3
#!/opt/homebrew/bin/bash # Homebrew bash (ARM)
#!/usr/local/bin/bash # Homebrew bash (Intel)
```

---

## When to Use Each Type

### Decision Matrix

| Scenario | Recommended | Reason |
|----------|-------------|---------|
| User scripts | `#!/usr/bin/env` | Respects user environment |
| System scripts | Hardcoded | Security, reliability |
| Containers | Hardcoded | Known environment |
| Development tools | `#!/usr/bin/env` | Version flexibility |
| Init scripts | Hardcoded `/bin/sh` | System bootstrap |
| Cron jobs | Hardcoded | Minimal PATH in cron |
| Security scripts | Hardcoded | Prevent PATH attacks |
| Cross-platform | `#!/usr/bin/env` | Maximum portability |

### ✅ User Scripts (env)

```bash
#!/usr/bin/env python3
# File: ~/bin/analyze-logs

# User might have:
# - pyenv managing Python versions
# - virtualenv activated
# - Custom Python installation
# env respects all of these
```

### ✅ System Scripts (hardcoded)

```bash
#!/bin/bash
# File: /etc/init.d/myservice

# System script requirements:
# - Must work during boot (minimal PATH)
# - Must not depend on user environment
# - Security: no PATH manipulation
# - Reliability: known interpreter location
```

### ✅ Container Scripts (hardcoded)

```dockerfile
FROM ubuntu:22.04

# Install Python
RUN apt-get update && apt-get install -y python3

# Create script
RUN echo '#!/usr/bin/python3\nprint("Hello")' > /app/script.py
RUN chmod +x /app/script.py

# Hardcoded path is fine - we control the image
CMD ["/app/script.py"]
```

### ✅ Development Tools (env)

```bash
#!/usr/bin/env node
# File: project/scripts/build.js

// Respects:
// - nvm (Node Version Manager)
// - fnm (Fast Node Manager)
// - asdf
// - Project's.nvmrc file
```

---

## Language-Specific Shebangs

### Bash Scripts

```bash
#!/bin/bash
# Most common for system scripts

#!/usr/bin/env bash
# Portable for user scripts

#!/bin/bash -e
# Exit on error (set -e)

#!/bin/bash -x
# Debug mode (set -x)

#!/bin/bash -eu
# Exit on error + undefined variables
```

**✅ Best Practice**:
```bash
#!/usr/bin/env bash
set -euo pipefail # Add flags in script, not shebang
```

### Python Scripts

```bash
#!/usr/bin/python3
# System Python 3

#!/usr/bin/env python3
# Respects virtualenv, pyenv

#!/usr/bin/env python3.11
# Specific version

#!/usr/bin/python3 -u
# Unbuffered output
```

**✅ Best Practice**:
```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script description here
"""
```

**❌ Avoid**:
```python
#!/usr/bin/python
# Python 2 is dead, use python3
```

### Node.js Scripts

```bash
#!/usr/bin/env node
# Standard for Node scripts

#!/usr/bin/node
# Less portable

#!/usr/bin/env node --experimental-modules
# With flags (may not work on all systems)
```

**✅ Best Practice**:
```javascript
#!/usr/bin/env node
'use strict';

// Your code here
```

### Perl Scripts

```bash
#!/usr/bin/perl
# System Perl

#!/usr/bin/env perl
# Portable

#!/usr/bin/perl -w
# Enable warnings

#!/usr/bin/perl -T
# Taint mode (security)
```

**✅ Best Practice**:
```perl
#!/usr/bin/env perl
use strict;
use warnings;
```

### Ruby Scripts

```bash
#!/usr/bin/ruby
# System Ruby

#!/usr/bin/env ruby
# Respects rbenv, rvm

#!/usr/bin/ruby -w
# Enable warnings
```

**✅ Best Practice**:
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# Your code here
```

### Shell Scripts (POSIX)

```bash
#!/bin/sh
# POSIX shell - maximum compatibility

#!/usr/bin/env sh
# Portable POSIX shell
```

**Use `/bin/sh` for**:
- Maximum portability
- Minimal dependencies
- System scripts
- Init scripts

**✅ Example**:
```bash
#!/bin/sh
# POSIX-compliant script
# Avoid bash-isms like [[ ]], ${var//}, etc.

if [ -f "/etc/config" ]; then
. /etc/config
fi
```

---

## Common Shebang Mistakes

### Mistake 1: Windows Line Endings

**❌ Problem**:
```bash
#!/bin/bash\r
# Windows CRLF line ending includes \r
```

**Error**:
```
bash:./script.sh: /bin/bash^M: bad interpreter: No such file or directory
```

**✅ Fix**:
```bash
# Convert to Unix line endings
dos2unix script.sh

# Or with sed
sed -i 's/\r$//' script.sh

# Or with tr
tr -d '\r' < script.sh > script.sh.fixed
```

### Mistake 2: Spaces in Shebang

**❌ Wrong**:
```bash
# !/bin/bash # Space before !
#! /bin/bash # Space after !
#!/bin/bash # Trailing spaces (some systems OK, not portable)
```

**✅ Correct**:
```bash
#!/bin/bash
# No spaces anywhere in shebang line
```

### Mistake 3: Not First Line

**❌ Wrong**:
```bash
# Copyright notice
# Author: John Doe
#!/bin/bash
echo "Hello"
```

**✅ Correct**:
```bash
#!/bin/bash
# Copyright notice
# Author: John Doe
echo "Hello"
```

### Mistake 4: Wrong Python Version

**❌ Wrong**:
```bash
#!/usr/bin/python
# Python 2 (removed from many systems)
```

**Error**:
```
/usr/bin/python: No such file or directory
```

**✅ Correct**:
```bash
#!/usr/bin/env python3
# Always use python3
```

### Mistake 5: Forgot to Make Executable

**❌ Problem**:
```bash
cat > script.sh << 'EOF'
#!/bin/bash
echo "Hello"
EOF

./script.sh
# bash:./script.sh: Permission denied
```

**✅ Fix**:
```bash
chmod +x script.sh
./script.sh
```

### Mistake 6: Shebang Too Long

**❌ Problem**:
```bash
#!/very/long/path/that/exceeds/the/system/limit/which/is/typically/127/or/255/characters/depending/on/the/operating/system/and/kernel/version/bin/bash
```

**Error**:
```
Exec format error
```

**✅ Solution**:
```bash
# Use symlink to shorten path
ln -s /very/long/path/bin/bash /usr/local/bin/mybash
#!/usr/local/bin/mybash
```

### Mistake 7: env with Multiple Arguments

**❌ Won't Work Everywhere**:
```bash
#!/usr/bin/env node --experimental-modules
# Some systems treat "node --experimental-modules" as single program name
```

**✅ Workaround**:
```bash
#!/usr/bin/env node
// Put flags in Node code instead
process.argv.unshift('--experimental-modules');
```

Or use wrapper script:
```bash
#!/bin/bash
exec node --experimental-modules "$@"
```

---

## Shebangs with Arguments

### Single Argument Support

Most systems support **one** argument in the shebang:

```bash
#!/bin/bash -e
# Works: single argument "-e"

#!/usr/bin/python3 -u
# Works: single argument "-u" (unbuffered)

#!/usr/bin/perl -w
# Works: single argument "-w" (warnings)
```

### ❌ Multiple Arguments (Unreliable)

```bash
#!/bin/bash -e -u -o pipefail
# May be treated as single argument "-e -u -o pipefail"
# System-dependent behavior
```

### ✅ Best Practice: Set Options in Script

```bash
#!/bin/bash
set -euo pipefail
# Explicitly set all options in script
# Portable and clear
```

**Python**:
```python
#!/usr/bin/env python3
import sys
sys.dont_write_bytecode = True # Instead of -B flag
```

**Node**:
```javascript
#!/usr/bin/env node
'use strict';
// Set options in code instead of shebang
```

### Common Shebang Arguments

**Bash**:
```bash
#!/bin/bash -e # Exit on error
#!/bin/bash -x # Debug mode
#!/bin/bash -u # Error on undefined variables
#!/bin/bash -n # Syntax check only
#!/bin/bash -v # Verbose mode
```

**Python**:
```bash
#!/usr/bin/python3 -u # Unbuffered output
#!/usr/bin/python3 -O # Optimize (remove assert)
#!/usr/bin/python3 -B # Don't write.pyc files
#!/usr/bin/python3 -W ignore # Ignore warnings
```

**Perl**:
```bash
#!/usr/bin/perl -w # Warnings
#!/usr/bin/perl -T # Taint mode (security)
#!/usr/bin/perl -d # Debugger
```

---

## Cross-Platform Considerations

### Linux vs macOS vs BSD

**Linux** (most distributions):
```bash
#!/bin/bash # Usually bash 5.x
#!/usr/bin/python3 # Python 3.8+
#!/usr/bin/env node # If installed
```

**macOS**:
```bash
#!/bin/bash # Old bash 3.2 (licensing)
#!/usr/bin/zsh # Default shell since Catalina
#!/usr/bin/python3 # Python 3.9+
#!/opt/homebrew/bin/bash # Homebrew bash (ARM)
#!/usr/local/bin/bash # Homebrew bash (Intel)
```

**FreeBSD**:
```bash
#!/bin/sh # FreeBSD sh (not bash)
#!/usr/local/bin/bash # Bash from ports
#!/usr/local/bin/python3 # Python from ports
```

### ✅ Maximum Portability

```bash
#!/bin/sh
# POSIX shell exists everywhere
# But limited features (no arrays, etc.)

#!/usr/bin/env bash
# Portable bash location
# But requires bash installed

#!/usr/bin/env python3
# Portable Python 3
# But requires python3 in PATH
```

### Detecting Platform in Script

```bash
#!/bin/sh

case "$(uname -s)" in
 Linux*) platform=linux;;
 Darwin*) platform=mac;;
 FreeBSD*) platform=bsd;;
 CYGWIN*) platform=cygwin;;
 MINGW*) platform=mingw;;
 *) platform=unknown;;
esac

echo "Platform: $platform"
```

### WSL (Windows Subsystem for Linux)

```bash
#!/bin/bash
# Works in WSL (uses Linux paths)

# Detect WSL
if grep -qi microsoft /proc/version; then
 echo "Running in WSL"
fi
```

### Git and Line Endings

**✅ Preserve Shebangs**:
```bash
#.gitattributes
*.sh text eol=lf
*.py text eol=lf
*.pl text eol=lf
*.rb text eol=lf

# Ensures Unix line endings even on Windows
```

---

## Troubleshooting Shebang Errors

### Error: "bad interpreter: No such file or directory"

**Symptom**:
```bash
./script.sh
bash:./script.sh: /bin/bash: bad interpreter: No such file or directory
```

**Causes & Solutions**:

1. **Windows line endings** (most common)
```bash
# Check for \r
cat -v script.sh | head -1
#!/bin/bash^M # ^M indicates \r

# Fix
dos2unix script.sh
```

2. **Wrong interpreter path**
```bash
# Check shebang
head -1 script.sh
#!/usr/local/bin/bash # Might not exist

# Find correct path
which bash
/bin/bash

# Fix shebang
sed -i '1s|.*|#!/bin/bash|' script.sh
```

3. **Interpreter doesn't exist**
```bash
# Install missing interpreter
sudo apt-get install bash
# or
sudo yum install bash
```

### Error: "Exec format error"

**Symptom**:
```bash
./script.sh
bash:./script.sh: cannot execute binary file: Exec format error
```

**Causes & Solutions**:

1. **No shebang**
```bash
# Check first line
head -1 script.sh
echo "Hello" # Missing shebang!

# Add shebang
sed -i '1i#!/bin/bash' script.sh
```

2. **Binary file**
```bash
# Check file type
file script.sh
script.sh: ELF 64-bit executable # Not a script!

# You're trying to execute wrong file
```

3. **Corrupted file**
```bash
# Check file integrity
hexdump -C script.sh | head

# Re-download or restore from backup
```

### Error: "Permission denied"

**Symptom**:
```bash
./script.sh
bash:./script.sh: Permission denied
```

**Solution**:
```bash
# Make executable
chmod +x script.sh
./script.sh # Now works

# Or run explicitly
bash script.sh # Ignores shebang but works
```

### Error: "command not found" (with env)

**Symptom**:
```bash
./script.sh
env: 'python3': No such file or directory
```

**Solutions**:

1. **Install interpreter**
```bash
sudo apt-get install python3
```

2. **Check PATH**
```bash
which python3
/usr/bin/python3

echo $PATH
# Make sure /usr/bin is in PATH
```

3. **Use absolute path**
```bash
# Change from:
#!/usr/bin/env python3

# To:
#!/usr/bin/python3
```

### Debugging Shebang Issues

**✅ Diagnostic Script**:
```bash
#!/bin/bash
# File: debug-shebang-issues.sh

echo "=== Shebang Diagnostics ==="
echo

echo "1. First line of script:"
head -1 "$1" | cat -v

echo
echo "2. File type:"
file "$1"

echo
echo "3. Permissions:"
ls -l "$1"

echo
echo "4. Shebang interpreter:"
INTERP=$(head -1 "$1" | sed 's/#!//' | awk '{print $1}')
echo "Interpreter: $INTERP"

echo
echo "5. Interpreter exists?"
if [ -f "$INTERP" ]; then
 echo "✅ Yes: $INTERP"
 ls -l "$INTERP"
else
 echo "❌ No: $INTERP not found"
fi

echo
echo "6. Checking for Windows line endings:"
if head -1 "$1" | grep -q $'\r'; then
 echo "❌ Found \\r (Windows line ending)"
 echo "Fix: dos2unix $1"
else
 echo "✅ No Windows line endings"
fi
```

**Usage**:
```bash
chmod +x debug-shebang-issues.sh
./debug-shebang-issues.sh problematic-script.sh
```

---

## Advanced Shebang Topics

### Shebang Recursion

**Can a shebang script call another shebang script?**

Yes, but there's a recursion limit:

```bash
# script1.sh
#!/usr/bin/env script2.sh

# script2.sh
#!/usr/bin/env script3.sh

# script3.sh
#!/bin/bash
echo "Hello"
```

Most systems limit to **4 levels** of recursion.

### Shebang in Here Documents

```bash
#!/bin/bash

# Create script with shebang
cat > generated.sh << 'EOF'
#!/bin/bash
echo "I was generated"
EOF

chmod +x generated.sh
./generated.sh
```

### Polyglot Scripts

**Valid Python AND Bash**:
```bash
#!/bin/bash
''''exec python3 "$0" "$@"
'''
# Python code below
print("Hello from Python")
# Bash never sees this
```

How it works:
- Bash sees `''''` as empty string + `exec python3`
- Python sees `'''` as string literal (ignored)

### Custom Interpreters

You can use ANY executable as shebang:

```bash
#!/usr/bin/awk -f
BEGIN { print "Hello from AWK" }
```

```bash
#!/usr/bin/sed -f
s/foo/bar/g
```

```bash
#!/bin/cat
This file just prints itself!
```

---

## Best Practices Summary

### ✅ DO

1. **Use `/usr/bin/env` for user scripts**
```bash
#!/usr/bin/env bash
```

2. **Use absolute paths for system scripts**
```bash
#!/bin/bash
```

3. **Make shebang first line**
```bash
#!/bin/bash
# Comments after
```

4. **Set options in script, not shebang**
```bash
#!/bin/bash
set -euo pipefail
```

5. **Use Unix line endings**
```bash
# Add to.gitattributes
*.sh text eol=lf
```

6. **Make scripts executable**
```bash
chmod +x script.sh
```

7. **Test across platforms**
```bash
# Test on Linux, macOS, etc.
```

### ❌ DON'T

1. **Don't use Python 2**
```bash
#!/usr/bin/python # NO - use python3
```

2. **Don't add spaces in shebang**
```bash
# !/bin/bash # NO
```

3. **Don't put comments before shebang**
```bash
# Copyright
#!/bin/bash # NO - shebang must be first
```

4. **Don't use multiple arguments**
```bash
#!/bin/bash -e -u -o pipefail # Unreliable
```

5. **Don't forget to check line endings**
```bash
# Always check files from Windows
```

---

## Quick Reference

### Common Shebangs

| Language | System | Portable | Notes |
|----------|--------|----------|-------|
| Bash | `#!/bin/bash` | `#!/usr/bin/env bash` | Use env for user scripts |
| POSIX Shell | `#!/bin/sh` | `#!/usr/bin/env sh` | Max compatibility |
| Python 3 | `#!/usr/bin/python3` | `#!/usr/bin/env python3` | Never use `python` |
| Node.js | `#!/usr/bin/node` | `#!/usr/bin/env node` | Respects nvm |
| Ruby | `#!/usr/bin/ruby` | `#!/usr/bin/env ruby` | Respects rbenv/rvm |
| Perl | `#!/usr/bin/perl` | `#!/usr/bin/env perl` | |
| AWK | `#!/usr/bin/awk -f` | `#!/usr/bin/env -S awk -f` | Note -S flag |

### Troubleshooting Checklist

- [ ] Is shebang the first line?
- [ ] No spaces in shebang?
- [ ] Unix line endings (LF not CRLF)?
- [ ] Interpreter exists at that path?
- [ ] File is executable (`chmod +x`)?
- [ ] Interpreter is in PATH (if using env)?
- [ ] No typos in interpreter name?

---

**Next**: [06-PERSONAL-BIN.md](./06-PERSONAL-BIN.md) - Setting up your personal bin directory
