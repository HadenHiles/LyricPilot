import 'package:flutter/material.dart';

import '../../domain/models/song_line.dart';

typedef _WordEntry = ({String word, int position});

List<_WordEntry> _splitWords(String lyric) {
  final result = <_WordEntry>[];
  for (final m in RegExp(r'\S+').allMatches(lyric)) {
    result.add((word: m.group(0)!, position: m.start));
  }
  return result;
}

/// Read-only word-chord slot display — mirrors the editor's visual style.
///
/// Words that have a chord assigned show the chord name in a coloured box
/// above the word. Words without chords render as plain text with no box,
/// matching real chord-sheet notation and keeping the view uncluttered.
class LyricsFirstLineView extends StatelessWidget {
  final SongLine line;

  const LyricsFirstLineView({super.key, required this.line});

  /// Maps word index → chord symbol by finding the closest word start position
  /// for each [ChordEvent] in the line.
  Map<int, String> _buildChordMap(List<_WordEntry> words) {
    final map = <int, String>{};
    for (final event in line.chords) {
      final pos = event.position ?? 0;
      if (words.isEmpty) continue;
      int closestIdx = 0;
      int minDist = (words[0].position - pos).abs();
      for (int i = 1; i < words.length; i++) {
        final d = (words[i].position - pos).abs();
        if (d < minDist) {
          minDist = d;
          closestIdx = i;
        }
      }
      map[closestIdx] = event.chord;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (line.isBlank) return const SizedBox(height: 8);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Instrumental — chords only, no lyric
    if (line.isInstrumental) {
      return Text(
        line.chords.map((c) => c.chord).join('   '),
        style: theme.textTheme.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      );
    }

    final words = _splitWords(line.lyric);
    if (words.isEmpty) return const SizedBox.shrink();

    final chordMap = _buildChordMap(words);

    return Wrap(
      spacing: 6,
      runSpacing: 10,
      children: words.asMap().entries.map((e) {
        final chord = chordMap[e.key];
        final hasChord = chord != null && chord.isNotEmpty;

        if (!hasChord) {
          // No chord on this word — render with a transparent placeholder box
          // so the baseline stays aligned with chorded words on the same run.
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invisible spacer matching the height of a chord box
              const SizedBox(height: 21),
              Text(e.value.word, style: theme.textTheme.bodyMedium),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 30),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: cs.primary.withValues(alpha: 0.5), width: 0.8),
              ),
              child: Text(
                chord,
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.primary, letterSpacing: 0.2, fontSize: 11),
              ),
            ),
            Text(e.value.word, style: theme.textTheme.bodyMedium),
          ],
        );
      }).toList(),
    );
  }
}
