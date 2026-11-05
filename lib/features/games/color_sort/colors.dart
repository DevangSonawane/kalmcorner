// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Color Sort palette (12 colors, hue-ordered, calm saturation).
/// Spec section 9.3.
class ColorSortColor {
  const ColorSortColor({
    required this.index,
    required this.name,
    required this.hex,
    required this.symbol,
  });
  final int index;
  final String name;
  final Color hex;
  final String symbol;
}

const List<ColorSortColor> colorSortPalette = [
  ColorSortColor(
    index: 0,
    name: 'Coral',
    hex: Color(0xFFF28B82),
    symbol: 'dot',
  ),
  ColorSortColor(
    index: 1,
    name: 'Apricot',
    hex: Color(0xFFF6B26B),
    symbol: 'square',
  ),
  ColorSortColor(
    index: 2,
    name: 'Butter',
    hex: Color(0xFFF2D96B),
    symbol: 'triangle',
  ),
  ColorSortColor(
    index: 3,
    name: 'Leaf',
    hex: Color(0xFF8BC98A),
    symbol: 'diamond',
  ),
  ColorSortColor(
    index: 4,
    name: 'Teal',
    hex: Color(0xFF5CC0B3),
    symbol: 'plus',
  ),
  ColorSortColor(index: 5, name: 'Sky', hex: Color(0xFF7FB8F2), symbol: 'ring'),
  ColorSortColor(
    index: 6,
    name: 'Indigo',
    hex: Color(0xFF7C8CF2),
    symbol: 'star',
  ),
  ColorSortColor(
    index: 7,
    name: 'Lavender',
    hex: Color(0xFFB79DF2),
    symbol: 'crescent',
  ),
  ColorSortColor(
    index: 8,
    name: 'Orchid',
    hex: Color(0xFFC878C8),
    symbol: 'bowtie',
  ),
  ColorSortColor(
    index: 9,
    name: 'Rose',
    hex: Color(0xFFF8A0B8),
    symbol: 'heart',
  ),
  ColorSortColor(
    index: 10,
    name: 'Stone',
    hex: Color(0xFFB9B2A8),
    symbol: 'stripes',
  ),
  ColorSortColor(
    index: 11,
    name: 'Cocoa',
    hex: Color(0xFFA67C5B),
    symbol: 'hexagon',
  ),
];

/// Convert sRGB (0..1) to CIELAB.
List<double> srgbToLab(Color c) {
  double toLinear(double v) {
    if (v <= 0.04045) return v / 12.92;
    return math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = toLinear(c.r);
  final g = toLinear(c.g);
  final b = toLinear(c.b);

  // D65 reference white
  double x = (r * 0.4124564 + g * 0.3575761 + b * 0.1804375) / 0.95047;
  double y = (r * 0.2126729 + g * 0.7151522 + b * 0.0721750) / 1.00000;
  double z = (r * 0.0193339 + g * 0.1191920 + b * 0.9503041) / 1.08883;

  double f(double t) {
    if (t > 0.008856) return math.pow(t, 1 / 3).toDouble();
    return 7.787 * t + 16.0 / 116.0;
  }

  final fx = f(x);
  final fy = f(y);
  final fz = f(z);
  final L = 116 * fy - 16;
  final a = 500 * (fx - fy);
  final bb = 200 * (fy - fz);
  return [L, a, bb];
}

/// CIEDE2000 color difference.
double deltaE2000(Color c1, Color c2) {
  final lab1 = srgbToLab(c1);
  final lab2 = srgbToLab(c2);
  final L1 = lab1[0], a1 = lab1[1], b1 = lab1[2];
  final L2 = lab2[0], a2 = lab2[1], b2 = lab2[2];

  final C1 = math.sqrt(a1 * a1 + b1 * b1);
  final C2 = math.sqrt(a2 * a2 + b2 * b2);
  final Cbar = (C1 + C2) / 2;
  final Cbar7 = math.pow(Cbar, 7).toDouble();
  final G = 0.5 * (1 - math.sqrt(Cbar7 / (Cbar7 + math.pow(25, 7))));

  final a1p = (1 + G) * a1;
  final a2p = (1 + G) * a2;
  final C1p = math.sqrt(a1p * a1p + b1 * b1);
  final C2p = math.sqrt(a2p * a2p + b2 * b2);
  final Cbarp = (C1p + C2p) / 2;

  double hp(double a, double b) {
    if (a == 0 && b == 0) return 0;
    final h = math.atan2(b, a);
    return h >= 0 ? h : h + 2 * math.pi;
  }

  final h1p = hp(a1p, b1);
  final h2p = hp(a2p, b2);

  double dhp = h2p - h1p;
  if (C1p * C2p == 0) dhp = 0;
  if (dhp > math.pi) dhp -= 2 * math.pi;
  if (dhp < -math.pi) dhp += 2 * math.pi;

  final dLp = L2 - L1;
  final dCp = C2p - C1p;
  final dHp = 2 * math.sqrt(C1p * C2p) * math.sin(dhp / 2);

  final Lbarp = (L1 + L2) / 2;

  double hbarp;
  if (C1p * C2p == 0) {
    hbarp = h1p + h2p;
  } else {
    if ((h1p - h2p).abs() <= math.pi) {
      hbarp = (h1p + h2p) / 2;
    } else if (h1p + h2p < 2 * math.pi) {
      hbarp = (h1p + h2p + 2 * math.pi) / 2;
    } else {
      hbarp = (h1p + h2p - 2 * math.pi) / 2;
    }
  }

  final T =
      1 -
      0.17 * math.cos(hbarp - math.pi / 6) +
      0.24 * math.cos(2 * hbarp) +
      0.32 * math.cos(3 * hbarp + math.pi / 30) -
      0.20 * math.cos(4 * hbarp - (63 * math.pi) / 180);

  final dTheta =
      (30 * math.pi / 180) *
      math.exp(-math.pow((hbarp * 180 / math.pi - 275) / 25, 2));
  final RC =
      2 *
      math.sqrt(math.pow(Cbarp, 7) / (math.pow(Cbarp, 7) + math.pow(25, 7)));
  final SL =
      1 +
      (0.015 * math.pow(Lbarp - 50, 2)) /
          math.sqrt(20 + math.pow(Lbarp - 50, 2));
  final SC = 1 + 0.045 * Cbarp;
  final SH = 1 + 0.015 * Cbarp * T;

  final RT = -RC * math.sin(2 * dTheta);

  final dE = math.sqrt(
    math.pow(dLp / SL, 2) +
        math.pow(dCp / SC, 2) +
        math.pow(dHp / SH, 2) +
        RT * (dCp / SC) * (dHp / SH),
  );
  return dE;
}
