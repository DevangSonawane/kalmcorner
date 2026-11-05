/// Pour animation helper for Color Sort (spec 9.7).
class PourAnimation {
  PourAnimation({required this.duration});
  final Duration duration;
  double _t = 0;

  void reset() => _t = 0;
  void advance(double dt) => _t += dt;
  double get progress => (_t / duration.inMilliseconds * 1000).clamp(0.0, 1.0);

  /// Phase boundaries in seconds.
  static const approachEnd = 0.16;
  static const tiltEnd = 0.42;

  double pourMsPerUnit = 0.18;
  int units = 1;

  double get pourEnd => tiltEnd + pourMsPerUnit * units;
  double get returnEnd => pourEnd + 0.28;

  bool get isApproach => progress < approachEnd;
  bool get isTilt => progress >= approachEnd && progress < tiltEnd;
  bool get isPour => progress >= tiltEnd && progress < pourEnd;
  bool get isReturn => progress >= pourEnd;
  bool get done => progress >= returnEnd;
}
