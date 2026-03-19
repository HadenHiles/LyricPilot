/// Every possible status for a performance playback session.
///
/// Transitions:
///   idle → playing     (user presses play)
///   playing → paused   (user presses pause)
///   playing → repeating (repeat mode is active and line/section wraps)
///   playing → uncertain (confidence dropped below threshold — Phase 5)
///   playing → ended    (last line of last section reached)
///   paused  → playing  (user presses play / resumes)
///   repeating → playing (repeat mode turned off)
///   uncertain → playing (confidence recovered)
///   any → idle         (user exits or resets)
enum PlaybackStatus {
  /// Session not started or has been reset.
  idle,

  /// Auto-advancing through the song at the configured pace.
  playing,

  /// Manually paused; position held, timer stopped.
  paused,

  /// Repeat mode is active — wrapping within a line or section.
  /// Timer continues; position wraps instead of advancing.
  repeating,

  /// Confidence too low to auto-advance (Phase 5 audio signal).
  /// Timer paused; position held until confidence recovers.
  uncertain,

  /// Reached the last line of the last section.
  ended,
}

/// Immutable playback lifecycle state.
///
/// Designed so the audio layer (Phase 5) can push confidence updates
/// without restructuring: simply call [copyWith(confidenceScore: ...)].
class PlaybackState {
  const PlaybackState({this.status = PlaybackStatus.idle, this.confidenceScore = 1.0, this.tempoMultiplier = 1.0});

  /// Current lifecycle status.
  final PlaybackStatus status;

  /// Confidence that the engine's position matches the player's real position.
  /// Range 0.0–1.0.  1.0 = full confidence.
  /// Injected by the audio layer in Phase 5; defaults to 1.0 (fully confident).
  final double confidenceScore;

  /// Relative speed multiplier applied on top of the BPM-derived interval.
  /// 1.0 = normal; 0.5 = half-speed; 2.0 = double-speed.
  /// Clamped to [minMultiplier]..[maxMultiplier] on write.
  final double tempoMultiplier;

  static const double minMultiplier = 0.25;
  static const double maxMultiplier = 4.0;

  /// True when the engine should be advancing position (timer ticking).
  bool get isAdvancing => status == PlaybackStatus.playing || status == PlaybackStatus.repeating;

  /// True when position is held and no timer ticks should fire.
  bool get isHeld => status == PlaybackStatus.paused || status == PlaybackStatus.uncertain || status == PlaybackStatus.idle;

  PlaybackState copyWith({PlaybackStatus? status, double? confidenceScore, double? tempoMultiplier}) => PlaybackState(status: status ?? this.status, confidenceScore: (confidenceScore ?? this.confidenceScore).clamp(0.0, 1.0), tempoMultiplier: (tempoMultiplier ?? this.tempoMultiplier).clamp(minMultiplier, maxMultiplier));
}
