# Calm Corner progress

See `docs/GAMES_PLAN.md` for the two-game direction (2026-11-05).

## Implemented (2026-11-05)

- App flow: splash -> onboarding (first launch only, `onboarding.done`) -> Home with two game cards.
- Shared level system (`lib/features/levels/`): `LevelGameModule`, level map with chapters,
  play screen with restart / how-to-play / completion card, progress saved per game
  (`levels.<id>.done`), Continue opens the next unplayed level.
- **Still Waters** (`lib/features/games/still_waters/`): colour-sort pouring, 60 seeded, solver-checked
  levels in 5 chapters, animated tilt-and-pour with level liquid surfaces, unlimited undo, hint,
  one extra tube per level, stuck detection, corks + chime on finished glasses.
- **Garden Streams** (`lib/features/games/garden_streams/`): rotate stone tiles so the spring reaches every
  flower. 60 levels (3x3 up to 7x9) from seeded spanning trees, smooth rotations, flowing water shimmer,
  blooming flowers, hint, light and dark palettes.
- Tests: generators (all 120 levels solvable and deterministic), progress persistence, app flow,
  visual frames rendered to `build/visual/`.

## Added (2026-11-05, round 2)

- **Clear Window** (`lib/features/games/clear_window/`): wipe dirty glass to reveal hand-painted scenes
  (lake, sea, meadow, city, snow, forest) at four times of day. 36 levels in 6 chapters: fog, dust, rain,
  frost, mud, storm. Five window shapes. A hidden friend in every view (duck, crab, cat, bird, fox, owl).
  Cloth wipe loop that follows your speed, squeaks, sparkles, rain ambience, auto-polish at 95%.
- Game-style UI: chunky 3D buttons with click sounds, star counter (one star per level), cozy evening
  home, winding level path with coins and chapter ribbons, celebration card with confetti.
- Audio: fixed SFX that stopped after two plays, music now loops; one soft track
  (`tools/gen_music.py`) plays throughout the app without restarting, saved sound settings load at
  start, mute toggle on Home, web audio enabled (`init_soloud.js`). Still Waters pours with a pouring
  loop; Garden Streams has soft wind chimes drifting by.

## Next

- Colour-blind symbols on Still Waters liquids (the palette already defines a symbol per colour).
- Gentle background music per game, and sound and haptics toggles that actually persist.
- Level map: show a small preview of each level.
- Real-device check on Android/iOS (so far tested in widget tests and in a web build).

## Not on Home

- Window Wipe, Bubble Pop, Sand Garden, Grow a Plant and the old Color Sort prototype are still in the repo
  and registered under `/game/:id`, but they are not shown on Home.

## Added (2026-11-05, round 3): loading screen and onboarding

- New logo drawn in code (`CalmLogo` in `lib/core/widgets/cozy_sky.dart`): a round wooden window with a
  moon over hills. Rendered to `assets/brand/splash_logo_1152.png` by `flutter test tools/render_logo_test.dart`.
- Native splash (Android, Android 12, iOS, web) regenerated in night blue `#1B1838` with the new logo,
  so it hands over seamlessly to the Flutter loading screen.
- Loading screen does real work: sounds load behind it (`bootProvider`) instead of before the app draws,
  with a filling bar and a calm tip. Minimum 1.8 s, then a slow fade.
- Onboarding: three swipeable pages on the cozy sky (welcome with the three games, how stars work,
  sound and vibration switches that are saved), chunky NEXT / LET'S PLAY, Skip. Shown on first launch only.
- The app icon is still the old bubble; it should be redrawn to match the new logo.

## Added (2026-11-05, round 4): settings, tap sound, icon

- Settings rebuilt in the game style; every control works. Removed dead rows (mix with other apps,
  left-handed layout, "coming soon" reminders, fake Calm Plus). Look section now applies and saves:
  theme (Auto / Day / Evening / Night, `settings.theme`), colour-blind symbols in Still Waters,
  reduce motion. Play: keep screen awake (wakelock during levels), fast pour. Reset progress keeps settings.
- Button tap, back and toggle sounds replaced with soft wooden "tocks" (`tools/gen_ui_sounds.py`):
  ~300 Hz, peak -16 dBFS (was a 560 Hz beep with a noise click at -6 dBFS).
- New app icon from the CalmLogo on the night sky (`tools/render_logo_test.dart`, then
  `dart run flutter_launcher_icons`): Android adaptive + themed monochrome, iOS (no alpha), web, macOS, Windows.
- `tools/serve_web.py` serves build/web with caching off (the default python server let browsers
  keep stale builds).
