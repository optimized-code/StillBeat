import 'package:flutter/widgets.dart';

import 'camera_frame.dart';

class CameraDeviceInfo {
  const CameraDeviceInfo({required this.id, required this.label});
  final String id;
  final String label;
}

/// Platform-neutral live camera acquisition.
///
/// Implementations must:
///  * request permission only inside [open] (called after a user action);
///  * never record video to disk;
///  * release every hardware resource in [close], which must be idempotent.
abstract interface class CameraSource {
  /// Opens the (front-facing, where available) camera and starts streaming.
  /// Throws an [AppError] subtype on failure.
  Future<void> open({String? deviceId});

  /// Frames from the currently open camera. Errors after opening (device
  /// lost, permission revoked) are delivered as stream errors of type
  /// [AppError].
  Stream<CameraFrame> get frames;

  /// Upright preview aspect ratio (width / height), once open.
  double? get previewAspectRatio;

  /// Whether the preview is displayed mirrored (selfie view).
  bool get isMirrored;

  Widget buildPreview(BuildContext context);

  /// Cameras available for selection. May be empty or unlabeled until
  /// permission has been granted (browser behaviour).
  Future<List<CameraDeviceInfo>> listCameras();

  Future<void> close();
}
