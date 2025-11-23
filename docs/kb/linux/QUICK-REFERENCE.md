---
id: linux-quick-reference
topic: linux
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [bash, shell, devops]
embedding_keywords: [linux-quickref, bash-snippets, shell-commands]
last_reviewed: 2025-11-13
---

# Linux - Quick Reference

**Purpose**: Fast command reference for Linux topics

**Current Organization**: See subtopic quick references

---

## 📁 Quick References by Topic

### Binary/PATH Management

See [bin/QUICK-REFERENCE.md](./bin/QUICK-REFERENCE.md) for:
- PATH configuration snippets
- Binary installation commands
- Permission setting examples
- Shebang templates
- Troubleshooting commands

---

## 🚀 Most Common Commands

### PATH Management
```bash
# Add to PATH temporarily
export PATH="$HOME/.local/bin:$PATH"

# Add to PATH permanently
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### File Permissions
```bash
# Make executable
chmod +x script.sh

# Check permissions
ls -l script.sh

# Change ownership
chown user:group file
```

### Finding Files
```bash
# Find by name
find / -name "filename" 2>/dev/null

# Find executables
which command
type command
whereis command
```

---

## 📖 Complete References

- **bin/** → [bin/QUICK-REFERENCE.md](./bin/QUICK-REFERENCE.md) - Complete binary/PATH reference

Future topics will have their own QUICK-REFERENCE files.

---

**Last Updated**: 2025-11-13
**KB Version**: 3.1
**Status**: bin/ reference complete
