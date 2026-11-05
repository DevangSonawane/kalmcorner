import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Time of day changes the sky and light of every scene.
enum DayTime { dawn, day, dusk, night }

enum SceneKind { lake, sea, meadow, city, snow, forest }

enum FriendKind { duck, crab, cat, owl, fox, bird }

class SkyLook {
  const SkyLook(this.top, this.bottom, this.sun, this.tint, this.isNight);
  final Color top;
  final Color bottom;
  final Color sun;
  final Color tint; // multiplied into the landscape
  final bool isNight;
}

const _skies = {
  DayTime.dawn: SkyLook(
    Color(0xFFF7B9A8),
    Color(0xFFFDE3C4),
    Color(0xFFFFF1D6),
    Color(0xFFF6C9B8),
    false,
  ),
  DayTime.day: SkyLook(
    Color(0xFF8CC8F0),
    Color(0xFFDDF1FB),
    Color(0xFFFFFBE8),
    Color(0xFFFFFFFF),
    false,
  ),
  DayTime.dusk: SkyLook(
    Color(0xFF6E5A9E),
    Color(0xFFF5A77E),
    Color(0xFFFFD39A),
    Color(0xFFC9A3C9),
    false,
  ),
  DayTime.night: SkyLook(
    Color(0xFF151A3A),
    Color(0xFF3A3F72),
    Color(0xFFF4F1DA),
    Color(0xFF6A72A8),
    true,
  ),
};

/// Where the hidden friend sits, in 0..1 coordinates of the window.
class FriendSpot {
  const FriendSpot(this.kind, this.pos, this.size);
  final FriendKind kind;
  final Offset pos;
  final double size; // fraction of window width
}

/// Paints one window scene. [t] is seconds, used for gentle motion.
class ScenePainter {
  ScenePainter(this.kind, this.time, this.seed);

  final SceneKind kind;
  final DayTime time;
  final int seed;

  SkyLook get sky => _skies[time]!;

  static FriendSpot friendFor(SceneKind kind, int variant) {
    final v = variant % 2;
    return switch (kind) {
      SceneKind.lake => FriendSpot(
        FriendKind.duck,
        v == 0 ? const Offset(0.3, 0.78) : const Offset(0.7, 0.82),
        0.12,
      ),
      SceneKind.sea => FriendSpot(
        FriendKind.crab,
        v == 0 ? const Offset(0.22, 0.9) : const Offset(0.75, 0.88),
        0.12,
      ),
      SceneKind.meadow => FriendSpot(
        FriendKind.cat,
        v == 0 ? const Offset(0.78, 0.7) : const Offset(0.2, 0.72),
        0.14,
      ),
      SceneKind.city => FriendSpot(
        FriendKind.bird,
        v == 0 ? const Offset(0.28, 0.43) : const Offset(0.72, 0.38),
        0.1,
      ),
      SceneKind.snow => FriendSpot(
        FriendKind.fox,
        v == 0 ? const Offset(0.7, 0.86) : const Offset(0.3, 0.88),
        0.15,
      ),
      SceneKind.forest => FriendSpot(
        FriendKind.owl,
        v == 0 ? const Offset(0.2, 0.42) : const Offset(0.8, 0.48),
        0.12,
      ),
    };
  }

  Color _lit(Color c) => Color.lerp(c, sky.tint, sky.isNight ? 0.55 : 0.18)!;

  void paint(
    Canvas canvas,
    Rect r,
    double t, {
    FriendSpot? friend,
    double found = 0,
  }) {
    canvas.save();
    canvas.clipRect(r);
    canvas.translate(r.left, r.top);
    final s = r.size;
    _paintSky(canvas, s, t);
    switch (kind) {
      case SceneKind.lake:
        _lake(canvas, s, t);
      case SceneKind.sea:
        _sea(canvas, s, t);
      case SceneKind.meadow:
        _meadow(canvas, s, t);
      case SceneKind.city:
        _city(canvas, s, t);
      case SceneKind.snow:
        _snow(canvas, s, t);
      case SceneKind.forest:
        _forest(canvas, s, t);
    }
    if (friend != null) {
      paintFriend(
        canvas,
        friend.kind,
        Offset(friend.pos.dx * s.width, friend.pos.dy * s.height),
        friend.size * s.width,
        t,
        found,
      );
    }
    canvas.restore();
  }

