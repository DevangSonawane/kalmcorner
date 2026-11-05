import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/features/games/game_module.dart';

class GrowPlantGame extends StatefulWidget {
  const GrowPlantGame({required this.session, super.key});
  final GameSession session;

  @override
  State<GrowPlantGame> createState() => _GrowPlantGameState();
}

class _GrowPlantGameState extends State<GrowPlantGame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;
  Duration _last = Duration.zero;
  double _growth = 0;
  double _moisture = 0.5;
  double _light = 0.3;
  int _species = 0;
  final _rng = math.Random(7);
  final List<_Mote> _motes = [];
  double _moteTimer = 0;
  Offset? _canPos;
  bool _pouring = false;
  CalmSoundHandle? _sprinkleHandle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..forward();
    final loaded = widget.session.loadState();
    if (loaded != null) {
      try {
        _species = (loaded['species'] as num?)?.toInt() ?? _species;
        _growth = (loaded['growth'] as num?)?.toDouble() ?? _growth;
        _moisture = (loaded['moisture'] as num?)?.toDouble() ?? _moisture;
        _light = (loaded['light'] as num?)?.toDouble() ?? _light;
      } catch (_) {}
    }
  }

  void _tick() {
    final now = _clock.lastElapsedDuration ?? Duration.zero;
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt <= 0 || dt > 0.05) return;
    _moisture = math.max(0, _moisture - 0.012 * dt);
    _light = math.max(0, _light - 0.02 * dt);
    if (_moisture > 0.25) {
      _growth = math.min(
        1.0,
        _growth +
            0.012 * math.min(_moisture / 0.9, 1) * (0.4 + 0.6 * _light) * dt,
      );
    }
    if (_pouring && _canPos != null) {
      _moisture = math.min(1.0, _moisture + 0.0036 * dt * 25);
    }
    _moteTimer -= dt;
    if (_moteTimer <= 0) {
      _spawnMote();
      _moteTimer = 1.5 + _rng.nextDouble() * 2.0;
    }
    for (final m in _motes) {
      m.y += (18 + _rng.nextDouble() * 12) * dt;
      m.x += math.sin(m.y * 0.05 + m.phase) * 12 * dt;
      m.life -= dt;
    }
    _motes.removeWhere((m) => m.life <= 0);
    if (mounted) setState(() {});
  }

  void _spawnMote() {
    final size = MediaQuery.sizeOf(context);
    _motes.add(
      _Mote(
        x: size.width * (0.2 + _rng.nextDouble() * 0.6),
        y: -20,
        r: 6 + _rng.nextDouble() * 3,
        phase: _rng.nextDouble() * math.pi * 2,
        life: 9,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      try {
        widget.session.saveState({
          'species': _species,
          'growth': _growth,
          'moisture': _moisture,
          'light': _light,
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    if (_sprinkleHandle != null) {
      widget.session.audio.fadeAndStop(
        _sprinkleHandle!,
        const Duration(milliseconds: 160),
      );
    }
    try {
      widget.session.saveState({
        'species': _species,
        'growth': _growth,
        'moisture': _moisture,
        'light': _light,
      });
    } catch (_) {}

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Semantics(
      label: 'Grow a Plant. Water and collect light.',
      child: GestureDetector(
        onPanStart: (d) async {
          _canPos = d.localPosition;
          _pouring = true;
          _sprinkleHandle = await widget.session.audio.play(
            SoundId.sprinkleLoop,
            volume: 0.5,
            loop: true,
          );
          setState(() {});
        },
        onPanUpdate: (d) => setState(() => _canPos = d.localPosition),
        onPanEnd: (_) async {
          _canPos = null;
          _pouring = false;
          if (_sprinkleHandle != null) {
            await widget.session.audio.fadeAndStop(
              _sprinkleHandle!,
              const Duration(milliseconds: 160),
            );
            _sprinkleHandle = null;
          }
          setState(() {});
        },
        onTapDown: (d) {
          for (final m in _motes) {
            final dx = d.localPosition.dx - m.x;
            final dy = d.localPosition.dy - m.y;
            if (dx * dx + dy * dy < 28 * 28) {
              _light = math.min(1.0, _light + 0.18);
              _motes.remove(m);
              widget.session.audio.play(
                SoundId.waterDrop,
                volume: 0.25,
                rate: 1.5,
              );
              widget.session.haptics.fire(HapticEvent.moteCatch);
              break;
            }
          }
          setState(() {});
        },
        child: CustomPaint(
          size: size,
          painter: _PlantPainter(
            growth: _growth,
            moisture: _moisture,
            light: _light,
            species: _species,
            motes: _motes,
            canPos: _canPos,
            pouring: _pouring,
          ),
        ),
      ),
    );
  }
}

class _Mote {
  _Mote({
    required this.x,
    required this.y,
    required this.r,
    required this.phase,
    required this.life,
  });
  double x, y, r, phase, life;
}

class _PlantPainter extends CustomPainter {
  _PlantPainter({
    required this.growth,
    required this.moisture,
    required this.light,
    required this.species,
    required this.motes,
    required this.canPos,
    required this.pouring,
  });
  final double growth, moisture, light;
  final int species;
  final List<_Mote> motes;
  final Offset? canPos;
  final bool pouring;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFEFD5), Color(0xFFD9ECF5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    final base = Offset(size.width * 0.5, size.height * 0.76);
    canvas.drawOval(
      Rect.fromCenter(
        center: base + const Offset(0, 48),
        width: 170,
        height: 60,
      ),
      Paint()
        ..color = Color.lerp(
          const Color(0xFFB38B63),
          const Color(0xFF6B4A32),
          moisture,
        )!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: base + const Offset(0, 32),
          width: 140,
          height: 84,
        ),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xFFD69D78),
    );
    final h = (250 * math.min(1, growth / 0.6)).toDouble();
    final stemColor = Color.lerp(
      const Color(0xFF6FB38A),
      const Color(0xFF4E9070),
      growth,
    )!;
    canvas.drawLine(
      base,
      base - Offset(0, h),
      Paint()
        ..color = stemColor
        ..strokeWidth = (4 + 5 * growth)
        ..strokeCap = StrokeCap.round,
    );
    for (int i = 1; i < 6; i++) {
      final p = base - Offset(0, h * i / 6);
      final leafScale = math
          .pow(math.max(0, math.min(1, (growth - i * 0.1) / 0.2)), 0.7)
          .toDouble();
      final sz = 32 * leafScale;
      if (sz <= 0) continue;
      final leafColor = species == 1
          ? const Color(0xFF3F8F6B)
          : const Color(0xFF6FB38A);
      canvas.drawOval(
        Rect.fromCenter(
          center: p + Offset(i.isEven ? sz * 0.55 : -sz * 0.55, 0),
          width: sz * 1.6,
          height: sz * 0.65,
        ),
        Paint()..color = leafColor,
      );
    }
    if (growth > 0.7) {
      final top = base - Offset(0, h);
      final flowerScale = growth > 0.88 ? 1.0 : (growth - 0.7) / 0.18;
      for (int i = 0; i < 14; i++) {
        final a = i * math.pi * 2 / 14;
        canvas.drawOval(
          Rect.fromCenter(
            center:
                top +
                Offset(
                  math.cos(a) * 18 * flowerScale,
                  math.sin(a) * 18 * flowerScale,
                ),
            width: 22 * flowerScale,
            height: 12 * flowerScale,
          ),
          Paint()..color = const Color(0xFFFFD35C),
        );
      }
      canvas.drawCircle(
        top,
        14 * flowerScale,
        Paint()..color = const Color(0xFF7A4B2A),
      );
      if (growth >= 1.0) {
        for (int i = 0; i < 90; i++) {
          final ang = i * 137.5 * math.pi / 180;
          final r = 1.9 * math.sqrt(i.toDouble());
          canvas.drawCircle(
            top + Offset(math.cos(ang) * r, math.sin(ang) * r),
            1.2,
            Paint()..color = const Color(0xFF5A3A1A),
          );
        }
      }
    }
    // succulent rosette (species 2)
    if (species == 2 && growth > 0.05) {
      final top = base - Offset(0, h * 0.3);
      final rings = 5;
      for (int ring = 0; ring < rings; ring++) {
        final count = 3 + ring * 4;
        final ringR = 8.0 + ring * 6.0;
        for (int i = 0; i < count; i++) {
          final ang = i * 2 * math.pi / count + ring * 0.3;
          final leafLen = 18.0 + ring * 5.0;
          final tip =
              top + Offset(math.cos(ang) * ringR, math.sin(ang) * ringR * 0.6);
          final leafColor = Color.lerp(
            const Color(0xFF9BCDA0),
            const Color(0xFF5FA87F),
            ring / rings,
          )!;
          canvas.drawOval(
            Rect.fromCenter(center: tip, width: leafLen, height: leafLen * 0.5),
            Paint()..color = leafColor,
          );
          if (growth >= 1.0 && ring == rings - 1) {
            canvas.drawCircle(top, 6, Paint()..color = const Color(0xFFE8A0B0));
          }
        }
      }
    }
    // bonsai (species 3)
    if (species == 3 && growth > 0.1) {
      final trunkTop = base - Offset(0, h);
      canvas.drawLine(
        base,
        trunkTop,
        Paint()
          ..color = const Color(0xFF6B4A32)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
      for (int b = 0; b < 3; b++) {
        final ang = (b - 1) * 0.6;
        final branchLen = h * (0.4 + b * 0.15);
        final branchEnd =
            trunkTop +
            Offset(math.sin(ang) * branchLen, -math.cos(ang) * branchLen);
        canvas.drawLine(
          trunkTop,
          branchEnd,
          Paint()
            ..color = const Color(0xFF6B4A32)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
        for (int c = 0; c < 6; c++) {
          final ca = c * math.pi * 2 / 6;
          canvas.drawCircle(
            branchEnd + Offset(math.cos(ca) * 8, math.sin(ca) * 8),
            12,
            Paint()..color = const Color(0xFF6FB38A).withValues(alpha: 0.8),
          );
        }
      }
    }
    // cherry blossom (species 4)
    if (species == 4 && growth > 0.1) {
      final trunkTop = base - Offset(0, h);
      canvas.drawLine(
        base,
        trunkTop,
        Paint()
          ..color = const Color(0xFF8B6B4A)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
      for (int b = 0; b < 5; b++) {
        final ang = (b - 2) * 0.5;
        final branchLen = h * (0.35 + b * 0.1);
        final branchEnd =
            trunkTop +
            Offset(math.sin(ang) * branchLen, -math.cos(ang) * branchLen);
        canvas.drawLine(
          trunkTop,
          branchEnd,
          Paint()
            ..color = const Color(0xFF8B6B4A)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        if (growth > 0.7) {
          for (int f = 0; f < 4; f++) {
            final fa = f * math.pi * 2 / 4;
            final fc = branchEnd + Offset(math.cos(fa) * 10, math.sin(fa) * 10);
            for (int p = 0; p < 5; p++) {
              final pa = p * math.pi * 2 / 5;
              canvas.drawOval(
                Rect.fromCenter(
                  center: fc + Offset(math.cos(pa) * 6, math.sin(pa) * 6),
                  width: 8,
                  height: 5,
                ),
                Paint()..color = const Color(0xFFFFC4D6),
              );
            }
            canvas.drawCircle(fc, 3, Paint()..color = const Color(0xFFF2A488));
          }
        }
      }
    }
    // fern fronds (species 1)
    if (species == 1 && growth > 0.1) {
      if (species == 1 && growth > 0.1) {
        for (int f = 0; f < 7; f++) {
          final ang = (f - 3) * 0.35;
          final frondLen = 190 * growth;
          final end =
              base +
              Offset(math.sin(ang) * frondLen, -math.cos(ang) * frondLen * 0.8);
          canvas.drawLine(
            base,
            end,
            Paint()
              ..color = const Color(0xFF3F8F6B)
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round,
          );
        }
      }
      for (final m in motes) {
        canvas.drawCircle(
          Offset(m.x, m.y),
          m.r,
          Paint()
            ..color = const Color(0xFFFFE7A3)
                .withValues(alpha: 0.6 + 0.4 * (m.life / 9)),
        );
      }
      if (canPos != null) {
        canvas.save();
        canvas.translate(canPos!.dx, canPos!.dy);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-30, -10, 60, 40),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xFF8FB8D9),
        );
        canvas.drawLine(
          const Offset(20, 0),
          const Offset(40, 15),
          Paint()
            ..color = const Color(0xFF8FB8D9)
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
        canvas.restore();
        if (pouring) {
          canvas.drawLine(
            canPos! + const Offset(35, 15),
            Offset(canPos!.dx + 35, canPos!.dy + 80),
            Paint()
              ..color = const Color(0xFFBFE3FF).withValues(alpha: 0.9)
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round,
          );
        }
      }
      canvas.drawCircle(
        Offset(size.width * 0.22, size.height * 0.18),
        22,
        Paint()
          ..color = const Color(0xFFFFE7A3)
              .withValues(alpha: 0.45 + 0.4 * light),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlantPainter old) => true;
}
