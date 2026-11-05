# Decisions

- 2026-10-27: Kept the MVP games procedural and asset-free. This preserves offline operation and avoids third-party asset licensing.
- 2026-10-27: Registered concise Canvas fallbacks for Bubble Pop, Sand Garden, Color Sort, and Grow a Plant so every specified MVP route is playable while the richer shader/physics variants can be added incrementally.
- 2026-10-27: Settings and game progress use existing `SharedPreferences` storage keys; this avoids adding a persistence dependency.
- 2026-10-27: Color Sort Orchid changed from #E39AE0 to #C878C8 and Rose from #F29AB8 to #F8A0B8 so all palette pairs meet deltaE2000 >= 12 (Lavender/Orchid and Orchid/Rose were below threshold).
- 2026-10-27: Audio music loading fixed to use a separate _musicSources map keyed by MusicId, since manifest music ids (dawn/dusk/moonlit/garden) are not SoundId values.
- 2026-10-27: Added soundIdToManifestId/musicIdManifestNames mapping because SoundId/MusicId enums use camelCase while manifest ids use snake_case.
- 2026-11-05: Focused the app on two finished level-based games (Still Waters, Garden Streams) instead of
  five half-finished toys. Added a separate `LevelGameModule` interface so the old `GameModule` prototypes keep compiling.
- 2026-11-05: Still Waters reuses the existing `ColorSortState` model and DFS solver; levels use a capped
  9-colour palette subset ordered for distinctness, 4 units per glass, 2 empty glasses.
- 2026-11-05: Garden Streams levels are spanning trees, so "every tile watered" is the same as "no leaks".
  Degree is capped at 3 so every tile is worth turning.
- 2026-11-05: Replaced the four background tracks with one track (`assets/audio/music/calm.flac`,
  made by `tools/gen_music.py`) that plays continuously across every screen. The old tracks had most of
  their energy at 2-7 kHz (noise bed and bright bells), which sounded hissy and irritating. The new track keeps
  about 95% of its energy at 200-800 Hz: slow pads, sparse soft piano-like notes, 168 s seamless loop,
  -28 dBFS RMS. FLAC because this ffmpeg has no libvorbis and MP3 padding breaks gapless loops.
  Garden Streams wind chimes are now rarer (every 22-42 s) and quieter.
