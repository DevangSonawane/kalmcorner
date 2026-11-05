import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_module.dart';

class GameRegistry {
  GameRegistry._(this._modules);
  final List<GameModule> _modules;

  static final GameRegistry instance = GameRegistry._([]);

  List<GameModule> get modules => List.unmodifiable(_modules);

  GameModule? getModule(String id) {
    try {
      return _modules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  void register(GameModule module) {
    _modules.add(module);
  }
}

final gameRegistryProvider = Provider<GameRegistry>(
  (ref) => GameRegistry.instance,
);
