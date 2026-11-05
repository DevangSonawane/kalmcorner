import 'dart:math';

import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/core/tuning/tuning.dart';
import 'package:calmcorner/features/games/game_module.dart';
import 'package:flutter/material.dart';
import 'package:calmcorner/features/games/grow_plant/game.dart';
import 'package:calmcorner/features/games/sand_garden/game.dart';
import 'package:calmcorner/features/games/bubble_pop/game.dart';
import 'package:calmcorner/features/games/color_sort/game.dart';

/// The remaining MVP games deliberately share lightweight Canvas widgets: they
/// stay offline, have no fail state, and do not need a physics package.
class BubblePopModule extends GameModule {
  BubblePopModule() {
    TuningRegistry.instance.register(
      Tuning('bubble_pop', {
        'spawnTarget': const Tunable('spawnTarget', 12, 6, 20),
        'maxBubbles': const Tunable('maxBubbles', 40, 20, 60),
        'radiusMin': const Tunable('radiusMin', 24, 16, 30),
        'radiusMax': const Tunable('radiusMax', 64, 48, 90),
        'riseBase': const Tunable('riseBase', 42, 20, 80),
        'risePerDp': const Tunable('risePerDp', 0.9, 0, 2),
        'relaxKappa': const Tunable('relaxKappa', 1.2, 0.4, 3),
        'windAmp': const Tunable('windAmp', 14, 0, 40),
        'windDamp': const Tunable('windDamp', 0.9, 0.3, 2),
        'repelK': const Tunable('repelK', 220, 50, 500),
        'popGoal': const Tunable('popGoal', 25, 10, 60),
        'hitMargin': const Tunable('hitMargin', 6, 0, 16),
        'wandHoldMs': const Tunable('wandHoldMs', 400, 200, 800),
      }),
    );
  }
  @override
  String get id => 'bubble_pop';
  @override
  GameMeta get meta => const GameMeta(
    titleKey: 'Bubble Pop',
    taglineKey: 'Tap a little joy',
    accent: Color(0xff7fb8f2),
    accent2: Color(0xffe39ae0),
    defaultMusic: 'dawn',
  );
  @override
  Widget buildThumbnail(BuildContext context, {required double t}) =>
      const _Thumbnail(
        icon: Icons.bubble_chart_rounded,
        colors: [Color(0xff8fc8ef), Color(0xffdcb9f4)],
      );
  @override
  Widget buildGame(BuildContext context, GameSession session) =>
      BubblePopGame(session: session);
}

class SandGardenModule extends GameModule {
  SandGardenModule() {
    TuningRegistry.instance.register(
      Tuning('sand_garden', {
        'texelDp': const Tunable('texelDp', 2, 1.5, 3),
        'tines': const Tunable('tines', 5, 3, 7),
        'fineTines': const Tunable('fineTines', 9, 6, 13),
        'spacing': const Tunable('spacing', 16, 12, 24),
        'fineSpacing': const Tunable('fineSpacing', 9, 6, 12),
        'grooveHeight': const Tunable('grooveHeight', 0.28, 0.1, 0.4),
        'ridgeHeight': const Tunable('ridgeHeight', 0.62, 0.55, 0.8),
        'headOffsetY': const Tunable('headOffsetY', -44, -80, 0),
        'rakeHz': const Tunable('rakeHz', 5.5, 3, 10),
        'rakeZeta': const Tunable('rakeZeta', 0.95, 0.6, 1.2),
        'minCarveSpeed': const Tunable('minCarveSpeed', 25, 5, 80),
        'curvatureLimit': const Tunable('curvatureLimit', 0.85, 0.5, 1.2),
        'rippleSpacing': const Tunable('rippleSpacing', 14, 10, 22),
        'lightStrength': const Tunable('lightStrength', 6.0, 2, 12),
      }),
    );
  }
  @override
  String get id => 'sand_garden';
  @override
  GameMeta get meta => const GameMeta(
    titleKey: 'Zen Sand Garden',
    taglineKey: 'Rake a quiet pattern',
    accent: Color(0xffb38b63),
    accent2: Color(0xff7fb89a),
    defaultMusic: 'garden',
  );
  @override
  Widget buildThumbnail(BuildContext context, {required double t}) =>
      const _Thumbnail(
        icon: Icons.waves_rounded,
        colors: [Color(0xffe8c98c), Color(0xffc58b63)],
      );
  @override
  Widget buildGame(BuildContext context, GameSession session) =>
      SandGardenGame(session: session);
}

