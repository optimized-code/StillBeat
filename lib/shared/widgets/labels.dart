import 'package:flutter/widgets.dart';

import '../../core/errors/app_error.dart';
import '../../features/measurement/domain/measurement_phase.dart';
import '../../features/measurement/domain/measurement_result.dart';
import '../../features/signal_quality/domain/signal_quality.dart';
import '../../l10n/generated/app_localizations.dart';

/// Maps domain enums to localised, user-facing text. Keeping this in one
/// place means domain code never contains display strings.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String qualityLabel(AppLocalizations l, SignalQuality q) => switch (q) {
      SignalQuality.good => l.qualityGood,
      SignalQuality.acceptable => l.qualityAcceptable,
      SignalQuality.poor => l.qualityPoor,
      SignalQuality.insufficientData => l.qualityInsufficientData,
      SignalQuality.unavailable => l.qualityUnavailable,
    };

String issueLabel(AppLocalizations l, QualityIssue i) => switch (i) {
      QualityIssue.noFace => l.issueNoFace,
      QualityIssue.multipleFaces => l.issueMultipleFaces,
      QualityIssue.faceTooSmall => l.issueFaceTooSmall,
      QualityIssue.faceTooLarge => l.issueFaceTooLarge,
      QualityIssue.faceOffCenter => l.issueFaceOffCenter,
      QualityIssue.notFacingCamera => l.issueNotFacingCamera,
      QualityIssue.lowLight => l.issueLowLight,
      QualityIssue.overexposed => l.issueOverexposed,
      QualityIssue.unevenLighting => l.issueUnevenLighting,
      QualityIssue.excessiveMotion => l.issueExcessiveMotion,
      QualityIssue.lowFrameRate => l.issueLowFrameRate,
      QualityIssue.irregularSampling => l.issueIrregularSampling,
      QualityIssue.insufficientSamples => l.issueInsufficientSamples,
      QualityIssue.weakSignal => l.issueWeakSignal,
      QualityIssue.ambiguousSpectrum => l.issueAmbiguousSpectrum,
      QualityIssue.unstableEstimate => l.issueUnstableEstimate,
    };

/// Most actionable issue first: positioning, then light, then motion, then
/// signal-level descriptors.
List<QualityIssue> prioritiseIssues(Iterable<QualityIssue> issues) =>
    issues.toList()..sort((a, b) => a.index.compareTo(b.index));

String phaseLabel(AppLocalizations l, MeasurementPhase p) => switch (p) {
      MeasurementPhase.idle => l.measurePhaseIdle,
      MeasurementPhase.requestingPermission =>
        l.measurePhaseRequestingPermission,
      MeasurementPhase.initializing => l.measurePhaseInitializing,
      MeasurementPhase.positioning => l.measurePhasePositioning,
      MeasurementPhase.warmingUp => l.measurePhaseWarmingUp,
      MeasurementPhase.measuring => l.measurePhaseMeasuring,
      MeasurementPhase.validating => l.measurePhaseValidating,
      MeasurementPhase.completed => l.measurePhaseCompleted,
      MeasurementPhase.cancelled => l.measurePhaseCancelled,
      MeasurementPhase.interrupted => l.measurePhaseInterrupted,
      MeasurementPhase.permissionDenied => l.measurePhasePermissionDenied,
      MeasurementPhase.unsupported => l.measurePhaseUnsupported,
      MeasurementPhase.lowSignalQuality => l.measurePhaseLowSignalQuality,
      MeasurementPhase.timedOut => l.measurePhaseTimedOut,
      MeasurementPhase.cameraFailure => l.measurePhaseCameraFailure,
      MeasurementPhase.inferenceFailure => l.measurePhaseInferenceFailure,
    };

String errorMessage(AppLocalizations l, AppError e) => switch (e.kind) {
      AppErrorKind.permissionDenied => l.errorPermissionDenied,
      AppErrorKind.permissionPermanentlyDenied =>
        l.errorPermissionPermanentlyDenied,
      AppErrorKind.cameraUnavailable => l.errorCameraUnavailable,
      AppErrorKind.cameraFailure => l.errorCameraFailure,
      AppErrorKind.unsupportedPlatform => l.errorUnsupportedPlatform,
      AppErrorKind.faceNotDetected => l.errorFaceNotDetected,
      AppErrorKind.poorLighting => l.errorPoorLighting,
      AppErrorKind.excessiveMovement => l.errorExcessiveMovement,
      AppErrorKind.insufficientSignal => l.errorInsufficientSignal,
      AppErrorKind.unsupportedModel => l.errorUnsupportedModel,
      AppErrorKind.modelInitializationFailed =>
        l.errorModelInitializationFailed,
      AppErrorKind.inferenceFailed => l.errorInferenceFailed,
      AppErrorKind.storageFailed => l.errorStorageFailed,
      AppErrorKind.exportFailed => l.errorExportFailed,
      AppErrorKind.sessionCancelled => l.errorSessionCancelled,
      AppErrorKind.measurementTimeout => l.errorMeasurementTimeout,
    };

String failureLabel(AppLocalizations l, MeasurementFailureReason r) =>
    switch (r) {
      MeasurementFailureReason.insufficientValidWindows =>
        l.failureInsufficientValidWindows,
      MeasurementFailureReason.unstableEstimates => l.failureUnstableEstimates,
      MeasurementFailureReason.noFace => l.failureNoFace,
      MeasurementFailureReason.poorLighting => l.failurePoorLighting,
      MeasurementFailureReason.excessiveMotion => l.failureExcessiveMotion,
      MeasurementFailureReason.lowFrameRate => l.failureLowFrameRate,
      MeasurementFailureReason.weakSignal => l.failureWeakSignal,
    };
