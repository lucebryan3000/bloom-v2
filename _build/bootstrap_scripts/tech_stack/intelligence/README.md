# Intelligence Phase Bootstrap Scripts

This directory contains bootstrap scripts for the **Intelligence Layer** - the core AI and business logic engine of Bloom2. These scripts set up:

1. **Melissa AI Prompt System** - Multi-phase AI assistant for business case discovery, quantification, validation, and synthesis
2. **ROI Engine** - Deterministic ROI calculation with conservative/base/aggressive scenarios
3. **Confidence Engine** - Weighted confidence scoring and uncertainty quantification
4. **HITL Review Queue** - Human-in-the-Loop governance with audit trails

## Scripts

### melissa-prompts.sh

Sets up the Melissa AI persona and phase-based prompting system.

**Creates:**
- `src/prompts/system.ts` - System prompt defining Melissa's persona (skeptical, truth-first analyst)
- `src/prompts/discovery.ts` - Discovery phase prompt for identifying metrics and value drivers
- `src/prompts/quantification.ts` - Quantification phase prompt for collecting metrics and building estimates
- `src/prompts/validation.ts` - Validation phase prompt for checking consistency and identifying uncertainties
- `src/prompts/synthesis.ts` - Synthesis phase prompt for building narrative and recommendations
- `src/prompts/phaseRouter.ts` - Phase state machine and routing logic

**Key Features:**
- Phase-driven conversation flow (Discovery → Quantification → Validation → Synthesis)
- Metric tagging with source and confidence level
- Do-nothing baseline reference
- Contradiction detection and flagging
- Assumption tracking and validation
- Behavioral rules (no invented metrics, skepticism about round numbers)

**Reference:** PRD Section 6.3 - Melissa AI Assistant

---

### roi-engine.sh

Sets up deterministic ROI calculation engine.

**Creates:**
- `src/lib/roi.ts` - Core ROI calculator with three-scenario analysis
- `src/schemas/roi.ts` - Zod validation schemas for ROI inputs/outputs

**Key Functions:**

```typescript
calculateROI(input: ROIInput): ROIOutput
```

**Input Metrics:**
- Process baseline: volume_per_period, cycle_time_minutes, team_size_affected, labor_cost_per_hour
- Error impact: error_rate_percent, rework_time_minutes, error_cost_per_incident
- Improvement: improvement_efficiency_percent, improvement_error_reduction_percent, implementation_cost

**Output (Three Scenarios: Conservative/Base/Aggressive):**
- Annual time saved (hours)
- Annual labor savings ($)
- Annual error cost reduction ($)
- Total annual savings ($)
- ROI percentage (%)
- Payback period (months)
- Multi-dimensional Improvement Index (financial/operational/human/composite, 0-1 scale)

**Calculation Logic:**
- **Conservative:** 80% of projected savings
- **Base:** 100% of projected savings
- **Aggressive:** 120% of projected savings

**Improvement Index:**
- Financial: ROI% / 100 (capped at 1.0)
- Operational: (efficiency_% + error_reduction_%) / 200
- Human: (efficiency_% + error_reduction_%) / 100 (capped at 1.0)
- Composite: Finance 40% + Operational 35% + Human 25%

**Reference:** PRD Section 6.5 - ROI Engine

---

### confidence-engine.sh

Sets up confidence scoring and uncertainty quantification.

**Creates:**
- `src/lib/confidence.ts` - Confidence calculator and snapshot builder
- `src/schemas/confidence.ts` - Zod validation schemas

**Key Functions:**

```typescript
calculateMetricConfidence(input): MetricConfidence
createSessionConfidenceSnapshot(input): SessionConfidenceSnapshot
getConfidenceNarrative(snapshot): string
```

**Confidence Factors (0-1 scale):**

| Factor | Weight | Options |
|--------|--------|---------|
| Data Quality | 30% | Direct (1.0), User (0.85), Estimated (0.65), Benchmark (0.5) |
| Measurement Precision | 25% | Exact (1.0), Narrow (0.8), Wide (0.6), Very Wide (0.4) |
| Stakeholder Agreement | 20% | Unanimous (1.0), Majority (0.85), Split (0.6), Contradictory (0.3) |
| Source Reliability | 25% | Data System (1.0), Expert (0.9), Staff (0.7), Guess (0.4) |

**Confidence Thresholds:**
- **High Confidence:** > 0.75 (ready for export)
- **Medium Confidence:** 0.55-0.75 (ready for review)
- **Low Confidence:** < 0.55 (requires investigation)

