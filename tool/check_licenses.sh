#!/usr/bin/env bash
# Lists the licence family of every resolved runtime dependency and fails on
# strong copyleft licences that would conflict with app-store distribution.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import json, os, re, sys
cfg = json.load(open(".dart_tool/package_config.json"))
deny = re.compile(r"GNU (AFFERO )?GENERAL PUBLIC LICENSE", re.I)
bad = []
for p in cfg["packages"]:
    root = p["rootUri"].replace("file://", "")
    if not os.path.isabs(root):
        continue
    lic = next((os.path.join(root, n) for n in ("LICENSE", "LICENSE.md", "LICENSE.txt") if os.path.exists(os.path.join(root, n))), None)
    if lic is None:
        print(f"{p['name']:40s} <no LICENSE file>")
        continue
    text = open(lic, errors="ignore").read(4000)
    kind = ("Apache-2.0" if "Apache License" in text else
            "MIT" if "Permission is hereby granted" in text else
            "BSD" if "Redistribution and use in source and binary forms" in text else
            "GPL-family" if deny.search(text) else "other")
    print(f"{p['name']:40s} {kind}")
    if kind == "GPL-family":
        bad.append(p["name"])
if bad:
    print("Copyleft dependencies found:", ", ".join(bad)); sys.exit(1)
PY
