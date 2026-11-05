import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/features/levels/level_game.dart';
import 'package:calmcorner/features/levels/level_tools.dart';

import 'levels.dart';

/// Colours for the garden scene.
class GardenPalette {
  const GardenPalette({
    required this.plotTop,
    required this.plotBottom,
    required this.stone,
    required this.stoneShadow,
    required this.groove,
    required this.water,
    required this.waterLight,
    required this.bud,
  });

  final Color plotTop;
  final Color plotBottom;
  final Color stone;
  final Color stoneShadow;
  final Color groove;
  final Color water;
  final Color waterLight;
  final Color bud;

  static const light = GardenPalette(
    plotTop: Color(0xFFD6EBC9),
    plotBottom: Color(0xFFA9D29C),
    stone: Color(0xFFF6EEDF),
    stoneShadow: Color(0xFFC9B99C),
    groove: Color(0xFFDCCBAE),
    water: Color(0xFF59AEE0),
    waterLight: Color(0xFFB5E3F7),
    bud: Color(0xFF7FA25E),
  );

  static const dark = GardenPalette(
    plotTop: Color(0xFF2E4636),
    plotBottom: Color(0xFF223628),
    stone: Color(0xFF59536B),
    stoneShadow: Color(0xFF2A2638),
    groove: Color(0xFF433E55),
    water: Color(0xFF5FB6E8),
    waterLight: Color(0xFFA8DDF5),
    bud: Color(0xFF8DB36A),
  );
}

class GardenStreamsLevel extends StatefulWidget {
  const GardenStreamsLevel({required this.host, required this.tint, super.key});

  final LevelHost host;
  final Color tint;

  @override
  State<GardenStreamsLevel> createState() => _GardenStreamsLevelState();
}

