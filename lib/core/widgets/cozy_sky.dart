import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Twilight sky with stars, a moon and rolling hills.
class CozySkyPainter extends CustomPainter {
  CozySkyPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B1838), Color(0xFF3A2F66), Color(0xFF6A4C83)],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );
    final rng = math.Random(4);
    for (var i = 0; i < 70; i++) {
      final p = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height * 0.7,
      );
      final tw = 0.5 + 0.5 * math.sin(t * (0.6 + rng.nextDouble()) + i);
      canvas.drawCircle(
        p,
        0.6 + rng.nextDouble() * 1.3,
        Paint()..color = Colors.white.withValues(alpha: 0.2 + 0.6 * tw),
      );
    }
    final moon = Offset(size.width * 0.09, size.height * 0.165);
    canvas.drawCircle(
      moon,
      90,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x55FFF1C9), const Color(0x00FFF1C9)],
        ).createShader(Rect.fromCircle(center: moon, radius: 90)),
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moon, radius: 18)),
        Path()..addOval(
          Rect.fromCircle(center: moon + const Offset(7, -4), radius: 15),
        ),
      ),
      Paint()..color = const Color(0xFFFFF1C9),
    );

    void hills(double base, double amp, double phase, Color c) {
      final path = Path()..moveTo(0, size.height);
      for (var i = 0; i <= 30; i++) {
        final x = size.width * i / 30;
        final y =
            size.height * base + math.sin(i / 30 * math.pi * 2 + phase) * amp;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = c);
    }

    hills(0.8, 18, 0.5, const Color(0xFF4E3B6E));
    hills(0.88, 14, 2.1, const Color(0xFF3B2D58));
    // Fireflies.
    for (var i = 0; i < 12; i++) {
      final p = Offset(
        (rng.nextDouble() * size.width + math.sin(t * 0.3 + i) * 20) %
            size.width,
        size.height * (0.72 + rng.nextDouble() * 0.25) +
            math.cos(t * 0.4 + i) * 10,
      );
      final a = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * 1.3 + i * 2));
      canvas.drawCircle(
        p,
        6,
        Paint()..color = const Color(0xFFFFE9A0).withValues(alpha: 0.12 * a),
      );
      canvas.drawCircle(
        p,
        2,
        Paint()..color = const Color(0xFFFFE9A0).withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CozySkyPainter old) => old.t != t;
}

/// Animated cozy sky that fills its parent.
class CozySky extends StatefulWidget {
  const CozySky({super.key});

  @override
  State<CozySky> createState() => _CozySkyState();
}

class _CozySkyState extends State<CozySky> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: CozySkyPainter(t: _c.value * 30),
        size: Size.infinite,
      ),
    );
  }
}

/// The Kalm Corner logo: a round window looking out at a moonlit hill.
class CalmLogo extends StatelessWidget {
  const CalmLogo({this.size = 120, this.t = 0, super.key});
  final double size;
  final double t;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: CalmLogoPainter(t));
}

class CalmLogoPainter extends CustomPainter {
  CalmLogoPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    const wood = Color(0xFFD9A273);
    const woodDark = Color(0xFF9C6B47);
    // Soft glow.
    canvas.drawCircle(
      c,
      r * 1.25,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x55FFE1A8), const Color(0x00FFE1A8)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.25)),
    );
    // Frame base (3D lip).
    canvas.drawCircle(c + Offset(0, r * 0.06), r, Paint()..color = woodDark);
    canvas.drawCircle(c, r, Paint()..color = wood);
    final glassR = r * 0.8;
    final glass = Rect.fromCircle(center: c, radius: glassR);
    canvas.save();
    canvas.clipPath(Path()..addOval(glass));
    canvas.drawRect(
      glass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B2557), Color(0xFF6A4C83), Color(0xFFF2A488)],
          stops: [0, 0.65, 1],
        ).createShader(glass),
    );
    // Stars.
    final rng = math.Random(3);
    for (var i = 0; i < 9; i++) {
      final p =
          c +
          Offset(
            (rng.nextDouble() - 0.5) * glassR * 1.6,
            -rng.nextDouble() * glassR * 0.8,
          );
      final tw = 0.5 + 0.5 * math.sin(t * 2 + i);
      canvas.drawCircle(
        p,
        r * 0.018,
        Paint()..color = Colors.white.withValues(alpha: 0.4 + 0.5 * tw),
      );
    }
    // Moon.
    final moon = c + Offset(glassR * 0.32, -glassR * 0.3);
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: moon, radius: glassR * 0.22)),
      Path()..addOval(
        Rect.fromCircle(
          center: moon + Offset(glassR * 0.09, -glassR * 0.05),
          radius: glassR * 0.18,
        ),
      ),
    );
    canvas.drawPath(crescent, Paint()..color = const Color(0xFFFFF1C9));
    // Hills.
    final hill = Path()..moveTo(glass.left, glass.bottom);
    for (var i = 0; i <= 20; i++) {
      final x = glass.left + glass.width * i / 20;
      hill.lineTo(
        x,
        c.dy +
            glassR * 0.35 +
            math.sin(i / 20 * math.pi * 1.6 + 0.6) * glassR * 0.12,
      );
    }
    hill
      ..lineTo(glass.right, glass.bottom)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF4E7A62));
    final hill2 = Path()..moveTo(glass.left, glass.bottom);
    for (var i = 0; i <= 20; i++) {
      final x = glass.left + glass.width * i / 20;
      hill2.lineTo(
        x,
        c.dy +
            glassR * 0.55 +
            math.sin(i / 20 * math.pi * 2 + 2) * glassR * 0.08,
      );
    }
    hill2
      ..lineTo(glass.right, glass.bottom)
      ..close();
    canvas.drawPath(hill2, Paint()..color = const Color(0xFF36594A));
    canvas.restore();
    // Window cross.
    final bar = Paint()..color = wood;
    canvas.drawRect(
      Rect.fromCenter(center: c, width: r * 0.1, height: glassR * 2),
      bar,
    );
    canvas.drawRect(
      Rect.fromCenter(center: c, width: glassR * 2, height: r * 0.1),
      bar,
    );
    // Glass shine.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: glassR * 0.82),
      math.pi * 1.1,
      math.pi * 0.35,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.06
        ..color = Colors.white.withValues(alpha: 0.22),
    );
    // Rim highlight.
    canvas.drawCircle(
      c,
      r * 0.97,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.04
        ..color = const Color(0xFFF2C9A0),
    );
  }

  @override
  bool shouldRepaint(covariant CalmLogoPainter old) => old.t != t;
}
