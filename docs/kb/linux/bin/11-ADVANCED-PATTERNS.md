---
id: linux-11-advanced-patterns
topic: linux
file_role: patterns
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: []
related_topics: ['unix', 'shell', 'bash']
embedding_keywords: [linux, patterns, examples, integration]
last_reviewed: 2025-11-13
---

# Advanced Patterns and Multi-Version Management

**Part of Linux Bin Directories Knowledge Base**

## Table of Contents
1. [Overview](#overview)
2. [Multi-Version Management Strategies](#multi-version-management-strategies)
3. [Python Version Managers](#python-version-managers)
4. [Node.js Version Managers](#nodejs-version-managers)
5. [Ruby Version Managers](#ruby-version-managers)
6. [Go Version Management](#go-version-management)
7. [Rust Toolchain Management](#rust-toolchain-management)
8. [Direnv for Project-Specific Environments](#direnv-for-project-specific-environments)
9. [Wrapper Scripts Pattern](#wrapper-scripts-pattern)
10. [Shell Functions as Commands](#shell-functions-as-commands)
11. [Dynamic PATH Modification](#dynamic-path-modification)
12. [Container-Based Tool Isolation](#container-based-tool-isolation)
13. [Complex Multi-Project Setups](#complex-multi-project-setups)
14. [CI/CD Integration](#cicd-integration)

---

## Overview

Modern development often requires managing multiple versions of programming languages and tools simultaneously. This guide covers advanced patterns for handling complex binary management scenarios.

### Why Multi-Version Management?

**Common scenarios**:
- Different projects require different language versions
- Testing across multiple versions
- Maintaining legacy applications
- Gradual migration to newer versions
- CI/CD pipeline requirements

### Management Approaches

1. **System alternatives** - OS-level version switching
2. **Version managers** - Tool-specific version management
3. **Virtual environments** - Isolated dependency management
4. **Containers** - Complete isolation
5. **Wrapper scripts** - Custom version selection logic

---

## Multi-Version Management Strategies

### Strategy 1: System-Level (Alternatives)

```bash
# ✅ Pros: System-wide, simple, no additional tools
# ❌ Cons: Requires root, affects all users, limited flexibility

# Install multiple versions
sudo apt install python3.9 python3.10 python3.11

# Set up alternatives
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 2
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 3

# Switch versions
sudo update-alternatives --config python3
```

### Strategy 2: Version Managers

```bash
# ✅ Pros: Per-user, automatic switching, extensive features
# ❌ Cons: Another tool to install, shell integration needed

# Examples:
# - pyenv (Python)
# - nvm (Node.js)
# - rbenv (Ruby)
# - rustup (Rust)
# - gvm (Go)
```

### Strategy 3: Virtual Environments

```bash
# ✅ Pros: Project-specific dependencies, no version manager needed
# ❌ Cons: Manual activation, doesn't manage language versions

# Python venv
python3 -m venv myproject-env
source myproject-env/bin/activate

# Node.js local install
mkdir myproject
cd myproject
npm init -y
npm install --save-dev node@18
```

### Strategy 4: Containers

```bash
# ✅ Pros: Complete isolation, reproducible, portable
# ❌ Cons: Overhead, complexity, requires Docker knowledge

# Run specific Python version
docker run -it python:3.11 python --version

# Project-specific container
docker run -v $(pwd):/app -w /app python:3.9 python script.py
```

---

## Python Version Managers

### pyenv - Python Version Management

#### Installation

```bash
# ✅ Install pyenv
curl https://pyenv.run | bash

# Add to ~/.bashrc or ~/.zshrc
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Reload shell
exec $SHELL
```

#### Basic Usage

```bash
# ✅ List available Python versions
pyenv install --list | grep "^ 3\."

# ✅ Install specific version
pyenv install 3.11.5
pyenv install 3.9.18

# ✅ List installed versions
pyenv versions
# * system (set by /home/user/.pyenv/version)
# 3.9.18
# 3.11.5

# ✅ Set global default
pyenv global 3.11.5
python --version
# Python 3.11.5

# ✅ Set version for current directory
cd ~/myproject
pyenv local 3.9.18
python --version
# Python 3.9.18

# Creates.python-version file
cat.python-version
# 3.9.18
```

#### How pyenv Works

```bash
# ✅ pyenv uses shims
which python
# /home/user/.pyenv/shims/python

# ✅ The shim redirects to correct version
cat ~/.pyenv/shims/python
# #!/usr/bin/env bash
# set -e
# [ -n "$PYENV_DEBUG" ] && set -x
# program="${0##*/}"
# exec "$(dirname "$0")/pyenv" exec "$program" "$@"

# ✅ Actual Python binaries are here
ls ~/.pyenv/versions/
# 3.9.18/
# 3.11.5/

ls ~/.pyenv/versions/3.11.5/bin/
# python python3 python3.11 pip pip3
```

#### Advanced pyenv Usage

```bash
# ✅ Multiple versions simultaneously (testing)
pyenv shell 3.9.18 3.10.13 3.11.5
python3.9 --version # Python 3.9.18
python3.10 --version # Python 3.10.13
python3.11 --version # Python 3.11.5

# ✅ Unset local version
pyenv local --unset

# ✅ Uninstall version
pyenv uninstall 3.9.18

# ✅ Update pyenv
cd ~/.pyenv && git pull
```

### virtualenv with pyenv

```bash
# ✅ Create virtual environment with specific Python
pyenv virtualenv 3.11.5 myproject-env

# ✅ Activate
pyenv activate myproject-env

# ✅ Auto-activation when entering directory
cd ~/myproject
pyenv local myproject-env
# Now automatically activated when cd'ing into directory

# ✅ List virtual environments
pyenv virtualenvs
# * myproject-env (created from /home/user/.pyenv/versions/3.11.5)
# another-env (created from /home/user/.pyenv/versions/3.9.18)

# ✅ Deactivate
pyenv deactivate

# ✅ Delete virtual environment
pyenv uninstall myproject-env
```

### pipx - Isolated Python Applications

```bash
# ✅ Install pipx
python3 -m pip install --user pipx
python3 -m pipx ensurepath

# ✅ Install applications in isolated environments
pipx install black
pipx install flake8
pipx install youtube-dl

# Each gets its own environment
ls ~/.local/pipx/venvs/
# black/
# flake8/
# youtube-dl/

# But binaries are in PATH
which black
# /home/user/.local/bin/black

# ✅ List installed apps
pipx list

# ✅ Upgrade app
pipx upgrade black

# ✅ Uninstall
pipx uninstall youtube-dl
```

---

## Node.js Version Managers

### nvm - Node Version Manager

#### Installation

```bash
# ✅ Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Add to ~/.bashrc or ~/.zshrc (installer usually does this)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Reload shell
exec $SHELL
```

#### Basic Usage

```bash
# ✅ List available Node versions
nvm ls-remote

# ✅ Install specific version
nvm install 18.17.0
nvm install 20.5.0

# ✅ Install latest LTS
nvm install --lts

# ✅ List installed versions
nvm ls
# -> v18.17.0
# v20.5.0
# default -> 18.17.0 (-> v18.17.0)

# ✅ Switch versions
nvm use 20.5.0
node --version
# v20.5.0

# ✅ Set default version
nvm alias default 18.17.0

# ✅ Use version specified in.nvmrc
echo "18.17.0" >.nvmrc
nvm use
# Found '/path/to/project/.nvmrc' with version <18.17.0>
# Now using node v18.17.0
```

#### How nvm Works

```bash
# ✅ nvm modifies PATH, not using shims
echo $PATH
# /home/user/.nvm/versions/node/v18.17.0/bin:/usr/local/bin:/usr/bin

which node
# /home/user/.nvm/versions/node/v18.17.0/bin/node

# ✅ Versions stored here
ls ~/.nvm/versions/node/
# v18.17.0/
# v20.5.0/
```

#### Advanced nvm Usage

```bash
# ✅ Run command with specific version without switching
nvm exec 20.5.0 node script.js

# ✅ Run command with version from.nvmrc
nvm exec node script.js

# ✅ Get path to specific version
nvm which 18.17.0
# /home/user/.nvm/versions/node/v18.17.0/bin/node

# ✅ Install node modules globally for current version
nvm use 18.17.0
npm install -g typescript
# Installs to ~/.nvm/versions/node/v18.17.0/lib/node_modules/

# ✅ Uninstall version
nvm uninstall 20.5.0

# ✅ Migrate packages between versions
nvm install 20.5.0 --reinstall-packages-from=18.17.0
```

#### Auto-Switching with Shell Hook

```bash
# ✅ Add to ~/.bashrc or ~/.zshrc for automatic switching
autoload -U add-zsh-hook
load-nvmrc {
 local node_version="$(nvm version)"
 local nvmrc_path="$(nvm_find_nvmrc)"

 if [ -n "$nvmrc_path" ]; then
 local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

 if [ "$nvmrc_node_version" = "N/A" ]; then
 nvm install
 elif [ "$nvmrc_node_version" != "$node_version" ]; then
 nvm use
 fi
 elif [ "$node_version" != "$(nvm version default)" ]; then
 echo "Reverting to nvm default version"
 nvm use default
 fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Now automatically switches when entering directory with.nvmrc
```

### volta - The Hassle-Free JavaScript Tool Manager

```bash
# ✅ Install volta
curl https://get.volta.sh | bash

# ✅ Install Node version
volta install node@18.17.0
volta install node@20.5.0

# ✅ Pin version for project
cd myproject
volta pin node@18.17.0
# Creates package.json entry:
# "volta": {
# "node": "18.17.0"
# }

# ✅ Auto-switches based on package.json
cd myproject
node --version
# v18.17.0 (automatically switched)

# ✅ Install tools
volta install npm@9.8.0
volta install yarn@1.22.19

# ✅ List installed tools
volta list
```

---

## Ruby Version Managers

### rbenv - Ruby Version Management

#### Installation

```bash
# ✅ Install rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv

# Add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Install ruby-build plugin
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Reload shell
exec $SHELL
```

#### Basic Usage

```bash
# ✅ List available Ruby versions
rbenv install --list

# ✅ Install specific version
rbenv install 3.2.2
rbenv install 3.1.4

# ✅ List installed versions
rbenv versions
# * system
# 3.1.4
# 3.2.2

# ✅ Set global version
rbenv global 3.2.2
ruby --version
# ruby 3.2.2

# ✅ Set local version
cd ~/myproject
rbenv local 3.1.4
# Creates.ruby-version file

# ✅ Refresh shims after installing gems
gem install bundler
rbenv rehash
```

### rvm - Ruby Version Manager (Alternative)

```bash
# ✅ Install rvm
\curl -sSL https://get.rvm.io | bash -s stable

# ✅ Load rvm
source ~/.rvm/scripts/rvm

# ✅ Install Ruby
rvm install 3.2.2
rvm install 3.1.4

# ✅ Use version
rvm use 3.2.2

# ✅ Set default
rvm --default use 3.2.2

# ✅ Create gemset (isolated gems)
rvm use 3.2.2@myproject --create
gem install rails

# ✅ List gemsets
rvm gemset list
```

---

## Go Version Management

### Multiple Go Versions with go install

```bash
# ✅ Install latest Go from golang.org
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz

# ✅ Add to PATH
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# ✅ Install specific Go version using go
go install golang.org/dl/go1.20.7@latest
go1.20.7 download

# ✅ Use specific version
go1.20.7 version
# go version go1.20.7 linux/amd64

# ✅ Build with specific version
go1.20.7 build main.go
```

### gvm - Go Version Manager

```bash
# ✅ Install gvm
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

# ✅ Install Go version
gvm install go1.21.0 -B
gvm install go1.20.7 -B

# ✅ Use version
gvm use go1.21.0

# ✅ Set default
gvm use go1.21.0 --default

# ✅ List versions
gvm list
# gvm gos (installed)
# => go1.20.7
# go1.21.0

# ✅ Create project-specific environment
gvm pkgset create myproject
gvm pkgset use myproject
```

### asdf - Universal Version Manager (Go + Others)

```bash
# ✅ Install asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.0

# Add to ~/.bashrc or ~/.zshrc
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash

# ✅ Add Go plugin
asdf plugin add golang

# ✅ Install Go version
asdf install golang 1.21.0
asdf install golang 1.20.7

# ✅ Set versions
asdf global golang 1.21.0 # Global default
asdf local golang 1.20.7 # Current directory

# ✅ List installed versions
asdf list golang

# ✅ asdf works for many languages
asdf plugin add python
asdf plugin add nodejs
asdf plugin add ruby
```

---

## Rust Toolchain Management

### rustup - The Rust Toolchain Installer

#### Installation

```bash
# ✅ Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# ✅ Load environment
source "$HOME/.cargo/env"
```

#### Basic Usage

```bash
# ✅ Install stable, beta, nightly
rustup install stable
rustup install beta
rustup install nightly

# ✅ Set default toolchain
rustup default stable

# ✅ Update toolchains
rustup update

# ✅ Show installed toolchains
rustup show
# active toolchain: stable-x86_64-unknown-linux-gnu
# installed toolchains:
# stable-x86_64-unknown-linux-gnu (default)
# beta-x86_64-unknown-linux-gnu
# nightly-x86_64-unknown-linux-gnu

# ✅ Use specific toolchain temporarily
rustup run nightly rustc --version
# rustc 1.74.0-nightly

# ✅ Set toolchain for project
cd myproject
rustup override set nightly
# Creates rust-toolchain.toml
```

#### Advanced Usage

```bash
# ✅ Install specific version
rustup install 1.70.0

# ✅ Install components
rustup component add clippy
rustup component add rustfmt
rustup component add rust-analyzer

# ✅ Install targets (cross-compilation)
rustup target add x86_64-unknown-linux-musl
rustup target add wasm32-unknown-unknown

# ✅ Build with specific target
cargo build --target x86_64-unknown-linux-musl

# ✅ List installed components
rustup component list --installed
```

---

## Direnv for Project-Specific Environments

### Installation

```bash
# ✅ Install direnv
# Ubuntu/Debian
sudo apt install direnv

# From source
curl -sfL https://direnv.net/install.sh | bash

# Add to ~/.bashrc or ~/.zshrc
eval "$(direnv hook bash)" # For bash
eval "$(direnv hook zsh)" # For zsh
```

### Basic Usage

```bash
# ✅ Create project with custom PATH
mkdir myproject
cd myproject

# Create.envrc file
cat >.envrc << 'EOF'
export PATH="$PWD/bin:$PATH"
export DATABASE_URL="postgresql://localhost/myproject_dev"
export RUST_LOG="debug"
EOF

# ✅ Allow direnv to load it
direnv allow

# Now environment is modified
echo $DATABASE_URL
# postgresql://localhost/myproject_dev

# ✅ Leave directory - environment reverts
cd..
echo $DATABASE_URL
# (empty)
```

### Advanced Patterns

```bash
# ✅ Load language versions
cat >.envrc << 'EOF'
# Load specific Python version
use python 3.11

# Or with pyenv
layout pyenv 3.11.5

# Activate virtualenv
layout python-venv

# Load Node.js version
use node 18.17.0
EOF

direnv allow

# ✅ Include common settings
# Create ~/.config/direnv/direnvrc
cat > ~/.config/direnv/direnvrc << 'EOF'
# Custom function for loading AWS profiles
use_aws_profile {
 export AWS_PROFILE="$1"
 export AWS_DEFAULT_REGION="us-east-1"
}

# Custom function for Docker Compose
use_docker_compose {
 export COMPOSE_PROJECT_NAME="$1"
 export COMPOSE_FILE="$PWD/docker-compose.yml"
}
EOF

# Use in.envrc
cat >.envrc << 'EOF'
use_aws_profile production
use_docker_compose myapp
EOF

# ✅ Load secrets from separate file
cat >.envrc << 'EOF'
# Load public config
export APP_ENV="development"

# Load secrets (gitignored)
source_env_if_exists.envrc.local
EOF

cat >.envrc.local << 'EOF'
export API_KEY="secret-key-here"
export DATABASE_PASSWORD="secret-password"
EOF

echo ".envrc.local" >>.gitignore
direnv allow
```

### Direnv with Language Managers

```bash
# ✅ Python with pyenv
cat >.envrc << 'EOF'
layout pyenv 3.11.5
layout python-venv
EOF

# ✅ Node with nvm
cat >.envrc << 'EOF'
use node 18.17.0
PATH_add node_modules/.bin
EOF

# ✅ Ruby with rbenv
cat >.envrc << 'EOF'
use ruby 3.2.2
layout ruby
EOF

# ✅ Go with specific GOPATH
cat >.envrc << 'EOF'
export GOPATH="$PWD/.go"
export PATH="$GOPATH/bin:$PATH"
EOF
```

---

## Wrapper Scripts Pattern

### Basic Wrapper Script

```bash
# ✅ Create wrapper that selects version based on context
cat > /usr/local/bin/python << 'EOF'
#!/bin/bash

# Check for.python-version file
if [ -f.python-version ]; then
 version=$(cat.python-version)
 exec "/usr/bin/python$version" "$@"
fi

# Check for virtual environment
if [ -n "$VIRTUAL_ENV" ]; then
 exec "$VIRTUAL_ENV/bin/python" "$@"
fi

# Default to python3
exec /usr/bin/python3 "$@"
EOF

chmod +x /usr/local/bin/python
```

### Advanced Wrapper with Logging

```bash
# ✅ Wrapper that logs usage
cat > /usr/local/bin/python-wrapper << 'EOF'
#!/bin/bash

# Log execution
log_file="$HOME/.python-wrapper.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - $PWD - $*" >> "$log_file"

# Determine version
if [ -f.python-version ]; then
 version=$(cat.python-version)
 python_bin="/usr/bin/python$version"
elif [ -f pyproject.toml ]; then
 # Parse from pyproject.toml
 version=$(grep -Po '(?<=requires-python = ")[^"]+' pyproject.toml | head -1)
 python_bin="/usr/bin/python${version#>=}"
else
 python_bin="/usr/bin/python3"
fi

# Verify binary exists
if [ ! -x "$python_bin" ]; then
 echo "Error: Python binary not found: $python_bin" >&2
 echo "Available versions:" >&2
 ls /usr/bin/python* >&2
 exit 1
fi

# Execute
exec "$python_bin" "$@"
EOF

chmod +x /usr/local/bin/python-wrapper
```

### Docker Wrapper

```bash
# ✅ Run commands in Docker container
cat > /usr/local/bin/docker-python << 'EOF'
#!/bin/bash

# Default to Python 3.11
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"

# Mount current directory
docker run --rm -it \
 -v "$(pwd):/app" \
 -w /app \
 -u "$(id -u):$(id -g)" \
 "python:${PYTHON_VERSION}" \
 python "$@"
EOF

chmod +x /usr/local/bin/docker-python

# Usage:
# docker-python script.py
# PYTHON_VERSION=3.9 docker-python script.py
```

---

## Shell Functions as Commands

### Defining Command Functions

```bash
# ✅ Add to ~/.bashrc or ~/.zshrc

# Python version selector
python {
 if [ -f.python-version ]; then
 local version=$(cat.python-version)
 command python"$version" "$@"
 else
 command python3 "$@"
 fi
}

# Node version selector with automatic nvm
node {
 if command -v nvm >/dev/null && [ -f.nvmrc ]; then
 nvm exec node "$@"
 else
 command node "$@"
 fi
}

# Git wrapper with automatic SSH key selection
git {
 if [ -f.git-ssh-key ]; then
 local key=$(cat.git-ssh-key)
 GIT_SSH_COMMAND="ssh -i $key" command git "$@"
 else
 command git "$@"
 fi
}
```

### Complex Function Example

```bash
# ✅ Intelligent project initializer
projinit {
 local name="$1"
 local type="${2:-python}"

 if [ -z "$name" ]; then
 echo "Usage: projinit <name> [python|node|rust]"
 return 1
 fi

 mkdir -p "$name"
 cd "$name" || return 1

 case "$type" in
 python)
 pyenv local 3.11.5
 python -m venv.venv
 echo ".venv/" >>.gitignore
 cat >.envrc << 'EOF'
source.venv/bin/activate
export PYTHONPATH="$PWD"
EOF
 direnv allow
;;
 node)
 echo "18.17.0" >.nvmrc
 nvm use
 npm init -y
 echo "node_modules/" >>.gitignore
;;
 rust)
 cargo init
 rustup override set stable
;;
 esac

 git init
 echo "Project $name initialized as $type project"
}
```

---

## Dynamic PATH Modification

### Intelligent PATH Builder

```bash
# ✅ Add to ~/.bashrc

# Function to safely add to PATH
pathadd {
 if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
 PATH="$1${PATH:+:$PATH}"
 fi
}

# Function to remove from PATH
pathremove {
 PATH=${PATH//:$1:/:} # Remove from middle
 PATH=${PATH/#$1:/} # Remove from beginning
 PATH=${PATH/%:$1/} # Remove from end
}

# Build PATH intelligently
build_path {
 # Start with empty PATH
 local new_path=""

 # Home bin (highest priority)
 [ -d "$HOME/bin" ] && new_path="$HOME/bin"
 [ -d "$HOME/.local/bin" ] && new_path="$new_path:$HOME/.local/bin"

 # Language-specific paths
 [ -d "$HOME/.cargo/bin" ] && new_path="$new_path:$HOME/.cargo/bin"
 [ -d "$HOME/.pyenv/shims" ] && new_path="$new_path:$HOME/.pyenv/shims"
 [ -d "$HOME/.rbenv/shims" ] && new_path="$new_path:$HOME/.rbenv/shims"

 # System paths
 new_path="$new_path:/usr/local/bin:/usr/bin:/bin"
 new_path="$new_path:/usr/local/sbin:/usr/sbin:/sbin"

 # Export clean PATH
 export PATH="$new_path"
}

# Rebuild PATH
build_path
```

### Context-Aware PATH

```bash
# ✅ Modify PATH based on current directory
cd {
 builtin cd "$@" || return

 # Reset PATH to base
 export PATH="$BASE_PATH"

 # Add project-specific bin if exists
 if [ -d "$PWD/bin" ]; then
 export PATH="$PWD/bin:$PATH"
 fi

 # Add node_modules/.bin if exists
 if [ -d "$PWD/node_modules/.bin" ]; then
 export PATH="$PWD/node_modules/.bin:$PATH"
 fi

 # Add vendor/bin if exists (PHP Composer)
 if [ -d "$PWD/vendor/bin" ]; then
 export PATH="$PWD/vendor/bin:$PATH"
 fi
}

# Save base PATH
export BASE_PATH="$PATH"
```

---

## Container-Based Tool Isolation

### Docker Tool Wrappers

```bash
# ✅ Create docker-tools directory
mkdir -p ~/.docker-tools

# Python wrapper
cat > ~/.docker-tools/python << 'EOF'
#!/bin/bash
exec docker run --rm -i \
 -v "$PWD:/app" \
 -w /app \
 -u "$(id -u):$(id -g)" \
 python:3.11 python "$@"
EOF

# Node wrapper
cat > ~/.docker-tools/node << 'EOF'
#!/bin/bash
exec docker run --rm -i \
 -v "$PWD:/app" \
 -w /app \
 -u "$(id -u):$(id -g)" \
 node:18 node "$@"
EOF

# Make executable
chmod +x ~/.docker-tools/*

# Add to PATH
export PATH="$HOME/.docker-tools:$PATH"
```

### Docker Compose Development Environment

```yaml
# ✅ docker-compose.yml for multi-language environment
version: '3.8'

services:
 python:
 image: python:3.11
 volumes:
 -.:/app
 working_dir: /app
 command: tail -f /dev/null # Keep container running

 node:
 image: node:18
 volumes:
 -.:/app
 working_dir: /app
 command: tail -f /dev/null

 rust:
 image: rust:1.73
 volumes:
 -.:/app
 - cargo-cache:/usr/local/cargo/registry
 working_dir: /app
 command: tail -f /dev/null

volumes:
 cargo-cache:
```

```bash
# ✅ Helper functions
docker-python {
 docker-compose run --rm python python "$@"
}

docker-node {
 docker-compose run --rm node node "$@"
}

docker-cargo {
 docker-compose run --rm rust cargo "$@"
}
```

---

## Complex Multi-Project Setups

### Monorepo with Multiple Languages

```bash
# ✅ Directory structure
mycompany/
â"œâ"€â"€.envrc # Root direnv config
â"œâ"€â"€ services/
â"‚ â"œâ"€â"€ api-python/
â"‚ â"‚ â"œâ"€â"€.envrc # Python-specific
â"‚ â"‚ â"œâ"€â"€.python-version
â"‚ â"‚ â""â"€â"€ requirements.txt
â"‚ â"œâ"€â"€ web-node/
â"‚ â"‚ â"œâ"€â"€.envrc # Node-specific
â"‚ â"‚ â"œâ"€â"€.nvmrc
â"‚ â"‚ â""â"€â"€ package.json
â"‚ â""â"€â"€ worker-rust/
â"‚ â"œâ"€â"€.envrc # Rust-specific
â"‚ â"œâ"€â"€ rust-toolchain.toml
â"‚ â""â"€â"€ Cargo.toml
â""â"€â"€ scripts/
 â""â"€â"€ dev.sh # Development helper

# Root.envrc
cat >.envrc << 'EOF'
# Common settings
export PROJECT_ROOT="$PWD"
export PATH="$PROJECT_ROOT/scripts:$PATH"

# Load service-specific env when in subdirectory
source_env_if_exists "services/*/".envrc
EOF

# Python service.envrc
cat > services/api-python/.envrc << 'EOF'
source_up # Load parent.envrc

layout pyenv 3.11.5
layout python-venv

export DATABASE_URL="postgresql://localhost/api_dev"
export PYTHONPATH="$PWD"
EOF

# Node service.envrc
cat > services/web-node/.envrc << 'EOF'
source_up

use node 18.17.0
PATH_add node_modules/.bin

export API_URL="http://localhost:8000"
export PORT=3000
EOF

# Rust service.envrc
cat > services/worker-rust/.envrc << 'EOF'
source_up

export RUST_LOG="debug"
export CARGO_TARGET_DIR="$PROJECT_ROOT/target"
EOF
```

### Multi-Stage Development Script

```bash
# ✅ scripts/dev.sh
cat > scripts/dev.sh << 'EOF'
#!/bin/bash

case "$1" in
 api)
 cd "$PROJECT_ROOT/services/api-python"
 python -m uvicorn main:app --reload
;;
 web)
 cd "$PROJECT_ROOT/services/web-node"
 npm run dev
;;
 worker)
 cd "$PROJECT_ROOT/services/worker-rust"
 cargo watch -x run
;;
 all)
 # Start all services with tmux
 tmux new-session -d -s dev "cd $PROJECT_ROOT/services/api-python && python -m uvicorn main:app --reload"
 tmux split-window -h "cd $PROJECT_ROOT/services/web-node && npm run dev"
 tmux split-window -v "cd $PROJECT_ROOT/services/worker-rust && cargo watch -x run"
 tmux attach-session -t dev
;;
 *)
 echo "Usage: dev.sh {api|web|worker|all}"
 exit 1
;;
esac
EOF

chmod +x scripts/dev.sh
```

---

## CI/CD Integration

### GitHub Actions with Multiple Versions

```yaml
# ✅.github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
 test-python:
 runs-on: ubuntu-latest
 strategy:
 matrix:
 python-version: ['3.9', '3.10', '3.11']

 steps:
 - uses: actions/checkout@v3

 - uses: actions/setup-python@v4
 with:
 python-version: ${{ matrix.python-version }}

 - name: Install dependencies
 run: |
 python -m pip install --upgrade pip
 pip install -r requirements.txt

 - name: Run tests
 run: pytest

 test-node:
 runs-on: ubuntu-latest
 strategy:
 matrix:
 node-version: ['16', '18', '20']

 steps:
 - uses: actions/checkout@v3

 - uses: actions/setup-node@v3
 with:
 node-version: ${{ matrix.node-version }}

 - name: Install dependencies
 run: npm ci

 - name: Run tests
 run: npm test

 test-rust:
 runs-on: ubuntu-latest
 strategy:
 matrix:
 rust-version: ['stable', 'beta', 'nightly']

 steps:
 - uses: actions/checkout@v3

 - uses: actions-rs/toolchain@v1
 with:
 toolchain: ${{ matrix.rust-version }}
 override: true

 - name: Build
 run: cargo build --verbose

 - name: Run tests
 run: cargo test --verbose
```

### GitLab CI with Version Management

```yaml
# ✅.gitlab-ci.yml
stages:
 - test
 - build

variables:
 PYTHON_VERSION: "3.11"
 NODE_VERSION: "18"

test:python:
 stage: test
 image: python:${PYTHON_VERSION}
 before_script:
 - pip install -r requirements.txt
 script:
 - pytest
 parallel:
 matrix:
 - PYTHON_VERSION: ["3.9", "3.10", "3.11"]

test:node:
 stage: test
 image: node:${NODE_VERSION}
 before_script:
 - npm ci
 script:
 - npm test
 parallel:
 matrix:
 - NODE_VERSION: ["16", "18", "20"]

test:rust:
 stage: test
 image: rust:latest
 script:
 - cargo test
 parallel:
 matrix:
 - RUST_VERSION: ["stable", "beta"]
 before_script:
 - rustup toolchain install ${RUST_VERSION}
 - rustup default ${RUST_VERSION}
```

This comprehensive guide provides advanced patterns for managing complex multi-version, multi-language development environments across various scenarios and toolchains.
