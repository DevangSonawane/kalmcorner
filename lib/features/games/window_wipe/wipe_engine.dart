import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:calmcorner/core/engine/spring.dart';
import 'package:calmcorner/core/engine/pointer_tracker.dart';
import 'package:calmcorner/core/engine/rng.dart';
import 'package:calmcorner/core/engine/math.dart';
import 'package:calmcorner/features/games/window_wipe/scenes.dart';

class Cloth {
  Cloth({
    required this.config,
    required this.brushRadius,
    required this.onStamp,
  }) : _spring = Spring2D(config: config);

  final SpringConfig config;
  final double brushRadius;
  final void Function(
    Offset center,
    double radius,
    double pressure,
    double speed, {
    bool isSqueak,
  })
  onStamp;

  final Spring2D _spring;
  Offset _pos = Offset.zero;
  Offset _target = Offset.zero;
  double _angle = 0;
  bool _visible = false;
  Offset _prevPos = Offset.zero;
  double _prevSpeed = 0;
  double _timeSinceLastRestStamp = 0;

  Offset get pos => _pos;
  Offset get target => _target;
  double get angle => _angle;
  bool get visible => _visible;
  double get speed => _spring.v.distance;

  void setTarget(Offset target) {
    _target = target;
    _spring.target = target;
    if (!_visible) {
      _visible = true;
      _pos = target;
      _spring.setValue(target);
    }
  }

  void hide() {
    _visible = false;
    _target = _pos;
  }

  void update(double dt, Rng rng) {
    if (!_visible) return;

    _prevPos = _pos;
    _prevSpeed = speed;

    _spring.update(dt);
    _pos = _spring.x;

    if (speed > 40) {
      final targetAngle = atan2(_spring.v.dy, _spring.v.dx) + pi / 2;
      _angle += angleDiff(targetAngle, _angle) * (1 - exp(-10 * dt));
    }

    _generateStamps(dt, speed, rng);
  }

  void _generateStamps(double dt, double speed, Rng rng) {
    const stampSpacingFactor = 0.35;
    final stampSpacing = stampSpacingFactor * brushRadius;
    final dist = (_pos - _prevPos).distance;

    if (dist < stampSpacing && speed < 25) {
      _timeSinceLastRestStamp += dt;
      if (_timeSinceLastRestStamp >= 1 / 120) {
        onStamp(_pos, brushRadius, 0.10, speed);
        _timeSinceLastRestStamp = 0;
      }
      return;
    }

    _timeSinceLastRestStamp = 0;
    final n = (dist / stampSpacing).ceil();
    for (int i = 0; i <= n; i++) {
      final t = n == 0 ? 0.5 : i / n;
      final pos = Offset.lerp(_prevPos, _pos, t)!;
      final pr = lerp(0.65, 1.0, (speed / 450).clamp(0, 1));
      onStamp(pos, brushRadius, pr, speed);
    }

    if (_prevSpeed > 350 && speed > 350) {
      final dot = _prevPos.dx * _spring.v.dx + _prevPos.dy * _spring.v.dy;
      if (dot < 0 && rng.chance(0.4)) {
        onStamp(_pos, brushRadius, 1.0, speed, isSqueak: true);
      }
    }
  }
}

class DirtGrid {
  DirtGrid({required this.cellSize, required this.maskScale});

  final double cellSize;
  final double maskScale;

  int _w = 0;
  int _h = 0;
  late Float32List _dirt;
  late Float32List _mask;

  int get w => _w;
  int get h => _h;
  Float32List get dirt => _dirt;
  Float32List get mask => _mask;

  void ensureSize(Size size) {
    final newW = (size.width / cellSize).ceil();
    final newH = (size.height / cellSize).ceil();
    if (_w == newW && _h == newH) return;

    _w = newW;
    _h = newH;
    _dirt = Float32List(_w * _h);
    _mask = Float32List(_w * _h);

    _dirt.fillRange(0, _dirt.length, 1.0);
    _mask.fillRange(0, _mask.length, 0.0);
  }

