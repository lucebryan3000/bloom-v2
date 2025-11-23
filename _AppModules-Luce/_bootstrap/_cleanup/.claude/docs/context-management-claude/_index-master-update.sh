#!/bin/bash

##############################################################################
# _index-master-update.sh
#
# Purpose: Automatically scan and update ALL index-* files throughout the
#          entire project, ensuring comprehensive documentation discovery
#          without context bloat. Adds tier headers to index files, tracks
#          changes, and generates comprehensive reports.
#
# Usage:
#   ./_index-master-update.sh                    # Update all indexes & report
#   ./_index-master-update.sh --help             # Show this help
#   ./_index-master-update.sh --verbose          # Detailed scanning output
#   ./_index-master-update.sh --dry-run          # Preview changes without updating
#
# Tiers Identified:
#   - Tier 1: Always preloaded (CLAUDE.md, _index-master.md)
#   - Tier 2: Core development indexes (agents, commands, prompts, gitignore)
#   - Tier 3: Specialized reference indexes (kb, build, sessions, features, ops)
#   - Tier 4: Project-wide indexes (docs/, _build/, kb/, etc.)
#
# Features:
#   - Comprehensive project-wide index file scanning
#   - Tier-aware categorization with comment headers
#   - Automatic tier header insertion in each index file
#   - Line count tracking for all modified files
#   - Error handling & validation
#   - Color-coded output with detailed reporting
#   - Dry-run and verbose modes
#   - Summary report with all changes
#
##############################################################################

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
CONTEXT_DIR="$SCRIPT_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Options
DRY_RUN=false
VERBOSE=false
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Report tracking
declare -a TIER1_FILES
declare -a TIER2_FILES
declare -a TIER3_FILES
declare -a TIER4_FILES
declare -a FOUND_INDEXES

# Change tracking: file path -> lines changed
declare -A FILE_CHANGES
declare -a UPDATE_ORDER

# Error tracking
declare -a ERRORS
ERRORS_FOUND=0

##############################################################################
# Helper Functions
##############################################################################

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${CYAN}→${NC} $*"
    fi
}

log_error_track() {
    local error_msg="$*"
    ERRORS+=("$error_msg")
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
    log_error "$error_msg"
}

track_change() {
    local file="$1"
    local lines="$2"
    FILE_CHANGES["$file"]=$lines
    UPDATE_ORDER+=("$file")
}

get_tier_header() {
    local tier="$1"
    case "$tier" in
        1)
            echo "---
Context Strategy: L1 (Always Preloaded)
Tier: 1 - Core Project Context
---"
            ;;
        2)
            echo "---
Context Strategy: L2 (Load on Demand)
Tier: 2 - Core Development Tools
---"
            ;;
        3)
            echo "---
Context Strategy: L2 (Load on Demand, Searchable)
Tier: 3 - Specialized Reference
---"
            ;;
        4)
            echo "---
Context Strategy: L2 (Load on Demand, Searchable)
Tier: 4 - Project-Wide Documentation
---"
            ;;
    esac
}

# Check if index file has tier header
has_tier_header() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 1  # File doesn't exist
    fi

    head -1 "$file" | grep -q "^---" && head -3 "$file" | grep -q "Context Strategy"
    return $?
}

# Get tier from file header or return default
get_file_tier() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Extract tier number from header
    grep "^Tier:" "$file" | head -1 | grep -oE "[0-9]" | head -1
}

# Determine tier for a file (with fallback logic)
determine_file_tier() {
    local file="$1"
    local relative_path="${file#$PROJECT_ROOT/}"

    # If file already has a tier header, use it
    if has_tier_header "$file"; then
        local existing_tier=$(get_file_tier "$file")
        if [[ -n "$existing_tier" ]]; then
            echo "$existing_tier"
            return 0
        fi
    fi

    # Auto-assign based on file location
    if [[ "$relative_path" == "CLAUDE.md" ]] || [[ "$relative_path" == ".claude/docs/context-management-claude/_index-master.md" ]]; then
        echo "1"
    elif [[ "$relative_path" == ".claude/docs/context-management-claude/index-agents.md" ]] || \
         [[ "$relative_path" == ".claude/docs/context-management-claude/index-slash-commands.md" ]] || \
         [[ "$relative_path" == ".claude/docs/context-management-claude/index-prompts.md" ]] || \
         [[ "$relative_path" == ".claude/docs/context-management-claude/index-gitignore-claude.ignore.md" ]]; then
        echo "2"
    elif [[ "$relative_path" == ".claude/docs/context-management-claude/"* ]] && [[ "$relative_path" == *"index"* ]]; then
        echo "3"
    else
        # Default to Tier 4 for unknown index files
        echo "4"
    fi
}

