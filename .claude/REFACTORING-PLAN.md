# bloom2 Bootstrap Modular Refactoring Plan

## Objective
Refactor the bloom2 bootstrap system from a monolithic structure into a modular, maintainable architecture while preserving all functionality and keeping `bootstrap.conf` as the single source of truth.

## Current State Analysis

### Strengths
- Centralized configuration in `bootstrap.conf` (single source of truth)
- Comprehensive phase system (0-5) with clear dependencies
- 150+ package definitions for flexible stack composition
- Feature flags enable/disable functionality cleanly
- Persistent state tracking prevents duplicate operations
- Rich documentation and knowledge base (25+ technology areas)

### Weaknesses
- **Duplicate Orchestrators**: Two `run-bootstrap.sh` files (root + _build) with different line counts
- **Incomplete Tech Stack**: Only 12/39+ scripts implemented in `tech_stack/`
- **Monolithic Config**: `bootstrap.conf` is 451 lines; hard to navigate
- **Missing Libraries**: Only `common.sh` exists; no utilities for validation, error recovery, packaging
- **Scattered Logic**: Similar functionality reimplemented across scripts

### Critical Gaps
1. No centralized validation/pre-flight checks
2. No error recovery/retry mechanism
3. No dedicated package management utilities
4. No state recovery/rollback support
5. Missing implementations for major phases

---

## Target Architecture

```
_build/bootstrap_scripts/
│
├── bin/
│   ├── bootstrap                    # Main executable (wrapper)
│   └── restore-state               # State recovery tool
│
├── lib/
│   ├── common.sh                   # (existing) Core utilities
│   ├── logging.sh                  # NEW: Logging functions
│   ├── config.sh                   # NEW: Config loading & validation
│   ├── state.sh                    # NEW: State file management
│   ├── validation.sh               # NEW: Pre-flight checks
│   ├── package-manager.sh          # NEW: pnpm/npm integration
│   ├── error-handling.sh           # NEW: Error recovery & retry
│   └── platform.sh                 # NEW: OS detection & compatibility
│
├── modules/
│   ├── foundation/                 # Phase 0: Project Foundation
│   │   ├── init-nextjs.sh
│   │   ├── setup-typescript.sh
│   │   ├── init-git-hooks.sh
│   │   └── validate-environment.sh
│   │
│   ├── infrastructure/             # Phase 1: Infrastructure & DB
│   │   ├── docker-setup.sh
│   │   ├── postgres-init.sh
│   │   ├── drizzle-setup.sh
│   │   ├── redis-setup.sh
│   │   ├── env-templates.sh
│   │   └── preflight-checks.sh
│   │
│   ├── core-features/              # Phase 2: Core Features
│   │   ├── authjs-setup.sh
│   │   ├── ai-sdk-setup.sh
│   │   ├── zustand-setup.sh
│   │   ├── pgboss-setup.sh
│   │   ├── logging-setup.sh
│   │   ├── drizzle-migrations.sh
│   │   ├── seed-database.sh
│   │   └── test-infra-setup.sh
│   │
│   ├── ui-components/              # Phase 3: User Interface
│   │   ├── shadcn-setup.sh
│   │   ├── tailwind-config.sh
│   │   └── theme-system.sh
│   │
│   ├── extensions/                 # Phase 4: Extensions & Quality
│   │   ├── pdfdocument-setup.sh
│   │   ├── pdf-exports.sh
│   │   ├── excel-export.sh
│   │   ├── markdown-export.sh
│   │   ├── json-export.sh
│   │   ├── intelligence-setup.sh
│   │   ├── code-quality.sh
│   │   ├── lint-format.sh
│   │   ├── testing-setup.sh
│   │   ├── vitest-setup.sh
│   │   └── playwright-setup.sh
│   │
│   └── observability/              # Phase 4 (alt): Monitoring
│       ├── health-checks.sh
│       ├── feature-flags.sh
│       └── settings-ui.sh
│
├── bootstrap.conf                  # UNCHANGED: Single source of truth
├── defaults.conf                   # NEW: Fallback values
├── run-bootstrap.sh                # REFACTORED: Single orchestrator
└── README.md                       # NEW: Library documentation
```

---

## Refactoring Phases

### Phase 1: Library Extraction (Foundation)
**Deliverable**: Extract core utilities from `common.sh` into focused libraries

- [ ] Create `lib/logging.sh` with all log functions
- [ ] Create `lib/config.sh` with config loading & validation
- [ ] Create `lib/state.sh` with state file operations
- [ ] Create `lib/validation.sh` with pre-flight checks
- [ ] Create `lib/platform.sh` with OS detection
- [ ] Update `lib/common.sh` to source new libraries
- [ ] Verify all existing scripts still work
- [ ] Document each library module

### Phase 2: Consolidate Orchestrators
**Deliverable**: Single authoritative `run-bootstrap.sh`

- [ ] Compare root vs _build/bootstrap_scripts versions
- [ ] Keep _build version as canonical (more modular)
- [ ] Update root `/run-bootstrap.sh` to simply call _build version
- [ ] Remove duplicate code paths
- [ ] Test all execution modes (phase, script, resume, all)
- [ ] Verify state tracking works consistently

### Phase 3: Error Recovery & Validation Framework
**Deliverable**: Robust error handling and pre-flight validation

- [ ] Create `lib/error-handling.sh` with retry logic
- [ ] Implement checkpoint-based recovery
- [ ] Create `lib/validation.sh` with dependency checks
- [ ] Add pre-flight validation script (run before bootstrap)
- [ ] Test recovery from partial failures
- [ ] Document error codes and recovery procedures

### Phase 4: Package Management Utilities
**Deliverable**: Centralized pnpm/npm integration

