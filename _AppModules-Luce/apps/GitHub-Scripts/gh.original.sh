#!/usr/bin/env bash
# gh-manager.sh - Menu-based Git & GitHub helper for Bloom
# Combines:
#   - Interactive merge helper (branch -> TARGET_BRANCH)
#   - Local workflow helper (status, commit, stash, diff, discard)
#   - Branch management tools (list merged, safe delete, cleanup claude/*)
#
# Usage: ./scripts/gh-manager.sh

set -e

########################
# Colors & Formatting  #
########################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color
BOLD='\033[1m'

########################
# Config               #
########################

TARGET_BRANCH="${TARGET_BRANCH:-main}"
DRY_RUN="${DRY_RUN:-false}"
AUTO_PUSH="${AUTO_PUSH:-true}"
MAX_RETRIES=4

########################
# Editor Preference    #
########################

prefer_micro_editor() {
    # Check if micro is installed
    if ! command -v micro >/dev/null 2>&1; then
        warn "micro editor not found"
        echo ""
        echo -e "${BOLD}Install micro editor?${NC}"
        echo "  • User-friendly terminal editor (similar to nano but better)"
        echo "  • Syntax highlighting and mouse support"
        echo "  • Installation: curl https://getmic.ro | bash"
        echo ""

        if confirm "Install micro now?"; then
            log "Installing micro editor..."
            if curl -s https://getmic.ro | bash; then
                # Move to user bin if possible
                if [[ -d "$HOME/bin" ]]; then
                    mv -f micro "$HOME/bin/" 2>/dev/null || sudo mv -f micro /usr/local/bin/
                else
                    sudo mv -f micro /usr/local/bin/ 2>/dev/null || {
                        error "Installation failed. Try manually: curl https://getmic.ro | bash"
                        return 1
                    }
                fi
                success "micro editor installed successfully!"
                export EDITOR="micro"
                export VISUAL="micro"
                export GIT_EDITOR="micro"
                return 0
            else
                error "Installation failed"
                return 1
            fi
        else
            return 1
        fi
    fi

    # Force micro as the editor for all contexts
    export EDITOR="micro"
    export VISUAL="micro"
    export GIT_EDITOR="micro"

    # Also set git config to use micro (local to this repo)
    git config core.editor "micro" 2>/dev/null || true

    return 0
}

prefer_micro_editor

########################
# Logging Helpers      #
########################

log()      { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
error()    { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn()     { echo -e "${YELLOW}[WARNING]${NC} $1"; }
info()     { echo -e "${CYAN}[INFO]${NC} $1"; }
success()  { echo -e "${GREEN}✓${NC} $1"; }

header() {
    echo ""
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA}  $1${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

########################
# Generic Helpers      #
########################

confirm() {
    local prompt="$1"
    local default="${2:-n}"

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$(echo -e ${YELLOW}${prompt}${NC})" response
    response=${response:-$default}

    [[ "$response" =~ ^[Yy]$ ]]
}

compare_versions() {
    # Compare two version numbers (e.g., "2.46.0" vs "2.83.1")
    # Returns: 0 if equal, 1 if v1 < v2, 2 if v1 > v2
    local v1=$1
    local v2=$2

    # Strip any extra text (e.g., "2.46.0 (2025-01-13)" -> "2.46.0")
    v1=$(echo "$v1" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    v2=$(echo "$v2" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

    if [[ "$v1" == "$v2" ]]; then
        return 0
    fi

    # Convert to arrays for comparison
    IFS='.' read -ra V1 <<< "$v1"
    IFS='.' read -ra V2 <<< "$v2"

    # Compare major, minor, patch
    for i in 0 1 2; do
        local n1=${V1[$i]:-0}
        local n2=${V2[$i]:-0}
        if [[ $n1 -lt $n2 ]]; then
            return 1  # v1 < v2
        elif [[ $n1 -gt $n2 ]]; then
            return 2  # v1 > v2
        fi
    done

    return 0  # Equal
}

check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        error "Not a git repository. Run this inside a Git repo."
        exit 1
    fi
}

check_gh_cli() {
    # Check if gh is installed
    if ! command -v gh >/dev/null 2>&1; then
        warn "GitHub CLI (gh) is not installed"
        echo ""
        echo -e "${BOLD}This script requires GitHub CLI for full functionality:${NC}"
        echo "  • Create and merge pull requests"
        echo "  • View GitHub Actions status"
        echo "  • Manage branches and releases"
        echo "  • Branch protection checks"
        echo ""

        if confirm "Install GitHub CLI now?"; then
            install_gh_cli
            if ! command -v gh >/dev/null 2>&1; then
                error "GitHub CLI installation failed. Exiting."
                exit 1
            fi
        else
            error "GitHub CLI is required to use this script. Exiting."
            echo ""
            echo "Install manually:"
            echo "  • Run option 19 from the menu"
            echo "  • Or visit: https://cli.github.com"
            exit 1
        fi
    fi

    # Check if authenticated
    if ! gh auth status >/dev/null 2>&1; then
        warn "Not authenticated with GitHub"
        echo ""
        echo -e "${BOLD}You need to authenticate to use GitHub features.${NC}"
        echo ""

        if confirm "Run 'gh auth login' now?"; then
            gh auth login
            if ! gh auth status >/dev/null 2>&1; then
                error "Authentication failed. Exiting."
                echo ""
                echo "Try running manually: gh auth login"
                exit 1
            fi
            success "Successfully authenticated with GitHub!"
        else
            error "GitHub authentication required. Exiting."
            echo ""
            echo "Run manually: gh auth login"
            exit 1
        fi
    fi

    # Show brief status with version check
    local gh_user=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
    local gh_version_full=$(gh --version | head -1)
    local gh_version=$(echo "$gh_version_full" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

    # Quick version check (non-blocking)
    local latest_version=$(curl -s --max-time 2 https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | \
        grep -oE '"tag_name":\s*"v[0-9]+\.[0-9]+\.[0-9]+"' | \
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | \
        head -1)

    if [[ -n "$latest_version" && -n "$gh_version" ]]; then
        compare_versions "$gh_version" "$latest_version"
        local cmp=$?

        if [[ $cmp -eq 1 ]]; then
            # Outdated version
            warn "GitHub CLI v$gh_version detected (latest: v$latest_version)"
            echo -e "${GRAY}Run option 19 to upgrade${NC}"
        else
            success "GitHub CLI ready (v$gh_version, user: $gh_user)"
        fi
    else
        # Could not check version, just show installed
        success "GitHub CLI ready (v$gh_version, user: $gh_user)"
    fi
}

get_current_branch() {
    git branch --show-current
}

########################
# Merge Helper (from gh-merge.sh)
########################

branch_exists() {
    local branch="$1"
    local location="${2:-both}" # local, remote, or both

    case $location in
        local)
            git show-ref --verify --quiet "refs/heads/$branch" >/dev/null 2>&1 && return 0 || return 1
            ;;
        remote)
            git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1 && return 0 || return 1
            ;;
        both)
            git show-ref --verify --quiet "refs/heads/$branch" >/dev/null 2>&1 && return 0 || \
            git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1 && return 0 || return 1
            ;;
    esac
}

fetch_origin() {
    log "Fetching latest changes from origin..."
    if git fetch origin 2>&1 | grep -q "error\|fatal"; then
        error "Failed to fetch from origin"
        return 1
    fi
    success "Fetched latest changes"
}

get_branch_list() {
    local -n branches_ref=$1

    # Claude Code session branches first
    while IFS= read -r branch; do
        branches_ref+=("$branch")
    done < <(git branch -r | grep "origin/claude/" | sed 's/origin\///' | sed 's/^[[:space:]]*//')

    # Other branches
    while IFS= read -r branch; do
        if [[ "$branch" != "$TARGET_BRANCH" ]]; then
            branches_ref+=("$branch")
        fi
    done < <(git branch -r | grep -v "origin/claude/" | grep -v "origin/HEAD" | sed 's/origin\///' | sed 's/^[[:space:]]*//')
}

list_branches_for_merge() {
    local -n branches_ref=$1
    local show_numbers="${2:-true}"

    header "Available Remote Branches for Merge → $TARGET_BRANCH"

    local idx=1
    local claude_count=0
    for branch in "${branches_ref[@]}"; do
        [[ "$branch" =~ ^claude/ ]] && ((claude_count++))
    done

    echo -e "${BOLD}Claude Code Session Branches:${NC}"
    for branch in "${branches_ref[@]}"; do
        if [[ "$branch" =~ ^claude/ ]]; then
            local last_commit
            last_commit=$(git log -1 --format="%h - %s (%cr)" "origin/$branch" 2>/dev/null || echo "N/A")
            if [[ "$show_numbers" == "true" ]]; then
                printf "  ${CYAN}[%2d]${NC} ${CYAN}%s${NC}\n" "$idx" "$branch"
            else
                echo -e "  ${CYAN}$branch${NC}"
            fi
            echo -e "       └─ $last_commit"
            ((idx++))
        fi
    done

    if [[ ${#branches_ref[@]} -gt $claude_count ]]; then
        echo ""
        echo -e "${BOLD}Other Remote Branches:${NC}"
        for branch in "${branches_ref[@]}"; do
            if [[ ! "$branch" =~ ^claude/ ]]; then
                local last_commit
                last_commit=$(git log -1 --format="%h - %s (%cr)" "origin/$branch" 2>/dev/null || echo "N/A")
                if [[ "$show_numbers" == "true" ]]; then
                    printf "  ${BLUE}[%2d]${NC} ${BLUE}%s${NC}\n" "$idx" "$branch"
                else
                    echo -e "  ${BLUE}$branch${NC}"
                fi
                echo -e "       └─ $last_commit"
                ((idx++))
            fi
        done
    fi
    echo ""
}

show_branch_comparison() {
    local source_branch="$1"

    header "Branch Comparison: $source_branch → $TARGET_BRANCH"

    local ahead behind
    ahead=$(git rev-list --count "$TARGET_BRANCH".."origin/$source_branch" 2>/dev/null || echo "0")
    behind=$(git rev-list --count "origin/$source_branch".."$TARGET_BRANCH" 2>/dev/null || echo "0")

    echo -e "${BOLD}Status:${NC}"
    echo -e "  Ahead:  ${GREEN}$ahead commit(s)${NC} (will be merged)"
    echo -e "  Behind: ${YELLOW}$behind commit(s)${NC} (target has new commits)"

    if [[ $ahead -gt 0 ]]; then
        echo ""
        echo -e "${BOLD}Commits to be merged (top 10):${NC}"
        git log --oneline --no-decorate "$TARGET_BRANCH".."origin/$source_branch" 2>/dev/null | head -10 | sed 's/^/  /' || echo "  (unable to show commits)"

        echo ""
        echo -e "${BOLD}Files changed (top 20):${NC}"
        local files_changed
        files_changed=$(git diff --name-status "$TARGET_BRANCH"..."origin/$source_branch" 2>/dev/null)
        if [[ -n "$files_changed" ]]; then
            echo "$files_changed" | head -20 | while IFS=$'\t' read -r status file rest; do
                case "$status" in
                    A) echo -e "  ${GREEN}+${NC} $file" ;;
                    D) echo -e "  ${RED}-${NC} $file" ;;
                    M) echo -e "  ${YELLOW}~${NC} $file" ;;
                    R*) echo -e "  ${BLUE}→${NC} $file → $rest" ;;
                    *) echo -e "  ${CYAN}?${NC} $file" ;;
                esac
            done
            local total_files
            total_files=$(echo "$files_changed" | wc -l)
            if [[ $total_files -gt 20 ]]; then
                echo -e "  ${CYAN}... and $((total_files - 20)) more file(s)${NC}"
            fi
        else
            echo "  (no files changed)"
        fi
    fi

    if [[ $behind -gt 0 ]]; then
        echo ""
        warn "Target branch has $behind new commit(s) – will need to rebase or merge"
    fi

    echo ""
}

check_merge_conflicts() {
    local source_branch="$1"

    log "Checking for potential merge conflicts..."

    git merge --no-commit --no-ff "origin/$source_branch" >/dev/null 2>&1 || {
        git merge --abort >/dev/null 2>&1 || true
        warn "Potential merge conflicts detected!"
        echo ""
        echo "Conflicting files (approx):"
        git diff --name-only --diff-filter=U "$TARGET_BRANCH" "origin/$source_branch" 2>/dev/null | sed 's/^/  - /' || echo "  (unable to determine)"
        echo ""
        if ! confirm "Continue with merge anyway?"; then
            error "Merge aborted by user"
            return 1
        fi
        return 0
    }

    git merge --abort >/dev/null 2>&1 || true
    success "No merge conflicts detected"
}

