import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/clear_window/levels.dart';

void main() {
  test('36 levels cover every dirt type, scene and window shape', () {
    final dirts = <DirtKind>{};
    final shapes = <WindowShape>{};
    final scenes = <Object>{};
    for (var l = 1; l <= ClearWindowLevels.levelCount; l++) {
      final w = ClearWindowLevels.build(l);
      dirts.add(w.dirt);
      shapes.add(w.shape);
      scenes.add(w.scene);
      expect(w.friend.pos.dx, inInclusiveRange(0.1, 0.9));
      expect(w.friend.pos.dy, inInclusiveRange(0.1, 0.95));
    }
    expect(dirts, DirtKind.values.toSet());
    expect(shapes, WindowShape.values.toSet());
    expect(scenes.length, 6);
    // Chapters follow the dirt order.
    expect(ClearWindowLevels.build(1).dirt, DirtKind.fog);
    expect(ClearWindowLevels.build(36).dirt, DirtKind.storm);
  });
}
