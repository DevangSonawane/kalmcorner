import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/color_sort/game.dart';
import 'package:calmcorner/features/games/game_module.dart';

class _FakeSession implements GameSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  for (final level in [1, 20, 60]) {
    for (final w in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets('Color Sort no overflow (level $level, width $w)', (
        tester,
      ) async {
        tester.view.physicalSize = Size(w, 844);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            home: ColorSortGame(session: _FakeSession(), initialLevel: level),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        addTearDown(tester.view.resetPhysicalSize);
      });
    }
  }
}
