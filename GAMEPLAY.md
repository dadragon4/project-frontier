# GAMEPLAY.md — PROJECT FRONTIER

Status labels are defined in `AGENTS.md`. Register entries (`Cn`, `Qn`) are in `TASKS.md`. Movement has its own file (`MOVEMENT_SPEC.md`), as does the deployment loop (`EXTRACTION_SPEC.md`).

## Core loop [Established]

1. **Safe colony / social hub** (third-person)
2. **Deployment selection:** faction, mission, map, loadout, solo or squad
3. **Instanced deployment** (first-person PvPvE): scavenging, combat, exploration
4. **Extraction / debrief:** keep recovered goods, process mission results, progress (XP, unlocks)
5. Back to the hub

## Exploration [Established]

Players who look past the obvious objective are rewarded with places and secrets that are not marked on the map: equipment and unlocks, valuable resources, hidden routes, artifacts, intelligence, narrative discoveries, references to hidden factions. Exploration is meaningful without forcing players to search every corner or backtrack heavily.

## Threats [Established]

1. Other players after valuable loot.
2. Hostile AI factions protecting installations and resources (Colony Militias, Rogue AI Mechs, others).
3. Environmental hazards and security systems.

## Combat [Established]

- Deliberate, responsive, integrated with the environment. Every trigger pull carries weight.
- Weapons have recognizable handling, recoil, sound and impact.
- Different weapons have different lethality. Players withstand several hits depending on the weapon. Not instant-kill.
- Physics influences encounters.
- Developed after the movement prototype. A small number of excellent weapons before variety.

**[Open] [Q17]** Health, armor, damage, recoil and lethality values.

## Physics and environmental interaction [Established]

Two layers: **physical simulation** (objects move, collide, fall, respond to forces) and **gameplay interaction** (players deliberately manipulate the environment to achieve something).

| Interaction | Purpose |
| :-- | :-- |
| Move containers | Create cover or reach locations |
| Throw objects | Distract enemies, create noise |
| Activate machinery | Open alternative routes |
| Move heavy objects | Reach concealed spaces |
| Manipulate electrical equipment | Disable security |
| Specialized equipment | Manipulate heavier objects |

Object categories: decorative / interactable / physics-driven gameplay objects / specialized-equipment interactions. Only gameplay-relevant objects get physics behaviour and server validation.

**[Open] [Q20]** A dedicated physics-manipulation tool is a possible direction. Its form is undecided and it is not a required starting feature.

## Hacking and QTEs

**[Established]** Quick-time events have one application: hacking into strongholds that hold substantial loot. Hacking is a high-value, pressured interaction with more depth than a proximity prompt. It may involve timing or sequencing. QTEs are not to be added elsewhere.

**[Established — ruling 2026-11-10, settles C7]** Hacking is both a mechanic and a skill. The skill levels up through the player's level **and** through use of hacking together: a player who never hacks never levels it. Higher skill makes hacks easier and faster. The concept doc's Level / Skill Unlock table is still empty.

**[Open]** Whether chests and lootboxes also use the hacking interaction (concept doc) or only strongholds (master prompt).

**[Open] [Q14]** The sequence itself; failure consequences; whether other players can interrupt; whether it makes noise or attracts AI; whether it is real-time; whether a squad defends the hacker.

## Factions in play

**[Established]**

- Two starting affiliations: **SGA / Frontier Corp** (centralized military authority, technological advancement) and **Federation of Aero / SEVs** (resource recovery, independent operations).
- Players may switch between them between deployments (from the hideout).
- Each faction has distinct starting equipment and weapons, but faction never permanently limits what a player can use.
- Same-faction players cooperate. Different factions cannot share a squad or a combined operation.
- Several same-faction squads may rally together against larger threats. Limits and matchmaking: **[Q10]**.
- Colony Militias are hostile or friendly depending on the player's faction (**[Q26]**).

**Children of Aero [Established — ruling 2026-11-10, settles C5]** — unlocked at **500 rp**. The faction is never shown outright: players discover who the Children of Aero are through exploration, and later gain them through the unlock. Potentially with their own contracts, objectives, alternative mission outcomes, storyline and equipment. They need not be playable at launch.

**Aero's operators [Established — ruling 2026-11-10]** — SEVs (officially employed) have more advanced gear and bio-enhancements; Aero's independent contractors have less advanced gear but higher stamina and movement speed. Whether and how this becomes a gameplay choice is to be discussed later (**[Open]**).

## Progression

### Equipment and weapons [Established]

- Upgrade weapons, unlock equipment.
- Weapons recovered from other factions and successfully extracted go to the stash at the safe colony.
- Recovering multiple examples of a weapon unlocks its **blueprint**; a blueprint lets the player craft that weapon indefinitely, subject to resource and crafting requirements to be set later (**[Q15]**).
- Losing everything still leaves the faction's default weapons.
- (Concept doc) Bringing back other players' high-level weapons, "to a certain extent", gives small XP bonuses and contributes to blueprint manufacturing. What "weapon level" means: **[Q16]**.

### Wealth vs progression [Established]

Accumulated resources and operator experience are separate measures. A player can be wealthy without being experienced.

### XP and skills

**[Established]** XP drives player level. Stamina is a skill that improves with level (capacity or efficiency).

**[Established — 2026-11-10]** Each player's maximum stamina differs by rank, class and faction (to be worked on later). Hacking levels through player level and use together.

**[Open] [Q18]** The full skill system. No large skill tree without approval. Classes and the detailed stamina rules are deferred by the user to a later discussion.

### Reputation [Established — ruling 2026-11-10, settles C6]

- There is **one overall Reputation**. Separate "faction reputation" is dropped.
- Earned by collecting specific in-game items — **medallions, artifacts and voice logs** — and by naturally leveling up.
- Reputation can unlock different contracts within the separate factions.
- Not the same thing as XP. Cannot be bought in the store (the concept doc marks this with an unexplained asterisk — **[Q19]**).
- Unlocks cosmetics (decals, stickers, accessories, calling cards, title cards) and, later, the Children of Aero.

| Reputation | Unlock |
| :-- | :-- |
| 0 rp | Nothing |
| 100 rp | Title Card |
| 500 rp | Children of Aero — faction |
| *(further rows not yet written)* | |

### Cosmetics [Established]

Personalize the operator through unlockable gear and cosmetic items.

### Personal hideout [Established]

A customizable personal room aboard a ship, separate from the public hub. There the player can display artifacts, unlocks and achievements; review news, updates and intelligence; change faction; customize the room; see progression. It may later also store equipment and host operator customization.

## Contracts [Established]

Hybrid model:

- **Dynamic contracts** — generated, repeatable objectives that give reasons to deploy.
- **Special contracts** — authored story missions that advance the larger narrative.

**[Open] [Q27]** Generation system, reward structure, mission variety.

## Social hubs [Established]

Shared public spaces, represented as ships belonging to each faction. Players meet others, form or join squads, inspect their characters in third-person, change equipment and loadouts, manage stash and recovered weapons, view progression, and enter deployments.

When players join friends or form a squad they are moved to a safe colony or ship instance associated with that squad, which becomes their staging area.

**[Open] [Q28]** Matchmaking, hub population, and the hub-to-deployment transition.

## Economy [Open] [Q19]

Currency and resources are anticipated (the master prompt lists them as server-authoritative data and as a Phase 5 item) and the concept doc refers to a store. Nothing else about currency, crafting costs or monetization is defined.
