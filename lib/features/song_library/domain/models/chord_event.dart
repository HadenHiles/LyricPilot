import 'package:freezed_annotation/freezed_annotation.dart';

part 'chord_event.freezed.dart';

/// A single chord event attached to a position within a lyric line.
///
/// [chord] is the chord symbol, e.g. "G", "Am7", "F#m", "Cadd9".
/// [position] is the zero-based character index in [SongLine.lyric] where the
/// chord change occurs. Null means the chord is anchored to the start of the line.
@freezed
class ChordEvent with _$ChordEvent {
  const factory ChordEvent({required String chord, int? position}) = _ChordEvent;
}
