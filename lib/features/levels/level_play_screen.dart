import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/audio/music_scope.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/core/providers.dart';
import 'package:calmcorner/core/widgets/game_ui.dart';

import 'level_game.dart';
import 'level_map_screen.dart' show showHowToPlay;
import 'level_progress.dart';

/// Hosts one level: top bar, the game itself, and the celebration card.
class LevelPlayScreen extends ConsumerStatefulWidget {
  const LevelPlayScreen({required this.game, required this.level, super.key});

  final LevelGameModule game;
  final int level;

  @override
  ConsumerState<LevelPlayScreen> createState() => _LevelPlayScreenState();
}

class _LevelPlayScreenState extends ConsumerState<LevelPlayScreen>
    with SingleTickerProviderStateMixin {
  late int _level = widget.level.clamp(1, widget.game.levelCount);
  int _attempt = 0;
  bool _solved = false;
  bool _firstTime = false;
  String? _note;
  late final AnimationController _doneCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const _cheers = [
    'Lovely!',
    'All settled',
    'So calm',
    'Beautiful',
    'Nicely done',
    'Peaceful',
    'Ahh, there',
  ];

  @override
  void initState() {
    super.initState();
    _rememberLastPlayed();
    if (ref.read(prefsStoreProvider).getBool('settings.keepAwake') ?? true) {
      WakelockPlus.enable().catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((Object _) {});
    _doneCtrl.dispose();
    super.dispose();
  }

  void _rememberLastPlayed() {
    ref.read(levelProgressStoreProvider).setLastPlayed(widget.game.id, _level);
  }

  Future<void> _onSolved({String? note}) async {
    if (_solved) return;
    final store = ref.read(levelProgressStoreProvider);
    final firstTime = !store.read(widget.game.id).isDone(_level);
    setState(() {
      _solved = true;
      _note = note;
      _firstTime = firstTime;
    });
    ref
        .read(audioServiceProvider)
        .duckMusic(to: 0.3, up: const Duration(seconds: 2));
    await store.markDone(widget.game.id, _level);
    ref.read(progressVersionProvider.notifier).bump();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    ref.read(audioServiceProvider).play(SoundId.levelComplete, volume: 0.8);
    ref.read(hapticServiceProvider).fire(HapticEvent.levelComplete);
    _doneCtrl.forward(from: 0);
  }

  void _restart() {
    setState(() {
      _attempt++;
      _solved = false;
    });
    _doneCtrl.value = 0;
  }

  void _goTo(int level) {
    setState(() {
      _level = level;
      _attempt++;
      _solved = false;
    });
    _doneCtrl.value = 0;
    _rememberLastPlayed();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final chapter = game.chapterOf(_level);
    final store = ref.read(prefsStoreProvider);
    final host = LevelHost(
      audio: ref.read(audioServiceProvider),
      haptics: ref.read(hapticServiceProvider),
      level: _level,
      reduceMotion: store.getBool('settings.reduceMotion') ?? false,
      colorblind: store.getBool('settings.colorblind') ?? false,
      fastPour: store.getBool('settings.fastPour') ?? false,
      onSolved: _onSolved,
      onRestart: _restart,
    );
    final barColor = darken(chapter.tint, 0.05);

    return MusicScope(
      music: game.music,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: KeyedSubtree(
                key: ValueKey('${game.id}-$_level-$_attempt'),
                child: game.buildLevel(context, host),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChunkyIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Levels',
                        color: barColor,
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: _LevelPill(
                            level: _level,
                            chapter: chapter.name,
                            color: barColor,
                          ),
                        ),
                      ),
                      ChunkyIconButton(
                        icon: Icons.help_rounded,
                        tooltip: 'How to play',
                        color: barColor,
                        onPressed: () => showHowToPlay(context, game),
                      ),
                      const SizedBox(width: 8),
                      ChunkyIconButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Restart level',
                        color: barColor,
                        onPressed: _solved ? null : _restart,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _doneCtrl,
                builder: (context, _) {
                  final v = _doneCtrl.value;
                  if (v == 0) return const SizedBox.shrink();
                  final isLast = _level >= game.levelCount;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black.withValues(
                            alpha: 0.45 * Curves.easeOut.transform(v),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: ConfettiBurst(
                          key: ValueKey('confetti-$_level-$_attempt'),
                          colors: [
                            chapter.tint,
                            const Color(0xFFFFC94D),
                            Colors.white,
                            lighten(chapter.tint, 0.4),
                          ],
                        ),
                      ),
                      Center(
                        child: _Celebration(
                          t: v,
                          cheer: _cheers[_level % _cheers.length],
                          level: _level,
                          note: _note,
                          firstTime: _firstTime,
                          tint: chapter.tint,
                          isLast: isLast,
                          onLevels: () => context.pop(),
                          onNext: isLast
                              ? () => context.pop()
                              : () => _goTo(_level + 1),
                        ),
                      ),
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

class _LevelPill extends StatelessWidget {
  const _LevelPill({
    required this.level,
    required this.chapter,
    required this.color,
  });
  final int level;
  final String chapter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lighten(color, 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(color: darken(color, 0.3), offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LEVEL $level',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1,
              height: 1.1,
            ),
          ),
          Text(
            chapter,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Celebration extends StatelessWidget {
  const _Celebration({
    required this.t,
    required this.cheer,
    required this.level,
    required this.note,
    required this.firstTime,
    required this.tint,
    required this.isLast,
    required this.onLevels,
    required this.onNext,
  });

  final double t;
  final String cheer;
  final int level;
  final String? note;
  final bool firstTime;
  final Color tint;
  final bool isLast;
  final VoidCallback onLevels;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final card = Curves.easeOutBack.transform((t / 0.6).clamp(0.0, 1.0));
    final star = Curves.elasticOut.transform(
      ((t - 0.35) / 0.65).clamp(0.0, 1.0),
    );
    return Opacity(
      opacity: (t * 3).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.6 + 0.4 * card,
        child: Container(
          width: math.min(MediaQuery.sizeOf(context).width - 40, 380),
          margin: const EdgeInsets.only(top: 40),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 22),
                padding: const EdgeInsets.fromLTRB(22, 56, 22, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF5),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: tint, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: darken(tint, 0.45),
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: star,
                      child: const StarIcon(size: 84),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cheer,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: darken(tint, 0.35),
                      ),
                    ),
                    if (firstTime)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          '+1 star',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD9932E),
                          ),
                        ),
                      ),
                    if (note != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        note!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6E6780),
                        ),
                      ),
                    ],
                    if (isLast) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'You finished every level. Thank you for playing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6E6780),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ChunkyButton(
                            semanticLabel: 'Levels',
                            color: const Color(0xFFB9B2C8),
                            expand: true,
                            onPressed: onLevels,
                            child: const Icon(Icons.grid_view_rounded),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ChunkyButton(
                            color: tint,
                            expand: true,
                            onPressed: onNext,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(isLast ? 'DONE' : 'NEXT'),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              RibbonBanner(
                text: 'Level $level clear',
                color: tint,
                fontSize: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
