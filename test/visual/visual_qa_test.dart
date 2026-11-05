import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/window_wipe/module.dart';
import 'package:calmcorner/features/games/game_module.dart';
import 'package:calmcorner/features/games/bubble_pop/game.dart';
import 'package:calmcorner/features/games/sand_garden/game.dart';
import 'package:calmcorner/features/games/grow_plant/game.dart';

import '_capture.dart';

class _FakeSession implements GameSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    WindowWipeModule();
  });

  testWidgets('Visual QA Window Wipe 0', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 2.0;
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: WindowWipeGame(session: _FakeSession()),
        ),
      ),
    );
    await tester.pump();
    await capturePng(tester, key, 'build/visual/window_wipe_0.png');
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Visual QA Bubble Pop', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 2.0;
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: BubblePopGame(session: _FakeSession()),
        ),
      ),
    );
    await tester.pump();
    await capturePng(tester, key, 'build/visual/bubble_pop.png');
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Visual QA Sand Garden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 2.0;
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
    await capturePng(tester, key, 'build/visual/sand_garden.png');
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Visual QA Grow Plant', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 2.0;
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: GrowPlantGame(session: _FakeSession()),
        ),
      ),
    );
    await tester.pump();
    await capturePng(tester, key, 'build/visual/grow_plant.png');
    addTearDown(tester.view.resetPhysicalSize);
  });
}
