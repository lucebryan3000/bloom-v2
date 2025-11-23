---
id: linux-04-installation-locations
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

# Linux Bin Directories - Installation Locations Decision Guide

**Master the art of choosing the right installation location for every type of executable.**

---

## Overview: The Installation Location Decision

Installing a binary or script in the wrong location can cause:
- Package manager conflicts
- Permission issues
- Maintenance nightmares
- Security vulnerabilities
- Difficulty in troubleshooting

This guide provides a comprehensive decision framework for choosing the right location every time.

### The Golden Rules

1. **Never touch `/bin` or `/usr/bin`** - These are package manager territory
2. **Personal scripts go in `~/bin` or `~/.local/bin`** - Your space, your rules
3. **System-wide custom tools go in `/usr/local/bin`** - Clearly separated from packages
4. **Project tools stay in project directories** - Keep context together
5. **Third-party applications go in `/opt/<app>/bin`** - Clean isolation

---

## Decision Tree (Start Here!)

```
┌─────────────────────────────────────────┐
│ Need to install an executable? │
└────────────┬────────────────────────────┘
 │
 ▼
 ┌────────────────────┐
 │ Who needs access? │
 └────────┬───────────┘
 │
 ┌──────┴──────┐
 │ │
 ▼ ▼
 ┌──────┐ ┌──────────┐
 │ Only │ │ All users│
 │ you │ │ (system) │
 └──┬───┘ └────┬─────┘
 │ │
 ▼ ▼
 ┌─────────────────┐ ┌─────────────────────┐
 │ Is it a: │ │ Is it a: │
 │ • Personal tool?│ │ • Package manager? │
 │ • Script? │ │ • Pre-built app? │
 │ • Wrapper? │ │ • Custom compile? │
 └──┬──────────────┘ └────┬────────────────┘
 │ │
 ▼ ▼
 ~/bin or /usr/local/bin
 ~/.local/bin or /opt/<app>/bin
```

### Quick Decision Matrix

| Type | Who Needs It | Managed By | Location | Requires Root |
|------|--------------|------------|----------|---------------|
| Personal script | Just you | You | `~/bin` | No |
| Personal tool | Just you | Language PM | `~/.local/bin` | No |
| System script | All users | You | `/usr/local/bin` | Yes |
| System tool | All users | You | `/usr/local/bin` | Yes |
| Third-party app | All users | Vendor | `/opt/<app>/bin` | Yes |
| Project script | Project team | Project | `<project>/bin` | No |
| Package | All users | apt/yum/dnf | `/usr/bin` | Yes (via PM) |
| System binary | All users | OS | `/bin` → `/usr/bin` | Yes (via PM) |

---

## 1. Personal Scripts → ~/bin or ~/.local/bin

### When to Use

✅ **Use when**:
- Script is only needed by you
- No root access required
- Quick personal automation
- Experimental or temporary tools
- Wrapper around complex commands
- Project-specific shortcuts for your workflow

❌ **Don't use when**:
- Multiple users need access
- System service requires it
- Needs to run as root
- Part of system initialization

### Setup Process

```bash
# 1. Create directory
mkdir -p ~/bin

# 2. Add to PATH (if not already present)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 3. Verify PATH
echo $PATH | grep -q "$HOME/bin" && echo "✅ In PATH" || echo "❌ Not in PATH"
```

### ~/.local/bin vs ~/bin

```bash
# ~/.local/bin - XDG Base Directory standard
# Used by: pip --user, npm --user-global (sometimes)
# Advantage: Standards-compliant, some tools auto-detect
mkdir -p ~/.local/bin

# ~/bin - Traditional personal bin
# Used by: Custom scripts, manual installations
# Advantage: Shorter path, easier to type
mkdir -p ~/bin

# Both work! Add both to PATH for maximum compatibility
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
```

### Installation Examples

#### ✅ Example 1: Personal Backup Script

```bash
# Create script
cat > ~/bin/backup-home << 'EOF'
#!/usr/bin/env bash
# Personal backup script
set -euo pipefail

BACKUP_DIR="/media/backup/$(hostname)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Backing up $HOME to $BACKUP_DIR/$TIMESTAMP"
rsync -av --exclude='.cache' "$HOME/" "$BACKUP_DIR/$TIMESTAMP/"
echo "✅ Backup complete"
EOF

# Make executable
chmod +x ~/bin/backup-home

# Test
backup-home
```

**Why ~/bin?** Personal automation, no other users need it, no root required.

#### ✅ Example 2: Docker Compose Wrapper

```bash
# Create wrapper for project-specific docker-compose
cat > ~/bin/this project-up << 'EOF'
#!/usr/bin/env bash
# Start this project development environment
cd ~/apps/project
docker-compose up -d
docker-compose logs -f app
EOF

chmod +x ~/bin/this project-up

# Now run from anywhere
this project-up
```

**Why ~/bin?** Personal workflow tool, quick access from any directory.

#### ✅ Example 3: Git Shortcuts

```bash
# Create git shortcuts
cat > ~/bin/git-cleanup << 'EOF'
#!/usr/bin/env bash
# Clean up merged git branches
git branch --merged | grep -v "\*" | grep -v "main" | grep -v "master" | xargs -n 1 git branch -d
EOF

chmod +x ~/bin/git-cleanup

# Use like: git cleanup (git- prefix makes it a git subcommand)
cd ~/apps/project
git cleanup
```

**Why ~/bin?** Personal git workflow, works with git's subcommand system.

#### ❌ Example 4: System Service (WRONG LOCATION)

```bash
# ❌ BAD: System service in personal bin
cat > ~/bin/backup-daemon << 'EOF'
#!/usr/bin/env bash
while true; do
 backup-all-users # Needs root access
 sleep 3600
done
EOF

# ❌ PROBLEM: Systemd service can't reliably access ~/bin
# ❌ PROBLEM: Doesn't run if user not logged in
# ❌ PROBLEM: Wrong permissions for system-wide service
```

**Why wrong?** System services need system-wide installation in `/usr/local/bin`.

### Best Practices for Personal Scripts

