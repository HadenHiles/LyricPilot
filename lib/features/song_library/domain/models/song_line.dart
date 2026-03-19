import 'package:freezed_annotation/freezed_annotation.dart';

import 'chord_event.dart';

part 'song_line.freezed.dart';

/// One line in the song — a lyric string paired with zero or more chord events.
///
/// An empty [lyric] with chords is an instrumental line (chord chart only).
/// Both empty means a blank spacer line between sections.
@freezed
class SongLine with _$SongLine {
  const SongLine._();

  const factory SongLine({required String id, required String lyric, @Default([]) List<ChordEvent> chords}) = _SongLine;

  /// True when this line has chords but no sung lyric (e.g. an intro riff).
  bool get isInstrumental => lyric.isEmpty && chords.isNotEmpty;

  /// True when this line is a blank spacer with no content.
  bool get isBlank => lyric.isEmpty && chords.isEmpty;
}
