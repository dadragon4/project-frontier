# MOVEMENT_SPEC.md — PROJECT FRONTIER

Movement is pillar #1. Status labels are defined in `AGENTS.md`; register entries (`Cn`, `Qn`) are in `DECISIONS.md`.

**Numbers live in `src/shared/Config/MovementConfig.luau`, not here.** Each one has a comment there saying what it does. This file describes behaviour; it quotes a number only where the user ruled on it. No tuning value is final until the tuning pass (M1.4).

## Intent [Established]

- Traversal is inseparable from gameplay. Momentum, acceleration, weight and stamina interact.
- Movement is responsive and rewards players who keep their flow through an environment.
- First-person during deployments.
- Custom-built rather than relying entirely on default Roblox character movement.

## Keys

`W A S D` move · `Left Shift` sprint (hold, any direction) · `C` tap: crouch / slide / stand up · `C` hold: prone / dive · `Left Ctrl` (or `Left Command` on a Mac) roll · `Space` jump / manual clamber / pull up / wall jump · `R` quick turn · `P` settings.

## Abilities

Everything in this section is built unless it says otherwise. "As built" lines are the agent's **[Proposed]** details, open to change.

### Sprint [Established]

- Responsive acceleration; smooth and controllable. Momentum carries into other movement actions.
- Works in any direction. Moving sideways or backwards is slower than straight ahead, in every ground state (`StrafeSpeedScale`, `BackSpeedScale`, blended in between).
- Added weight lowers top speed (see "Weight"; not built).

### Strafing [Established: precise, responsive, competitive, still momentum-based]

As built:

- Pushing against your own momentum (a counter-strafe) brakes at its own faster rate, `ReverseDecel`. Letting go of the keys uses `GroundDecel`; cornering uses `TurnFriction`.
- The gentle bleed-off of extra sprint speed only applies when pushing forward, so forward sprint speed cannot be carried into a strafe or a backpedal.
- Steering in the air cannot build more speed than walking that way would.
- A sideways cut out of a sprint picks up the new direction at the normal (fast) rate.
- Measured at 60 frames per second with the current config: walk reversal 0.23 s; sprint reversal 0.37 s; a sprint cut to the side dips from 25 to 19.6 and completes in 0.22 s.

### Crouch key: tap and hold [Established]

| | Tap `C` | Hold `C` |
| :-- | :-- | :-- |
| Standing or walking | Crouch (stays crouched; tap again to stand) | Prone |
| Sprinting | Slide (no need to keep the key down) | Dive, landing prone |
| Crouched | Stand up | Prone |
| Sliding | End the slide early, into a crouch | — |
| Prone | Stand up | — |

- Holding sprint while moving stands you up from a crouch and runs.
- Slide, roll and dive stay three separate moves.
- As built: a press released within `CrouchHoldTime` is a tap, so tap actions start when the key comes back up.

### Crouch [Established]

Responsive and intuitive. For stealth, tactical positioning, getting under obstacles, and reacting to threats. You cannot stand up under a low roof.

### Slide [Established]

- A momentum-based transition out of sprinting; players build speed first. Momentum is preserved where appropriate.
- On flat ground it ends in a crouch. Down a slope it keeps going until the slope levels out, and can be ended early by jumping or pressing crouch.
- Chains into other moves: slide into an obstacle → vault; slide → jump (slide-hop); slide → roll key → roll.
- Slide distance will depend on weight (longer when light; not built).
- As built: a slope counts from `Slide.SlopeMinAngle` degrees; on it the slide has no friction.

### Slide-hop [Established]

Jumping out of a slide keeps a little of the speed, and then acceleration picks back up. As built: a small speed bonus on the jump, capped and limited to once a second; while sprinting, speed above sprint speed eases off gently instead of being cut.

### Prone [Established]

Lying down and crawling. Slow to get into and out of. You cannot stand up under a low roof. As built: `Space` also stands you up.

**Known limitation:** a Roblox Humanoid cannot lie down, so the body is only lowered as far as it goes and stays upright. In first person it reads as lying down; other players see a very short standing character. **Planned:** lay the body flat (Humanoid "Physics" state with the root pitched 90 degrees, as mantle and wall-run do) once the custom rig and animations exist.

### Dive [Established]

Our own omnidirectional dive: hold crouch while sprinting to leap in the direction you are moving and land prone. No steering in the air. Needs a minimum speed (`Dive.MinSpeed`). Not built: firing while diving or on your back (combat and animation work).

