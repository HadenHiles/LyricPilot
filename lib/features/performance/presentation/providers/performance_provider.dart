import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../song_library/domain/models/song.dart';
import '../../../song_library/presentation/providers/song_library_provider.dart';
import '../../data/timed_scroll_engine.dart';
import '../../domain/performance_state.dart';
import '../../domain/playback_state.dart';
import '../../domain/progress_state.dart';
import '../../domain/scroll_engine.dart';

part 'performance_provider.g.dart';

/// Manages the state of an active performance session for [songId].
///
/// In Phase 4 the [TimedScrollEngine] drives BPM-based auto-scroll.
/// Manual navigation calls always override the engine immediately.
/// Phase 5 will inject audio confidence via [updateConfidence].
@riverpod
class PerformanceNotifier extends _$PerformanceNotifier {
  ScrollEngine? _engine;

  @override
  PerformanceState build(String songId) {
    // Dispose engine when the provider is rebuilt or destroyed.
    ref.onDispose(() {
      _engine?.dispose();
      _engine = null;
    });
    return const PerformanceState();
  }

  // ── Engine helpers ─────────────────────────────────────────────────────────

  Song? get _song => ref.read(songByIdProvider(songId));

  List<int> _lineCounts(Song song) => song.sections.map((s) => s.lines.length).toList();

  ProgressState _progressFromState(PerformanceState s) => ProgressState(sectionIndex: s.sectionIndex, lineIndex: s.lineIndex);

  void _startEngine(Song song) {
    _engine?.dispose();
    _engine = TimedScrollEngine();
    _engine!.start(initial: _progressFromState(state), lineCounts: _lineCounts(song), playbackState: state.playback, onAdvance: _onEngineAdvance);
  }

  void _onEngineAdvance(ProgressState next) {
    final s = state;
    // In repeat-line mode, ignore the timer's advance — the engine ticks but
    // position is frozen; this mirrors manual behaviour.
    if (s.repeatMode == RepeatMode.line) return;

    // In repeat-section mode, wrap within the section.
    if (s.repeatMode == RepeatMode.section) {
      final song = _song;
      if (song == null) return;
      final sIdx = s.sectionIndex.clamp(0, song.sections.length - 1);
      final lineCount = song.sections[sIdx].lines.length;
      final wrappedLine = next.lineIndex >= lineCount ? 0 : next.lineIndex;
      state = s.copyWith(sectionIndex: sIdx, lineIndex: wrappedLine, chordIndex: next.chordIndex);
      return;
    }

    // Detect end of song.
    final song = _song;
    if (song != null &&
        next.sectionIndex >= song.sections.length - 1 &&
        next.lineIndex >=
            (song.sections.last.lines.length - 1)
                .clamp(0, song.sections.last.lines.length)) {
      state = s.copyWith(
        sectionIndex: next.sectionIndex,
        lineIndex: next.lineIndex,
        chordIndex: next.chordIndex,
        playback: s.playback.copyWith(status: PlaybackStatus.ended),
      );
      _engine?.pause();
      return;
    }

    state = s.copyWith(sectionIndex: next.sectionIndex, lineIndex: next.lineIndex, chordIndex: next.chordIndex);
  }

  // ── Playback control ───────────────────────────────────────────────────────

  /// Start auto-scroll from the current position.
  void play() {
    final song = _song;
    if (song == null || song.sections.isEmpty) return;
    final s = state;

    if (s.playback.status == PlaybackStatus.paused) {
      _engine?.resume();
      state = s.copyWith(playback: s.playback.copyWith(status: PlaybackStatus.playing));
    } else {
      // Fresh start or re-start after ended.
      final newPlayback = s.playback.copyWith(status: PlaybackStatus.playing);
      state = s.copyWith(playback: newPlayback);
      _startEngine(song);
    }
  }

  /// Pause auto-scroll; position is preserved.
  void pause() {
    _engine?.pause();
    state = state.copyWith(playback: state.playback.copyWith(status: PlaybackStatus.paused));
  }

  /// Toggle between playing and paused.
  void togglePlayPause() {
    if (state.playback.isAdvancing) {
      pause();
    } else {
      play();
    }
  }

  /// Stop and reset to the beginning of the song.
  void stop() {
    _engine?.dispose();
    _engine = null;
    state = state.copyWith(sectionIndex: 0, lineIndex: 0, chordIndex: 0, playback: state.playback.copyWith(status: PlaybackStatus.idle));
  }

