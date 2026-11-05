import 'package:flutter/widgets.dart';

class ReduceMotion {
  static bool of(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
}
