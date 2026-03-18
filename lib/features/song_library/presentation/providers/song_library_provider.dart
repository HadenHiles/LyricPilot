import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sample_songs.dart';
import '../../domain/models/song.dart';

/// Provides the full song library.
///
/// Phase 0: returns the hard-coded in-memory [sampleSongs] list.
/// Phase 2: will be replaced with an AsyncNotifier backed by Isar.
final songLibraryProvider = Provider<List<Song>>((ref) => sampleSongs);

/// Looks up a single song by its [id]. Returns null if not found.
final songByIdProvider = Provider.family<Song?, String>((ref, id) {
  final songs = ref.watch(songLibraryProvider);
  try {
    return songs.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});
