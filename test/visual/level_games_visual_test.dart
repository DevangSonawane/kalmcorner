import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calmcorner/app/app.dart';
import 'package:calmcorner/core/providers.dart';
import 'package:calmcorner/core/persistence/prefs_store.dart';
import 'package:calmcorner/core/audio/audio_service_impl.dart';
import 'package:calmcorner/core/haptics/haptic_service_impl.dart';
import 'package:calmcorner/core/analytics/analytics_service.dart';
import 'package:calmcorner/core/monetization/ads_service.dart';
import 'package:calmcorner/core/monetization/purchase_service.dart';
import 'package:calmcorner/features/levels/level_game.dart';
import 'package:calmcorner/features/games/still_waters/module.dart';
import 'package:calmcorner/features/games/garden_streams/module.dart';
import 'package:calmcorner/features/games/clear_window/module.dart';

import '_capture.dart';

/// Renders key frames to build/visual/ for a human (or Claude) to look at.
void main() {
  final key = GlobalKey();

  Future<void> pump(WidgetTester tester, String path) async {
    SharedPreferences.setMockInitialValues({'onboarding.done': true});
    final store = await PrefsStore.create();
    final purchases = FakePurchases();
    LevelGames.register(StillWatersModule());
    LevelGames.register(GardenStreamsModule());
    LevelGames.register(ClearWindowModule());
  LevelGames.register(ClearWindowModule());
    tester.view.physicalSize = const Size(400 * 2, 820 * 2);
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            prefsStoreProvider.overrideWithValue(store),
            audioServiceProvider.overrideWithValue(SoloudAudioService()),
            hapticServiceProvider.overrideWithValue(HapticServiceImpl()),
            analyticsProvider.overrideWithValue(NoopAnalytics()),
            adsProvider.overrideWithValue(NoopAds()),
            purchaseProvider.overrideWithValue(purchases),
            entitlementProvider.overrideWith((ref) => purchases.entitlement),
          ],
          child: const CalmCornerApp(),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('still waters mid-pour', (tester) async {
    await pump(tester, '');
    await tester.tap(find.text('PLAY').first);
    await tester.pump(const Duration(milliseconds: 800));
    // Level 1: 5 tubes in one row; tap first, then fourth (empty).
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tapAt(const Offset(75, 420));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tapAt(const Offset(272, 420));
    for (var i = 0; i < 26; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await capturePng(tester, key, 'build/visual/still_waters_pour.png');
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('garden streams level 30', (tester) async {
    await pump(tester, '');
    await tester.scrollUntilVisible(find.text('Garden Streams'), 200);
    await tester.tap(find.text('Garden Streams'));
    await tester.pump(const Duration(milliseconds: 800));
    await capturePng(tester, key, 'build/visual/garden_map.png');
    await tester.tap(find.text('PLAY LEVEL 1'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Hint'));
    await tester.pump(const Duration(milliseconds: 900));
    await capturePng(tester, key, 'build/visual/garden_level.png');
  });
}