perform_merge() {
    local source_branch="$1"
    local merge_strategy="${2:-merge}" # merge or rebase

    header "Merging: $source_branch → $TARGET_BRANCH"

    if [[ "$DRY_RUN" == "true" ]]; then
        warn "DRY RUN MODE - No actual changes will be made"
        echo ""
        echo "Would execute:"
        echo "  git checkout $TARGET_BRANCH"
        echo "  git pull origin $TARGET_BRANCH"
        if [[ "$merge_strategy" == "rebase" ]]; then
            echo "  git rebase origin/$source_branch"
        else
            echo "  git merge --no-ff origin/$source_branch -m 'Merge branch $source_branch into $TARGET_BRANCH'"
        fi
        if [[ "$AUTO_PUSH" == "true" ]]; then
            echo "  git push origin $TARGET_BRANCH"
        fi
        return 0
    fi

    log "Switching to $TARGET_BRANCH..."
    git checkout "$TARGET_BRANCH"

    log "Pulling latest changes from origin/$TARGET_BRANCH..."
    git pull origin "$TARGET_BRANCH" || warn "Failed to pull latest changes (may already be up-to-date)"

    if [[ "$merge_strategy" == "rebase" ]]; then
        log "Rebasing onto origin/$source_branch..."
        if git rebase "origin/$source_branch"; then
            success "Rebase successful"
        else
            error "Rebase failed"
            echo ""
            echo "To resolve conflicts:"
            echo "  1. Fix conflicts in the listed files"
            echo "  2. git add <resolved-files>"
            echo "  3. git rebase --continue"
            echo ""
            echo "Or to abort:"
            echo "  git rebase --abort"
            return 1
        fi
    else
        log "Merging origin/$source_branch..."
        if git merge --no-ff "origin/$source_branch" -m "Merge branch '$source_branch' into $TARGET_BRANCH"; then
            success "Merge successful"
        else
            error "Merge failed"
            echo ""
            echo "To resolve conflicts:"
            echo "  1. Fix conflicts in the listed files"
            echo "  2. git add <resolved-files>"
            echo "  3. git commit"
            echo ""
            echo "Or to abort:"
            echo "  git merge --abort"
            return 1
        fi
    fi

    echo ""
    git log --oneline -5 | sed 's/^/  /'
    echo ""
}

push_with_retry() {
    local branch="$1"
    local attempt=1
    local delay=2

    header "Pushing Changes to Remote"

    if [[ "$DRY_RUN" == "true" ]]; then
        warn "DRY RUN MODE - Would push $branch to origin"
        return 0
    fi

    while [[ $attempt -le $MAX_RETRIES ]]; do
        log "Push attempt $attempt/$MAX_RETRIES..."

        if git push -u origin "$branch"; then
            success "Successfully pushed $branch to origin"
            return 0
        else
            local exit_code=$?
            if [[ $exit_code -eq 403 ]]; then
                error "Permission denied (403) - Cannot push from this environment"
                echo ""
                warn "To push manually from your local machine:"
                echo "  git checkout $branch"
                echo "  git pull origin $branch"
                echo "  git push origin $branch"
                return 1
            fi
            if [[ $attempt -lt $MAX_RETRIES ]]; then
                warn "Push failed, retrying in ${delay}s..."
                sleep $delay
                delay=$((delay * 2))
                attempt=$((attempt + 1))
            else
                error "Push failed after $MAX_RETRIES attempts"
                return 1
            fi
        fi
    done
}

merge_branch_workflow() {
    local source_branch="$1"

    source_branch="${source_branch#origin/}"

    header "Merge Workflow: $source_branch → $TARGET_BRANCH"

    if ! branch_exists "$source_branch" "remote"; then
        error "Branch '$source_branch' not found on remote"
        return 1
    fi

    if ! fetch_origin; then
        return 1
    fi

    show_branch_comparison "$source_branch"

    if ! confirm "Proceed with merge?" "y"; then
        warn "Merge cancelled by user"
        return 1
    fi

    if ! check_merge_conflicts "$source_branch"; then
        return 1
    fi

    echo ""
    echo "Merge strategies:"
    echo "  1) Merge (preserve branch history)"
    echo "  2) Rebase (linear history)"
    read -p "$(echo -e ${YELLOW}Select strategy [1]: ${NC})" strategy
    strategy=${strategy:-1}

    local merge_strategy="merge"
    [[ "$strategy" == "2" ]] && merge_strategy="rebase"

    if ! perform_merge "$source_branch" "$merge_strategy"; then
        return 1
    fi

    if [[ "$AUTO_PUSH" == "true" ]]; then
        if ! push_with_retry "$TARGET_BRANCH"; then
            warn "Merge completed locally but not pushed to remote"
            return 1
        fi
    else
        warn "AUTO_PUSH disabled – changes not pushed"
        echo "To push manually: git push origin $TARGET_BRANCH"
    fi

    success "Merge workflow completed!"
}