```bash
# 1. Use consistent naming
# ✅ Good: project-action format
~/bin/this project-deploy
~/bin/db-backup
~/bin/server-restart

# ❌ Bad: Generic names (conflict risk)
~/bin/deploy
~/bin/backup
~/bin/restart

# 2. Add documentation headers
cat > ~/bin/example << 'EOF'
#!/usr/bin/env bash
# example - Short description of what this does
#
# Usage: example [options] <args>
# Options:
# -h, --help Show this help
# -v, --verbose Verbose output
#
# Author: Your Name <email>
# Created: 2025-11-09

set -euo pipefail

# Script content here
EOF

# 3. Use portable shebangs
#!/usr/bin/env bash # ✅ Finds bash in PATH
#!/usr/bin/env python3 # ✅ Finds python3 in PATH
#!/bin/bash # ❌ Hardcoded path

# 4. Make scripts directory-independent
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Now can reference other scripts/files relative to script location

# 5. Add error handling
set -euo pipefail # Exit on error, undefined vars, pipe failures
trap 'echo "Error on line $LINENO"' ERR
```

---

## 2. System-Wide Custom Tools → /usr/local/bin

### When to Use

✅ **Use when**:
- All system users need access
- Custom-compiled software
- Scripts for system administration
- Tools you built from source
- System-wide wrappers
- Service management scripts

❌ **Don't use when**:
- Package manager version available (use that instead)
- Only you need access (use ~/bin)
- Already exists in /bin or /usr/bin
- Part of a larger application (use /opt)

### Why /usr/local?

The `/usr/local` hierarchy is specifically for **locally-compiled** and **administrator-installed** software that's separate from the distribution's package manager.

```
/usr/local/
├── bin/ # Executables
├── lib/ # Libraries
├── include/ # Header files
├── share/ # Shared data
├── man/ # Manual pages
└── src/ # Source code (optional)
```

### Installation Process

```bash
# 1. Download/create your tool
wget https://example.com/tool.tar.gz
tar xzf tool.tar.gz
cd tool

# 2. Compile if needed
./configure --prefix=/usr/local
make
sudo make install # Installs to /usr/local/bin

# 3. Verify installation
which tool
# Output: /usr/local/bin/tool

# 4. Test
tool --version
```

### Installation Examples

#### ✅ Example 1: Custom System Monitoring Script

```bash
# Create system-wide monitoring script
sudo tee /usr/local/bin/system-health << 'EOF'
#!/usr/bin/env bash
# System health check - available to all users

echo "=== System Health Report ==="
echo "Uptime: $(uptime -p)"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% used"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
echo "=========================="
EOF

sudo chmod +x /usr/local/bin/system-health

# Now any user can run
system-health
```

**Why /usr/local/bin?** System administration tool, all users benefit.

#### ✅ Example 2: Installing Go from Source

```bash
# Download and install Go 1.21
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz

# Remove old version (if exists)
sudo rm -rf /usr/local/go

# Extract to /usr/local
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# /usr/local/go/bin now contains: go, gofmt, etc.

# Add to system-wide PATH
sudo tee /etc/profile.d/go.sh << 'EOF'
export PATH=$PATH:/usr/local/go/bin
EOF

# Verify
go version
# Output: go version go1.21.5 linux/amd64
```

**Why /usr/local?** System-wide Go installation, all developers need it.

#### ✅ Example 3: Installing a Custom-Compiled Tool

```bash
# Install neovim from source
git clone https://github.com/neovim/neovim
cd neovim

# Build with /usr/local prefix
make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX=/usr/local
sudo make install

# Verify
which nvim
# Output: /usr/local/bin/nvim

nvim --version
# Output: NVIM v0.9.4
```

**Why /usr/local/bin?** Custom-compiled, system-wide editor.

#### ✅ Example 4: System-Wide Git Hooks

```bash
# Install company-standard git hooks
sudo tee /usr/local/bin/install-git-hooks << 'EOF'
#!/usr/bin/env bash
# Install standard git hooks for project

REPO_DIR="${1:-.}"
HOOKS_DIR="$REPO_DIR/.git/hooks"

echo "Installing hooks to $HOOKS_DIR"

# Pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'HOOK'
#!/usr/bin/env bash
# Run linters before commit
npm run lint || exit 1
npm run test || exit 1
HOOK

chmod +x "$HOOKS_DIR/pre-commit"
echo "✅ Hooks installed"
EOF

sudo chmod +x /usr/local/bin/install-git-hooks

# Any user can now run
cd ~/apps/project
install-git-hooks
```

**Why /usr/local/bin?** Development tool used by entire team.

#### ❌ Example 5: Python Package (WRONG - Use pip)

```bash
# ❌ BAD: Manually copying Python package to /usr/local/bin
sudo cp ~/Downloads/mytool.py /usr/local/bin/mytool
sudo chmod +x /usr/local/bin/mytool

# ✅ GOOD: Use proper Python packaging
cd ~/Downloads/mytool
sudo pip install.
# Automatically installs to correct location with dependencies
```

**Why wrong?** Python tools should use pip for dependency management.

### Permission Considerations

```bash
# All /usr/local/bin files should be:
# - Owned by root:root (or root:staff on some systems)
# - Executable by all (755)
# - NOT writable by non-root (security risk)

# Check permissions
ls -l /usr/local/bin/

# Correct permissions
# -rwxr-xr-x 1 root root 12345 Nov 09 10:00 tool

# Fix permissions if needed
sudo chown root:root /usr/local/bin/tool
sudo chmod 755 /usr/local/bin/tool
```

---

## 3. Project-Specific Tools → <project>/bin

### When to Use

✅ **Use when**:
- Tool is specific to one project
- Should be version-controlled with project
- Team members need consistent tooling
- Tool depends on project structure
- Development/build helpers
- Testing utilities

❌ **Don't use when**:
- Tool is useful across multiple projects (use ~/bin or /usr/local/bin)
- Not related to project code
- Should be in global PATH always

### Directory Structure

```
myproject/
├── bin/ # Project executables (in project PATH)
│ ├── setup # Initial project setup
│ ├── dev # Start development server
│ ├── test # Run test suite
│ ├── deploy # Deployment script
│ └── cleanup # Clean build artifacts
├── scripts/ # Support scripts (NOT in PATH)
│ ├── install-deps.sh # Called by bin/setup
│ ├── build-docker.sh # Build helpers
│ └── migrate-db.sh # Database utilities
├── src/ # Source code
└── tests/ # Tests
```

