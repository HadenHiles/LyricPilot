import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls whether the app uses dark, light, or system theme.
/// Defaults to dark — dark mode is the primary design target for musicians.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
