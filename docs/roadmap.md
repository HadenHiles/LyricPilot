# LyricPilot — Phased Roadmap

> This file is the authoritative source of truth for what has been built, what
> is in progress, and what comes next. Read it before every coding session.

---

## Current Status

**Active Phase: Phase 1 — Domain Models & Song Library UI** ✅ Complete  
**Next Phase: Phase 2 — Song CRUD & Local Persistence**

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
survives app restarts via Isar embedded database.

### Deliverables

- [ ] Add Isar + isar_flutter_libs + path_provider
- [ ] `SongRepository` interface in `domain/`
- [ ] `IsarSongRepository` implementation in `data/`
- [ ] Song create screen — title, artist, key, BPM, add sections
- [ ] Song edit screen — in-place editing of sections and lines
- [ ] Chord event editor — add/edit chords on a line
- [ ] Delete song with confirmation dialog
- [ ] Duplicate song
- [ ] Input validation — non-empty title required
- [ ] Migration strategy for future schema changes (documented)
- [ ] Seed Isar with sample songs on first launch

### Dependencies to Add

| Package | Purpose |
|---|---|
| isar | Embedded NoSQL database |
| isar_flutter_libs | Native Isar binaries |
| path_provider | Locate device file system paths |
| isar_generator (dev) | Generates Isar schema code |

**Why Isar over Hive:** Isar has a strongly-typed query API, full indexing
support, and better performance for the data access patterns we need (song list
filtering, section lookup). Hive is simpler but lacks query power.

### Out of Scope (Phase 2)

- Performance mode features (Phase 3)
- Import/export (future phase)
- Cloud backup (non-goal)

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

- [ ] Full-screen performance view — no app chrome, minimal UI
- [ ] Large lyric/chord text — configurable font size
- [ ] Section and line indicators — "Verse 2, line 3 / 4"
- [ ] Manual navigation — next line, previous line, next section, previous section
- [ ] Repeat line mode — loops current line until manually advanced
- [ ] Repeat section mode — loops current section
- [ ] Pause/resume state
- [ ] Keep screen awake while performance is active (`wakelock_plus`)
- [ ] Adjustable font size (via swipe or settings)
- [ ] Adjustable line spacing
- [ ] Auto-hide controls after inactivity
- [ ] Performance mode settings screen — font size, display density

### Dependencies to Add

| Package | Purpose |
|---|---|
| wakelock_plus | Keep screen awake during performance |

### Out of Scope (Phase 3)

- Timed auto-scroll (Phase 4)
- Audio-assisted following (Phase 5)
- Playback state machine (Phase 4 — basic state only in Phase 3)

### Exit Criteria

- Full song navigable manually without crash
- Text readable from 1–2m on a real device
- Line/section repeat works
- Screen stays awake
- `flutter analyze` passes

### Risk Notes

Low-medium risk. Screen awake APIs need platform setup.

---

## Phase 4 — Scroll Engine & Playback State Machine

**Goal:** Build a reliable, testable scroll engine and playback state machine
that can drive timed auto-scroll and that audio logic can plug into later.

### Deliverables

- [ ] `ScrollEngine` abstraction — interface for advancing position
- [ ] `PlaybackState` — full state machine (idle, playing, paused, uncertain,  
      repeating, ended)
- [ ] `ProgressState` — current section/line/chord indices + estimated tempo
- [ ] BPM-based timed auto-scroll mode
- [ ] Sensitivity controls — slower/faster auto-scroll
- [ ] Manual override — always wins over auto-scroll
- [ ] Recovery behavior — if user manually corrects, don't fight them
- [ ] Confidence-aware design — engine accepts confidence scores as input
- [ ] Scroll engine unit tests

### Out of Scope (Phase 4)

- Real audio input (Phase 5)
- Confidence scores from audio (Phase 5)
- ML-based anything (Phase 6)

### Exit Criteria

