#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

DOC_DIR="docs/playbooks"
mkdir -p "${DOC_DIR}"

SPEC_FILE="${DOC_DIR}/PLAYBOOK_SPEC_V1.md"

if [[ -f "${SPEC_FILE}" ]]; then
  echo "${SPEC_FILE} already exists, skipping."
  exit 0
fi

cat > "${SPEC_FILE}" <<'EOF'
# Playbook Specification v1 (Markdown)

This document defines the **authoring format** for Bloom playbooks.
Playbooks are written in Markdown and then compiled into structured JSON (`PlaybookCompiled`)
for runtime execution by Melissa.ai.

## Frontmatter Block

At the top of each playbook:

- `slug`: unique identifier (e.g., `bottleneck_throughput_v1`)
- `category`: logical grouping (`Throughput`, `ROI`, `EX`, `CX`, `Data`, etc.)
- `objective`: one-sentence description of the playbook's purpose
- `protocol`: which ChatProtocol to use (e.g., `bloom_ifl_v1`)
- `persona`: which Melissa persona slug to use (e.g., `melissa_v2`)

Example:

```md
# Playbook: Enterprise Bottleneck & Throughput Accelerator
slug: bottleneck_throughput_v1
category: Throughput
objective: Identify the top 1–3 bottlenecks in a critical workflow and estimate capacity gains.
protocol: bloom_ifl_v1
persona: melissa_v2
```

## Phases

List the phases this playbook will use. These must map to IFL phases
defined in the ChatProtocol:

- `greet_frame`
- `discover_probe`
- `validate_quantify`
- `synthesize_reflect`
- `advance_close`

Example:

```md
## Phases
- greet_frame
- discover_probe
- validate_quantify
- synthesize_reflect
- advance_close
```

## Questions

Questions are defined as a YAML-like list under `## Questions`.

Each question requires:

- `id`: unique ID within the playbook
- `phase`: one of the phases above
- `type`: `free_text` | `single_choice` | `multi_choice` | `scale`
- `text`: question text shown to the user
- optional `options`: for choice or scale questions

Example:

```md
## Questions
- id: q_intro_scope
  phase: greet_frame
  type: free_text
  text: "In one sentence, which part of your operation feels most clogged right now?"

- id: q_where_clogs
  phase: discover_probe
  type: free_text
  text: "Where does work tend to pile up or wait for someone?"

- id: q_frequency
  phase: validate_quantify
  type: scale
  text: "How often does this bottleneck cause delays in a typical week?"
  options: ["rarely", "1-2 times", "3-5 times", "daily", "multiple times per day"]
```

## Local Rules (Optional)

A `## Rules` section can provide local overrides within the global ChatProtocol:

```md
## Rules
forceCompliance: false
localMaxQuestions: 15
```

These will be compiled into `PlaybookCompiled.rulesOverrides`.

## Scoring Model (Optional)

A `## Scoring` section can describe how this playbook scores responses:

```md
## Scoring
dimensions:
  - id: impact
    label: "Impact"
    weight: 0.6
  - id: ease
    label: "Ease of Fix"
    weight: 0.4
```

The compiler will convert this into `PlaybookCompiled.scoringModel`.

## Report Spec (Optional)

A `## Report` section describes how to build the Insight Bloom report
for this playbook:

```md
## Report
sections:
  - id: exec_summary
    label: "Executive Summary"
  - id: bottlenecks
    label: "Identified Bottlenecks"
  - id: recommendations
    label: "Recommendations"
```

The compiler will convert this into `PlaybookCompiled.reportSpec`.

EOF

echo "Markdown Playbook spec created at ${SPEC_FILE}"
