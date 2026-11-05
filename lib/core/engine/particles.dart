import 'dart:math';

class ParticlePool<T extends Particle> {
  ParticlePool({
    required this.capacity,
    required this.createParticle,
    required this.updateParticle,
  }) {
    _particles = List<T>.generate(capacity, (i) => createParticle(i));
    _freeList = List<int>.generate(capacity, (i) => i);
    _alive = <T>[];
  }

  final int capacity;
  final T Function(int index) createParticle;
  final void Function(T particle, double dt) updateParticle;

  late final List<T> _particles;
  late final List<int> _freeList;
  late final List<T> _alive;
  int _freeCount = 0;

  List<T> get alive => _alive;

  T? spawn() {
    if (_freeCount == 0) return null;
    final index = _freeList[--_freeCount];
    final p = _particles[index];
    p.alive = true;
    _alive.add(p);
    return p;
  }

  void despawn(T particle) {
    if (!particle.alive) return;
    particle.alive = false;
    _alive.remove(particle);
    _freeList[_freeCount++] = particle.index;
  }

  void updateAll(double dt) {
    for (final p in _alive) {
      updateParticle(p, dt);
      if (!p.alive) {
        _freeList[_freeCount++] = p.index;
      }
    }
    _alive.removeWhere((p) => !p.alive);
  }

  void clear() {
    for (final p in _alive) {
      p.alive = false;
      _freeList[_freeCount++] = p.index;
    }
    _alive.clear();
  }
}

abstract class Particle {
  late int index;
  bool alive = false;
}

class PointParticle extends Particle {
  double x = 0, y = 0;
  double vx = 0, vy = 0;
  double life = 0, maxLife = 1;
  double size = 1;
  double hue = 0;
  double alpha = 1;
  double drag = 0;
  double gravity = 0;
}

class ParticlePools {
  static ParticlePool<PointParticle> createPointPool({
    int capacity = 500,
    double defaultDrag = 0,
    double defaultGravity = 0,
  }) {
    return ParticlePool<PointParticle>(
      capacity: capacity,
      createParticle: (i) => PointParticle()..index = i,
      updateParticle: (p, dt) {
        p.vx *= exp(-p.drag * dt);
        p.vy *= exp(-p.drag * dt);
        p.vy += p.gravity * dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
        p.alpha = (p.life / p.maxLife).clamp(0, 1);
        if (p.life <= 0) p.alive = false;
      },
    );
  }

  static ParticlePool<PointParticle> createDropletPool({int capacity = 120}) {
    return ParticlePool<PointParticle>(
      capacity: capacity,
      createParticle: (i) => PointParticle()..index = i,
      updateParticle: (p, dt) {
        // Droplet physics handled externally
        p.life -= dt;
        p.alpha = (p.life / p.maxLife).clamp(0, 1);
        if (p.life <= 0) p.alive = false;
      },
    );
  }
}
