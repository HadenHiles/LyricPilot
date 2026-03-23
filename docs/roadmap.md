# LyricPilot — Phased Roadmap

> This file is the authoritative source of truth for what has been built, what
> is in progress, and what comes next. Read it before every coding session.

---

## What This App Is

**LyricPilot** is a practice tool for musicians (primarily guitarists) to master songs
through structured repetition, tempo control, and progressive independence. The goal is
to help users internalize chord changes and lyrics so they can eventually **"ditch the phone"**
and play from memory.

This is NOT a performance teleprompter or a chord transcription tool. It's a **practice companion** 
for songs you already know (or are learning), with tools to loop, slow down, and gradually 
reduce scaffolding as you build mastery.

---

## Current Status

**Active Phase: Phase 4 — Scroll Engine & Playback State Machine** ✅ Complete  
**Performance View: Karaoke UX + smooth animation + welcome overlay** ✅ Complete  
**Audio Scaffolding: AudioAnalyzer interface + NullAudioAnalyzer stub** ✅ Complete  
**Next Phase: Phase 5 — Practice Enhancements (Loop Counts, Tempo Tap, Section Focus)**

---

## Roadmap Strategy Shift (March 2026)

Vision updated from **performance teleprompter** → **practice/mastery tool**.  
Audio-assisted following (previously Phase 5) is now **Phase 7** (lower priority).  
New Phases 5-6 focus on **repetition, tempo tools, and progressive independence**.

---

## Phase 0 — Foundation & Repo Guidance

**Goal:** Establish architecture, documentation, project skeleton, and a
navigable app shell with sample data. Nothing is persisted. No audio. No CRUD.

### Deliverables

- [x] `copilot_instructions.md` — persistent Copilot guidance
- [x] `.github/copilot-instructions.md` — VS Code Copilot auto-loaded instructions
- [x] `docs/roadmap.md` — this file
- [x] Dependency selection documented in `pubspec.yaml` comments
- [x] Flutter project scaffolded (`flutter create`)
- [x] Material 3 theme — dark/light, warm amber seed color
- [x] GoRouter — routes for library, song detail, performance, settings
- [x] App entry point (`main.dart` → `ProviderScope` → `LyricPilotApp`)
- [x] Song library screen — lists in-memory sample songs
- [x] Song detail screen — displays sections and chord/lyric lines
- [x] Performance screen — placeholder (Phase 3 stub)
- [x] Settings screen — placeholder with theme toggle
- [x] Domain models — `Song`, `SongSection`, `SongLine`, `ChordEvent`, `SectionType`
- [x] Sample songs — 3 fictional songs with realistic chord/lyric data
- [x] In-memory Riverpod providers for song library

### Dependencies Added

| Package | Version | Purpose |
|---|---|---|
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Provider annotations (used Phase 1+) |
| go_router | ^14.6.3 | Declarative navigation |
| google_fonts | ^6.2.1 | Typography — Inter font |

### Out of Scope (Phase 0)

- Local persistence (Isar/Hive) — Phase 2
- Song creation/editing — Phase 2
- Real performance mode — Phase 3
- Scroll engine — Phase 4
- Audio — Phase 5
- Code generation (freezed, build_runner) — Phase 1

### Exit Criteria

- `flutter analyze` passes with zero issues ✅
- App launches on simulator/device ✅
- All screens reachable via navigation ✅
- Sample songs visible in library ✅

---

## Phase 1 — Domain Modeling & Song Library UI

**Goal:** Harden the domain model with Freezed, build a polished song library
screen, and implement proper song detail view with all sections and chords
rendered correctly.

### Deliverables

- [x] Add Freezed + build_runner + riverpod_generator
- [x] Migrate domain models to `@freezed` — Song, SongSection, SongLine, ChordEvent
- [x] Migrate providers to `@riverpod` annotation style
- [x] Song library screen — search/filter by title/artist, empty states
- [x] Song detail screen — full chord/lyric rendering with section headers
- [x] `ChordLyricLine` widget — inline and stacked chord display modes
- [x] App branding — logo in AppBar, adaptive launcher icon from `assets/icon.png`
- [x] `UserSettings` domain model stub (font size, scroll, audio preferences)
- [x] `AppLogo` shared widget (theme-matched color filter)

