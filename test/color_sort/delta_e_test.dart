import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/color_sort/colors.dart';

void main() {
  test('all color pairs have deltaE2000 >= 12', () {
    for (int i = 0; i < colorSortPalette.length; i++) {
      for (int j = i + 1; j < colorSortPalette.length; j++) {
        final de = deltaE2000(colorSortPalette[i].hex, colorSortPalette[j].hex);
        expect(
          de >= 12,
          true,
          reason:
              '${colorSortPalette[i].name} vs ${colorSortPalette[j].name}: $de',
        );
      }
    }
  });
}