  // ---------------------------------------------------------------- sky --
  void _paintSky(Canvas canvas, Size s, double t) {
    final rect = Offset.zero & s;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky.top, sky.bottom],
        ).createShader(rect),
    );
    final rng = math.Random(seed);
    if (sky.isNight) {
      for (var i = 0; i < 60; i++) {
        final p = Offset(
          rng.nextDouble() * s.width,
          rng.nextDouble() * s.height * 0.55,
        );
        final tw = 0.5 + 0.5 * math.sin(t * (1 + rng.nextDouble() * 2) + i);
        canvas.drawCircle(
          p,
          0.6 + rng.nextDouble() * 1.2,
          Paint()..color = Colors.white.withValues(alpha: 0.35 + 0.5 * tw),
        );
      }
    }
    // Sun or moon.
    final sunPos = Offset(
      s.width * (time == DayTime.dawn ? 0.25 : 0.72),
      s.height * (time == DayTime.day ? 0.14 : 0.3),
    );
    final sr = s.width * 0.09;
    canvas.drawCircle(
      sunPos,
      sr * 2.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            sky.sun.withValues(alpha: 0.5),
            sky.sun.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sunPos, radius: sr * 2.6)),
    );
    canvas.drawCircle(sunPos, sr, Paint()..color = sky.sun);
    if (sky.isNight) {
      canvas.drawCircle(
        sunPos + Offset(sr * 0.45, -sr * 0.2),
        sr * 0.85,
        Paint()..color = sky.top.withValues(alpha: 0.85),
      );
    }
    // Drifting clouds.
    final cloud = Paint()
      ..color = Colors.white.withValues(alpha: sky.isNight ? 0.12 : 0.65);
    for (var i = 0; i < 3; i++) {
      final y = s.height * (0.08 + 0.1 * i + rng.nextDouble() * 0.05);
      final w = s.width * (0.25 + rng.nextDouble() * 0.2);
      final x =
          ((rng.nextDouble() * s.width + t * (6 + i * 3)) % (s.width + w)) - w;
      _cloud(canvas, Offset(x, y), w, cloud);
    }
  }

  void _cloud(Canvas canvas, Offset o, double w, Paint p) {
    canvas.drawOval(Rect.fromLTWH(o.dx, o.dy, w, w * 0.22), p);
    canvas.drawOval(
      Rect.fromLTWH(o.dx + w * 0.15, o.dy - w * 0.1, w * 0.45, w * 0.28),
      p,
    );
    canvas.drawOval(
      Rect.fromLTWH(o.dx + w * 0.45, o.dy - w * 0.06, w * 0.35, w * 0.22),
      p,
    );
  }

  Path _hills(Size s, double base, double amp, double phase) {
    final path = Path()..moveTo(0, s.height);
    for (var i = 0; i <= 40; i++) {
      final x = s.width * i / 40;
      final y =
          s.height *
          (base +
              amp * math.sin(i / 40 * math.pi * 2 + phase) * 0.5 +
              amp * 0.3 * math.sin(i / 40 * math.pi * 5 + phase * 2));
      path.lineTo(x, y);
    }
    path.lineTo(s.width, s.height);
    path.close();
    return path;
  }

  void _pine(Canvas canvas, Offset base, double h, Color c) {
    final p = Paint()..color = c;
    for (var k = 0; k < 3; k++) {
      final w = h * (0.42 - k * 0.09);
      final top = base.dy - h * (0.35 + k * 0.28);
      final bottom = base.dy - h * (k * 0.25);
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, top - h * 0.1)
          ..lineTo(base.dx - w / 2, bottom)
          ..lineTo(base.dx + w / 2, bottom)
          ..close(),
        p,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(base.dx - h * 0.03, base.dy - h * 0.05, h * 0.06, h * 0.08),
      Paint()..color = const Color(0xFF6B4A35),
    );
  }

  // -------------------------------------------------------------- scenes --
  void _lake(Canvas canvas, Size s, double t) {
    final far = _lit(const Color(0xFFA9B7D8));
    final mid = _lit(const Color(0xFF7D93C2));
    canvas.drawPath(_mountains(s, 0.52, 0.28, 1), Paint()..color = far);
    canvas.drawPath(_mountains(s, 0.6, 0.2, 2), Paint()..color = mid);
    // Snow caps on far range.
    // Lake.
    final lake = Rect.fromLTWH(0, s.height * 0.62, s.width, s.height * 0.38);
    canvas.drawRect(
      lake,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _lit(const Color(0xFF8FC3E3)),
            _lit(const Color(0xFF4F87B8)),
          ],
        ).createShader(lake),
    );
    final shimmer = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final rng = math.Random(seed + 9);
    for (var i = 0; i < 14; i++) {
      final y = s.height * (0.65 + rng.nextDouble() * 0.33);
      final x = (rng.nextDouble() * s.width + math.sin(t * 0.6 + i) * 6);
      final w = 8 + rng.nextDouble() * 18;
      canvas.drawLine(Offset(x, y), Offset(x + w, y), shimmer);
    }
    final pine = _lit(const Color(0xFF2F5D4E));
    for (var i = 0; i < 5; i++) {
      _pine(
        canvas,
        Offset(s.width * (0.02 + i * 0.06), s.height * 0.66),
        s.height * (0.16 + (i % 2) * 0.04),
        pine,
      );
    }
    for (var i = 0; i < 3; i++) {
      _pine(
        canvas,
        Offset(s.width * (0.84 + i * 0.07), s.height * 0.65),
        s.height * (0.14 + (i % 2) * 0.05),
        pine,
      );
    }
    // Little boat bobbing.
    final bob = math.sin(t * 1.2) * 2;
    final bx = s.width * 0.6, by = s.height * 0.72 + bob;
    canvas.drawPath(
      Path()
        ..moveTo(bx - 22, by)
        ..lineTo(bx + 22, by)
        ..lineTo(bx + 14, by + 9)
        ..lineTo(bx - 14, by + 9)
        ..close(),
      Paint()..color = _lit(const Color(0xFFB0643E)),
    );
    canvas.drawLine(
      Offset(bx, by),
      Offset(bx, by - 30),
      Paint()
        ..color = const Color(0xFF6B4A35)
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(bx + 1, by - 30)
        ..lineTo(bx + 18, by - 6)
        ..lineTo(bx + 1, by - 6)
        ..close(),
      Paint()..color = _lit(const Color(0xFFFFF6E8)),
    );
  }

  Path _mountains(Size s, double base, double amp, int off) {
    final rng = math.Random(seed * 3 + off);
    final path = Path()..moveTo(0, s.height);
    path.lineTo(0, s.height * base);
    var x = 0.0;
    while (x < s.width) {
      final w = s.width * (0.18 + rng.nextDouble() * 0.2);
      final h = s.height * amp * (0.5 + rng.nextDouble() * 0.5);
      path.lineTo(x + w / 2, s.height * base - h);
      path.lineTo(x + w, s.height * base);
      x += w * 0.8;
    }
    path.lineTo(s.width, s.height);
    path.close();
    return path;
  }

  void _sea(Canvas canvas, Size s, double t) {
    final horizon = s.height * 0.55;
    final sea = Rect.fromLTWH(0, horizon, s.width, s.height * 0.3);
    canvas.drawRect(
      sea,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _lit(const Color(0xFF5FA8D3)),
            _lit(const Color(0xFF3B7FB0)),
          ],
        ).createShader(sea),
    );
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (var row = 0; row < 5; row++) {
      final y = horizon + 10 + row * s.height * 0.05;
      final path = Path()..moveTo(0, y);
      for (var i = 0; i <= 30; i++) {
        final x = s.width * i / 30;
        path.lineTo(x, y + math.sin(i * 0.9 + t * 1.3 + row) * 2.5);
      }
      canvas.drawPath(path, wave);
    }
    // Sand.
    final sand = Path()
      ..moveTo(0, s.height * 0.82)
      ..quadraticBezierTo(
        s.width * 0.5,
        s.height * 0.76,
        s.width,
        s.height * 0.84,
      )
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(sand, Paint()..color = _lit(const Color(0xFFEBD3A6)));
    // Foam edge.
    final foamY = s.height * 0.81 + math.sin(t * 0.8) * 3;
    canvas.drawPath(
      Path()
        ..moveTo(0, foamY)
        ..quadraticBezierTo(
          s.width * 0.5,
          foamY - s.height * 0.05,
          s.width,
          foamY + 6,
        ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Lighthouse on a rock.
    final lx = s.width * 0.8, ly = horizon + 4;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(lx, ly + 6), width: 70, height: 22),
      Paint()..color = _lit(const Color(0xFF6E6A73)),
    );
    final tower = Path()
      ..moveTo(lx - 12, ly)
      ..lineTo(lx - 8, ly - 70)
      ..lineTo(lx + 8, ly - 70)
      ..lineTo(lx + 12, ly)
      ..close();
    canvas.drawPath(tower, Paint()..color = _lit(const Color(0xFFFFF8EE)));
    for (var k = 0; k < 3; k++) {
      canvas.drawRect(
        Rect.fromLTWH(lx - 11 + k * 1.2, ly - 18 - k * 22, 22 - k * 2.4, 8),
        Paint()..color = _lit(const Color(0xFFE0645A)),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(lx - 9, ly - 82, 18, 12),
      Paint()..color = const Color(0xFFFFE9A8),
    );
    if (sky.isNight || time == DayTime.dusk) {
      final a = (math.sin(t * 1.5) * 0.5 + 0.5) * 0.35;
      canvas.drawPath(
        Path()
          ..moveTo(lx, ly - 76)
          ..lineTo(lx - s.width * 0.6, ly - 100)
          ..lineTo(lx - s.width * 0.6, ly - 52)
          ..close(),
        Paint()..color = const Color(0xFFFFF0B8).withValues(alpha: a),
      );
    }
    // Gulls.
    final gull = Paint()
      ..color = _lit(const Color(0xFF4A4A5A))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final gx = (s.width * (0.15 + i * 0.18) + t * 8) % s.width;
      final gy = s.height * (0.22 + i * 0.05) + math.sin(t + i) * 4;
      final flap = math.sin(t * 4 + i) * 3;
      canvas.drawPath(
        Path()
          ..moveTo(gx - 7, gy - flap)
          ..quadraticBezierTo(gx - 3, gy - 4, gx, gy)
          ..quadraticBezierTo(gx + 3, gy - 4, gx + 7, gy - flap),
        gull,
      );
    }
  }

  void _meadow(Canvas canvas, Size s, double t) {
    canvas.drawPath(
      _hills(s, 0.58, 0.06, seed * 0.3),
      Paint()..color = _lit(const Color(0xFFA7D59A)),
    );
    canvas.drawPath(
      _hills(s, 0.7, 0.05, seed * 0.7 + 2),
      Paint()..color = _lit(const Color(0xFF7FC27A)),
    );
    // Cottage.
    final cx = s.width * 0.42, cy = s.height * 0.68;
    final w = s.width * 0.3, h = s.width * 0.2;
    canvas.drawRect(
      Rect.fromLTWH(cx - w / 2, cy - h, w, h),
      Paint()..color = _lit(const Color(0xFFFFF1DC)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.62, cy - h)
        ..lineTo(cx, cy - h - w * 0.42)
        ..lineTo(cx + w * 0.62, cy - h)
        ..close(),
      Paint()..color = _lit(const Color(0xFFCB6F5A)),
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.1, cy - h * 0.55, w * 0.2, h * 0.55),
      Paint()..color = _lit(const Color(0xFF8A5A44)),
    );
    final windowLit = sky.isNight || time == DayTime.dusk;
    final winC = windowLit
        ? const Color(0xFFFFD98A)
        : _lit(const Color(0xFF9CC7E6));
    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.38, cy - h * 0.75, w * 0.18, h * 0.3),
      Paint()..color = winC,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx + w * 0.2, cy - h * 0.75, w * 0.18, h * 0.3),
      Paint()..color = winC,
    );
    // Chimney smoke.
    for (var k = 0; k < 4; k++) {
      final f = (t * 0.25 + k * 0.25) % 1.0;
      canvas.drawCircle(
        Offset(cx + w * 0.3 + math.sin(f * 4) * 6, cy - h - w * 0.3 - f * 50),
        4 + f * 8,
        Paint()..color = Colors.white.withValues(alpha: 0.45 * (1 - f)),
      );
    }
    // Fence.
    final fence = Paint()
      ..color = _lit(const Color(0xFFE9DCC4))
      ..strokeWidth = 3;
    final fy = s.height * 0.76;
    canvas.drawLine(Offset(s.width * 0.6, fy), Offset(s.width, fy), fence);
    canvas.drawLine(
      Offset(s.width * 0.6, fy + 10),
      Offset(s.width, fy + 10),
      fence,
    );
    for (var x = s.width * 0.62; x < s.width; x += 16) {
      canvas.drawLine(Offset(x, fy - 8), Offset(x, fy + 18), fence);
    }
    // Flowers.
    final rng = math.Random(seed + 4);
    const petals = [
      Color(0xFFF4A6B8),
      Color(0xFFFFE08A),
      Color(0xFFFFFFFF),
      Color(0xFFB79DF2),
    ];
    for (var i = 0; i < 26; i++) {
      final p = Offset(
        rng.nextDouble() * s.width,
        s.height * (0.8 + rng.nextDouble() * 0.18),
      );
      final sway = math.sin(t * 1.5 + i) * 1.5;
      canvas.drawCircle(
        p + Offset(sway, 0),
        3,
        Paint()..color = _lit(petals[i % petals.length]),
      );
    }
  }

  void _city(Canvas canvas, Size s, double t) {
    final rng = math.Random(seed + 11);
    final layers = [
      (_lit(const Color(0xFF9AA5C9)), 0.35, 0.55),
      (_lit(const Color(0xFF6C779F)), 0.45, 0.68),
    ];
    for (final (color, minTop, maxTop) in layers) {
      var x = -10.0;
      while (x < s.width) {
        final w = s.width * (0.1 + rng.nextDouble() * 0.12);
        final top = s.height * (minTop + rng.nextDouble() * (maxTop - minTop));
        canvas.drawRect(
          Rect.fromLTWH(x, top, w, s.height - top),
          Paint()..color = color,
        );
        // Windows.
        for (var wy = top + 8; wy < s.height - 8; wy += 14) {
          for (var wx = x + 5; wx < x + w - 8; wx += 11) {
            final lit = rng.nextDouble() < (sky.isNight ? 0.45 : 0.15);
            final flicker = sky.isNight && rng.nextDouble() < 0.05
                ? (math.sin(t * 2 + wx) > 0 ? 1.0 : 0.3)
                : 1.0;
            canvas.drawRect(
              Rect.fromLTWH(wx, wy, 5, 7),
              Paint()
                ..color = lit
                    ? const Color(0xFFFFE3A0).withValues(alpha: 0.9 * flicker)
                    : Colors.white.withValues(alpha: 0.12),
            );
          }
        }
        x += w + 2;
      }
    }
    // Rooftop with water tower in front.
    final roofY = s.height * 0.82;
    canvas.drawRect(
      Rect.fromLTWH(0, roofY, s.width, s.height - roofY),
      Paint()..color = _lit(const Color(0xFF4B4F6E)),
    );
    final tx = s.width * 0.18;
    canvas.drawRect(
      Rect.fromLTWH(tx, roofY - 46, 34, 30),
      Paint()..color = _lit(const Color(0xFF8A6A55)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(tx - 3, roofY - 46)
        ..lineTo(tx + 17, roofY - 60)
        ..lineTo(tx + 37, roofY - 46)
        ..close(),
      Paint()..color = _lit(const Color(0xFF6B4F40)),
    );
    final leg = Paint()
      ..color = _lit(const Color(0xFF3B3E57))
      ..strokeWidth = 2;
    canvas.drawLine(Offset(tx + 4, roofY - 16), Offset(tx + 2, roofY), leg);
    canvas.drawLine(Offset(tx + 30, roofY - 16), Offset(tx + 32, roofY), leg);
    // String lights.
    final bulbs = Path()..moveTo(s.width * 0.45, roofY - 30);
    bulbs.quadraticBezierTo(s.width * 0.72, roofY - 10, s.width, roofY - 34);
    canvas.drawPath(
      bulbs,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < 8; i++) {
      final f = i / 7;
      final bx = s.width * (0.45 + 0.55 * f);
      final by = roofY - 30 + 20 * math.sin(f * math.pi) - 4 * f;
      final glow = 0.6 + 0.4 * math.sin(t * 2 + i);
      canvas.drawCircle(
        Offset(bx, by + 3),
        2.5,
        Paint()..color = const Color(0xFFFFD27A).withValues(alpha: glow),
      );
    }
  }

  void _snow(Canvas canvas, Size s, double t) {
    canvas.drawPath(
      _mountains(s, 0.55, 0.22, 5),
      Paint()..color = _lit(const Color(0xFFDDE6F3)),
    );
    canvas.drawPath(
      _hills(s, 0.72, 0.05, seed * 0.5),
      Paint()..color = _lit(const Color(0xFFF4F7FC)),
    );
    final pine = _lit(const Color(0xFF3E6B5E));
    for (var i = 0; i < 6; i++) {
      final x = s.width * (0.05 + i * 0.17);
      _pine(
        canvas,
        Offset(x, s.height * (0.72 + (i % 2) * 0.02)),
        s.height * 0.13,
        pine,
      );
      // Snow on tree tip.
      canvas.drawCircle(
        Offset(x, s.height * (0.72 + (i % 2) * 0.02) - s.height * 0.13 * 1.05),
        3,
        Paint()..color = Colors.white,
      );
    }
    // Two cabins.
    for (final (fx, scale) in [(0.32, 1.0), (0.66, 0.8)]) {
      final cx = s.width * fx, cy = s.height * 0.8;
      final w = s.width * 0.2 * scale, h = s.width * 0.13 * scale;
      canvas.drawRect(
        Rect.fromLTWH(cx - w / 2, cy - h, w, h),
        Paint()..color = _lit(const Color(0xFFA0674A)),
      );
      canvas.drawPath(
        Path()
          ..moveTo(cx - w * 0.65, cy - h)
          ..lineTo(cx, cy - h - w * 0.45)
          ..lineTo(cx + w * 0.65, cy - h)
          ..close(),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromLTWH(cx - w * 0.15, cy - h * 0.7, w * 0.3, h * 0.35),
        Paint()..color = const Color(0xFFFFD98A),
      );
    }
    // Falling snow.
    final rng = math.Random(seed + 2);
    final flake = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (var i = 0; i < 50; i++) {
      final speed = 10 + rng.nextDouble() * 18;
      final x =
          (rng.nextDouble() * s.width + math.sin(t * 0.7 + i) * 8) % s.width;
      final y = (rng.nextDouble() * s.height + t * speed) % s.height;
      canvas.drawCircle(Offset(x, y), 1 + rng.nextDouble() * 1.6, flake);
    }
  }

  void _forest(Canvas canvas, Size s, double t) {
    final back = _lit(const Color(0xFF7FA88C));
    final mid = _lit(const Color(0xFF4F7F64));
    for (var i = 0; i < 9; i++) {
      _pine(
        canvas,
        Offset(s.width * (i / 8), s.height * 0.62),
        s.height * 0.3,
        back,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, s.height * 0.62, s.width, s.height * 0.38),
      Paint()..color = _lit(const Color(0xFF9CC48A)),
    );
    // Sunbeams.
    if (!sky.isNight) {
      for (var i = 0; i < 3; i++) {
        final x = s.width * (0.2 + i * 0.25);
        final a = 0.12 + 0.06 * math.sin(t * 0.5 + i);
        canvas.drawPath(
          Path()
            ..moveTo(x, 0)
            ..lineTo(x + 30, 0)
            ..lineTo(x + 110, s.height)
            ..lineTo(x + 50, s.height)
            ..close(),
          Paint()..color = sky.sun.withValues(alpha: a),
        );
      }
    }
    // Two big trunks.
    final trunk = _lit(const Color(0xFF7A5641));
    canvas.drawRect(
      Rect.fromLTWH(
        s.width * 0.12,
        s.height * 0.28,
        s.width * 0.11,
        s.height * 0.6,
      ),
      Paint()..color = trunk,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        s.width * 0.74,
        s.height * 0.32,
        s.width * 0.12,
        s.height * 0.56,
      ),
      Paint()..color = trunk,
    );
    canvas.drawCircle(
      Offset(s.width * 0.175, s.height * 0.26),
      s.width * 0.2,
      Paint()..color = mid,
    );
    canvas.drawCircle(
      Offset(s.width * 0.8, s.height * 0.3),
      s.width * 0.22,
      Paint()..color = mid,
    );
    // Mushrooms.
    for (final fx in [0.4, 0.47, 0.6]) {
      final p = Offset(s.width * fx, s.height * 0.86);
      canvas.drawRect(
        Rect.fromCenter(center: p, width: 5, height: 12),
        Paint()..color = const Color(0xFFFFF4E0),
      );
      canvas.drawArc(
        Rect.fromCenter(center: p - const Offset(0, 6), width: 18, height: 14),
        math.pi,
        math.pi,
        true,
        Paint()..color = _lit(const Color(0xFFE0645A)),
      );
    }
    // Fireflies at dusk and night, pollen by day.
    final rng = math.Random(seed + 8);
    for (var i = 0; i < 18; i++) {
      final p = Offset(
        rng.nextDouble() * s.width + math.sin(t * 0.8 + i) * 10,
        s.height * (0.4 + rng.nextDouble() * 0.5) + math.cos(t * 0.6 + i) * 8,
      );
      final glow = sky.isNight || time == DayTime.dusk;
      final a = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(t * 2 + i * 1.7));
      canvas.drawCircle(
        p,
        glow ? 2.2 : 1.4,
        Paint()
          ..color = (glow ? const Color(0xFFFFF0A0) : Colors.white).withValues(
            alpha: a * (glow ? 1 : 0.6),
          ),
      );
    }
  }
}

