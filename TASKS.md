# TASKS.md — PROJECT FRONTIER

Current state and the active checklist only. Decisions, conflicts (`Cn`) and questions (`Qn`) are in `DECISIONS.md`. History is in git.

## Current state (2026-11-11)

- Milestone 1 (movement prototype) is nearly complete. Every planned ability is built; what is left is listed below.
- 38 scripted checks pass in Studio (`python3 tools/studio.py test`). The user has tuned the core speeds; looks have not been checked by eye, and the full tuning pass is still to come.
- Code is in the GitHub repo `dadragon4/project-frontier`; the place file is shared through Roblox and is not in git.
- **Next:** the user plays the test course and tunes; then stamina and weight.
- **Waiting on the user:** stamina recovery and values (Q5); weight values (Q6).

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

**Done:** project setup, test course and scripted tests; input, state machine, config, debug readout; walk, omnidirectional sprint, crouch, prone, slide (flat and slope), slide-hop, dive, jump, roll, quick turn; vault, mantle, ledge grab (automatic and manual); wall-run and wall jump; camera feel, reduce-camera-motion and the settings panel (`P`, not saved yet).

**Left:**

- [ ] Stamina: sprint, slide, dive and roll cost it, momentum discounts it, zero stamina slows the player — needs recovery and values (Q5).
- [ ] Weight modifier (lowers top speed), driven by a hand-set test value — needs Q6 values.
- [ ] Check by eye: the visible first-person body, head bob (including strafe bob), roll camera, landing dip.
- [ ] Server plausibility checks (first check Roblox's built-in server-authority status).
- [ ] Two-client multiplayer test.
- [ ] Basic traversal animations and camera polish; lay the prone body flat (waits for the custom rig).
- [ ] Tuning pass with the user.

Out of scope for M1: inventory, factions, weapons, AI, persistence, UI beyond the debug readout and settings panel.

## Known limits

- The agent cannot judge movement feel or how things look; that needs the user playing the test course.