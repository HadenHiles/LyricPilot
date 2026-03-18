# LyricPilot — GitHub Copilot Instructions

This file is automatically read by VS Code GitHub Copilot for every session in
this workspace. For the full architecture reference, read `copilot_instructions.md`
at the project root. For the phased roadmap, read `docs/roadmap.md`.

---

## What This App Is

**LyricPilot** — a smart lyric/chord teleprompter for musicians (primarily
acoustic guitarists). The user loads a known song; the app displays lyrics and
chords in a large readable performance view and helps the player navigate
hands-free.

This is NOT a chord recognition app. The song structure is known in advance.

---

## Current Phase

Check `docs/roadmap.md` section "Current Status" before starting any work.

---

## Key Architecture Rules

- Flutter + Dart, Material 3, Riverpod, GoRouter.
- Folder layout: `lib/app/`, `lib/core/`, `lib/features/`, `lib/shared/`.
- Each feature has `domain/`, `data/`, `presentation/` sub-folders.
- `domain/` = pure Dart, no Flutter imports.
- Models are immutable with `copyWith`. Use `const` constructors.
- Providers live in `presentation/providers/` inside their feature.
- Local persistence = Isar (Phase 2+). No backend, no cloud.
- Audio = layered abstraction starting Phase 5. Never fake working audio.

---

## Coding Rules (Short Form)

1. Small, reviewable steps only.
2. Mark stubs: `// TODO(phase-N): description`.
3. No dynamic typing. No god classes. No deeply nested widgets.
4. `flutter analyze` must pass after every change.
5. Do NOT add dependencies without justifying them in `pubspec.yaml` comments.
6. Do NOT build features from future phases without explicit approval.
7. Do NOT implement: cloud, auth, ML chord recognition, social features.

---

## Audio Constraints

Build audio in layers: (1) silence/activity → (2) onset detection →
(3) confidence-based scrolling → (4) harmonic similarity (only if justified).
When uncertain, hold position. Audio is one signal, not the only signal.

---

## Full Reference

→ `copilot_instructions.md` (architecture, domain model, workflow)  
→ `docs/roadmap.md` (phases, deliverables, exit criteria)
