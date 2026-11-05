import 'package:flutter/material.dart';

import 'package:calmcorner/features/levels/level_game.dart';

import 'game.dart';
import 'levels.dart';
import 'scenes.dart';

class ClearWindowModule extends LevelGameModule {
  @override
  String get id => 'clear_window';

  @override
  String get title => 'Clear Window';

  @override
  String get tagline => 'Wipe the glass and find who is waiting outside.';

  @override
  String get howToPlay =>
      'Drag your finger over the glass to wipe it. Fog clears in one pass; '
      'dust, frost and mud need a few more rubs. A little friend hides in '
      'every view. Wipe their spot to say hello.\n\n'
      'When the window is almost clean, the last smudges polish away by themselves.';

  @override
  IconData get icon => Icons.window_rounded;

  @override
  List<Color> get gradient => const [Color(0xFFF6C29B), Color(0xFFC77D5B)];

  @override
  List<LevelChapter> get chapters => const [
    LevelChapter(
      name: 'Morning Fog',
      first: 1,
      last: 6,
      tint: Color(0xFF8FB8D8),
    ),
    LevelChapter(
      name: 'Dusty Attic',
      first: 7,
      last: 12,
      tint: Color(0xFFC9A16E),
    ),
    LevelChapter(
      name: 'Rainy Days',
      first: 13,
      last: 18,
      tint: Color(0xFF6E8FC4),
    ),
    LevelChapter(
      name: 'First Frost',
      first: 19,
      last: 24,
      tint: Color(0xFF7FB6D9),
    ),
    LevelChapter(
      name: 'Muddy Lane',
      first: 25,
      last: 30,
      tint: Color(0xFFA7805A),
    ),
    LevelChapter(
      name: 'After the Storm',
      first: 31,
      last: 36,
      tint: Color(0xFF8E7CC3),
    ),
  ];

  @override
  int get levelCount => ClearWindowLevels.levelCount;

  @override
  Widget buildThumbnail(BuildContext context) =>
      const CustomPaint(painter: _Thumb(), child: SizedBox.expand());

  @override
  Widget buildLevel(BuildContext context, LevelHost host) =>
      ClearWindowLevel(host: host, tint: chapterOf(host.level).tint);
}

class _Thumb extends CustomPainter {
  const _Thumb();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF3D9C2),
    );
    final h = size.height * 0.78;
    final w = h * 0.8;
    final g = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );
    final scene = ScenePainter(SceneKind.lake, DayTime.dawn, 3);
    scene.paint(canvas, g, 0);
    // Half of the glass still foggy, with a wiped swoosh.
    canvas.save();
    canvas.clipRect(g);
    final fog = Path()
      ..addRect(g)
      ..fillType = PathFillType.evenOdd
      ..addOval(
        Rect.fromCenter(
          center: g.center.translate(-w * 0.05, -h * 0.05),
          width: w * 0.75,
          height: h * 0.45,
        ),
      );
    canvas.drawPath(
      fog,
      Paint()..color = const Color(0xFFF2F5F8).withValues(alpha: 0.8),
    );
    canvas.restore();
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = const Color(0xFFB98A62);
    canvas.drawRRect(
      RRect.fromRectAndRadius(g, const Radius.circular(4)),
      frame,
    );
    canvas.drawLine(
      Offset(g.center.dx, g.top),
      Offset(g.center.dx, g.bottom),
      frame..strokeWidth = 5,
    );
    canvas.drawLine(
      Offset(g.left, g.center.dy),
      Offset(g.right, g.center.dy),
      frame,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