### Roll [Established]

- **Air roll:** press the roll key in the air and you roll on landing, but only after a fall of at least 6 studs. On a shorter fall the press does nothing.
- **Ground roll:** press the roll key while walking, sprinting or sliding. Standing still does not roll. The roll goes in the direction you are pushing.

As built: the roll keeps your speed (within limits), lasts about half a second, keeps the body low, and turns the camera over once. Afterwards: sprint if sprint is held, otherwise walk.

**Agent's readings, to confirm:** "height" is the drop from the highest point of the jump or fall to the landing spot. Rolling out of a slide was kept; rolling from a crouch was removed, since the ruling says "walking or sprinting".

**Known risk with Command as the roll key:** macOS treats Command plus a letter as a shortcut (`Command+W` closes the window, `Command+Q` quits), and often fails to report other keys being released while Command is held. Untested; check in Studio and the Roblox player before relying on it.

### Quick turn [Established]

`R` swings the view round 180 degrees. As built: works in every state except mid-mantle; speed is not kept, so a sprinting player slows sharply and then accelerates the other way.

### Clambering mode: automatic or manual [Established]

"Clambering" means vaulting, mantling and grabbing ledges. This replaces the concept doc's "vaulting should require deliberate player input" as a hard rule.

- Players choose in settings (`P`). Keyboard and mouse default to **automatic**: moving into an obstacle clambers it, on the ground or in the air.
- **Manual:** the same only happens while `Space` is held or was just pressed. It will be rewarded with a small amount of stamina given back (not built; no stamina yet). Obstacles matter, and misreading one costs time.
- **Gamepad and touch** clamber automatically by default; manual is available to them in settings.

**Lowest obstacle [Established]:** Roblox's character steps over anything lower than about 2 studs by itself, so obstacles under about 2 studs count as steps in both modes and are never vaulted or mantled. (`Vault.MinHeight` and `Mantle.MinHeight` are 1.9, so an obstacle exactly 2 studs tall still counts.)

**[Open] [Q4]** What vaulting "under" an obstacle means.

### Vault [Established]

Traverses obstacles. As built: low, thin obstacles with floor behind them are vaulted in one arc, keeping nearly all your speed. Deeper low obstacles are mantled onto instead.

### Mantle [Established]

Climb ledges, pipes and other structures, to escape, pursue and reach hidden areas. The user asked for mantling onto "a block that is at least 5 blocks high"; **agent's reading, to confirm:** blocks of 5 studs and more must work. As built: up to 6.5 studs, from the ground or from a jump. Climbing will be affected by weight (not built).

### Ledge grab [Established]

A ledge too tall to mantle and within reach is grabbed while airborne. While hanging: `Space` pulls up, crouch lets go, left/right shimmies along the ledge. **[Open]** whether hanging is time-limited or drains stamina; for now it is unlimited.

### Wall-run [Established]

An alternative route where conventional ones do not exist. As built: jump alongside a wall while moving along it fast enough and you run along it for a short time in a shallow arc. `Space` wall-jumps off; crouch drops off. It also ends when the wall ends, you reach the floor, or speed runs out. You cannot run the same wall twice before landing. Automatic in both clambering modes.

### Jump

As built: a press just before landing is remembered (buffered jump); a press just after walking off an edge still jumps (coyote jump). `JumpCooldown` blocks a new jump for a moment after landing from one, and takes priority over the buffered jump. Wall jumps ignore it.

### Camera feel and settings [Established]

Movement should feel physical, with a setting to reduce camera motion.

As built: head bob scaled with speed (up-down and side-to-side; strafing rocks sideways more and bounces less); a landing dip that grows with fall height; a slight lean when strafing; a tilt away from the wall while wall-running; small downward looks during mantles and vaults; the camera turning over in a roll. **Reduce camera motion** removes all of these except a smaller landing dip and a smaller speed field-of-view change. Settings are not saved between sessions yet (Phase 5).

## Stamina and momentum [Established] — not built

- Parkour consumes stamina: **sprinting, sliding, diving and rolling** cost it.
- Momentum reduces the cost: keeping flow lets a player traverse for longer. Poor planning costs; skill is rewarded.
- At zero stamina the player's **speed is slowed**: reduced, never disabled.
- Manual clambering gives a small amount back.
- Stamina is a player skill: capacity or efficiency improves with level.
- It must **not** feel like a traditional stamina bar that punishes players for simply moving.

