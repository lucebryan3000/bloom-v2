#!/usr/bin/env bash
# =============================================================================
# omni.profiles.sh
# Canonical profile data for OmniForge.
# PROFILE_* arrays and AVAILABLE_PROFILES were moved here from bootstrap.conf.
# =============================================================================

# Profile 1: AI_AUTOMATION - Document Processing & Workflows
declare -A PROFILE_AI_AUTOMATION=(
    [name]="AI_AUTOMATION"
    [tagline]="Intelligent Process Automation"
    [description]="BOS portal for document processing, RAG, and background AI workflows"
    [mode]="dev"
    [time_estimate]="~80 minutes"
    [recommended]="false"
    [ENABLE_NEXTJS]="true"
    [ENABLE_DATABASE]="true"
    [ENABLE_AUTHJS]="true"
    [ENABLE_AI_SDK]="true"
    [ENABLE_PG_BOSS]="true"
    [ENABLE_SHADCN]="true"
    [ENABLE_ZUSTAND]="false"
    [ENABLE_PDF_EXPORTS]="false"
    [ENABLE_TEST_INFRA]="true"
    [ENABLE_CODE_QUALITY]="true"
    [APP_AUTO_INSTALL]="true"
    [GIT_SAFETY]="false"
    [ALLOW_DIRTY]="true"
    [STRICT_TESTS]="true"
    [WARN_POLICY]="strict"
)

# Profile 2: FPA_DASHBOARD - Enterprise Financial Planning & Analysis
declare -A PROFILE_FPA_DASHBOARD=(
    [name]="FPA_DASHBOARD"
    [tagline]="High-Integrity Financial Reporting"
    [description]="Secure FP&A dashboard with RBAC, charting, and PDF/Excel reporting"
    [mode]="dev"
    [time_estimate]="~70 minutes"
    [recommended]="false"
    [ENABLE_NEXTJS]="true"
    [ENABLE_DATABASE]="true"
    [ENABLE_AUTHJS]="true"
    [ENABLE_AI_SDK]="false"
    [ENABLE_PG_BOSS]="false"
    [ENABLE_SHADCN]="true"
    [ENABLE_ZUSTAND]="true"
    [ENABLE_PDF_EXPORTS]="true"
    [ENABLE_TEST_INFRA]="true"
    [ENABLE_CODE_QUALITY]="true"
    [APP_AUTO_INSTALL]="true"
    [GIT_SAFETY]="false"
    [ALLOW_DIRTY]="true"
    [STRICT_TESTS]="true"
    [WARN_POLICY]="strict"
)

# Profile 3: COLLAB_EDITOR - Real-Time Policy & Doc Editor
declare -A PROFILE_COLLAB_EDITOR=(
    [name]="COLLAB_EDITOR"
    [tagline]="Real-Time Document Control"
    [description]="Foundation for real-time apps (WebSockets/CRDT), complex state, async saving"
    [mode]="dev"
    [time_estimate]="~75 minutes"
    [recommended]="false"
    [ENABLE_NEXTJS]="true"
    [ENABLE_DATABASE]="true"
    [ENABLE_AUTHJS]="true"
    [ENABLE_AI_SDK]="false"
    [ENABLE_PG_BOSS]="true"
    [ENABLE_SHADCN]="true"
    [ENABLE_ZUSTAND]="true"
    [ENABLE_PDF_EXPORTS]="false"
    [ENABLE_TEST_INFRA]="true"
    [ENABLE_CODE_QUALITY]="true"
    [APP_AUTO_INSTALL]="true"
    [GIT_SAFETY]="false"
    [ALLOW_DIRTY]="true"
    [STRICT_TESTS]="false"
    [WARN_POLICY]="warn"
)

