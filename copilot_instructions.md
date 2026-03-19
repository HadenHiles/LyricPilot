# LyricPilot — Copilot Instructions

> This file is the persistent guidance contract for all GitHub Copilot sessions
> working in this repository. Read it before making any changes.

---

## 1. Project Summary

**LyricPilot** is a mobile app for musicians — primarily amateur guitarists — that
displays lyrics and chords in a large, readable performance view and follows the
player's pace in a hands-free way.

It is a **smart lyric/chord teleprompter for known songs**, not a chord
recognition engine. The user loads or creates a song ahead of time. The app
helps display and navigate it during practice or casual performance.

Target platform: **iOS and Android** (Flutter).  
Current phase: see `docs/roadmap.md`.

---

## 2. Product Principles

These rules govern every feature, architecture, and UX decision:

1. Do NOT build this as a magical AI app.
2. Do NOT promise exact chord detection from a phone microphone.
3. Assume the expected song structure and expected chords are known ahead of time.
4. The system **estimates** where the player is in the song — it does not identify
   arbitrary chords from the universe.
5. When confidence is low, **hold position** instead of jumping.
6. The user must always be able to **manually correct** playback position.
7. Optimize the MVP for solo acoustic guitar in a relatively quiet room.
8. Use **graceful fallback behavior** everywhere.
9. The app must be **useful even before audio logic exists**.
10. Prioritize a shippable MVP over speculative DSP/ML complexity.

---

## 3. MVP Definition

The MVP is:

> A musician can create or load a song with lyrics, chords, and sections, open a
> readable performance mode, move through the song without touching the phone much,
> use manual controls and repeat tools, and optionally benefit from simple
> microphone-based activity detection that improves scrolling behavior.

**MVP is NOT**: chord recognition, perfect transcription, band rehearsal support,
cloud sync, or ML-based analysis.

---

## 4. Tech Stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter 3.x | Dart, Material 3 |
| State | flutter_riverpod | Provider pattern, AsyncNotifier for async |
| Navigation | go_router | Typed routes preferred in Phase 2+ |
| Models | Plain Dart (Phase 0–1), Freezed (Phase 1+) | Immutable, copyWith |
| Persistence | JSON files via path_provider (Phase 2+) | One file per song; `SongRepository` abstraction allows swapping |
| Typography | google_fonts (Inter) | Readable at distance |
| Code gen | build_runner + freezed + riverpod_generator | Phase 1+ only |

Do not add dependencies without justifying them here and in the PR/commit.

---

## 5. Architecture

```
lib/
  app/            # Root widget, router, theme, app-level providers
  core/           # Constants, extensions, utilities — no feature logic
  features/       # One folder per product feature
    song_library/ # Song CRUD, domain models, library UI
    performance/  # Full-screen display, scroll engine
    settings/     # User preferences
    audio/        # (Phase 5+) Microphone abstraction and analysis
  shared/         # Reusable widgets and helpers used across features
```

Inside each feature:
```
features/<name>/
  domain/         # Models, enums, pure business logic — no Flutter imports
  data/           # Repositories, data sources, sample data
  presentation/   # Screens, widgets, Riverpod providers
```

### Rules

- `domain/` must not import Flutter or Riverpod — pure Dart only.
- Keep `presentation/` focused on widgets and providers.
- Repositories live in `data/` and are injected via Riverpod.
- No god classes. Files should have a single clear responsibility.
- Shared widgets go in `shared/widgets/`. Do not inline reusable widgets.

---

## 6. Domain Model

Core entities (all immutable):

| Entity | Location | Purpose |
|---|---|---|
| `Song` | song_library/domain | Root entity — title, artist, key, bpm, sections |
| `SongSection` | song_library/domain | Named part of song (Verse, Chorus, etc.) |
| `SongLine` | song_library/domain | One lyric line with zero or more chord events |
| `ChordEvent` | song_library/domain | Chord name + character position in lyric |
| `SectionType` | song_library/domain | Enum: intro, verse, chorus, bridge, etc. |
| `PlaybackSession` | performance/domain | (Phase 3) Active play state |
| `ProgressState` | performance/domain | (Phase 4) Scroll/position tracking |
| `AudioActivityState` | audio/domain | (Phase 5) Microphone signal state |
| `UserSettings` | settings/domain | (Phase 3) Font size, scroll speed, etc. |

When adding new fields to a model, add them with a default value so existing
serialized data (Phase 2+) won't break.

---

## 7. State Management Rules

