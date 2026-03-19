import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../song_library/presentation/providers/song_library_provider.dart';
import '../../domain/performance_state.dart';

part 'performance_provider.g.dart';

/// Manages the state of an active performance session for [songId].
///
/// Navigation methods respect the current [RepeatMode] before advancing.
/// All font/spacing mutations clamp to [PerformanceState] bounds.
@riverpod
class PerformanceNotifier extends _$PerformanceNotifier {
  @override
  PerformanceState build(String songId) {
    return const PerformanceState();
  }

  // ── Line navigation ────────────────────────────────────────────────────────

  /// Advance to the next line, respecting the current [RepeatMode].
  void nextLine() {
    final song = ref.read(songByIdProvider(songId));
    if (song == null || song.sections.isEmpty) return;
    final s = state;
    final sectionIdx = s.sectionIndex.clamp(0, song.sections.length - 1);
    final sectionLines = song.sections[sectionIdx].lines;

    // Repeat-line: stay put
    if (s.repeatMode == RepeatMode.line) return;

    final next = s.lineIndex + 1;

    // Repeat-section: wrap within section
    if (s.repeatMode == RepeatMode.section) {
      state = s.copyWith(lineIndex: next >= sectionLines.length ? 0 : next);
      return;
    }

    // No repeat — advance normally
    if (next < sectionLines.length) {
      state = s.copyWith(lineIndex: next);
    } else {
      final nextSection = sectionIdx + 1;
      if (nextSection < song.sections.length) {
        state = s.copyWith(sectionIndex: nextSection, lineIndex: 0);
      }
      // Already at the last line of the last section — hold position.
    }
  }

  /// Go back to the previous line (or the last line of the previous section).
  void prevLine() {
    final song = ref.read(songByIdProvider(songId));
    if (song == null || song.sections.isEmpty) return;
    final s = state;
    if (s.lineIndex > 0) {
      state = s.copyWith(lineIndex: s.lineIndex - 1);
    } else if (s.sectionIndex > 0) {
      final prevSection = song.sections[s.sectionIndex - 1];
      state = s.copyWith(sectionIndex: s.sectionIndex - 1, lineIndex: (prevSection.lines.length - 1).clamp(0, prevSection.lines.length - 1));
    }
    // Already at the start — hold position.
  }

  // ── Section navigation ─────────────────────────────────────────────────────

  /// Jump to the first line of the next section.
  void nextSection() {
    final song = ref.read(songByIdProvider(songId));
    if (song == null || song.sections.isEmpty) return;
    final next = state.sectionIndex + 1;
    if (next < song.sections.length) {
      state = state.copyWith(sectionIndex: next, lineIndex: 0);
    }
  }

  /// Jump to the first line of the previous section.
  /// If already on the first section, rewind to line 0.
  void prevSection() {
    final song = ref.read(songByIdProvider(songId));
    if (song == null || song.sections.isEmpty) return;
    final s = state;
    if (s.sectionIndex > 0) {
      state = s.copyWith(sectionIndex: s.sectionIndex - 1, lineIndex: 0);
    } else {
      state = s.copyWith(lineIndex: 0);
    }
  }

  // ── Repeat mode ────────────────────────────────────────────────────────────

  /// Cycle through [RepeatMode.none] → [RepeatMode.line] → [RepeatMode.section].
  void cycleRepeatMode() {
    final values = RepeatMode.values;
    state = state.copyWith(repeatMode: values[(state.repeatMode.index + 1) % values.length]);
  }

  // ── Display preferences ────────────────────────────────────────────────────

  /// Set font size directly (clamped to [PerformanceState.minFontSize..maxFontSize]).
  void setFontSize(double size) {
    state = state.copyWith(fontSize: size.clamp(PerformanceState.minFontSize, PerformanceState.maxFontSize));
  }

  /// Apply a relative font-size delta — delegates to [setFontSize].
  void adjustFontSize(double delta) => setFontSize(state.fontSize + delta);

  /// Set line spacing directly (clamped to bounds).
  void setLineSpacing(double spacing) {
    state = state.copyWith(lineSpacing: spacing.clamp(PerformanceState.minLineSpacing, PerformanceState.maxLineSpacing));
  }

  // ── Controls visibility ────────────────────────────────────────────────────

  void showControls() {
    if (!state.controlsVisible) state = state.copyWith(controlsVisible: true);
  }

  void hideControls() {
    if (state.controlsVisible) state = state.copyWith(controlsVisible: false);
  }
}
