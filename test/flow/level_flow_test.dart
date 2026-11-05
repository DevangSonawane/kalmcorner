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

Future<void> pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final store = await PrefsStore.create();
  final purchases = FakePurchases();
  LevelGames.register(StillWatersModule());
  LevelGames.register(GardenStreamsModule());
  LevelGames.register(ClearWindowModule());
  tester.view.physicalSize = const Size(400 * 3, 820 * 3);
  tester.view.devicePixelRatio = 3;
  await tester.pumpWidget(
    ProviderScope(
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
  );
}

void main() {
  Future<void> passSplash(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('first run: splash -> onboarding -> home', (tester) async {
    await pumpApp(tester, {});
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Kalm Corner'), findsOneWidget); // splash wordmark
    await passSplash(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await passSplash(tester);
    expect(find.text('Play at your own pace'), findsOneWidget);
    await tester.tap(find.text('NEXT'));
    await passSplash(tester);
    expect(find.text('Make it yours'), findsOneWidget);

    // Turning vibration off is saved.
    await tester.tap(find.text('Vibration'));
    await tester.pump(const Duration(milliseconds: 100));
    final store = await PrefsStore.create();
    expect(store.getString('settings.haptics'), 'Off');

    await tester.tap(find.text("LET'S PLAY"));
    await passSplash(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Still Waters'), findsOneWidget);
    expect((await PrefsStore.create()).getBool('onboarding.done'), isTrue);
  });

  testWidgets('returning user: home -> level map -> level', (tester) async {
    await pumpApp(tester, {'onboarding.done': true});
    await passSplash(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Still Waters'), findsOneWidget);
    await tester.tap(find.text('PLAY').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('Garden Streams level opens and a tap rotates a stone', (
    tester,
  ) async {
    await pumpApp(tester, {'onboarding.done': true});
    await passSplash(tester);
    await tester.scrollUntilVisible(find.text('Garden Streams'), 200);
    await tester.tap(find.text('Garden Streams'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('PLAY LEVEL 1'), findsOneWidget);
    await tester.tap(find.text('PLAY LEVEL 1'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('stones flowing'), findsOneWidget);
    await tester.tapAt(const Offset(200, 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}
