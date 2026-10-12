import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Experimental contactless pulse estimation';

  @override
  String get disclaimer => 'This application provides experimental camera-based physiological estimates for informational and research purposes only. Results are not a medical diagnosis and must not be used to make medical decisions. Measurement quality and accuracy may vary.';

  @override
  String get disclaimerShort => 'Experimental estimate — not a medical device or diagnosis.';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDone => 'Done';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonBpm => 'BPM';

  @override
  String get commonNotAvailable => 'Not available';

  @override
  String get commonLearnMore => 'Learn more';

  @override
  String get onboardingTitle1 => 'How it works';

  @override
  String get onboardingBody1 => 'Each heartbeat slightly changes the colour of your skin as blood volume changes. These changes are far too small to see, but a camera can pick them up. This technique is called remote photoplethysmography (rPPG).';

  @override
  String get onboardingTitle2 => 'Light and stillness matter';

  @override
  String get onboardingBody2 => 'The signal is tiny, so movement, talking, changing light, screen flicker and strong backlight can easily overwhelm it. Sit still in soft, even, front-facing light for best results.';

  @override
  String get onboardingTitle3 => 'What this app can and cannot do';

  @override
  String get onboardingBody3 => 'It estimates heart rate in beats per minute when the signal passes quality checks. It does not measure blood pressure, oxygen saturation, glucose, temperature or stress, and it cannot detect or rule out any medical condition.';

  @override
  String get onboardingTitle4 => 'Your data stays on this device';

  @override
  String get onboardingBody4 => 'Video is processed on the device and is never recorded, saved or uploaded. Only measurement summaries you choose to save are stored locally, and you can export or delete them at any time.';

  @override
  String get onboardingAcknowledge => 'I understand these results are experimental estimates and are not medical advice.';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String onboardingStepLabel(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get homeStartMeasurement => 'Start measurement';

  @override
  String homeIntro(int seconds) {
    return 'Sit still, face the camera in even light, and hold for about $seconds seconds.';
  }

  @override
  String get homeLatestResult => 'Latest saved result';

  @override
  String get homeNoResults => 'No saved measurements yet.';

  @override
  String homeHistorySummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count measurements saved',
      one: '1 measurement saved',
      zero: 'No measurements',
    );
    return '$_temp0';
  }

  @override
  String get homeViewHistory => 'View history';

  @override
  String get homeMethodology => 'How it works';

  @override
  String get homePrivacy => 'Privacy';

  @override
  String get homeSettings => 'Settings';

  @override
  String homeUnsupported(String reason) {
    return 'Live measurement isn\'t available here: $reason';
  }

  @override
  String get measureTitle => 'Measurement';

  @override
  String get measureCancel => 'Cancel measurement';

  @override
  String get measureCamera => 'Camera';

  @override
  String get measurePhaseIdle => 'Ready';

  @override
  String get measurePhaseRequestingPermission => 'Requesting camera access…';

  @override
  String get measurePhaseInitializing => 'Starting camera…';

  @override
  String get measurePhasePositioning => 'Position your face';

  @override
  String get measurePhaseWarmingUp => 'Hold still — stabilising';

  @override
  String get measurePhaseMeasuring => 'Measuring';

  @override
  String get measurePhaseValidating => 'Checking signal quality…';

  @override
  String get measurePhaseCompleted => 'Measurement complete';

  @override
  String get measurePhaseCancelled => 'Measurement cancelled';

  @override
  String get measurePhaseInterrupted => 'Measurement paused';

  @override
  String get measurePhasePermissionDenied => 'Camera access needed';

  @override
  String get measurePhaseUnsupported => 'Not supported';

  @override
  String get measurePhaseLowSignalQuality => 'Signal quality too low';

  @override
  String get measurePhaseTimedOut => 'Measurement timed out';

  @override
  String get measurePhaseCameraFailure => 'Camera problem';

  @override
  String get measurePhaseInferenceFailure => 'Processing unavailable';

  @override
  String measureSecondsRemaining(int seconds) {
    return '${seconds}s remaining';
  }

  @override
  String get measureCollecting => 'Collecting signal…';

  @override
  String get measureLiveEstimate => 'Live estimate';

  @override
  String get measureLiveUnavailable => 'No reliable estimate right now';

  @override
  String get measurePurpose => 'The camera is used only while measuring, to read tiny colour changes in your skin. Nothing is recorded or uploaded.';

  @override
  String get measureStart => 'Start camera';

  @override
  String get measureHeuristicLocator => 'Face detection is not available in the browser. The app checks that skin-coloured pixels fill the guide; it cannot confirm a face or detect other people.';

  @override
  String measureFps(String fps) {
    return '$fps fps';
  }

  @override
  String get measureOpenSettings => 'Open settings';

  @override
  String get measureViewResult => 'View result';

  @override
  String get measureWaveformLabel => 'Filtered pulse signal (normalised)';

  @override
  String get measureGuideSemantics => 'Camera preview with face guide';

  @override
  String get issueNoFace => 'No face detected — centre your face in the guide';

  @override
  String get issueMultipleFaces => 'More than one face detected — only one person should be in view';

  @override
  String get issueFaceTooSmall => 'Move closer to the camera';

  @override
  String get issueFaceTooLarge => 'Move a little further away';

  @override
  String get issueFaceOffCenter => 'Centre your face in the guide';

  @override
  String get issueNotFacingCamera => 'Look straight at the camera';

  @override
  String get issueLowLight => 'Too dark — add soft light in front of you';

  @override
  String get issueOverexposed => 'Too bright — avoid direct light on your face';

  @override
  String get issueUnevenLighting => 'Lighting is changing or uneven — face a steady, even light';

  @override
  String get issueExcessiveMotion => 'Too much movement — keep your head still';

  @override
  String get issueLowFrameRate => 'Camera frame rate is too low — close other apps or tabs';

  @override
  String get issueIrregularSampling => 'Frames are arriving irregularly — the device may be busy';

  @override
  String get issueInsufficientSamples => 'Not enough usable signal yet';

  @override
  String get issueWeakSignal => 'Pulse signal is weak';

  @override
  String get issueAmbiguousSpectrum => 'Pulse signal is ambiguous';

  @override
  String get issueUnstableEstimate => 'Estimates are inconsistent';

  @override
  String get errorPermissionDenied => 'Camera access was denied. Allow camera access to measure.';

  @override
  String get errorPermissionPermanentlyDenied => 'Camera access is blocked. Enable it in system or browser settings, then try again.';

  @override
  String get errorCameraUnavailable => 'No usable camera was found.';

  @override
  String get errorCameraFailure => 'The camera stopped or could not start. Close other apps using the camera and try again.';

  @override
  String get errorUnsupportedPlatform => 'Live measurement isn\'t supported on this platform or browser.';

  @override
  String get errorFaceNotDetected => 'A face could not be detected.';

  @override
  String get errorPoorLighting => 'Lighting was not suitable for measurement.';

  @override
  String get errorExcessiveMovement => 'There was too much movement.';

  @override
  String get errorInsufficientSignal => 'The signal was not strong enough.';

  @override
  String get errorUnsupportedModel => 'The selected algorithm is not available in this build.';

  @override
  String get errorModelInitializationFailed => 'The model could not be loaded.';

  @override
  String get errorInferenceFailed => 'Signal processing failed. Please try again.';

  @override
  String get errorStorageFailed => 'Your data could not be read or saved.';

  @override
  String get errorExportFailed => 'Export failed.';

  @override
  String get errorSessionCancelled => 'The measurement was cancelled.';

  @override
  String get errorMeasurementTimeout => 'The measurement took too long. Check positioning and lighting and try again.';

  @override
  String get errorInterrupted => 'The app left the foreground, so the camera was stopped. Return to resume.';

  @override
  String get failureInsufficientValidWindows => 'Too little of the recording passed quality checks to report a value.';

  @override
  String get failureUnstableEstimates => 'Estimates varied too much across the recording to report a value.';

  @override
  String get failureNoFace => 'Your face was not consistently in position.';

  @override
  String get failurePoorLighting => 'Lighting was not suitable.';

  @override
  String get failureExcessiveMotion => 'There was too much movement.';

  @override
  String get failureLowFrameRate => 'The camera delivered too few frames.';

  @override
  String get failureWeakSignal => 'The pulse signal was too weak.';

  @override
  String get failureNoValue => 'No heart rate is reported because the signal did not pass quality checks.';

  @override
  String get failureTips => 'Tips: sit still, avoid talking, face a soft light source, and avoid backlight or flickering screens.';

  @override
  String get resultsTitle => 'Result';

  @override
  String get resultsHeartRate => 'Estimated heart rate';

  @override
  String get resultsQuality => 'Signal quality';

  @override
  String get resultsDate => 'Date';

  @override
  String get resultsDuration => 'Duration';

  @override
  String resultsDurationValue(int seconds) {
    return '$seconds s';
  }

  @override
  String get resultsConsistency => 'Window agreement';

  @override
  String resultsConsistencyValue(int valid, int total, String iqr) {
    return '$valid of $total windows usable · spread ±$iqr BPM';
  }

  @override
  String get resultsConsistencyHelp => 'The recording is split into overlapping 10-second windows. This shows how many passed quality checks and how much their estimates disagreed (interquartile range). It describes internal consistency, not accuracy against a medical device.';

  @override
  String get resultsAlgorithm => 'Algorithm';

  @override
  String get resultsAlgorithmKindSignal => 'Signal processing (no neural network)';

  @override
  String get resultsAlgorithmKindNeural => 'Neural network';

  @override
  String get resultsWaveform => 'Pulse waveform';

  @override
  String get resultsWaveformHelp => 'Band-pass-filtered pulse signal extracted from your camera feed for the last valid window, scaled to unit variance. It is not an ECG.';

  @override
  String get resultsSave => 'Save';

  @override
  String get resultsSaved => 'Saved to history';

  @override
  String get resultsDiscard => 'Discard';

  @override
  String get resultsRetry => 'Measure again';

  @override
  String get resultsLimitations => 'Limitations';

  @override
  String get resultsLimitationsBody => 'Accuracy has not been clinically validated. Skin tone, lighting, camera quality, movement, makeup and facial hair can all affect results. Do not use this value for medical decisions.';

  @override
  String get resultsNone => 'No result to show.';

  @override
  String get qualityGood => 'Good';

  @override
  String get qualityAcceptable => 'Acceptable';

  @override
  String get qualityPoor => 'Poor';

  @override
  String get qualityInsufficientData => 'Insufficient data';

  @override
  String get qualityUnavailable => 'Unavailable';

  @override
  String get qualityExplanation => 'Signal quality is a rule-based rating from signal-to-noise ratio, spectral peak clarity, agreement between windows, face tracking, lighting and motion. It is not a probability that the value is correct.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No saved measurements for this period.';

  @override
  String get historyError => 'History could not be loaded.';

  @override
  String historyCorrupted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stored entries could not be read and were skipped.',
      one: '1 stored entry could not be read and was skipped.',
    );
    return '$_temp0';
  }

  @override
  String get historyFilter7d => '7 days';

  @override
  String get historyFilter30d => '30 days';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyFilterCustom => 'Custom';

  @override
  String get historyTrend => 'Trend';

  @override
  String get historyTrendNeedsMore => 'Save at least two measurements to see a trend.';

  @override
  String get historyTrendNote => 'Normal heart rate varies with activity, posture, caffeine, time of day and more. Changes here are not a diagnosis.';

  @override
  String get historyExportJson => 'Export as JSON';

  @override
  String get historyExportCsv => 'Export as CSV';

  @override
  String get historyDeleteAll => 'Delete all measurements';

  @override
  String get historyDeleteAllConfirm => 'Delete all saved measurements from this device? This cannot be undone.';

  @override
  String get historyDeleteOneConfirm => 'Delete this measurement?';

  @override
  String get historyDeleted => 'Deleted';

  @override
  String get historyDetailTitle => 'Measurement details';

  @override
  String get historyExported => 'Export ready';

  @override
  String get historyNothingToExport => 'There are no measurements to export.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsMeasurement => 'Measurement';

  @override
  String get settingsDuration => 'Measurement duration';

  @override
  String settingsDurationValue(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get settingsAlgorithm => 'Algorithm';

  @override
  String get settingsNeuralUnavailable => 'Neural model — not installed in this build';

  @override
  String get settingsData => 'Your data';

  @override
  String get settingsExport => 'Export measurements';

  @override
  String get settingsDeleteAll => 'Delete all data';

  @override
  String get settingsDeleteAllBody => 'Deletes all measurements and settings from this device, including your acknowledgement of the limitations. This cannot be undone.';

  @override
  String get settingsDeletedAll => 'All data deleted';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsMethodology => 'Methodology, models and licences';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsLicenses => 'Open-source licences';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsSupport => 'Support';

  @override
  String settingsStorage(String backend) {
    return 'Storage: $backend (not encrypted by the app)';
  }

  @override
  String get aboutTitle => 'How it works';

  @override
  String get aboutPipelineTitle => 'Signal pipeline';

  @override
  String get aboutPipelineBody => '1. A face detector locates your face (on Android and iOS). 2. The average colour of skin pixels on your forehead and cheeks is computed for each frame; pixels are discarded immediately. 3. Samples are re-timed onto an even 30 Hz grid. 4. An rPPG algorithm combines the colour channels to cancel lighting and motion effects. 5. The signal is band-pass filtered (0.6–4 Hz) and the strongest frequency between 40 and 180 BPM is found. 6. Quality checks decide whether a value can be reported.';

  @override
  String get aboutAlgorithmsTitle => 'Algorithms';

  @override
  String get aboutActiveAlgorithm => 'Active';

  @override
  String get aboutFaceDetectionTitle => 'Face detection';

  @override
  String get aboutFaceDetectionMobile => 'Android and iOS use Google ML Kit face detection on the device, configured for bounding boxes and head angle only. No recognition, tracking or attribute classification is used.';

  @override
  String get aboutFaceDetectionWeb => 'The web build has no face detector. It checks that skin-coloured pixels fill the on-screen guide, so it cannot confirm that a face is present or that only one person is in view.';

  @override
  String get aboutQualityTitle => 'Signal quality';

  @override
  String get aboutLimitationsTitle => 'Known limitations';

  @override
  String get aboutLimitationsBody => 'Not clinically validated. rPPG is known to be less reliable on darker skin tones, in low or changing light, with movement, and with low-quality cameras. Respiratory rate, blood pressure, oxygen saturation and other vital signs are not estimated.';

  @override
  String get aboutNeuralTitle => 'Neural models';

  @override
  String get aboutNeuralBody => 'Neural rPPG models (for example EfficientPhys and TS-CAN from rPPG-Toolbox) were evaluated but are not included: the available pretrained weights are distributed under a licence with use restrictions and were trained on research-only datasets. See docs/model_evaluation.md in the source repository.';

  @override
  String get aboutNotices => 'View open-source licences';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyBody1Title => 'Camera';

  @override
  String get privacyBody1 => 'Camera access is requested only when you start a measurement. Frames are processed in memory into average colour values and discarded immediately. No video or images are recorded, saved or uploaded. The camera is switched off when a measurement ends, is cancelled, or the app leaves the foreground.';

  @override
  String get privacyBody2Title => 'Stored data';

  @override
  String privacyBody2(String backend) {
    return 'Only measurements you choose to save are stored: date, duration, heart-rate estimate, quality metrics and algorithm version. They are stored locally ($backend) and are not encrypted by the app beyond the protection your operating system or browser provides.';
  }

  @override
  String get privacyBody3Title => 'No accounts, analytics or cloud';

  @override
  String get privacyBody3 => 'There is no account, no cloud sync, no advertising and no analytics or crash-reporting SDK. The Android release build has no internet permission, and the web build loads all of its code and fonts from its own server.';

  @override
  String get privacyBody4Title => 'Third-party components';

  @override
  String get privacyBody4 => 'Face detection on Android and iOS uses Google ML Kit, which runs on the device. On Android the app has no internet permission, so ML Kit cannot send anything. On iOS, Google\'s ML Kit SDK may send performance and usage metrics to Google under Google\'s own terms; the app itself sends no data. The web version uses no face detector and makes no third-party requests.';

  @override
  String get privacyBody5Title => 'Export and deletion';

  @override
  String get privacyBody5 => 'You can export your measurements as JSON or CSV and delete individual measurements or all data in Settings. Deletion removes the records from the app\'s database; like most apps, it cannot guarantee physical erasure from flash storage.';

  @override
  String get metricSnr => 'Signal-to-noise ratio (dB)';

  @override
  String get metricProminence => 'Spectral peak prominence';

  @override
  String get metricFrameRate => 'Camera frame rate (Hz)';
}
