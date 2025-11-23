#!/usr/bin/env bash
# =============================================================================
# File: phases/05-ai/19-prompts-structure.sh
# Purpose: Create src/prompts folder structure with stub files
# Assumes: Project exists with src directory
# Creates: src/prompts/*.ts prompt templates
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="19"
readonly SCRIPT_NAME="prompts-structure"
readonly SCRIPT_DESCRIPTION="Create Melissa AI prompt structure"

# =============================================================================
# USAGE
# =============================================================================
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

$SCRIPT_DESCRIPTION

OPTIONS:
    -h, --help      Show this help message and exit
    -n, --dry-run   Show what would be done without making changes
    -v, --verbose   Enable verbose output

EXAMPLES:
    $(basename "$0")              # Create prompt files
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Creates system.ts - Core Melissa persona and rules
    2. Creates discovery.ts - Discovery phase prompts
    3. Creates quantification.ts - Metric extraction prompts
    4. Creates validation.ts - Review phase prompts
    5. Creates synthesis.ts - Report generation prompts

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting prompts structure creation"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Initialize project first"
    ensure_dir "src/prompts"

    # Step 2: Create system.ts
    log_step "Creating src/prompts/system.ts"

    local system_prompt='import type { SessionState } from "@/lib/ai.types";

/**
 * System Prompt - Melissa AI Core Persona
 *
 * Defines Melissa'\''s identity, capabilities, and behavioral rules.
 * This is the foundation of all AI interactions in Bloom2.
 *
 * TODO: Customize this prompt for your specific use case
 */

/**
 * Core persona definition
 */
const PERSONA = `You are Melissa, an expert ROI workshop facilitator for Bloom2.

Your role is to guide users through structured ROI discovery sessions,
helping them identify, quantify, and validate the value of their initiatives.

## Your Personality
- Professional but warm and approachable
- Patient and thorough in exploration
- Focused on extracting concrete, measurable data
- Supportive when users are uncertain

## Your Capabilities
- Guide discovery conversations to uncover value drivers
- Extract and structure quantitative metrics
- Calculate ROI using established methodologies
- Generate executive-ready reports and narratives

## Your Limitations
- You cannot access external systems or databases
- You rely on user-provided information
- You flag uncertainty rather than making assumptions
`;

/**
 * Safety and behavioral rules
 */
const RULES = `## Rules You Must Follow

1. NEVER make up numbers - always ask for clarification
2. NEVER promise specific ROI outcomes before analysis
3. ALWAYS cite the source of metrics (user-provided vs calculated)
4. ALWAYS flag low-confidence extractions for human review
5. MAINTAIN professional boundaries - you are a facilitator, not a consultant
6. PROTECT confidentiality - never reference other sessions or clients
`;

/**
 * Response format instructions
 */
const FORMAT = `## Response Format

- Keep responses concise and focused
- Use bullet points for lists of metrics or questions
- When extracting metrics, use this format:
  **[Metric Name]**: [Value] [Unit] (Confidence: High/Medium/Low)
- Ask one question at a time during discovery
- Summarize key points at natural breakpoints
`;

/**
 * Build the complete system prompt
 */
export function buildSystemPrompt(sessionState?: SessionState): string {
  let prompt = `${PERSONA}\n\n${RULES}\n\n${FORMAT}`;

  // Inject session context if available
  if (sessionState) {
    prompt += `\n\n## Current Session Context

Session ID: ${sessionState.sessionId}
Current Phase: ${sessionState.phase}
Overall Confidence: ${(sessionState.confidence * 100).toFixed(0)}%

### Extracted Metrics So Far
${sessionState.metrics.length > 0
  ? sessionState.metrics.map(m =>
      `- ${m.name}: ${m.value} ${m.unit || ""} (${(m.confidence * 100).toFixed(0)}% confidence)`
    ).join("\n")
  : "No metrics extracted yet."}

### Open Questions
${sessionState.openQuestions.length > 0
  ? sessionState.openQuestions.map(q => `- ${q}`).join("\n")
  : "No open questions."}
`;
  }

  return prompt;
}

