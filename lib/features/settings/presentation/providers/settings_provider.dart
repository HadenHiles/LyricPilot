import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/user_settings.dart';

/// Holds the current user settings in memory.
///
/// Phase 1: in-memory only, resets on app restart.
/// Phase 3: will be persisted via SharedPreferences or Isar.
final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) => UserSettingsNotifier());

class UserSettingsNotifier extends StateNotifier<UserSettings> {
  UserSettingsNotifier() : super(const UserSettings());

  // TODO(phase-3): add updateFontSize, updateLineSpacing, etc.
  // TODO(phase-4): add toggleAutoScroll, updateScrollSpeed.
  // TODO(phase-5): add toggleAudioFollowing, updateAudioSensitivity.

  void reset() => state = const UserSettings();
}
