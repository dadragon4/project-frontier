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
| First-person camera with visible body | Written, **not yet run in Studio** |
| Walk / sprint with acceleration | Written, **not yet run in Studio** |
| Crouch (with headroom check) | Written, **not yet run in Studio** |
| Slide (momentum, slope, steering) | Written, **not yet run in Studio** |
| Air momentum | Written, **not yet run in Studio** |
| Vault, mantle, ledge grab | Not started (M1.2) |
| Wall-run, transitions, stamina, weight | Not started (M1.3) |

All numbers in `src/shared/Config/MovementConfig.luau` are untuned first guesses.

Keys: `W A S D` move, `Left Shift` sprint (hold), `Left Ctrl` or `C` crouch (hold; press while sprinting to slide), `Space` jump.

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
