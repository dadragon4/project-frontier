# TECHNICAL_ARCHITECTURE.md — PROJECT FRONTIER

Status labels are defined in `AGENTS.md`. Register entries are in `DECISIONS.md`.

## Code map

Open only the files that own what you are changing.

```text
default.project.json                 Rojo mapping (below)
tools/studio.py                      drives Studio from the command line; `test` runs the scripted checks
src/shared/Config/MovementConfig     every movement tuning number
src/shared/Config/DevConfig          test-course, debug-readout and test switches
src/client/Main.client               starts everything when the character spawns
src/client/Input                     actions ("Sprint", "Crouch", ...) mapped to keys; press buffering
src/client/Settings                  the player's own preferences (not saved yet)
src/client/UI/SettingsPanel          settings window on P
src/client/Camera/FirstPersonCamera  first-person view and all camera feel effects
src/client/Movement/MovementController   per-frame loop: input, ground, jump, speed rules, runs the current state
src/client/Movement/Detection        raycast checks: obstacles to vault/mantle/hang from, wall-run walls, room to stand
src/client/Movement/States/*         one file per state: Walk, Sprint, Crouch, Slide, Air, Roll, Mantle, Vault, LedgeHang, WallRun, Prone, Dive
src/client/Movement/DebugReadout     on-screen state and speed
src/client/Dev/MovementTests         scripted movement checks on the test course
src/server/TestCourse.server         builds the greybox course at server start
src/server/CharacterCollision.server stops players' arms and legs colliding with the world
```

Rojo maps these into three folders it owns and touches nothing else in the place: `ReplicatedStorage.Shared`, `ServerScriptService.Server`, `StarterPlayer.StarterPlayerScripts.Client`. The place file itself holds only the default baseplate and lighting; it is shared through Roblox and kept out of git, because a place file is one binary that git cannot merge.

**How movement works.** Roblox's own control script still reads the keyboard (and later the thumbstick) and tells the Humanoid which way the player wants to go. Straight afterwards, each frame, our controller reads that wish from `Humanoid.MoveDirection`, works out a velocity using our own acceleration rules, and tells the Humanoid to walk in that direction at that speed. States that move the body directly (mantle, vault, ledge hang, wall-run) put the Humanoid in its "Physics" state instead.

**Roblox behaviours found in Studio that the code depends on** (check the live place, not memory, before touching Roblox's default scripts):

- `PlayerModule` lives at `StarterPlayer.PlayerModule` (not in `PlayerScripts`), and its public interface is only `ControlModule.Enabled`; the old `GetControls()` / `GetMoveVector()` calls are gone. It still moves the character at render priority `Input`, which our ordering relies on.
- Scripts cannot set `Player.DevEnableMouseLock`.
- In the Humanoid's "Physics" state every body part becomes solid, and setting `CanCollide` from a script does not stick. A collision group (`PlayerLimbs`, set up by the server) stops limbs colliding with the world.
- In that state gravity still acts between our frames, so a held body sags. While such a state is active, a `VectorForce` equal to the character's weight cancels gravity.
- Studio runs at a low frame rate while its window is in the background, which matters for timing-sensitive tests.

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

## Hubs and deployments [Established direction, details Open]

Hubs and extraction missions are separate experiences or instances with a reliable transition between them. Rallying needs a system that knows faction affiliation and deployment capacity.

**[Proposed]** One experience with separate places — hub, hideout, each deployment map — joined by Roblox's teleport service using private reserved servers for squads and deployments. To be designed properly in Phases 4–6 (**[Q28]**). Not needed for the movement prototype, which runs in a single test place.

## Client, server and networking

The rules (what the server decides, what the client handles, what every remote must validate) are in `AGENTS.md` → "Technical standards".

## Movement architecture

**Built:** Roblox's own character (`Humanoid`) handles standing, stairs and replication; our state machine on top controls acceleration and speed and takes over the body for the special moves. The character is always in exactly one state, one small file each (see the code map). All motion is scaled by elapsed time, so it is the same at any frame rate. If the Humanoid ever gets in the way, the fallback is Roblox's newer `ControllerManager` system; a fully custom controller is the last resort.

**Not built yet [Proposed]:**

- **Server checks.** The client simulates its own character so movement feels instant; the server checks that what it sees is plausible (speed limits per state, no impossible position jumps, stamina tracked on the server too) and corrects or flags violations. Before writing this, check the official documentation for Roblox's built-in server-authoritative movement; if it is production-ready it could replace hand-written checks.
- **Stamina and weight** as small pure modules (numbers in, numbers out) that are easy to test.
- **Gamepad and touch** bindings in the Input module; movement code does not change.

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

## Tooling

In use: git (GitHub repo), Rojo 7.7.1 (Homebrew on Mac, release zip on Windows) with its Studio plugin, and `tools/studio.py` (talks to Studio's built-in MCP server; works on Mac and Windows). **[Proposed]**, not installed: Rokit (pins tool versions), StyLua and Selene (formatting and catching common Luau mistakes). No gameplay libraries or frameworks are proposed.

## Testing

See `AGENTS.md` → Testing. Anything networked also needs Studio's multi-client test mode.
