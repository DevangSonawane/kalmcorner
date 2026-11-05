import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/color_sort/liquid_geometry.dart';

void main() {
  test('liquid area conservation at various tilts', () {
    const w = 44.0;
    const h = 4 * 42.0 + 18.0; // cap 4
    final poly = LiquidGeometry.tubePolygon(w, h);
    final total = LiquidGeometry.area(poly);
    for (final deg in [0, 30, 60, 80]) {
      final phi = deg * math.pi / 180;
      final g = (math.sin(phi), -math.cos(phi));
      for (final frac in [0.25, 0.5, 0.75]) {
        final target = total * frac;
        final c = LiquidGeometry.findC(poly, g, target);
        final clipped = LiquidGeometry.clipHalfPlane(poly, g, c);
        final a = LiquidGeometry.area(clipped);
        final err = (a - target).abs() / target;
        expect(err < 0.005, true, reason: 'deg=$deg frac=$frac err=$err');
      }
    }
  });
}
