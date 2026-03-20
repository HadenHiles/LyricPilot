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

  /// When non-negative, the chord at this index in the line's sorted chord
  /// list is highlighted with a translucent pill to show it is currently active.
  final int activeChordIndex;

  const ChordLyricLine({super.key, required this.line, this.lyricStyle, this.chordStyle, this.dimIfEmpty = true, this.displayMode = ChordDisplayMode.inline, this.activeChordIndex = -1});

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
      return _StackedLine(line: line, lyricStyle: effectiveLyricStyle, chordStyle: effectiveChordStyle, activeChordIndex: activeChordIndex);
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
// Splits [lyric] into (word, charStartPosition) entries.
List<({String word, int position})> _splitLyricWords(String lyric) {
  final result = <({String word, int position})>[];
  for (final m in RegExp(r'\S+').allMatches(lyric)) {
    result.add((word: m.group(0)!, position: m.start));
  }
  return result;
}

/// Stacked chord + lyric layout using a [Wrap] of per-word chord-slot columns.
///
/// Each word is wrapped with an optional chord name above it in a fixed-size
/// slot.  Words without chords render an invisible placeholder slot of the
/// same size, guaranteeing that every word sits on the same baseline regardless
/// of whether it carries a chord.
///
/// This approach is font-size and wrap-safe: unlike the previous TextPainter
/// offset method, chords remain directly above their word even when the lyric
/// exceeds one visible line at large font sizes.
class _StackedLine extends StatelessWidget {
  final SongLine line;
  final TextStyle lyricStyle;
  final TextStyle chordStyle;
  final int activeChordIndex;

  const _StackedLine({required this.line, required this.lyricStyle, required this.chordStyle, this.activeChordIndex = -1});

  @override
  Widget build(BuildContext context) {
    final words = _splitLyricWords(line.lyric);
    if (words.isEmpty) return Text(line.lyric, style: lyricStyle);

    final sortedChords = [...line.chords]..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

    // Map each chord (by sorted index) to the nearest word index.
    // When two chords land on the same word, the later one overrides.
    final chordAtWord = <int, ({String symbol, int chordIdx})>{};
    for (int ci = 0; ci < sortedChords.length; ci++) {
      final pos = sortedChords[ci].position ?? 0;
      int closest = 0;
      int minDist = (words[0].position - pos).abs();
      for (int wi = 1; wi < words.length; wi++) {
        final d = (words[wi].position - pos).abs();
        if (d < minDist) {
          minDist = d;
          closest = wi;
        }
      }
      chordAtWord[closest] = (symbol: sortedChords[ci].chord, chordIdx: ci);
    }

    // Font-proportional word gap — approximates a natural space character width.
    final wordSpacing = (lyricStyle.fontSize ?? 20.0) * 0.28;

    return Wrap(
      spacing: wordSpacing,
      runSpacing: 8,
      children: words.asMap().entries.map((e) {
        final wi = e.key;
        final word = e.value.word;
        final entry = chordAtWord[wi];
        final hasChord = entry != null;
        final isActive = hasChord && entry.chordIdx == activeChordIndex;

        // SizedBox(width:0, height:chordLineH) ensures the slot contributes
        // zero width (Column width = word width only) while bounding the height
        // so OverflowBox never receives maxHeight:infinity from the Column
        // layout pass.  Without the height, OverflowBox sizes itself to the
        // infinite incoming maxHeight, which cascades into an infinite inner-
        // Column → infinite Wrap → crash.
        final chordLineH = (chordStyle.fontSize ?? 14.0) * 2.5 + 8;
        final chordSlot = SizedBox(
          width: 0,
          height: chordLineH,
          child: OverflowBox(
            maxWidth: 300,
            maxHeight: chordLineH,
            alignment: Alignment.topLeft,
            child: Opacity(
              opacity: hasChord ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                margin: const EdgeInsets.only(bottom: 2),
                decoration: isActive ? BoxDecoration(color: (chordStyle.color ?? Colors.white).withValues(alpha: 0.22), borderRadius: BorderRadius.circular(5)) : null,
                child: Text(hasChord ? entry.symbol : 'A', style: chordStyle),
              ),
            ),
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            chordSlot,
            Text(word, style: lyricStyle),
          ],
        );
      }).toList(),
    );
  }
}
