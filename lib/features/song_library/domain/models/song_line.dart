import 'chord_event.dart';

/// One line in the song — a lyric string paired with zero or more chord events.
///
/// An empty [lyric] with chords is an instrumental line (chord chart only).
/// Both empty means a blank spacer line between sections.
class SongLine {
  final String id;
  final String lyric;
  final List<ChordEvent> chords;

  const SongLine({required this.id, required this.lyric, this.chords = const []});

  /// True when this line has chords but no sung lyric (e.g., an intro riff).
  bool get isInstrumental => lyric.isEmpty && chords.isNotEmpty;

  /// True when this line is a structural spacer with no content.
  bool get isEmpty => lyric.isEmpty && chords.isEmpty;

  SongLine copyWith({String? id, String? lyric, List<ChordEvent>? chords}) {
    return SongLine(id: id ?? this.id, lyric: lyric ?? this.lyric, chords: chords ?? this.chords);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is SongLine && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SongLine(id: $id, lyric: "$lyric", chords: ${chords.length})';
}
