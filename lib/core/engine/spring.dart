import 'dart:ui';

import '../../app/theme/tokens.dart' show SpringConfig;

export '../../app/theme/tokens.dart' show SpringConfig;

class Spring {
  Spring({required this.config, double initial = 0, this._target = 0})
    : _x = initial,
      _v = 0;

  final SpringConfig config;
  double _x;
  double _v;
  double _target;
  int _settledFrames = 0;

  double get x => _x;
  double get v => _v;
  double get target => _target;
  bool get settled => _settledFrames >= 3;

  set target(double value) {
    _target = value;
    _settledFrames = 0;
  }

  void update(double dt) {
    dt = dt.clamp(0, 1 / 30);
    final force = -config.k * (_x - _target) - config.c * _v;
    _v += force / config.m * dt;
    _x += _v * dt;

    if ((_x - _target).abs() < 0.01 && _v.abs() < 0.01) {
      _settledFrames++;
    } else {
      _settledFrames = 0;
    }

    if (settled) {
      _x = _target;
      _v = 0;
    }
  }

  void setValue(double value) {
    _x = value;
    _v = 0;
    _settledFrames = 0;
  }

  void pullToTarget() {
    _x = _target;
    _v = 0;
    _settledFrames = 3;
  }
}

class Spring2D {
  Spring2D({
    required this.config,
    Offset initial = Offset.zero,
    this._target = Offset.zero,
  }) : _x = initial,
       _v = Offset.zero;

  final SpringConfig config;
  Offset _x;
  Offset _v;
  Offset _target;
  int _settledFrames = 0;

  Offset get x => _x;
  Offset get v => _v;
  Offset get target => _target;
  bool get settled => _settledFrames >= 3;

  set target(Offset value) {
    _target = value;
    _settledFrames = 0;
  }

  void update(double dt) {
    dt = dt.clamp(0, 1 / 30);
    final force = Offset(
      -config.k * (_x.dx - _target.dx) - config.c * _v.dx,
      -config.k * (_x.dy - _target.dy) - config.c * _v.dy,
    );
    _v += force / config.m * dt;
    _x += _v * dt;

    final dx = (_x - _target).distance;
    if (dx < 0.01 && _v.distance < 0.01) {
      _settledFrames++;
    } else {
      _settledFrames = 0;
    }

    if (settled) {
      _x = _target;
      _v = Offset.zero;
    }
  }

  void setValue(Offset value) {
    _x = value;
    _v = Offset.zero;
    _settledFrames = 0;
  }
}
