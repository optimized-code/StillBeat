import '../../features/measurement/domain/positioning.dart';
import '../../services/camera/camera_source.dart';
import '../../services/face_detection/face_locator.dart';
import 'platform_services_stub.dart'
    if (dart.library.io) 'platform_services_io.dart'
    if (dart.library.js_interop) 'platform_services_web.dart';

/// Platform-specific adapters and capability flags, resolved once at
/// startup and injected through Riverpod so tests can substitute fakes.
class PlatformServices {
  const PlatformServices({
    required this.platformId,
    required this.supportsLiveMeasurement,
    required this.createCamera,
    required this.createFaceLocator,
    this.unsupportedReason,
    this.supportsCameraSelection = false,
    this.analysisRunsInBackgroundIsolate = false,
  });

  final String platformId;
  final bool supportsLiveMeasurement;
  final String? unsupportedReason;
  final CameraSource Function() createCamera;
  final FaceLocator Function(PositioningConfig config) createFaceLocator;
  final bool supportsCameraSelection;

  /// True where `compute` runs work on a separate isolate (native). On web
  /// it runs on the main thread; the per-window cost is a few milliseconds.
  final bool analysisRunsInBackgroundIsolate;

  static PlatformServices detect() => detectPlatformServices();
}
