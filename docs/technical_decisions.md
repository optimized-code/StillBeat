# Technical decisions

Each entry: context → decision → consequences. Dates are 2026-10-09 unless
noted.

## TD-1 Toolchain

**Context.** Installed: Flutter 3.27.3 / Dart 3.6.1, Android SDK 35, JDK 17,
Chrome. Xcode is not fully installed and CocoaPods is missing.
**Decision.** Target Flutter 3.27.x. Pin packages to versions resolvable on
Dart 3.6.
**Consequences.** iOS cannot be built or tested in this environment.
`permission_handler` is pinned to 11.x: 13.x pulls
`permission_handler_android` 14.x, which requires AGP 9/Kotlin 2.3 and does not
build with Flutter 3.27's Gradle integration. The Android project uses AGP
8.7.3, Kotlin 2.1.0, Gradle 8.10.2, NDK 27.0, Java 17.

## TD-2 Algorithm: POS default, CHROM alternative, no neural model

See docs/model_evaluation.md. Neural checkpoints are licence-blocked; the
engine slot reports itself as unavailable rather than falling back silently.

## TD-3 State management: Riverpod 2 (no code generation)

Simple `Notifier`/`Provider` classes keep the build free of `build_runner`.
`ProviderScope` overrides inject the database, settings, platform adapters,
the analysis runner and configs in tests.

## TD-4 Camera

* **Android/iOS:** `camera` 0.11 (CameraX on Android, AVFoundation on iOS)
  with `startImageStream`. Android YUV_420_888, iOS BGRA8888,
  `ResolutionPreset.medium`, audio disabled. Measurement screen is
  portrait-locked so rotation is fixed: Android uses the sensor orientation;
  iOS frames arrive upright (the plugin sets `videoOrientation`) and mirrored.
* **Timestamps:** the plugin exposes no capture timestamp on all platforms,
  so frame **arrival** time on a monotonic `Stopwatch` is used. Platform
  channel jitter (typically a few ms) is absorbed by resampling, and the
  quality gate checks effective FPS and the maximum gap.
* **Web:** the `camera` plugin offers no image stream on web, so
  `WebCameraSource` uses `getUserMedia` → `<video>` (platform view) →
  `requestVideoFrameCallback` → 160-px-wide canvas → `getImageData`. When
  `requestVideoFrameCallback` is missing (Firefox at the time of writing) it
  polls and skips frames whose `currentTime` has not advanced, so
  duplicate frames never enter the signal. Timestamps use the frame callback's
  `captureTime` when present, else its `now`.

## TD-5 Face detection

* **Android/iOS:** Google ML Kit (`google_mlkit_face_detection`, MIT plugin;
  SDK under Google's ML Kit terms). Fast mode, no tracking, landmarks,
  contours or classification. Android frames are converted YUV_420_888 →
  NV21 because the plugin only accepts NV21/YV12 bytes on Android.
* **Web:** no detector is bundled. MediaPipe's web runtime would add several
  MB of WASM/model assets and either a CDN dependency or vendored binaries;
  the Shape Detection API (`FaceDetector`) is not generally available. The
  web build uses `GuideRegionFaceLocator`: the on-screen oval is the
  region of interest, and it is accepted when ≥35% of its pixels pass the
  skin mask. Limitations (cannot confirm a face, cannot detect a second
  person, no head pose) are shown in the UI.
* Detection runs at ≤5 Hz; the last box is reused between detections and
  considered stale after 1 s.

## TD-6 ROI and skin mask

ROI = forehead + cheeks: x 20–80%, y 10–70% of the face box (excludes
mouth/jaw motion and most hair). Pixels are kept if they fall inside fixed
YCbCr bounds (Cb 77–127, Cr 133–173; Chai & Ngan 1999) and are not
saturated (any channel ≥250). Sampling is strided to ≤4096 pixels/frame.
**Risk:** fixed chroma bounds are known to vary in performance across skin
tones and lighting; the validation protocol requires stratified analysis by
skin type.

## TD-7 Signal-processing parameters (see `RppgConfig`)

* Resample to 30 Hz (linear) — all downstream steps need a known rate.
* Inner window 1.6 s (Wang et al. 2017).
* Analysis window 10 s, hop 1 s: ≥6 cycles at 40 BPM, ~6 BPM native
  resolution; zero-padded FFT (≥4096) + parabolic interpolation.
* Band-pass 0.6–4.0 Hz, wider than the 40–180 BPM search band so filter
  roll-off does not bias edge peaks; a peak within 1 BPM of a search edge is
  treated as ambiguous.
* Zero-phase filtering (forward–backward 2nd-order Butterworth sections,
  odd-reflection padding) so the displayed waveform is not time-shifted.

## TD-8 Quality model

Rule-based; thresholds in `QualityConfig`. Hard failures (any one ⇒ poor):
face present <85% of frames, mean luma <40 or >230, luma CV >8%, motion
>0.15 face-widths/s, FPS <10, gap >0.5 s. Signal tiers: SNR (de Haan-style,
±6 BPM around f0 and 2·f0) and peak prominence (vs strongest peak >12 BPM
away), plus stability over the last 3 windows. Without stability history the
best tier is *acceptable*. Session result: median of usable windows, requires
≥8 usable windows, ≥50% of windows usable and IQR ≤8 BPM. **These thresholds
are uncalibrated heuristics.** The UI explicitly says the score is not a
probability of correctness.

## TD-9 Concurrency

Window analysis runs via `compute` (background isolate on native, inline on
web) once per second, single-flight. Face detection is single-flight and
async on the platform side. Per-frame ROI work is bounded and runs on the
main isolate: shipping full frames to an isolate would cost more in copying
than the computation itself. **Not yet measured on devices** (release
checklist).

## TD-10 Storage

sembast for both platforms (one code path, JSON documents, versioned
migrations, in-memory factory for tests). Native file in app-support;
IndexedDB on web. Not encrypted (see docs/privacy.md); encryption would need
a key held in the platform keystore (e.g. `flutter_secure_storage`) plus a
sembast codec, and on web there is no equivalent secure key storage, so an
"encrypted" claim would be misleading. Deferred.

## TD-11 No network

No network code. Android release removes `INTERNET` from the merged manifest.
Web builds use `--no-web-resources-cdn` and a bundled Roboto font (Apache-2.0,
copied from the Flutter SDK) so the app never contacts Google CDNs.

## TD-12 Web-compat rule for shared code

Code shared with web must avoid `Int64List`/`Uint64List` and 64-bit integer
shifts (unsupported or truncated under dart2js). This bug was found by the
headless-Chrome end-to-end run and is now guarded by running the pure-Dart
test suites with `flutter test --platform chrome` in CI.

## TD-13 Respiratory rate and other vitals

Not estimated (see docs/model_integration.md). No other vitals are shown,
not even as placeholders with values.
