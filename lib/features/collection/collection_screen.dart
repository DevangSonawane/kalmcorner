import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final plants = [
      {'name': 'Sunny', 'unlocked': true, 'icon': Icons.wb_sunny_rounded},
      {'name': 'Fern', 'unlocked': false, 'icon': Icons.eco_rounded},
      {'name': 'Succulent', 'unlocked': false, 'icon': Icons.grass_rounded},
      {'name': 'Bonsai', 'unlocked': false, 'icon': Icons.park_rounded},
      {
        'name': 'Cherry Blossom',
        'unlocked': false,
        'icon': Icons.local_florist_rounded,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garden'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Windowsill Garden',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a grown plant to visit it',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: plants.length,
                itemBuilder: (context, index) {
                  final plant = plants[index];
                  final unlocked = plant['unlocked'] as bool;
                  return _PlantPot(
                    name: plant['name'] as String,
                    unlocked: unlocked,
                    icon: plant['icon'] as IconData,
                    onTap: unlocked
                        ? () => context.push('/game/grow_plant')
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantPot extends StatelessWidget {
  const _PlantPot({
    required this.name,
    required this.unlocked,
    required this.icon,
    this.onTap,
  });

  final String name;
  final bool unlocked;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: unlocked
                    ? colors.surface
                    : colors.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border.all(
                  color: unlocked
                      ? colors.outlineVariant
                      : colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 48,
                  color: unlocked
                      ? colors.primary
                      : colors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              border: Border.all(
                color: unlocked
                    ? colors.outlineVariant
                    : colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              name,
              style: theme.textTheme.labelMedium?.copyWith(
                color: unlocked
                    ? colors.onSurface
                    : colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
