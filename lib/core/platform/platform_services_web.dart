import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../../services/camera/web_camera_source.dart';
import '../../services/face_detection/guide_region_face_locator.dart';
import 'platform_services.dart';

PlatformServices detectPlatformServices() {
  String? reason;
  if (!web.window.isSecureContext) {
    reason = 'Camera access requires HTTPS (or localhost).';
  } else if (!(web.window.navigator as JSObject).has('mediaDevices')) {
    reason = 'This browser does not provide camera access (mediaDevices).';
  }
  return PlatformServices(
    platformId: 'web',
    supportsLiveMeasurement: reason == null,
    unsupportedReason: reason,
    createCamera: WebCameraSource.new,
    // No face detector is bundled for web (see docs/technical_decisions.md);
    // the guide-region heuristic is disclosed in the UI.
    createFaceLocator: (c) => GuideRegionFaceLocator(guide: c.guide),
    supportsCameraSelection: true,
  );
}
