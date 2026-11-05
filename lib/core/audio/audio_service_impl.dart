import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_service.dart';

/// flutter_soloud backed audio. SFX are preloaded into memory; music files are
/// large, so each track is streamed from disk the first time it is needed.
class SoloudAudioService implements AudioService {
  SoloudAudioService();

  SoLoud? _soloud;
  bool _initialized = false;
  AudioSettings _settings = const AudioSettings();

  final Map<SoundId, AudioSource> _sources = {};
  final Map<String, String> _musicFiles = {};
  final Map<MusicId, AudioSource> _musicSources = {};
  final Map<SoundId, List<SoundHandle>> _voices = {};
  final Map<SoundId, int> _lastPlayMs = {};

  SoundHandle? _musicHandle;
  MusicId? _currentMusic;
  SoundHandle? _ambienceHandle;
  SoundId? _currentAmbience;
  double _ambienceVolume = 0;

  static const Map<SoundId, int> _maxVoices = {
    SoundId.popSmall: 6,
    SoundId.popMedium: 6,
    SoundId.popLarge: 6,
    SoundId.waterDrop: 4,
    SoundId.stonePlace: 4,
    SoundId.wipeSqueak1: 1,
    SoundId.wipeSqueak2: 1,
    SoundId.wipeSqueak3: 1,
    SoundId.levelComplete: 1,
    SoundId.completeSoft: 1,
  };
  static const int _minIntervalMs = 35;

  @override
  AudioSettings get settings => _settings;

