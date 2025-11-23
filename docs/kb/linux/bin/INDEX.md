---
id: linux-index
topic: linux
file_role: navigation
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: ['unix', 'shell', 'bash']
embedding_keywords: [linux, index, navigation, map]
last_reviewed: 2025-11-13
---

# Linux bin Directories - Complete Index

**Purpose**: Quick topic lookup and navigation across the entire knowledge base.

---

## Table of Contents

- [Directory Locations](#directory-locations)
- [PATH Variable](#path-variable)
- [Installation & Setup](#installation--setup)
- [Shebangs & Interpreters](#shebangs--interpreters)
- [Permissions & Security](#permissions--security)
- [Symlinks & Alternatives](#symlinks--alternatives)
- [Package Management](#package-management)
- [Debugging & Troubleshooting](#debugging--troubleshooting)
- [Advanced Topics](#advanced-topics)
- [Best Practices](#best-practices)
- [Common Commands](#common-commands)
- [Error Messages](#error-messages)
- [Framework-Specific](#framework-specific)

---

## Directory Locations

### System Directories

| Directory | Purpose | File | Section |
|-----------|---------|------|---------|
| `/bin` | Essential commands for all users | [02](02-DIRECTORY-HIERARCHY.md) | § The /bin Directory |
| `/sbin` | System administration commands | [02](02-DIRECTORY-HIERARCHY.md) | § The /sbin Directory |
| `/usr/bin` | Primary executable directory | [02](02-DIRECTORY-HIERARCHY.md) | § The /usr/bin Directory |
| `/usr/sbin` | Non-essential system binaries | [02](02-DIRECTORY-HIERARCHY.md) | § The /usr/sbin Directory |
| `/usr/local/bin` | Locally-compiled programs | [02](02-DIRECTORY-HIERARCHY.md) | § The /usr/local/bin Directory |
| `/usr/local/sbin` | Local system administration | [02](02-DIRECTORY-HIERARCHY.md) | § /usr/local/sbin |
| `/opt/*/bin` | Third-party application binaries | [02](02-DIRECTORY-HIERARCHY.md) | § /opt Binaries |

### User Directories

| Directory | Purpose | File | Section |
|-----------|---------|------|---------|
| `~/bin` | Personal executables (traditional) | [06](06-PERSONAL-BIN.md) | § Setting Up ~/bin |
| `~/.local/bin` | XDG-compliant personal binaries | [06](06-PERSONAL-BIN.md) | §.local/bin vs ~/bin |
| `~/.<tool>/bin` | Tool-specific (e.g., ~/.cargo/bin) | [11](11-ADVANCED-PATTERNS.md) | § Language-Specific Bins |

---

## PATH Variable

### Core Concepts

| Topic | File | Section |
|-------|------|---------|
| What is PATH? | [03](03-PATH-VARIABLE.md) | § Understanding PATH |
| How command lookup works | [03](03-PATH-VARIABLE.md) | § Command Resolution Process |
| PATH order and precedence | [03](03-PATH-VARIABLE.md) | § Directory Order Matters |
| Viewing current PATH | [03](03-PATH-VARIABLE.md) | § Inspecting PATH |
| Modifying PATH | [03](03-PATH-VARIABLE.md) | § Adding Directories |
| Temporary vs permanent changes | [03](03-PATH-VARIABLE.md) | § Session vs Persistent |

### Configuration Files

| File | When Used | Details |
|------|-----------|---------|
| `~/.bashrc` | Interactive non-login shells | [03](03-PATH-VARIABLE.md) § Shell Configuration |
| `~/.bash_profile` | Login shells | [03](03-PATH-VARIABLE.md) § Login vs Non-Login |
| `~/.profile` | POSIX-compliant login | [03](03-PATH-VARIABLE.md) § Profile Files |
| `~/.zshrc` | Zsh configuration | [03](03-PATH-VARIABLE.md) § Zsh Specifics |
| `/etc/environment` | System-wide PATH | [03](03-PATH-VARIABLE.md) § System-Wide Configuration |
| `/etc/profile` | System-wide login | [03](03-PATH-VARIABLE.md) § System Profile |

---

## Installation & Setup

### Where to Install

| Use Case | Location | File | Section |
|----------|----------|------|---------|
| Personal scripts | `~/bin` or `~/.local/bin` | [04](04-INSTALLATION-LOCATIONS.md) | § Personal Scripts |
| System-wide custom tools | `/usr/local/bin` | [04](04-INSTALLATION-LOCATIONS.md) | § System-Wide Installation |
| Project-specific tools | `<project>/bin` | [04](04-INSTALLATION-LOCATIONS.md) | § Project Directories |
| Language package managers | `~/.npm`, `~/.cargo/bin` | [04](04-INSTALLATION-LOCATIONS.md) | § Language Managers |
| Third-party applications | `/opt/<app>/bin` | [04](04-INSTALLATION-LOCATIONS.md) | § Third-Party Apps |

### Setup Procedures

| Task | File | Section |
|------|------|---------|
| Create ~/bin directory | [06](06-PERSONAL-BIN.md) | § Initial Setup |
| Add to PATH | [06](06-PERSONAL-BIN.md) | § PATH Configuration |
| Make script executable | [07](07-PERMISSIONS-SECURITY.md) | § Setting Permissions |
| Test installation | [06](06-PERSONAL-BIN.md) | § Verification |

---

## Shebangs & Interpreters

### Shebang Patterns

| Shebang | Use Case | File | Section |
|---------|----------|------|---------|
| `#!/usr/bin/env bash` | Portable bash scripts | [05](05-SHEBANGS.md) | § Portable Shebangs |
| `#!/usr/bin/env python3` | Portable Python scripts | [05](05-SHEBANGS.md) | § Python Shebangs |
| `#!/bin/bash` | System bash (less portable) | [05](05-SHEBANGS.md) | § Hardcoded Shebangs |
| `#!/usr/bin/env node` | Node.js scripts | [05](05-SHEBANGS.md) | § Node.js Shebangs |
| `#!/bin/sh` | POSIX shell scripts | [05](05-SHEBANGS.md) | § POSIX Compliance |

### Best Practices

| Topic | File | Section |
|-------|------|---------|
| Why use /usr/bin/env | [05](05-SHEBANGS.md) | § Benefits of env |
| When to use hardcoded paths | [05](05-SHEBANGS.md) | § Hardcoded Use Cases |
| Shebang pitfalls | [05](05-SHEBANGS.md) | § Common Mistakes |
| Cross-platform compatibility | [05](05-SHEBANGS.md) | § Portability |

---

## Permissions & Security

### File Permissions

| Topic | File | Section |
|-------|------|---------|
| Understanding chmod | [07](07-PERMISSIONS-SECURITY.md) | § File Permissions |
| Making scripts executable | [07](07-PERMISSIONS-SECURITY.md) | § chmod +x |
| Permission octal notation | [07](07-PERMISSIONS-SECURITY.md) | § Numeric Modes |
| Ownership (chown) | [07](07-PERMISSIONS-SECURITY.md) | § File Ownership |

### Security Topics

| Topic | File | Section |
|-------|------|---------|
| PATH hijacking attacks | [07](07-PERMISSIONS-SECURITY.md) | § PATH Security |
| SUID/SGID binaries | [07](07-PERMISSIONS-SECURITY.md) | § Special Permissions |
| File capabilities | [07](07-PERMISSIONS-SECURITY.md) | § Linux Capabilities |
| Security best practices | [07](07-PERMISSIONS-SECURITY.md) | § Security Guidelines |
| Avoiding root when possible | [07](07-PERMISSIONS-SECURITY.md) | § Principle of Least Privilege |

---

## Symlinks & Alternatives

### Symlink Management

| Topic | File | Section |
|-------|------|---------|
| Creating symlinks with ln -s | [08](08-SYMLINKS-ALTERNATIVES.md) | § Creating Symlinks |
| Removing symlinks safely | [08](08-SYMLINKS-ALTERNATIVES.md) | § Removing Symlinks |
| Symlink best practices | [08](08-SYMLINKS-ALTERNATIVES.md) | § Best Practices |
| Absolute vs relative symlinks | [08](08-SYMLINKS-ALTERNATIVES.md) | § Path Types |

### Alternatives System

| Topic | File | Section |
|-------|------|---------|
| update-alternatives command | [08](08-SYMLINKS-ALTERNATIVES.md) | § Alternatives System |
| Managing multiple versions | [08](08-SYMLINKS-ALTERNATIVES.md) | § Version Management |
| Setting default version | [08](08-SYMLINKS-ALTERNATIVES.md) | § Setting Defaults |
| Alternatives use cases | [08](08-SYMLINKS-ALTERNATIVES.md) | § Practical Examples |

---

## Package Management

### Package Manager Integration

| Package Manager | File | Section |
|-----------------|------|---------|
| apt (Debian/Ubuntu) | [09](09-PACKAGE-MANAGEMENT.md) | § APT Package Management |
| yum/dnf (RHEL/Fedora) | [09](09-PACKAGE-MANAGEMENT.md) | § YUM/DNF Management |
| pacman (Arch Linux) | [09](09-PACKAGE-MANAGEMENT.md) | § Pacman |
| zypper (openSUSE) | [09](09-PACKAGE-MANAGEMENT.md) | § Zypper |

### Package Topics

| Topic | File | Section |
|-------|------|---------|
| Where packages install binaries | [09](09-PACKAGE-MANAGEMENT.md) | § Installation Paths |
| Package alternatives | [09](09-PACKAGE-MANAGEMENT.md) | § Managing Alternatives |
| Manual installation vs packages | [09](09-PACKAGE-MANAGEMENT.md) | § Manual vs Package |
| Creating custom packages | [09](09-PACKAGE-MANAGEMENT.md) | § Building Packages |

---

## Debugging & Troubleshooting

### Common Errors

| Error | File | Section |
|-------|------|---------|
| "command not found" | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § Command Not Found |
| "Permission denied" | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § Permission Errors |
| "No such file or directory" (shebang) | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § Shebang Errors |
| Wrong version executes | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § Version Conflicts |
| "Text file busy" | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § File In Use |
| "Cannot execute binary file" | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § Binary Format Errors |

### Debugging Tools

| Tool | Purpose | File | Section |
|------|---------|------|---------|
| `which` | Find command location | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § which Command |
| `type` | Show command type | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § type Builtin |
| `whereis` | Locate binary/source/man | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § whereis Command |
| `command -v` | POSIX command lookup | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § POSIX Lookup |
| `file` | Determine file type | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § file Command |
| `ldd` | Show shared library dependencies | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § Library Dependencies |

### Troubleshooting Techniques

| Technique | File | Section |
|-----------|------|---------|
| PATH inspection | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § Inspecting PATH |
| Command cache clearing | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § Hash Cache |
| Debugging with bash -x | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § Script Debugging |
| Checking file permissions | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § Permission Checks |
| Tracing with strace | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § System Call Tracing |

---

## Advanced Topics

### Multi-Version Management

| Topic | File | Section |
|-------|------|---------|
| Python version managers (pyenv) | [11](11-ADVANCED-PATTERNS.md) | § Python Versions |
| Node version managers (nvm) | [11](11-ADVANCED-PATTERNS.md) | § Node.js Versions |
| Ruby version managers (rbenv) | [11](11-ADVANCED-PATTERNS.md) | § Ruby Versions |
| Direnv for project-specific PATH | [11](11-ADVANCED-PATTERNS.md) | § Direnv |

### Complex Patterns

| Topic | File | Section |
|-------|------|---------|
| Wrapper scripts | [11](11-ADVANCED-PATTERNS.md) | § Command Wrappers |
| Function-based commands | [11](11-ADVANCED-PATTERNS.md) | § Shell Functions |
| Dynamic PATH modification | [11](11-ADVANCED-PATTERNS.md) | § Dynamic PATH |
| Container-based isolation | [11](11-ADVANCED-PATTERNS.md) | § Containerization |

---

## Best Practices

### General Guidelines

| Best Practice | File | Section |
|---------------|------|---------|
| Use standard locations | [04](04-INSTALLATION-LOCATIONS.md) | § Standard Locations |
| Prefer ~/bin over custom locations | [06](06-PERSONAL-BIN.md) | § Why ~/bin |
| Use portable shebangs | [05](05-SHEBANGS.md) | § Portability |
| Order PATH correctly | [03](03-PATH-VARIABLE.md) | § PATH Order |
| Name commands carefully | [06](06-PERSONAL-BIN.md) | § Naming Guidelines |
| Document your scripts | [this project](FRAMEWORK-INTEGRATION-PATTERNS.md) | § Documentation |

### Anti-Patterns

| Anti-Pattern | File | Section |
|--------------|------|---------|
| Installing to /bin or /usr/bin | [04](04-INSTALLATION-LOCATIONS.md) | § What Not To Do |
| Using. in PATH | [07](07-PERMISSIONS-SECURITY.md) | § Security Risks |
| Hardcoded shebangs | [05](05-SHEBANGS.md) | § Hardcoded Risks |
| Too many directories in PATH | [03](03-PATH-VARIABLE.md) | § PATH Pollution |
| Conflicting command names | [10](10-DEBUGGING-TROUBLESHOOTING.md) | § Name Conflicts |

---

## Common Commands

### Command Reference

| Command | Purpose | File | Section |
|---------|---------|------|---------|
| `which <cmd>` | Show full path of command | [QUICK](QUICK-REFERENCE.md) | § Finding Commands |
| `type <cmd>` | Display command type | [QUICK](QUICK-REFERENCE.md) | § Command Type |
| `whereis <cmd>` | Locate binary, source, man pages | [QUICK](QUICK-REFERENCE.md) | § Locate Files |
| `echo $PATH` | Display PATH variable | [QUICK](QUICK-REFERENCE.md) | § PATH Display |
| `export PATH=...` | Modify PATH | [QUICK](QUICK-REFERENCE.md) | § PATH Modification |
| `chmod +x <file>` | Make executable | [QUICK](QUICK-REFERENCE.md) | § Permissions |
| `ln -s <target> <link>` | Create symlink | [QUICK](QUICK-REFERENCE.md) | § Symlinks |
| `hash -r` | Clear command cache (bash) | [QUICK](QUICK-REFERENCE.md) | § Cache |
| `rehash` | Clear command cache (zsh) | [QUICK](QUICK-REFERENCE.md) | § Cache |

---

## Error Messages

### Quick Error Lookup

| Error Message | Cause | Fix | File |
|---------------|-------|-----|------|
| `command not found` | Not in PATH or doesn't exist | Add to PATH or use./command | [10](10-DEBUGGING-TROUBLESHOOTING.md) |
| `Permission denied` | Not executable | chmod +x | [10](10-DEBUGGING-TROUBLESHOOTING.md) |
| `No such file or directory` | Bad shebang interpreter | Fix shebang path | [10](10-DEBUGGING-TROUBLESHOOTING.md) |
| `cannot execute binary file` | Wrong architecture | Recompile or get correct binary | [10](10-DEBUGGING-TROUBLESHOOTING.md) |
| `Text file busy` | File being executed/modified | Wait or kill process | [10](10-DEBUGGING-TROUBLESHOOTING.md) |
| `bad interpreter: No such file` | Shebang path wrong | Use /usr/bin/env | [10](10-DEBUGGING-TROUBLESHOOTING.md) |

---

## Framework-Specific

### this project Project Patterns

| Pattern | File | Section |
|---------|------|---------|
| Project-local kb-codex command | [this project](FRAMEWORK-INTEGRATION-PATTERNS.md) | § Project Commands |
| Script organization | [this project](FRAMEWORK-INTEGRATION-PATTERNS.md) | § Directory Structure |
| PATH configuration | [this project](FRAMEWORK-INTEGRATION-PATTERNS.md) | § PATH Setup |
| Shell script standards | [this project](FRAMEWORK-INTEGRATION-PATTERNS.md) | § Script Standards |
| Deployment scripts | [this project](FRAMEWORK-INTEGRATION-PATTERNS.md) | § Deployment |

---

## Search Terms

Quick lookup by keyword (file references):

- **alternatives**: [08](08-SYMLINKS-ALTERNATIVES.md)
- **bash**: [05](05-SHEBANGS.md), [03](03-PATH-VARIABLE.md)
- **chmod**: [07](07-PERMISSIONS-SECURITY.md)
- **command not found**: [10](10-DEBUGGING-TROUBLESHOOTING.md)
- **debugging**: [10](10-DEBUGGING-TROUBLESHOOTING.md)
- **env**: [05](05-SHEBANGS.md)
- **executable**: [07](07-PERMISSIONS-SECURITY.md)
- **FHS**: [02](02-DIRECTORY-HIERARCHY.md), [01](01-FUNDAMENTALS.md)
- **install**: [04](04-INSTALLATION-LOCATIONS.md)
- **ln -s**: [08](08-SYMLINKS-ALTERNATIVES.md)
- **package**: [09](09-PACKAGE-MANAGEMENT.md)
- **PATH**: [03](03-PATH-VARIABLE.md)
- **permissions**: [07](07-PERMISSIONS-SECURITY.md)
- **python**: [05](05-SHEBANGS.md), [11](11-ADVANCED-PATTERNS.md)
- **security**: [07](07-PERMISSIONS-SECURITY.md)
- **shebang**: [05](05-SHEBANGS.md)
- **symlink**: [08](08-SYMLINKS-ALTERNATIVES.md)
- **troubleshoot**: [10](10-DEBUGGING-TROUBLESHOOTING.md)
- **version**: [11](11-ADVANCED-PATTERNS.md)
- **which**: [10](10-DEBUGGING-TROUBLESHOOTING.md), [QUICK](QUICK-REFERENCE.md)
- **~/bin**: [06](06-PERSONAL-BIN.md)

---

## Navigation

- **Start here**: [README.md](README.md) - Overview and learning paths
- **Quick answers**: [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Copy-paste solutions
- **Fundamentals**: [01-FUNDAMENTALS.md](01-FUNDAMENTALS.md) - Start learning
- **Real examples**: [FRAMEWORK-INTEGRATION-PATTERNS.md](FRAMEWORK-INTEGRATION-PATTERNS.md) - Production patterns

---

*Index last updated: November 9, 2025*
