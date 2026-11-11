# TASKS.md — PROJECT FRONTIER

Current state and the active checklist only. Decisions, conflicts (`Cn`) and questions (`Qn`) are in `DECISIONS.md`. History is in git.

## Current state (2026-11-10)

- Milestone 1 (movement prototype) is in progress. Walk, sprint, crouch, slide, roll, quick turn, vault, mantle, ledge grab, wall-run, slide-hop, camera feel and a settings panel are built.
- 18 scripted checks pass in Studio (`python3 tools/studio.py test`). Nobody has judged feel or looks yet; every number in `MovementConfig` is an untuned first guess.
- Code is in the private GitHub repo `dadragon4/project-frontier`; the place file is shared through Roblox and is not in git.
- **Next:** the user plays the test course and tunes; then stamina and weight (M1.3), which need the user's deferred stamina rules.
- **Waiting on the user:** C10, C13 (neither blocks Milestone 1); the lowest vault height (below).

## Roadmap [Established]

| Phase | Target | Goal |
| :-- | :-- | :-- |
| 1 | Movement prototype | Movement is enjoyable before anything else is added |
| 2 | Combat prototype | A small but satisfying combat system: weapons, damage, basic AI |
| 3 | Physics prototype | The environment meaningfully contributes to gameplay |
| 4 | Vertical slice | First complete extraction deployment |
| 5 | Persistence and progression | Deployments feed long-term progress |
| 6 | Faction and social systems | Hubs, hideouts, squads, factions, reputation, contracts |
| 7 | World and narrative expansion | More maps, lore, enemies, seasonal story |

Specs still to write when their phase approaches: `COMBAT_SPEC.md`, `WORLD_DESIGN.md`, `UI_AUDIO_GUIDE.md`, `ASSET_GUIDE.md`.

## Milestone 1 — Movement prototype [Approved by the user 2026-11-10]

A box is ticked only once the item has been run and checked in Studio. What exactly was tested is in `MOVEMENT_SPEC.md` → "Implementation status".

### M1.0 Setup
- [x] Git, private GitHub repo, Rojo 7.7.1 and its Studio plugin, live sync.
- [x] Greybox test course, built by code at server start.
- [x] Scripted movement tests, run with one command.
- [ ] Time-boxed comparison of controller options A and B — skipped; everything is built on option A.

### M1.1 Core locomotion
- [x] Input module with input buffering; state machine; configuration module; debug readout.
- [x] Walk, sprint, crouch, jump (buffered and coyote).
- [ ] First-person camera — runs; visible body not yet checked by eye.
- [x] Slide — works on flat ground; slopes and steering untested.

### M1.2 Obstacle traversal
- [x] Vault, mantle, ledge grab (pull-up, drop, shimmy), automatic and manual (Space).
- [x] Roll (air and ground) and quick turn (`R`).
- [x] Decide: raise the lowest vault height to ~2 studs? (Roblox's character steps over anything lower.)

### M1.3 Advanced traversal and resources
- [x] Wall-run and wall jump; slide transitions; slide-hop.
- [x] Camera feel and the reduce-camera-motion setting (settings panel on `P`, not saved yet).
- [ ] Stamina with momentum discount — needs Q5.
- [ ] Weight modifier, driven by a hand-set test value — needs Q6 values.

### M1.4 Hardening and presentation
- [ ] Server plausibility checks (first check Roblox's built-in server-authority status).
- [ ] Two-client multiplayer test.
- [ ] Basic traversal animations and camera polish.
- [ ] Tuning pass with the user; record agreed values in `MOVEMENT_SPEC.md`.

Out of scope for M1: inventory, factions, weapons, AI, persistence, UI beyond the debug readout and settings panel.

## Known limits

- The agent cannot judge movement feel or how things look; that needs the user playing the test course.
- The Command key as crouch on macOS is untested (see `MOVEMENT_SPEC.md`).
