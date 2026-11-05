import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calmcorner/features/home/home_screen.dart';
import 'package:calmcorner/features/onboarding/onboarding_screen.dart';
import 'package:calmcorner/features/splash/splash_screen.dart';
import 'package:calmcorner/features/settings/settings_screen.dart';
import 'package:calmcorner/features/premium/premium_screen.dart';
import 'package:calmcorner/features/collection/collection_screen.dart';
import 'package:calmcorner/features/credits/credits_screen.dart';
import 'package:calmcorner/features/games/game_shell.dart';
import 'package:calmcorner/features/games/game_registry/game_registry.dart';
import 'package:calmcorner/features/games/game_module.dart';
import 'package:calmcorner/core/providers.dart';
import 'package:calmcorner/core/audio/music_scope.dart';
import 'package:calmcorner/features/levels/level_game.dart';
import 'package:calmcorner/features/levels/level_map_screen.dart';
import 'package:calmcorner/features/levels/level_play_screen.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';

import 'dart:convert';

final routerProvider = Provider<GoRouter>((ref) {
  return _createRouter(ref);
});

GoRouter _createRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    observers: [routeObserver],
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fade(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fade(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _fade(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/game/:id',
        builder: (context, state) {
          final gameId = state.pathParameters['id']!;
          final registry = ref.read(gameRegistryProvider);
          final module = registry.getModule(gameId);
          if (module == null) {
            return const Scaffold(body: Center(child: Text('Game not found')));
          }
          final session = _GameSessionImpl(
            ref: ref,
            gameId: gameId,
            isTablet: MediaQuery.of(context).size.shortestSide >= 600,
          );
          return GameShell(module: module, session: session);
        },
      ),
      GoRoute(
        path: '/play/:id',
        builder: (context, state) {
          final game = LevelGames.byId(state.pathParameters['id']!);
          if (game == null) return const _NotFound();
          return LevelMapScreen(game: game);
        },
        routes: [
          GoRoute(
            path: ':level',
            builder: (context, state) {
              final game = LevelGames.byId(state.pathParameters['id']!);
              final level = int.tryParse(state.pathParameters['level']!) ?? 1;
              if (game == null) return const _NotFound();
              return LevelPlayScreen(game: game, level: level);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/collection',
        builder: (context, state) => const CollectionScreen(),
      ),
      GoRoute(
        path: '/credits',
        builder: (context, state) => const CreditsScreen(),
      ),
    ],
    redirect: (context, state) {
      return null;
    },
  );
}

class _GameSessionImpl implements GameSession {
  _GameSessionImpl({
    required this.ref,
    required this.gameId,
    required this.isTablet,
  });

  final Ref ref;
  final String gameId;
  @override
  final bool isTablet;

  @override
  AudioService get audio => ref.read(audioServiceProvider);

  @override
  HapticService get haptics => ref.read(hapticServiceProvider);

  @override
  SettingsSnapshot get settings {
    final store = ref.read(prefsStoreProvider);
    return SettingsSnapshot(
      reduceMotion: store.getBool('settings.reduceMotion') ?? false,
      colorblindAssist: store.getBool('settings.colorblind') ?? false,
      leftHanded: store.getBool('settings.leftHanded') ?? false,
      fastPour: store.getBool('settings.fastPour') ?? false,
      keepAwake: store.getBool('settings.keepAwake') ?? true,
    );
  }

  @override
  Map<String, dynamic>? loadState() {
    final raw = ref.read(prefsStoreProvider).getString('game_state.$gameId');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveState(Map<String, dynamic> json) async {
    await ref
        .read(prefsStoreProvider)
        .setString('game_state.$gameId', jsonEncode(json));
  }

  @override
  void reportProgress(double zeroToOne) {
    ref
        .read(prefsStoreProvider)
        .setDouble('game_progress.$gameId', zeroToOne.clamp(0, 1).toDouble());
  }

  @override
  void complete({required GameResult result}) {
    reportProgress(1);
  }

  @override
  void requestChromeVisible(bool visible) {
    // Handle chrome visibility
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Game not found')));
}

/// Slow cross-fade used between splash, onboarding and Home.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 600),
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
  );
}
