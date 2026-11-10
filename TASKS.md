# TASKS.md — PROJECT FRONTIER

Status labels are defined in `AGENTS.md`.

## Current state (2026-11-10)

- Initial review complete. Documentation set written: `AGENTS.md`, `GAME_DESIGN.md`, `LORE_BIBLE.md`, `GAMEPLAY.md`, `MOVEMENT_SPEC.md`, `EXTRACTION_SPEC.md`, `TECHNICAL_ARCHITECTURE.md`, `TASKS.md`.
- No code exists. A place file, `Project Frontier.rbxl`, is now in the project folder (contents not yet inspected).
- The Roblox Studio MCP server is registered for this folder; it loads in new sessions.
- User answered the M1 questions on 2026-11-10 (see register). Workflow: git with a private GitHub repository, shared with a second developer.
- Docs are in a private GitHub repository, `dadragon4/project-frontier`. The place file is not in the repository.
- User ruled on C1–C9, C11 and C12 on 2026-11-10 and approved starting Milestone 1.
- M1.1 code is written under `src/` but **has not been run**: this session had no Studio connection and no Luau tooling, so it has not even been syntax-checked by a tool.
- **Next:** install Rojo, sync into Studio, run and fix M1.1, tune with the user; then M1.2.
- **Waiting on the user:** C10 and C13 (neither blocks Milestone 1).
- **Next:** in a new session (so the Studio connection loads), M1.0 setup.

Still to write, when their phase approaches: `COMBAT_SPEC.md`, `WORLD_DESIGN.md`, `UI_AUDIO_GUIDE.md`, `ASSET_GUIDE.md`.

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

## Milestone 1 — Movement prototype [Approved by the user 2026-11-10]

Split into four slices so there is something playable and testable after each. "Written" means the code exists; a box is only ticked once it has been run and checked in Studio.

### M1.0 Setup
- [x] Workflow decided; git and private GitHub repo; Rojo project file.
- [ ] Install Rojo (and the Studio plugin); first sync.
- [ ] Greybox movement test course with measured obstacles — written (built by code at server start).
- [ ] Time-boxed comparison of controller options A and B — not done; M1.1 is built on option A.

### M1.1 Core locomotion
- [ ] Input module (actions mapped to keys) — written.
- [ ] First-person camera — written.
- [ ] Movement state machine skeleton + configuration module — written.
- [ ] Walk and sprint with acceleration and deceleration — written.
- [ ] Crouch — written.
- [ ] Slide with momentum carry — written.
- [ ] On-screen debug readout (state, speed) — written.

### M1.2 Obstacle traversal — *needs Q4*
- [ ] Obstacle and ledge detection.
- [ ] Manual vault.
- [ ] Mantle.
- [ ] Ledge grab.

### M1.3 Advanced traversal and resources — *needs Q5, Q6/C8*
- [ ] Wall-run.
- [ ] Slide transitions (slide → vault and others).
- [ ] Stamina with momentum discount.
- [ ] Weight modifier, driven by a hand-set test value.

