# Calm Corner: Complete Build Specification

> **Audience: Claude Code.** This file is the single source of truth for building the whole app, from empty folder to store-ready build. Read it fully once, then work phase by phase (section 17). The owner is a Flutter developer who does not want to hunt for assets or tune numbers: **everything below is designed so you can build, generate and verify it yourself.**
>
> Spec date: 2026-10-26. Product name "Calm Corner" is a placeholder; keep it in one constant (`AppBrand.name`).

---

## 0. How to work (read first)

### 0.1 Mission

Build a Flutter app (Android + iOS) of short, tactile, **no-fail** relaxation games (wipe a foggy window, pop bubbles, rake a sand garden, sort colored water, grow a plant), wrapped in a calm, polished UI with soft sound and haptics. The target feeling is *a pocket full of small satisfying things*, not a "game" with scores.

### 0.2 Operating rules

1. **Do not ask the owner for assets, art, sounds, fonts or numbers.** Section 9 and the appendices give you generators and sources. If a download is blocked by the network, use the procedural fallback and keep going.
2. **Loop on every feature:** build → run tests → render a frame to PNG (section 16.3) → *look at the PNG* with the Read tool → compare against this spec → fix → repeat. A feature is not done until you have looked at it.
3. **Every tunable number lives in a per-game `*Tuning` class** (section 4.6) with the default taken from this file. When this spec says "k = 0.9", that goes into `tuning`, not into the middle of a painter. Never hide magic numbers.
4. **Fallback first, polish second.** For every shader effect, first build the pure-Canvas version (works in `flutter test`, on weak GPUs, on web). Add the fragment shader as an upgrade behind a flag with automatic fallback.
5. **No dark patterns, ever:** no fail states, no timers pressuring the player, no streak-loss messaging, no flashing, no interstitial over gameplay, no fake urgency. The only timers are user-started (sleep timer).
6. **Performance is a feature.** Budgets in section 4.7 are acceptance criteria.
7. **Keep a log.** Maintain `docs/PROGRESS.md` (what is done, what is next, known issues) and `docs/DECISIONS.md` (any deviation from this spec and why). Commit at the end of each phase with a clear message.
8. **Licences:** use only assets whose licence is recorded in `assets/LICENSES_ASSETS.md` (template in Appendix E). The default plan ships **zero third-party art and audio**, because everything is generated.
9. **If something in this spec is wrong or impossible** (a package API changed, a constant feels bad): fix it, note it in `docs/DECISIONS.md`, move on. Do not stop to ask.

### 0.3 What was verified when this spec was written (2026-10-26)