### Dependencies to Add

| Package | Purpose |
|---|---|
| freezed_annotation | Immutable model codegen annotations |
| json_annotation | JSON serialization annotations |
| freezed (dev) | Code generator for Freezed |
| json_serializable (dev) | JSON serialization code generator |
| build_runner (dev) | Runs code generators |
| riverpod_generator (dev) | Generates Riverpod providers from annotations |

### Out of Scope (Phase 1)

- Creating or editing songs (Phase 2)
- Local persistence (Phase 2)
- Performance mode features (Phase 3)

### Exit Criteria

- All models are Freezed with `copyWith`, equality, and `toString` ✅
- `flutter analyze` passes ✅
- Song detail shows all sections legibly with inline chord markers ✅
- Search bar filters by title and artist in real time ✅
- No regressions from Phase 0 ✅

### Risk Notes

Low risk. Freezed codegen is well-established in Flutter ecosystem.

---

## Phase 2 — Song CRUD & Local Persistence

**Goal:** Let musicians create, edit, duplicate, and delete songs. All data
survives app restarts via JSON file storage on the device.

### Architecture Note — JSON files instead of Isar

Isar 3.x stagnated (no meaningful releases since late 2023). For a song library
of the expected size (~100 songs max) and data access patterns (simple CRUD,
no complex queries), per-song JSON files on the device file system are simpler,
more testable, and more maintainable. The `SongRepository` abstraction
means the storage backend can be swapped later without touching any UI code.

### Deliverables

- [x] Add `json_annotation`, `path_provider` dependencies; `json_serializable` dev dep
- [x] JSON serialization added to all Freezed models (`fromJson` / `.g.dart`)
- [x] `SongRepository` abstract interface in `domain/repositories/`
- [x] `JsonFileSongRepository` in `data/repositories/` — one JSON file per song
- [x] `songRepositoryProvider` — injectable, overridable in tests
- [x] `SongLibraryNotifier` — `AsyncNotifier` backed by the repository
- [x] Seed repository with `sampleSongs` on first launch (empty check)
- [x] `SongEditorScreen` — create and edit a song's metadata, sections, and lines
- [x] Inline section editor — name, type picker, reorder/delete sections
- [x] Inline line editor — lyric text + space-separated chord names per line
- [x] Chord positions auto-distributed evenly across the lyric on save
- [x] Input validation — title and artist required, BPM range 20–300
- [x] Delete song with confirmation dialog (from song detail overflow menu)
- [x] Duplicate song (from song detail overflow menu)
- [x] Edit song navigates to `/song/:id/edit`; create navigates to `/song/new`
- [x] Library FAB now navigates to create screen
- [x] Library screen handles async loading / error states

### Dependencies Added

| Package | Version | Purpose |
|---|---|---|
| json_annotation | ^4.9.0 | JSON serialization annotations |
| path_provider | ^2.1.5 | Locate device file system paths |
| json_serializable (dev) | ^6.9.0 | JSON code generation |

### Out of Scope (Phase 2)

- Per-character chord position editing (Phase 3 enhancement)
- Import/export (future phase)
- Cloud backup (non-goal)

### Exit Criteria

- [x] Songs persist across app restarts
- [x] CRUD operations all work and `flutter analyze` passes with zero issues
- [x] Empty state handled gracefully on first launch (seeded with sample songs)
- [x] Existing Phase 0–1 UI remains functional

### Exit Criteria

- Songs persist across app restarts
- CRUD operations all work and `flutter analyze` passes
- Empty state handled gracefully on first launch
- Existing Phase 0–1 UI remains functional

### Risk Notes

Medium risk. Isar schema migrations need care. Plan schema carefully before
writing migration code.

---

## Phase 3 — Performance Mode MVP

**Goal:** A musician can open a song and use it during practice or performance
from a readable, clutter-free full-screen view with manual navigation and
repeat tools.

