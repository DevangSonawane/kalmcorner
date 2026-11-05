import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calmcorner/app/app.dart';
import 'package:calmcorner/core/audio/audio_service_impl.dart';
import 'package:calmcorner/core/haptics/haptic_service_impl.dart';
import 'package:calmcorner/core/persistence/prefs_store.dart';
import 'package:calmcorner/core/providers.dart';

void main() {
  testWidgets('App loads and leaves the splash', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await PrefsStore.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsStoreProvider.overrideWithValue(store),
          audioServiceProvider.overrideWithValue(SoloudAudioService()),
          hapticServiceProvider.overrideWithValue(HapticServiceImpl()),
        ],
        child: const CalmCornerApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });
}
