/// A single chord event attached to a position within a lyric line.
///
/// [chord] is the chord symbol, e.g. "G", "Am7", "F#m", "Cadd9".
/// [position] is the zero-based character index in [SongLine.lyric] where the
/// chord change occurs. Null means the chord plays over the whole line.
class ChordEvent {
  final String chord;
  final int? position;

  const ChordEvent({required this.chord, this.position});

  ChordEvent copyWith({String? chord, int? position}) {
    return ChordEvent(chord: chord ?? this.chord, position: position ?? this.position);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChordEvent && other.chord == chord && other.position == position;

  @override
  int get hashCode => Object.hash(chord, position);

  @override
  String toString() => 'ChordEvent(chord: $chord, position: $position)';
}
