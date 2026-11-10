# Game Concept & Vision

## Executive Summary

### Project Title: PROJECT FRONTIER

### Genre: First-person sci-fi extraction adventure / shooter

### Target Audience: Roblox Community (Core gamers & creators)

### Core Identity

A futuristic extraction experience where movement, exploration, resource accumulation, and survival are interconnected.  
Players operate in contested territories across abandoned colonies, orbital installations, and industrial infrastructure. Their decisions about what to carry, where to travel, who to fight, and when to extract directly affect their chances of survival.

| Category | Current direction |
| :---- | :---- |
| **Genre** | First-person sci-fi extraction shooter / adventure |
| **Perspective** | First-person deployments, third-person safe hubs |
| **Multiplayer** | PvPvE |
| **Team size** | 1–5 players |
| **Session length** | 10–15 or 15–30 minutes |
| **World** | Multiple planetary and orbital environments |
| **Movement** | Momentum-based traversal and moderate parkour |
| **Combat** | Deliberate tactical gunplay |
| **Physics** | Environmental and combat-oriented interactions |
| **Progression** | Equipment, weapons, cosmetics, hideout, reputation |
| **Narrative** | Original science-fiction universe with faction-driven storytelling |

## Roadmap

| Phase | Development target | Deliverable |
| :---- | :---- | :---- |
| 1 | Movement prototype | Playable first-person traversal |
| 2 | Combat prototype | Weapons, damage, AI |
| 3 | Physics prototype | Environmental interaction |
| 4 | Vertical slice | First complete extraction deployment |
| 5 | Persistence | Inventory, hideout, progression |
| 6 | Faction systems | Affiliation, contracts, reputation |
| 7 | World expansion | Additional maps, lore, enemies |

## 

## Gameplay System

### 01 — Movement

**Highest priority**  
Traversal is inseparable from gameplay. Fluid movement is fluid gameplay.

### 02 — Exploration

Players are rewarded for looking deeper and beyond the obvious boundaries of the game, without making exploration unnecessarily exhaustive.

### 03 — Extraction

Decisions have consequences. Carrying too much reduces mobility and changes how players approach encounters.

### 04 — Combat

Gunplay is deliberate. Every trigger pull carries weight. Physics and the environment are intertwined with combat.

### 05 — Progression

Players need a reason to return to the front lines. Accumulating supplies is the beginning of a longer struggle for control and hope.

| Ability | Priority | Design requirement |
| :---- | :---- | :---- |
| Sprint | Essential | Responsive acceleration influenced by carried weight |
| Sliding | Essential | Momentum-based transition from sprinting |
| Vaulting | Essential | Manual traversal of obstacles |
| Mantling | Essential | Climbing ledges, pipes, and obstacles |
| Wall-running | High | Alternative traversal where conventional routes don't exist |
| Ledge grabbing | High | Natural integration with climbing and wall-running |
| Crouching | Essential | Tactical positioning and obstacle navigation |
| Sliding transitions | Medium | Advanced transitions between sliding, vaulting, and other movements |

Regarding manual input, vaulting should require deliberate player input. Failing to recognize an obstacle or choosing the wrong movement action could cost valuable time.

## Weight and Movement

### Inventory influences mobility

**High mobility** \- *Light*

* Fast acceleration, longer slides, easier traversal

**Balanced** \- *Medium*

* Moderate acceleration and traversal limitations.

**Reduced** mobility \- *Heavy*

* Slower acceleration, shorter slides, more difficult traversal.

Weight affects acceleration, slide distance, stamina consumption (if we use stamina), and climbing performance.

### Stamina and momentum

Stamina is a player skill that can improve as the player levels up through XP.

* Parkour consumes stamina.  
* Momentum reduces stamina consumption.  
* Maintaining a good movement flow allows players to traverse longer before exhausting themselves.  
* Weight can make acceleration and traversal more difficult.  
* Higher-level players can improve their stamina capacity or efficiency.

