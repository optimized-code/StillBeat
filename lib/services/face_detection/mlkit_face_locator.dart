import 'dart:io' show Platform;
import 'dart:ui' show Size;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../camera/camera_frame.dart';
import 'face_locator.dart';
import 'nv21.dart';

/// On-device face detection via Google ML Kit (Android/iOS only).
///
/// Only bounding boxes and head yaw are requested. Landmarks, contours,
/// classification (smile/eyes) and cross-frame tracking IDs are disabled.
class MlKitFaceLocator implements FaceLocator {
  MlKitFaceLocator()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            enableTracking: false,
            enableClassification: false,
            enableLandmarks: false,
            enableContours: false,
            minFaceSize: 0.15,
          ),
        );

  final FaceDetector _detector;

  @override
  FaceLocatorInfo get info => const FaceLocatorInfo(
        id: 'google-mlkit-face-detection',
        isLearnedDetector: true,
        canDetectMultipleFaces: true,
      );

  @override
  Future<FaceDetectionResult> detect(CameraFrame frame) async {
    final input = _toInputImage(frame);
    final faces = await _detector.processImage(input);

    // Android: ML Kit returns boxes in the rotated (upright) space we asked
    // for. iOS: we pass rotation 0 and frames arrive upright from the
    // plugin, so raw == upright. Verify on hardware (docs/testing.md).
    final w = frame.uprightWidth.toDouble();
    final h = frame.uprightHeight.toDouble();
    return FaceDetectionResult([
      for (final f in faces)
        DetectedFace(
          box: NormRect(
            f.boundingBox.left / w,
            f.boundingBox.top / h,
            f.boundingBox.right / w,
            f.boundingBox.bottom / h,
          ),
          yawDegrees: f.headEulerAngleY,
        ),
    ]);
  }

  InputImage _toInputImage(CameraFrame f) {
    if (Platform.isAndroid) {
      return InputImage.fromBytes(
        bytes: yuv420ToNv21(f),
        metadata: InputImageMetadata(
          size: Size(f.width.toDouble(), f.height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(f.rotationDegrees) ??
              InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: f.width,
        ),
      );
    }
    if (f.format != FramePixelFormat.bgra8888) {
      throw ArgumentError('iOS face detection expects BGRA frames');
    }
    return InputImage.fromBytes(
      bytes: f.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(f.width.toDouble(), f.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: f.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  Future<void> dispose() => _detector.close();
}
