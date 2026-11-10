# TECHNICAL_ARCHITECTURE.md — PROJECT FRONTIER

Status labels are defined in `AGENTS.md`. Register entries are in `TASKS.md`.

## Current state of the project (inspected 2026-11-10)

- `Roblox Studio/` was an **empty folder**. No place file, no scripts, no Rojo project, no git repository.
- None of the common Roblox command-line tools (Rojo, Rokit/Aftman, Wally, Selene, StyLua) are installed on this machine.
- There is therefore no existing code, no technical debt, and nothing functional yet.

Update, same day: a place file `Project Frontier.rbxl` now sits in the folder (not yet inspected); the Roblox Studio MCP server is registered for this folder; a local git repository is initialized. The user chose git with a private GitHub repository, to be shared with a second developer.

**[Proposed] Two-developer workflow.** Code lives as files in git and is synced into Studio with Rojo, so both developers can review and merge each other's scripts. A place file is a single binary that git cannot merge, so the world itself (maps, models, the rig) is better shared through Roblox's Team Create, where both developers edit the same published place.

Because nothing exists, everything below about structure and implementation is a starting recommendation, not a description of real code. It will be replaced by facts as code is written.

## Principles [Established]

- Luau, Roblox Studio, current supported APIs; nothing deprecated.
- Modular, readable, independently testable systems; no premature abstraction; no unjustified dependencies.
- Client handles input, camera, animation and local feedback. Server is authoritative for gameplay state.
- Validate every important action on the server.
- Use physics deliberately.
- Separate permanent player data from temporary deployment data.

## Key terms (for reference)

- **Server / client:** the server is Roblox's computer running the authoritative copy of the game; each client is one player's device. Anything a client says can be faked by a cheater, so the server must check it.
- **RemoteEvent / RemoteFunction:** the channels a client and server use to send each other messages.
- **Replication:** Roblox automatically copying changes from the server to clients (and some from client to server).
- **Network ownership:** which machine simulates the physics of a given object. By default each player's client owns its own character, which is why movement feels instant — and why movement can be cheated.
- **Place / experience:** an experience (the game) can contain several places (separate levels with their own servers). Players are moved between them by teleporting.

## Project structure

**[Established — as a starting proposal from the user, to adapt]**

```text
ReplicatedStorage      Shared · Modules · Configurations · Remotes     (visible to server and clients)
ServerScriptService    Services · Systems · AI                          (server only)
ServerStorage          Assets · Templates                               (server only)
StarterPlayer
  StarterPlayerScripts Controllers · Movement · Camera                  (runs on each client)
StarterGui                                                              (UI)
Workspace              Map · InteractiveObjects · NPCs                  (the 3D world)
```

Folders are created only when something real goes in them.

**[Proposed] Files on disk, synced into Studio with Rojo.** Scripts live as `.luau` files in this folder and Rojo copies them into Studio live. This gives version history (git), lets the agent read and edit code directly, and keeps code reviewable. The alternative is writing scripts only inside Studio, which is simpler to start but leaves the agent unable to see or edit the code except through the Studio window. This is decision **[Q1]**.

## Hubs and deployments [Established direction, details Open]

Hubs and extraction missions are separate experiences or instances with a reliable transition between them. Rallying needs a system that knows faction affiliation and deployment capacity.

**[Proposed]** One experience with separate places — hub, hideout, each deployment map — joined by Roblox's teleport service using private reserved servers for squads and deployments. To be designed properly in Phases 4–6 (**[Q28]**). Not needed for the movement prototype, which runs in a single test place.

## Client/server responsibilities [Established]

| Server decides | Client handles |
| :-- | :-- |
| Inventory, item and weapon ownership | Input |
| Damage | Camera and camera effects |
| Extraction outcomes | Animation presentation |
| Persistent progression, currency, resources, blueprints | Local feedback (sound, UI, effects) |
| Faction affiliation, squad restrictions | |
| Important environmental interactions | |

## Networking [Established]

Each remote validates arguments, permissions, distance and interaction conditions; is protected against spam; sends minimal state; and is designed with network ownership and multiplayer consistency in mind.

## Movement architecture [Proposed]

**The core trade-off.** Responsive movement needs the player's own device to simulate their character immediately. Cheat-resistant movement needs the server to be in charge. The standard Roblox answer, and the recommendation here, is: **the client simulates movement; the server checks that what it sees is plausible** (speed limits per movement state, no impossible position jumps, stamina tracked on the server too) and corrects or flags violations.

**How to build the character controller — three options:**