  void applyStamp(
    Offset center,
    double radius,
    double pressure,
    double k,
    double stampSpacingFactor,
  ) {
    final gridRadius = (radius / cellSize).ceil();
    final cx = (center.dx / cellSize).floor();
    final cy = (center.dy / cellSize).floor();

    for (int gy = -gridRadius; gy <= gridRadius; gy++) {
      for (int gx = -gridRadius; gx <= gridRadius; gx++) {
        final x = cx + gx;
        final y = cy + gy;
        if (x < 0 || x >= _w || y < 0 || y >= _h) continue;

        final dx = (x + 0.5) * cellSize - center.dx;
        final dy = (y + 0.5) * cellSize - center.dy;
        final d = sqrt(dx * dx + dy * dy) / radius;
        final w = smoothstep(1.0, 0.45, d);
        final dD = k * stampSpacingFactor * w * pressure;

        final idx = y * _w + x;
        _dirt[idx] = (_dirt[idx] - dD).clamp(0, 1);
        _mask[idx] = 1 - _dirt[idx];
      }
    }
  }

  void applySpotStamp(
    Offset center,
    double radius,
    double pressure,
    double kSpot,
    double stampSpacingFactor,
  ) {
    final gridRadius = (radius / cellSize).ceil() + 1;
    final cx = (center.dx / cellSize).floor();
    final cy = (center.dy / cellSize).floor();

    for (int gy = -gridRadius; gy <= gridRadius; gy++) {
      for (int gx = -gridRadius; gx <= gridRadius; gx++) {
        final x = cx + gx;
        final y = cy + gy;
        if (x < 0 || x >= _w || y < 0 || y >= _h) continue;

        final dx = (x + 0.5) * cellSize - center.dx;
        final dy = (y + 0.5) * cellSize - center.dy;
        final d = sqrt(dx * dx + dy * dy);
        if (d > radius + 0.5 * radius) continue;

        final normD = d / radius;
        final w = smoothstep(1.0, 0.45, normD);
        final dD = kSpot * stampSpacingFactor * w * pressure;

        final idx = y * _w + x;
        _dirt[idx] = (_dirt[idx] - dD).clamp(0, 1);
        _mask[idx] = 1 - _dirt[idx];
      }
    }
  }

  double getProgress() {
    if (_dirt.isEmpty) return 0;
    double sum = 0;
    for (final v in _dirt) {
      sum += v;
    }
    return 1 - (sum / _dirt.length);
  }

  void reset() {
    _dirt.fillRange(0, _dirt.length, 1.0);
    _mask.fillRange(0, _mask.length, 0.0);
  }

  Uint8List toBytes() {
    final bytes = Uint8List(_dirt.length);
    for (int i = 0; i < _dirt.length; i++) {
      bytes[i] = (255 * _dirt[i]).round();
    }
    return bytes;
  }

  void fromBytes(Uint8List bytes) {
    for (int i = 0; i < min(bytes.length, _dirt.length); i++) {
      _dirt[i] = bytes[i] / 255;
      _mask[i] = 1 - _dirt[i];
    }
  }
}

class Spot {
  Spot({
    required this.center,
    required this.radius,
    required this.style,
    required this.seed,
  });

  final Offset center;
  final double radius;
  final String style;
  final int seed;
  double remaining = 1.0;
}

class SpotManager {
  SpotManager(this.rng);

  Rng rng;
  final List<Spot> spots = [];

  void generateSpots(Size size, DirtType dirtType) {
    spots.clear();
    if (dirtType == DirtType.fog) return;

    final spotData = _getSpotData(dirtType);
    for (final data in spotData) {
      final spot = Spot(
        center: Offset(data.x * size.width, data.y * size.height),
        radius: data.radius,
        style: data.style,
        seed: data.seed,
      );
      spots.add(spot);
    }
  }

