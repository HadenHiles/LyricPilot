import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/chord_event.dart';
import '../../domain/models/section_type.dart';
import '../../domain/models/song.dart';
import '../../domain/models/song_line.dart';
import '../../domain/models/song_section.dart';
import '../providers/song_library_provider.dart';

// ─────────────────────────────────────────────────────────
// Editor state helpers (local, not domain models)
// ─────────────────────────────────────────────────────────

class _EditableLine {
  final String id;
  final TextEditingController lyricCtrl;
  final TextEditingController chordsCtrl;

  _EditableLine({required this.id, String lyric = '', String chords = ''}) : lyricCtrl = TextEditingController(text: lyric), chordsCtrl = TextEditingController(text: chords);

  void dispose() {
    lyricCtrl.dispose();
    chordsCtrl.dispose();
  }

  SongLine toSongLine() {
    final lyric = lyricCtrl.text.trim();
    final names = chordsCtrl.text.trim().split(RegExp(r'\s+')).where((c) => c.isNotEmpty).toList();
    return SongLine(id: id, lyric: lyric, chords: _buildChords(names, lyric));
  }

  static List<ChordEvent> _buildChords(List<String> names, String lyric) {
    if (names.isEmpty) return [];
    if (lyric.isEmpty) return names.map((n) => ChordEvent(chord: n)).toList();
    final step = lyric.length / names.length;
    return names.asMap().entries.map((e) => ChordEvent(chord: e.value, position: (e.key * step).round().clamp(0, lyric.length))).toList();
  }
}

class _EditableSection {
  final String id;
  final TextEditingController nameCtrl;
  SectionType type;
  final List<_EditableLine> lines;
  bool isExpanded = true;

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

/// Creates or edits a song.
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
      _sections.add(
        _EditableSection(
          id: section.id,
          name: section.name,
          type: section.type,
          lines: section.lines.map((line) {
            final chordStr = line.chords.map((c) => c.chord).join(' ');
            return _EditableLine(id: line.id, lyric: line.lyric, chords: chordStr);
          }).toList(),
        ),
      );
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
  String _newLineId(int si) => 'line_${DateTime.now().microsecondsSinceEpoch}_$si';

  void _addSection() => setState(() => _sections.add(_EditableSection(id: _newId())));

  void _removeSection(int i) => setState(() {
    _sections[i].dispose();
    _sections.removeAt(i);
  });

  void _addLine(int si) => setState(() => _sections[si].lines.add(_EditableLine(id: _newLineId(si))));

  void _removeLine(int si, int li) => setState(() {
    _sections[si].lines[li].dispose();
    _sections[si].lines.removeAt(li);
  });

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Song' : 'New Song'),
        actions: [
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _MetadataCard(titleCtrl: _titleCtrl, artistCtrl: _artistCtrl, keyCtrl: _keyCtrl, bpmCtrl: _bpmCtrl, notesCtrl: _notesCtrl),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Sections', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(onPressed: _addSection, icon: const Icon(Icons.add, size: 18), label: const Text('Add Section')),
              ],
            ),
            if (_sections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No sections yet.\nTap "Add Section" to start building your song.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ...List.generate(_sections.length, (i) => _SectionEditor(key: ValueKey(_sections[i].id), section: _sections[i], onRemove: () => _removeSection(i), onAddLine: () => _addLine(i), onRemoveLine: (li) => _removeLine(i, li), onStructureChanged: () => setState(() {}))),
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
// Section editor
// ─────────────────────────────────────────────────────────

class _SectionEditor extends StatefulWidget {
  final _EditableSection section;
  final VoidCallback onRemove;
  final VoidCallback onAddLine;
  final void Function(int li) onRemoveLine;
  final VoidCallback onStructureChanged;

  const _SectionEditor({super.key, required this.section, required this.onRemove, required this.onAddLine, required this.onRemoveLine, required this.onStructureChanged});

  @override
  State<_SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends State<_SectionEditor> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final section = widget.section;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: section.nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Section name',
                      hintText: section.type.displayName,
                      isDense: true,
                      border: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary)),
                    ),
                  ),
                ),
                IconButton(icon: Icon(section.isExpanded ? Icons.expand_less : Icons.expand_more), onPressed: () => setState(() => section.isExpanded = !section.isExpanded)),
                IconButton(icon: const Icon(Icons.delete_outline), color: colorScheme.error, tooltip: 'Remove section', onPressed: widget.onRemove),
              ],
            ),
          ),
          // Type chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _SectionTypePicker(value: section.type, onChanged: (t) => setState(() => section.type = t)),
          ),
          if (section.isExpanded) ...[
            const Divider(height: 1),
            ...section.lines.asMap().entries.map((e) => _LineEditor(key: ValueKey(e.value.id), line: e.value, onRemove: () => widget.onRemoveLine(e.key))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: OutlinedButton.icon(
                onPressed: widget.onAddLine,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Line'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
              ),
            ),
          ],
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
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(type.displayName, style: const TextStyle(fontSize: 12)),
                  selected: type == value,
                  onSelected: (_) => onChanged(type),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Line editor — lyric text + chord text
// ─────────────────────────────────────────────────────────

class _LineEditor extends StatelessWidget {
  final _EditableLine line;
  final VoidCallback onRemove;

  const _LineEditor({super.key, required this.line, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: line.chordsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Chords',
                    hintText: 'G Am F C',
                    isDense: true,
                    prefixIcon: Icon(Icons.music_note, size: 16, color: colorScheme.primary),
                  ),
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: line.lyricCtrl,
                  decoration: const InputDecoration(labelText: 'Lyric', hintText: 'Type lyric, or leave blank for chord-only line', isDense: true),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close, size: 18), color: colorScheme.error, tooltip: 'Remove line', onPressed: onRemove),
        ],
      ),
    );
  }
}