class _GardenStreamsLevelState extends State<GardenStreamsLevel>
    with SingleTickerProviderStateMixin {
  late final StreamPuzzle _p = GardenStreamsLevels.build(widget.host.level);

  /// Total quarter turns per tile (never wraps, so tiles always spin clockwise).
  late final List<int> _turns = List<int>.from(_p.rotations);
  late final List<double> _angle = [for (final t in _turns) t.toDouble()];
  late final List<double> _water = List<double>.filled(_p.length, 0);
  late final List<double> _bloom = List<double>.filled(_p.length, 0);
  late Set<int> _watered = _p.watered();
  final _repaint = ValueNotifier<int>(0);
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  double _time = 0;
  int? _hintTile;
  double _hintT = 0;
  bool _solved = false;
  double _celebrate = 0;
  double _nextChime = 12;

  @override
  void initState() {
    super.initState();
    for (final i in _watered) {
      _water[i] = 1;
      if (_isEnd(i)) _bloom[i] = 1;
    }
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  bool _isEnd(int i) => bitCount(_p.solution[i]) == 1 && i != _p.source;

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    _time += dt;
    final fast = widget.host.reduceMotion;
    final k = 1 - math.exp(-dt * (fast ? 40 : 16));
    for (var i = 0; i < _p.length; i++) {
      final target = _turns[i].toDouble();
      _angle[i] += (target - _angle[i]) * k;
      if ((target - _angle[i]).abs() < 0.002) _angle[i] = target;

      final settled = (target - _angle[i]).abs() < 0.15;
      final wantWater = _watered.contains(i) && settled ? 1.0 : 0.0;
      final rate = dt * (wantWater > _water[i] ? 3.5 : 6);
      _water[i] += (wantWater - _water[i]).clamp(-rate, rate);

      if (_isEnd(i)) {
        final wantBloom = _water[i] > 0.8 ? 1.0 : 0.0;
        final r = dt * (wantBloom > _bloom[i] ? 2.2 : 4);
        _bloom[i] += (wantBloom - _bloom[i]).clamp(-r, r);
      }
    }
    if (_hintTile != null) {
      _hintT += dt;
      if (_hintT > 1.8) _hintTile = null;
    }
    if (_solved) _celebrate = math.min(1, _celebrate + dt * 0.7);
    // A soft wind chime drifts by now and then.
    _nextChime -= dt;
    if (_nextChime <= 0) {
      _nextChime = 22 + math.Random().nextDouble() * 20;
      const chimes = [
        SoundId.windChime0,
        SoundId.windChime1,
        SoundId.windChime2,
        SoundId.windChime3,
      ];
      widget.host.audio.play(
        chimes[math.Random().nextInt(chimes.length)],
        volume: 0.09,
        pan: math.Random().nextDouble() * 1.2 - 0.6,
      );
    }
    _repaint.value++;
  }

  void _tapTile(int i) {
    if (_solved) return;
    final before = _watered;
    _turns[i]++;
    _p.rotate(i);
    _watered = _p.watered();
    _hintTile = null;

    widget.host.audio.play(
      SoundId.stonePlace,
      volume: 0.35,
      rate: 0.95 + (i % 5) * 0.03,
    );
    widget.host.haptics.fire(HapticEvent.uiTap);

    final gained = _watered.difference(before);
    if (gained.isNotEmpty) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        widget.host.audio.play(SoundId.waterDrop, volume: 0.4);
        if (gained.any(_isEnd)) {
          widget.host.audio.play(SoundId.bloom, volume: 0.45);
          widget.host.haptics.fire(HapticEvent.bloom);
        }
      });
    }

    if (_p.isSolved) {
      setState(() => _solved = true);
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.host.onSolved();
      });
    } else {
      setState(() {});
    }
  }

  void _hint() {
    if (_solved) return;
    // Prefer a misaligned tile touching the water, so the stream grows.
    int? pick;
    for (var i = 0; i < _p.length; i++) {
      if (_p.isAligned(i) || _isSymmetricAligned(i)) continue;
      pick ??= i;
      if (_touchesWater(i)) {
        pick = i;
        break;
      }
    }
    if (pick == null) return;
    final i = pick;
    var spins = 0;
    while (!_p.isAligned(i) && spins < 4) {
      _turns[i]++;
      _p.rotate(i);
      spins++;
    }
    widget.host.audio.play(SoundId.windChime2, volume: 0.4);
    setState(() {
      _watered = _p.watered();
      _hintTile = i;
      _hintT = 0;
    });
    if (_p.isSolved) {
      setState(() => _solved = true);
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.host.onSolved();
      });
    }
  }

  /// Straight tiles are correct in two orientations.
  bool _isSymmetricAligned(int i) {
    final m = _p.solution[i];
    final straight = m == (Dir.n | Dir.s) || m == (Dir.e | Dir.w);
    return straight && _p.maskAt(i) == m;
  }

  bool _touchesWater(int i) {
    final x = i % _p.cols, y = i ~/ _p.cols;
    for (final d in Dir.all) {
      final (dx, dy) = Dir.delta(d);
      final nx = x + dx, ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= _p.cols || ny >= _p.rows) continue;
      if (_watered.contains(ny * _p.cols + nx)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final palette = dark ? GardenPalette.dark : GardenPalette.light;
    final flowing = _watered.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(colors.surface, palette.plotTop, dark ? 0.25 : 0.45)!,
            colors.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = Size(box.maxWidth, box.maxHeight);
                  final board = _boardRect(size);
                  final tile = board.width / _p.cols;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final local = d.localPosition - board.topLeft;
                      if (local.dx < 0 || local.dy < 0) return;
                      final cx = local.dx ~/ tile, cy = local.dy ~/ tile;
                      if (cx >= _p.cols || cy >= _p.rows) return;
                      _tapTile(cy * _p.cols + cx);
                    },
                    child: CustomPaint(
                      size: size,
                      painter: _GardenPainter(
                        puzzle: _p,
                        board: board,
                        angle: _angle,
                        water: _water,
                        bloom: _bloom,
                        time: () => _time,
                        hintTile: () => _hintTile,
                        hintT: () => _hintT,
                        celebrate: () => _celebrate,
                        palette: palette,
                        tint: widget.tint,
                        repaint: _repaint,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _solved
                  ? 'Every flower is watered.'
                  : '$flowing of ${_p.length} stones flowing',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LevelToolbar(
                children: [
                  LevelToolButton(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Hint',
                    enabled: !_solved,
                    onTap: _hint,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Rect _boardRect(Size size) {
    const pad = 20.0;
    final tile = math.min(
      96.0,
      math.min(
        (size.width - pad * 2) / _p.cols,
        (size.height - pad * 2) / _p.rows,
      ),
    );
    final w = tile * _p.cols, h = tile * _p.rows;
    return Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
  }
}

class _GardenPainter extends CustomPainter {
  _GardenPainter({
    required this.puzzle,
    required this.board,
    required this.angle,
    required this.water,
    required this.bloom,
    required this.time,
    required this.hintTile,
    required this.hintT,
    required this.celebrate,
    required this.palette,
    required this.tint,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final StreamPuzzle puzzle;
  final Rect board;
  final List<double> angle;
  final List<double> water;
  final List<double> bloom;
  final double Function() time;
  final int? Function() hintTile;
  final double Function() hintT;
  final double Function() celebrate;
  final GardenPalette palette;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final t = board.width / puzzle.cols;
    final now = time();

    // Garden plot behind the stones.
    final plot = RRect.fromRectAndRadius(
      board.inflate(10),
      const Radius.circular(26),
    );
    canvas.drawRRect(
      plot.shift(const Offset(0, 4)),
      Paint()..color = palette.stoneShadow.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      plot,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.plotTop, palette.plotBottom],
        ).createShader(plot.outerRect),
    );
    _paintGrass(canvas, t);

    for (var i = 0; i < puzzle.length; i++) {
      final x = i % puzzle.cols, y = i ~/ puzzle.cols;
      final c = board.topLeft + Offset((x + 0.5) * t, (y + 0.5) * t);
      _paintTile(canvas, i, c, t, now);
    }

    final h = hintTile();
    if (h != null) {
      final x = h % puzzle.cols, y = h ~/ puzzle.cols;
      final r = Rect.fromLTWH(
        board.left + x * t,
        board.top + y * t,
        t,
        t,
      ).deflate(1);
      final a = (1 - hintT() / 1.8).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(t * 0.2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFFFC85A).withValues(alpha: a),
      );
    }

    final cel = celebrate();
    if (cel > 0 && cel < 1) _paintPetalsDrift(canvas, cel);
  }

  void _paintGrass(Canvas canvas, double t) {
    final rng = math.Random(puzzle.cols * 31 + puzzle.rows);
    final p = Paint()
      ..color = palette.bud.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < puzzle.length * 2; k++) {
      final o = Offset(
        board.left + rng.nextDouble() * board.width,
        board.top + rng.nextDouble() * board.height,
      );
      canvas.drawLine(o, o + Offset(-2, -t * 0.08), p);
      canvas.drawLine(o, o + Offset(2, -t * 0.1), p);
    }
  }

  void _paintTile(Canvas canvas, int i, Offset c, double t, double now) {
    final stone = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: t - 6, height: t - 6),
      Radius.circular(t * 0.2),
    );
    canvas.drawRRect(
      stone.shift(const Offset(0, 2.5)),
      Paint()..color = palette.stoneShadow.withValues(alpha: 0.7),
    );
    canvas.drawRRect(stone, Paint()..color = palette.stone);

    final mask = puzzle.solution[i];
    final w = water[i];

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle[i] * math.pi / 2);

    // Channels run exactly to the tile edge so neighbours meet.
    final half = t / 2;
    final groove = Paint()
      ..color = palette.groove
      ..strokeWidth = t * 0.3
      ..strokeCap = StrokeCap.butt;
    final waterPaint = Paint()
      ..color = Color.lerp(palette.groove, palette.water, w)!
      ..strokeWidth = t * 0.19
      ..strokeCap = StrokeCap.butt;

    final ends = <Offset>[];
    for (final d in Dir.all) {
      if (mask & d == 0) continue;
      final (dx, dy) = Dir.delta(d);
      ends.add(Offset(dx * half, dy * half));
    }
    for (final e in ends) {
      canvas.drawLine(Offset.zero, e, groove);
    }
    canvas.drawCircle(Offset.zero, t * 0.15, Paint()..color = palette.groove);
    for (final e in ends) {
      canvas.drawLine(Offset.zero, e, waterPaint);
    }
    canvas.drawCircle(
      Offset.zero,
      t * 0.095,
      Paint()..color = waterPaint.color,
    );

    // Flowing shimmer on watered channels.
    if (w > 0.05) {
      final shimmer = Paint()
        ..color = palette.waterLight.withValues(alpha: 0.75 * w)
        ..strokeWidth = t * 0.05
        ..strokeCap = StrokeCap.round;
      for (final e in ends) {
        for (var k = 0; k < 2; k++) {
          final f = ((now * 0.6 + k * 0.5 + i * 0.13) % 1.0);
          final a = e * f;
          final b = e * math.min(1.0, f + 0.14);
          canvas.drawLine(a, b, shimmer);
        }
      }
    }
    canvas.restore();

    if (i == puzzle.source) {
      _paintSpring(canvas, c, t, now);
    } else if (bitCount(mask) == 1) {
      _paintFlower(canvas, c, t, bloom[i], now + i);
    }
  }

  void _paintSpring(Canvas canvas, Offset c, double t, double now) {
    final r = t * 0.24;
    canvas.drawCircle(c, r + 3, Paint()..color = palette.stoneShadow);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [palette.waterLight, palette.water])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
    for (var k = 0; k < 2; k++) {
      final f = (now * 0.5 + k * 0.5) % 1.0;
      canvas.drawCircle(
        c,
        r * (0.2 + 0.75 * f),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.7 * (1 - f)),
      );
    }
  }

  void _paintFlower(Canvas canvas, Offset c, double t, double b, double seed) {
    final sway = math.sin(seed * 1.3 + time() * 1.2) * 0.06;
    // Leaves.
    final leaf = Paint()..color = palette.bud;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(side * 0.9 + sway);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -t * 0.13),
          width: t * 0.1,
          height: t * 0.22,
        ),
        leaf,
      );
      canvas.restore();
    }
    if (b < 0.02) {
      // Closed bud.
      canvas.drawCircle(c, t * 0.08, Paint()..color = palette.bud);
      canvas.drawCircle(
        c + Offset(0, -t * 0.02),
        t * 0.05,
        Paint()..color = Color.lerp(palette.bud, tint, 0.35)!,
      );
      return;
    }
    final eased = Curves.easeOutBack.transform(b.clamp(0.0, 1.0));
    final pr = t * 0.12 * eased;
    final petal = Paint()..color = tint;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(sway + seed);
    for (var k = 0; k < 5; k++) {
      final a = k / 5 * 2 * math.pi;
      canvas.drawCircle(
        Offset(math.cos(a), math.sin(a)) * pr,
        pr * 0.75,
        petal,
      );
    }
    canvas.restore();
    canvas.drawCircle(c, pr * 0.55, Paint()..color = const Color(0xFFFFE08A));
  }

  void _paintPetalsDrift(Canvas canvas, double cel) {
    final rng = math.Random(7);
    for (var k = 0; k < 24; k++) {
      final x0 = board.left + rng.nextDouble() * board.width;
      final y0 = board.top + rng.nextDouble() * board.height * 0.4;
      final drift = cel * board.height * (0.4 + rng.nextDouble() * 0.6);
      final o = Offset(x0 + math.sin(cel * 6 + k) * 14, y0 + drift);
      canvas.drawCircle(
        o,
        3 + rng.nextDouble() * 3,
        Paint()..color = tint.withValues(alpha: (1 - cel) * 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GardenPainter old) =>
      old.board != board || old.palette != palette || old.tint != tint;
}
