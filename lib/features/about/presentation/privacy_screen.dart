import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/storage/app_database.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/labels.dart';

/// In-app privacy notice. Must stay consistent with docs/privacy.md and the
/// actual implementation.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final degraded = ref.watch(storageDegradedProvider);
    final backend = degraded ? 'in-memory' : storageBackendInfo.name;
    final sections = [
      (l.privacyBody1Title, l.privacyBody1),
      (l.privacyBody2Title, l.privacyBody2(backend)),
      (l.privacyBody3Title, l.privacyBody3),
      (l.privacyBody4Title, l.privacyBody4),
      (l.privacyBody5Title, l.privacyBody5),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.privacyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (title, body) in sections) ...[
                    SectionCard(
                      title: title,
                      child: Text(body, style: context.text.bodyMedium),
                    ),
                    const SizedBox(height: Space.md),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
