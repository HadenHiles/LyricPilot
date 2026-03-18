import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../song_library/domain/models/song.dart';
import '../../../song_library/presentation/providers/song_library_provider.dart';

/// Full-screen performance view — Phase 3 stub.
///
/// Phase 0: shows a placeholder with the song title and a back button.
/// Phase 3: replaces this with the real large-text performance display,
///          manual navigation controls, repeat tools, and scroll engine hook.
/// Phase 5: adds microphone-assisted following.
///
/// TODO(phase-3): Implement full performance mode display.
class PerformanceScreen extends ConsumerWidget {
  final String songId;

  const PerformanceScreen({super.key, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(songByIdProvider(songId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _PerformancePlaceholder(song: song)),
    );
  }
}

class _PerformancePlaceholder extends StatelessWidget {
  final Song? song;

  const _PerformancePlaceholder({this.song});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Minimal top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Exit performance',
              ),
              if (song != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    song!.title,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Placeholder body
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.piano_outlined, size: 80, color: colorScheme.primary.withValues(alpha: 0.6)),
                  const SizedBox(height: 24),
                  Text(
                    'Performance Mode',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text('Coming in Phase 3', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      'Phase 3 will add: large readable text, '
                      'manual line/section navigation, repeat tools, '
                      'screen-awake mode, and adjustable font size.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