  List<_SpotData> _getSpotData(DirtType type) {
    final data = <_SpotData>[];
    rng = Rng(9000 + type.index);

    switch (type) {
      case DirtType.dust:
        data.addAll([
          _SpotData(0.2, 0.3, 18, 'dried_drop', rng.nextInt(10000)),
          _SpotData(0.7, 0.4, 20, 'dried_drop', rng.nextInt(10000)),
          _SpotData(0.5, 0.8, 22, 'dried_drop', rng.nextInt(10000)),
        ]);
        break;
      case DirtType.grime:
        for (int i = 0; i < 6; i++) {
          data.add(
            _SpotData(
              rng.nextDouble(),
              rng.nextDouble() * 0.8 + 0.1,
              14 + rng.nextDouble() * 12,
              'mud_splat',
              rng.nextInt(10000),
            ),
          );
        }
        break;
      case DirtType.frost:
        for (int i = 0; i < 4; i++) {
          data.add(
            _SpotData(
              rng.nextDouble(),
              rng.nextDouble() * 0.8 + 0.1,
              18 + rng.nextDouble() * 10,
              'ice_patch',
              rng.nextInt(10000),
            ),
          );
        }
        break;
      case DirtType.salt:
        for (int i = 0; i < 4; i++) {
          data.add(
            _SpotData(
              rng.nextDouble(),
              rng.nextDouble() * 0.8 + 0.1,
              14 + rng.nextDouble() * 8,
              'salt_crust',
              rng.nextInt(10000),
            ),
          );
        }
        break;
      case DirtType.pollen:
        for (int i = 0; i < 3; i++) {
          data.add(
            _SpotData(
              rng.nextDouble(),
              rng.nextDouble() * 0.8 + 0.1,
              14 + rng.nextDouble() * 6,
              'pollen_clump',
              rng.nextInt(10000),
            ),
          );
        }
        break;
      case DirtType.fog:
        break;
    }
    return data;
  }

  void applyStamp(
    Offset center,
    double radius,
    double pressure,
    double kSpot,
    double stampSpacingFactor,
  ) {
    for (final spot in spots) {
      final dist = (spot.center - center).distance;
      if (dist < spot.radius + 0.5 * radius) {
        final normD = dist / radius;
        final w = smoothstep(1.0, 0.45, normD);
        final dD = kSpot * stampSpacingFactor * w * pressure;
        spot.remaining = (spot.remaining - dD).clamp(0, 1);
      }
    }
  }

  bool get allSpotsCleared => spots.every((s) => s.remaining <= 0.1);
}

class _SpotData {
  _SpotData(this.x, this.y, this.radius, this.style, this.seed);
  final double x, y, radius;
  final String style;
  final int seed;
}

class Droplet {
  Droplet({
    required this.x,
    required this.y,
    required this.r,
    required this.vy,
    required this.phase,
    required this.rCrit,
  });

  double x, y, r, vy, phase;
  final double rCrit;
  bool alive = true;
  String state = 'pinned';
  double stateTimer = 0;
  bool absorbing = false;
  double absorbProgress = 0;

  void update(double dt, Size size, Rng rng) {
    if (!alive) return;

    if (absorbing) {
      absorbProgress += dt / 0.12;
      if (absorbProgress >= 1) {
        alive = false;
      }
      return;
    }

    stateTimer -= dt;
    if (stateTimer <= 0) {
      if (state == 'pinned') {
        state = 'slip';
        stateTimer = 0.2 + rng.nextDouble() * 0.5;
        vy = 0;
      } else {
        state = 'pinned';
        stateTimer = 0.4 + rng.nextDouble() * 2.1;
        vy = 0;
      }
    }

    if (state == 'slip') {
      final a = 900.0;
      final vmax = (60 + 40 * (r - rCrit)).clamp(0, 140).toDouble();
      vy = (vy + a * dt).clamp(0, vmax);
      y += vy * dt;
      x += sin(y * 0.05 + phase) * 0.15 * vy * dt;

      if (y > size.height + r) {
        alive = false;
      }
    } else if (state == 'pinned') {
      y += vy * dt * 0.1;
    }

    if (x < -r || x > size.width + r) alive = false;
  }

  void absorb() {
    absorbing = true;
    absorbProgress = 0;
  }
}

class WipeEngine extends ChangeNotifier {
  WipeEngine({
    required this.tuning,
    required this.sceneId,
    required this.onProgress,
    required this.onComplete,
    required this.onSqueak,
    required this.onSpotResist,
    required this.onWipeTick,
  });

  final Map<String, double> tuning;
  final SceneId sceneId;
  final void Function(double) onProgress;
  final VoidCallback onComplete;
  final VoidCallback onSqueak;
  final VoidCallback onSpotResist;
  final VoidCallback onWipeTick;

