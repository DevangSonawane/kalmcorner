import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/window_wipe/module.dart';
import 'package:calmcorner/features/games/bubble_pop/game.dart';
import 'package:calmcorner/features/games/sand_garden/game.dart';
import 'package:calmcorner/features/games/color_sort/game.dart';
import 'package:calmcorner/features/games/grow_plant/game.dart';
import 'package:calmcorner/features/games/game_module.dart';

class _FakeSession implements GameSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() => WindowWipeModule());

  for (final w in [320.0, 360.0, 390.0, 430.0, 768.0]) {
    for (final ts in [1.0, 1.6]) {
      testWidgets('WindowWipe builds $w ts$ts', (tester) async {
        tester.view.physicalSize = Size(w, 844);
        tester.view.devicePixelRatio = 1.0;
        tester.view.platformDispatcher.textScaleFactorTestValue = ts;
        await tester.pumpWidget(MaterialApp(home: WindowWipeGame(session: _FakeSession())));
        await tester.pump();
        expect(tester.takeException(), isNull);
        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('BubblePop builds $w ts$ts', (tester) async {
        tester.view.physicalSize = Size(w, 844);
        tester.view.devicePixelRatio = 1.0;
        tester.view.platformDispatcher.textScaleFactorTestValue = ts;
        await tester.pumpWidget(MaterialApp(home: BubblePopGame(session: _FakeSession())));
        await tester.pump();
        expect(tester.takeException(), isNull);
        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('SandGarden builds $w ts$ts', (tester) async {
        tester.view.physicalSize = Size(w, 844);
        tester.view.devicePixelRatio = 1.0;
        tester.view.platformDispatcher.textScaleFactorTestValue = ts;
        await tester.pumpWidget(MaterialApp(home: SandGardenGame(session: _FakeSession())));
        await tester.pump();
        expect(tester.takeException(), isNull);
        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('ColorSort builds $w ts$ts', (tester) async {
        tester.view.physicalSize = Size(w, 844);
        tester.view.devicePixelRatio = 1.0;
        tester.view.platformDispatcher.textScaleFactorTestValue = ts;
        await tester.pumpWidget(MaterialApp(home: ColorSortGame(session: _FakeSession())));
        await tester.pump();
        expect(tester.takeException(), isNull);
        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('GrowPlant builds $w ts$ts', (tester) async {
        tester.view.physicalSize = Size(w, 844);
        tester.view.devicePixelRatio = 1.0;
        tester.view.platformDispatcher.textScaleFactorTestValue = ts;
        await tester.pumpWidget(MaterialApp(home: GrowPlantGame(session: _FakeSession())));
        await tester.pump();
        expect(tester.takeException(), isNull);
        addTearDown(tester.view.resetPhysicalSize);
      });
    }
  }
}
