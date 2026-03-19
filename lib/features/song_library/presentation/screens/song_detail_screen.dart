import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/section_type.dart';
import '../../domain/models/song.dart';
import '../../domain/models/song_section.dart';
import '../providers/song_library_provider.dart';
import '../widgets/lyrics_first_line_view.dart';

/// Shows a song's full content — metadata, sections, and chord/lyric lines.
///
/// From here the user can launch performance mode or edit/delete the song.
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
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit song', onPressed: () => context.push('/song/$songId/edit')),
          PopupMenuButton<_SongAction>(
            onSelected: (action) => _handleAction(context, ref, song, action),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _SongAction.duplicate,
                child: ListTile(leading: Icon(Icons.copy_outlined), title: Text('Duplicate'), dense: true),
              ),
              PopupMenuItem(
                value: _SongAction.delete,
                child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'), dense: true),
              ),
            ],
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

  Future<void> _handleAction(BuildContext context, WidgetRef ref, Song song, _SongAction action) async {
    switch (action) {
      case _SongAction.duplicate:
        await ref.read(songLibraryNotifierProvider.notifier).duplicate(song.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${song.title}" duplicated'), behavior: SnackBarBehavior.floating));
        }
      case _SongAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete song?'),
            content: Text('This will permanently delete "${song.title}". This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(songLibraryNotifierProvider.notifier).delete(song.id);
          if (context.mounted) context.go('/');
        }
    }
  }
}

enum _SongAction { duplicate, delete }

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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      decoration: BoxDecoration(
        color: _sectionTint(section.type, colorScheme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtle section label
            Text(
              section.name.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55), letterSpacing: 1.4, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            // Lines
            ...section.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LyricsFirstLineView(line: line),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _sectionTint(SectionType type, ColorScheme cs) {
    switch (type) {
      case SectionType.chorus:
        return cs.primaryContainer.withValues(alpha: 0.28);
      case SectionType.verse:
        return cs.secondaryContainer.withValues(alpha: 0.28);
      case SectionType.bridge:
        return cs.tertiaryContainer.withValues(alpha: 0.28);
      case SectionType.preChorus:
        return cs.secondaryContainer.withValues(alpha: 0.16);
      case SectionType.intro:
      case SectionType.outro:
        return cs.primaryContainer.withValues(alpha: 0.16);
      case SectionType.solo:
        return cs.tertiaryContainer.withValues(alpha: 0.22);
      default:
        return cs.surfaceContainerHighest.withValues(alpha: 0.35);
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