class ColorSortModule extends GameModule {
  ColorSortModule() {
    TuningRegistry.instance.register(
      Tuning('color_sort', {
        'tubeWidth': const Tunable('tubeWidth', 44, 34, 56),
        'unitHeight': const Tunable('unitHeight', 42, 32, 52),
        'liftDp': const Tunable('liftDp', 14, 6, 24),
        'approachMs': const Tunable('approachMs', 160, 80, 400),
        'tiltMs': const Tunable('tiltMs', 260, 150, 500),
        'pourMsPerUnit': const Tunable('pourMsPerUnit', 180, 100, 300),
        'returnMs': const Tunable('returnMs', 280, 160, 500),
        'phiBaseDeg': const Tunable('phiBaseDeg', 52, 40, 70),
        'phiExtraDeg': const Tunable('phiExtraDeg', 38, 0, 50),
        'streamGravity': const Tunable('streamGravity', 1400, 800, 2200),
        'waveAmp': const Tunable('waveAmp', 2.2, 0, 5),
        'sloshK': const Tunable('sloshK', 60, 20, 120),
        'sloshC': const Tunable('sloshC', 5, 2, 12),
        'queueSpeed': const Tunable('queueSpeed', 1.4, 1, 2),
        'hintCooldownMs': const Tunable('hintCooldownMs', 3000, 0, 8000),
      }),
    );
  }
  @override
  String get id => 'color_sort';
  @override
  GameMeta get meta => const GameMeta(
    titleKey: 'Color Sort',
    taglineKey: 'Pour colors together',
    accent: Color(0xff8e7cc3),
    accent2: Color(0xfff2a488),
    defaultMusic: 'dusk',
  );
  @override
  Widget buildThumbnail(BuildContext context, {required double t}) =>
      const _Thumbnail(
        icon: Icons.science_rounded,
        colors: [Color(0xfff28b82), Color(0xff7fb8f2)],
      );
  @override
  Widget buildGame(BuildContext context, GameSession session) =>
      ColorSortGame(session: session);
}

class GrowPlantModule extends GameModule {
  GrowPlantModule() {
    TuningRegistry.instance.register(
      Tuning('grow_plant', {
        'growthRate': const Tunable('growthRate', 0.012, 0.004, 0.03),
        'moistureDecay': const Tunable('moistureDecay', 0.012, 0, 0.04),
        'lightDecay': const Tunable('lightDecay', 0.02, 0, 0.06),
        'restMoisture': const Tunable('restMoisture', 0.25, 0.1, 0.5),
        'waterRate': const Tunable('waterRate', 90, 40, 160),
        'dropMoisture': const Tunable('dropMoisture', 0.0036, 0.001, 0.01),
        'moteLight': const Tunable('moteLight', 0.18, 0.05, 0.4),
        'windAmp': const Tunable('windAmp', 6, 0, 12),
      }),
    );
  }
  @override
  String get id => 'grow_plant';
  @override
  GameMeta get meta => const GameMeta(
    titleKey: 'Grow a Plant',
    taglineKey: 'Water, light, and grow',
    accent: Color(0xff7fb89a),
    accent2: Color(0xffffd35c),
    defaultMusic: 'garden',
  );
  @override
  Widget buildThumbnail(BuildContext context, {required double t}) =>
      const _Thumbnail(
        icon: Icons.local_florist_rounded,
        colors: [Color(0xffb8dfb0), Color(0xffffd5a4)],
      );
  @override
  Widget buildGame(BuildContext context, GameSession session) =>
      GrowPlantGame(session: session);
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.icon, required this.colors});
  final IconData icon;
  final List<Color> colors;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Center(child: Icon(icon, color: Colors.white, size: 48)),
  );
}

class _Bubble {
  _Bubble(this.position, this.radius, this.color, this.speed);
  Offset position;
  final double radius;
  final Color color;
  final double speed;
}

class _BubbleGame extends StatefulWidget {
  const _BubbleGame({required this.session});
  final GameSession session;
  @override
  State<_BubbleGame> createState() => _BubbleGameState();
}