# Prompt user for tier if needed
prompt_for_tier() {
    local file="$1"
    local relative_path="${file#$PROJECT_ROOT/}"

    log_info "Index file missing tier header: $relative_path"
    echo ""
    echo "  Available tiers:"
    echo "    1 = Always Preloaded"
    echo "    2 = Core Development Tools"
    echo "    3 = Specialized Reference"
    echo "    4 = Project-Wide Documentation"
    echo ""

    # In interactive mode, ask user
    if [[ -t 0 ]]; then
        read -p "  Enter tier (1-4) or press Enter for default [4]: " user_tier
        user_tier="${user_tier:-4}"

        # Validate input
        if [[ $user_tier =~ ^[1-4]$ ]]; then
            echo "$user_tier"
        else
            log_warning "Invalid tier input, using default (4)"
            echo "4"
        fi
    else
        # Non-interactive mode: use default
        log_verbose "Non-interactive mode: using default tier 4"
        echo "4"
    fi
}

# Add tier header to file if missing
ensure_tier_header() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error_track "Cannot add header to non-existent file: $file"
        return 1
    fi

    # Check if header already exists
    if has_tier_header "$file"; then
        log_verbose "  Header already present: $(basename "$file")"
        return 0
    fi

    # Determine tier
    local tier=$(determine_file_tier "$file")

    # In interactive mode with missing header, prompt for confirmation
    if [[ -t 0 ]] && ! grep -q "^Tier:" "$file"; then
        log_warning "Auto-assigning Tier $tier to $(basename "$file") (no header found)"
        log_verbose "  File: $file"
    fi

    # Generate header
    local tier_header=$(get_tier_header "$tier")

    # Add header to file (preserve content)
    local temp_file="${file}.tmp.$$"
    {
        echo "$tier_header"
        echo ""
        cat "$file"
    } > "$temp_file"

    mv "$temp_file" "$file"
    log_success "Added Tier $tier header to $(basename "$file")"

    return 0
}

show_help() {
    sed -n '1,/^##############################################################################/p' "$0" | tail -n +2 | head -n -1
}

count_files() {
    local dir="$1"
    local pattern="${2:-*}"
    find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | wc -l
}

list_files() {
    local dir="$1"
    local pattern="${2:-*}"
    find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | sort
}

# Comprehensive index file discovery across entire project
find_all_index_files() {
    log_info "Scanning entire project for index files..."

    # Find all files named *index*.md anywhere in the project
    find "$PROJECT_ROOT" \
        -type f \
        -name "*index*.md" \
        -not -path "*/node_modules/*" \
        -not -path "*/.next/*" \
        -not -path "*/build/*" \
        -not -path "*/dist/*" \
        -not -path "*/.git/*" \
        2>/dev/null | sort
}

# Categorize found index files into tiers
categorize_index_files() {
    local index_file="$1"
    local relative_path="${index_file#$PROJECT_ROOT/}"

    # Tier 1: Always preloaded
    if [[ "$relative_path" == "CLAUDE.md" ]] || [[ "$relative_path" == ".claude/docs/context-management-claude/_index-master.md" ]]; then
        TIER1_FILES+=("$relative_path")
        log_verbose "  Tier 1: $relative_path"

    # Tier 2: Core development indexes
    elif [[ "$relative_path" == ".claude/docs/context-management-claude/index-agents.md" ]] || \
         [[ "$relative_path" == ".claude/docs/context-management-claude/index-slash-commands.md" ]] || \
         [[ "$relative_path" == ".claude/docs/context-management-claude/index-prompts.md" ]] || \
         [[ "$relative_path" == ".claude/docs/context-management-claude/index-gitignore-claude.ignore.md" ]]; then
        TIER2_FILES+=("$relative_path")
        log_verbose "  Tier 2: $relative_path"

    # Tier 3: Specialized reference indexes
    elif [[ "$relative_path" == ".claude/docs/context-management-claude/"* ]] && [[ "$relative_path" == *"index"* ]]; then
        TIER3_FILES+=("$relative_path")
        log_verbose "  Tier 3: $relative_path"

    # Tier 4: Project-wide documentation indexes
    else
        TIER4_FILES+=("$relative_path")
        log_verbose "  Tier 4: $relative_path"
    fi

    FOUND_INDEXES+=("$index_file")
}

