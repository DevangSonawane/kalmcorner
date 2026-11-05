import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'wipe_engine.dart';
import 'scenes.dart';

class WindowWipePainter extends CustomPainter {
  WindowWipePainter({
    required this.engine,
    required this.revealProgress,
    required this.completionProgress,
    required this.useShader,
    required this.shaderProgram,
  });

  final WipeEngine engine;
  final double revealProgress;
  final double completionProgress;
  final bool useShader;
  final ui.FragmentProgram? shaderProgram;

  @override
  void paint(Canvas canvas, Size size) {
    final recipe = SceneRegistry.getScene(engine.sceneId)!;

    if (useShader &&
        shaderProgram != null &&
        engine.sharpImage != null &&
        engine.dirtyImage != null) {
      _drawWithShader(canvas, size, recipe);
    } else {
      _drawWithCanvas(canvas, size, recipe);
    }

    _drawDroplets(canvas, size);
    _drawCloth(canvas, size);
    _drawReveal(canvas, size);
    _drawCompletionMotes(canvas, size, recipe);
    _drawWindowFrame(canvas, size, recipe);
  }

  void _drawWithShader(Canvas canvas, Size size, SceneRecipe recipe) {
    final maskImage = engine.createMaskImage(size);

    final paint = Paint();
    final shader = shaderProgram!.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setImageSampler(0, engine.sharpImage!);
    shader.setImageSampler(1, engine.dirtyImage!);
    shader.setImageSampler(2, maskImage);
    paint.shader = shader;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    maskImage.dispose();
  }

