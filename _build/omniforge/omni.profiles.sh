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
)

# Profile 2: FPA_DASHBOARD - Enterprise Financial Planning & Analysis
declare -A PROFILE_FPA_DASHBOARD=(
    [name]="FPA_DASHBOARD"
    [tagline]="High-Integrity Financial Reporting"
    [description]="Secure FP&A dashboard with RBAC, charting, and PDF/Excel reporting"
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
)

# Profile 3: COLLAB_EDITOR - Real-Time Policy & Doc Editor
declare -A PROFILE_COLLAB_EDITOR=(
    [name]="COLLAB_EDITOR"
    [tagline]="Real-Time Document Control"
    [description]="Foundation for real-time apps (WebSockets/CRDT), complex state, async saving"
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
)

# Profile 4: ERP_GATEWAY - BOS-ERP Data Synchronization API
declare -A PROFILE_ERP_GATEWAY=(
    [name]="ERP_GATEWAY"
    [tagline]="Secure Data Synchronization Layer"
    [description]="API-only profile for high-volume data sync with ERP (ETL/service auth)"
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
)

# Profile 5: ASSET_MANAGER - Custom Internal Asset Management Tool
declare -A PROFILE_ASSET_MANAGER=(
    [name]="ASSET_MANAGER"
    [tagline]="Excel Replacement / Core CRUD"
    [description]="Core CRUD template replacing spreadsheets (high UI, heavy DB, reporting)"
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
)

# Profile 6: TECH_STACK - Full Tech Stack Coverage
declare -A PROFILE_TECH_STACK=(
    [name]="TECH_STACK"
    [tagline]="Full Tech Stack Coverage"
    [description]="Enable every component under tech_stack/ to validate end-to-end installs (great for --dry-run smoke checks)"
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
