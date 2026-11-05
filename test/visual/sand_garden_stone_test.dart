import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/sand_garden/game.dart';
import 'package:calmcorner/features/games/game_module.dart';

import '_capture.dart';

class _FakeSession implements GameSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('Sand Garden stone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: SandGardenGame(session: _FakeSession()),
        ),
      ),
    );
    await tester.pump();
    await tester.tapAt(const Offset(195, 780));
    await tester.pump();
    await capturePng(tester, key, 'build/visual/sand_garden.png');
    addTearDown(tester.view.resetPhysicalSize);
  });
}
