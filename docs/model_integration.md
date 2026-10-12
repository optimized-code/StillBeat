# Model integration

## What is integrated

| Engine | Kind | Status | Source |
|---|---|---|---|
| `SignalProcessingRppgEngine(PulseMethod.pos)` | Unsupervised signal processing | **Active (default)** | `lib/services/rppg/algorithms/pos.dart` |
| `SignalProcessingRppgEngine(PulseMethod.chrom)` | Unsupervised signal processing | Available (Settings) | `lib/services/rppg/algorithms/chrom.dart` |
| `UnavailableNeuralRppgEngine` | Neural network slot | **Unavailable** — no weights bundled | `lib/services/rppg/rppg_engine.dart` |

No pretrained weights, no ML inference runtime (TFLite/LiteRT/ONNX
Runtime/TF.js) and no model files are included. `assets/models/manifest.json`
is intentionally empty. The UI labels the active algorithm as "Signal
processing (no neural network)".

Face detection on Android/iOS uses Google ML Kit (a learned detector, run on
device by Google's SDK). It is used only to place the measurement region; it
is not the rPPG model.

## Per-window pipeline (identical on all platforms)

| Step | Implementation | Parameters (`RppgConfig`) |
|---|---|---|
| Frame → ROI stats | `extractRoiStats` — skin-masked mean RGB inside forehead/cheek ROI; saturated pixels dropped | ≤4096 pixels/frame; YCbCr mask Cb∈[77,127], Cr∈[133,173] |
| Buffer | `SignalBuffer` — bounded FIFO, drops non-advancing timestamps | capacity 1200 samples |
| Resample | `resampleLinear` | 30 Hz |
| Pulse extraction | `posPulse` / `chromPulse` | inner window 1.6 s |
| Detrend | `detrendLinear` | — |
| Band-pass | `ZeroPhaseBandPass` (2nd-order Butterworth HP+LP, forward-backward, odd-reflection padding) | 0.6–4.0 Hz |
| Spectrum | Hann window, zero-padded FFT | ≥4096 points |
| HR | Peak in plausible band + parabolic interpolation | 40–180 BPM |
| Quality | `assessWindowQuality` | `QualityConfig` |
| Session result | `aggregateMeasurement` — median of usable windows, IQR gate | `AggregationConfig` |

Output interpretation: the band-passed pulse signal is unit-less; BPM is
`60 × f_peak`. The waveform shown in the UI is the last valid window's
band-passed signal, z-scored for display. The final ~0.5 s can appear
attenuated: this is the edge behaviour of the zero-phase filter, not
physiology.

## Execution

| Platform | Where the window analysis runs | Verified |
|---|---|---|
| Android / iOS | `compute()` → short-lived background isolate, once per second | Isolate path compiles; device run **not verified** (no device available) |
| Web | `compute()` runs inline on the main thread (no isolates in JS). Cost per window is a few ms. | Verified in headless Chrome with a synthetic camera feed |

Only one analysis is in flight per session (`analysisInFlight` guard) and
results carry a session identity check, so late results from a cancelled
session are discarded.

## Adding a neural model later

1. Clear licensing (docs/model_evaluation.md §"Paths to unblock").
2. Export to ONNX (preferred: one format for mobile and web via ONNX Runtime)
   or LiteRT for mobile + ONNX Runtime Web for browsers.
3. Add the file to `assets/models/`, an entry to `manifest.json`
   (`file`, `sha256`, `sourceUrl`, `license`, `trainingData`, `inputSpec`,
   `outputSpec`), and run `tool/verify_models.sh`.
4. Implement `RppgEngine` for it: reproduce the reference preprocessing
   exactly (e.g. 72×72 face crops, difference-normalisation, chunk length),
   return `analyzerMethod == null`, and route the controller through
   `engine.process` in a dedicated isolate/worker with a single-flight guard.
5. Build a fixed conversion corpus; compare converted vs reference outputs
   (target: max abs error of the normalised waveform < 1e-3 and identical
   HR peak bin) and record tolerances here.
6. Keep `UnavailableNeuralRppgEngine` as the fallback when the runtime is
   missing on a platform; never fall back silently to POS while labelling
   the result as neural.

## Respiratory rate

Not implemented. POS/CHROM are not validated for respiration here, a 30–60 s
window holds only ~6–20 breaths (poor spectral resolution), and no
respiratory reference data was available. `respiratoryRateBpm` is always
`null` and the UI never shows a respiratory value.
