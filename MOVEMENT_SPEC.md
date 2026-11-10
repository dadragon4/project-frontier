# MOVEMENT_SPEC.md — PROJECT FRONTIER

Movement is pillar #1 and the first system to prototype. Status labels are defined in `AGENTS.md`; register entries (`Cn`, `Qn`) are in `TASKS.md`.

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
- **Manual** uses a dedicated key, and is rewarded with a **stamina boost**.
- **Gamepad and touch** use auto-clambering.
- The original intent still stands for manual players: obstacles matter, and misreading one costs time.

- The stamina boost is a **small amount of stamina given back**.
- Keyboard and mouse default to **automatic**.

**[Open] [Q4]** Whether gamepad and touch players may opt into manual; what vaulting "under" an obstacle means.

### Vault — Essential [Established]

- Traverses obstacles, in automatic or manual mode as above.
- The master prompt speaks of vaulting "over or under" an obstacle.

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

The user asked for mantling onto "a block that is at least 5 blocks high". **Agent's reading, to confirm:** mantling must handle blocks of 5 studs and more. As built, it works on blocks 3 to 6.5 studs tall; lower blocks are simply jumped onto (vaulting comes later), taller ledges are out of reach (ledge grab comes later). Both limits are in the config.

As built it is **automatic** (keyboard default per the earlier decision): jump at the block while pushing toward it. The manual mode with its own key and stamina refund is not built yet; the key has not been chosen.

### Crouch — Essential [Established]

Responsive and intuitive. For stealth, tactical positioning, getting under obstacles, and reacting to threats.

### Wall-run — High [Established]

An alternative route where conventional ones (climbing, ladders) do not exist. Complements the rest of the system.

### Ledge grab — High [Established]

Integrates with mantling and wall-running; supports natural movement between surfaces.

### Slide transitions — Medium [Established]

Skilled players chain a slide into a vault or another action. Successful chains enable longer gaps and advanced routes.

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

| Ability | Status (2026-11-10) |
| :-- | :-- |
| First-person camera with visible body | Runs without errors; first-person lock and FOV change confirmed. Body visibility **not yet looked at** |
| Walk / sprint with acceleration | **Tested in Studio**: 12 and 20 studs/s reached (retuned 2026-11-10: slower speeds and acceleration) |
| Turning (no "ice") | **Tested in Studio**: full reverse from sprint to walking the other way takes about 0.45 s (was about 1.6 s) |
| Crouch (with headroom check) | **Tested in Studio**: lowers, slows (now 7), stays crouched under the tunnel roof, stands after it |
| Slide (momentum, slope, steering) | **Tested in Studio** on flat ground: from sprint it starts at 24 and reaches crouch in about 0.65 s (was about 1.5 s). Slope and steering **not yet tested** |
| Roll | **Tested in Studio**: no roll from a normal flat-ground jump (slides instead); air roll after jumping off the 8 stud ledge; ground roll from a crouch double-tap while standing and while sprinting; two slow taps (0.6 s apart) correctly do not roll. Camera turn-over returns level. **Not yet looked at by eye** |
| Quick turn (`R`) | **Tested in Studio**: view turns 180° in about 0.2 s and stays turned, standing and while sprinting |
| Mantle (automatic) | **Tested in Studio**: 4, 5 and 6 stud blocks mantled from a running jump; 8 stud ledge correctly not mantled. Manual mode **not built** |
| Air momentum | Jump and landing tested from standstill; momentum in the air **not yet tested** |
| Input buffering and coyote jump | Buffered jump **tested in Studio** (pressed in mid-air, fired on landing). Slide-on-landing and coyote jump **not yet tested** |
| Vault, ledge grab | Not started (M1.2) |
| Wall-run, transitions, stamina, weight | Not started (M1.3) |

Tests on 2026-11-10 were run by the agent through Studio with simulated key presses, reading the debug readout. Nobody has yet judged how it feels. All numbers in `src/shared/Config/MovementConfig.luau` are untuned first guesses.

Keys: `W A S D` move, `Left Shift` sprint (hold), `C`, `Left Ctrl` or (on a Mac) `Left Command` crouch (hold; press while sprinting to slide), `Space` jump.

Jump height is 3.25 studs (lowered from 6, then 4.5, at the user's request on 2026-11-10 for a more realistic human jump; Roblox's default is 7.2).

Roll: tap crouch while in the air after a drop of 6 studs or more, or double-tap crouch on the ground.

Quick turn: `R`.

Mantle: jump at a block between 3 and 6.5 studs tall while pushing toward it.

**Known risk with Command as crouch:** macOS treats Command plus a letter as a shortcut. Crouch-walking means holding Command with `W`, `A`, `S` or `D`, and `Command+W` / `Command+Q` normally close the window or quit the app. macOS also often fails to report other keys being released while Command is held, which can leave a movement key "stuck". To be checked in Studio and in the Roblox player before relying on it.

## Open items specific to movement

| ID | Status |
| :-- | :-- |
| Q2 | **Decided:** keyboard and mouse for the prototype, built on an input foundation that gamepad and touch can plug into later. |
| Q3 | **Decided:** a custom rig with a visible body. Players see their own hands when carrying no weapon. Still open: who builds the rig, and what stands in for it during the prototype. |
| Q4 | Mostly decided (see "Clambering mode"); details open. |
| Q5 | Partly decided (see "Stamina and momentum"); details open. |
| Q6 / C8 | Mostly decided (see "Weight model"): threshold-based. Loadout does not count for its owner; weight lowers top speed. Open: threshold and maximum values. |
| Q7 | **Decided:** placeholder animations are fine for now. |

## Character and input [Established — user decision 2026-11-10]

- Custom character rig, with the body visible in first person (looking down shows the body; empty hands are visible).
- Input is built as actions ("sprint", "vault") mapped to devices, so gamepad and touch can be added without changing movement code. Only keyboard and mouse are bound for the prototype.

**[Established 2026-11-10]** Until the custom rig exists, the prototype uses a standard Roblox R15 rig, with the code written so the rig can be swapped.
