import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:go_router/go_router.dart';

import 'game_module.dart';

import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/core/widgets/calm_widgets.dart';

class GameShell extends ConsumerStatefulWidget {
  const GameShell({required this.module, required this.session, super.key});

  final GameModule module;
  final GameSession session;

  @override
  ConsumerState<GameShell> createState() => _GameShellState();
}

class _GameShellState extends ConsumerState<GameShell>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final AnimationController _chromeController;
  late final Animation<double> _chromeAnimation;
  bool _chromeVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _chromeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _chromeAnimation = CurvedAnimation(
      parent: _chromeController,
      curve: Curves.easeOutCubic,
    );
    _chromeController.forward();

    WakelockPlus.enable();
    widget.session.requestChromeVisible(true);
    _scheduleChromeHide();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _chromeController.dispose();
    WakelockPlus.disable();
    widget.session.requestChromeVisible(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      WakelockPlus.disable();
    } else if (state == AppLifecycleState.resumed) {
      if (widget.session.settings.keepAwake) {
        WakelockPlus.enable();
      }
    }
  }

  void _scheduleChromeHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _chromeVisible) {
        setState(() => _chromeVisible = false);
        _chromeController.reverse();
      }
    });
  }

  void _onTouch() {
    if (!_chromeVisible) {
      setState(() => _chromeVisible = true);
      _chromeController.forward();
    }
    _scheduleChromeHide();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isTablet = widget.session.isTablet;

    return Listener(
      onPointerDown: (_) => _onTouch(),
      onPointerMove: (_) => _onTouch(),
      child: Scaffold(
        body: Stack(
          children: [
            // Game canvas
            widget.module.buildGame(context, widget.session),

            // Chrome overlay
            AnimatedBuilder(
              animation: _chromeAnimation,
              builder: (context, child) => Opacity(
                opacity: _chromeAnimation.value,
                child: IgnorePointer(
                  ignoring: !_chromeVisible,
                  child: _buildChrome(context, colors, isTablet),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChrome(BuildContext context, ColorScheme colors, bool isTablet) {
    final left = isTablet ? 24.0 : 16.0;
    final top = MediaQuery.of(context).padding.top + 16;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: left, right: left, top: top),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            GlassIconButton(
              icon: Icons.chevron_left_rounded,
              onPressed: () => _handleBack(context),
              tooltip: 'Back',
            ),
            const Spacer(),
            // Sound toggle
            GlassIconButton(
              icon: Icons.volume_up_rounded,
              onPressed: () => widget.session.audio.applySettings(
                const AudioSettings(enabled: false),
              ),
              tooltip: 'Sound',
            ),
            const SizedBox(width: 8),
            // Haptics toggle
            GlassIconButton(
              icon: Icons.vibration_rounded,
              onPressed: () => widget.session.haptics.applySettings(
                const HapticSettings(level: HapticLevel.off),
              ),
              tooltip: 'Haptics',
            ),
            const SizedBox(width: 8),
            // Menu
            GlassIconButton(
              icon: Icons.more_horiz_rounded,
              onPressed: () => _showMenu(context),
              tooltip: 'Menu',
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    widget.session.audio.pauseAll();
    context.pop();
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          _GameMenu(module: widget.module, session: widget.session),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _GameMenu extends StatelessWidget {
  const _GameMenu({required this.module, required this.session});
  final GameModule module;
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh_rounded),
            title: const Text('Restart'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Restart game
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Help'),
            onTap: () {
              Navigator.pop(context);
              _showHelp(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    // TODO: Show help hint card
  }
}

class CompletionSheet extends StatelessWidget {
  const CompletionSheet({
    required this.result,
    required this.onAgain,
    required this.onNext,
    required this.onHome,
    super.key,
  });

  final GameResult result;
  final VoidCallback onAgain;
  final VoidCallback onNext;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _getCompletionLine(),
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${(result.seconds ~/ 60).toString().padLeft(2, '0')}:${(result.seconds % 60).toString().padLeft(2, '0')} of calm',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAgain,
                  child: const Text('Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onNext,
                  child: Text(result.nextLabelKey ?? 'Next scene'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onHome,
                  child: const Text('Home'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCompletionLine() {
    const lines = [
      'Clear as morning.',
      'Nicely done. Take a breath.',
      'That felt good.',
      'All settled.',
      'Soft and still.',
      'Lovely.',
      'Calm, collected.',
      'Ahh. There it is.',
      'Well tended.',
      'Peace, delivered.',
    ];
    return lines[DateTime.now().millisecondsSinceEpoch % lines.length];
  }
}