/**
 * Get system prompt for a session
 *
 * This is the main export used by the chat API route.
 */
export async function getSystemPrompt(sessionId?: string): Promise<string> {
  // TODO: Fetch session state from database
  // For now, return base prompt
  return buildSystemPrompt();
}

export { PERSONA, RULES, FORMAT };
'

    write_file "src/prompts/system.ts" "$system_prompt"

    # Step 3: Create discovery.ts
    log_step "Creating src/prompts/discovery.ts"

    local discovery_prompt='/**
 * Discovery Phase Prompts
 *
 * Used during the initial exploration phase where Melissa
 * helps users identify value drivers and gather baseline data.
 *
 * TODO: Customize these prompts for your specific domain
 */

/**
 * Opening prompt for new sessions
 */
export const DISCOVERY_OPENING = `Let'\''s begin our ROI discovery session. I'\''ll guide you through a structured exploration to identify and quantify the value of your initiative.

To start, could you briefly describe the initiative or project we'\''ll be analyzing today? What problem does it solve, and who benefits from it?`;

/**
 * Follow-up prompts by topic area
 */
export const DISCOVERY_PROMPTS = {
  /** Understanding the current state */
  currentState: `To establish our baseline, I need to understand the current situation.
- What processes or systems exist today?
- How much time or resources are currently spent?
- What are the main pain points or inefficiencies?`,

  /** Identifying stakeholders */
  stakeholders: `Let'\''s identify who is affected by this initiative:
- Who are the primary users or beneficiaries?
- How many people are impacted?
- Are there any secondary stakeholders we should consider?`,

  /** Time and effort metrics */
  timeMetrics: `I'\''d like to quantify the time impact:
- How many hours per week/month are spent on this task?
- How many people perform this task?
- What is the average time to complete one cycle?`,

  /** Cost metrics */
  costMetrics: `Let'\''s explore the financial aspects:
- What is the current cost of the existing solution?
- What are the hidden costs (errors, delays, rework)?
- Are there any opportunity costs we should consider?`,

  /** Quality and risk metrics */
  qualityMetrics: `Now let'\''s look at quality and risk:
- What is the current error or defect rate?
- How often do issues occur?
- What is the cost of each error or incident?`,
} as const;

/**
 * Transition prompt to quantification phase
 */
export const DISCOVERY_TO_QUANTIFICATION = `Excellent! We'\''ve gathered good foundational information. I'\''d like to move into the quantification phase where we'\''ll assign specific numbers to the value drivers we'\''ve identified.

Before we proceed, is there anything else about the current state that we should capture?`;

/**
 * Get appropriate discovery prompt based on context
 */
export function getDiscoveryPrompt(
  topic: keyof typeof DISCOVERY_PROMPTS
): string {
  return DISCOVERY_PROMPTS[topic];
}
'

    write_file "src/prompts/discovery.ts" "$discovery_prompt"

    # Step 4: Create quantification.ts
    log_step "Creating src/prompts/quantification.ts"

    local quantification_prompt='/**
 * Quantification Phase Prompts
 *
 * Used when Melissa is extracting specific metrics and
 * calculating potential ROI values.
 *
 * TODO: Customize extraction rules for your domain
 */

/**
 * Metric extraction instructions
 *
 * These are injected into the system prompt when
 * the session is in quantification phase.
 */
export const EXTRACTION_INSTRUCTIONS = `## Metric Extraction Mode

You are now in quantification mode. When the user provides numeric information:

1. Extract the metric with its exact value and unit
2. Assign a confidence level based on:
   - HIGH: Direct user statement with specific numbers
   - MEDIUM: User estimate or range
   - LOW: Inferred from context or assumed
3. Note the source text that supports this metric

Always confirm extracted values with the user before recording.`;

/**
 * Structured output format for metrics
 */
