#!/usr/bin/env bash
# Verifies every model listed in assets/models/manifest.json exists, matches
# its SHA-256 and declares provenance + licence. An empty list is valid.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import hashlib, json, os, sys
m = json.load(open("assets/models/manifest.json"))
required = {"file", "sha256", "sourceUrl", "license", "trainingData"}
errors = []
for entry in m.get("models", []):
    missing = required - entry.keys()
    if missing:
        errors.append(f"{entry.get('file', '?')}: missing {sorted(missing)}")
        continue
    path = os.path.join("assets/models", entry["file"])
    if not os.path.exists(path):
        errors.append(f"{path}: file not found")
        continue
    digest = hashlib.sha256(open(path, "rb").read()).hexdigest()
    if digest != entry["sha256"].lower():
        errors.append(f"{path}: sha256 {digest} != {entry['sha256']}")
listed = {e.get("file") for e in m.get("models", [])}
for f in os.listdir("assets/models"):
    if f != "manifest.json" and f not in listed:
        errors.append(f"assets/models/{f}: not declared in manifest.json")
if errors:
    print("\n".join(errors)); sys.exit(1)
print(f"model manifest OK ({len(listed)} model(s))")
PY
