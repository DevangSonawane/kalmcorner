import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/bubble_pop/game.dart';
import 'package:calmcorner/features/games/game_module.dart';

void main() {
  testWidgets('Bubble Pop renders a frame', (tester) async {
    final session = _FakeSession();
    await tester.pumpWidget(MaterialApp(home: BubblePopGame(session: session)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CustomPaint), findsWidgets);
  });
}

class _FakeSession implements GameSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
