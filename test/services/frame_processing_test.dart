import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stillbeat/services/camera/camera_frame.dart';
import 'package:stillbeat/services/face_detection/guide_region_face_locator.dart';
import 'package:stillbeat/services/face_detection/nv21.dart';
import 'package:stillbeat/services/frame_processing/roi_extractor.dart';

/// Builds a frame where the left half is skin-coloured and the right half
/// is blue background, in the requested pixel format.
CameraFrame twoToneFrame(
  FramePixelFormat format, {
  int w = 40,
  int h = 30,
  int rotation = 0,
  List<int> skin = const [180, 130, 110],
  List<int> bg = const [30, 50, 200],
}) {
  List<int> rgbAt(int x, int y) => x < w ~/ 2 ? skin : bg;
  (int, int, int) yuv(List<int> c) {
    final r = c[0], g = c[1], b = c[2];
    final y = (0.299 * r + 0.587 * g + 0.114 * b).round();
    final u = (128 - 0.168736 * r - 0.331264 * g + 0.5 * b).round();
    final v = (128 + 0.5 * r - 0.418688 * g - 0.081312 * b).round();
    return (y, u, v);
  }

  switch (format) {
    case FramePixelFormat.rgba8888:
    case FramePixelFormat.bgra8888:
      final bytes = Uint8List(w * h * 4);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final c = rgbAt(x, y);
          final o = (y * w + x) * 4;
          if (format == FramePixelFormat.rgba8888) {
            bytes.setAll(o, [c[0], c[1], c[2], 255]);
          } else {
            bytes.setAll(o, [c[2], c[1], c[0], 255]);
          }
        }
      }
      return CameraFrame(
        timestampMicros: 0,
        width: w,
        height: h,
        format: format,
        rotationDegrees: rotation,
        planes: [
          FramePlane(bytes: bytes, bytesPerRow: w * 4, bytesPerPixel: 4)
        ],
      );
    case FramePixelFormat.yuv420:
      // Padded rows (stride > width) and interleaved chroma (pixelStride 2)
      // mimic real Android buffers.
      final yStride = w + 8;
      final yb = Uint8List(yStride * h);
      final cw = w ~/ 2, ch = h ~/ 2;
      final cStride = w + 4;
      final ub = Uint8List(cStride * ch);
      final vb = Uint8List(cStride * ch);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          yb[y * yStride + x] = yuv(rgbAt(x, y)).$1;
        }
      }
      for (var y = 0; y < ch; y++) {
        for (var x = 0; x < cw; x++) {
          final (_, u, v) = yuv(rgbAt(x * 2, y * 2));
          ub[y * cStride + x * 2] = u;
          vb[y * cStride + x * 2] = v;
        }
      }
      return CameraFrame(
        timestampMicros: 0,
        width: w,
        height: h,
        format: format,
        rotationDegrees: rotation,
        planes: [
          FramePlane(bytes: yb, bytesPerRow: yStride),
          FramePlane(bytes: ub, bytesPerRow: cStride, bytesPerPixel: 2),
          FramePlane(bytes: vb, bytesPerRow: cStride, bytesPerPixel: 2),
        ],
      );
    case FramePixelFormat.nv21:
      final y420 =
          twoToneFrame(FramePixelFormat.yuv420, w: w, h: h, skin: skin, bg: bg);
      return CameraFrame(
        timestampMicros: 0,
        width: w,
        height: h,
        format: FramePixelFormat.nv21,
        rotationDegrees: rotation,
        planes: [FramePlane(bytes: yuv420ToNv21(y420), bytesPerRow: w)],
      );
  }
}