  /// Increase auto-scroll speed by one step.
  void fasterScroll() {
    final next = state.playback.copyWith(tempoMultiplier: (state.playback.tempoMultiplier + 0.25).clamp(PlaybackState.minMultiplier, PlaybackState.maxMultiplier));
    state = state.copyWith(playback: next);
    _engine?.updatePlaybackState(next);
  }

  /// Decrease auto-scroll speed by one step.
  void slowerScroll() {
    final next = state.playback.copyWith(tempoMultiplier: (state.playback.tempoMultiplier - 0.25).clamp(PlaybackState.minMultiplier, PlaybackState.maxMultiplier));
    state = state.copyWith(playback: next);
    _engine?.updatePlaybackState(next);
  }

  /// Phase 5 entry point — audio layer calls this to inject a new confidence
  /// score without touching anything else.
  void updateConfidence(double score) {
    final next = state.playback.copyWith(confidenceScore: score);
    state = state.copyWith(playback: next);
    _engine?.updatePlaybackState(next);
  }

  // ── Line navigation ────────────────────────────────────────────────────────

  /// Advance to the next line (manual override — always wins over engine).
  void nextLine() {
    final song = _song;
    if (song == null || song.sections.isEmpty) return;
    final s = state;
    final sectionIdx = s.sectionIndex.clamp(0, song.sections.length - 1);
    final sectionLines = song.sections[sectionIdx].lines;

    if (s.repeatMode == RepeatMode.line) return;

    final next = s.lineIndex + 1;

    if (s.repeatMode == RepeatMode.section) {
      final newLine = next >= sectionLines.length ? 0 : next;
      state = s.copyWith(lineIndex: newLine, chordIndex: 0);
      _engine?.manualJumpTo(ProgressState(sectionIndex: sectionIdx, lineIndex: newLine));
      return;
    }

    if (next < sectionLines.length) {
      state = s.copyWith(lineIndex: next, chordIndex: 0);
      _engine?.manualJumpTo(ProgressState(sectionIndex: sectionIdx, lineIndex: next));
    } else {
      final nextSection = sectionIdx + 1;
      if (nextSection < song.sections.length) {
        state = s.copyWith(sectionIndex: nextSection, lineIndex: 0, chordIndex: 0);
        _engine?.manualJumpTo(ProgressState(sectionIndex: nextSection, lineIndex: 0));
      }
    }
  }

  /// Go back to the previous line (manual override).
  void prevLine() {
    final song = _song;
    if (song == null || song.sections.isEmpty) return;
    final s = state;
    final ProgressState target;
    if (s.lineIndex > 0) {
      target = ProgressState(sectionIndex: s.sectionIndex, lineIndex: s.lineIndex - 1);
    } else if (s.sectionIndex > 0) {
      final prevSection = song.sections[s.sectionIndex - 1];
      target = ProgressState(sectionIndex: s.sectionIndex - 1, lineIndex: (prevSection.lines.length - 1).clamp(0, prevSection.lines.length));
    } else {
      return;
    }
    state = s.copyWith(sectionIndex: target.sectionIndex, lineIndex: target.lineIndex, chordIndex: 0);
    _engine?.manualJumpTo(target);
  }

  // ── Section navigation ─────────────────────────────────────────────────────

  void nextSection() {
    final song = _song;
    if (song == null || song.sections.isEmpty) return;
    final next = state.sectionIndex + 1;
    if (next < song.sections.length) {
      state = state.copyWith(sectionIndex: next, lineIndex: 0, chordIndex: 0);
      _engine?.manualJumpTo(ProgressState(sectionIndex: next, lineIndex: 0));
    }
  }

  void prevSection() {
    final song = _song;
    if (song == null || song.sections.isEmpty) return;
    final s = state;
    final target = s.sectionIndex > 0 ? ProgressState(sectionIndex: s.sectionIndex - 1, lineIndex: 0) : ProgressState(sectionIndex: 0, lineIndex: 0);
    state = s.copyWith(sectionIndex: target.sectionIndex, lineIndex: target.lineIndex, chordIndex: 0);
    _engine?.manualJumpTo(target);
  }

  // ── Repeat mode ────────────────────────────────────────────────────────────

  void cycleRepeatMode() {
    final values = RepeatMode.values;
    state = state.copyWith(repeatMode: values[(state.repeatMode.index + 1) % values.length]);
  }

  // ── Display preferences ────────────────────────────────────────────────────

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size.clamp(PerformanceState.minFontSize, PerformanceState.maxFontSize));
  }

  void adjustFontSize(double delta) => setFontSize(state.fontSize + delta);

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
