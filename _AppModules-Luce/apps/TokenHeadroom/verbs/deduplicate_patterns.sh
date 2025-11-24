#!/usr/bin/env bash
# verbs/deduplicate_patterns.sh — TokenHeadroom: Deduplicate ignore patterns verb

verb_register "deduplicate_patterns" "verb::deduplicate_patterns::preview" "verb::deduplicate_patterns::apply"
verb::deduplicate_patterns::preview(){ local rel="$1" abs="$2"; [[ -f "$abs" ]] || { ui_info "$rel not found."; return 0; } ; local tmp; tmp="$(mktemp)"; awk '!seen[$0]++' "$abs" > "$tmp"; ui_info "Diff (duplicates removed):"; diff -u "$abs" "$tmp" || true; rm -f "$tmp"; preview_step "[Apply/Ignores] ID: apply.ignores" "Remove duplicate lines while preserving comments" "awk '!seen[\$0]++' $rel" "Restore backup" "Write access to $rel"; }
verb::deduplicate_patterns::apply(){ local rel="$1" abs="$2"; [[ -f "$abs" ]] || { ui_info "$rel not found."; return 0; } ; local tmp; tmp="$(mktemp)"; awk '!seen[$0]++' "$abs" > "$tmp"; ui_info "Diff:"; diff -u "$abs" "$tmp" || true; if ! confirm_gate 1 0; then rm -f "$tmp"; return 0; fi; local bak; bak="$(backup_file "$abs")"; if [[ "${DRY_RUN:-0}" -eq 1 ]]; then ui_warn "(dry-run)"; rm -f "$tmp"; return 0; fi; mv -f "$tmp" "$abs"; ui_result "Updated $rel (backup: $bak)"; }