class _BubbleGameState extends State<_BubbleGame>
    with SingleTickerProviderStateMixin {
  final _rng = Random(8);
  final _bubbles = <_Bubble>[];
  late final AnimationController _clock;
  Duration _last = Duration.zero;
  int _popped = 0;
  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..forward();
  }

  void _tick() {
    final now = _clock.lastElapsedDuration ?? Duration.zero;
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (!mounted) return;
    setState(() {
      for (final b in _bubbles) {
        b.position = Offset(
          b.position.dx + sin(now.inMilliseconds / 600 + b.radius) * 8 * dt,
          b.position.dy - b.speed * dt,
        );
      }
      _bubbles.removeWhere((b) => b.position.dy + b.radius < 0);
    });
  }

  void _add(Offset p, Size s) {
    if (_bubbles.length >= 18) return;
    final r = 24 + _rng.nextDouble() * 28;
    _bubbles.add(
      _Bubble(
        Offset(p.dx.clamp(r, s.width - r), p.dy.clamp(r, s.height - r)),
        r,
        [
          const Color(0x997fb8f2),
          const Color(0x99e39ae0),
          const Color(0x99f2d96b),
        ][_rng.nextInt(3)],
        12 + _rng.nextDouble() * 26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => GestureDetector(
      onTapDown: (d) {
        final hit = _bubbles
            .where((b) => (b.position - d.localPosition).distance <= b.radius)
            .toList();
        if (hit.isNotEmpty) {
          setState(() {
            _bubbles.remove(hit.first);
            _popped++;
          });
          widget.session.audio.play(
            SoundId.popSmall,
            rate: .9 + _rng.nextDouble() * .25,
          );
          widget.session.haptics.fire(HapticEvent.popSmall);
          widget.session.reportProgress(min(1, _popped / 30));
        } else {
          setState(() => _add(d.localPosition, box.biggest));
        }
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: _BubblePainter(_bubbles),
      ),
    ),
  );
  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.bubbles);
  final List<_Bubble> bubbles;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffdff3fb), Color(0xfff7e5f4)],
        ).createShader(Offset.zero & s),
    );
    for (final b in bubbles) {
      c.drawCircle(b.position, b.radius, Paint()..color = b.color);
      c.drawCircle(
        b.position - Offset(b.radius * .25, b.radius * .28),
        b.radius * .22,
        Paint()..color = Colors.white54,
      );
      c.drawCircle(
        b.position,
        b.radius,
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => true;
}

class _SandGame extends StatefulWidget {
  const _SandGame({required this.session});
  final GameSession session;
  @override
  State<_SandGame> createState() => _SandGameState();
}

class _SandGameState extends State<_SandGame> {
  final paths = <Path>[];
  Path? active;
  Offset? last;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onPanStart: (d) {
      active = Path()..moveTo(d.localPosition.dx, d.localPosition.dy);
      last = d.localPosition;
      setState(() => paths.add(active!));
    },
    onPanUpdate: (d) {
      final p = d.localPosition;
      final l = last;
      if (l != null && active != null) {
        active!.lineTo(p.dx, p.dy);
        last = p;
        widget.session.haptics.fire(HapticEvent.sandTick);
        setState(() {});
      }
    },
    child: CustomPaint(size: Size.infinite, painter: _SandPainter(paths)),
  );
}

