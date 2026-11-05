import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:calmcorner/app/brand.dart';
import 'package:calmcorner/core/providers.dart';
import 'package:calmcorner/core/widgets/cozy_sky.dart';

/// Loading screen: the logo rises in, a soft bar fills while sounds load,
/// then we fade to onboarding (first launch) or Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _minShow = Duration(milliseconds: 1800);

  static const _tips = [
    'There is never a timer.',
    'You can’t lose. Take your time.',
    'Every finished level earns a star.',
    'Undo and hints are always free.',
  ];

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  late final AnimationController _bar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final String _tip = _tips[DateTime.now().second % _tips.length];
  Timer? _creep;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    // Creep towards 85% while loading; jump to 100% when done.
    _creep = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (_bar.value < 0.85) {
        _bar.animateTo(math.min(0.85, _bar.value + 0.06));
      }
    });
    _start();
  }

  Future<void> _start() async {
    final boot = ref.read(bootProvider);
    await Future.wait([
      boot.catchError((Object _) {}),
      Future<void>.delayed(_minShow),
    ]);
    _creep?.cancel();
    if (!mounted) return;
    await _bar.animateTo(1, duration: const Duration(milliseconds: 300));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _leaving = true);
    final seen =
        ref.read(prefsStoreProvider).getBool('onboarding.done') ?? false;
    context.go(seen ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _creep?.cancel();
    _intro.dispose();
    _loop.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1838),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: CozySky()),
          SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _loop, _bar]),
              builder: (context, _) {
                final rise = Curves.easeOutBack.transform(
                  (_intro.value / 0.7).clamp(0.0, 1.0),
                );
                final text = Curves.easeOut.transform(
                  ((_intro.value - 0.35) / 0.65).clamp(0.0, 1.0),
                );
                final bob = math.sin(_loop.value * 2 * math.pi) * 5;
                return Column(
                  children: [
                    const Spacer(flex: 3),
                    Opacity(
                      opacity: _intro.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - rise) * 60 + bob),
                        child: Transform.scale(
                          scale: 0.7 + 0.3 * rise,
                          child: Semantics(
                            label: '${AppBrand.name} logo',
                            child: CalmLogo(size: 150, t: _loop.value * 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    Opacity(
                      opacity: text,
                      child: Transform.translate(
                        offset: Offset(0, (1 - text) * 16),
                        child: Column(
                          children: [
                            const Text(
                              AppBrand.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF0E0C22),
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'little games for a slow evening',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    AnimatedOpacity(
                      opacity: _leaving ? 0 : text,
                      duration: const Duration(milliseconds: 250),
                      child: Column(
                        children: [
                          _LoadBar(value: _bar.value),
                          const SizedBox(height: 14),
                          Text(
                            _tip,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadBar extends StatelessWidget {
  const _LoadBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      value: '${(value * 100).round()}%',
      child: Container(
        width: 200,
        height: 18,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2A52),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFF4A4378), width: 2),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.04, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFDD85), Color(0xFFFFB84D)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
