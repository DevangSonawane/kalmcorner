import 'package:flutter/material.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';

class GameMeta {
  const GameMeta({
    required this.titleKey,
    required this.taglineKey,
    required this.accent,
    required this.accent2,
    required this.defaultMusic,
    this.premium = false,
  });

  final String titleKey;
  final String taglineKey;
  final Color accent;
  final Color accent2;
  final String defaultMusic;
  final bool premium;
}

abstract class GameSession {
  AudioService get audio;
  HapticService get haptics;
  SettingsSnapshot get settings;
  bool get isTablet;
  Map<String, dynamic>? loadState();
  Future<void> saveState(Map<String, dynamic> json);
  void reportProgress(double zeroToOne);
  void complete({required GameResult result});
  void requestChromeVisible(bool visible);
}

class GameResult {
  const GameResult({required this.seconds, this.detailKey, this.nextLabelKey});

  final int seconds;
  final String? detailKey;
  final String? nextLabelKey;
}

class SettingsSnapshot {
  const SettingsSnapshot({
    this.reduceMotion = false,
    this.colorblindAssist = false,
    this.leftHanded = false,
    this.fastPour = false,
    this.keepAwake = true,
  });

  final bool reduceMotion;
  final bool colorblindAssist;
  final bool leftHanded;
  final bool fastPour;
  final bool keepAwake;
}

abstract class GameModule {
  String get id;
  GameMeta get meta;
  Widget buildThumbnail(BuildContext context, {required double t});
  Widget buildGame(BuildContext context, GameSession session);
}
