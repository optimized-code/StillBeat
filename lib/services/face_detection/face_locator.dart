import '../camera/camera_frame.dart';

/// A face found in a frame, in normalised upright coordinates.
///
/// Detection is used only to position the measurement region. No identity,
/// landmarks for recognition, tracking IDs across sessions or demographic
/// attributes are requested or stored.
class DetectedFace {
  const DetectedFace({required this.box, this.yawDegrees});

  final NormRect box;

  /// Head rotation around the vertical axis, when the detector reports it.
  final double? yawDegrees;
}

class FaceDetectionResult {
  const FaceDetectionResult(this.faces);
  final List<DetectedFace> faces;
}

class FaceLocatorInfo {
  const FaceLocatorInfo({
    required this.id,
    required this.isLearnedDetector,
    required this.canDetectMultipleFaces,
  });

  final String id;

  /// False for the heuristic guide-region locator, which only checks that
  /// skin-coloured pixels fill the guide and cannot confirm a face.
  final bool isLearnedDetector;
  final bool canDetectMultipleFaces;
}

abstract interface class FaceLocator {
  FaceLocatorInfo get info;
  Future<FaceDetectionResult> detect(CameraFrame frame);
  Future<void> dispose();
}
