import '../../../services/camera/camera_frame.dart';
import '../../../services/face_detection/face_locator.dart';
import '../../signal_quality/domain/signal_quality.dart';

class PositioningConfig {
  const PositioningConfig({
    this.guide = const NormRect(0.2, 0.15, 0.8, 0.8),
    this.minFaceWidth = 0.25,
    this.maxFaceWidth = 0.85,
    this.maxCenterOffset = 0.15,
    this.maxYawDegrees = 20,
    this.minMeanLuma = 40,
    this.maxMeanLuma = 230,
    this.minSkinFraction = 0.2,
    this.roiInFace = const NormRect(0.2, 0.1, 0.8, 0.7),
  });

  /// On-screen guide region in normalised upright preview coordinates.
  final NormRect guide;

  /// Face box width as a fraction of frame width.
  final double minFaceWidth;
  final double maxFaceWidth;

  /// Allowed distance between face centre and guide centre (normalised).
  final double maxCenterOffset;
  final double maxYawDegrees;
  final double minMeanLuma;
  final double maxMeanLuma;
  final double minSkinFraction;

  /// Measurement ROI as fractions of the face box: forehead and cheeks,
  /// excluding the mouth/chin (speech and jaw motion) and the hairline.
  final NormRect roiInFace;
}

class PositioningStatus {
  const PositioningStatus({required this.issues, this.face});

  final Set<QualityIssue> issues;

  /// The single face used for measurement when exactly one was found.
  final DetectedFace? face;

  bool get isReady => issues.isEmpty && face != null;
}

/// Evaluates whether the detected faces allow a measurement. Never picks
/// one face out of several: multiple faces is always an error so another
/// person's signal is never substituted.
PositioningStatus evaluatePositioning(
  List<DetectedFace> faces,
  PositioningConfig c,
) {
  if (faces.isEmpty) {
    return const PositioningStatus(issues: {QualityIssue.noFace});
  }
  if (faces.length > 1) {
    return const PositioningStatus(issues: {QualityIssue.multipleFaces});
  }
  final f = faces.single;
  final issues = <QualityIssue>{};
  if (f.box.width < c.minFaceWidth) issues.add(QualityIssue.faceTooSmall);
  if (f.box.width > c.maxFaceWidth) issues.add(QualityIssue.faceTooLarge);
  final dx = (f.box.centerX - c.guide.centerX).abs();
  final dy = (f.box.centerY - c.guide.centerY).abs();
  if (dx > c.maxCenterOffset || dy > c.maxCenterOffset) {
    issues.add(QualityIssue.faceOffCenter);
  }
  final yaw = f.yawDegrees;
  if (yaw != null && yaw.abs() > c.maxYawDegrees) {
    issues.add(QualityIssue.notFacingCamera);
  }
  return PositioningStatus(issues: issues, face: f);
}

/// Adds lighting issues from ROI statistics.
Set<QualityIssue> lightingIssues({
  required double meanLuma,
  required double skinFraction,
  required PositioningConfig c,
}) {
  return {
    if (meanLuma.isNaN || meanLuma < c.minMeanLuma) QualityIssue.lowLight,
    if (meanLuma > c.maxMeanLuma) QualityIssue.overexposed,
    if (skinFraction < c.minSkinFraction && meanLuma >= c.minMeanLuma)
      QualityIssue.unevenLighting,
  };
}
