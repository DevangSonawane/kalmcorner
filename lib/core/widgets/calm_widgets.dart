import 'dart:math';

import 'package:flutter/material.dart';

class CalmButton extends StatelessWidget {
  const CalmButton({
    required this.onPressed,
    required this.child,
    this.variant = CalmButtonVariant.primary,
    this.size = CalmButtonSize.regular,
    this.enabled = true,
    this.icon,
    this.hapticEvent,
    this.soundId,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final CalmButtonVariant variant;
  final CalmButtonSize size;
  final bool enabled;
  final Widget? icon;
  final Object? hapticEvent;
  final Object? soundId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPressed = enabled && onPressed != null;

    Color bgColor;
    Color fgColor;
    BorderSide? side;

    switch (variant) {
      case CalmButtonVariant.primary:
        bgColor = isPressed ? colors.primary : colors.primary;
        fgColor = isPressed ? colors.onPrimary : colors.onPrimary;
        break;
      case CalmButtonVariant.secondary:
        bgColor = isPressed
            ? colors.secondaryContainer
            : colors.surfaceContainerHighest;
        fgColor = isPressed
            ? colors.onSecondaryContainer
            : colors.onSurfaceVariant;
        break;
      case CalmButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = isPressed ? colors.primary : colors.onSurface;
        side = BorderSide(
          color: isPressed ? colors.primary : colors.outline,
          width: 1.5,
        );
        break;
      case CalmButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = isPressed ? colors.primary : colors.onSurface;
        break;
    }

    final h = switch (size) {
      CalmButtonSize.small => 40.0,
      CalmButtonSize.regular => 52.0,
      CalmButtonSize.large => 60.0,
    };

    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isPressed
              ? () {
                  // Haptic and sound would be triggered here via callback
                  onPressed!();
                }
              : null,
          borderRadius: BorderRadius.circular(999),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Container(
            height: h,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: side != null ? Border.fromBorderSide(side) : null,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  DefaultTextStyle(
                    style:
                        theme.textTheme.labelLarge?.copyWith(
                          color: fgColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ) ??
                        const TextStyle(),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum CalmButtonVariant { primary, secondary, outline, ghost }

enum CalmButtonSize { small, regular, large }

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.size = 44,
    this.iconSize = 20,
    this.enabled = true,
    super.key,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(size / 2),
          splashFactory: NoSplash.splashFactory,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: enabled
                    ? colors.onSurface
                    : colors.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.elevation = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      elevation: elevation ? 0 : 0,
      shadowColor: elevation
          ? colors.shadow.withValues(alpha: 0.08)
          : Colors.transparent,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    this.size = 28,
    this.strokeWidth = 3,
    this.backgroundColor,
    this.foregroundColor,
    this.gapDegree = 0,
    super.key,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double gapDegree;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          progress: progress.clamp(0, 1),
          strokeWidth: strokeWidth,
          backgroundColor: backgroundColor ?? colors.outlineVariant,
          foregroundColor: foregroundColor ?? colors.primary,
          gapDegree: gapDegree,
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
    this.gapDegree = 0,
  });

  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;
  final double gapDegree;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    if (gapDegree > 0) {
      final gapRad = gapDegree * pi / 180;
      canvas.drawArc(
        rect,
        startAngle + gapRad / 2,
        2 * pi - gapRad,
        false,
        bgPaint,
      );
      if (progress > 0) {
        canvas.drawArc(
          rect,
          startAngle + gapRad / 2,
          sweepAngle - gapRad * progress,
          false,
          fgPaint,
        );
      }
    } else {
      canvas.drawArc(rect, startAngle, 2 * pi, false, bgPaint);
      if (progress > 0) {
        canvas.drawArc(rect, startAngle, sweepAngle, false, fgPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.gapDegree != gapDegree;
  }
}

class BreathingDot extends StatefulWidget {
  const BreathingDot({
    this.color,
    this.size = 8,
    this.duration = const Duration(milliseconds: 4000),
    super.key,
  });

  final Color? color;
  final double size;
  final Duration duration;

  @override
  State<BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<BreathingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.scale(
        scale: _animation.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class CalmBottomSheet extends StatelessWidget {
  const CalmBottomSheet({
    required this.child,
    this.title,
    this.showDragHandle = true,
    super.key,
  });

  final Widget child;
  final Widget? title;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: DefaultTextStyle(
                style: theme.textTheme.titleLarge!,
                child: title!,
              ),
            ),
          Flexible(child: child),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
