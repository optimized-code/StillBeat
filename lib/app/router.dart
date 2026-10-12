import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/about/presentation/about_screen.dart';
import '../features/about/presentation/privacy_screen.dart';
import '../features/history/presentation/history_detail_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/measurement/presentation/measurement_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/results/presentation/results_screen.dart';
import '../features/settings/presentation/settings_controller.dart';
import '../features/settings/presentation/settings_screen.dart';

abstract final class Routes {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const measure = '/measure';
  static const results = '/results';
  static const history = '/history';
  static String historyDetail(String id) => '/history/$id';
  static const settings = '/settings';
  static const about = '/about';
  static const privacy = '/privacy';
}

/// Re-evaluates redirects when the acknowledgement state changes.
class _AckListenable extends ChangeNotifier {
  _AckListenable(Ref ref) {
    ref.listen(
      settingsControllerProvider.select((s) => s.hasAcknowledgedDisclaimer),
      (_, __) => notifyListeners(),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AckListenable(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final ack =
          ref.read(settingsControllerProvider).hasAcknowledgedDisclaimer;
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      // Privacy information must be readable before acknowledging.
      final exempt = state.matchedLocation == Routes.privacy ||
          state.matchedLocation == Routes.about;
      if (!ack && !atOnboarding && !exempt) return Routes.onboarding;
      if (ack && atOnboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.measure,
        builder: (_, __) => const MeasurementScreen(),
      ),
      GoRoute(path: Routes.results, builder: (_, __) => const ResultsScreen()),
      GoRoute(
        path: Routes.history,
        builder: (_, __) => const HistoryScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, s) => HistoryDetailScreen(id: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(path: Routes.about, builder: (_, __) => const AboutScreen()),
      GoRoute(path: Routes.privacy, builder: (_, __) => const PrivacyScreen()),
    ],
  );
});
