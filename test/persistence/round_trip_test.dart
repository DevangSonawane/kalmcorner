import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/window_wipe/module.dart';
import 'package:calmcorner/features/games/game_module.dart';
import 'package:calmcorner/features/games/bubble_pop/game.dart';
import 'package:calmcorner/features/games/color_sort/game.dart';
import 'package:calmcorner/features/games/grow_plant/game.dart';

class _MemorySession implements GameSession {
  Map<String, dynamic>? _state;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
  @override
  Map<String, dynamic>? loadState() => _state;
  @override
  Future<void> saveState(Map<String, dynamic> json) async {
    _state = json;
  }
}

void main() {
  setUpAll(() => WindowWipeModule());

  testWidgets('Window Wipe round-trip', (tester) async {
    final session = _MemorySession();
    await tester.pumpWidget(
      MaterialApp(home: WindowWipeGame(session: session)),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(session.loadState(), isNotNull);
  });

  testWidgets('Bubble Pop round-trip', (tester) async {
    final session = _MemorySession();
    await tester.pumpWidget(MaterialApp(home: BubblePopGame(session: session)));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(session.loadState(), isNotNull);
  });

  testWidgets('Color Sort round-trip', (tester) async {
    final session = _MemorySession();
    await tester.pumpWidget(MaterialApp(home: ColorSortGame(session: session)));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(session.loadState(), isNotNull);
  });

  testWidgets('Grow Plant round-trip', (tester) async {
    final session = _MemorySession();
    await tester.pumpWidget(MaterialApp(home: GrowPlantGame(session: session)));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(session.loadState(), isNotNull);
  });
}
