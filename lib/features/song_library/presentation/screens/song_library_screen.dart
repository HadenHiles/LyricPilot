import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/song_library_provider.dart';
import '../widgets/song_list_tile.dart';

/// The home screen — shows the user's song library.
///
/// Phase 0: displays in-memory sample songs.
/// Phase 2: will show songs from the Isar database with search/filter.
class SongLibraryScreen extends ConsumerWidget {
  const SongLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(songLibraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LyricPilot'),
        actions: [IconButton(icon: const Icon(Icons.settings_outlined), tooltip: 'Settings', onPressed: () => context.push('/settings'))],
      ),
      body: songs.isEmpty
          ? const _EmptyLibrary()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: songs.length,
              itemBuilder: (context, index) => SongListTile(song: songs[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO(phase-2): navigate to song create screen
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song creation coming in Phase 2'), behavior: SnackBarBehavior.floating));
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Song'),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_music_outlined, size: 72, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No songs yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Tap + to add your first song', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}