### Deliverables

- [x] Full-screen performance view — no app chrome, minimal UI
- [x] Large lyric/chord text — configurable font size
- [x] Section and line indicators — "Verse 2, line 3 / 4"
- [x] Manual navigation — next line, previous line, next section, previous section
- [x] Repeat line mode — loops current line until manually advanced
- [x] Repeat section mode — loops current section
- [x] Keep screen awake while performance is active (`wakelock_plus`)
- [x] Adjustable font size (via performance settings sheet)
- [x] Adjustable line spacing (via performance settings sheet)
- [x] Auto-hide controls after inactivity (4-second timer, tap to toggle)
- [x] Performance mode settings sheet — font size slider, line spacing slider
- [x] `PerformanceState` domain model — pure Dart, no Flutter imports
- [x] `PerformanceNotifier` — Riverpod `@riverpod` family notifier (keyed by songId)
- [x] Context lines — 1 dimmed line above + 2 dimmed lines below current line
- [x] Immersive full-screen mode (`SystemUiMode.immersiveSticky`); restored on exit
- [x] Karaoke-style scrolling — `_LinesView` replaced with smooth-scrolling `ListView`
- [x] Active line anchored at ~25 % from top; player can always read ahead
- [x] Graduated opacity + font scale across context lines (active 100 % → far history 10 %)
- [x] Upcoming line (+1) keeps elevated chord tint — "this chord is coming up"
- [x] Active line: left primary-colour accent bar + translucent background pill
- [x] All inactive lines carry matching indent so text columns stay aligned
- [x] `AnimatedOpacity` (280 ms, `easeInOut`) smooth fade as active line advances
- [x] `ChordLyricLine` `activeChordIndex` parameter — active chord gets a pill highlight
- [x] `chordIndex` field on `PerformanceState`; all nav methods reset/propagate it
- [x] Smooth animation: `TweenAnimationBuilder<double>` per line item — active line "snaps into focus" by animating font size, not jumping
- [x] All animated properties (opacity, scale, pill, accent bar) share 380 ms `easeInOutCubic` timing so they move together
- [x] Scroll to active line now uses 520 ms `easeInOutQuart` for a more polished feel
- [x] Welcome overlay on first entry: gradient card explaining controls (fades out 600 ms on first interaction)
- [x] Initial controls auto-hide extended to 10 s (vs. 4 s) on first entry; resets to 4 s after interaction

### Dependencies Added

| Package | Version | Purpose |
|---|---|---|
| wakelock_plus | ^1.3.4 | Keep screen awake during performance |

### Out of Scope (Phase 3)

- Timed auto-scroll (Phase 4)
- Audio-assisted following (Phase 5)
- Playback state machine (Phase 4 — basic state only in Phase 3)

### Exit Criteria

- [x] Full song navigable manually without crash
- [x] Text readable from 1–2m on a real device
- [x] Line/section repeat works
- [x] Screen stays awake
- [x] `flutter analyze` passes

### Risk Notes

Low-medium risk. Screen awake APIs need platform setup.

---

## Phase 4 — Scroll Engine & Playback State Machine

**Goal:** Build a reliable, testable scroll engine and playback state machine
that can drive timed auto-scroll and that audio logic can plug into later.

### Deliverables

