import 'dart:async';

// Hide Flutter's own RepeatMode (added in 3.x) to avoid ambiguity with ours.
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../song_library/domain/models/song.dart';
import '../../../song_library/domain/models/song_line.dart';
import '../../../song_library/domain/models/song_section.dart';
import '../../../song_library/presentation/providers/song_library_provider.dart';
import '../../../song_library/presentation/widgets/chord_lyric_line.dart';
import '../../domain/performance_state.dart';
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
            child: _ContentLayer(
              song: song,
              state: perfState,
              onScrollActivated: (si, li) {
                ref.read(performanceNotifierProvider(widget.songId).notifier).jumpToLine(si, li);
              },
            ),
          ),

          // ── Controls overlay (header only) — pointer-transparent when hidden
          IgnorePointer(
            ignoring: !perfState.controlsVisible,
            child: AnimatedOpacity(
              opacity: perfState.controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _ControlsLayer(song: song, state: perfState, notifier: notifier, onInteraction: _onControlInteraction, onClose: () => Navigator.of(context).pop(), onSettings: _openSettings, onEdit: () => context.push('/song/${widget.songId}/edit')),
            ),
          ),

          // ── Footer controls — always visible ──────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _FooterBar(state: perfState, notifier: notifier, onInteraction: _onControlInteraction),
          ),

          // ── Welcome overlay — purely visual; always pointer-transparent so
          //    taps fall through to the GestureDetector beneath, which calls
          //    _onFirstInteraction and dismisses it.
          IgnorePointer(
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

class _ContentLayer extends StatefulWidget {
  final Song song;
  final PerformanceState state;

  /// Called when the user scrolls and the nearest line to screen centre
  /// changes.  The parent uses this to update the active line in the notifier.
  final void Function(int si, int li)? onScrollActivated;

  const _ContentLayer({required this.song, required this.state, this.onScrollActivated});

  @override
  State<_ContentLayer> createState() => _ContentLayerState();
}

class _ContentLayerState extends State<_ContentLayer> {
  final _scrollCtrl = ScrollController();

  /// Key on the SafeArea so we can read the viewport's screen position + size.
  final _scrollKey = GlobalKey();

  /// Maps (sectionIndex, lineIndex) → GlobalKey for that _LineItem.
  final _lineKeys = <(int, int), GlobalKey>{};

  /// Suppresses scroll-activation while a programmatic snap animation runs.
  bool _suppressScrollActivation = false;

  /// Current height fed to the spotlight AnimatedContainer.
  double _spotlightHeight = 56.0;

  GlobalKey _keyFor(int si, int li) => _lineKeys.putIfAbsent((si, li), GlobalKey.new);

  @override
  void initState() {
    super.initState();
    // After the first frame the keys and scroll position are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _snapToCenter(widget.state.sectionIndex, widget.state.lineIndex);
    });
  }

  @override
  void didUpdateWidget(_ContentLayer old) {
    super.didUpdateWidget(old);
    if (old.state.sectionIndex != widget.state.sectionIndex || old.state.lineIndex != widget.state.lineIndex) {
      _snapToCenter(widget.state.sectionIndex, widget.state.lineIndex);
    }
  }

  /// Scrolls so the given line is precisely centred in the viewport, and
  /// animates the spotlight container to match the line's rendered height.
  void _snapToCenter(int si, int li) {
    _suppressScrollActivation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final lineCtx = _keyFor(si, li).currentContext;
      final scrollCtx = _scrollKey.currentContext;
      if (lineCtx == null || scrollCtx == null) return;

      final lineRb = lineCtx.findRenderObject() as RenderBox?;
      final scrollRb = scrollCtx.findRenderObject() as RenderBox?;
      if (lineRb == null || scrollRb == null || !_scrollCtrl.hasClients) return;

      // All positions in global (screen) coordinates.
      final scrollTopGlobal = scrollRb.localToGlobal(Offset.zero).dy;
      final lineTopGlobal = lineRb.localToGlobal(Offset.zero).dy;

      final lineTopInViewport = lineTopGlobal - scrollTopGlobal;
      final viewportH = scrollRb.size.height;
      final lineH = lineRb.size.height;

      // Scroll so the line's centre aligns with the viewport centre.
      final targetOffset = (_scrollCtrl.offset + lineTopInViewport - (viewportH - lineH) / 2).clamp(0.0, _scrollCtrl.position.maxScrollExtent);

      _scrollCtrl.animateTo(targetOffset, duration: const Duration(milliseconds: 380), curve: Curves.easeInOutCubic);

      // Animate the spotlight height to hug this line.
      setState(() => _spotlightHeight = lineH);

      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) _suppressScrollActivation = false;
      });
    });
  }

  /// After the user's scroll settles, activates the line whose centre is closest
  /// to the viewport centre, then snaps it into the spotlight.
  void _activateNearestLine() {
    if (!mounted) return;

    final scrollRb = _scrollKey.currentContext?.findRenderObject() as RenderBox?;
    final viewportCenterY = scrollRb != null ? scrollRb.localToGlobal(Offset.zero).dy + scrollRb.size.height / 2 : MediaQuery.of(context).size.height / 2;

    double bestDist = double.infinity;
    int bestSi = 0;
    int bestLi = 0;
    bool found = false;

    for (final entry in _lineKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final rb = ctx.findRenderObject() as RenderBox?;
      if (rb == null || !rb.attached) continue;
      final lineCenterY = rb.localToGlobal(Offset.zero).dy + rb.size.height / 2;
      final dist = (lineCenterY - viewportCenterY).abs();
      if (dist < bestDist) {
        bestDist = dist;
        bestSi = entry.key.$1;
        bestLi = entry.key.$2;
        found = true;
      }
    }

    if (!found) return;

    // Notify the notifier (updates state → didUpdateWidget → _snapToCenter).
    widget.onScrollActivated?.call(bestSi, bestLi);

    // In case the notifier doesn't change the state (same line), still snap.
    if (bestSi == widget.state.sectionIndex && bestLi == widget.state.lineIndex) {
      _snapToCenter(bestSi, bestLi);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.song.sections.isEmpty) {
      return const Center(
        child: Text('No sections in this song.', style: TextStyle(color: Colors.white38, fontSize: 18)),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final activeSi = widget.state.sectionIndex;
    final activeLi = widget.state.lineIndex;

    // Build section + line widgets (without spacers — added inside LayoutBuilder).
    final contentItems = <Widget>[];
    for (int si = 0; si < widget.song.sections.length; si++) {
      final section = widget.song.sections[si];
      contentItems.add(_InlineSectionHeader(section: section));
      contentItems.add(const SizedBox(height: 8));
      for (int li = 0; li < section.lines.length; li++) {
        contentItems.add(_LineItem(key: _keyFor(si, li), line: section.lines[li], isActive: si == activeSi && li == activeLi, activeChordIndex: (si == activeSi && li == activeLi) ? widget.state.chordIndex : -1, fontSize: widget.state.fontSize, lineSpacing: widget.state.lineSpacing, colorScheme: cs));
      }
      contentItems.add(const SizedBox(height: 28));
    }

    return Stack(
      children: [
        // ── Scrollable song list ────────────────────────────────────────────
        SafeArea(
          key: _scrollKey,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              // Half-screen buffers let every line be scrolled to centre.
              final halfH = constraints.maxHeight / 2;
              return NotificationListener<ScrollEndNotification>(
                onNotification: (_) {
                  if (!_suppressScrollActivation) _activateNearestLine();
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: halfH),
                      ...contentItems,
                      SizedBox(height: halfH),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ── Spotlight frame — fixed at viewport centre ───────────────────────
        Align(
          alignment: Alignment.center,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              height: (_spotlightHeight + 16).clamp(40.0, 500.0),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.07),
                border: Border.all(color: cs.primary.withValues(alpha: 0.50), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Inline section header ────────────────────────────────────────────────────

class _InlineSectionHeader extends StatelessWidget {
  final SongSection section;

  const _InlineSectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = section.name.isNotEmpty ? section.name.toUpperCase() : section.type.displayName.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)),
      child: Text(
        label,
        style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4),
      ),
    );
  }
}

// ─── Song line item ───────────────────────────────────────────────────────────

class _LineItem extends StatelessWidget {
  final SongLine line;
  final bool isActive;
  final int activeChordIndex;
  final double fontSize;
  final double lineSpacing;
  final ColorScheme colorScheme;

  const _LineItem({super.key, required this.line, required this.isActive, required this.activeChordIndex, required this.fontSize, required this.lineSpacing, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    // The spotlight frame handles all active-line decoration — _LineItem just
    // controls the text colour/weight so lines are readable when dimmed.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isActive ? 1.0 : 0.38,
        child: ChordLyricLine(
          line: line,
          lyricStyle: TextStyle(color: Colors.white, fontSize: fontSize, height: lineSpacing, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400),
          chordStyle: TextStyle(
            color: colorScheme.primary.withValues(alpha: isActive ? 1.0 : 0.7),
            fontSize: fontSize * 0.60,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            height: 1.1,
          ),
          displayMode: ChordDisplayMode.stacked,
          activeChordIndex: activeChordIndex,
        ),
      ),
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
  final VoidCallback onEdit;

  const _ControlsLayer({required this.song, required this.state, required this.notifier, required this.onInteraction, required this.onClose, required this.onSettings, required this.onEdit});

  static const _overlay = Color(0xD0000000);

  @override
  Widget build(BuildContext context) {
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
                        // Key · BPM — compact info row, auto-hides if both absent
                        Builder(
                          builder: (_) {
                            final parts = [if (song.key != null) 'Key of ${song.key}', if (song.bpm != null) '${song.bpm} BPM'];
                            if (parts.isEmpty) return const SizedBox.shrink();
                            return Text(parts.join('  ·  '), style: const TextStyle(color: Colors.white24, fontSize: 11));
                          },
                        ),
                      ],
                    ),
                  ),
                  // Edit song
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white54),
                    tooltip: 'Edit song',
                    onPressed: () {
                      onInteraction();
                      onEdit();
                    },
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
      ],
    );
  }
}