### PATH Management

```bash
# Option 1: Temporary PATH (per-session)
cd ~/apps/project
export PATH="$PWD/bin:$PATH"
dev # Runs ~/apps/project/bin/dev

# Option 2: Project-specific PATH in.envrc (direnv)
echo 'export PATH="$PWD/bin:$PATH"' > ~/apps/project/.envrc
direnv allow ~/apps/project
cd ~/apps/project
# PATH automatically includes bin/

# Option 3: Add to shell config (if always working on this project)
echo 'export PATH="$HOME/apps/app/bin:$PATH"' >> ~/.bashrc

# Option 4: Symlinks to ~/bin (for frequently-used tools)
ln -s ~/apps/project/bin/dev ~/bin/app-dev
ln -s ~/apps/project/bin/test ~/bin/this project-test
```

### Installation Examples

#### ✅ Example 1: Development Environment Script

```bash
# Create project development launcher
cat > ~/apps/project/bin/dev << 'EOF'
#!/usr/bin/env bash
# Start this project development environment
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 Starting this project development environment..."

# Check dependencies
command -v node >/dev/null || { echo "❌ Node.js not found"; exit 1; }
command -v docker >/dev/null || { echo "❌ Docker not found"; exit 1; }

# Start services
docker-compose up -d redis postgres
npm run dev
EOF

chmod +x ~/apps/project/bin/dev

# Usage (from project directory)
cd ~/apps/project
./bin/dev

# Or with PATH
export PATH="$PWD/bin:$PATH"
dev
```

**Why project/bin?** Project-specific, version-controlled, team collaboration.

#### ✅ Example 2: Test Runner Wrapper

```bash
# Create smart test runner
cat > ~/apps/project/bin/test << 'EOF'
#!/usr/bin/env bash
# Run this project tests with automatic setup
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Parse arguments
WATCH=false
COVERAGE=false

while [[ $# -gt 0 ]]; do
 case $1 in
 -w|--watch) WATCH=true; shift;;
 -c|--coverage) COVERAGE=true; shift;;
 *) TEST_PATTERN="$1"; shift;;
 esac
done

# Run tests
if [ "$WATCH" = true ]; then
 npm run test:watch "${TEST_PATTERN:-}"
elif [ "$COVERAGE" = true ]; then
 npm run test:coverage "${TEST_PATTERN:-}"
else
 npm run test "${TEST_PATTERN:-}"
fi
EOF

chmod +x ~/apps/project/bin/test

# Usage examples
./bin/test # Run all tests
./bin/test --watch # Watch mode
./bin/test --coverage # With coverage
./bin/test api/sessions # Specific pattern
```

**Why project/bin?** Project test configuration, team consistency.

#### ✅ Example 3: Database Management Scripts

```bash
# Create database reset script
cat > ~/apps/project/bin/db-reset << 'EOF'
#!/usr/bin/env bash
# Reset the database (DESTRUCTIVE!)
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "⚠️ WARNING: This will DELETE all data!"
read -p "Are you sure? (type 'yes'): " confirm

if [ "$confirm" != "yes" ]; then
 echo "Aborted"
 exit 1
fi

echo "🗑️ Dropping database..."
rm -f prisma/this project.db

echo "📦 Running migrations..."
npx prisma migrate deploy

echo "🌱 Seeding data..."
npx prisma db seed

echo "✅ Database reset complete"
EOF

chmod +x ~/apps/project/bin/db-reset

# Usage
./bin/db-reset
```

**Why project/bin?** Project database structure, safe defaults.

#### ✅ Example 4: Deployment Script

```bash
# Create deployment script
cat > ~/apps/project/bin/deploy << 'EOF'
#!/usr/bin/env bash
# Deploy this project to production
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

ENVIRONMENT="${1:-staging}"

echo "🚀 Deploying to $ENVIRONMENT..."

# Run checks
echo "🔍 Running pre-deploy checks..."
npm run lint || exit 1
npm run type-check || exit 1
npm run test || exit 1

# Build
echo "🏗️ Building production bundle..."
npm run build || exit 1

# Deploy based on environment
case "$ENVIRONMENT" in
 staging)
 echo "📦 Deploying to Vercel staging..."
 vercel --prod=false
;;
 production)
 echo "⚠️ DEPLOYING TO PRODUCTION"
 read -p "Confirm? (type 'yes'): " confirm
 [ "$confirm" = "yes" ] || exit 1
 vercel --prod
;;
 *)
 echo "❌ Unknown environment: $ENVIRONMENT"
 echo "Usage: deploy [staging|production]"
 exit 1
;;
esac

echo "✅ Deployment complete"
EOF

chmod +x ~/apps/project/bin/deploy

# Usage
./bin/deploy staging
./bin/deploy production
```

**Why project/bin?** Deployment configuration embedded with code.

#### ❌ Example 5: Generic Git Utility (WRONG LOCATION)

```bash
# ❌ BAD: Generic git helper in project bin
cat > ~/apps/project/bin/git-branch-cleanup << 'EOF'
#!/usr/bin/env bash
# Clean up merged branches - useful for ANY git repo
git branch --merged | grep -v "\*" | grep -v "main" | xargs -n 1 git branch -d
EOF

# ✅ GOOD: Move to personal bin instead
cat > ~/bin/git-branch-cleanup << 'EOF'
#!/usr/bin/env bash
# Clean up merged branches - useful for ANY git repo
git branch --merged | grep -v "\*" | grep -v "main" | xargs -n 1 git branch -d
EOF
chmod +x ~/bin/git-branch-cleanup
```

**Why wrong?** Generic tools belong in personal/system bin, not project-specific.

---

## 4. Language Package Managers

### Overview

Different language ecosystems have their own conventions for installing binaries.

| Language | Package Manager | Default Install Location | User Install Location |
|----------|----------------|--------------------------|------------------------|
| Node.js | npm | `/usr/local/lib/node_modules/.bin` | `~/.npm-global/bin` |
| Python | pip | `/usr/local/bin` | `~/.local/bin` |
| Rust | cargo | N/A (no system install) | `~/.cargo/bin` |
| Go | go install | N/A (no global install) | `~/go/bin` |
| Ruby | gem | `/usr/local/bin` | `~/.gem/ruby/X.Y.Z/bin` |

