import 'dart:math';

import 'package:flutter/material.dart';

enum SceneId {
  rainyEvening,
  mistyMorning,
  snowyCabin,
  sunsetBeach,
  nightCity,
  springGarden,
}

enum DirtType { fog, dust, grime, frost, salt, pollen }

enum AmbientEffect { rain, mist, snowflakes, sparkle, butterflies, petals }

class SceneRecipe {
  const SceneRecipe({
    required this.id,
    required this.name,
    required this.free,
    required this.skyStops,
    required this.skyStopsPositions,
    required this.silhouettes,
    required this.accents,
    required this.ambientEffect,
    required this.dirtType,
    required this.dropletRate,
    required this.musicId,
    required this.seed,
    this.premium = false,
    this.muntinCross = false,
  });

  final SceneId id;
  final String name;
  final bool free;
  final List<Color> skyStops;
  final List<double> skyStopsPositions;
  final List<SilhouetteLayer> silhouettes;
  final List<AccentElement> accents;
  final AmbientEffect ambientEffect;
  final DirtType dirtType;
  final double dropletRate;
  final String musicId;
  final int seed;
  final bool premium;
  final bool muntinCross;
}

class SilhouetteLayer {
  const SilhouetteLayer({
    required this.color,
    required this.shapes,
    this.parallax = 0.0,
  });

  final Color color;
  final double parallax;
  final List<SilhouetteShape> shapes;
}

class SilhouetteShape {
  const SilhouetteShape({
    required this.type,
    required this.rect,
    this.color,
    this.points,
  });

  final SilhouetteType type;
  final Rect rect;
  final Color? color;
  final List<Offset>? points;
}

enum SilhouetteType { rect, triangle, ellipse, custom }

class AccentElement {
  const AccentElement({
    required this.type,
    required this.position,
    required this.size,
    required this.color,
    this.alpha = 1.0,
    this.blur = 0.0,
  });

  final AccentType type;
  final Offset position;
  final Size size;
  final Color color;
  final double alpha;
  final double blur;
}

enum AccentType {
  litWindow,
  bokeh,
  sunDisc,
  sunGlow,
  star,
  seaSparkle,
  neon,
  neonGlow,
  blossomCluster,
  butterfly,
  petal,
}

