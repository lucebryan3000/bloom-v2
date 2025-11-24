#!/usr/bin/env bash
# =============================================================================
# lib/scaffold.sh - Project Template Deployment
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Deploys template files from example-files/ to project root for user reference.
# These templates document what OmniForge creates and serve as examples.
#
# Philosophy:
#   - Templates are REFERENCE files (.example suffix)
#   - Generated files are WORKING copies (no suffix)
#   - Templates must match their generators (validated in CI)
#
# Exports:
#   scaffold_deploy_all, scaffold_deploy_toolsrc_example,
#   scaffold_validate_templates
#
# Dependencies:
#   lib/logging.sh, bootstrap.conf (TEMPLATE_*, OMNIFORGE_EXAMPLE_FILES_DIR)
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_SCAFFOLD_LOADED:-}" ]] && return 0
_LIB_SCAFFOLD_LOADED=1

# =============================================================================
# TEMPLATE DEPLOYMENT
# =============================================================================

# Deploy all required template files
# Usage: scaffold_deploy_all
scaffold_deploy_all() {
    log_debug "Checking project templates"

    local deployed=0

    # Deploy .toolsrc.example
    if scaffold_deploy_toolsrc_example; then
        ((deployed++))
    fi

    # Future templates can be added here:
    # if scaffold_deploy_gitattributes_example; then ((deployed++)); fi
    # if scaffold_deploy_readme_example; then ((deployed++)); fi

    if [[ $deployed -gt 0 ]]; then
        log_success "Deployed $deployed template file(s)"
    fi

    return 0
}

# Deploy .toolsrc.example template
# Usage: scaffold_deploy_toolsrc_example
scaffold_deploy_toolsrc_example() {
    local source="${TEMPLATE_TOOLSRC}"
    local target="${PROJECT_ROOT}/.toolsrc.example"

    # Skip if already exists
    if [[ -f "$target" ]]; then
        log_debug "Template exists: .toolsrc.example"
        return 1
    fi

    # Verify source exists
    if [[ ! -f "$source" ]]; then
        log_warn "Template not found: $source"
        return 1
    fi

    # Deploy template
    if cp "$source" "$target"; then
        log_info "Deployed: .toolsrc.example"
        return 0
    else
        log_error "Failed to deploy: .toolsrc.example"
        return 1
    fi
}

# =============================================================================
# VALIDATION
# =============================================================================

# Validate templates match their generators
# Usage: scaffold_validate_templates
scaffold_validate_templates() {
    log_step "Validating templates"

    local errors=0

    # Validate .toolsrc.example matches generator
    if ! scaffold_validate_toolsrc_template; then
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "All templates valid"
        return 0
    else
        log_error "Template validation failed ($errors error(s))"
        return 1
    fi
}

# Validate .toolsrc.example matches prereqs_local_create_activate_script()
# Usage: scaffold_validate_toolsrc_template
scaffold_validate_toolsrc_template() {
    local template="${TEMPLATE_TOOLSRC}"
    local generated="/tmp/.toolsrc.generated.$$"

    # Check if template exists
    if [[ ! -f "$template" ]]; then
        log_error ".toolsrc.example not found at: $template"
        return 1
    fi

    # Generate fresh copy to temp location
    local original_script="${TOOLS_ACTIVATE_SCRIPT}"
    TOOLS_ACTIVATE_SCRIPT="$generated"

    if ! prereqs_local_create_activate_script; then
        log_error "Failed to generate .toolsrc for validation"
        TOOLS_ACTIVATE_SCRIPT="$original_script"
        return 1
    fi

    TOOLS_ACTIVATE_SCRIPT="$original_script"

    # Compare content (ignore empty lines and comments with dates/timestamps)
    local template_content generated_content
    template_content=$(grep -v '^$' "$template" | grep -v '^# Generated' | grep -v '^# =============')
    generated_content=$(grep -v '^$' "$generated" | grep -v '^# Generated' | grep -v '^# =============')

    if [[ "$template_content" == "$generated_content" ]]; then
        log_success ".toolsrc.example matches generator"
        rm -f "$generated"
        return 0
    else
        log_error ".toolsrc.example differs from generator"
        log_info "Compare with: diff ${template} ${generated}"
        log_info "To update template: cp ${generated} ${template}"
        return 1
    fi
}
