import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/theme/app_theme.dart';

/// Plots the extracted, filtered pulse signal. The data is whatever the
/// pipeline produced; nothing here is synthesised or animated.
class WaveformView extends StatelessWidget {
  const WaveformView({
    super.key,
    required this.samples,
    required this.semanticLabel,
    this.height = 96,
  });

  final Float64List? samples;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _WaveformPainter(
            samples: samples,
            color: context.colors.primary,
            gridColor: context.colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.samples,
    required this.color,
    required this.gridColor,
  });

  final Float64List? samples;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );
    final s = samples;
    if (s == null || s.length < 2) return;
    // Robust scale: clip to ±3 SD so a single spike does not flatten the
    // rest of the trace.
    const clip = 3.0;
    final path = Path();
    for (var i = 0; i < s.length; i++) {
      final x = size.width * i / (s.length - 1);
      final v = s[i].clamp(-clip, clip) / clip;
      final y = mid - v * (size.height / 2 - 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      !identical(old.samples, samples) || old.color != color;
}

class TrendPoint {
  const TrendPoint(this.time, this.value);
  final DateTime time;
  final double value;
}

/// Simple time-series chart of saved heart-rate estimates.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.points,
    required this.semanticLabel,
    this.height = 160,
  });

  final List<TrendPoint> points;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _TrendPainter(
            points: points,
            line: context.colors.primary,
            grid: context.colors.outlineVariant.withValues(alpha: 0.6),
            labelStyle: context.text.labelSmall!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            dateFormat: DateFormat.MMMd(locale),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.line,
    required this.grid,
    required this.labelStyle,
    required this.dateFormat,
  });

  final List<TrendPoint> points;
  final Color line;
  final Color grid;
  final TextStyle labelStyle;
  final DateFormat dateFormat;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final sorted = [...points]..sort((a, b) => a.time.compareTo(b.time));
    const leftPad = 36.0;
    const bottomPad = 20.0;
    final plot =
        Rect.fromLTRB(leftPad, 6, size.width - 6, size.height - bottomPad);

    var lo = sorted.map((p) => p.value).reduce(math.min);
    var hi = sorted.map((p) => p.value).reduce(math.max);
    lo = (lo / 10).floor() * 10.0 - 5;
    hi = (hi / 10).ceil() * 10.0 + 5;
    final t0 = sorted.first.time.millisecondsSinceEpoch.toDouble();
    final t1 = sorted.last.time.millisecondsSinceEpoch.toDouble();
    final span = math.max(1.0, t1 - t0);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final v in [lo, (lo + hi) / 2, hi]) {
      final y = plot.bottom - (v - lo) / (hi - lo) * plot.height;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _text(canvas, v.round().toString(), Offset(0, y - 7));
    }
    _text(canvas, dateFormat.format(sorted.first.time.toLocal()),
        Offset(plot.left, plot.bottom + 4));
    final lastLabel = dateFormat.format(sorted.last.time.toLocal());
    final tp = _layout(lastLabel);
    tp.paint(canvas, Offset(plot.right - tp.width, plot.bottom + 4));

    Offset pos(TrendPoint p) => Offset(
          plot.left + (p.time.millisecondsSinceEpoch - t0) / span * plot.width,
          plot.bottom - (p.value - lo) / (hi - lo) * plot.height,
        );

    final path = Path()..moveTo(pos(sorted.first).dx, pos(sorted.first).dy);
    for (final p in sorted.skip(1)) {
      final o = pos(p);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final dot = Paint()..color = line;
    for (final p in sorted) {
      canvas.drawCircle(pos(p), 3.5, dot);
    }
  }

  TextPainter _layout(String s) => TextPainter(
        text: TextSpan(text: s, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

  void _text(Canvas c, String s, Offset o) => _layout(s).paint(c, o);

  @override
  bool shouldRepaint(_TrendPainter old) =>
      !identical(old.points, points) || old.line != line;
}
