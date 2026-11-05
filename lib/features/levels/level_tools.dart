import 'package:flutter/material.dart';

import 'package:calmcorner/core/widgets/game_ui.dart';

/// A row of tool buttons that scales down rather than overflowing.
class LevelToolbar extends StatelessWidget {
  const LevelToolbar({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Chunky tool button used under the game board.
class LevelToolButton extends StatelessWidget {
  const LevelToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.color = const Color(0xFFFFFFFF),
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF3B3548);
    return ChunkyButton(
      semanticLabel: label,
      color: color,
      onPressed: enabled ? onTap : null,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: ink),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: ink)),
        ],
      ),
    );
  }
}
