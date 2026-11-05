import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/audio/audio_service_impl.dart';

void main() {
  test('SoloudAudioService constructs', () {
    final a = SoloudAudioService();
    expect(a, isNotNull);
  });

  test('SoundId values exist', () {
    expect(SoundId.values.length, greaterThan(10));
  });
}