- Use `Provider` for static/derived data (e.g., song list from memory).
- Use `StateProvider` for simple mutable state (e.g., themeMode).
- Use `StateNotifier` / `AsyncNotifier` for complex mutable state.
- Use `riverpod_generator` (`@riverpod` annotation) starting Phase 1.
- Keep providers in `presentation/providers/` inside their feature folder.
- App-level providers (theme, router) live in `lib/app/`.

---

## 8. Coding Standards

1. Build incrementally in small, reviewable steps.
2. Prefer compile-safe code over ambitious but fragile code.
3. Keep files focused — aim for under 200 lines; refactor when they grow too large.
4. Prefer clear code over clever code. Dartdoc only where it adds real value.
5. Use `const` constructors wherever possible.
6. Use named parameters for models and widgets with more than 2 parameters.
7. Avoid deeply nested widget trees — extract into named widget classes.
8. If something is stubbed, mark it: `// TODO(phase-N): implement ...`
9. Do NOT invent fake working audio logic. Stub audio cleanly.
10. Do NOT silently add dependencies. Justify every pub addition.
11. Do NOT rewrite unrelated files unless necessary for the change.
12. Strong typing — avoid `dynamic` and untyped `List`/`Map`.
13. All models implement `copyWith`. No mutable fields on domain objects.

---

## 9. UI/UX Guidelines

- Material 3 everywhere. Use `Theme.of(context)` color roles, not hardcoded colors.
- Dark mode is the **primary** design target. Test light mode too.
- Seed color: warm amber (`0xFFE8A838`) — musician-friendly warmth.
- Font: `google_fonts` Inter (body), consider a monospace font for chord display.
- Performance mode must be readable from 1–2 meters away.
- Minimum tap targets: 48×48 dp. No tiny buttons during performance.
- Navigation pattern: library → song detail → performance mode.
- Always provide a clear way back. Never strand the user.
- Avoid decorative UI elements that slow down practice setup.

---

## 10. Audio Feature Constraints

Audio must be built in layers — do NOT skip ahead:

| Layer | Description | Phase |
|---|---|---|
| 1 | Silence vs. activity detection | 5 |
| 2 | Onset / strum detection (energy burst) | 5 |
| 3 | Confidence-based adaptive scrolling | 5–6 |
| 4 | Expected nearby harmonic comparison | 6 (if justified) |

Rules:
- Audio is ONE signal among several (time elapsed, user behavior, structure).
- Design audio as a **swappable interface** (`AudioAnalyzer` abstraction).
- When uncertain, hold position. Never jump forward speculatively.
- Do not assume ML or advanced DSP until Phase 6 and only if clearly beneficial.
- The app must work perfectly with audio completely disabled.

---

## 11. File Organization Rules

- One class/widget per file (with small private helpers allowed in the same file).
- File names: `snake_case.dart` matching the primary class.
- Barrel files (`index.dart`) are optional — use them only if they reduce clutter.
- Test files mirror `lib/` structure under `test/`.
- Documentation goes in `docs/`. Never delete `docs/roadmap.md`.
- This file (`copilot_instructions.md`) must be updated when the architecture changes.

---

## 12. Workflow for Future Changes

For every coding session:

1. Read `docs/roadmap.md` to know the current phase and what's in scope.
2. Read this file to confirm architectural rules.
3. Make changes in small, logical steps.
4. Do not add features from a future phase in the current session.
5. Mark stubs clearly with `// TODO(phase-N):`.
6. After changes: check `flutter analyze` passes.
7. Update `copilot_instructions.md` or `docs/roadmap.md` if architecture changes.

---

## 13. What NOT to Build Yet

Until explicitly approved, do NOT implement:

- Cloud backend or API integration
- User accounts or authentication
- Social features (sharing, reviews, collaboration)
- Advanced ML-based chord recognition
- Complex DSP signal processing
- Universal chord recognition for unknown songs
- Noisy band environment support
- Web or desktop platform support
- Fret/fingering detection
- MIDI integration
- Import from external services (Spotify, Ultimate Guitar, etc.)

---

## 14. Definition of Done Per Phase

A phase is complete when:

1. All deliverables in `docs/roadmap.md` are implemented.
2. `flutter analyze` reports zero issues.
3. The app runs on a real device or simulator without crashes.
4. Stubbed items are labeled `// TODO(phase-N):` and tracked in the roadmap.
5. No regressions in previously completed phases.
6. `copilot_instructions.md` and `docs/roadmap.md` are updated if needed.

---

## 15. Current Phase Status

See `docs/roadmap.md` for the authoritative phase tracking.

> Last updated: Phase 2 — Song CRUD & Local Persistence complete.
