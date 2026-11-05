// On-device smoothness + haptics check.
//
// Run on a real phone in profile mode (see docs/RELEASE.md section 8):
//   flutter drive --profile --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_test.dart -d <device>
//
// For each scene it plays the game with scripted touches, records frame
// build/raster times (FrameTiming) and counts which haptic events fired.
// Results are written to build/perf/perf_report.json by the driver.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:calmcorner/app/app.dart';
import 'package:calmcorner/core/analytics/analytics_service.dart';
import 'package:calmcorner/core/audio/audio_service_impl.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/core/haptics/haptic_service_impl.dart';
import 'package:calmcorner/core/monetization/ads_service.dart';
import 'package:calmcorner/core/monetization/purchase_service.dart';
import 'package:calmcorner/core/persistence/prefs_store.dart';
import 'package:calmcorner/core/providers.dart';
import 'package:calmcorner/features/games/clear_window/module.dart';
import 'package:calmcorner/features/games/garden_streams/module.dart';
import 'package:calmcorner/features/games/still_waters/module.dart';
import 'package:calmcorner/features/levels/level_game.dart';

/// Forwards to the real haptics (so you can feel them) and counts events.
class RecordingHaptics implements HapticService {
  RecordingHaptics(this.inner);
  final HapticService inner;
  final Map<String, int> counts = {};
  @override
  Future<void> init() => inner.init();
  @override
  void applySettings(HapticSettings s) => inner.applySettings(s);
  @override
  void fire(HapticEvent e) {
    counts[e.name] = (counts[e.name] ?? 0) + 1;
    inner.fire(e);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('perf + haptics sweep across the three games', (tester) async {
    final prefs = await PrefsStore.create();
    await prefs.setBool('onboarding.done', true);
    final audio = SoloudAudioService();
    final haptics = RecordingHaptics(HapticServiceImpl());
    final purchases = FakePurchases();
    LevelGames.register(StillWatersModule());
    LevelGames.register(GardenStreamsModule());
    LevelGames.register(ClearWindowModule());
    Future<void> boot() async {
      await audio.init();
      await haptics.init();
      haptics.applySettings(const HapticSettings(level: HapticLevel.normal));
      await purchases.init();
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsStoreProvider.overrideWithValue(prefs),
          audioServiceProvider.overrideWithValue(audio),
          hapticServiceProvider.overrideWithValue(haptics),
          analyticsProvider.overrideWithValue(NoopAnalytics()),
          adsProvider.overrideWithValue(NoopAds()),
          purchaseProvider.overrideWithValue(purchases),
          bootProvider.overrideWithValue(boot()),
          entitlementProvider.overrideWith((ref) => purchases.entitlement),
        ],
        child: const CalmCornerApp(),
      ),
    );
    await _settle(tester, const Duration(seconds: 5));

    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    Offset at(double fx, double fy) => Offset(size.width * fx, size.height * fy);

    Future<void> go(String route) async {
      final ctx = tester.element(find.byType(Navigator).first);
      GoRouter.of(ctx).go(route);
      await _settle(tester, const Duration(seconds: 2));
    }

    final report = <String, dynamic>{};
    Future<void> scene(String name, Future<void> Function() body) async {
      final before = Map<String, int>.from(haptics.counts);
      // Collect engine frame timings directly (watchPerformance needs a VM
      // service connection that real devices refuse).
      final timings = <FrameTiming>[];
      void onTimings(List<FrameTiming> t) => timings.addAll(t);
      SchedulerBinding.instance.addTimingsCallback(onTimings);
      await body();
      await _settle(tester, const Duration(milliseconds: 600));
      SchedulerBinding.instance.removeTimingsCallback(onTimings);
      report['frames_$name'] = _summarise(timings);
      final delta = <String, int>{
        for (final e in haptics.counts.entries)
          if (e.value - (before[e.key] ?? 0) > 0) e.key: e.value - (before[e.key] ?? 0),
      };
      report['haptics_$name'] = delta;
    }

    // Home: scroll the game cards.
    await go('/home');
    await scene('home_scroll', () async {
      for (var i = 0; i < 3; i++) {
        await _drag(tester, at(0.5, 0.75), at(0.5, 0.3), steps: 30);
        await _drag(tester, at(0.5, 0.3), at(0.5, 0.75), steps: 30);
      }
    });

    // Still Waters: tap tubes across both rows (selects + pours).
    await go('/play/still_waters/18');
    await scene('still_waters', () async {
      final xs = [0.2, 0.4, 0.6, 0.8];
      for (var r = 0; r < 3; r++) {
        for (final y in [0.3, 0.55]) {
          for (final x in xs) {
            await _tap(tester, at(x, y));
          }
        }
      }
    });

    // Garden Streams: rotate stones over the board.
    await go('/play/garden_streams/28');
    await scene('garden_streams', () async {
      for (var y = 0.25; y <= 0.7; y += 0.08) {
        for (var x = 0.15; x <= 0.85; x += 0.14) {
          await _tap(tester, at(x, y));
        }
      }
    });

    // Clear Window: long wiping strokes (the heaviest scene: shader + mask).
    await go('/play/clear_window/7');
    await scene('clear_window_wipe', () async {
      for (var k = 0; k < 14; k++) {
        final y = 0.2 + k * 0.04;
        await _drag(tester, at(0.12, y), at(0.88, y + 0.02), steps: 40);
      }
    });

    // Level map scroll.
    await go('/play/still_waters');
    await scene('level_map_scroll', () async {
      for (var i = 0; i < 3; i++) {
        await _drag(tester, at(0.5, 0.8), at(0.5, 0.2), steps: 30);
        await _drag(tester, at(0.5, 0.2), at(0.5, 0.8), steps: 30);
      }
    });

    binding.reportData = {...?binding.reportData, ...report};
  });
}

Map<String, num> _summarise(List<FrameTiming> t) {
  double ms(Duration d) => d.inMicroseconds / 1000.0;
  List<double> sorted(Iterable<double> v) => v.toList()..sort();
  double pct(List<double> v, double p) =>
      v.isEmpty ? 0 : v[((v.length - 1) * p).round()];
  final build = sorted(t.map((f) => ms(f.buildDuration)));
  final raster = sorted(t.map((f) => ms(f.rasterDuration)));
  final total = sorted(t.map((f) => ms(f.totalSpan)));
  double r(double x) => (x * 100).round() / 100;
  return {
    'frames': t.length,
    'build_p50_ms': r(pct(build, .5)),
    'build_p90_ms': r(pct(build, .9)),
    'build_p99_ms': r(pct(build, .99)),
    'build_worst_ms': r(build.isEmpty ? 0 : build.last),
    'raster_p50_ms': r(pct(raster, .5)),
    'raster_p90_ms': r(pct(raster, .9)),
    'raster_p99_ms': r(pct(raster, .99)),
    'raster_worst_ms': r(raster.isEmpty ? 0 : raster.last),
    'over_8ms_120hz': total.where((x) => x > 8.33).length,
    'over_16ms_60hz': total.where((x) => x > 16.67).length,
    'over_33ms_visible_jank': total.where((x) => x > 33.3).length,
  };
}

Future<void> _settle(WidgetTester t, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _tap(WidgetTester t, Offset p) async {
  await t.tapAt(p);
  await _settle(t, const Duration(milliseconds: 450));
}

Future<void> _drag(WidgetTester t, Offset a, Offset b, {int steps = 30}) async {
  final g = await t.startGesture(a);
  for (var i = 1; i <= steps; i++) {
    await g.moveTo(Offset.lerp(a, b, i / steps)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _settle(t, const Duration(milliseconds: 400));
}
