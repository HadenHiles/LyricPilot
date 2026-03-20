import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/chord_event.dart';
import '../../domain/models/section_type.dart';
import '../../domain/models/song.dart';
import '../../domain/models/song_line.dart';
import '../../domain/models/song_section.dart';
import '../../domain/lyric_parser.dart';
import '../providers/song_library_provider.dart';

// ─────────────────────────────────────────────────────────
// Word-position helpers
// ─────────────────────────────────────────────────────────

typedef _WordEntry = ({String word, int position});

/// Splits [lyric] into non-whitespace tokens, recording each token's
/// start character offset in the original string.
List<_WordEntry> _splitWords(String lyric) {
  final result = <_WordEntry>[];
  for (final m in RegExp(r'\S+').allMatches(lyric)) {
    result.add((word: m.group(0)!, position: m.start));
  }
  return result;
}

// ─────────────────────────────────────────────────────────
// Editor state helpers (local, not domain models)
// ─────────────────────────────────────────────────────────

class _EditableLine {
  final String id;
  final TextEditingController lyricCtrl;

  /// Maps word index (0-based) → chord symbol assigned to that word.
  Map<int, String> chordByWordIndex;

  /// When true the line widget auto-enters lyric-edit mode on first build.
  /// The widget clears this flag once consumed.
  bool autoFocus;

  _EditableLine({required this.id, String lyric = '', Map<int, String>? chords, this.autoFocus = false}) : lyricCtrl = TextEditingController(text: lyric), chordByWordIndex = chords ?? {};

  void dispose() => lyricCtrl.dispose();

  SongLine toSongLine() {
    final lyric = lyricCtrl.text.trim();
    final words = _splitWords(lyric);
    final events = <ChordEvent>[];
    for (final entry in chordByWordIndex.entries) {
      if (entry.key >= words.length) continue;
      events.add(ChordEvent(chord: entry.value, position: words[entry.key].position));
    }
    events.sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    return SongLine(id: id, lyric: lyric, chords: events);
  }

  /// Load chord events from a persisted [SongLine], mapping char offsets
  /// back to the nearest word index.
  static _EditableLine fromSongLine(SongLine line) {
    final words = _splitWords(line.lyric);
    final chords = <int, String>{};
    for (final chord in line.chords) {
      final pos = chord.position ?? 0;
      if (words.isEmpty) continue;
      int closestIdx = 0;
      int minDist = (words[0].position - pos).abs();
      for (int i = 1; i < words.length; i++) {
        final d = (words[i].position - pos).abs();
        if (d < minDist) {
          minDist = d;
          closestIdx = i;
        }
      }
      chords[closestIdx] = chord.chord;
    }
    return _EditableLine(id: line.id, lyric: line.lyric, chords: chords);
  }
}

class _EditableSection {
  final String id;
  final TextEditingController nameCtrl;
  SectionType type;
  final List<_EditableLine> lines;

  _EditableSection({required this.id, String name = '', this.type = SectionType.verse, List<_EditableLine>? lines}) : nameCtrl = TextEditingController(text: name), lines = lines ?? [];

  void dispose() {
    nameCtrl.dispose();
    for (final l in lines) {
      l.dispose();
    }
  }

  SongSection toSongSection() => SongSection(id: id, name: nameCtrl.text.trim().isEmpty ? type.displayName : nameCtrl.text.trim(), type: type, lines: lines.map((l) => l.toSongLine()).toList());
}

// ─────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────

/// Creates or edits a song using a lyrics-first interface.
///
/// Pass [songId] to edit an existing song; leave null to create a new one.
class SongEditorScreen extends ConsumerStatefulWidget {
  final String? songId;

  const SongEditorScreen({super.key, this.songId});

  @override
  ConsumerState<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends ConsumerState<SongEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _artistCtrl;
  late final TextEditingController _keyCtrl;
  late final TextEditingController _bpmCtrl;
  late final TextEditingController _notesCtrl;
  final List<_EditableSection> _sections = [];
  bool _saving = false;

  bool get _isEditing => widget.songId != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _artistCtrl = TextEditingController();
    _keyCtrl = TextEditingController();
    _bpmCtrl = TextEditingController();
    _notesCtrl = TextEditingController();

