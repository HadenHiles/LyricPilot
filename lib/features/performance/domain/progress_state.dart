/// The current playback position within a song.
///
/// Tracks which section and line are active, plus the running estimated tempo.
/// Chord-level tracking is a Phase 4+ refinement; [chordIndex] defaults to 0.
///
/// This model is the shared vocabulary between [ScrollEngine], the notifier,
/// and (in Phase 5) the audio layer.
class ProgressState {
  const ProgressState({this.sectionIndex = 0, this.lineIndex = 0, this.chordIndex = 0, this.estimatedBpm});

  /// Zero-based index of the current section in [Song.sections].
  final int sectionIndex;

  /// Zero-based index of the current line in the current section.
  final int lineIndex;

  /// Zero-based index of the current chord event on the active line.
  /// Defaults to 0; Phase 4+ may track this more granularly.
  final int chordIndex;

  /// Estimated beats-per-minute derived from the engine's tick rate.
  /// Null until the engine has produced at least one advance cycle.
  final double? estimatedBpm;

  ProgressState copyWith({int? sectionIndex, int? lineIndex, int? chordIndex, double? estimatedBpm}) => ProgressState(sectionIndex: sectionIndex ?? this.sectionIndex, lineIndex: lineIndex ?? this.lineIndex, chordIndex: chordIndex ?? this.chordIndex, estimatedBpm: estimatedBpm ?? this.estimatedBpm);

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProgressState && other.sectionIndex == sectionIndex && other.lineIndex == lineIndex && other.chordIndex == chordIndex && other.estimatedBpm == estimatedBpm;

  @override
  int get hashCode => Object.hash(sectionIndex, lineIndex, chordIndex, estimatedBpm);
}
