#!/bin/bash
# UserPromptSubmit Hook: Start tracking prompt execution
# Runs when user submits a prompt to Claude Code

METRICS_FILE="/home/luce/apps/bloom/.claude/logs/hooks/prompt-metrics.json"

# Capture start time
START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Initialize metrics file for this prompt
# Note: Token counting happens at completion time by parsing the transcript
cat > "$METRICS_FILE" << EOF
{
  "startTime": "$START_TIME",
  "startTokens": 0,
  "endTime": null,
  "endTokens": null,
  "durationMs": null,
  "tokensUsed": null,
  "completed": false
}
EOF

exit 0
