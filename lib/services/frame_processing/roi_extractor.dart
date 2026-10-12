import 'dart:math' as math;

import '../camera/camera_frame.dart';

class RoiExtractionConfig {
  const RoiExtractionConfig({
    this.maxSampledPixels = 4096,
    this.minSkinPixels = 64,
    this.clipThreshold = 250,
    this.skinCbMin = 77,
    this.skinCbMax = 127,
    this.skinCrMin = 133,
    this.skinCrMax = 173,
  });

  /// Upper bound on pixels visited per frame. Spatial averaging over a few
  /// thousand pixels already suppresses sensor noise well; touching every
  /// pixel would cost CPU without improving the mean materially.
  final int maxSampledPixels;

  /// Minimum skin pixels for a frame to count as valid.
  final int minSkinPixels;

  /// Pixels with any channel at or above this are saturated and excluded
  /// (a clipped channel cannot carry the pulse modulation).
  final int clipThreshold;

  /// Explicit YCbCr skin-colour bounds (Chai & Ngan, 1999). Deliberately
  /// broad; this is a mask to drop hair, eyes and background, not a
  /// classifier of people.
  final int skinCbMin;
  final int skinCbMax;
  final int skinCrMin;
  final int skinCrMax;
}

/// Aggregate colour statistics of one region. No pixel data is retained.
class RoiStats {
  const RoiStats({
    required this.meanRed,
    required this.meanGreen,
    required this.meanBlue,
    required this.meanLuma,
    required this.skinFraction,
    required this.clippedFraction,
    required this.sampledPixels,
    required this.skinPixels,
  });

  final double meanRed;
  final double meanGreen;
  final double meanBlue;

  /// Mean luma over all sampled ROI pixels (skin or not).
  final double meanLuma;
  final double skinFraction;
  final double clippedFraction;
  final int sampledPixels;
  final int skinPixels;
}

/// Computes mean skin colour inside [roi] (normalised upright coordinates)
/// for any supported pixel format, honouring frame rotation.
///
/// Cost is bounded by [RoiExtractionConfig.maxSampledPixels] regardless of
/// camera resolution, so this is cheap enough to run per frame.
RoiStats extractRoiStats(
  CameraFrame frame,
  NormRect roi, {
  RoiExtractionConfig config = const RoiExtractionConfig(),
}) {
  final r = roi.clampToUnit();
  final uw = frame.uprightWidth;
  final uh = frame.uprightHeight;
  final u0 = (r.left * uw).floor();
  final u1 = math.min(uw, (r.right * uw).ceil());
  final v0 = (r.top * uh).floor();
  final v1 = math.min(uh, (r.bottom * uh).ceil());
  final areaW = u1 - u0;
  final areaH = v1 - v0;
  if (areaW <= 0 || areaH <= 0) return _empty;

  final step = math.max(
    1,
    math.sqrt(areaW * areaH / config.maxSampledPixels).ceil(),
  );
  final reader = _PixelReader.forFrame(frame);

  var sumR = 0.0, sumG = 0.0, sumB = 0.0, sumY = 0.0;
  var sampled = 0, skin = 0, clipped = 0;
  final px = _Pixel();
  for (var v = v0; v < v1; v += step) {
    for (var u = u0; u < u1; u += step) {
      final (x, y) = _uprightToRaw(u, v, frame);
      reader.read(x, y, px);
      sampled++;
      sumY += px.y;
      if (px.r >= config.clipThreshold ||
          px.g >= config.clipThreshold ||
          px.b >= config.clipThreshold) {
        clipped++;
        continue;
      }
      if (px.cb < config.skinCbMin ||
          px.cb > config.skinCbMax ||
          px.cr < config.skinCrMin ||
          px.cr > config.skinCrMax) {
        continue;
      }
      skin++;
      sumR += px.r;
      sumG += px.g;
      sumB += px.b;
    }
  }
  if (sampled == 0) return _empty;
  return RoiStats(
    meanRed: skin > 0 ? sumR / skin : double.nan,
    meanGreen: skin > 0 ? sumG / skin : double.nan,
    meanBlue: skin > 0 ? sumB / skin : double.nan,
    meanLuma: sumY / sampled,
    skinFraction: skin / sampled,
    clippedFraction: clipped / sampled,
    sampledPixels: sampled,
    skinPixels: skin,
  );
}

