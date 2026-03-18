import 'song_section.dart';

/// Root entity representing a song in the library.
///
/// All fields are immutable. Use [copyWith] to produce modified copies.
/// Phase 2 will add Isar persistence and JSON serialization.
class Song {
  final String id;
  final String title;
  final String artist;
  final String? key;
  final int? bpm;
  final String? notes;
  final List<SongSection> sections;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Song({required this.id, required this.title, required this.artist, this.key, this.bpm, this.notes, this.sections = const [], required this.createdAt, required this.updatedAt});

  int get totalLines => sections.fold(0, (sum, s) => sum + s.lineCount);

  int get sectionCount => sections.length;

  Song copyWith({String? id, String? title, String? artist, String? key, int? bpm, String? notes, List<SongSection>? sections, DateTime? createdAt, DateTime? updatedAt}) {
    return Song(id: id ?? this.id, title: title ?? this.title, artist: artist ?? this.artist, key: key ?? this.key, bpm: bpm ?? this.bpm, notes: notes ?? this.notes, sections: sections ?? this.sections, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song(id: $id, title: "$title", artist: "$artist", sections: $sectionCount)';
}
