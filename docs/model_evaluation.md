# Model evaluation and selection

Status: **decision recorded 2026-10-09**. Re-evaluate before any commercial
release or if upstream licences change.

## Question

Which rPPG method should the app use to estimate heart rate from a live
front-camera feed on Android, iOS and web, given that the product may later
be distributed commercially?

## Sources inspected

| Source | What was checked | Result |
|---|---|---|
| `github.com/ubicomplab/rPPG-Toolbox` (pushed 2025-09-15) | `LICENSE`, `final_model_release/` listing, GitHub licence metadata | Licence is the **Responsible AI Source Code License v1.1** (GitHub reports `NOASSERTION`). 36 `.pth` checkpoints for DeepPhys, EfficientPhys, TS-CAN, PhysNet, PhysFormer, PhysMamba, RhythmFormer, iBVPNet and FactorizePhys, trained on UBFC-rPPG, PURE, SCAMPS, BP4D+ (pseudo-labels), MA-UBFC and iBVP. |
| `github.com/phuselab/pyVHR` | GitHub licence metadata | GPL-3.0. Not used: copying code would impose GPL on the app. |
| `github.com/danmcduff/scampsdataset` | GitHub licence metadata | `NOASSERTION`; terms must be read directly before use. |
| Original papers for POS and CHROM | Algorithm descriptions | Implemented from the papers; no third-party code copied. |

No weights were downloaded. Nothing from these repositories is vendored.

## Candidates

### 1. POS — Plane-Orthogonal-to-Skin (selected, default)

| Item | Detail |
|---|---|
| Publication | W. Wang, A. C. den Brinker, S. Stuijk, G. de Haan, *Algorithmic Principles of Remote PPG*, IEEE TBME 64(7):1479–1491, 2017. doi:10.1109/TBME.2016.2609282 |
| Code licence | Original Dart implementation in this repository (app licence). Algorithms are not subject to copyright; no upstream code copied. Patent status was **not** searched — see open questions. |
| Weights / datasets | None required. |
| Commercial redistribution | Allowed for our own code; patent clearance outstanding. |
| Input | Per-frame mean RGB of skin pixels; uniformly sampled (we resample to 30 Hz); 1.6 s inner window; 10 s analysis window. |
| Latency / memory | O(N·l) per window (N ≈ 300, l = 48). Sub-millisecond to a few ms in Dart; memory is a few KB per window. Measured via unit-test runtime only; device profiling pending. |
| Runtime compatibility | Pure Dart. Runs identically on Android, iOS and web (JS). Verified on VM and in Chrome (dart2js). |
| Pre/post-processing | Skin ROI mean → resample → POS → linear detrend → zero-phase Butterworth band-pass 0.6–4 Hz → Hann-windowed FFT peak in 40–180 BPM → SNR / prominence / stability gates. |
| Accuracy limitations | Sensitive to motion, illumination change, low light, compression and low SNR on darker skin tones (cf. Nowara et al., CVPRW 2020). Not clinically validated here. |
| Conversion / retraining | None. |

### 2. CHROM — chrominance-based (implemented, selectable)

| Item | Detail |
|---|---|
| Publication | G. de Haan, V. Jeanne, *Robust Pulse Rate From Chrominance-Based rPPG*, IEEE TBME 60(10):2878–2886, 2013. doi:10.1109/TBME.2013.2266196 |
| Code licence | Original Dart implementation. Patent status not searched. |
| Weights / datasets | None. |
| Input | Same as POS. Local-mean normalisation (1.6 s), band-pass before α-tuning, Hann overlap-add. |
| Latency / memory | Comparable to POS plus two extra band-pass filters. |
| Runtime | Pure Dart, all platforms. |
| Limitations | Assumes a standardised skin-tone vector; similar sensitivity to motion and lighting as POS. |

### 3. EfficientPhys (rPPG-Toolbox) — evaluated, **not integrated**

