import 'models/section_type.dart';

// ─────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────

/// A single line of a song after parsing: the lyric text plus a map of
/// character-position → chord symbol for any chords that were detected.
///
/// [chordAtCharPos] keys are zero-based character offsets within [lyric].
/// An empty map means no chords were encoded for this line.
class ParsedLine {
  final String lyric;
  final Map<int, String> chordAtCharPos;

  const ParsedLine({required this.lyric, this.chordAtCharPos = const {}});

  bool get hasChords => chordAtCharPos.isNotEmpty;
}

/// A parsed section ready to be wired into editor state.
class ParsedSection {
  final String name;
  final SectionType type;
  final List<ParsedLine> lines;

  const ParsedSection({required this.name, required this.type, required this.lines});
}

// ─────────────────────────────────────────────────────────
// LyricParser
// ─────────────────────────────────────────────────────────

/// Parses raw pasted song text — with or without chords — into structured
/// [ParsedSection] objects.
///
/// **Section detection**
/// *Labeled mode* — text contains explicit headers like `[Verse 1]`, `Chorus:`,
/// `BRIDGE`, `(Pre-Chorus)`, `--- Intro ---`.  Each header starts a section.
/// *Smart mode* — no headers found. Blank-line-separated blocks are compared;
/// the block appearing ≥ 2 times is promoted to chorus, others become verses.
///
/// **Chord formats handled**
/// 1. *Stacked* — a chord line (all tokens are valid chords) immediately
///    above a lyric line.  Column offsets are used to anchor each chord to
///    the correct character position in the lyric.
/// 2. *Inline brackets* — `[G]Walking down the [Am]road`.  Brackets are
///    stripped and the chord is anchored to the character that follows.
/// 3. *ChordPro* — `{chord:G}` or `{G}` inline.  Same treatment as brackets.
/// 4. *Chord-only lines* (no adjacent lyric) are kept as instrumental lines.
class LyricParser {
  // ── regexes ───────────────────────────────────────────

  /// Matches `[Verse 1]`, `Chorus:`, `BRIDGE`, `(Pre-Chorus)`, etc.
  static final _headerRe = RegExp(
    r'''^\s*[-\u2013\u2014=*#\[(\s]*'''
    r'''(verse|chorus|hook|refrain|bridge|pre[-\s]?chorus|prechorus|'''
    r'''intro|outro|solo|instrumental|interlude|section|breakdown|tag|coda)'''
    r'''[\s\d]*[)\],:.\.\s\-\u2013\u2014=*#]*\s*$''',
    caseSensitive: false,
  );

  /// Matches a single chord symbol, e.g. G, Am, F#m, Cadd9, D/F#, Bbmaj7.
  static final _chordRe = RegExp(
    r'^[A-G][#b\u266f\u266d]?'
    r'(m(?:aj)?7?|M7?|min|dim|aug|sus[24]?|add)?'
    r'\d{0,2}'
    r'(b\d|#\d|sus\d|add\d|maj\d)*'
    r'(/[A-G][#b]?)?$',
  );

  /// Inline bracket chord: `[G]`, `[Am7]`, `[F#m]`.
  static final _inlineBracketRe = RegExp(r'\[([A-G][^\]]{0,8})\]');

  /// ChordPro inline: `{chord:G}`, `{G}`.
  static final _chordProRe = RegExp(r'\{(?:chord:)?([A-G][^}]{0,8})\}', caseSensitive: false);

  // ── chord-line detection ──────────────────────────────

  /// Returns true when every non-empty token on the line is a chord symbol.
  static bool _isChordLine(String line) {
    final tokens = line.trim().split(RegExp(r'\s+'));
    if (tokens.isEmpty) return false;
    final nonEmpty = tokens.where((t) => t.isNotEmpty).toList();
    if (nonEmpty.isEmpty) return false;
    return nonEmpty.every(_chordRe.hasMatch);
  }

  /// Returns true when the line contains inline bracket or ChordPro chords.
  static bool _hasInlineChords(String line) => _inlineBracketRe.hasMatch(line) || _chordProRe.hasMatch(line);

  // ── chord extraction ──────────────────────────────────

  /// Extracts inline bracket / ChordPro chords from [line], returning a
  /// [ParsedLine] with the clean lyric and chord positions.
  static ParsedLine _extractInlineChords(String line) {
    final chords = <int, String>{};
    final buffer = StringBuffer();

    // Replace both inline formats in one pass by building a combined regex.
    final combined = RegExp(r'\[([A-G][^\]]{0,8})\]|\{(?:chord:)?([A-G][^}]{0,8})\}', caseSensitive: false);

    int offset = 0;
    for (final m in combined.allMatches(line)) {
      // Append lyric text before this chord marker.
      buffer.write(line.substring(offset, m.start));
      // The chord symbol is in group 1 (bracket) or group 2 (ChordPro).
      final symbol = (m.group(1) ?? m.group(2) ?? '').trim();
      if (_chordRe.hasMatch(symbol)) {
        chords[buffer.length] = symbol;
      }
      offset = m.end;
    }
    buffer.write(line.substring(offset));

    return ParsedLine(lyric: buffer.toString().trim(), chordAtCharPos: chords);
  }

