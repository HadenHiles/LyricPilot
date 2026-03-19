import 'dart:async';

import '../domain/playback_state.dart';
import '../domain/progress_state.dart';
import '../domain/scroll_engine.dart';

/// Default number of beats to wait on each line when no BPM is available.
const int _kDefaultBeatsPerLine = 4;

/// BPM-based scroll engine.
///
/// Each line is assumed to occupy one musical measure ([beatsPerLine] beats).
/// The advance interval is:
///
///   interval = (beatsPerLine / bpm) × 60 seconds × (1 / tempoMultiplier)
///
/// When BPM is unknown the engine falls back to [_kDefaultBeatsPerLine] beats
/// at 80 BPM, giving a sensible ~3-second default.
///
/// Manual overrides always win — they cancel the running timer and restart it
/// from the corrected position, so the engine never fights the user.
class TimedScrollEngine implements ScrollEngine {
  TimedScrollEngine({int beatsPerLine = _kDefaultBeatsPerLine, double fallbackBpm = 80.0}) : _beatsPerLine = beatsPerLine, _fallbackBpm = fallbackBpm;

  final int _beatsPerLine;
  final double _fallbackBpm;

  Timer? _timer;
  ProgressState _progress = const ProgressState();
  List<int> _lineCounts = const [];
  PlaybackState _playback = const PlaybackState();
  PositionAdvancedCallback? _onAdvance;
  bool _running = false;

  // ── ScrollEngine interface ─────────────────────────────────────────────────

  @override
  void start({required ProgressState initial, required List<int> lineCounts, required PlaybackState playbackState, required PositionAdvancedCallback onAdvance}) {
    _progress = initial;
    _lineCounts = lineCounts;
    _playback = playbackState;
    _onAdvance = onAdvance;
    _running = true;
    _scheduleNext();
  }

  @override
  void pause() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void resume() {
    if (_running) return;
    _running = true;
    _scheduleNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _onAdvance = null;
    _running = false;
  }

  @override
  void updatePlaybackState(PlaybackState next) {
    _playback = next;
    if (_running) {
      // Reschedule with the updated interval so a multiplier change takes
      // effect immediately rather than waiting for the current tick to fire.
      _timer?.cancel();
      _scheduleNext();
    }
  }

  // ── Manual overrides ───────────────────────────────────────────────────────

  @override
  void manualNextLine() {
    _timer?.cancel();
    _progress = _advance(_progress);
    _onAdvance?.call(_progress);
    if (_running) _scheduleNext();
  }

  @override
  void manualPrevLine() {
    _timer?.cancel();
    final next = _retreat(_progress);
    // If already at the very beginning, don't emit a spurious callback.
    if (next != _progress) {
      _progress = next;
      _onAdvance?.call(_progress);
    }
    if (_running) _scheduleNext();
  }

  @override
  void manualJumpTo(ProgressState target) {
    _timer?.cancel();
    _progress = target;
    _onAdvance?.call(_progress);
    if (_running) _scheduleNext();
  }

  @override
  ProgressState get currentProgress => _progress;

  // ── Internal helpers ───────────────────────────────────────────────────────

  Duration get _interval {
    final bpm = (_playback.confidenceScore > 0.0 && _playback.confidenceScore < 1.0)
        ? null // uncertain — use fallback
        : null; // BPM is carried on Song, not here; caller sets via estimatedBpm
    final effectiveBpm = bpm ?? _progress.estimatedBpm ?? _fallbackBpm;
    final seconds = (_beatsPerLine / effectiveBpm) * 60.0 / _playback.tempoMultiplier;
    return Duration(milliseconds: (seconds * 1000).round().clamp(50, 60000));
  }

  void _scheduleNext() {
    if (!_running || _onAdvance == null) return;
    _timer = Timer(_interval, _tick);
  }

  void _tick() {
    if (!_running) return;
    _progress = _advance(_progress);
    _onAdvance?.call(_progress);
    _scheduleNext();
  }

  /// Move forward one line (wraps to next section; stops at end).
  ProgressState _advance(ProgressState p) {
    if (_lineCounts.isEmpty) return p;
    final sIdx = p.sectionIndex.clamp(0, _lineCounts.length - 1);
    final lineCount = _lineCounts[sIdx];
    final nextLine = p.lineIndex + 1;
    if (nextLine < lineCount) {
      return p.copyWith(lineIndex: nextLine);
    }
    final nextSection = sIdx + 1;
    if (nextSection < _lineCounts.length) {
      return p.copyWith(sectionIndex: nextSection, lineIndex: 0);
    }
    // At the very end — hold position.
    return p;
  }

  /// Move back one line (wraps to last line of previous section; stops at start).
  ProgressState _retreat(ProgressState p) {
    if (p.lineIndex > 0) {
      return p.copyWith(lineIndex: p.lineIndex - 1);
    }
    if (p.sectionIndex > 0) {
      final prevSectionIdx = p.sectionIndex - 1;
      final prevLineCount = _lineCounts.length > prevSectionIdx ? _lineCounts[prevSectionIdx] : 0;
      return p.copyWith(sectionIndex: prevSectionIdx, lineIndex: (prevLineCount - 1).clamp(0, prevLineCount));
    }
    return p;
  }
}
