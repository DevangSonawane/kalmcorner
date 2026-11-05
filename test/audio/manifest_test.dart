import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/core/audio/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('manifest matches SoundId and MusicId', () async {
    final manifestStr = await rootBundle.loadString(
      'assets/audio/manifest.json',
    );
    final List<dynamic> manifest = json.decode(manifestStr);
    final manifestIds = manifest.map((e) => e['id'] as String).toSet();

    // Every SoundId must have a manifest entry
    for (final id in SoundId.values) {
      final mid = soundIdToManifestId(id);
      expect(
        manifestIds.contains(mid),
        true,
        reason: 'missing manifest entry for $id ($mid)',
      );
    }
    // Every MusicId must have a manifest entry
    for (final id in MusicId.values) {
      final mid = musicIdManifestNames[id]!;
      expect(
        manifestIds.contains(mid),
        true,
        reason: 'missing manifest entry for $id ($mid)',
      );
    }
    // Every manifest entry must be referenced
    for (final entry in manifest) {
      final id = entry['id'] as String;
      final kind = entry['kind'] as String;
      if (kind == 'music') {
        expect(
          musicIdManifestNames.values.contains(id),
          true,
          reason: 'unreferenced music entry $id',
        );
      } else {
        expect(
          soundIdManifestNames.values.contains(id),
          true,
          reason: 'unreferenced sfx entry $id',
        );
      }
    }
  });
}
