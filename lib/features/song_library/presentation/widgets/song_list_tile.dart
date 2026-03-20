import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/song.dart';
import '../providers/song_library_provider.dart';

// ─────────────────────────────────────────────────────────
// Swipeable song row
// ─────────────────────────────────────────────────────────

/// A single row in the song library list.
///
/// Swipe **right** to pin / unpin. Swipe **left** to delete (confirmation
/// required). Both actions use a smooth Gmail-like slide-to-reveal background.
class SongListTile extends ConsumerWidget {
  final Song song;

  const SongListTile({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(songLibraryNotifierProvider.notifier);
    final isPinned = song.pinnedAt != null;

    return Dismissible(
      key: ValueKey(song.id),
      direction: DismissDirection.horizontal,
      // Right-swipe background: pin action
      background: _SwipeBackground(
        color: isPinned
            ? const Color(0xFF7B61FF).withValues(alpha: 0.85) // unpin = purple
            : const Color(0xFF00897B).withValues(alpha: 0.85), // pin = teal
        icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
        label: isPinned ? 'Unpin' : 'Pin',
        alignment: Alignment.centerLeft,
      ),
      // Left-swipe background: delete action
      secondaryBackground: _SwipeBackground(color: const Color(0xFFE53935).withValues(alpha: 0.85), icon: Icons.delete_outline_rounded, label: 'Delete', alignment: Alignment.centerRight),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Pin / unpin — no confirmation needed, spring back after.
          await notifier.togglePin(song.id);
          return false;
        } else {
          // Delete — require confirmation.
          return _confirmDelete(context, song.title);
        }
      },
      onDismissed: (direction) {
        // Only fires for confirmed left-swipe delete.
        if (direction == DismissDirection.endToStart) {
          notifier.delete(song.id);
        }
      },
      child: _SongCard(song: song, isPinned: isPinned),
    );
  }

  /// Shows a confirmation dialog for delete. Returns true if confirmed.
  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete song?'),
        content: Text('"$title" will be permanently removed from your library.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ─────────────────────────────────────────────────────────
// Swipe reveal background
// ─────────────────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final AlignmentGeometry alignment;

  const _SwipeBackground({required this.color, required this.icon, required this.label, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Card content
// ─────────────────────────────────────────────────────────

class _SongCard extends StatelessWidget {
  final Song song;
  final bool isPinned;

  const _SongCard({required this.song, required this.isPinned});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/song/${song.id}/performance'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isPinned) ...[Icon(Icons.push_pin_rounded, size: 13, color: cs.primary.withValues(alpha: 0.7)), const SizedBox(width: 4)],
                        Expanded(
                          child: Text(
                            song.title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _MetaChips(song: song),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Meta-data chips
// ─────────────────────────────────────────────────────────

class _MetaChips extends StatelessWidget {
  final Song song;

  const _MetaChips({required this.song});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (song.key != null) {
      chips.add(_Chip(label: 'Key: ${song.key}'));
    }
    if (song.bpm != null) {
      chips.add(_Chip(label: '${song.bpm} BPM'));
    }
    chips.add(_Chip(label: '${song.sectionCount} section${song.sectionCount == 1 ? '' : 's'}'));

    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
    );
  }
}