merge_branch_menu() {
    check_git_repo
    header "Interactive Branch Merger"

    local current_branch
    current_branch=$(get_current_branch)
    info "Current branch: $current_branch"
    info "Target branch: $TARGET_BRANCH"
    echo ""

    fetch_origin

    local branches=()
    get_branch_list branches

    if [[ ${#branches[@]} -eq 0 ]]; then
        error "No remote branches available to merge"
        return 1
    fi

    list_branches_for_merge branches

    echo -e "${BOLD}Select branch to merge (number or name, or 'q' to cancel):${NC}"
    read -p "> " selection

    if [[ "$selection" == "q" ]]; then
        log "Merge cancelled."
        return 0
    fi

    if [[ -z "$selection" ]]; then
        error "No branch specified"
        return 1
    fi

    local selected_branch=""
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        local idx=$((selection - 1))
        if [[ $idx -ge 0 && $idx -lt ${#branches[@]} ]]; then
            selected_branch="${branches[$idx]}"
            info "Selected: [$selection] $selected_branch"
        else
            error "Invalid selection: $selection (valid range: 1-${#branches[@]})"
            return 1
        fi
    else
        selected_branch="$selection"
    fi

    merge_branch_workflow "$selected_branch"
}

########################
# Branch Management Tools
########################

list_merged_remote_branches() {
    check_git_repo
    header "Remote branches fully merged into origin/$TARGET_BRANCH"

    fetch_origin

    git branch -r --merged "origin/$TARGET_BRANCH" \
        | grep -v "origin/HEAD" \
        | grep -v "origin/$TARGET_BRANCH" \
        | sed 's/^/  /' || true
}

list_merged_local_branches() {
    check_git_repo
    header "Local branches fully merged into $TARGET_BRANCH"

    git branch --merged "$TARGET_BRANCH" \
        | grep -v "^\*" \
        | grep -v " $TARGET_BRANCH$" \
        | sed 's/^/  /' || true
}

delete_remote_branch_safe() {
    check_git_repo
    header "Delete Remote Branch (with safety check)"

    fetch_origin

    echo "Remote branches fully merged into origin/$TARGET_BRANCH:"
    local merged
    merged=$(git branch -r --merged "origin/$TARGET_BRANCH" | grep -v "origin/HEAD" | grep -v "origin/$TARGET_BRANCH" | sed 's/origin\///')
    if [[ -z "$merged" ]]; then
        warn "No fully merged remote branches found."
    else
        echo "$merged" | sed 's/^/  - /'
    fi
    echo ""

    read -p "Branch name to delete on origin (without 'origin/'): " branch
    [[ -z "$branch" ]] && { warn "No branch specified"; return; }
    if [[ "$branch" == "$TARGET_BRANCH" ]]; then
        error "Refusing to delete the target branch '$TARGET_BRANCH'."
        return
    fi

    if echo "$merged" | grep -qx "$branch"; then
        info "Branch '$branch' is fully merged into origin/$TARGET_BRANCH."
    else
        warn "Branch '$branch' is NOT listed as fully merged into origin/$TARGET_BRANCH."
    fi

    local remote_ref="origin/$branch"
    local merge_verified="false"
    if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        if git merge-base --is-ancestor "$remote_ref" "origin/$TARGET_BRANCH"; then
            merge_verified="true"
            info "Verified: '$remote_ref' is already merged into origin/$TARGET_BRANCH."
        else
            warn "Git reports that '$remote_ref' still has commits not in origin/$TARGET_BRANCH."
        fi
    else
        warn "Unable to verify merge status because '$remote_ref' was not found locally."
    fi

    local prompt
    if [[ "$merge_verified" == "true" ]]; then
        prompt="Delete remote branch '$remote_ref'? (already merged)"
    else
        prompt="Delete remote branch '$remote_ref' even though merge status is uncertain?"
    fi

    if ! confirm "$prompt"; then
        warn "Remote delete cancelled."
        return
    fi

    git push origin --delete "$branch"
    success "Remote branch 'origin/$branch' deleted."
}

delete_local_branch_safe() {
    check_git_repo
    header "Delete Local Branch (safe)"

    echo "Local branches fully merged into $TARGET_BRANCH:"
    local merged
    merged=$(git branch --merged "$TARGET_BRANCH" | grep -v "^\*" | grep -v " $TARGET_BRANCH$" | sed 's/^[[:space:]]*//')
    if [[ -z "$merged" ]]; then
        warn "No fully merged local branches found."
        return
    fi

    echo "$merged" | sed 's/^/  - /'
    echo ""

    read -p "Local branch name to delete: " branch
    [[ -z "$branch" ]] && { warn "No branch specified"; return; }
    if [[ "$branch" == "$TARGET_BRANCH" ]]; then
        error "Refusing to delete the target branch '$TARGET_BRANCH'."
        return
    fi

    if ! git show-ref --verify --quiet "refs/heads/$branch"; then
        error "Local branch '$branch' does not exist."
        return
    fi

    local merge_verified="false"
    if git merge-base --is-ancestor "$branch" "$TARGET_BRANCH"; then
        merge_verified="true"
        info "Verified: '$branch' is already merged into $TARGET_BRANCH."
    else
        warn "Git reports that '$branch' still has commits not in $TARGET_BRANCH."
    fi

    if [[ "$merge_verified" == "true" ]]; then
        if ! confirm "Delete local branch '$branch'? (already merged)"; then
            warn "Local delete cancelled."
            return
        fi
        git branch -d "$branch"
        success "Local branch '$branch' safely deleted."
    else
        if ! confirm "Force delete '$branch' even though it is not fully merged?"; then
            warn "Local delete cancelled."
            return
        fi
        git branch -D "$branch"
        success "Local branch '$branch' FORCE deleted (not guaranteed merged)."
    fi
}

cleanup_merged_claude_remote() {
    check_git_repo
    header "Cleanup Merged Claude Code Branches"

    info "Fetching merged PRs with claude/* branches from GitHub..."
    echo ""

    # Use gh CLI to get actually-merged PRs with claude/* branches
    local merged_prs=$(gh pr list \
        --state merged \
        --json headRefName,number,mergedAt,title \
        --jq '.[] | select(.headRefName | startswith("claude/")) |
             "\(.headRefName)\t\(.number)\t\(.mergedAt)\t\(.title)"' 2>/dev/null)

    if [[ -z "$merged_prs" ]]; then
        success "No merged claude/* branches found"
        echo ""
        info "All clean! No claude/* branches with merged PRs."
        return
    fi

    # Check which branches actually still exist on GitHub
    info "Checking which branches still exist on GitHub..."
    echo ""

    local existing_branches=""
    local deleted_count=0

    while IFS=$'\t' read -r branch pr_num merged_at title; do
        # Check if branch exists using gh API
        if gh api "repos/:owner/:repo/git/refs/heads/$branch" >/dev/null 2>&1; then
            # Branch exists, add to list
            existing_branches+="$branch\t$pr_num\t$merged_at\t$title"$'\n'
        else
            ((deleted_count++))
        fi
    done <<< "$merged_prs"

    # Remove trailing newline
    existing_branches=$(echo -n "$existing_branches")

    if [[ -z "$existing_branches" ]]; then
        success "All merged branches already deleted!"
        echo ""
        info "Found $deleted_count merged PR(s), but all branches are already cleaned up."
        return
    fi

    echo -e "${BOLD}Merged Claude Code Web Session Branches (still exist):${NC}"
    echo ""
    echo -e "${CYAN}BRANCH\t\t\t\t\t\tPR#\tMERGED\t\t\tTITLE${NC}"
    echo "────────────────────────────────────────────────────────────────────────────────"
    echo "$existing_branches" | while IFS=$'\t' read -r branch pr_num merged_at title; do
        local short_title=$(echo "$title" | cut -c1-40)
        local merged_date=$(date -d "$merged_at" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$merged_at")
        printf "%-45s\t#%-5s\t%-20s\t%s\n" "$branch" "$pr_num" "$merged_date" "$short_title"
    done
    echo ""

    local branch_count=$(echo "$existing_branches" | grep -c '^')
    echo -e "${YELLOW}Total: $branch_count branch(es) to delete${NC}"

    if [[ $deleted_count -gt 0 ]]; then
        echo -e "${GRAY}($deleted_count already deleted)${NC}"
    fi
    echo ""

    if ! confirm "Delete all these branches from GitHub?"; then
        warn "Cleanup cancelled"
        return
    fi

    echo ""
    local deleted=0
    local failed=0

    while IFS=$'\t' read -r branch pr_num merged_at title; do
        log "Deleting $branch (PR #$pr_num)..."
        if gh api -X DELETE "repos/:owner/:repo/git/refs/heads/$branch" >/dev/null 2>&1; then
            success "✓ Deleted $branch"
            ((deleted++))
        else
            error "✗ Failed to delete $branch"
            ((failed++))
        fi
    done <<< "$existing_branches"

    echo ""
    if [[ $failed -eq 0 ]]; then
        success "All $deleted branch(es) deleted successfully!"
    else
        warn "Deleted: $deleted, Failed: $failed"
    fi

    # Clean up local tracking refs
    log "Cleaning up local tracking references..."
    git remote prune origin >/dev/null 2>&1
    success "Local tracking refs cleaned up"
}

claude_session_merge_and_cleanup() {
    check_git_repo

    while true; do
        header "Claude Code Web Session - Merge & Cleanup Workflow"

        info "This workflow will:"
        echo "  1. List Claude Code session branches"
        echo "  2. Merge selected branch to $TARGET_BRANCH"
        echo "  3. Delete the branch locally and remotely"
        echo "  4. Clean up tracking references"
        echo ""

        # Fetch latest
        if ! fetch_origin; then
            return 1
        fi

        # Get list of claude/* branches
        local claude_branches=()
        while IFS= read -r branch; do
            [[ -n "$branch" ]] && claude_branches+=("$branch")
        done < <(git branch -r | grep "origin/claude/" | sed 's/^[[:space:]]*origin\///' | sed 's/[[:space:]]*$//')

        if [[ ${#claude_branches[@]} -eq 0 ]]; then
            success "No Claude Code session branches found - all clean!"
            return 0
        fi

        # Display branches with details
        echo -e "${BOLD}Available Claude Code Session Branches:${NC}"
        echo ""
        local idx=1
        for branch in "${claude_branches[@]}"; do
            local ahead behind last_commit files_changed
            ahead=$(git rev-list --count "$TARGET_BRANCH".."origin/$branch" 2>/dev/null || echo "0")
            behind=$(git rev-list --count "origin/$branch".."$TARGET_BRANCH" 2>/dev/null || echo "0")
            last_commit=$(git log -1 --format="%h - %s (%cr)" "origin/$branch" 2>/dev/null || echo "N/A")

            # Get files changed count
            files_changed=$(git diff --name-only "$TARGET_BRANCH"..."origin/$branch" 2>/dev/null | wc -l | tr -d ' ')

            printf "  ${CYAN}[%2d]${NC} ${CYAN}%s${NC}\n" "$idx" "$branch"
            echo -e "       └─ $last_commit"
            echo -e "       └─ ${GREEN}↑$ahead${NC} ahead, ${YELLOW}↓$behind${NC} behind, ${BLUE}${files_changed}${NC} files changed"

            # Show top 5 changed files
            if [[ $files_changed -gt 0 ]]; then
                echo -e "       └─ Files:"
                git diff --name-status "$TARGET_BRANCH"..."origin/$branch" 2>/dev/null | head -5 | while IFS=$'\t' read -r status file rest; do
                    local indicator
                    case "$status" in
                        A) indicator="${GREEN}+${NC}" ;;
                        D) indicator="${RED}-${NC}" ;;
                        M) indicator="${YELLOW}~${NC}" ;;
                        R*) indicator="${BLUE}→${NC}" ;;
                        *) indicator="${GRAY}?${NC}" ;;
                    esac
                    echo -e "          $indicator $file"
                done

                if [[ $files_changed -gt 5 ]]; then
                    local remaining=$((files_changed - 5))
                    echo -e "          ${GRAY}... and $remaining more file(s)${NC}"
                fi
            fi
            echo ""
            ((idx++))
        done

        # Select branch
        echo -e "${BOLD}Select branch to merge and cleanup (number or name, 'q' to cancel):${NC}"
        read -p "> " selection

        if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
            log "Returning to main menu"
            return 0
        fi

        if [[ -z "$selection" ]]; then
            error "No branch specified"
            continue
        fi

        local selected_branch=""
        if [[ "$selection" =~ ^[0-9]+$ ]]; then
            local idx=$((selection - 1))
            if [[ $idx -ge 0 && $idx -lt ${#claude_branches[@]} ]]; then
                selected_branch="${claude_branches[$idx]}"
                info "Selected: [$selection] $selected_branch"
            else
                error "Invalid selection: $selection (valid range: 1-${#claude_branches[@]})"
                continue
            fi
        else
            selected_branch="${selection#origin/}"
        fi

        # Show detailed comparison
        show_branch_comparison "$selected_branch"

        # Confirm merge
        if ! confirm "Proceed with merge to $TARGET_BRANCH?" "y"; then
            warn "Merge cancelled"
            continue
        fi

        # Perform the merge
        echo ""
        log "Switching to $TARGET_BRANCH..."
        git checkout "$TARGET_BRANCH" || { error "Failed to checkout $TARGET_BRANCH"; continue; }

        log "Pulling latest $TARGET_BRANCH..."
        git pull origin "$TARGET_BRANCH" || warn "Already up to date"

        log "Merging origin/$selected_branch into $TARGET_BRANCH..."
        if ! git merge --no-ff "origin/$selected_branch" -m "Merge Claude Code session: $selected_branch

Automated merge and cleanup via gh.sh script"; then
            error "Merge failed - resolve conflicts manually"
            echo ""
            echo "To resolve:"
            echo "  1. Fix conflicts in listed files"
            echo "  2. git add <resolved-files>"
            echo "  3. git commit"
            echo "  4. Re-run this script to continue cleanup"
            continue
        fi

        success "Merge completed successfully"
        echo ""
        echo "Recent commits:"
        git log --oneline -5 | sed 's/^/  /'
        echo ""

        # Push to main
        log "Pushing $TARGET_BRANCH to origin..."
        if git push origin "$TARGET_BRANCH"; then
            success "Successfully pushed $TARGET_BRANCH to origin"
        else
            local exit_code=$?
            if [[ $exit_code -eq 403 ]]; then
                warn "Permission denied (403) - Branch protection active"
                echo ""
                echo "The merge is complete locally, but you need to push manually:"
                echo "  git push origin $TARGET_BRANCH"
                echo ""
                if ! confirm "Continue with branch cleanup anyway?"; then
                    warn "Cleanup cancelled - branch remains"
                    continue
                fi
            else
                error "Failed to push $TARGET_BRANCH"
                echo ""
                echo "Retry manually with: git push origin $TARGET_BRANCH"
                if ! confirm "Continue with branch cleanup anyway?"; then
                    warn "Cleanup cancelled - branch remains"
                    continue
                fi
            fi
        fi

        # Delete remote branch
        echo ""
        log "Deleting remote branch origin/$selected_branch..."
        if git push origin --delete "$selected_branch"; then
            success "Deleted remote branch origin/$selected_branch"
        else
            error "Failed to delete remote branch"
            echo "Delete manually with: git push origin --delete $selected_branch"
        fi

        # Delete local branch if it exists
        if git show-ref --verify --quiet "refs/heads/$selected_branch"; then
            log "Deleting local branch $selected_branch..."
            git branch -D "$selected_branch" 2>/dev/null || git branch -d "$selected_branch"
            success "Deleted local branch $selected_branch"
        fi

        # Clean up tracking references
        log "Cleaning up tracking references..."
        git remote prune origin

        echo ""
        success "✓ Claude Code session workflow complete!"
        echo ""
        echo "Summary:"
        echo "  ✓ Merged $selected_branch → $TARGET_BRANCH"
        echo "  ✓ Deleted remote branch"
        echo "  ✓ Deleted local branch (if existed)"
        echo "  ✓ Cleaned up tracking refs"
        echo ""
        echo "Your repository is clean and ready for the next session!"
        echo ""
    done
}

show_claude_web_help() {
    header "Claude Code Web - Git Workflow Guide"

    cat << 'EOF'
🌐 CLAUDE CODE WEB BRANCH BEHAVIOR

Every Claude Code web session automatically creates a new branch:
  • Pattern: claude/[session-type]-[session-id]
  • Examples:
    - claude/fix-s-01HH3SA5nhHjgc5Po4fimzuu
    - claude/new-session-01956oJwQMRfy3jS5kf6HCSr
    - claude/work-in-progress-01GtwK1st2bwyis9sS2PjsX1

Without cleanup, these branches accumulate rapidly! This script automates the workflow.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 TYPICAL WORKFLOW

1. WORK IN CLAUDE CODE WEB SESSION
   • Claude Code automatically commits to session branch
   • All changes are on: claude/[session-id]

2. SESSION COMPLETE - SYNC TO MAIN
   Run this script: ./scripts/gh.sh

   Option 11) Session merge & cleanup

   This will:
   ✓ List all Claude Code session branches with status
   ✓ Let you select which session to merge
   ✓ Show detailed comparison (commits, files changed)
   ✓ Merge to main with proper commit message
   ✓ Push to main (or tell you how if branch protection is active)
   ✓ Delete remote branch (origin/claude/...)
   ✓ Delete local branch (if it exists)
   ✓ Clean up tracking references
   ✓ Leave repo ready for next session
   ✓ Loop back to select another branch (or type 'q' to exit)

3. START FRESH
   • New Claude Code session = new clean branch
   • No clutter from previous sessions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 KEY SCRIPT OPTIONS FOR CLAUDE CODE WEB

Option 1)  Status snapshot
           → See current branch and uncommitted changes

Option 9)  Branch manager (manual)
           → Interactive branch operations (list, merge, delete)
           → Use when you need more control

Option 11) Session merge & cleanup (RECOMMENDED)
           → Full automated workflow for Claude Code sessions
           → One-stop solution for session cleanup
           → Handles everything from merge to deletion
           → Loops back to select another branch

Option 10) Cleanup claude/* remotes (bulk)
           → Delete ALL merged claude/* branches at once
           → Uses gh CLI to find actually-merged PRs
           → Shows PR number and merge date

Option 12) Create pull request
           → Interactive PR creation with gh CLI
           → Can create PR directly or just show command
           → Auto-populates from PR template if exists

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  COMMON ISSUES & SOLUTIONS

Issue: "Permission denied (403)" when pushing to main
Solution: Branch protection is active. The script will:
          1. Complete merge locally
          2. Show you manual push command
          3. Still delete the session branch
          4. You push manually: git push origin main

Issue: Multiple accumulated claude/* branches
Solution: Use Option 10 to bulk delete all merged branches
          Or use Option 11 to clean them one by one

Issue: Merge conflicts detected
Solution: Script shows conflicting files. Fix manually:
          1. Edit conflicting files
          2. git add <files>
          3. git commit
          4. Re-run script Option 11 to finish cleanup

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 BEST PRACTICES

✓ Run Option 11 after EVERY Claude Code web session
✓ Review the commit list before merging
✓ Check "ahead/behind" status to avoid surprises
✓ Keep main branch clean - merge sessions regularly
✓ Use Option 10 for bulk cleanup when you have multiple branches
✓ GitHub CLI (gh) is now REQUIRED - script checks at startup

❌ Don't manually delete branches before merging
❌ Don't accumulate 10+ session branches
❌ Don't force push to main
❌ Don't skip the comparison step

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚫 CLAUDE CODE WEB LIMITATIONS (Important!)

❌ CANNOT DO (requires manual action):
  • Push to protected branches (main) → 403 error, must use PR workflow
  • Manage branch protection rules → GitHub Settings required
  • Create/manage GitHub Issues/Releases (use gh CLI for these)

✅ CAN NOW DO (via gh CLI integration):
  • Create Pull Requests → Option 12 creates PRs directly
  • View GitHub Actions → Option 15 shows workflow status
  • Delete branches via GitHub API → Option 10 uses gh CLI
  • All local Git operations (commit, add, status, log, diff)
  • Push to feature branches (claude/*)
  • Fetch and pull from any branch
  • Local merges and branch management

⚙️ RECOMMENDED WORKFLOW:
  When Option 11 fails to push to main (403 error):

  1. Script completes merge locally ✓
  2. Script deletes session branch ✓
  3. YOU MUST: Create PR

     Option A - Use script:
     Run Option 12 → Select "Create PR now"
     Opens browser and creates PR automatically

     Option B - Manual gh CLI:
     gh pr create --base main --fill

  4. Merge PR in GitHub web UI or: gh pr merge <number> --merge
  5. Local sync: git pull origin main

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 QUICK REFERENCE

Start session:       Claude Code Web auto-creates branch
End session:         ./scripts/gh.sh → Option 11 (Session merge & cleanup)
Check status:        ./scripts/gh.sh → Option 1 (Status snapshot)
View commit log:     ./scripts/gh.sh → Option 3 (Commit log)
Branch operations:   ./scripts/gh.sh → Option 9 (Branch manager)
Bulk cleanup:        ./scripts/gh.sh → Option 10 (Cleanup claude/* remotes)
Create PR:           ./scripts/gh.sh → Option 12 (Create pull request)
View Actions:        ./scripts/gh.sh → Option 15 (Check Actions status)
Configure:           ./scripts/gh.sh → Option 17-18 (Git config, PR template)
Install gh CLI:      ./scripts/gh.sh → Option 19 (Install GitHub CLI)

EOF

    echo ""
    read -p "Press Enter to return to main menu..."
}

generate_pr_command() {
    header "Generate GitHub PR Command"

    local current_branch=$(get_current_branch)

    if [[ "$current_branch" == "$TARGET_BRANCH" ]]; then
        error "You are on $TARGET_BRANCH. Switch to a feature branch first."
        echo ""
        echo "Run: git checkout <branch-name>"
        return
    fi

    echo "Current branch: $current_branch"
    echo ""

    # Get commit summary
    local commits=$(git log origin/main..HEAD --oneline 2>/dev/null | head -10)
    local commit_count=$(git log origin/main..HEAD --oneline 2>/dev/null | wc -l)

    if [[ $commit_count -eq 0 ]]; then
        warn "No commits ahead of main on current branch"
        echo ""
        echo "This means:"
        echo "  • Branch is up to date with main, or"
        echo "  • Changes haven't been committed yet"
        echo ""
        echo "Try:"
        echo "  1. Make sure you committed your changes"
        echo "  2. Check: git log origin/main..HEAD"
        return
    fi

    echo "Commits to include ($commit_count):"
    echo "$commits"
    echo ""

    read -p "PR title (or press Enter for auto): " pr_title
    if [[ -z "$pr_title" ]]; then
        pr_title="Merge $current_branch into main"
    fi

    # Check for PR template
    local pr_template=""
    local template_file=""
    if [[ -f ".github/pull_request_template.md" ]]; then
        template_file=".github/pull_request_template.md"
        info "PR template found: $template_file"
    elif [[ -f ".github/PULL_REQUEST_TEMPLATE.md" ]]; then
        template_file=".github/PULL_REQUEST_TEMPLATE.md"
        info "PR template found: $template_file"
    fi

    echo ""
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}Copy and run this command in your terminal:${NC}"
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}gh pr create \\"
    echo "  --base main \\"
    echo "  --head $current_branch \\"
    echo "  --title \"$pr_title\" \\"
    echo "  --body \"\$(cat <<'PRBODY'"

    # If template exists, use it and populate sections
    if [[ -n "$template_file" ]]; then
        # Read template and populate known sections
        while IFS= read -r line; do
            # Replace placeholders with actual data
            if [[ "$line" =~ "## Summary" ]] || [[ "$line" =~ "## Description" ]]; then
                echo "$line"
                echo ""
                echo "Automated PR from gh.sh script - $commit_count commits from $current_branch"
            elif [[ "$line" =~ "## Changes" ]] || [[ "$line" =~ "## What changed" ]]; then
                echo "$line"
                echo ""
                echo "### Commits ($commit_count)"
                git log origin/main..HEAD --oneline | sed 's/^/- /'
                echo ""
                echo "### Files Changed"
                git diff --name-status origin/main..HEAD | head -20 | while IFS=$'\t' read -r status file rest; do
                    case "$status" in
                        A) echo "- ✅ Added: $file" ;;
                        D) echo "- ❌ Deleted: $file" ;;
                        M) echo "- 📝 Modified: $file" ;;
                        *) echo "- $status: $file" ;;
                    esac
                done
            elif [[ "$line" =~ "## Testing" ]] || [[ "$line" =~ "## Test Plan" ]]; then
                echo "$line"
                echo ""
                # Look for test file changes
                local test_files=$(git diff --name-status origin/main..HEAD | grep -E '(test|spec)' | wc -l)
                if [[ $test_files -gt 0 ]]; then
                    echo "- ✅ $test_files test file(s) added/modified"
                else
                    echo "- ⚠️ No test files in this PR (add if needed)"
                fi
            else
                echo "$line"
            fi
        done < "$template_file"
    else
        # No template - use basic format
        echo "## Summary"
        echo "Automated PR from gh.sh script"
        echo ""
        echo "## Commits ($commit_count)"
        git log origin/main..HEAD --oneline | sed 's/^/- /'
        echo ""
        echo "## Files Changed"
        git diff --name-status origin/main..HEAD | head -20 | while IFS=$'\t' read -r status file rest; do
            case "$status" in
                A) echo "- ✅ Added: $file" ;;
                D) echo "- ❌ Deleted: $file" ;;
                M) echo "- 📝 Modified: $file" ;;
                *) echo "- $status: $file" ;;
            esac
        done
        echo ""
        echo "## Testing"
        echo ""
        echo "- [ ] Tests added/updated"
        echo "- [ ] All tests passing"
        echo "- [ ] No breaking changes"
    fi

    echo "PRBODY"
    echo ")\""
    echo -e "${NC}"
    echo ""

    # Store the command for potential execution
    local pr_body_file="/tmp/gh_pr_body_$$.md"

    # Generate PR body to temp file
    if [[ -n "$template_file" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ "## Summary" ]] || [[ "$line" =~ "## Description" ]]; then
                echo "$line"
                echo ""
                echo "Automated PR from gh.sh script - $commit_count commits from $current_branch"
            elif [[ "$line" =~ "## Changes" ]] || [[ "$line" =~ "## What changed" ]]; then
                echo "$line"
                echo ""
                echo "### Commits ($commit_count)"
                git log origin/main..HEAD --oneline | sed 's/^/- /'
                echo ""
                echo "### Files Changed"
                git diff --name-status origin/main..HEAD | head -20 | while IFS=$'\t' read -r status file rest; do
                    case "$status" in
                        A) echo "- ✅ Added: $file" ;;
                        D) echo "- ❌ Deleted: $file" ;;
                        M) echo "- 📝 Modified: $file" ;;
                        *) echo "- $status: $file" ;;
                    esac
                done
            elif [[ "$line" =~ "## Testing" ]] || [[ "$line" =~ "## Test Plan" ]]; then
                echo "$line"
                echo ""
                local test_files=$(git diff --name-status origin/main..HEAD | grep -E '(test|spec)' | wc -l)
                if [[ $test_files -gt 0 ]]; then
                    echo "- ✅ $test_files test file(s) added/modified"
                else
                    echo "- ⚠️ No test files in this PR (add if needed)"
                fi
            else
                echo "$line"
            fi
        done < "$template_file" > "$pr_body_file"
    else
        cat > "$pr_body_file" << PRBODY
## Summary
Automated PR from gh.sh script

## Commits ($commit_count)
$(git log origin/main..HEAD --oneline | sed 's/^/- /')

## Files Changed
$(git diff --name-status origin/main..HEAD | head -20 | while IFS=$'\t' read -r status file rest; do
    case "$status" in
        A) echo "- ✅ Added: $file" ;;
        D) echo "- ❌ Deleted: $file" ;;
        M) echo "- 📝 Modified: $file" ;;
        *) echo "- $status: $file" ;;
    esac
done)

## Testing
- [ ] Tests added/updated
- [ ] All tests passing
- [ ] No breaking changes
PRBODY
    fi

    echo ""
    echo -e "${BOLD}What would you like to do?${NC}"
    echo ""
    echo "  1) Create PR now (execute with gh CLI)"
    echo "  2) Just show command (copy manually)"
    echo "  3) Cancel"
    echo ""
    read -p "Select [1-3]: " choice

    case "$choice" in
        1)
            echo ""
            log "Creating pull request..."

            if gh pr create \
                --base main \
                --head "$current_branch" \
                --title "$pr_title" \
                --body-file "$pr_body_file" \
                --web; then

                rm -f "$pr_body_file"
                success "Pull request created successfully!"
                echo ""

                # Get PR number
                local pr_number=$(gh pr list --head "$current_branch" --json number --jq '.[0].number')
                if [[ -n "$pr_number" ]]; then
                    echo -e "${BOLD}PR #$pr_number created${NC}"
                    echo ""
                    echo "Next steps:"
                    echo "  • PR opened in browser for review"
                    echo "  • Merge via: gh pr merge $pr_number --merge"
                    echo "  • Or use GitHub web UI"
                fi
            else
                error "Failed to create pull request"
                warn "Try running the command manually (option 2)"
            fi
            ;;
        2)
            echo ""
            info "Command ready to copy"
            ;;
        3)
            rm -f "$pr_body_file"
            warn "PR creation cancelled"
            return
            ;;
        *)
            rm -f "$pr_body_file"
            error "Invalid choice"
            return
            ;;
    esac

    rm -f "$pr_body_file"

    # Offer to create PR template if missing
    if [[ -z "$template_file" ]]; then
        echo ""
        echo -e "${GRAY}💡 Tip: Create a PR template to standardize descriptions${NC}"
        echo -e "${GRAY}   Run option 18 to create .github/pull_request_template.md${NC}"
    fi
}

check_github_actions() {
    check_git_repo
    header "GitHub Actions Status"

    info "Fetching GitHub Actions status..."
    echo ""

    # Get current branch or main
    local current_branch=$(get_current_branch)
    local check_branch="${1:-$current_branch}"

    echo "Checking branch: $check_branch"
    echo ""

    # List recent workflow runs
    echo -e "${BOLD}Recent Workflow Runs:${NC}"
    gh run list --branch "$check_branch" --limit 10 2>/dev/null || {
        error "Failed to fetch workflow runs"
        echo ""
        echo "This requires:"
        echo "  1. gh CLI installed: https://cli.github.com/"
        echo "  2. Authentication: gh auth login"
        echo "  3. Run this command yourself: gh run list --branch $check_branch"
        return 1
    }

    echo ""
    read -p "Enter run ID to view details (or press Enter to skip): " run_id

    if [[ -n "$run_id" ]]; then
        echo ""
        header "Workflow Run Details: #$run_id"

        # Show run details
        gh run view "$run_id" 2>/dev/null || {
            error "Failed to fetch run details for #$run_id"
            return 1
        }

        echo ""
        echo -e "${BOLD}Jobs:${NC}"
        gh run view "$run_id" --log-failed 2>/dev/null || true

        echo ""
        if confirm "View full logs?"; then
            log "Fetching logs for run #$run_id..."
            local temp_log="/tmp/gh-run-$run_id.log"

            if gh run view "$run_id" --log > "$temp_log" 2>&1; then
                success "Logs saved to $temp_log"
                echo ""
                info "Opening logs in micro editor..."
                echo -e "${GRAY}(Press Ctrl+Q to exit micro)${NC}"
                sleep 1

                # Open in micro editor
                if command -v micro >/dev/null 2>&1; then
                    micro "$temp_log"
                else
                    warn "micro editor not found, displaying logs with less"
                    less "$temp_log"
                fi

                # Offer to keep or delete log file
                echo ""
                if ! confirm "Keep log file at $temp_log?"; then
                    rm -f "$temp_log"
                    success "Log file deleted"
                else
                    info "Log file saved at: $temp_log"
                fi
            else
                error "Failed to fetch logs"
                rm -f "$temp_log"
            fi
        fi
    fi

    echo ""
    echo -e "${YELLOW}To manually check Actions:${NC}"
    echo -e "${CYAN}gh run list${NC}                    # List recent runs"
    echo -e "${CYAN}gh run view <run-id>${NC}           # View run details"
    echo -e "${CYAN}gh run view <run-id> --log${NC}     # View full logs"
    echo -e "${CYAN}gh run rerun <run-id>${NC}          # Rerun failed workflow"
}

check_actions_last_5_commits() {
    check_git_repo
    header "GitHub Actions Failures - Recent Runs"

    info "Fetching recent workflow runs..."
    echo ""

    local has_failures=false
    local failure_count=0
    local failure_summary=""

    # Get recent workflow runs (last 50) and filter for failures
    local recent_runs
    recent_runs=$(gh run list --limit 50 --json status,conclusion,name,workflowName,number,createdAt,headBranch --jq '.[] | select(.conclusion=="failure")' 2>/dev/null)

    if [[ -z "$recent_runs" ]]; then
        echo -e "${GREEN}✓ No workflow failures detected in recent runs${NC}"
        echo ""
        return 0
    fi

    # Parse and display failures
    echo -e "${BOLD}${RED}FAILURES DETECTED:${NC}"
    echo ""

    while IFS= read -r run_json; do
        if [[ -z "$run_json" ]]; then
            continue
        fi

        # Extract fields from JSON
        local workflow_name=$(echo "$run_json" | jq -r '.workflowName // .name' 2>/dev/null)
        local run_name=$(echo "$run_json" | jq -r '.name' 2>/dev/null)
        local run_number=$(echo "$run_json" | jq -r '.number' 2>/dev/null)
        local created_at=$(echo "$run_json" | jq -r '.createdAt' 2>/dev/null)
        local branch=$(echo "$run_json" | jq -r '.headBranch' 2>/dev/null)
        local conclusion=$(echo "$run_json" | jq -r '.conclusion' 2>/dev/null)

        has_failures=true
        ((failure_count++))

        echo -e "${RED}✗${NC} ${BOLD}$workflow_name${NC} #$run_number"
        echo -e "  ${GRAY}Job: $run_name${NC}"
        echo -e "  ${GRAY}Branch: $branch | Status: $conclusion${NC}"
        echo -e "  ${GRAY}Time: $created_at${NC}"
        echo ""

        failure_summary+="• #$run_number: $workflow_name - $run_name\n"

    done <<< "$recent_runs"

    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════${NC}"
    echo ""

    if [[ "$has_failures" == "true" ]]; then
        echo -e "${RED}${BOLD}Summary: $failure_count workflow failure(s) found${NC}"
        echo ""
        echo -e "$failure_summary"
        echo ""
        echo -e "${YELLOW}Next Steps:${NC}"
        echo -e "  • ${CYAN}gh run view <number> --log${NC}     - View detailed logs for a run"
        echo -e "  • ${CYAN}gh run rerun <number>${NC}          - Rerun a failed workflow"
        echo -e "  • ${CYAN}gh run view <number>{{NC}}           - View run summary"
        echo -e "  • Option 15 in menu: Check specific run interactively"
    else
        echo -e "${GREEN}✓ No workflow failures detected${NC}"
    fi

    echo ""
    echo -e "${BOLD}Quick Reference:${NC}"
    echo -e "  ${CYAN}gh run list --limit 50{{NC}}         # List recent runs"
    echo -e "  ${CYAN}gh run view <number> --log{{NC}}     # View logs for a specific run"
    echo -e "  ${CYAN}gh run rerun <number>{{NC}}          # Rerun a failed workflow"
}

toggle_github_actions() {
    check_git_repo

    # Check if gh CLI is available
    if ! command -v gh >/dev/null 2>&1; then
        error "GitHub CLI (gh) is not installed"
        echo "Install it with: curl -fsSL https://cli.github.com/install.sh | bash"
        return 1
    fi

    header "Toggle GitHub Actions CI/CD"
    echo ""
    echo "This will enable or disable all GitHub Actions workflows"
    echo "to help manage CI/CD costs during development."
    echo ""

    # Get current workflow status
    echo "Fetching workflow status..."
    local workflows=$(gh workflow list --json name,path,state 2>/dev/null)

    if [[ -z "$workflows" ]]; then
        error "Could not fetch workflow status"
        return 1
    fi

    # Parse and display current status
    echo ""
    echo -e "${BOLD}Current Workflow Status:${NC}"
    echo ""

    local active_count=0
    local disabled_count=0

    while IFS= read -r line; do
        local name=$(echo "$line" | jq -r '.name')
        local path=$(echo "$line" | jq -r '.path')
        local state=$(echo "$line" | jq -r '.state')

        if [[ "$state" == "active" ]]; then
            echo -e "  ${GREEN}✓${NC} $name (active)"
            ((active_count++))
        else
            echo -e "  ${RED}✗${NC} $name (disabled)"
            ((disabled_count++))
        fi
    done < <(echo "$workflows" | jq -c '.[]')

    echo ""
    echo "Active: $active_count | Disabled: $disabled_count"
    echo ""

    # Offer toggle options
    echo "Options:"
    echo "  (1) Disable all workflows (skip CI on next commits)"
    echo "  (2) Enable all workflows (run CI on next commits)"
    echo "  (3) Disable specific workflow"
    echo "  (4) Enable specific workflow"
    echo "  (q) Cancel"
    echo ""

    read -p "Choose action: " toggle_choice

    case "$toggle_choice" in
        1)
            # Disable all workflows
            echo ""
            if confirm "Disable ALL workflows?"; then
                log "Disabling workflows..."
                echo "$workflows" | jq -r '.path' | while read -r path; do
                    if [[ -n "$path" ]]; then
                        local wf_name=$(basename "$path" | sed 's/\..*//')
                        if gh workflow disable "$path" 2>/dev/null; then
                            success "Disabled: $wf_name"
                        else
                            warn "Failed to disable: $wf_name"
                        fi
                    fi
                done
                echo ""
                success "All workflows disabled!"
                echo ""
                echo -e "${CYAN}💡 Tip:${NC} You can still use '${BOLD}[skip ci]${NC}' in commit messages"
                echo "         or re-enable workflows when ready to run CI."
            fi
            ;;
        2)
            # Enable all workflows
            echo ""
            if confirm "Enable ALL workflows?"; then
                log "Enabling workflows..."
                echo "$workflows" | jq -r '.path' | while read -r path; do
                    if [[ -n "$path" ]]; then
                        local wf_name=$(basename "$path" | sed 's/\..*//')
                        if gh workflow enable "$path" 2>/dev/null; then
                            success "Enabled: $wf_name"
                        else
                            warn "Failed to enable: $wf_name"
                        fi
                    fi
                done
                echo ""
                success "All workflows enabled!"
            fi
            ;;
        3)
            # Disable specific workflow
            echo ""
            echo "Available workflows:"
            echo ""

            local idx=1
            local workflows_array=()
            local workflows_paths=()

            while IFS= read -r line; do
                local name=$(echo "$line" | jq -r '.name')
                local path=$(echo "$line" | jq -r '.path')
                workflows_array+=("$name")
                workflows_paths+=("$path")
                echo -e "  ${CYAN}[$idx]${NC} $name"
                ((idx++))
            done < <(echo "$workflows" | jq -c '.[]')

            echo ""
            read -p "Select workflow number to disable: " wf_choice

            if [[ $wf_choice =~ ^[0-9]+$ ]] && [[ $wf_choice -ge 1 && $wf_choice -lt $idx ]]; then
                local selected_name="${workflows_array[$((wf_choice-1))]}"
                local selected_path="${workflows_paths[$((wf_choice-1))]}"
                if confirm "Disable workflow: $selected_name?"; then
                    if gh workflow disable "$selected_path" 2>/dev/null; then
                        success "Disabled: $selected_name"
                    else
                        error "Failed to disable: $selected_name"
                    fi
                fi
            else
                error "Invalid selection"
            fi
            ;;
        4)
            # Enable specific workflow
            echo ""
            echo "Available workflows:"
            echo ""

            local idx=1
            local workflows_array=()
            local workflows_paths=()

            while IFS= read -r line; do
                local name=$(echo "$line" | jq -r '.name')
                local path=$(echo "$line" | jq -r '.path')
                workflows_array+=("$name")
                workflows_paths+=("$path")
                echo -e "  ${CYAN}[$idx]${NC} $name"
                ((idx++))
            done < <(echo "$workflows" | jq -c '.[]')

            echo ""
            read -p "Select workflow number to enable: " wf_choice

            if [[ $wf_choice =~ ^[0-9]+$ ]] && [[ $wf_choice -ge 1 && $wf_choice -lt $idx ]]; then
                local selected_name="${workflows_array[$((wf_choice-1))]}"
                local selected_path="${workflows_paths[$((wf_choice-1))]}"
                if confirm "Enable workflow: $selected_name?"; then
                    if gh workflow enable "$selected_path" 2>/dev/null; then
                        success "Enabled: $selected_name"
                    else
                        error "Failed to enable: $selected_name"
                    fi
                fi
            else
                error "Invalid selection"
            fi
            ;;
        q)
            log "Cancelled"
            return 0
            ;;
        *)
            error "Invalid option"
            return 1
            ;;
    esac
}

