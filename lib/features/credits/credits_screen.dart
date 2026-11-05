import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credits'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/brand/icon_1024.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'Kalm Corner',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'A pocket of small, satisfying things\nfor when you need a breath.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          _Section(
            title: 'Built with',
            items: [
              _CreditItem(name: 'Flutter', url: 'https://flutter.dev'),
              _CreditItem(name: 'Dart', url: 'https://dart.dev'),
              _CreditItem(name: 'Riverpod', url: 'https://riverpod.dev'),
              _CreditItem(
                name: 'Go Router',
                url: 'https://pub.dev/packages/go_router',
              ),
              _CreditItem(
                name: 'flutter_soloud',
                url: 'https://pub.dev/packages/flutter_soloud',
              ),
              _CreditItem(
                name: 'haptic_feedback',
                url: 'https://pub.dev/packages/haptic_feedback',
              ),
            ],
          ),

          const SizedBox(height: 24),

          _Section(
            title: 'Fonts (SIL OFL 1.1)',
            items: [
              _CreditItem(
                name: 'Nunito',
                url: 'https://fonts.google.com/specimen/Nunito',
              ),
              _CreditItem(
                name: 'Noto Sans Devanagari',
                url: 'https://fonts.google.com/specimen/Noto+Sans+Devanagari',
              ),
            ],
          ),

          const SizedBox(height: 24),

          _Section(
            title: 'Audio',
            items: [
              _CreditItem(
                name: 'Procedurally generated with gen_audio.py',
                url: '',
              ),
            ],
          ),

          const SizedBox(height: 24),

          _Section(
            title: 'Icons & Graphics',
            items: [
              _CreditItem(
                name: 'Procedurally generated with gen_icons.py',
                url: '',
              ),
              _CreditItem(
                name: 'Material Icons',
                url: 'https://fonts.google.com/icons',
              ),
            ],
          ),

          const SizedBox(height: 24),

          _Section(
            title: 'Special thanks',
            items: [
              _CreditItem(name: 'The Flutter team', url: ''),
              _CreditItem(name: 'Open source community', url: ''),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<_CreditItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }
}

class _CreditItem extends StatelessWidget {
  const _CreditItem({required this.name, required this.url});

  final String name;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(name, style: theme.textTheme.bodyMedium),
          if (url.isNotEmpty) ...[
            const Spacer(),
            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: colors.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}