This gives us two interacting systems:  
Stamina controls how long a player can sustain demanding movement. Momentum rewards maintaining flow and making efficient traversal decisions.  
We should avoid making the system feel like a traditional stamina bar that punishes players for simply moving. The goal is to reward skilled movement.

### Inventory weight

Weight is calculated from the total mass of items collected during a deployment.  
Important distinction: The player's original deployment loadout does not count toward this scavenged inventory weight.  
The intended gameplay relationship is:

* More loot means more weight.  
* More weight affects movement.  
* Movement becomes less efficient as the player accumulates resources.  
* Players must decide whether additional loot is worth the traversal penalty and potential danger.

This reinforces your third gameplay priority: extraction decisions should carry baggage, literally and strategically.

## Extraction and Deployment Structure

1. *Safe Colony/Social Hub*  
2. Deployment (Select)  
   1. Faction  
   2. Mission  
   3. Map  
   4. Loadout  
   5. Solo or Squad  
3. Instanced Deployment  
   1. First-person PvPvE  
   2. Scavening  
   3. Combat  
   4. Exploration  
4. Extraction / Debrief  
   1. Retain recovered goods  
   2. Process *Mission Results*  
   3. Progress \[XP, Unlocks\]  
5. Back to the Safe Colony/Social Hub

### Match specifications

| Property | Current design |
| :---- | :---- |
| Minimum team | 1 player |
| Maximum team | 5 players |
| Solo | Supported |
| Cooperative | Supported |
| PvP | Supported |
| PvE | Supported |
| Short deployment | 10–15 minutes |
| Long deployment | 15–30 minutes |
| Safe hub perspective | Third-person |
| Deployment perspective | First-person |

I would also make sure that solo players aren't automatically placed at an overwhelming disadvantage against coordinated five-player squads. We can explore matchmaking, deployment population limits, and alternative objectives later.

### Extraction Mechanics

* Multiple extraction points.  
* Activation requirements that depend on faction.  
* Temporary and conditional extractions.  
* Limited inventory capacity.  
* Recoverable intelligence and equipment.  
* Risk of losing carried equipment and loot on death.  
* Successful extraction contributes to long-term progression.

### Death and recovery

Dying means losing:

* Weapons equipped for that deployment.  
* Loot collected during that deployment.

The player retains their faction's default weapons, so a bad deployment does not permanently prevent them from playing.  
This creates meaningful risk without allowing a player to become completely stranded.

## Physics and Environmental Interaction

**Physical simulation**: Objects move, collide, fall, and respond to forces.  
**Gameplay interaction**: Players intentionally manipulate the environment to accomplish objectives.

| Interaction | Gameplay purpose |
| :---- | :---- |
| Move containers | Create cover or access locations |
| Throw objects | Distract enemies or create noise |
| Activate machinery | Open alternative traversal routes |
| Move heavy objects | Access concealed spaces |
| Manipulate electrical equipment | Disable security infrastructure |
| Specialized equipment | Manipulate heavier objects |

Not every chair, wall panel, or decorative prop needs to be physically movable. Instead, objects that contribute to gameplay receive intentional physics behavior and server-side validation.

### Combat

Combat should be deliberate and consequential, but not necessarily instant-kill.

Players should withstand several hits depending on the weapon used against them. Weapon lethality, armor, and damage balancing can be refined during prototyping.

The physics system remains closely tied to combat and environmental interaction.

### QTEs

QTEs (Quick Time Events) are now associated with hacking into strongholds containing substantial amounts of loot.

This gives them a clear gameplay purpose: hacking is a high-value activity that can introduce risk, pressure, and a more involved interaction than simply pressing an interaction button.

The exact hacking sequence, failure consequences, and whether other players can interrupt the process remain to be designed.

Hacking is a skill that can be leveled up. The more times a player hacks into strongholds, chests/lootboxes, etc. the more their hacking skill levels up allowing for easier, faster hacks.

| Level | Skill Unlock |
| :---- | :---- |
|  |  |

## Progression & Player Identity

| System | Purpose |
| :---- | :---- |
| Equipment and weapons | Improve deployment capability, level up XP, unlock weapon blueprints. |
| Gear and cosmetics | Personalize operator appearance. |
| Personal hideout | Give players a persistent space to design and layout how they want. |
| Faction reputation | Unlock contracts, rewards, and narrative content. |

