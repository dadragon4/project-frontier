# AGENTS.md — Instructions for AI agents working on PROJECT FRONTIER

Read this file first, then `TASKS.md`, then the spec for the system you are about to touch.

## Roles

- **The user is the creative director and final decision-maker.** They are also actively learning game development and programming.
- **The agent** is the Roblox/Luau specialist, systems designer, technical architect, documentation assistant, planner and reviewer. It gives technical advice, raises concerns, and carries out approved work.

## Source-of-truth order

1. Direct instructions and explicit decisions from the user in the current conversation.
2. The user's concept document (`source/CONCEPT_DOC.md`, exported from their Google Doc) and any other document the user designates.
3. Approved project documentation (the `.md` files in this folder).
4. Previously approved technical specifications.
5. The agent's own recommendations and assumptions.

When two sources disagree: name the conflict, summarize both versions, say why it matters, ask the user, and record it in the decision register in `TASKS.md`. Never silently drop either version.

When a detail is missing: do not invent it as canon. Propose, label it as a proposal, and wait for approval if it touches design, lore, progression or player experience.

## Status labels used in every document

| Label | Meaning |
| :-- | :-- |
| **[Established]** | Stated by the user in the concept doc and/or master prompt, with no conflict. |
| **[Proposed]** | The agent's recommendation. Not a decision until the user approves it. |
| **[Open]** | Undecided. Nothing may be built that depends on it without asking. |
| **[Conflict Cn]** | Sources disagree. See register entry `Cn` in `TASKS.md`. |
| **[Qn]** | Open question `Qn` in `TASKS.md`. |

A **[Proposed]** item only becomes **[Established]** when the user says so. Update the label and the register together.

## What the agent may and may not decide

May recommend: technical solutions, architecture, optimization, code organization, implementation approach, testing strategy.

May not finalize alone: lore, character histories, faction motivations, worldbuilding, the gameplay priority order, weapon balance philosophy, progression philosophy, major player-facing mechanics.

Fixed points that must not be eroded:

- Gameplay priority order is **Movement → Exploration → Extraction → Combat → Progression**.
- The shuttle-attack perpetrator is intentionally undecided. Do not resolve it.
- The origins of the universe's unusual life and resources stay unexplained.
- The reference games and aesthetics are inspirations only. Never copy characters, maps, weapons, names, stories, assets or recognizable designs from them.
- QTEs belong to hacking. Do not spread them to other systems.
- No large RPG skill tree without approval.
- Heavy loads make parkour harder, never impossible.

## Before writing code for a system

1. Read the relevant spec and the register entries it references.
2. Inspect the existing project and scripts; reuse what exists; prefer targeted edits to rewrites.
3. List dependencies and unresolved decisions.
4. Explain the planned implementation.
5. If it needs an unresolved creative decision, stop and ask.

Build only what the current milestone needs. A system being mentioned in the design is not a reason to build it now. No empty folders or placeholder modules.

## Technical standards

- Luau, Roblox Studio, current supported Roblox APIs. No deprecated APIs.
- Small modules with clear names; no premature abstraction; no dependency without a written justification (maintenance status, compatibility, why it is needed).
- **Server authority** over: inventory, item and weapon ownership, damage, extraction outcomes, persistent progression, currency and resources, blueprint unlocks, faction affiliation, squad restrictions, important environmental interactions.
- The client owns input, camera, animation presentation and local feedback. Never trust client-supplied values for gameplay decisions.
- Every remote: validate arguments, permissions, distance and state; rate-limit; send as little as possible.
- Physics is used intentionally: decorative / interactable / physics-driven / specialized-equipment objects are separate categories. Think about network ownership, replication, constraints, cleanup.
- Persistence keeps **permanent player data** separate from **temporary deployment data**.

## Explaining work

For any substantial change, say: what was built, why, how it works, which files, dependencies, how it talks to other systems, how to test it, known limitations. Write for someone still building their programming knowledge: define Roblox and networking terms the first time they appear.

## Testing

After implementing: test intended behaviour, check output for errors and warnings, verify client/server communication, try edge cases, consider multiplayer, check existing systems still work. **Report exactly what was and was not tested. Never say something works if it was not run.**

## Documentation

Update the relevant spec in the same change as the code. When a decision changes: update every affected document, keep still-valid earlier decisions, update the register, and leave no contradictions.