class _SandPainter extends CustomPainter {
  _SandPainter(this.paths);
  final List<Path> paths;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xffe8c98c));
    for (final p in paths) {
      c.drawPath(
        p,
        Paint()
          ..color = const Color(0x667a5133)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      c.drawPath(
        p.shift(const Offset(-1.2, -1.2)),
        Paint()
          ..color = const Color(0x66fff2ce)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final p in const [
      Offset(.26, .42),
      Offset(.7, .62),
      Offset(.52, .25),
    ]) {
      c.drawCircle(
        Offset(p.dx * s.width, p.dy * s.height),
        22,
        Paint()..color = const Color(0xff8b7865),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SandPainter old) => true;
}

class _ColorSortGame extends StatefulWidget {
  const _ColorSortGame({required this.session});
  final GameSession session;
  @override
  State<_ColorSortGame> createState() => _ColorSortGameState();
}

class _ColorSortGameState extends State<_ColorSortGame> {
  final colors = const [
    Color(0xfff28b82),
    Color(0xff7fb8f2),
    Color(0xff8bc98a),
  ];
  late List<List<int>> tubes;
  int? selected;
  final history = <List<List<int>>>[];
  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() => tubes = [
    [0, 1, 2, 0],
    [1, 2, 0, 1],
    [2, 0, 1, 2],
    [],
    [],
  ];
  void _tap(int i) {
    if (selected == null) {
      if (tubes[i].isNotEmpty) setState(() => selected = i);
      return;
    }
    if (selected == i) {
      setState(() => selected = null);
      return;
    }
    final a = selected!;
    final src = tubes[a], dst = tubes[i];
    final top = src.last;
    var run = 0;
    for (var j = src.length - 1; j >= 0 && src[j] == top; j--) {
      run++;
    }
    if (dst.length < 4 && (dst.isEmpty || dst.last == top)) {
      history.add(tubes.map((e) => List<int>.from(e)).toList());
      final count = min(run, 4 - dst.length);
      setState(() {
        for (var j = 0; j < count; j++) {
          dst.add(src.removeLast());
        }
        selected = null;
      });
      widget.session.audio.play(SoundId.pourLoop, volume: .45);
      widget.session.haptics.fire(HapticEvent.pourPulse);
      if (_won) {
        widget.session.haptics.fire(HapticEvent.levelComplete);
        widget.session.complete(
          result: const GameResult(seconds: 0, nextLabelKey: 'Next level'),
        );
      }
    } else {
      widget.session.haptics.fire(HapticEvent.invalid);
      setState(() {});
    }
  }

  bool get _won => tubes
      .where((t) => t.isNotEmpty)
      .every((t) => t.length == 4 && t.every((v) => v == t.first));
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff7ecf3),
    body: SafeArea(
      child: Column(
        children: [
          const Spacer(),
          Wrap(
            spacing: 16,
            runSpacing: 28,
            alignment: WrapAlignment.center,
            children: List.generate(
              tubes.length,
              (i) => GestureDetector(
                onTap: () => _tap(i),
                child: _Tube(
                  layers: tubes[i],
                  colors: colors,
                  selected: selected == i,
                ),
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: history.isEmpty
                    ? null
                    : () {
                        setState(() {
                          tubes = history.removeLast();
                          selected = null;
                        });
                      },
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Undo'),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(_reset);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Restart'),
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    ),
  );
}

class _Tube extends StatelessWidget {
  const _Tube({
    required this.layers,
    required this.colors,
    required this.selected,
  });
  final List<int> layers;
  final List<Color> colors;
  final bool selected;
  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: Offset(0, selected ? -14 : 0),
    child: Container(
      width: 48,
      height: 190,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: layers
            .map((i) => Container(height: 39, width: 44, color: colors[i]))
            .toList(),
      ),
    ),
  );
}

class _PlantGame extends StatefulWidget {
  const _PlantGame({required this.session});
  final GameSession session;
  @override
  State<_PlantGame> createState() => _PlantGameState();
}

class _PlantGameState extends State<_PlantGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController clock;
  double moisture = .25, light = .2, growth = 0;
  Duration last = Duration.zero;
  @override
  void initState() {
    super.initState();
    clock = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..forward();
  }

  void _tick() {
    final n = clock.lastElapsedDuration ?? Duration.zero;
    final dt = (n - last).inMicroseconds / 1e6;
    last = n;
    if (dt <= 0) return;
    setState(() {
      moisture = max(0, moisture - .012 * dt);
      light = max(0, light - .02 * dt);
      if (moisture > .25) {
        growth = min(
          1,
          growth + .012 * min(moisture / .9, 1) * (.4 + .6 * light) * dt,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onPanUpdate: (d) {
      setState(() => moisture = min(1, moisture + .012));
      widget.session.haptics.fire(HapticEvent.waterPulse);
    },
    onTapDown: (d) {
      if (d.localPosition.dy < MediaQuery.sizeOf(context).height * .45) {
        setState(() => light = min(1, light + .18));
      }
    },
    child: CustomPaint(
      size: Size.infinite,
      painter: _PlantPainter(growth, moisture, light),
    ),
  );
  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }
}

class _PlantPainter extends CustomPainter {
  _PlantPainter(this.g, this.m, this.l);
  final double g, m, l;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffffefd5), Color(0xffd9ecf5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & s),
    );
    final base = Offset(s.width * .5, s.height * .76);
    c.drawOval(
      Rect.fromCenter(
        center: base + const Offset(0, 48),
        width: 170,
        height: 60,
      ),
      Paint()
        ..color = Color.lerp(
          const Color(0xffb38b63),
          const Color(0xff6b4a32),
          m,
        )!,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: base + const Offset(0, 32),
          width: 140,
          height: 84,
        ),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xffd69d78),
    );
    final h = (250 * min(1, g / .6)).toDouble();
    c.drawLine(
      base,
      base - Offset(0, h),
      Paint()
        ..color = const Color(0xff4e9070)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 1; i < 6; i++) {
      final p = base - Offset(0, h * i / 6);
      final size = 32 * max(0, min(1, (g - i * .1) / .2));
      c.drawOval(
        Rect.fromCenter(
          center: p + Offset(i.isEven ? size * .55 : -size * .55, 0),
          width: size * 1.6,
          height: size * .65,
        ),
        Paint()..color = const Color(0xff6fb38a),
      );
    }
    if (g > .7) {
      final top = base - Offset(0, h);
      for (var i = 0; i < 12; i++) {
        final a = i * pi / 6;
        c.drawOval(
          Rect.fromCenter(
            center: top + Offset(cos(a) * 18, sin(a) * 18),
            width: 22,
            height: 12,
          ),
          Paint()..color = const Color(0xffffd35c),
        );
      }
      c.drawCircle(top, 14, Paint()..color = const Color(0xff7a4b2a));
    }
    c.drawCircle(
      Offset(s.width * .22, s.height * .18),
      22,
      Paint()..color = const Color(0xffffe7a3).withValues(alpha: .45 + .4 * l),
    );
  }

  @override
  bool shouldRepaint(covariant _PlantPainter old) => true;
}
