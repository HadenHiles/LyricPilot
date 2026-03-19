import 'audio_activity_state.dart';

/// Called by [AudioAnalyzer] when a new audio observation is available.
///
/// [state]  — the interpreted activity level.
/// [rmsDb]  — raw RMS level in dBFS (negative values; 0 = full scale).
///            Useful for a debug overlay (Phase 5).
typedef AudioActivityCallback = void Function(AudioActivityState state, double rmsDb);

/// Abstract interface for microphone-based activity detection.
///
/// Implementations are injected via Riverpod so they can be swapped or mocked
/// in tests without touching any performance-mode code.
///
/// Integration surface:
///   • [PerformanceNotifier.updateConfidence] \u2014 audio layer calls this on each
///     observation; it maps the confidence score to [PlaybackState.confidenceScore]
///     and passes it to the active [ScrollEngine].
///
/// Build order (see roadmap Phase 5):
///   Layer 1 \u2014 silence vs. activity detection (RMS energy threshold).
///   Layer 2 \u2014 onset / strum detection (rapid energy burst).
///   Layer 3 \u2014 confidence-based adaptive scrolling (Phase 5\u20136).
///
/// TODO(phase-5): replace [NullAudioAnalyzer] with [MicAudioAnalyzer]
///               backed by the `record` package.
abstract class AudioAnalyzer {
  /// Start capturing microphone audio and emit [AudioActivityState] events via
  /// [onActivity]. Implementations must request mic permission if not yet
  /// granted; permission denial should emit [AudioActivityState.unavailable]
  /// and return without crashing.
  Future<void> start({required AudioActivityCallback onActivity});

  /// Stop the microphone stream and release all associated resources.
  Future<void> stop();

  /// Whether the analyzer is currently capturing audio.
  bool get isRunning;

  /// Most-recent RMS level in dBFS, or `null` if not running.
  double? get latestRmsDb;
}