const _empty = RoiStats(
  meanRed: double.nan,
  meanGreen: double.nan,
  meanBlue: double.nan,
  meanLuma: double.nan,
  skinFraction: 0,
  clippedFraction: 0,
  sampledPixels: 0,
  skinPixels: 0,
);

/// Maps an upright pixel coordinate back to the raw buffer.
(int, int) _uprightToRaw(int u, int v, CameraFrame f) {
  return switch (f.rotationDegrees) {
    90 => (v, f.height - 1 - u),
    180 => (f.width - 1 - u, f.height - 1 - v),
    270 => (f.width - 1 - v, u),
    _ => (u, v),
  };
}

/// Exposed for tests.
(int, int) uprightToRawForTest(int u, int v, CameraFrame f) =>
    _uprightToRaw(u, v, f);

class _Pixel {
  double r = 0, g = 0, b = 0, y = 0, cb = 0, cr = 0;

  void setYuv(int yy, int uu, int vv) {
    // Full-range BT.601 (JFIF). Camera YUV on Android/iOS is full range in
    // practice; any affine mismatch is a per-channel gain/offset, which the
    // rPPG algorithms remove through temporal normalisation.
    y = yy.toDouble();
    cb = uu.toDouble();
    cr = vv.toDouble();
    final du = uu - 128.0;
    final dv = vv - 128.0;
    r = (yy + 1.402 * dv).clamp(0.0, 255.0);
    g = (yy - 0.344136 * du - 0.714136 * dv).clamp(0.0, 255.0);
    b = (yy + 1.772 * du).clamp(0.0, 255.0);
  }

  void setRgb(int rr, int gg, int bb) {
    r = rr.toDouble();
    g = gg.toDouble();
    b = bb.toDouble();
    y = 0.299 * r + 0.587 * g + 0.114 * b;
    cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
    cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
  }
}

abstract class _PixelReader {
  factory _PixelReader.forFrame(CameraFrame f) => switch (f.format) {
        FramePixelFormat.yuv420 => _Yuv420Reader(f),
        FramePixelFormat.nv21 => _Nv21Reader(f),
        FramePixelFormat.bgra8888 => _PackedReader(f, bgra: true),
        FramePixelFormat.rgba8888 => _PackedReader(f, bgra: false),
      };

  void read(int x, int y, _Pixel out);
}

class _Yuv420Reader implements _PixelReader {
  _Yuv420Reader(CameraFrame f)
      : yp = f.planes[0],
        up = f.planes[1],
        vp = f.planes[2];
  final FramePlane yp, up, vp;

  @override
  void read(int x, int y, _Pixel out) {
    final yy = yp.bytes[y * yp.bytesPerRow + x * yp.bytesPerPixel];
    final cx = x >> 1, cy = y >> 1;
    final uu = up.bytes[cy * up.bytesPerRow + cx * up.bytesPerPixel];
    final vv = vp.bytes[cy * vp.bytesPerRow + cx * vp.bytesPerPixel];
    out.setYuv(yy, uu, vv);
  }
}

class _Nv21Reader implements _PixelReader {
  _Nv21Reader(CameraFrame f)
      : bytes = f.planes[0].bytes,
        stride = f.planes[0].bytesPerRow,
        height = f.height;
  final List<int> bytes;
  final int stride;
  final int height;

  @override
  void read(int x, int y, _Pixel out) {
    final yy = bytes[y * stride + x];
    final off = stride * height + (y >> 1) * stride + (x & ~1);
    out.setYuv(yy, bytes[off + 1], bytes[off]);
  }
}

class _PackedReader implements _PixelReader {
  _PackedReader(CameraFrame f, {required this.bgra})
      : bytes = f.planes[0].bytes,
        stride = f.planes[0].bytesPerRow;
  final List<int> bytes;
  final int stride;
  final bool bgra;

  @override
  void read(int x, int y, _Pixel out) {
    final o = y * stride + x * 4;
    if (bgra) {
      out.setRgb(bytes[o + 2], bytes[o + 1], bytes[o]);
    } else {
      out.setRgb(bytes[o], bytes[o + 1], bytes[o + 2]);
    }
  }
}
