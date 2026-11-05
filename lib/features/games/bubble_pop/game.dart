import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/features/games/game_module.dart';

import 'world.dart';

class BubblePopGame extends StatefulWidget {
  const BubblePopGame({required this.session, super.key});
  final GameSession session;

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<BubblePopGame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final BubbleWorld _world;
  late final AnimationController _clock;
  Duration _last = Duration.zero;
  final _rng = math.Random(8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _world = BubbleWorld(width: 390, height: 844, rng: _rng);
    _clock = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..forward();
    final loaded = widget.session.loadState();
    if (loaded != null) {
      try {
        _world.rounds = (loaded['rounds'] as num?)?.toInt() ?? _world.rounds;
        _world.totalPopped =
            (loaded['totalPopped'] as num?)?.toInt() ?? _world.totalPopped;
        _world.paletteIndex =
            (loaded['paletteIndex'] as num?)?.toInt() ?? _world.paletteIndex;
        _world.poppedThisRound =
            (loaded['poppedThisRound'] as num?)?.toInt() ??
            _world.poppedThisRound;
      } catch (_) {}
    }
  }

  void _tick() {
    final now = _clock.lastElapsedDuration ?? Duration.zero;
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt <= 0 || dt > 0.05) return;
    if (!mounted) return;
    _world.update(dt);
    if (_world.roundComplete) {
      _world.bloom();
      widget.session.audio.play(SoundId.bloom, volume: 0.9);
      widget.session.haptics.fire(HapticEvent.bloom);
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      try {
        widget.session.saveState({
          'rounds': _world.rounds,
          'totalPopped': _world.totalPopped,
          'paletteIndex': _world.paletteIndex,
          'poppedThisRound': _world.poppedThisRound,
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    try {
      widget.session.saveState({
        'rounds': _world.rounds,
        'totalPopped': _world.totalPopped,
        'paletteIndex': _world.paletteIndex,
        'poppedThisRound': _world.poppedThisRound,
      });
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _world.width = size.width;
    _world.height = size.height;
    return Semantics(
      label: 'Bubble Pop. Tap bubbles to pop them.',
      child: GestureDetector(
        onTapDown: (d) {
          // find bubble under tap
          for (final b in _world.bubbles) {
            if (b.state != BubbleState.alive) continue;
            final dx = d.localPosition.dx - b.x;
            final dy = d.localPosition.dy - b.y;
            if (dx * dx + dy * dy <= (b.r + 6) * (b.r + 6)) {
              _world.pop(b);
              // audio + haptic per spec 7.7
              final SoundId sid = b.r < 36
                  ? SoundId.popSmall
                  : (b.r < 50 ? SoundId.popMedium : SoundId.popLarge);
              final HapticEvent hev = b.r < 36
                  ? HapticEvent.popSmall
                  : (b.r < 50 ? HapticEvent.popMedium : HapticEvent.popLarge);
              final rate = 0.94 + _rng.nextDouble() * 0.14;
              final volume = 0.55 + 0.3 * ((b.r - 24).clamp(0, 40)) / 40.0;
              widget.session.audio.play(sid, volume: volume, rate: rate);
              widget.session.haptics.fire(hev);
              break;
            }
          }
          setState(() {});
        },
        child: CustomPaint(size: size, painter: _BubblePainter(_world)),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.world);
  final BubbleWorld world;

  @override
  void paint(Canvas canvas, Size size) {
    // background gradient
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE3D0), Color(0xFFD7C6FF)],
        ).createShader(Offset.zero & size),
    );
    // bubbles
    for (final b in world.bubbles) {
      if (b.state == BubbleState.popping) {
        final t = (b.popT / 0.42).clamp(0.0, 1.0);
        final ringR = b.r * (1 + 0.35 * t);
        canvas.drawCircle(
          Offset(b.x, b.y),
          ringR,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7 * (1 - t))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        continue;
      }
      final wobble =
          0.035 * math.sin(2 * math.pi * 2.1 * world.t + b.wobblePhase);
      canvas.save();
      canvas.translate(b.x, b.y);
      canvas.scale(1 + wobble, 1 - wobble);
      final tint = [
        const Color(0xFFFFB3C7),
        const Color(0xFFFFD2A8),
        const Color(0xFFFFF0A8),
        const Color(0xFFB9F0C8),
        const Color(0xFFA8DCFF),
        const Color(0xFFD0B8FF),
      ][b.tint % 6];
      canvas.drawCircle(
        Offset.zero,
        b.r,
        Paint()..color = tint.withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        Offset(-b.r * 0.3, -b.r * 0.35),
        b.r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => true;
}
