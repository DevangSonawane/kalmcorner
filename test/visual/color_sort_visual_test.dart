import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/color_sort/game.dart';
import 'package:calmcorner/features/games/game_module.dart';

void main() {
  testWidgets('Color Sort renders a frame', (tester) async {
    final session = _FakeSession();
    await tester.pumpWidget(MaterialApp(home: ColorSortGame(session: session)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CustomPaint), findsWidgets);
  });
}

class _FakeSession implements GameSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
