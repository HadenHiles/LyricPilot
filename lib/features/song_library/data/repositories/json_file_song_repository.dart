import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/models/song.dart';
import '../../domain/repositories/song_repository.dart';

/// Persists songs as individual JSON files in the app documents directory.
///
/// Each song is stored at `<documents>/songs/<id>.json`.
/// This is adequate for the expected library size (~100 songs max).
class JsonFileSongRepository implements SongRepository {
  static const _subdir = 'songs';

  Future<Directory> _songsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_subdir');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  File _songFile(Directory dir, String id) => File('${dir.path}/$id.json');

  @override
  Future<List<Song>> getAll() async {
    final dir = await _songsDir();
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));

    final songs = <Song>[];
    for (final file in files) {
      try {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        songs.add(Song.fromJson(json));
      } catch (_) {
        // Corrupt file — skip silently; do not crash the library.
      }
    }

    songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return songs;
  }

  @override
  Future<Song?> getById(String id) async {
    final dir = await _songsDir();
    final file = _songFile(dir, id);
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return Song.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Song song) async {
    final dir = await _songsDir();
    final file = _songFile(dir, song.id);
    await file.writeAsString(jsonEncode(song.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    final dir = await _songsDir();
    final file = _songFile(dir, id);
    if (file.existsSync()) await file.delete();
  }
}
