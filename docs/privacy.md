# Privacy design and actual data flow

This document describes what the code in this repository actually does.
Keep it in sync with `lib/features/about/presentation/privacy_screen.dart`
and the `privacy*` strings in `lib/l10n/app_en.arb`.

## Data flow

```mermaid
flowchart LR
  Cam[Camera frames<br/>(memory only)] --> ROI[Skin-masked ROI mean RGB<br/>per frame]
  Cam -. 5 Hz .-> FD[Face detector<br/>ML Kit on device / guide heuristic on web]
  FD --> ROI
  ROI --> Buf[Bounded sample buffer<br/>≤1200 numbers ×7]
  Buf --> An[Window analysis<br/>POS/CHROM + FFT]
  An --> UI[Live display]
  An --> Res[Session result<br/>(memory)]
  Res -- user taps Save --> DB[(Local DB<br/>summary only)]
  DB -- user taps Export --> Share[Share sheet / browser download]
```

* Frames are never written to disk, never encoded to video and never leave
  the process. Each frame is reduced to seven numbers (mean R/G/B, luma,
  face-valid flag, motion, timestamp) and then dropped.
* The sample buffer and window results exist only for the session and are
  discarded when it ends, is cancelled, or the app is backgrounded.
* Nothing is saved unless the user taps **Save** on the result screen.

## What is stored

`MeasurementRecord` (schema v1): id (random UUID), session start time,
duration, heart-rate estimate, quality class and aggregate quality metrics,
algorithm id/version, processing metadata (window counts, IQR, face-locator
id), creation time. `respiratoryRateBpm` is always null.

Not stored: images, video, colour traces, waveforms, face boxes, device model,
OS version, advertising IDs, account data, location.

Settings store theme, language, duration, algorithm and the disclaimer
acknowledgement version.

| Platform | Backend | Encryption |
|---|---|---|
| Android / iOS | sembast JSON file in the app-support directory (OS sandbox) | **Not encrypted by the app.** Protected by OS sandboxing and, when the device is locked, by OS full-disk/file encryption where the device provides it. |
| Web | IndexedDB via sembast_web (origin-scoped) | **Not encrypted.** Readable by anyone with access to the browser profile. |

Android backup and device-to-device transfer are disabled
(`allowBackup=false`, `data_extraction_rules.xml`). iOS: the app-support
directory is included in iCloud/iTunes backups by default; excluding it
(`NSURLIsExcludedFromBackupKey`) is an open item in the release checklist.

If the database cannot be opened, the app falls back to an in-memory store
and says so in Settings; nothing is persisted in that state.

## Permissions

| Platform | Requested | Notes |
|---|---|---|
| Android | `CAMERA` only (verified with `aapt dump badging` on the release APK) | `INTERNET`, `ACCESS_NETWORK_STATE`, `RECORD_AUDIO`, storage permissions merged in by plugins are removed with `tools:node="remove"`. Debug/profile builds keep `INTERNET` for Flutter tooling only. |
| iOS | Camera (`NSCameraUsageDescription`) | No microphone, photo library or location keys. `permission_handler` is compiled with only `PERMISSION_CAMERA=1`. |
| Web | `getUserMedia({video})`, after a user click, HTTPS/localhost only | `audio: false`. |

Camera permission is requested only after the user taps **Start camera** on a
screen that states the purpose.

## Camera lifecycle

The camera is stopped (Android/iOS: `stopImageStream` + `dispose`; web: every
`MediaStreamTrack.stop()`, `srcObject = null`) when:

* the measuring phase completes (before results are computed),
* the user cancels or navigates back,
* the app becomes hidden (background, tab hidden, screen locked),
* any camera/processing error occurs,
* the measurement controller is disposed.

Verified by unit tests (`measurement_controller_test.dart`) and, on web, by a
headless-Chrome run that checks no live track or `<video>` element remains
after completion (docs/testing.md).

## Network

The app code performs no network requests. There is no analytics,
advertising, crash reporting or remote logging SDK.

* **Android release:** no `INTERNET` permission, so no component (including
  ML Kit) can make network requests.
* **iOS:** iOS has no network permission. Google ML Kit's SDK may contact
  Google to send API performance/usage metrics or fetch updates, per Google's
  ML Kit terms. Review Google's current ML Kit data-disclosure documentation
  before submission and reflect it in the App Store privacy label.
* **Web:** built with `--no-web-resources-cdn` and a bundled Roboto font, so
  CanvasKit and fonts are served from the app's own origin. Verified: a full
  session in Chrome requested only `http://localhost:8787` resources.

## Logging

`AppLogger` redacts any field whose key looks like a health value, sample,
frame, image, face, path, device or identifier, converts non-scalar values to
their type name, and in release builds only emits warnings/errors to the local
developer log. No logs leave the device.

## Deletion

* Single record: History → record → Delete.
* All data: Settings → Delete all data (measurements and settings,
  including the disclaimer acknowledgement).
* sembast compacts its file over time; deleted records may persist in flash
  storage until overwritten. The app does not claim secure erasure.
* Uninstalling the app (or clearing site data on web) removes the database.

## Exports

JSON (versioned schema, disclaimer included) or CSV, containing measurement
summaries only — no device, OS, locale or account information. CSV cells are
escaped against formula injection. Mobile: temporary file → system share
sheet → file deleted after the sheet closes. Web: Blob download; nothing is
uploaded.

## Third parties

| Component | Data it sees | Notes |
|---|---|---|
| Google ML Kit Face Detection (Android/iOS) | Camera frames, on device, ~5 Hz | Closed-source SDK under Google's ML Kit terms. Bounding box + head yaw only; tracking, landmarks, contours and classification disabled. |
| Flutter, Riverpod, go_router, sembast, camera, permission_handler, share_plus, package_info_plus, path_provider, intl, uuid | Local only | See THIRD_PARTY_NOTICES.md |

## Not claimed

* Not encrypted at rest by the app.
* Not a guarantee of physical erasure.
* Not HIPAA/GDPR "compliant": compliance depends on the deploying
  organisation, jurisdiction and intended use. A DPIA is recommended before
  any deployment that processes data about identifiable people.