- Timed auto-scroll works at BPM-derived pace
- State machine transitions are correct and tested
- Audio layer can inject confidence scores without restructuring
- `flutter analyze` and unit tests pass

### Risk Notes

Medium risk. Scroll timing with Flutter animation system needs care.
Design the `ScrollEngine` interface so it can be driven by audio OR time OR
user input interchangeably.

---

## Phase 5 — Audio-Assisted Following MVP

**Goal:** Use the device microphone to detect playing activity and improve
auto-scroll confidence. No chord recognition. Layer 1 and Layer 2 audio only.

### Deliverables

- [ ] Microphone permission handling (iOS + Android)
- [ ] `AudioAnalyzer` interface — injectable, testable abstraction
- [ ] Layer 1: Silence vs. activity detection (RMS energy threshold)
- [ ] Layer 2: Onset/strum detection (energy burst detection)
- [ ] `AudioActivityState` — active, silent, uncertain
- [ ] Feed audio signals into `PlaybackState` as confidence adjustments
- [ ] Adaptive behavior: hold position when silent, advance when active
- [ ] Sensitivity settings — how responsive to audio cues
- [ ] Mute/disable audio following option
- [ ] Debug overlay (dev-only) — shows RMS level, onset events

### Dependencies to Add

| Package | Purpose |
|---|---|
| record | Cross-platform microphone access |
| permission_handler | Request mic permission at runtime |

### Out of Scope (Phase 5)

- Chord frequency analysis (Phase 6)
- FFT/harmonic analysis (Phase 6)
- ML model inference (non-goal unless compelling)

### Exit Criteria

- App works perfectly with audio assistance disabled
- Activity detection meaningfully improves scroll behavior in a quiet room
- Microphone permissions handled gracefully on both platforms
- `flutter analyze` passes

### Risk Notes

**HIGH RISK.** Audio on mobile has real limitations:

- iOS microphone permission is strict — must justify usage in `Info.plist`
- Latency varies across devices
- Background noise affects all simple energy detectors
- Do NOT promise reliable chord detection from this layer

If Layer 2 (onset detection) proves unreliable, keep Layer 1 (activity only)
and document the limitation clearly.

---

## Phase 6 — Progressive Intelligence

**Goal:** Improve position tracking confidence using expected chord context.
This is optional and speculative — only implement if Phase 5 results warrant it.

### Deliverables (conditional)

- [ ] FFT-based pitch/frequency analysis (via `fftea` or similar)
- [ ] Expected nearby chord comparison — match against known chord list only
- [ ] Harmonic similarity scoring — not universal recognition
- [ ] Improved recovery behavior — use chord context to detect drift
- [ ] Better confidence thresholds

### Out of Scope (Phase 6)

- Universal chord recognition
- Training custom ML models
- Band/noisy environment support

### Exit Criteria

- Measurably better position tracking compared to Phase 5
- No regressions
- Works gracefully when signals are ambiguous

### Risk Notes

**HIGH RISK.** Phase 6 is speculative. Do not start until Phase 5 is proven
in real use. If onset detection from Phase 5 is reliable enough, skip Phase 6.

---

## Phase 7 — Polish & Hardening

**Goal:** Make the app production-ready. Accessibility, error handling,
onboarding, testing, and performance.

### Deliverables

- [ ] Onboarding flow — first launch, create first song guide
- [ ] Accessibility — semantic labels, minimum touch targets, dynamic type
- [ ] Full error handling — empty states, load failures, permission denials
- [ ] Unit tests — domain models, scroll engine, state machine
- [ ] Widget tests — key screens
- [ ] Integration tests — create song → performance mode flow
- [ ] Performance profiling — frame rate in performance mode
- [ ] App icons and splash screen
- [ ] Store metadata preparation (screenshots, description)

### Exit Criteria

- 80%+ test coverage on core domain and engine logic
- Passes Flutter accessibility checks
- App icon and splash present
- Zero `flutter analyze` issues

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
