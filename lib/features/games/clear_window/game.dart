import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/features/levels/level_game.dart';

import 'levels.dart';
import 'scenes.dart';

/// Tunables for the wipe feel.
class _Feel {
  static const cell = 6.0; // logical px per dirt cell
  static const brushFrac = 0.1; // brush radius as a fraction of glass width
  static const strength = 0.6; // dirt removed per brush-radius of travel
  static const finishAt = 0.95; // auto-polish the rest from here
  static const friendClearAt = 0.3; // average dirt around the friend
}

class ClearWindowLevel extends StatefulWidget {
  const ClearWindowLevel({required this.host, required this.tint, super.key});

  final LevelHost host;
  final Color tint;

  @override
  State<ClearWindowLevel> createState() => _ClearWindowLevelState();
}

class _Sparkle {
  _Sparkle(this.p, this.v, this.life);
  Offset p;
  Offset v;
  double life;
  double age = 0;
}

class _Drop {
  _Drop(this.x, this.y, this.r, this.speed);
  double x, y, r, speed;
}

class _ClearWindowLevelState extends State<ClearWindowLevel>
    with SingleTickerProviderStateMixin {
  late final WindowLevel _lv = ClearWindowLevels.build(widget.host.level);
  late final DirtStyle _style = DirtStyle.of(_lv.dirt);
  late final ScenePainter _scene = ScenePainter(
    _lv.scene,
    _lv.time,
    widget.host.level * 31,
  );

  // Dirt grid, built once the glass size is known.
  Rect? _glass;
  Path? _shape;
  int _gw = 0, _gh = 0;
  late Float32List _dirt; // remaining dirt 0..1
  late Float32List _hard; // passes multiplier (mud spots > 1)
  late Uint8List _inside; // 1 if the cell is on the glass
  int _insideCount = 1;
  double _progress = 0;

  ui.Image? _maskImage;
  ui.Image? _spotImage;
  bool _maskDirty = true;
  bool _decoding = false;
  ui.Picture? _texture;

  late final Ticker _ticker = createTicker(_tick);
  final _repaint = ValueNotifier<int>(0);
  final _pct = ValueNotifier<int>(0);
  Duration _last = Duration.zero;
  double _time = 0;

  Offset? _finger;
  Offset? _lastFinger;
  Offset _lastDir = Offset.zero;
  double _speed = 0;
  CalmSoundHandle? _wipeLoop;
  final List<_Sparkle> _sparkles = [];
  final List<_Drop> _drops = [];
  final _rng = math.Random(7);

  bool _friendFound = false;
  double _friendAnim = 0;
  String? _banner;
  Timer? _bannerTimer;
  bool _finishing = false;
  bool _solved = false;
  double _glint = -1;

  @override
  void initState() {
    super.initState();
    _ticker.start();
    if (_style.drops) {
      widget.host.audio.playAmbience(SoundId.rainLoop, volume: 0.3);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    _pct.dispose();
    _bannerTimer?.cancel();
    final loop = _wipeLoop;
    if (loop != null) {
      widget.host.audio.fadeAndStop(loop, const Duration(milliseconds: 200));
    }
    widget.host.audio.stopAmbience();
    _maskImage?.dispose();
    _spotImage?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- setup --
  Path _shapePath(Rect r) {
    switch (_lv.shape) {
      case WindowShape.round:
        return Path()..addOval(r);
      case WindowShape.arch:
        final rad = r.width / 2;
        return Path()
          ..moveTo(r.left, r.bottom)
          ..lineTo(r.left, r.top + rad)
          ..arcToPoint(
            Offset(r.right, r.top + rad),
            radius: Radius.circular(rad),
          )
          ..lineTo(r.right, r.bottom)
          ..close();
      default:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)));
    }
  }

  void _setup(Rect glass) {
    if (_glass == glass) return;
    // Keep what was already wiped if the layout changes size.
    final hadGrid = _glass != null;
    final oldW = _gw, oldH = _gh;
    final oldDirt = hadGrid ? _dirt : null;
    _glass = glass;
    _shape = _shapePath(glass);
    _gw = (glass.width / _Feel.cell).ceil();
    _gh = (glass.height / _Feel.cell).ceil();
    final n = _gw * _gh;
    _dirt = Float32List(n);
    _hard = Float32List(n);
    _inside = Uint8List(n);
    final rng = math.Random(_lv.level * 977);

    // Mud splats: centre, radius in cells.
    final spots = <(double, double, double)>[
      for (var k = 0; k < _style.spots; k++)
        (
          rng.nextDouble() * _gw,
          rng.nextDouble() * _gh,
          3 + rng.nextDouble() * 5,
        ),
    ];
    _insideCount = 0;
    for (var y = 0; y < _gh; y++) {
      for (var x = 0; x < _gw; x++) {
        final i = y * _gw + x;
        final c =
            glass.topLeft +
            Offset((x + 0.5) * _Feel.cell, (y + 0.5) * _Feel.cell);
        if (!_shape!.contains(c)) continue;
        _inside[i] = 1;
        _insideCount++;
        _dirt[i] = 1;
        var hard = _style.hardness * (0.85 + rng.nextDouble() * 0.3);
        if (_style.streaks) {
          hard *= 0.9 + 0.35 * math.sin(x * 0.9 + math.sin(y * 0.05) * 2).abs();
        }
        for (final (sx, sy, sr) in spots) {
          final d = math.sqrt((x - sx) * (x - sx) + (y - sy) * (y - sy));
          if (d < sr) hard += 1.6 * (1 - d / sr);
        }
        _hard[i] = hard;
      }
    }
    if (oldDirt != null && oldW > 0 && oldH > 0) {
      for (var y = 0; y < _gh; y++) {
        for (var x = 0; x < _gw; x++) {
          final i = y * _gw + x;
          if (_inside[i] == 0) continue;
          final ox = (x * oldW / _gw).floor().clamp(0, oldW - 1);
          final oy = (y * oldH / _gh).floor().clamp(0, oldH - 1);
          _dirt[i] = oldDirt[oy * oldW + ox];
        }
      }
      _updateProgress();
    }
    _texture = _buildTexture(glass);
    if (_style.drops) {
      _drops
        ..clear()
        ..addAll([
          for (var k = 0; k < 22; k++)
            _Drop(
              glass.left + rng.nextDouble() * glass.width,
              glass.top + rng.nextDouble() * glass.height,
              2 + rng.nextDouble() * 3.5,
              6 + rng.nextDouble() * 30,
            ),
        ]);
    }
    _maskDirty = true;
  }

  ui.Picture _buildTexture(Rect g) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final rng = math.Random(_lv.level);
    if (_style.specks) {
      for (var k = 0; k < 420; k++) {
        c.drawCircle(
          Offset(
            g.left + rng.nextDouble() * g.width,
            g.top + rng.nextDouble() * g.height,
          ),
          0.5 + rng.nextDouble() * 1.4,
          Paint()
            ..color = const Color(0xFF7A6A55)
                .withValues(alpha: 0.25 + rng.nextDouble() * 0.3),
        );
      }
    }
    if (_style.streaks) {
      final p = Paint()
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.35);
      for (var k = 0; k < 60; k++) {
        final x = g.left + rng.nextDouble() * g.width;
        final y = g.top + rng.nextDouble() * g.height;
        c.drawLine(
          Offset(x, y),
          Offset(x + rng.nextDouble() * 2 - 1, y + 20 + rng.nextDouble() * 50),
          p,
        );
      }
    }
    if (_style.crystals) {
      final p = Paint()
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.7);
      for (var k = 0; k < 26; k++) {
        final o = Offset(
          g.left + rng.nextDouble() * g.width,
          g.top + rng.nextDouble() * g.height,
        );
        _crystal(
          c,
          o,
          10 + rng.nextDouble() * 22,
          rng.nextDouble() * math.pi,
          p,
          2,
        );
      }
    }
    if (!_style.specks && !_style.crystals) {
      // Condensation beads.
      for (var k = 0; k < 160; k++) {
        final o = Offset(
          g.left + rng.nextDouble() * g.width,
          g.top + rng.nextDouble() * g.height,
        );
        final r = 0.8 + rng.nextDouble() * 2;
        c.drawCircle(
          o,
          r,
          Paint()..color = Colors.white.withValues(alpha: 0.5),
        );
      }
    }
    return rec.endRecording();
  }

  void _crystal(Canvas c, Offset o, double len, double a, Paint p, int depth) {
    for (var k = 0; k < 6; k++) {
      final ang = a + k * math.pi / 3;
      final e = o + Offset(math.cos(ang), math.sin(ang)) * len;
      c.drawLine(o, e, p);
      if (depth > 0) {
        final mid = Offset.lerp(o, e, 0.6)!;
        for (final side in [-0.6, 0.6]) {
          c.drawLine(
            mid,
            mid +
                Offset(math.cos(ang + side), math.sin(ang + side)) * len * 0.3,
            p,
          );
        }
      }
    }
  }

  // ----------------------------------------------------------- masks --
  void _refreshMasks() {
    if (!_maskDirty || _decoding || _glass == null) return;
    _maskDirty = false;
    _decoding = true;
    final n = _gw * _gh;
    final a = Uint8List(n * 4);
    final b = Uint8List(n * 4);
    for (var i = 0; i < n; i++) {
      final d = _dirt[i];
      final o = i * 4;
      a[o] = a[o + 1] = a[o + 2] = 255;
      a[o + 3] = (d * 255).round();
      final heavy = ((_hard[i] - _style.hardness * 1.2) / 1.2).clamp(0.0, 1.0);
      b[o] = b[o + 1] = b[o + 2] = 255;
      b[o + 3] = (heavy * d.clamp(0.0, 1.0) * 255).round();
    }
    var pending = 2;
    void done() {
      if (--pending == 0) {
        _decoding = false;
        _repaint.value++;
      }
    }

    ui.decodeImageFromPixels(a, _gw, _gh, ui.PixelFormat.rgba8888, (img) {
      _maskImage?.dispose();
      _maskImage = img;
      done();
    });
    if (_style.spots > 0) {
      ui.decodeImageFromPixels(b, _gw, _gh, ui.PixelFormat.rgba8888, (img) {
        _spotImage?.dispose();
        _spotImage = img;
        done();
      });
    } else {
      done();
    }
  }

  // ------------------------------------------------------------ wiping --
  void _wipeSegment(Offset from, Offset to) {
    final g = _glass;
    if (g == null || _finishing) return;
    final radius = g.width * _Feel.brushFrac;
    final dist = (to - from).distance;
    final steps = math.max(1, (dist / (radius * 0.3)).ceil());
    final perStep = dist / steps;
    var cleaned = 0;
    for (var s = 1; s <= steps; s++) {
      final p = Offset.lerp(from, to, s / steps)! - g.topLeft;
      final cx = p.dx / _Feel.cell, cy = p.dy / _Feel.cell;
      final rc = radius / _Feel.cell;
      final x0 = math.max(0, (cx - rc).floor()),
          x1 = math.min(_gw - 1, (cx + rc).ceil());
      final y0 = math.max(0, (cy - rc).floor()),
          y1 = math.min(_gh - 1, (cy + rc).ceil());
      for (var y = y0; y <= y1; y++) {
        for (var x = x0; x <= x1; x++) {
          final i = y * _gw + x;
          if (_inside[i] == 0 || _dirt[i] <= 0) continue;
          final dx = x + 0.5 - cx, dy = y + 0.5 - cy;
          final dd = math.sqrt(dx * dx + dy * dy) / rc;
          if (dd >= 1) continue;
          final falloff = 1 - dd * dd;
          final amt =
              _Feel.strength * falloff * (perStep / radius + 0.04) / _hard[i];
          final before = _dirt[i];
          _dirt[i] = math.max(0, before - amt);
          if (before > 0.05 && _dirt[i] <= 0.05) {
            _dirt[i] = 0;
            cleaned++;
          }
        }
      }
    }
    if (cleaned > 0 && _sparkles.length < 80 && _rng.nextDouble() < 0.5) {
      _sparkles.add(
        _Sparkle(
          to,
          Offset(_rng.nextDouble() * 40 - 20, -20 - _rng.nextDouble() * 30),
          0.6,
        ),
      );
    }
    _maskDirty = true;
    _updateProgress();
  }

  void _updateProgress() {
    var sum = 0.0;
    for (var i = 0; i < _dirt.length; i++) {
      if (_inside[i] == 1) sum += _dirt[i];
    }
    _progress = 1 - sum / math.max(1, _insideCount);
    _pct.value = (_progress * 100).floor();
    _checkFriend();
    if (!_finishing && _progress >= _Feel.finishAt) {
      _finishing = true;
      widget.host.audio.play(SoundId.completeSoft, volume: 0.6);
    }
  }

  void _checkFriend() {
    final g = _glass;
    if (_friendFound || g == null) return;
    final f = _lv.friend;
    final c = Offset(f.pos.dx * g.width, f.pos.dy * g.height) / _Feel.cell;
    final r = f.size * g.width * 0.6 / _Feel.cell;
    var sum = 0.0;
    var n = 0;
    for (var y = (c.dy - r).floor(); y <= (c.dy + r).ceil(); y++) {
      for (var x = (c.dx - r).floor(); x <= (c.dx + r).ceil(); x++) {
        if (x < 0 || y < 0 || x >= _gw || y >= _gh) continue;
        final i = y * _gw + x;
        if (_inside[i] == 0) continue;
        sum += _dirt[i];
        n++;
      }
    }
    if (n > 0 && sum / n < _Feel.friendClearAt) {
      _friendFound = true;
      _friendAnim = 0.0001;
      widget.host.audio.play(SoundId.windChime2, volume: 0.6);
      widget.host.haptics.fire(HapticEvent.moteCatch);
      _showBanner('You found ${friendName(f.kind)}!');
      setState(() {});
    }
  }

  void _showBanner(String text) {
    _bannerTimer?.cancel();
    setState(() => _banner = text);
    _bannerTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  void _down(Offset p) {
    if (_solved) return;
    _finger = p;
    _lastFinger = p;
    _speed = 0;
    widget.host.audio.play(SoundId.wipeLoop, volume: 0, loop: true).then((h) {
      if (_finger == null && h != null) {
        widget.host.audio.fadeAndStop(h, const Duration(milliseconds: 100));
      } else {
        _wipeLoop = h;
      }
    });
  }

  void _move(Offset p, Duration stamp) {
    final last = _lastFinger;
    if (last == null || _solved) return;
    final delta = p - last;
    _wipeSegment(last, p);
    _lastFinger = p;
    _finger = p;
    final inst = delta.distance / (1 / 60);
    _speed = _speed * 0.7 + inst * 0.3;
    final loop = _wipeLoop;
    if (loop != null) {
      widget.host.audio.setVolume(loop, (_speed / 1400).clamp(0.0, 0.55));
      widget.host.audio.setRate(loop, 0.85 + (_speed / 3000).clamp(0.0, 0.4));
    }
    // Squeak on quick direction changes.
    if (delta.distance > 4) {
      final dir = delta / delta.distance;
      if (_speed > 600 &&
          dir.dx * _lastDir.dx + dir.dy * _lastDir.dy < -0.3 &&
          _rng.nextDouble() < 0.5) {
        const squeaks = [
          SoundId.wipeSqueak1,
          SoundId.wipeSqueak2,
          SoundId.wipeSqueak3,
        ];
        widget.host.audio.play(
          squeaks[_rng.nextInt(3)],
          volume: 0.35,
          rate: 0.9 + _rng.nextDouble() * 0.2,
        );
        widget.host.haptics.fire(HapticEvent.wipeTick);
      }
      _lastDir = dir;
    }
  }

  void _up() {
    _finger = null;
    _lastFinger = null;
    final loop = _wipeLoop;
    _wipeLoop = null;
    if (loop != null) {
      widget.host.audio.fadeAndStop(loop, const Duration(milliseconds: 180));
    }
  }

  // -------------------------------------------------------------- tick --
  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    _time += dt;

    for (final s in _sparkles) {
      s.age += dt;
      s.p += s.v * dt;
      s.v += const Offset(0, 30) * dt;
    }
    _sparkles.removeWhere((s) => s.age >= s.life);

    final g = _glass;
    if (g != null) {
      for (final d in _drops) {
        d.y += d.speed * dt;
        if (d.y > g.bottom + 10) {
          d.y = g.top - 10;
          d.x = g.left + _rng.nextDouble() * g.width;
        }
      }
    }

    if (_friendAnim > 0 && _friendAnim < 1) {
      _friendAnim = math.min(1, _friendAnim + dt * 1.2);
    }

    if (_finishing && !_solved && g != null) {
      var any = false;
      for (var i = 0; i < _dirt.length; i++) {
        if (_dirt[i] > 0) {
          _dirt[i] = math.max(0, _dirt[i] - dt * 1.4);
          any = true;
        }
      }
      _maskDirty = true;
      if (!any) {
        _solved = true;
        _progress = 1;
        _pct.value = 100;
        _glint = 0;
        if (!_friendFound) {
          _friendFound = true;
          _friendAnim = 0.0001;
        }
        widget.host.audio.play(SoundId.windChime0, volume: 0.5);
        setState(() {});
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (mounted) {
            widget.host.onSolved(
              note: 'You met ${friendName(_lv.friend.kind)}.',
            );
          }
        });
      }
    }
    if (_glint >= 0 && _glint < 1) _glint = math.min(1, _glint + dt * 1.1);

    _refreshMasks();
    _repaint.value++;
  }

  // ------------------------------------------------------------ build --
  Rect _glassRect(Size size) {
    const margin = 34.0;
    final aspect = ClearWindowLevels.aspect(_lv.shape);
    var w = size.width - margin * 2;
    var h = w / aspect;
    final maxH = size.height - margin * 2 - 30;
    if (h > maxH) {
      h = maxH;
      w = h * aspect;
    }
    return Rect.fromLTWH(
      (size.width - w) / 2,
      (size.height - h) / 2 - 10,
      w,
      h,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(colors.surface, widget.tint, dark ? 0.14 : 0.2)!,
            Color.lerp(
              colors.surface,
              const Color(0xFFB08968),
              dark ? 0.08 : 0.12,
            )!,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = Size(box.maxWidth, box.maxHeight);
                  final glass = _glassRect(size);
                  _setup(glass);
                  return Stack(
                    children: [
                      Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (e) => _down(e.localPosition),
                        onPointerMove: (e) =>
                            _move(e.localPosition, e.timeStamp),
                        onPointerUp: (_) => _up(),
                        onPointerCancel: (_) => _up(),
                        child: CustomPaint(
                          size: size,
                          painter: _WindowPainter(this, _repaint),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _banner == null
                                ? const SizedBox(height: 40)
                                : _Banner(
                                    key: ValueKey(_banner),
                                    text: _banner!,
                                    tint: widget.tint,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: ValueListenableBuilder<int>(
                valueListenable: _pct,
                builder: (context, pct, _) => _CleanMeter(
                  progress: pct / 100,
                  label: _solved ? 'Sparkling clean' : '$pct% clean',
                  friendFound: _friendFound,
                  friend: _lv.friend.kind,
                  tint: widget.tint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.tint, super.key});
  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: tint.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _CleanMeter extends StatelessWidget {
  const _CleanMeter({
    required this.progress,
    required this.label,
    required this.friendFound,
    required this.friend,
    required this.tint,
  });

  final double progress;
  final String label;
  final bool friendFound;
  final FriendKind friend;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: progress),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      color: tint,
                      backgroundColor: tint.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: friendFound
                ? 'Friend found'
                : 'Someone is hiding behind the glass',
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: friendFound
                    ? tint.withValues(alpha: 0.2)
                    : colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: friendFound
                  ? CustomPaint(painter: _FriendIcon(friend))
                  : Icon(
                      Icons.question_mark_rounded,
                      color: colors.onSurfaceVariant,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendIcon extends CustomPainter {
  _FriendIcon(this.kind);
  final FriendKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    paintFriend(
      canvas,
      kind,
      size.center(Offset(0, size.height * 0.08)),
      size.width * 0.6,
      0,
      0,
    );
  }

  @override
  bool shouldRepaint(covariant _FriendIcon old) => old.kind != kind;
}

class _WindowPainter extends CustomPainter {
  _WindowPainter(this.s, Listenable repaint) : super(repaint: repaint);
  final _ClearWindowLevelState s;

  static const _wood = Color(0xFFB98A62);
  static const _woodDark = Color(0xFF8A6448);
  static const _woodLight = Color(0xFFD6AE85);

  @override
  void paint(Canvas canvas, Size size) {
    final g = s._glass;
    final shape = s._shape;
    if (g == null || shape == null) return;
    final t = s._time;
    final st = s._style;
    final friend = s._lv.friend;

    _paintFrame(canvas, g, shape);

    // Clear scene.
    canvas.save();
    canvas.clipPath(shape);
    s._scene.paint(canvas, g, t, friend: friend, found: s._friendAnim);

    // Dirty glass layer.
    canvas.saveLayer(g.inflate(2), Paint());
    canvas.saveLayer(
      g.inflate(2),
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: st.blur,
          sigmaY: st.blur,
          tileMode: TileMode.clamp,
        ),
    );
    s._scene.paint(canvas, g, t, friend: friend);
    canvas.restore();
    canvas.drawRect(
      g,
      Paint()..color = st.tint.withValues(alpha: st.tintAlpha),
    );
    final tex = s._texture;
    if (tex != null) canvas.drawPicture(tex);
    final spot = s._spotImage;
    if (spot != null) {
      canvas.drawImageRect(
        spot,
        Rect.fromLTWH(0, 0, spot.width.toDouble(), spot.height.toDouble()),
        Rect.fromLTWH(g.left, g.top, s._gw * _Feel.cell, s._gh * _Feel.cell),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = const ColorFilter.mode(
            Color(0xFF8C6A4A),
            BlendMode.srcIn,
          ),
      );
    }
    final mask = s._maskImage;
    if (mask != null) {
      canvas.drawImageRect(
        mask,
        Rect.fromLTWH(0, 0, mask.width.toDouble(), mask.height.toDouble()),
        Rect.fromLTWH(g.left, g.top, s._gw * _Feel.cell, s._gh * _Feel.cell),
        Paint()
          ..blendMode = BlendMode.dstIn
          ..filterQuality = FilterQuality.medium,
      );
    }
    canvas.restore();

    // Raindrops on the outside of the glass.
    for (final d in s._drops) {
      final c = Offset(d.x, d.y);
      canvas.drawLine(
        c - Offset(0, d.r * 4),
        c,
        Paint()
          ..strokeWidth = d.r * 0.6
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        c,
        d.r,
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        c - Offset(d.r * 0.3, d.r * 0.3),
        d.r * 0.35,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }

    // Glass reflection.
    canvas.drawPath(
      Path()
        ..moveTo(g.left + g.width * 0.1, g.top)
        ..lineTo(g.left + g.width * 0.3, g.top)
        ..lineTo(g.left, g.top + g.height * 0.35)
        ..lineTo(g.left, g.top + g.height * 0.15)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // Finishing glint sweep.
    final gl = s._glint;
    if (gl >= 0 && gl < 1) {
      final x = g.left - g.width * 0.4 + gl * g.width * 1.8;
      canvas.drawPath(
        Path()
          ..moveTo(x, g.top)
          ..lineTo(x + 40, g.top)
          ..lineTo(x - g.height * 0.4 + 40, g.bottom)
          ..lineTo(x - g.height * 0.4, g.bottom)
          ..close(),
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.35 * math.sin(gl * math.pi),
          ),
      );
    }
    canvas.restore();

    _paintMullions(canvas, g);

    // Sparkles from freshly cleaned glass.
    for (final sp in s._sparkles) {
      final a = 1 - sp.age / sp.life;
      _star(canvas, sp.p, 3 + 3 * a, Colors.white.withValues(alpha: a));
    }

    // Cloth under the finger.
    final f = s._finger;
    if (f != null) {
      final r = g.width * _Feel.brushFrac;
      canvas.save();
      canvas.translate(f.dx, f.dy);
      canvas.rotate(math.sin(t * 2) * 0.1 + 0.2);
      final cloth = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r * 1.5, height: r * 1.2),
        Radius.circular(r * 0.35),
      );
      canvas.drawRRect(
        cloth.shift(const Offset(0, 3)),
        Paint()..color = Colors.black.withValues(alpha: 0.12),
      );
      canvas.drawRRect(
        cloth,
        Paint()..color = const Color(0xFF8EC9E8).withValues(alpha: 0.9),
      );
      final fold = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1.5;
      for (var k = -1; k <= 1; k++) {
        canvas.drawLine(
          Offset(-r * 0.6, k * r * 0.3),
          Offset(r * 0.6, k * r * 0.3 + 3),
          fold,
        );
      }
      canvas.restore();
    }
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r),
      p,
    );
  }

  void _paintFrame(Canvas canvas, Rect g, Path shape) {
    const fw = 16.0;
    // Wall shadow.
    canvas.drawPath(
      shape.shift(const Offset(0, 8)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fw * 2,
    );
    // Frame.
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = fw * 2
        ..color = _wood,
    );
    canvas.drawPath(
      shape.shift(const Offset(0, -1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _woodLight,
    );
    // Sill with a little potted plant.
    final sill = Rect.fromLTWH(
      g.left - fw - 10,
      g.bottom + fw - 4,
      g.width + fw * 2 + 20,
      14,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        sill.shift(const Offset(0, 4)),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sill, const Radius.circular(4)),
      Paint()..color = _woodLight,
    );
    canvas.drawRect(
      Rect.fromLTWH(sill.left, sill.bottom - 4, sill.width, 4),
      Paint()..color = _woodDark,
    );
    final pot = Offset(g.right - 18, sill.top);
    final sway = math.sin(s._time * 1.1) * 0.08;
    canvas.save();
    canvas.translate(pot.dx, pot.dy - 14);
    canvas.rotate(sway);
    final leaf = Paint()..color = const Color(0xFF6FAE7A);
    for (final a in [-0.7, 0.0, 0.7]) {
      canvas.save();
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -10), width: 8, height: 20),
        leaf,
      );
      canvas.restore();
    }
    canvas.restore();
    canvas.drawPath(
      Path()
        ..moveTo(pot.dx - 10, pot.dy - 16)
        ..lineTo(pot.dx + 10, pot.dy - 16)
        ..lineTo(pot.dx + 7, pot.dy)
        ..lineTo(pot.dx - 7, pot.dy)
        ..close(),
      Paint()..color = const Color(0xFFD9805F),
    );
  }

  void _paintMullions(Canvas canvas, Rect g) {
    final bar = Paint()..color = _wood;
    final hi = Paint()..color = _woodLight;
    void v(double x) {
      canvas.drawRect(Rect.fromLTWH(x - 4, g.top, 8, g.height), bar);
      canvas.drawRect(Rect.fromLTWH(x - 4, g.top, 2, g.height), hi);
    }

    void h(double y) {
      canvas.drawRect(Rect.fromLTWH(g.left, y - 4, g.width, 8), bar);
      canvas.drawRect(Rect.fromLTWH(g.left, y - 4, g.width, 2), hi);
    }

    switch (s._lv.shape) {
      case WindowShape.cross:
        v(g.center.dx);
        h(g.center.dy);
      case WindowShape.sixPane:
        v(g.center.dx);
        h(g.top + g.height / 3);
        h(g.top + g.height * 2 / 3);
      case WindowShape.arch:
        h(g.top + g.width / 2);
        v(g.center.dx);
      case WindowShape.round:
      case WindowShape.plain:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _WindowPainter old) => old.s != s;
}
