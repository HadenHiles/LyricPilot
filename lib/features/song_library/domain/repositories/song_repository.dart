import '../models/song.dart';

/// Abstract contract for all song persistence operations.
///
/// Implementations live in `data/` (e.g. [JsonFileSongRepository]).
/// Providers in `presentation/` depend on this interface, not the concrete type.
abstract interface class SongRepository {
  /// Returns all songs ordered by title ascending.
  Future<List<Song>> getAll();

  /// Returns the song with [id], or null if not found.
  Future<Song?> getById(String id);

  /// Persists [song] — creates a new entry or replaces an existing one.
  Future<void> save(Song song);

  /// Permanently removes the song with [id]. No-op if not found.
  Future<void> delete(String id);
}