### Wealth vs Progression

A player might have accumulated substantial resources without necessarily being a highly experienced operator. Bringing back other player’s weapons that are of high level (to a certain extent), can give small XP bonuses to a player’s level and contribute to *blueprint manufacturing*.

### Reputation/Rank

Reputation is earned by collecting artifacts and naturally leveling up. Enough reputation earned unlocks the \[Children of Aero\] faction. Faction-specific opportunities are also granted to players with specific amounts of Reputation. Reputation can not be bought in the store\*.

Reputation is not to be confused with XP.

| Reputation Level | Unlock |
| :---- | :---- |
| Starting \- 0 rp | Nothing\! |
| 100 rp | Title Card |
| 500 rp | Children of Aero \- Faction |
|  |  |

Reputation unlocks the following:

* Cosmetics \- Decals, stickers, accessories, calling cards, title cards, etc.

The hideout could eventually become a place to display recovered artifacts, store equipment, review intelligence, and customize the operator.

### Contracts

#### Contract structure

A hybrid model:

* Dynamic contracts: Generated to provide repeatable objectives and reasons to deploy.  
* Special contracts: Authored story missions that advance the larger narrative.

## Narrative structure

The central story progresses through seasonal updates.  
Players can discover additional narrative content through:

* Unmarked locations.  
* Hidden rooms and facilities.  
* Artifacts and documents.  
* Recovered intelligence.  
* Environmental storytelling.  
* Encounters with hidden factions and unusual technology.

*The Children of Aero* should be an especially interesting example of this approach: players may first encounter references to them long before they understand who they are or what they represent.  
The universe's religious and cosmic mystery also remains intact. The existence of the one true God who blessed Earth is an established fact within the setting, a cultural belief, and an important part of the Children of Aero's perspective. Other groups may deny or suppress it, influenced by propaganda and competing narratives.

## Safe Colony / Social Hub

The social hubs are shared public spaces, visually represented as ships belonging to the respective factions.

Players can:

* Meet other players.  
* Form or join squads.  
* Inspect their characters in third-person.  
* Change equipment and loadouts.  
* Manage their stash and recovered weapons.  
* Prepare for deployments.

When players join friends or form a squad, they are transported to a safe colony or ship instance associated with their squad. This becomes their staging area before deployment.

### Personal hideout

Every player has a customizable personal room aboard a ship.  
The hideout serves as a personal space where players can:

* Display collected artifacts, unlocks, and achievements.  
* Review news, updates, and intelligence.  
* Change factions.  
* Customize their room.  
* Access personal progression information.

Keeping the hideout aboard a ship creates continuity between the player's personal space and the broader faction environment.

## The Universe and its History (Story)

#### **Humanity's expansion**

Humanity has advanced far beyond its original colonies.  
Technological development and biological adaptations have fundamentally changed how people live. Wealthier populations have pursued increasingly advanced lifestyles through colonization and technological integration.  
However, this advancement has consequences.  
Remote colonies are abandoned as humanity moves forward. Infrastructure, technology, resources, and entire communities are left behind.  
Those who remain must maintain what the expanding civilization no longer considers worth maintaining.  
This creates a divide:

* Those who advance with the SGA.  
* Those who are abandoned by the SGA.  
* Those who profit from the remnants of the old world.

#### **The formation of Aero**

Led by Lorenz Aero, a small group of friends initially works to maintain the systems and infrastructure abandoned by humanity's expansion.  
What begins as a small operation becomes a contract-for-hire organization.  
Aero grows through maintenance, protection, resource recovery, and contracted services. Its reputation and accumulated resources eventually allow it to become a federation.  
Lorenz rules with an iron hand, but maintains a personal commitment to those around him. Friends and family occupy positions within his cabinet, helping establish Aero as an independent power.  
The SGA refuses to recognize its sovereignty.  
Eventually, Aero's leadership changes. A nephew of Lorenz assumes the presidency and begins corrupting the cabinet, redirecting the federation toward galactic control.  
This creates the circumstances for Enzo Hart.

