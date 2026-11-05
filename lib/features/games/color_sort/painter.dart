import 'package:flutter/material.dart';

import 'colors.dart';
import 'model.dart';

/// Color Sort tube painter (spec 9.5).
class ColorSortPainter extends CustomPainter {
  ColorSortPainter({
    required this.state,
    required this.selected,
    required this.tubeWidth,
    required this.unitHeight,
    required this.capacity,
    this.hint,
  });

  final ColorSortState state;
  final int? selected;
  final double tubeWidth;
  final double unitHeight;
  final int capacity;
  final (int, int)? hint;

  @override
  void paint(Canvas canvas, Size size) {
    // layout
    final tubes = state.tubes;
    final t = tubes.length;
    final gap = 14.0;
    var w = tubeWidth;
    var g = gap;
    final avail = size.width - 40;
    int perRow = ((avail + g) / (w + g)).floor();
    if (perRow < 1) perRow = 1;
    if (perRow < (t / 3).ceil()) {
      w = 34.0;
      g = 8.0;
      perRow = ((avail + g) / (w + g)).floor();
      if (perRow < 1) perRow = 1;
    }
    final rows = (t / perRow).ceil();
    final tubeH = capacity * unitHeight + 18;
    final rowGap = 24.0;
    final totalH = rows * tubeH + (rows - 1) * rowGap;
    var yStart = (size.height - totalH) / 2;
    if (yStart < 20) yStart = 20;

    for (int i = 0; i < t; i++) {
      final row = i ~/ perRow;
      final col = i % perRow;
      final rowTubes = (row == rows - 1) ? (t - row * perRow) : perRow;
      final rowWidth = rowTubes * (w + g) - g;
      final xStart = (size.width - rowWidth) / 2;
      final x = xStart + col * (w + g);
      final y = yStart + row * (tubeH + rowGap);
      final isSelected = selected == i;
      _drawTube(
        canvas,
        Offset(x, y),
        w,
        tubeH,
        unitHeight,
        capacity,
        tubes[i],
        isSelected,
        hint != null && (i == hint!.$1 || i == hint!.$2),
      );
    }
  }

  void _drawTube(
    Canvas canvas,
    Offset origin,
    double w,
    double h,
    double uh,
    int cap,
    List<int> colors,
    bool selected,
    bool isHint,
  ) {
    final rect = Rect.fromLTWH(origin.dx, origin.dy, w, h);
    // shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: origin + Offset(w / 2, h + 6),
        width: w * 0.9,
        height: 8,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
    // glass shape: straight sides + semicircular bottom
    final path = Path();
    final r = w / 2;
    path.moveTo(origin.dx, origin.dy);
    path.lineTo(origin.dx, origin.dy + h - r);
    path.arcToPoint(
      Offset(origin.dx + w, origin.dy + h - r),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.lineTo(origin.dx + w, origin.dy);
    path.close();

    // interior fill
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    // liquid layers
    final baseY = origin.dy + h - 4;
    for (int i = 0; i < colors.length; i++) {
      final color = colorSortPalette[colors[i]].hex;
      final layerBottom = baseY - i * uh;
      final layerTop = layerBottom - uh;
      final layerRect = Rect.fromLTWH(origin.dx + 2, layerTop, w - 4, uh);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 1.0), color.withValues(alpha: 0.85)],
        ).createShader(layerRect);
      canvas.drawRect(layerRect, paint);
      // lighter line between layers
      if (i > 0) {
        canvas.drawLine(
          Offset(origin.dx + 2, layerTop),
          Offset(origin.dx + w - 2, layerTop),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..strokeWidth = 1,
        );
      }
    }
    // meniscus on top layer
    if (colors.isNotEmpty) {
      final topY = baseY - (colors.length - 1) * uh - uh;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(origin.dx + w / 2, topY + 2),
          width: w - 4,
          height: 5,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.15),
      );
    }
    canvas.restore();

    // outline
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // left highlight stripe
    canvas.drawRect(
      Rect.fromLTWH(origin.dx + 2, origin.dy + h * 0.12, 4, h * 0.68),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // cork if full & uniform
    if (colors.length == cap &&
        colors.isNotEmpty &&
        colors.every((c) => c == colors.first)) {
      final corkRect = Rect.fromCenter(
        center: Offset(origin.dx + w / 2, origin.dy - 6),
        width: w - 4,
        height: 12,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(corkRect, const Radius.circular(6)),
        Paint()..color = const Color(0xFFEBDDC4),
      );
    }

    // selection glow
    if (selected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF8E7CC3).withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }
    // hint glow
    if (isHint) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF8E7CC3).withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ColorSortPainter old) => true;
}