### Node.js / npm

#### ✅ Example: Installing a Global npm Package

```bash
# Option 1: Global install (requires root or sudo)
sudo npm install -g typescript

# Binary installed to: /usr/local/lib/node_modules/.bin/tsc
# Symlink in: /usr/local/bin/tsc

which tsc
# Output: /usr/local/bin/tsc

# Option 2: User-global install (no sudo required)
npm config set prefix '~/.npm-global'
npm install -g typescript

# Binary in: ~/.npm-global/bin/tsc

# Add to PATH
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

which tsc
# Output: /home/user/.npm-global/bin/tsc
```

#### ❌ Example: Manual Binary Installation (WRONG)

```bash
# ❌ BAD: Manually copying node package binary
sudo cp node_modules/.bin/eslint /usr/local/bin/

# ✅ GOOD: Use npm global install
npm install -g eslint
```

**Why wrong?** Missing dependencies, wrong version management.

### Python / pip

#### ✅ Example: Installing Python CLI Tools

```bash
# Option 1: System-wide (requires sudo)
sudo pip install ansible

# Installed to: /usr/local/bin/ansible

which ansible
# Output: /usr/local/bin/ansible

# Option 2: User install (recommended)
pip install --user ansible

# Installed to: ~/.local/bin/ansible

# Add to PATH if not already
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

which ansible
# Output: /home/user/.local/bin/ansible

# Option 3: Virtual environment (project-specific)
cd ~/apps/project
python -m venv venv
source venv/bin/activate
pip install black

# Installed to: ~/apps/project/venv/bin/black
# Only available when venv is activated
```

#### ✅ Example: Installing pipx for CLI Tools

```bash
# pipx installs each tool in isolated environment
pip install --user pipx
pipx ensurepath

# Install tools via pipx
pipx install black
pipx install poetry
pipx install pytest

# Each tool gets its own virtualenv in ~/.local/pipx/venvs/
# Binaries in ~/.local/bin/

which black
# Output: /home/user/.local/bin/black

# Benefits:
# - Isolated dependencies (no conflicts)
# - Easy upgrades: pipx upgrade black
# - Easy removal: pipx uninstall black
```

#### ❌ Example: System pip with sudo (PROBLEMATIC)

```bash
# ⚠️ PROBLEMATIC: System pip can conflict with package manager
sudo pip install requests # Installs to /usr/lib/python3/dist-packages

# May conflict with apt install python3-requests
# Can break system Python tools

# ✅ BETTER: Use virtual environments or --user flag
```

### Rust / cargo

#### ✅ Example: Installing Rust CLI Tools

```bash
# Install tool from crates.io
cargo install ripgrep

# Installed to: ~/.cargo/bin/rg

# Add to PATH if not already
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

which rg
# Output: /home/user/.cargo/bin/rg

# Install specific version
cargo install ripgrep --version 13.0.0

# Update tool
cargo install ripgrep --force # --force to overwrite
```

#### ✅ Example: Installing from Git Repository

```bash
# Install from GitHub
cargo install --git https://github.com/user/repo

# Install from local path
cd ~/projects/mytool
cargo install --path.

# Uninstall
cargo uninstall ripgrep
```

### Go

#### ✅ Example: Installing Go Tools

```bash
# Install with go install (Go 1.16+)
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Installed to: ~/go/bin/golangci-lint

# Add to PATH
echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

which golangci-lint
# Output: /home/user/go/bin/golangci-lint

# Custom GOBIN location
export GOBIN=$HOME/.local/bin
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
# Now installs to ~/.local/bin
```

#### ✅ Example: Installing Specific Version

```bash
# Install specific version
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.54.2

# Install from main branch
go install github.com/user/tool/cmd/tool@main

# Install from local
cd ~/projects/mytool
go install./cmd/mytool
```

### Ruby / gem

#### ✅ Example: Installing Ruby Gems with Binaries

```bash
# Option 1: System-wide (requires sudo)
sudo gem install bundler

# Installed to: /usr/local/bin/bundler

# Option 2: User install
gem install bundler --user-install

# Installed to: ~/.gem/ruby/3.0.0/bin/bundler

# Add to PATH
echo 'export PATH="$HOME/.gem/ruby/3.0.0/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Better: Use variable for Ruby version
echo 'export PATH="$(ruby -r rubygems -e "puts Gem.user_dir")/bin:$PATH"' >> ~/.bashrc
```

---

## 5. Third-Party Applications → /opt/<app>/bin

### When to Use

✅ **Use when**:
- Installing pre-packaged third-party software
- Application has multiple components (bin, lib, share, etc.)
- Want clean isolation from system
- Software not managed by package manager
- Commercial software

❌ **Don't use when**:
- Package manager version available
- Single binary file (use /usr/local/bin)
- Personal tool (use ~/bin)

### Directory Structure

```
/opt/
├── app1/
│ ├── bin/ # Executables
│ ├── lib/ # Libraries
│ ├── share/ # Data files
│ ├── etc/ # Configuration
│ └── README # Documentation
├── app2/
│ └──...
└──...
```

### Installation Examples

#### ✅ Example: Installing IntelliJ IDEA

```bash
# Download
cd /tmp
wget https://download.jetbrains.com/idea/ideaIC-2023.2.5.tar.gz

# Extract to /opt
sudo tar -xzf ideaIC-2023.2.5.tar.gz -C /opt/
sudo mv /opt/idea-IC-232.10227.8 /opt/idea

# /opt/idea/
# ├── bin/
# │ ├── idea.sh # Main launcher
# │ └──...
# ├── lib/
# ├── plugins/
# └──...

# Create symlink in /usr/local/bin
sudo ln -s /opt/idea/bin/idea.sh /usr/local/bin/idea

# Now can run
idea
```

**Why /opt?** Large application with many components, clean isolation.

#### ✅ Example: Installing Custom Application Bundle