#### **The SGA and Frontier**

The Spacial Government of Advancement continues pursuing technological growth, often at the expense of the populations and communities it leaves behind.  
Its research and development initiatives become increasingly ambitious, including a project known as Frontier.  
The project reaches a technological breakpoint, requiring resources previously deemed unnecessary.  
The SGA subsequently redirects its achievements toward military applications, deploying bio-enhanced soldiers to reclaim remote colonies.  
The Frontier Corp becomes its boots-on-the-ground task force.  
This is an important distinction: Frontier isn't simply another military organization. It represents the SGA's attempt to reclaim control over territories and resources it previously abandoned.

#### **The Children of Aero**

Enzo Hart, the rightful heir to Lorenz Aero's original vision, establishes the Children of Aero.  
His objective is to restore the federation to its roots and free remote colonies from SGA authority.  
This introduces a third ideological direction:

* The SGA wants advancement, consolidation, and control.  
* The Aero Federation seeks power and galactic dominance under corrupted leadership.  
* The Children of Aero seek restoration, independence, and the original ideals of Lorenz.

None of these factions needs to be entirely good or evil.

#### **Historical Timeline**

1. The Spacial Alliance for Freedom (SAF): The original organization that eventually became the SGA. It represents an earlier political identity and historical period.  
2. The shuttle attack: A devastating terrorist attack against a civilian shuttle prompts the SAF/SGA to consolidate military authority and establish the Frontier Corp. The attack is a false-flag operation, but its perpetrator remains unknown in the present day. Both the SGA and Federation of Aero use propaganda to shift blame.  
3. The rise of the SGA: The Spacial Government of Advancement becomes the dominant governing authority, pursuing technological and biological advancement while leaving some colonies and populations behind.  
4. The formation of Aero: Lorenz Aero and a group of friends begin operating as contractors, maintaining systems and infrastructure that larger institutions have neglected. Their organization grows into a powerful federation.  
5. The corruption of Aero: After Lorenz's eventual successor takes control, the federation's leadership becomes increasingly corrupt and shifts toward galactic control.  
6. The Children of Aero: Enzo Hart, believing himself to be the true heir to Lorenz's original vision, establishes a hidden movement seeking to restore Aero's roots and liberate remote colonies from SGA control.

### 

### **Player affiliations**

**SGA — Frontier Corp**  
Players operate as military personnel deployed to reclaim resources, secure installations, and investigate threats to SGA interests.  
**Aero — SEVs**  
Players operate as independent scavengers and contractors, recovering technology and resources while working toward Aero's objectives.  
*Scavenge. Evolve. Vindicate.*

**Children of Aero** – Unlockable Playable Faction  
There’s potential for:

* Separate contracts and objectives.  
* Reputation-based access.  
* Alternative mission outcomes.  
* Storyline progression.  
* Different equipment or rewards.

We don't necessarily need to make them playable immediately.

## Atmosphere & Visual Identity

#### **A. Civilized Politicism**

The face of technological advancement.

* Government buildings.  
* Clean transportation systems.  
* Advanced residential architecture.  
* Research facilities.  
* Corporate infrastructure.  
* Sophisticated user interfaces.

Visual language: clean, organized, bright, and highly technological.

#### **B. Industrialized Foundation**

The infrastructure that keeps humanity functioning.

* Maintenance facilities.  
* Manufacturing plants.  
* Cargo terminals.  
* Mechanical infrastructure.  
* Abandoned settlements.  
* Underground transportation.

Visual language: utilitarian, mechanical, worn, and functional.

#### **C. Unknown Origin and Predictive Future**

The remnants of something humanity doesn't fully understand.

* Experimental technology.  
* Ancient structures.  
* Unexplained biological specimens.  
* Rare minerals.  
* Unusual energy sources.  
* Forgotten research projects.

