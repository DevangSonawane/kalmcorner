import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:calmcorner/core/audio/music_scope.dart';
import 'package:calmcorner/core/widgets/game_ui.dart';

import 'level_game.dart';
import 'level_progress.dart';

const double _heroH = 204;
const double _chapterHeader = 96;
const double _rowH = 92;

double _chapterHeight(LevelChapter c) =>
    _chapterHeader + (c.last - c.first + 1) * _rowH + 20;

/// A winding path of level coins, chapter by chapter.
class LevelMapScreen extends ConsumerStatefulWidget {
  const LevelMapScreen({required this.game, super.key});

  final LevelGameModule game;

  @override
  ConsumerState<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends ConsumerState<LevelMapScreen>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  bool _scrolled = false;

  @override
  void dispose() {
    _scroll.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _scrollToCurrent(int level, double viewport) {
    if (_scrolled) return;
    _scrolled = true;
    var y = _heroH;
    for (final c in widget.game.chapters) {
      if (c.contains(level)) {
        y += _chapterHeader + (level - c.first) * _rowH;
        break;
      }
      y += _chapterHeight(c);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = (y - viewport * 0.45).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      _scroll.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final progress = ref.watch(gameProgressProvider(game.id));
    final next = progress.nextLevel(game.levelCount);
    final allDone = progress.completed.length >= game.levelCount;
    final base = darken(game.gradient.last, 0.55);

    return MusicScope(
      music: game.music,
      child: Scaffold(
        backgroundColor: base,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      darken(game.gradient.last, 0.25),
                      base,
                      darken(game.gradient.last, 0.65),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, box) {
                  _scrollToCurrent(next, box.maxHeight);
                  return CustomScrollView(
                    controller: _scroll,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: _heroH,
                          child: _Hero(
                            game: game,
                            done: progress.completed.length,
                            next: next,
                            allDone: allDone,
                          ),
                        ),
                      ),
                      for (final chapter in game.chapters)
                        SliverToBoxAdapter(
                          child: _ChapterPath(
                            game: game,
                            chapter: chapter,
                            progress: progress,
                            current: allDone ? -1 : next,
                            pulse: _pulse,
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.game,
    required this.done,
    required this.next,
    required this.allDone,
  });

  final LevelGameModule game;
  final int done;
  final int next;
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              ChunkyIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                color: darken(game.gradient.last, 0.1),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  game.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    shadows: [
                      Shadow(
                        color: darken(game.gradient.last, 0.6),
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              ChunkyIconButton(
                icon: Icons.help_rounded,
                tooltip: 'How to play',
                color: darken(game.gradient.last, 0.1),
                onPressed: () => showHowToPlay(context, game),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: game.buildThumbnail(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const StarIcon(size: 24),
                        const SizedBox(width: 6),
                        Text(
                          '$done / ${game.levelCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ChunkyButton(
                      color: const Color(0xFFFFC94D),
                      onPressed: () => context.push('/play/${game.id}/$next'),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF6B4A12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              allDone ? 'PLAY AGAIN' : 'PLAY LEVEL $next',
                              style: const TextStyle(color: Color(0xFF6B4A12)),
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
        ],
      ),
    );
  }
}

class _ChapterPath extends StatelessWidget {
  const _ChapterPath({
    required this.game,
    required this.chapter,
    required this.progress,
    required this.current,
    required this.pulse,
  });

  final LevelGameModule game;
  final LevelChapter chapter;
  final GameProgress progress;
  final int current;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final count = chapter.last - chapter.first + 1;
    final doneHere = progress.completed.where(chapter.contains).length;
    final locked = !progress.isUnlocked(chapter.first);

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        Offset nodeAt(int i) => Offset(
          w / 2 + math.sin(i * 1.15 + chapter.first) * w * 0.26,
          _chapterHeader + i * _rowH + _rowH / 2,
        );
        final nodes = [for (var i = 0; i < count; i++) nodeAt(i)];

        return SizedBox(
          height: _chapterHeight(chapter),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(
                    nodes: nodes,
                    doneUpTo: progress.unlockedUpTo - chapter.first,
                    tint: chapter.tint,
                  ),
                ),
              ),
              Positioned(
                top: 18,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    RibbonBanner(
                      text: chapter.name,
                      color: locked ? const Color(0xFF6E6A80) : chapter.tint,
                      fontSize: 17,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          locked ? Icons.lock_rounded : Icons.star_rounded,
                          size: 16,
                          color: locked
                              ? Colors.white54
                              : const Color(0xFFFFC94D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$doneHere / $count',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < count; i++)
                Positioned(
                  left: nodes[i].dx - 34,
                  top: nodes[i].dy - 34,
                  child: _LevelCoin(
                    level: chapter.first + i,
                    tint: chapter.tint,
                    done: progress.isDone(chapter.first + i),
                    unlocked: progress.isUnlocked(chapter.first + i),
                    current: chapter.first + i == current,
                    pulse: pulse,
                    onTap: () =>
                        context.push('/play/${game.id}/${chapter.first + i}'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.nodes,
    required this.doneUpTo,
    required this.tint,
  });
  final List<Offset> nodes;
  final int doneUpTo;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 2) return;
    for (var i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i], b = nodes[i + 1];
      final reached = i + 1 < doneUpTo + 1 && i < doneUpTo;
      final paint = Paint()
        ..color = reached
            ? lighten(tint, 0.3).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      // Dotted curve.
      const dots = 7;
      for (var k = 1; k < dots; k++) {
        final t = k / dots;
        final mid = Offset(
          (a.dx + b.dx) / 2 + (b.dy - a.dy) * 0.15,
          (a.dy + b.dy) / 2,
        );
        final p = Offset(
          (1 - t) * (1 - t) * a.dx + 2 * (1 - t) * t * mid.dx + t * t * b.dx,
          (1 - t) * (1 - t) * a.dy + 2 * (1 - t) * t * mid.dy + t * t * b.dy,
        );
        canvas.drawCircle(p, 3.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.doneUpTo != doneUpTo ||
      old.nodes.length != nodes.length ||
      old.nodes.first != nodes.first;
}

class _LevelCoin extends StatelessWidget {
  const _LevelCoin({
    required this.level,
    required this.tint,
    required this.done,
    required this.unlocked,
    required this.current,
    required this.pulse,
    required this.onTap,
  });

  final int level;
  final Color tint;
  final bool done;
  final bool unlocked;
  final bool current;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final face = done
        ? tint
        : current
        ? Colors.white
        : unlocked
        ? lighten(tint, 0.55)
        : const Color(0xFF55506A);
    final textColor = done
        ? Colors.white
        : current
        ? darken(tint, 0.35)
        : unlocked
        ? darken(tint, 0.4)
        : Colors.white38;

    final coin = SizedBox(
      width: 68,
      height: 68,
      child: ChunkyButton(
        semanticLabel:
            'Level $level${done
                ? ', done'
                : unlocked
                ? ''
                : ', locked'}',
        onPressed: unlocked ? onTap : null,
        color: face,
        radius: 34,
        depth: 6,
        padding: EdgeInsets.zero,
        child: unlocked
            ? Text('$level', style: TextStyle(color: textColor, fontSize: 22))
            : const Icon(Icons.lock_rounded, color: Colors.white38, size: 22),
      ),
    );

    return SizedBox(
      width: 68,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (current)
            AnimatedBuilder(
              animation: pulse,
              builder: (context, _) {
                final t = pulse.value;
                return Positioned(
                  left: -8 - t * 10,
                  top: -8 - t * 10,
                  right: -8 - t * 10,
                  child: Container(
                    height: 84 + t * 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: (1 - t) * 0.7),
                        width: 3,
                      ),
                    ),
                  ),
                );
              },
            ),
          coin,
          if (done) const Positioned(bottom: 0, child: StarIcon(size: 22)),
        ],
      ),
    );
  }
}

Future<void> showHowToPlay(BuildContext context, LevelGameModule game) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final color = game.gradient.last;
      return Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF5),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color, width: 4),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RibbonBanner(text: 'How to play', color: color, fontSize: 16),
              const SizedBox(height: 16),
              Text(
                game.howToPlay,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF3B3548),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'No timer. No way to lose. Take your time.',
                style: TextStyle(
                  color: Color(0xFF6E6780),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ChunkyButton(
                color: color,
                expand: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('GOT IT'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
