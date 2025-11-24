#!/usr/bin/env bash
# =============================================================================
# lib/prereqs-local.sh - Local Prerequisite Installer
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Installs Node.js and pnpm LOCALLY within the project (.tools/ directory)
# for complete isolation and portability. No system-wide or user-wide installs.
#
# Philosophy:
#   - Self-contained: All tools in PROJECT_ROOT/.tools/
#   - Portable: Move project to new machine, tools come with it
#   - Isolated: No PATH pollution, no version conflicts
#   - Version-locked: Exact Node.js version per project
#
# Exports:
#   prereqs_local_install_node, prereqs_local_install_pnpm,
#   prereqs_local_activate, prereqs_local_check
#
# Dependencies:
#   lib/logging.sh, bootstrap.conf (TOOLS_DIR, NODE_VERSION, etc.)
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_PREREQS_LOCAL_LOADED:-}" ]] && return 0
_LIB_PREREQS_LOCAL_LOADED=1

# =============================================================================
# DETECTION FUNCTIONS
# =============================================================================

# Check if local Node.js is installed
# Usage: prereqs_local_node_exists
prereqs_local_node_exists() {
    [[ -x "${NODE_LOCAL_BIN}" ]]
}

# Check if local pnpm is installed
# Usage: prereqs_local_pnpm_exists
prereqs_local_pnpm_exists() {
    [[ -x "${PNPM_LOCAL_BIN}" ]]
}

# Get local Node.js version
# Usage: version=$(prereqs_local_node_version)
prereqs_local_node_version() {
    if prereqs_local_node_exists; then
        "${NODE_LOCAL_BIN}" --version 2>/dev/null | sed 's/v//'
    else
        echo ""
    fi
}

# Get local pnpm version
# Usage: version=$(prereqs_local_pnpm_version)
prereqs_local_pnpm_version() {
    if prereqs_local_pnpm_exists; then
        "${PNPM_LOCAL_BIN}" --version 2>/dev/null
    else
        echo ""
    fi
}

# Check if local tools are up to date
# Usage: prereqs_local_check_versions
prereqs_local_check_versions() {
    local node_ok=false
    local pnpm_ok=false

    # Check Node.js version
    if prereqs_local_node_exists; then
        local node_ver
        node_ver=$(prereqs_local_node_version | cut -d. -f1)
        if [[ "$node_ver" -ge "${NODE_VERSION:-20}" ]]; then
            node_ok=true
            log_success "Local Node.js v$(prereqs_local_node_version) OK"
        else
            log_warn "Local Node.js v$(prereqs_local_node_version) < required v${NODE_VERSION}"
        fi
    else
        log_warn "Local Node.js not found at: ${NODE_LOCAL_BIN}"
    fi

    # Check pnpm version
    if prereqs_local_pnpm_exists; then
        local pnpm_ver
        pnpm_ver=$(prereqs_local_pnpm_version | cut -d. -f1)
        if [[ "$pnpm_ver" -ge "${PNPM_VERSION:-9}" ]]; then
            pnpm_ok=true
            log_success "Local pnpm v$(prereqs_local_pnpm_version) OK"
        else
            log_warn "Local pnpm v$(prereqs_local_pnpm_version) < required v${PNPM_VERSION}"
        fi
    else
        log_warn "Local pnpm not found at: ${PNPM_LOCAL_BIN}"
    fi

    $node_ok && $pnpm_ok
}

# =============================================================================
# NODE.JS LOCAL INSTALLATION
# =============================================================================

