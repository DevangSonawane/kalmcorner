import 'package:flutter_soloud/flutter_soloud.dart';

enum SoundId {
  uiTap,
  uiBack,
  uiToggleOn,
  uiToggleOff,
  popSmall,
  popMedium,
  popLarge,
  wipeLoop,
  wipeSqueak1,
  wipeSqueak2,
  wipeSqueak3,
  sandLoop,
  stonePlace,
  pourLoop,
  selectTube,
  tubeComplete0,
  tubeComplete1,
  tubeComplete2,
  tubeComplete3,
  tubeComplete4,
  tubeComplete5,
  levelComplete,
  completeSoft,
  bloom,
  waterDrop,
  sprinkleLoop,
  rainLoop,
  windChime0,
  windChime1,
  windChime2,
  windChime3,
}

/// One soft track plays across the whole app (see tools/gen_music.py).
enum MusicId { calm }

class AudioSettings {
  const AudioSettings({
    this.masterVolume = 0.8,
    this.musicVolume = 0.5,
    this.sfxVolume = 0.9,
    this.enabled = true,
    this.mixWithOthers = false,
  });

  final double masterVolume;
  final double musicVolume;
  final double sfxVolume;
  final bool enabled;
  final bool mixWithOthers;

  AudioSettings copyWith({
    double? masterVolume,
    double? musicVolume,
    double? sfxVolume,
    bool? enabled,
    bool? mixWithOthers,
  }) {
    return AudioSettings(
      masterVolume: masterVolume ?? this.masterVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      enabled: enabled ?? this.enabled,
      mixWithOthers: mixWithOthers ?? this.mixWithOthers,
    );
  }
}

class CalmSoundHandle {
  CalmSoundHandle(this._handle, this._id);
  final SoundHandle _handle;
  final SoundId _id;
  SoundHandle get handle => _handle;
  SoundId get id => _id;
}

abstract class AudioService {
  Future<void> init();
  Future<CalmSoundHandle?> play(
    SoundId id, {
    double volume = 1,
    double rate = 1,
    double pan = 0,
    bool loop = false,
  });
  void setVolume(CalmSoundHandle handle, double volume);
  void setRate(CalmSoundHandle handle, double rate);
  Future<void> fadeAndStop(CalmSoundHandle handle, Duration duration);
  Future<void> playMusic(
    MusicId id, {
    Duration crossfade = const Duration(milliseconds: 2500),
  });
  void duckMusic({
    double to = 0.4,
    Duration down = const Duration(milliseconds: 300),
    Duration up = const Duration(milliseconds: 1200),
  });

  /// Fade the current music out and stop it.
  Future<void> stopMusic({Duration fade = const Duration(milliseconds: 1200)});

  /// Start a looping ambience bed (rain, wind...) that replaces any previous one.
  Future<void> playAmbience(SoundId id, {double volume = 0.35});

  /// Fade out the ambience bed.
  Future<void> stopAmbience({
    Duration fade = const Duration(milliseconds: 1200),
  });

  AudioSettings get settings;
  void applySettings(AudioSettings settings);
  void pauseAll();
  void resumeAll();
  Future<void> dispose();
}

/// Mapping between SoundId enum (camelCase) and manifest ids (snake_case).
const Map<SoundId, String> soundIdManifestNames = {
  SoundId.uiTap: 'ui_tap',
  SoundId.uiBack: 'ui_back',
  SoundId.uiToggleOn: 'ui_toggle_on',
  SoundId.uiToggleOff: 'ui_toggle_off',
  SoundId.popSmall: 'pop_small',
  SoundId.popMedium: 'pop_medium',
  SoundId.popLarge: 'pop_large',
  SoundId.wipeLoop: 'wipe_loop',
  SoundId.wipeSqueak1: 'wipe_squeak_1',
  SoundId.wipeSqueak2: 'wipe_squeak_2',
  SoundId.wipeSqueak3: 'wipe_squeak_3',
  SoundId.sandLoop: 'sand_loop',
  SoundId.stonePlace: 'stone_place',
  SoundId.pourLoop: 'pour_loop',
  SoundId.selectTube: 'select_tube',
  SoundId.tubeComplete0: 'tube_complete_0',
  SoundId.tubeComplete1: 'tube_complete_1',
  SoundId.tubeComplete2: 'tube_complete_2',
  SoundId.tubeComplete3: 'tube_complete_3',
  SoundId.tubeComplete4: 'tube_complete_4',
  SoundId.tubeComplete5: 'tube_complete_5',
  SoundId.levelComplete: 'level_complete',
  SoundId.completeSoft: 'complete_soft',
  SoundId.bloom: 'bloom',
  SoundId.waterDrop: 'water_drop',
  SoundId.sprinkleLoop: 'sprinkle_loop',
  SoundId.rainLoop: 'rain_loop',
  SoundId.windChime0: 'wind_chime_0',
  SoundId.windChime1: 'wind_chime_1',
  SoundId.windChime2: 'wind_chime_2',
  SoundId.windChime3: 'wind_chime_3',
};

String soundIdToManifestId(SoundId id) => soundIdManifestNames[id]!;

SoundId? manifestIdToSoundId(String id) {
  for (final e in soundIdManifestNames.entries) {
    if (e.value == id) return e.key;
  }
  return null;
}

const Map<MusicId, String> musicIdManifestNames = {MusicId.calm: 'calm'};