class SceneRegistry {
  static final List<SceneRecipe> _scenes = [
    SceneRecipe(
      id: SceneId.rainyEvening,
      name: 'Rainy Evening',
      free: true,
      skyStops: const [Color(0xFF1B2338), Color(0xFF3C4B73), Color(0xFFE8A27A)],
      skyStopsPositions: const [0.0, 0.62, 1.0],
      silhouettes: [
        SilhouetteLayer(
          color: Color(0xFF232C45),
          parallax: 0.1,
          shapes: _generateBuildings(14, 40, 90, 120, 320, 0),
        ),
        SilhouetteLayer(
          color: Color(0xFF151A28),
          parallax: 0.25,
          shapes: _generateBuildings(14, 40, 90, 120, 320, 1),
        ),
      ],
      accents: [
        ..._generateLitWindows(0.05, Color(0xFFFFD9A0), 0.8),
        ..._generateBokeh(
          28,
          8,
          26,
          [
            Color(0xFFFFB77A),
            Color(0xFFFF8F8F),
            Color(0xFF9CC3FF),
            Color(0xFFFFE29A),
          ],
          0.22,
          0.5,
          2,
        ),
      ],
      ambientEffect: AmbientEffect.rain,
      dirtType: DirtType.fog,
      dropletRate: 6,
      musicId: 'dusk',
      seed: 42,
      premium: false,
    ),
    SceneRecipe(
      id: SceneId.mistyMorning,
      name: 'Misty Morning',
      free: true,
      skyStops: const [Color(0xFFDCE6EA), Color(0xFFF4EBDD)],
      skyStopsPositions: const [0.0, 1.0],
      silhouettes: [
        SilhouetteLayer(
          color: Color(0xFFB9C9C6),
          parallax: 0.05,
          shapes: _generateHillRidges(3, Color(0xFFB9C9C6), 0),
        ),
        SilhouetteLayer(
          color: Color(0xFF98B0AE),
          parallax: 0.1,
          shapes: _generateHillRidges(3, Color(0xFF98B0AE), 1),
        ),
        SilhouetteLayer(
          color: Color(0xFF6F918F),
          parallax: 0.15,
          shapes: _generateHillRidges(3, Color(0xFF6F918F), 2),
        ),
      ],
      accents: [
        AccentElement(
          type: AccentType.sunDisc,
          position: Offset(0.7, 0.3),
          size: Size(92, 92),
          color: Color(0xFFFFF3D6),
        ),
        AccentElement(
          type: AccentType.sunGlow,
          position: Offset(0.7, 0.3),
          size: Size(200, 200),
          color: Color(0xFFFFF3D6),
          alpha: 0.15,
          blur: 50,
        ),
        AccentElement(
          type: AccentType.bokeh,
          position: Offset(0.5, 0.4),
          size: Size(100, 100),
          color: Colors.white,
          alpha: 0.25,
        ),
        AccentElement(
          type: AccentType.bokeh,
          position: Offset(0.3, 0.6),
          size: Size(80, 80),
          color: Colors.white,
          alpha: 0.25,
        ),
      ],
      ambientEffect: AmbientEffect.mist,
      dirtType: DirtType.dust,
      dropletRate: 0,
      musicId: 'dawn',
      seed: 123,
      premium: false,
    ),
    SceneRecipe(
      id: SceneId.snowyCabin,
      name: 'Snowy Cabin',
      free: true,
      skyStops: const [Color(0xFF28365B), Color(0xFF8FA6D1)],
      skyStopsPositions: const [0.0, 1.0],
      silhouettes: [
        SilhouetteLayer(
          color: Color(0xFF1E3B3A),
          parallax: 0.1,
          shapes: _generatePineRows(3, Color(0xFF1E3B3A), 0),
        ),
        SilhouetteLayer(
          color: Color(0xFF2B5150),
          parallax: 0.2,
          shapes: _generatePineRows(3, Color(0xFF2B5150), 1),
        ),
      ],
      accents: [
        AccentElement(
          type: AccentType.litWindow,
          position: Offset(0.5, 0.65),
          size: Size(30, 40),
          color: Color(0xFFFFC978),
        ),
        ..._generateStars(0.33),
      ],
      ambientEffect: AmbientEffect.snowflakes,
      dirtType: DirtType.frost,
      dropletRate: 0,
      musicId: 'moonlit',
      seed: 456,
      premium: false,
    ),
    SceneRecipe(
      id: SceneId.sunsetBeach,
      name: 'Sunset Beach',
      free: false,
      skyStops: const [Color(0xFFFF9E7A), Color(0xFFFFD39A), Color(0xFF7EC8E3)],
      skyStopsPositions: const [0.0, 0.5, 1.0],
      silhouettes: [
        SilhouetteLayer(
          color: Colors.black,
          shapes: [
            SilhouetteShape(
              type: SilhouetteType.custom,
              rect: Rect.fromLTWH(0.1, 0.6, 0.15, 0.4),
              points: _palmPoints(Offset(0.1, 0.6), Size(0.15, 0.4)),
            ),
            SilhouetteShape(
              type: SilhouetteType.custom,
              rect: Rect.fromLTWH(0.75, 0.6, 0.15, 0.4),
              points: _palmPoints(Offset(0.75, 0.6), Size(0.15, 0.4)),
            ),
          ],
        ),
      ],
      accents: [
        AccentElement(
          type: AccentType.sunDisc,
          position: Offset(0.5, 0.35),
          size: Size(120, 120),
          color: Color(0xFFFFD39A),
        ),
        AccentElement(
          type: AccentType.sunGlow,
          position: Offset(0.5, 0.35),
          size: Size(300, 300),
          color: Color(0xFFFFD39A),
          alpha: 0.2,
        ),
        ..._generateSeaSparkles(),
      ],
      ambientEffect: AmbientEffect.sparkle,
      dirtType: DirtType.salt,
      dropletRate: 0,
      musicId: 'dawn',
      seed: 789,
      premium: true,
    ),
    SceneRecipe(
      id: SceneId.nightCity,
      name: 'Night City',
      free: false,
      skyStops: const [Color(0xFF0B1026), Color(0xFF3A1C5C)],
      skyStopsPositions: const [0.0, 1.0],
      silhouettes: [
        SilhouetteLayer(
          color: Color(0xFF151A28),
          parallax: 0.15,
          shapes: _generateBuildings(20, 30, 80, 100, 300, 2),
        ),
      ],
      accents: [..._generateNeonRects(15), ..._generateWetStreetReflections()],
      ambientEffect: AmbientEffect.rain,
      dirtType: DirtType.grime,
      dropletRate: 3,
      musicId: 'dusk',
      seed: 999,
      premium: true,
    ),
    SceneRecipe(
      id: SceneId.springGarden,
      name: 'Spring Garden',
      free: false,
      skyStops: const [Color(0xFFCDEBFF), Color(0xFFF0FFE0)],
      skyStopsPositions: const [0.0, 1.0],
      silhouettes: [
        SilhouetteLayer(
          color: Color(0xFFA8D5A2),
          shapes: [
            SilhouetteShape(
              type: SilhouetteType.rect,
              rect: Rect.fromLTWH(0, 0.8, 1, 0.2),
            ),
          ],
        ),
      ],
      accents: [..._generateBlossomTree(), ..._generateButterflies(2)],
      ambientEffect: AmbientEffect.butterflies,
      dirtType: DirtType.pollen,
      dropletRate: 0,
      musicId: 'garden',
      seed: 111,
      premium: true,
    ),
  ];

