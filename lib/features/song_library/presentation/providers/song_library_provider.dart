import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/json_file_song_repository.dart';
import '../../data/sample_songs.dart';
import '../../domain/models/song.dart';
import '../../domain/repositories/song_repository.dart';

part 'song_library_provider.g.dart';

/// Provides the concrete [SongRepository] implementation.
/// Override in tests to inject a fake.
final songRepositoryProvider = Provider<SongRepository>((_) => JsonFileSongRepository());

/// Current search query string typed by the user in the library screen.
final songSearchQueryProvider = StateProvider<String>((ref) => '');

/// The authoritative song library, backed by [SongRepository].
///
/// On first launch the repository is empty — it is seeded with [sampleSongs].
/// Exposes [save] and [delete] to mutate the library and invalidate itself.
@riverpod
class SongLibraryNotifier extends _$SongLibraryNotifier {
  SongRepository get _repo => ref.read(songRepositoryProvider);

  @override
  Future<List<Song>> build() async {
    final repo = _repo;
    if (await repo.isEmpty()) {
      for (final song in sampleSongs) {
        await repo.save(song);
      }
    }
    return repo.getAll();
  }

  Future<void> save(Song song) async {
    await _repo.save(song);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
  }

  Future<void> duplicate(String id) async {
    final original = await _repo.getById(id);
    if (original == null) return;
    final now = DateTime.now();
    final copy = original.copyWith(id: 'song_${now.millisecondsSinceEpoch}', title: '${original.title} (Copy)', createdAt: now, updatedAt: now);
    await _repo.save(copy);
    ref.invalidateSelf();
  }

  Future<void> togglePin(String id) async {
    final song = await _repo.getById(id);
    if (song == null) return;
    final pinned = song.pinnedAt == null ? DateTime.now() : null;
    await _repo.save(song.copyWith(pinnedAt: pinned, updatedAt: DateTime.now()));
    ref.invalidateSelf();
  }
}

/// Songs filtered by the current [songSearchQueryProvider] value.
@riverpod
List<Song> filteredSongs(FilteredSongsRef ref) {
  final songsAsync = ref.watch(songLibraryNotifierProvider);
  final songs = songsAsync.valueOrNull ?? [];
  final query = ref.watch(songSearchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) {
    // Pinned first, then by updatedAt desc.
    return songs..sort((a, b) {
      if ((a.pinnedAt != null) != (b.pinnedAt != null)) {
        return a.pinnedAt != null ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }
  return songs.where((s) => s.title.toLowerCase().contains(query) || s.artist.toLowerCase().contains(query)).toList()..sort((a, b) {
    if ((a.pinnedAt != null) != (b.pinnedAt != null)) {
      return a.pinnedAt != null ? -1 : 1;
    }
    return b.updatedAt.compareTo(a.updatedAt);
  });
}

/// Looks up a single song by its [id]. Returns null if not found.
@riverpod
Song? songById(SongByIdRef ref, String id) {
  final songsAsync = ref.watch(songLibraryNotifierProvider);
  final songs = songsAsync.valueOrNull ?? [];
  try {
    return songs.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}
