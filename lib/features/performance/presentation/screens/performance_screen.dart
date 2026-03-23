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
  // True until the player first interacts in full-screen mode.
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    // Default to edge-to-edge; ref.listen in build() reacts to fullscreen changes.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  bool get _isFullScreen => ref.read(performanceNotifierProvider(widget.songId)).isFullScreen;

  /// Restart the auto-hide countdown (full-screen only): 10 s on entry, 4 s thereafter.
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

  /// Tap on the content area: toggle controls visibility (full-screen only).
  void _onContentTap() {
    if (!_isFullScreen) return;
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

  /// Called by control button interactions — surfaces controls + resets timer.
  /// No-op in normal (non-fullscreen) mode.
  void _onControlInteraction() {
    if (!_isFullScreen) return;
    _onFirstInteraction();
    ref.read(performanceNotifierProvider(widget.songId).notifier).showControls();
    _scheduleHide();
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1B1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SettingsSheet(songId: widget.songId, onInteraction: _onControlInteraction),
    );
  }

  void _showTempoTapDialog(BuildContext context, PerformanceNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _TempoTapDialog(notifier: notifier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(songByIdProvider(widget.songId));
    final perfState = ref.watch(performanceNotifierProvider(widget.songId));
    final notifier = ref.read(performanceNotifierProvider(widget.songId).notifier);

    // React to fullscreen toggle — update system UI and (de)activate hide timer.
    ref.listen<bool>(performanceNotifierProvider(widget.songId).select((s) => s.isFullScreen), (prev, next) {
      if (next) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        setState(() => _showWelcome = true);
        _scheduleHide();
      } else {
        _hideTimer?.cancel();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });

    if (song == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Song not found.', style: TextStyle(color: Colors.white54, fontSize: 18)),
        ),
      );
    }

    if (perfState.isFullScreen) {
      return _buildFullScreenLayout(context, song, perfState, notifier);
    }
    return _buildNormalLayout(context, song, perfState, notifier);
  }

  // ── Normal (non-immersive) layout ──────────────────────────────────────────

  Widget _buildNormalLayout(BuildContext context, Song song, PerformanceState perfState, PerformanceNotifier notifier) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          tooltip: 'Exit performance mode',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              song.title,
              style: const TextStyle(color: Color(0xDEFFFFFF), fontSize: 15, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            if (song.artist.isNotEmpty)
              Text(
                song.artist,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.touch_app_rounded, color: Colors.white54),
            tooltip: 'Tap to detect tempo',
            onPressed: () => _showTempoTapDialog(context, notifier),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white54),
            tooltip: 'Edit song',
            onPressed: () => context.push('/song/${widget.songId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white54),
            tooltip: 'Performance settings',
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded, color: Colors.white54),
            tooltip: 'Full screen',
            onPressed: () => notifier.toggleFullScreen(),
          ),
        ],
      ),
      body: Column(
        children: [
          _SongDetailsHeader(song: song),
          Expanded(
            child: _ContentLayer(song: song, state: perfState, onScrollActivated: (si, li) => ref.read(performanceNotifierProvider(widget.songId).notifier).jumpToLine(si, li)),
          ),
        ],
      ),
      bottomNavigationBar: _FooterBar(state: perfState, notifier: notifier, onInteraction: () {}),
    );
  }

  // ── Full-screen (immersive) layout ─────────────────────────────────────────

  Widget _buildFullScreenLayout(BuildContext context, Song song, PerformanceState perfState, PerformanceNotifier notifier) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Content area — tap toggles controls ─────────────────────────
          Positioned.fill(
            child: GestureDetector(
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
          ),

          // ── Controls overlay — pointer-transparent when hidden ──────────
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !perfState.controlsVisible,
              child: AnimatedOpacity(
                opacity: perfState.controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _ControlsLayer(song: song, state: perfState, notifier: notifier, onInteraction: _onControlInteraction, onClose: () => Navigator.of(context).pop(), onSettings: _openSettings, onEdit: () => context.push('/song/${widget.songId}/edit'), onExitFullScreen: () => notifier.toggleFullScreen()),
              ),
            ),
          ),

          // ── Footer controls — always visible ────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _FooterBar(state: perfState, notifier: notifier, onInteraction: _onControlInteraction),
          ),

          // ── Welcome overlay — pointer-transparent ───────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showWelcome ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: _WelcomeOverlay(song: song),
              ),
            ),
          ),

          // ── Quick restart FAB — top right corner ────────────────────────
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IgnorePointer(
                ignoring: !perfState.controlsVisible,
                child: AnimatedOpacity(
                  opacity: perfState.controlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: FloatingActionButton(
                    onPressed: () {
                      notifier.stop(); // Resets to line 0
                      notifier.setTempoMultiplier(1.0); // Reset speed to 1×
                      _onControlInteraction();
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                    child: const Icon(Icons.restart_alt_rounded, color: Colors.black87, size: 28),
                  ),
                ),
              ),
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

  /// Per-line proximity notifier (0.0 = far from centre, 1.0 = in spotlight).
  /// Updated on every scroll tick so _LineItem can animate without rebuilding
  /// the entire Content Layer on every frame.
  final _lineFocusNotifiers = <(int, int), ValueNotifier<double>>{};

  /// Suppresses scroll-activation while a programmatic snap animation runs.
  bool _suppressScrollActivation = false;

  /// Current height fed to the spotlight AnimatedContainer.
  double _spotlightHeight = 56.0;

  GlobalKey _keyFor(int si, int li) => _lineKeys.putIfAbsent((si, li), GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScrollUpdate);
    // After the first frame the keys and scroll position are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _snapToCenter(widget.state.sectionIndex, widget.state.lineIndex);
        _updateLineFocusValues();
      }
    });
  }

  @override
  void didUpdateWidget(_ContentLayer old) {
    super.didUpdateWidget(old);
    final posChanged = old.state.sectionIndex != widget.state.sectionIndex || old.state.lineIndex != widget.state.lineIndex;
    final displayChanged = old.state.fontSize != widget.state.fontSize || old.state.lineSpacing != widget.state.lineSpacing;
    if (posChanged || displayChanged) {
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

      _scrollCtrl.animateTo(targetOffset, duration: const Duration(milliseconds: 550), curve: Curves.easeInOutSine);

      // Animate the spotlight height to hug this line.
      setState(() => _spotlightHeight = lineH);

      Future.delayed(const Duration(milliseconds: 620), () {
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

  ValueNotifier<double> _focusNotifierFor(int si, int li) => _lineFocusNotifiers.putIfAbsent((si, li), () => ValueNotifier(0.0));

  void _onScrollUpdate() => _updateLineFocusValues();

  /// Recomputes focus progress (0.0–1.0) for every line based on its distance
  /// from the viewport centre.  Skips notifiers whose value hasn't changed
  /// meaningfully to minimise per-frame widget rebuilds.
  void _updateLineFocusValues() {
    if (!mounted) return;
    final scrollRb = _scrollKey.currentContext?.findRenderObject() as RenderBox?;
    if (scrollRb == null) return;
    final viewportCenterY = scrollRb.localToGlobal(Offset.zero).dy + scrollRb.size.height / 2;

    for (final entry in _lineKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final rb = ctx.findRenderObject() as RenderBox?;
      if (rb == null || !rb.attached) continue;

      final lineCenterY = rb.localToGlobal(Offset.zero).dy + rb.size.height / 2;
      final dist = (lineCenterY - viewportCenterY).abs();
      // Full focus within 60 px of centre; fades to 0 beyond 280 px.
      const fullFocusDist = 60.0;
      const zeroFocusDist = 280.0;
      final newProg = ((zeroFocusDist - dist) / (zeroFocusDist - fullFocusDist)).clamp(0.0, 1.0);

      final notifier = _focusNotifierFor(entry.key.$1, entry.key.$2);
      if ((notifier.value - newProg).abs() > 0.005) notifier.value = newProg;
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScrollUpdate);
    _scrollCtrl.dispose();
    for (final n in _lineFocusNotifiers.values) {
      n.dispose();
    }
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

    final contentItems = <Widget>[];
    for (int si = 0; si < widget.song.sections.length; si++) {
      final section = widget.song.sections[si];
      contentItems.add(_InlineSectionHeader(section: section));
      contentItems.add(const SizedBox(height: 8));
      for (int li = 0; li < section.lines.length; li++) {
        contentItems.add(_LineItem(key: _keyFor(si, li), line: section.lines[li], isActive: si == activeSi && li == activeLi, activeChordIndex: (si == activeSi && li == activeLi) ? widget.state.chordIndex : -1, fontSize: widget.state.fontSize, lineSpacing: widget.state.lineSpacing, colorScheme: cs, focusNotifier: _focusNotifierFor(si, li)));
      }
      contentItems.add(const SizedBox(height: 28));
    }

    return SizedBox.expand(
      // SizedBox.expand caps any infinite incoming constraints before they
      // reach the inner Stack, making StackFit.expand safe to use here.
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Scrollable song list ──────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              // LayoutBuilder is safe here: StackFit.expand passes the finite
              // tight constraints from SizedBox.expand through SafeArea so
              // maxHeight is always a real screen dimension, never infinity.
              builder: (ctx, constraints) {
                final halfH = constraints.maxHeight > 0 ? constraints.maxHeight / 2 : 400.0;
                return NotificationListener<ScrollEndNotification>(
                  onNotification: (_) {
                    if (!_suppressScrollActivation) _activateNearestLine();
                    return false;
                  },
                  child: SingleChildScrollView(
                    key: _scrollKey,
                    controller: _scrollCtrl,
                    padding: EdgeInsets.fromLTRB(16, halfH, 16, halfH),
                    child: Column(
                      // stretch forces every _LineItem / Wrap to receive tight
                      // width = columnWidth, preventing unconstrained-width
                      // collapses that cause items to pile at (0,0).
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: contentItems,
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Spotlight frame — fixed at viewport centre ───────────────────
          // Align is safe here: StackFit.expand gives it finite tight bounds.
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
      ),
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

class _LineItem extends StatefulWidget {
  final SongLine line;
  final bool isActive;
  final int activeChordIndex;
  final double fontSize;
  final double lineSpacing;
  final ColorScheme colorScheme;

  /// Scroll-driven proximity to the viewport centre (0.0–1.0).
  /// Updated by _ContentLayerState on every scroll tick.
  final ValueNotifier<double> focusNotifier;

  const _LineItem({super.key, required this.line, required this.isActive, required this.activeChordIndex, required this.fontSize, required this.lineSpacing, required this.colorScheme, required this.focusNotifier});

  @override
  State<_LineItem> createState() => _LineItemState();
}

class _LineItemState extends State<_LineItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  // Scale: inactive lines are ~88 % the size of the focused line.
  late Animation<double> _scale;
  // Slight upward slide as the line snaps into focus — easeOutBack overshoots
  // and bounces back, giving the "snappy pop" without feeling heavy.
  late Animation<double> _slideY;
  // Opacity is driven by the same controller so everything moves together.
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _scale = Tween<double>(begin: 0.875, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _slideY = Tween<double>(begin: 10.0, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _opacity = Tween<double>(begin: 0.38, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    // Start immediately at the correct position without animating on first build.
    if (widget.isActive) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_LineItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      // Start the bounce from whatever scroll proximity the line already has so
      // the animation feels like a natural continuation of the scroll gesture.
      _ctrl.forward(from: widget.focusNotifier.value);
    } else if (!widget.isActive && old.isActive) {
      // Stop the controller — scroll-driven rendering takes over immediately.
      _ctrl
        ..stop()
        ..value = 0.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the lyric widget once; only the transforms are recomputed per tick.
    final lineWidget = ChordLyricLine(
      line: widget.line,
      lyricStyle: TextStyle(color: Colors.white, fontSize: widget.fontSize, height: widget.lineSpacing, fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400),
      chordStyle: TextStyle(
        color: widget.colorScheme.primary.withValues(alpha: widget.isActive ? 1.0 : 0.7),
        fontSize: widget.fontSize * 0.60,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.1,
      ),
      displayMode: ChordDisplayMode.stacked,
      activeChordIndex: widget.activeChordIndex,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      child: ValueListenableBuilder<double>(
        valueListenable: widget.focusNotifier,
        builder: (context, scrollProg, _) {
          return AnimatedBuilder(
            animation: _ctrl,
            child: lineWidget,
            builder: (context, child) {
              final double scale;
              final double slideY;
              final double opacity;

              if (widget.isActive) {
                // Bounce animation takes control — easeOutBack gives the snap.
                scale = _scale.value;
                slideY = _slideY.value;
                opacity = _opacity.value;
              } else {
                // Inactive lines track scroll proximity smoothly — no bounce,
                // just a soft grow/fade as the line drifts through the spotlight.
                scale = 0.875 + 0.125 * scrollProg;
                slideY = 0.0;
                opacity = 0.38 + 0.62 * scrollProg;
              }

              return Transform.translate(
                offset: Offset(0, slideY),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: Opacity(opacity: opacity, child: child),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
// ─── Song details header (normal mode) ─────────────────────────────────────────────

/// Compact chip row showing key, BPM, and notes.  Hidden when all are absent.
class _SongDetailsHeader extends StatelessWidget {
  final Song song;
  const _SongDetailsHeader({required this.song});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chips = <Widget>[if (song.key != null) _InfoChip(label: 'Key of ${song.key!}', cs: cs), if (song.bpm != null) _InfoChip(label: '${song.bpm} BPM', cs: cs), if (song.notes != null && song.notes!.isNotEmpty) _InfoChip(label: song.notes!, cs: cs)];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      color: const Color(0xFF0D0D0D),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _InfoChip({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
  final VoidCallback onExitFullScreen;

  const _ControlsLayer({required this.song, required this.state, required this.notifier, required this.onInteraction, required this.onClose, required this.onSettings, required this.onEdit, required this.onExitFullScreen});

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
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white54),
                    tooltip: 'Edit song',
                    onPressed: () {
                      onInteraction();
                      onEdit();
                    },
                  ),
                  // Section loop toggle with counter
                  _SectionLoopButton(
                    isActive: state.repeatMode == RepeatMode.section,
                    loopCount: state.sectionLoopCounter,
                    onPressed: () {
                      onInteraction();
                      notifier.toggleSectionLoop();
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
                  IconButton(
                    icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white54),
                    tooltip: 'Exit full screen',
                    onPressed: () {
                      onInteraction();
                      onExitFullScreen();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speed presets row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SpeedPresetChip(
                    label: '0.5×',
                    multiplier: 0.5,
                    currentMultiplier: state.playback.tempoMultiplier,
                    onTap: () {
                      notifier.setTempoMultiplier(0.5);
                      onInteraction();
                    },
                    cs: cs,
                  ),
                  const SizedBox(width: 8),
                  _SpeedPresetChip(
                    label: '0.75×',
                    multiplier: 0.75,
                    currentMultiplier: state.playback.tempoMultiplier,
                    onTap: () {
                      notifier.setTempoMultiplier(0.75);
                      onInteraction();
                    },
                    cs: cs,
                  ),
                  const SizedBox(width: 8),
                  _SpeedPresetChip(
                    label: '1×',
                    multiplier: 1.0,
                    currentMultiplier: state.playback.tempoMultiplier,
                    onTap: () {
                      notifier.setTempoMultiplier(1.0);
                      onInteraction();
                    },
                    cs: cs,
                  ),
                  const SizedBox(width: 8),
                  _SpeedPresetChip(
                    label: '1.25×',
                    multiplier: 1.25,
                    currentMultiplier: state.playback.tempoMultiplier,
                    onTap: () {
                      notifier.setTempoMultiplier(1.25);
                      onInteraction();
                    },
                    cs: cs,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Main playback controls
              Row(
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
          const SizedBox(height: 20),

          // Auto-scroll speed
          _SettingRow(label: 'Auto-scroll Speed', value: '${state.playback.tempoMultiplier.toStringAsFixed(2)}×', colorScheme: cs),
          const SizedBox(height: 4),
          _ThemedSlider(
            value: state.playback.tempoMultiplier,
            min: PlaybackState.minMultiplier,
            max: PlaybackState.maxMultiplier,
            divisions: 15,
            colorScheme: cs,
            onChanged: (v) {
              notifier.setTempoMultiplier(v);
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

// ─── Speed preset chip ────────────────────────────────────────────────────────

/// Quick-tap speed preset button for common practice speeds.
class _SpeedPresetChip extends StatelessWidget {
  final String label;
  final double multiplier;
  final double currentMultiplier;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _SpeedPresetChip({required this.label, required this.multiplier, required this.currentMultiplier, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isActive = (currentMultiplier - multiplier).abs() < 0.01;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isActive ? cs.primary : Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(
          label,
          style: TextStyle(color: isActive ? Colors.black87 : Colors.white70, fontSize: 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Section loop toggle button ───────────────────────────────────────────────

/// Toggle button for section loop with counter display.
class _SectionLoopButton extends StatelessWidget {
  final bool isActive;
  final int loopCount;
  final VoidCallback onPressed;

  const _SectionLoopButton({required this.isActive, required this.loopCount, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? cs.primary.withValues(alpha: 0.25) : Colors.transparent,
          border: Border.all(color: isActive ? cs.primary : Colors.white30, width: isActive ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat_rounded, color: isActive ? cs.primary : Colors.white54, size: 20),
            if (isActive && loopCount > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$loopCount',
                style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Tempo tap dialog ──────────────────────────────────────────────────────────

/// Dialog for detecting BPM by tapping — tap 4-8 times to calculate tempo.
class _TempoTapDialog extends StatefulWidget {
  final PerformanceNotifier notifier;

  const _TempoTapDialog({required this.notifier});

  @override
  State<_TempoTapDialog> createState() => _TempoTapDialogState();
}

class _TempoTapDialogState extends State<_TempoTapDialog> {
  int _tapCount = 0;
  double? _detectedBpm;

  void _onTap() {
    final (tapCount, bpm) = widget.notifier.tapTempo();
    setState(() {
      _tapCount = tapCount;
      if (bpm != null) {
        _detectedBpm = bpm;
      }
    });
  }

  void _applyTempo() {
    if (_detectedBpm == null) return;
    // Calculate multiplier: detected BPM / original BPM (assume 120 as default)
    // For now, just close — user can adjust via speed presets
    // TODO(phase-5): enhance with actual BPM storage in Song model
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: const Color(0xFF1C1B1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tap to Detect Tempo',
              style: TextStyle(color: Color(0xDEFFFFFF), fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _onTap,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary.withValues(alpha: 0.2), border: Border.all(color: cs.primary, width: 3)),
                child: Center(
                  child: _detectedBpm == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded, color: cs.primary, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Tap $_tapCount/4',
                              style: TextStyle(color: cs.primary, fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_detectedBpm!.round()}',
                              style: TextStyle(color: cs.primary, fontSize: 56, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'BPM',
                              style: TextStyle(color: cs.primary, fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_detectedBpm == null)
              const Text(
                'Tap at least 4 times\nat your desired tempo',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              )
            else
              TextButton.icon(
                onPressed: _applyTempo,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Got it'),
                style: TextButton.styleFrom(foregroundColor: cs.primary, textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}
