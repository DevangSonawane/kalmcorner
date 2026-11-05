import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/sand_garden/game.dart';
import 'package:calmcorner/features/games/game_module.dart';

class _FakeSession implements GameSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('Sand Garden builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SandGardenGame(session: _FakeSession())),
    );
    await tester.pump();
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
