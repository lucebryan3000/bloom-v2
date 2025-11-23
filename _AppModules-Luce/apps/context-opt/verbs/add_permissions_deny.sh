#!/usr/bin/env bash
verb_register "add_permissions_deny" "verb::add_permissions_deny::preview" "verb::add_permissions_deny::apply"
_verb_deny_preview(){ python3 - "$1" "$@" <<'PY'
import json, sys
p=sys.argv[1]; adds=sys.argv[2:]
d=json.load(open(p,'r',encoding='utf-8'))
perm=d.setdefault("permissions",{}); deny=perm.setdefault("deny",[])
missing=[x for x in adds if x not in deny]
print(json.dumps({"add":missing},indent=2))
PY
}
_verb_deny_apply(){ python3 - "$1" "$@" <<'PY'
import json, sys
p=sys.argv[1]; adds=sys.argv[2:]
d=json.load(open(p,'r',encoding='utf-8'))
perm=d.setdefault("permissions",{}); deny=perm.setdefault("deny",[])
for x in adds:
  if x not in deny: deny.append(x)
print(json.dumps(d,indent=2,ensure_ascii=False))
PY
}
verb::add_permissions_deny::preview(){ local rel="$1" abs="$2"; shift 2; local adds=( "$@" ); [[ -f "$abs" ]] || { ui_warn "$rel not found"; return 0; } ; local rep; rep="$(_verb_deny_preview "$abs" "${adds[@]}")"; preview_step "[Apply/Settings] ID: apply.settings" "Add permissions.deny entries to block heavy paths" "Proposed additions:\n$rep" "Restore backup" "Write access to $rel"; }
verb::add_permissions_deny::apply(){ local rel="$1" abs="$2"; shift 2; local adds=( "$@" ); [[ -f "$abs" ]] || { ui_warn "$rel not found"; return 0; } ; local tmp; tmp="$(mktemp)"; _verb_deny_apply "$abs" "${adds[@]}" > "$tmp"; ui_info "Diff:"; diff -u "$abs" "$tmp" || true; if ! confirm_gate 1 1; then rm -f "$tmp"; return 0; fi; if ! double_confirm_if_critical 1; then rm -f "$tmp"; return 0; fi; local bak; bak="$(backup_file "$abs")"; if [[ "${DRY_RUN:-0}" -eq 1 ]]; then ui_warn "(dry-run)"; rm -f "$tmp"; return 0; fi; mv -f "$tmp" "$abs"; ui_result "Updated $rel (backup: $bak)"; }
