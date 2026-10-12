import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Experimental contactless pulse estimation'**
  String get appTagline;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'This application provides experimental camera-based physiological estimates for informational and research purposes only. Results are not a medical diagnosis and must not be used to make medical decisions. Measurement quality and accuracy may vary.'**
  String get disclaimer;

  /// No description provided for @disclaimerShort.
  ///
  /// In en, this message translates to:
  /// **'Experimental estimate — not a medical device or diagnosis.'**
  String get disclaimerShort;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonBpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get commonBpm;

  /// No description provided for @commonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get commonNotAvailable;

  /// No description provided for @commonLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get commonLearnMore;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Each heartbeat slightly changes the colour of your skin as blood volume changes. These changes are far too small to see, but a camera can pick them up. This technique is called remote photoplethysmography (rPPG).'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Light and stillness matter'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'The signal is tiny, so movement, talking, changing light, screen flicker and strong backlight can easily overwhelm it. Sit still in soft, even, front-facing light for best results.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'What this app can and cannot do'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'It estimates heart rate in beats per minute when the signal passes quality checks. It does not measure blood pressure, oxygen saturation, glucose, temperature or stress, and it cannot detect or rule out any medical condition.'**
  String get onboardingBody3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this device'**
  String get onboardingTitle4;

  /// No description provided for @onboardingBody4.
  ///
  /// In en, this message translates to:
  /// **'Video is processed on the device and is never recorded, saved or uploaded. Only measurement summaries you choose to save are stored locally, and you can export or delete them at any time.'**
  String get onboardingBody4;

  /// No description provided for @onboardingAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand these results are experimental estimates and are not medical advice.'**
  String get onboardingAcknowledge;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepLabel(int current, int total);

  /// No description provided for @homeStartMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Start measurement'**
  String get homeStartMeasurement;

  /// No description provided for @homeIntro.
  ///
  /// In en, this message translates to:
  /// **'Sit still, face the camera in even light, and hold for about {seconds} seconds.'**
  String homeIntro(int seconds);

  /// No description provided for @homeLatestResult.
  ///
  /// In en, this message translates to:
  /// **'Latest saved result'**
  String get homeLatestResult;

  /// No description provided for @homeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No saved measurements yet.'**
  String get homeNoResults;

  /// No description provided for @homeHistorySummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No measurements} =1{1 measurement saved} other{{count} measurements saved}}'**
  String homeHistorySummary(int count);

  /// No description provided for @homeViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get homeViewHistory;

  /// No description provided for @homeMethodology.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get homeMethodology;

  /// No description provided for @homePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get homePrivacy;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @homeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Live measurement isn\'t available here: {reason}'**
  String homeUnsupported(String reason);

  /// No description provided for @measureTitle.
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get measureTitle;

  /// No description provided for @measureCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel measurement'**
  String get measureCancel;

  /// No description provided for @measureCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get measureCamera;

  /// No description provided for @measurePhaseIdle.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get measurePhaseIdle;

  /// No description provided for @measurePhaseRequestingPermission.
  ///
  /// In en, this message translates to:
  /// **'Requesting camera access…'**
  String get measurePhaseRequestingPermission;

  /// No description provided for @measurePhaseInitializing.
  ///
  /// In en, this message translates to:
  /// **'Starting camera…'**
  String get measurePhaseInitializing;

  /// No description provided for @measurePhasePositioning.
  ///
  /// In en, this message translates to:
  /// **'Position your face'**
  String get measurePhasePositioning;

  /// No description provided for @measurePhaseWarmingUp.
  ///
  /// In en, this message translates to:
  /// **'Hold still — stabilising'**
  String get measurePhaseWarmingUp;

  /// No description provided for @measurePhaseMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring'**
  String get measurePhaseMeasuring;

  /// No description provided for @measurePhaseValidating.
  ///
  /// In en, this message translates to:
  /// **'Checking signal quality…'**
  String get measurePhaseValidating;

  /// No description provided for @measurePhaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Measurement complete'**
  String get measurePhaseCompleted;

  /// No description provided for @measurePhaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Measurement cancelled'**
  String get measurePhaseCancelled;

  /// No description provided for @measurePhaseInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Measurement paused'**
  String get measurePhaseInterrupted;

  /// No description provided for @measurePhasePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access needed'**
  String get measurePhasePermissionDenied;

  /// No description provided for @measurePhaseUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Not supported'**
  String get measurePhaseUnsupported;

  /// No description provided for @measurePhaseLowSignalQuality.
  ///
  /// In en, this message translates to:
  /// **'Signal quality too low'**
  String get measurePhaseLowSignalQuality;

  /// No description provided for @measurePhaseTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Measurement timed out'**
  String get measurePhaseTimedOut;

  /// No description provided for @measurePhaseCameraFailure.
  ///
  /// In en, this message translates to:
  /// **'Camera problem'**
  String get measurePhaseCameraFailure;

  /// No description provided for @measurePhaseInferenceFailure.
  ///
  /// In en, this message translates to:
  /// **'Processing unavailable'**
  String get measurePhaseInferenceFailure;

  /// No description provided for @measureSecondsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s remaining'**
  String measureSecondsRemaining(int seconds);

  /// No description provided for @measureCollecting.
  ///
  /// In en, this message translates to:
  /// **'Collecting signal…'**
  String get measureCollecting;

  /// No description provided for @measureLiveEstimate.
  ///
  /// In en, this message translates to:
  /// **'Live estimate'**
  String get measureLiveEstimate;

  /// No description provided for @measureLiveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No reliable estimate right now'**
  String get measureLiveUnavailable;

  /// No description provided for @measurePurpose.
  ///
  /// In en, this message translates to:
  /// **'The camera is used only while measuring, to read tiny colour changes in your skin. Nothing is recorded or uploaded.'**
  String get measurePurpose;

  /// No description provided for @measureStart.
  ///
  /// In en, this message translates to:
  /// **'Start camera'**
  String get measureStart;

  /// No description provided for @measureHeuristicLocator.
  ///
  /// In en, this message translates to:
  /// **'Face detection is not available in the browser. The app checks that skin-coloured pixels fill the guide; it cannot confirm a face or detect other people.'**
  String get measureHeuristicLocator;

  /// No description provided for @measureFps.
  ///
  /// In en, this message translates to:
  /// **'{fps} fps'**
  String measureFps(String fps);

  /// No description provided for @measureOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get measureOpenSettings;

  /// No description provided for @measureViewResult.
  ///
  /// In en, this message translates to:
  /// **'View result'**
  String get measureViewResult;

  /// No description provided for @measureWaveformLabel.
  ///
  /// In en, this message translates to:
  /// **'Filtered pulse signal (normalised)'**
  String get measureWaveformLabel;

  /// No description provided for @measureGuideSemantics.
  ///
  /// In en, this message translates to:
  /// **'Camera preview with face guide'**
  String get measureGuideSemantics;

  /// No description provided for @issueNoFace.
  ///
  /// In en, this message translates to:
  /// **'No face detected — centre your face in the guide'**
  String get issueNoFace;

  /// No description provided for @issueMultipleFaces.
  ///
  /// In en, this message translates to:
  /// **'More than one face detected — only one person should be in view'**
  String get issueMultipleFaces;

  /// No description provided for @issueFaceTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Move closer to the camera'**
  String get issueFaceTooSmall;

  /// No description provided for @issueFaceTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Move a little further away'**
  String get issueFaceTooLarge;

  /// No description provided for @issueFaceOffCenter.
  ///
  /// In en, this message translates to:
  /// **'Centre your face in the guide'**
  String get issueFaceOffCenter;

  /// No description provided for @issueNotFacingCamera.
  ///
  /// In en, this message translates to:
  /// **'Look straight at the camera'**
  String get issueNotFacingCamera;

  /// No description provided for @issueLowLight.
  ///
  /// In en, this message translates to:
  /// **'Too dark — add soft light in front of you'**
  String get issueLowLight;

  /// No description provided for @issueOverexposed.
  ///
  /// In en, this message translates to:
  /// **'Too bright — avoid direct light on your face'**
  String get issueOverexposed;

  /// No description provided for @issueUnevenLighting.
  ///
  /// In en, this message translates to:
  /// **'Lighting is changing or uneven — face a steady, even light'**
  String get issueUnevenLighting;

  /// No description provided for @issueExcessiveMotion.
  ///
  /// In en, this message translates to:
  /// **'Too much movement — keep your head still'**
  String get issueExcessiveMotion;

  /// No description provided for @issueLowFrameRate.
  ///
  /// In en, this message translates to:
  /// **'Camera frame rate is too low — close other apps or tabs'**
  String get issueLowFrameRate;

  /// No description provided for @issueIrregularSampling.
  ///
  /// In en, this message translates to:
  /// **'Frames are arriving irregularly — the device may be busy'**
  String get issueIrregularSampling;

  /// No description provided for @issueInsufficientSamples.
  ///
  /// In en, this message translates to:
  /// **'Not enough usable signal yet'**
  String get issueInsufficientSamples;

  /// No description provided for @issueWeakSignal.
  ///
  /// In en, this message translates to:
  /// **'Pulse signal is weak'**
  String get issueWeakSignal;

  /// No description provided for @issueAmbiguousSpectrum.
  ///
  /// In en, this message translates to:
  /// **'Pulse signal is ambiguous'**
  String get issueAmbiguousSpectrum;

  /// No description provided for @issueUnstableEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimates are inconsistent'**
  String get issueUnstableEstimate;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access was denied. Allow camera access to measure.'**
  String get errorPermissionDenied;

  /// No description provided for @errorPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is blocked. Enable it in system or browser settings, then try again.'**
  String get errorPermissionPermanentlyDenied;

  /// No description provided for @errorCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No usable camera was found.'**
  String get errorCameraUnavailable;

  /// No description provided for @errorCameraFailure.
  ///
  /// In en, this message translates to:
  /// **'The camera stopped or could not start. Close other apps using the camera and try again.'**
  String get errorCameraFailure;

  /// No description provided for @errorUnsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Live measurement isn\'t supported on this platform or browser.'**
  String get errorUnsupportedPlatform;

  /// No description provided for @errorFaceNotDetected.
  ///
  /// In en, this message translates to:
  /// **'A face could not be detected.'**
  String get errorFaceNotDetected;

  /// No description provided for @errorPoorLighting.
  ///
  /// In en, this message translates to:
  /// **'Lighting was not suitable for measurement.'**
  String get errorPoorLighting;

  /// No description provided for @errorExcessiveMovement.
  ///
  /// In en, this message translates to:
  /// **'There was too much movement.'**
  String get errorExcessiveMovement;

  /// No description provided for @errorInsufficientSignal.
  ///
  /// In en, this message translates to:
  /// **'The signal was not strong enough.'**
  String get errorInsufficientSignal;

  /// No description provided for @errorUnsupportedModel.
  ///
  /// In en, this message translates to:
  /// **'The selected algorithm is not available in this build.'**
  String get errorUnsupportedModel;

  /// No description provided for @errorModelInitializationFailed.
  ///
  /// In en, this message translates to:
  /// **'The model could not be loaded.'**
  String get errorModelInitializationFailed;

  /// No description provided for @errorInferenceFailed.
  ///
  /// In en, this message translates to:
  /// **'Signal processing failed. Please try again.'**
  String get errorInferenceFailed;

  /// No description provided for @errorStorageFailed.
  ///
  /// In en, this message translates to:
  /// **'Your data could not be read or saved.'**
  String get errorStorageFailed;

  /// No description provided for @errorExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed.'**
  String get errorExportFailed;

  /// No description provided for @errorSessionCancelled.
  ///
  /// In en, this message translates to:
  /// **'The measurement was cancelled.'**
  String get errorSessionCancelled;

  /// No description provided for @errorMeasurementTimeout.
  ///
  /// In en, this message translates to:
  /// **'The measurement took too long. Check positioning and lighting and try again.'**
  String get errorMeasurementTimeout;

  /// No description provided for @errorInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The app left the foreground, so the camera was stopped. Return to resume.'**
  String get errorInterrupted;

  /// No description provided for @failureInsufficientValidWindows.
  ///
  /// In en, this message translates to:
  /// **'Too little of the recording passed quality checks to report a value.'**
  String get failureInsufficientValidWindows;

  /// No description provided for @failureUnstableEstimates.
  ///
  /// In en, this message translates to:
  /// **'Estimates varied too much across the recording to report a value.'**
  String get failureUnstableEstimates;

  /// No description provided for @failureNoFace.
  ///
  /// In en, this message translates to:
  /// **'Your face was not consistently in position.'**
  String get failureNoFace;

  /// No description provided for @failurePoorLighting.
  ///
  /// In en, this message translates to:
  /// **'Lighting was not suitable.'**
  String get failurePoorLighting;

  /// No description provided for @failureExcessiveMotion.
  ///
  /// In en, this message translates to:
  /// **'There was too much movement.'**
  String get failureExcessiveMotion;

  /// No description provided for @failureLowFrameRate.
  ///
  /// In en, this message translates to:
  /// **'The camera delivered too few frames.'**
  String get failureLowFrameRate;

  /// No description provided for @failureWeakSignal.
  ///
  /// In en, this message translates to:
  /// **'The pulse signal was too weak.'**
  String get failureWeakSignal;

  /// No description provided for @failureNoValue.
  ///
  /// In en, this message translates to:
  /// **'No heart rate is reported because the signal did not pass quality checks.'**
  String get failureNoValue;

  /// No description provided for @failureTips.
  ///
  /// In en, this message translates to:
  /// **'Tips: sit still, avoid talking, face a soft light source, and avoid backlight or flickering screens.'**
  String get failureTips;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultsTitle;

  /// No description provided for @resultsHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Estimated heart rate'**
  String get resultsHeartRate;

  /// No description provided for @resultsQuality.
  ///
  /// In en, this message translates to:
  /// **'Signal quality'**
  String get resultsQuality;

  /// No description provided for @resultsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get resultsDate;

  /// No description provided for @resultsDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get resultsDuration;

  /// No description provided for @resultsDurationValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String resultsDurationValue(int seconds);

  /// No description provided for @resultsConsistency.
  ///
  /// In en, this message translates to:
  /// **'Window agreement'**
  String get resultsConsistency;

  /// No description provided for @resultsConsistencyValue.
  ///
  /// In en, this message translates to:
  /// **'{valid} of {total} windows usable · spread ±{iqr} BPM'**
  String resultsConsistencyValue(int valid, int total, String iqr);

  /// No description provided for @resultsConsistencyHelp.
  ///
  /// In en, this message translates to:
  /// **'The recording is split into overlapping 10-second windows. This shows how many passed quality checks and how much their estimates disagreed (interquartile range). It describes internal consistency, not accuracy against a medical device.'**
  String get resultsConsistencyHelp;

  /// No description provided for @resultsAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Algorithm'**
  String get resultsAlgorithm;

  /// No description provided for @resultsAlgorithmKindSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal processing (no neural network)'**
  String get resultsAlgorithmKindSignal;

  /// No description provided for @resultsAlgorithmKindNeural.
  ///
  /// In en, this message translates to:
  /// **'Neural network'**
  String get resultsAlgorithmKindNeural;

  /// No description provided for @resultsWaveform.
  ///
  /// In en, this message translates to:
  /// **'Pulse waveform'**
  String get resultsWaveform;

  /// No description provided for @resultsWaveformHelp.
  ///
  /// In en, this message translates to:
  /// **'Band-pass-filtered pulse signal extracted from your camera feed for the last valid window, scaled to unit variance. It is not an ECG.'**
  String get resultsWaveformHelp;

  /// No description provided for @resultsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get resultsSave;

  /// No description provided for @resultsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to history'**
  String get resultsSaved;

  /// No description provided for @resultsDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get resultsDiscard;

  /// No description provided for @resultsRetry.
  ///
  /// In en, this message translates to:
  /// **'Measure again'**
  String get resultsRetry;

  /// No description provided for @resultsLimitations.
  ///
  /// In en, this message translates to:
  /// **'Limitations'**
  String get resultsLimitations;

  /// No description provided for @resultsLimitationsBody.
  ///
  /// In en, this message translates to:
  /// **'Accuracy has not been clinically validated. Skin tone, lighting, camera quality, movement, makeup and facial hair can all affect results. Do not use this value for medical decisions.'**
  String get resultsLimitationsBody;

  /// No description provided for @resultsNone.
  ///
  /// In en, this message translates to:
  /// **'No result to show.'**
  String get resultsNone;

  /// No description provided for @qualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get qualityGood;

  /// No description provided for @qualityAcceptable.
  ///
  /// In en, this message translates to:
  /// **'Acceptable'**
  String get qualityAcceptable;

  /// No description provided for @qualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get qualityPoor;

  /// No description provided for @qualityInsufficientData.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data'**
  String get qualityInsufficientData;

  /// No description provided for @qualityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get qualityUnavailable;

  /// No description provided for @qualityExplanation.
  ///
  /// In en, this message translates to:
  /// **'Signal quality is a rule-based rating from signal-to-noise ratio, spectral peak clarity, agreement between windows, face tracking, lighting and motion. It is not a probability that the value is correct.'**
  String get qualityExplanation;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved measurements for this period.'**
  String get historyEmpty;

  /// No description provided for @historyError.
  ///
  /// In en, this message translates to:
  /// **'History could not be loaded.'**
  String get historyError;

  /// No description provided for @historyCorrupted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stored entry could not be read and was skipped.} other{{count} stored entries could not be read and were skipped.}}'**
  String historyCorrupted(int count);

  /// No description provided for @historyFilter7d.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get historyFilter7d;

  /// No description provided for @historyFilter30d.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get historyFilter30d;

  /// No description provided for @historyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// No description provided for @historyFilterCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get historyFilterCustom;

  /// No description provided for @historyTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get historyTrend;

  /// No description provided for @historyTrendNeedsMore.
  ///
  /// In en, this message translates to:
  /// **'Save at least two measurements to see a trend.'**
  String get historyTrendNeedsMore;

  /// No description provided for @historyTrendNote.
  ///
  /// In en, this message translates to:
  /// **'Normal heart rate varies with activity, posture, caffeine, time of day and more. Changes here are not a diagnosis.'**
  String get historyTrendNote;

  /// No description provided for @historyExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON'**
  String get historyExportJson;

  /// No description provided for @historyExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get historyExportCsv;

  /// No description provided for @historyDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all measurements'**
  String get historyDeleteAll;

  /// No description provided for @historyDeleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all saved measurements from this device? This cannot be undone.'**
  String get historyDeleteAllConfirm;

  /// No description provided for @historyDeleteOneConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this measurement?'**
  String get historyDeleteOneConfirm;

  /// No description provided for @historyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get historyDeleted;

  /// No description provided for @historyDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Measurement details'**
  String get historyDetailTitle;

  /// No description provided for @historyExported.
  ///
  /// In en, this message translates to:
  /// **'Export ready'**
  String get historyExported;

  /// No description provided for @historyNothingToExport.
  ///
  /// In en, this message translates to:
  /// **'There are no measurements to export.'**
  String get historyNothingToExport;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get settingsMeasurement;

  /// No description provided for @settingsDuration.
  ///
  /// In en, this message translates to:
  /// **'Measurement duration'**
  String get settingsDuration;

  /// No description provided for @settingsDurationValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String settingsDurationValue(int seconds);

  /// No description provided for @settingsAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Algorithm'**
  String get settingsAlgorithm;

  /// No description provided for @settingsNeuralUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Neural model — not installed in this build'**
  String get settingsNeuralUnavailable;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsData;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export measurements'**
  String get settingsExport;

  /// No description provided for @settingsDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get settingsDeleteAll;

  /// No description provided for @settingsDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes all measurements and settings from this device, including your acknowledgement of the limitations. This cannot be undone.'**
  String get settingsDeleteAllBody;

  /// No description provided for @settingsDeletedAll.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get settingsDeletedAll;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsMethodology.
  ///
  /// In en, this message translates to:
  /// **'Methodology, models and licences'**
  String get settingsMethodology;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get settingsLicenses;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage: {backend} (not encrypted by the app)'**
  String settingsStorage(String backend);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get aboutTitle;

  /// No description provided for @aboutPipelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Signal pipeline'**
  String get aboutPipelineTitle;

  /// No description provided for @aboutPipelineBody.
  ///
  /// In en, this message translates to:
  /// **'1. A face detector locates your face (on Android and iOS). 2. The average colour of skin pixels on your forehead and cheeks is computed for each frame; pixels are discarded immediately. 3. Samples are re-timed onto an even 30 Hz grid. 4. An rPPG algorithm combines the colour channels to cancel lighting and motion effects. 5. The signal is band-pass filtered (0.6–4 Hz) and the strongest frequency between 40 and 180 BPM is found. 6. Quality checks decide whether a value can be reported.'**
  String get aboutPipelineBody;

  /// No description provided for @aboutAlgorithmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Algorithms'**
  String get aboutAlgorithmsTitle;

  /// No description provided for @aboutActiveAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get aboutActiveAlgorithm;

  /// No description provided for @aboutFaceDetectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Face detection'**
  String get aboutFaceDetectionTitle;

  /// No description provided for @aboutFaceDetectionMobile.
  ///
  /// In en, this message translates to:
  /// **'Android and iOS use Google ML Kit face detection on the device, configured for bounding boxes and head angle only. No recognition, tracking or attribute classification is used.'**
  String get aboutFaceDetectionMobile;

  /// No description provided for @aboutFaceDetectionWeb.
  ///
  /// In en, this message translates to:
  /// **'The web build has no face detector. It checks that skin-coloured pixels fill the on-screen guide, so it cannot confirm that a face is present or that only one person is in view.'**
  String get aboutFaceDetectionWeb;

  /// No description provided for @aboutQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Signal quality'**
  String get aboutQualityTitle;

  /// No description provided for @aboutLimitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Known limitations'**
  String get aboutLimitationsTitle;

  /// No description provided for @aboutLimitationsBody.
  ///
  /// In en, this message translates to:
  /// **'Not clinically validated. rPPG is known to be less reliable on darker skin tones, in low or changing light, with movement, and with low-quality cameras. Respiratory rate, blood pressure, oxygen saturation and other vital signs are not estimated.'**
  String get aboutLimitationsBody;

  /// No description provided for @aboutNeuralTitle.
  ///
  /// In en, this message translates to:
  /// **'Neural models'**
  String get aboutNeuralTitle;

  /// No description provided for @aboutNeuralBody.
  ///
  /// In en, this message translates to:
  /// **'Neural rPPG models (for example EfficientPhys and TS-CAN from rPPG-Toolbox) were evaluated but are not included: the available pretrained weights are distributed under a licence with use restrictions and were trained on research-only datasets. See docs/model_evaluation.md in the source repository.'**
  String get aboutNeuralBody;

  /// No description provided for @aboutNotices.
  ///
  /// In en, this message translates to:
  /// **'View open-source licences'**
  String get aboutNotices;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyBody1Title.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get privacyBody1Title;

  /// No description provided for @privacyBody1.
  ///
  /// In en, this message translates to:
  /// **'Camera access is requested only when you start a measurement. Frames are processed in memory into average colour values and discarded immediately. No video or images are recorded, saved or uploaded. The camera is switched off when a measurement ends, is cancelled, or the app leaves the foreground.'**
  String get privacyBody1;

  /// No description provided for @privacyBody2Title.
  ///
  /// In en, this message translates to:
  /// **'Stored data'**
  String get privacyBody2Title;

  /// No description provided for @privacyBody2.
  ///
  /// In en, this message translates to:
  /// **'Only measurements you choose to save are stored: date, duration, heart-rate estimate, quality metrics and algorithm version. They are stored locally ({backend}) and are not encrypted by the app beyond the protection your operating system or browser provides.'**
  String privacyBody2(String backend);

  /// No description provided for @privacyBody3Title.
  ///
  /// In en, this message translates to:
  /// **'No accounts, analytics or cloud'**
  String get privacyBody3Title;

  /// No description provided for @privacyBody3.
  ///
  /// In en, this message translates to:
  /// **'There is no account, no cloud sync, no advertising and no analytics or crash-reporting SDK. The Android release build has no internet permission, and the web build loads all of its code and fonts from its own server.'**
  String get privacyBody3;

  /// No description provided for @privacyBody4Title.
  ///
  /// In en, this message translates to:
  /// **'Third-party components'**
  String get privacyBody4Title;

  /// No description provided for @privacyBody4.
  ///
  /// In en, this message translates to:
  /// **'Face detection on Android and iOS uses Google ML Kit, which runs on the device. On Android the app has no internet permission, so ML Kit cannot send anything. On iOS, Google\'s ML Kit SDK may send performance and usage metrics to Google under Google\'s own terms; the app itself sends no data. The web version uses no face detector and makes no third-party requests.'**
  String get privacyBody4;

  /// No description provided for @privacyBody5Title.
  ///
  /// In en, this message translates to:
  /// **'Export and deletion'**
  String get privacyBody5Title;

  /// No description provided for @privacyBody5.
  ///
  /// In en, this message translates to:
  /// **'You can export your measurements as JSON or CSV and delete individual measurements or all data in Settings. Deletion removes the records from the app\'s database; like most apps, it cannot guarantee physical erasure from flash storage.'**
  String get privacyBody5;

  /// No description provided for @metricSnr.
  ///
  /// In en, this message translates to:
  /// **'Signal-to-noise ratio (dB)'**
  String get metricSnr;

  /// No description provided for @metricProminence.
  ///
  /// In en, this message translates to:
  /// **'Spectral peak prominence'**
  String get metricProminence;

  /// No description provided for @metricFrameRate.
  ///
  /// In en, this message translates to:
  /// **'Camera frame rate (Hz)'**
  String get metricFrameRate;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
