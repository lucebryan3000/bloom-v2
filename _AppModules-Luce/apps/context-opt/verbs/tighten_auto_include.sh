#!/usr/bin/env bash
verb_register "tighten_auto_include" "verb::tighten_auto_include::preview" "verb::tighten_auto_include::apply"
_verb_auto_include_props(){ python3 - "$1" <<'PY'
import json, glob, sys, os
p=sys.argv[1]
d=json.load(open(p,'r',encoding='utf-8'))
pats=(d.get("context",{}) or {}).get("autoIncludePatterns",[]) or []
out=[]
for pat in pats:
  matches=glob.glob(pat, recursive=True)
  if len(matches)>50:
    head=pat.split('/**',1)[0]
    subs=set()
    for m in matches:
      s=m.split('/')
      if len(s)>2 and s[0]==head: subs.add(s[1])
    out.append({"pattern":pat,"count":len(matches),"suggest":[f"{head}/{x}/**/*" for x in sorted(list(subs))[:8]]})
print(json.dumps({"proposals":out},indent=2))
PY
}
verb::tighten_auto_include::preview(){ local rel="$1" abs="$2"; [[ -f "$abs" ]] || { ui_warn "$rel not found"; return 0; } ; local props; props="$(_verb_auto_include_props "$abs")"; preview_step "[Suggest/Settings] ID: suggest.settings" "Proposals to narrow high-match autoIncludePatterns (>50 files)" "$props" "No write in v1" "Review and adjust manually"; }
verb::tighten_auto_include::apply(){ ui_warn "tighten_auto_include is preview-only in v1; no write performed."; }
