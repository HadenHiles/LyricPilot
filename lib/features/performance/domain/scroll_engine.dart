import '../domain/playback_state.dart';
import '../domain/progress_state.dart';

/// Callback invoked whenever the engine determines that the playback position
/// should advance (or wrap) to a new line/section.
typedef PositionAdvancedCallback = void Function(ProgressState next);

/// Abstract interface for anything that drives playback position forward.
///
/// Implementations must be injectable and replaceable so the same app logic
/// works whether driven by:
///   - a BPM-derived timer ([TimedScrollEngine]), or
///   - audio confidence signals (Phase 5), or
///   - a combination of both.
///
/// The engine is **stateless with respect to the song structure** — it receives
/// [totalSections] and per-section line counts at [start] time and calls back
/// via [onAdvance] whenever a position change is warranted.
///
/// Manual overrides ([manualNextLine], [manualPrevLine], etc.) must always win
/// over any internal timer or heuristic — the engine must cancel its current
/// countdown and restart it from the newly forced position.
abstract class ScrollEngine {
  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Begin or resume advancing from [initial] position.
  ///
  /// [lineCounts] is an ordered list of line counts, one per section.
  /// [playbackState] carries the tempo multiplier and confidence score.
  void start({required ProgressState initial, required List<int> lineCounts, required PlaybackState playbackState, required PositionAdvancedCallback onAdvance});

  /// Pause the engine.  Position is held; the timer (if any) stops.
  void pause();

  /// Resume after a pause without resetting position.
  void resume();

  /// Stop and dispose all resources.  Must be called before discarding.
  void dispose();

  // ── Live updates ───────────────────────────────────────────────────────────

  /// Update the [PlaybackState] without restarting.
  /// Used to inject a new tempo multiplier or confidence score mid-session.
  void updatePlaybackState(PlaybackState next);

  // ── Manual overrides ───────────────────────────────────────────────────────

  /// The user pressed "next line".  Engine must honour this immediately,
  /// cancel its current countdown, and restart from the new position.
  void manualNextLine();

  /// The user pressed "previous line".
  void manualPrevLine();

  /// The user jumped to a new section.
  void manualJumpTo(ProgressState target);

  // ── Current state ──────────────────────────────────────────────────────────

  ProgressState get currentProgress;
}
