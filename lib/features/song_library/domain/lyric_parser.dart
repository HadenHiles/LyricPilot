import 'models/section_type.dart';

/// A single parsed section ready to be wired into editor state.
class ParsedSection {
  final String name;
  final SectionType type;

  /// Raw lyric strings; blank entries represent spacer lines.
  final List<String> lines;

  const ParsedSection({required this.name, required this.type, required this.lines});
}

/// Parses raw pasted song text into a structured list of [ParsedSection]s.
///
/// **Labeled mode** — text contains explicit section headers such as
/// `[Verse 1]`, `Chorus:`, `BRIDGE`, `(Pre-Chorus)`, etc.
/// Each header starts a new section; lines between headers are lyrics.
///
/// **Smart mode** — no recognisable headers present.
/// Lines are grouped by blank-line separators into blocks.
/// The block that appears most often (≥ 2 times) is detected as the chorus;
/// all other blocks are numbered as verses in order.
class LyricParser {
  // Matches the most common section label formats, case-insensitive.
  // Examples: [Verse 1]  (Chorus)  CHORUS  Bridge:  --- Intro ---  Pre-Chorus
  static final _headerRe = RegExp(
    r'''^\s*[-–—=*#\[(\s]*'''
    r'''(verse|chorus|hook|refrain|bridge|pre[-\s]?chorus|prechorus|'''
    r'''intro|outro|solo|instrumental|interlude|section|breakdown|tag|coda)'''
    r'''[\s\d]*[)\],:.\s\-–—=*#]*\s*$''',
    caseSensitive: false,
  );

  // ── helpers ───────────────────────────────────────────

  static SectionType _typeFromLabel(String raw) {
    final l = raw.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
    if (l.contains('chorus') || l.contains('hook') || l.contains('refrain')) {
      return SectionType.chorus;
    }
    if (l.contains('prechorus') || (l.contains('pre') && l.contains('chorus'))) {
      return SectionType.preChorus;
    }
    if (l.contains('bridge') || l.contains('breakdown')) return SectionType.bridge;
    if (l.contains('intro')) return SectionType.intro;
    if (l.contains('outro') || l.contains('coda') || l.contains('tag')) {
      return SectionType.outro;
    }
    if (l.contains('solo')) return SectionType.solo;
    if (l.contains('instrumental') || l.contains('interlude')) {
      return SectionType.instrumental;
    }
    return SectionType.verse;
  }

  /// Strips bracket/paren/colon/dash decoration and returns a clean label.
  static String _cleanLabel(String raw) {
    return raw.replaceAll(RegExp(r'^[\s\[(—–\-=*#]*'), '').replaceAll(RegExp(r'[\s\])\-—–=*#:,.]*$'), '').trim();
  }

  static bool _hasLabels(List<String> lines) => lines.any(_headerRe.hasMatch);

  static List<String> _trimBlanks(List<String> lines) {
    if (lines.isEmpty) return lines;
    int s = 0;
    while (s < lines.length && lines[s].trim().isEmpty) {
      s++;
    }
    int e = lines.length - 1;
    while (e >= s && lines[e].trim().isEmpty) {
      e--;
    }
    return lines.sublist(s, e + 1);
  }

  // ── labeled mode ──────────────────────────────────────

  static List<ParsedSection> _parseLabeledSong(List<String> lines) {
    final sections = <ParsedSection>[];
    String? currentName;
    SectionType currentType = SectionType.verse;
    final buffer = <String>[];

    void flush() {
      if (currentName == null) return;
      final trimmed = _trimBlanks(buffer);
      if (trimmed.isNotEmpty) {
        sections.add(ParsedSection(name: currentName, type: currentType, lines: List.from(trimmed)));
      }
      buffer.clear();
    }

    for (final raw in lines) {
      if (_headerRe.hasMatch(raw)) {
        flush();
        final clean = _cleanLabel(raw);
        currentName = clean.isEmpty ? 'Section' : _titleCase(clean);
        currentType = _typeFromLabel(raw);
      } else {
        buffer.add(raw.trimRight());
      }
    }
    flush();
    return sections;
  }

  // ── smart (unlabeled) mode ────────────────────────────

  static List<ParsedSection> _parseUnlabeledSong(List<String> lines) {
    // 1. Split at blank lines into blocks
    final blocks = <List<String>>[];
    var cur = <String>[];
    for (final l in lines) {
      if (l.trim().isEmpty) {
        if (cur.isNotEmpty) {
          blocks.add(List.from(cur));
          cur.clear();
        }
      } else {
        cur.add(l.trimRight());
      }
    }
    if (cur.isNotEmpty) blocks.add(cur);
    if (blocks.isEmpty) return [];

    // 2. Canonical key per block (all lines lower-cased, joined)
    String blockKey(List<String> b) => b.map((l) => l.trim().toLowerCase()).join('|');

    final keys = blocks.map(blockKey).toList();
    final counts = <String, int>{};
    for (final k in keys) {
      counts[k] = (counts[k] ?? 0) + 1;
    }

    // 3. Determine chorus key — most repeated block (count ≥ 2).
    //    On tie, shorter block wins (choruses tend to be shorter).
    String? chorusKey;
    int maxCount = 1;
    for (final e in counts.entries) {
      if (e.value > maxCount || (e.value == maxCount && chorusKey != null && e.key.length < chorusKey.length)) {
        maxCount = e.value;
        chorusKey = e.key;
      }
    }
    // A block only appears once but 2+ other blocks repeat → still no chorus.
    // Only promote to chorus if it appears ≥ 2 times.
    if (maxCount < 2) chorusKey = null;

    // 4. Assign names and types
    int verseNum = 0;
    final sections = <ParsedSection>[];
    for (int i = 0; i < blocks.length; i++) {
      final k = keys[i];
      if (k == chorusKey) {
        sections.add(ParsedSection(name: 'Chorus', type: SectionType.chorus, lines: _trimBlanks(blocks[i])));
      } else {
        verseNum++;
        sections.add(ParsedSection(name: 'Verse $verseNum', type: SectionType.verse, lines: _trimBlanks(blocks[i])));
      }
    }
    return sections;
  }

  // ── public entry point ────────────────────────────────

  /// Parse [text] into sections, auto-selecting labeled or smart strategy.
  static List<ParsedSection> parse(String text) {
    if (text.trim().isEmpty) return [];
    final lines = text.split('\n');
    return _hasLabels(lines) ? _parseLabeledSong(lines) : _parseUnlabeledSong(lines);
  }

  // ── utils ─────────────────────────────────────────────

  static String _titleCase(String s) {
    return s
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
