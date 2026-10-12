/// Typed application errors. User-facing text is resolved from [kind] via
/// localisation; [debugDetail] is for redacted diagnostics only and is never
/// shown to users.
sealed class AppError implements Exception {
  const AppError([this.debugDetail]);

  final String? debugDetail;

  AppErrorKind get kind;

  @override
  String toString() =>
      '${kind.name}${debugDetail == null ? '' : ': $debugDetail'}';
}

enum AppErrorKind {
  permissionDenied,
  permissionPermanentlyDenied,
  cameraUnavailable,
  unsupportedPlatform,
  faceNotDetected,
  poorLighting,
  excessiveMovement,
  insufficientSignal,
  unsupportedModel,
  modelInitializationFailed,
  inferenceFailed,
  storageFailed,
  exportFailed,
  sessionCancelled,
  measurementTimeout,
  cameraFailure,
}

class PermissionDeniedError extends AppError {
  const PermissionDeniedError({this.permanent = false, String? detail})
      : super(detail);
  final bool permanent;
  @override
  AppErrorKind get kind => permanent
      ? AppErrorKind.permissionPermanentlyDenied
      : AppErrorKind.permissionDenied;
}

class CameraUnavailableError extends AppError {
  const CameraUnavailableError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.cameraUnavailable;
}

class CameraFailureError extends AppError {
  const CameraFailureError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.cameraFailure;
}

class UnsupportedPlatformError extends AppError {
  const UnsupportedPlatformError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.unsupportedPlatform;
}

class FaceNotDetectedError extends AppError {
  const FaceNotDetectedError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.faceNotDetected;
}

class PoorLightingError extends AppError {
  const PoorLightingError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.poorLighting;
}

class ExcessiveMovementError extends AppError {
  const ExcessiveMovementError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.excessiveMovement;
}

class InsufficientSignalError extends AppError {
  const InsufficientSignalError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.insufficientSignal;
}

class UnsupportedModelError extends AppError {
  const UnsupportedModelError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.unsupportedModel;
}

/// The requested model is not installed/licensed in this build.
class ModelUnavailableError extends AppError {
  const ModelUnavailableError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.modelInitializationFailed;
}

class InferenceFailedError extends AppError {
  const InferenceFailedError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.inferenceFailed;
}

class StorageError extends AppError {
  const StorageError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.storageFailed;
}

class ExportError extends AppError {
  const ExportError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.exportFailed;
}

class SessionCancelledError extends AppError {
  const SessionCancelledError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.sessionCancelled;
}

class MeasurementTimeoutError extends AppError {
  const MeasurementTimeoutError([super.detail]);
  @override
  AppErrorKind get kind => AppErrorKind.measurementTimeout;
}