# Profile 4: ERP_GATEWAY - BOS-ERP Data Synchronization API
declare -A PROFILE_ERP_GATEWAY=(
    [name]="ERP_GATEWAY"
    [tagline]="Secure Data Synchronization Layer"
    [description]="API-only profile for high-volume data sync with ERP (ETL/service auth)"
    [mode]="dev"
    [time_estimate]="~60 minutes"
    [recommended]="false"
    [ENABLE_NEXTJS]="true"
    [ENABLE_DATABASE]="true"
    [ENABLE_AUTHJS]="true"
    [ENABLE_AI_SDK]="false"
    [ENABLE_PG_BOSS]="true"
    [ENABLE_SHADCN]="false"
    [ENABLE_ZUSTAND]="false"
    [ENABLE_PDF_EXPORTS]="false"
    [ENABLE_TEST_INFRA]="true"
    [ENABLE_CODE_QUALITY]="true"
    [APP_AUTO_INSTALL]="true"
    [GIT_SAFETY]="false"
    [ALLOW_DIRTY]="true"
    [STRICT_TESTS]="true"
    [WARN_POLICY]="strict"
)

# Profile 5: ASSET_MANAGER - Custom Internal Asset Management Tool
declare -A PROFILE_ASSET_MANAGER=(
    [name]="ASSET_MANAGER"
    [tagline]="Excel Replacement / Core CRUD"
    [description]="Core CRUD template replacing spreadsheets (high UI, heavy DB, reporting)"
    [mode]="dev"
    [time_estimate]="~65 minutes"
    [recommended]="true"
    [ENABLE_NEXTJS]="true"
    [ENABLE_DATABASE]="true"
    [ENABLE_AUTHJS]="true"
    [ENABLE_AI_SDK]="false"
    [ENABLE_PG_BOSS]="true"
    [ENABLE_SHADCN]="true"
    [ENABLE_ZUSTAND]="true"
    [ENABLE_PDF_EXPORTS]="true"
    [ENABLE_TEST_INFRA]="true"
    [ENABLE_CODE_QUALITY]="true"
    [APP_AUTO_INSTALL]="true"
    [GIT_SAFETY]="false"
    [ALLOW_DIRTY]="true"
    [STRICT_TESTS]="true"
    [WARN_POLICY]="strict"
)

# Profile 6: TECH_STACK - Full Tech Stack Coverage
declare -A PROFILE_TECH_STACK=(
    [name]="TECH_STACK"
    [tagline]="Full Tech Stack Coverage"
    [description]="Enable every component under tech_stack/ to validate end-to-end installs (great for --dry-run smoke checks)"
    [mode]="dev"
    [time_estimate]="~90 minutes"
    [recommended]="false"
    [ENABLE_NEXTJS]="true"
    [ENABLE_DATABASE]="true"
    [ENABLE_AUTHJS]="true"
    [ENABLE_AI_SDK]="true"
    [ENABLE_PG_BOSS]="true"
    [ENABLE_SHADCN]="true"
    [ENABLE_ZUSTAND]="true"
    [ENABLE_PDF_EXPORTS]="true"
    [ENABLE_TEST_INFRA]="true"
    [ENABLE_CODE_QUALITY]="true"
    [APP_AUTO_INSTALL]="true"
    [GIT_SAFETY]="false"
    [ALLOW_DIRTY]="true"
    [STRICT_TESTS]="true"
    [WARN_POLICY]="strict"
)

# Available profiles (order matters - shown in this order in menu)
AVAILABLE_PROFILES=("ai_automation" "fpa_dashboard" "collab_editor" "erp_gateway" "asset_manager" "tech_stack")

# Default dry-run behavior per profile (used if user does not specify -n/--dry-run)
declare -A PROFILE_DRY_RUN=(
    [ai_automation]="false"
    [fpa_dashboard]="false"
    [collab_editor]="false"
    [erp_gateway]="false"
    [asset_manager]="false"
    [tech_stack]="true"
)

# Resource hints per profile (used for container runs; host just logs)
# Units: memory in Docker format (e.g., 2g), cpu in cores (e.g., 1.5)
declare -A PROFILE_RESOURCES=(
    [ai_automation]="memory=4g cpu=2"
    [fpa_dashboard]="memory=4g cpu=2"
    [collab_editor]="memory=4g cpu=2"
    [erp_gateway]="memory=3g cpu=1.5"
    [asset_manager]="memory=4g cpu=2"
    [tech_stack]="memory=6g cpu=2"
)
