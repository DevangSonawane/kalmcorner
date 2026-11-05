import 'dart:math';
import 'dart:ui';

double lerp(double a, double b, double t) => a + (b - a) * t;

double clamp(double value, double min, double max) =>
    value < min ? min : (value > max ? max : value);

double smoothstep(double edge0, double edge1, double x) {
  final t = clamp((x - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3 - 2 * t);
}

double smootherstep(double edge0, double edge1, double x) {
  final t = clamp((x - edge0) / (edge1 - edge0), 0, 1);
  return t * t * t * (t * (t * 6 - 15) + 10);
}

double easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();

double easeInOutCubic(double t) =>
    t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3).toDouble() / 2;

double wrapPi(double x) {
  while (x > pi) {
    x -= 2 * pi;
  }
  while (x < -pi) {
    x += 2 * pi;
  }
  return x;
}

double angleDiff(double a, double b) => wrapPi(a - b);

double lerpAngle(double a, double b, double t) => a + angleDiff(b, a) * t;

double dist2(double x1, double y1, double x2, double y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  return dx * dx + dy * dy;
}

Offset rotate(Offset v, double angle) {
  final c = cos(angle);
  final s = sin(angle);
  return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
}

double triangleArea(Offset a, Offset b, Offset c) =>
    (a.dx * (b.dy - c.dy) + b.dx * (c.dy - a.dy) + c.dx * (a.dy - b.dy)).abs() /
    2;
