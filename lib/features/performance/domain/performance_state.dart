import 'playback_state.dart';

/// Repeat behaviour for the performance session.
enum RepeatMode {
  /// Advance normally through lines and sections.
  none,

  /// Stay on the current line when "next" is pressed (until toggled off).
  line,

  /// Wrap within the current section instead of advancing to the next one.
  section,
}

/// Immutable state snapshot for an active performance session.
///
/// All navigation and display preference are captured here so the view
/// is a pure function of this value — no local widget state for position.
class PerformanceState {
  const PerformanceState({this.sectionIndex = 0, this.lineIndex = 0, this.chordIndex = 0, this.repeatMode = RepeatMode.none, this.fontSize = 28.0, this.lineSpacing = 1.6, this.controlsVisible = true, this.playback = const PlaybackState()});

  /// Index of the currently active section in [Song.sections].
  final int sectionIndex;

  /// Index of the currently active line within the current section.
  final int lineIndex;

  /// Index of the currently active chord within the current line (0 = first).
  final int chordIndex;

  /// Current repeat behaviour.
  final RepeatMode repeatMode;

  /// Base font size (sp) for the active lyric line.
  final double fontSize;

  /// Line height multiplier applied to all displayed lines.
  final double lineSpacing;

  /// Whether the navigation overlay (header + footer controls) is visible.
  final bool controlsVisible;

  /// Playback lifecycle and engine configuration.
  final PlaybackState playback;

  // ── Font / spacing bounds ──────────────────────────────────────────────────

  static const double minFontSize = 16.0;
  static const double maxFontSize = 56.0;
  static const double minLineSpacing = 1.2;
  static const double maxLineSpacing = 2.8;

  // ── Convenience getters ────────────────────────────────────────────────────

  PlaybackStatus get playbackStatus => playback.status;
  bool get isPlaying => playback.isAdvancing;

  // ── copyWith ───────────────────────────────────────────────────────────────

  PerformanceState copyWith({int? sectionIndex, int? lineIndex, int? chordIndex, RepeatMode? repeatMode, double? fontSize, double? lineSpacing, bool? controlsVisible, PlaybackState? playback}) => PerformanceState(
    sectionIndex: sectionIndex ?? this.sectionIndex,
    lineIndex: lineIndex ?? this.lineIndex,
    chordIndex: chordIndex ?? this.chordIndex,
    repeatMode: repeatMode ?? this.repeatMode,
    fontSize: fontSize ?? this.fontSize,
    lineSpacing: lineSpacing ?? this.lineSpacing,
    controlsVisible: controlsVisible ?? this.controlsVisible,
    playback: playback ?? this.playback,
  );
}