/// Small friendly creatures hidden in each scene.
void paintFriend(
  Canvas canvas,
  FriendKind kind,
  Offset c,
  double size,
  double t,
  double found,
) {
  final hop = found > 0 ? math.sin(found * math.pi) * size * 0.25 : 0.0;
  canvas.save();
  canvas.translate(c.dx, c.dy - hop);
  final s = size;
  final eye = Paint()..color = const Color(0xFF2B2530);
  void eyes(double dx, double y, double r) {
    canvas.drawCircle(Offset(-dx, y), r, eye);
    canvas.drawCircle(Offset(dx, y), r, eye);
  }

  switch (kind) {
    case FriendKind.duck:
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.5),
        Paint()..color = const Color(0xFFFFE08A),
      );
      canvas.drawCircle(
        Offset(s * 0.32, -s * 0.28),
        s * 0.22,
        Paint()..color = const Color(0xFFFFE08A),
      );
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.5, -s * 0.3)
          ..lineTo(s * 0.7, -s * 0.25)
          ..lineTo(s * 0.5, -s * 0.2)
          ..close(),
        Paint()..color = const Color(0xFFF2A46B),
      );
      canvas.drawCircle(Offset(s * 0.38, -s * 0.33), s * 0.035, eye);
    case FriendKind.crab:
      final body = Paint()..color = const Color(0xFFE8705E);
      final legs = Paint()
        ..color = const Color(0xFFE8705E)
        ..strokeWidth = s * 0.06
        ..strokeCap = StrokeCap.round;
      final wave = math.sin(t * 3) * 0.2;
      for (final side in [-1.0, 1.0]) {
        for (var k = 0; k < 3; k++) {
          canvas.drawLine(
            Offset(side * s * 0.2, s * 0.05),
            Offset(side * s * 0.48, s * (0.1 + k * 0.08)),
            legs,
          );
        }
        canvas.save();
        canvas.translate(side * s * 0.38, -s * 0.18);
        canvas.rotate(side * (0.4 + wave));
        canvas.drawCircle(Offset.zero, s * 0.12, body);
        canvas.restore();
      }
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * 0.7, height: s * 0.42),
        body,
      );
      eyes(s * 0.1, -s * 0.12, s * 0.045);
    case FriendKind.cat:
      final fur = Paint()..color = const Color(0xFFF2A46B);
      final tail = math.sin(t * 2) * s * 0.1;
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.25, s * 0.1)
          ..quadraticBezierTo(
            s * 0.6,
            -s * 0.05 + tail,
            s * 0.5,
            -s * 0.35 + tail,
          ),
        Paint()
          ..color = const Color(0xFFF2A46B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.08
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, s * 0.05),
          width: s * 0.6,
          height: s * 0.4,
        ),
        fur,
      );
      canvas.drawCircle(Offset(-s * 0.15, -s * 0.22), s * 0.2, fur);
      for (final side in [-1.0, 1.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(-s * 0.15 + side * s * 0.16, -s * 0.3)
            ..lineTo(-s * 0.15 + side * s * 0.12, -s * 0.48)
            ..lineTo(-s * 0.15 + side * s * 0.03, -s * 0.38)
            ..close(),
          fur,
        );
      }
      canvas.save();
      canvas.translate(-s * 0.15, 0);
      eyes(s * 0.07, -s * 0.24, s * 0.03);
      canvas.restore();
    case FriendKind.owl:
      final body = Paint()..color = const Color(0xFFB08968);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * 0.7, height: s),
        body,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, s * 0.15),
          width: s * 0.45,
          height: s * 0.55,
        ),
        Paint()..color = const Color(0xFFE8D3B5),
      );
      final blink = (t % 4) < 0.15;
      for (final side in [-1.0, 1.0]) {
        canvas.drawCircle(
          Offset(side * s * 0.15, -s * 0.18),
          s * 0.13,
          Paint()..color = Colors.white,
        );
        if (blink) {
          canvas.drawLine(
            Offset(side * s * 0.15 - s * 0.08, -s * 0.18),
            Offset(side * s * 0.15 + s * 0.08, -s * 0.18),
            eye..strokeWidth = 2,
          );
        } else {
          canvas.drawCircle(Offset(side * s * 0.15, -s * 0.18), s * 0.06, eye);
        }
      }
      canvas.drawPath(
        Path()
          ..moveTo(-s * 0.05, -s * 0.06)
          ..lineTo(s * 0.05, -s * 0.06)
          ..lineTo(0, s * 0.04)
          ..close(),
        Paint()..color = const Color(0xFFF2A46B),
      );
    case FriendKind.fox:
      final fur = Paint()..color = const Color(0xFFE8834E);
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.25, s * 0.15)
          ..quadraticBezierTo(
            s * 0.7,
            s * 0.2,
            s * 0.6,
            -s * 0.15 + math.sin(t * 1.5) * s * 0.05,
          ),
        Paint()
          ..color = const Color(0xFFE8834E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.16
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(s * 0.6, -s * 0.15 + math.sin(t * 1.5) * s * 0.05),
        s * 0.07,
        Paint()..color = Colors.white,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, s * 0.1),
          width: s * 0.6,
          height: s * 0.36,
        ),
        fur,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-s * 0.45, -s * 0.15)
          ..lineTo(-s * 0.05, -s * 0.3)
          ..lineTo(-s * 0.1, s * 0.0)
          ..close(),
        fur,
      );
      for (final dx in [-0.3, -0.12]) {
        canvas.drawPath(
          Path()
            ..moveTo(s * dx - s * 0.06, -s * 0.24)
            ..lineTo(s * dx, -s * 0.42)
            ..lineTo(s * dx + s * 0.06, -s * 0.26)
            ..close(),
          fur,
        );
      }
      canvas.drawCircle(Offset(-s * 0.2, -s * 0.19), s * 0.03, eye);
      canvas.drawCircle(Offset(-s * 0.44, -s * 0.15), s * 0.03, eye);
    case FriendKind.bird:
      final body = Paint()..color = const Color(0xFF7FB8F2);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * 0.7, height: s * 0.5),
        body,
      );
      canvas.drawCircle(Offset(s * 0.25, -s * 0.2), s * 0.2, body);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, s * 0.08),
          width: s * 0.4,
          height: s * 0.25,
        ),
        Paint()..color = const Color(0xFFF4A6B8),
      );
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.42, -s * 0.22)
          ..lineTo(s * 0.58, -s * 0.18)
          ..lineTo(s * 0.42, -s * 0.13)
          ..close(),
        Paint()..color = const Color(0xFFF2C46B),
      );
      canvas.drawCircle(Offset(s * 0.3, -s * 0.24), s * 0.04, eye);
      final flap = math.sin(t * (found > 0 ? 12 : 1.5)) * 0.3;
      canvas.save();
      canvas.rotate(flap);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-s * 0.1, -s * 0.05),
          width: s * 0.4,
          height: s * 0.2,
        ),
        Paint()..color = const Color(0xFF5E9BD8),
      );
      canvas.restore();
  }
  canvas.restore();
}

String friendName(FriendKind k) => switch (k) {
  FriendKind.duck => 'a duckling',
  FriendKind.crab => 'a little crab',
  FriendKind.cat => 'a sleepy cat',
  FriendKind.owl => 'an owl',
  FriendKind.fox => 'a fox',
  FriendKind.bird => 'a bluebird',
};
