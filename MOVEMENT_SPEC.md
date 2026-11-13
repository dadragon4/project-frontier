# MOVEMENT_SPEC.md — PROJECT FRONTIER

Movement is pillar #1. Status labels are defined in `AGENTS.md`; register entries (`Cn`, `Qn`) are in `DECISIONS.md`.

**Numbers live in `src/shared/Config/MovementConfig.luau`, not here.** Each one has a comment there saying what it does. This file describes behaviour; it quotes a number only where the user ruled on it. No tuning value is final until the tuning pass (M1.4).

## Intent [Established]

- Traversal is inseparable from gameplay. Momentum, acceleration, weight and stamina interact.
- Movement is responsive and rewards players who keep their flow through an environment.
- First-person during deployments.
- Custom-built rather than relying entirely on default Roblox character movement.

## Keys

`W A S D` move · `Left Shift` sprint (toggle by default, hold optional; any direction) · `C` tap: crouch / slide / stand up · `C` hold: prone / dive · `Left Ctrl` (or `Left Command` on a Mac) roll · `Space` jump / manual clamber / pull up / wall jump · `R` quick turn · `P` settings.

## Abilities

Everything in this section is built unless it says otherwise. "As built" lines are the agent's **[Proposed]** details, open to change.

### Sprint [Established]

- Responsive acceleration; smooth and controllable. Momentum carries into other movement actions.
- Works in any direction. Moving sideways or backwards is slower than straight ahead, in every ground state (`StrafeSpeedScale`, `BackSpeedScale`, blended in between).
- Added weight lowers top speed (see "Weight"; not built).

**Toggle or hold [Established]:** players choose in settings (`P`). The default is **toggle** (user decision 2026-11-12): the sprint key switches sprinting on, and off again, so it does not have to be held. **Hold** is the alternative: sprinting lasts only while the key is down.

A toggled sprint also switches itself off whenever leaving it on would surprise the player (user decisions 2026-11-12):

- when the player stops pushing a direction, so setting off again walks;
- when they crouch, slide, dive or go prone — otherwise a tap of crouch would stand straight back up into a sprint, and crouching would be impossible. You come out of a slide crouched, as in hold mode;
- when they run out of stamina, so recovering does not resume a sprint on its own.

