import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/section_type.dart';
import '../../domain/models/song.dart';
import '../../domain/models/song_section.dart';
import '../providers/song_library_provider.dart';
import '../widgets/chord_lyric_line.dart';

/// Shows a song's full content — metadata, sections, and chord/lyric lines.
///
/// From here the user can launch performance mode.
class SongDetailScreen extends ConsumerWidget {
  final String songId;

  const SongDetailScreen({super.key, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(songByIdProvider(songId));

    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Song not found')),
        body: const Center(child: Text('This song no longer exists.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        actions: [
          // TODO(phase-2): edit action
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit song',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song editing coming in Phase 2'), behavior: SnackBarBehavior.floating));
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _SongHeader(song: song)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _SectionCard(section: song.sections[index], sectionNumber: index + 1),
              childCount: song.sections.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: _PerformanceBar(song: song),
    );
  }
}

class _SongHeader extends StatelessWidget {
  final Song song;

  const _SongHeader({required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song.artist,
            style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (song.key != null) _InfoChip(icon: Icons.music_note_outlined, label: 'Key of ${song.key}'),
              if (song.bpm != null) _InfoChip(icon: Icons.speed_outlined, label: '${song.bpm} BPM'),
              _InfoChip(icon: Icons.format_list_bulleted_outlined, label: '${song.sectionCount} section${song.sectionCount == 1 ? '' : 's'}'),
            ],
          ),
          if (song.notes != null && song.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
              child: Text(
                song.notes!,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final SongSection section;
  final int sectionNumber;

  const _SectionCard({required this.section, required this.sectionNumber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _sectionColor(section.type, colorScheme), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    section.name,
                    style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Lines
          ...section.lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ChordLyricLine(line: line),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Color _sectionColor(SectionType type, ColorScheme colorScheme) {
    switch (type) {
      case SectionType.chorus:
        return colorScheme.primary;
      case SectionType.verse:
        return colorScheme.secondary;
      case SectionType.bridge:
        return colorScheme.tertiary;
      case SectionType.preChorus:
        return colorScheme.secondaryContainer;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }
}

class _PerformanceBar extends StatelessWidget {
  final Song song;

  const _PerformanceBar({required this.song});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.push('/song/${song.id}/performance'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Performance'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
