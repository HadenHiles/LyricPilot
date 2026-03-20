import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/song.dart';

/// A single row in the song library list.
class SongListTile extends StatelessWidget {
  final Song song;

  const SongListTile({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/song/${song.id}/performance'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _MetaChips(song: song),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  final Song song;

  const _MetaChips({required this.song});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (song.key != null) {
      chips.add(_Chip(label: 'Key: ${song.key}'));
    }
    if (song.bpm != null) {
      chips.add(_Chip(label: '${song.bpm} BPM'));
    }
    chips.add(_Chip(label: '${song.sectionCount} section${song.sectionCount == 1 ? '' : 's'}'));

    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
    );
  }
}