### M1.4 Hardening and presentation — *needs Q7*
- [ ] Server plausibility checks (after checking Roblox's built-in server-authority status).
- [ ] Two-client multiplayer test.
- [ ] Basic traversal animations and camera polish.
- [ ] Tuning pass with the user; update `MOVEMENT_SPEC.md` with agreed values.

Out of scope for M1: inventory, factions, weapons, AI, persistence, UI beyond the debug readout.

## Decision register

### Rulings by the user, 2026-11-10

| ID | Ruling | Recorded in |
| :-- | :-- | :-- |
| C1 | Frontier is the R&D project's name, later also given to the special corp that receives the bio-enhancements. The SGA also has a normal military. | `LORE_BIBLE.md` |
| C2 | The Frontier Corp followed the aftermath of the shuttle attack, enforcing SGA galactic law. Aero and the Children of Aero formed hundreds of years later. | `LORE_BIBLE.md` |
| C3 | The corrupt successor is Lorenz's nephew (unnamed), installed by Lorenz's brother after overthrowing Lorenz. Enzo Hart is Lorenz's child. | `LORE_BIBLE.md` |
| C4 | Enzo was raised in exile by Lorenz and founded the Children of Aero to regain what was his father's and bring good, peace and trust. | `LORE_BIBLE.md` |
| C5 | Children of Aero unlock at 500 rp; never shown outright; discovered through exploration first. | `GAMEPLAY.md` |
| C6 | One overall Reputation, earned from medallions, artifacts and voice logs. Faction reputation dropped. | `GAMEPLAY.md` |
| C7 | Hacking is a mechanic and a skill, levelling with player level and use together. | `GAMEPLAY.md` |
| C9 | Extraction type depends on the map: several locations, faction-dependent activation, or temporary/conditional. | `EXTRACTION_SPEC.md` |
| C11 | SEVs are officially employed with advanced gear and bio-enhancements; independent contractors have lesser gear but higher stamina and speed. | `LORE_BIBLE.md` |
| C12 | A player's own loadout does not weigh on them; equipment taken from a downed player does. Approaching maximum carry weight caps stamina at 20%. | `MOVEMENT_SPEC.md` |

### Still open

| ID | Topic |
| :-- | :-- |
| C10 | "Struggle for control and hope" (concept doc) or "controlled hope" (master prompt)? Wording only. |
| C13 | Timeline order: the attack is centuries before Aero, yet blame for it brings down Lorenz; and where the Frontier project sits relative to the attack. See `LORE_BIBLE.md`. |

Also ruled 2026-11-10: weight lowers top speed (C8); reputation is also earned by naturally leveling up and can unlock different contracts within the separate factions; the place file is shared with the second developer through Roblox, the code through the GitHub repo (Q1).

Deferred by the user: classes; detailed stamina rules (including what zero stamina does). Still unasked: whether chests and lootboxes are hacked.

### Original conflict record (for history)

| ID | Topic | Concept doc | Master prompt | Blocks |
| :-- | :-- | :-- | :-- | :-- |
| C1 | What "Frontier" names | An SGA R&D **project known as Frontier**; redirected to military use; "the Frontier Corp becomes its boots-on-the-ground task force" | Frontier Corp is separate from the R&D initiative, whose official name is not yet established | Lore |
| C2 | How the Frontier Corp formed | Timeline: established after the shuttle attack. Story section: emerges from the Frontier project | Consolidation of multiple armies | Lore |
| C3 | Who is Lorenz's nephew | The **corrupt successor** is "a nephew of Lorenz"; Enzo's relation is unstated | **Enzo Hart** is the nephew; the successor's relation is unstated | Lore |
| C4 | Enzo's claim | "The rightful heir" and also "believing himself to be the true heir" | "Is believed to be the true heir" | Lore |
| C5 | Unlocking the Children of Aero | 500 rp; rp from artifacts and natural levelling | Gradually uncovered through discovery; no threshold | Phase 6 |
| C6 | Reputation structure | One "Reputation/Rank" track (cosmetics, Children of Aero) and also "faction reputation" | "Faction reputation" only | Phase 5–6 |
| C7 | Hacking skill and scope | Hacking levels up with use; applies to strongholds, chests/lootboxes, etc. | Not mentioned; QTE hacking is for strongholds; skill system undefined | Phase 3–5 |
| C8 | What weight affects | Acceleration, slide distance, stamina consumption, climbing | Also "movement speed"; stamina interaction "not finalized" | **M1.3** — partly resolved 2026-11-10: weight raises stamina drain slightly. Top speed still open. |
| C12 | Does the deployed loadout count toward weight | No (both original sources) | User, 2026-11-10: "equipment (weapons, special grenades, grenades)" have weight values — unclear whether that includes the loadout | **M1.3** |
| C9 | Status of extraction mechanics | Listed as the mechanics (multiple points, faction-dependent activation, temporary/conditional) | "Potential design directions" | Phase 4 |
| C10 | Progression theme wording | "a longer struggle for control and hope" | "controlled hope" | Wording |
| C11 | SEV employment | "Independent scavengers and contractors" | Officially employed by Aero; some independent | Lore |

### Open questions

**Blocking Milestone 1**

| ID | Question | Status (2026-11-10) |
| :-- | :-- | :-- |
| Q1 | Workflow | **Decided:** git with a private GitHub repo; a second developer will collaborate. **Open:** how the two developers share the place file (maps, models) — Roblox Team Create is the agent's recommendation, with code in git via Rojo. |
| Q2 | Devices | **Decided:** keyboard and mouse now, on a foundation for gamepad and touch. Gamepad and touch auto-clamber. |
| Q3 | Character | **Decided:** custom rig, visible body, hands visible when unarmed. Prototype uses a standard R15 rig. **Open:** who builds the custom rig. |
| Q4 | Vault and mantle input | **Decided:** auto or manual by player setting; manual has a dedicated key and earns a stamina boost. The boost is a small stamina refund; keyboard defaults to automatic. **Open:** vaulting "under". |
| Q5 | Stamina | **Decided:** heavy scavenged load drains stamina a little faster; at zero, movement is moderately inhibited. "Slowed down aggressively but still leaving 20% of max stamina" (reading to confirm: a 20% reserve). **Open:** which actions cost stamina, whether sprinting does, recovery. |
| Q6 | Weight | **Decided:** threshold-based; at or over the threshold: slower sprint acceleration, lower stamina regeneration, less chance for increased momentum. Top speed unaffected (agent's reading). Inventory is loadout plus extra slots. **Open:** threshold values; C12. |
| Q7 | Animations | **Decided:** placeholders for now. |

**Later phases**

| ID | Question | Phase |
| :-- | :-- | :-- |
| Q8 | Solo fairness against squads | 4–6 |
| Q9 | PvP rules: opposing faction only? same-faction outside the squad? friendly fire? | 2–4 |
| Q10 | Rally limits and matchmaking | 6 |
| Q11 | Extraction point mechanics in detail | 4 |
| Q12 | Death details: non-weapon gear, revives, lootable drops, timer expiry | 4 |
| Q13 | Inventory capacity model; item list and masses | 4 |
| Q14 | Hacking sequence, failure, interruption, noise | 3–4 |
| Q15 | Blueprint counts and crafting requirements | 5 |
| Q16 | Weapon levels and upgrades | 2–5 |
| Q17 | Health, armor, damage, recoil values | 2 |
| Q18 | Skill system scope | 5 |
| Q19 | Currency, store, and the asterisk on "reputation cannot be bought" | 5 |
| Q20 | Physics-manipulation tool | 3 |
| Q21 | What "dorfic" refers to | Art |
| Q23 | Name of the enhancement initiative | Lore |
| Q25 | Map size vs duration vs population | 4 |
| Q26 | When militias are friendly or hostile | 2–4 |
| Q27 | Contract generation and rewards | 6 |
| Q28 | Hub population, matchmaking, hub-to-deployment transition | 4–6 |

Intentionally undecided, not questions: the shuttle-attack perpetrator; the origin of the universe's unusual life and resources; a name for the universe.

## Known blockers

- No Roblox tooling installed and no workflow chosen (Q1).
- The agent cannot judge movement *feel*; tuning needs the user playing the test course.