manage_github_actions_workflows() {
    check_git_repo
    header "GitHub Actions Workflows"

    local git_root=$(git rev-parse --show-toplevel)
    local workflows_dir="$git_root/.github/workflows"

    if [[ ! -d "$workflows_dir" ]]; then
        error "No workflows directory found: .github/workflows"
        echo ""
        echo "Create workflows directory? This will:"
        echo "  1. Create .github/workflows/"
        echo "  2. You can then add workflow YAML files"
        if confirm "Create directory?"; then
            mkdir -p "$workflows_dir"
            success "Created .github/workflows"
        fi
        return
    fi

    while true; do
        echo ""
        echo -e "${BOLD}Workflow Files:${NC}"
        echo ""

        local workflow_files=()
        local idx=1

        while IFS= read -r file; do
            [[ -n "$file" ]] && {
                workflow_files+=("$file")
                echo -e "  ${CYAN}[$idx]${NC} $(basename "$file")"
                ((idx++))
            }
        done < <(find "$workflows_dir" -name "*.yml" -o -name "*.yaml" 2>/dev/null)

        if [[ ${#workflow_files[@]} -eq 0 ]]; then
            warn "No workflow files found in .github/workflows"
            echo ""
            echo "Add a new workflow file (e.g., ci.yml, deploy.yml)"
            return
        fi

        echo ""
        echo "Actions:"
        echo "  (v) View workflow file"
        echo "  (e) Edit workflow file"
        echo "  (n) Create new workflow"
        echo "  (s) Check workflow syntax"
        echo ""

        read -p "Select action: " action

        case "$action" in
            v|V)
                read -p "Enter workflow number to view: " num
                if [[ "$num" =~ ^[0-9]+$ ]]; then
                    local idx=$((num - 1))
                    if [[ $idx -ge 0 && $idx -lt ${#workflow_files[@]} ]]; then
                        local file="${workflow_files[$idx]}"
                        echo ""
                        header "Viewing: $(basename "$file")"
                        cat "$file"
                        echo ""
                        read -p "Press Enter to continue..."
                    else
                        error "Invalid selection"
                    fi
                fi
                ;;
            e|E)
                read -p "Enter workflow number to edit: " num
                if [[ "$num" =~ ^[0-9]+$ ]]; then
                    local idx=$((num - 1))
                    if [[ $idx -ge 0 && $idx -lt ${#workflow_files[@]} ]]; then
                        local file="${workflow_files[$idx]}"
                        echo ""
                        log "Opening $file in ${EDITOR:-micro}..."
                        ${EDITOR:-micro} "$file"
                        success "Edit complete"
                    else
                        error "Invalid selection"
                    fi
                fi
                ;;
            n|N)
                read -p "New workflow filename (e.g., ci.yml): " filename
                if [[ -n "$filename" ]]; then
                    if [[ ! "$filename" =~ \.(yml|yaml)$ ]]; then
                        filename="${filename}.yml"
                    fi
                    local new_file="$workflows_dir/$filename"
                    if [[ -f "$new_file" ]]; then
                        error "File already exists: $new_file"
                    else
                        cat > "$new_file" << 'WORKFLOW'
name: New Workflow
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run a one-line script
        run: echo Hello, world!
WORKFLOW
                        success "Created template: $new_file"
                        echo ""
                        if confirm "Edit now?"; then
                            ${EDITOR:-micro} "$new_file"
                        fi
                    fi
                fi
                ;;
            s|S)
                echo ""
                log "Checking workflow syntax..."
                for file in "${workflow_files[@]}"; do
                    echo ""
                    echo "Checking: $(basename "$file")"
                    # Basic YAML syntax check
                    if command -v yamllint >/dev/null 2>&1; then
                        yamllint "$file" || warn "Syntax issues found"
                    else
                        # Basic check - just try to parse
                        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
                            success "Syntax OK"
                        else
                            error "Syntax errors detected"
                        fi
                    fi
                done
                read -p "Press Enter to continue..."
                ;;
            q|Q|*)
                # q or any other key returns to main menu
                return
                ;;
        esac
    done
}

github_healthcheck() {
    check_git_repo
    header "Git / GitHub Healthcheck - bloom"

    echo -e "${BOLD}1) Branch & working tree status${NC}"
    git status -sb || warn "Unable to read git status"
    echo ""

    echo -e "${BOLD}2) Remotes${NC}"
    git remote -v || echo "No remotes configured"
    echo ""

    echo -e "${BOLD}3) Sync state vs origin/main${NC}"
    if ! git fetch origin >/dev/null 2>&1; then
        warn "Unable to fetch origin"
    fi
    local local_head=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    local remote_head=$(git rev-parse --short origin/main 2>/dev/null || echo "unknown")
    echo "Local : $local_head (HEAD)"
    echo "Remote: $remote_head (origin/main)"
    echo ""

    echo -e "${BOLD}4) Unpushed commits on current branch${NC}"
    local unpushed
    unpushed=$(git log --oneline origin/main..HEAD 2>/dev/null || true)
    if [[ -n "$unpushed" ]]; then
        echo "$unpushed"
    else
        echo "None"
    fi
    echo ""

    echo -e "${BOLD}5) Local branches not merged into main${NC}"
    local unmerged
    unmerged=$(git branch -vv --no-merged main 2>/dev/null || true)
    if [[ -n "${unmerged//[[:space:]]/}" ]]; then
        echo "$unmerged"
    else
        echo "None"
    fi
    echo ""

    echo -e "${BOLD}6) Git stashes${NC}"
    local stashes
    stashes=$(git stash list 2>/dev/null || true)
    if [[ -n "$stashes" ]]; then
        echo "$stashes"
    else
        echo "None"
    fi
    echo ""

    echo -e "${BOLD}7) Recent commits on main (last 15)${NC}"
    if ! git log --oneline main -n 15 2>/dev/null; then
        git log --oneline -n 15 || echo "No commits available"
    fi
    echo ""

    echo -e "${BOLD}8) Large tracked files (>5 MB)${NC}"
    local large_output
    large_output=$(git ls-files | python3 - <<'PY'
import os, sys
files = []
for line in sys.stdin:
    path = line.strip()
    if not path or not os.path.isfile(path):
        continue
    size = os.path.getsize(path)
    if size > 5 * 1024 * 1024:
        files.append((size, path))
files.sort(reverse=True)
for size, path in files:
    print(f"{size/1048576:8.2f} MB  {path}")
PY
)
    if [[ -n "$large_output" ]]; then
        echo "$large_output"
    else
        echo "(Empty list is good.)"
    fi
    echo ""

    echo -e "${BOLD}9) Git config (user.* and core settings)${NC}"
    git config user.name  && git config user.email  || true
    git config core.autocrlf || true
    echo ""

    echo -e "${BOLD}10) GitHub Actions workflows detected${NC}"
    if [[ -d ".github/workflows" ]]; then
        ls .github/workflows
    else
        echo "No workflows found (.github/workflows is missing)"
    fi
    echo ""

    echo -e "${BOLD}11) Dependabot config${NC}"
    if [[ -f ".github/dependabot.yml" ]]; then
        sed -n '1,80p' .github/dependabot.yml
    else
        echo "No .github/dependabot.yml found."
    fi

    echo ""
    echo -e "${BOLD}Healthcheck complete${NC}"
}

show_github_cli_reference() {
    header "GitHub CLI Quick Reference"

    cat << 'EOF'
📋 COMMANDS YOU CAN RUN (outside Claude Code):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔀 PULL REQUESTS

# Create Pull Request
gh pr create --base main --head <branch> --title "Title" --body "Description"

# Quick PR with current branch
gh pr create --fill  # Auto-fills from commits

# List Pull Requests
gh pr list
gh pr list --state all  # Include closed PRs

# View PR details
gh pr view <number>
gh pr view <number> --web  # Open in browser

# Merge Pull Request
gh pr merge <number> --merge     # Regular merge
gh pr merge <number> --squash    # Squash commits
gh pr merge <number> --rebase    # Rebase and merge

# Check PR status
gh pr status

# Review PRs
gh pr review <number> --approve
gh pr review <number> --comment --body "LGTM!"
gh pr review <number> --request-changes --body "Needs fixes"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 REPOSITORY OPERATIONS

# Clone repo
gh repo clone <owner>/<repo>

# View repo
gh repo view
gh repo view --web

# Fork repo
gh repo fork

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌿 BRANCH OPERATIONS (These work in Claude Code too!)

# Fetch changes
git fetch origin

# Pull from main
git pull origin main

# Checkout branch
git checkout <branch>

# Merge branch
git merge <branch>

# Push to feature branch ✅
git push origin claude/*

# Push to main ❌ (Use PR workflow instead!)
git push origin main  # 403 error with branch protection

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔗 WEB UI SHORTCUTS

Create PR:  https://github.com/[user]/[repo]/compare/main...[branch]
View PRs:   https://github.com/[user]/[repo]/pulls
Settings:   https://github.com/[user]/[repo]/settings/branches
Actions:    https://github.com/[user]/[repo]/actions
Branches:   https://github.com/[user]/[repo]/branches

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 TIPS

1. Install gh CLI: https://cli.github.com/
2. Authenticate: gh auth login
3. Check auth status: gh auth status
4. Use tab completion: gh completion -s bash >> ~/.bashrc

EOF

    echo ""
    read -p "Press Enter to return to main menu..."
}

########################
# Local Workflow Helpers (from gh.sh)
########################

check_git_status() {
    [[ -z $(git status -s) ]]
}

show_git_status() {
    header "Current Git Status"

    git status -s || true
    echo ""

    if check_git_status; then
        success "Working directory is clean"
    else
        warn "Working directory has uncommitted changes"
    fi

    echo ""
    echo "Current branch: $(get_current_branch)"
    echo "Last commit: $(git log -1 --oneline)"
}

commit_changes() {
    header "Commit Changes"

    if check_git_status; then
        warn "No changes to commit"
        return
    fi

    echo "Changes to be committed:"
    git status -s
    echo ""

    if ! confirm "Stage all listed files and create a commit?"; then
        warn "Commit cancelled"
        return
    fi

    read -p "Commit message: " commit_msg
    if [[ -z "$commit_msg" ]]; then
        error "Commit message cannot be empty"
        return
    fi

    git add .
    git commit -m "$commit_msg"
    success "Changes committed successfully"
}

commit_wip() {
    header "Quick WIP Commit"

    if check_git_status; then
        warn "No changes to commit"
        return
    fi

    echo "Files that will be captured in the WIP commit:"
    git status -s
    echo ""

    if ! confirm "Create a WIP commit with all files above?"; then
        warn "WIP commit cancelled"
        return
    fi

    git add .
    git commit -m "WIP: saving current changes"
    success "WIP commit created"
}

stash_changes() {
    header "Stash Changes"

    if check_git_status; then
        warn "No changes to stash"
        return
    fi

    echo "Changes to be stashed:"
    git status -s
    echo ""

    if ! confirm "Move all listed changes into a stash?"; then
        warn "Stash cancelled"
        return
    fi

    read -p "Stash description (optional): " stash_msg

    if [[ -z "$stash_msg" ]]; then
        git stash
    else
        git stash push -m "$stash_msg"
    fi

    success "Changes stashed successfully"
    echo "Use 'Restore stashed changes' to bring them back."
}

stash_quick() {
    header "Quick Stash"

    if check_git_status; then
        warn "No changes to stash"
        return
    fi

    echo "Changes that will be stored in the quick stash:"
    git status -s
    echo ""

    if ! confirm "Create a quick stash with the files above?"; then
        warn "Quick stash cancelled"
        return
    fi

    git stash push -m "Quick stash @ $(date '+%Y-%m-%d %H:%M:%S')"
    success "Changes stashed with timestamp"
}

list_stashes() {
    header "Stashed Changes"

    if [[ -z $(git stash list) ]]; then
        warn "No stashes found"
        return
    fi

    git stash list
    echo ""

    read -p "Enter stash number to view details (or press Enter to skip): " stash_num
    if [[ -n "$stash_num" ]]; then
        echo ""
        git stash show -p "stash@{$stash_num}"
    fi
}

restore_stash() {
    header "Restore Stashed Changes"

    if [[ -z $(git stash list) ]]; then
        error "No stashes found"
        return
    fi

    git stash list
    echo ""

    read -p "Enter stash number to restore (or press Enter for latest): " stash_num

    if [[ -z "$stash_num" ]]; then
        git stash pop
        success "Latest stash restored and removed"
    else
        read -p "Keep stash after restoring? (y/n): " keep_stash
        if [[ "$keep_stash" == "y" ]]; then
            git stash apply "stash@{$stash_num}"
            success "Stash restored (stash kept)"
        else
            git stash pop "stash@{$stash_num}"
            success "Stash restored and removed"
        fi
    fi
}

discard_changes() {
    header "Discard ALL Changes - DANGEROUS"

    if check_git_status; then
        warn "No changes to discard"
        return
    fi

    echo -e "${RED}WARNING: This will permanently delete ALL uncommitted changes!${NC}"
    echo ""
    echo "Changes that will be discarded:"
    git status -s
    echo ""

    read -p "Type 'yes' to confirm: " confirm_str
    if [[ "$confirm_str" != "yes" ]]; then
        warn "Discard cancelled"
        return
    fi

    git restore .

    read -p "Also remove untracked files? (y/n): " remove_untracked
    if [[ "$remove_untracked" == "y" ]]; then
        git clean -fd
        success "All changes discarded and untracked files removed"
    else
        success "Modified files restored (untracked files kept)"
    fi
}

discard_file() {
    header "Discard Changes in Specific File"

    if check_git_status; then
        warn "No changes to discard"
        return
    fi

    echo "Modified files:"
    git status -s
    echo ""

    read -p "Enter file path to discard: " file_path

    if [[ -z "$file_path" ]]; then
        error "File path cannot be empty"
        return
    fi

    if [[ ! -f "$file_path" ]]; then
        error "File not found: $file_path"
        return
    fi

    echo ""
    echo "Preview of changes that will be discarded in '${file_path}':"
    git status -s -- "$file_path" || true
    git diff -- "$file_path" || true
    echo ""

    if ! confirm "Discard the changes shown above?"; then
        warn "Discard cancelled"
        return
    fi

    git restore "$file_path"
    success "Changes discarded in: $file_path"
}

remove_untracked() {
    header "Remove Untracked Files"

    local preview
    preview=$(git clean -nd)

    if [[ -z "$preview" ]]; then
        warn "No untracked files found"
        return
    fi

    echo "Untracked files/directories that would be removed:"
    echo "$preview"
    echo ""

    if ! confirm "Permanently remove everything listed above?"; then
        warn "Operation cancelled"
        return
    fi

    git clean -fd
    success "Untracked files removed"
}

view_diff() {
    header "View Changes (Diff)"

    if check_git_status; then
        warn "No changes to view"
        return
    fi

    echo "1) View unstaged changes"
    echo "2) View staged changes"
    echo "3) View all changes (vs HEAD)"
    read -p "Select option: " diff_option

    case $diff_option in
        1) git diff ;;
        2) git diff --staged ;;
        3) git diff HEAD ;;
        *) error "Invalid option" ;;
    esac
}

check_clean() {
    header "Check if Working Tree is Clean"

    if check_git_status; then
        success "Working directory is CLEAN"
    else
        warn "Working directory is DIRTY"
        echo ""
        echo "Fix with one of:"
        echo "  2) Commit changes"
        echo "  4) Stash changes"
        echo "  8) Discard changes (careful!)"
    fi
}

show_branches() {
    header "Git Branches"

    echo "Local branches:"
    git branch -v
    echo ""

    read -p "Show remote branches? (y/n): " show_remote
    if [[ "$show_remote" == "y" ]]; then
        echo ""
        echo "Remote branches:"
        git branch -r
    fi
}

recent_commits() {
    header "Recent Commits"

    read -p "Number of commits to show (default: 10): " num_commits
    num_commits=${num_commits:-10}

    git log -n "$num_commits" --oneline --graph --decorate
}

########################
# Consolidated Functions (Menu Simplification)
########################

commit_changes_unified() {
    header "Commit Changes"

    if check_git_status; then
        warn "No changes to commit"
        return
    fi

    echo "Changes to be committed:"
    git status -s
    echo ""

    if ! confirm "Stage all listed files and create a commit?"; then
        warn "Commit cancelled"
        return
    fi

    read -p "Commit message (or type 'wip' for quick WIP commit): " commit_msg

    if [[ -z "$commit_msg" ]]; then
        error "Commit message cannot be empty"
        return
    fi

    git add .

    if [[ "$commit_msg" == "wip" || "$commit_msg" == "WIP" ]]; then
        git commit -m "WIP: saving current changes"
        success "WIP commit created"
    else
        git commit -m "$commit_msg"
        success "Changes committed successfully"
    fi
}

stash_changes_unified() {
    header "Stash Changes"

    if check_git_status; then
        warn "No changes to stash"
        return
    fi

    echo "Changes to be stashed:"
    git status -s
    echo ""

    if ! confirm "Stash all listed changes?"; then
        warn "Stash cancelled"
        return
    fi

    read -p "Stash message (or press Enter for quick stash with timestamp): " stash_msg

    if [[ -z "$stash_msg" ]]; then
        git stash push -m "Quick stash @ $(date '+%Y-%m-%d %H:%M:%S')"
        success "Changes stashed with timestamp"
    else
        git stash push -m "$stash_msg"
        success "Changes stashed successfully"
    fi
}

manage_stashes_unified() {
    header "Manage Stashes"

    if [[ -z $(git stash list) ]]; then
        warn "No stashes found"
        return
    fi

    while true; do
        echo ""
        git stash list
        echo ""
        echo "Actions:"
        echo "  (v) View stash details"
        echo "  (r) Restore stash"
        echo "  (d) Delete stash"
        echo ""

        read -p "Select action: " action

        case "$action" in
            v|V)
                read -p "Enter stash number to view: " stash_num
                if [[ -n "$stash_num" ]]; then
                    echo ""
                    git stash show -p "stash@{$stash_num}" 2>/dev/null || error "Invalid stash number"
                fi
                ;;
            r|R)
                read -p "Enter stash number to restore (or press Enter for latest): " stash_num
                if [[ -z "$stash_num" ]]; then
                    git stash pop
                    success "Latest stash restored and removed"
                else
                    read -p "Keep stash after restoring? (y/n): " keep_stash
                    if [[ "$keep_stash" == "y" ]]; then
                        git stash apply "stash@{$stash_num}"
                        success "Stash restored (stash kept)"
                    else
                        git stash pop "stash@{$stash_num}"
                        success "Stash restored and removed"
                    fi
                fi
                ;;
            d|D)
                read -p "Enter stash number to delete: " stash_num
                if [[ -n "$stash_num" ]]; then
                    if confirm "Delete stash@{$stash_num}?"; then
                        git stash drop "stash@{$stash_num}"
                        success "Stash deleted"
                    fi
                fi
                ;;
            *)
                # Any other key returns to main menu
                return
                ;;
        esac
    done
}

discard_changes_unified() {
    header "Discard Changes"

    if check_git_status; then
        warn "No changes to discard"
        return
    fi

    echo "Current changes:"
    git status -s
    echo ""
    echo "Discard options:"
    echo "  (a) All changes - Reset tracked files to HEAD"
    echo "  (f) Specific file - Choose one file to revert"
    echo "  (u) Untracked files - Remove untracked files/directories"
    echo "  (q) Cancel"
    echo ""

    read -p "Select option: " option

    case "$option" in
        a|A)
            echo ""
            echo -e "${RED}WARNING: This will permanently delete ALL uncommitted changes!${NC}"
            echo ""
            echo "Changes that will be discarded:"
            git status -s
            echo ""
            read -p "Type 'yes' to confirm: " confirm_str
            if [[ "$confirm_str" != "yes" ]]; then
                warn "Discard cancelled"
                return
            fi
            git restore .
            read -p "Also remove untracked files? (y/n): " remove_untracked
            if [[ "$remove_untracked" == "y" ]]; then
                git clean -fd
                success "All changes discarded and untracked files removed"
            else
                success "Modified files restored (untracked files kept)"
            fi
            ;;
        f|F)
            echo ""
            echo "Modified files:"
            git status -s
            echo ""
            read -p "Enter file path to discard: " file_path
            if [[ -z "$file_path" ]]; then
                error "File path cannot be empty"
                return
            fi
            if [[ ! -f "$file_path" ]]; then
                error "File not found: $file_path"
                return
            fi
            echo ""
            echo "Preview of changes that will be discarded in '${file_path}':"
            git diff -- "$file_path" || true
            echo ""
            if ! confirm "Discard the changes shown above?"; then
                warn "Discard cancelled"
                return
            fi
            git restore "$file_path"
            success "Changes discarded in: $file_path"
            ;;
        u|U)
            local preview
            preview=$(git clean -nd)
            if [[ -z "$preview" ]]; then
                warn "No untracked files found"
                return
            fi
            echo ""
            echo "Untracked files/directories that would be removed:"
            echo "$preview"
            echo ""
            if ! confirm "Permanently remove everything listed above?"; then
                warn "Operation cancelled"
                return
            fi
            git clean -fd
            success "Untracked files removed"
            ;;
        q|Q)
            warn "Operation cancelled"
            return
            ;;
        *)
            error "Invalid option"
            ;;
    esac
}

branch_manager_unified() {
    check_git_repo
    header "Branch Manager"

    fetch_origin

    while true; do
        echo ""
        local current_branch=$(get_current_branch)

        # Collect all branches (local and remote)
        local all_branches=()
        local branch_info=()

        # Add current branch first
        all_branches+=("$current_branch")
        branch_info+=("current")

        # Add other local branches
        while IFS= read -r branch; do
            [[ -n "$branch" && "$branch" != "$current_branch" ]] && {
                all_branches+=("$branch")
                branch_info+=("local")
            }
        done < <(git branch | sed 's/^[* ]*//' | sed 's/^[[:space:]]*//')

        # Add remote branches
        while IFS= read -r branch; do
            [[ -n "$branch" ]] && {
                all_branches+=("$branch")
                branch_info+=("remote")
            }
        done < <(git branch -r | grep -v "origin/HEAD" | sed 's/^[[:space:]]*origin\///' | sed 's/[[:space:]]*$//')

        # Display branches
        echo -e "${BOLD}Available Branches:${NC}"
        echo ""
        local idx=1
        for i in "${!all_branches[@]}"; do
            local branch="${all_branches[$i]}"
            local info="${branch_info[$i]}"
            local display_branch="$branch"

            if [[ "$info" == "current" ]]; then
                echo -e "  ${GREEN}[${idx}]${NC} ${GREEN}${branch}${NC} (current)"
            elif [[ "$info" == "remote" ]]; then
                local ahead behind
                ahead=$(git rev-list --count "$TARGET_BRANCH".."origin/$branch" 2>/dev/null || echo "0")
                behind=$(git rev-list --count "origin/$branch".."$TARGET_BRANCH" 2>/dev/null || echo "0")
                echo -e "  ${CYAN}[${idx}]${NC} ${CYAN}origin/${branch}${NC} - ${GREEN}↑$ahead${NC} ahead, ${YELLOW}↓$behind${NC} behind"
            else
                echo -e "  ${BLUE}[${idx}]${NC} ${BLUE}${branch}${NC} (local)"
            fi
            ((idx++))
        done

        echo ""
        echo -e "${BOLD}Select branch [1-$((${#all_branches[@]}))]:${NC}"
        read -p "> " selection

        # Exit on any non-number input
        if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
            return
        fi

        local idx=$((selection - 1))
        if [[ $idx -lt 0 || $idx -ge ${#all_branches[@]} ]]; then
            error "Invalid selection: $selection (valid range: 1-${#all_branches[@]})"
            continue
        fi

        local selected_branch="${all_branches[$idx]}"
        local selected_info="${branch_info[$idx]}"

        # Show branch actions menu
        echo ""
        echo -e "${BOLD}Branch: ${CYAN}${selected_branch}${NC}"
        echo ""
        echo "Actions:"
        echo "  (m) Merge to $TARGET_BRANCH"
        echo "  (i) Show detailed info"

        if [[ "$selected_info" == "local" ]]; then
            echo "  (d) Delete local branch"
        elif [[ "$selected_info" == "remote" ]]; then
            echo "  (D) Delete remote branch"
        fi

        echo "  (b) Back to branch list"
        echo ""

        read -p "Select action: " branch_action

        case "$branch_action" in
            m|M)
                if [[ "$selected_info" == "remote" ]]; then
                    merge_branch_workflow "$selected_branch"
                else
                    echo ""
                    log "Merging local branch $selected_branch into $TARGET_BRANCH..."
                    git checkout "$TARGET_BRANCH"
                    git merge --no-ff "$selected_branch" -m "Merge branch '$selected_branch' into $TARGET_BRANCH"
                    success "Merge completed"
                fi
                ;;
            i|I)
                echo ""
                if [[ "$selected_info" == "remote" ]]; then
                    show_branch_comparison "$selected_branch"
                else
                    git log --oneline -10 "$selected_branch"
                fi
                read -p "Press Enter to continue..."
                ;;
            d|D)
                if [[ "$selected_info" == "local" && ("$branch_action" == "d" || "$branch_action" == "D") ]]; then
                    if confirm "Delete local branch '$selected_branch'?"; then
                        git branch -D "$selected_branch" 2>/dev/null || git branch -d "$selected_branch"
                        success "Local branch '$selected_branch' deleted"
                    fi
                elif [[ "$selected_info" == "remote" && "$branch_action" == "D" ]]; then
                    if confirm "Delete remote branch 'origin/$selected_branch'?"; then
                        git push origin --delete "$selected_branch"
                        success "Remote branch 'origin/$selected_branch' deleted"
                    fi
                fi
                ;;
            b|B)
                # Back to branch list
                continue
                ;;
            *)
                # Any other key exits to main menu
                return
                ;;
        esac
    done
}

########################
# Dashboard            #
########################

show_dashboard() {
    local current_branch
    current_branch=$(get_current_branch)

    # Collect metrics
    local status_summary=""
    local files_changed=0
    local ahead=0
    local behind=0
    local claude_branches=0
    local stash_count=0
    local actions_status="N/A"
    local open_prs="N/A"
    local git_config_status="N/A"
    local branch_protection="N/A"

    # Working tree status (no color codes in variables)
    if git diff --quiet && git diff --cached --quiet; then
        status_summary="Clean"
    else
        status_summary="Dirty"
        files_changed=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    fi

    # Ahead/behind tracking branch
    local tracking_info=$(git rev-list --left-right --count @{u}...HEAD 2>/dev/null || echo "0 0")
    behind=$(echo "$tracking_info" | awk '{print $1}')
    ahead=$(echo "$tracking_info" | awk '{print $2}')

    # Claude session branches
    local claude_count=$(git branch -a 2>/dev/null | grep 'claude/' | wc -l)
    claude_branches=${claude_count:-0}

    # Stash count
    stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

    # Git config check (pull.rebase and pull.ff)
    local pull_rebase=$(git config --get pull.rebase 2>/dev/null)
    local pull_ff=$(git config --get pull.ff 2>/dev/null)
    if [[ -n "$pull_rebase" && -n "$pull_ff" ]]; then
        git_config_status="✓ OK"
    else
        git_config_status="⚠ Missing"
    fi

    # Branch protection check (simple heuristic)
    if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
        # Try to detect protection via gh API (graceful fail)
        if command -v gh >/dev/null 2>&1; then
            local protected=$(gh api "repos/:owner/:repo/branches/$current_branch/protection" 2>/dev/null && echo "yes" || echo "no")
            if [[ "$protected" == "yes" ]]; then
                branch_protection="🔒 Protected"
            else
                branch_protection="🔓 Unprotected"
            fi
        else
            branch_protection="🔒 Likely"
        fi
    else
        branch_protection="🔓 No"
    fi

    # GitHub Actions (if gh CLI available - no color codes)
    if command -v gh >/dev/null 2>&1; then
        local latest_run=$(gh run list --limit 1 --json conclusion,status 2>/dev/null | grep -o '"conclusion":"[^"]*"' | cut -d'"' -f4)
        case "$latest_run" in
            success) actions_status="✓ Pass" ;;
            failure) actions_status="✗ Fail" ;;
            *) actions_status="Running" ;;
        esac

        open_prs=$(gh pr list --state open 2>/dev/null | wc -l | tr -d ' ')
    fi

    # Build recommendations (using array instead of string concatenation)
    local recommendations=()
    if [[ $files_changed -gt 0 ]]; then
        recommendations+=("• Uncommitted changes (option 5 or 6)")
    fi
    if [[ $ahead -gt 0 ]]; then
        recommendations+=("• $ahead unpushed commit(s)")
    fi
    if [[ $claude_branches -gt 3 ]]; then
        recommendations+=("• $claude_branches claude/* branches (consider cleanup: option 10)")
    fi
    if [[ "$actions_status" == *"Fail"* ]]; then
        recommendations+=("• GitHub Actions failing (check: option 15)")
    fi
    if [[ "$git_config_status" == *"Missing"* ]]; then
        recommendations+=("• Git config missing (run: git config pull.rebase false)")
    fi
    if [[ "$branch_protection" == *"Protected"* ]] && [[ $ahead -gt 0 ]]; then
        recommendations+=("• Branch protected - use option 12 to generate PR")
    fi

    # Display compact table (61 chars wide inside borders)
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} ${BOLD}Dashboard - Quick Overview${NC}                                 ${BLUE}│${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"

    printf "${BLUE}│${NC} %-25s ${BLUE}│${NC} %-31s ${BLUE}│${NC}\n" "Branch" "$current_branch"
    printf "${BLUE}│${NC} %-25s ${BLUE}│${NC} %-31s ${BLUE}│${NC}\n" "Branch Protection" "$branch_protection"
    printf "${BLUE}│${NC} %-25s ${BLUE}│${NC} %-31s ${BLUE}│${NC}\n" "Working Tree" "$status_summary ($files_changed files changed)"
    printf "${BLUE}│${NC} %-25s ${BLUE}│${NC} %-31s ${BLUE}│${NC}\n" "Commits Ahead/Behind" "$ahead ahead, $behind behind"
    printf "${BLUE}│${NC} %-25s ${BLUE}│${NC} %-31s ${BLUE}│${NC}\n" "Git Config" "$git_config_status"
    printf "${BLUE}│${NC} %-25s ${BLUE}│${NC} %-31s ${BLUE}│${NC}\n" "Claude Session Branches" "$claude_branches"
    printf "${BLUE}│${NC} %-25s ${BLUE}│${NC} %-31s ${BLUE}│${NC}\n" "Stashes" "$stash_count"
    printf "${BLUE}│${NC} %-25s ${BLUE}│${NC} %-31s ${BLUE}│${NC}\n" "GitHub Actions" "$actions_status"
    printf "${BLUE}│${NC} %-25s ${BLUE}│${NC} %-31s ${BLUE}│${NC}\n" "Open PRs" "$open_prs"

    if [[ ${#recommendations[@]} -gt 0 ]]; then
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│${NC} ${BOLD}Recommended Actions:${NC}                                       ${BLUE}│${NC}"
        echo -e "${BLUE}│${NC}                                                             ${BLUE}│${NC}"
        for line in "${recommendations[@]}"; do
            printf "${BLUE}│${NC}   %-57s ${BLUE}│${NC}\n" "$line"
        done
    fi

    echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

########################
# Configuration Helpers#
########################

setup_git_config() {
    header "Git Configuration Setup"

    info "Checking current Git configuration..."
    echo ""

    # Check current settings
    local pull_rebase=$(git config --get pull.rebase 2>/dev/null)
    local pull_ff=$(git config --get pull.ff 2>/dev/null)
    local merge_conflictstyle=$(git config --get merge.conflictstyle 2>/dev/null)

    echo -e "${BOLD}Current Configuration:${NC}"
    echo -e "  pull.rebase:              ${pull_rebase:-${YELLOW}not set${NC}}"
    echo -e "  pull.ff:                  ${pull_ff:-${YELLOW}not set${NC}}"
    echo -e "  merge.conflictstyle:      ${merge_conflictstyle:-${YELLOW}not set${NC}}"
    echo ""

    echo -e "${BOLD}Recommended Settings:${NC}"
    echo "  pull.rebase = false       (use merge strategy, preserves history)"
    echo "  pull.ff = false           (always create merge commit)"
    echo "  merge.conflictstyle = diff3  (3-way conflict markers)"
    echo ""

    # Generate setup script (relative to git root)
    local git_root=$(git rev-parse --show-toplevel)
    local config_file="$git_root/scripts/gh.config"
    cat > "$config_file" << 'GITCONFIG'
#!/bin/bash
# Git Configuration Setup
# Generated by gh.sh - Edit with: micro scripts/gh.config

# Pull Strategy (merge vs rebase)
# false = merge strategy (preserves all commits, creates merge commits)
# true = rebase strategy (linear history, rewrites commits)
git config pull.rebase false

# Fast-forward merges
# false = always create merge commit (recommended for tracking)
# only = only allow fast-forward merges
git config pull.ff false

# Conflict markers style
# diff3 = shows base, ours, and theirs (easier to resolve)
# merge = shows only ours and theirs (default)
git config merge.conflictstyle diff3

# Optional: Set default editor (already set globally by this script)
# git config core.editor "micro"

echo "✓ Git configuration complete"
echo ""
echo "Settings applied:"
git config --get pull.rebase | xargs -I {} echo "  pull.rebase = {}"
git config --get pull.ff | xargs -I {} echo "  pull.ff = {}"
git config --get merge.conflictstyle | xargs -I {} echo "  merge.conflictstyle = {}"
GITCONFIG

    chmod +x "$config_file"
    success "Created configuration script: scripts/gh.config"
    echo ""

    echo -e "${BOLD}Next Steps:${NC}"
    echo "  1. Review:  micro scripts/gh.config"
    echo "  2. Run:     bash scripts/gh.config"
    echo "  3. Verify:  git config --list | grep -E '(pull|merge)'"
    echo ""

    if confirm "Run configuration script now?"; then
        echo ""
        bash "$config_file"
        echo ""
        success "Git configuration applied!"
    else
        info "Configuration script saved. Run manually: bash scripts/gh.config"
    fi
}

create_pr_template() {
    header "Create Pull Request Template"

    local git_root=$(git rev-parse --show-toplevel)
    local template_dir="$git_root/.github"
    local template_file="$template_dir/pull_request_template.md"

    # Check if template already exists
    if [[ -f "$template_file" ]]; then
        warn "PR template already exists: .github/pull_request_template.md"
        echo ""
        if confirm "Edit existing template?"; then
            if prefer_micro_editor; then
                micro "$template_file"
            else
                warn "Falling back to nano editor (Ctrl+X to exit)"
                nano "$template_file"
            fi
        fi
        return
    fi

    # Create .github directory if needed
    if [[ ! -d "$template_dir" ]]; then
        log "Creating $template_dir directory..."
        mkdir -p "$template_dir"
    fi

    # Create template
    cat > "$template_file" << 'PRTEMPLATE'
## Summary
<!-- Provide a brief description of the changes in this PR -->


## Motivation
<!-- Why is this change needed? What problem does it solve? -->


## Changes
<!-- List the main changes made in this PR -->

-
-


## Testing
<!-- How were these changes tested? -->

- [ ] Tests added/updated
- [ ] All tests passing
- [ ] Manual testing completed


## Checklist
<!-- Mark completed items with [x] -->

- [ ] Code follows project style guidelines
- [ ] Documentation updated (if needed)
- [ ] No breaking changes (or documented in PR description)
- [ ] Reviewed my own code
- [ ] Added tests for new functionality


## Screenshots
<!-- If UI changes, add screenshots here -->


## Breaking Changes
<!-- List any breaking changes and migration steps -->

None

PRTEMPLATE

    success "Created PR template: .github/pull_request_template.md"
    echo ""

    echo -e "${BOLD}Template created with sections:${NC}"
    echo "  • Summary - Brief description"
    echo "  • Motivation - Why this change"
    echo "  • Changes - What changed"
    echo "  • Testing - How tested"
    echo "  • Checklist - Pre-merge requirements"
    echo "  • Screenshots - UI changes"
    echo "  • Breaking Changes - Migration notes"
    echo ""

    echo -e "${BOLD}Next Steps:${NC}"
    echo "  1. Edit template: micro .github/pull_request_template.md"
    echo "  2. Customize sections for your project"
    echo "  3. Option 12 will now use this template for PRs"
    echo ""

    if confirm "Edit template now?"; then
        if prefer_micro_editor; then
            micro "$template_file"
        else
            warn "Falling back to nano editor (Ctrl+X to exit)"
            nano "$template_file"
        fi
        success "Template saved!"
    else
        info "Template created. Edit later: micro .github/pull_request_template.md"
    fi
}

install_gh_cli() {
    header "Install GitHub CLI (gh)"

    # Check if already installed
    if command -v gh >/dev/null 2>&1; then
        local gh_version=$(gh --version | head -1)
        local current_version=$(echo "$gh_version" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

        success "GitHub CLI is already installed: $gh_version"
        echo ""

        # Check for latest version
        info "Checking for updates..."
        local latest_version=$(curl -s --max-time 5 https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | \
            grep -oE '"tag_name":\s*"v[0-9]+\.[0-9]+\.[0-9]+"' | \
            grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | \
            head -1)

        if [[ -n "$latest_version" && -n "$current_version" ]]; then
            compare_versions "$current_version" "$latest_version"
            local cmp=$?

            if [[ $cmp -eq 1 ]]; then
                # Current version is older
                warn "Outdated version detected!"
                echo ""
                echo -e "${BOLD}Current:${NC}  v$current_version"
                echo -e "${BOLD}Latest:${NC}   v$latest_version"
                echo ""
                echo -e "${YELLOW}Upgrade recommended for latest features and security fixes${NC}"
                echo ""

                if confirm "Upgrade to v$latest_version now?"; then
                    # Continue to installation logic below
                    :
                else
                    info "Keeping current version v$current_version"
                    return 0
                fi
            elif [[ $cmp -eq 0 ]]; then
                success "You have the latest version (v$current_version)"
                echo ""
                if ! confirm "Reinstall anyway?"; then
                    return 0
                fi
            else
                # Current version is newer (beta/dev build?)
                success "You have a newer version than latest release (v$current_version > v$latest_version)"
                echo ""
                if ! confirm "Reinstall anyway?"; then
                    return 0
                fi
            fi
        else
            warn "Could not check for updates (no internet or API error)"
            echo ""
            if ! confirm "Reinstall/upgrade anyway?"; then
                return 0
            fi
        fi
    fi

    # Detect OS
    local os_type=""
    if [[ "$(uname)" == "Darwin" ]]; then
        os_type="macos"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            ubuntu|debian) os_type="debian" ;;
            fedora|rhel|centos) os_type="redhat" ;;
            arch|manjaro) os_type="arch" ;;
            *) os_type="unknown" ;;
        esac
    else
        os_type="unknown"
    fi

    echo -e "${BOLD}Detected OS: ${os_type}${NC}"
    echo ""

    case "$os_type" in
        debian)
            log "Upgrading GitHub CLI via apt..."
            echo ""

            # Add GitHub CLI repository if not present
            if [[ ! -f /etc/apt/sources.list.d/github-cli.list ]]; then
                info "Adding GitHub CLI repository..."
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            fi

            # Update and upgrade
            sudo apt update -qq
            sudo apt install -y gh
            ;;

        redhat)
            log "Upgrading GitHub CLI via dnf..."
            echo ""
            sudo dnf install -y 'dnf-command(config-manager)' 2>/dev/null || true
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || true
            sudo dnf install -y gh
            ;;

        arch)
            log "Upgrading GitHub CLI via pacman..."
            echo ""
            sudo pacman -S --noconfirm github-cli
            ;;

        macos)
            if command -v brew >/dev/null 2>&1; then
                log "Upgrading GitHub CLI via Homebrew..."
                echo ""
                brew upgrade gh || brew install gh
            else
                error "Homebrew not found. Install from https://brew.sh first"
                return 1
            fi
            ;;

        *)
            error "Unsupported OS or unable to detect package manager"
            echo ""
            echo "Manual installation:"
            echo "  Visit: https://github.com/cli/cli#installation"
            echo ""
            echo "Or download binary:"
            echo "  https://github.com/cli/cli/releases/latest"
            return 1
            ;;
    esac

    # Verify installation
    if command -v gh >/dev/null 2>&1; then
        local gh_version=$(gh --version | head -1)
        success "GitHub CLI installed successfully: $gh_version"
        echo ""

        # Check if already authenticated
        if gh auth status >/dev/null 2>&1; then
            local gh_user=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
            success "Already authenticated as: $gh_user"
            echo ""
            info "You're all set! GitHub CLI is ready to use."
        else
            echo -e "${BOLD}Authentication Required:${NC}"
            echo "  GitHub CLI needs to authenticate to access your repositories"
            echo ""
            echo -e "${GRAY}Note: If running over SSH, the browser won't open automatically.${NC}"
            echo -e "${GRAY}You'll need to manually open the URL shown below.${NC}"
            echo ""

            if confirm "Run 'gh auth login' now?"; then
                echo ""
                gh auth login

                # Verify authentication succeeded
                if gh auth status >/dev/null 2>&1; then
                    echo ""
                    success "Authentication successful!"
                else
                    echo ""
                    warn "Authentication may have failed. Run 'gh auth login' manually if needed."
                fi
            else
                echo ""
                info "Run 'gh auth login' later to authenticate"
            fi
        fi
    else
        error "Installation failed. Check errors above."
        return 1
    fi
}

