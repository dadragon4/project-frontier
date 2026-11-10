# EXTRACTION_SPEC.md — PROJECT FRONTIER

Status labels are defined in `AGENTS.md`. Register entries (`Cn`, `Qn`) are in `TASKS.md`. This system is built in Phase 4; nothing here is implemented.

## Deployment structure [Established]

1. Prepare at the safe colony / social hub.
2. Select: faction, mission, map, loadout, solo or squad.
3. Enter an instanced deployment (first-person PvPvE): scavenge, fight, explore.
4. Extract and debrief: keep recovered goods, process mission results, gain progress (XP, unlocks).
5. Return to the hub.

## Match specification [Established]

| Property | Design |
| :-- | :-- |
| Squad size | 1–5 (the limit applies per squad) |
| Solo, co-op, PvP, PvE | All supported |
| Short deployment | 10–15 minutes |
| Long deployment | 15–30 minutes |
| Hub perspective | Third-person |
| Deployment perspective | First-person |

Players explicitly choose short or long. Some locations may have a predetermined duration.

**[Open] [Q25]** How map design, duration and total instance population relate.

## Squad rules [Established]

- Solo, duo, small group or full five.
- Same faction only. Different factions cannot squad or rally together.
- Several same-faction squads may rally against larger threats.
- Solo players should not be automatically overwhelmed by coordinated five-player squads.

**[Open]** Rally limits and matchmaking (**[Q10]**); how solo fairness is achieved — matchmaking, population limits, alternative objectives (**[Q8]**); PvP rules, including whether same-faction players outside your squad can be attacked (**[Q9]**).

## Objectives [Established]

Recover loot; collect intelligence; complete dynamic contracts and special story objectives; recover weapons; discover hidden locations; access high-value strongholds (via hacking); extract before dying.

## Inventory, loot and weight [Established]

- Weight is the total mass of items collected during the deployment. The deployed loadout is excluded.
- Weight feeds the movement system (`MOVEMENT_SPEC.md`).
- Recoverable items include resources, intelligence, equipment, weapons and artifacts. Scarce resources are concentrated in strongholds, abandoned facilities and contested installations.
- The concept doc lists **limited inventory capacity**.

**[Established — user decision 2026-11-10]** The inventory is **slot-based**: it holds the deployed loadout plus extra empty slots, which players fill with quest items, resources, blueprints, other weapons and so on. Equipment has assigned weight values, and crossing a weight threshold inhibits movement (`MOVEMENT_SPEC.md`).

**[Established — ruling 2026-11-10, settles C12]** A player's own deployed loadout has weight values but they have no effect on that player. If Player B downs (kills) Player A and takes their equipment, those weight values activate and count against Player B. There is a maximum weight a player is allowed to carry; approaching it limits stamina to 20% of the player's maximum.

**[Open] [Q13]** Number of extra slots; item list and weight values; loot spawning rules. Blueprints are named here as something picked up — how that fits with "recovering multiple examples of a weapon unlocks its blueprint" needs confirming (**[Q15]**).

## Extraction mechanics

The concept doc lists these as the extraction mechanics:

- Multiple extraction points.
- Activation requirements that depend on faction.
- Temporary and conditional extractions.
- Limited inventory capacity.
- Recoverable intelligence and equipment.
- Risk of losing carried equipment and loot on death.
- Successful extraction contributes to long-term progression.

**[Established — ruling 2026-11-10, settles C9]** The extraction type depends on the map (planet). At exfil a map uses one of:

- **several different locations** to exfiltrate from;
- a **faction-dependent activation sequence** and exfiltration;
- a **temporary / conditional extraction**, prompted by time running out or by all quest items being collected.

**[Open] [Q11]** The details of each type.

## Death [Established]

On death the player loses:

- the weapons equipped for that deployment,
- the loot collected during that deployment.

The player keeps their faction's default weapons, so a bad deployment never locks them out.

**[Open] [Q12]** Non-weapon gear carried in; whether teammates can revive; whether other players can loot what a dead player dropped; what happens when the deployment timer ends with players still inside.

## Equipment retention [Established]

- A successfully extracted weapon — including another faction's — goes to the player's stash at the safe colony.
- Multiple recovered examples unlock a blueprint; blueprints allow indefinite crafting subject to later requirements (**[Q15]**).
- Already-extracted, stashed equipment is distinct from equipment currently carried into a deployment. Taking a stashed weapon into a deployment puts it at risk; leaving it in the stash does not.
- Permanent progression, blueprints and unlocks are stored separately from temporary deployment inventory.

## Data boundary [Established]

| Permanent player data | Temporary deployment data |
| :-- | :-- |
| Faction progression, XP, reputation, unlocks, blueprints, hideout customization, stash | Current loadout, loot collected, mission state, deployment-specific equipment and objectives |

All inventory, ownership, damage and extraction outcomes are decided by the server.
