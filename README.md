# Stillbeat — experimental camera-based heart-rate estimation

> **Not a medical device.** This app provides experimental camera-based
> physiological estimates for informational and research purposes only.
> Results are not a medical diagnosis and must not be used to make medical
> decisions. Accuracy has not been clinically validated.

"Stillbeat" is a configurable placeholder name (`--dart-define=APP_NAME=…`).

A Flutter app for Android, iOS and web that estimates heart rate from a live
front-camera feed using remote photoplethysmography (rPPG). Processing
happens entirely on the device; nothing is recorded or uploaded.

## What it does

* Guided onboarding with a mandatory limitations acknowledgement.
* Live camera measurement with a face guide, positioning, lighting and motion
  guidance, a progress indicator and a live estimate that disappears when
  quality drops.
* **POS** (default) or **CHROM** pulse extraction, original Dart
  implementations of the published algorithms. No neural network is used.
  A neural-model slot exists and is explicitly marked unavailable
  (licensing; see docs/model_evaluation.md).
* Rule-based signal-quality gates. If they fail, **no value is shown**.
* Results with BPM, quality class, window agreement, the extracted filtered
  pulse waveform, algorithm name/version and limitations.
* Local history with date filters, trend chart, detail view, JSON/CSV export,
  single and full deletion.
* Light/dark themes, responsive layouts, screen-reader labels, reduced motion
  and localisation infrastructure (English).

Not estimated: respiratory rate, blood pressure, SpO₂, glucose, temperature
or stress.

## Quick start

Prerequisites: Flutter 3.27.x (Dart 3.6), Android SDK 35 + JDK 17 for
Android, Xcode 16 + CocoaPods for iOS, Chrome for web.

```bash
tool/dev.sh setup
```

```bash
tool/dev.sh run-web
```

Camera access on the web requires `https://` or `http://localhost`.

| Task | Command |
|---|---|
| Install deps + generate l10n | `tool/dev.sh setup` |
| Run (device) / run in Chrome | `tool/dev.sh run` / `tool/dev.sh run-web` |
| Format / analyze | `tool/dev.sh format` / `tool/dev.sh analyze` |
| Tests (VM) / pipeline tests in Chrome | `tool/dev.sh test` / `tool/dev.sh test-web` |
| Integration test on a device | `tool/dev.sh test-integration <device-id>` |
| Web release build | `tool/dev.sh build-web` |
| Android AAB (+ permission audit) | `tool/dev.sh build-android` |
| iOS IPA (macOS) | `tool/dev.sh build-ios` |
| Model asset checksums | `tool/dev.sh verify-models` |
| Dependency licence audit | `tool/dev.sh licenses` |
| Everything CI runs locally | `tool/dev.sh ci` |

Build-time configuration (`--dart-define`): `APP_NAME`,
`PRIVACY_POLICY_URL`, `SUPPORT_URL`. Android signing: see
docs/release_checklist.md.

## Status and limitations

| Area | Android | iOS | Web |
|---|---|---|---|
| Builds in this environment | ✅ release APK + AAB (debug-signed) | ❌ Xcode/CocoaPods missing | ✅ release |
| Camera acquisition | Implemented, **not run on a device** | Implemented, **not built** | ✅ Verified in headless Chrome with a synthetic camera feed |
| Face detection | ML Kit (on device) | ML Kit (on device) | None: guide-region skin heuristic (disclosed in UI) |
| Window analysis | Background isolate | Background isolate | Main thread (few ms/window) |
| Storage | sembast file, not app-encrypted | same | IndexedDB, not encrypted |
| Network | None (release has no INTERNET permission) | App sends nothing; ML Kit may send metrics per Google's terms | Same-origin only (verified) |

* Accuracy is **unknown**. Synthetic tests prove the code behaves as designed,
  not that it measures people correctly. See docs/validation_protocol.md.
* rPPG is known to degrade with motion, poor or changing light, darker skin
  tones, low-end cameras and arrhythmias.
* Quality thresholds are uncalibrated heuristics.
* Placeholder app IDs (`com.example.*`), default icons and debug signing must
  be replaced before any store submission.

## Documentation

* [Implementation plan & status](docs/implementation_plan.md)
* [Technical decisions](docs/technical_decisions.md)
* [Architecture](docs/architecture.md)
* [Model evaluation](docs/model_evaluation.md) · [Model integration](docs/model_integration.md)
* [Privacy](docs/privacy.md)
* [Validation protocol](docs/validation_protocol.md)
* [Testing](docs/testing.md)
* [Release checklist](docs/release_checklist.md)
* [Web deployment](deploy/README.md)
* [Third-party notices](THIRD_PARTY_NOTICES.md) · [Changelog](CHANGELOG.md)

## Regulatory note

Whether a heart-rate feature is a medical device depends on its claims,
intended use and jurisdiction. This repository makes no compliance or
exemption claim. Obtain regulatory and legal review before publishing in any
market.