- [x] `ScrollEngine` abstract interface — injectable, testable, driven by time OR audio
- [x] `PlaybackState` model — full lifecycle enum (idle, playing, paused, uncertain, repeating, ended), confidence score, tempo multiplier
- [x] `ProgressState` model — current section/line/chord indices + estimated BPM
- [x] `TimedScrollEngine` (BPM-based) — advance interval = (beatsPerLine / bpm) × 60s / multiplier
- [x] Sensitivity controls — `fasterScroll` / `slowerScroll` (±0.25× steps, clamped 0.25–4.0×)
- [x] Manual override — `manualNextLine/PrevLine/JumpTo` cancel running timer and restart from new position; always win over engine
- [x] Recovery behavior — `manualJumpTo` resets engine to user's corrected position and resumes
- [x] Confidence-aware design — `updateConfidence(score)` API on `PerformanceNotifier`; accepted by engine via `updatePlaybackState`
- [x] Extend `PerformanceState` to carry `PlaybackState`; convenience getters `isPlaying`, `playbackStatus`
- [x] Wire `PerformanceNotifier` to `TimedScrollEngine`; engine disposed via `ref.onDispose`
- [x] Play / Pause / Stop / Toggle controls in `PerformanceScreen` footer
- [x] Speed label (±0.25× buttons, current multiplier display) in footer
- [x] End-of-song detection — status transitions to `ended`, engine pauses
- [x] Scroll engine unit tests — 14 tests covering advance, retreat, wrap, end-hold, timing, pause, multiplier

### Dependencies Added

None (pure Dart; `dart:async` `Timer` only).

### Out of Scope (Phase 4)

- Real audio input (Phase 5)
- Confidence scores from audio (Phase 5)
- ML-based anything (Phase 6)

### Exit Criteria

- [x] Timed auto-scroll works at BPM-derived pace
- [x] State machine transitions are correct and tested
- [x] Audio layer can inject confidence scores without restructuring (`updateConfidence`)
- [x] `flutter analyze` and unit tests pass (14/14)

### Risk Notes

Medium risk. Scroll timing with Flutter animation system needs care.
Design the `ScrollEngine` interface so it can be driven by audio OR time OR
user input interchangeably.

---

## Phase 5 — Practice Enhancements

**Goal:** Make practicing specific sections and challenging transitions effortless.
Add tools that support deliberate, focused practice sessions.

### Deliverables

- [ ] **Tempo tap button** — tap 4-8 times to auto-detect/refine song BPM; updates scroll engine in real-time
- [ ] **Section loop toggle** — simple "Loop Section" button; highlights current section, loops it until toggled off
- [ ] **Loop counter display** — show "Loop 3" (incrementing) when section/line repeat is active
- [ ] **Playback speed presets** — quick-tap buttons for 0.5×, 0.75×, 1×, 1.25× (complement existing ±0.25 fine control)
- [ ] **Quick restart FAB** — jump to song start + reset speed to 1× in one tap
- [ ] **Practice session indicators** — subtle visual marks on sections practiced this session (e.g., checkmark badge)

### Dependencies to Add

None (pure Dart logic + UI state extensions).

### Out of Scope (Phase 5)

- Transpose/capo support (players know shapes; display is just a reminder)
- Configurable loop count targets (incrementing counter is simpler)
- Count-in clicks (Phase 9+ if needed)
- Visual metronome (Phase 9+ if needed)
- Audio metronome (Phase 9+)
- Practice analytics dashboard (Phase 8)
- Chord/lyric hiding (Phase 6)

### Exit Criteria

- User can tap tempo to quickly set BPM for a new song (accurate within ±3 BPM for 40–200 BPM range)
- User can toggle section loop on/off mid-practice without losing position
- Loop counter increments correctly and resets when loop is disabled
- Speed presets switch instantly without playback hiccups
- `flutter analyze` passes

### Risk Notes

Low risk. Tempo tap needs debouncing and outlier rejection. Section loop is a simple state toggle.

---

## Phase 6 — Progressive Mastery Tools

**Goal:** Help users gradually reduce dependence on the app by progressively hiding
scaffolding (chords, lyrics) and testing recall. The ultimate goal is memorization.

### Deliverables

- [ ] **Chord hiding modes:**
  - Hide all chords (lyrics only)
  - Show only first chord of each line (prompt for the rest)
  - Show chords on tap/hold only (test recall)
- [ ] **Lyric hiding modes:**
  - Hide lyrics, show only chords (for instrumental focus)
  - Show first word of each line only (prompt for the rest)
  - Completely blank (full memory test — advance manually)
