# Physiological validation protocol (draft)

Nothing in this repository establishes physiological accuracy. Synthetic
tests verify that the implementation behaves as designed; they are not
evidence of accuracy on people. This protocol must be executed, with ethics
approval where required, before any performance claim.

## 1. Objective and intended use

Estimate agreement between the app's heart-rate output (POS default, CHROM
secondary) and a reference instrument in adults at rest, using the front
camera of consumer phones and laptops/webcams, for informational/research
use only.

Primary endpoint: mean absolute error (MAE, BPM) of completed measurements.
Co-primary: valid-measurement rate (completed / attempted). Both must be
reported together; an error metric over only the sessions the app chose to
accept is not interpretable on its own.

## 2. Population

* Adults 18–80, able to sit still for 2 minutes, informed consent.
* Stratify recruitment to cover Fitzpatrick skin types I–VI with at least 15%
  per group (pairs I–II, III–IV, V–VI), sex, age bands (18–39, 40–59, 60+),
  facial hair, glasses, and makeup.
* Exclusions: known arrhythmia (AF, frequent ectopy) for the primary
  analysis — analysed separately as a secondary cohort, because a spectral
  peak estimator assumes a quasi-periodic rhythm; pacemaker; photosensitive
  conditions.
* Sample size: plan for ≥100 participants; justify formally from the
  expected SD of differences (e.g. to estimate 95% limits of agreement with a
  CI half-width of about ±1.5 BPM if SD≈5 BPM, n≈100 participants with
  repeated sessions accounted for).

## 3. Reference instrumentation

* Gold reference: 3-lead ECG (R-peak-derived instantaneous HR), sampled ≥250
  Hz. Acceptable alternative: clinical-grade finger PPG (contact pulse
  oximeter with waveform output). Record make, model, firmware and
  calibration status.
* Reference HR for a session: mean of instantaneous HR over the exact
  measuring-phase interval (excluding warm-up), computed by the same
  scripted pipeline for all sessions.

## 4. Time synchronisation

* Display a visible sync event (screen flash or audible beep captured by
  the reference logger) at session start and end; or log both clocks
  against NTP-disciplined time with <50 ms offset.
* The app must expose a research-build-only export of measuring-phase start
  and end timestamps (the current build stores only the session start time;
  adding phase timestamps to the export is a prerequisite task).

## 5. Conditions (within-subject, randomised order)

| Factor | Levels |
|---|---|
| Lighting | Diffuse indoor 300–500 lux; dim 50–100 lux; side light; backlight (window behind); flickering LED |
| Motion | Still; natural small movement; talking |
| Device | ≥3 Android phones (low/mid/high end), ≥2 iPhones, ≥2 laptop webcams in Chrome, Safari and Firefox |
| Duration setting | 30 s and 60 s |
| Algorithm | POS and CHROM (same recording can be re-analysed offline only if a research build captures ROI traces with consent) |

Record lux at the face, camera model, OS/browser version, app build hash.

## 6. Procedure

1. Consent; record demographics and self/assessor-rated Fitzpatrick type.
2. Fit reference; 2 minutes seated rest.
3. For each condition: start reference logging → sync event → run app
   measurement → sync event → save outcome (success value or rejection
   reason). Do not retry silently: every attempt is a row.
4. Maximum 3 attempts per condition; all attempts are kept.

## 7. Data handling

* Store only pseudonymised IDs. No video unless a separately consented
  research protocol requires it; if video is kept, encrypt at rest, restrict
  access, set retention.
* Public datasets (UBFC-rPPG, PURE, etc.) may be used for offline
  development only under their own terms; they must not be redistributed
  with the app and results on them must be reported separately from the
  prospective study.

## 8. Metrics and statistics

Per algorithm × condition × device class × skin-type group:

* MAE, RMSE, mean bias (app − reference) with 95% CI;
* Bland–Altman 95% limits of agreement, using a repeated-measures method
  (e.g. Bland & Altman 2007) because participants contribute multiple
  sessions;
* Proportion within ±5 BPM and ±10 BPM;
* **Valid-measurement rate** and rejection reasons;
* Measurement completion time;
* Pearson/concordance correlation (secondary only — correlation is not
  agreement);
* Calibration of the quality class: error distribution for *good* vs
  *acceptable*; the quality thresholds in `QualityConfig` must be re-tuned on
  a development split and evaluated on a held-out split.
* Latency: per-window analysis time and end-to-end time-to-result per device.

Missing data: a rejected session is a missing app value, not excluded. Report
an intention-to-measure analysis (all attempts) alongside per-protocol.
Do not drop outliers without a pre-registered rule.

## 9. Acceptance criteria (to be pre-registered)

Example targets for an informational wellness feature (not a medical claim):
MAE ≤5 BPM and valid-measurement rate ≥70% in the still/diffuse-light
condition, with no skin-type group's MAE exceeding the best group's by more
than 2 BPM. If not met, the app must not claim accuracy and should display
stronger limitations.

## 10. Failure analysis

For every error >10 BPM and every rejection: condition, quality metrics,
dominant issue, device, skin type. Look specifically for harmonic errors
(≈2× or 0.5× reference) and lock-on to motion or flicker frequencies.

## 11. Reporting

Publish the full protocol, statistical analysis plan, code version and
device list with the results. State that results are limited to the tested
conditions and population.

## 12. Regulatory note

Depending on claims and market, a heart-rate feature may fall under medical
device regulation (e.g. EU MDR, US FDA). Clinical evaluation requirements
then go beyond this protocol. Seek regulatory advice before claiming any
health benefit or accuracy.
