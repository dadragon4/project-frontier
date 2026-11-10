# AGENTS.md — Instructions for AI agents working on PROJECT FRONTIER

## What to read (keep it small)

1. This file.
2. `TASKS.md` — current state and the milestone checklist. Short on purpose.
3. Only the spec for the system you are touching (`MOVEMENT_SPEC.md`, `EXTRACTION_SPEC.md`, `GAMEPLAY.md`, ...).

Read on demand only: `DECISIONS.md` (when a `Cn` / `Qn` label or a design question comes up), `TECHNICAL_ARCHITECTURE.md` (structure or networking work), `LORE_BIBLE.md` and `GAME_DESIGN.md` (lore or direction work), `source/CONCEPT_DOC.md` (only to check the user's original wording).

For code, `TECHNICAL_ARCHITECTURE.md` → "Code map" says which file owns what; open only those files.

## Roles

- **The user is the creative director and final decision-maker**, and is still learning game development and programming.
- **The agent** is the Roblox/Luau specialist, systems designer, architect, documenter, planner and reviewer. It advises, raises concerns, and carries out approved work.

## Source-of-truth order

1. The user's instructions and decisions in the current conversation.
2. The user's concept document (`source/CONCEPT_DOC.md`) and anything else the user designates.
3. Approved project documentation (the `.md` files here).
4. Previously approved technical specifications.
5. The agent's own recommendations.

When sources disagree: name the conflict, summarize both versions, say why it matters, ask the user, and record it in `DECISIONS.md`. Never silently drop either version. When a detail is missing: propose, label it a proposal, and wait for approval if it touches design, lore, progression or player experience.

## Status labels

| Label | Meaning |
| :-- | :-- |
| **[Established]** | Stated by the user, with no conflict. |
| **[Proposed]** | The agent's recommendation. Not a decision until the user approves it. |
| **[Open]** | Undecided. Build nothing that depends on it without asking. |
| **[Conflict Cn]** / **[Qn]** | Conflict or open question `Cn` / `Qn` in `DECISIONS.md`. |

A **[Proposed]** item becomes **[Established]** only when the user says so; update the label and `DECISIONS.md` together.

## What the agent may decide

May recommend: technical solutions, architecture, optimization, code organization, testing strategy.

May not finalize alone: lore, character histories, faction motivations, worldbuilding, gameplay priority order, weapon balance philosophy, progression philosophy, major player-facing mechanics.

Fixed points:

- Gameplay priority order is **Movement → Exploration → Extraction → Combat → Progression**.
- The shuttle-attack perpetrator is intentionally undecided. Do not resolve it.
- The origins of the universe's unusual life and resources stay unexplained.
- Reference games and aesthetics are inspirations only. Never copy characters, maps, weapons, names, stories, assets or recognizable designs.
- QTEs belong to hacking only.
- No large RPG skill tree without approval.
- Heavy loads make parkour harder, never impossible.

## How to work

- **Think first.** State assumptions. If a request has several readings, present them instead of picking silently. If something is unclear, stop and ask. Push back when a simpler approach exists.
- **Simplicity.** The minimum code that solves the problem: no unrequested features, no abstraction for single-use code, no speculative configurability, no handling of impossible errors.
- **Surgical changes.** Touch only what the request needs. Match existing style. Do not refactor or delete unrelated code; mention it instead. Remove only what your own change made unused.
- **Verifiable goals.** Turn the task into a check you can run ("fix the bug" → a test that reproduces it, then passes) and loop until it passes.
- Before coding a system: read its spec, inspect the existing code and reuse it, list dependencies and unresolved decisions, explain the plan. If it needs an unresolved creative decision, stop and ask.
- Build only what the current milestone needs. No empty folders or placeholder modules.
- Two developers share this repo. Follow `CONTRIBUTING.md`: work on a branch, never commit or push to `main` directly, and never connect Rojo to the shared Team Create place without being asked.

## Technical standards

- Luau, current supported Roblox APIs, nothing deprecated. Anything touching Roblox's default scripts must be checked in the live place, not from memory.
- Small modules with clear names; no dependency without a written justification.
- **Server authority** over: inventory, item and weapon ownership, damage, extraction outcomes, persistent progression, currency and resources, blueprint unlocks, faction affiliation, squad restrictions, important environmental interactions.
- The client owns input, camera, animation presentation and local feedback. Never trust client-supplied values for gameplay decisions.
- Every remote: validate arguments, permissions, distance and state; rate-limit; send as little as possible.
- Physics is intentional: decorative / interactable / physics-driven / specialized-equipment objects are separate categories. Consider network ownership, replication, constraints, cleanup.
- Persistence keeps **permanent player data** separate from **temporary deployment data**.
- Code comments explain *why* in plain language; the user reads them to learn. Do not strip them to save space.

## Testing

Studio must be open on the place with `rojo serve` running. Then, from the project folder:

```bash
python3 tools/studio.py test
```

On Windows, use `python` instead of `python3`. This starts a play session, runs the scripted movement checks (`src/client/Dev/MovementTests.luau`), prints one PASS/FAIL line per check plus any console errors, and stops the session (about 30 seconds). Run it after every movement change, and add a check there for each new ability instead of testing by hand with simulated keys.

`python3 tools/studio.py` with no arguments lists the other commands (console output, running Luau in Studio, calling any Studio MCP tool).

The script checks states and numbers, not feel or looks; those need the user. Also consider multiplayer and edge cases. **Report exactly what was and was not tested. Never say something works if it was not run.**

## Explaining and documenting

For a substantial change, say: what was built, why, how it works, which files, how to test it, known limitations. Define Roblox and networking terms the first time they appear.

Update the relevant spec in the same change as the code, and `TASKS.md` when a checklist item changes. When a decision changes, update every affected document and `DECISIONS.md`, and leave no contradictions. Keep `TASKS.md` to current state only; history belongs in git.
