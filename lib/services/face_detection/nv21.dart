import 'dart:typed_data';

import '../camera/camera_frame.dart';

/// Packs a YUV_420_888 frame (arbitrary strides) into a tightly packed NV21
/// buffer, which is the byte layout ML Kit accepts on Android.
Uint8List yuv420ToNv21(CameraFrame f) {
  if (f.format == FramePixelFormat.nv21) return f.planes[0].bytes;
  if (f.format != FramePixelFormat.yuv420) {
    throw ArgumentError('Expected yuv420, got ${f.format}');
  }
  final w = f.width;
  final h = f.height;
  final out = Uint8List(w * h + 2 * ((w + 1) >> 1) * ((h + 1) >> 1));
  final yp = f.planes[0];
  final up = f.planes[1];
  final vp = f.planes[2];

  var o = 0;
  for (var y = 0; y < h; y++) {
    final row = y * yp.bytesPerRow;
    if (yp.bytesPerPixel == 1) {
      out.setRange(o, o + w, yp.bytes, row);
      o += w;
    } else {
      for (var x = 0; x < w; x++) {
        out[o++] = yp.bytes[row + x * yp.bytesPerPixel];
      }
    }
  }
  final cw = (w + 1) >> 1;
  final ch = (h + 1) >> 1;
  for (var y = 0; y < ch; y++) {
    final vr = y * vp.bytesPerRow;
    final ur = y * up.bytesPerRow;
    for (var x = 0; x < cw; x++) {
      out[o++] = vp.bytes[vr + x * vp.bytesPerPixel];
      out[o++] = up.bytes[ur + x * up.bytesPerPixel];
    }
  }
  return out;
}
