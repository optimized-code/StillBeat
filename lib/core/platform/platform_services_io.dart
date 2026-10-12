import 'dart:io' show Platform;

import '../../services/camera/mobile_camera_source.dart';
import '../../services/face_detection/guide_region_face_locator.dart';
import '../../services/face_detection/mlkit_face_locator.dart';
import '../errors/app_error.dart';
import 'platform_services.dart';

PlatformServices detectPlatformServices() {
  if (Platform.isAndroid || Platform.isIOS) {
    return PlatformServices(
      platformId: Platform.isAndroid ? 'android' : 'ios',
      supportsLiveMeasurement: true,
      createCamera: MobileCameraSource.new,
      createFaceLocator: (_) => MlKitFaceLocator(),
      analysisRunsInBackgroundIsolate: true,
    );
  }
  return PlatformServices(
    platformId: Platform.operatingSystem,
    supportsLiveMeasurement: false,
    unsupportedReason: 'Live measurement is supported on Android, iOS and web '
        'browsers only.',
    createCamera: () => throw const UnsupportedPlatformError('desktop'),
    createFaceLocator: (c) => GuideRegionFaceLocator(guide: c.guide),
    analysisRunsInBackgroundIsolate: true,
  );
}
