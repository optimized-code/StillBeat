import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../features/signal_quality/domain/signal_quality.dart';
import 'labels.dart';

/// Centres content and caps its width on tablets and desktop.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: child,
        ),
      );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(Space.lg),
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title!, style: context.text.titleMedium),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

Color qualityColor(BuildContext context, SignalQuality q) => switch (q) {
      SignalQuality.good => context.status.good,
      SignalQuality.acceptable => context.status.acceptable,
      SignalQuality.poor => context.status.poor,
      _ => context.status.neutral,
    };

/// Coloured pill with text (never colour alone, for colour-blind users).
class QualityBadge extends StatelessWidget {
  const QualityBadge(this.quality, {super.key});
  final SignalQuality quality;

  @override
  Widget build(BuildContext context) {
    final label = qualityLabel(context.l10n, quality);
    final color = qualityColor(context, quality);
    return Semantics(
      label: '${context.l10n.resultsQuality}: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.xs,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          label,
          style: context.text.labelLarge?.copyWith(
            color: context.status.onStatus,
          ),
        ),
      ),
    );
  }
}

class DisclaimerNote extends StatelessWidget {
  const DisclaimerNote({super.key, this.short = false});
  final bool short;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: context.colors.onSecondaryContainer,
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              short ? l.disclaimerShort : l.disclaimer,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic error/empty state with an optional action.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.actions = const [],
  });

  final IconData icon;
  final String? title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: context.colors.primary),
          const SizedBox(height: Space.lg),
          if (title != null) ...[
            Text(
              title!,
              style: context.text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.sm),
          ],
          Text(
            message,
            style: context.text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: Space.xl),
            Wrap(
              spacing: Space.md,
              runSpacing: Space.md,
              alignment: WrapAlignment.center,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              flex: 3,
              child: Text(value, style: context.text.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String message,
  required String confirmLabel,
  String? title,
}) async {
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: ctx.colors.error,
            foregroundColor: ctx.colors.onError,
            minimumSize: const Size(64, 44),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}