// ─── Footer bar (always visible) ─────────────────────────────────────────────

/// Persistent music-player style footer with skip / play-pause / skip buttons.
/// Lives outside the auto-hide [AnimatedOpacity] so it is always reachable.
class _FooterBar extends StatelessWidget {
  final PerformanceState state;
  final PerformanceNotifier notifier;
  final VoidCallback onInteraction;

  const _FooterBar({required this.state, required this.notifier, required this.onInteraction});

  static const _overlay = Color(0xD0000000);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: _overlay,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                color: Colors.white70,
                iconSize: 34,
                tooltip: 'Skip to beginning',
                onPressed: () {
                  notifier.stop();
                  onInteraction();
                },
              ),
              const SizedBox(width: 28),
              GestureDetector(
                onTap: () {
                  notifier.togglePlayPause();
                  onInteraction();
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary),
                  child: Icon(state.playback.isAdvancing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black87, size: 42),
                ),
              ),
              const SizedBox(width: 28),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                color: Colors.white70,
                iconSize: 34,
                tooltip: 'Skip to end',
                onPressed: () {
                  notifier.jumpToEnd();
                  onInteraction();
                },
              ),
            ],
          ),
        ),
      ),
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
                      const Text('Scroll freely  ·  tap ▶ to auto-advance', style: TextStyle(color: Colors.white60, fontSize: 13)),
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
