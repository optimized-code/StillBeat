# Architecture

Feature-first Flutter app with Riverpod for dependency injection and state.
Domain logic is pure Dart (no Flutter imports) wherever possible, so it can
be unit-tested on the VM, compiled to JavaScript, and run in isolates.

## Layers

```mermaid
flowchart TB
  subgraph Presentation
    Screens[Screens & widgets<br/>features/*/presentation]
    Ctrl[MeasurementController<br/>SettingsController<br/>history providers]
  end
  subgraph Domain
    SM[MeasurementStateMachine]
    Pos[Positioning rules]
    QA[Quality assessor]
    Agg[Result aggregator]
    Models[Records, settings, results]
  end
  subgraph Services
    CamI[[CameraSource]]
    FaceI[[FaceLocator]]
    ROI[ROI extractor]
    Eng[[RppgEngine]] --> WA[Window analyzer<br/>POS/CHROM, filters, FFT]
    Exp[Export builder / saver]
  end
  subgraph Platform adapters
    Mob[MobileCameraSource<br/>camera plugin]
    Web[WebCameraSource<br/>getUserMedia + canvas]
    MLK[MlKitFaceLocator]
    Guide[GuideRegionFaceLocator]
    DBio[(sembast io)]
    DBweb[(sembast web / IndexedDB)]
  end
  Screens --> Ctrl --> SM & Pos & Agg
  Ctrl --> CamI & FaceI & ROI & WA
  CamI -.-> Mob & Web
  FaceI -.-> MLK & Guide
  Ctrl --> Models
  Models --> DBio & DBweb
```

Platform adapters are chosen at startup by `PlatformServices.detect()` using
conditional imports (`dart.library.io` / `dart.library.js_interop`), and
injected through `platformServicesProvider`, so tests substitute fakes.

## Directory map

```
lib/
  main.dart                     bootstrap: DB, settings, version, error hooks
  app/                          app widget, router, providers, brand, theme
  core/
    errors/app_error.dart       typed AppError hierarchy
    logging/app_logger.dart     redacting structured logger
    platform/                   PlatformServices + io/web/stub factories
    storage/                    database open, migrations, factories
  features/
    onboarding/ home/ measurement/ results/ history/ settings/ about/
    signal_quality/domain/      quality enums, metrics, config, assessor
  services/
    camera/                     CameraFrame, CameraSource, mobile + web
    face_detection/             FaceLocator, ML Kit, guide heuristic, NV21
    frame_processing/           ROI colour statistics
    rppg/                       DSP, POS, CHROM, spectral estimator,
                                window analyzer, engines, sample buffer
    export/                     JSON/CSV builder, io/web savers
  shared/widgets/               cards, badges, charts, label mappers
  l10n/                         ARB + generated localisations
```

## Measurement session

```mermaid
stateDiagram-v2
  [*] --> idle
  idle --> requestingPermission: Start camera (user action)
  requestingPermission --> initializing: camera open
  requestingPermission --> permissionDenied
  initializing --> positioning
  initializing --> inferenceFailure: engine unavailable
  positioning --> warmingUp: face OK for 1 s
  positioning --> timedOut: 60 s
  warmingUp --> measuring: 5 s
  warmingUp --> positioning: face lost > 2 s
  measuring --> positioning: face lost > 2 s
  measuring --> validating: measuring duration elapsed
  validating --> completed: quality gates pass
  validating --> lowSignalQuality: gates fail
  positioning --> cameraFailure
  measuring --> cameraFailure
  measuring --> inferenceFailure
  state "cancelled / interrupted" as stop
  positioning --> stop
  warmingUp --> stop
  measuring --> stop
```

Terminal phases may only go back to `idle` or `requestingPermission`. Every
transition goes through `MeasurementStateMachine.canTransition`; invalid ones
are rejected and logged.

### Frame pipeline (per frame, main isolate, bounded cost)

```mermaid
sequenceDiagram
  participant Cam as CameraSource
  participant C as MeasurementController
  participant F as FaceLocator
  participant R as ROI extractor
  participant B as SignalBuffer
  participant A as analyzeWindow (isolate on native)
  Cam->>C: CameraFrame (t)
  alt ≥200 ms since last request and none in flight
    C-)F: detect(frame)
    F--)C: faces (session-checked)
  end
  C->>C: positioning + lighting rules
  C->>R: extractRoiStats(frame, ROI) (≤4096 px)
  C->>B: RgbSample or invalid sample
  alt ≥1 s since last analysis, none in flight, ≥10 s buffered
    C-)A: snapshot (typed lists)
    A--)C: WindowAnalysis (session-checked)
  end
  C->>C: throttled UI state (10 Hz)
```

Back-pressure: the camera stream is consumed synchronously and does constant
work per frame; expensive work (face detection, window analysis) is
single-flight, so excess frames simply do not trigger new work. Nothing is
queued.

Stale-result protection: every async continuation checks that its `_Session`
object is still the current one; cancel/pause/failure replace or clear it.

## Persistence

sembast (pure Dart, JSON documents) with a version number and an ordered
migration chain (`core/storage/migrations.dart`). Upgrades run inside
sembast's `onVersionChanged` transaction. Records are parsed tolerantly;
unparseable rows are skipped and counted, never crash history.

## Why these choices

See docs/technical_decisions.md.
