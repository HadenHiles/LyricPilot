import 'package:freezed_annotation/freezed_annotation.dart';

import 'song_section.dart';

part 'song.freezed.dart';

/// Root entity representing a song in the library.
///
/// All fields are immutable. Use [copyWith] to produce modified copies.
/// Phase 2 will add Isar persistence and JSON serialization.
@freezed
class Song with _$Song {
  const Song._();

  const factory Song({required String id, required String title, required String artist, String? key, int? bpm, String? notes, @Default([]) List<SongSection> sections, required DateTime createdAt, required DateTime updatedAt}) = _Song;

  int get totalLines => sections.fold(0, (sum, s) => sum + s.lineCount);

  int get sectionCount => sections.length;
}