# Download and install Node.js locally
# Usage: prereqs_local_install_node
prereqs_local_install_node() {
    local version="${NODE_VERSION:-20}"
    local platform="${NODE_PLATFORM:-linux}"
    local arch="${NODE_ARCH:-x64}"

    log_step "Installing Node.js v${version} locally"
    log_info "Target directory: ${NODE_LOCAL_DIR}"

    # Create tools directory
    mkdir -p "${TOOLS_DIR}"

    # Determine download URL
    local node_tarball="node-v${version}-${platform}-${arch}.tar.xz"
    local download_url="${NODE_DOWNLOAD_BASE}/v${version}/${node_tarball}"

    log_debug "Download URL: ${download_url}"

    # Check if Node.js version already exists
    if prereqs_local_node_exists; then
        local existing_version
        existing_version=$(prereqs_local_node_version)
        if [[ "${existing_version%%.*}" == "$version" ]]; then
            log_success "Node.js v${version} already installed locally"
            return 0
        else
            log_info "Replacing Node.js v${existing_version} with v${version}"
            rm -rf "${NODE_LOCAL_DIR}"
        fi
    fi

    # Download Node.js tarball
    local download_dir="${TOOLS_DIR}/downloads"
    mkdir -p "$download_dir"

    log_info "Downloading Node.js v${version}..."
    if ! curl -fsSL "$download_url" -o "${download_dir}/${node_tarball}"; then
        log_error "Failed to download Node.js from: ${download_url}"
        return 1
    fi

    # Extract tarball
    log_info "Extracting Node.js..."
    if ! tar -xJf "${download_dir}/${node_tarball}" -C "$download_dir"; then
        log_error "Failed to extract Node.js tarball"
        rm -f "${download_dir}/${node_tarball}"
        return 1
    fi

    # Move to final location
    local extracted_dir="${download_dir}/node-v${version}-${platform}-${arch}"
    mv "$extracted_dir" "${NODE_LOCAL_DIR}"

    # Cleanup
    rm -f "${download_dir}/${node_tarball}"

    # Verify installation
    if prereqs_local_node_exists; then
        local installed_version
        installed_version=$(prereqs_local_node_version)
        log_success "Node.js v${installed_version} installed successfully"
        log_info "Location: ${NODE_LOCAL_BIN}"
        return 0
    else
        log_error "Node.js installation verification failed"
        return 1
    fi
}

# =============================================================================
# PNPM LOCAL INSTALLATION
# =============================================================================

# Install pnpm locally using local Node.js
# Usage: prereqs_local_install_pnpm
prereqs_local_install_pnpm() {
    local version="${PNPM_VERSION:-9}"

    log_step "Installing pnpm v${version} locally"
    log_info "Target directory: ${PNPM_LOCAL_DIR}"

    # Ensure Node.js is installed locally first
    if ! prereqs_local_node_exists; then
        log_error "Local Node.js required before installing pnpm"
        log_info "Run: prereqs_local_install_node"
        return 1
    fi

    # Create pnpm directory
    mkdir -p "${PNPM_LOCAL_DIR}"

    # Check if pnpm already exists
    if prereqs_local_pnpm_exists; then
        local existing_version
        existing_version=$(prereqs_local_pnpm_version)
        if [[ "${existing_version%%.*}" == "$version" ]]; then
            log_success "pnpm v${version} already installed locally"
            return 0
        else
            log_info "Replacing pnpm v${existing_version} with v${version}"
            rm -f "${PNPM_LOCAL_BIN}"
        fi
    fi

    # Install pnpm via npm (simple and reliable)
    log_info "Installing pnpm via npm..."

    # Install pnpm into .tools/pnpm/ directory
    if ! "${NPM_LOCAL_BIN}" install --global --prefix "${PNPM_LOCAL_DIR}" "pnpm@${version}"; then
        log_error "Failed to install pnpm via npm"
        return 1
    fi

    # The binary is at .tools/pnpm/bin/pnpm (symlink to pnpm.cjs)
    # Verify it exists
    if [[ ! -e "${PNPM_LOCAL_DIR}/bin/pnpm" ]]; then
        log_error "pnpm binary not found after installation"
        return 1
    fi

    # Update PNPM_LOCAL_BIN to point to actual binary location
    PNPM_LOCAL_BIN="${PNPM_LOCAL_DIR}/bin/pnpm"

    # Verify installation
    if prereqs_local_pnpm_exists; then
        local installed_version
        installed_version=$(prereqs_local_pnpm_version)
        log_success "pnpm v${installed_version} installed successfully"
        log_info "Location: ${PNPM_LOCAL_BIN}"
        return 0
    else
        log_error "pnpm installation verification failed"
        return 1
    fi
}

# =============================================================================
# ENVIRONMENT ACTIVATION
# =============================================================================

