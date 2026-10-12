# Implementation plan and status

Updated 2026-10-10. Status values: **done** (implemented and verified as
stated), **partial**, **unverified** (implemented, not run on target),
**blocked**.

## Environment findings (start of work)

* Empty directory with only the brief; no existing code, model or camera
  implementation. Initialised git and a Flutter project.
* Flutter 3.27.3 / Dart 3.6.1; Android SDK 35 + NDK 27; JDK 17; Chrome.
* Xcode incomplete and CocoaPods missing → **iOS cannot be built here.**
* No Android device/emulator attached → mobile camera paths cannot be run.
* Network available for package resolution.

## Milestones

| # | Milestone | Status | Evidence |
|---|---|---|---|
| 1 | Foundation: architecture, theme, routing, DI, platforms, CI, tests | done | `flutter analyze` clean; CI workflow; 135 tests |
| 2 | Camera experience: mobile + web adapters, permissions, lifecycle, face guidance | partial | Web verified in headless Chrome with a fake camera; Android/iOS adapters implemented but **unverified on hardware** |
| 3 | Signal pipeline: sampling, resampling, POS/CHROM, filtering, quality, HR, waveform, state machine | done | Unit, controller and browser end-to-end tests |
| 4 | Model integration | blocked | Licence review (docs/model_evaluation.md); neural slot reports unavailable |
| 5 | Product features: onboarding, home, measurement, results, history, settings, about, privacy, persistence, migrations, export, deletion, a11y | done | Widget tests incl. accessibility guidelines |
| 6 | Hardening: tests, analysis, lifecycle, permissions, performance, responsive web | partial | Permissions verified on release APK; no device performance measurements |
| 7 | Release preparation: IDs, versioning, signing, notices, checklist, artefacts | partial | Web build, release APK and AAB built (debug-signed); iOS not built; placeholder IDs |

## Deliverables checklist

- [x] Flutter project for Android, iOS, web (`android/`, `ios/`, `web/`)
- [x] Model research + licence analysis → docs/model_evaluation.md
- [x] POS and CHROM engines behind `RppgEngine`; neural slot explicitly unavailable
- [x] Bounded, session-guarded frame pipeline; isolate analysis on native
- [x] Rule-based quality model with configurable thresholds
- [x] Explicit state machine with tested transitions
- [x] Results gated by quality; rejection instead of fabricated values
- [x] Waveform = extracted, filtered signal (labelled)
- [x] Local persistence with migrations; corrupt-row tolerance; in-memory fallback
- [x] JSON/CSV export; single and full deletion
- [x] Localisation infrastructure (ARB, English)
- [x] Light/dark themes; responsive layouts; reduced-motion; semantics
- [x] Privacy: no network code, Android INTERNET removed, no CDN on web
- [x] Docs: README, plan, decisions, model evaluation/integration, architecture, privacy, validation protocol, testing, release checklist, notices, changelog
- [x] CI: format, analyze, VM + Chrome tests, model checksums, licence check, web/Android/iOS builds
- [ ] Android/iOS run on physical devices
- [ ] iOS build (needs Xcode + CocoaPods)
- [ ] Integration test execution on a device
- [ ] Device performance profiling
- [ ] Physiological validation study
- [ ] Final branding, IDs, icons, privacy-policy URL, signing keys
- [ ] Neural model (licence-blocked)
- [ ] Respiratory rate (not supported; intentionally absent)
