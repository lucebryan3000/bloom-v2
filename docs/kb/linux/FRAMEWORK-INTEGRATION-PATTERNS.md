---
id: linux-framework-integration-patterns
topic: linux
file_role: patterns
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: [bash, shell, docker, devops]
embedding_keywords: [linux-patterns, bash-integration, shell-scripts, system-integration]
last_reviewed: 2025-11-13
---

# Linux - Framework Integration Patterns

**Purpose**: Integration patterns for Linux system topics

**Current Organization**: See subtopic pattern files

---

## 📁 Pattern Files by Topic

### Binary/PATH Management

See [bin/FRAMEWORK-INTEGRATION-PATTERNS.md](./bin/FRAMEWORK-INTEGRATION-PATTERNS.md) for:
- Adding custom binaries to PATH in different shells
- Creating wrapper scripts for applications
- Integrating with package managers
- Setting up personal ~/bin directories
- Symlinking executables
- Cross-platform shebang patterns
- Docker container binary management
- CI/CD binary installation patterns

---

## 🚀 Quick Integration Examples

### Adding Binary to PATH (Multiple Shells)

```bash
# Bash (~/.bashrc)
export PATH="$HOME/.local/bin:$PATH"

# Zsh (~/.zshrc)
export PATH="$HOME/.local/bin:$PATH"

# Fish (~/.config/fish/config.fish)
set -gx PATH $HOME/.local/bin $PATH
```

### Docker Integration

```dockerfile
# Dockerfile
FROM ubuntu:22.04

# Add custom binary directory
ENV PATH="/opt/app/bin:${PATH}"

# Copy binaries
COPY --chmod=755 bin/* /opt/app/bin/

# Verify
RUN which my-command
```

### CI/CD Integration (GitHub Actions)

```yaml
# .github/workflows/ci.yml
steps:
  - name: Install custom binary
    run: |
      mkdir -p $HOME/.local/bin
      curl -L -o $HOME/.local/bin/tool https://example.com/tool
      chmod +x $HOME/.local/bin/tool
      echo "$HOME/.local/bin" >> $GITHUB_PATH
```

---

## 📖 Complete Pattern Files

Future Linux topics will have their own FRAMEWORK-INTEGRATION-PATTERNS files:

- **bin/** → [bin/FRAMEWORK-INTEGRATION-PATTERNS.md](./bin/FRAMEWORK-INTEGRATION-PATTERNS.md) - Complete binary/PATH patterns
- **systemd/** → (planned) Service management patterns
- **networking/** → (planned) Network configuration patterns
- **security/** → (planned) Security and permissions patterns

---

**Last Updated**: 2025-11-13
**KB Version**: 3.1
**Status**: bin/ patterns complete, other topics planned