  late final Rng rng;
  late final Cloth cloth;
  late final DirtGrid dirtGrid;
  late final SpotManager spotManager;
  final PointerTracker pointerTracker = PointerTracker();
  final List<Droplet> droplets = [];

  bool _completed = false;
  bool _revealing = false;
  double _revealProgress = 0;
  Offset _revealCenter = Offset.zero;
  double _elapsed = 0;
  double _lastProgressReport = 0;

  double get elapsed => _elapsed;
  double get progress => dirtGrid.getProgress();
  bool get isCompleted => _completed;
  bool get isRevealing => _revealing;
  double get revealProgress => _revealProgress;
  Offset get revealCenter => _revealCenter;

  void init(Size size) {
    rng = Rng(SceneRegistry.getScene(sceneId)!.seed);
    cloth = Cloth(
      config: SpringConfig(
        k: tuning['followerHz']! * 2 * pi,
        c: 2 * tuning['followerZeta']! * sqrt(tuning['followerHz']! * 2 * pi),
      ),
      brushRadius: tuning['brushRadius']!,
      onStamp: _onStamp,
    );
    dirtGrid = DirtGrid(cellSize: 8.0, maskScale: 0.5);
    spotManager = SpotManager(rng);

    dirtGrid.ensureSize(size);
    spotManager.generateSpots(size, SceneRegistry.getScene(sceneId)!.dirtType);
    _spawnInitialDroplets(size);
  }

  void _spawnInitialDroplets(Size size) {
    final recipe = SceneRegistry.getScene(sceneId)!;
    if (recipe.dropletRate > 0) {
      for (int i = 0; i < min(20, recipe.dropletRate.toInt()); i++) {
        _spawnDroplet(size);
      }
    }
  }

  void _spawnDroplet(Size size) {
    final r = 2 + 4 * rng.nextDouble() * rng.nextDouble();
    final x = rng.nextDouble() * size.width;
    final y = -r;
    final phase = rng.nextDouble() * 2 * pi;
    final droplet = Droplet(
      x: x,
      y: y,
      r: r,
      vy: 0,
      phase: phase,
      rCrit: tuning['rCrit']!,
    );
    droplets.add(droplet);
  }

  void _onStamp(
    Offset center,
    double radius,
    double pressure,
    double speed, {
    bool isSqueak = false,
  }) {
    if (isSqueak) {
      onSqueak();
      return;
    }

    final k = _getDirtK();
    dirtGrid.applyStamp(center, radius, pressure, k, tuning['stampSpacing']!);

    if (dirtGrid.getProgress() > 0.25 && spotManager.spots.isNotEmpty) {
      final oldSpotsCleared = spotManager.spots
          .where((s) => s.remaining <= 0.1)
          .length;
      spotManager.applyStamp(
        center,
        radius,
        pressure,
        tuning['kSpot']!,
        tuning['stampSpacing']!,
      );
      final newSpotsCleared = spotManager.spots
          .where((s) => s.remaining <= 0.1)
          .length;
      if (newSpotsCleared > oldSpotsCleared) {
        onSpotResist();
      }
    }

    final dist = (center - cloth._prevPos).distance;
    if (dist >= 18 && speed >= 60) {
      onWipeTick();
    }
  }

  double _getDirtK() {
    final recipe = SceneRegistry.getScene(sceneId)!;
    switch (recipe.dirtType) {
      case DirtType.fog:
        return 1.6;
      case DirtType.dust:
        return 0.9;
      case DirtType.grime:
        return 0.55;
      case DirtType.frost:
        return 0.7;
      case DirtType.salt:
        return 0.8;
      case DirtType.pollen:
        return 1.0;
    }
  }

  void update(double dt, Size size) {
    if (_completed) return;

    _elapsed += dt;
    cloth.update(dt, rng);
    _updateDroplets(dt, size);

    _checkCompletion();

    final progress = dirtGrid.getProgress();
    if ((progress - _lastProgressReport).abs() > 0.01) {
      onProgress(progress);
      _lastProgressReport = progress;
    }

    notifyListeners();
  }

