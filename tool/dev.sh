#!/usr/bin/env bash
# Developer task runner. Usage: tool/dev.sh <command>
set -euo pipefail
cd "$(dirname "$0")/.."
case "${1:-help}" in
  setup)    flutter pub get && flutter gen-l10n ;;
  run)      flutter run ;;
  run-web)  flutter run -d chrome --web-port 8787 ;;
  format)   dart format lib test integration_test ;;
  analyze)  flutter analyze --fatal-infos ;;
  test)     flutter test ;;
  test-web) flutter test --platform chrome test/services/rppg test/services/export_test.dart test/services/frame_processing_test.dart test/features/measurement/domain_test.dart ;;
  test-integration) flutter test integration_test/app_flow_test.dart -d "${2:?device id}" ;;
  build-web) flutter build web --release --no-web-resources-cdn --no-source-maps ;;
  build-android) flutter build appbundle --release && tool/check_android_permissions.sh ;;
  build-apk) flutter build apk --release --split-per-abi && tool/check_android_permissions.sh ;;
  build-ios) flutter build ipa --release ;;
  verify-models) tool/verify_models.sh ;;
  licenses) tool/check_licenses.sh ;;
  ci) "$0" format && git diff --exit-code && "$0" analyze && "$0" test && "$0" test-web && "$0" verify-models ;;
  *) sed -n '2,3p' "$0"; grep -E '^  [a-z-]+\)' "$0" | sed 's/).*//' ;;
esac
