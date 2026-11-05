import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import 'haptic_service.dart';

class HapticServiceImpl implements HapticService {
  HapticServiceImpl();

  HapticBackend? _backend;
  HapticSettings _settings = const HapticSettings();
  bool _initialized = false;
  DateTime _lastHaptic = DateTime.fromMillisecondsSinceEpoch(0);
  int _hapticsPerSecond = 0;
  DateTime _secondStart = DateTime.now();

  static const Map<HapticEvent, HapticType> _eventTypeMap = {
    HapticEvent.uiTap: HapticType.selection,
    HapticEvent.toggle: HapticType.light,
    HapticEvent.sliderTick: HapticType.selection,
    HapticEvent.wipeTick: HapticType.soft,
    HapticEvent.scrubResist: HapticType.medium,
    HapticEvent.popSmall: HapticType.light,
    HapticEvent.popMedium: HapticType.medium,
    HapticEvent.popLarge: HapticType.heavy,
    HapticEvent.sandTick: HapticType.soft,
    HapticEvent.stonePlace: HapticType.medium,
    HapticEvent.tubeSelect: HapticType.selection,
    HapticEvent.pourPulse: HapticType.soft,
    HapticEvent.tubeComplete: HapticType.medium,
    HapticEvent.levelComplete: HapticType.success,
    HapticEvent.waterPulse: HapticType.soft,
    HapticEvent.moteCatch: HapticType.light,
    HapticEvent.stageUp: HapticType.medium,
    HapticEvent.bloom: HapticType.success,
    HapticEvent.completeSoft: HapticType.success,
    HapticEvent.invalid: HapticType.light,
  };

  static const Map<HapticEvent, int> _minIntervals = {
    HapticEvent.uiTap: 40,
    HapticEvent.toggle: 60,
    HapticEvent.sliderTick: 80,
    HapticEvent.wipeTick: 45,
    HapticEvent.scrubResist: 120,
    HapticEvent.popSmall: 45,
    HapticEvent.popMedium: 45,
    HapticEvent.popLarge: 60,
    HapticEvent.sandTick: 55,
    HapticEvent.stonePlace: 200,
    HapticEvent.tubeSelect: 60,
    HapticEvent.pourPulse: 110,
    HapticEvent.tubeComplete: 200,
    HapticEvent.levelComplete: 500,
    HapticEvent.waterPulse: 140,
    HapticEvent.moteCatch: 100,
    HapticEvent.stageUp: 300,
    HapticEvent.bloom: 500,
    HapticEvent.completeSoft: 500,
    HapticEvent.invalid: 150,
  };

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      final canVibrate = await Haptics.canVibrate();
      if (canVibrate) {
        _backend = PackageHapticBackend();
      } else {
        _backend = BuiltInHapticBackend();
      }
      _initialized = true;
    } catch (e) {
      _backend = BuiltInHapticBackend();
      _initialized = true;
    }
  }

  @override
  void fire(HapticEvent event) {
    if (!_initialized || _settings.level == HapticLevel.off) return;

    final now = DateTime.now();
    final msSinceLast = now.difference(_lastHaptic).inMilliseconds;
    if (msSinceLast < 24) return; // Global limiter: 24ms

    // Rate limit: max 25 per second
    if (now.difference(_secondStart).inSeconds >= 1) {
      _hapticsPerSecond = 0;
      _secondStart = now;
    }
    if (_hapticsPerSecond >= 25) return;
    _hapticsPerSecond++;

    final minInterval = _minIntervals[event] ?? 40;
    if (msSinceLast < minInterval) return;

    final type = _eventTypeMap[event]!;
    final adjustedType = _adjustForLevel(type);
    final adjustedInterval = _adjustInterval(minInterval);

    if (now.difference(_lastHaptic).inMilliseconds < adjustedInterval) return;

    try {
      _backend?.play(adjustedType);
      _lastHaptic = now;
    } catch (e) {
      // Silent fail
    }
  }

  HapticType _adjustForLevel(HapticType type) {
    if (_settings.level == HapticLevel.normal) return type;
    // Soft: step down one level
    return switch (type) {
      HapticType.heavy => HapticType.medium,
      HapticType.medium => HapticType.light,
      HapticType.light => HapticType.soft,
      HapticType.rigid => HapticType.medium,
      HapticType.success => HapticType.light,
      HapticType.warning => HapticType.light,
      HapticType.error => HapticType.light,
      _ => type,
    };
  }

  int _adjustInterval(int base) {
    if (_settings.level == HapticLevel.soft) return base * 2;
    return base;
  }

  @override
  void applySettings(HapticSettings settings) {
    _settings = settings;
  }
}

abstract class HapticBackend {
  Future<bool> get supported;
  Future<void> play(HapticType type);
}

class PackageHapticBackend implements HapticBackend {
  @override
  Future<bool> get supported async => await Haptics.canVibrate();

  @override
  Future<void> play(HapticType type) async {
    final hapticType = switch (type) {
      HapticType.soft => HapticsType.soft,
      HapticType.light => HapticsType.light,
      HapticType.medium => HapticsType.medium,
      HapticType.heavy => HapticsType.heavy,
      HapticType.rigid => HapticsType.rigid,
      HapticType.selection => HapticsType.selection,
      HapticType.success => HapticsType.success,
      HapticType.warning => HapticsType.warning,
      HapticType.error => HapticsType.error,
    };
    await Haptics.vibrate(hapticType);
  }
}

class BuiltInHapticBackend implements HapticBackend {
  @override
  Future<bool> get supported async => true;

  @override
  Future<void> play(HapticType type) async {
    switch (type) {
      case HapticType.soft:
      case HapticType.light:
        await HapticFeedback.lightImpact();
      case HapticType.medium:
      case HapticType.rigid:
        await HapticFeedback.mediumImpact();
      case HapticType.heavy:
        await HapticFeedback.heavyImpact();
      case HapticType.selection:
        await HapticFeedback.selectionClick();
      case HapticType.success:
      case HapticType.warning:
      case HapticType.error:
        await HapticFeedback.mediumImpact();
    }
  }
}
