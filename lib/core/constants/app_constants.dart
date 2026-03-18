/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'LyricPilot';
  static const String appVersion = '0.1.0';

  // Navigation paths
  static const String pathLibrary = '/';
  static const String pathSettings = '/settings';

  // Display
  static const double defaultFontSize = 18.0;
  static const double performanceFontSize = 28.0;
  static const double minFontSize = 14.0;
  static const double maxFontSize = 48.0;

  // Song limits (Phase 0 — in-memory only)
  static const int maxSectionsPerSong = 50;
  static const int maxLinesPerSection = 100;
}
