import 'dart:typed_data';

enum FramePixelFormat {
  /// Android YUV_420_888: three planes with arbitrary row/pixel strides.
  yuv420,

  /// Single plane: Y followed by interleaved V/U at half resolution.
  nv21,

  /// iOS kCVPixelFormatType_32BGRA.
  bgra8888,

  /// Browser canvas ImageData.
  rgba8888,
}

class FramePlane {
  const FramePlane({
    required this.bytes,
    required this.bytesPerRow,
    this.bytesPerPixel = 1,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

/// A single camera frame in its raw sensor orientation.
///
/// Frames are transient: they are processed immediately into aggregate
/// statistics and never stored.
class CameraFrame {
  const CameraFrame({
    required this.timestampMicros,
    required this.width,
    required this.height,
    required this.format,
    required this.planes,
    this.rotationDegrees = 0,
  });

  /// Monotonic capture time.
  final int timestampMicros;

  /// Raw buffer dimensions.
  final int width;
  final int height;
  final FramePixelFormat format;
  final List<FramePlane> planes;

  /// Clockwise rotation that turns the raw buffer upright (0/90/180/270).
  final int rotationDegrees;

  bool get _swapsAxes => rotationDegrees == 90 || rotationDegrees == 270;
  int get uprightWidth => _swapsAxes ? height : width;
  int get uprightHeight => _swapsAxes ? width : height;
}

/// Axis-aligned rectangle in normalised upright frame coordinates (0..1).
class NormRect {
  const NormRect(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  bool get isEmpty => width <= 0 || height <= 0;

  /// Sub-rectangle expressed in fractions of this rectangle.
  NormRect fraction(double l, double t, double r, double b) => NormRect(
        left + width * l,
        top + height * t,
        left + width * r,
        top + height * b,
      );

  NormRect clampToUnit() => NormRect(
        left.clamp(0.0, 1.0),
        top.clamp(0.0, 1.0),
        right.clamp(0.0, 1.0),
        bottom.clamp(0.0, 1.0),
      );

  @override
  bool operator ==(Object other) =>
      other is NormRect &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'NormRect($left, $top, $right, $bottom)';
}