**[Open] [Q5]** How much speed is lost at zero stamina; what each action costs; whether vault, mantle, wall-run and jump cost any; how stamina recovers; how "momentum" is measured for the discount and for the "chance for increased momentum".

## Weight [Established] — not built

- Weight is the total of items **collected during the deployment**. The loadout a player deploys with has weight values, but they have **no effect on that player**. They count when equipment changes hands: if Player B downs Player A and takes their equipment, Player B feels its weight (C12).
- More loot → less efficient movement → a real decision about whether more loot is worth it. Heavily loaded players are never made incapable of parkour.
- Each piece of equipment (weapons, special grenades, grenades) has a weight value.

Two levels:

1. **Inhibition threshold.** At or above it: slower sprint acceleration, lower top speed (C8), stamina drains a little faster and regenerates slower, less chance for increased momentum. Slides are shorter and climbing is harder.
2. **Approaching maximum carry weight.** Stamina is capped at **20% of the player's maximum**. Maximum stamina differs per player by rank, class and faction (later work).

| Load | Mobility | Effect |
| :-- | :-- | :-- |
| Light | High | Fast acceleration, longer slides, easier traversal |
| Medium | Balanced | Moderate acceleration and traversal limitations |
| Heavy | Reduced | Slower acceleration, shorter slides, more difficult traversal |

**[Open] [Q6]** The threshold and maximum values; what "approaching" means as a number; penalty sizes; whether non-equipment items (resources, quest items) have weight; whether anything can be picked up beyond the maximum.

For the prototype, weight and stamina capacity are test values set by hand; the inventory (`EXTRACTION_SPEC.md`) and progression systems supply them later.

## Character and input [Established]

- Custom character rig, with the body visible in first person (looking down shows the body; empty hands are visible). Until it exists the prototype uses a standard Roblox R15 rig, with the code written so the rig can be swapped.
- Input is built as actions ("sprint", "vault") mapped to devices, so gamepad and touch can be added without changing movement code. Only keyboard and mouse are bound.

## Implementation status

Checked automatically by `python3 tools/studio.py test` (38 checks, all passing on 2026-11-11; `src/client/Dev/MovementTests.luau`):

| Area | What the script checks |
| :-- | :-- |
| Walk, sprint | Reaches walk and sprint speed in the right state |
| Direction speed | Walking backwards is capped; sprint works backwards and sideways, slower; a diagonal is no faster than straight ahead |
| Strafing | A counter-strafe reverses quickly with no speed spike; forward sprint speed is not carried into a backpedal; no speed gained in the air while backpedalling; a sideways cut out of a sprint keeps most of its speed |
| Slide | A crouch tap while sprinting slides with a boost and ends in a crouch; down the 15° ramp it keeps its speed and ends on the flat |
| Crouch | Tap toggles it; stays without the key at crouch speed and height; sprint stands you up; cannot stand under the tunnel roof |
| Prone | Hold crouch lowers the body; crawl speed; tap stands up; cannot stand under the tunnel roof |
| Dive | Leaves the ground and lands prone |
| Jump | Height matches the config; buffered jump (checked with the cooldown off); coyote jump (on a slow frame rate the script widens the window, so the tuned window itself is unverified); jump cooldown |
| Roll | Air roll after an 8 stud fall; ground roll while walking; no roll while standing still |
| Vault | Automatic vault over the 2 stud box while sprinting |
| Mantle | Automatic mantle onto the 4 stud box |
| Ledge grab | Grab on the 8 stud wall from a jump; Space pulls up onto the top |
| Wall-run | Starts from a jump beside the wall; Space wall-jumps away from it |

Checked once by hand with simulated keys (2026-11-10), not in the script: quick turn; slide-hop; manual clamber mode; ledge shimmy and drop; mantles of 5 and 6 studs; the settings panel and reduced camera motion; that a flat-ground jump does not roll.

**Not tested:** slide steering; slide on landing; ending a slide early with crouch; getting up from prone with Space; diving sideways or backwards; strafing around cover or against a wall; the Command key on a Mac; anything with two players.

**Not looked at by eye by anyone:** the visible body, the roll camera, head bob (including the strafe bob), landing dip and lean. Feel has not been judged beyond the user's own number tuning.
