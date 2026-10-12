import '../../services/face_detection/guide_region_face_locator.dart';
import '../errors/app_error.dart';
import 'platform_services.dart';

PlatformServices detectPlatformServices() => PlatformServices(
      platformId: 'unknown',
      supportsLiveMeasurement: false,
      unsupportedReason: 'Unsupported platform',
      createCamera: () => throw const UnsupportedPlatformError(),
      createFaceLocator: (c) => GuideRegionFaceLocator(guide: c.guide),
    );