- [ ] **Memory test mode** — blank screen, user plays from memory, taps to reveal current position
- [ ] **Progressive reveal** — start song with everything hidden, reveal on tap as needed
- [ ] **Difficulty presets** — "Full Support" / "Partial Prompts" / "Memory Test"
- [ ] **Mastery indicators** — per-song flag: "Needs Practice" / "Comfortable" / "Mastered"
- [ ] **ChordPro import** — parse `.cho` / `.chopro` / `.txt` files in ChordPro format (huge existing library)
- [ ] **Export to ChordPro** — save songs in portable text format

### Dependencies to Add

None (all Flutter UI + domain logic).

### Out of Scope (Phase 6)

- Automated mastery scoring (Phase 8 — track practice metrics first)
- Spaced repetition scheduling (future)

### Exit Criteria

- User can successfully practice a song with full lyrics → partial prompts → memory test
- ChordPro import correctly parses 95% of standard ChordPro files (test with real-world corpus)
- Mastery flags persist and are visible in song library
- `flutter analyze` passes

### Risk Notes

Low-medium risk. ChordPro parsing needs robust handling of edge cases and malformed files.

---

## Phase 7 — Audio-Assisted Following (Optional Enhancement)

**Goal:** Use the device microphone to detect playing activity and validate practice
pacing. This is **validation feedback**, not control. The user drives the flow;
audio confirms they're on track.

⚠️ **This phase is now OPTIONAL.** If manual practice tools (Phases 5-6) prove
sufficient, audio can be deferred indefinitely. Only build if user testing shows
clear demand for audio validation.

### Deliverables

- [ ] Microphone permission handling (iOS + Android)
- [ ] `AudioAnalyzer` interface — injectable, testable abstraction (**scaffolded** in `domain/audio_analyzer.dart`)
- [ ] `AudioActivityState` enum: `unavailable`, `silent`, `uncertain`, `active` (**scaffolded** in `domain/audio_activity_state.dart`)
- [ ] `NullAudioAnalyzer` no-op stub (**scaffolded** in `data/null_audio_analyzer.dart`)
- [ ] `audioAnalyzerProvider` (Provider<AudioAnalyzer>) (**stubbed** in `presentation/providers/audio_analyzer_provider.dart`)
- [ ] Layer 1: Silence vs. activity detection (RMS energy threshold)
- [ ] Layer 2: Onset/strum detection (energy burst detection)
- [ ] Feed audio signals into `PlaybackState` via `PerformanceNotifier.updateConfidence()` (entry point already wired)
- [ ] Adaptive behavior: **pause auto-advance when silent** (player is thinking/reviewing)
- [ ] Sensitivity settings — how responsive to audio cues
- [ ] Mute/disable audio following option
- [ ] Debug overlay (dev-only) — shows RMS level, onset events

### Dependencies to Add

| Package | Purpose |
|---|---|
| record | Cross-platform microphone access |
| permission_handler | Request mic permission at runtime |

### Out of Scope (Phase 7)

- Chord frequency analysis (Phase 8)
- FFT/harmonic analysis (Phase 8)
- ML model inference (non-goal unless compelling)
- Using audio to **drive** scrolling (audio is validation only, not control)

### Exit Criteria

- App works perfectly with audio assistance disabled (not a regression)
- Activity detection provides useful "you seem stuck" feedback during practice
- Microphone permissions handled gracefully on both platforms
- `flutter analyze` passes

### Risk Notes

**HIGH RISK.** Audio on mobile has real limitations:

- iOS microphone permission is strict — must justify usage in `Info.plist`
- Latency varies across devices
- Background noise affects all simple energy detectors
- **In practice context, audio is less critical** than in performance — user can manually drive

If Phase 7 is built and Layer 2 (onset detection) proves unreliable, keep Layer 1 
(activity only) and document the limitation clearly. Or skip this phase entirely.

---

## Phase 8 — Practice Analytics & Intelligence

**Goal:** Track practice sessions over time and help users identify weak sections.
Provide data-driven feedback on mastery progress.

### Deliverables

