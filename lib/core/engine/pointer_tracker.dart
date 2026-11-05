import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class TrackedPointer {
  TrackedPointer({
    required this.id,
    required this.position,
    required this.downAt,
    this.radius = 0,
  }) : prevPosition = position;

  final int id;
  Offset position;
  Offset prevPosition;
  Offset velocity = Offset.zero;
  final Duration downAt;
  final double radius;

  double get speed => velocity.distance;
}

class PointerTracker {
  PointerTracker({this.ignoreRadiusMajor = 90});

  final double ignoreRadiusMajor;
  final Map<int, TrackedPointer> _pointers = {};
  static const _velocityAlpha = 0.35;

  void addPointer(PointerDownEvent event) {
    if (event.radiusMajor > ignoreRadiusMajor) return;
    _pointers[event.pointer] = TrackedPointer(
      id: event.pointer,
      position: event.localPosition,
      downAt: event.timeStamp,
      radius: event.radiusMajor,
    );
  }

  void updatePointer(PointerMoveEvent event) {
    final pointer = _pointers[event.pointer];
    if (pointer == null) return;
    pointer.prevPosition = pointer.position;
    pointer.position = event.localPosition;
    final dt = (event.timeStamp - pointer.downAt).inMicroseconds / 1e6;
    if (dt > 0) {
      final delta = pointer.position - pointer.prevPosition;
      final instantV = delta / dt;
      pointer.velocity = Offset.lerp(
        pointer.velocity,
        instantV,
        _velocityAlpha,
      )!;
    }
  }

  void removePointer(PointerUpEvent event) {
    _pointers.remove(event.pointer);
  }

  void removePointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
  }

  List<TrackedPointer> get activePointers => _pointers.values.toList();

  TrackedPointer? getPointer(int id) => _pointers[id];

  bool get hasPointers => _pointers.isNotEmpty;

  void clear() => _pointers.clear();
}