  void _drawWithCanvas(Canvas canvas, Size size, SceneRecipe recipe) {
    // Draw sharp scene
    if (engine.sharpImage != null) {
      canvas.drawImageRect(
        engine.sharpImage!,
        Rect.fromLTWH(
          0,
          0,
          engine.sharpImage!.width.toDouble(),
          engine.sharpImage!.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      _drawSceneFallback(canvas, size, recipe);
    }

    // Draw dirty with mask
    if (engine.dirtyImage != null) {
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
      canvas.drawImageRect(
        engine.dirtyImage!,
        Rect.fromLTWH(
          0,
          0,
          engine.dirtyImage!.width.toDouble(),
          engine.dirtyImage!.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..filterQuality = FilterQuality.high,
      );

      // Apply mask - clean areas become transparent
      final maskImage = engine.createMaskImage(size);
      canvas.drawImageRect(
        maskImage,
        Rect.fromLTWH(
          0,
          0,
          maskImage.width.toDouble(),
          maskImage.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..blendMode = BlendMode.dstOut
          ..filterQuality = FilterQuality.high,
      );
      canvas.restore();
      maskImage.dispose();
    } else {
      _drawDirtFallback(canvas, size, recipe);
    }
  }

  void _drawSceneFallback(Canvas canvas, Size size, SceneRecipe recipe) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Sky gradient
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        recipe.skyStops,
        recipe.skyStopsPositions,
      );
    canvas.drawRect(rect, skyPaint);

    // Silhouettes
    for (final layer in recipe.silhouettes) {
      final paint = Paint()..color = layer.color;
      for (final shape in layer.shapes) {
        final scaledRect = Rect.fromLTWH(
          shape.rect.left * size.width,
          shape.rect.top * size.height,
          shape.rect.width * size.width,
          shape.rect.height * size.height,
        );
        switch (shape.type) {
          case SilhouetteType.rect:
            canvas.drawRect(scaledRect, paint);
            break;
          case SilhouetteType.triangle:
            final path = Path()
              ..moveTo(scaledRect.center.dx, scaledRect.top)
              ..lineTo(scaledRect.left, scaledRect.bottom)
              ..lineTo(scaledRect.right, scaledRect.bottom)
              ..close();
            canvas.drawPath(path, paint);
            break;
          case SilhouetteType.ellipse:
            canvas.drawOval(scaledRect, paint);
            break;
          case SilhouetteType.custom:
            if (shape.points != null) {
              final path = Path();
              for (int i = 0; i < shape.points!.length; i++) {
                final p = shape.points![i];
                final scaled = Offset(p.dx * size.width, p.dy * size.height);
                if (i == 0) {
                  path.moveTo(scaled.dx, scaled.dy);
                } else {
                  path.lineTo(scaled.dx, scaled.dy);
                }
              }
              path.close();
              canvas.drawPath(path, paint..color = shape.color ?? layer.color);
            }
            break;
        }
      }
    }

    // Accents
    for (final accent in recipe.accents) {
      final pos = Offset(
        accent.position.dx * size.width,
        accent.position.dy * size.height,
      );
      final accentPaint = Paint()
        ..color = accent.color.withValues(alpha: accent.alpha);

      if (accent.blur > 0) {
        accentPaint.maskFilter = ui.MaskFilter.blur(
          ui.BlurStyle.normal,
          accent.blur,
        );
      }

      switch (accent.type) {
        case AccentType.litWindow:
          canvas.drawRect(
            Rect.fromCenter(
              center: pos,
              width: accent.size.width,
              height: accent.size.height,
            ),
            accentPaint,
          );
          break;
        case AccentType.bokeh:
          canvas.drawCircle(pos, accent.size.width / 2, accentPaint);
          break;
        case AccentType.sunDisc:
          canvas.drawCircle(pos, accent.size.width / 2, accentPaint);
          break;
        case AccentType.sunGlow:
          final glowPaint = Paint()
            ..shader = ui.Gradient.radial(pos, accent.size.width / 2, [
              accent.color.withValues(alpha: accent.alpha),
              accent.color.withValues(alpha: 0),
            ]);
          canvas.drawCircle(pos, accent.size.width / 2, glowPaint);
          break;
        case AccentType.star:
          canvas.drawCircle(pos, accent.size.width / 2, accentPaint);
          break;
        case AccentType.seaSparkle:
          canvas.drawCircle(pos, accent.size.width / 2, accentPaint);
          break;
        case AccentType.neon:
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromCenter(
                center: pos,
                width: accent.size.width,
                height: accent.size.height,
              ),
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            accentPaint
              ..maskFilter = ui.MaskFilter.blur(
                ui.BlurStyle.normal,
                accent.blur,
              ),
          );
          break;
        case AccentType.neonGlow:
          final glowPaint = Paint()
            ..shader = ui.Gradient.linear(
              Offset(pos.dx, pos.dy - accent.size.height / 2),
              Offset(pos.dx, pos.dy + accent.size.height / 2),
              [
                accent.color.withValues(alpha: 0),
                accent.color.withValues(alpha: accent.alpha),
                accent.color.withValues(alpha: 0),
              ],
            );
          canvas.drawRect(
            Rect.fromCenter(
              center: pos,
              width: accent.size.width * 2,
              height: accent.size.height * 2,
            ),
            glowPaint,
          );
          break;
        case AccentType.blossomCluster:
          canvas.drawOval(
            Rect.fromCenter(
              center: pos,
              width: accent.size.width,
              height: accent.size.height,
            ),
            accentPaint,
          );
          break;
        case AccentType.butterfly:
        case AccentType.petal:
          canvas.drawCircle(pos, accent.size.width / 2, accentPaint);
          break;
      }
    }
  }

  void _drawDirtFallback(Canvas canvas, Size size, SceneRecipe recipe) {
    final rng = Random(recipe.seed + 10000);

    switch (recipe.dirtType) {
      case DirtType.fog:
        final paint = Paint()..color = Color(0xFFE8EEF5).withValues(alpha: 0.8);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

        for (int i = 0; i < 40; i++) {
          final r = 60 + rng.nextDouble() * 100;
          final x = rng.nextDouble() * size.width;
          final y = rng.nextDouble() * size.height;
          final alpha = 0.03 + rng.nextDouble() * 0.04;
          final blotchPaint = Paint()
            ..shader = ui.Gradient.radial(Offset(x, y), r, [
              Color(0xFFE8EEF5).withValues(alpha: alpha),
              Color(0xFFE8EEF5).withValues(alpha: 0),
            ]);
          canvas.drawCircle(Offset(x, y), r, blotchPaint);
        }
        break;

      case DirtType.dust:
        final basePaint = Paint()
          ..color = Color(0xFFCBB89E).withValues(alpha: 0.55);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width * 0.6, size.height),
          basePaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = Color(0xFFCBB89E).withValues(alpha: 0.35),
        );

        for (int i = 0; i < 900; i++) {
          final r = 0.6 + rng.nextDouble() * 1.0;
          final x = rng.nextDouble() * size.width;
          final y = rng.nextDouble() * size.height;
          final alpha = 0.15 + rng.nextDouble() * 0.2;
          canvas.drawCircle(
            Offset(x, y),
            r,
            Paint()..color = Color(0xFFCBB89E).withValues(alpha: alpha),
          );
        }

        for (int i = 0; i < 6; i++) {
          final x = rng.nextDouble() * size.width;
          final y = rng.nextDouble() * size.height * 0.8;
          final w = 2 + rng.nextDouble() * 4;
          final len = 80 + rng.nextDouble() * 180;
          final streakPaint = Paint()
            ..shader = ui.Gradient.linear(Offset(x, y), Offset(x, y + len), [
              Color(0xFFCBB89E).withValues(alpha: 0.12),
              Color(0xFFCBB89E).withValues(alpha: 0),
            ]);
          canvas.drawRect(Rect.fromLTWH(x - w / 2, y, w, len), streakPaint);
        }
        break;

      case DirtType.grime:
        final grimePaint = Paint()
          ..color = Color(0xFF8F8A78).withValues(alpha: 0.7);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          grimePaint,
        );

