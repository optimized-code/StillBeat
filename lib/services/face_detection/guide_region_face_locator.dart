import '../camera/camera_frame.dart';
import '../frame_processing/roi_extractor.dart';
import 'face_locator.dart';

/// Fallback locator for platforms without a supported face detector
/// (currently the web build).
///
/// It does not detect faces. It reports the on-screen guide region as the
/// "face" when enough of the guide is filled with skin-coloured, unclipped
/// pixels. It therefore cannot detect multiple people, cannot reject a
/// skin-coloured non-face object, and cannot measure head pose. The UI
/// discloses this whenever this locator is active.
class GuideRegionFaceLocator implements FaceLocator {
  const GuideRegionFaceLocator({
    required this.guide,
    this.minSkinFraction = 0.35,
  });

  final NormRect guide;
  final double minSkinFraction;

  @override
  FaceLocatorInfo get info => const FaceLocatorInfo(
        id: 'guide-region-skin-heuristic',
        isLearnedDetector: false,
        canDetectMultipleFaces: false,
      );

  @override
  Future<FaceDetectionResult> detect(CameraFrame frame) async {
    final stats = extractRoiStats(frame, guide);
    if (stats.skinFraction >= minSkinFraction) {
      return FaceDetectionResult([DetectedFace(box: guide)]);
    }
    return const FaceDetectionResult([]);
  }

  @override
  Future<void> dispose() async {}
}
