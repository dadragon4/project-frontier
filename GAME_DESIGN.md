# GAME_DESIGN.md — PROJECT FRONTIER

Status labels are defined in `AGENTS.md`. Register entries (`Cn`, `Qn`) are in `TASKS.md`.

## Identity [Established]

| | |
| :-- | :-- |
| Working title | PROJECT FRONTIER |
| Platform | Roblox |
| Genre | First-person sci-fi extraction adventure / shooter |
| Audience | Roblox community: core gamers and creators |
| Multiplayer | PvPvE |
| Squad size | 1–5 players |
| Perspective | First-person in deployments, third-person in safe hubs |
| Session length | Short deployments 10–15 min, long deployments 15–30 min |
| World | Multiple planetary and orbital environments |
| Narrative | Original science-fiction universe, faction-driven, told through seasonal updates and discovery |

## Core experience [Established]

Players deploy into contested territories — abandoned colonies, orbital installations, industrial infrastructure — as Frontier Corp personnel (SGA) or SEVs (Federation of Aero). In a deployment they explore, traverse with parkour, recover equipment, resources and intelligence, fight hostile AI and other players, complete contracts, use physics-based environmental systems, find hidden places and narrative, and decide when to extract and how much more risk to accept.

What they carry, where they go, who they fight and when they leave all affect survival. Extracting successfully keeps what was recovered and feeds long-term progression.

A deployment should feel like **an expedition into a world that already existed**, not a disconnected multiplayer match.

## Gameplay pillars, in fixed priority order [Established]

1. **Movement** — Traversal is inseparable from gameplay. Fluid movement is fluid gameplay.
2. **Exploration** — Reward looking deeper and past the obvious, without making exploration exhausting or requiring excessive backtracking.
3. **Extraction** — Decisions have consequences. Carrying more reduces mobility and changes how encounters are approached.
4. **Combat** — Deliberate gunplay. Every trigger pull carries weight. Physics and environment are part of combat.
5. **Progression** — A reason to return. Gathering supplies is the beginning of a longer struggle. (Exact wording of that struggle: **[Conflict C10]**.)

These are not interchangeable. When two pillars compete for time or design space, the higher one wins.

## Creative influences [Established — inspirations only, nothing is to be copied]

| Reference | What is taken from it |
| :-- | :-- |
| Mirror's Edge | Fluid first-person parkour, momentum, movement as the core mechanic |
| Halo | Sci-fi military atmosphere, scale, faction conflict, worldbuilding |
| Call of Duty: DMZ | PvPvE extraction, contested resources, equipment risk, deployment-based progression |
| Half-Life 2 | Physics-driven interaction, object manipulation, gameplay arising from the environment |
| Star Wars Jedi: Fallen Order | The feeling of discovering ancient or experimental places (atmosphere only) |

## Design principles [Established]

- Movement should reward skill and flow; stamina must not feel like a bar that punishes simply moving.
- Vaulting and mantling can be automatic or manual (a player setting). Manual takes deliberate input, is rewarded with a stamina boost, and misreading an obstacle costs time. Gamepad and touch clamber automatically. (User decision 2026-11-10; replaces the earlier manual-only rule.)
- Loot is baggage, literally and strategically. Weight makes traversal harder but never removes parkour.
- Dying costs the weapons and loot of that deployment, but faction default weapons mean a player is never stranded.
- Combat is consequential but not instant-kill. A few excellent weapons before many weapons.
- Physics objects exist for gameplay reasons. Not every prop is simulated.
- QTEs have one job: hacking high-value strongholds.
- The world never looks abandoned just because a map needed to be post-apocalyptic. Some places work perfectly, some were just evacuated, some are reclaimed by nature or failing technology. A player should look at a place and wonder what happened there.
- No faction is purely good or evil.
- Nostalgia and futurism coexist.
- Solo players should not be automatically overwhelmed by five-player squads (method **[Q8]**).
- Progression should not make every activity feel like it exists only to generate XP.

## World and visual identity [Established]

Three environmental categories:

| Category | Examples | Visual language |
| :-- | :-- | :-- |
| **Civilized Politicism** — the face of advancement | Government buildings, clean transit, advanced housing, research and corporate facilities, sophisticated interfaces | Clean, organized, bright, highly technological; functioning or recently abandoned |
| **Industrialized Foundation** — what keeps humanity running | Maintenance and manufacturing, cargo terminals, warehouses, machinery, abandoned settlements, underground transport | Utilitarian, mechanical, worn, functional |
| **Unknown Origin and Predictive Future** — what humanity does not understand | Experimental technology, ancient structures, forgotten labs, unexplained specimens, rare minerals, unusual energy sources | Mysterious, unfamiliar, atmospheric, occasionally beautiful, potentially dangerous |

Aesthetic references: Frutiger Aero, Frutiger Aurora, Neo-Aero, Gen X Soft Club, Y2K futurism, Dark Aero, Technozen, Metalheart, Brutalist architecture, and "dorfic" (**[Q21]** — reference needs clarifying). These are to be combined thoughtfully; the game must not collapse into generic dark sci-fi or post-apocalypse. The balance is nostalgic futuristic optimism against political tension, industrial decay and mystery.

Nostalgia is carried by familiar interfaces, menus, in-game objects, sound, environmental detail, memorable exploration and a sense of discovery.

## Audio [Established]

Ambient electronic soundscapes, early sci-fi sound design, atmospheric IDM, occasional house music where the place or moment supports more energy, plus environmental and mechanical sound. Music follows the mood of a location; no constant high-intensity score. Movement, machinery, weapons and interactions should sound satisfying and recognizable.

## UI [Established]

Retro-futuristic operating-system interfaces combined with military tactical displays, with clean modern usability. The in-deployment HUD stays lean and readable. Menus, inventory, equipment, maps, hub and hideout screens carry more of the personality. It must not look like a generic modern military shooter.

## Player identity and progression (summary) [Established]

Equipment and weapons, gear and cosmetics, a personal hideout, and reputation. Wealth and experience are separate: a player can be rich in resources without being an experienced operator. Details in `GAMEPLAY.md`.