        for (int i = 0; i < 30; i++) {
          final x = rng.nextDouble() * size.width;
          final y = rng.nextDouble() * size.height;
          final w = (2 + rng.nextDouble() * 4);
          final len = (80 + rng.nextDouble() * 180);
          final runPaint = Paint()
            ..shader = ui.Gradient.linear(Offset(x, y), Offset(x, y + len), [
              Color(0xFF8F8A78).withValues(alpha: 0.12),
              Color(0xFF8F8A78).withValues(alpha: 0),
            ]);
          canvas.drawRect(Rect.fromLTWH(x - w / 2, y, w, len), runPaint);
        }
        break;

      case DirtType.frost:
        final frostPaint = Paint()
          ..color = Color(0xFFDCEBFF).withValues(alpha: 0.8);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          frostPaint,
        );

        for (int i = 0; i < 60; i++) {
          final cx = rng.nextDouble() * size.width;
          final cy = rng.nextDouble() * size.height;
          final crystalPaint = Paint()
            ..color = Color(0xFFDCEBFF).withValues(alpha: 0.5);
          for (int arm = 0; arm < 6; arm++) {
            final angle = arm * pi / 3;
            final length = 20 + rng.nextDouble() * 40;
            for (int branch = 0; branch < 3; branch++) {
              final bx = cos(angle) * length * (0.5 + branch * 0.25);
              final by = sin(angle) * length * (0.5 + branch * 0.25);
              canvas.drawLine(
                Offset(cx, cy),
                Offset(cx + bx, cy + by),
                crystalPaint..strokeWidth = (2 - branch * 0.5),
              );
            }
          }
        }
        break;

      case DirtType.salt:
        final saltPaint = Paint()
          ..color = Color(0xFFEDEAE0).withValues(alpha: 0.7);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          saltPaint,
        );

        for (int i = 0; i < 2000; i++) {
          final r = (0.5 + rng.nextDouble() * 0.7);
          final x = rng.nextDouble() * size.width;
          final y = rng.nextDouble() * size.height;
          canvas.drawCircle(
            Offset(x, y),
            r,
            Paint()..color = Colors.white.withValues(alpha: 0.5),
          );
        }
        break;

      case DirtType.pollen:
        final pollenPaint = Paint()
          ..color = Color(0xFFF2E09A).withValues(alpha: 0.6);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          pollenPaint,
        );

        for (int i = 0; i < 1200; i++) {
          final r = (0.5 + rng.nextDouble() * 0.5);
          final x = rng.nextDouble() * size.width;
          final y = rng.nextDouble() * size.height;
          canvas.drawCircle(
            Offset(x, y),
            r,
            Paint()..color = Color(0xFFF2E09A).withValues(alpha: 0.3),
          );
        }
        break;
    }
  }

  void _drawDroplets(Canvas canvas, Size size) {
    for (final droplet in engine.droplets) {
      if (!droplet.alive) continue;

      final center = Offset(droplet.x, droplet.y);
      final r = droplet.r;

      // Body
      final bodyPaint = Paint()
        ..shader = ui.Gradient.radial(center, r, [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.45),
        ]);

      canvas.drawCircle(center, r, bodyPaint);

      // Lower arc
      final arcPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        pi * 0.2,
        pi * 1.6,
        false,
        arcPaint,
      );

      // Specular highlight
      canvas.drawCircle(
        Offset(center.dx - r * 0.25, center.dy - r * 0.25),
        r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );

      // Lens effect for larger droplets
      if (r >= 4 && engine.sharpImage != null) {
        canvas.save();
        canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: center, radius: r)),
        );
        canvas.translate(center.dx, center.dy);
        canvas.scale(1.6, -1.6);
        canvas.translate(-center.dx, -center.dy);
        if (engine.sharpImage != null) {
          canvas.drawImageRect(
            engine.sharpImage!,
            Rect.fromLTWH(
              0,
              0,
              engine.sharpImage!.width.toDouble(),
              engine.sharpImage!.height.toDouble(),
            ),
            Rect.fromLTWH(0, 0, size.width, size.height),
            Paint()..filterQuality = FilterQuality.high,
          );
        }
        canvas.restore();
      }
    }
  }

  void _drawCloth(Canvas canvas, Size size) {
    if (!engine.cloth.visible) return;

    final pos = engine.cloth.pos;
    final radius = engine.cloth.brushRadius;
    final angle = engine.cloth.angle;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final squash = (engine.cloth.speed / 1400).clamp(0, 1);
    final scaleX = 1 + 0.12 * squash;
    final scaleY = 1 - 0.06 * squash;
    canvas.scale(scaleX, scaleY);

    // Contact shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 6 * radius / 34),
        width: radius * 1.2,
        height: radius * 0.3,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 10),
    );

    // Cloth body
    final clothPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromCenter(
            center: Offset.zero,
            width: radius * 1.5,
            height: radius * 1.2,
          ),
          topLeft: Radius.circular(radius * 0.3),
          topRight: Radius.circular(radius * 0.3),
          bottomLeft: Radius.circular(radius * 0.3),
          bottomRight: Radius.circular(radius * 0.3),
        ),
      );

    // Microfiber texture with wet sheen
    final clothPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, -radius * 0.6),
        Offset(0, radius * 0.6),
        [
          Color(0xFFF5F0E6).withValues(alpha: 1.0),
          Color(0xFFF5F0E6).withValues(alpha: 0.7),
          Color(0xFFFFFFFF).withValues(alpha: 0.35),
          Color(0xFFFFFFFF).withValues(alpha: 0.0),
        ],
        [0.0, 0.4, 0.7, 1.0],
      );
    canvas.drawPath(clothPath, clothPaint);

    // Stitched border
    final borderPaint = Paint()
      ..color = Color(0xFFE0D8CC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(clothPath, borderPaint);

    canvas.restore();
  }

  void _drawReveal(Canvas canvas, Size size) {
    if (revealProgress <= 0) return;

    final center = engine.revealCenter == Offset.zero
        ? Offset(size.width / 2, size.height / 2)
        : engine.revealCenter;
    final maxRadius = sqrt(size.width * size.width + size.height * size.height);
    final radius = maxRadius * revealProgress;

    final paint = Paint()
      ..color = Colors.white
      ..blendMode = BlendMode.dstOut;
    canvas.drawCircle(center, radius, paint);
  }

  void _drawCompletionMotes(Canvas canvas, Size size, SceneRecipe recipe) {
    if (completionProgress <= 0) return;

    final moteCount = recipe.dirtType == DirtType.frost ? 8 : 24;
    final rng = Random(recipe.seed + 9999);

    for (int i = 0; i < moteCount; i++) {
      final progress = (completionProgress + i / moteCount) % 1.0;
      final y = size.height - progress * (size.height + 50);
      final x = size.width * (0.1 + rng.nextDouble() * 0.8);
      final r = 2 + rng.nextDouble() * 3;
      final alpha = sin(progress * pi) * 0.5;

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = Color(0xFFFFE7B0).withValues(alpha: alpha),
      );
    }
  }

  void _drawWindowFrame(Canvas canvas, Size size, SceneRecipe recipe) {
    const frameWidth = 10.0;
    final framePaint = Paint()
      ..color = Color(0xFF8B7355).withValues(alpha: 0.9);

    // Outer frame
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, frameWidth),
      framePaint,
    ); // Top
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - frameWidth, size.width, frameWidth),
      framePaint,
    ); // Bottom
    canvas.drawRect(
      Rect.fromLTWH(0, 0, frameWidth, size.height),
      framePaint,
    ); // Left
    canvas.drawRect(
      Rect.fromLTWH(size.width - frameWidth, 0, frameWidth, size.height),
      framePaint,
    ); // Right

    // Inner shadow
    final shadowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, frameWidth),
        Offset(0, frameWidth + 20),
        [Colors.black.withValues(alpha: 0.15), Colors.transparent],
      );
    canvas.drawRect(
      Rect.fromLTWH(frameWidth, frameWidth, size.width - 2 * frameWidth, 20),
      shadowPaint,
    );

    // Muntin cross if needed
    if (recipe.muntinCross) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width / 2 - 2,
          frameWidth,
          4,
          size.height - 2 * frameWidth,
        ),
        framePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          frameWidth,
          size.height / 2 - 2,
          size.width - 2 * frameWidth,
          4,
        ),
        framePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WindowWipePainter oldDelegate) {
    return oldDelegate.engine != engine ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.completionProgress != completionProgress ||
        oldDelegate.useShader != useShader ||
        oldDelegate.shaderProgram != shaderProgram;
  }
}