##############################################################################
# Index Update Functions
##############################################################################

update_agents_index() {
    log_info "Scanning agents directory (Tier 2)..."

    local agents_dir="$CLAUDE_DIR/agents"
    local index_file="$CONTEXT_DIR/index-agents.md"
    local count=$(count_files "$agents_dir" "*.md")

    log_verbose "Found $count agent files in $agents_dir"

    if [[ $count -eq 0 ]]; then
        log_error_track "No agents found in $agents_dir"
        return 1
    fi

    local tier_header=$(get_tier_header 2)
    local header="$tier_header

# Agent Index - Quick Reference

This file provides a quick overview of all available agents in the \`.claude/agents/\` directory and their corresponding \`/agent-*\` commands.

## What Are Agents?

Agents are specialized AI assistants configured for specific domains and tasks. They are loaded on-demand via slash commands to reduce context bloat while keeping specialized capabilities accessible.

---

## Agent Directory

**Total Agents:** $count

### Auto-Scanned Files
"

    if [[ "$DRY_RUN" == false ]]; then
        echo "$header" > "$index_file"

        list_files "$agents_dir" "*.md" | while read -r file; do
            local filename=$(basename "$file")
            local name=$(basename "$filename" .md)
            echo -e "\n- **$name** (\`$filename\`)" >> "$index_file"
            echo "  - File: \`agents/$filename\`" >> "$index_file"
        done

        echo -e "\n---\n*Last updated: $TIMESTAMP*" >> "$index_file"

        local lines=$(wc -l < "$index_file")
        track_change "index-agents.md" "$lines"
        log_success "Updated: index-agents.md ($count agents, $lines lines)"
    else
        log_verbose "[DRY-RUN] Would update: $index_file ($count agents)"
    fi
}

update_prompts_index() {
    log_info "Scanning prompts directory (Tier 2)..."

    local prompts_dir="$CLAUDE_DIR/prompts"
    local index_file="$CONTEXT_DIR/index-prompts.md"
    local count=$(count_files "$prompts_dir" "*.md")

    log_verbose "Found $count prompt files in $prompts_dir"

    if [[ $count -eq 0 ]]; then
        log_error_track "No prompts found in $prompts_dir"
        return 1
    fi

    local tier_header=$(get_tier_header 2)
    local header="$tier_header

# Prompts Index - Reference & Documentation

This file catalogs all prompts available in the \`.claude/prompts/\` directory.

## What Are Prompts?

Prompts are pre-written conversation starters and instruction sets for specific tasks. They provide structured guidance for Claude Code operations.

---

## Prompts Directory

**Total Prompts:** $count

### Available Prompts
"

    if [[ "$DRY_RUN" == false ]]; then
        echo "$header" > "$index_file"

        list_files "$prompts_dir" "*.md" | while read -r file; do
            local filename=$(basename "$file")
            local name=$(basename "$filename" .md)
            echo -e "\n- **$name**" >> "$index_file"
            echo "  - File: \`prompts/$filename\`" >> "$index_file"
        done

        echo -e "\n---\n*Last updated: $TIMESTAMP*" >> "$index_file"

        local lines=$(wc -l < "$index_file")
        track_change "index-prompts.md" "$lines"
        log_success "Updated: index-prompts.md ($count prompts, $lines lines)"
    else
        log_verbose "[DRY-RUN] Would update: $index_file ($count prompts)"
    fi
}

update_slash_commands_index() {
    log_info "Scanning slash commands directory (Tier 2)..."

    local commands_dir="$CLAUDE_DIR/commands"
    local index_file="$CONTEXT_DIR/index-slash-commands.md"
    local count=$(count_files "$commands_dir" "*.md")

    log_verbose "Found $count command files in $commands_dir"

    if [[ $count -eq 0 ]]; then
        log_error_track "No commands found in $commands_dir"
        return 1
    fi

    local tier_header=$(get_tier_header 2)
    local header="$tier_header

# Slash Commands Index - Quick Reference

This file catalogs all slash commands available in the \`.claude/commands/\` directory.

## What Are Slash Commands?

Slash commands (e.g., \`/build-backlog\`, \`/prompt-review\`) are entry points that expand to full prompts for complex workflows.

---

## Available Slash Commands

**Total Commands:** $count

### Command List
"

    if [[ "$DRY_RUN" == false ]]; then
        echo "$header" > "$index_file"

        list_files "$commands_dir" "*.md" | while read -r file; do
            local filename=$(basename "$file")
            local command_name=$(basename "$filename" .md)

            # Extract description from frontmatter if available
            local description=$(grep -A 1 "description:" "$file" 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "")

            echo -e "\n- **/$command_name**" >> "$index_file"
            if [[ -n "$description" ]]; then
                echo "  - Description: $description" >> "$index_file"
            fi
            echo "  - File: \`commands/$filename\`" >> "$index_file"
        done

        echo -e "\n---\n*Last updated: $TIMESTAMP*" >> "$index_file"

        local lines=$(wc -l < "$index_file")
        track_change "index-slash-commands.md" "$lines"
        log_success "Updated: index-slash-commands.md ($count commands, $lines lines)"
    else
        log_verbose "[DRY-RUN] Would update: $index_file ($count commands)"
    fi
}

update_gitignore_index() {
    log_info "Scanning gitignored directories (Tier 2)..."

    local app_modules_dir="$PROJECT_ROOT/_AppModules-Luce"
    local index_file="$CONTEXT_DIR/index-gitignore-claude.ignore.md"

    if [[ ! -d "$app_modules_dir" ]]; then
        log_warning "_AppModules-Luce directory not found - skipping"
        return 0
    fi

    local count=$(find "$app_modules_dir" -type f 2>/dev/null | wc -l)
    log_verbose "Found $count files in _AppModules-Luce"

    local tier_header=$(get_tier_header 2)

    if [[ "$DRY_RUN" == false ]]; then
        local header="$tier_header

# Index: _AppModules-Luce Directory

**Status:** Directory is gitignored but contents are documented here for Claude Code context management.

**Location:** \`_AppModules-Luce/\` (root level, not tracked in git)

**Purpose:** User working directory for app modules, playbooks, CLI manager templates, and GitHub scripts.

---

## Directory Structure & File Listing

**Last Scanned:** $TIMESTAMP
**Total Files:** $count

### Subdirectories
"

        echo "$header" > "$index_file"

        # List subdirectories with file counts
        find "$app_modules_dir" -maxdepth 1 -type d ! -name ".*" 2>/dev/null | sort | while read -r subdir; do
            if [[ "$subdir" != "$app_modules_dir" ]]; then
                local dirname=$(basename "$subdir")
                local file_count=$(find "$subdir" -type f 2>/dev/null | wc -l)
                echo -e "\n- **$dirname/** ($file_count files)" >> "$index_file"

                # List files in this subdirectory
                find "$subdir" -maxdepth 1 -type f 2>/dev/null | sort | while read -r file; do
                    local filename=$(basename "$file")
                    echo "  - \`$filename\`" >> "$index_file"
                done
            fi
        done

        echo -e "\n---\n*Last updated: $TIMESTAMP*" >> "$index_file"

        local lines=$(wc -l < "$index_file")
        track_change "index-gitignore-claude.ignore.md" "$lines"
        log_success "Updated: index-gitignore-claude.ignore.md ($count files, $lines lines)"
    else
        log_verbose "[DRY-RUN] Would update: $index_file ($count files)"
    fi
}

##############################################################################
# Summary Report Generation
##############################################################################

generate_summary_report() {
    log_info "Generating update summary report..."
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                      INDEX FILES UPDATE SUMMARY                              ║"
    echo "║                      Tier-Aware Context Management                           ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📊 Timestamp: $TIMESTAMP"
    echo "📁 Project Root: $PROJECT_ROOT"
    echo "📍 Context Dir: $CONTEXT_DIR"
    echo ""

    # Files Updated Section
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "📝 FILES UPDATED"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""

    local total_lines=0
    local file_count=0
    local update_count=0
    if [[ -n "${UPDATE_ORDER[0]:-}" ]] || [[ ${#UPDATE_ORDER[@]} -gt 0 ]] 2>/dev/null; then
        update_count=${#UPDATE_ORDER[@]}
    fi

    # Safely check if UPDATE_ORDER array has elements
    if [[ $update_count -eq 0 ]]; then
        echo "   (No files updated in this run)"
    else
        for file in "${UPDATE_ORDER[@]}"; do
            local lines="${FILE_CHANGES[$file]:-0}"
            total_lines=$((total_lines + lines))
            file_count=$((file_count + 1))

            # Get basename for cleaner output
            local basename=$(basename "$file")
            printf "   %-40s %5s lines\n" "$basename" "$lines"
        done
    fi

    echo ""
    echo "   Total Files: $file_count | Total Lines: $total_lines"
    echo ""

    # _index-master.md Summary (shown last)
    if [[ $file_count -gt 0 ]]; then
        echo "════════════════════════════════════════════════════════════════════════════════"
        echo "📊 SUMMARY"
        echo "════════════════════════════════════════════════════════════════════════════════"
        echo ""
        echo "   Files Updated:     $file_count"
        echo "   Total Lines:       $total_lines"
        echo "   Tier 2 Indexes:    ${#TIER2_FILES[@]}"
        echo "   Tier 3 Indexes:    ${#TIER3_FILES[@]}"
        echo "   Tier 4 Indexes:    ${#TIER4_FILES[@]}"
        echo ""
    fi

    # Error Summary Section
    if [[ $ERRORS_FOUND -gt 0 ]]; then
        echo "════════════════════════════════════════════════════════════════════════════════"
        echo "⚠️  ERRORS ENCOUNTERED ($ERRORS_FOUND)"
        echo "════════════════════════════════════════════════════════════════════════════════"
        echo ""
        for error in "${ERRORS[@]}"; do
            echo "   ✗ $error"
        done
        echo ""
    fi

    # Tier Distribution
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "🎯 TIER DISTRIBUTION"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "   Tier 1 (Always Preloaded):     ${#TIER1_FILES[@]} files"
    echo "   Tier 2 (Core Development):     ${#TIER2_FILES[@]} files"
    echo "   Tier 3 (Specialized Ref):      ${#TIER3_FILES[@]} files"
    echo "   Tier 4 (Project-Wide Docs):    ${#TIER4_FILES[@]} files"
    echo "   Total Index Files:             ${#FOUND_INDEXES[@]} files"
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
}

##############################################################################
# Main Execution
##############################################################################

main() {
    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --help)
                show_help
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                log_info "Running in DRY-RUN mode (no changes will be made)"
                ;;
            --verbose)
                VERBOSE=true
                ;;
            *)
                log_error "Unknown argument: $arg"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    log_info "Context Management Master Index Updater"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Comprehensive scan of all index files
    log_info "Discovering all index files..."
    while IFS= read -r index_file; do
        if [[ -n "$index_file" ]]; then
            categorize_index_files "$index_file"
        fi
    done < <(find_all_index_files)

    log_success "Found ${#FOUND_INDEXES[@]} index files across all tiers"
    echo ""

    # Phase 1.5: Ensure all discovered files have tier headers
    log_info "Checking tier headers on all index files..."
    local files_needing_headers=0
    local files_with_headers=0

    for index_file in "${FOUND_INDEXES[@]}"; do
        if [[ -f "$index_file" ]]; then
            if has_tier_header "$index_file"; then
                files_with_headers=$((files_with_headers + 1))
            else
                files_needing_headers=$((files_needing_headers + 1))
                if [[ "$DRY_RUN" == true ]]; then
                    log_verbose "[DRY-RUN] Would add header to: $(basename "$index_file")"
                else
                    ensure_tier_header "$index_file"
                fi
            fi
        fi
    done

    if [[ $files_needing_headers -gt 0 ]]; then
        log_success "Headers processed: $files_with_headers present, $files_needing_headers added"
    fi
    echo ""

    # Update core development indexes (Tier 2)
    log_info "Updating Tier 2 indexes..."
    update_agents_index || true
    update_prompts_index || true
    update_slash_commands_index || true
    update_gitignore_index || true

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Generate and display summary report
    generate_summary_report

    # Final status
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY-RUN completed. No changes were made."
    elif [[ $ERRORS_FOUND -gt 0 ]]; then
        log_warning "Update completed with $ERRORS_FOUND error(s). Review above."
        exit 1
    else
        log_success "Index update completed successfully!"
    fi

    echo ""
}

# Run main function
main "$@"