  void _updateDroplets(double dt, Size size) {
    final recipe = SceneRegistry.getScene(sceneId)!;

    if (recipe.dropletRate > 0 &&
        droplets.length < tuning['maxDroplets']!.toInt()) {
      if (rng.chance(recipe.dropletRate * dt)) {
        _spawnDroplet(size);
      }
    }

    for (final droplet in droplets) {
      droplet.update(dt, size, rng);
    }

    _handleDropletMerges();
    _handleDropletWipes();

    droplets.removeWhere((d) => !d.alive);
  }

  void _handleDropletMerges() {
    for (int i = 0; i < droplets.length; i++) {
      for (int j = i + 1; j < droplets.length; j++) {
        final d1 = droplets[i];
        final d2 = droplets[j];
        final dist = (Offset(d1.x, d1.y) - Offset(d2.x, d2.y)).distance;
        if (dist < 0.8 * (d1.r + d2.r)) {
          final newR = sqrt(d1.r * d1.r + d2.r * d2.r) * 0.98;
          final newX =
              (d1.x * d1.r * d1.r + d2.x * d2.r * d2.r) /
              (d1.r * d1.r + d2.r * d2.r);
          final newY =
              (d1.y * d1.r * d1.r + d2.y * d2.r * d2.r) /
              (d1.r * d1.r + d2.r * d2.r);
          final newVy =
              (d1.vy * d1.r * d1.r + d2.vy * d2.r * d2.r) /
              (d1.r * d1.r + d2.r * d2.r);

          d1.r = newR;
          d1.x = newX;
          d1.y = newY;
          d1.vy = newVy;

          if (rng.chance(0.35)) {
            final satR = 1.2 + rng.nextDouble() * 0.6;
            droplets.add(
              Droplet(
                x: newX,
                y: newY,
                r: satR,
                vy: 0,
                phase: rng.nextDouble() * 2 * pi,
                rCrit: tuning['rCrit']!,
              ),
            );
          }

          d2.alive = false;
        }
      }
    }
  }

  void _handleDropletWipes() {
    if (!cloth.visible) return;
    for (final droplet in droplets) {
      final dist = (Offset(droplet.x, droplet.y) - cloth.pos).distance;
      if (dist < 0.9 * cloth.brushRadius) {
        droplet.absorb();
      }
    }
  }

  void _checkCompletion() {
    final progress = dirtGrid.getProgress();
    if (progress >= tuning['completionThreshold']! &&
        spotManager.allSpotsCleared &&
        !_completed) {
      _completed = true;
      _revealing = true;
      _revealCenter = cloth.pos;
      onComplete();
    }
  }

  void updateReveal(double dt) {
    if (!_revealing) return;
    _revealProgress += dt / tuning['revealSeconds']!;
    if (_revealProgress >= 1) {
      _revealProgress = 1;
      _revealing = false;
    }
    notifyListeners();
  }

  void setClothTarget(Offset target) {
    cloth.setTarget(target);
  }

  void hideCloth() {
    cloth.hide();
  }

  Map<String, dynamic> saveState() {
    return {
      'scene': sceneId.index,
      'grid': base64Encode(dirtGrid.toBytes()),
      'spots': spotManager.spots
          .map((s) => {'x': s.center.dx, 'y': s.center.dy, 's': s.remaining})
          .toList(),
      'elapsed': _elapsed,
    };
  }

  void loadState(Map<String, dynamic> state, Size size) {
    init(size);
    if (state['grid'] != null) {
      dirtGrid.fromBytes(base64Decode(state['grid'] as String));
    }
    if (state['spots'] != null) {
      for (
        int i = 0;
        i < (state['spots'] as List).length && i < spotManager.spots.length;
        i++
      ) {
        final s = (state['spots'] as List)[i];
        spotManager.spots[i].remaining = (s['s'] as num).toDouble();
      }
    }
    _elapsed = (state['elapsed'] as num?)?.toDouble() ?? 0;
  }

  ui.Image? _sharpCache;
  ui.Image? _blurredCache;
  ui.Image? _dirtyCache;

  ui.Image? get sharpImage => _sharpCache;
  ui.Image? get dirtyImage => _dirtyCache;

