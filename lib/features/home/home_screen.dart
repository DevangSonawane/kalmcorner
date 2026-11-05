import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:calmcorner/app/brand.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/audio/music_scope.dart';
import 'package:calmcorner/core/widgets/cozy_sky.dart';
import 'package:calmcorner/core/widgets/game_ui.dart';
import 'package:calmcorner/features/levels/level_game.dart';
import 'package:calmcorner/features/levels/level_progress.dart';

/// Home: a cozy evening scene with one big tile per game.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sky = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _sky.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final games = LevelGames.all;
    final stars = ref.watch(totalStarsProvider);
    final soundOn = ref.watch(soundOnProvider);
    final totalLevels = games.fold<int>(0, (a, g) => a + g.levelCount);

    return MusicScope(
      music: MusicId.calm,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1B3A),
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _sky,
                builder: (context, _) =>
                    CustomPaint(painter: CozySkyPainter(t: _sky.value * 30)),
              ),
            ),
            SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
                children: [
                  Row(
                    children: [
                      Semantics(
                        label: '$stars of $totalLevels stars',
                        child: StarCounter(count: stars),
                      ),
                      const Spacer(),
                      ChunkyIconButton(
                        icon: soundOn
                            ? Icons.music_note_rounded
                            : Icons.music_off_rounded,
                        tooltip: soundOn ? 'Mute' : 'Sound on',
                        color: const Color(0xFF3B3660),
                        onPressed: () =>
                            ref.read(soundOnProvider.notifier).toggle(),
                      ),
                      const SizedBox(width: 10),
                      ChunkyIconButton(
                        icon: Icons.settings_rounded,
                        tooltip: 'Settings',
                        color: const Color(0xFF3B3660),
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const _Wordmark(),
                  const SizedBox(height: 26),
                  for (var i = 0; i < games.length; i++) ...[
                    _Pop(
                      animation: _intro,
                      index: i,
                      child: _GameTile(game: games[i]),
                    ),
                    const SizedBox(height: 22),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppBrand.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -0.5,
            shadows: [
              Shadow(color: Color(0xFF0E0C22), offset: Offset(0, 4)),
              Shadow(color: Color(0x668E7CC3), blurRadius: 24),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'little games for a slow evening',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _Pop extends StatelessWidget {
  const _Pop({
    required this.animation,
    required this.index,
    required this.child,
  });
  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final start = (index * 0.18).clamp(0.0, 0.6);
        final p = ((animation.value - start) / (1 - start)).clamp(0.0, 1.0);
        final t = Curves.easeOutBack.transform(p);
        return Opacity(
          opacity: p,
          child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
        );
      },
    );
  }
}

class _GameTile extends ConsumerStatefulWidget {
  const _GameTile({required this.game});
  final LevelGameModule game;

  @override
  ConsumerState<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends ConsumerState<_GameTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final progress = ref.watch(gameProgressProvider(game.id));
    final done = progress.completed.length;
    final next = progress.nextLevel(game.levelCount);
    final color = game.gradient.last;
    final base = darken(color, 0.35);
    const depth = 7.0;

    return Semantics(
      button: true,
      label:
          '${game.title}. ${game.tagline}. $done of ${game.levelCount} levels.',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          context.push('/play/${game.id}');
        },
        child: Stack(
          children: [
            Positioned.fill(
              top: depth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              margin: EdgeInsets.only(
                top: _down ? depth - 2 : 0,
                bottom: _down ? 2 : depth,
              ),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: lighten(color, 0.35), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: 150,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          game.buildThumbnail(context),
                          Positioned(
                            left: 10,
                            top: 10,
                            child: _Badge(
                              text: done >= game.levelCount
                                  ? 'ALL DONE'
                                  : 'LEVEL $next',
                              color: base,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 6, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  height: 1.05,
                                  shadows: [
                                    Shadow(
                                      color: base,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                game.tagline,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _ProgressStrip(
                                done: done,
                                total: game.levelCount,
                                track: base,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ChunkyButton(
                          semanticLabel: 'Play ${game.title} level $next',
                          color: const Color(0xFFFFC94D),
                          depth: 5,
                          radius: 20,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          onPressed: () =>
                              context.push('/play/${game.id}/$next'),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 26,
                                color: Color(0xFF6B4A12),
                              ),
                              Text(
                                'PLAY',
                                style: TextStyle(color: Color(0xFF6B4A12)),
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
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.done,
    required this.total,
    required this.track,
  });
  final int done;
  final int total;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const StarIcon(size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(99),
            ),
            padding: const EdgeInsets.all(2),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (done / total).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC94D),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$done/$total',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
