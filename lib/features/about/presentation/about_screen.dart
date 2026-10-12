import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../services/rppg/rppg_engine.dart';
import '../../../services/rppg/window_analyzer.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/labels.dart';
import '../../settings/presentation/settings_controller.dart';

/// Methodology, algorithms, licences and limitations.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final active =
        ref.watch(settingsControllerProvider.select((s) => s.method));
    final platform = ref.watch(platformServicesProvider);
    final version = ref.watch(appVersionProvider);
    final algos = [
      for (final m in PulseMethod.values) AlgorithmInfo.forMethod(m),
      AlgorithmInfo.neuralPlaceholder,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.aboutTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    title: l.aboutPipelineTitle,
                    child: Text(l.aboutPipelineBody,
                        style: context.text.bodyMedium),
                  ),
                  const SizedBox(height: Space.md),
                  SectionCard(
                    title: l.aboutAlgorithmsTitle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final a in algos) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${a.displayName} · v${a.version}',
                                  style: context.text.titleSmall,
                                ),
                              ),
                              if (a.id == AlgorithmInfo.forMethod(active).id)
                                Chip(label: Text(l.aboutActiveAlgorithm)),
                            ],
                          ),
                          Text(
                            a.kind == AlgorithmKind.neuralNetwork
                                ? l.resultsAlgorithmKindNeural
                                : l.resultsAlgorithmKindSignal,
                            style: context.text.labelMedium,
                          ),
                          const SizedBox(height: Space.xs),
                          SelectableText(a.citation,
                              style: context.text.bodySmall),
                          Text(a.implementationNote,
                              style: context.text.bodySmall),
                          const SizedBox(height: Space.md),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  SectionCard(
                    title: l.aboutFaceDetectionTitle,
                    child: Text(
                      platform.platformId == 'web'
                          ? l.aboutFaceDetectionWeb
                          : l.aboutFaceDetectionMobile,
                      style: context.text.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  SectionCard(
                    title: l.aboutQualityTitle,
                    child: Text(l.qualityExplanation,
                        style: context.text.bodyMedium),
                  ),
                  const SizedBox(height: Space.md),
                  SectionCard(
                    title: l.aboutNeuralTitle,
                    child:
                        Text(l.aboutNeuralBody, style: context.text.bodyMedium),
                  ),
                  const SizedBox(height: Space.md),
                  SectionCard(
                    title: l.aboutLimitationsTitle,
                    child: Text(l.aboutLimitationsBody,
                        style: context.text.bodyMedium),
                  ),
                  const SizedBox(height: Space.md),
                  const DisclaimerNote(),
                  const SizedBox(height: Space.md),
                  OutlinedButton(
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: AppBrand.name,
                      applicationVersion: version.display,
                    ),
                    child: Text(l.aboutNotices),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