  void ensureImagesBuilt(Size size) {
    if (_sharpCache != null) return;

    final recipe = SceneRegistry.getScene(sceneId)!;
    final pixelRatio = 2.0; // Cap at 2.0 for performance
    final renderSize = Size(size.width * pixelRatio, size.height * pixelRatio);
    final recorder = ui.PictureRecorder();
    final renderCanvas = Canvas(recorder);

    // Draw sharp scene
    _drawSceneForCache(renderCanvas, renderSize, recipe, pixelRatio);
    _sharpCache = recorder.endRecording().toImageSync(
      renderSize.width.toInt(),
      renderSize.height.toInt(),
    );

    // Draw blurred
    final blurRecorder = ui.PictureRecorder();
    final blurCanvas = Canvas(blurRecorder);
    blurCanvas.drawImageRect(
      _sharpCache!,
      Rect.fromLTWH(
        0,
        0,
        _sharpCache!.width.toDouble(),
        _sharpCache!.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, renderSize.width, renderSize.height),
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: 14 * pixelRatio,
          sigmaY: 14 * pixelRatio,
        ),
    );
    _blurredCache = blurRecorder.endRecording().toImageSync(
      renderSize.width.toInt(),
      renderSize.height.toInt(),
    );

    // Draw dirty (blurred + dirt baked in)
    final dirtyRecorder = ui.PictureRecorder();
    final dirtyCanvas = Canvas(dirtyRecorder);
    dirtyCanvas.drawImage(_blurredCache!, Offset.zero, Paint());
    _drawDirtForCache(dirtyCanvas, renderSize, recipe, pixelRatio);
    _dirtyCache = dirtyRecorder.endRecording().toImageSync(
      renderSize.width.toInt(),
      renderSize.height.toInt(),
    );
  }

  void _drawSceneForCache(
    Canvas canvas,
    Size size,
    SceneRecipe recipe,
    double pixelRatio,
  ) {
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
          accent.blur * pixelRatio,
        );
      }

      switch (accent.type) {
        case AccentType.litWindow:
          canvas.drawRect(
            Rect.fromCenter(
              center: pos,
              width: accent.size.width * pixelRatio,
              height: accent.size.height * pixelRatio,
            ),
            accentPaint,
          );
          break;
        case AccentType.bokeh:
          canvas.drawCircle(
            pos,
            accent.size.width * pixelRatio / 2,
            accentPaint,
          );
          break;
        case AccentType.sunDisc:
          canvas.drawCircle(
            pos,
            accent.size.width * pixelRatio / 2,
            accentPaint,
          );
          break;
        case AccentType.sunGlow:
          final glowPaint = Paint()
            ..shader = ui.Gradient.radial(
              pos,
              accent.size.width * pixelRatio / 2,
              [
                accent.color.withValues(alpha: accent.alpha),
                accent.color.withValues(alpha: 0),
              ],
            );
          canvas.drawCircle(pos, accent.size.width * pixelRatio / 2, glowPaint);
          break;
        case AccentType.star:
          canvas.drawCircle(
            pos,
            accent.size.width * pixelRatio / 2,
            accentPaint,
          );
          break;
        case AccentType.seaSparkle:
          canvas.drawCircle(
            pos,
            accent.size.width * pixelRatio / 2,
            accentPaint,
          );
          break;
        case AccentType.neon:
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromCenter(
                center: pos,
                width: accent.size.width * pixelRatio,
                height: accent.size.height * pixelRatio,
              ),
              topLeft: Radius.circular(4 * pixelRatio),
              topRight: Radius.circular(4 * pixelRatio),
            ),
            accentPaint
              ..maskFilter = ui.MaskFilter.blur(
                ui.BlurStyle.normal,
                accent.blur * pixelRatio,
              ),
          );
          break;
        case AccentType.neonGlow:
          final glowPaint = Paint()
            ..shader = ui.Gradient.linear(
              Offset(pos.dx, pos.dy - accent.size.height * pixelRatio / 2),
              Offset(pos.dx, pos.dy + accent.size.height * pixelRatio / 2),
              [
                accent.color.withValues(alpha: 0),
                accent.color.withValues(alpha: accent.alpha),
                accent.color.withValues(alpha: 0),
              ],
            );
          canvas.drawRect(
            Rect.fromCenter(
              center: pos,
              width: accent.size.width * pixelRatio * 2,
              height: accent.size.height * pixelRatio * 2,
            ),
            glowPaint,
          );
          break;
        case AccentType.blossomCluster:
          canvas.drawOval(
            Rect.fromCenter(
              center: pos,
              width: accent.size.width * pixelRatio,
              height: accent.size.height * pixelRatio,
            ),
            accentPaint,
          );
          break;
        case AccentType.butterfly:
        case AccentType.petal:
          canvas.drawCircle(
            pos,
            accent.size.width * pixelRatio / 2,
            accentPaint,
          );
          break;
      }
    }
  }

  void _drawDirtForCache(
    Canvas canvas,
    Size size,
    SceneRecipe recipe,
    double pixelRatio,
  ) {
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
            ..shader = ui.Gradient.radial(Offset(x, y), r * pixelRatio, [
              Color(0xFFE8EEF5).withValues(alpha: alpha),
              Color(0xFFE8EEF5).withValues(alpha: 0),
            ]);
          canvas.drawCircle(Offset(x, y), r * pixelRatio, blotchPaint);
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
            r * pixelRatio,
            Paint()..color = Color(0xFFCBB89E).withValues(alpha: alpha),
          );
        }

        for (int i = 0; i < 6; i++) {
          final x = rng.nextDouble() * size.width;
          final y = rng.nextDouble() * size.height * 0.8;
          final w = 2 + rng.nextDouble() * 4;
          final len = 80 + rng.nextDouble() * 180;
          final streakPaint = Paint()
            ..shader = ui.Gradient.linear(
              Offset(x, y),
              Offset(x, y + len * pixelRatio),
              [
                Color(0xFFCBB89E).withValues(alpha: 0.12),
                Color(0xFFCBB89E).withValues(alpha: 0),
              ],
            );
          canvas.drawRect(
            Rect.fromLTWH(
              x - w * pixelRatio / 2,
              y,
              w * pixelRatio,
              len * pixelRatio,
            ),
            streakPaint,
          );
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
          final w = (2 + rng.nextDouble() * 4) * pixelRatio;
          final len = (80 + rng.nextDouble() * 180) * pixelRatio;
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
                Offset(cx + bx * pixelRatio, cy + by * pixelRatio),
                crystalPaint..strokeWidth = (2 - branch * 0.5) * pixelRatio,
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
          final r = (0.5 + rng.nextDouble() * 0.7) * pixelRatio;
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
          final r = (0.5 + rng.nextDouble() * 0.5) * pixelRatio;
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

  ui.Image createMaskImage(Size size) {
    final maskScale = 0.5;
    final maskW = (size.width * maskScale).ceil();
    final maskH = (size.height * maskScale).ceil();
    final recorder = ui.PictureRecorder();
    final maskCanvas = Canvas(recorder);

    final grid = dirtGrid;
    final cellSize = 8.0;
    final paint = Paint()..blendMode = BlendMode.plus;

    for (int y = 0; y < grid.h; y++) {
      for (int x = 0; x < grid.w; x++) {
        final clean = grid.mask[y * grid.w + x];
        if (clean > 0) {
          paint.color = ui.Color.fromARGB((255 * clean).round(), 255, 255, 255);
          maskCanvas.drawRect(
            Rect.fromLTWH(
              x * cellSize * maskScale,
              y * cellSize * maskScale,
              cellSize * maskScale,
              cellSize * maskScale,
            ),
            paint,
          );
        }
      }
    }

    // Draw droplet trails from the grid
    for (final droplet in droplets) {
      if (droplet.state == 'slip' && droplet.alive) {
        // Trails are already in the mask from the stamp mechanism
      }
    }

    final picture = recorder.endRecording();
    return picture.toImageSync(maskW, maskH);
  }

  void disposeImages() {
    _sharpCache?.dispose();
    _blurredCache?.dispose();
    _dirtyCache?.dispose();
    _sharpCache = null;
    _blurredCache = null;
    _dirtyCache = null;
  }
}
