import 'dart:math' as math;

/// Bubble Pop world model (spec 7.2).
class Bubble {
  Bubble({
    required this.x,
    required this.y,
    required this.r,
    required this.tint,
    this.phase = 0,
    this.wobblePhase = 0,
    this.vx = 0,
    this.vy = 0,
    this.age = 0,
    this.state = BubbleState.alive,
    this.popT = 0,
  });

  double x, y, vx, vy, r;
  int tint;
  double phase, wobblePhase, age;
  BubbleState state;
  double popT;
}

enum BubbleState { alive, popping }

class BubbleWorld {
  BubbleWorld({required this.width, required this.height, this.rng});

  double width, height;
  math.Random? rng;
  final List<Bubble> bubbles = [];
  int spawnTarget = 12;
  int maxBubbles = 40;
  double popGoal = 25;
  int poppedThisRound = 0;
  int rounds = 0;
  int totalPopped = 0;
  int paletteIndex = 0;
  double t = 0;

  math.Random get _rng => rng ??= math.Random(1);

  void update(double dt) {
    t += dt;
    _spawn();
    _updateMotion(dt);
    _collisions();
    _walls();
    _removeTop();
    _updatePopping(dt);
  }

  void _spawn() {
    final alive = bubbles.where((b) => b.state == BubbleState.alive).length;
    if (alive >= spawnTarget || bubbles.length >= maxBubbles) return;
    // random delay handled by caller; here spawn immediately if below target
    final r = 24 + 40 * math.pow(_rng.nextDouble(), 1.6);
    final x = _rng.nextDouble() * (width - 2 * r) + r;
    // clearance from existing bottom bubbles
    final y = height + r + 10;
    final tint = _rng.nextInt(6);
    bubbles.add(
      Bubble(
        x: x,
        y: y,
        r: r.toDouble(),
        tint: tint,
        phase: _rng.nextDouble() * math.pi * 2,
        wobblePhase: _rng.nextDouble() * math.pi * 2,
      ),
    );
  }

  void _updateMotion(double dt) {
    for (final b in bubbles) {
      if (b.state != BubbleState.alive) continue;
      b.age += dt;
      final vt = 42 + 0.9 * (b.r - 24);
      b.vy += (-vt - b.vy) * 1.2 * dt;
      final ax = 14 * math.sin(2 * math.pi * (0.11 * t + b.y / 620) + b.phase);
      b.vx += ax * dt;
      b.vx *= math.exp(-0.9 * dt);
      b.x += b.vx * dt;
      b.y += b.vy * dt;
    }
  }

  void _collisions() {
    for (int i = 0; i < bubbles.length; i++) {
      for (int j = i + 1; j < bubbles.length; j++) {
        final a = bubbles[i], bb = bubbles[j];
        if (a.state != BubbleState.alive || bb.state != BubbleState.alive) {
          continue;
        }
        final dx = bb.x - a.x, dy = bb.y - a.y;
        final d = math.sqrt(dx * dx + dy * dy);
        final rr = a.r + bb.r;
        if (d < 0.95 * rr && d > 0) {
          final o = 0.95 * rr - d;
          final F = 220 * o;
          final nx = dx / d, ny = dy / d;
          final ma = a.r * a.r, mb = bb.r * bb.r;
          a.vx -= (F / ma) * nx * dtSafe(dtImplicit);
          a.vy -= (F / ma) * ny * dtSafe(dtImplicit);
          bb.vx += (F / mb) * nx * dtSafe(dtImplicit);
          bb.vy += (F / mb) * ny * dtSafe(dtImplicit);
          // normal velocity damping
          final rvx = bb.vx - a.vx, rvy = bb.vy - a.vy;
          final vn = rvx * nx + rvy * ny;
          if (vn < 0) {
            final damp = 6 * (-vn);
            a.vx -= damp * nx * dtSafe(dtImplicit);
            a.vy -= damp * ny * dtSafe(dtImplicit);
            bb.vx += damp * nx * dtSafe(dtImplicit);
            bb.vy += damp * ny * dtSafe(dtImplicit);
          }
        }
      }
    }
  }

  // dt not passed; use a fixed small dt for collision impulses (approx)
  double dtSafe(double dt) => dt;
  // placeholder; collisions should use sim dt. We'll refactor to pass dt.
  double dtImplicit = 1 / 120;

  void _walls() {
    for (final b in bubbles) {
      if (b.state != BubbleState.alive) continue;
      if (b.x - b.r < 8) {
        b.vx += 120 * (8 - (b.x - b.r)) * (1 / 120);
      }
      if (b.x + b.r > width - 8) {
        b.vx -= 120 * (8 - (width - 8 - (b.x + b.r))) * (1 / 120);
      }
    }
  }

  void _removeTop() {
    bubbles.removeWhere((b) {
      if (b.state != BubbleState.alive) return false;
      if (b.y + b.r < -10) return true;
      return false;
    });
  }

  void _updatePopping(double dt) {
    for (final b in bubbles) {
      if (b.state == BubbleState.popping) {
        b.popT += dt;
        if (b.popT >= 0.42) {
          b.state = BubbleState.alive; // mark for removal
        }
      }
    }
    bubbles.removeWhere(
      (b) => b.state == BubbleState.popping && b.popT >= 0.42,
    );
  }

  void pop(Bubble b) {
    if (b.state != BubbleState.alive) return;
    b.state = BubbleState.popping;
    b.popT = 0;
    // neighbor impulse
    for (final other in bubbles) {
      if (other.state != BubbleState.alive || other == b) continue;
      final dx = other.x - b.x, dy = other.y - b.y;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d < 2 * b.r && d > 0) {
        final impulse = 90 * (1 - d / (2 * b.r));
        other.vx += (dx / d) * impulse;
        other.vy += (dy / d) * impulse;
      }
    }
    poppedThisRound++;
    totalPopped++;
  }

  bool get roundComplete => poppedThisRound >= popGoal;

  void bloom() {
    // pop remaining alive bubbles in descending y order
    final alive = bubbles.where((b) => b.state == BubbleState.alive).toList()
      ..sort((a, b) => b.y.compareTo(a.y));
    for (final b in alive) {
      pop(b);
    }
    poppedThisRound = 0;
    rounds++;
  }
}