  /// Parses chords from a dedicated chord line and maps them against the
  /// following [lyricLine] using column offsets.
  static ParsedLine _mergeChordLine(String chordLine, String lyricLine) {
    final chords = <int, String>{};
    // Walk the chord line token by token, recording each chord's column.
    for (final m in RegExp(r'\S+').allMatches(chordLine)) {
      final token = m.group(0)!;
      if (!_chordRe.hasMatch(token)) continue;
      // Map chord column → lyric character position (clamped).
      final col = m.start;
      final pos = col.clamp(0, lyricLine.length);
      chords[pos] = token;
    }
    return ParsedLine(lyric: lyricLine.trim(), chordAtCharPos: chords);
  }

  // ── raw-line → ParsedLine pipeline ───────────────────

  /// Converts a list of raw text lines (within one section buffer) into
  /// [ParsedLine] objects, handling stacked, inline, and plain formats.
  static List<ParsedLine> _cookLines(List<String> raw) {
    final result = <ParsedLine>[];
    int i = 0;
    while (i < raw.length) {
      final line = raw[i];

      // Blank spacer
      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // Stacked format: chord line immediately followed by lyric line
      if (_isChordLine(line)) {
        final next = (i + 1 < raw.length) ? raw[i + 1] : '';
        if (next.isNotEmpty && !_isChordLine(next) && !_headerRe.hasMatch(next)) {
          result.add(_mergeChordLine(line, next));
          i += 2;
        } else {
          // Chord-only / instrumental line — no lyric follows.
          final chords = <int, String>{};
          int col = 0;
          for (final m in RegExp(r'\S+').allMatches(line)) {
            final t = m.group(0)!;
            if (_chordRe.hasMatch(t)) {
              chords[col++] = t;
            }
          }
          // Store as lyric-empty line (instrumental).
          result.add(ParsedLine(lyric: '', chordAtCharPos: chords));
          i++;
        }
        continue;
      }

      // Inline bracket / ChordPro
      if (_hasInlineChords(line)) {
        result.add(_extractInlineChords(line));
        i++;
        continue;
      }

      // Plain lyric — no chords
      result.add(ParsedLine(lyric: line.trim()));
      i++;
    }
    return result;
  }

  // ── section-type helpers ──────────────────────────────

  static SectionType _typeFromLabel(String raw) {
    final l = raw.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
    if (l.contains('chorus') || l.contains('hook') || l.contains('refrain')) {
      return SectionType.chorus;
    }
    if (l.contains('prechorus') || (l.contains('pre') && l.contains('chorus'))) {
      return SectionType.preChorus;
    }
    if (l.contains('bridge') || l.contains('breakdown')) {
      return SectionType.bridge;
    }
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

  static String _cleanLabel(String raw) {
    return raw.replaceAll(RegExp(r'^[\s\[(\u2014\u2013\-=*#]*'), '').replaceAll(RegExp(r'[\s\])\-\u2014\u2013=*#:,.]*$'), '').trim();
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
        sections.add(ParsedSection(name: currentName, type: currentType, lines: _cookLines(trimmed)));
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

    // Canonical key uses only the lyric text (chord lines stripped) so that
    // repeated chorus blocks with different notation still match.
    String blockKey(List<String> b) {
      return b
          .where((l) => !_isChordLine(l))
          .map((l) {
            // Strip inline chords for key comparison.
            return l.replaceAll(_inlineBracketRe, '').replaceAll(_chordProRe, '').trim().toLowerCase();
          })
          .where((l) => l.isNotEmpty)
          .join('|');
    }

    final keys = blocks.map(blockKey).toList();
    final counts = <String, int>{};
    for (final k in keys) {
      counts[k] = (counts[k] ?? 0) + 1;
    }

    String? chorusKey;
    int maxCount = 1;
    for (final e in counts.entries) {
      if (e.value > maxCount || (e.value == maxCount && chorusKey != null && e.key.length < chorusKey.length)) {
        maxCount = e.value;
        chorusKey = e.key;
      }
    }
    if (maxCount < 2) chorusKey = null;

    int verseNum = 0;
    final sections = <ParsedSection>[];
    for (int i = 0; i < blocks.length; i++) {
      final k = keys[i];
      final cookedLines = _cookLines(blocks[i]);
      if (k == chorusKey) {
        sections.add(ParsedSection(name: 'Chorus', type: SectionType.chorus, lines: cookedLines));
      } else {
        verseNum++;
        sections.add(ParsedSection(name: 'Verse $verseNum', type: SectionType.verse, lines: cookedLines));
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
