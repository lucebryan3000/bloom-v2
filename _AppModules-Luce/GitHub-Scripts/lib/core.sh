#!/usr/bin/env bash
# Core Git/GitHub helper functions factored out of gh.sh
# This file is sourced by gh.sh; it does not execute anything on its own.

if [ -z "${BASH_VERSION:-}" ]; then
    echo "core.sh requires bash. Run via gh.sh using bash." >&2
    return 1 2>/dev/null || exit 1
fi

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
        local files_changed
        files_changed=$(git diff --name-status "$TARGET_BRANCH"..."origin/$source_branch" 2>/dev/null)
        if [[ -n "$files_changed" ]]; then
            local page_size=${GH_FILES_PAGE_SIZE:-20}
            local files_array=()
            while IFS= read -r line; do
                [[ -n "$line" ]] && files_array+=("$line")
            done <<< "$files_changed"

            local total_files=${#files_array[@]}
            echo -e "${BOLD}Files changed (${total_files} total, ${page_size} per page):${NC}"

            local start=0
            while true; do
                local end=$((start + page_size))
                (( end > total_files )) && end=$total_files

                for ((i=start; i<end; i++)); do
                    IFS=$'\t' read -r status file rest <<< "${files_array[$i]}"
                    case "$status" in
                        A) echo -e "  ${GREEN}+${NC} $file" ;;
                        D) echo -e "  ${RED}-${NC} $file" ;;
                        M) echo -e "  ${YELLOW}~${NC} $file" ;;
                        R*) echo -e "  ${BLUE}→${NC} $file → $rest" ;;
                        *) echo -e "  ${CYAN}?${NC} $file" ;;
                    esac
                done

                (( end >= total_files )) && break

                local remaining=$((total_files - end))
                echo ""
                read -p "$(echo -e ${YELLOW}Press Enter for next ${page_size} file(s) (${remaining} remaining), or 'q' to stop: ${NC})" next_page
                if [[ "$next_page" =~ ^[Qq]$ ]]; then
                    break
                fi
                echo ""
                start=$end
            done
        else
            echo -e "${BOLD}Files changed:${NC}"
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

    # Use merge-tree to safely detect conflicts without actually merging
    local merge_base
    merge_base=$(git merge-base "$TARGET_BRANCH" "origin/$source_branch" 2>/dev/null)

    if [[ -z "$merge_base" ]]; then
        warn "Unable to determine merge base - branches may be unrelated"
        return 0
    fi

    # Check for conflicts using merge-tree (Git 2.38+) or fallback to actual merge test
    local conflict_files
    if git merge-tree --help 2>/dev/null | grep -q "\-\-write-tree"; then
        # Git 2.38+: use new merge-tree with --write-tree
        conflict_files=$(git merge-tree --write-tree "$merge_base" "$TARGET_BRANCH" "origin/$source_branch" 2>&1 | grep -A1000 "^Conflicted file" | tail -n +2 || true)
    else
        # Fallback: test merge and capture conflicts before aborting
        git merge --no-commit --no-ff "origin/$source_branch" >/dev/null 2>&1 || {
            conflict_files=$(git diff --name-only --diff-filter=U 2>/dev/null || true)
            git merge --abort >/dev/null 2>&1 || true

            if [[ -n "$conflict_files" ]]; then
                warn "Potential merge conflicts detected!"
                echo ""
                echo "Conflicting files (approx):"
                echo "$conflict_files" | sed 's/^/  - /'
                echo ""
                if ! confirm "Continue with merge anyway?"; then
                    error "Merge aborted by user"
                    return 1
                fi
                return 0
            fi
        }
        git merge --abort >/dev/null 2>&1 || true
    fi

    # If conflicts found, display them
    if [[ -n "$conflict_files" ]]; then
        warn "Potential merge conflicts detected!"
        echo ""
        echo "Conflicting files:"
        echo "$conflict_files" | sed 's/^/  - /'
        echo ""
        if ! confirm "Continue with merge anyway?"; then
            error "Merge aborted by user"
            return 1
        fi
        return 0
    fi

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

    # Ensure working tree clean before switching branches
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "Working tree has uncommitted changes"
        git status -s | head -10
        echo ""
        if confirm "Stash changes before merging?" "y"; then
            local stash_label="merge-${TARGET_BRANCH}-$(date '+%Y-%m-%d_%H-%M-%S')"
            git stash push -m "$stash_label" >/dev/null 2>&1 && success "Stashed as '$stash_label'"
        else
            error "Merge cancelled (working tree not clean)"
            return 1
        fi
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
            echo "Conflicting files:"
            git diff --name-only --diff-filter=U | sed 's/^/  - /'
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
            echo "Conflicting files:"
            git diff --name-only --diff-filter=U | sed 's/^/  - /'
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

update_branch_from_main() {
    local branch="$1"
    local branch_type="${2:-remote}" # remote or local

    branch="${branch#origin/}"

    # Require clean working tree to avoid mixing changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        error "Working tree is dirty. Commit/stash before updating branches."
        return 1
    fi

    if ! fetch_origin; then
        return 1
    fi

    local starting_branch
    starting_branch=$(get_current_branch)

    # Switch to branch (create local tracking if needed)
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        git checkout "$branch"
    else
        if [[ "$branch_type" == "remote" ]]; then
            git checkout -B "$branch" "origin/$branch" || {
                error "Failed to create local branch from origin/$branch"
                return 1
            }
        else
            error "Branch $branch not found locally"
            return 1
        fi
    fi

    echo ""
    echo "Update strategy for syncing ${CYAN}$branch${NC} with ${GREEN}origin/$TARGET_BRANCH${NC}:"
    echo "  1) Rebase (recommended, linear history)"
    echo "  2) Merge  (preserve separate branch commits)"
    read -p "$(echo -e ${YELLOW}Select [1]: ${NC})" update_mode
    update_mode=${update_mode:-1}

    if [[ "$update_mode" == "2" ]]; then
        log "Merging origin/$TARGET_BRANCH into $branch..."
        if git merge --no-ff "origin/$TARGET_BRANCH" -m "Merge $TARGET_BRANCH into $branch"; then
            success "Branch updated with $TARGET_BRANCH changes"
        else
            error "Merge produced conflicts."
            echo ""
            echo "To resolve conflicts on $branch:"
            echo "  1. Fix conflicts in files"
            echo "  2. git add <files>"
            echo "  3. git commit"
            echo ""
            echo "Or abort:"
            echo "  git merge --abort"
            echo ""
            read -p "Press Enter after resolving or aborting to return to menu..." _
            return 1
        fi
    else
        log "Rebasing $branch onto origin/$TARGET_BRANCH..."
        if git rebase "origin/$TARGET_BRANCH"; then
            success "Rebased onto origin/$TARGET_BRANCH"
        else
            error "Rebase produced conflicts."
            echo ""
            echo "To resolve conflicts on $branch:"
            echo "  1. Fix conflicts in files"
            echo "  2. git add <files>"
            echo "  3. git rebase --continue"
            echo ""
            echo "Or abort:"
            echo "  git rebase --abort"
            echo ""
            read -p "Press Enter after resolving or aborting to return to menu..." _
            return 1
        fi
    fi

    echo ""
    if confirm "Push updated $branch to origin?" "y"; then
        if git push origin "$branch"; then
            success "Pushed updated branch to origin/$branch"
        else
            error "Push failed. Resolve and retry."
        fi
    else
        warn "Skipped push. Run: git push origin $branch"
    fi

    # Return to starting branch if possible and safe
    if git show-ref --verify --quiet "refs/heads/$starting_branch"; then
        git checkout "$starting_branch" >/dev/null 2>&1 || true
    fi
}