```bash
# Your company's internal tool
cd /tmp
wget https://internal.company.com/myapp-1.0.tar.gz

# Extract
sudo mkdir -p /opt/myapp
sudo tar -xzf myapp-1.0.tar.gz -C /opt/myapp --strip-components=1

# /opt/myapp/
# ├── bin/
# │ ├── myapp
# │ └── myapp-cli
# ├── lib/
# │ └── libmyapp.so
# ├── share/
# │ └── config.default
# └── LICENSE

# Add bin to PATH system-wide
sudo tee /etc/profile.d/myapp.sh << 'EOF'
export PATH="/opt/myapp/bin:$PATH"
export LD_LIBRARY_PATH="/opt/myapp/lib:$LD_LIBRARY_PATH"
EOF

# Or symlink individual binaries
sudo ln -s /opt/myapp/bin/myapp /usr/local/bin/
sudo ln -s /opt/myapp/bin/myapp-cli /usr/local/bin/

# Verify
which myapp
# Output: /usr/local/bin/myapp -> /opt/myapp/bin/myapp
```

**Why /opt?** Self-contained application, multiple components.

#### ✅ Example: Installing Google Chrome (Alternative Location)

```bash
# Chrome actually installs to /opt/google/chrome by default
# Package: google-chrome-stable.deb

# After installation:
# /opt/google/chrome/
# ├── chrome # Main binary
# ├── chrome_sandbox
# ├── libvulkan.so.1
# └──...

# Wrapper in /usr/bin/
ls -l /usr/bin/google-chrome
# Output: /usr/bin/google-chrome -> /etc/alternatives/google-chrome
```

**Why /opt?** Vendor preference, complex application structure.

---

## 6. What NOT to Do

### ❌ Never Install to /bin or /usr/bin

```bash
# ❌ WRONG: These are package manager territory
sudo cp my-script /bin/
sudo cp my-tool /usr/bin/

# Problems:
# 1. Package manager may overwrite your files
# 2. System updates can break your tools
# 3. No clear separation from system files
# 4. Violates FHS (Filesystem Hierarchy Standard)
# 5. Makes system auditing difficult

# ✅ RIGHT: Use designated locations
sudo cp my-script /usr/local/bin/ # System-wide custom
cp my-tool ~/bin/ # Personal
```

### ❌ Never Put Scripts in Current Directory Only

```bash
# ❌ WRONG: Relying on current directory
cd ~/apps/project
./deploy.sh # Only works if in this directory

# ✅ RIGHT: Make it accessible from anywhere
# Option 1: Move to ~/bin
mv deploy.sh ~/bin/this project-deploy
chmod +x ~/bin/this project-deploy
this project-deploy # Works from anywhere

# Option 2: Create project bin/
mkdir -p bin
mv deploy.sh bin/deploy
chmod +x bin/deploy
# Add bin/ to PATH or use: ~/apps/project/bin/deploy
```

### ❌ Never Use Relative Paths in Shebangs

```bash
# ❌ WRONG
#!/bin/sh
#../../../usr/bin/python3

# ✅ RIGHT
#!/usr/bin/env python3
```

### ❌ Never Add Too Many Directories to PATH

```bash
# ❌ WRONG: PATH pollution
export PATH="$PATH:/dir1:/dir2:/dir3:/dir4:/dir5:/dir6:/dir7:/dir8:/dir9:/dir10"

# Problems:
# 1. Slow command lookup
# 2. Difficult to debug
# 3. Name collision risk
# 4. Hard to maintain

# ✅ RIGHT: Use consolidation
# Create symlinks in ~/bin to actual tools
ln -s /path/to/project1/tool1 ~/bin/
ln -s /path/to/project2/tool2 ~/bin/
export PATH="$HOME/bin:$PATH"
```

### ❌ Never Install Without Verification

```bash
# ❌ WRONG: Install untrusted script directly
curl https://unknown-site.com/install.sh | sudo bash

# Problems:
# 1. Executes with root privileges
# 2. No review of what it does
# 3. Could be malicious
# 4. No way to undo

# ✅ RIGHT: Download, review, then install
cd /tmp
curl -O https://known-site.com/install.sh
less install.sh # REVIEW THE CODE
chmod +x install.sh
./install.sh # Run without sudo first if possible
```

---

## 7. Decision Flowchart (Detailed)

```
START: Need to install executable
 │
 ▼
┌───────────────────────────┐
│ Is it a package? │
│ (apt, yum, dnf available?)│
└───────┬───────────────────┘
 │
 Yes │ No
 │
 ▼
 ┌──────────────────┐
 │ Use package │
 │ manager! │
 │ (apt install...) │
 └──────────────────┘

 │ No (continue)
 ▼
┌───────────────────────────┐
│ Who needs access? │
└───────┬───────────────────┘
 │
 ┌──┴──┐
 │ │
 Only │ All users
 you │ (system-wide)
 │ │
 ▼ ▼
┌─────────────┐ ┌─────────────────────────┐
│ Personal │ │ What type? │
│ installation│ └───────┬─────────────────┘
└──────┬──────┘ │
 │ ┌─────┴─────┐
 │ │ │
 │ Single Multi-component
 │ binary application
 │ │ │
 │ ▼ ▼
 │ ┌─────────────┐ ┌──────────────┐
 │ │/usr/local/ │ │ /opt/ │
 │ │ bin │ │ <app>/bin │
 │ └─────────────┘ └──────────────┘
 │
 ▼
┌─────────────────────────┐
│ Is it project-specific? │
└────────┬────────────────┘
 │
 Yes │ No
 │
 ▼
 ┌─────────────┐
 │<project>/bin│
 │(add to PATH │
 │ or symlink) │
 └─────────────┘
 │
 │ No (generic tool)
 ▼
 ┌─────────────┐
 │ ~/bin or │
 │~/.local/bin │
 └─────────────┘
 │
 ▼
┌─────────────────────────┐
│ Is it from language PM? │
│ (npm, pip, cargo, go) │
└────────┬────────────────┘
 │
 Yes│ No
 │
 ▼
 ┌─────────────────────┐
 │ Use PM's location: │
 │ npm → ~/.npm-global │
 │ pip → ~/.local/bin │
 │ cargo → ~/.cargo/bin│
 │ go → ~/go/bin │
 └─────────────────────┘
 │
 │ No (custom)
 ▼
 ┌─────────────┐
 │ ~/bin │
 └─────────────┘
```