void main() {
  const left = NormRect(0.05, 0.1, 0.45, 0.9);
  const right = NormRect(0.55, 0.1, 0.95, 0.9);

  for (final f in FramePixelFormat.values) {
    test('${f.name}: skin half yields skin mean, background is masked', () {
      final frame = twoToneFrame(f);
      final s = extractRoiStats(frame, left);
      expect(s.skinFraction, greaterThan(0.95));
      expect(s.meanRed, closeTo(180, 4));
      expect(s.meanGreen, closeTo(130, 4));
      expect(s.meanBlue, closeTo(110, 4));
      final bgStats = extractRoiStats(frame, right);
      expect(bgStats.skinFraction, lessThan(0.05));
      expect(bgStats.meanGreen.isNaN, isTrue);
    });
  }

  test('rotation maps upright ROI to the correct raw pixels', () {
    // Raw frame: skin on the raw left half. After rotating 90° clockwise
    // the raw left half becomes the upright TOP half.
    final frame = twoToneFrame(FramePixelFormat.rgba8888, rotation: 90);
    expect(frame.uprightWidth, frame.height);
    expect(frame.uprightHeight, frame.width);
    final top = extractRoiStats(frame, const NormRect(0.1, 0.05, 0.9, 0.45));
    final bottom = extractRoiStats(frame, const NormRect(0.1, 0.55, 0.9, 0.95));
    expect(top.skinFraction, greaterThan(0.95));
    expect(bottom.skinFraction, lessThan(0.05));

    // 270°: raw left half becomes the upright BOTTOM half.
    final f270 = twoToneFrame(FramePixelFormat.rgba8888, rotation: 270);
    expect(
      extractRoiStats(f270, const NormRect(0.1, 0.55, 0.9, 0.95)).skinFraction,
      greaterThan(0.95),
    );
  });

  test('upright→raw mapping is a bijection for each rotation', () {
    for (final rot in [0, 90, 180, 270]) {
      final f = CameraFrame(
        timestampMicros: 0,
        width: 6,
        height: 4,
        format: FramePixelFormat.rgba8888,
        rotationDegrees: rot,
        planes: const [],
      );
      final seen = <(int, int)>{};
      for (var v = 0; v < f.uprightHeight; v++) {
        for (var u = 0; u < f.uprightWidth; u++) {
          final (x, y) = uprightToRawForTest(u, v, f);
          expect(x, inInclusiveRange(0, 5));
          expect(y, inInclusiveRange(0, 3));
          seen.add((x, y));
        }
      }
      expect(seen, hasLength(24), reason: 'rotation $rot');
    }
  });

  test('saturated pixels are excluded', () {
    final frame = twoToneFrame(
      FramePixelFormat.rgba8888,
      skin: const [255, 200, 180],
    );
    final s = extractRoiStats(frame, left);
    expect(s.clippedFraction, greaterThan(0.95));
    expect(s.skinPixels, 0);
  });

  test('pixel visits are bounded regardless of resolution', () {
    final frame = twoToneFrame(FramePixelFormat.rgba8888, w: 640, h: 480);
    final s = extractRoiStats(frame, const NormRect(0, 0, 1, 1));
    expect(s.sampledPixels, lessThanOrEqualTo(4096 * 1.2));
  });

  test('empty or out-of-frame ROI returns empty stats', () {
    final frame = twoToneFrame(FramePixelFormat.rgba8888);
    expect(
        extractRoiStats(frame, const NormRect(0.5, 0.5, 0.5, 0.9))
            .sampledPixels,
        0);
    expect(
        extractRoiStats(frame, const NormRect(1.2, 1.2, 1.5, 1.5))
            .sampledPixels,
        0);
  });

  test('yuv420ToNv21 packs Y then interleaved VU', () {
    final f = twoToneFrame(FramePixelFormat.yuv420, w: 4, h: 2);
    final nv = yuv420ToNv21(f);
    expect(nv.length, 4 * 2 + 2 * 2 * 1);
    expect(nv.sublist(0, 4), [
      f.planes[0].bytes[0],
      f.planes[0].bytes[1],
      f.planes[0].bytes[2],
      f.planes[0].bytes[3],
    ]);
    expect(nv[8], f.planes[2].bytes[0]); // V first
    expect(nv[9], f.planes[1].bytes[0]); // then U
  });

  test('guide-region locator reports a face only when skin fills the guide',
      () async {
    final frame = twoToneFrame(FramePixelFormat.rgba8888);
    final yes = await const GuideRegionFaceLocator(guide: left).detect(frame);
    final no = await const GuideRegionFaceLocator(guide: right).detect(frame);
    expect(yes.faces, hasLength(1));
    expect(no.faces, isEmpty);
    expect(const GuideRegionFaceLocator(guide: left).info.isLearnedDetector,
        isFalse);
  });

  test('NormRect helpers', () {
    const r = NormRect(0.2, 0.2, 0.6, 0.8);
    expect(r.width, closeTo(0.4, 1e-12));
    expect(r.centerY, closeTo(0.5, 1e-12));
    final sub = r.fraction(0.5, 0, 1, 0.5);
    expect(sub, const NormRect(0.4, 0.2, 0.6, 0.5));
    expect(
        const NormRect(-1, -1, 2, 2).clampToUnit(), const NormRect(0, 0, 1, 1));
  });
}
