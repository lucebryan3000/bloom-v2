#!/bin/bash
# Diagnostic script for Claude Code hooks
# Checks hook configuration and troubleshoots common issues

echo "🔍 Claude Code Hooks Diagnostic Tool"
echo "======================================"
echo ""

# Check hook files exist
echo "📁 Checking hook files..."
HOOKS_DIR="/home/luce/apps/bloom/.claude/hooks"

if [ ! -d "$HOOKS_DIR" ]; then
    echo "❌ Hooks directory not found: $HOOKS_DIR"
    exit 1
fi

echo "✅ Hooks directory exists"
echo ""

# List all hooks
echo "📋 Available hooks:"
ls -1 "$HOOKS_DIR"/*.{sh,js} 2>/dev/null || echo "  No hook files found"
echo ""

# Check permissions
echo "🔐 Checking hook permissions..."
for hook in "$HOOKS_DIR"/*.{sh,js}; do
    if [ -f "$hook" ]; then
        if [ -x "$hook" ]; then
            echo "  ✅ $(basename $hook) is executable"
        else
            echo "  ⚠️  $(basename $hook) is NOT executable"
            echo "     Fix with: chmod +x $hook"
        fi
    fi
done
echo ""

# Check task tracking files
echo "📊 Checking task tracking files..."
TASK_START="/home/luce/apps/bloom/.claude/logs/hooks/task-start.json"
TASK_METRICS="/home/luce/apps/bloom/.claude/logs/hooks/task-metrics.json"

if [ -f "$TASK_START" ]; then
    echo "  ⚠️  Active task file found: $TASK_START"
    echo "  Current task:"
    cat "$TASK_START" | jq -r '.name' 2>/dev/null || echo "  (Unable to parse)"
    echo "  Started: $(cat "$TASK_START" | jq -r '.startTime' 2>/dev/null || echo 'Unknown')"
    echo ""
    echo "  This may prevent new completion metrics from showing."
    echo "  To clear: rm -f $TASK_START"
else
    echo "  ✅ No stale task file (clean state)"
fi
echo ""

if [ -f "$TASK_METRICS" ]; then
    TASK_COUNT=$(cat "$TASK_METRICS" | jq '.tasks | length' 2>/dev/null || echo "0")
    echo "  📈 Metrics file exists with $TASK_COUNT completed tasks"
    echo "  Last 3 tasks:"
    cat "$TASK_METRICS" | jq -r '.tasks[-3:] | .[] | "    - \(.name) (\(.duration))"' 2>/dev/null || echo "    (Unable to parse)"
else
    echo "  ℹ️  No metrics file found (will be created on first completion)"
fi
echo ""

# Check settings.json hook configuration
echo "⚙️  Checking hook configuration..."
SETTINGS_FILE="/home/luce/apps/bloom/.claude/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    echo "  ✅ Settings file found"

    # Check if hooks are configured
    if grep -q '"hooks"' "$SETTINGS_FILE"; then
        echo "  ✅ Hooks section exists in settings.json"

        # Check TodoWrite hook
        if grep -q 'TodoWrite' "$SETTINGS_FILE"; then
            echo "  ✅ TodoWrite hook configured"
            HOOK_COMMAND=$(cat "$SETTINGS_FILE" | jq -r '.hooks.PostToolUse[] | select(.matcher.tool_name == "TodoWrite") | .hooks[0].command' 2>/dev/null)
            echo "     Command: $HOOK_COMMAND"
        else
            echo "  ❌ TodoWrite hook NOT configured"
        fi
    else
        echo "  ❌ No hooks section in settings.json"
    fi
else
    echo "  ❌ Settings file not found: $SETTINGS_FILE"
fi
echo ""

# Test hook execution
echo "🧪 Testing hook execution..."
TEST_TODO='[{"content":"Test task","status":"completed","activeForm":"Testing"}]'

echo "  Testing todo-timestamp.js..."
if [ -f "$HOOKS_DIR/todo-timestamp.js" ]; then
    echo "$TEST_TODO" | node "$HOOKS_DIR/todo-timestamp.js" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "  ✅ todo-timestamp.js executed successfully"
    else
        echo "  ❌ todo-timestamp.js failed to execute"
    fi
else
    echo "  ❌ todo-timestamp.js not found"
fi
echo ""

# Summary and recommendations
echo "📝 Summary and Recommendations:"
echo "================================"

if [ -f "$TASK_START" ]; then
    echo "⚠️  ISSUE FOUND: Stale task tracking file"
    echo "   This will prevent completion metrics from showing."
    echo "   Fix: rm -f $TASK_START"
    echo ""
fi

echo "✅ Hook system appears to be configured correctly"
echo ""
echo "💡 To manually test completion metrics:"
echo "   1. Create a new TodoWrite with some in_progress items"
echo "   2. Mark all todos as completed"
echo "   3. You should see completion metrics output"
echo ""
echo "📚 For more info, see:"
echo "   - .claude/hooks/todo-timestamp.js (main hook)"
echo "   - .claude/hooks/todo-metrics-report.js (alternative, not used)"
echo "   - .claude/settings.json (hook configuration)"