**Session-Level Metrics:**
- `overall_confidence` - Weighted average across all metrics
- `data_completeness` - % of key metrics captured
- `assumption_clarity` - 0.85 if documented, 0.5 if not
- `high_uncertainty_metrics` - Metrics < 0.6 confidence
- `ready_for_review` - overall_confidence > 0.6 && no unresolved contradictions
- `ready_for_export` - overall_confidence > 0.75 && no unresolved contradictions

**Reference:** PRD Section 6.6 - Confidence & Uncertainty Engine

---

### hitl-review-queue.sh

Sets up Human-in-the-Loop review governance with immutable audit trails.

**Creates:**
- `src/lib/reviewQueue.ts` - Review item management and action application
- `src/schemas/review.ts` - Zod validation schemas

**Review Item Types:**
- `low_confidence_metric` - Confidence < 0.6
- `contradiction` - Conflicting data points
- `flagged_assumption` - High-impact assumptions
- `outlier_value` - Values outside expected ranges
- `missing_data` - Required metrics not provided

**Reviewer Actions:**
- `accept` - Validate and confirm data
- `adjust` - Correct value slightly
- `reject` - Remove from analysis
- `replace` - Replace with different value
- `mark_as_assumption` - Reframe as assumption
- `escalate` - Route to management

**Priority Scoring:**
- Contradictions: 90 (highest)
- Low confidence metrics: 80-70 (based on severity)
- Flagged assumptions: 70
- Other items: 50-60

**Audit Trail:**
Every change creates immutable audit log entry:
- What changed (metric name, old/new value)
- Who changed it (AI/human actor ID)
- When (timestamp)
- Why (rationale)
- What was affected (related metrics, ROI impact)

**Key Functions:**

```typescript
createReviewItems(input): ReviewItem[]
applyReviewerAction(input): { updated_metrics, updated_confidence, audit_log_entry }
generateReviewSummary(items): { total_items, critical_count, warning_count, by_type, next_review_item }
```

**Confidence Adjustment Logic:**
- Accept: +5% confidence (slight boost from validation)
- Adjust: -10% confidence (penalty for correction)
- Reject: remove metric entirely

**Reference:** PRD Section 6.8 - Human-in-the-Loop Governance

---

## Phase Integration

These scripts work together in sequence:

1. **Melissa Prompts** → Extracts metrics and assumptions
2. **Confidence Engine** → Scores data quality and uncertainty
3. **ROI Engine** → Calculates financial impact
4. **HITL Review Queue** → Routes high-uncertainty items for review

### Data Flow

```
Melissa AI
  ↓ (metrics, assumptions, source, confidence)
Confidence Engine
  ↓ (confidence scores, flagged items)
ROI Engine
  ↓ (financial scenarios)
Review Queue
  ↓ (items needing human review)
Human Review
  ↓ (human decision + rationale)
Audit Log
```

## Shared Data Structures

All intelligence scripts use these core types (defined in `src/lib/` and `src/schemas/`):

- `Metric` - name, value, unit, confidence, source
- `ConfidenceSnapshot` - overall confidence, data quality factors
- `ROIOutput` - three-scenario financial analysis
- `ReviewItem` - high-uncertainty or contradictory data
- `ReviewerAction` - human decision and rationale
- `AuditLogEntry` - immutable change record

## Environment & Configuration

Set these in `bootstrap.conf` to control intelligence features:

```bash
# Feature flags (intelligence phase)
ENABLE_MELISSA_AI="true"        # Enable AI discovery phase
ENABLE_CONFIDENCE_SCORING="true" # Enable confidence engine
ENABLE_ROI_ENGINE="true"        # Enable financial calculations
ENABLE_HITL_REVIEW="true"       # Enable human review queue
```

## Dependencies

These scripts require:

- **Packages:** `zod` (validation), `@ai-sdk/anthropic` (AI client)
- **Database:** Sessions table (created by db phase)
- **Environment:** `ANTHROPIC_API_KEY` (for Melissa AI)

## Testing

Each intelligence module exports types and functions suitable for unit testing:

```bash
pnpm test src/lib/roi.test.ts
pnpm test src/lib/confidence.test.ts
pnpm test src/lib/reviewQueue.test.ts
```

## Next Steps

After intelligence phase bootstrap:

1. **Settings** → Configure confidence thresholds per user
2. **Export** → Format business cases for sharing
3. **Monitoring** → Track metrics and review queue health
4. **API Routes** → Expose intelligence functions as endpoints

---

**Last Updated:** Bootstrap System v2.0
**Reference:** Bloom2 PRD Sections 6.3, 6.5, 6.6, 6.8
