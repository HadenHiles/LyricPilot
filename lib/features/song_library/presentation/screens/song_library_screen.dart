import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_logo.dart';
import '../providers/song_library_provider.dart';
import '../widgets/song_list_tile.dart';

/// The home screen — shows the user's song library with live search.
class SongLibraryScreen extends ConsumerWidget {
  const SongLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songLibraryNotifierProvider);
    final songs = ref.watch(filteredSongsProvider);
    final query = ref.watch(songSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: AppLogo.wide(height: 28),
        actions: [IconButton(icon: const Icon(Icons.settings_outlined), tooltip: 'Settings', onPressed: () => context.push('/settings'))],
      ),
      body: Column(
        children: [
          _SearchBar(query: query, onChanged: (value) => ref.read(songSearchQueryProvider.notifier).state = value),
          Expanded(
            child: songsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading songs: $e')),
              data: (_) => songs.isEmpty
                  ? _EmptyLibrary(isSearchActive: query.trim().isNotEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 96),
                      itemCount: songs.length,
                      itemBuilder: (context, index) => SongListTile(song: songs[index]),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/song/new'), icon: const Icon(Icons.add), label: const Text('Add Song')),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.query, required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(_SearchBar old) {
    super.didUpdateWidget(old);
    // Sync controller when the provider is cleared externally.
    if (widget.query.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Search songs or artists\u2026',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final bool isSearchActive;

  const _EmptyLibrary({required this.isSearchActive});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSearchActive ? Icons.search_off : Icons.library_music_outlined, size: 72, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(isSearchActive ? 'No matching songs' : 'No songs yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(isSearchActive ? 'Try a different search term' : 'Tap + to add your first song', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}
