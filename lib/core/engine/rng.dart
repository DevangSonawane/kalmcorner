import 'dart:math';

class Rng {
  Rng([int? seed]) : _random = Random(seed);

  final Random _random;

  double nextDouble() => _random.nextDouble();
  int nextInt(int max) => _random.nextInt(max);
  bool nextBool() => _random.nextBool();

  double range(double min, double max) => min + (max - min) * nextDouble();
  int rangeInt(int min, int max) => min + nextInt(max - min + 1);
  bool chance(double p) => nextDouble() < p;

  double gauss([double mean = 0, double stdDev = 1]) {
    // Box-Muller transform
    final u1 = nextDouble();
    final u2 = nextDouble();
    final z = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    return mean + z * stdDev;
  }

  T choice<T>(List<T> list) => list[nextInt(list.length)];

  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
