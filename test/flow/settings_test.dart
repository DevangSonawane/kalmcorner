import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calmcorner/app/app.dart';
import 'package:calmcorner/core/audio/audio_service_impl.dart';
import 'package:calmcorner/core/haptics/haptic_service_impl.dart';
import 'package:calmcorner/core/persistence/prefs_store.dart';
import 'package:calmcorner/core/providers.dart';
import 'package:calmcorner/features/settings/settings_screen.dart';

void main() {
  testWidgets('settings: theme, colour-blind and reset really work', (tester) async {
    SharedPreferences.setMockInitialValues({
      'levels.still_waters.done': ['1', '2'],
      'settings.music': 0.5,
    });
    final store = await PrefsStore.create();
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsStoreProvider.overrideWithValue(store),
          audioServiceProvider.overrideWithValue(SoloudAudioService()),
          hapticServiceProvider.overrideWithValue(HapticServiceImpl()),
        ],
        child: Consumer(
          builder: (context, r, _) {
            ref = r;
            return const MaterialApp(home: SettingsScreen());
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    // Theme: Night is saved and applied.
    await tester.tap(find.text('Night'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.getString('settings.theme'), 'moonlit');
    expect(ref.read(themeModeProvider).name, 'moonlit');

    // Colour-blind symbols saved.
    await tester.tap(find.text('Colour-blind symbols'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.getBool('settings.colorblind'), isTrue);

    // Reset clears levels but keeps settings.
    await tester.scrollUntilVisible(find.text('Reset progress'), 200);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Reset progress'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('RESET'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.getStringList('levels.still_waters.done'), isNull);
    expect(store.getDouble('settings.music'), 0.5);
    expect(store.getBool('settings.colorblind'), isTrue);
    await tester.pump(const Duration(seconds: 5));
  });
}
