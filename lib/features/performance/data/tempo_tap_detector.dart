/// Utility for detecting tempo (BPM) from user tap timestamps.
///
/// Collects 4-8 taps, removes outliers, averages intervals, and returns BPM.
class TempoTapDetector {
  final List<DateTime> _taps = [];

  static const int minTaps = 4;
  static const int maxTaps = 8;
  static const Duration tapTimeout = Duration(seconds: 3);

  /// Record a tap at the current time.
  /// Auto-resets if more than [tapTimeout] has passed since last tap.
  void tap() {
    final now = DateTime.now();

    // Reset if last tap was too long ago (user started over)
    if (_taps.isNotEmpty && now.difference(_taps.last) > tapTimeout) {
      _taps.clear();
    }

    _taps.add(now);

    // Keep only the most recent maxTaps
    if (_taps.length > maxTaps) {
      _taps.removeAt(0);
    }
  }

  /// Reset all collected taps.
  void reset() {
    _taps.clear();
  }

  /// Number of taps collected.
  int get tapCount => _taps.length;

  /// Whether we have enough taps to calculate BPM.
  bool get canCalculate => _taps.length >= minTaps;

  /// Calculate BPM from collected taps, or null if not enough data.
  /// Returns null if intervals are too inconsistent (outliers detected).
  double? calculateBpm() {
    if (!canCalculate) return null;

    // Calculate intervals between consecutive taps (in milliseconds)
    final intervals = <int>[];
    for (var i = 1; i < _taps.length; i++) {
      intervals.add(_taps[i].difference(_taps[i - 1]).inMilliseconds);
    }

    if (intervals.isEmpty) return null;

    // Remove outliers (intervals more than 30% away from median)
    intervals.sort();
    final median = intervals[intervals.length ~/ 2];
    final filtered = intervals.where((i) => (i - median).abs() / median < 0.3).toList();

    if (filtered.isEmpty) return null;

    // Average the remaining intervals
    final avgInterval = filtered.reduce((a, b) => a + b) / filtered.length;

    // Convert to BPM (60,000 ms per minute / interval in ms)
    final bpm = 60000 / avgInterval;

    // Clamp to reasonable range
    return bpm.clamp(40.0, 200.0);
  }
}
