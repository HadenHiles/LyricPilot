import 'package:flutter/material.dart';

import '../../domain/models/song_line.dart';

/// Renders a single [SongLine] with chord markers inline.
///
/// Chords use the [ChordEvent.position] to interleave chord names (displayed
/// in the primary color) into the lyric text. This is the standard format
/// used on guitar chord sites: `[G]Walking [D]down the road`.
///
/// For instrumental lines (no lyric, only chords), shows the chord names
/// spaced out on one line.
///
/// Phase 3 will introduce a more refined stacked layout (chord line above
/// lyric line) for the performance mode view. This widget remains the
/// standard detail/library view representation.
class ChordLyricLine extends StatelessWidget {
  final SongLine line;
  final TextStyle? lyricStyle;
  final TextStyle? chordStyle;
  final bool dimIfEmpty;

  const ChordLyricLine({super.key, required this.line, this.lyricStyle, this.chordStyle, this.dimIfEmpty = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveLyricStyle = lyricStyle ?? theme.textTheme.bodyLarge!;
    final effectiveChordStyle = chordStyle ?? theme.textTheme.bodyMedium!.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 0.3);

    // Instrumental line — just show chord names spaced out
    if (line.isInstrumental) {
      final chordNames = line.chords.map((c) => c.chord).join('   ');
      return Text(chordNames, style: effectiveChordStyle);
    }

    // Blank spacer line
    if (line.isEmpty) {
      return const SizedBox(height: 8);
    }

    // Lyric-only line
    if (line.chords.isEmpty) {
      return Text(line.lyric, style: effectiveLyricStyle);
    }

    // Lyric with inline chord markers
    return RichText(text: TextSpan(children: _buildSpans(line, effectiveLyricStyle, effectiveChordStyle)));
  }

  List<TextSpan> _buildSpans(SongLine line, TextStyle lyricStyle, TextStyle chordStyle) {
    final spans = <TextSpan>[];
    final lyric = line.lyric;

    final sortedChords = [...line.chords]..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

    int cursor = 0;

    for (final chord in sortedChords) {
      final pos = (chord.position ?? cursor).clamp(cursor, lyric.length);

      if (pos > cursor) {
        spans.add(TextSpan(text: lyric.substring(cursor, pos), style: lyricStyle));
      }

      spans.add(TextSpan(text: '[${chord.chord}]', style: chordStyle));

      cursor = pos;
    }

    if (cursor < lyric.length) {
      spans.add(TextSpan(text: lyric.substring(cursor), style: lyricStyle));
    }

    return spans;
  }
}
