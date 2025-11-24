#!/usr/bin/env bash
# =============================================================================
# lib/packages.sh - Package Management & PKG_* Expansion
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Pure functions for package.json operations and PKG_* variable expansion.
# No execution on source.
#
# Exports:
#   pkg_expand, pkg_is_enabled, pkg_has_dependency, pkg_add_dependency,
#   pkg_add_script, pkg_update_field
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_PACKAGES_LOADED:-}" ]] && return 0
_LIB_PACKAGES_LOADED=1

# =============================================================================
# PKG_* VARIABLE EXPANSION
# =============================================================================

# Expand a PKG_* reference to its actual package name/version
# Usage: pkg=$(pkg_expand "PKG_NEXT")  # returns "next@15"
pkg_expand() {
    local pkg_ref="$1"

    # If it's a PKG_* reference, look up the variable
    if [[ "$pkg_ref" == PKG_* ]]; then
        local var_name="${pkg_ref%%|*}"  # Remove |enabled:false suffix
        local pkg_value="${!var_name:-}"

        if [[ -z "$pkg_value" ]]; then
            log_warn "Package variable not defined: $var_name"
            return 1
        fi

        echo "$pkg_value"
    else
        # Not a PKG_* reference, return as-is
        echo "$pkg_ref"
    fi
}

# Check if a package reference is enabled
# Usage: pkg_is_enabled "PKG_NEXT|enabled:false" && echo "yes"
pkg_is_enabled() {
    local pkg_ref="$1"

    # Check for |enabled:false suffix
    if [[ "$pkg_ref" == *"|enabled:false"* ]]; then
        return 1
    fi

    # Default to enabled
    return 0
}

# Parse PHASE_PACKAGES_0N_* into list of enabled packages
# Usage: packages=($(pkg_get_phase_packages "0"))
pkg_get_phase_packages() {
    local phase_num="$1"

    # Find the PHASE_PACKAGES variable for this phase
    local packages_var=""
    for var in $(compgen -v | grep "^PHASE_PACKAGES_0${phase_num}_"); do
        packages_var="$var"
        break
    done

    if [[ -z "$packages_var" ]]; then
        return 0
    fi

    local packages_list="${!packages_var:-}"
    local enabled_packages=()

    # Parse each line
    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue
        line="${line#"${line%%[![:space:]]*}"}"  # trim leading
        line="${line%"${line##*[![:space:]]}"}"  # trim trailing
        [[ -z "$line" ]] && continue

        # Check if enabled
        if pkg_is_enabled "$line"; then
            local pkg
            pkg=$(pkg_expand "$line")
            if [[ -n "$pkg" ]]; then
                enabled_packages+=("$pkg")
            fi
        fi
    done <<< "$packages_list"

    echo "${enabled_packages[@]}"
}

# =============================================================================
# PACKAGE.JSON HELPERS
# =============================================================================

# Check if dependency exists in package.json
# Usage: pkg_has_dependency "next"
pkg_has_dependency() {
    local dep="$1"
    local pkg_file="${2:-package.json}"

    if [[ ! -f "$pkg_file" ]]; then
        return 1
    fi

    if grep -q "\"$dep\"" "$pkg_file" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Add dependency if not present
# Usage: pkg_add_dependency "next@15" [dev]
pkg_add_dependency() {
    local dep="$1"
    local dev="${2:-false}"

    # Extract package name (without version) for checking
    local pkg_name="${dep%%@*}"

    if pkg_has_dependency "$pkg_name"; then
        log_skip "Dependency: $pkg_name"
        return 0
    fi

    local flag=""
    if [[ "$dev" == "true" ]]; then
        flag="-D"
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_dry "pnpm add $flag $dep"
    else
        log_info "Installing $dep..."
        pnpm add $flag "$dep"
        log_success "Installed: $dep"
    fi
}

# Add script to package.json
# Usage: pkg_add_script "dev" "next dev"
pkg_add_script() {
    local name="$1"
    local command="$2"
    local pkg_file="package.json"

    if [[ ! -f "$pkg_file" ]]; then
        log_error "package.json not found"
        return 1
    fi

    # Check if script already exists
    if grep -q "\"$name\":" "$pkg_file" 2>/dev/null; then
        log_skip "Script: $name"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_dry "Add script '$name': '$command'"
        return 0
    fi

    # Use node to safely add script
    node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('$pkg_file', 'utf8'));
        pkg.scripts = pkg.scripts || {};
        pkg.scripts['$name'] = '$command';
        fs.writeFileSync('$pkg_file', JSON.stringify(pkg, null, 2) + '\n');
    "
    log_success "Added script: $name"
}

# Update package.json field
# Usage: pkg_update_field "engines.node" '">= 20"'
pkg_update_field() {
    local field="$1"
    local value="$2"
    local pkg_file="package.json"

    if [[ ! -f "$pkg_file" ]]; then
        log_error "package.json not found"
        return 1
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_dry "Set package.json $field = $value"
        return 0
    fi

    # Use node to safely update field
    node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('$pkg_file', 'utf8'));
        const path = '$field'.split('.');
        let obj = pkg;
        for (let i = 0; i < path.length - 1; i++) {
            obj[path[i]] = obj[path[i]] || {};
            obj = obj[path[i]];
        }
        obj[path[path.length - 1]] = $value;
        fs.writeFileSync('$pkg_file', JSON.stringify(pkg, null, 2) + '\n');
    "
    log_success "Updated package.json: $field"
}

# =============================================================================
# INSTALL PHASE PACKAGES
# =============================================================================

# Install all enabled packages for a phase
# Usage: pkg_install_phase "0"
pkg_install_phase() {
    local phase_num="$1"

    local packages
    packages=($(pkg_get_phase_packages "$phase_num"))

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_debug "No packages to install for phase $phase_num"
        return 0
    fi

    log_info "Installing ${#packages[@]} packages for phase $phase_num..."

    for pkg in "${packages[@]}"; do
        pkg_add_dependency "$pkg"
    done
}
