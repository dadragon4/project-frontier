# DECISIONS.md — PROJECT FRONTIER

The decision register: the user's rulings and the open questions (`Qn`). Status labels are defined in `AGENTS.md`. Read this when a label or a design question comes up; it is not needed for routine coding.

No conflicts (`Cn`) are open. What each source document said before a ruling is in git history.

## Rulings by the user

| ID | Ruling | Recorded in |
| :-- | :-- | :-- |
| C1 | Frontier is the R&D project's name, later also given to the special corp that receives the bio-enhancements. The SGA also has a normal military. | `LORE_BIBLE.md` |
| C2, C13 | The shuttle attack takes place during the uprising of the remote colonies and the arrival of Lorenz Aero. Order: the Frontier R&D project exists in secret; attack during the uprising and Lorenz's arrival; the Frontier Corp (enforcing SGA galactic law) and the SGA's rise; Aero's growth; later the Children of Aero. The push to reclaim the colonies is a present-day development. | `LORE_BIBLE.md` |
| C3 | The corrupt successor is Lorenz's nephew (unnamed), installed by Lorenz's brother after overthrowing Lorenz. Enzo Hart is Lorenz's child. | `LORE_BIBLE.md` |
| C4 | Enzo was raised in exile by Lorenz and founded the Children of Aero to regain what was his father's and bring good, peace and trust. | `LORE_BIBLE.md` |
| C5 | Children of Aero unlock at 500 rp; never shown outright; discovered through exploration first. | `GAMEPLAY.md` |
| C6 | One overall Reputation, earned from medallions, artifacts and voice logs and by naturally leveling up. It can unlock different contracts within the separate factions. Faction reputation dropped. | `GAMEPLAY.md` |
| C7 | Hacking is a mechanic and a skill, levelling with player level and use together. | `GAMEPLAY.md` |
| C8 | Weight picked up during the deployment lowers top speed and makes stamina drain a little faster. | `MOVEMENT_SPEC.md` |
| C9 | Extraction type depends on the map: several locations, faction-dependent activation, or temporary/conditional. | `EXTRACTION_SPEC.md` |
| C10 | The progression theme reads "a longer struggle for control and resources". | `GAME_DESIGN.md` |
| C11 | SEVs are officially employed with advanced gear and bio-enhancements; independent contractors have lesser gear but higher stamina and speed. | `LORE_BIBLE.md` |
| C12 | A player's own loadout does not weigh on them; equipment taken from a downed player does. Approaching maximum carry weight caps stamina at 20%. | `MOVEMENT_SPEC.md` |
| Q1 | Code in git (GitHub repo `dadragon4/project-frontier`, two developers), synced with Rojo. The place file is shared through Roblox. | `CONTRIBUTING.md` |
| Q2 | Keyboard and mouse now, on a foundation for gamepad and touch. Gamepad and touch auto-clamber by default; manual is available to them in settings. | `MOVEMENT_SPEC.md` |
| Q7 | Animations are placeholders for now. | — |
| — | Movement controls (crouch tap/hold, prone, dive, roll on Ctrl/Command, slope slides, omnidirectional sprint, slide/roll/dive separate). | `MOVEMENT_SPEC.md` |

## Open questions for Milestone 1

| ID | Topic | Decided | Still open |
| :-- | :-- | :-- | :-- |
| Q3 | Character | Custom rig, visible body, hands visible when unarmed. The prototype's standard R15 rig is a placeholder. | Who builds the custom rig. |
| Q4 | Vault and mantle input | Automatic or manual by player setting; manual uses Space and earns a small stamina refund; keyboard defaults to automatic. Obstacles under about 2 studs are steps, not vaults. | Vaulting "under". |
| Q5 | Stamina | Sprinting, sliding, diving and rolling cost it. Zero stamina slows the player, never disables movement. A heavy scavenged load drains it a little faster. | Deferred by the user: recovery and every number. See `MOVEMENT_SPEC.md`. |
| Q6 | Weight | Threshold-based: slower sprint acceleration, lower stamina regeneration, less chance for increased momentum, lower top speed. Near maximum carry weight, stamina is capped at 20%. | Threshold, maximum and penalty values; whether non-equipment items weigh anything. |

Agent's readings awaiting confirmation are marked "to confirm" in `MOVEMENT_SPEC.md` (air-roll height, roll from slide/crouch, mantle height).

## Questions for later phases

| ID | Question | Phase |
| :-- | :-- | :-- |
| Q8 | Solo fairness against squads | 4–6 |
| Q9 | PvP rules: opposing faction only? same-faction outside the squad? friendly fire? | 2–4 |
| Q10 | Rally limits and matchmaking | 6 |
| Q11 | Extraction point mechanics in detail | 4 |
| Q12 | Death details: non-weapon gear, revives, lootable drops, timer expiry | 4 |
| Q13 | Inventory capacity model; item list and masses | 4 |
| Q14 | Hacking sequence, failure, interruption, noise; whether chests and lootboxes are hacked | 3–4 |
| Q15 | Blueprint counts and crafting requirements | 5 |
| Q16 | Weapon levels and upgrades | 2–5 |
| Q17 | Health, armor, damage, recoil values | 2 |
| Q18 | Skill system scope; classes (deferred by the user) | 5 |
| Q19 | Currency, store, and the asterisk on "reputation cannot be bought" | 5 |
| Q20 | Physics-manipulation tool | 3 |
| Q21 | What "dorfic" refers to | Art |
| Q23 | Name of the enhancement initiative | Lore |
| Q25 | Map size vs duration vs population | 4 |
| Q26 | When militias are friendly or hostile | 2–4 |
| Q27 | Contract generation and rewards | 6 |
| Q28 | Hub population, matchmaking, hub-to-deployment transition | 4–6 |

Intentionally undecided, not questions: the shuttle-attack perpetrator; the origin of the universe's unusual life and resources; a name for the universe.
