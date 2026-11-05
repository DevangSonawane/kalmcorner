import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/features/games/game_module.dart';
import 'package:calmcorner/core/tuning/tuning.dart';
import 'package:calmcorner/core/engine/sim_loop.dart';
import 'package:calmcorner/features/games/window_wipe/scenes.dart';
import 'package:calmcorner/features/games/window_wipe/wipe_engine.dart';
import 'package:calmcorner/features/games/window_wipe/painter.dart';

class WindowWipeTuning {
  static Tuning create() {
    return Tuning('window_wipe', {
      'brushRadius': const Tunable('brushRadius', 34, 24, 50),
      'followerHz': const Tunable('followerHz', 7.5, 4, 14),
      'followerZeta': const Tunable('followerZeta', 0.85, 0.5, 1.2),
      'stampSpacing': const Tunable('stampSpacing', 0.35, 0.2, 0.6),
      'restCleanRate': const Tunable('restCleanRate', 0.10, 0, 0.3),
      'completionThreshold': const Tunable(
        'completionThreshold',
        0.93,
        0.85,
        0.98,
      ),
      'revealSeconds': const Tunable('revealSeconds', 1.4, 0.6, 3),
      'kSpot': const Tunable('kSpot', 0.28, 0.1, 0.6),
      'rCrit': const Tunable('rCrit', 3.4, 2, 5),
      'maxDroplets': const Tunable('maxDroplets', 90, 20, 150),
      'squeakProb': const Tunable('squeakProb', 0.4, 0, 1),
    });
  }
}

class WindowWipeModule extends GameModule {
  WindowWipeModule() {
    TuningRegistry.instance.register(WindowWipeTuning.create());
  }

  @override
  String get id => 'window_wipe';

  @override
  GameMeta get meta => const GameMeta(
    titleKey: 'windowWipe',
    taglineKey: 'windowWipeTagline',
    accent: Color(0xFF8E7CC3),
    accent2: Color(0xFFF2A488),
    defaultMusic: 'dusk',
    premium: false,
  );

  @override
  Widget buildThumbnail(BuildContext context, {required double t}) {
    return const _WindowWipeThumbnail();
  }

  @override
  Widget buildGame(BuildContext context, GameSession session) {
    return WindowWipeGame(session: session);
  }
}

class _WindowWipeThumbnail extends StatelessWidget {
  const _WindowWipeThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2338), Color(0xFF3C4B73), Color(0xFFE8A27A)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.cleaning_services, size: 48, color: Colors.white70),
      ),
    );
  }
}

class WindowWipeGame extends StatefulWidget {
  const WindowWipeGame({required this.session, super.key});
  final GameSession session;

  @override
  State<WindowWipeGame> createState() => _WindowWipeGameState();
}

