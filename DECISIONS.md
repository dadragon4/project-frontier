# DECISIONS.md — PROJECT FRONTIER

The decision register: the user's rulings, open conflicts (`Cn`) and open questions (`Qn`). Status labels are defined in `AGENTS.md`. Read this when a label or a design question comes up; it is not needed for routine coding.

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

### Questions for Milestone 1

| ID | Topic | Decided | Still open |
| :-- | :-- | :-- | :-- |
| Q1 | Workflow | Code in git (private GitHub repo, shared with a second developer), synced with Rojo. The place file is shared through Roblox. | — |
| Q2 | Devices | Keyboard and mouse now, on a foundation for gamepad and touch. Gamepad and touch auto-clamber. | May gamepad and touch players opt into manual? |
| Q3 | Character | Custom rig, visible body, hands visible when unarmed. The prototype uses a standard R15 rig. | Who builds the custom rig. |
| Q4 | Vault and mantle input | Automatic or manual by player setting; manual uses Space and earns a small stamina refund; keyboard defaults to automatic. | Vaulting "under"; the lowest vault height (see `TASKS.md`). |
| Q5 | Stamina | A heavy scavenged load drains stamina a little faster; at zero, movement is moderately inhibited, not disabled. | Deferred by the user: which actions cost stamina, recovery, what zero stamina does concretely. |
| Q6 | Weight | Threshold-based: slower sprint acceleration, lower stamina regeneration, less chance for increased momentum, lower top speed. Own loadout does not count (C12). Near maximum carry weight, stamina is capped at 20% of maximum. | Threshold, maximum and penalty values; whether non-equipment items weigh anything. |
| Q7 | Animations | Placeholders for now. | — |

### Questions for later phases

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

### Original conflict record (history: what each source said before the rulings)

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
