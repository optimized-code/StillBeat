#!/usr/bin/env bash
# Fails if the merged release manifest requests any permission outside the
# allow-list. Run after `flutter build apk|appbundle --release`.
set -euo pipefail
cd "$(dirname "$0")/.."

ALLOWED=(
  "android.permission.CAMERA"
  # AndroidX core adds this signature-level permission for its own
  # non-exported dynamic receivers; it grants nothing to other apps.
  "com.example.stillbeat.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
)

manifest=$(find build/app/intermediates -path '*release*' -name AndroidManifest.xml \
  \( -path '*bundle_manifest*' -o -path '*packaged_manifests*' \) | head -1)
if [[ -z "$manifest" ]]; then
  echo "No merged release manifest found; build a release first." >&2
  exit 2
fi

status=0
while read -r perm; do
  ok=false
  for a in "${ALLOWED[@]}"; do [[ "$perm" == "$a" ]] && ok=true; done
  if $ok; then echo "ok        $perm"; else echo "FORBIDDEN $perm"; status=1; fi
done < <(grep -o 'uses-permission[^>]*android:name="[^"]*"' "$manifest" | sed 's/.*android:name="\([^"]*\)"/\1/' | sort -u)

exit $status