export const METRIC_OUTPUT_FORMAT = `When you extract a metric, format it as:

\`\`\`metric
name: [Metric Name]
value: [Numeric Value]
unit: [Unit of measurement]
min: [Minimum if range]
max: [Maximum if range]
confidence: [HIGH|MEDIUM|LOW]
source: "[Quote from user]"
perspective: [financial|cultural|customer|employee]
\`\`\``;

/**
 * Prompts for different metric categories
 */
export const QUANTIFICATION_PROMPTS = {
  /** Time savings */
  timeSavings: `Let'\''s quantify the time savings:
- How many minutes/hours will be saved per task?
- How many times is this task performed per month?
- What is the hourly cost of the people performing this task?`,

  /** Cost reduction */
  costReduction: `Let'\''s calculate the cost reduction:
- What is the current cost we'\''re trying to reduce?
- What percentage reduction do you expect?
- Over what time period?`,

  /** Revenue impact */
  revenueImpact: `Let'\''s explore the revenue potential:
- How might this increase revenue?
- What is the average transaction value?
- How many additional transactions might result?`,

  /** Risk reduction */
  riskReduction: `Let'\''s quantify the risk mitigation:
- What is the probability of the risk occurring?
- What is the cost if the risk materializes?
- What reduction in probability or impact do you expect?`,
} as const;

/**
 * Confidence calibration prompt
 */
export const CONFIDENCE_CALIBRATION = `For each metric, I'\''ll assess my confidence:

- **High confidence**: You provided a specific number from actual data
- **Medium confidence**: You provided an estimate or reasonable range
- **Low confidence**: I'\''m inferring this from context

Would you like to adjust any of these confidence levels?`;

export function getQuantificationPrompt(
  category: keyof typeof QUANTIFICATION_PROMPTS
): string {
  return QUANTIFICATION_PROMPTS[category];
}
'

    write_file "src/prompts/quantification.ts" "$quantification_prompt"

    # Step 5: Create validation.ts
    log_step "Creating src/prompts/validation.ts"

    local validation_prompt='/**
 * Validation Phase Prompts
 *
 * Used during the human-in-the-loop review process
 * where users confirm or adjust extracted metrics.
 *
 * TODO: Customize validation flows for your needs
 */

/**
 * Validation opening prompt
 */
export const VALIDATION_OPENING = `We'\''ve extracted several metrics from our conversation. Before we calculate the final ROI, I'\''d like you to review and confirm these values.

I'\''ll present each metric for your review. You can:
- **Confirm** if the value is accurate
- **Adjust** if you have a more precise number
- **Flag** if you'\''re unsure and need more research

Ready to begin the review?`;

/**
 * Individual metric review prompt template
 */
export function getMetricReviewPrompt(metric: {
  name: string;
  value: number;
  unit?: string;
  confidence: string;
  source: string;
}): string {
  return `## Reviewing: ${metric.name}

**Current Value**: ${metric.value} ${metric.unit || ""}
**Confidence**: ${metric.confidence}
**Source**: "${metric.source}"

Is this value accurate? Please respond with:
- "Confirm" to accept as-is
- "Adjust to [new value]" to change it
- "Flag" if you need to verify this later`;
}

/**
 * Conflict resolution prompts
 */
export const CONFLICT_PROMPTS = {
  /** When values seem inconsistent */
  inconsistency: `I noticed a potential inconsistency between these metrics. Could you help clarify?`,

  /** When values seem unusually high/low */
  outlier: `This value seems [higher/lower] than typical. Is this correct, or should we adjust?`,

  /** When user overrides AI extraction */
  override: `I'\''ve updated the value based on your input. For the audit trail, could you briefly explain the reason for this change?`,
} as const;

/**
 * Summary before ROI calculation
 */
export const PRE_CALCULATION_SUMMARY = `Here'\''s a summary of all validated metrics:

[Metrics will be listed here]

Overall data confidence: [X]%

Shall I proceed with the ROI calculation using these values?`;

/**
 * Transition to synthesis
 */