bulk_update_branches_from_main() {
    # Update all local branches (except target) from origin/$TARGET_BRANCH
    if ! git diff --quiet || ! git diff --cached --quiet; then
        error "Working tree is dirty. Commit/stash before bulk updating branches."
        return 1
    fi

    if ! fetch_origin; then
        return 1
    fi

    local branches=()
    while IFS= read -r b; do
        [[ -z "$b" ]] && continue
        [[ "$b" == "$TARGET_BRANCH" ]] && continue
        [[ "$b" == "HEAD" ]] && continue
        [[ "$b" == stash* ]] && continue  # skip stash recovery branches
        branches+=("$b")
    done < <(git for-each-ref --format='%(refname:short)' refs/heads)

    if [[ ${#branches[@]} -eq 0 ]]; then
        warn "No local branches to update"
        return 0
    fi

    echo ""
    echo -e "${BOLD}Bulk updating local branches from ${TARGET_BRANCH}:${NC}"
    for b in "${branches[@]}"; do
        echo "  - $b"
    done
    echo ""

    if ! confirm "Proceed to update ALL listed branches from ${TARGET_BRANCH}?" "y"; then
        warn "Bulk update cancelled"
        return 1
    fi

    for b in "${branches[@]}"; do
        echo ""
        log "Updating $b from $TARGET_BRANCH..."
        update_branch_from_main "$b" "local" || {
            error "Stopped on $b due to errors"
            return 1
        }
    done

    success "Bulk update complete"
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
    header "Cleanup Merged Remote Branches"

    # Ask user what pattern to filter (or all)
    echo ""
    echo -e "${BOLD}What type of branches do you want to clean up?${NC}"
    echo ""
    echo "  1) claude/* branches only (Claude Code sessions)"
    echo "  2) dependabot/* branches only"
    echo "  3) All merged branches (any pattern)"
    echo "  4) Custom pattern..."
    echo ""
    read -p "Select option [1-4]: " cleanup_choice
    echo ""

    local branch_pattern=""
    local pattern_display=""
    
    case $cleanup_choice in
        1)
            branch_pattern="claude/"
            pattern_display="claude/*"
            ;;
        2)
            branch_pattern="dependabot/"
            pattern_display="dependabot/*"
            ;;
        3)
            branch_pattern=""
            pattern_display="all branches"
            ;;
        4)
            read -p "Enter pattern (e.g., 'feature/', 'hotfix/'): " branch_pattern
            pattern_display="$branch_pattern*"
            ;;
        *)
            warn "Invalid option"
            return
            ;;
    esac

    info "Fetching merged PRs with $pattern_display from GitHub..."
    echo ""

    # Use gh CLI to get actually-merged PRs (with optional pattern filter)
    local jq_filter
    if [[ -n "$branch_pattern" ]]; then
        jq_filter='.[] | select(.headRefName | startswith("'"$branch_pattern"'")) | "\(.headRefName)\t\(.number)\t\(.mergedAt)\t\(.title)"'
    else
        jq_filter='.[] | "\(.headRefName)\t\(.number)\t\(.mergedAt)\t\(.title)"'
    fi

    local merged_prs=$(gh pr list \
        --state merged \
        --json headRefName,number,mergedAt,title \
        --jq "$jq_filter" 2>/dev/null)

    if [[ -z "$merged_prs" ]]; then
        success "No merged $pattern_display found"
        echo ""
        info "All clean! No $pattern_display with merged PRs."
        return
    fi

    # Check which branches actually still exist on GitHub
    info "Checking which branches still exist on GitHub..."
    echo ""

    local existing_branches=""
    local deleted_count=0

    while IFS=$'\t' read -r branch pr_num merged_at title; do
        # Skip main/master branches for safety
        if [[ "$branch" == "main" || "$branch" == "master" ]]; then
            continue
        fi
        
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

    echo -e "${BOLD}Merged Branches ($pattern_display) - Still Exist:${NC}"
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

quick_sync() {
    header "Quick Sync: Pull → Merge → Push"

    local current_branch
    current_branch=$(get_current_branch)

    log "Fetching latest changes..."
    if ! fetch_origin >/dev/null 2>&1; then
        error "Failed to fetch from remote"
        return 1
    fi
    success "Fetched latest changes"

    log "Pulling latest from origin/$current_branch..."
    if ! git pull --ff-only origin "$current_branch" >/dev/null 2>&1; then
        # Try with merge if ff-only fails
        if ! git pull origin "$current_branch" >/dev/null 2>&1; then
            warn "Pull had issues; continuing..."
        fi
    fi
    success "Pulled latest changes"

    # Clean up all stashes (safe to drop during sync)
    log "Cleaning up stashes..."
    local stash_count=$(git stash list | wc -l)
    if [[ $stash_count -gt 0 ]]; then
        git stash clear >/dev/null 2>&1
        success "Cleaned up $stash_count stash(es)"
    else
        log "No stashes to clean"
    fi

    log "Pushing changes to origin/$current_branch..."
    if git push origin "$current_branch" >/dev/null 2>&1; then
        success "Pushed changes to origin"
    else
        warn "Push had issues (nothing to push or conflicts)"
    fi

    success "Quick sync complete on $current_branch"
}

