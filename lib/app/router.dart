import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/performance/presentation/screens/performance_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/song_library/presentation/screens/song_detail_screen.dart';
import '../features/song_library/presentation/screens/song_editor_screen.dart';
import '../features/song_library/presentation/screens/song_library_screen.dart';

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SongLibraryScreen()),
      // /song/new must be declared before /song/:id to avoid "new" being treated as an id.
      GoRoute(path: '/song/new', builder: (context, state) => const SongEditorScreen()),
      GoRoute(
        path: '/song/:id',
        builder: (context, state) {
          final songId = state.pathParameters['id']!;
          return SongDetailScreen(songId: songId);
        },
        routes: [
          GoRoute(
            path: 'performance',
            builder: (context, state) {
              final songId = state.pathParameters['id']!;
              return PerformanceScreen(songId: songId);
            },
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final songId = state.pathParameters['id']!;
              return SongEditorScreen(songId: songId);
            },
          ),
        ],
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  ),
);