---

## 8. Installation Checklist

Before installing any executable, use this checklist:

### Pre-Installation

- [ ] Is there a package manager version? → Use that instead
- [ ] Do I have permission to install here? → Check with `touch /target/test`
- [ ] Is the source trusted? → Verify checksums, signatures
- [ ] Have I reviewed the installation script? → Never pipe to bash without review
- [ ] Will this conflict with existing tools? → Check with `which <command>`
- [ ] Do I need this system-wide or personal? → Decide location

### Installation

- [ ] Downloaded from official source
- [ ] Verified checksum (SHA256, GPG signature)
- [ ] Reviewed installation script/method
- [ ] Chose correct installation location
- [ ] Set correct permissions (755 for executables)
- [ ] Set correct ownership (root:root for system, user:user for personal)
- [ ] Updated PATH if needed
- [ ] Created symlinks if necessary

### Post-Installation

- [ ] Verified command is found → `which <command>`
- [ ] Verified correct version → `<command> --version`
- [ ] Tested basic functionality
- [ ] Documented installation (for team/future reference)
- [ ] Added to infrastructure-as-code if applicable
- [ ] Cleaned up installation files

### Example Checklist Usage

```bash
# Installing bat (modern cat alternative)

# 1. Check package manager
apt search bat
# ✅ Found: bat (0.18.3) - but want latest (0.24.0)

# 2. Check permissions
touch /usr/local/bin/test && rm /usr/local/bin/test
# ✅ Have sudo access

# 3. Download from GitHub releases
cd /tmp
wget https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-unknown-linux-gnu.tar.gz

# 4. Verify checksum
sha256sum bat-v0.24.0-x86_64-unknown-linux-gnu.tar.gz
# Compare with checksum from GitHub releases page
# ✅ Matches

# 5. Check for conflicts
which bat
# /usr/bin/bat (old version from apt)

# 6. Install to /usr/local/bin (higher precedence)
tar xzf bat-v0.24.0-x86_64-unknown-linux-gnu.tar.gz
cd bat-v0.24.0-x86_64-unknown-linux-gnu
sudo cp bat /usr/local/bin/
sudo chmod 755 /usr/local/bin/bat

# 7. Verify
which bat
# /usr/local/bin/bat (✅ correct - /usr/local before /usr in PATH)

bat --version
# bat 0.24.0 (✅ latest version)

# 8. Test
bat ~/.bashrc
# ✅ Works!

# 9. Clean up
cd /tmp
rm -rf bat-v0.24.0-*

# 10. Document
echo "Installed bat 0.24.0 to /usr/local/bin/ on $(date)" >> ~/installations.log
```

---

## 9. Uninstallation Procedures

### Uninstalling from ~/bin

```bash
# Simple: just remove the file
rm ~/bin/my-script

# If symlink to project
ls -l ~/bin/my-script
# If shows -> /path/to/project/script, just remove symlink
rm ~/bin/my-script
# Original file in project remains
```

### Uninstalling from /usr/local/bin

```bash
# Remove the binary
sudo rm /usr/local/bin/my-tool

# If it's a complex installation with lib, share, etc.
sudo rm -rf /usr/local/bin/my-tool
sudo rm -rf /usr/local/lib/my-tool
sudo rm -rf /usr/local/share/my-tool

# Remove from PATH (if added to profile.d)
sudo rm /etc/profile.d/my-tool.sh

# Update command cache
hash -r
```

### Uninstalling from /opt

```bash
# Remove entire application directory
sudo rm -rf /opt/myapp

# Remove symlinks if created
sudo rm /usr/local/bin/myapp

# Remove PATH additions
sudo rm /etc/profile.d/myapp.sh

# Update cache
hash -r
```

### Uninstalling Language Package Manager Tools

```bash
# npm
npm uninstall -g typescript

# pip
pip uninstall ansible
# or
pipx uninstall ansible

# cargo
cargo uninstall ripgrep

# go (no built-in uninstall)
rm ~/go/bin/golangci-lint

# gem
gem uninstall bundler
```

---

## 10. Common Mistakes and How to Avoid Them

### Mistake #1: Installing to Wrong Location

```bash
# ❌ MISTAKE: Personal script in system location
sudo cp ~/my-script.sh /usr/local/bin/

# Problem: Unnecessarily using sudo, mixing personal/system

# ✅ FIX: Use personal bin
cp ~/my-script.sh ~/bin/my-script
chmod +x ~/bin/my-script
```

### Mistake #2: Not Making Script Executable

```bash
# ❌ MISTAKE: Copy but forget chmod
cp script.sh ~/bin/script

# Trying to run
script
# bash: script: Permission denied

# ✅ FIX: Always chmod +x
cp script.sh ~/bin/script
chmod +x ~/bin/script
```

### Mistake #3: Hardcoded Paths

```bash
# ❌ MISTAKE: Hardcoded interpreter
#!/usr/bin/python3 # May not exist on all systems

# ❌ MISTAKE: Hardcoded helper paths
/home/user/scripts/helper.sh # Breaks for other users

# ✅ FIX: Use env and relative paths
#!/usr/bin/env python3

# Find script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/helper.sh"
```

### Mistake #4: Name Collisions

```bash
# ❌ MISTAKE: Generic names
~/bin/test # Conflicts with /usr/bin/test
~/bin/time # Conflicts with /usr/bin/time
~/bin/build # Too generic

# ✅ FIX: Use prefixed/namespaced names
~/bin/myproject-test
~/bin/myproject-time
~/bin/myproject-build
```

### Mistake #5: Not Updating PATH

```bash
# ❌ MISTAKE: Install but forget PATH
cp script ~/bin/script
chmod +x ~/bin/script
script
# bash: script: command not found

# ✅ FIX: Ensure PATH includes ~/bin
echo $PATH | grep -q "$HOME/bin" || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Mistake #6: Installing Untrusted Code

```bash
# ❌ MISTAKE: Pipe to bash
curl https://get.example.com/install | sudo bash

