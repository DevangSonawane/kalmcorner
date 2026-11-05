import 'dart:math' as math;

/// Liquid geometry helpers for Color Sort tilted tubes (spec 9.8).
class LiquidGeometry {
  /// Tube polygon: rectangle [-w/2,w/2] x [0,H] plus rounded bottom 16-arc.
  static List<(double, double)> tubePolygon(double w, double h) {
    final pts = <(double, double)>[];
    // bottom arc (semicircle-ish): 16 points from left bottom to right bottom
    for (int i = 0; i <= 16; i++) {
      final t = i / 16.0;
      final ang = math.pi + t * math.pi; // bottom semicircle
      pts.add((
        math.cos(ang) * (w / 2),
        h - math.sin(ang).abs() * 0,
      )); // flat bottom approx
    }
    // Actually use rectangle + bottom arc properly:
    pts.clear();
    // left side up
    pts.add((-w / 2, 0));
    pts.add((-w / 2, h));
    // top
    pts.add((w / 2, h));
    pts.add((w / 2, 0));
    // bottom arc (semicircle radius w/2)
    final arc = <(double, double)>[];
    for (int i = 0; i <= 16; i++) {
      final ang = math.pi + (i / 16.0) * math.pi;
      arc.add((math.cos(ang) * (w / 2), (w / 2) * math.sin(ang).abs()));
    }
    // replace bottom edge with arc
    final result = <(double, double)>[];
    result.add((-w / 2, 0));
    for (final p in arc) {
      result.add(p);
    }
    result.add((w / 2, 0));
    result.add((w / 2, h));
    result.add((-w / 2, h));
    return result;
  }

  /// Clip polygon to half-plane g·p <= c (Sutherland-Hodgman, one plane).
  static List<(double, double)> clipHalfPlane(
    List<(double, double)> poly,
    (double, double) g,
    double c,
  ) {
    final out = <(double, double)>[];
    if (poly.isEmpty) return out;
    for (int i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      final fa = g.$1 * a.$1 + g.$2 * a.$2 - c;
      final fb = g.$1 * b.$1 + g.$2 * b.$2 - c;
      final aIn = fa <= 0;
      final bIn = fb <= 0;
      if (aIn) out.add(a);
      if (aIn != bIn) {
        // intersection
        final t = fa / (fa - fb);
        final ix = a.$1 + (b.$1 - a.$1) * t;
        final iy = a.$2 + (b.$2 - a.$2) * t;
        out.add((ix, iy));
      }
    }
    return out;
  }

  /// Polygon area (shoelace).
  static double area(List<(double, double)> poly) {
    if (poly.length < 3) return 0;
    double s = 0;
    for (int i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      s += a.$1 * b.$2 - b.$1 * a.$2;
    }
    return s.abs() / 2;
  }

  /// Find c such that area of polygon clipped to g·p <= c equals target V.
  static double findC(
    List<(double, double)> poly,
    (double, double) g,
    double targetV,
  ) {
    // bounds for c
    double minC = double.infinity;
    double maxC = -double.infinity;
    for (final p in poly) {
      final v = g.$1 * p.$1 + g.$2 * p.$2;
      if (v < minC) minC = v;
      if (v > maxC) maxC = v;
    }
    for (int i = 0; i < 12; i++) {
      final mid = (minC + maxC) / 2;
      final clipped = clipHalfPlane(poly, g, mid);
      final a = area(clipped);
      if (a < targetV) {
        minC = mid;
      } else {
        maxC = mid;
      }
    }
    return (minC + maxC) / 2;
  }
}
