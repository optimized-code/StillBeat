/// Phases of a measurement session. Transitions are restricted by
/// [MeasurementStateMachine].
enum MeasurementPhase {
  idle,
  requestingPermission,
  initializing,
  positioning,
  warmingUp,
  measuring,
  validating,
  completed,

  // Terminal or recoverable failure phases.
  cancelled,
  interrupted,
  permissionDenied,
  unsupported,
  lowSignalQuality,
  timedOut,
  cameraFailure,
  inferenceFailure;

  bool get isActive => switch (this) {
        requestingPermission ||
        initializing ||
        positioning ||
        warmingUp ||
        measuring ||
        validating =>
          true,
        _ => false,
      };

  /// Phases in which the camera should be streaming.
  bool get needsCamera => switch (this) {
        positioning || warmingUp || measuring => true,
        _ => false,
      };

  bool get isTerminal => !isActive && this != idle;
}

class InvalidTransitionError extends StateError {
  InvalidTransitionError(this.from, this.to)
      : super('Invalid measurement transition ${from.name} -> ${to.name}');
  final MeasurementPhase from;
  final MeasurementPhase to;
}

/// Explicit transition table for measurement sessions.
class MeasurementStateMachine {
  MeasurementStateMachine([this._phase = MeasurementPhase.idle]);

  MeasurementPhase _phase;
  MeasurementPhase get phase => _phase;

  static const _failures = {
    MeasurementPhase.cancelled,
    MeasurementPhase.interrupted,
    MeasurementPhase.cameraFailure,
  };

  static final Map<MeasurementPhase, Set<MeasurementPhase>> _allowed = {
    MeasurementPhase.idle: {
      MeasurementPhase.requestingPermission,
      MeasurementPhase.unsupported,
    },
    MeasurementPhase.requestingPermission: {
      MeasurementPhase.initializing,
      MeasurementPhase.permissionDenied,
      MeasurementPhase.cancelled,
      MeasurementPhase.interrupted,
      MeasurementPhase.unsupported,
      MeasurementPhase.cameraFailure,
    },
    MeasurementPhase.initializing: {
      MeasurementPhase.positioning,
      MeasurementPhase.unsupported,
      MeasurementPhase.inferenceFailure,
      MeasurementPhase.permissionDenied,
      ..._failures,
    },
    MeasurementPhase.positioning: {
      MeasurementPhase.warmingUp,
      MeasurementPhase.timedOut,
      ..._failures,
    },
    MeasurementPhase.warmingUp: {
      MeasurementPhase.measuring,
      MeasurementPhase.positioning,
      MeasurementPhase.timedOut,
      ..._failures,
    },
    MeasurementPhase.measuring: {
      MeasurementPhase.validating,
      MeasurementPhase.positioning,
      MeasurementPhase.timedOut,
      MeasurementPhase.inferenceFailure,
      ..._failures,
    },
    MeasurementPhase.validating: {
      MeasurementPhase.completed,
      MeasurementPhase.lowSignalQuality,
      MeasurementPhase.inferenceFailure,
      MeasurementPhase.cancelled,
      MeasurementPhase.interrupted,
    },
  };

  /// Every terminal phase may only restart via [reset] (→ idle) or retry
  /// (→ requestingPermission).
  static const _restartable = {
    MeasurementPhase.requestingPermission,
    MeasurementPhase.idle,
  };

  bool canTransition(MeasurementPhase to) {
    if (_phase.isTerminal) return _restartable.contains(to);
    return _allowed[_phase]?.contains(to) ?? false;
  }

  /// Applies a transition or throws [InvalidTransitionError].
  void transition(MeasurementPhase to) {
    if (!canTransition(to)) throw InvalidTransitionError(_phase, to);
    _phase = to;
  }

  void reset() => _phase = MeasurementPhase.idle;
}
