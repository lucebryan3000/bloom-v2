# **Appmelia Bloom — Playbook Engine Installation Guide**

*Last updated: 2025-11-15*

This document explains how to install the **Melissa/Bloom Playbook Engine architecture** using the auto-generated scripts, and what you get after installation.

This guide is the canonical reference for:

* Installing the **new schema + engine**
* Understanding the **Persona → Protocol → Playbook** architecture
* Using the **installation script bundles** (Phase 1 & Phase 2)
* Understanding how the new system replaces the prototype structures

---

# **1. Overview of the New Architecture**

Bloom now uses a **three-layer configuration model**:

```
MelissaPersona  →  ChatProtocol  →  PlaybookCompiled
(who she is)       (how she behaves)     (what she is doing)
```

### These feed into the runtime engine:

```
Persona + Protocol + PlaybookCompiled + SessionContext
          ↓
 Prompt Builder (system + user prompt generator)
          ↓
 IFL Engine (Intelligent Facilitation Loop)
          ↓
 User Responses
          ↓
 Insight Bloom Report
```

### Authoring Flow

Playbooks are **authored in Markdown (`PlaybookSource`)**, then compiled into structured JSON (`PlaybookCompiled`) for runtime.

The Markdown format is defined in:

```
docs/playbooks/PLAYBOOK_SPEC_V1.md
```

---

# **2. What the Script Bundles Provide**

Two script bundles automate installation of the foundation.

### **Phase 1 bundle includes:**

| File                      | Purpose                                        |
| ------------------------- | ---------------------------------------------- |
| `install.sh`              | Orchestrates Phase 1 tasks                     |
| `1_schema_and_migrate.sh` | Adds Prisma models + migration + seeds         |
| `2_config_services.sh`    | Adds persona/protocol/playbook services        |
| `3_markdown_spec.sh`      | Adds the Markdown playbook spec                |
| `4_compile_pipeline.sh`   | Adds Markdown → JSON compiler                  |
| `5_settings_prompt.sh`    | Adds a Claude Code prompt to build Settings UI |
| `6_session_context.sh`    | Adds the SessionContext runtime type           |

### **Phase 2 bundle includes:**

| File                          | Purpose                                           |
| ----------------------------- | ------------------------------------------------- |
| `install_phase2.sh`           | Orchestrates Phase 2 tasks                        |
| `7_ifl_and_prompt_builder.sh` | Adds IFL engine + prompt builder                  |
| `8_tests_prompt.sh`           | Adds Claude Code prompt for engine/compiler tests |
| `9_cleanup_prompt.sh`         | Adds Claude Code prompt for prototype cleanup     |

---

# **3. Installation Instructions**

Make sure both zip files are extracted into:

```
bloom/_build-prompts/Melissa-Playbooks/
```

You should see:

```
install.sh
install_phase2.sh
1_schema_and_migrate.sh
2_config_services.sh
...
9_cleanup_prompt.sh
Claude-Settings-Playbook-UI.md
Claude-Tests-IFL-and-Compiler.md
Claude-Cleanup-Prototype-Playbooks.md
```

### **Run Phase 1**

From repo root:

```bash
cd _build-prompts/Melissa-Playbooks
./install.sh
```

This will:

* Update your Prisma schema
* Generate migration
* Seed default persona/protocol/example playbook
* Create all service modules
* Add Markdown spec, compiler, SessionContext

### **Run Phase 2**

```bash
./install_phase2.sh
```

This will:

* Create IFL Engine
* Create PromptBuilder
* Generate Claude Code prompts for tests + cleanup

---

# **4. After Installation — What You Have**

At this point your repo now contains:

### **A. New Prisma Models**

* `MelissaPersona`
* `ChatProtocol`
* `PlaybookSource` (Markdown)
* `PlaybookCompiled` (JSON)

### **B. Supporting Services (`lib/melissa/`)**

