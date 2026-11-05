import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/app/theme/themes.dart';
import 'package:calmcorner/core/audio/audio_service_impl.dart';
import 'package:calmcorner/core/haptics/haptic_service_impl.dart';
import 'package:calmcorner/features/levels/level_game.dart';
import 'package:calmcorner/features/games/still_waters/game.dart';

import '_capture.dart';

void main() {
  testWidgets('still waters with colour-blind symbols', (tester) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(400 * 2, 820 * 2);
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildMoonlitTheme(),
        home: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: StillWatersLevel(
              tint: const Color(0xFF8E7CC3),
              host: LevelHost(
                audio: SoloudAudioService(),
                haptics: HapticServiceImpl(),
                level: 40,
                reduceMotion: false,
                colorblind: true,
                onSolved: ({String? note}) {},
                onRestart: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    await capturePng(tester, key, 'build/visual/still_waters_colorblind.png');
  });
}