A roll does not clear it (**agent's reading, to confirm**): a roll out of a sprint continues sprinting, as it does in hold mode. Pressing sprint during a slide still cuts the slide back into a sprint in both modes.

### Strafing [Established: precise, responsive, competitive, still momentum-based]

As built:

- Pushing against your own momentum (a counter-strafe) brakes at its own faster rate, `ReverseDecel`. Letting go of the keys uses `GroundDecel`; cornering uses `TurnFriction`.
- The gentle bleed-off of extra sprint speed only applies when pushing forward, so forward sprint speed cannot be carried into a strafe or a backpedal.
- Steering in the air cannot build more speed than walking that way would.
- **Camera steering in the air** (user request 2026-11-12): turning the view bends your flight by a share of the turn (`AirCameraSteer`, 0.3, agent's guess), with or without a key held. Speed is kept. Not during a dive, which has no steering.
- Pressing sprint while already strafing goes straight to sprint-strafe speed, with no build-up (user ruling 2026-11-12). It applies to a sideways push more than 60 degrees off straight ahead (`StrafeSprintSnapDot`); forward and diagonal sprints still build up.
- A sideways cut out of a sprint picks up the new direction at the normal (fast) rate.
- Measured at 60 frames per second with the current config: walk reversal 0.23 s; sprint reversal 0.37 s; a sprint cut to the side dips from 25 to 19.6 and completes in 0.22 s.

### Crouch key: tap and hold [Established]

| | Tap `C` | Hold `C` |
| :-- | :-- | :-- |
| Standing or walking | Crouch (stays crouched; tap again to stand) | Prone |
| Sprinting | Slide (no need to keep the key down) | Dive, landing prone |
| Crouched | Stand up | Prone |
| Sliding | End the slide early, into a crouch (pressing sprint again ends it into a sprint) | — |
| Prone | Stand up | — |

- Holding sprint while moving stands you up from a crouch and runs.
- Slide, roll and dive stay three separate moves.
- As built: a press released within `CrouchHoldTime` is a tap, so tap actions start when the key comes back up.

### Crouch [Established]

Responsive and intuitive. For stealth, tactical positioning, getting under obstacles, and reacting to threats. You cannot stand up under a low roof.

### Slide [Established]

- A momentum-based transition out of sprinting; players build speed first. Momentum is preserved where appropriate.
- It only starts when sprinting straight ahead; diagonals, sideways and backwards crouch instead (`Slide.MinForwardDot`; no diagonal slide, user ruling 2026-11-12).
- On flat ground it ends after about **15 studs** (`Slide.Friction`; shortened by 2 studs on 2026-11-12), and never travels further than **25 studs** (`Slide.MaxFlatDistance`). Down a slope it keeps going until the slope levels out, and can be ended early by jumping or pressing crouch.
- Down a slope its speed is capped at **28**, or **30** if the slide was started while in FLOW (`Slide.SlopeMaxSpeed`, `Slide.FlowSlopeMaxSpeed`; user rulings 2026-11-12).
- Steering turns the slide at about 74 degrees per second (`Slide.SteerRate`, raised by 5 degrees per second on 2026-11-12).
- **Camera steering** (user request 2026-11-12): turning the view also turns the slide, by a share of the turn (`Slide.CameraSteer`, 0.5, agent's guess: look 90 degrees left and the slide bends 45). Speed is kept. The quick turn (`R`) does not count as steering.
- **Pressing sprint again during a slide cuts it straight back into a sprint** (user ruling 2026-11-11). It must be a new press: sprint is usually still held from the run-up, and holding it does not end the slide. In Toggle mode that press would flip the sprint switch off, so it is turned back on (fixed 2026-11-13: before, it did nothing when the switch was already on).
- **Cooldown** (user ruling 2026-11-11): after a slide ends, another cannot start for 1 second (agent's guess at the value), so sprint and slide cannot be spammed. A crouch tap during the cooldown crouches instead, as it does when too slow to slide.
- Chains into other moves: slide into an obstacle → vault; slide → jump (slide-hop). **There is no roll out of a slide** (user ruling 2026-11-11): the roll key does nothing while sliding.
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
- **Ground roll:** press the roll key while walking or sprinting. Standing still does not roll, neither does sliding (user ruling 2026-11-11), and neither does moving backwards (user ruling 2026-11-13). The roll goes in the direction you are pushing.

As built: the roll keeps your speed (within limits), lasts about half a second, keeps the body low, and turns the camera over once. Afterwards: sprint if sprint is held, otherwise walk.

**Agent's readings, to confirm:** "height" is the drop from the highest point of the jump or fall to the landing spot. Rolling from a crouch was removed, since the ruling says "walking or sprinting".

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

**Tallest obstacle [Established]:** up to 3 studs is vaulted; anything taller is mantled onto. (`Vault.MaxHeight` is 3.2 rather than 3.0, the same slack as `MinHeight`, so an obstacle exactly 3 studs tall still vaults instead of landing either side of the limit — user ruling 2026-11-12.)

### Mantle [Established]

Climb ledges, pipes and other structures, to escape, pursue and reach hidden areas. The user asked for mantling onto "a block that is at least 5 blocks high"; **agent's reading, to confirm:** blocks of 5 studs and more must work. As built: up to 6.5 studs, from the ground or from a jump. Climbing will be affected by weight (not built).

### Ledge grab [Established]

A ledge too tall to mantle and within reach is grabbed while airborne. While hanging: `Space` pulls up, crouch lets go, left/right shimmies along the ledge. **Hanging drains stamina** (user ruling 2026-11-11): 5 per second as built (agent's guess at the value), and nothing comes back meanwhile. **At zero stamina the player lets go** (user ruling 2026-11-11). As built, an exhausted player also cannot grab a ledge until they have recovered, or they would grab and drop at once; a pull-up pressed at the last moment still happens.

### Wall-run [Established]

An alternative route where conventional ones do not exist. **A wall-run needs a sprint first** (user ruling 2026-11-12): it only starts if you left the ground from a sprint, a slide or another wall-run. As built: jump alongside a wall while moving along it fast enough and you run along it in a shallow arc. `Space` wall-jumps off; crouch drops off.

**It lasts until your feet reach the ground** (user ruling 2026-11-12): there is no time limit. It also ends when the wall ends or speed runs out (not when stamina runs out). The arc is flat enough to clear about 50 studs at sprint speed (`WallRun.Gravity` 3, about 2.2 s); a run started **in FLOW** is flatter still and lasts longer (`WallRun.FlowGravity` 2, about 3 s). Both values are the agent's guesses. The run rises only about half a stud above where it starts (`WallRun.UpKick` 2, was 6; lowered on request 2026-11-13).

**Wall to wall** (user ruling 2026-11-12): a wall jump can carry you onto the opposite wall, which starts a fresh run. Straight after a wall jump the steep angle toward the new wall is allowed (`WallRun.WallToWallApproachDot`). **Wall-running drains stamina** (user ruling 2026-11-11; see Stamina), and an exhausted player cannot start one. You cannot run the same wall twice in a row before landing; bouncing between two walls is limited only by stamina. Automatic in both clambering modes.

### Jump

**[Established — user rulings 2026-11-13]**

- A fresh jump rises **7 studs** (`JumpHeight`).
- **Weighted fall:** the rise is a normal arc, but you come down faster than you went up, like jumping with equipment (`JumpFallGravityScale`, 1.6, agent's guess). The height is unchanged.
- **Jump fatigue:** each jump in a row is **2 studs lower**: 7, 5, 3. Landing the 3-stud jump blocks jumping for **2 seconds**, then the next jump is 7 again. Resting on the ground for 2 seconds without jumping also brings back the full 7 (`JumpHeightStep`, `JumpMinHeight`, `JumpFatigueCooldown`, `JumpRestTime`). Wall jumps and dives are separate and do not count; a jump out of a slide does.

As built: a press just before landing is remembered (buffered jump); a press just after walking off an edge still jumps (coyote jump). `JumpCooldown` blocks a new jump for a moment after landing from one, and takes priority over the buffered jump. Wall jumps ignore it.

### Camera feel and settings [Established]

Movement should feel physical, with a setting to reduce camera motion.

The view cannot look further down than 60 degrees below level (`Camera.MaxLookDown`; user ruling 2026-11-12, the value is the agent's guess), so it never ends up inside the body. Walking has its own side-to-side sway, `CameraFeel.WalkSideBobAmount` (0.08 at walk speed; user ruling 2026-11-12); `SideBobAmount` covers sprint, crouch and crawl. Sprinting forward or on a forward diagonal tilts the view left and right with the steps (`CameraFeel.SprintSwayTilt`, 1 degree, a guess); `SideBobAmount` only slides the camera sideways, which mostly shows on your own body.

As built: head bob scaled with speed (up-down and side-to-side; strafing rocks sideways more and bounces less); a landing dip that grows with fall height; a slight lean when strafing; a tilt away from the wall while wall-running; small downward looks during mantles and vaults; the camera turning over in a roll. **Reduce camera motion** removes all of these except a smaller landing dip and a smaller speed field-of-view change. Settings are not saved between sessions yet (Phase 5).

The settings panel (`P`) holds three options so far: camera motion, clamber mode (automatic / manual) and sprint mode (toggle / hold).

## Stamina and FLOW [Established] — built 2026-11-11

Design intent (user, 2026-11-11): **momentum rewards preparation, FLOW rewards execution, stamina rewards intelligent movement.**

- Parkour consumes stamina: **sprinting, sliding, diving and rolling** cost it.
- Momentum reduces the cost: keeping flow lets a player traverse for longer. Poor planning costs; skill is rewarded.
- At zero stamina the player is **exhausted**: slowed, and unable to use anything that needs stamina until it recovers (user ruling 2026-11-11, replacing "reduced, never disabled" from 2026-11-10). Walking, crouching, crawling, jumping, vaulting and mantling always work.
- Manual clambering gives a small amount back.
- Stamina is a player skill: capacity or efficiency improves with level.
- It must **not** feel like a traditional stamina bar that punishes players for simply moving.

### As built

Every number below is an **initial tuning value** (user, 2026-11-11), not final balance. They live in `MovementConfig.Stamina` and `MovementConfig.Flow`. The rules are in two small modules that use no Roblox services, `src/shared/Stamina.luau` and `src/shared/FlowChain.luau`, so the server can run the same rules later.

**Spending and recovery**

| | Value |
| :-- | :-- |
| Maximum | 100 |
| Sprint | 8 per second, for as long as the Sprint state lasts |
| Wall-run | 10 per second while running the wall, less the momentum discount measured when the run starts (up to half off; user ruling 2026-11-12). A normal run of about 2.2 s costs about 22 at most |
| Ledge hang | 5 per second while hanging (agent's guess at the value) |
| Slide / roll / dive | 15 / 15 / 20, once, when the action starts (air rolls included) |
| Recovery | 15 per second, starting 1 second after stamina was last spent |

- Sprinting, wall-running and hanging spend all the time, so nothing comes back while they last.
- Vault, mantle, grabbing a ledge, wall jump and jump cost nothing.
- **With some stamina left but less than an action costs, the action still starts**: it takes what is left, and that exhausts the player.

**Exhaustion.** It starts when stamina reaches zero and ends when stamina is back up to 15, not as soon as it is above zero. While it lasts (user ruling 2026-11-11):

- **Nothing that needs stamina can start**: no sprint, slide, dive, roll, wall-run or ledge grab. A sprint or ledge hang under way ends when stamina runs out; a wall-run, slide, roll or dive already started finishes (wall-run: user ruling 2026-11-12).
- Walk, crouch and crawl speeds are multiplied by 0.70, and so is the speed that steering in the air can build up to (otherwise hopping would get round it).
- Vaults, mantles and jumps are unaffected.
- Sprint held through the recovery starts again by itself once exhaustion ends.

From empty, recovery takes about 2 seconds of not spending: the 1 second wait, then 1 second to reach 15.

**Momentum discount (preparation).** Speed takes up to 50% off a slide, roll or dive: nothing standing still, rising in a straight line to the full 50% at sprint speed (25). Only speed that is real, intended and straight ahead counts: the lower of the speed the movement code asks for and the body's actual speed, measured along where the player is looking. So sideways and backward speed, falling speed, running into a wall and being shoved earn nothing. A slide at its minimum speed (14) costs 10.8; at full sprint, 7.5. Sprint drain itself is not discounted.

**FLOW chain (execution).** Linking abilities gives a little stamina back.

- Actions that count: slide, dive, roll, wall-run, wall jump, vault, mantle, and a jump out of a slide. A plain jump, walking and sprinting do not.
- An action counts when it **finishes**, if it lasted at least 0.15 s (one dropped the instant it began does not).
- The next action must begin within **3 seconds** of the last one finishing. The clock does not run during an action, so a long slope slide cannot break a chain.
- The same action twice in a row keeps the chain alive but counts once.
- The third counted action **completes the chain** and pays **25** stamina, once per chain. A new chain can earn again only after this one has ended (the window ran out).
- **In FLOW** (user rulings 2026-11-12): a hidden meter fills by a third with each counted action. At 100% (the chain is completed) the player is in FLOW until the chain ends. While in FLOW: sprint top speed is **+5** (walk, crouch and crawl are unchanged), the field of view is **+5** degrees, and a slide started now has the higher slope cap. The meter is shown only on the developer readout.

The two are independent: a slide begun at speed is cheaper, and if it is also the first link of a chain the chain pays later. A chain never makes an action cheaper.

**Manual clamber refund.** A vault or mantle in Manual mode gives 3 stamina back (agent's guess at the value). A ledge grab gives nothing, because grabbing, dropping and grabbing again could repeat it on the spot. Vaults and mantles count toward a chain in both modes, so a manual mantle that completes a chain pays both (3 + 5).

**Not player-facing yet.** Stamina and FLOW are shown only on the developer readout. Whether and how players see them is undecided.

**Known limitations**

- Stamina is simulated on the player's own device, like movement, so a cheater could ignore it until the server checks exist (M1.4).
- Sprinting into a wall still drains.
- Nothing stops a slow loop of free moves (vault back and forth) from earning chain rewards, but the 10 per chain limit and the 2 second gap keep it below what simply standing still recovers (15 per second).
- Stamina refills on respawn.

**[Open] [Q5]** Final values for everything above; whether vault, mantle and jump should cost anything; whether an air roll should cost the same as a ground roll; how weight changes stamina (see Weight); what "chance for increased momentum" in the weight rules refers to now that FLOW exists; how stamina is shown to the player.

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

Weight is not built: stamina currently ignores it. For the prototype, weight and stamina capacity are test values set by hand; the inventory (`EXTRACTION_SPEC.md`) and progression systems supply them later.

## Character and input [Established]

- Custom character rig, with the body visible in first person (looking down shows the body; empty hands are visible). Until it exists the prototype uses a standard Roblox R15 rig, with the code written so the rig can be swapped.
- Input is built as actions ("sprint", "vault") mapped to devices, so gamepad and touch can be added without changing movement code. Only keyboard and mouse are bound.

## Implementation status

Checked automatically by `python3 tools/studio.py test` (117 checks; `src/client/Dev/MovementTests.luau`). The last run, before the 2026-11-12 second hotfix set, passed all 112 checks it had then; the changed and new checks below have **not been run yet**. `python3 tools/studio.py quick` runs a short suite instead: 16 checks, one per main feature, each printed with its input and output. Every check other than the sprint-mode ones below runs in **hold** mode, because the script holds the key down and lets go to stop:

| Area | What the script checks |
| :-- | :-- |
| Hotfixes 2026-11-12 | Crouch pressed during a slide ends it in a crouch; out of stamina a slide ends in a walk; a wall jump onto the opposite wall starts a new wall-run; a wall-run lasts past the old 1.3 s; a wall-run started in FLOW uses the flatter curve; no slide while sprinting backwards; no slide on a forward diagonal; a normal flat slide travels about 15 studs; sprinting forward tilts the view; the view stops at the look-down limit; no wall-run from a walk |
| Walk, sprint | Reaches walk and sprint speed in the right state |
| Sprint mode | Toggle: a tap sprints with the key let go, a second tap ends it; the switch survives a slide (which ends in a sprint), and is cleared by stopping and by running out of stamina |
| Direction speed | Walking backwards is capped; sprint works backwards and sideways, slower; a diagonal is no faster than straight ahead |
| Strafing | Sprint pressed while strafing is at full strafe speed at once, and the body follows; pressed while walking forward it still builds up; a counter-strafe reverses quickly with no speed spike; forward sprint speed is not carried into a backpedal; no speed gained in the air while backpedalling; a sideways cut out of a sprint keeps most of its speed |
| Slide | A crouch tap while sprinting slides with a boost and ends in a sprint with the key held; down the 15° ramp it keeps its speed and ends on the flat; the roll key does nothing during it; pressing sprint again cuts it into a sprint; no new slide (and no stamina charge) during the cooldown, and one starts again after it; down the ramp it holds the slope cap (28, or 30 when started in FLOW); a flat slide stops within 25 studs |
| Crouch | Tap toggles it; stays without the key at crouch speed and height; sprint stands you up; cannot stand under the tunnel roof |
| Prone | Hold crouch lowers the body; crawl speed; tap stands up; cannot stand under the tunnel roof |
| Dive | Leaves the ground and lands prone |
| Jump | Height matches the config; buffered jump (checked with the cooldown off); coyote jump (on a slow frame rate the script widens the window, so the tuned window itself is unverified); jump cooldown |
| Roll | Air roll after an 8 stud fall; ground roll while walking; no roll while standing still |
| Vault | Automatic vault over the 2 stud box while sprinting, and over the 3 stud box (the tallest that still vaults) |
| Mantle | Automatic mantle onto the 4 stud box |
| Ledge grab | Grab on the 8 stud wall from a jump; Space pulls up onto the top; hanging drains stamina at the set rate; running out lets go; an exhausted player cannot grab |
| Wall-run | Starts from a jump beside the wall; Space wall-jumps away from it; drains stamina at the set rate less the momentum discount; a run under way finishes even with no stamina; an exhausted player cannot start one |
| Stamina rules (numbers only, no character) | Starts full; never below zero or above the maximum; exhaustion at zero and until the recovery threshold; recovery only after the delay, at the set rate, the same at any frame rate; spending restarts the delay |
| Momentum rules (numbers only) | No discount at rest; grows with speed to the maximum and no further; only speed straight ahead counts; falling, blocked and shoved speed do not; the discount comes off the cost |
| FLOW chain rules (numbers only) | Slide, wall-run, roll pays on the third action; instant actions count; continues inside the window and restarts after it; the window does not run during a long action; a repeated action counts once; dropped, switched-off and unknown actions do not count; a two-move loop stops paying at the limit; a new chain can earn again |
| Stamina on the course | Sprint drains at the set rate and nothing comes back meanwhile; recovery only after the delay; slide and dive at full sprint cost half, once; a roll at walk speed gets a smaller discount and a sideways roll none; a roll or slide that does not start costs nothing |
| Exhaustion on the course | Resting recovers; walking is slowed to 70%; no sprint and no roll while exhausted; running dry ends a sprint and no slide or dive can start; sprint returns once exhaustion is over; normal speed returns at the threshold, not before |
| Manual clamber refund | An automatic vault gives nothing; in Manual mode nothing happens without the key; a manual clamber gives the refund once |
| FLOW chain on the course | Slide, jump out of it, wall-run, wall jump is a chain of four, paid once, with the slide's momentum discount applied separately; the chain ends when its window runs out; slide, jump, mantle completes a chain; in FLOW the sprint is 5 faster and the view wider, and both end with the chain |

Checked once by hand with simulated keys (2026-11-10), not in the script: quick turn; slide-hop; manual clamber mode; ledge shimmy and drop; mantles of 5 and 6 studs; the settings panel and reduced camera motion; that a flat-ground jump does not roll.

**Not tested:** slide steering, and camera steering in a slide or in the air (no scripted check; the user checks by playing); slide on landing; getting up from prone with Space; diving sideways or backwards; strafing around cover or against a wall; the Command key on a Mac; anything with two players. For stamina and FLOW: a real slide, wall-run, roll sequence and a wall-run, wall jump, slide sequence on the course (their rules are checked on the numbers only); a chain that reaches the 10 stamina limit on the course; the manual mantle refund (only a manual vault ran); stamina across a respawn; the debug readout's new lines (not looked at). The course checks for stamina switch sprint drain or recovery off where they would blur the number being measured.

**Not looked at by eye by anyone:** the visible body, the roll camera, head bob (including the strafe bob), landing dip and lean. Feel has not been judged beyond the user's own number tuning.
