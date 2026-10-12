# Changelog

## 0.1.0+1 — 2026-10-10 (unreleased)

Initial implementation.

### Added
* Flutter app for Android, iOS and web with onboarding (limitations
  acknowledgement), home, measurement, results, history (filters, trend,
  detail), settings and methodology/privacy screens.
* Camera adapters: `camera` plugin image stream (Android/iOS);
  `getUserMedia` + canvas sampling (web) with `requestVideoFrameCallback`
  and a de-duplicating polling fallback.
* Face positioning via Google ML Kit (Android/iOS) and a disclosed
  guide-region skin heuristic (web).
* Signal pipeline: skin-masked ROI means, resampling, POS and CHROM,
  zero-phase band-pass, spectral HR with SNR/prominence/stability quality
  gates, session aggregation with rejection.
* Measurement state machine with session guards and camera release on
  completion, cancel, background and error.
* Local storage (sembast) with versioned migrations; JSON/CSV export;
  deletion.
* Redacting logger; typed errors with localised recovery messages.
* CI workflow; developer scripts; permission, model-manifest and licence
  checks.

### Fixed during development
* Web: `Int64List` (unsupported by dart2js) in sample snapshots made every
  window analysis fail in browsers; replaced and covered by Chrome tests.
* Web: 64-bit shift sentinels replaced with web-safe constants.
* Android: removed `INTERNET`, `RECORD_AUDIO` and storage permissions that
  plugins merged into the release manifest.

### Known limitations
See README.md → "Status and limitations".
