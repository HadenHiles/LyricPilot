import '../domain/audio_activity_state.dart';
import '../domain/audio_analyzer.dart';

/// No-op [AudioAnalyzer] used until Phase 5.
///
/// [start] is a no-op — no microphone permission is ever requested.
/// All callers receive [AudioActivityState.unavailable] implicitly through
/// the absence of any callback invocation.
///
/// TODO(phase-5): replace with `MicAudioAnalyzer` (backed by the `record`
///               package) once mic permission handling and RMS detection are
///               implemented.
class NullAudioAnalyzer implements AudioAnalyzer {
  @override
  Future<void> start({required AudioActivityCallback onActivity}) async {
    // Intentional no-op — Phase 5 implements real mic capture here.
  }

  @override
  Future<void> stop() async {}

  @override
  bool get isRunning => false;

  @override
  double? get latestRmsDb => null;
}
