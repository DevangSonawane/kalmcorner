import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/core/haptics/haptic_service_impl.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';

void main() {
  test('HapticServiceImpl applies off settings without crash', () {
    final h = HapticServiceImpl();
    h.applySettings(const HapticSettings(level: HapticLevel.off));
    h.fire(HapticEvent.uiTap);
    // no exception
    expect(true, isTrue);
  });

  test('HapticServiceImpl fires all events without crash', () {
    final h = HapticServiceImpl();
    for (final e in HapticEvent.values) {
      h.fire(e);
    }
    expect(true, isTrue);
  });
}
