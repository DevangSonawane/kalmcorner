import 'package:flutter/scheduler.dart';

class SimLoop {
  SimLoop({this.step = 1 / 120, this.maxSteps = 8, required this.onStep});

  final double step;
  final int maxSteps;
  final void Function(double dt) onStep;

  Duration _last = Duration.zero;
  double _acc = 0;
  Ticker? _ticker;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _last = Duration.zero;
    _acc = 0;
    _ticker = Ticker(_tick)..start();
  }

  void stop() {
    _ticker?.dispose();
    _ticker = null;
    _running = false;
  }

  void _tick(Duration elapsed) {
    if (!_running) return;
    var frame = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (frame > 0.05) frame = 0.05;
    _acc += frame;
    var n = 0;
    while (_acc >= step && n < maxSteps) {
      onStep(step);
      _acc -= step;
      n++;
    }
    if (n == maxSteps) _acc = 0;
  }

  bool get isRunning => _running;
}
