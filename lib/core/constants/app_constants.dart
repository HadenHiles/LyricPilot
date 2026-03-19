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

  // Song limits
  static const int maxSectionsPerSong = 50;
  static const int maxLinesPerSection = 100;

  // ── ChordMini API (Phase 3+) ──────────────────────────────────────────────
  //
  // See section 13 of copilot_instructions.md for full usage rules.
  //
  // The production URL is not publicly documented — contact the maintainer at
  // https://www.chordmini.me/docs for remote access.
  // For local dev, run the Python backend and set this to http://localhost:5001.
  //
  // NEVER hardcode this value in feature code. NEVER expose it in Settings.
  static const String chordMiniBaseUrl = 'http://localhost:5001';

  // Rate-limit compliance — minimum millseconds between calls to each endpoint.
  // These are enforced client-side in addition to the server-side limits.
  static const int chordMiniLyricsMinIntervalMs = 7000; // 10 req/min server limit
  static const int chordMiniAudioMinIntervalMs = 32000; // 2 req/min server limit

  // Anti-spam: warn the user after this many imports in a single session.
  static const int chordMiniImportSessionWarnThreshold = 10;
}