  double get _sfxGain => _settings.masterVolume * _settings.sfxVolume;
  double get _musicGain => _settings.masterVolume * _settings.musicVolume;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      _soloud = SoLoud.instance;
      await _soloud!.init();
      await _loadManifest();
      _initialized = true;
    } catch (e) {
      debugPrint('Audio init failed: $e');
      _initialized = false;
    }
  }

  Future<void> _loadManifest() async {
    final raw = await rootBundle.loadString('assets/audio/manifest.json');
    final List<dynamic> manifest = json.decode(raw);
    for (final entry in manifest) {
      final id = entry['id'] as String;
      final file = entry['file'] as String;
      if (entry['kind'] == 'music') {
        _musicFiles[id] = 'assets/audio/$file';
        continue;
      }
      final soundId = manifestIdToSoundId(id);
      if (soundId == null) continue;
      try {
        _sources[soundId] = await _soloud!.loadAsset('assets/audio/$file');
      } catch (e) {
        debugPrint('Failed to load $file: $e');
      }
    }
  }

  bool _alive(SoundHandle h) {
    try {
      return _soloud!.getIsValidVoiceHandle(h);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<CalmSoundHandle?> play(
    SoundId id, {
    double volume = 1,
    double rate = 1,
    double pan = 0,
    bool loop = false,
  }) async {
    if (!_initialized || !_settings.enabled) return null;
    final source = _sources[id];
    if (source == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (!loop && now - (_lastPlayMs[id] ?? 0) < _minIntervalMs) return null;

    final voices = _voices.putIfAbsent(id, () => []);
    voices.removeWhere((h) => !_alive(h));
    if (voices.length >= (_maxVoices[id] ?? 3)) return null;

    try {
      final handle = _soloud!.play(
        source,
        volume: (volume * _sfxGain).clamp(0.0, 1.0),
        pan: pan.clamp(-1.0, 1.0),
        looping: loop,
      );
      if (rate != 1) _soloud!.setRelativePlaySpeed(handle, rate);
      voices.add(handle);
      _lastPlayMs[id] = now;
      return CalmSoundHandle(handle, id);
    } catch (e) {
      debugPrint('Play failed for $id: $e');
      return null;
    }
  }

  @override
  void setVolume(CalmSoundHandle handle, double volume) {
    if (!_initialized || !_alive(handle.handle)) return;
    _soloud!.setVolume(handle.handle, (volume * _sfxGain).clamp(0.0, 1.0));
  }

  @override
  void setRate(CalmSoundHandle handle, double rate) {
    if (!_initialized || !_alive(handle.handle)) return;
    _soloud!.setRelativePlaySpeed(handle.handle, rate);
  }

  @override
  Future<void> fadeAndStop(CalmSoundHandle handle, Duration duration) async {
    if (!_initialized) return;
    _fadeStop(handle.handle, duration);
  }

  void _fadeStop(SoundHandle h, Duration d) {
    if (!_alive(h)) return;
    try {
      _soloud!.fadeVolume(h, 0, d);
      _soloud!.scheduleStop(h, d);
    } catch (e) {
      debugPrint('Fade/stop failed: $e');
    }
  }

  @override
  Future<void> playMusic(
    MusicId id, {
    Duration crossfade = const Duration(milliseconds: 2500),
  }) async {
    if (!_initialized) return;
    if (_currentMusic == id && _musicHandle != null && _alive(_musicHandle!)) {
      return;
    }
    _currentMusic = id;
    try {
      var source = _musicSources[id];
      if (source == null) {
        final path = _musicFiles[musicIdManifestNames[id]];
        if (path == null) return;
        source = await _soloud!.loadAsset(path, mode: LoadMode.disk);
        _musicSources[id] = source;
      }
      if (_currentMusic != id) return; // changed while loading
      final old = _musicHandle;
      if (old != null) _fadeStop(old, crossfade);
      final musicOn = _settings.enabled && _settings.musicVolume > 0;
      final h = _soloud!.play(source, volume: 0, looping: true);
      if (musicOn) _soloud!.fadeVolume(h, _musicGain, crossfade);
      _musicHandle = h;
    } catch (e) {
      debugPrint('PlayMusic failed: $e');
    }
  }

  @override
  Future<void> stopMusic({
    Duration fade = const Duration(milliseconds: 1200),
  }) async {
    final h = _musicHandle;
    _musicHandle = null;
    _currentMusic = null;
    if (h != null && _initialized) _fadeStop(h, fade);
  }

  @override
  Future<void> playAmbience(SoundId id, {double volume = 0.35}) async {
    if (!_initialized) return;
    _ambienceVolume = volume;
    if (_currentAmbience == id &&
        _ambienceHandle != null &&
        _alive(_ambienceHandle!)) {
      return;
    }
    final old = _ambienceHandle;
    if (old != null) _fadeStop(old, const Duration(milliseconds: 800));
    final source = _sources[id];
    if (source == null) return;
    try {
      final h = _soloud!.play(source, volume: 0, looping: true);
      if (_settings.enabled) {
        _soloud!.fadeVolume(
          h,
          (volume * _sfxGain).clamp(0.0, 1.0),
          const Duration(milliseconds: 1500),
        );
      }
      _ambienceHandle = h;
      _currentAmbience = id;
    } catch (e) {
      debugPrint('Ambience failed: $e');
    }
  }

  @override
  Future<void> stopAmbience({
    Duration fade = const Duration(milliseconds: 1200),
  }) async {
    final h = _ambienceHandle;
    _ambienceHandle = null;
    _currentAmbience = null;
    if (h != null && _initialized) _fadeStop(h, fade);
  }

  @override
  void duckMusic({
    double to = 0.4,
    Duration down = const Duration(milliseconds: 300),
    Duration up = const Duration(milliseconds: 1200),
  }) {
    final h = _musicHandle;
    if (!_initialized || h == null || !_settings.enabled) return;
    _soloud!.fadeVolume(h, _musicGain * to, down);
    Future.delayed(down + up, () {
      if (_musicHandle == h && _alive(h)) {
        _soloud!.fadeVolume(h, _musicGain, up);
      }
    });
  }

  @override
  void applySettings(AudioSettings settings) {
    _settings = settings;
    if (!_initialized) return;
    final m = _musicHandle;
    if (m != null && _alive(m)) {
      _soloud!.fadeVolume(
        m,
        settings.enabled ? _musicGain : 0,
        const Duration(milliseconds: 400),
      );
    }
    final a = _ambienceHandle;
    if (a != null && _alive(a)) {
      _soloud!.fadeVolume(
        a,
        settings.enabled ? (_ambienceVolume * _sfxGain).clamp(0.0, 1.0) : 0,
        const Duration(milliseconds: 400),
      );
    }
  }

  @override
  void pauseAll() {
    if (!_initialized) return;
    _soloud!.setGlobalVolume(0);
  }

  @override
  void resumeAll() {
    if (!_initialized) return;
    _soloud!.setGlobalVolume(1);
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) return;
    _soloud!.deinit();
    _sources.clear();
    _musicSources.clear();
    _initialized = false;
  }
}