- [ ] **Session tracking** — log each practice session (date, duration, tempo used, sections practiced)
- [ ] **Section practice counters** — track how many times each section has been practiced lifetime
- [ ] **Weak section detection** — flag sections that are repeatedly looped or played at slow tempo
- [ ] **Mastery scoring** — auto-suggest mastery level based on practice patterns (e.g., "played 10× at full speed without pausing")
- [ ] **Practice history view** — calendar/list of past sessions per song
- [ ] **Suggested next practice** — "You haven't practiced the bridge in 5 days"
- [ ] **Progress visualization** — simple charts showing improvement over time
- [ ] **(Optional) FFT-based pitch analysis** — if Phase 7 audio is implemented, add expected chord comparison
  - Match detected harmonics against known chord list only
  - Provide confidence score: "You seem to be playing the right chord"
  - Help detect consistent early/late changes

### Dependencies to Add

| Package | Purpose (if FFT is added) |
|---|---|
| fftea | FFT library for Dart (optional) |

### Out of Scope (Phase 8)

- Universal chord recognition (non-goal)
- Training custom ML models (non-goal)
- Social features / sharing practice stats (future)
- Spaced repetition scheduling (future)

### Exit Criteria

- User can see "You've practiced this song 12 times over 3 weeks"
- Weak sections are correctly identified and surfaced
- Practice history survives app restarts (persisted with song data)
- `flutter analyze` passes

### Risk Notes

Medium risk. Balancing useful feedback vs. overwhelming users with data. Keep metrics
simple and actionable. FFT analysis (if implemented) carries same risks as Phase 7.

---

## Phase 9 — Polish & Hardening

**Goal:** Make the app production-ready. Accessibility, error handling,
onboarding, testing, and performance.

### Deliverables

- [ ] **Practice-focused onboarding** — first launch guide emphasizing loops, tempo, and mastery goals
- [ ] **"Quick start" tutorial** — shows how to load a song, loop a section, slow it down, hide chords
- [ ] Accessibility — semantic labels, minimum touch targets, dynamic type, screen reader support
- [ ] Full error handling — empty states, load failures, permission denials, corrupt song files
- [ ] Unit tests — domain models, scroll engine, state machine, tempo tap algorithm
- [ ] Widget tests — key screens (library, editor, practice mode)
- [ ] Integration tests — create song → practice mode → mastery flow
- [ ] Performance profiling — frame rate in practice mode, memory usage
- [ ] App icons and splash screen
- [ ] Store metadata preparation (screenshots, description emphasizing **practice tool**, not performance tool)
- [ ] Audio metronome (optional) — click track during practice (if Phase 7 audio is skipped)
- [ ] Export/share songs as PDF or ChordPro for backup
- [ ] **(Future consideration) Transpose/Capo support** — if user research shows demand for viewing chords in different keys

### Exit Criteria

- 80%+ test coverage on core domain and engine logic
- Passes Flutter accessibility checks (WCAG AA minimum)
- App icon and splash present
- Zero `flutter analyze` issues
- App store listing clearly communicates **practice/mastery value proposition**

---

## Dependency Register

Track all dependencies here as they are added.

| Package | Phase Added | Purpose | Location |
|---|---|---|---|
| flutter_riverpod | 0 | State management | lib/ |
| riverpod_annotation | 0 | Provider annotations | lib/ |
| go_router | 0 | Routing | lib/ |
| google_fonts | 0 | Typography | lib/ |
| freezed_annotation | 1 | Immutable models | lib/ |
| json_annotation | 1 | JSON serialization | lib/ |
| freezed | 1 | Code gen (dev) | — |
| json_serializable | 1 | Code gen (dev) | — |
| build_runner | 1 | Code gen runner (dev) | — |
| riverpod_generator | 1 | Provider codegen (dev) | — |
| isar | 2 | Local persistence | lib/ |
| isar_flutter_libs | 2 | Native Isar libs | lib/ |
| path_provider | 2 | File paths | lib/ |
| isar_generator | 2 | Isar schema gen (dev) | — |
| wakelock_plus | 3 | Screen awake | lib/ |
| record | 5 | Microphone access | lib/ |
| permission_handler | 5 | Runtime permissions | lib/ |