Visual language: mysterious, unfamiliar, atmospheric, and occasionally beautiful.  
***Design Principle***: The world should never look abandoned simply because we need a post-apocalyptic map. Some facilities should still operate perfectly. Some should look recently evacuated. Others should be reclaimed by nature or malfunctioning technology.  
The player should be able to look at a location and wonder what happened there.

## Factions

| Organization | Identity | Role |
| :---- | :---- | :---- |
| SGA | Its military arm is the Frontier Corp. The SGA believes continued advancement and centralized authority are necessary to preserve humanity's future. Its pursuit of progress has also left entire populations behind. | Story. |
| **Frontier Corp**  | SGA military response force. | Playable Faction. |
| Aero Federation | Independent federation | Story. |
| **SEVs**  | Aero operators. *Scavenge. Evolve. Vindicate.* | Playable Faction. |
| **Children of Aero**  | Ideological opposition to corrupted Aero leadership | Playable Faction. |
| Colony Militias  | Local defensive forces | Can be hostile or friendly AI depending on *Player Faction*. |
| Rogue AI Mechs  | Autonomous hostile systems | Hostile AI. |

## Audio / Sound Design / Theme

* Ambient electronic soundscapes.  
* Early sci-fi sound design.  
* Atmospheric IDM.  
* Occasional house music, particularly where the environment or situation supports a more energetic sound.

## UI Direction

A combination of:

* Retro-futuristic operating-system interfaces.  
* Military tactical displays.  
* Clean modern usability.

The HUD should communicate information efficiently while maintaining the game's nostalgic sci-fi identity. Menus, equipment screens, maps, and social-hub interfaces can carry more of the visual personality than the in-deployment HUD.

# Development Architecture

## Structure Tree

PROJECT  
│  
├── AGENTS.md  
├── GAME\_DESIGN.md  
├── LORE\_BIBLE.md  
├── GAMEPLAY.md  
├── MOVEMENT\_SPEC.md  
├── COMBAT\_SPEC.md  
├── EXTRACTION\_SPEC.md  
├── WORLD\_DESIGN.md  
├── ASSET\_GUIDE.md  
├── TECHNICAL\_ARCHITECTURE.md  
│  
└── Roblox Project  
    ├── ReplicatedStorage  
    │   ├── Shared  
    │   ├── Modules  
    │   ├── Configurations  
    │   └── Remotes  
    │  
    ├── ServerScriptService  
    │   ├── Services  
    │   ├── Systems  
    │   └── AI  
    │  
    ├── StarterPlayer  
    │   └── StarterPlayerScripts  
    │       ├── Controllers  
    │       ├── Movement  
    │       └── Camera  
    │  
    ├── StarterGui  
    └── Workspace

# Roblox Development Architecture

| System | Responsibility |
| :---- | :---- |
| Movement Controller | Sprinting, sliding, vaulting, mantling, wall-running, stamina |
| Inventory Service | Item storage, mass calculations, loot, stash |
| Loadout Service | Faction equipment, weapon selection, deployment preparation |
| Weapon Service | Weapon handling, damage, firing, reloading |
| Extraction Service | Deployment lifecycle, extraction points, success and failure |
| Squad Service | Squad formation, five-player limit, rallying |
| Faction Service | SGA/Aero affiliation, switching, faction restrictions |
| Progression Service | XP, unlocks, blueprints, reputation |
| Contract Service | Dynamic contracts and authored story missions |
| World Interaction Service | Physics objects, machinery, hacking, environmental interactions |
| Persistence Service | Player data, inventory, unlocks, hideout customization |

### Important architectural implications

* Shared hubs and deployments: Hubs and extraction missions should be separate experiences or instances, with a reliable transition between them.  
* Squad management: Rallying multiple squads requires a system that understands faction affiliation and deployment capacity.  
* Weapon persistence: Extracted weapons, stash inventory, and unlocked blueprints need separate data records.  
* Server authority: Inventory, weapon ownership, damage, extraction outcomes, and persistent progression must be validated server-side.  
* Movement: Custom movement will need careful client/server handling to feel responsive without allowing players to exploit movement physics.  
* Persistence: Player data should distinguish permanent unlocks from equipment temporarily carried into a deployment.

