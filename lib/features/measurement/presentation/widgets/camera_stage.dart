import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../services/camera/camera_frame.dart';
import '../../../../services/camera/camera_source.dart';

/// Camera preview with the face guide drawn in the same normalised
/// coordinate space used for positioning checks.
class CameraStage extends ConsumerWidget {
  const CameraStage({
    super.key,
    required this.camera,
    required this.guideReady,
    required this.semanticLabel,
  });

  final CameraSource? camera;
  final bool guideReady;
  final String semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = ref.watch(positioningConfigProvider).guide;
    final aspect = camera?.previewAspectRatio ?? 3 / 4;
    final color = guideReady ? context.status.good : context.colors.onPrimary;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: AspectRatio(
        aspectRatio: aspect,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.black.withValues(alpha: 0.9)),
              if (camera != null)
                ExcludeSemantics(child: camera!.buildPreview(context)),
              IgnorePointer(
                child: CustomPaint(
                  painter: _GuidePainter(guide: guide, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  _GuidePainter({required this.guide, required this.color});
  final NormRect guide;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromLTRB(
      guide.left * size.width,
      guide.top * size.height,
      guide.right * size.width,
      guide.bottom * size.height,
    );
    // Dim everything outside the guide.
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas.drawPath(
        outside, Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawOval(
      oval,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_GuidePainter old) =>
      old.guide != guide || old.color != color;
}
