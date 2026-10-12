import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/brand.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/labels.dart';
import '../../settings/presentation/settings_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;
  bool _acknowledged = false;
  bool _saving = false;

  static const _icons = [
    Icons.favorite_outline,
    Icons.wb_sunny_outlined,
    Icons.rule_outlined,
    Icons.lock_outline,
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    if (context.reduceMotion) {
      _pages.jumpToPage(i);
    } else {
      _pages.animateToPage(
        i,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .acknowledgeDisclaimer();
      if (mounted) context.go(Routes.home);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorStorageFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final titles = [
      l.onboardingTitle1,
      l.onboardingTitle2,
      l.onboardingTitle3,
      l.onboardingTitle4,
    ];
    final bodies = [
      l.onboardingBody1,
      l.onboardingBody2,
      l.onboardingBody3,
      l.onboardingBody4,
    ];
    final total = titles.length + 1;
    final isLast = _index == total - 1;

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xl,
                  Space.lg,
                  Space.xl,
                  0,
                ),
                child: Row(
                  children: [
                    Text(AppBrand.name, style: context.text.titleLarge),
                    const Spacer(),
                    Text(
                      l.onboardingStepLabel(_index + 1, total),
                      style: context.text.labelMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    for (var i = 0; i < titles.length; i++)
                      _InfoPage(
                        icon: _icons[i],
                        title: titles[i],
                        body: bodies[i],
                        footer: i == 3
                            ? TextButton(
                                onPressed: () => context.push(Routes.privacy),
                                child: Text(l.homePrivacy),
                              )
                            : null,
                      ),
                    _AcknowledgePage(
                      acknowledged: _acknowledged,
                      onChanged: (v) => setState(() => _acknowledged = v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Row(
                  children: [
                    if (_index > 0)
                      TextButton(
                        onPressed: () => _goTo(_index - 1),
                        child: Text(l.commonBack),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: isLast
                          ? (_acknowledged && !_saving ? _finish : null)
                          : () => _goTo(_index + 1),
                      child: Text(
                        isLast ? l.onboardingGetStarted : l.commonContinue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({
    required this.icon,
    required this.title,
    required this.body,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Space.xxl),
          CircleAvatar(
            radius: 36,
            backgroundColor: context.colors.primaryContainer,
            child:
                Icon(icon, size: 36, color: context.colors.onPrimaryContainer),
          ),
          const SizedBox(height: Space.xl),
          Semantics(
            header: true,
            child: Text(title, style: context.text.headlineSmall),
          ),
          const SizedBox(height: Space.lg),
          Text(body, style: context.text.bodyLarge),
          if (footer != null) ...[
            const SizedBox(height: Space.md),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _AcknowledgePage extends StatelessWidget {
  const _AcknowledgePage({required this.acknowledged, required this.onChanged});
  final bool acknowledged;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Space.xxl),
          const DisclaimerNote(),
          const SizedBox(height: Space.xl),
          CheckboxListTile(
            value: acknowledged,
            onChanged: (v) => onChanged(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(l.onboardingAcknowledge),
          ),
        ],
      ),
    );
  }
}
