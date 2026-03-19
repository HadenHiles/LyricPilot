import 'package:flutter/material.dart';

import '../../domain/models/song_line.dart';

/// How chord names are displayed relative to lyric text.
enum ChordDisplayMode {
  /// Chord names interleaved inline: `[G]Walking [D]down the road`.
  inline,

  /// Chord names rendered in a row above the lyric, horizontally aligned
  /// by character position using [TextPainter] measurement.
  stacked,
}

/// Renders a single [SongLine] with chord markers.
///
/// In [ChordDisplayMode.inline] (default), chords appear interleaved as
/// `[G]text`. In [ChordDisplayMode.stacked], chord names float above the
/// lyric in their correct horizontal position (printed chord-sheet style).
///
/// For instrumental lines (no lyric), shows chord names spaced on one row.
class ChordLyricLine extends StatelessWidget {
  final SongLine line;
  final TextStyle? lyricStyle;
  final TextStyle? chordStyle;
  final bool dimIfEmpty;
  final ChordDisplayMode displayMode;

  const ChordLyricLine({super.key, required this.line, this.lyricStyle, this.chordStyle, this.dimIfEmpty = true, this.displayMode = ChordDisplayMode.inline});

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
    if (line.isBlank) {
      return const SizedBox(height: 8);
    }

    // Lyric-only line (no chords either way)
    if (line.chords.isEmpty) {
      return Text(line.lyric, style: effectiveLyricStyle);
    }

    // Stacked layout: chord row sits above lyric row
    if (displayMode == ChordDisplayMode.stacked) {
      return _StackedLine(line: line, lyricStyle: effectiveLyricStyle, chordStyle: effectiveChordStyle);
    }

    // Inline: chord markers woven into the lyric RichText
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

/// Stacked chord + lyric layout using [TextPainter] for horizontal alignment.
class _StackedLine extends StatelessWidget {
  final SongLine line;
  final TextStyle lyricStyle;
  final TextStyle chordStyle;

  const _StackedLine({required this.line, required this.lyricStyle, required this.chordStyle});

  /// Returns the pixel width of [text] up to [position] using [style].
  double _measureOffset(String text, int position, TextStyle style, double maxWidth) {
    final tp = TextPainter(
      text: TextSpan(text: text.substring(0, position.clamp(0, text.length)), style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    final lyric = line.lyric;
    final sortedChords = [...line.chords]..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

    return LayoutBuilder(
      builder: (context, constraints) {
        final chordHeightPainter = TextPainter(
          text: TextSpan(text: 'A', style: chordStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final chordRowHeight = chordHeightPainter.height + 4;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: chordRowHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: sortedChords.map((chord) {
                  final pos = chord.position ?? 0;
                  final left = _measureOffset(lyric, pos, lyricStyle, constraints.maxWidth);
                  return Positioned(
                    left: left,
                    child: Text(chord.chord, style: chordStyle),
                  );
                }).toList(),
              ),
            ),
            Text(lyric, style: lyricStyle),
          ],
        );
      },
    );
  }
}
