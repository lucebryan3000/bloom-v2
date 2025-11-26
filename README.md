# bloom-v2

A Next.js + TypeScript + PostgreSQL + AI stack project, powered by OmniForge.

## OmniForge - The Factory That Builds Universes

OmniForge is the project initialization and build system for bloom-v2. It orchestrates a 6-phase setup process to bootstrap the complete tech stack.

### Quick Start

```bash
# Preview what will be executed
./_build/omniforge/omni.sh --help

# Initialize the project (interactive bootstrap)
./_build/omniforge/omni.sh --init

# Check progress
./_build/omniforge/omni.sh --status

# Build and verify
./_build/omniforge/omni.sh build
```

### CLI Commands

| Command | Description |
|---------|-------------|
| `./_build/omniforge/omni.sh --init` | Initialize project with all phases |
| `./_build/omniforge/omni.sh --help` | Show help and available commands |
| `./_build/omniforge/omni.sh --run` | Run all initialization phases |
| `./_build/omniforge/omni.sh --status` | Show completion status |
| `./_build/omniforge/omni.sh build` | Build and verify the project |

### Documentation

See [`_build/omniforge/OMNIFORGE.md`](_build/omniforge/OMNIFORGE.md) for the complete, up-to-date documentation set. Handy entry points:

- Quick reference: `_build/omniforge/docs/OMNIFORGE-QUICK-REFERENCE.md`
- Workflow runbook: `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
- CLI reference: `_build/omniforge/docs/OMNIFORGE-CLI.md`
- OmniForge Optional Services & Flags: `_build/omniforge/docs/OMNIFORGE-FLAGS.md`