export const VALIDATION_TO_SYNTHESIS = `All metrics have been reviewed and validated. We'\''re now ready to generate your ROI report.

The report will include:
- Executive summary
- Detailed metric breakdown
- ROI calculations with multiple scenarios
- Recommendations

Would you like to proceed, or is there anything you'\''d like to adjust first?`;
'

    write_file "src/prompts/validation.ts" "$validation_prompt"

    # Step 6: Create synthesis.ts
    log_step "Creating src/prompts/synthesis.ts"

    local synthesis_prompt='/**
 * Synthesis Phase Prompts
 *
 * Used when generating final reports and narratives
 * from validated session data.
 *
 * TODO: Customize report templates for your audience
 */

/**
 * Report generation instructions
 */
export const SYNTHESIS_INSTRUCTIONS = `## Report Generation Mode

You are now generating the final ROI report. Follow these guidelines:

1. Write for a CFO/executive audience
2. Lead with the bottom line (total ROI)
3. Support claims with validated metrics
4. Acknowledge uncertainty with confidence levels
5. Use conservative estimates (minimum of ranges)
6. Include clear methodology explanation`;

/**
 * Executive summary template
 */
export const EXECUTIVE_SUMMARY_TEMPLATE = `## Executive Summary

[Initiative Name] presents a compelling ROI opportunity with a projected return of **[X]%** over [time period].

**Key Findings:**
- [Top value driver 1]
- [Top value driver 2]
- [Top value driver 3]

**Investment Required:** [Amount]
**Projected Return:** [Amount]
**Payback Period:** [Time]
**Data Confidence:** [X]%`;

/**
 * Value perspective templates
 */
export const PERSPECTIVE_TEMPLATES = {
  financial: `### Financial Impact
[Narrative about direct cost savings, revenue gains, and financial metrics]`,

  cultural: `### Cultural Impact
[Narrative about employee satisfaction, engagement, and organizational health]`,

  customer: `### Customer Impact
[Narrative about customer satisfaction, retention, and experience improvements]`,

  employee: `### Employee Impact
[Narrative about productivity, satisfaction, and talent retention]`,
} as const;

/**
 * Methodology section
 */
export const METHODOLOGY_SECTION = `## Methodology

This analysis uses the **Ironclad Baseline** approach:
- All projections use the minimum value of provided ranges
- Only metrics with medium or higher confidence are included in calculations
- ROI is calculated using: (Total Benefits - Total Costs) / Total Costs × 100

**Data Sources:**
- User-provided estimates and actuals
- Industry benchmarks (where noted)
- Historical data (where available)`;

/**
 * Get narrative prompt for a specific perspective
 */
export function getPerspectiveNarrative(
  perspective: keyof typeof PERSPECTIVE_TEMPLATES,
  metrics: Array<{ name: string; value: number; unit?: string }>
): string {
  const template = PERSPECTIVE_TEMPLATES[perspective];
  const metricList = metrics
    .map(m => `- ${m.name}: ${m.value} ${m.unit || ""}`)
    .join("\n");

  return `${template}\n\n**Supporting Metrics:**\n${metricList}`;
}

/**
 * Final report assembly prompt
 */
export const ASSEMBLE_REPORT = `Based on all validated metrics and calculations, generate a complete ROI report with:

1. Executive Summary (2-3 paragraphs)
2. Detailed Findings by Value Perspective
3. ROI Calculation Breakdown
4. Risk Factors and Assumptions
5. Recommendations
6. Appendix: Raw Metrics Table

Write in a professional tone suitable for board presentation.`;
'

    write_file "src/prompts/synthesis.ts" "$synthesis_prompt"

    # Step 7: Update index.ts
    log_step "Updating src/prompts/index.ts"

    local prompts_index='/**
 * Melissa AI Prompts
 *
 * Prompts-as-code for consistent AI behavior across sessions.
 *
 * @see docs/ARCHITECTURE-README.md for prompt design principles
 */

export * from "./system";
export * from "./discovery";
export * from "./quantification";
export * from "./validation";
export * from "./synthesis";
'

    write_file "src/prompts/index.ts" "$prompts_index"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
