import 'dart:async';

// Hide Flutter's own RepeatMode (added in 3.x) to avoid ambiguity with ours.
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../song_library/domain/models/song.dart';
import '../../../song_library/domain/models/song_line.dart';
import '../../../song_library/domain/models/song_section.dart';
import '../../../song_library/presentation/providers/song_library_provider.dart';
import '../../../song_library/presentation/widgets/chord_lyric_line.dart';
import '../../domain/performance_state.dart';
import '../../domain/playback_state.dart';
import '../providers/performance_provider.dart';

/// Full-screen performance view — Phase 3 + 4.
///
/// Phase 3: manual navigation, repeat modes, auto-hide overlay, wakelock.
/// Phase 4: BPM-based auto-scroll via [TimedScrollEngine]; play/pause/stop
///          controls; adjustable tempo multiplier.
/// TODO(phase-5): Add microphone-assisted position following.
class PerformanceScreen extends ConsumerStatefulWidget {
  final String songId;

  const PerformanceScreen({super.key, required this.songId});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  Timer? _hideTimer;
  // True until the player first interacts — shows the welcome overlay and
  // keeps controls visible for 10 s on entry instead of 4 s.
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Restart the auto-hide countdown: 10 s on first entry, 4 s thereafter.
  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: _showWelcome ? 10 : 4), () {
      if (mounted) {
        ref.read(performanceNotifierProvider(widget.songId).notifier).hideControls();
      }
    });
  }

  /// Dismiss the welcome overlay and switch to the shorter 4-second timer.
  void _onFirstInteraction() {
    if (_showWelcome) setState(() => _showWelcome = false);
  }

  /// Tap on the content area: toggle controls visibility.
  void _onContentTap() {
    _onFirstInteraction();
    final notifier = ref.read(performanceNotifierProvider(widget.songId).notifier);
    final visible = ref.read(performanceNotifierProvider(widget.songId)).controlsVisible;
    if (visible) {
      notifier.hideControls();
      _hideTimer?.cancel();
    } else {
      notifier.showControls();
      _scheduleHide();
    }
  }

  /// Called by any control button interaction — surfaces controls + resets timer.
  void _onControlInteraction() {
    _onFirstInteraction();
    ref.read(performanceNotifierProvider(widget.songId).notifier).showControls();
    _scheduleHide();
  }

  void _openSettings() {
    _onControlInteraction();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1B1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SettingsSheet(songId: widget.songId, onInteraction: _onControlInteraction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(songByIdProvider(widget.songId));
    final perfState = ref.watch(performanceNotifierProvider(widget.songId));
    final notifier = ref.read(performanceNotifierProvider(widget.songId).notifier);

    if (song == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Song not found.', style: TextStyle(color: Colors.white54, fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Content area — tap toggles controls ───────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onContentTap,
            child: _ContentLayer(song: song, state: perfState),
          ),

          // ── Controls overlay — pointer-transparent when hidden ─────────────
          IgnorePointer(
            ignoring: !perfState.controlsVisible,
            child: AnimatedOpacity(
              opacity: perfState.controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _ControlsLayer(song: song, state: perfState, notifier: notifier, onInteraction: _onControlInteraction, onClose: () => Navigator.of(context).pop(), onSettings: _openSettings),
            ),
          ),

          // ── Welcome overlay — fades out after first interaction ─────────────
          IgnorePointer(
            ignoring: !_showWelcome,
            child: AnimatedOpacity(
              opacity: _showWelcome ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: _WelcomeOverlay(song: song),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Content Layer ────────────────────────────────────────────────────────────

class _ContentLayer extends StatelessWidget {
  final Song song;
  final PerformanceState state;

  const _ContentLayer({required this.song, required this.state});

  @override
  Widget build(BuildContext context) {
    if (song.sections.isEmpty) {
      return const Center(
        child: Text('No sections in this song.', style: TextStyle(color: Colors.white38, fontSize: 18)),
      );
    }

    final sectionIdx = state.sectionIndex.clamp(0, song.sections.length - 1);
    final section = song.sections[sectionIdx];
    final lines = section.lines;
    final lineIdx = lines.isEmpty ? 0 : state.lineIndex.clamp(0, lines.length - 1);

    return SafeArea(
      child: Padding(
        // Top/bottom padding reserves space for header and footer bars.
        padding: const EdgeInsets.fromLTRB(24, 68, 24, 84),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionBadge(section: section, sectionIndex: sectionIdx, totalSections: song.sections.length, lineIndex: lineIdx, totalLines: lines.length),
            const SizedBox(height: 20),
            Expanded(
              child: _LinesView(lines: lines, activeIndex: lineIdx, activeChordIndex: state.chordIndex, fontSize: state.fontSize, lineSpacing: state.lineSpacing),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section badge + line indicator ──────────────────────────────────────────

class _SectionBadge extends StatelessWidget {
  final SongSection section;
  final int sectionIndex;
  final int totalSections;
  final int lineIndex;
  final int totalLines;

  const _SectionBadge({required this.section, required this.sectionIndex, required this.totalSections, required this.lineIndex, required this.totalLines});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = section.name.isNotEmpty ? section.name.toUpperCase() : section.type.displayName.toUpperCase();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
          child: Text(
            label,
            style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4),
          ),
        ),
        const SizedBox(width: 12),
        if (totalLines > 0) Text('Line ${lineIndex + 1} / $totalLines', style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const Spacer(),
        if (totalSections > 1) Text('${sectionIndex + 1} / $totalSections', style: const TextStyle(color: Colors.white24, fontSize: 12)),
      ],
    );
  }
}

// ─── Lines view ───────────────────────────────────────────────────────────────

/// Karaoke-style lyric display: the active line is anchored at ~25 % from the
/// top so the player can always read ahead. Lines animate between dim and bright
/// as [activeIndex] changes, and the list scrolls smoothly to follow.
class _LinesView extends StatefulWidget {
  final List<SongLine> lines;
  final int activeIndex;
  final int activeChordIndex;
  final double fontSize;
  final double lineSpacing;

  const _LinesView({required this.lines, required this.activeIndex, required this.activeChordIndex, required this.fontSize, required this.lineSpacing});

  @override
  State<_LinesView> createState() => _LinesViewState();
}

class _LinesViewState extends State<_LinesView> {
  final _scrollController = ScrollController();
  final _lineKeys = <int, GlobalKey>{};

  GlobalKey _keyFor(int index) => _lineKeys.putIfAbsent(index, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive(snap: true));
  }

  @override
  void didUpdateWidget(_LinesView old) {
    super.didUpdateWidget(old);
    if (!identical(old.lines, widget.lines)) {
      _lineKeys.clear();
    }
    if (!identical(old.lines, widget.lines) || old.activeIndex != widget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive(snap: !identical(old.lines, widget.lines)));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive({bool snap = false}) {
    if (!mounted) return;
    final ctx = _keyFor(widget.activeIndex).currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: snap ? Duration.zero : const Duration(milliseconds: 520), curve: Curves.easeInOutQuart, alignment: 0.25);
  }

  // Opacity ramp: 0 = active, +N = upcoming, -N = past.
  double _targetOpacity(int rel) => switch (rel) {
    0 => 1.00,
    1 => 0.68,
    2 => 0.42,
    3 => 0.24,
    >= 4 => 0.14,
    -1 => 0.38,
    -2 => 0.20,
    _ => 0.10,
  };

  // Font-scale ramp — active line is largest, shrinks progressively away.
  double _targetScale(int rel) => switch (rel) {
    0 => 1.00,
    1 => 0.86,
    2 => 0.78,
    >= 3 => 0.72,
    -1 => 0.80,
    _ => 0.70,
  };

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) {
      return const Center(
        child: Text('No lines in this section.', style: TextStyle(color: Colors.white24, fontSize: 16)),
      );
    }

    final cs = Theme.of(context).colorScheme;
    // Shared animation config — all animated properties use the same timing
    // so every visual change (size, opacity, pill, accent bar) moves together.
    const dur = Duration(milliseconds: 380);
    const crv = Curves.easeInOutCubic;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 200),
      itemCount: widget.lines.length,
      itemBuilder: (context, index) {
        final rel = index - widget.activeIndex;
        final isActive = rel == 0;
        final opacity = _targetOpacity(rel);
        final targetScale = _targetScale(rel);
        // Upcoming line (+1) keeps an elevated chord tint so the player can
        // see the next chord without it competing with the active line.
        final chordAlpha = isActive ? 1.0 : (rel == 1 ? 0.82 : 0.72);

        return KeyedSubtree(
          key: _keyFor(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            // AnimatedOpacity handles overall line brightness transitions.
            child: AnimatedOpacity(
              opacity: opacity,
              duration: dur,
              curve: crv,
              // AnimatedContainer transitions the active-line pill and accent bar.
              child: AnimatedContainer(
                duration: dur,
                curve: crv,
                padding: isActive ? const EdgeInsets.fromLTRB(0, 10, 16, 10) : const EdgeInsets.fromLTRB(17, 3, 16, 3),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: isActive ? 0.09 : 0.0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Accent bar — animates from 0 width to 3 px when active.
                    AnimatedContainer(
                      duration: dur,
                      curve: crv,
                      width: isActive ? 3.0 : 0.0,
                      margin: EdgeInsets.only(right: isActive ? 14.0 : 0.0),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: isActive ? 1.0 : 0.0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // TweenAnimationBuilder drives the font-size change smoothly
                    // so the active line "snaps into focus" by growing larger
                    // rather than jumping to a new size instantly.
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: targetScale),
                        duration: dur,
                        curve: crv,
                        builder: (ctx, scale, _) => ChordLyricLine(
                          line: widget.lines[index],
                          lyricStyle: TextStyle(color: Colors.white, fontSize: widget.fontSize * scale, height: widget.lineSpacing, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400),
                          chordStyle: TextStyle(
                            color: cs.primary.withValues(alpha: chordAlpha),
                            fontSize: widget.fontSize * 0.60 * scale,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            height: 1.1,
                          ),
                          displayMode: ChordDisplayMode.stacked,
                          activeChordIndex: isActive ? widget.activeChordIndex : -1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Controls overlay ─────────────────────────────────────────────────────────

class _ControlsLayer extends StatelessWidget {
  final Song song;
  final PerformanceState state;
  final PerformanceNotifier notifier;
  final VoidCallback onInteraction;
  final VoidCallback onClose;
  final VoidCallback onSettings;

  const _ControlsLayer({required this.song, required this.state, required this.notifier, required this.onInteraction, required this.onClose, required this.onSettings});

  static const _overlay = Color(0xD0000000);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ── Header bar ────────────────────────────────────────────────────
        Container(
          color: _overlay,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Exit performance mode',
                    onPressed: () {
                      onInteraction();
                      onClose();
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(color: Color(0xDEFFFFFF), fontSize: 15, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist,
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (song.bpm != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text('${song.bpm} BPM', style: const TextStyle(color: Colors.white30, fontSize: 12)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: Colors.white54),
                    tooltip: 'Performance settings',
                    onPressed: () {
                      onInteraction();
                      onSettings();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        const Spacer(),

        // ── Footer (two rows: playback + navigation) ───────────────────────
        Container(
          color: _overlay,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Row 1: play/pause · stop · speed ─────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Slower
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: Colors.white38,
                        iconSize: 22,
                        tooltip: 'Slower',
                        onPressed: () {
                          notifier.slowerScroll();
                          onInteraction();
                        },
                      ),
                      // Speed label
                      _SpeedLabel(multiplier: state.playback.tempoMultiplier, colorScheme: cs),
                      // Faster
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: Colors.white38,
                        iconSize: 22,
                        tooltip: 'Faster',
                        onPressed: () {
                          notifier.fasterScroll();
                          onInteraction();
                        },
                      ),
                      const SizedBox(width: 16),
                      // Play / Pause
                      IconButton(
                        icon: Icon(state.playback.isAdvancing ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
                        color: cs.primary,
                        iconSize: 40,
                        tooltip: state.playback.isAdvancing ? 'Pause' : 'Play',
                        onPressed: () {
                          notifier.togglePlayPause();
                          onInteraction();
                        },
                      ),
                      // Stop
                      IconButton(
                        icon: const Icon(Icons.stop_circle_outlined),
                        color: Colors.white38,
                        iconSize: 28,
                        tooltip: 'Stop and reset',
                        onPressed: () {
                          notifier.stop();
                          onInteraction();
                        },
                      ),
                      // Ended indicator (replaces stop when ended)
                      if (state.playbackStatus == PlaybackStatus.ended)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            'END',
                            style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                          ),
                        ),
                    ],
                  ),
                ),
                // ── Row 2: section/line navigation ───────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        color: Colors.white54,
                        iconSize: 28,
                        tooltip: 'Previous section',
                        onPressed: () {
                          notifier.prevSection();
                          onInteraction();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        color: const Color(0xDEFFFFFF),
                        iconSize: 40,
                        tooltip: 'Previous line',
                        onPressed: () {
                          notifier.prevLine();
                          onInteraction();
                        },
                      ),
                      _RepeatButton(
                        mode: state.repeatMode,
                        colorScheme: cs,
                        onTap: () {
                          notifier.cycleRepeatMode();
                          onInteraction();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        color: const Color(0xDEFFFFFF),
                        iconSize: 40,
                        tooltip: 'Next line',
                        onPressed: () {
                          notifier.nextLine();
                          onInteraction();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        color: Colors.white54,
                        iconSize: 28,
                        tooltip: 'Next section',
                        onPressed: () {
                          notifier.nextSection();
                          onInteraction();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Repeat mode button ───────────────────────────────────────────────────────

class _RepeatButton extends StatelessWidget {
  final RepeatMode mode;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _RepeatButton({required this.mode, required this.colorScheme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = mode != RepeatMode.none;
    final icon = mode == RepeatMode.line ? Icons.repeat_one_rounded : Icons.repeat_rounded;
    final label = switch (mode) {
      RepeatMode.none => '',
      RepeatMode.line => 'LINE',
      RepeatMode.section => 'SEC',
    };

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? colorScheme.primary : Colors.white38, size: 26),
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  label,
                  style: TextStyle(color: colorScheme.primary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Speed label ─────────────────────────────────────────────────────────────

class _SpeedLabel extends StatelessWidget {
  final double multiplier;
  final ColorScheme colorScheme;

  const _SpeedLabel({required this.multiplier, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isDefault = (multiplier - 1.0).abs() < 0.01;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${multiplier.toStringAsFixed(2)}×',
          style: TextStyle(color: isDefault ? Colors.white38 : colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const Text('SPEED', style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 1.0)),
      ],
    );
  }
}

// ─── Welcome overlay ─────────────────────────────────────────────────────────

/// Bottom-anchored gradient overlay shown when the player first enters
/// performance mode. Explains the controls and fades out on first interaction.
class _WelcomeOverlay extends StatelessWidget {
  final Song song;

  const _WelcomeOverlay({required this.song});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.45, 1.0], colors: [Colors.transparent, Color(0x99000000), Color(0xDD000000)]),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (song.artist.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: const TextStyle(color: Colors.white54, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded, color: cs.primary, size: 16),
                      const SizedBox(width: 8),
                      const Text('Tap ▶ to auto-scroll  ·  tap lyrics to navigate', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}

// ─── Performance settings bottom sheet ───────────────────────────────────────

class _SettingsSheet extends ConsumerWidget {
  final String songId;
  final VoidCallback onInteraction;

  const _SettingsSheet({required this.songId, required this.onInteraction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(performanceNotifierProvider(songId));
    final notifier = ref.read(performanceNotifierProvider(songId).notifier);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          const Text(
            'Performance Settings',
            style: TextStyle(color: Color(0xDEFFFFFF), fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),

          // Font size
          _SettingRow(label: 'Font Size', value: '${state.fontSize.round()} sp', colorScheme: cs),
          const SizedBox(height: 4),
          _ThemedSlider(
            value: state.fontSize,
            min: PerformanceState.minFontSize,
            max: PerformanceState.maxFontSize,
            divisions: 20,
            colorScheme: cs,
            onChanged: (v) {
              notifier.setFontSize(v);
              onInteraction();
            },
          ),
          const SizedBox(height: 20),

          // Line spacing
          _SettingRow(label: 'Line Spacing', value: '${state.lineSpacing.toStringAsFixed(1)}×', colorScheme: cs),
          const SizedBox(height: 4),
          _ThemedSlider(
            value: state.lineSpacing,
            min: PerformanceState.minLineSpacing,
            max: PerformanceState.maxLineSpacing,
            divisions: 16,
            colorScheme: cs,
            onChanged: (v) {
              notifier.setLineSpacing(v);
              onInteraction();
            },
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _SettingRow({required this.label, required this.value, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(color: colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ThemedSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ColorScheme colorScheme;
  final ValueChanged<double> onChanged;

  const _ThemedSlider({required this.value, required this.min, required this.max, required this.divisions, required this.colorScheme, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(activeTrackColor: colorScheme.primary, thumbColor: colorScheme.primary, inactiveTrackColor: Colors.white12, overlayColor: colorScheme.primary.withValues(alpha: 0.15)),
      child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
    );
  }
}
