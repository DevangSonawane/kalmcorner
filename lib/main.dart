import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/audio/audio_service.dart';
import 'core/audio/audio_service_impl.dart';
import 'core/haptics/haptic_service.dart';
import 'core/haptics/haptic_service_impl.dart';
import 'core/persistence/prefs_store.dart';
import 'core/analytics/analytics_service.dart';
import 'core/monetization/ads_service.dart';
import 'core/monetization/purchase_service.dart';
import 'features/games/game_registry/game_registry.dart';
import 'features/games/window_wipe/module.dart';
import 'features/games/tactile_games.dart';
import 'core/providers.dart';
import 'features/levels/level_game.dart';
import 'features/games/still_waters/module.dart';
import 'features/games/garden_streams/module.dart';
import 'features/games/clear_window/module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation on phones
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Edge-to-edge
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Load settings before runApp for correct initial theme
  final prefsStore = await PrefsStore.create();

  // Initialize services
  final audioService = SoloudAudioService();
  final hapticService = HapticServiceImpl();
  final analytics = NoopAnalytics();
  final ads = NoopAds();
  final purchases = FakePurchases();

  // The calm level games shown on Home.
  LevelGames.register(StillWatersModule());
  LevelGames.register(GardenStreamsModule());
  LevelGames.register(ClearWindowModule());

  // Older prototypes (not shown on Home).
  GameRegistry.instance.register(WindowWipeModule());
  GameRegistry.instance.register(BubblePopModule());
  GameRegistry.instance.register(SandGardenModule());
  GameRegistry.instance.register(ColorSortModule());
  GameRegistry.instance.register(GrowPlantModule());

  // Slow work (loading sounds) runs while the splash screen is showing.
  Future<void> boot() async {
    await audioService.init();
    audioService.applySettings(
      AudioSettings(
        enabled: prefsStore.getBool('settings.sound') ?? true,
        masterVolume: prefsStore.getDouble('settings.master') ?? 0.8,
        musicVolume: prefsStore.getDouble('settings.music') ?? 0.5,
        sfxVolume: prefsStore.getDouble('settings.sfx') ?? 0.9,
      ),
    );
    await hapticService.init();
    final hapticPref = prefsStore.getString('settings.haptics');
    hapticService.applySettings(
      HapticSettings(
        level: hapticPref == 'Off'
            ? HapticLevel.off
            : hapticPref == 'Soft'
            ? HapticLevel.soft
            : HapticLevel.normal,
      ),
    );
    await purchases.init();
  }

  final booting = boot();

  runApp(
    ProviderScope(
      overrides: [
        prefsStoreProvider.overrideWithValue(prefsStore),
        audioServiceProvider.overrideWithValue(audioService),
        hapticServiceProvider.overrideWithValue(hapticService),
        analyticsProvider.overrideWithValue(analytics),
        adsProvider.overrideWithValue(ads),
        purchaseProvider.overrideWithValue(purchases),
        bootProvider.overrideWithValue(booting),
        entitlementProvider.overrideWith((ref) => purchases.entitlement),
      ],
      child: const CalmCornerApp(),
    ),
  );
}