  static List<SceneRecipe> get scenes => _scenes;

  static SceneRecipe? getScene(SceneId id) {
    try {
      return _scenes.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<SilhouetteShape> _generateBuildings(
    int count,
    double minW,
    double maxW,
    double minH,
    double maxH,
    int seed,
  ) {
    final rng = Random(seed);
    final shapes = <SilhouetteShape>[];
    double x = 0;
    for (int i = 0; i < count; i++) {
      final w = minW + rng.nextDouble() * (maxW - minW);
      final h = minH + rng.nextDouble() * (maxH - minH);
      shapes.add(
        SilhouetteShape(
          type: SilhouetteType.rect,
          rect: Rect.fromLTWH(x, 1 - h / 1000, w / 1000, h / 1000),
        ),
      );
      x += w / 1000 + rng.nextDouble() * 0.02;
      if (x > 1) x = 0;
    }
    return shapes;
  }

  static List<SilhouetteShape> _generateHillRidges(
    int count,
    Color color,
    int seed,
  ) {
    final rng = Random(seed + color.toARGB32());
    final shapes = <SilhouetteShape>[];
    for (int i = 0; i < count; i++) {
      final points = <Offset>[];
      final baseY = 0.5 + i * 0.1 + rng.nextDouble() * 0.1;
      for (double x = 0; x <= 1; x += 0.02) {
        final y =
            baseY +
            sin(x * 10 + rng.nextDouble() * 5) * 0.03 +
            sin(x * 3 + rng.nextDouble() * 3) * 0.015;
        points.add(Offset(x, y.clamp(0.3, 0.9)));
      }
      points.add(Offset(1, 1));
      points.add(Offset(0, 1));
      shapes.add(
        SilhouetteShape(
          type: SilhouetteType.custom,
          rect: Rect.fromLTWH(0, 0.3, 1, 0.7),
          points: points,
          color: color,
        ),
      );
    }
    return shapes;
  }

  static List<SilhouetteShape> _generatePineRows(
    int count,
    Color color,
    int seed,
  ) {
    final rng = Random(seed + color.toARGB32());
    final shapes = <SilhouetteShape>[];
    for (int row = 0; row < count; row++) {
      final y = 0.4 + row * 0.15 + rng.nextDouble() * 0.1;
      for (int i = 0; i < 8; i++) {
        final x = i * 0.125 + rng.nextDouble() * 0.05;
        final h = 0.15 + rng.nextDouble() * 0.2;
        shapes.add(
          SilhouetteShape(
            type: SilhouetteType.triangle,
            rect: Rect.fromLTWH(x, y - h, 0.1, h),
            color: color,
          ),
        );
      }
    }
    return shapes;
  }

  static List<AccentElement> _generateLitWindows(
    double density,
    Color color,
    double alpha,
  ) {
    final accents = <AccentElement>[];
    final rng = Random(1000);
    for (double x = 0; x < 1; x += 0.05) {
      for (double y = 0.2; y < 0.7; y += 0.05) {
        if (rng.nextDouble() < density) {
          accents.add(
            AccentElement(
              type: AccentType.litWindow,
              position: Offset(x, y),
              size: Size(4, 8),
              color: color,
              alpha: alpha,
            ),
          );
        }
      }
    }
    return accents;
  }

  static List<AccentElement> _generateBokeh(
    int count,
    double minR,
    double maxR,
    List<Color> colors,
    double minAlpha,
    double maxAlpha,
    double blur,
  ) {
    final rng = Random(2000);
    final accents = <AccentElement>[];
    for (int i = 0; i < count; i++) {
      accents.add(
        AccentElement(
          type: AccentType.bokeh,
          position: Offset(rng.nextDouble(), 0.2 + rng.nextDouble() * 0.6),
          size: Size(
            minR + rng.nextDouble() * (maxR - minR),
            minR + rng.nextDouble() * (maxR - minR),
          ),
          color: colors[rng.nextInt(colors.length)],
          alpha: minAlpha + rng.nextDouble() * (maxAlpha - minAlpha),
          blur: blur,
        ),
      );
    }
    return accents;
  }

  static List<Offset> _palmPoints(Offset base, Size size) {
    return [
      Offset(base.dx, base.dy + size.height),
      Offset(base.dx + size.width * 0.5, base.dy),
      Offset(base.dx + size.width, base.dy + size.height),
    ];
  }

  static List<AccentElement> _generateStars(double upperThird) {
    final rng = Random(3000);
    final accents = <AccentElement>[];
    for (int i = 0; i < 60; i++) {
      accents.add(
        AccentElement(
          type: AccentType.star,
          position: Offset(rng.nextDouble(), rng.nextDouble() * upperThird),
          size: Size(2, 2),
          color: Colors.white,
          alpha: 0.5 + rng.nextDouble() * 0.5,
        ),
      );
    }
    return accents;
  }

  static List<AccentElement> _generateSeaSparkles() {
    final rng = Random(4000);
    final accents = <AccentElement>[];
    for (int i = 0; i < 30; i++) {
      accents.add(
        AccentElement(
          type: AccentType.seaSparkle,
          position: Offset(rng.nextDouble(), 0.55 + rng.nextDouble() * 0.4),
          size: Size(3, 3),
          color: Colors.white,
          alpha: 0.3 + rng.nextDouble() * 0.4,
        ),
      );
    }
    return accents;
  }

  static List<AccentElement> _generateNeonRects(int count) {
    final rng = Random(5000);
    final colors = [Color(0xFFFF5FA2), Color(0xFF5FE3FF)];
    final accents = <AccentElement>[];
    for (int i = 0; i < count; i++) {
      accents.add(
        AccentElement(
          type: AccentType.neon,
          position: Offset(
            rng.nextDouble() * 0.8 + 0.1,
            0.2 + rng.nextDouble() * 0.5,
          ),
          size: Size(10 + rng.nextDouble() * 40, 30 + rng.nextDouble() * 100),
          color: colors[rng.nextInt(colors.length)],
          alpha: 0.8,
          blur: 8,
        ),
      );
      accents.add(
        AccentElement(
          type: AccentType.neonGlow,
          position: Offset(
            rng.nextDouble() * 0.8 + 0.1,
            0.7 + rng.nextDouble() * 0.2,
          ),
          size: Size(10 + rng.nextDouble() * 40, 30 + rng.nextDouble() * 100),
          color: colors[rng.nextInt(colors.length)],
          alpha: 0.3,
          blur: 16,
        ),
      );
    }
    return accents;
  }

  static List<AccentElement> _generateWetStreetReflections() {
    final rng = Random(6000);
    final accents = <AccentElement>[];
    for (int i = 0; i < 10; i++) {
      final x = rng.nextDouble();
      accents.add(
        AccentElement(
          type: AccentType.bokeh,
          position: Offset(x, 0.65 + rng.nextDouble() * 0.3),
          size: Size(20, 80),
          color: Colors.white,
          alpha: 0.1,
          blur: 4,
        ),
      );
    }
    return accents;
  }

  static List<AccentElement> _generateBlossomTree() {
    final rng = Random(7000);
    final accents = <AccentElement>[];
    for (int cluster = 0; cluster < 8; cluster++) {
      final cx = 0.2 + cluster * 0.1;
      for (int i = 0; i < 12; i++) {
        final angle = rng.nextDouble() * 2 * pi;
        final r = 0.05 + rng.nextDouble() * 0.1;
        accents.add(
          AccentElement(
            type: AccentType.blossomCluster,
            position: Offset(cx + cos(angle) * r, 0.3 + sin(angle) * r),
            size: Size(6, 6),
            color: Color(0xFFFFC4D6),
            alpha: 0.8,
          ),
        );
      }
    }
    return accents;
  }

  static List<AccentElement> _generateButterflies(int count) {
    final rng = Random(8000);
    final accents = <AccentElement>[];
    for (int i = 0; i < count; i++) {
      accents.add(
        AccentElement(
          type: AccentType.butterfly,
          position: Offset(rng.nextDouble(), 0.2 + rng.nextDouble() * 0.4),
          size: Size(20, 15),
          color: Colors.white,
          alpha: 0.9,
        ),
      );
    }
    return accents;
  }
}
