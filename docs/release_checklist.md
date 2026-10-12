# Release checklist

Nothing here implies store approval. Acceptance depends on review, current
policies, disclosures and testing at submission time.

Legend: ✅ done in repo · ⬜ to do · ⚠️ blocked/needs decision

## 0. Product and legal (all platforms)

* ⬜ Final product name (replace placeholder "Stillbeat": `--dart-define=APP_NAME`,
  `android/app/build.gradle` `appName`, iOS `CFBundleDisplayName`,
  `web/index.html`, `web/manifest.json`). Run a trademark search.
* ⬜ App icon and launch assets (current icons are Flutter defaults).
* ⬜ Privacy policy hosted over HTTPS; pass via
  `--dart-define=PRIVACY_POLICY_URL=…` and `SUPPORT_URL=…`. Content must match
  docs/privacy.md.
* ⚠️ Regulatory review per target market. Heart-rate estimation may be a
  medical device feature depending on claims and intended use (e.g. EU MDR,
  US FDA, UK MHRA, Saudi SFDA). Keep marketing to "experimental /
  informational". Do not claim accuracy until docs/validation_protocol.md is
  executed.
* ⚠️ Patent freedom-to-operate for POS/CHROM (docs/model_evaluation.md).
* ⚠️ Neural models: blocked on licensing; ship without.
* ⬜ Run docs/validation_protocol.md, or at minimum a pilot, and update the
  in-app limitations text with the results.
* ⬜ Physical-device testing on ≥3 Android and ≥2 iOS devices (docs/testing.md
  "Not yet tested").
* ⬜ Measure per-frame and per-window processing time and memory on a
  low-end Android device; set performance budgets.
* ⬜ Accessibility pass with TalkBack, VoiceOver and keyboard-only on web.

## 1. Google Play

* ⬜ Application ID: replace `com.example.stillbeat` in
  `android/app/build.gradle` (`namespace` and `applicationId`; also move
  `MainActivity.kt` package). Play rejects `com.example.*`.
* ✅ Versioning from `pubspec.yaml` `version:` (`0.1.0+1`); bump the build
  number for every upload.
* ✅ Release build config: R8 minify + resource shrinking, `allowBackup=false`,
  backup/transfer exclusions.
* ✅ Signing reads `android/key.properties` (git-ignored) or
  `STILLBEAT_KEYSTORE_PATH`, `STILLBEAT_KEYSTORE_PASSWORD`, `STILLBEAT_KEY_ALIAS`,
  `STILLBEAT_KEY_PASSWORD`. Without them the release is **debug-signed and must
  not be uploaded**.
  ```properties
  # android/key.properties (never commit)
  storeFile=/absolute/path/upload-keystore.jks
  storePassword=…
  keyAlias=upload
  keyPassword=…
  ```
  Create: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
  Enrol in Play App Signing.
* ✅ AAB: `tool/dev.sh build-android` →
  `build/app/outputs/bundle/release/app-release.aab` (built locally,
  44.5 MB, debug-signed).
* ✅ Permissions: release requests only `CAMERA` (verified by
  `tool/check_android_permissions.sh`).
* ✅ targetSdk 35 / compileSdk 35 / minSdk 23. ⬜ Re-check Play's current
  target-API deadline at submission.
* ⬜ Data safety form (suggested, verify against final build):
  data collected: none transmitted off device; health info (heart rate)
  stored on device only; no sharing; data can be deleted in app; no
  encryption-in-transit question applies because nothing is transmitted.
* ⬜ Camera permission justification: "Measures colour changes of the face
  during a user-started measurement; frames are not stored or transmitted."
* ⬜ Health apps declaration / health-features policy questionnaire.
* ⬜ Store listing: description must state experimental/not medical;
  screenshots (phone, 7" and 10" tablet), feature graphic.
* ⬜ Internal testing track → closed testing (new personal accounts must meet
  Play's closed-testing requirements before production).

## 2. Apple App Store

* ⬜ Bundle ID: set `PRODUCT_BUNDLE_IDENTIFIER` in
  `ios/Runner.xcodeproj` (currently `com.example.stillbeat`).
* ✅ `NSCameraUsageDescription` present; no microphone/photo/location keys.
* ✅ Deployment target 15.5 (ML Kit requirement); Podfile sets
  `PERMISSION_CAMERA=1` only.
* ✅ `ITSAppUsesNonExemptEncryption = false`.
* ⚠️ **Not built**: this environment has no full Xcode/CocoaPods. On a Mac:
  `sudo xcode-select -s /Applications/Xcode.app`, `sudo gem install cocoapods`
  (or Homebrew), `cd ios && pod install`, then `tool/dev.sh build-ios`.
  Expect to fix any ML Kit/Pods issues on first build.
* ⬜ Exclude the database from iCloud backup (`NSURLIsExcludedFromBackupKey`)
  or document that history is backed up.
* ⬜ Signing: Apple Developer team, automatic signing or a distribution
  certificate + provisioning profile kept outside the repo; CI uses App
  Store Connect API keys stored as secrets.
* ⬜ Privacy manifest (`PrivacyInfo.xcprivacy`) for the app and confirm
  third-party SDK manifests (ML Kit) are present; required-reason APIs.
* ⬜ App Privacy label: health data (heart rate) not collected/transmitted by
  the app; review Google ML Kit's disclosures for metrics it may send on iOS.
* ⬜ Review notes: explain the camera use, that results are experimental, and
  provide a demo path (reviewers may test in poor light).
* ⬜ Screenshots (6.9", 6.5", iPad if supported), metadata, age rating.
* ⬜ TestFlight internal → external testing.

## 3. Web

* ✅ `tool/dev.sh build-web` (no CDN, bundled fonts, no source maps).
* ✅ Header templates in `deploy/` (HSTS, CSP, Permissions-Policy, etc.).
* ⬜ Deploy over HTTPS; verify CSP doesn't block CanvasKit
  (`wasm-unsafe-eval`) in each target browser.
* ⬜ Browser support statement: tested Chrome (headless, fake camera).
  Firefox lacks `requestVideoFrameCallback` (polling fallback, untested on
  hardware); Safari untested. The web build has no face detector (guide
  heuristic) — disclose on the site.
* ⬜ Privacy policy and terms links on the site.

## 4. Before every release

* ⬜ `tool/dev.sh ci` green; CI green on all jobs.
* ⬜ `tool/check_android_permissions.sh` on the final AAB.
* ⬜ `tool/verify_models.sh` (models manifest empty unless cleared).
* ⬜ THIRD_PARTY_NOTICES.md and in-app licence page reviewed.
* ⬜ CHANGELOG.md updated; version bumped.