# ✅ FIX: Download, review, then run
curl -o install.sh https://get.example.com/install
less install.sh # REVIEW!
bash install.sh # Run without sudo if possible
```

### Mistake #7: Overwriting System Commands

```bash
# ❌ MISTAKE: Shadowing system command
cat > ~/bin/ls << 'EOF'
#!/bin/bash
echo "Custom ls"
EOF
chmod +x ~/bin/ls

# Now 'ls' runs your script instead of system ls
# Can break many things!

# ✅ FIX: Use unique name
mv ~/bin/ls ~/bin/my-ls
# Or remove from PATH if you want system ls
```

---

## 11. Case Studies

### Case Study #1: Developer Workflow Scripts

**Scenario**: Developer works on 5 different projects, each needs custom build/test/deploy scripts.

**❌ Wrong Approach**:
```bash
# Pollute PATH with all project bin directories
export PATH="$PATH:/home/dev/proj1/bin:/home/dev/proj2/bin:/home/dev/proj3/bin:/home/dev/proj4/bin:/home/dev/proj5/bin"

# Problems:
# - Long PATH
# - Name collisions (all have "build", "test", etc.)
# - Slow command lookup
```

**✅ Right Approach**:
```bash
# Option 1: Use project-specific PATH via direnv
# Install direnv: apt install direnv

# In each project:
echo 'export PATH="$PWD/bin:$PATH"' >.envrc
direnv allow

# Now when cd into project, its bin/ is automatically in PATH
cd ~/proj1
test # Runs ~/proj1/bin/test
cd ~/proj2
test # Runs ~/proj2/bin/test

# Option 2: Use namespaced symlinks in ~/bin
ln -s ~/proj1/bin/build ~/bin/proj1-build
ln -s ~/proj1/bin/test ~/bin/proj1-test
ln -s ~/proj2/bin/build ~/bin/proj2-build
ln -s ~/proj2/bin/test ~/bin/proj2-test
#...

# Now from anywhere:
proj1-build
proj2-test
```

### Case Study #2: System Administration Scripts

**Scenario**: Sysadmin needs to deploy monitoring scripts to 20 servers.

**❌ Wrong Approach**:
```bash
# Install to ~/bin on each server
scp monitor.sh server1:~/bin/
scp monitor.sh server2:~/bin/
#...

# Problems:
# - Only works if sysadmin is logged in
# - Doesn't run as service
# - Other admins can't access
```

**✅ Right Approach**:
```bash
# Install to /usr/local/bin (system-wide)
for server in server{1..20}; do
 scp monitor.sh $server:/tmp/
 ssh $server 'sudo cp /tmp/monitor.sh /usr/local/bin/monitor && \
 sudo chmod 755 /usr/local/bin/monitor && \
 sudo chown root:root /usr/local/bin/monitor'
done

# Create systemd service
cat > monitor.service << 'EOF'
[Unit]
Description=System Monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/monitor
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Deploy service
for server in server{1..20}; do
 scp monitor.service $server:/tmp/
 ssh $server 'sudo cp /tmp/monitor.service /etc/systemd/system/ && \
 sudo systemctl daemon-reload && \
 sudo systemctl enable monitor && \
 sudo systemctl start monitor'
done

# Benefits:
# - Runs on boot
# - Available to all users
# - Managed by systemd
# - Consistent across servers
```

### Case Study #3: Python CLI Tool Development

**Scenario**: Developing a Python CLI tool, need to test it frequently.

**❌ Wrong Approach**:
```bash
# Run with python every time
cd ~/projects/mytool
python -m mytool.cli arg1 arg2

# Problems:
# - Can't run from anywhere
# - Verbose command
# - Not testing actual installation
```

**✅ Right Approach**:
```bash
# Create setup.py with entry_point
cat > setup.py << 'EOF'
from setuptools import setup, find_packages

setup(
 name='mytool',
 version='0.1.0',
 packages=find_packages,
 entry_points={
 'console_scripts': [
 'mytool=mytool.cli:main',
 ],
 },
)
EOF

# Install in development mode
cd ~/projects/mytool
pip install --editable.

# Now can run from anywhere
cd ~
mytool arg1 arg2

# Benefits:
# - Tests actual installation
# - Auto-updates when code changes (editable install)
# - Creates proper executable in ~/.local/bin/mytool
# - Mimics real user experience
```

### Case Study #4: Team Development Environment

**Scenario**: Team of 10 developers need consistent tooling for a project.

**❌ Wrong Approach**:
```bash
# Tell everyone to install tools manually
# "Everyone please install these tools: foo, bar, baz"

# Problems:
# - Version inconsistencies
# - Some people forget
# - New team members have to ask
```

**✅ Right Approach**:
```bash
# Create project bin/ with setup script
mkdir -p ~/projects/app/bin

cat > ~/projects/app/bin/setup << 'EOF'
#!/usr/bin/env bash
# Setup this project development environment
set -euo pipefail

echo "🔧 Setting up this project development environment..."

# Check prerequisites
command -v node >/dev/null || { echo "❌ Node.js required"; exit 1; }
command -v docker >/dev/null || { echo "❌ Docker required"; exit 1; }

# Install dependencies
echo "📦 Installing npm dependencies..."
npm install

# Setup database
echo "🗄️ Setting up database..."
npx prisma migrate dev

# Create local bin symlinks
echo "🔗 Creating command shortcuts..."
mkdir -p ~/bin
ln -sf "$PWD/bin/dev" ~/bin/app-dev
ln -sf "$PWD/bin/test" ~/bin/this project-test
ln -sf "$PWD/bin/deploy" ~/bin/this project-deploy

echo "✅ Setup complete!"
echo ""
echo "Available commands:"
echo " app-dev - Start development server"
echo " this project-test - Run tests"
echo " this project-deploy - Deploy application"
EOF

chmod +x ~/projects/app/bin/setup

# Document in README.md
cat >> README.md << 'EOF'
## Setup

```bash
git clone https://github.com/company/this project
cd this project
./bin/setup
```

This will install all dependencies and create command shortcuts.
EOF

# Benefits:
# - One command setup
# - Consistent environment
# - Self-documenting
# - Easy for new team members
```

### Case Study #5: Multi-Version Tool Management

**Scenario**: Need Python 3.9, 3.10, and 3.11 for different projects.

**❌ Wrong Approach**:
```bash
# Install all to system, use full paths
sudo apt install python3.9 python3.10 python3.11

