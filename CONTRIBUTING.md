# CONTRIBUTING.md — working on PROJECT FRONTIER together

Two people (each with their own AI agent) work on this game. The rules below keep us from overwriting each other.

## The split

- **Code** lives in this git repository and is copied into Roblox Studio by Rojo.
- **The world** (maps, models, the character rig) lives in the Roblox place, shared through Team Create. The place file is never committed to git: it is one binary file, and git cannot merge two people's edits to it.

## One-time setup

1. Clone the repository.
2. Install Rojo 7.7.1 (`brew install rojo` on a Mac) and its Studio plugin (`rojo plugin install`).
3. In VS Code, install the Luau language server and Rojo extensions.
4. Turn on the guard that stops accidental pushes to `main`:

   ```bash
   git config core.hooksPath .githooks
   ```

5. Accept the Team Create invitation to the shared place.
6. For coding, make your own local place: in Studio, create a new Baseplate and save it into this folder as a `.rbxl` file (git ignores those).

## Rojo and Team Create: do not mix them

Rojo copies the scripts on your disk into whatever place Studio has open. In the Team Create place that means **everyone** gets your scripts, including unfinished ones, and two people running `rojo serve` there overwrite each other.

- **Coding and testing:** your own local place, with `rojo serve` running.
- **World building:** the Team Create place, with Rojo **not** connected.
- **Shared playtests:** one person, on an up-to-date `main`, connects Rojo to the Team Create place. Say so in chat first.

## Daily routine

1. `git switch main`, then `git pull`.
2. Create a branch for one task: `git switch -c stamina`.
3. Put your name next to the item in `TASKS.md` so the other person knows it is taken.
4. Do the work. Commit as you go.
5. Run the tests: `python3 tools/studio.py test` (Studio open on your local place, `rojo serve` running).
6. Push the branch and open a pull request on GitHub. The other person, or their agent, reviews it.
7. Merge it, then delete the branch. Keep branches short-lived: a day or two, not a week.

`main` should always run. Nothing goes into it except through a pull request.

## Avoiding conflicts

- One task, one owner. Do not both work in the same files at the same time.
- `src/shared/Config/MovementConfig.luau`: only one person tunes numbers at a time.
- `TASKS.md` and `DECISIONS.md`: keep edits small and merge them quickly, because both agents update these.
- If git reports a merge conflict you do not understand, stop and ask rather than guessing; both versions are still safe in git.

## Decisions

`AGENTS.md` makes "the user" the final decision-maker on design and lore. With two people that needs one answer: **design, lore and player-facing decisions are approved by dadragon4** (the creative director). The other developer and their agent propose them in a pull request or in `DECISIONS.md` and wait for approval.
