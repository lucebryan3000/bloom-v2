#!/bin/bash
# Stop Hook: Report prompt execution metrics
# Official Claude Code Stop hook pattern (2025)

# Read JSON input from stdin (provided by Claude Code)
INPUT_JSON=$(cat)

# Log for debugging
DEBUG_LOG="/home/luce/apps/bloom/.claude/logs/hooks/debug.log"
{
  echo "=== Stop Hook Executed at $(date) ==="
  echo "Input received: $INPUT_JSON"
} >> "$DEBUG_LOG" 2>&1

# Check stop_hook_active to prevent infinite loops (per official docs)
STOP_HOOK_ACTIVE=$(echo "$INPUT_JSON" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  echo "Stop hook already active, exiting" >> "$DEBUG_LOG"
  exit 0
fi

# Get metrics file path
METRICS_FILE="/tmp/claude-prompt-metrics.json"

# Exit silently if no metrics file exists
if [ ! -f "$METRICS_FILE" ]; then
  echo "No metrics file found, exiting" >> "$DEBUG_LOG"
  exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
  echo "jq not found, exiting" >> "$DEBUG_LOG"
  exit 0
fi

# Read metrics from file
START_TIME=$(jq -r '.startTime' "$METRICS_FILE" 2>/dev/null)
START_TOKENS=$(jq -r '.startTokens' "$METRICS_FILE" 2>/dev/null)

# Validate we got valid data
if [ -z "$START_TIME" ] || [ "$START_TIME" = "null" ]; then
  echo "Invalid metrics data, exiting" >> "$DEBUG_LOG"
  exit 0
fi

# Extract transcript path from hook input
TRANSCRIPT_PATH=$(echo "$INPUT_JSON" | jq -r '.transcript_path // empty' 2>/dev/null)
echo "Transcript path: $TRANSCRIPT_PATH" >> "$DEBUG_LOG"

# Record end time and extract tokens from transcript
END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Extract token usage from the last assistant message in transcript
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  # Get the last assistant message with usage data (as JSON, not raw)
  LAST_MESSAGE=$(tail -50 "$TRANSCRIPT_PATH" | grep '"type":"assistant"' | tail -1 2>/dev/null)

  if [ -n "$LAST_MESSAGE" ]; then
    # Extract token counts from the message
    INPUT_TOKENS=$(echo "$LAST_MESSAGE" | jq -r '.message.usage.input_tokens // 0' 2>/dev/null)
    OUTPUT_TOKENS=$(echo "$LAST_MESSAGE" | jq -r '.message.usage.output_tokens // 0' 2>/dev/null)
    CACHE_READ=$(echo "$LAST_MESSAGE" | jq -r '.message.usage.cache_read_input_tokens // 0' 2>/dev/null)
    CACHE_CREATE=$(echo "$LAST_MESSAGE" | jq -r '.message.usage.cache_creation_input_tokens // 0' 2>/dev/null)

    # Debug logging
    echo "Token extraction: input=$INPUT_TOKENS, output=$OUTPUT_TOKENS, cache_read=$CACHE_READ, cache_create=$CACHE_CREATE" >> "$DEBUG_LOG"

    # Calculate total tokens (input + output, cache tokens are part of input)
    END_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS + CACHE_READ + CACHE_CREATE))
  else
    echo "No assistant message found in transcript" >> "$DEBUG_LOG"
    END_TOKENS=0
  fi
else
  echo "Transcript path missing or file not found: $TRANSCRIPT_PATH" >> "$DEBUG_LOG"
  END_TOKENS=0
fi

