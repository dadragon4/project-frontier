# MOVEMENT_SPEC.md — PROJECT FRONTIER

Movement is pillar #1 and the first system to prototype. Status labels are defined in `AGENTS.md`; register entries (`Cn`, `Qn`) are in `DECISIONS.md`.

**No tuning numbers are established.** Every speed, distance, cost and threshold is to be found by playtesting; values will live in one configuration module so they can be changed without touching logic.

## Intent [Established]

- Traversal is inseparable from gameplay. Momentum, acceleration, weight and stamina interact.
- Movement is responsive and rewards players who keep their flow through an environment.
- First-person during deployments.
- Custom-built rather than relying entirely on default Roblox character movement.

## Abilities

### Sprint — Essential [Established]

- Responsive acceleration; smooth and controllable.
- Influenced by carried weight (exactly how: **[Conflict C8]**).
- Momentum carries into other movement actions.

### Slide — Essential [Established]

- A momentum-based transition out of sprinting. Depends on acceleration and momentum; players build speed first.
- Momentum is preserved where appropriate.
- Connects naturally into other traversal actions.
- Slide distance is affected by weight (longer when light, shorter when heavy).

### Clambering mode: automatic or manual [Established — user decision 2026-11-10]

This supersedes the concept doc's "vaulting should require deliberate player input" as a hard rule. "Clambering" means vaulting and mantling together.

- Players choose in settings whether clambering is **automatic** or **manual**. Players should have options.
- **Manual** uses a dedicated key, and is rewarded with a **stamina boost**. The key is **Space** for vault, mantle and ledge grab (user decision 2026-11-10).
- **Gamepad and touch** use auto-clambering.
- The original intent still stands for manual players: obstacles matter, and misreading one costs time.

- The stamina boost is a **small amount of stamina given back**.
- Keyboard and mouse default to **automatic**.

As built: **automatic** — moving into an obstacle vaults, mantles or grabs it (on the ground or in the air); **manual** — the same only happens while Space is held or was pressed within the last 0.25 s. The setting is in the settings panel (`P`). The stamina refund is not built (no stamina yet).

**Known limitation:** Roblox's built-in character automatically steps over anything lower than about 2 studs. So in manual mode, obstacles under roughly 2 studs cannot block anyone; the 1.5-stud test rail was simply walked over. Options: raise the lowest vault height to about 2 studs (so low obstacles count as steps), or accept it. **Not decided.**

**[Open] [Q4]** Whether gamepad and touch players may opt into manual; what vaulting "under" an obstacle means.

### Vault — Essential [Established]

- Traverses obstacles, in automatic or manual mode as above.
- The master prompt speaks of vaulting "over or under" an obstacle.

**[Proposed]** as built: obstacles 1.2 to 3 studs tall and at most 4 studs deep, with floor behind them, are vaulted in one smooth arc, keeping 95% of your speed (at least 10). Deeper low obstacles are mantled onto instead. Sliding into an obstacle vaults it too, which covers the "slide into a vault" transition.

### Mantle — Essential [Established]

- Climb ledges, pipes and other structures, in automatic or manual mode as above.
- Supports escaping, pursuing, and reaching hidden areas and stored resources.
- Climbing performance is affected by weight.

### Roll [Established — user decision 2026-11-10]

Two ways to roll (user decisions 2026-11-10):

- **Air roll:** press crouch while in the air, before touching the ground, and you roll on landing — but only if you fell from a height of at least 6 studs. **Agent's reading, to confirm:** "height" is measured as the drop from the highest point of the jump or fall to the landing spot. A normal jump on flat ground (3.25 studs) is too low; jumping or falling off something 6 studs or taller qualifies. Below that, crouch pressed in the air behaves as before: landing fast gives a slide, landing slowly with crouch held gives a crouch.
- **Ground roll:** press crouch twice quickly (within 0.3 seconds) while on the ground — standing, walking, sprinting, crouching or sliding. The roll goes in the direction you are pushing, or straight ahead if you are not.

**[Proposed]** details as built: the roll keeps the speed you had (at least 10, at most 24 studs/s), lasts about half a second, keeps the body low, and turns the camera over once (can be set to 0 in the config). Afterwards: crouch held → crouch; sprint held → sprint; otherwise walk. Not built: a hard-landing penalty that the roll would avoid (a possible later addition, not decided).

### Quick turn [Established — user decision 2026-11-10]

Pressing `R` makes the player do a quick turn: the view swings round 180 degrees.

**[Proposed]** details as built: the turn takes 0.18 seconds and works in every state except mid-mantle. Speed is not kept through the turn; the normal turning rules apply, so a sprinting player slows sharply and then accelerates the other way. (An alternative would be to keep full speed through the turn; not decided.)

### Mantle heights [Established — user decision 2026-11-10]

The user asked for mantling onto "a block that is at least 5 blocks high". **Agent's reading, to confirm:** mantling must handle blocks of 5 studs and more. As built, it works on blocks up to 6.5 studs tall (from the ground or from a jump). Low thick blocks that cannot be vaulted are mantled too (from 1.2 studs). Taller ledges are grabbed instead (see Ledge grab). The limits are in the config.