workflow_sync() {
    header "Sync all branches into ${TARGET_BRANCH}"

    local starting_branch
    starting_branch=$(get_current_branch)

    # lightweight lock to avoid concurrent syncs (best-effort if flock exists)
    local lock_file="${GH_SYNC_LOCK_FILE:-$HOME/.cache/gh-sync.lock}"
    local lock_max_age="${GH_SYNC_LOCK_MAX_AGE:-7200}"
    local lock_fd=""
    if command -v flock >/dev/null 2>&1; then
        mkdir -p "$(dirname "$lock_file")"

        if [[ -f "$lock_file" ]]; then
            local lock_pid
            lock_pid=$(cat "$lock_file" 2>/dev/null || true)
            local lock_age=""
            if lock_age=$(stat -c %Y "$lock_file" 2>/dev/null); then
                lock_age=$(( $(date +%s) - lock_age ))
            elif lock_age=$(stat -f %m "$lock_file" 2>/dev/null); then
                lock_age=$(( $(date +%s) - lock_age ))
            fi

        if [[ -n "$lock_age" && $lock_age -gt $lock_max_age && -n "$lock_pid" ]]; then
            if ! kill -0 "$lock_pid" 2>/dev/null; then
                warn "Stale sync lock detected (pid=$lock_pid, age=${lock_age}s). Removing."
                rm -f "$lock_file"
            fi
        fi
        fi

        exec {lock_fd}>"$lock_file" || {
            error "Unable to open lock file at $lock_file"
            return 1
        }
        if ! flock -n "$lock_fd"; then
            warn "Another sync appears to be running (lock: $lock_file). Skipping."
            return 1
        fi
        echo "$$" >&"$lock_fd"
        trap 'flock -u '"$lock_fd"'; rm -f "'"$lock_file"'"' RETURN
    else
        warn "flock not found; proceeding without a sync lock."
    fi

    # breadcrumb log for recoverability
    local breadcrumb_log="${GH_SYNC_BREADCRUMB_LOG:-$GH_ROOT_DIR/logs/branch-sync.log}"
    mkdir -p "$(dirname "$breadcrumb_log")"
    local starting_head
    starting_head=$(git rev-parse HEAD)
    echo "$(date +'%Y-%m-%d %H:%M:%S') | branch=$TARGET_BRANCH | head=$starting_head | action=workflow_sync start" >>"$breadcrumb_log"

    # Require clean working tree to avoid mixing in-progress changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "Uncommitted changes detected on $starting_branch"
        git status -s | head -8
        echo ""
        if confirm "Stash changes to continue syncing everything into ${TARGET_BRANCH}?" "y"; then
            local stash_label="sync-all-$(date '+%Y-%m-%d_%H-%M-%S')"
            git stash push -m "$stash_label" >/dev/null 2>&1 && success "Stashed as '$stash_label'"
        else
            error "Sync cancelled (working tree is not clean)"
            return 1
        fi
    fi

    # Fetch all remotes
    if ! fetch_origin; then
        return 1
    fi

    # Ensure we have the target branch locally and update it first
    if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
        git checkout "$TARGET_BRANCH"
    else
        warn "Local $TARGET_BRANCH not found; creating from origin/$TARGET_BRANCH"
        git checkout -B "$TARGET_BRANCH" "origin/$TARGET_BRANCH" || {
            error "Failed to create $TARGET_BRANCH from origin/$TARGET_BRANCH"
            return 1
        }
    fi

    log "Updating $TARGET_BRANCH from origin/$TARGET_BRANCH..."
    if ! git pull --ff-only origin "$TARGET_BRANCH"; then
        warn "$TARGET_BRANCH cannot fast-forward cleanly."
        if confirm "Merge origin/$TARGET_BRANCH into $TARGET_BRANCH with a merge commit?" "y"; then
            if git pull origin "$TARGET_BRANCH"; then
                success "Merged origin/$TARGET_BRANCH into $TARGET_BRANCH"
            else
                error "Failed to update $TARGET_BRANCH from origin"
                return 1
            fi
        else
            error "Sync cancelled (target branch not up to date)"
            return 1
        fi
    else
        success "Updated $TARGET_BRANCH to latest origin/$TARGET_BRANCH"
    fi

    # Opt-in list (empty = allow all)
    local allowed_patterns=()
    if [[ -n "${AUTO_SYNC_BRANCHES[*]}" ]]; then
        # shellcheck disable=SC2206
        allowed_patterns=(${AUTO_SYNC_BRANCHES[*]})
    fi

    # Collect remote branches that are ahead of TARGET_BRANCH
    local remote_branches=()
    while IFS= read -r ref; do
        ref=${ref#origin/}
        [[ "$ref" == "$TARGET_BRANCH" || "$ref" == "HEAD" ]] && continue
        remote_branches+=("$ref")
    done < <(git for-each-ref --format='%(refname:short)' refs/remotes/origin)

    if [[ ${#remote_branches[@]} -eq 0 ]]; then
        success "No remote branches found to merge."
        git checkout "$starting_branch" >/dev/null 2>&1 || true
        return 0
    fi

    local merge_candidates=()
    for branch in "${remote_branches[@]}"; do
        if [[ ${#allowed_patterns[@]} -gt 0 ]]; then
            local allowed="false"
            for pat in "${allowed_patterns[@]}"; do
                if [[ "$branch" == $pat ]]; then
                    allowed="true"
                    break
                fi
            done
            if [[ "$allowed" != "true" ]]; then
                warn "Skipping $branch (not in AUTO_SYNC_BRANCHES)"
                continue
            fi
        fi

        local ahead_count
        ahead_count=$(git rev-list --count "$TARGET_BRANCH".."origin/$branch" 2>/dev/null || echo "0")
        if [[ $ahead_count -gt 0 ]]; then
            merge_candidates+=("$branch:$ahead_count")
        fi
    done

    if [[ ${#merge_candidates[@]} -eq 0 ]]; then
        success "All remote branches are already merged into $TARGET_BRANCH"
        git checkout "$starting_branch" >/dev/null 2>&1 || true
        return 0
    fi

    echo ""
    echo -e "${BOLD}Branches to merge into ${TARGET_BRANCH}:${NC}"
    for entry in "${merge_candidates[@]}"; do
        local branch=${entry%%:*}
        local ahead=${entry##*:}
        echo "  - $branch (${ahead} commit[s] ahead)"
    done
    echo ""

    if ! confirm "Merge ALL of the above branches into $TARGET_BRANCH now?" "y"; then
        warn "Sync cancelled (no merges performed)"
        git checkout "$starting_branch" >/dev/null 2>&1 || true
        return 1
    fi

    local merged=0
    for entry in "${merge_candidates[@]}"; do
        local branch=${entry%%:*}
        local ahead=${entry##*:}

        echo ""
        log "Merging origin/$branch into $TARGET_BRANCH (${ahead} commit[s] ahead)..."
        if git merge --no-ff --no-edit "origin/$branch"; then
            success "Merged origin/$branch into $TARGET_BRANCH"
            ((merged++))
        else
            error "Merge conflicts detected with origin/$branch."
            echo ""
            echo "Resolve conflicts on $TARGET_BRANCH, then run:"
            echo "  git add <files>"
            echo "  git commit"
            echo ""
            echo "Or abort merge:"
            echo "  git merge --abort"
            return 1
        fi
    done

    echo ""
    success "Merged $merged branch(es) into $TARGET_BRANCH"

    if confirm "Push $TARGET_BRANCH to origin now?" "y"; then
        if git push origin "$TARGET_BRANCH"; then
            success "Pushed $TARGET_BRANCH to origin"
        else
            error "Push failed. Resolve issues and push manually."
            return 1
        fi
    else
        warn "Skipped push. Run: git push origin $TARGET_BRANCH"
    fi

    local ending_head
    ending_head=$(git rev-parse HEAD)
    echo "$(date +'%Y-%m-%d %H:%M:%S') | branch=$TARGET_BRANCH | head=$ending_head | merged=$merged | action=workflow_sync end" >>"$breadcrumb_log"

    # Return to original branch if different
    if [[ "$starting_branch" != "$TARGET_BRANCH" ]]; then
        git checkout "$starting_branch" >/dev/null 2>&1 || true
    fi
}

claude_session_merge_and_cleanup() {
    check_git_repo

    # Fetch latest first (silent)
    if ! fetch_origin >/dev/null 2>&1; then
        error "Failed to fetch from remote"
        return 1
    fi

    # Get list of claude/* branches
    local claude_branches=()
    while IFS= read -r branch; do
        [[ -n "$branch" ]] && claude_branches+=("$branch")
    done < <(git branch -r | grep "origin/claude/" | sed 's/^[[:space:]]*origin\/\///' | sed 's/[[:space:]]*$//')

    if [[ ${#claude_branches[@]} -eq 0 ]]; then
        info "No session branches found to merge and cleanup"
        return 0
    fi

    while true; do
        header "Session Merge & Cleanup Workflow"

        info "This workflow will:"
        echo "  1. List session branches"
        echo "  2. Merge selected branch to $TARGET_BRANCH"
        echo "  3. Delete the branch locally and remotely"
        echo "  4. Clean up tracking references"
        echo ""

        # Display branches with details
        echo -e "${BOLD}Available Session Branches:${NC}"
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

        # Confirmation before merge
        if ! confirm "Proceed with merge and cleanup for '$selected_branch'?"; then
            warn "Merge cancelled"
            continue
        fi

        # Perform merge
        if merge_branch_to_target "$selected_branch"; then
            # Cleanup
            cleanup_remote_and_local_branch "$selected_branch"
            success "Merge and cleanup complete for: $selected_branch"

            # Refresh branch list for next iteration
            claude_branches=()
            while IFS= read -r branch; do
                [[ -n "$branch" ]] && claude_branches+=("$branch")
            done < <(git branch -r | grep "origin/claude/" | sed 's/^[[:space:]]*origin\/\///' | sed 's/[[:space:]]*$//')

            if [[ ${#claude_branches[@]} -eq 0 ]]; then
                success "All session branches have been merged and cleaned up!"
                return 0
            fi

            # Ask if user wants to continue with another branch
            if ! confirm "Merge another branch?"; then
                return 0
            fi
        else
            error "Merge failed for: $selected_branch"
            return 1
        fi
    done
}

show_claude_web_help() {
    header "Claude Code Web - Workflow Guide"

    cat << 'INNER_EOF'
🌐 HOW CLAUDE CODE WEB BRANCHING WORKS

Every Claude Code web session creates a new branch automatically:
  • Pattern: claude/[session-type]-[session-id]
  • Examples:
    - claude/fix-s-01HH3SA5nhHjgc5Po4fimzuu
    - claude/new-session-01956oJwQMRfy3jS5kf6HCSr

Without cleanup, these branches accumulate! This script automates the workflow.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 WORKFLOW: FROM SESSION TO MAIN

1. WORK IN CLAUDE CODE WEB
   • Claude commits changes to claude/[session-id] branch
   • All changes are isolated on that branch

2. SESSION COMPLETE - MERGE TO MAIN
   
   Main Menu → Option 2: Session merge & cleanup
   
   This command will:
   ✓ List all claude/* branches with commit counts
   ✓ Let you select which session to merge
   ✓ Show detailed diff (commits, files changed)
   ✓ Merge to main with proper commit message
   ✓ Push to remote (or show manual command if protected)
   ✓ Delete remote branch (origin/claude/...)
   ✓ Delete local branch
   ✓ Clean tracking references
   ✓ Loop to select another branch or quit

3. START FRESH
   • Next Claude session = new clean branch
   • Previous sessions cleaned up

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 KEY COMMANDS FOR CLAUDE CODE WEB

Main Menu:
  1) Commit changes
     → Quick commit on current branch

  2) Session merge & cleanup ⭐ RECOMMENDED
     → Full automated merge workflow
     → Handles everything from merge to deletion
     → Interactive selection of sessions

Advanced Menu (Option 10):
  1) View diff code
     → See line-by-line changes in detail

  5) Branch manager
     → Manual branch operations (merge, delete, list)
     → Use when you need more control

  6) Cleanup merged branches
     → Bulk delete claude/* branches
     → Choose: claude/*, dependabot/*, or all
     → Only deletes merged branches

Main Menu:
  3) Generate PR command
     → Create pull request interactively
     → Or get gh pr create command to copy-paste

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  COMMON ISSUES

Issue: "Permission denied (403)" when pushing to main
Fix:   Branch protection active. Script will:
       1. Complete merge locally
       2. Show manual push command
       3. Delete session branch
       4. You manually push: git push origin main

Issue: Multiple accumulated claude/* branches
Fix:   Advanced → Option 6 → Select option 1 (claude/*)
       Bulk deletes all merged claude/* branches

Issue: Merge conflicts
Fix:   Script shows conflicting files:
       1. Edit conflicting files to resolve
       2. git add <resolved-files>
       3. git commit
       4. Re-run Option 2 to finish cleanup

Issue: Need to create PR instead of direct merge
Fix:   Main → Option 3 (Generate PR command)
       Creates PR from claude/* branch to main

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 BEST PRACTICES

✓ Run "Session merge & cleanup" after EVERY Claude session
✓ Review commit list before merging
✓ Check ahead/behind status to avoid surprises
✓ Use PR workflow for team review when needed
✓ Bulk cleanup merged branches weekly

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 MORE HELP

  Help → GitHub CLI reference  - Quick gh command reference
  Help → Git/GitHub healthcheck - Diagnose repo issues

INNER_EOF
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

# ============================================================================
# Account-Level GitHub Actions Management Functions
# ============================================================================
# These functions manage workflows across ALL repositories in the account
# to handle billing/cost issues by disabling Actions globally
# ============================================================================

get_all_repos_with_workflows() {
    # Get all user repositories and their workflow counts
    # Output: nameWithOwner (one per line)
    gh repo list --json nameWithOwner --limit 100 --no-pager 2>/dev/null | \
        jq -r '.[].nameWithOwner' | sort
}

get_repo_workflow_summary() {
    local repo=$1
    local active_count=0
    local disabled_count=0

    # Get workflow status for this repo
    local workflows=$(gh workflow list --repo "$repo" --json name,state 2>/dev/null)

    if [[ -z "$workflows" ]]; then
        return
    fi

    while IFS= read -r line; do
        local state=$(echo "$line" | jq -r '.state')
        if [[ "$state" == "active" ]]; then
            ((active_count++))
        else
            ((disabled_count++))
        fi
    done < <(echo "$workflows" | jq -c '.[]')

    echo "$active_count|$disabled_count"
}

disable_all_account_workflows() {
    # Disable all workflows across all repositories
    local repos=$(get_all_repos_with_workflows)
    local total_disabled=0
    local total_failed=0

    if [[ -z "$repos" ]]; then
        error "Could not fetch repository list"
        return 1
    fi

    echo ""
    log "Disabling workflows across all repositories..."
    echo ""

    while IFS= read -r repo; do
        if [[ -z "$repo" ]]; then
            continue
        fi

        echo -ne "${CYAN}Processing: $repo${NC}\r"

        # Get active workflows for this repo
        local workflows=$(gh workflow list --repo "$repo" --json id,name --jq '.[] | select(.state == "active")' 2>/dev/null)

        if [[ -z "$workflows" ]]; then
            continue
        fi

        while IFS= read -r line; do
            local id=$(echo "$line" | jq -r '.id')
            local name=$(echo "$line" | jq -r '.name')

            if [[ -n "$id" ]]; then
                if gh workflow disable "$id" --repo "$repo" 2>/dev/null >/dev/null; then
                    ((total_disabled++))
                else
                    ((total_failed++))
                fi
            fi
        done < <(echo "$workflows" | jq -c '.[]')
    done < <(echo "$repos")

    echo -ne "\033[K"  # Clear the line

    echo ""
    success "Account-wide workflow disabling complete!"
    echo ""
    echo -e "  ${GREEN}Disabled:${NC} $total_disabled workflows"
    if [[ $total_failed -gt 0 ]]; then
        echo -e "  ${RED}Failed:${NC} $total_failed workflows"
    fi
    echo ""
    echo -e "${YELLOW}⚠️  Note:${NC} Protected workflows (Dependabot, Dependency Submission)"
    echo "         cannot be disabled via CLI. Manage them in GitHub Settings:"
    echo "         https://github.com/settings/security_and_analysis"
}

enable_all_account_workflows() {
    # Enable all workflows across all repositories
    local repos=$(get_all_repos_with_workflows)
    local total_enabled=0
    local total_failed=0

    if [[ -z "$repos" ]]; then
        error "Could not fetch repository list"
        return 1
    fi

    echo ""
    log "Enabling workflows across all repositories..."
    echo ""

    while IFS= read -r repo; do
        if [[ -z "$repo" ]]; then
            continue
        fi

        echo -ne "${CYAN}Processing: $repo${NC}\r"

        # Get disabled workflows for this repo
        local workflows=$(gh workflow list --repo "$repo" --json id,name --jq '.[] | select(.state != "active")' 2>/dev/null)

        if [[ -z "$workflows" ]]; then
            continue
        fi

        while IFS= read -r line; do
            local id=$(echo "$line" | jq -r '.id')
            local name=$(echo "$line" | jq -r '.name')

            if [[ -n "$id" ]]; then
                if gh workflow enable "$id" --repo "$repo" 2>/dev/null >/dev/null; then
                    ((total_enabled++))
                else
                    ((total_failed++))
                fi
            fi
        done < <(echo "$workflows" | jq -c '.[]')
    done < <(echo "$repos")

    echo -ne "\033[K"  # Clear the line

    echo ""
    success "Account-wide workflow enabling complete!"
    echo ""
    echo -e "  ${GREEN}Enabled:${NC} $total_enabled workflows"
    if [[ $total_failed -gt 0 ]]; then
        echo -e "  ${RED}Failed:${NC} $total_failed workflows"
    fi
    echo ""
}

show_account_workflow_status() {
    # Display detailed workflow status across all repositories
    local repos=$(get_all_repos_with_workflows)
    local total_active=0
    local total_disabled=0

    if [[ -z "$repos" ]]; then
        error "Could not fetch repository list"
        return 1
    fi

    header "GitHub Actions Account Status"
    echo ""

    echo "Repository Workflow Status:"
    echo ""

    while IFS= read -r repo; do
        if [[ -z "$repo" ]]; then
            continue
        fi

        local summary=$(get_repo_workflow_summary "$repo")
        local active=$(echo "$summary" | cut -d'|' -f1)
        local disabled=$(echo "$summary" | cut -d'|' -f2)

        if [[ -z "$active" ]]; then
            active=0
        fi
        if [[ -z "$disabled" ]]; then
            disabled=0
        fi

        if [[ $active -gt 0 || $disabled -gt 0 ]]; then
            ((total_active+=active))
            ((total_disabled+=disabled))

            local status_str=""
            if [[ $active -gt 0 ]]; then
                status_str+="${GREEN}✓ $active active${NC}"
            fi
            if [[ $disabled -gt 0 ]]; then
                [[ -n "$status_str" ]] && status_str+=" | "
                status_str+="${RED}✗ $disabled disabled${NC}"
            fi

            echo -e "  ${CYAN}$repo${NC}"
            echo -e "    $status_str"
        fi
    done < <(echo "$repos")

    echo ""
    echo -e "  ${BOLD}Total:${NC} ${GREEN}$total_active active${NC} | ${RED}$total_disabled disabled${NC}"
    echo ""
}

toggle_account_actions() {
    # Account-level GitHub Actions management
    check_git_repo

    # Check if gh CLI is available
    if ! command -v gh >/dev/null 2>&1; then
        error "GitHub CLI (gh) is not installed"
        echo "Install it with: curl -fsSL https://cli.github.com/install.sh | bash"
        return 1
    fi

    header "GitHub Actions Account-Wide Control"
    echo ""
    echo "Manage GitHub Actions workflows across ALL your repositories"
    echo "to handle billing costs and CI/CD resource management."
    echo ""

    # Show current status
    show_account_workflow_status

    # Offer control options
    echo "Options:"
    echo "  (1) Disable all workflows (pause CI across account)"
    echo "  (2) Enable all workflows (resume CI across account)"
    echo "  (3) Show detailed status"
    echo "  (q) Cancel"
    echo ""

    read -p "Choose action: " action_choice

    case "$action_choice" in
        1)
            echo ""
            if confirm "Disable ALL workflows across ALL repositories?"; then
                disable_all_account_workflows
            fi
            ;;
        2)
            echo ""
            if confirm "Enable ALL workflows across ALL repositories?"; then
                enable_all_account_workflows
            fi
            ;;
        3)
            show_account_workflow_status
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

    # Use -A to stage all changes from repository root, regardless of current directory
    git add -A
    git commit -m "$commit_msg"
    success "Changes committed successfully"

    # Push to remote
    echo ""
    if confirm "Push to origin/$(get_current_branch)?"; then
        if git push origin "$(get_current_branch)"; then
            success "Pushed to origin/$(get_current_branch)"
        else
            error "Push failed. Run 'git push' manually to retry."
        fi
    else
        warn "Skipped push. Run 'git push' when ready."
    fi
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

    # Use -A to stage all changes from repository root, regardless of current directory
    git add -A
    git commit -m "WIP: saving current changes"
    success "WIP commit created"

    # Push to remote
    echo ""
    if confirm "Push to origin/$(get_current_branch)?"; then
        if git push origin "$(get_current_branch)"; then
            success "Pushed to origin/$(get_current_branch)"
        else
            error "Push failed. Run 'git push' manually to retry."
        fi
    else
        warn "Skipped push. Run 'git push' when ready."
    fi
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
        echo "  5) Discard changes (careful!)"
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

commit_changes_unified() {
    header "Commit Changes"

    if check_git_status; then
        warn "No changes to commit"
        return
    fi

    local current_branch
    current_branch=$(get_current_branch)

    # Step 1: Fetch latest changes from remote
    echo "Fetching latest changes from origin..."
    if git fetch origin >/dev/null 2>&1; then
        success "Fetched latest changes"
    else
        warn "Failed to fetch from origin (continuing anyway)"
    fi

    # Step 2: Check if local branch is behind remote
    local behind_count
    behind_count=$(git rev-list --count HEAD..origin/"$current_branch" 2>/dev/null || echo "0")

    if [[ "$behind_count" -gt 0 ]]; then
        warn "Your branch is $behind_count commit(s) behind origin/$current_branch"
        echo ""
        echo "You should pull the latest changes before committing."
        echo ""
        if confirm "Pull latest changes now (recommended)?" "y"; then
            echo ""
            echo "Pull strategy:"
            echo "  (m) Merge  - preserves your local commits as-is"
            echo "  (r) Rebase - replays your work on top of remote changes (cleaner history)"
            echo ""
            read -p "Select strategy [m/r]: " pull_strategy

            case "$pull_strategy" in
                r|R|rebase)
                    if git pull --rebase origin "$current_branch"; then
                        success "Rebased successfully on origin/$current_branch"
                    else
                        error "Rebase failed. Resolve conflicts and run 'git rebase --continue'"
                        return 1
                    fi
                    ;;
                *)
                    if git pull origin "$current_branch"; then
                        success "Merged successfully with origin/$current_branch"
                    else
                        error "Merge failed. Resolve conflicts and commit manually."
                        return 1
                    fi
                    ;;
            esac
            echo ""
        else
            warn "Continuing without pull - push may fail if remote has new commits"
            echo ""
        fi
    fi

    # Step 3: Show what will be committed
    echo "Changes to be committed:"
    git status -s
    echo ""

    if ! confirm "Stage all listed files and create a commit?" "y"; then
        warn "Commit cancelled"
        return
    fi

    read -p "Commit message (or press Enter for WIP commit): " commit_msg

    # Default to 'wip' if empty
    if [[ -z "$commit_msg" ]]; then
        commit_msg="wip"
    fi

    # Use -A to stage all changes from repository root, regardless of current directory
    # This fixes the issue where `git add .` only stages files in the current directory
    git add -A

    if [[ "$commit_msg" == "wip" || "$commit_msg" == "WIP" ]]; then
        git commit -m "WIP: saving current changes"
        success "WIP commit created"
    else
        git commit -m "$commit_msg"
        success "Changes committed successfully"
    fi

    # Step 4: Push to remote
    echo ""
    if confirm "Push to origin/$current_branch?" "y"; then
        if git push origin "$current_branch"; then
            success "Pushed to origin/$current_branch"
        else
            error "Push failed. Run 'git push' manually to retry."
            echo ""
            echo "Common causes:"
            echo "  - Remote has new commits (try: git pull --rebase && git push)"
            echo "  - Network issues (check connection and retry)"
        fi
    else
        warn "Skipped push. Run 'git push' when ready."
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

    # Offer to clean up fully merged local branches and stale stashes up front (safe delete)
    set +e  # tolerate git branch/prune/drop failures; we'll re-enable after cleanup
    {
        local current_branch
        current_branch=$(get_current_branch)
        local merged_locals=()

        while IFS= read -r b; do
            [[ -z "$b" ]] && continue
            [[ "$b" == "$current_branch" ]] && continue
            [[ "$b" == "$TARGET_BRANCH" ]] && continue
            [[ "$b" == "HEAD" ]] && continue
            merged_locals+=("$b")
        done < <(git branch --format='%(refname:short)' --merged "origin/$TARGET_BRANCH" 2>/dev/null | sed 's/^[* ]*//')

        # Fallback to local target if remote not available
        if [[ ${#merged_locals[@]} -eq 0 ]]; then
            while IFS= read -r b; do
                [[ -z "$b" ]] && continue
                [[ "$b" == "$current_branch" ]] && continue
                [[ "$b" == "$TARGET_BRANCH" ]] && continue
                [[ "$b" == "HEAD" ]] && continue
                merged_locals+=("$b")
            done < <(git branch --format='%(refname:short)' --merged "$TARGET_BRANCH" 2>/dev/null | sed 's/^[* ]*//')
        fi

        if [[ ${#merged_locals[@]} -gt 0 ]]; then
            echo ""
            echo -e "${BOLD}Deleting fully merged local branches (no prompt):${NC}"
            for b in "${merged_locals[@]}"; do
                echo "  - $b"
            done
            echo ""
            local deleted=0
            local skipped=0
            for b in "${merged_locals[@]}"; do
                if git branch -d "$b" >/dev/null 2>&1; then
                    ((deleted++))
                else
                    ((skipped++))
                    warn "Skipped $b (not fully merged or protected)"
                fi
            done
            success "Deleted $deleted merged local branch(es); skipped $skipped"
            git remote prune origin >/dev/null 2>&1 || true
        fi

        # Auto-drop stale stashes that match allowed patterns and exceed age threshold
        if [[ "${GH_STASH_AUTO_CLEAN:-true}" != "false" ]]; then
            local max_age_days="${GH_STASH_MAX_AGE_DAYS:-7}"
            # shellcheck disable=SC2206
            local stash_patterns=(${GH_STASH_PATTERNS:-sync- temp- autoupdate})
            local now
            now=$(date +%s)
            local stale_refs=()

            while IFS='|' read -r ref msg commit_date; do
                [[ -z "$ref" || -z "$commit_date" ]] && continue

                local matches_pattern="false"
                for pat in "${stash_patterns[@]}"; do
                    [[ -z "$pat" ]] && continue
                    if [[ "$msg" == "$pat"* ]]; then
                        matches_pattern="true"
                        break
                    fi
                done
                [[ "$matches_pattern" != "true" ]] && continue

                local ts
                ts=$(date -d "$commit_date" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S%z" "$commit_date" +%s 2>/dev/null || true)
                [[ -z "$ts" ]] && continue

                local age_days=$(( (now - ts) / 86400 ))
                [[ $age_days -lt $max_age_days ]] && continue
                stale_refs+=("$ref|$msg|$age_days")
            done < <(git stash list --date=iso-strict --format="%gd|%gs|%cd")

            if [[ ${#stale_refs[@]} -gt 0 ]]; then
                echo ""
                echo -e "${BOLD}Dropping stale stashes (>${max_age_days}d, patterns: ${stash_patterns[*]}):${NC}"
                local dropped=0
                local skipped=0
                for entry in "${stale_refs[@]}"; do
                    IFS='|' read -r ref msg age_days <<<"$entry"
                    if git stash drop "$ref" >/dev/null 2>&1; then
                        echo "  - $ref ($msg) [${age_days}d]"
                        ((dropped++))
                    else
                        ((skipped++))
                        warn "Skipped $ref ($msg)"
                    fi
                done
                success "Dropped $dropped stale stash(es); skipped $skipped"
            fi
        fi
    }
    set -e

    while true; do
        echo ""
        local current_branch=$(get_current_branch)

        # Collect all branches (local and remote)
        local all_branches=()
        local branch_info=()
        declare -A branch_seen=()

        # Add current branch first
        all_branches+=("$current_branch")
        branch_info+=("current")
        branch_seen["$current_branch"]=1

        # Add other local branches
        while IFS= read -r branch; do
            [[ -n "$branch" && "$branch" != "$current_branch" ]] && {
                all_branches+=("$branch")
                branch_info+=("local")
                branch_seen["$branch"]=1
            }
        done < <(git branch | sed 's/^[* ]*//' | sed 's/^[[:space:]]*//')

        # Add remote branches
        while IFS= read -r branch; do
            [[ -z "$branch" ]] && continue
            # Skip remote if we already have the same branch locally/current to avoid duplicates
            if [[ -n "${branch_seen[$branch]}" ]]; then
                continue
            fi
            {
                all_branches+=("$branch")
                branch_info+=("remote")
                branch_seen["$branch"]=1
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

                # Count files ahead/behind
                local ahead_files=0 behind_files=0
                if [[ "$ahead" -gt 0 ]]; then
                    ahead_files=$(git diff --name-only "$TARGET_BRANCH".."origin/$branch" 2>/dev/null | wc -l)
                fi
                if [[ "$behind" -gt 0 ]]; then
                    behind_files=$(git diff --name-only "origin/$branch".."$TARGET_BRANCH" 2>/dev/null | wc -l)
                fi

                local file_info=""
                if [[ $ahead_files -gt 0 ]] || [[ $behind_files -gt 0 ]]; then
                    file_info=" (${ahead_files}↑/${behind_files}↓ files)"
                fi

                echo -e "  ${CYAN}[${idx}]${NC} ${CYAN}origin/${branch}${NC} - ${GREEN}↑$ahead${NC} ahead, ${YELLOW}↓$behind${NC} behind${file_info}"
            else
                echo -e "  ${BLUE}[${idx}]${NC} ${BLUE}${branch}${NC} (local)"
            fi
            ((idx++))
        done

        echo ""
        echo -e "${BOLD}Select branch [1-$((${#all_branches[@]}))] or 'u' to update all from ${TARGET_BRANCH}:${NC}"
        read -p "> " selection

        if [[ "$selection" == "u" || "$selection" == "U" ]]; then
            bulk_update_branches_from_main
            continue
        fi

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
        echo "  (u) Update branch from $TARGET_BRANCH"

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
            u|U)
                if [[ "$selected_info" == "remote" ]]; then
                    update_branch_from_main "$selected_branch" "remote"
                else
                    update_branch_from_main "$selected_branch" "local"
                fi
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
    local incoming_files=0
    local incoming_branches=0
    local incoming_preview=""
    local actions_status="Running"
    local open_prs=0

    # Working tree status
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

    # Incoming changes to TARGET_BRANCH from remote branches (for menu indicator)
    local target_ref="$TARGET_BRANCH"
    if ! git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
        # No local target branch; fall back to remote
        if git show-ref --verify --quiet "refs/remotes/origin/$TARGET_BRANCH"; then
            target_ref="origin/$TARGET_BRANCH"
        else
            target_ref=""
        fi
    fi

    if [[ -n "$target_ref" ]]; then
        local incoming_file_list=""
        while IFS= read -r remote_ref; do
            [[ "$remote_ref" == "origin/HEAD" ]] && continue
            [[ "$remote_ref" == "$target_ref" ]] && continue

            local ahead_count
            ahead_count=$(git rev-list --count "$target_ref".."$remote_ref" 2>/dev/null || echo "0")
            if [[ $ahead_count -gt 0 ]]; then
                incoming_branches=$((incoming_branches + 1))
                local branch_files
                branch_files=$(git diff --name-only "$target_ref"..."$remote_ref" 2>/dev/null || true)
                if [[ -n "$branch_files" ]]; then
                    incoming_file_list+=$'\n'"$branch_files"
                fi
            fi
        done < <(git for-each-ref --format='%(refname:short)' refs/remotes/origin 2>/dev/null)

        if [[ -n "${incoming_file_list//[[:space:]]/}" ]]; then
            incoming_files=$(echo "$incoming_file_list" | sed '/^$/d' | sort -u | wc -l | tr -d ' ')
            incoming_preview=$(echo "$incoming_file_list" | sed '/^$/d' | sort -u | head -5 | paste -sd ', ' -)
        fi
    fi

    # GitHub Actions (tolerate API/network failures)
    if command -v gh >/dev/null 2>&1; then
        local gh_runs_json
        gh_runs_json=$(gh run list --limit 1 --json conclusion,status,createdAt 2>/dev/null || true)
        if [[ -n "$gh_runs_json" && "$gh_runs_json" != "[]" ]]; then
            local latest_run=$(echo "$gh_runs_json" | grep -o '"conclusion":"[^"]*"' | cut -d'"' -f4)
            local run_date=$(echo "$gh_runs_json" | grep -o '"createdAt":"[^"]*"' | cut -d'"' -f4 | cut -d'T' -f1)
            case "$latest_run" in
                success) actions_status="✓ Pass" ;;
                failure) actions_status="✗ Fail" ;;
                "") actions_status="Idle" ;;
                *) actions_status="Running" ;;
            esac
            [[ -n "$run_date" ]] && actions_status="$actions_status ($run_date)"
        else
            actions_status="Idle"
        fi
        local gh_prs
        gh_prs=$(gh pr list --state open 2>/dev/null || true)
        open_prs=$(echo "$gh_prs" | wc -l | tr -d ' ')
    fi

    # ═══════════════════════════════════════════════════════════════════════
    # QUICK OVERVIEW - Teal header for consistency
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${BOLD}${CYAN}Quick Overview${NC}"
    echo ""

    # Branch (with color)
    printf "  %-22s ${GREEN}%-10s${NC} ${GRAY}→${NC} ${CYAN}%-10s${NC}\n" "Branch" "$current_branch" "$TARGET_BRANCH"

    # Working tree (with dynamic color)
    if [[ "$status_summary" == "Clean" ]]; then
        printf "  %-22s ${GREEN}%-5s${NC} (${files_changed} files changed)\n" "Working Tree" "$status_summary"
    else
        printf "  %-22s ${YELLOW}%-5s${NC} (${files_changed} files changed)\n" "Working Tree" "$status_summary"
    fi

    # Commits (with color)
    if [[ $ahead -eq 0 && $behind -eq 0 ]]; then
        printf "  %-22s ${GREEN}↑%d${NC} ahead, ${GREEN}↓%d${NC} behind\n" "Commits Ahead/Behind" "$ahead" "$behind"
    elif [[ $ahead -gt 0 ]]; then
        printf "  %-22s ${YELLOW}↑%d${NC} ahead, ${GREEN}↓%d${NC} behind\n" "Commits Ahead/Behind" "$ahead" "$behind"
    else
        printf "  %-22s ${GREEN}↑%d${NC} ahead, ${RED}↓%d${NC} behind\n" "Commits Ahead/Behind" "$ahead" "$behind"
    fi

    # Simple rows (no color on values)
    printf "  %-22s %s\n" "Claude Session Branches" "$claude_branches"
    printf "  %-22s %s\n" "Stashes" "$stash_count"
    printf "  %-22s %s\n" "GitHub Actions" "$actions_status"
    printf "  %-22s %s\n" "Open PRs" "$open_prs"
    echo ""

    # Store metrics for menu (export for menu function to use)
    export DASHBOARD_FILES_CHANGED=$files_changed
    export DASHBOARD_AHEAD=$ahead
    export DASHBOARD_BEHIND=$behind
    export DASHBOARD_INCOMING_FILES=$incoming_files
    export DASHBOARD_INCOMING_BRANCHES=$incoming_branches
    export DASHBOARD_INCOMING_PREVIEW="$incoming_preview"
}



setup_git_config() {
    header "GitHub Script Configuration (gh.conf)"

    # Load configuration defaults from gh.conf
    local auto_apply="${GIT_CONFIG_AUTO_APPLY:-false}"
    local pull_rebase="${GIT_CONFIG_PULL_REBASE:-false}"
    local pull_ff="${GIT_CONFIG_PULL_FF:-false}"
    local merge_conflictstyle="${GIT_CONFIG_MERGE_CONFLICTSTYLE:-diff3}"
    local use_script="${GIT_CONFIG_USE_SCRIPT:-false}"

    echo -e "${BOLD}Current Git Configuration Settings (from gh.conf):${NC}"
    echo ""
    echo -e "  ${CYAN}GIT_CONFIG_AUTO_APPLY${NC}          ${auto_apply}"
    echo -e "    ${GRAY}Auto-apply git config without prompting${NC}"
    echo ""
    echo -e "  ${CYAN}GIT_CONFIG_USE_SCRIPT${NC}          ${use_script}"
    echo -e "    ${GRAY}Generate scripts/gh.config file for manual review${NC}"
    echo ""
    echo -e "  ${CYAN}GIT_CONFIG_PULL_REBASE${NC}         ${pull_rebase}"
    echo -e "    ${GRAY}Git pull strategy (false=merge, true=rebase)${NC}"
    echo ""
    echo -e "  ${CYAN}GIT_CONFIG_PULL_FF${NC}             ${pull_ff}"
    echo -e "    ${GRAY}Fast-forward behavior (false=always merge commit)${NC}"
    echo ""
    echo -e "  ${CYAN}GIT_CONFIG_MERGE_CONFLICTSTYLE${NC} ${merge_conflictstyle}"
    echo -e "    ${GRAY}Conflict markers (diff3=3-way, merge=2-way)${NC}"
    echo ""

    # Show current git config for comparison
    local current_pull_rebase=$(git config --get pull.rebase 2>/dev/null)
    local current_pull_ff=$(git config --get pull.ff 2>/dev/null)
    local current_merge_conflictstyle=$(git config --get merge.conflictstyle 2>/dev/null)

    echo -e "${BOLD}Current Git Settings (applied to repository):${NC}"
    echo ""
    echo -e "  pull.rebase              ${current_pull_rebase:-${YELLOW}not set${NC}}"
    echo -e "  pull.ff                  ${current_pull_ff:-${YELLOW}not set${NC}}"
    echo -e "  merge.conflictstyle      ${current_merge_conflictstyle:-${YELLOW}not set${NC}}"
    echo ""

    echo -e "${GRAY}────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${BOLD}What this does:${NC}"
    echo "  • Displays current gh.conf settings"
    echo "  • Shows applied git configuration"
    echo "  • Lets you edit gh.conf to change behavior"
    echo ""
    echo -e "${BOLD}To apply git config settings:${NC}"
    echo "  • Set GIT_CONFIG_AUTO_APPLY=true in gh.conf (applies on every run)"
    echo "  • Or set GIT_CONFIG_USE_SCRIPT=true (generates scripts/gh.config)"
    echo ""

    if confirm "Edit configuration?" "n"; then
        local config_file="$GH_ROOT_DIR/gh.conf"
        if [[ -f "$config_file" ]]; then
            if command -v micro >/dev/null 2>&1; then
                micro "$config_file"
                success "Configuration file edited. Restart cs-gh to see changes."
            else
                warn "micro editor not found. Using nano..."
                nano "$config_file"
                success "Configuration file edited. Restart cs-gh to see changes."
            fi
        else
            error "Configuration file not found: $config_file"
        fi
    else
        info "Configuration not edited"
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

check_gh_updates() {
    header "GitHub CLI - Check for Updates"
    
    echo ""
    info "Checking current GitHub CLI version..."
    
    local gh_version_full=$(gh --version 2>/dev/null | head -1)
    local gh_version=$(echo "$gh_version_full" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    
    if [[ -z "$gh_version" ]]; then
        error "Could not determine GitHub CLI version"
        return 1
    fi
    
    echo ""
    echo -e "${BOLD}Current version:${NC} ${GREEN}$gh_version${NC}"
    echo ""
    
    info "Checking for latest version..."
    local latest_version=$(curl -s --max-time 5 https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | \
        grep -oE '"tag_name":\s*"v[0-9]+\.[0-9]+\.[0-9]+"' | \
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | \
        head -1)
    
    if [[ -z "$latest_version" ]]; then
        warn "Could not check for updates (network issue or rate limit)"
        echo ""
        echo "Check manually: https://github.com/cli/cli/releases"
        return 1
    fi
    
    echo -e "${BOLD}Latest version:${NC}  ${CYAN}$latest_version${NC}"
    echo ""
    
    # Compare versions
    compare_versions "$gh_version" "$latest_version"
    local cmp=$?
    
    if [[ $cmp -eq 0 ]]; then
        # Same version
        success "✓ You are on the latest version!"
        return 0
    elif [[ $cmp -eq 2 ]]; then
        # Newer than latest (development version)
        success "✓ You are on a newer version (development/beta)"
        return 0
    else
        # Outdated
        warn "⚠ Update available: $gh_version → $latest_version"
        echo ""
        
        if confirm "Upgrade GitHub CLI now?"; then
            echo ""
            log "Running upgrade..."
            
            # Use install_gh_cli function which handles upgrade
            if install_gh_cli; then
                echo ""
                local new_version=$(gh --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
                success "✓ Upgraded to version $new_version"
            else
                error "✗ Upgrade failed"
                echo ""
                echo "Try manually:"
                echo "  • Visit: https://github.com/cli/cli/releases"
                echo "  • Or run: sudo apt update && sudo apt upgrade gh"
            fi
        else
            echo ""
            info "Skipped upgrade. To upgrade later:"
            echo "  • Run this option again (Advanced → Check for updates)"
            echo "  • Or manually: sudo apt update && sudo apt upgrade gh"
        fi
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

# ============================================================================
# Advanced Commands Submenu
# ============================================================================

show_advanced_menu() {
    clear
    local current_branch
    current_branch=$(get_current_branch)

    echo ""
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║          Advanced Commands                                    ║${NC}"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${BOLD}Quick Actions${NC}"
    echo -e "  1) View diff code                 ${GRAY}Line-by-line code changes${NC}"
    echo -e "  2) Generate PR command            ${GRAY}Copy-paste gh pr create command${NC}"
    echo ""

    echo -e "${BOLD}Stash Management${NC}"
    echo -e "  3) Stash changes                  ${GRAY}Save work in progress${NC}"
    echo -e "  4) Manage stashes                 ${GRAY}View/restore/delete stashes${NC}"
    echo -e "  5) Discard changes                ${GRAY}Hard reset working tree${NC}"
    echo ""

    echo -e "${BOLD}Branch Operations${NC}"
    echo -e "  6) Branch manager                 ${GRAY}Switch/merge/delete branches${NC}"
    echo -e "  7) Cleanup merged branches        ${GRAY}Delete merged remote branches${NC}"
    echo ""

    echo -e "${BOLD}GitHub Actions${NC}"
    echo -e "  8) View GitHub Actions status     ${GRAY}Show workflow runs${NC}"
    echo -e "  9) View recent commits            ${GRAY}Check last 5 commits${NC}"
    echo -e " 10) List workflows                 ${GRAY}Show all workflow files${NC}"
    echo -e " 11) Toggle workflows               ${GRAY}Enable/disable workflows${NC}"
    echo -e " 12) Account-wide Actions toggle    ${GRAY}Manage all repos${NC}"
    echo ""

    echo -e "${BOLD}System${NC}"
    echo -e " 13) Check for GitHub CLI updates  ${GRAY}Update gh CLI${NC}"
    echo ""

    echo -e "${GRAY}Any other key returns to main menu${NC}"
    echo ""
}





advanced_menu_handler() {
    while true; do
        show_advanced_menu
        read -p "Select option: " adv_option

        case $adv_option in
            # Quick Actions
            1)  view_diff ;;
            2)  generate_pr_command ;;

            # Stash Management
            3)  stash_changes_unified ;;
            4)  manage_stashes_unified ;;
            5)  discard_changes_unified ;;

            # Branch Operations
            6)  branch_manager_unified ;;
            7)  cleanup_merged_claude_remote ;;

            # GitHub Actions Management
            8)  check_github_actions ;;
            9)  check_actions_last_5_commits ;;
            10) manage_github_actions_workflows ;;
            11) toggle_github_actions ;;
            12) toggle_account_actions ;;

            # System
            13) check_gh_updates ;;

            # Any other key returns to main menu
            *)
                return 0
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..." _
    done
}




show_menu() {
    clear
    local current_branch
    current_branch=$(get_current_branch)

    # Get script last modified time
    local script_path="${BASH_SOURCE[0]}"
    local last_updated=$(date -r "$script_path" '+%B %d, %Y at %I:%M %p' 2>/dev/null || echo "Unknown")

    # ═══════════════════════════════════════════════════════════════════════
    # HEADER - Teal color for consistency
    # ═══════════════════════════════════════════════════════════════════════

    echo ""
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║          GitHub Manager - Bloom Project                       ║${NC}"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "       ${GRAY}Updated: $last_updated${NC}"
    echo -e "                                          ${GRAY}Bryan Luce${NC}"
    echo ""

    # Show dashboard (sets DASHBOARD_* env vars)
    show_dashboard

    # ═══════════════════════════════════════════════════════════════════════
    # MENU OPTIONS - Quick Actions box (fixed spacing)
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${CYAN}Quick Actions${NC}                                                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"

    # Dynamic commit option (yellow if changes, show unpushed count)
    local commit_color="${NC}"
    local commit_desc="Shows files changed, then commit"
    local commit_parts=()
    local commit_count=${DASHBOARD_FILES_CHANGED:-0}
    local commit_count_display="[${commit_color}${commit_count}${NC}]"

    if [[ ${DASHBOARD_FILES_CHANGED:-0} -gt 0 ]]; then
        commit_color="${YELLOW}"
        commit_parts+=("Uncommitted local changes (${DASHBOARD_FILES_CHANGED} files)")
        commit_count_display="[${commit_color}${commit_count}${NC}]"
    fi

    if [[ ${DASHBOARD_AHEAD:-0} -gt 0 ]]; then
        commit_color="${YELLOW}"
        commit_parts+=("${DASHBOARD_AHEAD} unpushed commit(s)")
    fi

    if [[ ${#commit_parts[@]} -gt 0 ]]; then
        commit_desc=$(IFS=' | '; echo "${commit_parts[*]}")
    fi

    echo -e "  ${commit_color}${BOLD}1)${NC}${commit_color} Commit changes${NC} ${commit_count_display}         ${GRAY}${commit_desc}${NC}"

    local branch_color="${GREEN}"
    local branch_desc="List, merge, delete branches interactively"
    local branch_parts=()
    local incoming_count=${DASHBOARD_INCOMING_FILES:-0}
    local incoming_count_color="${NC}"
    [[ $incoming_count -gt 0 ]] && incoming_count_color="${GREEN}"
    local branch_count_display="[${incoming_count_color}${incoming_count}${NC}]"

    if [[ ${DASHBOARD_BEHIND:-0} -gt 0 ]]; then
        branch_parts+=("Target behind upstream (${DASHBOARD_BEHIND} commit[s])")
    fi

    if [[ $incoming_count -gt 0 ]]; then
        if [[ ${DASHBOARD_INCOMING_BRANCHES:-0} -gt 0 ]]; then
            branch_parts+=("${incoming_count} file(s) ready from ${DASHBOARD_INCOMING_BRANCHES} branch(es)")
        else
            branch_parts+=("${incoming_count} file(s) ready to pull")
        fi
    fi

    if [[ ${#branch_parts[@]} -gt 0 ]]; then
        branch_desc=$(IFS=' | '; echo "${branch_parts[*]}")
    elif [[ $incoming_count -gt 0 ]]; then
        branch_desc="Files ready to pull into ${TARGET_BRANCH}"
    fi

    echo -e "  ${branch_color}${BOLD}2)${NC}${branch_color} Branch manager${NC} ${branch_count_display}         ${GRAY}${branch_desc}${NC}"

    local sync_color="${NC}"
    local sync_parts=()
    if [[ ${DASHBOARD_FILES_CHANGED:-0} -gt 0 ]]; then
        sync_color="${YELLOW}"
        sync_parts+=("working tree needs commit")
    else
        sync_parts+=("Clean working tree")
    fi
    local sync_desc=$(IFS=' | '; echo "${sync_parts[*]}")

    echo -e "  ${sync_color}${BOLD}3)${NC}${sync_color} Quick sync (fetch/pull/push)${NC}  ${GRAY}${sync_desc}${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}Claude Code Web${NC}"
    echo -e "  ${BOLD}4)${NC} Session merge & cleanup     ${GRAY}Automated session workflow${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}Help & Documentation${NC}"
    echo -e "  ${BOLD}5)${NC} Claude Code Web guide       ${GRAY}How to use commands & branching${NC}"
    echo -e "  ${BOLD}6)${NC} GitHub CLI reference        ${GRAY}Quick gh command reference${NC}"
    echo -e "  ${BOLD}7)${NC} Git/GitHub healthcheck      ${GRAY}Diagnose repo & remote state${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}Configuration${NC}"
    echo -e "  ${BOLD}8)${NC} Edit GitHub script gh.conf  ${GRAY}View/edit script configuration${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}Advanced${NC}"
    echo -e "  ${BOLD}9)${NC} Advanced Commands →         ${GRAY}Diff, stash, branches, PR, Actions, updates${NC}"
    echo ""
    echo -e "${GRAY}────────────────────────────────────────────────────────────────${NC}"
    echo ""
}
