import 'dart:typed_data';

import '../../core/errors/app_error.dart';
import 'algorithms/chrom.dart';
import 'algorithms/pos.dart';
import 'window_analyzer.dart';

/// Kind of algorithm, surfaced in the UI so a signal-processing baseline is
/// never presented as a trained neural network.
enum AlgorithmKind { unsupervisedSignalProcessing, neuralNetwork }

/// Descriptive, user-facing metadata for an rPPG algorithm.
class AlgorithmInfo {
  const AlgorithmInfo({
    required this.id,
    required this.version,
    required this.displayName,
    required this.kind,
    required this.citation,
    required this.implementationNote,
    this.modelVersion,
  });

  final String id;
  final String version;
  final String displayName;
  final AlgorithmKind kind;
  final String citation;
  final String implementationNote;
  final String? modelVersion;

  static const pos = AlgorithmInfo(
    id: 'pos',
    version: '1.0.0',
    displayName: 'POS (Plane-Orthogonal-to-Skin)',
    kind: AlgorithmKind.unsupervisedSignalProcessing,
    citation: 'Wang, den Brinker, Stuijk, de Haan. Algorithmic Principles of '
        'Remote PPG. IEEE TBME 64(7), 2017. doi:10.1109/TBME.2016.2609282',
    implementationNote: 'Original Dart implementation of the published '
        'algorithm. No pretrained weights.',
  );

  static const chrom = AlgorithmInfo(
    id: 'chrom',
    version: '1.0.0',
    displayName: 'CHROM (chrominance-based)',
    kind: AlgorithmKind.unsupervisedSignalProcessing,
    citation: 'de Haan, Jeanne. Robust Pulse Rate From Chrominance-Based '
        'rPPG. IEEE TBME 60(10), 2013. doi:10.1109/TBME.2013.2266196',
    implementationNote: 'Original Dart implementation of the published '
        'algorithm. No pretrained weights.',
  );

  static const neuralPlaceholder = AlgorithmInfo(
    id: 'neural',
    version: '0.0.0',
    displayName: 'Neural model (not installed)',
    kind: AlgorithmKind.neuralNetwork,
    citation: 'Candidate: EfficientPhys / TS-CAN (rPPG-Toolbox). '
        'See docs/model_evaluation.md.',
    implementationNote: 'No model weights are bundled: licensing of the '
        'available checkpoints has not been cleared for redistribution.',
  );

  static AlgorithmInfo forMethod(PulseMethod m) => switch (m) {
        PulseMethod.pos => pos,
        PulseMethod.chrom => chrom,
      };

  static AlgorithmInfo? byId(String id) => switch (id) {
        'pos' => pos,
        'chrom' => chrom,
        'neural' => neuralPlaceholder,
        _ => null,
      };
}

class RppgCapabilities {
  const RppgCapabilities({
    required this.available,
    required this.runsOnDevice,
    required this.supportsRespiratoryRate,
    this.unavailableReason,
  });

  final bool available;
  final bool runsOnDevice;
  final bool supportsRespiratoryRate;
  final String? unavailableReason;
}

/// Uniformly resampled colour traces for one window.
class RppgInput {
  const RppgInput({
    required this.red,
    required this.green,
    required this.blue,
    required this.sampleRateHz,
  });

  final Float64List red;
  final Float64List green;
  final Float64List blue;
  final double sampleRateHz;
}

class RppgOutput {
  const RppgOutput({required this.pulse, required this.sampleRateHz});

  /// Unfiltered pulse signal aligned with the input samples.
  final Float64List pulse;
  final double sampleRateHz;
}

/// Replaceable rPPG pulse-extraction engine.
abstract interface class RppgEngine {
  AlgorithmInfo get info;
  Future<void> initialize();
  Future<RppgCapabilities> getCapabilities();
  Future<RppgOutput> process(RppgInput input);
  Future<void> reset();
  Future<void> dispose();

  /// The method used by the isolate-based window analyzer, or null when the
  /// engine cannot be expressed as a pure function (e.g. a neural runtime).
  PulseMethod? get analyzerMethod;
}

/// POS/CHROM engine. Stateless, so concurrent calls are safe.
class SignalProcessingRppgEngine implements RppgEngine {
  SignalProcessingRppgEngine(this.method, {this.windowSeconds = 1.6});

  final PulseMethod method;
  final double windowSeconds;

  @override
  AlgorithmInfo get info => AlgorithmInfo.forMethod(method);

  @override
  PulseMethod get analyzerMethod => method;

  @override
  Future<void> initialize() async {}

  @override
  Future<RppgCapabilities> getCapabilities() async => const RppgCapabilities(
        available: true,
        runsOnDevice: true,
        supportsRespiratoryRate: false,
      );

  @override
  Future<RppgOutput> process(RppgInput input) async {
    final pulse = switch (method) {
      PulseMethod.pos => posPulse(
          red: input.red,
          green: input.green,
          blue: input.blue,
          sampleRateHz: input.sampleRateHz,
          windowSeconds: windowSeconds,
        ),
      PulseMethod.chrom => chromPulse(
          red: input.red,
          green: input.green,
          blue: input.blue,
          sampleRateHz: input.sampleRateHz,
          bandLowHz: 0.6,
          bandHighHz: 4.0,
          windowSeconds: windowSeconds,
        ),
    };
    return RppgOutput(pulse: pulse, sampleRateHz: input.sampleRateHz);
  }

  @override
  Future<void> reset() async {}

  @override
  Future<void> dispose() async {}
}

/// Slot for a future neural model. It reports itself unavailable and never
/// produces output; it must not be replaced by a fallback that pretends to
/// be neural.
class UnavailableNeuralRppgEngine implements RppgEngine {
  const UnavailableNeuralRppgEngine();

  static const reason = 'No licensed neural rPPG model is bundled with this '
      'build. See docs/model_integration.md.';

  @override
  AlgorithmInfo get info => AlgorithmInfo.neuralPlaceholder;

  @override
  PulseMethod? get analyzerMethod => null;

  @override
  Future<void> initialize() async => throw const ModelUnavailableError(reason);

  @override
  Future<RppgCapabilities> getCapabilities() async => const RppgCapabilities(
        available: false,
        runsOnDevice: false,
        supportsRespiratoryRate: false,
        unavailableReason: reason,
      );

  @override
  Future<RppgOutput> process(RppgInput input) async =>
      throw const ModelUnavailableError(reason);

  @override
  Future<void> reset() async {}

  @override
  Future<void> dispose() async {}
}
