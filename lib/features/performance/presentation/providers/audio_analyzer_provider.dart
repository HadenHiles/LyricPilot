import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/null_audio_analyzer.dart';
import '../../domain/audio_analyzer.dart';

/// Provides the active [AudioAnalyzer] for the current performance session.
///
/// Returns [NullAudioAnalyzer] until Phase 5.
///
/// To wire real audio:
///   1. Add `record` + `permission_handler` to pubspec.yaml (with comments).
///   2. Implement `MicAudioAnalyzer` in `data/mic_audio_analyzer.dart`.
///   3. Swap the return value here to `MicAudioAnalyzer()`.
///   4. In `PerformanceNotifier.play()`, call
///      `ref.read(audioAnalyzerProvider).start(onActivity: _onAudioActivity)`
///      and in `_onAudioActivity` map [AudioActivityState] → confidence score
///      → `updateConfidence(score)`.
///   5. In `PerformanceNotifier.stop()/pause()`, call
///      `ref.read(audioAnalyzerProvider).stop()`.
///
/// TODO(phase-5): replace NullAudioAnalyzer with MicAudioAnalyzer.
final audioAnalyzerProvider = Provider<AudioAnalyzer>((ref) => NullAudioAnalyzer());
