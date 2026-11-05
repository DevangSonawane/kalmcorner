enum HapticEvent {
  uiTap,
  toggle,
  sliderTick,
  wipeTick,
  scrubResist,
  popSmall,
  popMedium,
  popLarge,
  sandTick,
  stonePlace,
  tubeSelect,
  pourPulse,
  tubeComplete,
  levelComplete,
  waterPulse,
  moteCatch,
  stageUp,
  bloom,
  completeSoft,
  invalid,
}

enum HapticLevel { off, soft, normal }

enum HapticType {
  soft,
  light,
  medium,
  heavy,
  rigid,
  selection,
  success,
  warning,
  error,
}

class HapticSettings {
  const HapticSettings({this.level = HapticLevel.normal});
  final HapticLevel level;

  HapticSettings copyWith({HapticLevel? level}) {
    return HapticSettings(level: level ?? this.level);
  }
}

abstract class HapticService {
  Future<void> init();
  void fire(HapticEvent event);
  void applySettings(HapticSettings settings);
}