# Create activation script for local tools
# Usage: prereqs_local_create_activate_script
prereqs_local_create_activate_script() {
    log_info "Creating environment activation script: ${TOOLS_ACTIVATE_SCRIPT}"

    cat > "${TOOLS_ACTIVATE_SCRIPT}" << 'EOF'
#!/usr/bin/env bash
# =============================================================================
# .toolsrc - Local Tools Environment Activation
# =============================================================================
# Source this file to use project-local Node.js and pnpm
# Usage: source .toolsrc
#
# This script:
#   - Prepends .tools/node/bin and .tools/pnpm to PATH
#   - Sets environment variables for tool locations
#   - Provides verification commands
#
# Generated by: OmniForge prereqs-local.sh
# =============================================================================

# Detect project root (directory containing this file)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Local tools directory
TOOLS_DIR="${PROJECT_ROOT}/.tools"

# Add local Node.js to PATH (highest priority)
export PATH="${TOOLS_DIR}/node/bin:${PATH}"

# Add local pnpm to PATH
export PATH="${TOOLS_DIR}/pnpm/bin:${PATH}"

# Set tool location variables
export NODE_LOCAL_BIN="${TOOLS_DIR}/node/bin/node"
export NPM_LOCAL_BIN="${TOOLS_DIR}/node/bin/npm"
export NPX_LOCAL_BIN="${TOOLS_DIR}/node/bin/npx"
export PNPM_LOCAL_BIN="${TOOLS_DIR}/pnpm/bin/pnpm"

# Disable npm update check (faster)
export NO_UPDATE_NOTIFIER=1

# pnpm configuration
export PNPM_HOME="${TOOLS_DIR}/pnpm"

# Show activation status
echo "✓ Local tools activated"
echo "  Node.js: $(command -v node) ($(node --version 2>/dev/null))"
echo "  pnpm: $(command -v pnpm) ($(pnpm --version 2>/dev/null))"
echo ""
echo "  To deactivate: exit this shell or open a new terminal"
EOF

    chmod +x "${TOOLS_ACTIVATE_SCRIPT}"
    log_success "Activation script created: ${TOOLS_ACTIVATE_SCRIPT}"
}

# Activate local tools environment in current shell
# Usage: prereqs_local_activate
prereqs_local_activate() {
    if [[ ! -f "${TOOLS_ACTIVATE_SCRIPT}" ]]; then
        prereqs_local_create_activate_script
    fi

    # Source the activation script
    # shellcheck source=/dev/null
    source "${TOOLS_ACTIVATE_SCRIPT}"

    log_info "Local tools environment activated"
}

# =============================================================================
# COMPLETE SETUP
# =============================================================================

# Install all local prerequisites (Node.js + pnpm)
# Usage: prereqs_local_setup_all
prereqs_local_setup_all() {
    log_step "Setting up local development tools"
    echo ""

    # Install Node.js
    if ! prereqs_local_install_node; then
        log_error "Node.js installation failed"
        return 1
    fi

    echo ""

    # Install pnpm
    if ! prereqs_local_install_pnpm; then
        log_error "pnpm installation failed"
        return 1
    fi

    echo ""

    # Create activation script
    prereqs_local_create_activate_script

    echo ""
    log_success "Local tools setup complete!"
    log_info "To use local tools in your shell:"
    log_info "  source .toolsrc"
    echo ""

    return 0
}

# Check local tools status and report
# Usage: prereqs_local_status
prereqs_local_status() {
    echo "=== Local Tools Status ==="
    echo ""

    # Node.js
    if prereqs_local_node_exists; then
        echo "✓ Node.js: v$(prereqs_local_node_version)"
        echo "  Location: ${NODE_LOCAL_BIN}"
    else
        echo "✗ Node.js: Not installed"
        echo "  Expected: ${NODE_LOCAL_BIN}"
    fi

    echo ""

    # pnpm
    if prereqs_local_pnpm_exists; then
        echo "✓ pnpm: v$(prereqs_local_pnpm_version)"
        echo "  Location: ${PNPM_LOCAL_BIN}"
    else
        echo "✗ pnpm: Not installed"
        echo "  Expected: ${PNPM_LOCAL_BIN}"
    fi

    echo ""

    # Tools directory size
    if [[ -d "${TOOLS_DIR}" ]]; then
        local size
        size=$(du -sh "${TOOLS_DIR}" 2>/dev/null | cut -f1)
        echo "Tools directory: ${TOOLS_DIR} (${size})"
    else
        echo "Tools directory: Not created"
    fi

    echo "=========================="
}
