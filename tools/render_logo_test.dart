// Renders brand images from the in-app CalmLogo:
//   assets/brand/splash_logo_1152.png  native splash
//   assets/brand/icon_1024.png         app icon (iOS, web, desktop, legacy Android)
//   assets/brand/icon_fg_1024.png      Android adaptive foreground
//   assets/brand/icon_bg_1024.png      Android adaptive background
//   assets/brand/icon_mono_1024.png    Android 13 themed (monochrome) icon
// Run: flutter test tools/render_logo_test.dart && dart run flutter_launcher_icons
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/core/widgets/cozy_sky.dart';

class _NightBg extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B1838), Color(0xFF3A2F66), Color(0xFF6A4C83)],
          stops: [0, 0.6, 1],
        ).createShader(r),
    );
    final rng = math.Random(9);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height * 0.8),
        size.width * (0.002 + rng.nextDouble() * 0.004),
        Paint()..color = Colors.white.withValues(alpha: 0.25 + rng.nextDouble() * 0.5),
      );
    }
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width * 0.45,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x33FFE1A8), const Color(0x00FFE1A8)],
        ).createShader(Rect.fromCircle(center: size.center(Offset.zero), radius: size.width * 0.45)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Mono extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.28;
    final white = Paint()..color = Colors.white;
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: c, radius: r))
      ..addOval(Rect.fromCircle(center: c, radius: r * 0.8));
    canvas.drawPath(path, white);
    canvas.drawRect(Rect.fromCenter(center: c, width: r * 0.1, height: r * 1.6), white);
    canvas.drawRect(Rect.fromCenter(center: c, width: r * 1.6, height: r * 0.1), white);
    final moonC = c + Offset(r * 0.38, -r * 0.36);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moonC, radius: r * 0.2)),
        Path()..addOval(Rect.fromCircle(center: moonC + Offset(r * 0.08, -r * 0.05), radius: r * 0.16)),
      ),
      white,
    );
    final hill = Path()..moveTo(c.dx - r * 0.8, c.dy + r * 0.8);
    for (var i = 0; i <= 20; i++) {
      final x = c.dx - r * 0.8 + r * 1.6 * i / 20;
      hill.lineTo(x, c.dy + r * 0.35 + math.sin(i / 20 * math.pi * 1.6 + 0.6) * r * 0.1);
    }
    hill.lineTo(c.dx + r * 0.8, c.dy + r * 0.8);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.8)));
    canvas.drawPath(hill..close(), white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _render(WidgetTester tester, double size, Widget child, String path) async {
  final key = GlobalKey();
  tester.view.physicalSize = Size(size, size);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    Center(
      child: RepaintBoundary(
        key: key,
        child: SizedBox(width: size, height: size, child: child),
      ),
    ),
  );
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('render brand images', (tester) async {
    // Android 12 shows the splash icon inside a circle ~2/3 of the image.
    await _render(tester, 1152, const Center(child: CalmLogo(size: 560, t: 1)),
        'assets/brand/splash_logo_1152.png');
    await _render(
      tester,
      1024,
      Stack(textDirection: TextDirection.ltr, fit: StackFit.expand, children: [
        CustomPaint(painter: _NightBg()),
        const Center(child: CalmLogo(size: 700, t: 1)),
      ]),
      'assets/brand/icon_1024.png',
    );
    // Adaptive icons: keep the art inside the central 66% safe zone.
    await _render(tester, 1024, const Center(child: CalmLogo(size: 560, t: 1)),
        'assets/brand/icon_fg_1024.png');
    await _render(tester, 1024, CustomPaint(painter: _NightBg()),
        'assets/brand/icon_bg_1024.png');
    await _render(tester, 1024, CustomPaint(painter: _Mono()),
        'assets/brand/icon_mono_1024.png');
  });
}
