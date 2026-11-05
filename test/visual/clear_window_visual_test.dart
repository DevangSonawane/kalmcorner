import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/core/audio/audio_service_impl.dart';
import 'package:calmcorner/core/haptics/haptic_service_impl.dart';
import 'package:calmcorner/app/theme/themes.dart';
import 'package:calmcorner/features/levels/level_game.dart';
import 'package:calmcorner/features/games/clear_window/game.dart';

import '_capture.dart';

void main() {
  for (final level in [1, 9, 15, 20, 27, 33]) {
    testWidgets('clear window level $level', (tester) async {
      final key = GlobalKey();
      String? note;
      tester.view.physicalSize = const Size(400 * 2, 820 * 2);
      tester.view.devicePixelRatio = 2;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDawnTheme(),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: ClearWindowLevel(
                tint: const Color(0xFF8FB8D8),
                host: LevelHost(
                  audio: SoloudAudioService(),
                  haptics: HapticServiceImpl(),
                  level: level,
                  reduceMotion: false,
                  onSolved: ({String? note}) {},
                  onRestart: () {},
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 16));
      // A zig-zag wipe across the middle.
      final g = await tester.startGesture(const Offset(80, 330));
      for (var k = 0; k < 40; k++) {
        await g.moveTo(Offset(80 + (k.isEven ? 0 : 240.0), 300 + k * 6.0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 16));
      await capturePng(tester, key, 'build/visual/clear_window_$level.png');
      expect(note, isNull);
    });
  }
}
