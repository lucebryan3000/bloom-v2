#!/usr/bin/env bash
# verbs/prune_alwaysInclude.sh — TokenHeadroom: Prune alwaysInclude verb

verb_register "prune_alwaysInclude" "verb::prune_alwaysInclude::preview" "verb::prune_alwaysInclude::apply"
_verb_prune_preview_json(){ python3 - "$1" <<'PY'
import json, os, sys
p=sys.argv[1]; data=json.load(open(p,'r',encoding='utf-8'))
ctx=data.setdefault("context",{}); ai=list(ctx.get("alwaysInclude",[]) or [])
missing=[x for x in ai if isinstance(x,str) and not os.path.exists(x)]
print(json.dumps({"missing":missing,"count":len(missing)},indent=2))
PY
}
_verb_prune_apply_json(){ python3 - "$1" <<'PY'
import json, os, sys
p=sys.argv[1]; data=json.load(open(p,'r',encoding='utf-8'))
ctx=data.setdefault("context",{}); ai=[x for x in (ctx.get("alwaysInclude",[]) or []) if isinstance(x,str) and os.path.exists(x)]
ctx["alwaysInclude"]=ai; print(json.dumps(data,indent=2,ensure_ascii=False))
PY
}
verb::prune_alwaysInclude::preview(){ local rel="$1" abs="$2"; [[ -f "$abs" ]] || { ui_warn "$rel not found"; return 0; } ; local report; report="$(_verb_prune_preview_json "$abs")"; preview_step "[Apply/Settings] ID: apply.settings" "Remove non-existent paths from context.alwaysInclude" "JSON patch: prune missing alwaysInclude entries\n$report" "Restore backup" "Write access to $rel"; }
verb::prune_alwaysInclude::apply(){ local rel="$1" abs="$2"; [[ -f "$abs" ]] || { ui_warn "$rel not found"; return 0; } ; local tmp; tmp="$(mktemp)"; _verb_prune_apply_json "$abs" > "$tmp"; ui_info "Diff:"; diff -u "$abs" "$tmp" || true; if ! confirm_gate 1 1; then rm -f "$tmp"; return 0; fi; if ! double_confirm_if_critical 1; then rm -f "$tmp"; return 0; fi; local bak; bak="$(backup_file "$abs")"; if [[ "${DRY_RUN:-0}" -eq 1 ]]; then ui_warn "(dry-run)"; rm -f "$tmp"; return 0; fi; mv -f "$tmp" "$abs"; ui_result "Updated $rel (backup: $bak)"; }