| Fact | Status | Source |
| --- | --- | --- |
| `flame` latest stable is 1.38.2 (a 2.0.0 dev line exists) | Verified | [pub.dev/flame docs](https://pub.dev/documentation/flame/latest/) |
| `rive` stable is 0.14.11; 0.15.x is dev-only; uses `rive_native`, new API (`File.asset(..., riveFactory: Factory.rive)`, `RiveWidgetController`) | Verified | [Rive Flutter docs](https://rive.app/docs/runtimes/flutter/flutter) |
| `flutter_soloud` is an official-cookbook low-latency audio engine: `SoLoud.instance.init()`, `loadAsset`, `play` returns a handle, `setVolume`, `setRelativePlaySpeed`, `fadeVolume`, gapless `looping: true`; supports MP3/WAV/OGG/FLAC | Verified | [Flutter cookbook](https://docs.flutter.dev/cookbook/audio/soloud) |
| `haptic_feedback` 0.6.5: `Haptics.canVibrate()`, `Haptics.vibrate(HapticsType.x)` with `success, warning, error, light, medium, heavy, rigid, soft, selection`; iOS uses UIKit generators; **needs Flutter 3.47+, Android API 24+, AGP 9** | Verified | [haptic_feedback docs](https://pub.dev/documentation/haptic_feedback/0.6.5/) |
| Fragment shaders: declare under `flutter: shaders:`, load with `FragmentProgram.fromAsset`; `FlutterFragCoord()`; only `sampler2D`; no UBO/SSBO; output premultiplied alpha; `ImageFilter.shader` is Impeller-only | Verified | [Flutter shader docs](https://docs.flutter.dev/ui/design/graphics/fragment-shaders.md) |
| Pixabay Content License: commercial use OK, no attribution required, **cannot redistribute content standalone**, no trademarks/recognisable people | Verified | [Pixabay terms](https://pixabay.com/service/terms/) |
| Kenney "Interface Sounds": CC0, 100 OGG files | Verified | [OpenGameArt page](https://opengameart.org/content/interface-sounds) |
| Mixkit free licence: commercial OK, no attribution, no resale in original form; whether a mobile *app* qualifies must be confirmed on its licence page | Partly verified | [Mixkit info](https://mixkit.co/llm-info/) |
| Source-by-source licence safety table (Kenney, Freesound CC0, OpenGameArt, Pixabay Music, Sonniss, Incompetech, etc.) | Third-party guide, re-check each item | [Cinevva guide](https://app.cinevva.com/guides/free-sound-effects-music) |
| Exact current versions of Riverpod, go_router, shared_preferences, Firebase packages, Google Mobile Ads, RevenueCat | **Not verified** (pub.dev was unreachable from the research sandbox) | Always run `flutter pub add <pkg>` to get the real latest |

**Rule:** never copy a version number from this file into `pubspec.yaml`. Run `flutter pub add`, and read the package's README for API changes.

### 0.4 Deviations from the PRD (on purpose)

| PRD said | This spec does | Why |
| --- | --- | --- |
| Flame for Bubble Pop | Own tiny engine (`SimLoop`, `Spring`, `ParticlePool`, section 4.5) | Five games share the same needs; fewer dependencies; full control of feel; Flame stays an optional later swap |
| Rive and Lottie animations | Code-driven animation only | `.riv` and Lottie files must be authored in an editor or downloaded; you cannot author them. Procedural painting gives exact control and zero licence risk |
| `just_audio` + `audioplayers` | One engine: `flutter_soloud` | Low latency, per-voice pitch/volume, gapless loops, fades: all required here |
| Drift or Hive | `shared_preferences` (+ small files via `path_provider`) | Data is tiny; fewer moving parts |
| Firebase, Ads, RevenueCat in MVP | Behind interfaces with no-op stubs; real implementations in Phase 5 | The app must build and run with no keys and no accounts |
| `freezed` / `build_runner` | No code generation | Faster builds, fewer failure modes; hand-write `copyWith` |

### 0.5 Contents

1. Product principles
2. Tech stack and project setup
3. Design system (colors, type, spacing, motion, springs)
4. Architecture (game interface, services, simulation engine, tuning, performance)
5. Screens and UX flows
6. Game 1: Window Wipe
7. Game 2: Bubble Pop
8. Game 3: Zen Sand Garden
9. Game 4: Color Sort
10. Game 5: Grow a Plant
11. Audio system
12. Haptics system
13. Assets: what exists, how it is generated, optional upgrades
14. Persistence and data
15. Accessibility, localisation, privacy, analytics
16. Testing and visual QA
17. Build phases with acceptance criteria
18. Release checklist and the few human-only steps
19. Appendices (A audio generator, B icon generator, C shaders, D copy deck, E licence ledger)

---

## 1. Product principles

| Principle | Concrete rule |
| --- | --- |
| No-fail | No game over, no lives, no countdown, no score that can go down |
| Instant | Cold start to playable game in two taps, splash under 1.2 s on a mid-range phone |
| Tactile | Every touch gets visual + sound + haptic feedback within 50 ms |
| Quiet | Soft palettes, no pure white or pure black, no sudden loud sounds, no flashes |
| Finite satisfaction | Each game has a natural "ahh" moment (completion bloom) within 1 to 5 minutes, then a gentle exit |
| Offline | Everything works with no network; cloud features only add sync |
| Respectful | Free to play first; ads (if any) never interrupt a game; one clear premium unlock |

Names used in code: `window_wipe`, `bubble_pop`, `sand_garden`, `color_sort`, `grow_plant`.

---

## 2. Tech stack and project setup

### 2.1 Stack

| Layer | Choice | Notes |
| --- | --- | --- |
| Framework | Flutter stable (latest) + Dart 3 | Check `flutter --version`. `haptic_feedback` 0.6.5 needs Flutter 3.47+; if older, use the fallback backend (section 12.3) |
| Targets | Android (minSdk 24 or the highest any plugin requires), iOS (the highest any plugin requires) | Phones portrait-locked; tablets (shortest side >= 600 dp) may rotate |
| Rendering | `CustomPainter` + `Ticker`; `dart:ui` `FragmentProgram` for optional shader upgrades | Impeller is the default renderer; keep Skia-safe code (no `ImageFilter.shader` without a guard) |
| State (app level) | `flutter_riverpod` (latest, no code generation) | Settings, progress, audio, haptics. **Game simulation state is NOT in Riverpod**: it lives in plain objects ticked by a `Ticker` |
| Navigation | `go_router` | Fade-through and hero transitions (section 5) |
| Audio | `flutter_soloud` | SFX + music + loops, one engine |
| Haptics | `haptic_feedback` with fallback to Flutter's built-in `HapticFeedback` | Behind `HapticService` |
| Storage | `shared_preferences` (settings, progress JSON) + `path_provider` (sand garden image) | |
| Utilities | `wakelock_plus`, `share_plus`, `package_info_plus`, `url_launcher`, `intl` | |
| Dev | `flutter_lints`, `mocktail`, `flutter_launcher_icons`, `flutter_native_splash`, `integration_test`, `flutter_test` | |
| Phase 5 (optional, behind interfaces) | `firebase_core`, `firebase_analytics`, `firebase_crashlytics`, `firebase_remote_config`, `google_mobile_ads`, `purchases_flutter` | Need human-created accounts and keys (section 18) |

### 2.2 Bootstrap commands

```bash
flutter --version
flutter create --org com.example.calmcorner --project-name calm_corner --platforms android,ios .
flutter pub add flutter_riverpod go_router flutter_soloud haptic_feedback shared_preferences \
  path_provider wakelock_plus share_plus package_info_plus url_launcher intl
flutter pub add --dev flutter_lints mocktail flutter_launcher_icons flutter_native_splash
# add to pubspec by hand (SDK packages): flutter_localizations (sdk: flutter), integration_test (dev, sdk: flutter)
```

If `flutter pub add haptic_feedback` fails the SDK constraint, run `flutter pub add haptic_feedback:<older version that matches the installed SDK>` or leave it out and use only the built-in backend. Record the choice in `docs/DECISIONS.md`.

### 2.3 `pubspec.yaml` shape (versions come from `pub add`)

```yaml
flutter:
  uses-material-design: true
  generate: true               # gen-l10n
  assets:
    - assets/audio/sfx/
    - assets/audio/music/
    - assets/brand/
  shaders:
    - shaders/window_glass.frag
    - shaders/sand_light.frag
  fonts:
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Variable.ttf   # variable font: wght axis 200-1000
    - family: NotoSansDevanagari
      fonts:
        - asset: assets/fonts/NotoSansDevanagari-Variable.ttf
```

### 2.4 Platform configuration

* Android: `minSdk` per plugins (>= 24), `android:screenOrientation` handled in Dart, `<uses-permission android:name="android.permission.VIBRATE"/>` (the plugin may add it; verify), enable R8/proguard defaults, adaptive icon from `assets/brand` (Appendix B), themed (monochrome) icon.
* iOS: deployment target per plugins, no special permission strings needed in the MVP (no camera, mic, photos, location). If the garden "Save image to Photos" is added later, add `NSPhotoLibraryAddUsageDescription`.
* Both: `SystemChrome.setPreferredOrientations([portraitUp])` on phones; edge-to-edge with `SystemUiMode.edgeToEdge`; transparent system bars; status bar icon brightness follows theme.

### 2.5 Lints and quality gates

`analysis_options.yaml`: include `flutter_lints`; enable `strict-casts`, `strict-inference`, `strict-raw-types`; treat `unused_*`, `unawaited_futures`, `cancel_subscriptions`, `close_sinks` as errors.
Gates before every commit: `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`.

---

## 3. Design system

One look, three themes. Soft, warm, rounded, low-contrast-but-readable. All values are tokens in `lib/app/theme/tokens.dart`; widgets never use raw hex.

### 3.1 Colors

| Token | Dawn (light) | Dusk (dark) | Moonlit (low-stimulation) |
| --- | --- | --- | --- |
| `bg` | `#FBF4EC` | `#1C1A2B` | `#0F0E16` |
| `bgGradientA` -> `B` (home) | `#FFE9D6` -> `#E9E0FF` | `#232042` -> `#171527` | `#14121C` -> `#0C0B12` |
| `surface` | `#FFFFFF` @ 72% | `#2A2744` @ 80% | `#181622` @ 90% |
| `surfaceAlt` | `#F3E8DD` | `#34304F` | `#1E1B2A` |
| `ink` (text) | `#3B3548` | `#EDE8F7` | `#CFC8DD` |
| `inkSoft` | `#6E6780` | `#A9A3BF` | `#8E88A3` |
| `line` | `#E6DACB` | `#3C3858` | `#262333` |
| `accent` | `#8E7CC3` | `#B3A1F0` | `#8F83B8` |
| `accent2` | `#F2A488` | `#F0B08F` | `#B08C7E` |
| `success` | `#7FB89A` | `#8FD1AB` | `#6E9C86` |
| `danger` (rarely used) | `#D98A8A` | `#E5A0A0` | `#A87878` |

Rules:
* Text on `bg` must meet WCAG AA (4.5:1) for `inkSoft`, 7:1 for `ink`. **Write `test/theme/contrast_test.dart`** computing the ratios and fail the build if violated; adjust hex minimally if needed.
* Moonlit never uses pure white anywhere, caps luminous elements at about 70% brightness, disables animated gradients, halves particle counts, and prefers the `moonlit` music track.
* "Auto" theme follows system brightness (Dawn/Dusk); Moonlit is manual or follows the sleep timer.

### 3.2 Typography

Font: **Nunito** (rounded, friendly, OFL licence). Hindi fallback: **Noto Sans Devanagari** (OFL). Bundle variable TTFs in `assets/fonts/` (get them from the official `google/fonts` GitHub repo under `ofl/nunito` and `ofl/notosansdevanagari`, and copy each family's `OFL.txt` into `assets/fonts/licenses/`). If the download fails, ship with the platform default font and the same scale; do not block on it.

| Style | Size / line | Weight | Letter spacing |
| --- | --- | --- | --- |
| `display` | 34 / 40 | 800 | -0.5 |
| `title` | 24 / 30 | 700 | -0.2 |
| `subtitle` | 18 / 24 | 600 | 0 |
| `body` | 16 / 24 | 400 | 0 |
| `label` | 14 / 20 | 600 | 0.1 |
| `caption` | 12 / 16 | 500 | 0.2 |

Text scaling: respect the system scale up to 1.6x in settings and menus; game chrome clamps to 1.3x.

### 3.3 Spacing, shape, elevation

* Spacing scale (dp): 4, 8, 12, 16, 24, 32, 48. Screen side padding 20. Minimum touch target 48x48.
* Radii: chips 12, cards 24, sheets 28 (top), pills 999, game glass 20.
* Elevation: never Material tonal elevation. Use soft shadows: `ink @ 8%`, blur 24, offset (0, 8) for cards; `ink @ 12%`, blur 12, offset (0, 4) for pressed/raised small items. Set `surfaceTint` to transparent.
* Glass (BackdropFilter blur sigma 18) only on the game chrome buttons and bottom sheets, never over a full-screen live game (performance).

### 3.4 Motion tokens

| Token | Value | Use |
| --- | --- | --- |
| `instant` | 90 ms | Press feedback |
| `fast` | 160 ms | Toggles, small fades |
| `base` | 280 ms | Most transitions |
| `slow` | 480 ms | Page and hero transitions |
| `ambient` | 900 ms | Mood changes, glows |
| `breathe` | 4000 ms | Idle breathing pulses (loop) |

Curves: `calmOut = Cubic(0.16, 1, 0.3, 1)`, `calmInOut = Cubic(0.65, 0, 0.35, 1)`, `softIn = Cubic(0.32, 0, 0.67, 0)`.

Springs (mass 1; damping ratio z = c / (2 sqrt(k m))):

| Name | k | c | z | Overshoot | Use |
| --- | --- | --- | --- | --- | --- |
| `uiSpring` | 260 | 26 | 0.81 | about 1.4% | Press scale, chips, sheets |
| `bouncy` | 180 | 14 | 0.52 | about 15% | Corks, bloom pops, stone drop |
| `float` | 90 | 18 | 0.95 | about 0% | Cloth follow, drifting UI |
| `heavy` | 60 | 16 | 1.03 | 0% | Rake, big objects |

Integrate springs with semi-implicit Euler: `v += ((-k * (x - target)) - c * v) / m * dt; x += v * dt;`. Clamp `dt` to 1/30 s.

Reduce Motion (system flag or settings override): replace springs with 160 ms fades, disable parallax, shake, particle trails and idle breathing; keep state changes visible with opacity and color only.

### 3.5 Component specs

* **Primary button:** pill, height 52, `accent` fill, `ink` on-accent text 16/600, press: scale 0.97 via `uiSpring` + haptic `uiTap` + sound `ui_tap`.
* **Chip / toggle:** 40 high, radius 12. Toggle thumb animates with `uiSpring`; sound `ui_toggle_on/off`.
* **Game card:** 4:5, radius 24, live procedural thumbnail (painter drawn once to an image, redrawn at 2 fps for a subtle shimmer), title `subtitle`, one-line tagline `caption`, progress ring 28 dp at bottom right.
* **Bottom sheet:** top radius 28, drag handle 36x4, slides up 360 ms `calmOut`, scrim `ink @ 28%`.
* **Icon buttons in game chrome:** 44 dp glass circles, 20 dp icon (use Material `Icons.*` rounded variants; no icon font to license).
* **Sliders:** 4 dp track, 22 dp thumb, tick haptic every 10%.

---

## 4. Architecture

### 4.1 Folder structure

```text
lib/
  main.dart                      bootstrap: bindings, services init, runApp
  app/
    app.dart                     MaterialApp.router, theme mode, locale
    router.dart                  go_router config, transitions
    theme/                       tokens.dart, themes.dart, text_styles.dart, motion.dart
    brand.dart                   AppBrand.name, store links, feature flags
  core/
    engine/                      sim_loop.dart, spring.dart, particles.dart, pointer_tracker.dart,
                                 rng.dart, math.dart, easing.dart
    audio/                       audio_service.dart, sound_ids.dart, music_director.dart
    haptics/                     haptic_service.dart, haptic_events.dart, backends/
    tuning/                      tuning.dart, tuning_panel.dart (debug only)
    persistence/                 prefs_store.dart, progress_repository.dart, models/
    analytics/                   analytics_service.dart (interface + no-op), events.dart
    monetization/                ads_service.dart, purchase_service.dart (interfaces + stubs)
    a11y/                        reduce_motion.dart, semantics_helpers.dart
    widgets/                     calm_button.dart, glass_icon_button.dart, bottom_sheet.dart,
                                 soft_card.dart, progress_ring.dart, breathing_dot.dart
  features/
    splash/ onboarding/ home/ settings/ premium/ collection/ credits/
    games/
      game_module.dart           interface (4.2)
      game_registry.dart         list of GameModule
      game_shell.dart            full-screen chrome, pause, completion sheet
      window_wipe/               module.dart, tuning.dart, scenes/, wipe_engine.dart,
                                 droplets.dart, cloth.dart, painter.dart, shader_painter.dart
      bubble_pop/                module.dart, tuning.dart, world.dart, painter.dart, sprites.dart
      sand_garden/               module.dart, tuning.dart, heightfield.dart, rake.dart, stones.dart, painter.dart
      color_sort/                module.dart, tuning.dart, model.dart, generator.dart, solver.dart,
                                 pour_animation.dart, liquid_geometry.dart, painter.dart
      grow_plant/                module.dart, tuning.dart, species/, plant_painter.dart, watering.dart
  l10n/                          app_en.arb, app_hi.arb
shaders/                         window_glass.frag, sand_light.frag
assets/ audio/ fonts/ brand/
tools/                           gen_audio.py, gen_icons.py, gen_scenes.dart (optional)
test/ integration_test/ docs/
```

### 4.2 Game interface

Every game is a `GameModule`. The home screen, router, progress, analytics and remote flags only know this interface.

```dart
abstract class GameModule {
  String get id;                                   // 'window_wipe'
  GameMeta get meta;                               // title/tagline keys, accent colors, premium flag, default music id
  Widget buildThumbnail(BuildContext c, {required double t}); // procedural, cheap, t = seconds for shimmer
  Widget buildGame(BuildContext c, GameSession session);      // the full-screen game
}

class GameMeta {
  const GameMeta({required this.titleKey, required this.taglineKey, required this.accent,
                  required this.accent2, required this.defaultMusic, this.premium = false});
  final String titleKey, taglineKey; final Color accent, accent2; final String defaultMusic; final bool premium;
}

/// Handed to a running game. Games never touch singletons directly.
abstract class GameSession {
  AudioService get audio;
  HapticService get haptics;
  SettingsSnapshot get settings;                   // reduceMotion, colorblindAssist, leftHanded...
  bool get isTablet;
  Map<String, dynamic>? loadState();               // game-specific JSON, null if none
  Future<void> saveState(Map<String, dynamic> json);
  void reportProgress(double zeroToOne);           // drives the progress ring on the card
  void complete({required GameResult result});     // shows the completion sheet
  void requestChromeVisible(bool visible);         // hide chrome during play
}

class GameResult { const GameResult({required this.seconds, this.detailKey, this.nextLabelKey}); /* ... */ }
```

Game widgets implement `WidgetsBindingObserver`: pause the ticker and audio loops on `inactive/paused`, save state, resume on `resumed`.

### 4.3 Services (interfaces; Riverpod providers expose them)

```dart
abstract class AudioService {
  Future<void> init();                                       // SoLoud.instance.init(), preload all SFX
  Future<SoundHandle?> play(SoundId id, {double volume = 1, double rate = 1, double pan = 0, bool loop = false});
  void setVolume(SoundHandle h, double v);                    // call at most once per frame
  void setRate(SoundHandle h, double r);
  Future<void> fadeAndStop(SoundHandle h, Duration d);
  Future<void> playMusic(MusicId id, {Duration crossfade = const Duration(milliseconds: 2500)});
  void duckMusic({double to = 0.4, Duration down = const Duration(milliseconds: 300), Duration up = const Duration(milliseconds: 1200)});
  void applySettings(AudioSettings s);                        // master, music, sfx volumes, enabled flags
  void pauseAll(); void resumeAll(); Future<void> dispose();
}

abstract class HapticService {
  Future<void> init();                                       // canVibrate, pick backend
  void fire(HapticEvent e);                                  // throttled + intensity-scaled, never throws
  void applySettings(HapticLevel level);                     // off | soft | normal
}

abstract class ProgressRepository {
  Future<ProgressData> load(); Future<void> save(ProgressData d);
  Stream<ProgressData> watch();
}
abstract class AnalyticsService { void log(String event, [Map<String, Object?> params]); }   // default: NoopAnalytics
abstract class AdsService { Future<void> init(); Future<void> maybeShowAfterCompletion(); bool get enabled; } // default: NoopAds
abstract class PurchaseService { Future<void> init(); Stream<Entitlement> get entitlement; Future<void> buyPremium(); Future<void> restore(); } // default: FakePurchases (debug toggle)
```

Providers (Riverpod, no codegen): `settingsProvider` (Notifier), `progressProvider` (AsyncNotifier), `audioServiceProvider`, `hapticServiceProvider`, `analyticsProvider`, `adsProvider`, `purchaseProvider`, `entitlementProvider`, `themeModeProvider`, `gameRegistryProvider`. Services are created in `main()` and overridden into the `ProviderScope`.

**Failure policy:** audio or haptics failing must never crash or block UI. Wrap in try/catch, log in debug, continue silently.

### 4.4 Startup sequence (target under 1.2 s to home on mid-range)

1. `WidgetsFlutterBinding.ensureInitialized()`, lock orientation, edge-to-edge.
2. Load settings (`SharedPreferences`) before `runApp` so the first frame has the right theme.
3. `runApp` with the native splash still visible; splash screen widget shows the logo + a 600 ms gentle breathing animation.
4. In parallel after first frame: `AudioService.init()` + preload SFX, `HapticService.init()`, `FragmentProgram.fromAsset` for both shaders (store the programs), generate/cached scene images lazily when a game opens (not at startup).
5. Navigate to onboarding (first launch) or home.

### 4.5 Engine primitives (`core/engine`)

**`SimLoop`** fixed-timestep simulation driven by a `Ticker`:

```dart
class SimLoop {
  SimLoop({this.step = 1 / 120, this.maxSteps = 8, required this.onStep});
  final double step; final int maxSteps; final void Function(double dt) onStep;
  Duration _last = Duration.zero; double _acc = 0;
  void tick(Duration elapsed) {
    var frame = (elapsed - _last).inMicroseconds / 1e6; _last = elapsed;
    if (frame > 0.05) frame = 0.05;              // tab switch / hitch: do not spiral
    _acc += frame; var n = 0;
    while (_acc >= step && n < maxSteps) { onStep(step); _acc -= step; n++; }
    if (n == maxSteps) _acc = 0;
  }
}
```
The painter repaints from a `Listenable` (a `ChangeNotifier` the sim pings once per frame). **Never `setState` per frame.**

**`Spring`**: scalar and 2D, with the semi-implicit Euler integrator of section 3.4 and a `settled` check (|v| < 0.01 and |x - target| < 0.01 for 3 steps) so idle springs cost nothing.

**`PointerTracker`**: maps `pointer id -> TrackedPointer{pos, prevPos, velocity, downAt, radius}`. Velocity is an EMA of `delta/dt` with alpha 0.35 (`v = lerp(v, d/dt, 0.35)`). Use `Listener` (not `GestureDetector`) so multi-touch and zero-slop moves work. Ignore pointers whose `radiusMajor` exceeds 90 dp (palm) when available.

**`ParticlePool<T>`**: pre-allocated struct-of-arrays (`Float32List` for x, y, vx, vy, life, size, hue) with a free-list; no allocation per spawn. Update loop applies `v *= exp(-drag * dt)`, gravity, life decay. Draw with `canvas.drawRawPoints` (round caps) for small dots or `drawAtlas` for sprites.

**`Rng`**: seeded `Random` wrapper with `range(a,b)`, `chance(p)`, `gauss()`. All game randomness takes an `Rng` so tests are deterministic.

### 4.6 Tuning

Each game has a `*Tuning` class whose constants are exactly the numbers in its spec section.

```dart
class Tunable { const Tunable(this.key, this.def, this.min, this.max, {this.unit = ''}); final String key; final double def, min, max; final String unit; }
class Tuning { Tuning(this.gameId, this.defs); double operator [](String k); /* reads debug override else default */ }
```
* In release builds `Tuning` returns defaults (compile out overrides with `kReleaseMode`).
* In debug/profile builds a three-finger long-press on the game opens `TuningPanel`: sliders for every tunable, a "Copy as Dart" button that prints the changed values, and a Reset. This is how the owner (or you) retunes feel quickly. Overrides persist in `SharedPreferences` under `tuning.<game>.<key>`.

### 4.7 Performance budgets (acceptance criteria)

| Metric | Budget |
| --- | --- |
| Frame time (profile mode, mid-range Android, continuous touch) | <= 8.3 ms avg on 120 Hz devices, never above 16.6 ms for more than 3 consecutive frames |
| Sim step (all games) | <= 1.5 ms per frame total |
| Paint | <= 5 ms per frame |
| Touch to first visual change | <= 50 ms |
| Cold start to home | <= 1.2 s (mid-range), <= 2 s (low-end) |
| Memory | <= 220 MB peak in any game; dispose `ui.Image`s (`image.dispose()`) when replaced |
| App size | <= 40 MB per ABI (audio ~4 MB, no raster art) |
| Battery | Pause tickers when app is inactive; cap to display refresh; no timers when idle |

Rules:
* Allocate nothing in per-frame code paths: reuse `Paint`, `Path` (call `reset()`), `Float32List`.
* One `RepaintBoundary` per independently animating layer (scene, glass, droplets, chrome).
* `saveLayer` is expensive: allowed only for the glass/dirt fallback and only over the glass rectangle, never full screen with large blur.
* Build `ui.Image`s (scene sharp/blur, sprites) once per size; rebuild on size change with 250 ms debounce.
* Warm up: before the first game frame, draw each shader once to an offscreen canvas to avoid first-use jank.
* Verify in **profile mode** (`flutter run --profile`), never debug. Record `integration_test` timelines (section 16.4).

---

## 5. Screens and UX flows

Routes (`go_router`): `/` splash, `/onboarding`, `/home`, `/game/:id`, `/settings`, `/premium`, `/collection`, `/credits`.

### 5.1 Transitions

| From -> To | Animation |
| --- | --- |
| Splash -> Home | Logo scales 1.0 -> 0.9 and fades 280 ms; home fades in 480 ms `calmOut` |
| Home -> Game | Card thumbnail expands to full screen (Hero-style, 480 ms `calmInOut`), card text fades out in the first 120 ms; the game scene cross-fades in during the last 200 ms |
| Game -> Home | Reverse, 360 ms |
| Any -> Settings/Premium | Bottom-up sheet-style page, 360 ms `calmOut`, scrim |
| Dialogs | Scale 0.96 -> 1.0 + fade, 200 ms |

Implement the home-to-game expansion with `Hero` + `flightShuttleBuilder` or a custom `PageRouteBuilder` using the card's `RenderBox` rect. Respect Reduce Motion (plain 200 ms fade).

### 5.2 Splash

Centered brand bubble (from `splash_logo_1152.png`) with a gentle 4 s breathing scale (1.0 <-> 1.04). Background = theme `bg`. Hold at least 500 ms, at most until services are ready (target 1.2 s). Native splash (`flutter_native_splash`) uses the same bubble on `#FBF4EC` (dark: `#1C1A2B`).

### 5.3 Onboarding (first launch only, skippable, 3 pages)

```text
+--------------------------+   Page 1  "A little pocket of calm"      (bubble drifts, tap it to pop: first haptic + sound)
|          (bubble)        |   Page 2  "No scores. No timers. No rush." (window wipes itself once, slowly)
|                          |   Page 3  "Make it yours": Sound [on]  Haptics [Normal]  (live toggles, sound plays on change)
|   headline               |
|   one line               |   Bottom: dots (breathing active dot) + [Next] / [Begin]; top-right [Skip]
+--------------------------+
```
After "Begin", go straight into **Window Wipe, first scene, already running** (no home detour): the user's first experience is the satisfying wipe within ~10 s of launch.

### 5.4 Home

```text
+----------------------------------------+
| Good evening                    [gear] |   greeting by local time: morning / afternoon / evening / night
| 12 calm minutes today                  |   subtle, never a goal; hide if 0
|                                        |
| +------------------------------------+ |
| | Continue                            | |   hero card (16:10): last game, live thumbnail, "Rainy Evening"
| | Window Wipe . Rainy Evening   [>]   | |
| +------------------------------------+ |
|                                        |
|  +----------+  +----------+            |   2-column grid of game cards (4:5)
|  | Bubble   |  | Sand     |            |
|  | Pop      |  | Garden   |            |
|  +----------+  +----------+            |
|  +----------+  +----------+            |
|  | Color    |  | Grow a   |            |
|  | Sort     |  | Plant    |            |
|  +----------+  +----------+            |
|                                        |
|   ( Wind down )          ( Calm Plus ) |   two quiet pills: sleep timer, premium (hidden if premium owned)
+----------------------------------------+
```
* Background: slow vertical gradient `bgGradientA -> B` with two blurred drifting circles (parallax 0.2x) at 30 fps max; frozen in Moonlit/Reduce Motion.
* Cards enter with a staggered fade-up (40 ms stagger, 280 ms each).
* Press: scale 0.97 (`uiSpring`), shadow lifts, `uiTap` sound + haptic.
* Premium games show a small lock chip; tapping opens the premium sheet, not an error.
* Progress ring on each card = `reportProgress` value (scenes done / levels / rounds), purely informational.
* Greeting copy and microcopy: Appendix D.

### 5.5 Game shell (shared by all games)

```text
+----------------------------------------+
| (<)                      (snd)(hap)(...)|   chrome: glass circles, 44 dp, 16 dp from safe-area edges
|                                        |
|                                        |
|              GAME CANVAS               |   full-bleed, edge to edge
|                                        |
|                                        |
|                                        |
+----------------------------------------+
```
* Chrome auto-hides after 3.0 s of no touches (fade 400 ms) and **stays hidden while a finger is down in the game**. It returns on any tap in the top 96 dp strip or after 1.5 s of touch inactivity when the user lifts their finger.
* `(<)` back: saves state, fades out sounds over 250 ms, returns home. System back does the same. No confirm dialog, ever.
* `(snd)` toggles all sound; `(hap)` toggles haptics; `(...)` opens a small menu: game-specific options (scene, tool, palette, level), "Restart", "Help" (one-sentence hint card), "Settings".
* Left-handed mode mirrors chrome horizontally.
* Keep screen awake while a game is active (`wakelock_plus`), release on exit/pause.
* The first time a game opens, show a one-line hint card at the bottom for 4 s ("Drag to wipe the glass"), then never again (stored flag).

### 5.6 Completion sheet

Not a modal: a soft bottom sheet that slides up 1.8 s after the completion animation begins (so the player enjoys the moment first).

```text
+----------------------------------------+
|              ---                        |
|        "Clear as morning."              |   rotating line (Appendix D), title style
|        2 min 14 s of calm               |   caption
|   [ Again ]  [ Next scene ]  [ Home ]   |   Next is the primary button; all three always visible
+----------------------------------------+
```
No stars, no scores, no "you earned" language. Tapping outside the sheet dismisses it and lets the player keep playing in free mode.

### 5.7 Settings

Sections and controls:

| Section | Controls |
| --- | --- |
| Sound | Master slider, Music slider, Effects slider, "Mix with other apps' audio" switch (default off) |
| Haptics | Segmented: Off / Soft / Normal (default Normal) |
| Look | Theme: Auto / Dawn / Dusk / Moonlit; Reduce motion: System / On / Off; Colorblind assist (symbols on colors); Left-handed layout |
| Play | Keep screen awake (default on); Fast pour (Color Sort, default off) |
| Reminders | Daily calm reminder switch + time picker (Phase 5) |
| Calm Plus | Status, Restore purchases (Phase 5) |
| About | Privacy policy, Open-source licenses (`showLicensePage`), Credits, Version, Reset all progress (confirm) |

Every change applies live and plays its feedback sound/haptic so the user *feels* the setting.

### 5.8 Wind down (sleep timer)

Pill on home opens a sheet: 10 / 20 / 30 / 45 minutes (user-started). On start: switch to Moonlit look, play `moonlit` music, open the last game or a dim "breathing" screen. Over the **last 90 s** fade music to 0 and fade the whole screen to near-black (`ink` overlay alpha 0 -> 0.92), then stop audio, release wakelock, show a single line "Good night." for 3 s and stop. Any touch during the last 90 s cancels the fade and keeps the music at its current level.

### 5.9 Calm Plus (premium sheet)

One screen, no countdown, no scarcity text: what is included (extra scenes, sand colors, plants, music tracks, no ads), a one-time price (from the store), [Unlock] and [Restore]. "Not now" is as prominent as the buy button. In Phase 1 to 4 it is wired to `FakePurchases` with a debug switch.

### 5.10 Collection (Grow a Plant)

A wooden shelf with five pot slots; grown plants show full color and a gentle idle sway; locked ones are soft silhouettes with "?" Tapping a grown plant opens it for free play at full bloom.

### 5.11 Empty/error states

Offline, missing audio, haptics unsupported: never show an error to the user. Degrade silently (no sound, no vibration) and log in debug.

---

## 6. Game 1: Window Wipe

*"Wipe the glass. Watch the world come back into focus."* This is the flagship and the first game built; its erase engine is reused by later "clean it" games (dust the shelf, wash the car).

### 6.1 Experience

The screen is a window. Outside is a soft scene (rainy city, misty hills, snowy cabin...). The glass is covered by a layer of dirt (fog, dust, grime, frost...). The player drags a finger; a cloth follows with a slightly heavy, springy lag, leaving a clean, softly feathered path. Dirt thins as you pass; stubborn spots need circular scrubbing. Rain droplets creep down the glass (rain scenes), merge and leave wet trails. At ~93% clean, the rest dissolves in a slow radial reveal, the scene brightens slightly, warm light motes drift, a soft chime plays, and the completion sheet appears.

### 6.2 Layers (bottom to top) and render pipeline

| # | Layer | How it is drawn |
| --- | --- | --- |
| 1 | Scene (sharp) | `ui.Image` pre-rendered once per scene+size by `ScenePainter` |
| 2 | Ambient motion behind glass | Rain streaks beyond the glass, snowflakes, birds/butterflies: tiny particle pool, painted before the glass |
| 3 | **Glass composite** | `sharp` + `dirty` + `mask` -> shader (6.2.2) or Canvas fallback (6.2.3) |
| 4 | Stubborn spots | Overlay blobs with alpha = remaining dirt (6.8) |
| 5 | Droplets and trails | `DropletPainter` (6.7) |
| 6 | Window frame | 10 dp procedural frame, inner shadow, optional muntin cross (scene flag) |
| 7 | Cloth, foam | Cloth sprite, soap-foam particles |
| 8 | Completion motes, glow | Particle pool, additive-ish `BlendMode.plus` at low alpha |
| 9 | Chrome | Game shell |

#### 6.2.1 Pre-rendered images (per scene, per size; rebuild on size change with 250 ms debounce)

* `sharp`: scene at `min(devicePixelRatio, 2.0)` scale.
* `blurred`: `sharp` drawn through `ImageFilter.blur(sigma: 14 dp)` once.
* `dirty`: `blurred` with the **dirt recipe baked in** (tint, blotches, speckles, streaks, crystals; section 6.4), fully opaque. All dirt look lives in this image, so the shader stays tiny.
* `noise`: shared 256x256 tileable value-noise image (generated once, seeded).
* Budget: all of the above <= 250 ms on a mid-range phone, run once per scene open, cached (LRU of 2 scenes). Show the previous scene cross-fading while generating.

#### 6.2.2 Shader path (upgrade, behind `useShader` flag with automatic fallback)

`shaders/window_glass.frag` (Appendix C.1) takes samplers `uSharp`, `uDirty`, `uMask` and outputs `mix(sharp, dirty, cover)` with `cover = smoothstep(0.0, 0.9, 1.0 - clean)`, plus a faint bright wet rim where `clean` is between 0.35 and 0.65. One full-screen quad per frame, 3 texture reads: cheap.

#### 6.2.3 Canvas fallback (BUILD THIS FIRST)

```dart
canvas.drawImage(sharp, Offset.zero, p);
canvas.saveLayer(glassRect, Paint());
canvas.drawImage(dirty, Offset.zero, Paint());
canvas.drawImageRect(maskImage, maskSrc, glassRect, Paint()..blendMode = BlendMode.dstOut); // mask alpha = clean amount
canvas.restore();
```
The mask image holds `clean` in all four channels (R=G=B=A), so `dstOut` removes dirt exactly where it is clean. Use `FilterQuality.high` when drawing the mask to get soft edges from the half-resolution texture.

#### 6.2.4 The mask accumulator (shared by both paths)

* Resolution: `maskScale = 0.5` mask pixels per dp (about 195x422 on a 390x844 dp phone). Bilinear upscaling gives soft edges for free.
* Each sim frame, pending **stamps** (center, radius, delta) are drawn in one go:
  1. Record a `Picture`: `drawImage(oldMask)`, then ONE `canvas.drawAtlas(brushSprite, transforms, rects, colors, BlendMode.modulate, null, Paint()..blendMode = BlendMode.plus)`, where `brushSprite` is a 64x64 soft radial white sprite and each stamp's color is `white @ alpha = delta` (per-stamp delta rides in the color).
  2. `picture.toImageSync(w, h)`, dispose the old image.
* Droplet trails and the completion reveal use the same stamp mechanism.
* Quantization guard: per-stamp delta must be >= 1/255; if lower, accumulate in the CPU grid and flush into the mask when it exceeds 2/255.

### 6.3 Scenes

Each scene is a `SceneRecipe`: sky stops, layered silhouettes, accents, ambient effect, dirt type, droplet rate, music id, premium flag. Built-in painters only; **no photos**. All randomness is seeded by the recipe seed, so a scene always looks the same.

| id | Name | Free | Palette and composition | Ambient | Dirt | Droplets/s | Music |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `rainy_evening` | Rainy Evening | yes | Sky `#1B2338` -> `#3C4B73` -> `#E8A27A` at 62% height; far skyline `#232C45`, near skyline `#151A28` (14 buildings, widths 40-90, heights 120-320); 5% of window cells lit `#FFD9A0` @ 0.8; 28 bokeh discs (r 8-26, `#FFB77A #FF8F8F #9CC3FF #FFE29A`, alpha 0.22-0.5, blur 2) | Rain streaks beyond glass, `rain_loop` | fog | 6 | `dusk` |
| `misty_morning` | Misty Morning | yes | Sky `#DCE6EA` -> `#F4EBDD`; 3 hill ridges as sums of sines, colors `#B9C9C6 #98B0AE #6F918F`; sun disc `#FFF3D6` r 46 at (70%, 30%) with radial glow; 2 horizontal fog bands alpha 0.25 | Drifting mist bands | dust | 0 | `dawn` |
| `snowy_cabin` | Snowy Cabin | yes | Sky `#28365B` -> `#8FA6D1`; 3 pine rows (triangles, `#1E3B3A #2B5150`); cabin with lit window `#FFC978`; ground `#E8EEF8`; stars on upper third | 60 slow snowflakes behind glass | frost | 0 | `moonlit` |
| `sunset_beach` | Sunset Beach | Calm Plus | Sky `#FF9E7A` -> `#FFD39A` -> sea `#7EC8E3`; sun r 60 with reflection column; 2 palm silhouettes; sea sparkle dots | Sparkle twinkle, gulls | salt | 0 | `dawn` |
| `night_city` | Night City | Calm Plus | Sky `#0B1026` -> `#3A1C5C`; neon rectangles with glow `#FF5FA2 #5FE3FF`; wet-street reflections (vertical gradients) | Light rain optional | grime | 3 | `dusk` |
| `spring_garden` | Spring Garden | Calm Plus | Sky `#CDEBFF` -> `#F0FFE0`; blossom tree = clusters of ellipses `#FFC4D6`; grass band `#A8D5A2`; 2 butterflies | Butterflies, drifting petals | pollen | 0 | `garden` |

Scene order = table order. "Next scene" on completion moves down the list (skipping locked ones when not entitled; if all free scenes are done, loop).

### 6.4 Dirt types (baked into `dirty`) and removal rates

| Type | Base | Tint | Details baked in the painter | Removal `k` | Spots |
| --- | --- | --- | --- | --- | --- |
| fog | `blurred` | `#E8EEF5` @ 0.80 | 40 large soft blotches r 60-160, alpha 0.03-0.07 | 1.6 | none |
| dust | `blurred` x 0.6 + sharp x 0.4 | `#CBB89E` @ 0.55 | 900 speckles r 0.6-1.6 alpha 0.15-0.35, 6 long soft streaks | 0.9 | 3 dried drops (r 14-22) |
| grime | `blurred` x 0.8 | `#8F8A78` @ 0.70 | blotches + 30 vertical run marks (w 2-6, len 80-260, alpha 0.12) | 0.55 | 6 mud splats (r 14-26) |
| frost | `blurred` x 0.9 | `#DCEBFF` @ 0.80 | 60 crystal clusters (6 arms, branch depth 3, alpha 0.5), density grows toward edges | 0.7 | 4 ice patches (r 18-28) |
| salt | `blurred` x 0.7 | `#EDEAE0` @ 0.70 | 2000 white specks r 0.5-1.2, wavy tide lines | 0.8 | 4 crusts (r 14-22) |
| pollen | `blurred` x 0.7 | `#F2E09A` @ 0.60 | 1200 yellow dots, soft clouds | 1.0 | 3 clumps (r 14-20) |

### 6.5 Cloth physics (the "feel")

**Follower.** The cloth center `c` follows the finger target `p` as a damped second-order system:

```text
x'' = w^2 (p - x) - 2 z w x'      w = 2 pi f,  f = 7.5 Hz,  z = 0.85
```
Integrate at 120 Hz (semi-implicit Euler). This gives about 35 ms of soft lag, so strokes look smooth and weighted. Stamps are generated along the **cloth** path, not the raw finger path.

**Cloth visual.**
* Size 76 x 56 dp rounded superellipse, microfiber `#F5F0E6` with a faint stitched border and a vertical wet-sheen gradient (white alpha 0.35 -> 0).
* Heading angle `theta` follows velocity direction: `theta += wrapPi(target - theta) * (1 - exp(-10 dt))`, only when speed > 40 dp/s.
* Squash and stretch: `s = clamp(speed / 1400, 0, 1)`; scale along heading `1 + 0.12 s`, across `1 - 0.06 s`.
* Contact shadow: ellipse offset (0, 6), blur 10, alpha 0.18. Lift scale 1.06 on touch (spring `uiSpring`).
* On finger-up: scale to 0.9 and fade out over 240 ms (`calmOut`).
* Brush radius `r = 34 dp` (tunable 24-50); the visible cloth is wider than the brush so the clean path looks natural.
* Optional soap foam: while moving faster than 200 dp/s emit 0-2 foam bubbles per 20 ms (r 2-5 dp, life 0.6-1.1 s, drift up 8 dp/s, alpha 0.6 -> 0). Particle pool, cap 40. Reduce Motion: off.

**Multi-touch.** Up to 2 independent cloths. Palm rejection: ignore a pointer whose `radiusMajor` > 90 dp.

### 6.6 Stamping and the clean grid

* Stamp spacing along the cloth path: `0.35 r`. For each segment of length `L` between steps, emit `ceil(L / (0.35 r))` stamps evenly spaced.
* Removal per stamp onto the **CPU grid** (cell 8 dp; grid value `D` = remaining dirt, 1 -> 0):

```text
d     = |cellCenter - stampCenter| / r
w     = smoothstep(1.0, 0.45, d)                       // soft brush profile
pr    = lerp(0.65, 1.0, clamp(speed / 450, 0, 1))      // slow pressure is gentler
dD    = k * (spacing / r) * w * pr                      // spacing = 0.35 r
D     = max(0, D - dD)
```
* The **mask** receives the same stamps with `delta = min(1, dD_center)`, so what you see matches the grid.
* Resting cloth (speed < 25 dp/s, finger down): one stamp every 120 ms with `dD = 0.10 k`, so pressing and holding slowly cleans.
* Progress `P = 1 - mean(D)`. Debounce `reportProgress` to 4 Hz.

### 6.7 Droplets (rain scenes)

Data per droplet: `pos, r, vy, state, stateTimer, phase, trailLen`. Max 90 alive.

* **Spawn:** Poisson process with rate `lambda` (table 6.3) per second over the whole glass. Radius `r = 2 + 4 * u^2`, `u ~ U(0,1)` (2 to 6 dp, mostly small). Static if `r < rCrit = 3.4 dp`.
* **Stick-slip motion (the realistic, calm look):** droplets with `r >= rCrit` alternate **pinned** and **slip** states:
  * pinned: duration `U(0.4, 2.5)` s, no motion;
  * slip: duration `U(0.2, 0.7)` s, accelerate `a = 900 dp/s^2` toward `vmax = 60 + 40 (r - rCrit)` dp/s (cap 140), then decelerate to 0 at the end of the slip;
  * lateral meander: `x += sin(y * 0.05 + phase) * 0.15 * |v| * dt`.
* **Trail:** while slipping, stamp a thin clean line into the mask every 6 dp: radius `0.55 r`, delta 0.5. On fog this draws a wet streak; the wipe grid is updated too. Trails also fade the wet rim after 1.5 s (visual only).
* **Merge:** if `dist < 0.8 (r1 + r2)`: new `r = sqrt(r1^2 + r2^2) * 0.98` (area conserved), position = area-weighted center, velocity = area-weighted. If the new droplet has `r >= rCrit` it starts in **slip** immediately. With probability 0.35 leave 1 to 2 satellite static droplets (r 1.2 to 1.8) behind on the trail.
* **Wiping:** a droplet within `0.9 * brushRadius` of a cloth shrinks to zero over 120 ms (absorbed).
* **Cap:** over 90, remove the oldest small static droplets first.
* **Look (Canvas):** body = circle with radial gradient (center transparent, rim `white @ 0.45`), a darker lower arc (`black @ 0.12`), a bright specular dot at upper-left (r * 0.25, `white @ 0.9`). For `r >= 4`, draw a **lens**: clip to the circle and draw `sharp` flipped vertically and magnified 1.6x around the droplet center (the refracted, upside-down scene), then the rim. Limit lens droplets to 40 per frame; profile and drop to plain bodies if over budget.
* Reduce Motion: halve `lambda`, no meander.

### 6.8 Stubborn spots

Spots are overlay blobs (not in the mask). Each has `center, radius, remaining s (1 -> 0), style`. A stamp overlapping a spot (distance < spotRadius + 0.5 r) reduces `s` by `kSpot * (spacing / r) * pr` with `kSpot = 0.28` (about 3 to 4 passes). Draw the blob with alpha `s`, feathered edge, style-specific look (dried drop = ring + inner tone; mud = irregular blob; ice = crystal star; salt crust = speckled disc; pollen clump = yellow cluster). A spot "resisting" gives a stronger haptic (6.10). Spots appear after 25% progress so the opening is pure satisfaction; place them with Poisson-disc spacing >= 90 dp, inside the glass.

### 6.9 Completion

Trigger: `P >= 0.93` **and** all spots `s <= 0.1`.
1. `t = 0`: input still allowed for 300 ms, `complete_soft` sound, haptic `completeSoft`.
2. **Auto-finish reveal** (1.4 s, `calmInOut`): from the last stamp point, a radial stamp grows to cover the glass (radius 0 -> diagonal), delta 1.0.
3. Scene brightness +8% (ambient overlay `white @ 0.06` pulsing once, 1.2 s) and 24 warm light motes drift up (`#FFE7B0`, r 2-5, alpha <= 0.5, life 3 s, rise 20-40 dp/s). Moonlit: 8 motes.
4. At `t = 1.8 s` show the completion sheet. Free play remains available behind it ("fog again" in the chrome menu re-dirties the glass with a 900 ms fade).

### 6.10 Audio and haptics

| Event | Sound | Rule |
| --- | --- | --- |
| Finger down | start `wipe_loop` (looping) at volume 0 | |
| Moving | loop volume `0.85 * smoothstep(40, 700, speed)`, smoothed 60 ms; `rate = 0.9 + 0.25 * clamp(speed / 900, 0, 1)` | update <= 60 Hz |
| Direction reversal | `wipe_squeak_{1..3}` (random) at volume 0.35-0.6, rate 0.95-1.1 | when `dot(vPrev, vNow) < 0` and prev speed > 350; cooldown 700 ms; probability 0.4 |
| Finger up | fade out loop 160 ms | |
| Rain scenes | `rain_loop` ambient at 0.35 (music at 0.6) | starts on scene open, cross-fades on scene change |
| Completion | `complete_soft`, duck music to 0.4 for 1.6 s | |

| Haptic event | Rule |
| --- | --- |
| `wipeTick` (soft) | every 18 dp of cloth travel while speed >= 60 dp/s |
| `scrubResist` (medium) | when a stamp reduces a spot's `s`, at most every 120 ms |
| `completeSoft` | at completion start |

### 6.11 Animation inventory

| Animation | Spec |
| --- | --- |
| Cloth lift/lower | scale 0.9 <-> 1.06 `uiSpring`; fade 240 ms |
| Scene change | cross-fade 600 ms; new dirt fades in 900 ms |
| Droplet absorb | shrink 120 ms `softIn` |
| Wet rim | handled in shader (0.35-0.65 band); Canvas fallback: skip |
| Reveal | 1.4 s `calmInOut` |
| Motes | 3 s life, ease-out rise, alpha `sin(pi t)` |
| Hint card | slide up 280 ms, hold 4 s, fade 280 ms |

### 6.12 Persistence

`window_wipe`: `completedScenes[]`, `current: {scene, grid (base64 of Uint8 cells), spots[] (x, y, s), elapsed}`. On resume rebuild the mask by painting the grid cells (value `1 - D`) at mask resolution with a 1-cell blur, then continue. Droplets are not persisted.

### 6.13 Tuning table (`WindowWipeTuning`)

| Key | Default | Range |
| --- | --- | --- |
| `brushRadius` | 34 | 24-50 |
| `followerHz` | 7.5 | 4-14 |
| `followerZeta` | 0.85 | 0.5-1.2 |
| `stampSpacing` | 0.35 | 0.2-0.6 |
| `restCleanRate` | 0.10 | 0-0.3 |
| `completionThreshold` | 0.93 | 0.85-0.98 |
| `revealSeconds` | 1.4 | 0.6-3 |
| `kSpot` | 0.28 | 0.1-0.6 |
| `rCrit` | 3.4 | 2-5 |
| `maxDroplets` | 90 | 20-150 |
| `squeakProb` | 0.4 | 0-1 |

### 6.14 Edge cases

Orientation change (tablets): rebuild images, keep grid (normalized coordinates), mask rebuilt from grid. App backgrounded mid-stroke: release pointers, stop loop sound. Tiny screens (<= 320 dp wide): brush radius x 0.85. Very fast flicks: stamps are interpolated along the segment, never skipped. Low-end fallback: if average frame time over 2 s exceeds 14 ms, drop `lens` droplets, halve the mask scale to 0.35 and disable foam.

### 6.15 Acceptance

* Smooth 60 fps (profile) while scrubbing continuously for 60 s; touch-to-cleaning latency < 50 ms.
* Edge of the cleaned path is soft, never jagged or blocky; no visible grid cells.
* A casual player finishes a fog scene in 25-70 s; grime in 60-120 s.
* Droplets merge and slide with believable pauses; they never jitter or teleport.
* Completion reveal feels like an exhale: no abrupt pop.
* Golden PNGs at 0%, 40%, 90%, 100% look right (section 16.3).

---

## 7. Game 2: Bubble Pop

*"Soft bubbles drift up. Touch one and it opens like a little sigh."*

### 7.1 Experience

Pastel bubbles of different sizes rise slowly from the bottom, swaying in a gentle invisible breeze. Touch or swipe through them to pop. Each pop is a tiny event: the film bursts into a ring, droplets spray and fall, neighbors get nudged, a soft pop sounds (lower for bigger bubbles) and the phone ticks. Every 25 pops the whole sky "blooms": remaining bubbles pop in a gentle cascade and the background palette changes. Holding a finger on empty space blows a stream of small bubbles (a wand). No score, no losing; bubbles that reach the top simply float away.

### 7.2 World model

Logical coordinates are dp; origin top-left; `y` grows downward. Fixed step 1/120 s. All values are tunable (7.9).

**Bubble fields:** `x, y, vx, vy, R, tint (0-5), phase, wobblePhase, age, state {alive, popping}, popT`.

**Spawning.** Maintain `spawnTarget = 12` alive bubbles (hard cap 40 including wand bubbles). When below target, spawn after a random delay `U(0.35, 0.9)` s at `y = H + R + 10`, `x` random with at least `0.8 R` clearance from existing bubbles near the bottom. Radius: `R = 24 + 40 * u^1.6` (24 to 64 dp, skewed to small). Tint uniform over the 6 sprite tints.

**Vertical motion (buoyancy):** relax toward a size-dependent rise speed:

```text
vt   = 42 + 0.9 (R - 24)              // dp/s: 42 at R=24, 78 at R=64
vy  += (-vt - vy) * 1.2 * dt          // kappa = 1.2 /s
```

**Horizontal sway (breeze):**

```text
ax   = 14 * sin(2 pi (0.11 t + y / 620) + phase)    // dp/s^2
vx  += ax * dt;  vx *= exp(-0.9 dt)                 // damping 0.9 /s
```

**Soft collisions** (no bounce): for each pair with `d < 0.95 (R1 + R2)`:
`o = 0.95 (R1 + R2) - d; F = 220 * o` along the normal, applied as acceleration split by inverse mass (`m = R^2`), plus normal-velocity damping `6 /s`. Use a uniform grid (cell = 130 dp) for neighbor lookup; at most 40 bubbles so O(n^2) is also fine.

**Walls:** soft spring: if `x - R < 8`, `ax += 120 (8 - (x - R))`; mirrored on the right. Bubbles leaving the top (`y + R < -10`) are removed; the last 90 dp fade alpha to 0.

**Wobble (surface tension):** `w = 0.035 sin(2 pi * 2.1 t + wobblePhase)`; scale x `1 + w`, y `1 - w`. Reduce Motion: `w = 0`.

### 7.3 Input

* `Listener` with multi-touch. For every pointer move, test the **capsule** from the previous to the current position (radius 14 dp) against each alive bubble circle (radius `R + 6`). Hit -> pop. At most 3 pops per frame (keeps sound clean); extras wait one frame.
* Touch-down on a bubble pops it immediately (no tap-vs-drag delay).
* **Wand:** finger held on empty space for 400 ms without moving more than 10 dp starts emitting 6 small bubbles/s (`R = 14 to 22`, initial `vy = -60`, small random `vx`) at the finger position until release. Wand bubbles count toward the cap of 40; they count toward the round goal when popped.
* Pointer velocity gives a tiny push: bubbles within `R + 20` of a fast finger (speed > 600 dp/s) that were *not* popped this frame receive `dv = 25 * (1 - d / (R + 20))` away from the finger (so a flick sweeps them gently aside, and slow touches pop).

### 7.4 Pop effect (0.42 s)

| Element | Spec |
| --- | --- |
| Film burst | Ring from `R` to `1.35 R` over 0.22 s (`calmOut`), stroke `0.08 R -> 0`, alpha `0.7 -> 0`, color = tint lightened 20% |
| Body | scale `1 -> 1.12`, alpha `1 -> 0` over 0.16 s |
| Droplets | `n = clamp(round(R / 4), 8, 16)`; angle uniform + jitter; speed 90-210 dp/s; drag `v *= exp(-3.2 dt)`; gravity 140 dp/s^2; size 1.6-3.2 dp; life 0.35-0.6 s; alpha `1 - t^2`; color = tint lightened 35% |
| Sparkle (R >= 48 only) | 4-point star, size `0.5 R`, alpha 0.8 -> 0 in 0.25 s |
| Neighbor impulse | each alive bubble within `2 R` of the popped one: `dv = 90 * (1 - d / (2 R))` away from the pop center |
| Reduce Motion | no droplets, no sparkle; ring only, 0.18 s |

Particles come from a pre-allocated `ParticlePool` (cap 400).

### 7.5 Rendering

* **Sprite:** at startup draw 6 bubble sprites (256x256 px) with Canvas into `ui.Image`s, one per tint:
  * body: radial gradient, alpha 0.05 at center to 0.22 at 0.85 R, tint color;
  * rim: ring 0.86 R to 1.0 R, gradient tint alpha 0.55 -> 0.0 outward;
  * iridescence: `SweepGradient` rim overlay of two neighboring hues at alpha 0.25;
  * highlights: large ellipse (upper-left, `white @ 0.85`, blurred 2 px), small ellipse (lower-right, `white @ 0.35`), thin arc highlight along the upper-left rim.
* Draw each bubble with `drawImageRect` under `canvas.save()/translate/scale` (non-uniform scale for wobble). Highlights stay upper-left (do not rotate the sprite): consistent light.
* **Background:** vertical 3-stop gradient (palette table 7.6). 8 large blurred decorative circles (r 60-140, alpha 0.10-0.18, tint = lighter palette color) drift at 6-14 dp/s on sine paths (parallax 0.2x of bubbles); 12 tiny twinkle dots.
* **Idle hint:** after 8 s without touch, the bubble nearest the screen center pulses scale `1 -> 1.06` at 0.5 Hz (off in Reduce Motion).
* Cap overdraw: bubbles are small and few; one `RepaintBoundary` for background, one for bubbles+particles.

### 7.6 Rounds and palettes

`popGoal = 25`. A thin soft arc at the top center fills with each pop (not a number). At the goal, **bloom**:
1. Remaining alive bubbles pop in order of descending `y` (bottom first), 55 ms apart, volume 0.4 each, polyphony cap 6.
2. Sound `bloom`; music ducks to 0.4 for 1.6 s; haptic `completeSoft`.
3. Background cross-fades to the next palette over 1.2 s; `rounds += 1`.
4. No sheet; the game continues. After rounds 1, 3, 6, 10 show the completion sheet once (so there is a natural exit point).

| # | Palette | Stops | Free |
| --- | --- | --- | --- |
| 1 | Peach Sky | `#FFE3D0 -> #FFC8D6 -> #D7C6FF` | yes |
| 2 | Mint Lagoon | `#D9F5E8 -> #BDE7F0 -> #C8D5FF` | yes |
| 3 | Lilac Dusk | `#E6D9FF -> #F6C9E3 -> #FFD9C2` | yes |
| 4 | Ocean Hush | `#CDE8FF -> #A8C8F2 -> #B9B1F0` | Calm Plus |
| 5 | Lemon Meadow | `#FFF3C9 -> #DDF0C8 -> #BFE6E0` | Calm Plus |
| 6 | Night Bloom (dark, bubbles slightly luminous) | `#1A1A33 -> #2B2650 -> #3F2E63` | Calm Plus |

Bubble tints (6): `#FFB3C7 #FFD2A8 #FFF0A8 #B9F0C8 #A8DCFF #D0B8FF`. In Night Bloom, boost sprite body alpha by 1.4x.

### 7.7 Audio and haptics

| Event | Sound | Notes |
| --- | --- | --- |
| Pop, `R < 36` | `pop_small` | rate `U(0.94, 1.08)`, volume `0.55 + 0.3 * (R - 24) / 40` |
| Pop, `36 <= R < 50` | `pop_medium` | same |
| Pop, `R >= 50` | `pop_large` | same |
| Polyphony | max 8 voices; if exceeded, drop the oldest with a 30 ms fade; min 35 ms between starts of the same sample | |
| Wand start | `water_drop` at 0.3 | once |
| Bloom | `bloom` | |
| Music | `dawn` default; Night Bloom -> `moonlit` | |

| Haptic | Mapping |
| --- | --- |
| `popSmall` | light, min interval 45 ms |
| `popMedium` | medium |
| `popLarge` | heavy |
| `bloom` | `completeSoft` |

### 7.8 Persistence

`bubble_pop`: `{rounds, totalPopped, paletteIndex, poppedThisRound}`. Bubbles themselves are not saved.

### 7.9 Tuning table (`BubblePopTuning`)

| Key | Default | Range |
| --- | --- | --- |
| `spawnTarget` | 12 | 6-20 |
| `maxBubbles` | 40 | 20-60 |
| `radiusMin` / `radiusMax` | 24 / 64 | 16-30 / 48-90 |
| `riseBase` / `risePerDp` | 42 / 0.9 | 20-80 / 0-2 |
| `relaxKappa` | 1.2 | 0.4-3 |
| `windAmp` | 14 | 0-40 |
| `windDamp` | 0.9 | 0.3-2 |
| `repelK` | 220 | 50-500 |
| `popGoal` | 25 | 10-60 |
| `hitMargin` | 6 | 0-16 |
| `wandHoldMs` | 400 | 200-800 |

### 7.10 Acceptance

* 60 fps with 40 bubbles + 200 particles in profile mode.
* Pop reacts on the same frame as touch-down; swiping through a cluster feels like brushing through foam, not a laggy machine-gun.
* Bubble motion is calm: no jitter, no sudden speed changes, collisions never "bounce".
* Pop sounds never stack into harshness (limiter + polyphony cap), and size is audible.

---

## 8. Game 3: Zen Sand Garden

*"Rake the sand. Place a stone. Breathe out."* No goal, no completion; it is the app's meditative sandbox and the best candidate for long sessions.

### 8.1 Experience

A wooden-framed tray of fine sand. The player drags a rake held slightly above the finger; five parallel grooves with raised ridges are carved, lit by a soft low sun so they have real relief. Stones can be placed; when a stone lands, concentric ripples radiate outward ring by ring. A smoothing brush erases. Random distant wind chimes play every so often. The garden is saved automatically.

### 8.2 Height-field model

* Maintain a height texture `H` (RGBA8, gray) at **1 texel = 2 dp** (about 195x422 on a 390x844 phone). Flat sand = `0.5` (128). Groove = `0.28` (71). Ridge = `0.62` (158).
* Each frame, pending carve operations are drawn into a new `Picture` on top of the previous `H` image (`drawImage(old)`; then strokes; then `toImageSync`), and the old image is disposed. **Later strokes overwrite earlier ones** (raking over a pattern replaces it, as in real sand).
* The visible sand is `shaders/sand_light.frag` (Appendix C.2) sampling `H`, computing a normal from the height gradient and shading with a fixed light. A Canvas fallback is required (8.7).

### 8.3 Rake

| Parameter | Rake | Fine rake |
| --- | --- | --- |
| Tines | 5 | 9 |
| Spacing | 16 dp | 9 dp |
| Groove width | 6.4 dp | 3.6 dp |
| Ridge width | 3 dp | 1.8 dp |
| Ridge offset from groove center | `groove/2 + ridge/2` | same |

**Carving a segment** (per tine, in order within each frame: all ridges first, then all grooves): two ridge strokes at lateral offsets `+-(groove/2 + ridge/2)` with gray 158, then the groove stroke with gray 71; stroke caps round; strokes in texel coordinates (`dp / 2`). If notches appear at segment joins, extend each segment backward by 1 texel.

**Rake dynamics.**
* Head position `c` follows `p_finger + (0, -44 dp)` (the head is offset above the finger so the finger does not hide the grooves) via a damped spring `f = 5.5 Hz, z = 0.95` ("heavy").
* Heading `theta` follows the velocity direction when speed > 25 dp/s: `theta += wrapPi(target - theta) * (1 - exp(-10 dt))`.
* Tine `i` position: `c + n(theta) * (i - (N - 1) / 2) * spacing`, `n(theta) = (-sin theta, cos theta)`.
* The rake only carves when speed >= 25 dp/s (a resting finger does not dig).
* **Curvature culling:** curvature `kappa = |d theta / ds|`. For tine offset `o_i`, if `|o_i| * kappa > 0.85` skip that tine's carving this step (prevents folded, self-intersecting grooves on tight turns).
* **Stones block:** skip any tine carve point inside a stone's footprint (`radius + 3 dp`).
* Visual: wooden rake head (bar length `(N - 1) * spacing + 28`, thickness 10, `#8B6B4A` with highlight and grain lines, N small teeth), a handle line to the finger (width 5, `#7A5C3E`, alpha 0.9), drop shadow offset (6, 8) blur 6 alpha 0.25. Fade in 160 ms on touch, out 200 ms on release.

### 8.4 Stones

* Tray: three stones (S r=22, M r=32, L r=44 dp) at the bottom of the chrome; drag one onto the sand to place; drag a placed stone to move it; drag a stone back onto the tray to remove it. Max 8 on sand.
* Shape (procedural, seeded): 12 vertices on an ellipse (axis ratio 0.78, random rotation), radius jitter `+-12%`, closed Catmull-Rom spline. Fill: radial gradient `#CFCFD6 -> #7B7B88 -> #4A4A55` centered upper-left; thin dark rim stroke alpha 0.25; optional moss patch (a green blurred blob, alpha 0.5, 30% of stones). Contact shadow: blurred ellipse offset (4, 6), alpha 0.3.
* Pick up: scale to 1.08 with a larger shadow offset (8, 12). Drop: scale `1.12 -> 1.0` with `bouncy` spring, 6 dust particles (`sand color lightened`, r 2-4, life 0.5 s), sound `stone_place`, haptic `stonePlace`.
* **Ripples** (on drop): `n = 3 (S), 4 (M), 5 (L)` rings at radii `rStone + 12 + 14 (k - 1)`. Ring `k` is carved progressively as an arc sweeping `0 -> 2 pi` over 450 ms, ring `k` starting `130 (k - 1)` ms after the drop, using the current rake's groove/ridge profile. Skip portions inside other stones.

### 8.5 Tools and chrome

Floating glass tool bar at the bottom: `Rake | Fine rake | Stone | Smooth | Undo | Sand color`.
* **Smooth:** a soft brush (radius 40 dp, flatten to 0.5 with a radial alpha falloff) that erases grooves; sand sound at lower volume.
* **Undo:** keeps the last 10 `H` snapshots (`image.clone()`, dispose beyond 10) and the stone list state; pushed on each pointer-down that will modify the garden.
* **Clear:** long-press Smooth for 800 ms -> confirm sheet -> flat sand.
* **Sand colors:** Warm `#E7D3B0`, Pearl `#E9E5DC`, Rose `#EBCFC4` free; Moon `#BFC3D6` Calm Plus. The tray frame tone adapts a little (darker for Moon).
* **Share:** `(...)` menu -> "Share garden": render a `RepaintBoundary` at pixel ratio 2 to PNG and share with `share_plus`.

### 8.6 Audio and haptics

| Event | Sound | Rule |
| --- | --- | --- |
| Raking | `sand_loop` looping | volume `0.8 * smoothstep(30, 500, speed)`, rate `0.9 + 0.2 * clamp(speed / 700, 0, 1)`; fade out 160 ms on release |
| Smoothing | `sand_loop` | volume x0.5, rate 0.8 |
| Stone drop | `stone_place` | volume 0.9, pan by x position (-0.5..0.5) |
| Ambient chimes | `wind_chime_{0..3}` random | every `U(25, 55)` s, volume 0.5, pan `U(-0.4, 0.4)`; only while the app is foreground |
| Music | `garden` default | |

Haptics: `sandTick` (soft) every 22 dp of travel at speed >= 30 dp/s; `stonePlace` (medium) on drop.

### 8.7 Canvas fallback (BUILD FIRST)

Without the shader, render the sand as: base sand color, then for each carved tine path draw (a) a lighter highlight line offset (-1.2, -1.2) dp and (b) a darker shadow line offset (+1.2, +1.2) dp, alpha 0.35 each; light comes from the upper-left. Keep the carved paths in a list that is baked into a `ui.Picture` periodically (every 2 s or 120 segments) so repaint cost stays flat. This version is used in tests and on weak GPUs.

### 8.8 Persistence

Files: `garden_height.png` (the `H` image) + `garden.json` (`{stones: [{x, y (normalized), size, rot, seed, moss}], sandColor, tool}`) in the app documents directory. Save debounced 2 s after the last change and on pause/exit; load on open. Also track `calmSeconds` (time the screen is on this game, foreground only).

### 8.9 Tuning table (`SandGardenTuning`)

| Key | Default | Range |
| --- | --- | --- |
| `texelDp` | 2 | 1.5-3 |
| `tines` / `fineTines` | 5 / 9 | 3-7 / 6-13 |
| `spacing` / `fineSpacing` | 16 / 9 | 12-24 / 6-12 |
| `grooveHeight` / `ridgeHeight` | 0.28 / 0.62 | 0.1-0.4 / 0.55-0.8 |
| `headOffsetY` | -44 | -80-0 |
| `rakeHz` / `rakeZeta` | 5.5 / 0.95 | 3-10 / 0.6-1.2 |
| `minCarveSpeed` | 25 | 5-80 |
| `curvatureLimit` | 0.85 | 0.5-1.2 |
| `rippleSpacing` | 14 | 10-22 |
| `lightStrength` | 6.0 | 2-12 |

### 8.10 Acceptance

* Grooves look carved: parallel, consistent width, with believable relief that changes as the pattern curves; no gaps at segment joins.
* Raking in a tight circle does not produce garbage; inner tines lift out.
* Stone ripples grow ring by ring and respect other stones.
* Smooth 60 fps while raking continuously for 2 minutes; undo restores exactly.
* Garden survives app restarts pixel-for-pixel (within PNG round trip).

---

## 9. Game 4: Color Sort

*"Pour the colors until every tube holds one."* A water-sort puzzle made gentle: unlimited undo, free hints, no move counter, no failing.

### 9.1 Rules

* State: `T` tubes, each a stack of color ids (bottom to top), capacity `cap` (4, later 5).
* Legal move `src -> dst`: `src` non-empty; `dst` is empty **or** `top(dst) == top(src)`; `dst` has free space. The move transfers the whole contiguous run of the top color from `src`, limited by the free space in `dst`: `n = min(run(src), cap - len(dst))`.
* Pointless moves are rejected in the UI as a soft shake (not an error): moving a fully uniform tube into an empty tube.
* A tube that is **full and uniform** gets a cork and locks.
* Win: every non-empty tube is full and uniform. No fail state exists; if the player is stuck, **Undo**, **Restart**, **Hint** and **Add tube** (once per level) are always available.

### 9.2 Level generation (infinite, deterministic)

`Level(n)`: `colors C = clamp(3 + (n - 1) ~/ 4, 3, 12)`, `cap = n <= 60 ? 4 : 5`, `tubes T = C + 2`. `seed = n * 7919`.

```text
generate(n):
  for attempt in 0..:
    rng = Rng(seed + attempt)
    units = [c for c in 0..C-1 for _ in 1..cap]; shuffle(units, rng)
    fill the first C tubes with cap units each; leave 2 tubes empty
    reject if any tube is already full+uniform, or the top two colors of every tube are identical for all tubes (too easy)
    result = solve(state, nodeLimit: 200000)
    if result.solvable and result.minMoves >= C * 2: return Level(state, solution = result.path)
```
A level is identified only by `n`, so progress is a single integer. The solver also provides the **hint** (next move of a solution from the *current* state; recompute lazily, cached by state key).

**Solver** (`solver.dart`): DFS with a visited set. State key = sorted list of tube strings. Move ordering: prefer moves that (1) complete a tube, (2) merge onto the same color, (3) move into an empty tube last. Prune: skip moves where `src` is uniform and `dst` is empty; skip moves that undo the previous move. Node limit 200k (hint) and run generation off the UI thread with `compute()`/`Isolate.run`. If a level cannot be proven solvable within the limit, discard and retry with the next attempt. Unit-test: 200 levels (1-200) all generate, all solvable, generation under 400 ms each.

### 9.3 Colors and symbols (colorblind assist)

12 colors, hue-ordered, calm saturation. Each has a symbol drawn on its liquid layers when **Colorblind assist** is on (or always for the last 4 colors, which are the most similar).

| # | Name | Hex | Symbol |
| --- | --- | --- | --- |
| 0 | Coral | `#F28B82` | dot |
| 1 | Apricot | `#F6B26B` | square |
| 2 | Butter | `#F2D96B` | triangle |
| 3 | Leaf | `#8BC98A` | diamond |
| 4 | Teal | `#5CC0B3` | plus |
| 5 | Sky | `#7FB8F2` | ring |
| 6 | Indigo | `#7C8CF2` | star |
| 7 | Lavender | `#B79DF2` | crescent |
| 8 | Orchid | `#E39AE0` | bowtie |
| 9 | Rose | `#F29AB8` | heart |
| 10 | Stone | `#B9B2A8` | stripes |
| 11 | Cocoa | `#A67C5B` | hexagon |

**Write a test** that converts all pairs to CIELAB and asserts `deltaE2000 >= 12`; nudge lightness/chroma of failing colors minimally (keep hue order) until it passes. Record final hex values in the code and update this table in `docs/DECISIONS.md`.

### 9.4 Layout

* Tube width `w = 44` dp, gap 14, unit height `42` dp, tube height `cap * 42 + 18`.
* `perRow` = the smallest number such that `perRow * (w + gap) - gap <= availableWidth`; if `perRow < ceil(T / 3)`, shrink `w` toward 34 (and gap toward 8). Rows <= 3; rows centered vertically in the safe area with 24 dp between rows; each row centered horizontally.
* Tubes cast a soft contact shadow (ellipse, alpha 0.15) on the table. Background: vertical gradient per level band: levels 1-10 `#FBEFE4 -> #EBDDF5`, 11-30 `#E3F1EE -> #D9E4F7`, 31+ cycle through the Bubble Pop palettes 1-5. Moonlit: `#14121C -> #0C0B12`.

### 9.5 Tube rendering

* Glass shape: path with straight sides and a semicircular bottom (radius `w/2`), open top with a rim ellipse (height 6 dp). Interior fill `white @ 0.10`; outline 1.5 dp `white @ 0.55`; left highlight stripe (4 dp wide, `white @ 0.35`, from 12% to 80% of the height); a faint right-side reflection (`white @ 0.12`).
* Liquid layers: each layer = color with a subtle vertical gradient (top +8% lightness, bottom -6%); a 1 dp lighter line between layers; the top layer has a **meniscus**: an ellipse (height 5 dp, lighter 15%) at the surface.
* Cork: appears on completion (drops 14 dp with `bouncy` spring, scale `0.8 -> 1`), cream `#EBDDC4` with a darker ring.
* Selected tube: lifts 14 dp (`uiSpring`) and shows a soft glow (`accent @ 0.25`, blur 16).
* Hint: the source and destination glow alternately, pulse period 1.2 s, until the next touch.

### 9.6 Interaction and animation

| Action | Behavior |
| --- | --- |
| Tap a tube | Select (lift 14 dp), sound `select_tube` at `rate = 0.9 + 0.04 * tubeIndex` (cap 1.3), haptic `tubeSelect` |
| Tap the same tube | Deselect |
| Tap a valid destination | Pour (9.7) |
| Tap an invalid destination | Source shakes: `x += 5 * sin(2 pi * 11 t) * exp(-t / 0.12)` for 260 ms; `ui_back` at 0.25 volume; haptic light; selection stays |
| Tap empty space | Deselect |
| Undo | Restores the previous state with a reversed, faster pour (x1.5); unlimited |
| Restart | Cross-fade 300 ms to the initial state |
| Hint | Highlights the next solver move; 3 s cooldown (button dims) |
| Add tube | Once per level; a new empty tube slides in (280 ms `calmOut`), layout recomputed with animated positions |

Input during an animation: moves involving tubes that are animating are ignored; others are accepted and **queued** (max 2). With a queue, playback speed becomes x1.4. "Fast pour" setting = x1.6 always.

### 9.7 Pour animation (n units, from `src` to `dst`)

Timeline (default speed):

| Phase | Time | What happens |
| --- | --- | --- |
| 1 Approach | 0-160 ms | `src` rises and moves so its lip sits above `dst`'s mouth: target = `(dst.x + dir * 0.62 w, dst.top - 20)`, `dir = -1` if `src` is right of `dst`, else `+1` (`float` spring) |
| 2 Tilt | 160-420 ms | Rotate about the lip: angle `phi = sign * easeInOut(t) * phiMax`, `phiMax = 52 deg + 38 deg * (1 - fillFraction)`, so it tilts further as it empties |
| 3 Pour | 420 ms to `420 + 180 n` | Liquid moves: `src` volume down, `dst` volume up, linear; stream visible; splash at `dst` |
| 4 Return | next 280 ms | Tilt back, return to the slot (`calmInOut`) |

Total for `n = 1`: about 880 ms.

**Stream:** drawn once `phi >= 34 deg`. Start at the lip point `P0`; initial velocity `v0 = 70 dp/s` along the lip's outward-down tangent; gravity `g = 1400 dp/s^2`. Solve flight time `tf` from `y0 + v0y * tf + 0.5 g tf^2 = ySurface(dst)`; set `v0x = (dstCenterX - x0) / tf` so it lands in the middle. Draw a smooth polyline of that parabola (16 samples); width `6 dp` at the lip tapering to `3.5 dp` at the impact, round caps, color = poured color, slight width ripple `+-0.4 sin(2 pi 6 t)`.

**Splash:** every 50 ms while pouring, emit 2 to 3 tiny droplets (r 1-2 dp, upward `vy -60..-120`, gravity 600, life 0.3 s) at the impact point, light version of the color.

**Surface wave** on `dst` after impact: `A(t) = A0 exp(-t / 0.5) sin(2 pi 2.2 t)` with `A0 = 2.2 dp`, applied to the surface line as a vertical offset with a half-period spatial wave across the width.

### 9.8 Liquid geometry in a tilted tube (area-preserving)

For a tube rotated by `phi` the surface stays **horizontal in the world**. Work in tube-local coordinates `(u, v)` (u across, v up from the tube bottom center). Gravity in local coords: `g = (sin phi, -cos phi)` (rotate `(0, -1)` by `-phi`). The surface is the line `g . p = c`.

1. Tube polygon: rectangle `[-w/2, w/2] x [0, H]` plus the rounded bottom approximated by a 16-point arc.
2. Liquid region = polygon clipped to the half-plane `g . p <= c` (Sutherland-Hodgman against one half-plane).
3. Find `c` for a target volume `V` (in unit-areas) by **bisection** (12 iterations) on the clipped polygon's area.
4. Layer slabs: for cumulative volumes `V_1 < V_2 < ...` find `c_1, c_2, ...`; slab `i` = polygon clipped between `c_{i-1}` and `c_i`.
5. Spill: if the surface line reaches the lip while pouring, liquid exits (this is what the stream represents); the volume transfer in phase 3 is a timed animation, not a fluid solver.
6. **Slosh:** add `s` to the surface angle where `s` is a spring (`k = 60, c = 5`) driven by the tube's lateral acceleration: `target = clamp(-ax * 0.0004, -0.12, 0.12)` rad. Settles in about 0.6 s after moves. Reduce Motion: `s = 0`.

### 9.9 Win

All tubes uniform or empty -> `level_complete`, haptic `levelComplete`, music duck 0.4. Tubes do a left-to-right wave: each scales `1 -> 1.04 -> 1` (`bouncy`) and emits a soft glow, 70 ms stagger. After 1.4 s show the completion sheet with **Next level** primary. Persist `level = n + 1` on win (so quitting mid-level resumes the same level from its initial state).

Tube completion (mid-level): cork drop + sound `tube_complete_{colorIndex % 6}` + haptic `tubeComplete` + 6 sparkles.

### 9.10 Audio and haptics

| Event | Sound | Notes |
| --- | --- | --- |
| Select | `select_tube` | rate by tube index |
| Pour | `pour_loop` loop | start with 120 ms ramp at phase 3; `rate = 0.85 + 0.5 * dstFillFraction` (the glug rises as the target fills); stop with 120 ms fade at phase 3 end; volume 0.7 |
| Invalid | `ui_back` @ 0.25 | |
| Tube complete | `tube_complete_k` | |
| Level complete | `level_complete` | |

Haptics: `tubeSelect` (selection tick); `pourPulse` (soft) every 110 ms during phase 3; `tubeComplete` (medium); `levelComplete` (success).

### 9.11 Persistence and menus

`color_sort`: `{level, usedAddTube (for the current level only, not persisted)}`. Chrome menu: Level picker (a sheet showing the last 20 completed and the next 5), Restart, Hint, Settings. Progress ring on the home card = `min(1, level / 100)`.

### 9.12 Tuning table (`ColorSortTuning`)

| Key | Default | Range |
| --- | --- | --- |
| `tubeWidth` | 44 | 34-56 |
| `unitHeight` | 42 | 32-52 |
| `liftDp` | 14 | 6-24 |
| `approachMs` / `tiltMs` / `pourMsPerUnit` / `returnMs` | 160 / 260 / 180 / 280 | 80-400 / 150-500 / 100-300 / 160-500 |
| `phiBaseDeg` / `phiExtraDeg` | 52 / 38 | 40-70 / 0-50 |
| `streamGravity` | 1400 | 800-2200 |
| `waveAmp` | 2.2 | 0-5 |
| `sloshK` / `sloshC` | 60 / 5 | 20-120 / 2-12 |
| `queueSpeed` | 1.4 | 1-2 |
| `hintCooldownMs` | 3000 | 0-8000 |

### 9.13 Acceptance

* Liquid volume is conserved visually at every tilt (no layer appears to grow or shrink while tilting).
* Pour looks physical: stream lands in the middle of the destination, the surface settles with a damped ripple, the tilt increases as the tube empties.
* 200 generated levels are all solvable; hints always lead toward a solution.
* A full level (about 10 to 30 moves) can be played quickly: queued moves and Fast pour keep it from feeling slow.

---

## 10. Game 5: Grow a Plant

*"Water it. Catch a little light. Watch it grow."* A windowsill garden. The plant never dies; it just rests when neglected. Completed plants join a collection shelf.

### 10.1 Experience

A pot sits on a windowsill with soft daylight. The player drags a small watering can over the pot to tilt and pour; tiny golden **light motes** float down from the window and can be tapped to collect. Moisture and light feed growth. Growth advances in seven stages with a procedurally drawn plant that sways in a light breeze and wiggles when touched. At full bloom: a gentle burst of petals/pollen, a chime, and the plant is added to the collection; the next species unlocks.

### 10.2 State and growth rules

```text
m  moisture 0..1   (decays 0.012 /s while the game is open)
L  light    0..1   (decays 0.02 /s)
g  growth   0..1   (never decreases)

dg/dt = 0.012 * min(m / 0.9, 1) * (0.4 + 0.6 * L)      only while m > 0.25
```
Full care gives about 83 s to bloom; typical play 2 to 3 minutes. **No offline growth and no real-time waiting**: growth only advances while the game is open and cared for. If `m <= 0.25` the plant "rests" (no change, no wilting). Stages: `0 seed, 1 sprout, 2 seedling, 3 young, 4 budding, 5 bloom, 6 full bloom` at `g = 0, 0.12, 0.30, 0.50, 0.70, 0.88, 1.0`.

### 10.3 Watering

* The can (procedural: body `#8FB8D9` with highlight, spout, handle) rests at the top right. Drag it; when its spout is within the pot's horizontal span (+- 40 dp) and above it, it **tilts** from 0 to 38 degrees over 300 ms (`uiSpring`); pouring starts when the tilt exceeds 20 degrees. It returns to rest on release (`float` spring).
* **Water particles** (pool, cap 160): spawn 90/s at the spout, initial velocity `(-60 + N(0, 10), 0) dp/s`, gravity 1100 dp/s^2, radius 1.8-2.8 dp, drawn as capsule streaks oriented along velocity (length `v * 0.02`), color `#BFE3FF @ 0.9`.
* A drop that reaches `y >= soilY` is removed: `m += 0.0036`, spawn a splash micro-particle; every ~10th impact plays `water_drop`.
* Over-watering: if `m > 1`, clamp to 1 and let excess drip off the pot rim as a few droplets that fall to the sill and form a tiny puddle (cosmetic).
* Soil color: `lerp(#B38B63 (dry), #6B4A32 (wet), m)`; dry soil shows small cracks (3 thin dark lines) when `m < 0.15`.

### 10.4 Light motes

A mote spawns every `U(1.5, 3.5)` s from the window area (top), drifts down on a sine path (`vy 18-30 dp/s`, sway 12 dp, radius 6-9 dp, `#FFE7A3` glow, pulsing alpha 0.6-1.0), max 4 alive, life 9 s (fades). **Tap** (hit radius 28 dp): `L = min(1, L + 0.18)`, sparkle burst (6 particles), `water_drop` at rate 1.5 and volume 0.25 (a "ting"), haptic light.

### 10.5 Species (parameter tables)

All plants are drawn by `PlantPainter(species, g, t, wind, touchImpulse)`.

| # | Species | Unlock | Structure | Key numbers |
| --- | --- | --- | --- | --- |
| 1 | Sunny (sunflower-like) | start | Single stem + 6 broad leaves + large flower | Stem height up to 250 dp; leaves at nodes every 0.16 of the stem, alternating, length up to 62 dp; flower: 14 petals `#FFD35C`, center disc r 22 `#7A4B2A` with 90 seeds on a phyllotaxis spiral (angle 137.5 deg, `r = 1.9 sqrt(i)`) |
| 2 | Fern | after #1 | 7 curved fronds with 14 leaflet pairs each; fiddlehead unfurling | Frond length up to 190 dp; unfurl: rolled spiral angle `a(g) = (1 - g_f) * 540 deg -> 0`; colors `#7DBB8A -> #3F8F6B` |
| 3 | Succulent | after #2 | Rosette of 21 leaves on the golden angle in 5 rings; small pink flower at the top at full bloom | Leaf length 18-46 dp; colors `#9BCDA0 -> #5FA87F`, tips tinted `#E8A0B0` |
| 4 | Bonsai | after #3 | Trunk (cubic Bezier) + 3 branches; foliage = clusters of 5-7 overlapping circles per branch | Height 210 dp; foliage `#6FB38A` with lighter `#8FCBA2` highlights; tiny stone lantern decor optional |
| 5 | Cherry blossom | after #4 | Slender trunk, 5 branches, blossom clusters (5-petal flowers) | Blossom `#FFC4D6`, center `#F2A488`; at full bloom spawn falling petals: 6/s, drift `vx 10-30`, `vy 25-45`, rotation 0.5-2 rad/s, life 6 s |

**Growth drawing rules**
* Stem: cubic Bezier from the soil; visible length `L(g) = H * easeOutCubic(clamp(g / 0.6, 0, 1))`; thickness `lerp(4, 9, g)` dp, color gradient `#6FB38A -> #4E9070`.
* Leaves: node position `s_i = 0.16 * i`; leaf scale `clamp((g - s_i * 0.7) / 0.18, 0, 1)^0.7`; each leaf has a midrib line and two-tone fill; sways with its own phase.
* Buds/flowers: flower scale springs in with `bouncy` when `g` crosses 0.70 (bud) and 0.88 (bloom): `scale 0 -> 1.15 -> 1`.
* **Wind:** top displacement `A sin(w t - k s) * s^2`, `A = 4..9 dp` (species), `w = 1.4 rad/s`, `s` = normalized height. **Touch:** dragging near the plant adds an impulse to a tip spring (`k = 40, c = 4`) so it wiggles and settles.
* Stage-up event: soft glow ring (radius 0 -> 90 dp, alpha 0.35 -> 0, 700 ms), sound `water_drop` at rate 1.4 (pretty chime), haptic medium.
* **Full bloom:** `bloom` sound, music duck, petals/pollen burst (40 particles), haptic `bloom`, mark species complete, show the completion sheet after 2.4 s with "Next plant" if unlocked.

### 10.6 Audio and haptics

| Event | Sound |
| --- | --- |
| Pouring | `sprinkle_loop` looping, volume by flow `0.7 * (spawnRate / 90)`; fade 160 ms on stop |
| Droplet impact | `water_drop` (every ~10th), rate 0.9-1.3, volume 0.3 |
| Light mote | `water_drop` rate 1.5, volume 0.25 |
| Stage up | `water_drop` rate 1.4, volume 0.5 |
| Full bloom | `bloom` + duck |
| Ambient | `wind_chime_{0..3}` every `U(30, 70)` s at 0.4; music `garden` |

Haptics: `waterPulse` (soft) every 140 ms while pouring; light on mote catch; medium on stage up; `bloom` (success) on full bloom.

### 10.7 Persistence

`grow_plant`: `{unlocked: n, current: {species, g, m, l}, completed: [species...]}`. On resume: `m` and `l` restored, no offline change.

### 10.8 Tuning table (`GrowPlantTuning`)

| Key | Default | Range |
| --- | --- | --- |
| `growthRate` | 0.012 | 0.004-0.03 |
| `moistureDecay` | 0.012 | 0-0.04 |
| `lightDecay` | 0.02 | 0-0.06 |
| `restMoisture` | 0.25 | 0.1-0.5 |
| `waterRate` | 90 | 40-160 |
| `dropMoisture` | 0.0036 | 0.001-0.01 |
| `moteInterval` | 1.5-3.5 | |
| `moteLight` | 0.18 | 0.05-0.4 |
| `windAmp` | 6 | 0-12 |

### 10.9 Acceptance

* Each species is clearly different and pretty at every stage (look at PNG frames at `g = 0, 0.12, 0.3, 0.5, 0.7, 0.88, 1`).
* Pouring feels liquid: streaks arc under gravity, soil darkens smoothly.
* No stage ever looks broken (no leaf popping in at full size, no stem jumping).
* Growth cannot be "lost"; neglect only pauses it.

---

## 10b. Later games (not in the MVP; reuse the engine)

| Game | Reuses | Core idea |
| --- | --- | --- |
| Dust the Shelf | Window Wipe mask + cloth | Wipe dust off objects, revealing details |
| Wash the Car | Window Wipe + foam particles | Soap, scrub, rinse stages |
| Jigsaw | Spring + snap | Large soft pieces, magnetic snap within 18 dp |
| Coloring | Region fill | Tap regions, palette sheet |
| Lantern Float | Bubble Pop world | Tap to release lanterns that rise, ambient night scene |

---

## 11. Audio system

### 11.1 Engine and rules

* **One engine: `flutter_soloud`.** `SoLoud.instance.init()` at startup (after first frame), then preload every SFX with `loadAsset` into memory (total about 0.8 MB of OGG, small after decode except `rain_loop`). Verify method names against the installed version's README before coding; the cookbook shows `init`, `loadAsset`, `play` (returns a handle), `setVolume(handle, v)`, `setRelativePlaySpeed(handle, r)`, `fadeVolume(handle, v, duration)`, `stop(handle)`, `disposeSource(source)`, and `looping: true` for gapless loops.
* **Music:** load one track at a time (prefer `LoadMode.disk` if the installed version supports it for assets; a decoded 64 s stereo track is about 11 MB in memory). Dispose the previous track after the crossfade.
* **Gains (defaults):** master 0.8, music 0.5, effects 0.9. Final volume = `master * bus * eventVolume`. Persist in settings; apply live.
* **Loudness policy:** SFX peaks between -4 and -14 dBFS (set by the generator), music RMS about -22 dBFS with peaks under -3 dBFS. Nothing may clip when 3 sounds overlap; if testing shows harshness, lower the master default, not the files.
* **Voice management:** per-sound concurrency caps (pop 6, tube_complete 3, wipe_squeak 1, others 2). Beyond the cap, stop the oldest with a 30 ms fade. Enforce a minimum 35 ms between starts of the same SFX id.
* **Loops driven by input** (wipe, sand, pour, sprinkle): start at volume 0 on touch-down, call `setVolume` / `setRelativePlaySpeed` at most once per frame, fade out over 160 ms on release, stop and release the handle after the fade. Never leave a loop running when the game is paused or closed.
* **Lifecycle:** on `AppLifecycleState.inactive/paused` pause everything (`pauseAll`), on `resumed` resume only what was playing. On game exit fade all game sounds over 250 ms.
* **Interruptions** (calls, other audio focus): rely on the engine; verify on a real device that music resumes sensibly. If "Mix with other apps' audio" is on, do not request exclusive focus; if off, behave as a normal media player. Respect the iOS silent switch behavior of the engine defaults; document the result in `docs/DECISIONS.md`.
* **Failure tolerance:** if `init` fails, all calls become no-ops. The app must work silently.

### 11.2 Music director

* `playMusic(id, crossfade: 2500 ms)`: fade the old track to 0 while fading the new one to the music bus level (equal-power).
* Default track per game/scene (the `defaultMusic` in `GameMeta`; scene overrides in the Window Wipe table). Home screen: `dawn` at 60% of the music level.
* **Ducking:** `duckMusic(to: 0.4, down: 300 ms, up: 1200 ms)` for completion jingles.
* **Sleep timer** fades per section 5.8.
* Tracks: `dawn`, `dusk`, `moonlit`, `garden` (64 s, seamless loops, generated; Appendix A). Always `looping: true`.

### 11.3 Sound catalogue (all generated by `tools/gen_audio.py`)

| Id | File | Loop | Seconds | Used by | Character |
| --- | --- | --- | --- | --- | --- |
| `ui_tap` | `sfx/ui_tap.ogg` | no | 0.1 | buttons | soft wooden tick |
| `ui_back` | `sfx/ui_back.ogg` | no | 0.2 | back, invalid move | gentle falling glide |
| `ui_toggle_on` / `ui_toggle_off` | `sfx/ui_toggle_*.ogg` | no | 0.3 | settings | two-note up / down |
| `pop_small` / `pop_medium` / `pop_large` | `sfx/pop_*.ogg` | no | 0.2-0.3 | Bubble Pop | pitched bloop + click |
| `wipe_loop` | `sfx/wipe_loop.ogg` | yes | 3.2 | Window Wipe | band-passed cloth-on-glass noise |
| `wipe_squeak_1..3` | `sfx/wipe_squeak_*.ogg` | no | 0.1-0.2 | Window Wipe | tiny glass squeaks |
| `sand_loop` | `sfx/sand_loop.ogg` | yes | 3.2 | Sand Garden | soft granular hiss |
| `stone_place` | `sfx/stone_place.ogg` | no | 0.5 | Sand Garden | low soft thud |
| `pour_loop` | `sfx/pour_loop.ogg` | yes | 2.3 | Color Sort | liquid with glug bubbles |
| `select_tube` | `sfx/select_tube.ogg` | no | 0.3 | Color Sort | clear tick |
| `tube_complete_0..5` | `sfx/tube_complete_*.ogg` | no | 3.2 | Color Sort | pentatonic bell notes C D E G A C |
| `level_complete` | `sfx/level_complete.ogg` | no | 6.2 | Color Sort | rising bell arpeggio with reverb |
| `complete_soft` | `sfx/complete_soft.ogg` | no | 5.0 | Window Wipe | warm chord swell |
| `bloom` | `sfx/bloom.ogg` | no | 5.0 | Bubble Pop, Plant | shimmering rising bells |
| `water_drop` | `sfx/water_drop.ogg` | no | 0.2 | Plant, wand | tiny rising blip |
| `sprinkle_loop` | `sfx/sprinkle_loop.ogg` | yes | 2.1 | Plant | watering patter |
| `rain_loop` | `sfx/rain_loop.ogg` | yes | 22 | Rainy scene | steady rain + drops |
| `wind_chime_0..3` | `sfx/wind_chime_*.ogg` | no | 5.5 | Sand, Plant | distant soft chimes |
| `dawn`, `dusk`, `moonlit`, `garden` | `music/*.ogg` | yes | 64 | music | evolving pad loops |

`assets/audio/manifest.json` (written by the generator) lists every file; a unit test must assert that every `SoundId` has a file in the manifest and every manifest entry is referenced by some `SoundId`.

### 11.4 Quality bar and upgrade path

The generated set is designed to be **cohesive and calm** and to ship as-is. If, after living with it, a sound feels thin, upgrade that one sound with a licensed recording (section 13.3) **keeping the same id and loudness**; log it in the licence ledger.

---

## 12. Haptics system

### 12.1 Events

`HapticEvent` -> default pattern (iOS generator / Android primitive via `haptic_feedback`):

| Event | Type | Min interval | Used by |
| --- | --- | --- | --- |
| `uiTap` | `selection` | 40 ms | buttons, chips |
| `toggle` | `light` | 60 ms | switches |
| `sliderTick` | `selection` | 80 ms | sliders every 10% |
| `wipeTick` | `soft` | 45 ms | Window Wipe, per 18 dp of travel |
| `scrubResist` | `medium` | 120 ms | stubborn spot |
| `popSmall` | `light` | 45 ms | Bubble Pop |
| `popMedium` | `medium` | 45 ms | |
| `popLarge` | `heavy` | 60 ms | |
| `sandTick` | `soft` | 55 ms | Sand Garden, per 22 dp |
| `stonePlace` | `medium` | 200 ms | |
| `tubeSelect` | `selection` | 60 ms | Color Sort |
| `pourPulse` | `soft` | 110 ms | |
| `tubeComplete` | `medium` | 200 ms | |
| `levelComplete` | `success` | 500 ms | |
| `waterPulse` | `soft` | 140 ms | Plant |
| `moteCatch` | `light` | 100 ms | |
| `stageUp` | `medium` | 300 ms | |
| `bloom` | `success` | 500 ms | |
| `completeSoft` | `success` | 500 ms | completions |
| `invalid` | `light` | 150 ms | invalid move |

### 12.2 Rules

* **Global limiter:** at most one haptic per 24 ms; drop (never queue) anything faster. Never fire more than 25 haptics per second in total.
* **Intensity setting:** `Normal` = table as written. `Soft` = step every type down one level (`heavy -> medium -> light -> soft`, `success -> light`), double every min interval. `Off` = nothing.
* **Scale with motion:** continuous textures (`wipeTick`, `sandTick`) only above their speed thresholds, so a slow drag is quiet.
* **No haptic without matching sound/visual** in the same 50 ms (they must feel like one event).
* Never throw: wrap in try/catch; if `Haptics.canVibrate()` is false, become a no-op.

### 12.3 Backends

```dart
abstract class HapticBackend { Future<bool> get supported; Future<void> play(HapticType t); }
class PackageHapticBackend  // uses haptic_feedback: Haptics.vibrate(HapticsType.x)
class BuiltInHapticBackend  // Flutter HapticFeedback: lightImpact, mediumImpact, heavyImpact, selectionClick, vibrate
```
Mapping for the built-in backend: `soft/light -> lightImpact`, `medium/rigid -> mediumImpact`, `heavy -> heavyImpact`, `selection -> selectionClick`, `success/warning/error -> mediumImpact` (or `vibrate` on Android only). Choose the package backend when it is installed and supported, else the built-in one. On Android the package uses haptic primitives on API 30+, waveforms on API 26-29, timing-only below: expect softer fidelity on old devices; this is acceptable.

Continuous "rubbing" haptics are **simulated with throttled ticks** (no platform offers a free continuous texture API through these packages). Optional later upgrade: a small native Core Haptics (iOS) plugin; not part of the MVP.

---

## 13. Assets: what exists and how it is produced

### 13.1 Inventory

| Asset | Source | Size | Licence |
| --- | --- | --- | --- |
| All visuals (scenes, bubbles, plants, tubes, rake, stones, UI) | Painted in code (`CustomPainter`, shaders) | 0 bytes of art | Ours |
| SFX (31 files) + music (4 files) | `tools/gen_audio.py` (Appendix A) | about 4 MB total | Ours (generated) |
| App icon, adaptive icon, themed icon, splash logo | `tools/gen_icons.py` (Appendix B) | about 0.7 MB | Ours |
| Fonts: Nunito, Noto Sans Devanagari | `google/fonts` GitHub repo | about 1 MB | SIL OFL 1.1 (keep `OFL.txt` files and list in Credits) |
| Material icons | Flutter SDK (`Icons.*`) | 0 | Apache 2.0 (SDK) |

**Do this in Phase 0:** run both generators, commit the outputs, add the manifest test.

```bash
pip install numpy scipy pillow
python3 tools/gen_audio.py --out assets/audio     # about 35 s, needs ffmpeg for .ogg (else .wav; then set format to wav in SoundIds)
python3 tools/gen_icons.py --out assets/brand
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
If `ffmpeg` is missing and cannot be installed, run with `--wav` and use `.wav` extensions; size grows to about 60 MB, so fix that before release (install ffmpeg, rerun).

### 13.2 Procedural scene art (the "assets" you write)

* `ScenePainter` per scene (section 6.3): gradients, silhouettes, bokeh, particles; seeded `Rng`; pure Canvas.
* `DirtPainter` per dirt type (section 6.4).
* `BubbleSprites`, `StoneShape`, `PlantPainter`, `TubePainter`, `RakePainter`, `CanPainter`.
* Thumbnails on home cards reuse these painters at low resolution.
* Dedicated tool (optional): `tools/gen_scenes.dart` renders all scenes to PNG via a headless test for the store screenshots.

### 13.3 Optional upgrades (licensed audio only; research-backed)

Use only when a generated sound is not good enough. Prefer **CC0**. Record every file in `assets/LICENSES_ASSETS.md`.

| Source | Licence summary | Safe for this app? | Notes |
| --- | --- | --- | --- |
| Kenney.nl (e.g. "Interface Sounds", 100 OGG) | CC0, credit optional | **Yes** | Verified: [Interface Sounds on OpenGameArt](https://opengameart.org/content/interface-sounds). Best for UI clicks |
| Freesound, filter **CC0 only** | Per-file licence | **Yes if CC0** | Needs an account; reject CC-BY-NC and share-alike items; CC-BY needs a credit line (Credits screen exists) |
| OpenGameArt, CC0 items | Per-file licence | **Yes if CC0** | Reject GPL items for a closed app |
| Pixabay (sounds, music) | [Content License](https://pixabay.com/service/terms/): commercial use OK, no attribution, **no standalone redistribution** | Yes | Embedding in the app is intended use; **do not publish the raw files in a public repo**; avoid sounds that depict brands |
| Mixkit | Free licence, commercial OK, no attribution, no resale in original form | Probably | A game guide says it covers games; confirm on [mixkit.co/license](https://mixkit.co/license/) before using for a mobile app |
| Sonniss GDC bundles | Royalty-free; no standalone redistribution | Yes | Large professional libraries |
| Incompetech (Kevin MacLeod) | CC-BY 4.0 | Only with the exact credit line | Add to Credits screen |
| BBC Sound Effects, Jamendo free tier, Free Music Archive, CC-BY-NC items | Non-commercial or mixed | **No** | Do not use |

(Third-party guide used for the table: [Cinevva](https://app.cinevva.com/guides/free-sound-effects-music). Always read the licence text on the item you download.)

**Search queries for upgrades** (on Freesound/OpenGameArt, CC0 filter): "soft pop bubble", "water droplet single", "glass squeak finger", "sand rake granular", "stone place soft thud", "wooden tick ui", "gentle rain loop", "wind chime single soft", "water pour loop glass". Process: download, trim, normalize to the peak targets in `gen_audio.py` (`ffmpeg -af loudnorm` or the same dB), export OGG q4, keep the file name, update the ledger.

### 13.4 App icon and store graphics

* Icon: soap bubble on a peach to lavender to sky gradient (generated). No text in the icon.
* Store screenshots: generated by an `integration_test` that opens each game, scripts input, and calls `takeScreenshot`; add a caption band later if desired (Pillow). Required sets: phone 6.7" and 5.5", tablet 12.9" if tablets are supported.
* Feature graphic (Play): 1024x500 gradient + bubble art: copy `gen_icons.py` and render a wide canvas.

---

## 14. Persistence and data

### 14.1 Settings (`SharedPreferences` keys, prefix `s.`)

`masterVol` 0.8, `musicVol` 0.5, `sfxVol` 0.9, `soundOn` true, `mixWithOthers` false, `haptics` `normal`, `theme` `auto`, `reduceMotion` `system`, `colorblind` false, `leftHanded` false, `keepAwake` true, `fastPour` false, `onboarded` false, `reminderOn` false, `reminderTime` `20:00`, `locale` null, `seenHints` set of game ids.

### 14.2 Progress JSON (`progress.v1`)

```json
{
  "version": 1,
  "calmSeconds": 5400,
  "daysVisited": 6,
  "lastGame": "window_wipe",
  "windowWipe": {"completedScenes": ["rainy_evening"], "current": {"scene": "misty_morning", "grid": "<base64>", "spots": [[120, 300, 0.6]], "elapsed": 41}},
  "bubblePop": {"rounds": 3, "totalPopped": 412, "paletteIndex": 2, "poppedThisRound": 11},
  "sandGarden": {"hasImage": true, "stones": [{"x": 0.4, "y": 0.6, "size": 1, "rot": 0.3, "seed": 9, "moss": false}], "sandColor": "warm"},
  "colorSort": {"level": 14},
  "growPlant": {"unlocked": 2, "completed": ["sunny"], "current": {"species": "fern", "g": 0.42, "m": 0.5, "l": 0.3}}
}
```
* Write through a single `ProgressRepository` (debounced 1 s, and on pause). Include `version` and a migration function; unknown future versions load best-effort.
* "Calm minutes today" on home = `calmSeconds` delta since local midnight; there are **no streaks** and no loss messaging.
* Reset progress: confirm, wipe prefs keys and the garden files.

### 14.3 Cloud sync (Phase 5, optional)

Firestore `users/{uid}/progress` mirrors the JSON above. Local is the source of truth; merge rule: per game take the higher progress (`level`, `rounds`, `completedScenes` union, plant `g` max); last-write-wins for settings. Anonymous auth by default.

---

## 15. Accessibility, localisation, privacy, analytics

### 15.1 Accessibility

* Every interactive control has a `Semantics` label and >= 48 dp target; focus order logical.
* Honor text scale, bold text, and system Reduce Motion (section 3.4).
* **Screen-reader alternatives** (when `MediaQuery.accessibleNavigation`): Window Wipe shows a "Clean the window" button that runs a scripted wiping animation; Bubble Pop shows "Pop a bubble"; Sand Garden "Draw a pattern" (plays a scripted rake path) and "Place a stone"; Color Sort exposes each tube as a button with a label like "Tube 3, from bottom: coral, coral, blue" and announces moves; Grow a Plant shows "Water the plant" and "Collect light".
* No flashing: no element changes luminance more than 3 times per second; completion glows are single 1.2 s pulses.
* Color is never the only cue: Colorblind assist adds symbols (section 9.3).
* Haptic and sound are always optional; nothing is communicated only through them.

### 15.2 Localisation

`flutter gen-l10n` with `app_en.arb` and `app_hi.arb` (Hindi). **All user-visible strings** go through `AppLocalizations`; Appendix D lists the English strings (keep them short and gentle). Hindi: translate yourself carefully, flag in `docs/DECISIONS.md` that a native speaker should review. Use `Noto Sans Devanagari` as the fallback family. Never concatenate translated fragments; use ICU placeholders. Layout must tolerate 30% longer strings.

### 15.3 Privacy and compliance

* MVP collects nothing off-device. Phase 5 analytics are anonymous events only; show a consent screen where required (UMP flow with `google_mobile_ads`) and respect the choice; make analytics togglable in Settings.
* Provide a privacy policy URL (draft the text from the facts of the build; host on GitHub Pages; the human supplies the URL).
* Target audience: general (13+) unless the owner decides on a Families listing; the Families path restricts ads and analytics. Record the choice in `docs/DECISIONS.md`; default is **no ads and no analytics until the owner decides**.
* Open-source licenses page via `showLicensePage`; Credits screen lists fonts (OFL) and any CC-BY assets.

### 15.4 Analytics events (no-op by default)

`app_open`, `game_start {game}`, `game_complete {game, seconds}`, `game_exit {game, seconds}`, `scene_complete {scene}`, `round_complete {n}`, `level_complete {n}`, `plant_bloom {species}`, `setting_changed {key}`, `sleep_timer_start {minutes}`, `paywall_view`, `purchase_complete`. No user identifiers, no precise timestamps beyond the event time, no content of garden/art.

---

## 16. Testing and visual QA

### 16.1 Unit tests (must pass)

| Area | Tests |
| --- | --- |
| Engine | `SimLoop` step count under hitch; `Spring` converges, overshoot matches table within 10%; `PointerTracker` velocity EMA |
| Theme | Contrast ratios (section 3.1) |
| Window Wipe | Stamp accumulation: clean path of a straight swipe reaches `D <= 0.05` after the expected number of passes for each dirt `k`; grid <-> mask consistency; droplet merge conserves area (`r^2`); stick-slip never produces negative or NaN velocity |
| Bubble Pop | Spawner respects caps and clearance; capsule hit test; pop impulse symmetry; round counter |
| Sand Garden | Curvature culling decisions on a circle path; stone footprint skipping; undo stack limits and disposal |
| Color Sort | 200 levels generate and solve; legal-move rules; move transfers `n = min(run, free)`; undo exactness; color delta-E test; liquid area conservation (`|area - V| < 0.5%` at tilt 0, 30, 60, 80 degrees) |
| Grow Plant | Growth stays monotonic; rest rule; species painter produces no NaN for `g` in [0, 1] |
| Audio | Manifest vs `SoundId`; voice cap logic; fade scheduling with a fake clock |
| Haptics | Limiter (24 ms, 25/s), intensity downgrades, throttling per event |
| Persistence | Round trip, migration, corrupted JSON falls back to defaults |

### 16.2 Widget and flow tests

Onboarding -> first game within 2 taps; settings toggles persist and apply; home cards open the right game; completion sheet actions; back button saves state; Reduce Motion path builds.

### 16.3 Visual QA loop (how you "see" the app)

`flutter test` cannot judge feel, but you can **render frames to PNG and look at them**:

1. In `test/visual/`, write one test per game that builds the game widget at 390x844 (dpr 2), loads real fonts with `FontLoader`, runs the **Canvas fallback** path (shaders are not available in tests), pumps scripted pointer input (e.g. a zig-zag swipe over time using `TestGesture`), and captures PNGs via `RepaintBoundary.toImage` (or `matchesGoldenFile`) to `build/visual/<game>_<state>.png`.
2. States to capture: Window Wipe 0%, 40%, 90%, 100% for 2 scenes; Bubble Pop at t=3 s, mid-pop, bloom; Sand Garden after a spiral rake + 2 stones; Color Sort level 1, mid-pour (frame at 600 ms), win; Grow Plant `g` = 0, 0.3, 0.7, 1.0 for each species; Home, Settings, Completion sheet in all 3 themes.
3. **Open each PNG with the Read tool and critique it against the relevant section** (edges soft? colors match the tables? alignment, spacing, text legible? anything clipped?). Fix and re-render until it matches. Keep the final PNGs as goldens (`test/goldens/`), generated on one platform only (Linux CI) to avoid drift.
4. If a Flutter web build is possible in your environment, you may also run `flutter build web` and screenshot with Playwright for a second opinion (audio and haptics are stubbed on web).

### 16.4 Performance tests

`integration_test` with `IntegrationTestWidgetsFlutterBinding.traceAction` + `TimelineSummary`: scripted 30 s of continuous input per game on a **real device in profile mode**; fail the budget in section 4.7 (record `average_frame_build_time_millis`, `90th_percentile_frame_rasterizer_time_millis`, `missed_frame_build_budget_count`). If no device is available in your environment, write the test and note in `docs/PROGRESS.md` that it is pending a real-device run.

### 16.5 Manual QA matrix (human, at the end)

Low-end Android (3 GB RAM), mid Android 120 Hz, iPhone SE class, a recent iPhone, a tablet. Check: audio interruptions, silent switch, haptics feel on both OSes, Reduce Motion, text scale 1.6x, TalkBack/VoiceOver flows, rotating tablets, 30-minute soak (no memory growth).

---

## 17. Build phases and acceptance criteria

Work strictly in order. At the end of each phase: gates (`format`, `analyze`, `test`), visual QA PNGs reviewed, `docs/PROGRESS.md` updated, one commit.

**Phase 0: Foundation (target: app launches to an empty home with theme, audio and haptics wired)**
* Bootstrap (2.2), folder structure (4.1), tokens/themes (3), router, settings + persistence, `AudioService` (loads manifest), `HapticService`, `SimLoop`/`Spring`/`ParticlePool`/`PointerTracker`, tuning system, run both generators, commit assets, contrast + manifest tests.
* Accept: app runs on emulator; toggling settings plays sounds; theme switch works; all gates pass.

**Phase 1: Window Wipe (the quality benchmark; do not move on until it feels great)**
* Scenes (all 6 painters; premium locks wired to the fake entitlement), dirt baking, mask accumulator + CPU grid, cloth follower, Canvas fallback glass, droplets, spots, completion, audio + haptics, tuning panel, persistence, game shell + completion sheet.
* Then the shader upgrade (`window_glass.frag`) with fallback.
* Accept: section 6.15 + visual QA PNGs.

**Phase 2: Home, onboarding, shell polish**
* Splash, onboarding (first-run lands in Window Wipe), home with hero + grid (only Window Wipe live; others "coming soon" cards hidden), transitions, settings screen, credits, sleep timer.
* Accept: first launch to wiping in under 10 s; all transitions per 5.1.

**Phase 3: Bubble Pop + Sand Garden**
* Accept: sections 7.10 and 8.10.

**Phase 4: Color Sort + Grow a Plant + Collection**
* Accept: sections 9.13 and 10.9.

**Phase 5: Hardening and optional services**
* Accessibility alternatives (15.1), localisation (en, hi), performance tests and fixes, low-end fallbacks, error resilience. Optional (only if keys exist; otherwise implement behind interfaces with stubs): Firebase analytics/crashlytics/remote config, AdMob with consent, RevenueCat premium, daily reminder (`flutter_local_notifications`).
* Accept: budgets met; app fully usable with all services stubbed.

**Phase 6: Release prep**
* Store listing text (Appendix D), privacy policy draft, screenshots, signing config placeholders, `docs/RELEASE.md` with exact commands (`flutter build appbundle --release`, `flutter build ipa --release`), version/build numbers, final QA checklist.

---

## 18. Release checklist and the few human-only steps

### 18.1 You (Claude Code) can do all of this

Code, tests, asset generation, icons, screenshots, store text, privacy policy draft, release docs, CI workflow (GitHub Actions: analyze + test; optional Android build).

### 18.2 Only the owner can do these (keep this list short, give exact steps in `docs/RELEASE.md`)

1. Install Flutter + Android Studio (and Xcode on a Mac for iOS builds).
2. Create store accounts: Google Play Console (one-time fee) and Apple Developer Program (annual fee); check current prices.
3. Choose the real bundle/application id and create signing keys (steps provided in `docs/RELEASE.md`).
4. Optional: create Firebase, AdMob and RevenueCat projects and paste the keys into a local, git-ignored config file (`--dart-define-from-file=env.json`).
5. Host the privacy policy text at a public URL (GitHub Pages) and paste it into the store forms.
6. Test on real phones (feel, haptics, audio) and have a Hindi speaker review the translations.

### 18.3 Store listing facts to prepare

Short description (<= 80 chars): "Calm little games: wipe windows, pop bubbles, rake sand." Category: Games > Casual (Android), Games > Casual or Health & Fitness decision by owner. Age rating: everyone. Data safety: "no data collected" until Phase 5 services are enabled.

---

## Appendix A: `tools/gen_audio.py` (procedural audio generator, tested)

Save exactly as `tools/gen_audio.py`. Tested: runs in about 35 s, writes 31 SFX + 4 music loops (about 4 MB as OGG), no clipping, loops seamless (end-to-start jump below 1.1x the typical sample step), RMS-matched music. Deterministic (fixed seed). Tweak recipes freely; keep the ids and loop flags (they must match `SoundId` and the manifest test).

```python
#!/usr/bin/env python3
"""
Calm Corner - procedural audio generator (no downloads, no licences, no attribution).

Usage:
    pip install numpy scipy
    python3 tools/gen_audio.py --out assets/audio            # writes .ogg if ffmpeg exists, else .wav
    python3 tools/gen_audio.py --out assets/audio --wav      # force .wav
    python3 tools/gen_audio.py --out assets/audio --only pop # build only ids containing "pop"

Writes:  <out>/sfx/*.ogg   <out>/music/*.ogg   <out>/manifest.json
Everything is deterministic (fixed seed), so re-running gives identical files.
"""
import argparse, json, os, shutil, subprocess, wave
import numpy as np
from scipy import signal

SR = 44100
rng = np.random.default_rng(7)


# ----------------------------------------------------------------- helpers --
def tt(dur):
    return np.arange(int(dur * SR)) / SR


def expdecay(t, tau, attack=0.004):
    return (1 - np.exp(-t / attack)) * np.exp(-t / tau)


def sos_filter(x, kind, fc, order=2):
    sos = signal.butter(order, fc, btype=kind, fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lp(x, fc, order=2): return sos_filter(x, "lowpass", fc, order)
def hp(x, fc, order=2): return sos_filter(x, "highpass", fc, order)
def bp(x, lo, hi, order=2): return sos_filter(x, "bandpass", [lo, hi], order)


def white(n): return rng.standard_normal(n)


def pink(n):
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n)
    f[0] = f[1]
    x = np.fft.irfft(spec / np.sqrt(f), n)
    return x / np.max(np.abs(x))


def mtof(m): return 440.0 * 2 ** ((m - 69) / 12.0)


def normalize(x, peak_db=-3.0):
    p = np.max(np.abs(x)) + 1e-9
    return x * (10 ** (peak_db / 20) / p)


def normalize_rms(x, rms_db=-22.0, peak_cap_db=-3.0):
    """Level-match by loudness (RMS), then cap the peak so loud transients never clip."""
    r = np.sqrt(np.mean(x ** 2)) + 1e-9
    y = x * (10 ** (rms_db / 20) / r)
    cap = 10 ** (peak_cap_db / 20)
    p = np.max(np.abs(y))
    return y * (cap / p) if p > cap else y


def edge_fade(x, fin=0.002, fout=0.01):
    x = x.copy()
    a, b = int(fin * SR), int(fout * SR)
    if a: x[:a] *= np.linspace(0, 1, a)
    if b: x[-b:] *= np.linspace(1, 0, b)
    return x


def reverb(x, rt=1.6, wet=0.25, damp=5000):
    n = int(rt * SR)
    t = np.arange(n) / SR
    ir = lp(white(n), damp) * np.exp(-t * 6.9 / rt)
    ir /= np.sqrt(np.sum(ir ** 2))
    tail = signal.fftconvolve(x, ir)
    y = np.zeros(len(tail))
    y[:len(x)] += x * (1 - wet)
    y += tail * wet
    return y


def loopify(x, xf=0.3):
    """Make x loop seamlessly: fade the last xf seconds into the first xf seconds."""
    n = int(xf * SR)
    y = x[:-n].copy()
    fin = np.sin(np.linspace(0, np.pi / 2, n))
    y[:n] = y[:n] * fin + x[-n:] * np.cos(np.linspace(0, np.pi / 2, n))
    return y


def mix_at(buf, seg, start):
    end = min(len(buf), start + len(seg))
    if start < len(buf) and end > start:
        buf[start:end] += seg[:end - start]


def tone(f, dur, tau, attack=0.004, partials=((1, 1.0),)):
    t = tt(dur)
    y = sum(a * np.sin(2 * np.pi * f * k * t) for k, a in partials)
    return y * expdecay(t, tau, attack)


def bell(f, dur=1.8, tau=0.9):
    t = tt(dur)
    y = np.zeros_like(t)
    for i, (k, a) in enumerate(((1.0, 1.0), (2.0, 0.35), (2.76, 0.22), (5.4, 0.10))):
        y += a * np.sin(2 * np.pi * f * k * t) * np.exp(-t / (tau / (1 + 0.9 * i)))
    return y * (1 - np.exp(-t / 0.003))


def glide(f0, f1, dur, tau, attack=0.003):
    t = tt(dur)
    f = f0 * (f1 / f0) ** np.clip(t / dur, 0, 1)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * expdecay(t, tau, attack)


# ------------------------------------------------------------------- SFX ----
def sfx_ui_tap():
    return tone(560, 0.12, 0.03, partials=((1, 1), (2, 0.25))) + 0.15 * bp(white(int(0.12 * SR)), 2000, 6000) * expdecay(tt(0.12), 0.01)


def sfx_ui_back():
    return glide(520, 340, 0.16, 0.05)


def sfx_ui_on():
    y = np.zeros(int(0.3 * SR)); mix_at(y, tone(660, 0.15, 0.04), 0); mix_at(y, tone(880, 0.2, 0.05), int(0.07 * SR)); return y


def sfx_ui_off():
    y = np.zeros(int(0.3 * SR)); mix_at(y, tone(880, 0.15, 0.04), 0); mix_at(y, tone(660, 0.2, 0.05), int(0.07 * SR)); return y


def _pop(f0, f1, dur=0.22):
    n = int(dur * SR)
    click = bp(white(n), 1500, 6500) * expdecay(tt(dur), 0.006, 0.0005)
    return glide(f1, f0, dur, 0.035) + 0.5 * click


def sfx_pop_small(): return _pop(520, 1100)
def sfx_pop_medium(): return _pop(360, 800, 0.26)
def sfx_pop_large(): return _pop(230, 520, 0.32)


def sfx_wipe_loop():
    n = int(3.6 * SR); t = np.arange(n) / SR
    y = bp(pink(n), 900, 4200) * (1 + 0.15 * np.sin(2 * np.pi * 2.3 * t))
    return loopify(y, 0.4)


def _squeak(f0, f1):
    dur = 0.14; t = tt(dur)
    f = np.linspace(f0, f1, len(t)) * (1 + 0.012 * np.sin(2 * np.pi * 38 * t))
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.3 * np.sin(4 * np.pi * np.cumsum(f) / SR)
    return y * np.sin(np.pi * t / dur) ** 2 * 0.6


def sfx_wipe_squeak_1(): return _squeak(2100, 2650)
def sfx_wipe_squeak_2(): return _squeak(2500, 2250)
def sfx_wipe_squeak_3(): return _squeak(1900, 2400)


def sfx_sand_loop():
    n = int(3.6 * SR); t = np.arange(n) / SR
    y = lp(hp(white(n), 1800), 8000) * (1 + 0.25 * np.sin(2 * np.pi * 1.1 * t))
    return loopify(y, 0.4)


def sfx_stone_place():
    t = tt(0.5)
    body = glide(150, 62, 0.5, 0.12)
    thud = lp(white(len(t)), 600) * expdecay(t, 0.04, 0.001)
    return body + 0.5 * thud


def sfx_pour_loop():
    dur = 2.6; n = int(dur * SR)
    y = bp(pink(n), 400, 1800) * 0.35
    for _ in range(int(dur * 28)):
        f = rng.uniform(350, 1100)
        mix_at(y, glide(f, f * 1.25, 0.09, 0.025) * rng.uniform(0.15, 0.4), rng.integers(0, n - int(0.1 * SR)))
    return loopify(y, 0.3)


def sfx_select_tube(): return tone(740, 0.25, 0.05, partials=((1, 1), (2, 0.3)))


_PENTA = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]


def _bell_note(i): return reverb(bell(_PENTA[i], 2.0, 0.9), 1.2, 0.2)


def sfx_tube_complete_0(): return _bell_note(0)
def sfx_tube_complete_1(): return _bell_note(1)
def sfx_tube_complete_2(): return _bell_note(2)
def sfx_tube_complete_3(): return _bell_note(3)
def sfx_tube_complete_4(): return _bell_note(4)
def sfx_tube_complete_5(): return _bell_note(5)


def sfx_level_complete():
    y = np.zeros(int(4 * SR))
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5, 1318.5]):
        mix_at(y, bell(f, 2.2, 1.0) * 0.8, int(i * 0.16 * SR))
    return reverb(y, 2.2, 0.35)


def sfx_complete_soft():
    dur = 3.0; t = tt(dur)
    y = np.zeros_like(t)
    for f in (261.63, 329.63, 392.0, 493.88, 659.25):
        for det in (-0.003, 0.0, 0.003):
            y += np.sin(2 * np.pi * f * (1 + det) * t)
    env = (1 - np.exp(-t / 0.6)) * np.exp(-np.maximum(t - 0.8, 0) / 1.1)
    return reverb(y * env, 2.0, 0.35)


def sfx_bloom():
    y = np.zeros(int(3 * SR))
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
        mix_at(y, bell(f, 2.4, 1.1) * 0.7, int(i * 0.09 * SR))
    t = tt(1.4)
    y[:len(t)] += 0.05 * np.sin(2 * np.pi * np.cumsum(np.linspace(1500, 4200, len(t))) / SR) * np.sin(np.pi * t / 1.4)
    return reverb(y, 2.0, 0.3)


def sfx_water_drop(): return glide(600, 1300, 0.2, 0.03)


def sfx_sprinkle_loop():
    n = int(2.4 * SR)
    patter = np.abs(lp(white(n), 18, 1)); patter /= patter.max()
    y = lp(hp(white(n), 3500), 9000) * (0.35 + 0.65 * patter)
    return loopify(y, 0.3)


def sfx_rain_loop():
    dur = 24; n = int(dur * SR)
    y = hp(lp(pink(n), 5000), 400) * 0.6
    for _ in range(int(dur * 40)):
        burst = bp(white(int(0.004 * SR)), 2000, 6500) * rng.uniform(0.1, 0.5)
        mix_at(y, burst, rng.integers(0, n - 300))
    return loopify(y, 2.0)


def _chime(i):
    f = [783.99, 880.0, 987.77, 1174.66][i]
    return reverb(bell(f, 3.5, 2.2) * 0.6, 2.0, 0.35)


def sfx_wind_chime_0(): return _chime(0)
def sfx_wind_chime_1(): return _chime(1)
def sfx_wind_chime_2(): return _chime(2)
def sfx_wind_chime_3(): return _chime(3)


SFX = {  # id: (function, loop?, peak dBFS)
    "ui_tap": (sfx_ui_tap, False, -6), "ui_back": (sfx_ui_back, False, -7),
    "ui_toggle_on": (sfx_ui_on, False, -7), "ui_toggle_off": (sfx_ui_off, False, -7),
    "pop_small": (sfx_pop_small, False, -4), "pop_medium": (sfx_pop_medium, False, -4),
    "pop_large": (sfx_pop_large, False, -4),
    "wipe_loop": (sfx_wipe_loop, True, -8), "wipe_squeak_1": (sfx_wipe_squeak_1, False, -10),
    "wipe_squeak_2": (sfx_wipe_squeak_2, False, -10), "wipe_squeak_3": (sfx_wipe_squeak_3, False, -10),
    "sand_loop": (sfx_sand_loop, True, -9), "stone_place": (sfx_stone_place, False, -4),
    "pour_loop": (sfx_pour_loop, True, -8), "select_tube": (sfx_select_tube, False, -7),
    "tube_complete_0": (sfx_tube_complete_0, False, -6), "tube_complete_1": (sfx_tube_complete_1, False, -6),
    "tube_complete_2": (sfx_tube_complete_2, False, -6), "tube_complete_3": (sfx_tube_complete_3, False, -6),
    "tube_complete_4": (sfx_tube_complete_4, False, -6), "tube_complete_5": (sfx_tube_complete_5, False, -6),
    "level_complete": (sfx_level_complete, False, -4), "complete_soft": (sfx_complete_soft, False, -5),
    "bloom": (sfx_bloom, False, -5), "water_drop": (sfx_water_drop, False, -8),
    "sprinkle_loop": (sfx_sprinkle_loop, True, -10), "rain_loop": (sfx_rain_loop, True, -12),
    "wind_chime_0": (sfx_wind_chime_0, False, -14), "wind_chime_1": (sfx_wind_chime_1, False, -14),
    "wind_chime_2": (sfx_wind_chime_2, False, -14), "wind_chime_3": (sfx_wind_chime_3, False, -14),
}


# ----------------------------------------------------------------- music ----
def _pad_voice(freq, n, pan_seed, nharm=3):
    t = np.arange(n) / SR
    L = np.zeros(n); R = np.zeros(n)
    for det_c in (-5, 0, 5):                       # detune in cents, spread over the stereo field
        f = freq * 2 ** (det_c / 1200)
        ph = rng.uniform(0, 2 * np.pi)
        v = np.sin(2 * np.pi * f * t + ph) + 0.28 * np.sin(4 * np.pi * f * t + ph) + 0.08 * np.sin(6 * np.pi * f * t)
        v *= 0.8 + 0.2 * np.sin(2 * np.pi * rng.uniform(0.05, 0.12) * t + rng.uniform(0, 6.28))   # slow breathing
        pan = np.clip(0.5 + det_c / 12 + 0.15 * np.sin(pan_seed), 0, 1)
        L += v * np.cos(pan * np.pi / 2); R += v * np.sin(pan * np.pi / 2)
    return L, R


def _add_circular(buf, seg, start):
    n = buf.shape[-1]; start %= n; k = min(len(seg), n - start)
    buf[..., start:start + k] += seg[..., :k]
    if k < len(seg): buf[..., :len(seg) - k] += seg[..., k:]


def make_pad_track(chords, bright, chime_every, sparkle_notes, chord_len=16.0, xf=5.0, sub=False):
    N = int(len(chords) * chord_len * SR)
    buf = np.zeros((2, N))
    for ci, chord in enumerate(chords):
        n = int((chord_len + 2 * xf) * SR)
        seg = np.zeros((2, n))
        for vi, m in enumerate(chord):
            L, R = _pad_voice(mtof(m), n, vi + ci)
            seg[0] += L; seg[1] += R
        w = np.ones(n); k = int(xf * SR)
        w[:k] = np.sin(np.linspace(0, np.pi / 2, k)) ** 2
        w[-k:] = np.cos(np.linspace(0, np.pi / 2, k)) ** 2
        _add_circular(buf, seg * w * 0.12, int((ci * chord_len - xf) * SR))
    if sub:
        t = np.arange(N) / SR
        drone = np.sin(2 * np.pi * mtof(chords[0][0] - 12) * t) * (0.6 + 0.4 * np.sin(2 * np.pi * (1 / (len(chords) * chord_len)) * t))
        buf += 0.008 * drone
    air = bp(white(N), 2500, 6500) * 0.012 * (0.5 + 0.5 * np.sin(2 * np.pi * np.arange(N) / SR / 23.0))
    buf[0] += air; buf[1] += np.roll(air, 4000)
    for _ in range(int(N / SR / chime_every)):                         # sparse, soft pentatonic sparkles
        f = mtof(rng.choice(sparkle_notes))
        s = bell(f, 4.0, 1.6) * rng.uniform(0.03, 0.07)
        pan = rng.uniform(0.2, 0.8)
        seg = np.stack([s * np.cos(pan * np.pi / 2), s * np.sin(pan * np.pi / 2)])
        _add_circular(buf, seg, int(rng.integers(0, N)))
    tiled = np.concatenate([buf, buf, buf], axis=1)                    # circular filtering + reverb
    out = []
    for ch in range(2):
        y = lp(tiled[ch], bright, 2)
        y = reverb(y, 2.6, 0.45, 4500)[:len(tiled[ch])]
        out.append(y[N:2 * N])
    return normalize_rms(np.stack(out), -22.0, -3.0)


MUSIC = {
    "dawn":    dict(chords=[[48, 52, 55, 59, 62], [45, 52, 55, 59, 60], [41, 48, 52, 55, 57], [43, 50, 52, 57, 59]],
                    bright=2400, chime_every=9, sparkle_notes=[72, 74, 76, 79, 81, 84]),
    "dusk":    dict(chords=[[50, 53, 57, 60, 64], [46, 53, 57, 62, 64], [41, 48, 52, 57, 60], [48, 55, 57, 62]],
                    bright=1500, chime_every=14, sparkle_notes=[69, 72, 74, 77, 79]),
    "moonlit": dict(chords=[[45, 52, 59, 62], [41, 48, 55, 60], [48, 55, 59, 64], [40, 47, 55, 59]],
                    bright=900, chime_every=30, sparkle_notes=[69, 72, 76], sub=True),
    "garden":  dict(chords=[[50, 54, 57, 61, 64], [47, 54, 57, 62, 66], [43, 50, 54, 59, 62], [45, 52, 55, 57, 62]],
                    bright=2800, chime_every=6, sparkle_notes=[74, 76, 78, 81, 83, 86]),
}


# ----------------------------------------------------------------- output ---
def write_wav(path, x):
    x = np.atleast_2d(x)
    pcm = (np.clip(x.T, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(x.shape[0]); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())


def emit(x, base, force_wav, quality):
    wav = base + ".wav"
    write_wav(wav, x)
    if not force_wav and shutil.which("ffmpeg"):
        r = subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", str(quality), base + ".ogg"])
        if r.returncode == 0:
            os.remove(wav); return base + ".ogg"
    return wav


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="assets/audio")
    ap.add_argument("--wav", action="store_true")
    ap.add_argument("--only", default="")
    a = ap.parse_args()
    os.makedirs(os.path.join(a.out, "sfx"), exist_ok=True)
    os.makedirs(os.path.join(a.out, "music"), exist_ok=True)
    manifest = []
    for sid, (fn, loop, peak) in SFX.items():
        if a.only and a.only not in sid: continue
        x = normalize(fn(), peak)
        x = x if loop else edge_fade(x)
        p = emit(x, os.path.join(a.out, "sfx", sid), a.wav, 4)
        manifest.append(dict(id=sid, kind="sfx", file=os.path.relpath(p, a.out), loop=loop, seconds=round(len(x) / SR, 2)))
        print("sfx  ", sid)
    for mid, cfg in MUSIC.items():
        if a.only and a.only not in mid: continue
        x = make_pad_track(**cfg)
        p = emit(x, os.path.join(a.out, "music", mid), a.wav, 4)
        manifest.append(dict(id=mid, kind="music", file=os.path.relpath(p, a.out), loop=True, seconds=round(x.shape[1] / SR, 2)))
        print("music", mid)
    mpath = os.path.join(a.out, "manifest.json")
    if os.path.exists(mpath):                      # --only runs merge into the existing manifest
        old = {e["id"]: e for e in json.load(open(mpath))}
        old.update({e["id"]: e for e in manifest})
        manifest = list(old.values())
    with open(mpath, "w") as f:
        json.dump(manifest, f, indent=2)
    print("done:", len(manifest), "files")


if __name__ == "__main__":
    main()
```

---

## Appendix B: `tools/gen_icons.py` (procedural icon and splash generator, tested)

Save exactly as `tools/gen_icons.py`. Produces the iOS icon, Android adaptive foreground/background, themed monochrome icon and the splash logo.

```python
#!/usr/bin/env python3
"""
Calm Corner - procedural app icon + splash generator (no stock art needed).

Usage:
    pip install pillow numpy
    python3 tools/gen_icons.py --out assets/brand

Writes (all PNG):
    icon_1024.png        opaque square, for iOS / store listing (iOS rounds the corners itself)
    icon_bg_1024.png     Android adaptive icon background (gradient)
    icon_fg_1024.png     Android adaptive icon foreground (bubble inside the 66% safe zone, transparent)
    icon_mono_1024.png   Android 13 themed icon (single colour silhouette, transparent)
    splash_logo_1152.png bubble on transparent, for flutter_native_splash
    preview.png          the above on one sheet, for a quick look
"""
import argparse, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 2048  # work size; downsampled for crisp edges


def lerp(a, b, t): return a + (b - a) * t


def gradient_bg(size):
    stops = [(0.0, (255, 221, 196)), (0.55, (214, 190, 245)), (1.0, (150, 190, 235))]   # peach -> lavender -> sky
    y = np.linspace(0, 1, size)[:, None]
    img = np.zeros((size, size, 3))
    for (p0, c0), (p1, c1) in zip(stops[:-1], stops[1:]):
        m = (y >= p0) & (y <= p1)
        t = np.clip((y - p0) / (p1 - p0), 0, 1)
        for ch in range(3):
            img[..., ch] = np.where(m, lerp(c0[ch], c1[ch], t), img[..., ch])
    x = np.linspace(-1, 1, size)[None, :]
    img *= (1 - 0.06 * x ** 2)[..., None]                                             # faint vignette
    return Image.fromarray(img.clip(0, 255).astype("uint8"), "RGB")


def bubble(size, scale=1.0, mono=False):
    """Soap bubble: translucent body, iridescent rim, two highlights, soft shadow. RGBA."""
    cx, cy, r = size * 0.5, size * 0.5, size * 0.30 * scale
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    d = np.hypot(xx - cx, yy - cy) / r
    inside = d <= 1.0
    out = np.zeros((size, size, 4), np.float32)
    if mono:
        ring = (d > 0.86) & inside
        out[ring] = (0, 0, 0, 255)
        hl = np.hypot(xx - (cx - r * 0.38), yy - (cy - r * 0.42)) / (r * 0.16) <= 1
        out[hl & inside] = (0, 0, 0, 255)
        return Image.fromarray(out.astype("uint8"), "RGBA")
    rim = np.clip((d - 0.62) / 0.38, 0, 1) ** 2
    ang = np.arctan2(yy - cy, xx - cx)
    hue = 0.5 + 0.5 * np.sin(ang * 2 + 0.8)
    pink, cyan, white = np.array([255, 170, 210]), np.array([150, 225, 255]), np.array([255, 255, 255])
    tint = pink[None, None] * hue[..., None] + cyan[None, None] * (1 - hue[..., None])
    col = white[None, None] * (1 - 0.55 * rim[..., None]) + tint * (0.55 * rim[..., None])
    alpha = (0.14 + 0.62 * rim) * 255
    edge = np.clip((1.0 - d) * r / 2.0, 0, 1)                                         # anti-aliased edge
    out[..., :3] = col
    out[..., 3] = np.where(inside, alpha * edge, 0)
    img = Image.fromarray(out.astype("uint8"), "RGBA")
    hl = Image.new("RGBA", (size, size), (255, 255, 255, 0))   # white-transparent: blur must not darken edges
    d1 = ImageDraw.Draw(hl)
    d1.ellipse([cx - r * 0.60, cy - r * 0.66, cx - r * 0.12, cy - r * 0.30], fill=(255, 255, 255, 235))
    d1.ellipse([cx + r * 0.30, cy + r * 0.42, cx + r * 0.56, cy + r * 0.62], fill=(255, 255, 255, 120))
    hl = hl.filter(ImageFilter.GaussianBlur(size * 0.006))
    return Image.alpha_composite(img, hl)


def shadow(size, scale=1.0):
    sh = Image.new("RGBA", (size, size), (90, 70, 150, 0))
    r = size * 0.30 * scale
    ImageDraw.Draw(sh).ellipse([size * 0.5 - r * 0.8, size * 0.5 + r * 1.12, size * 0.5 + r * 0.8, size * 0.5 + r * 1.26], fill=(90, 70, 150, 70))
    return sh.filter(ImageFilter.GaussianBlur(size * 0.012))


def save(img, path, px):
    img.resize((px, px), Image.LANCZOS).save(path)


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--out", default="assets/brand"); a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    bg = gradient_bg(S).convert("RGBA")
    icon = Image.alpha_composite(Image.alpha_composite(bg, shadow(S)), bubble(S)).convert("RGB")
    save(icon, f"{a.out}/icon_1024.png", 1024)
    save(bg.convert("RGB"), f"{a.out}/icon_bg_1024.png", 1024)
    fg = Image.alpha_composite(shadow(S, 0.66), bubble(S, 0.66))                      # inside the 66% adaptive safe zone
    save(fg, f"{a.out}/icon_fg_1024.png", 1024)
    save(bubble(S, 0.66, mono=True), f"{a.out}/icon_mono_1024.png", 1024)
    save(Image.alpha_composite(shadow(S, 0.62), bubble(S, 0.62)), f"{a.out}/splash_logo_1152.png", 1152)
    sheet = Image.new("RGB", (4 * 360, 360), (245, 245, 245))
    for i, name in enumerate(["icon_1024", "icon_bg_1024", "icon_fg_1024", "icon_mono_1024"]):
        im = Image.open(f"{a.out}/{name}.png").convert("RGBA").resize((340, 340))
        base = Image.new("RGBA", (340, 340), (230, 230, 230, 255)); base.alpha_composite(im)
        sheet.paste(base.convert("RGB"), (i * 360 + 10, 10))
    sheet.save(f"{a.out}/preview.png")
    print("wrote icons to", a.out)


if __name__ == "__main__":
    main()
```


---

## Appendix C: Shaders (Flutter fragment programs)

Declare both in `pubspec.yaml` under `flutter: shaders:` (section 2.3). Constraints that apply (from the Flutter docs): only `sampler2D` samplers, two-argument `texture(sampler, uv)`, no UBO/SSBO, output is premultiplied alpha (ours is opaque), use `FlutterFragCoord()` not `gl_FragCoord`. Uniform float indices are counted in declaration order and do **not** include samplers; samplers are indexed separately from 0.

Load once at startup: `final program = await FragmentProgram.fromAsset('shaders/window_glass.frag');` and reuse `program.fragmentShader()` objects across frames (do not create one per frame). Guard every shader use with try/catch and fall back to the Canvas path on any error. Never use `ImageFilter.shader` unless Impeller is confirmed.

### C.1 `shaders/window_glass.frag`

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;          // float slots 0,1: size in logical px of the drawn rect
uniform sampler2D uSharp;    // sampler 0: the scene
uniform sampler2D uDirty;    // sampler 1: blurred scene with the dirt baked in (opaque)
uniform sampler2D uMask;     // sampler 2: clean amount in R (1 = clean)

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec3 sharp = texture(uSharp, uv).rgb;
  vec3 dirty = texture(uDirty, uv).rgb;
  float clean = texture(uMask, uv).r;

  float cover = smoothstep(0.0, 0.85, 1.0 - clean);      // dirt remaining
  vec3 col = mix(sharp, dirty, cover);

  // faint bright wet rim where the cloth just passed
  float rim = smoothstep(0.35, 0.5, clean) * (1.0 - smoothstep(0.5, 0.65, clean));
  col += rim * 0.05;

  fragColor = vec4(col, 1.0);
}
```

Dart usage:

```dart
final s = program.fragmentShader()
  ..setFloat(0, size.width)..setFloat(1, size.height)
  ..setImageSampler(0, sharp)..setImageSampler(1, dirty)..setImageSampler(2, maskImage);
canvas.drawRect(Offset.zero & size, Paint()..shader = s);
```

### C.2 `shaders/sand_light.frag`

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;        // float slots 0,1: drawn size in logical px
uniform vec2 uTexel;       // float slots 2,3: 1 / height-texture size
uniform vec3 uSand;        // float slots 4,5,6: base sand color (0..1)
uniform float uStrength;   // float slot 7: relief strength (default 6.0)
uniform sampler2D uHeight; // sampler 0: height in R (0.5 flat)

out vec4 fragColor;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;

  float hl = texture(uHeight, uv - vec2(uTexel.x, 0.0)).r;
  float hr = texture(uHeight, uv + vec2(uTexel.x, 0.0)).r;
  float hd = texture(uHeight, uv - vec2(0.0, uTexel.y)).r;   // y grows downward in uv
  float hu = texture(uHeight, uv + vec2(0.0, uTexel.y)).r;

  vec3 n = normalize(vec3((hl - hr) * uStrength, (hd - hu) * uStrength, 1.0));
  vec3 L = normalize(vec3(-0.55, -0.65, 0.52));              // light from the upper left
  float lit = dot(n, L) / L.z;                                // 1.0 on flat sand

  vec3 col = uSand * clamp(0.55 + 0.45 * lit, 0.35, 1.35);

  float g = hash(floor(frag));                                // fine static grain
  col *= 0.96 + 0.08 * g;
  col += step(0.997, hash(floor(frag) + 7.3)) * 0.05;         // rare glints

  fragColor = vec4(col, 1.0);
}
```

Dart usage:

```dart
final s = program.fragmentShader()
  ..setFloat(0, w)..setFloat(1, h)
  ..setFloat(2, 1 / heightImage.width)..setFloat(3, 1 / heightImage.height)
  ..setFloat(4, sand.r)..setFloat(5, sand.g)..setFloat(6, sand.b)   // Color.r/g/b are 0..1 floats in current Flutter
  ..setFloat(7, 6.0)
  ..setImageSampler(0, heightImage);
```

If the installed Flutter exposes `UniformFloatSlot` (`shader.getUniformFloat('uStrength')`), prefer it: it is name-based and safer than indices.

---

## Appendix D: Copy deck (English; keep it gentle and short)

**Greetings (by local hour):** 05-11 "Good morning" / 12-16 "Good afternoon" / 17-20 "Good evening" / 21-04 "Take it slow tonight"

**Home:** "Continue", "Wind down", "Calm Plus", "{n} calm minutes today"

**Game names and taglines**

| Game | Tagline |
| --- | --- |
| Window Wipe | Clear the glass, bring the world back |
| Bubble Pop | Soft little pops |
| Sand Garden | Rake, place, breathe |
| Color Sort | Pour until each tube is one color |
| Grow a Plant | Water it, catch the light |

**First-time hints (4 s, once per game):** Window Wipe "Drag to wipe the glass" / Bubble Pop "Touch a bubble. Hold to blow more" / Sand Garden "Drag to rake. Drop a stone" / Color Sort "Tap a tube, then another" / Grow a Plant "Drag the can over the pot"

**Onboarding:** 1 "A little pocket of calm" / "Short, gentle games for whenever you need a breath." 2 "No scores. No timers. No rush." / "Nothing to win or lose. Just something nice to do with your hands." 3 "Make it yours" / "Sound and touch can be changed any time." [Begin]

**Completion lines (rotate; never repeat twice in a row):** "Clear as morning." / "Nicely done. Take a breath." / "That felt good." / "All settled." / "Soft and still." / "Lovely." / "Calm, collected." / "Ahh. There it is." / "Well tended." / "Peace, delivered."

**Completion sheet:** "Again", "Next scene" / "Next level" / "Next plant", "Home", "{m} min {s} s of calm"

**Sleep timer:** title "Wind down", options "10 min / 20 min / 30 min / 45 min", end line "Good night."

**Settings labels:** Sound, Master, Music, Effects, Mix with other apps' audio, Haptics (Off / Soft / Normal), Look, Theme (Auto / Dawn / Dusk / Moonlit), Reduce motion (System / On / Off), Colorblind assist, Left-handed layout, Keep screen awake, Fast pour, Daily reminder, Privacy policy, Open-source licenses, Credits, Reset all progress ("This clears your progress and your sand garden. It cannot be undone.")

**Premium sheet:** title "Calm Plus", bullets "Three more window scenes", "More bubble skies and a night palette", "Moon sand and more plants", "Extra music", "No ads", buttons "Unlock", "Restore purchases", "Not now"

**Reminder notification (opt-in):** "A quiet minute is waiting." (never more than one per day; never guilt-based)

**Store text (draft)**
* Title: Calm Corner: Relaxing Games
* Short: Calm little games: wipe windows, pop bubbles, rake sand.
* Long: "Calm Corner is a pocket of small, satisfying things to do when you need a breath. Wipe a foggy window and watch the world come back. Pop soft bubbles. Rake a sand garden and place stones. Pour colors until every tube is one. Water a plant and watch it bloom. No scores, no timers, no losing: just gentle touch, soft sound and a little calm. Works offline."

**Privacy policy skeleton (fill from the final build):** what is collected (none in the MVP; anonymous analytics if enabled), on-device storage (settings, progress, garden image), third parties (ads/analytics/purchases only if enabled, with links), children (target audience statement), data deletion (reset in Settings, uninstall), contact (owner's email, to be supplied).

---

## Appendix E: Asset licence ledger (`assets/LICENSES_ASSETS.md`)

```markdown
# Asset licences

Everything below is either generated by this project (no third-party rights) or listed with its licence.

| File / group | Origin | Licence | Attribution required? | Link | Added |
| --- | --- | --- | --- | --- | --- |
| assets/audio/sfx/*, assets/audio/music/* | tools/gen_audio.py | Project-owned (generated) | No | n/a | 2026-10-26 |
| assets/brand/* | tools/gen_icons.py | Project-owned (generated) | No | n/a | 2026-10-26 |
| assets/fonts/Nunito-Variable.ttf | google/fonts (ofl/nunito) | SIL OFL 1.1 | Keep licence file; list in Credits | https://github.com/google/fonts | |
| assets/fonts/NotoSansDevanagari-Variable.ttf | google/fonts | SIL OFL 1.1 | Keep licence file; list in Credits | https://github.com/google/fonts | |
```
Rules: nothing is added to `assets/` without a row here; CC-BY items also appear on the Credits screen with the creator's required line; never use non-commercial or share-alike items.

---

## Appendix F: Sources used for the verified facts

* flame: https://pub.dev/documentation/flame/latest/
* Rive Flutter runtime: https://rive.app/docs/runtimes/flutter/flutter
* flutter_soloud cookbook: https://docs.flutter.dev/cookbook/audio/soloud
* haptic_feedback 0.6.5: https://pub.dev/documentation/haptic_feedback/0.6.5/
* Flutter fragment shaders: https://docs.flutter.dev/ui/design/graphics/fragment-shaders
* Pixabay Content License: https://pixabay.com/service/terms/
* Kenney Interface Sounds (CC0): https://opengameart.org/content/interface-sounds
* Mixkit licence info: https://mixkit.co/llm-info/
* Free game audio sources overview (third party): https://app.cinevva.com/guides/free-sound-effects-music

*End of specification.*
