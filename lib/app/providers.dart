import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../core/platform/platform_services.dart';
import '../features/history/data/measurement_repository.dart';
import '../features/measurement/domain/measurement_result.dart';
import '../features/measurement/domain/positioning.dart';
import '../features/measurement/domain/result_aggregator.dart';
import '../features/measurement/domain/session_config.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/signal_quality/domain/quality_config.dart';
import '../services/export/export_service.dart';
import '../services/rppg/rppg_config.dart';
import '../services/rppg/rppg_engine.dart';
import '../services/rppg/window_analyzer.dart';
import 'brand.dart';

/// Overridden at bootstrap with the opened database.
final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

/// Overridden at bootstrap with version information.
final appVersionProvider = Provider<AppVersion>(
  (ref) => const AppVersion(version: '0.0.0', buildNumber: '0'),
);

final platformServicesProvider =
    Provider<PlatformServices>((ref) => PlatformServices.detect());

final measurementRepositoryProvider = Provider<MeasurementRepository>(
  (ref) => SembastMeasurementRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SembastSettingsRepository(ref.watch(databaseProvider)),
);

final rppgConfigProvider = Provider<RppgConfig>((ref) => const RppgConfig());
final qualityConfigProvider =
    Provider<QualityConfig>((ref) => const QualityConfig());
final positioningConfigProvider =
    Provider<PositioningConfig>((ref) => const PositioningConfig());
final aggregationConfigProvider =
    Provider<AggregationConfig>((ref) => const AggregationConfig());
final sessionConfigProvider =
    Provider<SessionConfig>((ref) => const SessionConfig());

/// Builds the engine for a selected method. The neural slot is exposed so
/// the UI can show its (unavailable) status.
final rppgEngineProvider = Provider.family<RppgEngine, PulseMethod>(
  (ref, method) => SignalProcessingRppgEngine(
    method,
    windowSeconds: ref.watch(rppgConfigProvider).algorithmWindowSeconds,
  ),
);

final neuralEngineProvider =
    Provider<RppgEngine>((ref) => const UnavailableNeuralRppgEngine());

typedef WindowAnalysisRunner = Future<WindowAnalysis> Function(
  AnalysisRequest request,
);

/// Runs window analysis off the UI isolate on native platforms (`compute`
/// spawns a short-lived isolate; on web it runs inline).
final analysisRunnerProvider = Provider<WindowAnalysisRunner>(
  (ref) => (req) => compute(analyzeWindow, req),
);

final exportServiceProvider = Provider<ExportService>((ref) {
  final v = ref.watch(appVersionProvider);
  return ExportService(
    ExportBuilder(appName: AppBrand.name, appVersion: v.display),
  );
});

/// Hand-off of a completed session from the measurement screen to the
/// results screen. Cleared once saved or discarded.
final pendingResultProvider = StateProvider<MeasurementResult?>((ref) => null);

/// Face-locator id of the pending result (stored as processing metadata).
final pendingLocatorIdProvider = StateProvider<String>((ref) => 'unknown');

/// True when the persistent database could not be opened and an in-memory
/// fallback is in use (nothing will survive a restart).
final storageDegradedProvider = Provider<bool>((ref) => false);
