import 'dart:collection';
import 'dart:typed_data';

/// One per-frame observation: aggregate colour statistics of the facial
/// region of interest. No pixels are retained.
class RgbSample {
  const RgbSample({
    required this.timestampMicros,
    required this.red,
    required this.green,
    required this.blue,
    required this.luma,
    required this.faceValid,
    required this.motion,
  });

  /// A frame where no usable face region was available.
  const RgbSample.invalid(this.timestampMicros)
      : red = double.nan,
        green = double.nan,
        blue = double.nan,
        luma = double.nan,
        faceValid = false,
        motion = 0;

  /// Monotonic capture timestamp in microseconds.
  final int timestampMicros;

  /// Mean channel values (0–255) over skin pixels in the ROI.
  final double red;
  final double green;
  final double blue;

  /// Mean ROI luma (0–255).
  final double luma;

  final bool faceValid;

  /// ROI centre displacement since the previous sample, in face widths.
  final double motion;
}

/// Bounded FIFO of recent samples. Old samples are evicted once [capacity]
/// is reached so memory stays constant for any session length.
class SignalBuffer {
  SignalBuffer({required this.capacity}) : assert(capacity > 0);

  final int capacity;
  final Queue<RgbSample> _samples = Queue<RgbSample>();

  int get length => _samples.length;
  bool get isEmpty => _samples.isEmpty;
  RgbSample? get last => _samples.isEmpty ? null : _samples.last;

  /// Adds [s]. Samples whose timestamp does not advance are dropped:
  /// duplicated or reordered frames would break resampling.
  bool add(RgbSample s) {
    final prev = last;
    if (prev != null && s.timestampMicros <= prev.timestampMicros) {
      return false;
    }
    _samples.addLast(s);
    while (_samples.length > capacity) {
      _samples.removeFirst();
    }
    return true;
  }

  void clear() => _samples.clear();

  /// Copies samples at or after [sinceMicros] into a transferable snapshot.
  SampleSnapshot snapshotSince(int sinceMicros) {
    final selected = _samples.where((s) => s.timestampMicros >= sinceMicros);
    final list = selected.toList(growable: false);
    final n = list.length;
    // Not Int64List: it is unsupported when compiled to JavaScript.
    final t = List<int>.filled(n, 0);
    final r = Float64List(n);
    final g = Float64List(n);
    final b = Float64List(n);
    final y = Float64List(n);
    final m = Float64List(n);
    final f = Uint8List(n);
    for (var i = 0; i < n; i++) {
      final s = list[i];
      t[i] = s.timestampMicros;
      r[i] = s.red;
      g[i] = s.green;
      b[i] = s.blue;
      y[i] = s.luma;
      m[i] = s.motion;
      f[i] = s.faceValid ? 1 : 0;
    }
    return SampleSnapshot(
      timestampsMicros: t,
      red: r,
      green: g,
      blue: b,
      luma: y,
      motion: m,
      faceValid: f,
    );
  }
}

/// Plain typed-data copy of buffered samples, safe to send to an isolate.
class SampleSnapshot {
  const SampleSnapshot({
    required this.timestampsMicros,
    required this.red,
    required this.green,
    required this.blue,
    required this.luma,
    required this.motion,
    required this.faceValid,
  });

  final List<int> timestampsMicros;
  final Float64List red;
  final Float64List green;
  final Float64List blue;
  final Float64List luma;
  final Float64List motion;
  final Uint8List faceValid;

  int get length => timestampsMicros.length;
}
