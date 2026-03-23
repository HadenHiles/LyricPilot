# LyricPilot — GitHub Copilot Instructions

This file is automatically read by VS Code GitHub Copilot for every session in
this workspace. For the full architecture reference, read `copilot_instructions.md`
at the project root. For the phased roadmap, read `docs/roadmap.md`.

---

## What This App Is

**LyricPilot** — a practice tool for musicians (primarily guitarists) to master
songs through structured repetition, tempo control, and progressive independence.
The goal: help users internalize chord changes and lyrics so they can eventually
**"ditch the phone"** and play from memory.

This is NOT a chord recognition app or a performance teleprompter.
The song structure is known in advance. We're building tools for **learning and mastery**.

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
- Local persistence = JSON files via `path_provider` (Phase 2+). `SongRepository` abstraction — no hardcoded storage backend.
- Audio = optional validation layer starting Phase 7. Never fake working audio.

---

## Coding Rules (Short Form)

1. Small, reviewable steps only.
2. Mark stubs: `// TODO(phase-N): description`.
3. No dynamic typing. No god classes. No deeply nested widgets.
4. `flutter analyze` must pass after every change.
5. Do NOT add dependencies without justifying them in `pubspec.yaml` comments.
6. Do NOT build features from future phases without explicit approval.
7. Do NOT implement: cloud, auth, ML chord recognition, social features.
   Exception: ChordMini API is approved for lyrics import (Phase 3+) — see section 13 of `copilot_instructions.md`.

---

## ChordMini API (Approved — Phase 3+)

- Docs: https://www.chordmini.me/docs
- No auth required (yet). Handle future `401`/`403` gracefully.
- Use `/api/lrclib-lyrics` and `/api/genius-lyrics` (10 req/min each) for song import.
- Chord/beat analysis (`/api/recognize-chords`, `/api/detect-beats`) = Phase 6+ only.
- **Rate limit rules (mandatory):** debounce search 600 ms; enforce 7-second client-side cooldown between lyrics calls; disable button while in-flight; never auto-retry on 429; import one song at a time; warn after 10 imports per session.
- Base URL lives in `AppConstants.chordMiniBaseUrl`. Never hardcode elsewhere.

---

## Audio Constraints

Build audio in layers: (1) silence/activity → (2) onset detection →
(3) confidence-based scrolling → (4) harmonic similarity (only if justified).
When uncertain, hold position. Audio is one signal, not the only signal.

---

## Full Reference

→ `copilot_instructions.md` (architecture, domain model, workflow)  
→ `docs/roadmap.md` (phases, deliverables, exit criteria)