# Run specific version with full path
/usr/bin/python3.9 script.py
/usr/bin/python3.10 script.py

# Problems:
# - Verbose
# - Easy to forget which version
# - Scripts need to know absolute paths
```

**✅ Right Approach**:
```bash
# Option 1: Use pyenv (version manager)
curl https://pyenv.run | bash

# Install versions
pyenv install 3.9.17
pyenv install 3.10.12
pyenv install 3.11.4

# Set global default
pyenv global 3.11.4

# Set project-specific version
cd ~/projects/legacy-app
pyenv local 3.9.17
# Creates.python-version file

# Now python points to correct version automatically
python --version # 3.9.17 in legacy-app directory

# Option 2: Use update-alternatives (system-wide)
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.10 2
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 3

# Switch versions
sudo update-alternatives --config python
# Interactive menu to choose

# Option 3: Project virtual environments
cd ~/projects/app1
python3.9 -m venv venv
source venv/bin/activate
# Now python points to 3.9

cd ~/projects/app2
python3.11 -m venv venv
source venv/bin/activate
# Now python points to 3.11
```

### Case Study #6: Installing Commercial Software

**Scenario**: Installing Oracle SQL Developer (large third-party app).

**✅ Correct Approach**:
```bash
# Download from vendor
cd /tmp
wget https://download.oracle.com/otn/java/sqldeveloper/sqldeveloper-23.1.0.097.1607-no-jre.zip

# Extract to /opt
sudo unzip sqldeveloper-23.1.0.097.1607-no-jre.zip -d /opt/

# /opt/sqldeveloper/
# ├── sqldeveloper.sh
# ├── lib/
# ├── modules/
# └──...

# Create launcher in /usr/local/bin
sudo tee /usr/local/bin/sqldeveloper << 'EOF'
#!/bin/bash
cd /opt/sqldeveloper
./sqldeveloper.sh "$@"
EOF

sudo chmod +x /usr/local/bin/sqldeveloper

# Create desktop entry (optional)
sudo tee /usr/share/applications/sqldeveloper.desktop << 'EOF'
[Desktop Entry]
Name=SQL Developer
Comment=Oracle SQL Developer
Exec=/usr/local/bin/sqldeveloper
Icon=/opt/sqldeveloper/icon.png
Terminal=false
Type=Application
Categories=Development;
EOF

# Now can run from anywhere
sqldeveloper

# Benefits:
# - Clean isolation in /opt
# - Easy to uninstall (just rm -rf /opt/sqldeveloper)
# - Doesn't mix with system files
# - Accessible to all users
```

---

## 12. Reference Summary

### Quick Decision Table

| Your Situation | Recommended Location | Add to PATH? | Requires Root? |
|----------------|---------------------|--------------|----------------|
| Personal shell script | `~/bin/` | Yes (user) | No |
| Personal Python tool | `~/.local/bin/` (via pip --user) | Yes (user) | No |
| System admin script | `/usr/local/bin/` | Already in PATH | Yes |
| Custom-compiled tool | `/usr/local/bin/` | Already in PATH | Yes |
| Project dev script | `<project>/bin/` | Optional | No |
| Node.js global tool | `~/.npm-global/bin/` | Yes (user) | No |
| Rust tool | `~/.cargo/bin/` | Yes (user) | No |
| Go tool | `~/go/bin/` | Yes (user) | No |
| Large third-party app | `/opt/<app>/bin/` | Via symlink | Yes |
| Package manager tool | `/usr/bin/` (via apt/yum) | Already in PATH | Yes (via PM) |

### PATH Priority Order

```bash
# Recommended PATH order (first = highest priority)
export PATH="\
$HOME/bin:\
$HOME/.local/bin:\
$HOME/.cargo/bin:\
$HOME/go/bin:\
/usr/local/bin:\
/usr/bin:\
/bin"

# Why this order?
# 1. ~/bin - Your personal overrides
# 2. ~/.local/bin - User-installed tools (pip --user, etc.)
# 3. Language-specific bins (cargo, go)
# 4. /usr/local/bin - System custom tools
# 5. /usr/bin - Distribution packages
# 6. /bin - Essential system binaries
```

### Command Summary

```bash
# Discovery
which <cmd> # Find first match in PATH
which -a <cmd> # Find all matches
type <cmd> # Show command type
whereis <cmd> # Find binary, source, man pages

# PATH management
echo $PATH # Show current PATH
echo $PATH | tr ':' '\n' # Show PATH (one per line)
export PATH="/new/dir:$PATH" # Add directory (temporary)
echo 'export PATH="..."' >> ~/.bashrc # Add directory (permanent)

# Installation
mkdir -p ~/bin # Create personal bin
chmod +x ~/bin/script # Make executable
sudo cp tool /usr/local/bin/ # Install system-wide
ln -s /path/to/tool ~/bin/name # Create symlink

# Verification
command -v <cmd> # Check if exists (script-safe)
<cmd> --version # Check version
ls -l $(which <cmd>) # Show permissions/ownership

# Troubleshooting
hash -r # Clear bash command cache
type -a <cmd> # Show all versions
strace -e execve <cmd> # Trace command execution
```

---

## Conclusion

Choosing the right installation location is crucial for:
- **Maintainability**: Easy to find and update
- **Security**: Proper permissions and ownership
- **Portability**: Works across systems and users
- **Clarity**: Clear separation of concerns

**Golden Rules Recap**:
1. Personal → `~/bin` or `~/.local/bin`
2. System → `/usr/local/bin`
3. Project → `<project>/bin`
4. Third-party → `/opt/<app>/bin`
5. Never → `/bin` or `/usr/bin` (package manager territory)

**When in doubt**: Start with `~/bin`. You can always move to system locations later if needed.

---

**Document Status**: Complete (728 lines)
**Last Updated**: November 9, 2025
**Part of**: Linux bin Directories Knowledge Base
**Related**: [03-PATH-VARIABLE.md](03-PATH-VARIABLE.md), [06-PERSONAL-BIN.md](06-PERSONAL-BIN.md), [09-PACKAGE-MANAGEMENT.md](09-PACKAGE-MANAGEMENT.md)
