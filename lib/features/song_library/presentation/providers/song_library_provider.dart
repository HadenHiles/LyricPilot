import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/sample_songs.dart';
import '../../domain/models/song.dart';

part 'song_library_provider.g.dart';

/// Current search query string typed by the user in the library screen.
/// Plain StateProvider — no codegen needed for simple string state.
final songSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provides the full song library.
///
/// Phase 0: returns the hard-coded in-memory [sampleSongs] list.
/// Phase 2: will be replaced with an AsyncNotifier backed by Isar.
@riverpod
List<Song> songLibrary(SongLibraryRef ref) => sampleSongs;

/// Songs filtered by the current [songSearchQueryProvider] value.
@riverpod
List<Song> filteredSongs(FilteredSongsRef ref) {
  final songs = ref.watch(songLibraryProvider);
  final query = ref.watch(songSearchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return songs;
  return songs.where((s) => s.title.toLowerCase().contains(query) || s.artist.toLowerCase().contains(query)).toList();
}

/// Looks up a single song by its [id]. Returns null if not found.
@riverpod
Song? songById(SongByIdRef ref, String id) {
  final songs = ref.watch(songLibraryProvider);
  try {
    return songs.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}
