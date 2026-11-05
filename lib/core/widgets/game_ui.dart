import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/core/providers.dart';

Color darken(Color c, [double amount = 0.22]) =>
    Color.lerp(c, Colors.black, amount)!;

Color lighten(Color c, [double amount = 0.25]) =>
    Color.lerp(c, Colors.white, amount)!;

/// A chunky "physical" button: a coloured face on a darker base that
/// presses down when touched, with a soft click.
class ChunkyButton extends ConsumerStatefulWidget {
  const ChunkyButton({
    required this.child,
    required this.onPressed,
    this.color = const Color(0xFF8E7CC3),
    this.depth = 5,
    this.radius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.expand = false,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final double depth;
  final double radius;
  final EdgeInsets padding;
  final bool expand;
  final String? semanticLabel;

  @override
  ConsumerState<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends ConsumerState<ChunkyButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final face = enabled ? widget.color : Colors.grey.shade400;
    final d = widget.depth;
    final offset = _down ? d - 1 : 0.0;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      margin: EdgeInsets.only(top: offset, bottom: d - offset),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lighten(face, 0.12), face],
        ),
        border: Border.all(color: lighten(face, 0.3), width: 1.5),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 17,
          letterSpacing: 0.3,
        ),
        child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white),
          child: Center(
            widthFactor: widget.expand ? null : 1,
            heightFactor: 1,
            child: widget.child,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapCancel: () => _set(false),
        onTapUp: enabled
            ? (_) {
                _set(false);
                ref.read(audioServiceProvider).play(SoundId.uiTap, volume: 0.4);
                ref.read(hapticServiceProvider).fire(HapticEvent.uiTap);
                widget.onPressed!();
              }
            : null,
        child: Stack(
          // Tight parents (e.g. a fixed-size coin) size the face too.
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              top: d,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: darken(face, 0.28),
                  borderRadius: BorderRadius.circular(widget.radius),
                ),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

/// Round chunky icon button for top bars.
class ChunkyIconButton extends StatelessWidget {
  const ChunkyIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final c = color ?? colors.surfaceContainerHighest;
    final onLight = c.computeLuminance() > 0.5;
    return Tooltip(
      message: tooltip,
      child: ChunkyButton(
        semanticLabel: tooltip,
        onPressed: onPressed,
        color: c,
        depth: 4,
        radius: 16,
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 22,
          color: onLight ? const Color(0xFF3B3548) : Colors.white,
        ),
      ),
    );
  }
}

/// HUD pill showing a star count.
class StarCounter extends StatelessWidget {
  const StarCounter({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2A45).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFFFD36B), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StarIcon(size: 26),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// A plump, hand-drawn style star.
class StarIcon extends StatelessWidget {
  const StarIcon({this.size = 24, this.filled = true, super.key});
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _StarPainter(filled));
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.filled);
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.48;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.52;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    if (!filled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      return;
    }
    canvas.drawPath(
      path.shift(Offset(0, size.height * 0.06)),
      Paint()..color = const Color(0xFFD9932E),
    );
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFC94D));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = size.width * 0.06
        ..color = const Color(0xFFFFE7A3),
    );
    canvas.drawCircle(
      c + Offset(-r * 0.25, -r * 0.2),
      r * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.filled != filled;
}

/// A folded ribbon banner with text.
class RibbonBanner extends StatelessWidget {
  const RibbonBanner({
    required this.text,
    required this.color,
    this.fontSize = 18,
    super.key,
  });

  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RibbonPainter(color),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: fontSize * 2.2,
          vertical: fontSize * 0.45,
        ),
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            letterSpacing: 1.2,
            shadows: [
              Shadow(color: darken(color, 0.4), offset: const Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final tail = h * 0.7;
    final dark = darken(color, 0.3);
    // Tails.
    for (final left in [true, false]) {
      final x0 = left ? 0.0 : size.width;
      final dir = left ? 1.0 : -1.0;
      final p = Path()
        ..moveTo(x0 + dir * tail * 0.6, h * 0.25)
        ..lineTo(x0 - dir * tail * 0.5, h * 0.25)
        ..lineTo(x0 - dir * tail * 0.15, h * 0.75)
        ..lineTo(x0 - dir * tail * 0.5, h * 1.2)
        ..lineTo(x0 + dir * tail * 0.6, h * 1.2)
        ..close();
      canvas.drawPath(p, Paint()..color = dark);
    }
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(tail * 0.4, 0, size.width - tail * 0.8, h),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tail * 0.4, 0, size.width - tail * 0.8, h * 0.45),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) => old.color != color;
}

/// Soft confetti burst. Restart by giving it a new key.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({required this.colors, this.count = 70, super.key});
  final List<Color> colors;
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  late final List<_Bit> _bits;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _bits = [
      for (var i = 0; i < widget.count; i++)
        _Bit(
          angle: -math.pi / 2 + (rng.nextDouble() - 0.5) * 2.2,
          speed: 0.5 + rng.nextDouble() * 0.7,
          spin: (rng.nextDouble() - 0.5) * 14,
          color: widget.colors[i % widget.colors.length],
          size: 5 + rng.nextDouble() * 6,
          round: rng.nextBool(),
        ),
    ];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_bits, _c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Bit {
  _Bit({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.color,
    required this.size,
    required this.round,
  });
  final double angle, speed, spin, size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, this.t);
  final List<_Bit> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.55);
    final reach = size.height * 0.75;
    for (final b in bits) {
      final d = reach * b.speed * (1 - math.pow(1 - t, 3).toDouble());
      final gravity = size.height * 0.5 * t * t;
      final p =
          origin +
          Offset(math.cos(b.angle) * d, math.sin(b.angle) * d + gravity);
      final a = (1 - t).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(b.spin * t);
      final paint = Paint()..color = b.color.withValues(alpha: a);
      if (b.round) {
        canvas.drawCircle(Offset.zero, b.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: b.size,
              height: b.size * 0.5,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