* `personaService.ts` - Load persona configurations
* `protocolService.ts` - Load conversation protocols
* `playbookService.ts` - Load playbook sources
* `playbookCompiler.ts` - **✅ IMPLEMENTED** (200+ line parser, Bugs #6 fixed)
* `promptBuilder.ts` - **✅ IMPLEMENTED** (148-line builder, Bug #7 fixed)
* `iflEngine.ts` - **✅ IMPLEMENTED** (Phase progression, Bug #8 fixed)
* `sessionContext.ts` - Session state management

### **C. User-Facing Playbook Authoring**

* `docs/playbooks/PLAYBOOK_SPEC_V1.md`

### **D. Claude-Compatible Prompts for Next Steps**

* `Claude-Settings-Playbook-UI.md`
* `Claude-Tests-IFL-and-Compiler.md`
* `Claude-Cleanup-Prototype-Playbooks.md`

---

# **5. Implementation Status**

### ✅ **Completed (Bugs #1-8 Fixed)**

The following components are **production-ready**:

**Compiler (`playbookCompiler.ts`)** - Bug #6 Fixed
- Full Markdown parser with 5 extraction functions
- Parses phases, questions, rules, scoring, report sections
- 200+ lines of regex-based parsing
- Commit: e88d7c3

**Prompt Builder (`promptBuilder.ts`)** - Bug #7 Fixed
- Persona-aware prompt composition
- Protocol constraint enforcement
- 5 structured sections (System, Playbook, Session, Task, Instructions)
- 148 lines
- Commit: e88d7c3

**IFL Engine (`iflEngine.ts`)** - Bug #8 Fixed
- Phase progression logic
- Automatic phase transitions when questions complete
- Counter management (totalQuestionsAsked, followupCount, driftCount)
- Helper functions: getNextPhase(), isPhaseComplete()
- Completed by local Claude Code: November 14, 2025

**Service Layer** - Bug #5 Fixed
- All services use singleton PrismaClient (no connection pool exhaustion)
- personaService.ts, protocolService.ts, playbookService.ts
- Commit: e88d7c3

**Installation Scripts** - Bugs #1, #3 Fixed
- Path resolution fixed (ROOT_DIR calculation)
- Added `npx prisma generate` step
- All 11 scripts executable and tested
- Commit: e88d7c3

### ⏳ **Remaining Work**

**Database Seeding** - Bug #4 (scripted, awaiting integration)
- Script created: `10_seed_melissa_data.sh`
- Seeds: Persona, Protocol, PlaybookSource, PlaybookCompiled
- Manual integration into `prisma/seed.ts` required

**Testing**
- Compiler unit tests (planned, 2 hours)
- Additional integration tests (planned)

**API Endpoint**
- `/api/melissa/playbook/chat` (not yet created)
- Will use IFL engine for playbook-driven conversations

**Frontend UI**
- Playbook management interface (planned)
- Settings UI for Persona/Protocol configuration (prompt exists)

---

# **6. How the System Works at Runtime**

### **1. Session starts**

* Load default `MelissaPersona`
* Load default `ChatProtocol`
* Load chosen `PlaybookCompiled`

### **2. IFL Engine runs**

* Identify next question
* Build prompt using Persona + Protocol + Playbook
* Ask ONE question per turn
* Store response in `SessionContext` + DB
* Apply follow-up rules, drift checks, etc.
* Move phase → next question (automatic advancement)

### **3. Report Builder (future step)**

* Structured JSON → exported Insight Bloom Report
* Includes:

  * Exec Summary
  * Value Map
  * Confidence Scorecard
  * Insights / Recommendations
  * Provenance Annex

---

# **7. Project Philosophy**

This refactor aligns Melissa with:

* **Deterministic behavior**
* **Spec-driven development**
* **Schema-first architecture**
* **Markdown for authoring**
* **Prisma for runtime configuration**
* **Strict separation of Persona / Protocol / Playbooks**
* **Adaptive IFL engine**

The scripts and prompts ensure the system evolves cleanly and predictably — no more "LLM drifting away from how Bloom should operate."

---

# **8. High-Level Directory Map**

```
bloom/
  prisma/
    schema.prisma
    seed-melissa-playbooks.cjs

  lib/
    melissa/
      personaService.ts
      protocolService.ts
      playbookService.ts
      promptBuilder.ts (✅ IMPLEMENTED)
      iflEngine.ts (✅ IMPLEMENTED)
      playbookCompiler.ts (✅ IMPLEMENTED)
      sessionContext.ts

  docs/
    playbooks/
      PLAYBOOK_SPEC_V1.md

  _build-prompts/
    Melissa-Playbooks/
      install.sh
      install_phase2.sh
      1_schema_and_migrate.sh
      2_config_services.sh
      3_markdown_spec.sh
      4_compile_pipeline.sh
      5_settings_prompt.sh
      6_session_context.sh
      7_ifl_and_prompt_builder.sh
      8_tests_prompt.sh
      9_cleanup_prompt.sh
      10_seed_melissa_data.sh
      Claude-Settings-Playbook-UI.md
      Claude-Tests-IFL-and-Compiler.md
      Claude-Cleanup-Prototype-Playbooks.md
```

---

# **9. Updating / Extending the Engine**

Once your foundation is complete, future extensions are easy:

* Add new playbooks → author Markdown → compile → done
* Add advanced state logic → modify IFL Engine
* Add new persona tones → modify Persona model
* Add new constraints → update ChatProtocol
* Evolve report schema → extend ReportSpec

Everything follows the same stable "Persona → Protocol → PlaybookCompiled" pattern.

---

# **10. Support / Maintenance Notes**

* All destructive schema changes rely on Git rollback — no backward compatibility needed.
* `logs.db` is untouched — logging architecture remains unchanged.
* Sessions continue using your existing `Session`, `Response`, and `ROIReport` tables.
* Everything is SQLite/Prisma friendly (single-instance, local-first).
* If the engine ever behaves unexpectedly, check:

  * The Persona
  * The Protocol constraints
  * The PlaybookCompiled output
  * The SessionContext state

---

# **11. What's Next?**

After installation is complete, see these guides for next steps:

### **Post-Installation Implementation**

📖 **FULL-IMPLEMENTATION-PLAN.md** (760 lines)
- 7-phase completion plan (6-8 hours total)
- Database seeding (Bug #4 fix)
- Compiler unit tests (2 hours)
- IFL engine unit tests (1 hour)
- SQL migration generation (30 mins)
- Minimal test playbook creation (1 hour)
- End-to-end verification (30 mins)

### **Bug Status Tracking**

📋 **BUG-STATUS-SUMMARY.md** (769 lines)
- Detailed status for all 8 bugs
- Bug #1-3, #5-7: ✅ FIXED
- Bug #2: ✅ N/A (Organization exists)
- Bug #4: ⚠️ SCRIPTED (awaiting integration)
- Bug #8: ✅ COMPLETE (November 14, 2025)
- Completion tracking: ~10% → ~85%
- Testing roadmap and priority actions

### **Detailed Implementation Guides**

🔧 **BUG-8-IFL-PHASE-PROGRESSION-FIX.md** (595 lines)
- Complete implementation guide for Bug #8
- Risk assessment (LOW - zero production impact)
- Unit test suite (5 tests)
- Manual testing script
- Rollback plan

📦 **10_seed_melissa_data.sh** (executable)
- Bug #4 fix - database seeding script
- Creates seedMelissaPlaybooks() function
- Ready for integration into prisma/seed.ts

### **Key References**

- **Playbook Format Spec:** `docs/playbooks/PLAYBOOK_SPEC_V1.md`
- **Codex Bug Report:** `MelissaPlaybookCodex-review.md`
- **Claude Analysis:** `MelissaPlaybookClaude-review.md`
- **Project README:** `/bloom/CLAUDE.md` (repo root)

---

## **Done.**

This guide provides everything needed to install the foundation of the Melissa Playbook Engine architecture.

For completing implementation, testing, and production deployment, see **FULL-IMPLEMENTATION-PLAN.md**.

---

*Last updated: 2025-11-15*
*Installation scripts: Phase 1 (1-6) + Phase 2 (7-9) + Seeding (10)*
*Implementation status: ~85% complete*
