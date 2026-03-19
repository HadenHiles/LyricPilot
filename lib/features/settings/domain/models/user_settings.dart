import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';

/// User-configurable display and behaviour preferences.
///
/// Phase 1: model stub only — not yet persisted. Values are defaults.
/// Phase 3: fontSize, lineSpacing, and keepScreenAwake become interactive.
/// Phase 4: autoScrollEnabled and scrollSpeedMultiplier become interactive.
/// Phase 5: audioFollowingEnabled and audioSensitivity become interactive.
@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    // --- Display (Phase 3) ---
    @Default(20.0) double fontSize,
    @Default(1.5) double lineSpacing,
    @Default(true) bool keepScreenAwake,

    // --- Scroll (Phase 4) ---
    // TODO(phase-4): wire up in scroll engine
    @Default(false) bool autoScrollEnabled,
    @Default(1.0) double scrollSpeedMultiplier,

    // --- Audio (Phase 5) ---
    // TODO(phase-5): wire up in audio analyzer
    @Default(false) bool audioFollowingEnabled,
    @Default(0.5) double audioSensitivity,
  }) = _UserSettings;
}