| Item | Detail |
|---|---|
| Publication | X. Liu et al., *EfficientPhys: Enabling Simple, Fast and Accurate Camera-Based Cardiac Measurement*, WACV 2023. |
| Code licence | Responsible AI Source Code License v1.1 (use-based restrictions, flow-down obligations; see below). |
| Weights | `UBFC-rPPG_EfficientPhys.pth`, `PURE_EfficientPhys.pth`, `SCAMPS_EfficientPhys.pth`, `iBVP_EfficientPhys.pth`, `MA-UBFC_efficientphys.pth`, `BP4D_PseudoLabel_EfficientPhys.pth` (≈8.7 MB each). No separate weight licence found; assumed to fall under the repository licence **(unverified)**. |
| Training-data terms | UBFC-rPPG and PURE are distributed for research use on request; BP4D+ requires a licence agreement; iBVP has a data-use agreement. Whether weights trained on them may be redistributed commercially is **unresolved**. |
| Input | Face crops resized to 72×72, standardised frames, temporal chunks (toolbox default 180 frames), frame-difference handled inside the network. Output is a pulse waveform (difference-normalised); HR via FFT/peak detection. |
| Runtime compatibility | PyTorch → ONNX → ONNX Runtime (mobile + web) or LiteRT via conversion. Requires a model runtime on each platform plus face cropping at fixed size. Not attempted. |
| Latency | Not measured. Papers report on-device feasibility; must be profiled on target phones and in WebAssembly. |
| Conversion | Yes (PyTorch → ONNX/LiteRT), with numerical-equivalence testing against the reference implementation. |

### 4. TS-CAN (rPPG-Toolbox) — evaluated, **not integrated**

| Item | Detail |
|---|---|
| Publication | X. Liu et al., *Multi-Task Temporal Shift Attention Networks for On-Device Contactless Vitals Measurement*, NeurIPS 2020. |
| Code / weights / datasets | Same licence situation as EfficientPhys (`*_TSCAN.pth`, ≈8.9 MB). |
| Input | Two-branch network: difference-normalised motion frames + standardised appearance frames at 72×72; temporal-shift modules with a fixed frame depth (10). |
| Runtime | Temporal shift is exportable as tensor slicing; requires careful ONNX export and verification. |

### 5. PhysNet / FactorizePhys (rPPG-Toolbox) — noted

PhysNet (Yu et al., BMVC 2019) is a 3D-CNN over 128-frame clips; FactorizePhys
(Joshi et al., NeurIPS 2024) ships very small checkpoints (≈220 KB). Both share
the toolbox licence and dataset constraints above.

## rPPG-Toolbox licence — why it blocks bundling for now

The RAIL v1.1 licence grants copy/modify/distribute rights subject to:

* §3.1 — include the full licence with any distribution;
* §3.2(a)(ii) — the Contribution may not be used to "detect or infer …
  health and medical conditions", with an exception for accessibility, and
  such data "should not be cached or stored without the explicit and time
  limited permission of Licensor";
* §3.2(c)(vi) — no diagnosis without human oversight;
* §3.3 — the restrictions must be passed down as enforceable terms in any
  agreement governing distribution, and users must be required to comply;
* §4 — the licensor may terminate and require destruction on breach.

A heart-rate app that stores history is at minimum in tension with §3.2(a)(ii)
and requires EULA flow-down (§3.3). Combined with research-only training
data, the conclusion is: **do not bundle these weights without written
clarification from the licensor and legal review.**

## Decision

1. **Stage A (done):** POS as default, CHROM as an alternative, both original
   Dart code behind the `RppgEngine` interface.
2. **Stage B (blocked):** a neural engine slot exists
   (`UnavailableNeuralRppgEngine`) that reports `available: false` with a
   reason and throws `ModelUnavailableError` if used. The UI lists it as
   "not installed". No neural output is ever simulated.
3. **Stage C (partial):** POS vs CHROM are compared on deterministic
   synthetic traces in `test/services/rppg/window_analyzer_test.dart` and
   end-to-end through a real browser (see docs/testing.md). Physiological
   comparison needs licensed data or a prospective study
   (docs/validation_protocol.md).

## Paths to unblock Stage B

* Obtain written permission from the rPPG-Toolbox licensors for commercial
  use and storage of outputs, **and** confirm dataset terms; or
* Train a model on data the project owns or has commercial rights to
  (e.g. a consented in-house dataset, or synthetic data whose licence permits
  it), then export via ONNX and add it to `assets/models/manifest.json` with
  a SHA-256, provenance and licence.

## Open questions

* Patent status of POS/CHROM-style chrominance methods in target markets.
  Both methods originate from Philips Research; assume related patents may
  exist until a freedom-to-operate search says otherwise (none was performed).
* Whether the toolbox's checkpoints carry any licence other than the
  repository's.
* SCAMPS dataset terms (GitHub reports no standard licence).
