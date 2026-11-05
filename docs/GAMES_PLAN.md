# Calm Corner: Two-Game Plan (2026-11-05)

## Problem with the old build
- Five half-finished games, two separate Color Sort implementations, home cards showing raw l10n keys
  ("windowWipe"), splash always routing to onboarding, no levels, no saved progress, menu "Restart" was a TODO.

## Direction
Ship **two** finished, level-based calm puzzles. When the app opens: splash -> (first run only) onboarding -> Home
with two large game cards. Each card -> Level Map -> Level -> gentle completion card -> next level.

No fail states, no timers, no move limits. Undo / restart / hint always available.

### Game 1: Still Waters (Color Sort), id `color_sort`
- Tap a tube, tap another: the top run of color pours across (animated lift, tilt, liquid transfer).
- 60 levels in 5 chapters of 12 (Dawn, Meadow, Tide, Dusk, Night). 3 colors growing to 9 colors.
- Levels are deterministic (seeded) and checked solvable by the solver before they are shown.
- Helpers: Undo (unlimited), Restart, Hint (solver's next move), +1 empty tube (one per level). You can never get stuck.

### Game 2: Garden Streams (new), id `stream_garden`
- A grid of stone channel tiles. Tap a tile to rotate it 90 degrees. Water flows from the spring through every
  tile that is connected. Dry flower buds at channel ends bloom when water reaches them.
- The level is done when every tile carries water (that is equivalent to "no leaks", because each level is a spanning tree).
- 60 levels in 5 chapters, grid 3x3 growing to 7x9. Generated from a seeded random spanning tree, so every level is
  solvable by construction. Then the tiles are scrambled.
- Hint rotates one wrong tile into its solved orientation. Restart re-scrambles the same level.

### Shared
- `LevelProgress` (SharedPreferences): unlocked level and the set of completed levels for each game.
- `LevelGameModule` interface: id, title, tagline, colours, levelCount, chapters, thumbnail, buildLevel(...).
- Routes: `/home`, `/play/:id` (level map), `/play/:id/:level` (level).
- The other prototypes (window wipe, bubble pop, sand, plant) stay in the repo but are not shown on Home.

## Steps
1. Plan (this file)
2. Shared level infrastructure + routing + home + level map
3. Still Waters rebuild
4. Garden Streams
5. Tests (generators solvable, progress persistence, widget smoke) + run in browser and look at every screen