    if (_isEditing) {
      final song = ref.read(songByIdProvider(widget.songId!));
      if (song != null) _populateFromSong(song);
    }
  }

  void _populateFromSong(Song song) {
    _titleCtrl.text = song.title;
    _artistCtrl.text = song.artist;
    _keyCtrl.text = song.key ?? '';
    _bpmCtrl.text = song.bpm?.toString() ?? '';
    _notesCtrl.text = song.notes ?? '';
    for (final section in song.sections) {
      _sections.add(_EditableSection(id: section.id, name: section.name, type: section.type, lines: section.lines.map(_EditableLine.fromSongLine).toList()));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _keyCtrl.dispose();
    _bpmCtrl.dispose();
    _notesCtrl.dispose();
    for (final s in _sections) {
      s.dispose();
    }
    super.dispose();
  }

  String _newId() => 'id_${DateTime.now().millisecondsSinceEpoch}_${_sections.length}';

  void _addSection() => setState(() => _sections.add(_EditableSection(id: _newId())));

  void _removeSection(int i) => setState(() {
    _sections[i].dispose();
    _sections.removeAt(i);
  });

  void _importParsed(List<ParsedSection> parsed) {
    for (final s in _sections) {
      s.dispose();
    }
    _sections.clear();
    int seq = 0;
    for (final p in parsed) {
      final lines = p.lines.where((l) => l.lyric.trim().isNotEmpty || l.chordAtCharPos.isNotEmpty).map((pl) {
        final line = _EditableLine(id: 'line_${DateTime.now().microsecondsSinceEpoch}_${seq++}', lyric: pl.lyric);
        if (pl.hasChords) {
          // Map character positions → nearest word index.
          final words = _splitWords(pl.lyric);
          for (final entry in pl.chordAtCharPos.entries) {
            if (words.isEmpty) {
              // Instrumental: store by insertion order.
              line.chordByWordIndex[line.chordByWordIndex.length] = entry.value;
              continue;
            }
            int closest = 0;
            int minDist = (words[0].position - entry.key).abs();
            for (int i = 1; i < words.length; i++) {
              final d = (words[i].position - entry.key).abs();
              if (d < minDist) {
                minDist = d;
                closest = i;
              }
            }
            line.chordByWordIndex[closest] = entry.value;
          }
        }
        return line;
      }).toList();
      _sections.add(_EditableSection(id: 'id_${DateTime.now().millisecondsSinceEpoch}_${seq++}', name: p.name, type: p.type, lines: lines));
    }
    setState(() {});
  }

  Future<void> _showPasteSheet() async {
    final parsed = await showModalBottomSheet<List<ParsedSection>?>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const _PasteLyricsSheet());
    if (parsed == null || !mounted) return;
    if (_sections.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Replace content?'),
          content: const Text('This will replace the existing sections with the pasted song.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Replace')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    _importParsed(parsed);
    if (mounted) {
      final n = _sections.length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $n section${n == 1 ? '' : 's'}'), behavior: SnackBarBehavior.floating));
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(Icons.content_paste_rounded, size: 36, color: cs.onSurfaceVariant.withValues(alpha: 0.45)),
            const SizedBox(height: 12),
            Text('Have the lyrics ready?', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Paste the full song and sections are detected automatically.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _showPasteSheet,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: const Text('Paste Full Song'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            ),
            const SizedBox(height: 10),
            Text('— or add sections manually below —', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.45))),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      Song? existing;
      if (_isEditing) existing = ref.read(songByIdProvider(widget.songId!));
      final song = Song(
        id: widget.songId ?? 'song_${now.millisecondsSinceEpoch}',
        title: _titleCtrl.text.trim(),
        artist: _artistCtrl.text.trim(),
        key: _keyCtrl.text.trim().isEmpty ? null : _keyCtrl.text.trim(),
        bpm: int.tryParse(_bpmCtrl.text.trim()),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        sections: _sections.map((s) => s.toSongSection()).toList(),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await ref.read(songLibraryNotifierProvider.notifier).save(song);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Song' : 'New Song'),
        actions: [
          if (!_saving) IconButton(icon: const Icon(Icons.content_paste_rounded), tooltip: 'Paste full song', onPressed: _showPasteSheet),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MetadataCard(titleCtrl: _titleCtrl, artistCtrl: _artistCtrl, keyCtrl: _keyCtrl, bpmCtrl: _bpmCtrl, notesCtrl: _notesCtrl),
            ),
            const SizedBox(height: 16),
            ...List.generate(_sections.length, (i) => _SectionEditor(key: ValueKey(_sections[i].id), section: _sections[i], onRemove: () => _removeSection(i))),
            if (_sections.isEmpty) _buildEmptyState(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: OutlinedButton.icon(
                onPressed: _addSection,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Section'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _saving ? null : _save, icon: const Icon(Icons.check), label: const Text('Save Song')),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Metadata Card
// ─────────────────────────────────────────────────────────

class _MetadataCard extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController artistCtrl;
  final TextEditingController keyCtrl;
  final TextEditingController bpmCtrl;
  final TextEditingController notesCtrl;

  const _MetadataCard({required this.titleCtrl, required this.artistCtrl, required this.keyCtrl, required this.bpmCtrl, required this.notesCtrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title *', hintText: 'Song title'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: artistCtrl,
              decoration: const InputDecoration(labelText: 'Artist *', hintText: 'Artist or band'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Artist is required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: keyCtrl,
                    decoration: const InputDecoration(labelText: 'Key', hintText: 'e.g. G, Am'),
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [LengthLimitingTextInputFormatter(5)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: bpmCtrl,
                    decoration: const InputDecoration(labelText: 'BPM', hintText: 'e.g. 120'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 20 || n > 300) return '20–300';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes', hintText: 'Capo, tuning, performance notes…'),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Section editor — tinted container, subtle label, lyrics-first lines
// ─────────────────────────────────────────────────────────

class _SectionEditor extends StatefulWidget {
  final _EditableSection section;
  final VoidCallback onRemove;

  const _SectionEditor({super.key, required this.section, required this.onRemove});

  @override
  State<_SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends State<_SectionEditor> {
  int _lineSeq = 0;
  bool _typePickerExpanded = false;

  String _newLineId() => 'line_${DateTime.now().microsecondsSinceEpoch}_${_lineSeq++}';

  void _addLineAfter(int lineIdx) {
    setState(() {
      final l = _EditableLine(id: _newLineId(), autoFocus: true);
      widget.section.lines.insert(lineIdx + 1, l);
    });
  }

  void _addLineAtEnd() {
    setState(() {
      widget.section.lines.add(_EditableLine(id: _newLineId(), autoFocus: true));
    });
  }

  void _removeLine(int li) {
    setState(() {
      widget.section.lines[li].dispose();
      widget.section.lines.removeAt(li);
    });
  }

  Color _sectionTint(SectionType type, ColorScheme cs) {
    switch (type) {
      case SectionType.chorus:
        return cs.primaryContainer.withValues(alpha: 0.28);
      case SectionType.verse:
        return cs.secondaryContainer.withValues(alpha: 0.28);
      case SectionType.bridge:
        return cs.tertiaryContainer.withValues(alpha: 0.28);
      case SectionType.preChorus:
        return cs.secondaryContainer.withValues(alpha: 0.16);
      case SectionType.intro:
      case SectionType.outro:
        return cs.primaryContainer.withValues(alpha: 0.16);
      case SectionType.solo:
        return cs.tertiaryContainer.withValues(alpha: 0.22);
      default:
        return cs.surfaceContainerHighest.withValues(alpha: 0.35);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final section = widget.section;

    return Container(
      color: _sectionTint(section.type, cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hairline separates adjacent sections
          Container(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),

          // ── Section header strip ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 6, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tappable type label — expands type picker
                GestureDetector(
                  onTap: () => setState(() => _typePickerExpanded = !_typePickerExpanded),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        section.type.displayName.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6), letterSpacing: 1.4, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 2),
                      Icon(_typePickerExpanded ? Icons.expand_less : Icons.expand_more, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.45)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Editable name (e.g. "Verse 1")
                Expanded(
                  child: TextField(
                    controller: section.nameCtrl,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    decoration: InputDecoration(
                      hintText: section.type.displayName,
                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18), color: cs.error.withValues(alpha: 0.55), padding: const EdgeInsets.all(8), tooltip: 'Remove section', onPressed: widget.onRemove),
              ],
            ),
          ),

          // Collapsible type picker
          if (_typePickerExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _SectionTypePicker(
                value: section.type,
                onChanged: (t) => setState(() {
                  section.type = t;
                  _typePickerExpanded = false;
                }),
              ),
            ),

          const SizedBox(height: 4),

          // ── Lines ──────────────────────────────────────
          ...section.lines.asMap().entries.map((e) => _LyricsFirstLineWidget(key: ValueKey(e.value.id), line: e.value, onRemove: () => _removeLine(e.key), onAddLineBelow: () => _addLineAfter(e.key))),

          // Add-line button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextButton.icon(
              onPressed: _addLineAtEnd,
              icon: const Icon(Icons.add, size: 15),
              label: const Text('Add Line'),
              style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant.withValues(alpha: 0.55), textStyle: const TextStyle(fontSize: 13), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Section type chip picker
// ─────────────────────────────────────────────────────────

class _SectionTypePicker extends StatelessWidget {
  final SectionType value;
  final ValueChanged<SectionType> onChanged;

  const _SectionTypePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SectionType.values
            .map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 5),
                child: FilterChip(
                  label: Text(type.displayName, style: const TextStyle(fontSize: 11)),
                  selected: type == value,
                  onSelected: (_) => onChanged(type),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Lyrics-first line widget
// ─────────────────────────────────────────────────────────

/// Each line in the editor shows tappable chord-slot boxes above every word.
///
/// - Tap a word/empty chord box → chord picker dialog.
/// - Tap the lyric text area (or empty placeholder) → inline text field.
/// - Press Enter / Submit in the text field → create a new line below.
class _LyricsFirstLineWidget extends StatefulWidget {
  final _EditableLine line;
  final VoidCallback onRemove;
  final VoidCallback onAddLineBelow;

  const _LyricsFirstLineWidget({super.key, required this.line, required this.onRemove, required this.onAddLineBelow});

  @override
  State<_LyricsFirstLineWidget> createState() => _LyricsFirstLineWidgetState();
}

class _LyricsFirstLineWidgetState extends State<_LyricsFirstLineWidget> {
  bool _editingLyric = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Consume the one-shot autoFocus flag
    if (widget.line.autoFocus) {
      widget.line.autoFocus = false;
      _editingLyric = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _editingLyric && mounted) {
        setState(() => _editingLyric = false);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // ── Chord picker ──────────────────────────────────────

  Future<void> _pickChord(int wordIndex) async {
    final lyric = widget.line.lyricCtrl.text;
    final words = _splitWords(lyric);
    if (wordIndex >= words.length) return;
    final wordLabel = words[wordIndex].word;
    final current = widget.line.chordByWordIndex[wordIndex];
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => _ChordPickerDialog(word: wordLabel, initialChord: current),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.isEmpty) {
        widget.line.chordByWordIndex.remove(wordIndex);
      } else {
        widget.line.chordByWordIndex[wordIndex] = result;
      }
    });
  }

  // ── Lyric editing ─────────────────────────────────────

  void _startLyricEdit() {
    setState(() => _editingLyric = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onSubmitted(String _) {
    setState(() => _editingLyric = false);
    widget.onAddLineBelow();
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final lyric = widget.line.lyricCtrl.text;
    final words = _splitWords(lyric);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _editingLyric ? _buildEditField(theme, cs) : GestureDetector(onTap: _startLyricEdit, behavior: HitTestBehavior.opaque, child: _buildChordLyricView(theme, cs, lyric, words)),
          ),
          // Delete-line button
          IconButton(icon: const Icon(Icons.close, size: 16), color: cs.onSurfaceVariant.withValues(alpha: 0.35), padding: const EdgeInsets.all(8), tooltip: 'Remove line', onPressed: widget.onRemove),
        ],
      ),
    );
  }

  Widget _buildEditField(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextField(
        controller: widget.line.lyricCtrl,
        focusNode: _focusNode,
        onChanged: (_) => setState(() {}), // rebuild chord slots live
        onSubmitted: _onSubmitted,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.sentences,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Type lyrics…',
          hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.outlineVariant)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.primary)),
        ),
      ),
    );
  }

  Widget _buildChordLyricView(ThemeData theme, ColorScheme cs, String lyric, List<_WordEntry> words) {
    if (lyric.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Tap to add lyrics…',
          style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.35), fontStyle: FontStyle.italic),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 10,
        children: words.asMap().entries.map((e) {
          return _WordChordSlot(word: e.value.word, chord: widget.line.chordByWordIndex[e.key], onTap: () => _pickChord(e.key));
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Word + chord-slot widget
// ─────────────────────────────────────────────────────────

/// Renders a word with a tappable chord slot above it.
///
/// The slot shows the assigned chord (if any) in a small coloured box,
/// or a greyed-out empty box when no chord has been set.
class _WordChordSlot extends StatelessWidget {
  final String word;
  final String? chord;
  final VoidCallback onTap;

  const _WordChordSlot({required this.word, this.chord, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasChord = chord != null && chord!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chord slot box
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: hasChord ? cs.primaryContainer.withValues(alpha: 0.55) : cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: hasChord ? cs.primary.withValues(alpha: 0.5) : cs.outlineVariant.withValues(alpha: 0.45), width: 0.8),
            ),
            child: Text(
              hasChord ? chord! : '',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: hasChord ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5), letterSpacing: 0.2, fontSize: 11),
            ),
          ),
          // Word text
          Text(word, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Chord picker dialog
// ─────────────────────────────────────────────────────────

class _ChordPickerDialog extends StatefulWidget {
  final String word;
  final String? initialChord;

  const _ChordPickerDialog({required this.word, this.initialChord});

  @override
  State<_ChordPickerDialog> createState() => _ChordPickerDialogState();
}

class _ChordPickerDialogState extends State<_ChordPickerDialog> {
  late final TextEditingController _ctrl;

  static const _common = ['Am', 'C', 'D', 'Em', 'F', 'G', 'A', 'Bm', 'Dm', 'E', 'G7', 'Am7', 'Cadd9', 'D/F#', 'F#m', 'E7', 'A7', 'B7'];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialChord ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasExisting = widget.initialChord != null && widget.initialChord!.isNotEmpty;

    return AlertDialog(
      title: Text('Chord on "${widget.word}"', style: theme.textTheme.titleSmall),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            decoration: const InputDecoration(hintText: 'e.g. G, Am7, F#m', isDense: true),
            onSubmitted: (_) => Navigator.pop(context, _ctrl.text.trim()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: _common
                .map(
                  (c) => ActionChip(
                    label: Text(c, style: const TextStyle(fontSize: 12)),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _ctrl.text = c),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        if (hasExisting)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Clear'),
          ),
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: const Text('Done')),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Paste full-song sheet
// ─────────────────────────────────────────────────────────

class _PasteLyricsSheet extends StatefulWidget {
  const _PasteLyricsSheet();

  @override
  State<_PasteLyricsSheet> createState() => _PasteLyricsSheetState();
}

class _PasteLyricsSheetState extends State<_PasteLyricsSheet> {
  final _ctrl = TextEditingController();
  List<ParsedSection>? _preview;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _detect() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _preview = LyricParser.parse(text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Column(
          children: [
            // drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
            // header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
              child: Row(
                children: [
                  Text('Paste Full Song', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            // scrollable body
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // paste area
                    TextField(
                      controller: _ctrl,
                      maxLines: null,
                      minLines: 8,
                      autofocus: true,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) {
                        if (_preview != null) setState(() => _preview = null);
                      },
                      decoration: InputDecoration(
                        hintText: 'Paste your song here…\n\nLabels like [Verse 1], Chorus:, or BRIDGE are detected automatically. Without labels, repeated blocks are identified as the chorus.\n\nChords are imported automatically — stacked lines (chord line above lyric line) or inline notation like [G]word are both supported.',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 13),
                        hintMaxLines: 6,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // detect / import button
                    if (_preview == null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _detect,
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('Detect Sections'),
                          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
                        ),
                      )
                    else ...[
                      // preview list
                      Text(
                        'Detected ${_preview!.length} section${_preview!.length == 1 ? '' : 's'}',
                        style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      ..._preview!.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  s.type.displayName,
                                  style: theme.textTheme.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(s.name, style: theme.textTheme.bodyMedium)),
                              Text('${s.lines.length} line${s.lines.length == 1 ? '' : 's'}', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(onPressed: () => setState(() => _preview = null), child: const Text('Re-paste')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(onPressed: () => Navigator.pop(context, _preview), icon: const Icon(Icons.check, size: 18), label: const Text('Import Song')),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
