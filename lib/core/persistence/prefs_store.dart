import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class PrefsStore {
  PrefsStore._(this._prefs);
  static Future<PrefsStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsStore._(prefs);
  }

  final SharedPreferences _prefs;
  final _changeController = StreamController<Set<String>>.broadcast();

  T? get<T>(String key, T Function(dynamic) fromJson) {
    final value = _prefs.get(key);
    if (value == null) return null;
    return fromJson(value);
  }

  Future<void> set<T>(String key, T value, dynamic Function(T) toJson) async {
    await _prefs.setString(key, json.encode(toJson(value)));
    _changeController.add({key});
  }

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
    _changeController.add({key});
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
    _changeController.add({key});
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
    _changeController.add({key});
  }

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
    _changeController.add({key});
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
    _changeController.add({key});
  }

  String? getString(String key) => _prefs.getString(key);
  bool? getBool(String key) => _prefs.getBool(key);
  double? getDouble(String key) => _prefs.getDouble(key);
  int? getInt(String key) => _prefs.getInt(key);
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  Future<void> remove(String key) async {
    await _prefs.remove(key);
    _changeController.add({key});
  }

  Future<void> clear() => _prefs.clear();

  Set<String> get keys => _prefs.getKeys();

  /// Removes every key that starts with one of [prefixes].
  Future<void> removePrefixed(List<String> prefixes) async {
    final gone = <String>{};
    for (final k in _prefs.getKeys()) {
      if (prefixes.any(k.startsWith)) {
        await _prefs.remove(k);
        gone.add(k);
      }
    }
    if (gone.isNotEmpty) _changeController.add(gone);
  }

  Stream<T> watch<T>(
    String key,
    T Function(dynamic) fromJson, {
    T? defaultValue,
  }) {
    return _changeController.stream
        .where((keys) => keys.contains(key))
        .map((_) => get(key, fromJson) ?? defaultValue)
        .where((v) => v != null)
        .map((v) => v as T)
        .distinct();
  }

  void dispose() {
    _changeController.close();
  }
}

class ProgressData {
  ProgressData({
    this.version = 1,
    this.calmSeconds = 0,
    this.daysVisited = 0,
    this.lastGame,
    this.windowWipe,
    this.bubblePop,
    this.sandGarden,
    this.colorSort,
    this.growPlant,
  });

  final int version;
  final int calmSeconds;
  final int daysVisited;
  final String? lastGame;
  final Map<String, dynamic>? windowWipe;
  final Map<String, dynamic>? bubblePop;
  final Map<String, dynamic>? sandGarden;
  final Map<String, dynamic>? colorSort;
  final Map<String, dynamic>? growPlant;

  Map<String, dynamic> toJson() => {
    'version': version,
    'calmSeconds': calmSeconds,
    'daysVisited': daysVisited,
    'lastGame': lastGame,
    'windowWipe': windowWipe,
    'bubblePop': bubblePop,
    'sandGarden': sandGarden,
    'colorSort': colorSort,
    'growPlant': growPlant,
  };

  static ProgressData fromJson(Map<String, dynamic> json) => ProgressData(
    version: json['version'] as int? ?? 1,
    calmSeconds: json['calmSeconds'] as int? ?? 0,
    daysVisited: json['daysVisited'] as int? ?? 0,
    lastGame: json['lastGame'] as String?,
    windowWipe: json['windowWipe'] as Map<String, dynamic>?,
    bubblePop: json['bubblePop'] as Map<String, dynamic>?,
    sandGarden: json['sandGarden'] as Map<String, dynamic>?,
    colorSort: json['colorSort'] as Map<String, dynamic>?,
    growPlant: json['growPlant'] as Map<String, dynamic>?,
  );

  ProgressData copyWith({
    int? version,
    int? calmSeconds,
    int? daysVisited,
    String? lastGame,
    Map<String, dynamic>? windowWipe,
    Map<String, dynamic>? bubblePop,
    Map<String, dynamic>? sandGarden,
    Map<String, dynamic>? colorSort,
    Map<String, dynamic>? growPlant,
  }) {
    return ProgressData(
      version: version ?? this.version,
      calmSeconds: calmSeconds ?? this.calmSeconds,
      daysVisited: daysVisited ?? this.daysVisited,
      lastGame: lastGame ?? this.lastGame,
      windowWipe: windowWipe ?? this.windowWipe,
      bubblePop: bubblePop ?? this.bubblePop,
      sandGarden: sandGarden ?? this.sandGarden,
      colorSort: colorSort ?? this.colorSort,
      growPlant: growPlant ?? this.growPlant,
    );
  }
}

abstract class ProgressRepository {
  Future<ProgressData> load();
  Future<void> save(ProgressData data);
  Stream<ProgressData> watch();
}

class SharedPrefsProgressRepository implements ProgressRepository {
  SharedPrefsProgressRepository(this._store);

  final PrefsStore _store;
  static const _key = 'progress.v1';
  final StreamController<ProgressData> _controller =
      StreamController.broadcast();
  Timer? _debounce;

  @override
  Future<ProgressData> load() async {
    final jsonStr = _store.getString(_key);
    if (jsonStr == null) return ProgressData();
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ProgressData.fromJson(json);
    } catch (e) {
      debugPrint('Progress load failed: $e');
      return ProgressData();
    }
  }

  @override
  Future<void> save(ProgressData data) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () async {
      await _store.setString(_key, json.encode(data.toJson()));
      _controller.add(data);
    });
  }

  @override
  Stream<ProgressData> watch() {
    return _controller.stream;
  }

  void dispose() {
    _debounce?.cancel();
    _controller.close();
  }
}

Future<String> getGardenDirectory() async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}

Future<String> getGardenImagePath() async {
  final dir = await getGardenDirectory();
  return '$dir/garden_height.png';
}

Future<String> getGardenJsonPath() async {
  final dir = await getGardenDirectory();
  return '$dir/garden.json';
}
