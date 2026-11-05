import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/app/theme/tokens.dart';

double _luminance(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final light = la > lb ? la : lb;
  final dark = la > lb ? lb : la;
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  test('contrast ratios meet WCAG', () {
    final themes = [
      ('dawn', ThemeColors.dawn()),
      ('dusk', ThemeColors.dusk()),
      ('moonlit', ThemeColors.moonlit()),
    ];
    for (final (name, tc) in themes) {
      // ink on bg
      expect(
        _contrast(tc.ink, tc.bg) >= 7.0,
        true,
        reason: '$name ink on bg: ${_contrast(tc.ink, tc.bg)}',
      );
      // inkSoft on bg
      expect(
        _contrast(tc.inkSoft, tc.bg) >= 4.5,
        true,
        reason: '$name inkSoft on bg: ${_contrast(tc.inkSoft, tc.bg)}',
      );
      // ink on surfaceAlt
      expect(
        _contrast(tc.ink, tc.surfaceAlt) >= 4.5,
        true,
        reason: '$name ink on surfaceAlt: ${_contrast(tc.ink, tc.surfaceAlt)}',
      );
    }
  });
}