# Calculate duration
START_SECONDS=$(date -d "$START_TIME" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${START_TIME:0:19}" +%s 2>/dev/null)
END_SECONDS=$(date -d "$END_TIME" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${END_TIME:0:19}" +%s 2>/dev/null)

if [ -z "$START_SECONDS" ] || [ -z "$END_SECONDS" ]; then
  echo "Unable to calculate duration, exiting" >> "$DEBUG_LOG"
  exit 0
fi

DURATION_SECONDS=$((END_SECONDS - START_SECONDS))
DURATION_MINUTES=$((DURATION_SECONDS / 60))
DURATION_SECS=$((DURATION_SECONDS % 60))

# Calculate tokens used
TOKENS_USED=$((END_TOKENS - START_TOKENS))

# Calculate cache hit rate (cache_read / total_input_tokens)
TOTAL_INPUT=$((INPUT_TOKENS + CACHE_READ + CACHE_CREATE))
if [ $TOTAL_INPUT -gt 0 ]; then
  CACHE_HIT_RATE=$(awk "BEGIN {printf \"%.1f\", ($CACHE_READ / $TOTAL_INPUT) * 100}")
else
  CACHE_HIT_RATE="0.0"
fi

# Calculate context window usage (assuming 200k limit for Sonnet 4.5)
CONTEXT_LIMIT=200000
CONTEXT_PCT=$(awk "BEGIN {printf \"%.1f\", ($TOTAL_INPUT / $CONTEXT_LIMIT) * 100}")

# Extract tool usage from transcript
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  TOOL_READ=$(grep -c '"name":"Read"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
  TOOL_EDIT=$(grep -c '"name":"Edit"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
  TOOL_WRITE=$(grep -c '"name":"Write"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
  TOOL_BASH=$(grep -c '"name":"Bash"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
  TOOL_GREP=$(grep -c '"name":"Grep"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
  TOOL_GLOB=$(grep -c '"name":"Glob"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
  TOOL_TASK=$(grep -c '"name":"Task"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
  TOOL_OTHER=$(grep '"type":"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null | grep -v -c '"name":"Read"\|"name":"Edit"\|"name":"Write"\|"name":"Bash"\|"name":"Grep"\|"name":"Glob"\|"name":"Task"' || echo 0)
  TOOL_TOTAL=$((TOOL_READ + TOOL_EDIT + TOOL_WRITE + TOOL_BASH + TOOL_GREP + TOOL_GLOB + TOOL_TASK + TOOL_OTHER))
else
  TOOL_TOTAL=0
fi

# Format completion time to CST
CST_TIME=$(TZ='America/Chicago' date -d "$END_TIME" +"%H:%M:%S CST" 2>/dev/null || TZ='CST6CDT' date -j -f "%Y-%m-%dT%H:%M:%S" "${END_TIME:0:19}" +"%H:%M:%S CST" 2>/dev/null)

# Format duration
if [ $DURATION_MINUTES -eq 0 ]; then
  DURATION_STR="${DURATION_SECS}s"
else
  DURATION_STR="${DURATION_MINUTES}m ${DURATION_SECS}s"
fi

# Extract transcript path and user prompt
TRANSCRIPT_PATH=$(echo "$INPUT_JSON" | jq -r '.transcript_path // empty' 2>/dev/null)
TODO_STATUS=""
TASK_SUMMARY=""
USER_PROMPT=""

if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  # Extract user prompt - find last user message with string content (not tool_results)
  USER_PROMPT=$(grep '"type":"user"' "$TRANSCRIPT_PATH" | tac | while read -r line; do
    CONTENT_TYPE=$(echo "$line" | jq -r '.message.content | type' 2>/dev/null)
    if [ "$CONTENT_TYPE" = "string" ]; then
      CONTENT=$(echo "$line" | jq -r '.message.content' 2>/dev/null)
      # Skip system caveats and empty content
      if [[ ! "$CONTENT" =~ ^(Caveat:|======) ]] && [ -n "$CONTENT" ]; then
        # Strip command XML tags (<command-message>, <command-name>, etc.)
        CLEAN_CONTENT=$(echo "$CONTENT" | sed -E 's/<command-[^>]+>//g; s/<\/command-[^>]+>//g; s/^[[:space:]]+//; s/[[:space:]]+$//')
        # Skip if content is now empty or just command metadata
        if [ -n "$CLEAN_CONTENT" ] && [[ ! "$CLEAN_CONTENT" =~ ^is\ running ]]; then
          echo "$CLEAN_CONTENT" | head -c 80
          exit 0
        fi
      fi
    fi
  done)
  if [ ${#USER_PROMPT} -eq 80 ]; then
    USER_PROMPT="${USER_PROMPT}..."
  fi
  # Get all TodoWrite tool uses from transcript and find the last non-empty one
  # Read transcript line by line, extract todos arrays, keep the last non-empty one
  TODO_JSON=""

  while IFS= read -r line; do
    if echo "$line" | grep -q '"name":"TodoWrite"'; then
      # Extract the full input object using jq
      EXTRACTED=$(echo "$line" | jq -r '.message.content[] | select(.name == "TodoWrite") | .input.todos // empty' 2>/dev/null)

      if [ -n "$EXTRACTED" ] && [ "$EXTRACTED" != "[]" ]; then
        TODO_JSON="$EXTRACTED"
      fi
    fi
  done < "$TRANSCRIPT_PATH"

  if [ -n "$TODO_JSON" ] && [ "$TODO_JSON" != "[]" ]; then
    TODO_COUNT=$(echo "$TODO_JSON" | jq 'length' 2>/dev/null || echo 0)
    COMPLETED_COUNT=$(echo "$TODO_JSON" | jq '[.[] | select(.status == "completed")] | length' 2>/dev/null || echo 0)
    IN_PROGRESS_COUNT=$(echo "$TODO_JSON" | jq '[.[] | select(.status == "in_progress")] | length' 2>/dev/null || echo 0)
    PENDING_COUNT=$(echo "$TODO_JSON" | jq '[.[] | select(.status == "pending")] | length' 2>/dev/null || echo 0)

    if [ "$TODO_COUNT" -gt 0 ]; then
      # Build task summary with completed tasks listed
      COMPLETED_TASKS=$(echo "$TODO_JSON" | jq -r '[.[] | select(.status == "completed") | .content] | .[]' 2>/dev/null)

      if [ -n "$COMPLETED_TASKS" ] && [ "$COMPLETED_COUNT" -gt 0 ]; then
        TASK_SUMMARY="📝 Completed Tasks:"
        while IFS= read -r task; do
          if [ -n "$task" ]; then
            # Truncate long task names to 60 chars
            if [ ${#task} -gt 60 ]; then
              task="${task:0:57}..."
            fi
            TASK_SUMMARY="$TASK_SUMMARY
   ✓ $task"
          fi
        done <<< "$COMPLETED_TASKS"
        TASK_SUMMARY="$TASK_SUMMARY
"
      fi
    fi
  fi
fi

# If no completed tasks, show user prompt as identifier
if [ -z "$TASK_SUMMARY" ] && [ -n "$USER_PROMPT" ]; then
  TASK_SUMMARY="💬 Prompt: $USER_PROMPT
"
fi

# Build tool usage summary
TOOL_SUMMARY=""
if [ $TOOL_TOTAL -gt 0 ]; then
  TOOL_SUMMARY="🔧 Tools Used: $TOOL_TOTAL calls"
  TOOL_DETAILS=""
  [ $TOOL_READ -gt 0 ] && TOOL_DETAILS="${TOOL_DETAILS} | 📖 Read: $TOOL_READ"
  [ $TOOL_EDIT -gt 0 ] && TOOL_DETAILS="${TOOL_DETAILS} | ✏️  Edit: $TOOL_EDIT"
  [ $TOOL_WRITE -gt 0 ] && TOOL_DETAILS="${TOOL_DETAILS} | 📝 Write: $TOOL_WRITE"
  [ $TOOL_BASH -gt 0 ] && TOOL_DETAILS="${TOOL_DETAILS} | 💻 Bash: $TOOL_BASH"
  [ $TOOL_GREP -gt 0 ] && TOOL_DETAILS="${TOOL_DETAILS} | 🔍 Grep: $TOOL_GREP"
  [ $TOOL_GLOB -gt 0 ] && TOOL_DETAILS="${TOOL_DETAILS} | 📁 Glob: $TOOL_GLOB"
  [ $TOOL_TASK -gt 0 ] && TOOL_DETAILS="${TOOL_DETAILS} | 🤖 Task: $TOOL_TASK"
  [ $TOOL_OTHER -gt 0 ] && TOOL_DETAILS="${TOOL_DETAILS} | 🔧 Other: $TOOL_OTHER"
  # Remove leading " | "
  TOOL_DETAILS="${TOOL_DETAILS# | }"
  if [ -n "$TOOL_DETAILS" ]; then
    TOOL_SUMMARY="$TOOL_SUMMARY
   $TOOL_DETAILS"
  fi
fi

# Build completion report
REPORT=$(cat <<EOF

======================================================================
📊 PROMPT EXECUTION COMPLETE
======================================================================${TASK_SUMMARY:+
$TASK_SUMMARY}
⏱️  Duration:  $DURATION_STR
⏰ Completed: ${CST_TIME:-$END_TIME}

🔢 Tokens:    $(printf "%'d" $TOKENS_USED 2>/dev/null || echo $TOKENS_USED) consumed
   📥 Input: $(printf "%'d" $INPUT_TOKENS 2>/dev/null || echo $INPUT_TOKENS) | 📤 Output: $(printf "%'d" $OUTPUT_TOKENS 2>/dev/null || echo $OUTPUT_TOKENS)
   💾 Cache Read: $(printf "%'d" $CACHE_READ 2>/dev/null || echo $CACHE_READ) | ✨ Cache Created: $(printf "%'d" $CACHE_CREATE 2>/dev/null || echo $CACHE_CREATE)
   📊 Cache Hit Rate: ${CACHE_HIT_RATE}%

📈 Context:   $(printf "%'d" $TOTAL_INPUT 2>/dev/null || echo $TOTAL_INPUT) / $(printf "%'d" $CONTEXT_LIMIT 2>/dev/null || echo $CONTEXT_LIMIT) tokens (${CONTEXT_PCT}%)
${TOOL_SUMMARY:+
$TOOL_SUMMARY
}======================================================================

EOF
)

# Echo to stdout (shows in Claude Code terminal)
echo "$REPORT"

# Also log to file for monitoring script
LOG_FILE="/home/luce/apps/bloom/.claude/logs/hooks/execution-log.txt"
echo "$REPORT" >> "$LOG_FILE" 2>&1

# Update metrics file
jq --arg endTime "$END_TIME" \
   --argjson endTokens "$END_TOKENS" \
   --argjson tokensUsed "$TOKENS_USED" \
   --argjson durationMs "$((DURATION_SECONDS * 1000))" \
   '.endTime = $endTime | .endTokens = $endTokens | .tokensUsed = $tokensUsed | .durationMs = $durationMs | .completed = true' \
   "$METRICS_FILE" > "${METRICS_FILE}.tmp" 2>/dev/null

if [ $? -eq 0 ]; then
  mv "${METRICS_FILE}.tmp" "$METRICS_FILE" 2>/dev/null
fi

# Always exit 0 (success) per official docs
exit 0
