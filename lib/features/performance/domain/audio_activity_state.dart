/// Represents the audio activity level detected from the device microphone.
///
/// The performance provider receives these events via [AudioAnalyzer.start]
/// and translates them into confidence-score updates via
/// [PerformanceNotifier.updateConfidence].
///
/// TODO(phase-5): implement RMS + onset detection to produce real values.
enum AudioActivityState {
  /// Microphone data unavailable — permission denied or analyzer disabled.
  /// The app should behave exactly as if no audio assistance were present.
  unavailable,

  /// Signal is below the silence threshold — player has likely stopped or paused.
  /// Confidence drops; the scroll engine holds position.
  silent,

  /// Signal is ambiguous — not clearly silent or active.
  /// Confidence stays neutral; hold current position.
  uncertain,

  /// Energy burst or onset detected — player is actively playing or singing.
  /// Confidence rises; the scroll engine advances (or resumes advancing).
  active,
}