| Option | What it is | For | Against |
| :-- | :-- | :-- | :-- |
| A. Humanoid + custom layer | Keep Roblox's built-in character (`Humanoid`) for standing, walking, stairs and replication. Add our own state machine that controls acceleration and speed and takes over for slide, vault, mantle, wall-run. | Fastest path to something playable. Avatars, animation and multiplayer replication work from the start. | The Humanoid has opinions of its own and sometimes fights custom behaviour; edge cases need workarounds. |
| B. Roblox's physics character controllers | Roblox's newer configurable controller system (`ControllerManager` with ground/air/climb controllers). | Designed for custom movement; more control over acceleration and friction. | Less community knowledge; behaviour and maturity need hands-on checking. |
| C. Fully custom controller | Our own collision and movement maths, no Humanoid. | Total control. | Most work by far; we rebuild slopes, stairs and replication ourselves. |

**Recommendation:** start with **A**, and write the movement states so they do not care which option moves the body underneath. Spend a short, time-boxed test on **B** at the start of the milestone before committing. Avoid C unless A and B both fail.

**To verify before the anti-cheat task:** Roblox has been developing built-in server-authoritative character movement. Its current availability must be checked in the official documentation at that point; if it is production-ready it could replace hand-written validation.

**Shape of the code [Proposed]:**

- A **state machine**: the character is always in exactly one movement state (walk, sprint, crouch, slide, air, vault, mantle, wall-run, ledge-hang). Each state has its own rules and a list of states it may switch to. This keeps each ability in its own small module and makes "slide into vault" an explicit, tunable transition.
- A single **movement configuration module** holding every tunable number.
- **Environment detection** by raycasts and shape-casts (invisible probes fired from the character to find obstacles, ledges and walls). Whether level geometry is detected purely by shape or also by designer-placed tags is an implementation choice to settle when vaulting is built.
- **Frame-rate independence:** all motion scaled by elapsed time, so movement is identical at 30 and 240 FPS.
- **Camera** as a separate module (first-person lock, tilt, field-of-view changes, head-bob), so feel can be tuned without touching movement logic.
- **Input** through one module that maps actions ("sprint", "vault") to physical inputs, so adding gamepad or touch later does not touch movement code (**[Q2]**).
- Stamina and weight as small pure modules (numbers in, numbers out) that are easy to test.

## Physics [Established]

Four object categories: decorative, interactable, physics-driven gameplay objects, specialized-equipment interactions. For each simulated object consider network ownership, who simulates it, replication cost, collision complexity, constraints, server validation, cleanup, and behaviour with many players. Detailed design in Phase 3.

## Persistence [Established]

Permanent data (faction progression, XP, reputation, unlocks, blueprints, hideout customization, stash) is stored separately from temporary deployment data (current loadout, collected loot, mission state). Extracted weapons, stash inventory and unlocked blueprints are separate records. Data-loss prevention, safe saving, validation and recovery are designed in from the start of Phase 5.

**[Open]** Storage approach. Any third-party library (ProfileStore has been mentioned) must be evaluated for current maintenance, compatibility and fit before adoption. Evaluation is deferred to Phase 5.

## Planned gameplay services [Established as anticipated; names are conceptual]

| System | Responsibility | Phase |
| :-- | :-- | :-- |
| Movement Controller | Sprint, slide, vault, mantle, wall-run, stamina | 1 |
| Weapon Service | Firing, reloading, ownership, damage | 2 |
| World Interaction Service | Physics objects, machinery, hacking, environmental interactions | 3 |
| Inventory Service | Item storage, mass calculation, loot, stash | 4–5 |
| Extraction Service | Deployment lifecycle, extraction points, outcomes | 4 |
| Loadout Service | Faction equipment, weapon selection, deployment preparation | 5 |
| Persistence Service | Player data, inventory, unlocks, hideout customization | 5 |
| Progression Service | XP, unlocks, blueprints, reputation | 5 |
| Squad Service | Squad formation, five-player limit, rallying | 6 |
| Faction Service | SGA/Aero affiliation, switching, restrictions | 6 |
| Contract Service | Dynamic contracts and authored story missions | 6 |

None is to be created before its phase.

## Tooling [Proposed] [Q1]

| Tool | Purpose |
| :-- | :-- |
| git | Version history and the ability to undo |
| Rojo | Sync script files on disk into Studio |
| Rokit | Installs and pins the versions of Rojo and the tools below |
| StyLua, Selene | Automatic formatting and catching common Luau mistakes |

No gameplay libraries or frameworks are proposed.

## Testing approach [Proposed]

- Pure logic (stamina, weight maths, state-transition rules) written so it can be checked without a running character.
- A greybox **movement test course** place: plain blocks with known dimensions — sprint lanes, slide gaps, vault obstacles of several heights, ledges, wall-run walls.
- Studio play-testing for feel; Studio's multi-client test mode for anything networked.
- Every report states what was and was not tested.
