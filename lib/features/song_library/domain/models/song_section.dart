import 'package:freezed_annotation/freezed_annotation.dart';

import 'section_type.dart';
import 'song_line.dart';

part 'song_section.freezed.dart';
part 'song_section.g.dart';

/// A named structural section of a song — Verse, Chorus, Bridge, etc.
@freezed
class SongSection with _$SongSection {
  const SongSection._();

  const factory SongSection({required String id, required String name, required SectionType type, @Default([]) List<SongLine> lines}) = _SongSection;

  factory SongSection.fromJson(Map<String, dynamic> json) => _$SongSectionFromJson(json);

  int get lineCount => lines.length;
}