########################
# Main Menu            #
########################

show_menu() {
    clear
    local current_branch
    current_branch=$(get_current_branch)

    # Get script last modified time
    local script_path="${BASH_SOURCE[0]}"
    local last_updated=$(date -r "$script_path" '+%B %d, %Y at %I:%M %p' 2>/dev/null || echo "Unknown")

    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        GitHub Manager - Bloom Project          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo -e "       ${GRAY}Updated: $last_updated${NC}"
    echo -e "                                   ${GRAY}Bryan Luce${NC}"
    echo ""

    # Show dashboard
    show_dashboard

    echo -e "Current branch: ${GREEN}$current_branch${NC}   Target: ${GREEN}$TARGET_BRANCH${NC}"
    echo ""

    echo -e "${BOLD}Workspace Info${NC}"
    echo -e "  1) Status snapshot ${GRAY}- Current working tree status${NC}"
    echo -e "  2) Clean check ${GRAY}- Verify clean state${NC}"
    echo -e "  3) Commit log ${GRAY}- Recent commit history${NC}"
    echo -e "  4) View diff ${GRAY}- Review changes${NC}"
    echo ""
    echo -e "${BOLD}Save Work${NC}"
    echo -e "  5) Commit changes ${GRAY}- Stage and commit (message or 'wip')${NC}"
    echo -e "  6) Stash changes ${GRAY}- Save changes (with note or quick)${NC}"
    echo ""
    echo -e "${BOLD}Restore & Discard${NC}"
    echo -e "  7) Manage stashes ${GRAY}- List, restore, or delete stashes${NC}"
    echo -e "  8) Discard changes ${GRAY}- Remove all/file/untracked changes${NC}"
    echo ""
    echo -e "${BOLD}Branch Management${NC}"
    echo -e "  9) Branch manager ${GRAY}- List, merge, delete branches interactively${NC}"
    echo -e " 10) Cleanup claude/* remotes ${GRAY}- Bulk delete merged session branches${NC}"
    echo ""
    echo -e "${BOLD}Claude Code Web${NC}"
    echo -e " 11) Session merge & cleanup ${GRAY}- Automated session workflow${NC}"
    echo -e " 12) Generate PR command ${GRAY}- Copy-paste gh pr create command${NC}"
    echo -e " 13) Help & workflow guide ${GRAY}- Full documentation${NC}"
    echo -e " 14) GitHub CLI reference ${GRAY}- Quick command reference${NC}"
    echo ""
    echo -e "${BOLD}GitHub Actions${NC}"
    echo -e " 15) Check Actions status ${GRAY}- View failing checks and logs${NC}"
    echo -e " 16) Check last 5 commits ${GRAY}- Find failing actions in recent commits${NC}"
    echo -e " 17) Manage workflows ${GRAY}- View/edit workflow files${NC}"
    echo -e " 18) Toggle Actions CI/CD ${GRAY}- Enable/disable workflows to manage costs${NC}"
    echo ""
    echo -e "${BOLD}Configuration${NC}"
    echo -e " 19) Setup Git config ${GRAY}- Create/edit scripts/gh.config${NC}"
    echo -e " 20) Create PR template ${GRAY}- Create/edit .github/pull_request_template.md${NC}"
    echo -e " 21) Install GitHub CLI ${GRAY}- Install gh command-line tool${NC}"
    echo ""
    echo -e "${BOLD}Diagnostics${NC}"
    echo -e " 22) Git/GitHub healthcheck ${GRAY}- Snapshot repo & remote state${NC}"
    echo ""
}

main() {
    check_git_repo
    check_gh_cli

    while true; do
        show_menu
        read -p "Select option: " option

        case $option in
            1)  show_git_status ;;
            2)  check_clean ;;
            3)  recent_commits ;;
            4)  view_diff ;;
            5)  commit_changes_unified ;;
            6)  stash_changes_unified ;;
            7)  manage_stashes_unified ;;
            8)  discard_changes_unified ;;
            9)  branch_manager_unified ;;
            10) cleanup_merged_claude_remote ;;
            11) claude_session_merge_and_cleanup ;;
            12) generate_pr_command ;;
            13) show_claude_web_help ;;
            14) show_github_cli_reference ;;
            15) check_github_actions ;;
            16) check_actions_last_5_commits ;;
            17) manage_github_actions_workflows ;;
            18) toggle_github_actions ;;
            19) setup_git_config ;;
            20) create_pr_template ;;
            21) install_gh_cli ;;
            22) github_healthcheck ;;
            *)
                # Any non-number or invalid option exits
                exit 0
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..." _
    done
}

main
