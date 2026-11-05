import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/features/games/color_sort/generator.dart'
    show ColorSortSolver;
import 'package:calmcorner/features/games/color_sort/model.dart';
import 'package:calmcorner/features/levels/level_game.dart';
import 'package:calmcorner/features/levels/level_tools.dart';

import 'levels.dart';

/// One Still Waters level: tap a tube, tap another, and the colour pours.
class StillWatersLevel extends StatefulWidget {
  const StillWatersLevel({required this.host, required this.tint, super.key});

  final LevelHost host;
  final Color tint;

  @override
  State<StillWatersLevel> createState() => _StillWatersLevelState();
}

class _Pour {
  _Pour(this.src, this.dst, this.color, this.amount);
  final int src;
  final int dst;
  final int color;
  final int amount;
}

class _StillWatersLevelState extends State<StillWatersLevel>
    with TickerProviderStateMixin {
  late ColorSortState _state = StillWatersLevels.build(widget.host.level);
  final List<ColorSortState> _history = [];
  int? _selected;
  bool _extraUsed = false;
  bool _solved = false;
  _Pour? _pour;
  (int, int)? _hint;
  int? _sparkleTube;
  String? _toast;
  Timer? _toastTimer;

  late final AnimationController _pourCtrl = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: widget.host.reduceMotion
          ? 260
          : widget.host.fastPour
          ? 450
          : 820,
    ),
  );
  late final AnimationController _liftCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  late final AnimationController _sparkleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _toastTimer?.cancel();
    _pourCtrl.dispose();
    _liftCtrl.dispose();
    _sparkleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _tapTube(int i) {
    if (_pour != null || _solved) return;
    final audio = widget.host.audio;
    final haptics = widget.host.haptics;

    if (_selected == null) {
      if (_state.tubes[i].isEmpty || _isSealed(i)) return;
      setState(() => _selected = i);
      _liftCtrl.forward(from: 0);
      audio.play(SoundId.selectTube, volume: 0.5, rate: 0.9 + (i % 6) * 0.04);
      haptics.fire(HapticEvent.tubeSelect);
      return;
    }
    if (_selected == i) {
      _liftCtrl.reverse();
      setState(() => _selected = null);
      return;
    }
    final src = _selected!;
    final n = _state.legalMoveCount(src, i);
    if (n <= 0) {
      // Switch selection to the newly tapped tube if it can pour.
      haptics.fire(HapticEvent.invalid);
      if (_state.tubes[i].isNotEmpty && !_isSealed(i)) {
        setState(() => _selected = i);
        _liftCtrl.forward(from: 0);
      } else {
        audio.play(SoundId.uiBack, volume: 0.2);
      }
      return;
    }
    _startPour(src, i, n);
  }

  bool _isSealed(int i) => _state.isUniformFull(_state.tubes[i]);

  Future<void> _startPour(int src, int dst, int n) async {
    final color = _state.tubes[src].last;
    setState(() {
      _pour = _Pour(src, dst, color, n);
      _selected = null;
      _hint = null;
    });
    _liftCtrl.value = 0;
    final pourSound = widget.host.audio.play(
      SoundId.pourLoop,
      volume: 0.5,
      rate: 0.9 + n * 0.06,
      loop: true,
    );
    widget.host.haptics.fire(HapticEvent.pourPulse);
    Future<void>.delayed(
      Duration(
        milliseconds: (_pourCtrl.duration!.inMilliseconds * 0.8).round(),
      ),
      () async {
        final h = await pourSound;
        if (h != null) {
          widget.host.audio.fadeAndStop(h, const Duration(milliseconds: 200));
        }
      },
    );
    await _pourCtrl.forward(from: 0);
    if (!mounted) return;

    _history.add(_state.copy());
    _state.applyMove(src, dst);
    setState(() => _pour = null);

    if (_isSealed(dst)) {
      _sparkleTube = dst;
      _sparkleCtrl.forward(from: 0);
      final sounds = [
        SoundId.tubeComplete0,
        SoundId.tubeComplete1,
        SoundId.tubeComplete2,
        SoundId.tubeComplete3,
        SoundId.tubeComplete4,
        SoundId.tubeComplete5,
      ];
      widget.host.audio.play(sounds[color % sounds.length], volume: 0.7);
      widget.host.haptics.fire(HapticEvent.tubeComplete);
    }

    if (_state.isWin) {
      setState(() => _solved = true);
      widget.host.onSolved();
    } else if (!_hasAnyMove()) {
      _showToast(
        _extraUsed
            ? 'No pours left from here. Try Undo.'
            : 'No pours left from here. Try Undo or an extra tube.',
      );
    }
  }

  bool _hasAnyMove() {
    for (var s = 0; s < _state.tubes.length; s++) {
      for (var d = 0; d < _state.tubes.length; d++) {
        if (_state.legalMoveCount(s, d) > 0) return true;
      }
    }
    return false;
  }

  void _undo() {
    if (_pour != null || _history.isEmpty || _solved) return;
    widget.host.audio.play(SoundId.uiBack, volume: 0.35);
    setState(() {
      _state = _history.removeLast();
      _selected = null;
      _hint = null;
    });
  }

  void _showHint() {
    if (_pour != null || _solved) return;
    final res = ColorSortSolver(_state.copy()).solve(nodeLimit: 120000);
    if (res.solvable && res.path != null && res.path!.isNotEmpty) {
      widget.host.audio.play(SoundId.windChime1, volume: 0.4);
      setState(() {
        _hint = res.path!.first;
        _selected = null;
      });
      _liftCtrl.value = 0;
    } else {
      _showToast(
        _extraUsed
            ? 'This path is tangled. Undo a few pours.'
            : 'This path is tangled. Undo, or add an extra tube.',
      );
    }
  }

  void _addTube() {
    if (_extraUsed || _pour != null || _solved) return;
    widget.host.audio.play(SoundId.uiToggleOn, volume: 0.4);
    setState(() {
      _extraUsed = true;
      _history.add(_state.copy());
      _state = ColorSortState(
        tubes: [..._state.tubes, <int>[]],
        capacity: _state.capacity,
        colorCount: _state.colorCount,
      );
      _hint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(colors.surface, widget.tint, dark ? 0.12 : 0.22)!,
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
                  final layout = _Layout.compute(
                    size,
                    _state.tubes.length,
                    _state.capacity,
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final i = layout.hit(d.localPosition);
                      if (i != null) {
                        _tapTube(i);
                      } else if (_selected != null) {
                        _liftCtrl.reverse();
                        setState(() => _selected = null);
                      }
                    },
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _pourCtrl,
                        _liftCtrl,
                        _sparkleCtrl,
                        _pulseCtrl,
                      ]),
                      builder: (context, _) => CustomPaint(
                        size: size,
                        painter: _TubesPainter(
                          state: _state,
                          layout: layout,
                          selected: _selected,
                          lift: Curves.easeOut.transform(_liftCtrl.value),
                          pour: _pour,
                          pourT: _pourCtrl.value,
                          hint: _hint,
                          pulse: _pulseCtrl.value,
                          sparkleTube: _sparkleTube,
                          sparkleT: _sparkleCtrl.value,
                          glass: colors.onSurface,
                          dark: dark,
                          symbols: widget.host.colorblind,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 36,
              child: AnimatedOpacity(
                opacity: _toast == null ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _toast ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LevelToolbar(
                children: [
                  LevelToolButton(
                    icon: Icons.undo_rounded,
                    label: 'Undo',
                    enabled: _history.isNotEmpty && !_solved,
                    onTap: _undo,
                  ),
                  LevelToolButton(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Hint',
                    enabled: !_solved,
                    onTap: _showHint,
                  ),
                  LevelToolButton(
                    icon: Icons.add_rounded,
                    label: 'Tube',
                    enabled: !_extraUsed && !_solved,
                    onTap: _addTube,
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

/// Where each tube sits on screen. Shared by painting and hit-testing.
class _Layout {
  _Layout(this.rects, this.unitH);

  final List<Rect> rects;
  final double unitH;

  static _Layout compute(Size size, int count, int capacity) {
    final rows = count <= 6 ? 1 : 2;
    final perRow = (count / rows).ceil();
    const sidePad = 20.0;
    final maxW = (size.width - sidePad * 2) / perRow;
    final w = math.min(58.0, maxW * 0.62);
    final gap = math.min(maxW - w, w * 0.9);
    final rowGap = 40.0;
    final availH = size.height - 40;
    final unitByH = (availH - rowGap * (rows - 1)) / rows / (capacity + 0.7);
    final unitH = math.min(w * 1.05, unitByH);
    final tubeH = unitH * (capacity + 0.6);
    final totalH = rows * tubeH + (rows - 1) * rowGap;
    final top = (size.height - totalH) / 2 + 10;

    final rects = <Rect>[];
    for (var i = 0; i < count; i++) {
      final row = i ~/ perRow;
      final inRow = row == rows - 1 ? count - perRow * (rows - 1) : perRow;
      final col = i % perRow;
      final rowW = inRow * w + (inRow - 1) * gap;
      final x = (size.width - rowW) / 2 + col * (w + gap);
      final y = top + row * (tubeH + rowGap);
      rects.add(Rect.fromLTWH(x, y, w, tubeH));
    }
    return _Layout(rects, unitH);
  }

  int? hit(Offset p) {
    for (var i = 0; i < rects.length; i++) {
      final r = rects[i].inflate(10).copyWith(top: rects[i].top - 30);
      if (r.contains(p)) return i;
    }
    return null;
  }
}

extension on Rect {
  Rect copyWith({double? top}) =>
      Rect.fromLTRB(left, top ?? this.top, right, bottom);
}

class _TubesPainter extends CustomPainter {
  _TubesPainter({
    required this.state,
    required this.layout,
    required this.selected,
    required this.lift,
    required this.pour,
    required this.pourT,
    required this.hint,
    required this.pulse,
    required this.sparkleTube,
    required this.sparkleT,
    required this.glass,
    required this.dark,
    this.symbols = false,
  });

  final ColorSortState state;
  final _Layout layout;
  final int? selected;
  final double lift;
  final _Pour? pour;
  final double pourT;
  final (int, int)? hint;
  final double pulse;
  final int? sparkleTube;
  final double sparkleT;
  final Color glass;
  final bool dark;
  final bool symbols;

  // Pour phases: move/tilt, pour, return.
  static const _a = 0.28;
  static const _b = 0.78;

  double get _flow {
    if (pour == null) return 0;
    return ((pourT - _a) / (_b - _a)).clamp(0.0, 1.0);
  }

  double get _travel {
    if (pour == null) return 0;
    if (pourT < _a) return Curves.easeInOut.transform(pourT / _a);
    if (pourT < _b) return 1;
    return 1 - Curves.easeInOut.transform((pourT - _b) / (1 - _b));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Hint arrow first (behind tubes).
    final h = hint;
    if (h != null) _paintHint(canvas, h);

    for (var i = 0; i < state.tubes.length; i++) {
      if (pour != null && i == pour!.src) continue;
      final rect = layout.rects[i];
      final dy = i == selected ? -lift * layout.unitH * 0.5 : 0.0;
      canvas.save();
      canvas.translate(rect.left, rect.top + dy);
      _paintTube(canvas, rect.size, _segmentsFor(i), i);
      canvas.restore();
    }

    final p = pour;
    if (p != null) _paintPouringTube(canvas, p);

    if (sparkleTube != null && sparkleT > 0 && sparkleT < 1) {
      _paintSparkle(canvas, layout.rects[sparkleTube!]);
    }
  }

  /// Liquid segments (colour, amount in units) for tube [i], bottom to top.
  List<(int, double)> _segmentsFor(int i) {
    final tube = state.tubes[i];
    final segs = <(int, double)>[];
    for (final c in tube) {
      if (segs.isNotEmpty && segs.last.$1 == c) {
        segs[segs.length - 1] = (c, segs.last.$2 + 1);
      } else {
        segs.add((c, 1));
      }
    }
    final p = pour;
    if (p == null) return segs;
    final moved = p.amount * _flow;
    if (i == p.src && segs.isNotEmpty) {
      final last = segs.removeLast();
      final left = last.$2 - moved;
      if (left > 0.001) segs.add((last.$1, left));
    } else if (i == p.dst && moved > 0) {
      if (segs.isNotEmpty && segs.last.$1 == p.color) {
        segs[segs.length - 1] = (p.color, segs.last.$2 + moved);
      } else {
        segs.add((p.color, moved));
      }
    }
    return segs;
  }

  Path _tubePath(Size s) {
    final r = s.width / 2;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(0, s.height - r)
      ..arcToPoint(
        Offset(s.width, s.height - r),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(s.width, 0)
      ..close();
  }

  void _paintTube(
    Canvas canvas,
    Size s,
    List<(int, double)> segs,
    int index, {
    double angle = 0,
    Offset pivot = Offset.zero,
  }) {
    final path = _tubePath(s);
    final sealed = state.isUniformFull(state.tubes[index]) && pour == null;

    // Glass body.
    canvas.drawPath(
      path,
      Paint()
        ..color = (dark ? Colors.white : Colors.white).withValues(
          alpha: dark ? 0.06 : 0.45,
        ),
    );

    // Liquid. Drawn in a world-aligned frame so the surface stays level
    // even while the tube is tilted.
    canvas.save();
    canvas.clipPath(path);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(-angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    final r = s.width / 2;
    final ca = math.cos(angle), sa = math.sin(angle);
    Offset toWorld(Offset p) {
      final d = p - pivot;
      return pivot + Offset(d.dx * ca - d.dy * sa, d.dx * sa + d.dy * ca);
    }

    final outline = <Offset>[
      toWorld(Offset.zero),
      toWorld(Offset(s.width, 0)),
      for (var k = 0; k <= 12; k++)
        toWorld(
          Offset(
            r + r * math.cos(k / 12 * math.pi),
            s.height - r + r * math.sin(k / 12 * math.pi),
          ),
        ),
    ];
    var yLow = -double.infinity, yHigh = double.infinity;
    for (final o in outline) {
      yLow = math.max(yLow, o.dy);
      yHigh = math.min(yHigh, o.dy);
    }
    final yLip = math.max(outline[0].dy, outline[1].dy);
    final unitWorld = (yLow - yHigh) / (state.capacity + 0.6);
    var level = 0.0;
    double surfaceY = yLow;
    for (final (color, amount) in segs) {
      final c = StillWatersLevels.colorFor(color);
      final bottom = yLow - level * unitWorld + 1;
      final top = math.max(yLip, yLow - (level + amount) * unitWorld);
      if (top >= bottom) break;
      final rect = Rect.fromLTRB(-s.height, top, s.width + s.height, bottom);
      final shadeRect = Rect.fromLTRB(
        outline.map((o) => o.dx).reduce(math.min),
        top,
        outline.map((o) => o.dx).reduce(math.max),
        bottom,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            shadeRect.topLeft,
            shadeRect.topRight,
            [
              Color.lerp(c, Colors.white, 0.18)!,
              c,
              Color.lerp(c, Colors.black, 0.12)!,
            ],
            [0, 0.45, 1],
          ),
      );
      surfaceY = top;
      level += amount;
    }
    if (symbols) {
      var lv = 0.0;
      for (final (color, amount) in segs) {
        for (var k = 0; k < amount.floor(); k++) {
          final cy = yLow - (lv + k + 0.5) * unitWorld;
          if (cy < yLip + unitWorld * 0.3) continue;
          final cx =
              outline.map((o) => o.dx).reduce((a, b) => a + b) / outline.length;
          drawColorSymbol(
            canvas,
            StillWatersLevels.symbolFor(color),
            Offset(cx, cy),
            math.min(s.width, unitWorld) * 0.22,
          );
        }
        lv += amount;
      }
    }
    if (segs.isNotEmpty && surfaceY < yLow - 2) {
      final c = StillWatersLevels.colorFor(segs.last.$1);
      canvas.drawRect(
        Rect.fromLTRB(
          -s.height,
          surfaceY - 2,
          s.width + s.height,
          surfaceY + 3,
        ),
        Paint()..color = Color.lerp(c, Colors.white, 0.45)!,
      );
    }
    canvas.restore();

    // Highlight streak.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * 0.18,
          s.height * 0.08,
          s.width * 0.12,
          s.height * 0.62,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.white.withValues(alpha: dark ? 0.12 : 0.35),
    );

    // Outline.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = glass.withValues(alpha: sealed ? 0.45 : 0.22),
    );
    // Rim.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-4, -4, s.width + 8, 8),
        const Radius.circular(4),
      ),
      Paint()..color = glass.withValues(alpha: 0.22),
    );

    if (sealed) {
      // A little cork on finished tubes.
      final cork = RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.18, -14, s.width * 0.64, 14),
        const Radius.circular(4),
      );
      canvas.drawRRect(cork, Paint()..color = const Color(0xFFC9A27E));
      canvas.drawRRect(
        cork,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF9C7A5B),
      );
    }
  }

  void _paintPouringTube(Canvas canvas, _Pour p) {
    final src = layout.rects[p.src];
    final dst = layout.rects[p.dst];
    final goRight = dst.center.dx >= src.center.dx;
    final s = src.size;

    // Mouth of the tilted tube ends up just above the destination's rim.
    final mouthTarget = Offset(
      dst.center.dx + (goRight ? -s.width * 0.25 : s.width * 0.25),
      dst.top - layout.unitH * 0.9,
    );
    final mouthHome = Offset(src.left + (goRight ? s.width : 0), src.top);
    final t = _travel;
    final mouth = Offset.lerp(mouthHome, mouthTarget, t)!;
    final angle = (goRight ? 1 : -1) * t * 1.25; // ~72 degrees
    final pivot = Offset(goRight ? s.width : 0, 0);

    canvas.save();
    canvas.translate(mouth.dx, mouth.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    _paintTube(
      canvas,
      s,
      _segmentsFor(p.src),
      p.src,
      angle: angle,
      pivot: pivot,
    );
    canvas.restore();

    // Stream.
    final flow = _flow;
    if (flow > 0 && flow < 1) {
      final dstSegs = state.tubes[p.dst].length + p.amount * flow;
      final surfaceY = dst.bottom - dstSegs * layout.unitH;
      final streamX = mouthTarget.dx;
      final c = StillWatersLevels.colorFor(p.color);
      final width = s.width * 0.18 * math.sin(flow * math.pi).clamp(0.4, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            streamX - width / 2,
            mouthTarget.dy,
            streamX + width / 2,
            surfaceY + 2,
          ),
          Radius.circular(width / 2),
        ),
        Paint()..color = c,
      );
    }
  }

  void _paintHint(Canvas canvas, (int, int) h) {
    final a = layout.rects[h.$1];
    final b = layout.rects[h.$2];
    final glow = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(pulse * 2 * math.pi));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFFD27A).withValues(alpha: glow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(a.inflate(8), const Radius.circular(30)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(b.inflate(8), const Radius.circular(30)),
      paint..color = const Color(0xFFFFD27A).withValues(alpha: glow * 0.5),
    );
    // Arc arrow over the top.
    final start = Offset(a.center.dx, a.top - 16);
    final end = Offset(b.center.dx, b.top - 16);
    final ctrl = Offset(
      (start.dx + end.dx) / 2,
      math.min(start.dy, end.dy) - 40,
    );
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFB84D).withValues(alpha: glow),
    );
    final dir = (end - ctrl);
    final ang = math.atan2(dir.dy, dir.dx);
    final head = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - 12 * math.cos(ang - 0.5),
        end.dy - 12 * math.sin(ang - 0.5),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - 12 * math.cos(ang + 0.5),
        end.dy - 12 * math.sin(ang + 0.5),
      );
    canvas.drawPath(
      head,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFB84D).withValues(alpha: glow),
    );
  }

  void _paintSparkle(Canvas canvas, Rect r) {
    final t = sparkleT;
    final c = Offset(r.center.dx, r.top);
    final paint = Paint()
      ..color = const Color(0xFFFFE6A8).withValues(alpha: (1 - t) * 0.9);
    for (var k = 0; k < 8; k++) {
      final a = k / 8 * 2 * math.pi + t;
      final d = 10 + t * 34;
      canvas.drawCircle(
        c + Offset(math.cos(a) * d, math.sin(a) * d * 0.7 - t * 10),
        3 * (1 - t) + 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TubesPainter old) => true;
}

/// Small white shapes so colours can be told apart without colour vision.
void drawColorSymbol(Canvas canvas, String symbol, Offset c, double r) {
  final fill = Paint()..color = Colors.white.withValues(alpha: 0.9);
  final stroke = Paint()
    ..color = Colors.white.withValues(alpha: 0.9)
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.35
    ..strokeCap = StrokeCap.round;
  Path poly(int n, double rot, [double rr = 1]) {
    final p = Path();
    for (var i = 0; i < n; i++) {
      final a = rot + i * 2 * math.pi / n;
      final o = c + Offset(math.cos(a), math.sin(a)) * r * rr;
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  switch (symbol) {
    case 'dot':
      canvas.drawCircle(c, r * 0.6, fill);
    case 'square':
      canvas.drawRect(
        Rect.fromCenter(center: c, width: r * 1.4, height: r * 1.4),
        fill,
      );
    case 'triangle':
      canvas.drawPath(poly(3, -math.pi / 2, 1.1), fill);
    case 'diamond':
      canvas.drawPath(poly(4, 0, 1.05), fill);
    case 'plus':
      canvas.drawLine(c - Offset(r, 0), c + Offset(r, 0), stroke);
      canvas.drawLine(c - Offset(0, r), c + Offset(0, r), stroke);
    case 'ring':
      canvas.drawCircle(c, r * 0.75, stroke);
    case 'star':
      final p = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final o =
            c + Offset(math.cos(a), math.sin(a)) * r * (i.isEven ? 1.1 : 0.5);
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(p..close(), fill);
    case 'heart':
      canvas.drawCircle(c + Offset(-r * 0.4, -r * 0.2), r * 0.45, fill);
      canvas.drawCircle(c + Offset(r * 0.4, -r * 0.2), r * 0.45, fill);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - r * 0.85, c.dy)
          ..lineTo(c.dx, c.dy + r * 0.9)
          ..lineTo(c.dx + r * 0.85, c.dy)
          ..close(),
        fill,
      );
    case 'hexagon':
      canvas.drawPath(poly(6, 0), fill);
    default:
      canvas.drawLine(c - Offset(r, r), c + Offset(r, r), stroke);
      canvas.drawLine(c - Offset(r, -r), c + Offset(r, -r), stroke);
  }
}
