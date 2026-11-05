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
import 'package:calmcorner/features/games/game_registry/game_registry.dart';
import 'package:calmcorner/features/games/window_wipe/module.dart';
import 'package:calmcorner/features/games/tactile_games.dart';

void main() {
  testWidgets('App builds and shows splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await PrefsStore.create();
    final audio = SoloudAudioService();
    final haptic = HapticServiceImpl();
    final purchases = FakePurchases();
    GameRegistry.instance.register(WindowWipeModule());
    GameRegistry.instance.register(BubblePopModule());
    GameRegistry.instance.register(SandGardenModule());
    GameRegistry.instance.register(ColorSortModule());
    GameRegistry.instance.register(GrowPlantModule());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsStoreProvider.overrideWithValue(store),
          audioServiceProvider.overrideWithValue(audio),
          hapticServiceProvider.overrideWithValue(haptic),
          analyticsProvider.overrideWithValue(NoopAnalytics()),
          adsProvider.overrideWithValue(NoopAds()),
          purchaseProvider.overrideWithValue(purchases),
          entitlementProvider.overrideWith((ref) => purchases.entitlement),
        ],
        child: const CalmCornerApp(),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    // Let the splash finish its minimum display time.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });
}
