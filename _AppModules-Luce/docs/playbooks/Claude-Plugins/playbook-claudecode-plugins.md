# Claude Code Plugins - Complete Playbook

> **Version:** 1.0
> **Last Updated:** 2025-11-16
> **Claude Code Version:** 2.0.42+
> **Audience:** Developers using Claude Code CLI or VS Code extension

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Marketplace Management](#marketplace-management)
4. [Plugin Discovery](#plugin-discovery)
5. [Plugin Installation](#plugin-installation)
6. [Using Installed Plugins](#using-installed-plugins)
7. [Plugin Management](#plugin-management)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [Reference](#reference)

---

## Overview

### What Are Claude Code Plugins?

**Plugins** are lightweight packages that extend Claude Code with custom capabilities:
- **Slash Commands** - New `/command` actions (e.g., `/docker-build`, `/test-all`)
- **Subagents** - Specialized AI agents for specific tasks (e.g., security audit, performance optimization)
- **MCP Servers** - Integrations with external tools (e.g., Figma, Jira, databases)
- **Hooks** - Automation triggers (e.g., pre-commit checks, file watchers)

### What Are Marketplaces?

**Marketplaces** are catalogs (JSON files) that list available plugins and where to find them. They provide:
- Centralized plugin discovery
- Version management
- Team distribution
- Support for GitHub repos, git repos, local paths

### Plugin Architecture

```
.claude/
├── plugins/
│   ├── plugin-name-1/
│   │   ├── manifest.json          # Plugin metadata
│   │   ├── commands/              # Slash commands
│   │   ├── agents/                # AI subagents
│   │   ├── hooks/                 # Automation hooks
│   │   └── mcp-servers/           # MCP server configs
│   └── plugin-name-2/
└── marketplaces/
    └── marketplace-configs.json
```

---

## Quick Start

### Install Your First Marketplace

```bash
# Navigate to your project
cd ~/apps/bloom

# Open plugin manager
claude /plugins

# At the prompt, enter a marketplace:
jeremylongshore/claude-code-plugins-plus

# Press Enter to add
```

### Browse & Install a Plugin

```bash
# Open plugin browser (shows all marketplaces and plugins)
claude /plugins

# Browse available plugins by category
# Click/select a plugin to see details
# Click "Install" to add it to your project

# Or install directly via command:
claude /plugin install <plugin-name>
```

### Use Your First Plugin

```bash
# Type "/" and press Tab to see all commands
/[TAB]

# Or ask Claude what's available:
"What plugins are installed?"
"Show me commands from the testing plugin"

# Use a command:
/test-all
/docker-build
/docs-generate
```

---

## Marketplace Management

### Available Marketplaces (2025)

#### **Recommended Starting Point**

| Marketplace | Source | Plugins | Focus |
|-------------|--------|---------|-------|
| **Claude Code Plugins Hub** | `jeremylongshore/claude-code-plugins-plus` | 243 | Most comprehensive, 100% schema compliant |

#### **Community Marketplaces**

| Marketplace | Source | Focus |
|-------------|--------|-------|
| **CC Plugins** | `ccplugins/marketplace` | Curated awesome plugins |
| **Anand's Marketplace** | `ananddtyagi/claude-code-marketplace` | General collection |
| **Every Marketplace** | `EveryInc/every-marketplace` | Every-Env plugins |

#### **Discovery Platforms** (Web-Based)

| Platform | URL | Purpose |
|----------|-----|---------|
| **MCP Market** | https://mcpmarket.com/ | Browse MCP servers |
| **Claude Code Marketplace** | https://claudecodemarketplace.net/ | Community voting/sharing |

**Note:** Web platforms are for **discovery only**. Install plugins using GitHub sources.

### Adding a Marketplace

#### **Method 1: Interactive (Recommended)**

```bash
claude /plugins

# At the "Add Marketplace" prompt, paste one of:
# GitHub repo (short form):
jeremylongshore/claude-code-plugins-plus

# GitHub repo (full URL):
https://github.com/jeremylongshore/claude-code-plugins-plus

# GitHub SSH:
git@github.com:jeremylongshore/claude-code-plugins-plus.git

# Direct marketplace.json URL:
https://example.com/marketplace.json

# Local path:
./path/to/marketplace
../shared-plugins-marketplace
```

#### **Method 2: Command Line**

```bash
# Add marketplace directly
claude /plugin add-marketplace jeremylongshore/claude-code-plugins-plus
```

### Listing Marketplaces

```bash
# View all added marketplaces
claude /plugins

# This shows:
# - Marketplace name and source
# - Number of available plugins
# - Installation status
```

### Removing a Marketplace

```bash
# Open plugin manager
claude /plugins

# Navigate to marketplace settings
# Select "Remove Marketplace"
# Confirm removal

# Note: Removing marketplace doesn't uninstall plugins
```

### Updating Marketplace Index

```bash
# Refresh marketplace plugin listings
claude /plugin update-marketplaces

# Or refresh in the UI:
claude /plugins
# Select "Refresh Marketplaces"
```

---

## Plugin Discovery

### Browsing Plugins in the UI

```bash
claude /plugins

# UI shows:
# ├─ Marketplaces
# │  ├─ Claude Code Plugins Hub (243 plugins)
# │  └─ CC Plugins (52 plugins)
# ├─ Categories
# │  ├─ Development Tools
# │  ├─ Testing & QA
# │  ├─ DevOps & Deployment
# │  ├─ Documentation
# │  └─ AI Agents
# └─ Installed Plugins (5)
```

### Searching for Plugins

```bash
# Search by keyword
claude /plugin search docker

# Search by category
claude /plugin search --category testing

# Search by capability
claude /plugin search --has-mcp
claude /plugin search --has-agents
```

### Viewing Plugin Details

```bash
# In the UI:
claude /plugins
# Click on a plugin to see:
# - Description
# - Author
# - Version
# - Capabilities (commands, agents, MCP servers, hooks)
# - Dependencies
# - Installation size
# - License
```

### Discovering Plugin Capabilities

```bash
# Ask Claude what a plugin does:
"What does the devops-toolkit plugin do?"
"Show me all commands in the testing-pro plugin"
"What MCP servers does the database-manager plugin include?"

# View plugin manifest directly:
cat .claude/plugins/plugin-name/manifest.json
```

### Recommended Plugins by Use Case

#### **For Next.js Projects (like Bloom)**

```bash
# Development
claude /plugin install nextjs-toolkit
claude /plugin install react-dev-tools
claude /plugin install typescript-helper

# Testing
claude /plugin install playwright-suite
claude /plugin install jest-toolkit

# Database
claude /plugin install prisma-helper
claude /plugin install db-migration-manager
```

#### **For DevOps**

```bash
claude /plugin install docker-manager
claude /plugin install kubernetes-toolkit
claude /plugin install deployment-automation
```

#### **For Code Quality**

```bash
claude /plugin install eslint-fixer
claude /plugin install security-audit
claude /plugin install performance-profiler
```

#### **For Documentation**

```bash
claude /plugin install auto-docs
claude /plugin install api-doc-generator
claude /plugin install changelog-manager
```

---

## Plugin Installation

### Installing Plugins

#### **Method 1: Via Plugin Manager (Recommended)**

```bash
claude /plugins

# Browse to the plugin you want
# Click "Install"
# Confirm installation
```

#### **Method 2: Direct Install**

```bash
# Install by plugin name (from marketplace)
claude /plugin install docker-manager

# Install from GitHub repo
claude /plugin install owner/repo

# Install from local path
claude /plugin install ./my-custom-plugin
```

#### **Method 3: Install Multiple Plugins**

```bash
# Install several plugins at once
claude /plugin install docker-manager testing-pro api-docs
```

### Installation Process

When you install a plugin, Claude Code:

1. **Downloads** the plugin from the source
2. **Validates** the manifest and schema
3. **Checks dependencies** (other plugins, MCP servers)
4. **Installs files** to `.claude/plugins/[plugin-name]/`
5. **Registers** commands, agents, hooks, and MCP servers
6. **Confirms** installation success

### Post-Installation

After installing a plugin:

```bash
# Verify installation
claude /plugin list

# Check what was added
ls -la .claude/plugins/[plugin-name]/

# View plugin README
cat .claude/plugins/[plugin-name]/README.md

# Test a command (if plugin adds commands)
/[command-name] --help
```

### Installing Plugin Dependencies

Some plugins require:
- **Other plugins** (auto-installed)
- **MCP servers** (may need manual configuration)
- **External tools** (must install separately)

```bash
# Example: Database plugin might require:
# 1. MCP server for database access
# 2. Database CLI tools (psql, mysql, etc.)

# Install MCP server dependency:
claude /mcp install database-connector

# Install external tools:
sudo apt install postgresql-client  # Ubuntu/Debian
brew install postgresql             # macOS
```

---

## Using Installed Plugins

### Slash Commands

Plugins often add new `/` commands:

```bash
# Discover available commands
/[TAB]  # Press Tab to see all commands

# Or ask Claude:
"What slash commands are available?"
"Show me commands from the docker-manager plugin"

# Use a command:
/docker-build
/test-coverage
/docs-generate

# Get help for a command:
/docker-build --help
```

#### **Common Command Patterns**

```bash
# Testing plugins
/test-all
/test-unit
/test-e2e
/test-coverage
/test-watch
/test-fix-failing

# Docker plugins
/docker-build
/docker-compose-up
/docker-logs
/docker-ps
/docker-clean

# Git workflow plugins
/git-feature-branch
/git-commit-conventional
/git-pr-create
/git-release

# Documentation plugins
/docs-generate
/docs-update-api
/docs-changelog-add
/docs-validate
```

### Subagents

Plugins can add specialized AI agents:

```bash
# Invoke agent via slash command
/agent-security-audit
/agent-performance
/agent-db-migrate

# Or reference in conversation:
"Run a security audit on the authentication code"
# Claude automatically uses /agent-security-audit

"Optimize this component for performance"
# Claude uses /agent-performance
```

#### **Common Agent Types**

```bash
# Code quality agents
/agent-security-audit
/agent-code-review
/agent-refactor

# Performance agents
/agent-performance-profile
/agent-memory-leak-detect

# Database agents
/agent-db-schema-design
/agent-db-migration
/agent-db-query-optimize

# Documentation agents
/agent-api-docs
/agent-readme-writer
```

### MCP Servers

Plugins can connect Claude Code to external tools:

```bash
# After installing Figma MCP plugin:
"Fetch designs from Figma project bloom-redesign"
"Export Figma component 'UserCard' to React"

# After installing database MCP plugin:
"Query production database for user count"
"Show schema for sessions table"
"Create migration to add email_verified column"

# After installing Jira MCP plugin:
"Create Jira ticket for session resume bug"
"Show open tickets assigned to me"
"Update ticket BLOOM-42 status to In Progress"

# After installing GitHub MCP plugin:
"Create GitHub issue for dark mode support"
"Show recent PRs on main branch"
"Merge PR #127"
```

#### **Verifying MCP Server Integration**

```bash
# List active MCP servers
claude /mcp list

# Test MCP server connection
claude /mcp test [server-name]

# View MCP server logs
claude /mcp logs [server-name]
```

### Hooks

Plugins can add automation hooks:

#### **Pre-Commit Hooks**

Automatically runs before commits:

```bash
# Installed by code-quality plugin:
git commit -m "feat: add feature"

# Hook automatically runs:
# ✓ ESLint check
# ✓ TypeScript type check
# ✓ Prettier format check
# ✓ Unit tests
# ✓ Build validation

# Commit proceeds if all checks pass
```

#### **File Watch Hooks**

Automatically triggers on file changes:

```bash
# Installed by dev-workflow plugin:
# When you save a .ts file:
# → Auto-formats with Prettier
# → Runs type check
# → Updates documentation
# → Restarts dev server if needed
```

#### **Error Detection Hooks**

Automatically runs when errors occur:

```bash
# Installed by error-helper plugin:
# When build fails:
# → Analyzes error message
# → Searches for similar issues
# → Suggests fixes
# → Creates GitHub issue (optional)
```

#### **Managing Hooks**

```bash
# List installed hooks
claude /plugin hooks

# Disable a hook temporarily
claude /plugin hook disable pre-commit-lint

# Enable a hook
claude /plugin hook enable pre-commit-lint

# Remove a hook
claude /plugin hook remove file-watch-prettier
```

---

## Plugin Management

### Listing Installed Plugins

```bash
# Show all installed plugins
claude /plugin list

# Show plugins with details
claude /plugin list --verbose

# Show plugins from specific marketplace
claude /plugin list --marketplace "Claude Code Plugins Hub"
```

### Updating Plugins

```bash
# Update all plugins
claude /plugin update

# Update specific plugin
claude /plugin update docker-manager

# Check for updates without installing
claude /plugin check-updates
```

### Uninstalling Plugins

```bash
# Uninstall via UI
claude /plugins
# Navigate to installed plugins
# Click "Uninstall" on the plugin

# Uninstall via command
claude /plugin uninstall docker-manager

# Uninstall multiple plugins
claude /plugin uninstall docker-manager testing-pro
```

#### **What Happens During Uninstall**

1. **Removes** plugin files from `.claude/plugins/[plugin-name]/`
2. **Unregisters** commands, agents, hooks, MCP servers
3. **Cleans up** configuration files
4. **Does NOT remove** dependencies (other plugins, MCP servers)

#### **Manual Cleanup (If Needed)**

```bash
# Remove plugin directory manually
rm -rf .claude/plugins/[plugin-name]/

# Restart Claude Code to refresh
claude --restart
```

### Disabling Plugins (Without Uninstalling)

```bash
# Disable a plugin temporarily
claude /plugin disable docker-manager

# Re-enable a plugin
claude /plugin enable docker-manager

# List disabled plugins
claude /plugin list --disabled
```

### Plugin Configuration

Some plugins have configurable settings:

```bash
# View plugin configuration
cat .claude/plugins/[plugin-name]/config.json

# Edit configuration
claude /plugin configure [plugin-name]

# Or edit manually:
vim .claude/plugins/[plugin-name]/config.json
```

#### **Example: Configuring Testing Plugin**

```json
{
  "plugin": "testing-pro",
  "config": {
    "test_framework": "jest",
    "coverage_threshold": 80,
    "watch_mode": true,
    "parallel_tests": 4,
    "ignore_patterns": ["**/node_modules/**", "**/.next/**"]
  }
}
```

### Sharing Plugins Across Projects

#### **Method 1: Global Installation**

```bash
# Install plugin globally (available in all projects)
claude /plugin install --global docker-manager

# List global plugins
claude /plugin list --global
```

#### **Method 2: Shared Plugin Directory**

```bash
# Create shared plugin directory
mkdir -p ~/shared-plugins

# Install plugins there
cd ~/shared-plugins
claude /plugin install docker-manager testing-pro

# Link to projects
cd ~/apps/bloom
ln -s ~/shared-plugins/.claude/plugins .claude/plugins-shared

# Configure Claude Code to use shared plugins
# (See plugin documentation for configuration)
```

#### **Method 3: Team Marketplace**

```bash
# Create team marketplace repo
# team-marketplace/
# ├── marketplace.json
# └── plugins/
#     ├── plugin-1/
#     └── plugin-2/

# Team members add marketplace:
claude /plugin add-marketplace git@github.com:company/team-marketplace.git
```

---

## Troubleshooting

### Plugin Installation Issues

#### **Issue: "Plugin not found in marketplace"**

```bash
# Solution 1: Update marketplace index
claude /plugin update-marketplaces

# Solution 2: Check spelling
claude /plugin search [partial-name]

# Solution 3: Install directly from GitHub
claude /plugin install owner/repo
```

#### **Issue: "Dependency conflict"**

```bash
# View dependency tree
claude /plugin deps [plugin-name]

# Solution 1: Update conflicting plugin
claude /plugin update [conflicting-plugin]

# Solution 2: Uninstall conflicting plugin
claude /plugin uninstall [conflicting-plugin]

# Solution 3: Install specific version
claude /plugin install [plugin-name]@version
```

#### **Issue: "Installation failed - permission denied"**

```bash
# Check .claude directory permissions
ls -la .claude/

# Fix permissions
chmod -R 755 .claude/
chown -R $USER:$USER .claude/

# Retry installation
claude /plugin install [plugin-name]
```

### Plugin Usage Issues

#### **Issue: "Slash command not found"**

```bash
# Verify plugin is installed
claude /plugin list

# Check if plugin adds the command
cat .claude/plugins/[plugin-name]/manifest.json | jq '.commands'

# Restart Claude Code
claude --restart

# Re-install plugin
claude /plugin uninstall [plugin-name]
claude /plugin install [plugin-name]
```

#### **Issue: "Agent not responding"**

```bash
# Check agent logs
claude /agent logs [agent-name]

# Verify agent is registered
claude /agent list

# Test agent directly
/agent-[name] "test prompt"

# Check for errors in manifest
cat .claude/plugins/[plugin-name]/manifest.json
```

#### **Issue: "MCP server connection failed"**

```bash
# List MCP servers
claude /mcp list

# Test connection
claude /mcp test [server-name]

# View server logs
claude /mcp logs [server-name]

# Restart MCP server
claude /mcp restart [server-name]

# Check configuration
cat .claude/plugins/[plugin-name]/mcp-servers/[server-name]/config.json
```

### Performance Issues

#### **Issue: "Claude Code is slow after installing plugins"**

```bash
# Check number of installed plugins
claude /plugin list | wc -l

# Disable unused plugins
claude /plugin disable [unused-plugin]

# Uninstall unused plugins
claude /plugin uninstall [unused-plugin]

# Clear plugin cache
rm -rf .claude/cache/plugins/
claude --restart
```

#### **Issue: "High memory usage"**

```bash
# List plugins sorted by memory usage
claude /plugin stats --sort-by memory

# Disable heavy plugins
claude /plugin disable [heavy-plugin]

# Use lazy loading for agents
# (Edit plugin manifest to enable lazy loading)
```

### Debug Mode

```bash
# Enable debug mode for plugins
export CLAUDE_PLUGIN_DEBUG=1
claude /plugins

# View detailed logs
tail -f ~/.claude/logs/plugins.log

# Disable debug mode
unset CLAUDE_PLUGIN_DEBUG
```

---

## Best Practices

### Installation Best Practices

1. **Start with one marketplace** (Claude Code Plugins Hub recommended)
2. **Install plugins as needed** (don't install everything)
3. **Read plugin documentation** before installing
4. **Check plugin maintenance status** (last updated, stars, issues)
5. **Test plugins in dev environment** before production use
6. **Version pin critical plugins** for stability
7. **Create backups** before major plugin changes

### Usage Best Practices

1. **Learn plugin commands** incrementally
2. **Use `/[TAB]` frequently** to discover commands
3. **Ask Claude for help** with plugin capabilities
4. **Check plugin READMEs** for examples
5. **Configure plugins** to match your workflow
6. **Disable unused hooks** to improve performance
7. **Monitor plugin updates** for new features

### Security Best Practices

1. **Only install plugins from trusted sources**
2. **Review plugin code** before installation (for critical projects)
3. **Check plugin permissions** in manifest
4. **Avoid plugins requesting unnecessary access**
5. **Keep plugins updated** for security patches
6. **Use global installation cautiously** (can affect all projects)
7. **Audit plugin changes** before updating

### Team Best Practices

1. **Create team marketplace** for standardization
2. **Document required plugins** in project README
3. **Version control plugin configuration** (`.claude/config.json`)
4. **Don't commit plugin files** (add to `.gitignore`)
5. **Share plugin recommendations** via documentation
6. **Test plugins before team rollout**
7. **Create custom plugins** for team-specific workflows

### Performance Best Practices

1. **Install only needed plugins** (avoid bloat)
2. **Disable unused plugins** instead of uninstalling (if might need later)
3. **Use lazy loading** for heavy agents
4. **Configure hooks selectively** (not every hook on every file)
5. **Monitor Claude Code startup time** after adding plugins
6. **Clear plugin cache periodically**
7. **Use lightweight alternatives** when available

---

## Reference

### Plugin Manifest Structure

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Plugin description",
  "author": "Author Name",
  "license": "MIT",
  "homepage": "https://github.com/author/my-plugin",
  "capabilities": {
    "commands": true,
    "agents": true,
    "mcp_servers": true,
    "hooks": true
  },
  "commands": [
    {
      "name": "my-command",
      "description": "Command description",
      "file": "commands/my-command.md"
    }
  ],
  "agents": [
    {
      "name": "my-agent",
      "description": "Agent description",
      "file": "agents/my-agent.md"
    }
  ],
  "mcp_servers": [
    {
      "name": "my-mcp-server",
      "type": "stdio",
      "command": "node",
      "args": ["mcp-servers/my-server/index.js"]
    }
  ],
  "hooks": [
    {
      "name": "pre-commit",
      "file": "hooks/pre-commit.js",
      "enabled": true
    }
  ],
  "dependencies": {
    "other-plugin": "^1.0.0"
  }
}
```

### Marketplace JSON Structure

```json
{
  "name": "My Marketplace",
  "version": "1.0.0",
  "description": "Marketplace description",
  "plugins": [
    {
      "name": "plugin-name",
      "description": "Plugin description",
      "version": "1.0.0",
      "author": "Author Name",
      "source": "https://github.com/author/plugin-name",
      "categories": ["development", "testing"],
      "tags": ["jest", "testing", "automation"]
    }
  ]
}
```

### Common Plugin Commands

```bash
# Marketplace Management
claude /plugin add-marketplace <source>
claude /plugin list-marketplaces
claude /plugin remove-marketplace <name>
claude /plugin update-marketplaces

# Plugin Discovery
claude /plugins                           # Open UI
claude /plugin search <keyword>
claude /plugin search --category <cat>
claude /plugin list

# Plugin Installation
claude /plugin install <name>
claude /plugin install <owner/repo>
claude /plugin install --global <name>
claude /plugin uninstall <name>

# Plugin Management
claude /plugin update
claude /plugin update <name>
claude /plugin enable <name>
claude /plugin disable <name>
claude /plugin configure <name>

# Plugin Information
claude /plugin info <name>
claude /plugin deps <name>
claude /plugin stats
claude /plugin hooks

# Debugging
claude /plugin validate <name>
claude /plugin logs <name>
claude --plugin-debug
```

### Environment Variables

```bash
# Enable plugin debug mode
export CLAUDE_PLUGIN_DEBUG=1

# Custom plugin directory
export CLAUDE_PLUGIN_DIR=/path/to/plugins

# Disable plugin auto-updates
export CLAUDE_PLUGIN_AUTO_UPDATE=0

# Plugin cache directory
export CLAUDE_PLUGIN_CACHE_DIR=/path/to/cache
```

### File Locations

```bash
# Plugin installation directory
.claude/plugins/

# Marketplace configuration
.claude/marketplaces/config.json

# Plugin cache
.claude/cache/plugins/

# Plugin logs
~/.claude/logs/plugins.log

# Global plugins (if using)
~/.claude/plugins/
```

### .gitignore Recommendations

```gitignore
# Claude Code plugin files (don't commit)
.claude/plugins/
.claude/cache/
.claude/marketplaces/

# Keep configuration (DO commit)
!.claude/config.json
!.claude/commands/
!.claude/agents/

# Keep custom plugins (optional - team decision)
!.claude/plugins/custom-team-plugin/
```

### Useful Resources

- **Official Documentation**: https://docs.anthropic.com/en/docs/claude-code/plugin-marketplaces
- **Plugin Development Guide**: https://docs.anthropic.com/en/docs/claude-code/building-plugins
- **MCP Documentation**: https://modelcontextprotocol.io/
- **Community Forum**: https://discord.gg/anthropic (check for #claude-code channel)

---

## Appendix: Example Workflows

### Workflow 1: Setting Up a New Project

```bash
# 1. Add marketplace
cd ~/apps/new-project
claude /plugin add-marketplace jeremylongshore/claude-code-plugins-plus

# 2. Install essential plugins
claude /plugin install git-flow
claude /plugin install testing-suite
claude /plugin install code-quality

# 3. Configure plugins
claude /plugin configure testing-suite
# Set test framework, coverage thresholds, etc.

# 4. Test installation
/git-feature-branch new-feature
/test-all
/code-quality-check

# 5. Document for team
echo "Required Plugins:" >> README.md
echo "- git-flow" >> README.md
echo "- testing-suite" >> README.md
echo "- code-quality" >> README.md
```

### Workflow 2: Adding DevOps Automation

```bash
# 1. Search for DevOps plugins
claude /plugin search devops

# 2. Install relevant plugins
claude /plugin install docker-manager
claude /plugin install deployment-automation
claude /plugin install monitoring-toolkit

# 3. Configure deployment
claude /plugin configure deployment-automation
# Set staging/production URLs, credentials, etc.

# 4. Use in workflow
/docker-build production
/deploy-staging
/health-check all-services
```

### Workflow 3: Improving Code Quality

```bash
# 1. Install quality plugins
claude /plugin install security-audit
claude /plugin install performance-profiler
claude /plugin install code-review-ai

# 2. Run initial audit
/security-audit full
/performance-profile app

# 3. Enable pre-commit hooks
claude /plugin hook enable pre-commit-security
claude /plugin hook enable pre-commit-performance

# 4. Integrate with CI/CD
# Add to .github/workflows/quality.yml
# claude /security-audit full
# claude /performance-profile app
```

### Workflow 4: Creating Team Marketplace

```bash
# 1. Create marketplace repo
mkdir team-marketplace
cd team-marketplace
git init

# 2. Create marketplace.json
cat > marketplace.json <<'EOF'
{
  "name": "Team Bloom Marketplace",
  "version": "1.0.0",
  "description": "Curated plugins for Bloom team",
  "plugins": [
    {
      "name": "nextjs-toolkit",
      "source": "https://github.com/example/nextjs-toolkit",
      "version": "1.0.0"
    }
  ]
}
EOF

# 3. Push to GitHub
git add .
git commit -m "Initial marketplace"
git push origin main

# 4. Team members add marketplace
claude /plugin add-marketplace git@github.com:team/team-marketplace.git
```

---

**End of Playbook**

For questions or contributions, see project documentation or contact the Bloom team.