### Crouch — Essential [Established]

Responsive and intuitive. For stealth, tactical positioning, getting under obstacles, and reacting to threats.

### Wall-run — High [Established]

An alternative route where conventional ones (climbing, ladders) do not exist. Complements the rest of the system.

**[Proposed]** as built: jump alongside a wall while moving along it at 12 studs/s or more, and you run along it for up to 1.3 s, with a small upward kick at the start that curves down. Space pushes off into a **wall jump** (keeping 80% of the speed); crouch drops off. The run also ends when the wall ends, you reach the floor, or speed runs out. You cannot run the same wall twice before landing. Wall-run is automatic in both clambering modes (not decided otherwise).

### Ledge grab — High [Established]

Integrates with mantling and wall-running; supports natural movement between surfaces.

**[Proposed]** as built: a ledge too tall to mantle (above 6.5 studs, up to 10, and within arm's reach) is grabbed while airborne. While hanging: **Space** pulls up, **crouch** lets go, **left/right** shimmies along the ledge as long as it continues. **[Open]** whether hanging should be time-limited (or drain stamina once stamina exists); for now it is unlimited.

### Slide transitions — Medium [Established]

Skilled players chain a slide into a vault or another action. Successful chains enable longer gaps and advanced routes.

As built: slide into an obstacle → vault; slide → jump (slide-hop, below); slide → double-tap crouch → roll.

### Slide-hop [Established — user decision 2026-11-10]

Jumping out of a slide keeps a little of the speed, and then acceleration picks back up.

**[Proposed]** as built: +3 studs/s on the jump (never above 26), at most once per second. While sprinting, speed above sprint speed eases off gently (10 studs/s per second) instead of being cut instantly, so the extra speed lasts about half a second after landing.

### Camera feel and settings [Established — user decision 2026-11-10]

Movement should feel physical, with a settings option to reduce camera motion.

**[Proposed]** as built: head bob scaled with speed, up and down each step plus a side-to-side sway (`SideBobAmount`); a landing dip that grows with fall height (none after a roll); a slight lean when strafing; a 10° tilt away from the wall while wall-running; small downward looks during mantles and vaults. **Reduce camera motion** removes the bob, lean, tilts and the roll/mantle/vault camera movements, and shrinks the landing dip (35%) and speed field-of-view change (50%). Settings open with `P` and are **not saved** between sessions yet (that belongs to Phase 5).

## Stamina and momentum [Established]

- Parkour consumes stamina.
- Momentum reduces stamina consumption: keeping flow lets a player traverse for longer.
- Poorly planned movement carries a cost; skilled movement is rewarded.
- Stamina is a player skill. Capacity or efficiency improves as the player levels up through XP.
- It must **not** feel like a traditional stamina bar that punishes players for simply moving.

Two interacting systems: stamina limits how long demanding movement can be sustained; momentum rewards flow and efficient decisions.

Note: one line in the concept doc hedges ("if we use stamina"); the dedicated stamina section and the master prompt both treat stamina as part of the design, so it is recorded as established.

User decisions, 2026-11-10 **[Established]**:

- Carrying heavy items picked up during the deployment (not the deployed loadout) makes stamina drain **a little faster**.
- At zero stamina, movement is **moderately inhibited** — reduced, not disabled.
- Manual clambering gives a stamina boost (see "Clambering mode").

- The "20%" figure is a **weight** rule, not a zero-stamina rule: see "The 20% rule" under Weight.

**[Open] [Q5]** What "moderately inhibited" at zero stamina means concretely; which actions cost stamina; whether plain sprinting costs any; how stamina recovers; how "momentum" is measured for the discount and for the "chance for increased momentum".

## Weight [Established]

- Weight is the total mass of items **collected during the deployment**. The loadout the player deployed with does not count.
- More loot → more weight → less efficient movement → a real decision about whether more loot is worth it.
- Heavily loaded players are never made incapable of parkour.

Concept-doc tiers:

| Load | Mobility | Effect |
| :-- | :-- | :-- |
| Light | High | Fast acceleration, longer slides, easier traversal |
| Medium | Balanced | Moderate acceleration and traversal limitations |
| Heavy | Reduced | Slower acceleration, shorter slides, more difficult traversal |

**[Conflict C8]** What weight affects:

- Concept doc: acceleration, slide distance, stamina consumption, climbing performance. Sprint is described as "responsive acceleration influenced by carried weight".
- Master prompt: acceleration, movement efficiency, sliding, traversal performance; under Sprint, "movement **speed** influenced by weight"; and "the exact weight thresholds, penalties, and interaction with stamina are not finalized".
- **Resolved 2026-11-10:** weight raises stamina drain slightly, and weight lowers top speed.

### Weight model [Established — user decision 2026-11-10]

- Each piece of equipment (weapons, special grenades, grenades) has an assigned weight value.
- Weight is **threshold-based**: when the total reaches or exceeds a specific value, inhibitions begin:
  - slower acceleration when sprinting,
  - lower stamina regeneration,
  - less chance for increased momentum.
- **Weight also lowers top speed** (user ruling 2026-11-10, settles C8).
- Earlier the same day: a heavy scavenged load also drains stamina a little faster.

**[Established — ruling 2026-11-10, settles C12]** The loadout a player deploys with carries weight values, but they have **no effect on that player**. Weight activates when equipment changes hands: if Player B downs (kills) Player A and takes their equipment, Player B feels its weight.

**[Established — ruling 2026-11-10] The 20% rule.** There is a maximum weight a player is allowed to carry. As a player approaches it, their stamina is **limited to 20% of their maximum stamina**. Maximum stamina differs per player by rank, class and faction (to be worked on later).

So there are two weight levels: the inhibition threshold (slower sprint acceleration, lower stamina regeneration, less chance for increased momentum) and, above it, the approach to maximum carry weight (stamina capped at 20%).

**[Open] [Q6]** The threshold and maximum values; what "approaching" means as a number; penalty sizes; whether non-equipment items (resources, quest items) also have weight; whether anything can be picked up beyond the maximum.

## Dependencies on other systems

For the prototype, weight is a test value set by hand; the real number will later come from the inventory system (`EXTRACTION_SPEC.md`). Stamina capacity is a fixed test value; progression will supply it later. Neither system is built during the movement milestone.

## Technical approach

See `TECHNICAL_ARCHITECTURE.md` → "Movement architecture".

## Implementation status

Checked automatically by `python3 tools/studio.py test` (18 checks, all passing on 2026-11-10; see `src/client/Dev/MovementTests.luau`):

| Area | What the script checks |
| :-- | :-- |
| Walk, sprint | Reaches walk and sprint speed in the right state |
| Slide | Starts from a sprint with a boost; ends in a crouch |
| Crouch | Speed and lowered body; stays crouched under the tunnel roof and stands once clear |
| Jump | Height matches the config; a jump pressed just before landing fires on landing; coyote jump (on a slow frame rate the script widens the window, so the tuned 0.12 s itself is unverified); jump cooldown (tested with 0.5 s: a press during it is ignored, one after it jumps) |
| Roll | Air roll after an 8 stud fall; ground roll from a crouch double-tap |
| Vault | Automatic vault over the 2 stud box while sprinting |
| Mantle | Automatic mantle onto the 4 stud box |
| Ledge grab | Grab on the 8 stud wall from a jump; Space pulls up onto the top |
| Wall-run | Starts from a jump beside the wall; Space wall-jumps away from it |

Checked once by hand through Studio with simulated keys (2026-11-10), not in the script: quick turn; turning without "ice" (full reverse in about 0.45 s); slide-hop (21 → 24, easing back over about 0.5 s); manual clamber mode; ledge shimmy and drop; mantles of 5 and 6 studs; the settings panel and reduced camera motion; that a normal flat-ground jump does not roll.

**Not tested:** slide on slopes and slide steering; slide on landing; momentum in the air; the Command key on a Mac; anything with two players. **Not looked at by eye by anyone:** the visible body, the roll camera, head bob, landing dip and lean. Nobody has yet judged how it feels. All numbers in `src/shared/Config/MovementConfig.luau` are untuned first guesses.

Keys: `W A S D` move, `Left Shift` sprint (hold), `C`, `Left Ctrl` or (on a Mac) `Left Command` crouch (hold; press while sprinting to slide), `Space` jump / manual clamber / pull up / wall jump, `R` quick turn, `P` settings.

Jump height is 3.25 studs (lowered from 6, then 4.5, at the user's request on 2026-11-10 for a more realistic human jump; Roblox's default is 7.2). `JumpCooldown` (requested by the user 2026-11-10) sets how long after landing from a jump before the next one; it is 0, so jumps work straight away until it is tuned. Wall jumps ignore it.

Roll: tap crouch while in the air after a drop of 6 studs or more, or double-tap crouch on the ground.

Quick turn: `R`.

Vault / mantle / ledge grab: move into the obstacle (automatic), or press Space at it (manual). Wall-run: jump beside a wall while running along it.

**Known risk with Command as crouch:** macOS treats Command plus a letter as a shortcut. Crouch-walking means holding Command with `W`, `A`, `S` or `D`, and `Command+W` / `Command+Q` normally close the window or quit the app. macOS also often fails to report other keys being released while Command is held, which can leave a movement key "stuck". To be checked in Studio and in the Roblox player before relying on it.

## Open items specific to movement

See `DECISIONS.md`: Q2–Q7, C8 and C12.

## Character and input [Established — user decision 2026-11-10]

- Custom character rig, with the body visible in first person (looking down shows the body; empty hands are visible).
- Input is built as actions ("sprint", "vault") mapped to devices, so gamepad and touch can be added without changing movement code. Only keyboard and mouse are bound for the prototype.

**[Established 2026-11-10]** Until the custom rig exists, the prototype uses a standard Roblox R15 rig, with the code written so the rig can be swapped.
