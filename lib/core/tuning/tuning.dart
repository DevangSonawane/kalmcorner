import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tunable {
  const Tunable(this.key, this.def, this.min, this.max, {this.unit = ''});
  final String key;
  final double def;
  final double min;
  final double max;
  final String unit;
}

class Tuning {
  Tuning(this.gameId, this.defs);

  final String gameId;
  final Map<String, Tunable> defs;
  final Map<String, double> _overrides = {};
  SharedPreferences? _prefs;

  Future<void> loadPrefs(SharedPreferences prefs) async {
    _prefs = prefs;
    for (final def in defs.values) {
      final key = 'tuning.$gameId.${def.key}';
      final value = prefs.getDouble(key);
      if (value != null) {
        _overrides[def.key] = value.clamp(def.min, def.max);
      }
    }
  }

  double operator [](String key) {
    if (!kReleaseMode && _overrides.containsKey(key)) {
      return _overrides[key]!;
    }
    return defs[key]?.def ?? 0;
  }

  void setOverride(String key, double value) {
    if (kReleaseMode) return;
    final def = defs[key];
    if (def == null) return;
    final clamped = value.clamp(def.min, def.max);
    _overrides[key] = clamped;
    _prefs?.setDouble('tuning.$gameId.$key', clamped);
  }

  void reset() {
    _overrides.clear();
    for (final def in defs.values) {
      _prefs?.remove('tuning.$gameId.${def.key}');
    }
  }

  Map<String, double> getAll() {
    final result = <String, double>{};
    for (final def in defs.values) {
      result[def.key] = this[def.key];
    }
    return result;
  }

  String toDartCode() {
    final buffer = StringBuffer();
    buffer.writeln('class ${_capitalize(gameId)}Tuning {');
    for (final def in defs.values) {
      final val = this[def.key];
      buffer.writeln(
        '  static const ${def.key} = $val; // ${def.min}-${def.max}${def.unit.isNotEmpty ? ' ${def.unit}' : ''}',
      );
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}

class TuningRegistry {
  TuningRegistry._();
  static final TuningRegistry instance = TuningRegistry._();
  final Map<String, Tuning> _tunings = {};

  void register(Tuning tuning) => _tunings[tuning.gameId] = tuning;
  Tuning? get(String gameId) => _tunings[gameId];
  Iterable<Tuning> get all => _tunings.values;
}
