import 'dart:math';

double easeOutCubic(double t) => 1 - (1 - t) * (1 - t) * (1 - t);
double easeInCubic(double t) => t * t * t;
double easeInOutCubic(double t) =>
    t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3).toDouble() / 2;
double easeOutQuart(double t) => 1 - pow(1 - t, 4).toDouble();
double easeInOutQuart(double t) =>
    t < 0.5 ? 8 * t * t * t * t : 1 - pow(-2 * t + 2, 4).toDouble() / 2;
double easeOutQuint(double t) => 1 - pow(1 - t, 5).toDouble();
double easeInOutQuint(double t) =>
    t < 0.5 ? 16 * t * t * t * t * t : 1 - pow(-2 * t + 2, 5).toDouble() / 2;

double easeOutExpo(double t) => t == 1 ? 1 : 1 - pow(2, -10 * t).toDouble();
double easeInOutExpo(double t) {
  if (t == 0) return 0;
  if (t == 1) return 1;
  return t < 0.5
      ? pow(2, 20 * t - 10).toDouble() / 2
      : (2 - pow(2, -20 * t + 10).toDouble()) / 2;
}

double easeOutCirc(double t) => sqrt(1 - pow(t - 1, 2).toDouble());
double easeInOutCirc(double t) => t < 0.5
    ? (1 - sqrt(1 - pow(2 * t, 2).toDouble())) / 2
    : (sqrt(1 - pow(-2 * t + 2, 2).toDouble()) + 1) / 2;

double easeOutBack(double t) {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * pow(t - 1, 3).toDouble() + c1 * pow(t - 1, 2).toDouble();
}

double easeInOutBack(double t) {
  const c1 = 1.70158;
  const c2 = c1 * 1.525;
  return t < 0.5
      ? (pow(2 * t, 2).toDouble() * ((c2 + 1) * 2 * t - c2)) / 2
      : (pow(2 * t - 2, 2).toDouble() * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2;
}

double easeOutElastic(double t) {
  const c4 = (2 * pi) / 3;
  if (t == 0) return 0;
  if (t == 1) return 1;
  return pow(2, -10 * t).toDouble() * sin((t * 10 - 0.75) * c4) + 1;
}

double easeInOutElastic(double t) {
  const c5 = (2 * pi) / 4.5;
  if (t == 0) return 0;
  if (t == 1) return 1;
  if (t < 0.5) {
    return -(pow(2, 20 * t - 10).toDouble() * sin((20 * t - 11.125) * c5)) / 2;
  }
  return (pow(2, -20 * t + 10).toDouble() * sin((20 * t - 11.125) * c5)) / 2 +
      1;
}

double easeOutBounce(double t) {
  const n1 = 7.5625;
  const d1 = 2.75;
  if (t < 1 / d1) {
    return n1 * t * t;
  } else if (t < 2 / d1) {
    return n1 * (t -= 1.5 / d1) * t + 0.75;
  } else if (t < 2.5 / d1) {
    return n1 * (t -= 2.25 / d1) * t + 0.9375;
  } else {
    return n1 * (t -= 2.625 / d1) * t + 0.984375;
  }
}

double easeInOutBounce(double t) => t < 0.5
    ? (1 - easeOutBounce(1 - 2 * t)) / 2
    : (1 + easeOutBounce(2 * t - 1)) / 2;
