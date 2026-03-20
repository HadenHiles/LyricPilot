import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/performance/presentation/screens/performance_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
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
      // Bare /song/:id redirects straight to performance — no preview screen.
      GoRoute(
        path: '/song/:id',
        redirect: (_, state) => '/song/${state.pathParameters['id']}/performance',
      ),
      GoRoute(
        path: '/song/:id/performance',
        builder: (context, state) => PerformanceScreen(songId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/song/:id/edit',
        builder: (context, state) => SongEditorScreen(songId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  ),
);
