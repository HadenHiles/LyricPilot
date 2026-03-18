import 'section_type.dart';
import 'song_line.dart';

/// A named structural section of a song — Verse, Chorus, Bridge, etc.
class SongSection {
  final String id;
  final String name;
  final SectionType type;
  final List<SongLine> lines;

  const SongSection({required this.id, required this.name, required this.type, this.lines = const []});

  int get lineCount => lines.length;

  SongSection copyWith({String? id, String? name, SectionType? type, List<SongLine>? lines}) {
    return SongSection(id: id ?? this.id, name: name ?? this.name, type: type ?? this.type, lines: lines ?? this.lines);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is SongSection && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SongSection(id: $id, name: $name, type: $type, lines: $lineCount)';
}