- [ ] Create `lib/package-manager.sh` with:
  - Install functions (monorepo-aware)
  - Version verification
  - Dependency resolution
  - Lock file management
- [ ] Extract package install logic from all scripts
- [ ] Add dry-run mode for testing
- [ ] Create package registry interface

### Phase 5: Organize Tech Stack Implementations
**Deliverable**: Implement missing 27 scripts, organize into modules

- [ ] Create `modules/foundation/` and implement Phase 0 scripts
- [ ] Create `modules/infrastructure/` and implement Phase 1 scripts
- [ ] Create `modules/core-features/` and implement Phase 2 scripts
- [ ] Create `modules/ui-components/` and implement Phase 3 scripts
- [ ] Create `modules/extensions/` and implement Phase 4 scripts
- [ ] Move existing tech_stack scripts to appropriate modules
- [ ] Update bootstrap.conf phase definitions to reference new modules
- [ ] Test phase execution sequentially

### Phase 6: Configuration Refactoring
**Deliverable**: Organize bootstrap.conf for clarity and maintainability

- [ ] Split bootstrap.conf into logical sections
  - Section 1: Identity & Paths
  - Section 2: Runtime Versions
  - Section 3: Database Configuration
  - Section 4: Environment Variables
  - Section 5: Feature Flags
  - Section 6: Package Definitions (remains central)
  - Section 7: Phase System Configuration
- [ ] Create `defaults.conf` for fallback values
- [ ] Add section comments and navigation
- [ ] Create config schema documentation
- [ ] Update bootstrap.conf.example

### Phase 7: State Management Improvements
**Deliverable**: Enhanced state tracking and recovery

- [ ] Improve state file format (structured vs flat)
- [ ] Add checkpoint mechanism (save state at phase boundaries)
- [ ] Implement rollback function
- [ ] Create state query commands
- [ ] Add state validation
- [ ] Document state machine

### Phase 8: Documentation & Playbooks
**Deliverable**: Complete documentation of modular architecture

- [ ] Create `/docs/ARCHITECTURE.md` (modules, responsibilities, dependencies)
- [ ] Create `/docs/LIBRARY-REFERENCE.md` (all lib functions, signatures)
- [ ] Create `/docs/MODULE-IMPLEMENTATION.md` (how to add new modules)
- [ ] Create `/docs/ERROR-RECOVERY.md` (error handling strategy)
- [ ] Update `/README.md` to reference new architecture
- [ ] Update Claude Playbooks in `_AppModules-Luce/docs/Melissa-Playbooks/`
- [ ] Create troubleshooting guide

### Phase 9: Testing & Validation
**Deliverable**: Comprehensive testing of refactored system

- [ ] Unit test core libraries (logging, config, state, validation)
- [ ] Integration test phase execution (0-5 in order)
- [ ] Test error recovery scenarios
- [ ] Test feature flag combinations
- [ ] Test NON_INTERACTIVE mode
- [ ] Performance test with large monorepos
- [ ] Create test suite documentation

### Phase 10: Migration & Rollback
**Deliverable**: Safe migration path for existing users

- [ ] Create migration script (from old to new structure)
- [ ] Preserve backward compatibility (at least 1 version)
- [ ] Create rollback procedure
- [ ] Update CHANGELOG
- [ ] Communicate changes to users
- [ ] Monitor for issues during transition

---

## Implementation Strategy

### Approach
1. **Backward Compatible**: New structure works alongside old until migration complete
2. **Incremental**: Deliver one phase at a time; test before moving forward
3. **Modular**: Each library is independent; scripts are stateless
4. **Well-Documented**: Every module has inline documentation and external guide
5. **Thoroughly Tested**: Unit tests for libraries, integration tests for phases

### Dependencies
- Bash 7+ (already required)
- No Python (per constraints)
- bootstrap.conf remains configuration source of truth
- Existing scripts must continue to work

### Success Criteria
- All 39+ scripts implemented and organized
- bootstrap.conf unchanged (only added clarity)
- All phases (0-5) execute successfully
- Error recovery works for common failure scenarios
- Documentation complete and clear
- Test coverage ≥80% for critical paths

---

## Timeline & Effort Estimation

| Phase | Focus | Effort |
|-------|-------|--------|
| 1 | Library extraction | High (foundation)
| 2 | Consolidate orchestrators | Medium |
| 3 | Error recovery | Medium |
| 4 | Package management | Medium |
| 5 | Implement missing scripts | High (many scripts)
| 6 | Config organization | Low (mostly comments)
| 7 | State management | Medium |
| 8 | Documentation | Medium (comprehensive)
| 9 | Testing | High (coverage)
| 10 | Migration & rollback | Medium |

### Token Utilization Note
Each phase can be completed in a single Claude Code session (10 min). Focus on completion over timeline.

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Breaking existing scripts | Maintain backward compatibility; test thoroughly |
| Configuration corruption | Version bootstrap.conf; create backup/restore |
| Incomplete implementations | Prioritize critical phases; defer optional features |
| State inconsistency | Use deterministic state format; validate on load |
| Documentation drift | Auto-generate docs from code where possible |

---

## Success Metrics

- ✅ All 6 phases execute successfully (0-5)
- ✅ bootstrap.conf remains single source of truth
- ✅ 39+ scripts organized and implemented
- ✅ Error recovery prevents repeat failures
- ✅ Documentation covers all modules
- ✅ Test suite validates critical paths
- ✅ Migration path for existing users

---

## Next Steps

1. Start with Phase 1: Library Extraction
2. Create focused, testable library modules
3. Verify all existing scripts continue to work
4. Document each library thoroughly
5. Move to Phase 2: Consolidate Orchestrators
