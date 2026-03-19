import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_pilot/features/performance/data/timed_scroll_engine.dart';
import 'package:lyric_pilot/features/performance/domain/playback_state.dart';
import 'package:lyric_pilot/features/performance/domain/progress_state.dart';

void main() {
  group('TimedScrollEngine', () {
    // ── _advance helper behaviour (via manualNextLine) ─────────────────────

    test('manualNextLine advances within the same section', () {
      final e = TimedScrollEngine();
      final advances = <ProgressState>[];

      e.start(
        initial: const ProgressState(sectionIndex: 0, lineIndex: 0),
        lineCounts: [4, 3], // 2 sections
        playbackState: const PlaybackState(status: PlaybackStatus.playing),
        onAdvance: advances.add,
      );
      e.pause(); // stop the timer so only manual calls fire

      e.manualNextLine();
      expect(advances.last.sectionIndex, 0);
      expect(advances.last.lineIndex, 1);

      e.dispose();
    });

    test('manualNextLine wraps to next section when at last line', () {
      final e = TimedScrollEngine();
      final advances = <ProgressState>[];

      e.start(
        initial: const ProgressState(sectionIndex: 0, lineIndex: 3), // last of 4
        lineCounts: [4, 3],
        playbackState: const PlaybackState(status: PlaybackStatus.playing),
        onAdvance: advances.add,
      );
      e.pause();

      e.manualNextLine();
      expect(advances.last.sectionIndex, 1);
      expect(advances.last.lineIndex, 0);

      e.dispose();
    });

    test('manualNextLine holds at end of last section', () {
      final e = TimedScrollEngine();
      final advances = <ProgressState>[];

      e.start(
        initial: const ProgressState(sectionIndex: 1, lineIndex: 2), // last line, last section
        lineCounts: [4, 3],
        playbackState: const PlaybackState(status: PlaybackStatus.playing),
        onAdvance: advances.add,
      );
      e.pause();

      e.manualNextLine();
      // Position must not change.
      expect(advances.last.sectionIndex, 1);
      expect(advances.last.lineIndex, 2);

      e.dispose();
    });

    // ── _retreat helper behaviour (via manualPrevLine) ─────────────────────

    test('manualPrevLine goes back within same section', () {
      final e = TimedScrollEngine();
      final advances = <ProgressState>[];

      e.start(
        initial: const ProgressState(sectionIndex: 0, lineIndex: 2),
        lineCounts: [4, 3],
        playbackState: const PlaybackState(status: PlaybackStatus.playing),
        onAdvance: advances.add,
      );
      e.pause();

      e.manualPrevLine();
      expect(advances.last.sectionIndex, 0);
      expect(advances.last.lineIndex, 1);

      e.dispose();
    });

    test('manualPrevLine wraps to last line of previous section', () {
      final e = TimedScrollEngine();
      final advances = <ProgressState>[];

      e.start(
        initial: const ProgressState(sectionIndex: 1, lineIndex: 0),
        lineCounts: [4, 3],
        playbackState: const PlaybackState(status: PlaybackStatus.playing),
        onAdvance: advances.add,
      );
      e.pause();

      e.manualPrevLine();
      expect(advances.last.sectionIndex, 0);
      expect(advances.last.lineIndex, 3); // last of 4-line section

      e.dispose();
    });

    test('manualPrevLine holds at very beginning', () {
      final e = TimedScrollEngine();
      final advances = <ProgressState>[];

      e.start(
        initial: const ProgressState(sectionIndex: 0, lineIndex: 0),
        lineCounts: [4, 3],
        playbackState: const PlaybackState(status: PlaybackStatus.playing),
        onAdvance: advances.add,
      );
      e.pause();

      e.manualPrevLine();
      expect(advances, isEmpty); // nothing should be emitted

      e.dispose();
    });

    // ── manualJumpTo ───────────────────────────────────────────────────────

    test('manualJumpTo lands on exact target', () {
      final e = TimedScrollEngine();
      final advances = <ProgressState>[];

      e.start(
        initial: const ProgressState(sectionIndex: 0, lineIndex: 0),
        lineCounts: [4, 3, 5],
        playbackState: const PlaybackState(status: PlaybackStatus.playing),
        onAdvance: advances.add,
      );
      e.pause();

      e.manualJumpTo(const ProgressState(sectionIndex: 2, lineIndex: 4));
      expect(advances.last.sectionIndex, 2);
      expect(advances.last.lineIndex, 4);
      expect(e.currentProgress.sectionIndex, 2);
      expect(e.currentProgress.lineIndex, 4);

      e.dispose();
    });

    // ── Timed advance ──────────────────────────────────────────────────────

    test('engine fires onAdvance callback after interval', () async {
      // Use a very fast BPM so the timer fires quickly in tests.
      final e = TimedScrollEngine(beatsPerLine: 1, fallbackBpm: 600.0);
      // At 600 BPM with 1 beat/line → 0.1 s interval / 1.0 multiplier = 100 ms.
      final advances = <ProgressState>[];

      e.start(
        initial: const ProgressState(sectionIndex: 0, lineIndex: 0),
        lineCounts: [4, 3],
        playbackState: const PlaybackState(status: PlaybackStatus.playing),
        onAdvance: advances.add,
      );

      await Future<void>.delayed(const Duration(milliseconds: 250));
      e.dispose();

      expect(advances.length, greaterThanOrEqualTo(2));
    });

    test('pause stops timer; no more advances fire', () async {
      final e = TimedScrollEngine(beatsPerLine: 1, fallbackBpm: 600.0);
      final advances = <ProgressState>[];

      e.start(
        initial: const ProgressState(sectionIndex: 0, lineIndex: 0),
        lineCounts: [4, 3],
        playbackState: const PlaybackState(status: PlaybackStatus.playing),
        onAdvance: advances.add,
      );

      await Future<void>.delayed(const Duration(milliseconds: 150));
      e.pause();
      final countAfterPause = advances.length;

      await Future<void>.delayed(const Duration(milliseconds: 200));
      e.dispose();

      // No new advances after pause.
      expect(advances.length, countAfterPause);
    });

    // ── updatePlaybackState ────────────────────────────────────────────────

    test('tempoMultiplier = 2.0 doubles advance rate', () async {
      final e = TimedScrollEngine(beatsPerLine: 1, fallbackBpm: 600.0);
      final advances = <ProgressState>[];

      e.start(
        initial: const ProgressState(sectionIndex: 0, lineIndex: 0),
        lineCounts: [10],
        playbackState: PlaybackState(status: PlaybackStatus.playing, tempoMultiplier: 2.0),
        onAdvance: advances.add,
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      e.dispose();

      // At 2× speed, interval ≈ 50 ms → expect ≥ 3 advances in 200 ms.
      expect(advances.length, greaterThanOrEqualTo(3));
    });
  });

  // ── PlaybackState model ────────────────────────────────────────────────────

  group('PlaybackState', () {
    test('isAdvancing is true for playing and repeating', () {
      expect(const PlaybackState(status: PlaybackStatus.playing).isAdvancing, isTrue);
      expect(const PlaybackState(status: PlaybackStatus.repeating).isAdvancing, isTrue);
    });

    test('isHeld is true for paused, uncertain, idle', () {
      expect(const PlaybackState(status: PlaybackStatus.paused).isHeld, isTrue);
      expect(const PlaybackState(status: PlaybackStatus.uncertain).isHeld, isTrue);
      expect(const PlaybackState(status: PlaybackStatus.idle).isHeld, isTrue);
    });

    test('confidenceScore clamps to 0..1', () {
      final s = const PlaybackState().copyWith(confidenceScore: 1.5);
      expect(s.confidenceScore, 1.0);
      final s2 = const PlaybackState().copyWith(confidenceScore: -0.1);
      expect(s2.confidenceScore, 0.0);
    });

    test('tempoMultiplier clamps to bounds', () {
      final s = const PlaybackState().copyWith(tempoMultiplier: 99.0);
      expect(s.tempoMultiplier, PlaybackState.maxMultiplier);
      final s2 = const PlaybackState().copyWith(tempoMultiplier: 0.0);
      expect(s2.tempoMultiplier, PlaybackState.minMultiplier);
    });
  });
}
