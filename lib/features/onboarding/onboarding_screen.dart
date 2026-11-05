import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:calmcorner/app/brand.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/audio/music_scope.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/core/providers.dart';
import 'package:calmcorner/core/widgets/cozy_sky.dart';
import 'package:calmcorner/core/widgets/game_ui.dart';
import 'package:calmcorner/features/levels/level_game.dart';

/// First-launch walkthrough: welcome, how it works, sound and touch.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pages = PageController();
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  int _page = 0;
  static const _count = 3;

  @override
  void dispose() {
    _pages.dispose();
    _float.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(prefsStoreProvider).setBool('onboarding.done', true);
    context.go('/home');
  }

  void _next() {
    if (_page < _count - 1) {
      _pages.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _count - 1;
    return MusicScope(
      music: MusicId.calm,
      child: Scaffold(
        backgroundColor: const Color(0xFF1B1838),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: CozySky()),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedOpacity(
                        opacity: last ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: last ? null : _finish,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (p) => setState(() => _page = p),
                      children: [
                        _WelcomePage(float: _float),
                        _HowPage(float: _float),
                        const _SettingsPage(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _count; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: i == _page ? 28 : 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: i == _page
                                      ? const Color(0xFFFFC94D)
                                      : Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ChunkyButton(
                            color: const Color(0xFFFFC94D),
                            expand: true,
                            onPressed: _next,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  last ? "LET'S PLAY" : 'NEXT',
                                  style: const TextStyle(
                                    color: Color(0xFF6B4A12),
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  last
                                      ? Icons.play_arrow_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: const Color(0xFF6B4A12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageText extends StatelessWidget {
  const _PageText({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.1,
            shadows: [Shadow(color: Color(0xFF0E0C22), offset: Offset(0, 3))],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.float});
  final Animation<double> float;

  @override
  Widget build(BuildContext context) {
    final games = LevelGames.all;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 230,
            child: AnimatedBuilder(
              animation: float,
              builder: (context, _) {
                final t = float.value * 2 * math.pi;
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Draw the middle card last so it sits on top.
                    for (final i in [
                      for (var k = 0; k < games.length; k++)
                        if (k != games.length ~/ 2) k,
                      if (games.isNotEmpty) games.length ~/ 2,
                    ])
                      Transform.translate(
                        offset: Offset(
                          (i - (games.length - 1) / 2) * 100,
                          math.sin(t + i * 1.4) * 6 +
                              (i == games.length ~/ 2 ? -16 : 10),
                        ),
                        child: Transform.rotate(
                          angle: (i - (games.length - 1) / 2) * 0.16,
                          child: _GameCard(game: games[i]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 36),
          _PageText(
            title: 'Welcome to\n${AppBrand.name}',
            body:
                'A cozy little corner with ${games.length} gentle games to help you slow down and unwind.',
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});
  final LevelGameModule game;

  @override
  Widget build(BuildContext context) {
    final color = game.gradient.last;
    return Container(
      width: 112,
      height: 150,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lighten(color, 0.35), width: 2),
        boxShadow: [
          BoxShadow(color: darken(color, 0.4), offset: const Offset(0, 6)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: game.buildThumbnail(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: FittedBox(
              child: Text(
                game.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowPage extends StatelessWidget {
  const _HowPage({required this.float});
  final Animation<double> float;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          AnimatedBuilder(
            animation: float,
            builder: (context, _) {
              final t = float.value * 2 * math.pi;
              return SizedBox(
                height: 170,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Transform.translate(
                      offset: Offset(0, math.sin(t) * 6),
                      child: Transform.rotate(
                        angle: math.sin(t * 0.5) * 0.08,
                        child: const StarIcon(size: 120),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: Transform.scale(
                          scale: 1 + math.sin(t * 2) * 0.05,
                          child: const RibbonBanner(
                            text: '+1 star',
                            color: Color(0xFFE0645A),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 26),
          const _PageText(
            title: 'Play at your own pace',
            body: 'Finish a level to earn a star. That’s the only score here.',
          ),
          const SizedBox(height: 22),
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Point(icon: Icons.timer_off_rounded, text: 'No timers, ever'),
              _Point(icon: Icons.favorite_rounded, text: 'No way to lose'),
              _Point(
                icon: Icons.lightbulb_rounded,
                text: 'Undo and hints whenever you like',
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: const Color(0xFFFFC94D)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPage extends ConsumerStatefulWidget {
  const _SettingsPage();

  @override
  ConsumerState<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<_SettingsPage> {
  late bool _haptics =
      (ref.read(prefsStoreProvider).getString('settings.haptics') ??
          'Normal') !=
      'Off';

  void _setHaptics(bool on) {
    setState(() => _haptics = on);
    ref
        .read(prefsStoreProvider)
        .setString('settings.haptics', on ? 'Normal' : 'Off');
    final h = ref.read(hapticServiceProvider);
    h.applySettings(
      HapticSettings(level: on ? HapticLevel.normal : HapticLevel.off),
    );
    if (on) h.fire(HapticEvent.toggle);
  }

  @override
  Widget build(BuildContext context) {
    final soundOn = ref.watch(soundOnProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          const CalmLogo(size: 110),
          const SizedBox(height: 28),
          const _PageText(
            title: 'Make it yours',
            body: 'Soft music and gentle taps help you settle in. You can change these any time.',
          ),
          const SizedBox(height: 26),
          _ToggleCard(
            icon: Icons.music_note_rounded,
            title: 'Music & sounds',
            subtitle: 'Calm background music',
            value: soundOn,
            onChanged: (_) => ref.read(soundOnProvider.notifier).toggle(),
          ),
          const SizedBox(height: 12),
          _ToggleCard(
            icon: Icons.vibration_rounded,
            title: 'Vibration',
            subtitle: 'Light taps as you play',
            value: _haptics,
            onChanged: _setHaptics,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: title,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2A52).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4A4378), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0xFF15122C), offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: value
                      ? const Color(0xFFFFC94D)
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: value ? const Color(0xFF6B4A12) : Colors.white54,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: const Color(0xFF6B4A12),
                activeTrackColor: const Color(0xFFFFC94D),
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
