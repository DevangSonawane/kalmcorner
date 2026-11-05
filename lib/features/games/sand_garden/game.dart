import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/features/games/game_module.dart';

class SandGardenGame extends StatefulWidget {
  const SandGardenGame({required this.session, super.key});
  final GameSession session;

  @override
  State<SandGardenGame> createState() => _SandGardenGameState();
}

class _SandGardenGameState extends State<SandGardenGame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;
  Duration _last = Duration.zero;
  final GlobalKey _boundaryKey = GlobalKey();
  final List<_RakeStroke> _strokes = [];
  final List<int> _undoCheckpoints = [];
  final List<_Stone> _stones = [];
  Offset? _finger;
  Offset? _rakeHead;
  double _rakeAngle = 0;
  final _rng = math.Random(42);
  final String _sandColor = 'warm';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..forward();
    _loadGarden();
  }

  void _tick() {
    final now = _clock.lastElapsedDuration ?? Duration.zero;
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt <= 0 || dt > 0.05) return;
    if (_finger != null) {
      final target = _finger! + const Offset(0, -44);
      if (_rakeHead == null) {
        _rakeHead = target;
      } else {
        final prev = _rakeHead;
        final dx = target.dx - _rakeHead!.dx;
        final dy = target.dy - _rakeHead!.dy;
        _rakeHead = Offset(
          _rakeHead!.dx + dx * (1 - math.exp(-5.5 * dt)),
          _rakeHead!.dy + dy * (1 - math.exp(-5.5 * dt)),
        );
        final speed = math.sqrt(dx * dx + dy * dy) / dt;
        if (speed > 25) {
          final ang = math.atan2(dy, dx);
          _rakeAngle += (ang - _rakeAngle) * (1 - math.exp(-10 * dt));
          _strokes.add(
            _RakeStroke(
              from: prev!,
              to: _rakeHead!,
              angle: _rakeAngle,
              time: now.inMilliseconds.toDouble(),
            ),
          );
          if (_strokes.length > 2000) _strokes.removeAt(0);
        }
      }
    }
    if (mounted) setState(() {});
  }

  // ignore: unused_element
  void _undo() {
    if (_undoCheckpoints.isEmpty) return;
    final prev = _undoCheckpoints.removeLast();
    setState(() {
      if (prev < _strokes.length) _strokes.removeRange(prev, _strokes.length);
    });
  }

  Future<void> _loadGarden() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/garden.json');
      if (await file.exists()) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final stones = (json['stones'] as List?) ?? [];
        _stones.clear();
        for (final s in stones) {
          final m = s as Map<String, dynamic>;
          _stones.add(
            _Stone(
              pos: Offset(
                (m['x'] as num).toDouble(),
                (m['y'] as num).toDouble(),
              ),
              r: (m['r'] as num).toDouble(),
              seed: (m['seed'] as num).toInt(),
            ),
          );
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _saveGarden() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/garden.json');
      final data = {
        'stones': _stones
            .map(
              (s) => {'x': s.pos.dx, 'y': s.pos.dy, 'r': s.r, 'seed': s.seed},
            )
            .toList(),
      };
      await file.writeAsString(jsonEncode(data));
      // height PNG
      try {
        final boundary =
            _boundaryKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 1.0);
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData != null) {
            await File('${dir.path}/garden_height.png')
                .writeAsBytes(byteData.buffer.asUint8List());
          }
        }
      } catch (_) {}
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveGarden();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveGarden();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sandColor = _sandColor == 'warm'
        ? const Color(0xFFE7D3B0)
        : _sandColor == 'pearl'
        ? const Color(0xFFE9E5DC)
        : _sandColor == 'rose'
        ? const Color(0xFFEBCFC4)
        : const Color(0xFFBFC3D6);
    return Semantics(
      label: 'Zen Sand Garden. Drag to rake the sand.',
      child: GestureDetector(
        onPanStart: (d) {
          _undoCheckpoints.add(_strokes.length);
          setState(() => _finger = d.localPosition);
        },
        onPanUpdate: (d) => setState(() => _finger = d.localPosition),
        onPanEnd: (_) => setState(() {
          _finger = null;
          _rakeHead = null;
        }),
        onTapDown: (d) {
          if (d.localPosition.dy > size.height - 80) {
            final sizes = [22.0, 32.0, 44.0];
            final r = sizes[_rng.nextInt(3)];
            _stones.add(
              _Stone(pos: d.localPosition, r: r, seed: _rng.nextInt(1000)),
            );
            try {
              widget.session.audio.play(
                SoundId.stonePlace,
                volume: 0.9,
                pan: (d.localPosition.dx / size.width - 0.5).clamp(-0.5, 0.5),
              );
            } catch (_) {}
            try {
              widget.session.haptics.fire(HapticEvent.stonePlace);
            } catch (_) {}
            setState(() {});
          }
        },
        child: RepaintBoundary(
          key: _boundaryKey,
          child: CustomPaint(
            size: size,
            painter: _SandPainter(
              strokes: _strokes,
              stones: _stones,
              rakeHead: _rakeHead,
              rakeAngle: _rakeAngle,
              sandColor: sandColor,
              fingerDown: _finger != null,
            ),
          ),
        ),
      ),
    );
  }
}

class _SandPainter extends CustomPainter {
  _SandPainter({
    required this.strokes,
    required this.stones,
    required this.rakeHead,
    required this.rakeAngle,
    required this.sandColor,
    required this.fingerDown,
  });
  final List<_RakeStroke> strokes;
  final List<_Stone> stones;
  final Offset? rakeHead;
  final double rakeAngle;
  final Color sandColor;
  final bool fingerDown;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = sandColor);
    for (final s in strokes) {
      final dx = s.to.dx - s.from.dx;
      final dy = s.to.dy - s.from.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len < 0.1) continue;
      final nx = -dy / len, ny = dx / len;
      for (int t = -2; t <= 2; t++) {
        final off = t * 3.2;
        final ox = nx * off, oy = ny * off;
        final isRidge = t.abs() >= 2;
        final color = isRidge
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.25);
        canvas.drawLine(
          Offset(s.from.dx + ox - nx * 1.2, s.from.dy + oy - ny * 1.2),
          Offset(s.to.dx + ox - nx * 1.2, s.to.dy + oy - ny * 1.2),
          Paint()
            ..color = color
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    for (final st in stones) {
      final rng = math.Random(st.seed);
      final path = Path();
      for (int i = 0; i < 12; i++) {
        final ang = i * math.pi * 2 / 12;
        final r = st.r * (0.88 + rng.nextDouble() * 0.24);
        final x = st.pos.dx + math.cos(ang) * r * 0.78;
        final y = st.pos.dy + math.sin(ang) * r;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()..color = const Color(0xFF7B7B88));
      canvas.drawOval(
        Rect.fromCenter(
          center: st.pos + const Offset(4, 6),
          width: st.r * 1.6,
          height: st.r * 0.8,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    if (rakeHead != null && fingerDown) {
      canvas.save();
      canvas.translate(rakeHead!.dx, rakeHead!.dy);
      canvas.rotate(rakeAngle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 100, height: 10),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF8B6B4A),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SandPainter old) => true;
}

class _RakeStroke {
  _RakeStroke({
    required this.from,
    required this.to,
    required this.angle,
    required this.time,
  });
  final Offset from, to;
  final double angle, time;
}

class _Stone {
  _Stone({required this.pos, required this.r, required this.seed});
  Offset pos;
  final double r;
  final int seed;
}
