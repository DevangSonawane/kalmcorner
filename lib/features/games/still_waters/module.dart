import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:calmcorner/features/levels/level_game.dart';

import 'game.dart';
import 'levels.dart';

class StillWatersModule extends LevelGameModule {
  @override
  String get id => 'still_waters';

  @override
  String get title => 'Still Waters';

  @override
  String get tagline => 'Pour soft colours until every glass is calm.';

  @override
  String get howToPlay =>
      'Tap a glass to pick it up, then tap another glass to pour. '
      'Colour can only pour onto the same colour or into an empty glass. '
      'Fill every glass with a single colour to finish the level.\n\n'
      'Undo is unlimited, Hint shows a good next pour, and once per level '
      'you can add an extra empty glass.';

  @override
  IconData get icon => Icons.water_drop_rounded;

  @override
  List<Color> get gradient => const [Color(0xFF9AD0EC), Color(0xFF6C8FD8)];

  @override
  List<LevelChapter> get chapters => const [
    LevelChapter(name: 'Dawn', first: 1, last: 12, tint: Color(0xFFF2A488)),
    LevelChapter(name: 'Meadow', first: 13, last: 24, tint: Color(0xFF7FB89A)),
    LevelChapter(name: 'Tide', first: 25, last: 36, tint: Color(0xFF5CA8C8)),
    LevelChapter(name: 'Dusk', first: 37, last: 48, tint: Color(0xFF8E7CC3)),
    LevelChapter(name: 'Night', first: 49, last: 60, tint: Color(0xFF5B6AA8)),
  ];

  @override
  int get levelCount => StillWatersLevels.levelCount;

  @override
  Widget buildThumbnail(BuildContext context) =>
      const CustomPaint(painter: _ThumbPainter(), child: SizedBox.expand());

  @override
  Widget buildLevel(BuildContext context, LevelHost host) =>
      StillWatersLevel(host: host, tint: chapterOf(host.level).tint);
}

class _ThumbPainter extends CustomPainter {
  const _ThumbPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      bg,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBFE3F2), Color(0xFF8FB0E8)],
        ).createShader(bg),
    );
    const tubes = [
      [0, 1, 0, 2],
      [1, 1, 2, 0],
      [2, 0, 1, 2],
      <int>[],
    ];
    final w = math.min(size.width / 9, size.height / 4.2);
    final h = w * 3.2;
    final gap = w * 0.8;
    final total = tubes.length * w + (tubes.length - 1) * gap;
    final x0 = (size.width - total) / 2;
    final y0 = (size.height - h) / 2;
    for (var i = 0; i < tubes.length; i++) {
      final x = x0 + i * (w + gap);
      final r = w / 2;
      final path = Path()
        ..moveTo(x, y0)
        ..lineTo(x, y0 + h - r)
        ..arcToPoint(
          Offset(x + w, y0 + h - r),
          radius: Radius.circular(r),
          clockwise: false,
        )
        ..lineTo(x + w, y0)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
      canvas.save();
      canvas.clipPath(path);
      final uh = h / 4.4;
      for (var k = 0; k < tubes[i].length; k++) {
        canvas.drawRect(
          Rect.fromLTWH(x, y0 + h - (k + 1) * uh, w, uh + 1),
          Paint()..color = StillWatersLevels.colorFor(tubes[i][k]),
        );
      }
      canvas.restore();
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