class _WindowWipeGameState extends State<WindowWipeGame>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final SimLoop _simLoop;
  late final WipeEngine _engine;
  late final AnimationController _revealController;
  late final AnimationController _completionController;
  late final AnimationController _moteController;
  bool _completed = false;
  bool _showCompletion = false;
  bool _useShader = false;
  ui.FragmentProgram? _shaderProgram;
  Timer? _hintTimer;
  bool _hintShown = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (TuningRegistry.instance.get('window_wipe') == null) {
      TuningRegistry.instance.register(WindowWipeTuning.create());
    }
    _engine = WipeEngine(
      tuning: TuningRegistry.instance.get('window_wipe')!.getAll(),
      sceneId: SceneId.rainyEvening,
      onProgress: (p) => widget.session.reportProgress(p),
      onComplete: _onComplete,
      onSqueak: () => widget.session.audio.play(
        [SoundId.wipeSqueak1, SoundId.wipeSqueak2, SoundId.wipeSqueak3][Random()
            .nextInt(3)],
        volume: 0.35 + Random().nextDouble() * 0.25,
        rate: 0.95 + Random().nextDouble() * 0.15,
      ),
      onSpotResist: () {
        widget.session.haptics.fire(HapticEvent.scrubResist);
      },
      onWipeTick: () {
        widget.session.haptics.fire(HapticEvent.wipeTick);
      },
    );

    _simLoop = SimLoop(
      step: 1 / 120,
      onStep: (dt) {
        _engine.update(dt, MediaQuery.sizeOf(context));
      },
    );

    _revealController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (_engine.tuning['revealSeconds']! * 1000).round(),
      ),
    );

    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _moteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    bool rm = false;
    try {
      rm = widget.session.settings.reduceMotion;
    } catch (_) {
      rm = false;
    }
    if (!rm) {
      _moteController.repeat();
    }

    _loadShader();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final rm = (() {
      try {
        return widget.session.settings.reduceMotion ||
            MediaQuery.of(context).disableAnimations;
      } catch (_) {
        return MediaQuery.of(context).disableAnimations;
      }
    })();
    if (rm) {
      _moteController.stop();
    }
    _engine.init(MediaQuery.sizeOf(context));
    final loaded = widget.session.loadState();
    if (loaded != null) {
      try {
        _engine.loadState(loaded, MediaQuery.sizeOf(context));
      } catch (_) {}
    }
    _simLoop.start();
    _hintTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && !_hintShown) {
        _hintShown = true;
        _showHintCard();
      }
    });
  }

  Future<void> _loadShader() async {
    try {
      _shaderProgram = await ui.FragmentProgram.fromAsset(
        'shaders/window_glass.frag',
      );
      _useShader = true;
    } catch (_) {
      _useShader = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hintTimer?.cancel();
    _simLoop.stop();
    _revealController.dispose();
    _completionController.dispose();
    _moteController.dispose();
    try {
      widget.session.saveState(_engine.saveState());
    } catch (_) {}
    try {
      widget.session.audio.pauseAll();
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _simLoop.stop();
      widget.session.audio.pauseAll();
      try {
        widget.session.saveState(_engine.saveState());
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      _simLoop.start();
      widget.session.audio.resumeAll();
    }
  }

  void _onComplete() {
    if (_completed) return;
    _completed = true;
    _simLoop.stop();

    widget.session.audio.play(SoundId.completeSoft);
    widget.session.haptics.fire(HapticEvent.completeSoft);
    widget.session.audio.duckMusic(
      to: 0.4,
      down: const Duration(milliseconds: 300),
      up: const Duration(milliseconds: 1200),
    );

    _revealController.forward().then((_) {
      _completionController.forward().then((_) {
        if (mounted) {
          setState(() => _showCompletion = true);
        }
      });
    });
  }

  void _showHintCard() {
    // Show a hint overlay for 4 seconds
    Overlay.of(context).insert(
      OverlayEntry(
        builder: (context) => Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 280),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow
                          .withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gesture, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Drag to wipe the glass',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 4), () {
      // The overlay entry will be removed automatically when the game exits
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Window Wipe. Drag to wipe the glass.',
      child: Listener(
        onPointerDown: (e) => _engine.pointerTracker.addPointer(e),
        onPointerMove: (e) => _engine.pointerTracker.updatePointer(e),
        onPointerUp: (e) => _engine.pointerTracker.removePointer(e),
        onPointerCancel: (e) => _engine.pointerTracker.removePointerCancel(e),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _engine,
              _revealController,
              _completionController,
              _moteController,
            ]),
            builder: (context, child) => Stack(
              children: [
                CustomPaint(
                  painter: WindowWipePainter(
                    engine: _engine,
                    revealProgress: _revealController.value,
                    completionProgress: _completionController.value,
                    useShader: _useShader,
                    shaderProgram: _shaderProgram,
                  ),
                  size: Size.infinite,
                ),
                if (_completed && !_showCompletion) _buildBrightnessOverlay(),
                if (_showCompletion) _buildCompletionSheet(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrightnessOverlay() {
    return AnimatedBuilder(
      animation: _completionController,
      builder: (context, child) => Container(
        color: Colors.white.withValues(
          alpha: 0.06 * sin(_completionController.value * pi),
        ),
      ),
    );
  }

  Widget _buildCompletionSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _completionController,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 100 * (1 - _completionController.value)),
          child: Opacity(
            opacity: _completionController.value,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _getCompletionLine(),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_engine.elapsed ~/ 60).toString().padLeft(2, '0')}:${(_engine.elapsed % 60).toString().padLeft(2, '0')} of calm',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _completed = false;
                              _showCompletion = false;
                              _engine.init(MediaQuery.sizeOf(context));
                              _simLoop.start();
                            });
                          },
                          child: const Text('Again'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _completed = false;
                              _showCompletion = false;
                              // advance to next scene
                              final currentIdx = SceneRegistry.scenes
                                  .indexWhere((s) => s.id == _engine.sceneId);
                              int nextIdx = currentIdx + 1;
                              if (nextIdx >= SceneRegistry.scenes.length) {
                                nextIdx = 0;
                              }
                              // skip locked (premium) if not entitled
                              final scene = SceneRegistry.scenes[nextIdx];
                              _engine = WipeEngine(
                                tuning: TuningRegistry.instance
                                    .get('window_wipe')!
                                    .getAll(),
                                sceneId: scene.id,
                                onProgress: (p) =>
                                    widget.session.reportProgress(p),
                                onComplete: _onComplete,
                                onSqueak: () => widget.session.audio.play(
                                  [
                                    SoundId.wipeSqueak1,
                                    SoundId.wipeSqueak2,
                                    SoundId.wipeSqueak3,
                                  ][Random().nextInt(3)],
                                  volume: 0.35 + Random().nextDouble() * 0.25,
                                  rate: 0.95 + Random().nextDouble() * 0.15,
                                ),
                                onSpotResist: () => widget.session.haptics.fire(
                                  HapticEvent.scrubResist,
                                ),
                                onWipeTick: () => widget.session.haptics.fire(
                                  HapticEvent.wipeTick,
                                ),
                              );
                              _engine.init(MediaQuery.sizeOf(context));
                              _simLoop.start();
                            });
                          },
                          child: const Text('Next scene'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Home'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getCompletionLine() {
    const lines = [
      'Clear as morning.',
      'Nicely done. Take a breath.',
      'That felt good.',
      'All settled.',
      'Soft and still.',
      'Lovely.',
      'Calm, collected.',
      'Ahh. There it is.',
      'Well tended.',
      'Peace, delivered.',
    ];
    return lines[DateTime.now().millisecondsSinceEpoch % lines.length];
  }
}
