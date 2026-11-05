import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:calmcorner/app/app.dart' show themeModeProvider;
import 'package:calmcorner/app/brand.dart';
import 'package:calmcorner/app/theme/tokens.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/audio/music_scope.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/core/providers.dart';
import 'package:calmcorner/core/widgets/cozy_sky.dart';
import 'package:calmcorner/core/widgets/game_ui.dart';
import 'package:calmcorner/features/levels/level_progress.dart';

const _panel = Color(0xFF2E2A52);
const _panelBorder = Color(0xFF4A4378);
const _gold = Color(0xFFFFC94D);
const _goldInk = Color(0xFF6B4A12);

/// Settings in the same cozy, chunky style as the rest of the app.
/// Every control here does something.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late double _music;
  late double _sfx;
  late String _haptics;
  late bool _reduceMotion;
  late bool _colorblind;
  late bool _keepAwake;
  late bool _fastPour;

  @override
  void initState() {
    super.initState();
    final store = ref.read(prefsStoreProvider);
    _music = store.getDouble('settings.music') ?? 0.5;
    _sfx = store.getDouble('settings.sfx') ?? 0.9;
    _haptics = store.getString('settings.haptics') ?? 'Normal';
    _reduceMotion = store.getBool('settings.reduceMotion') ?? false;
    _colorblind = store.getBool('settings.colorblind') ?? false;
    _keepAwake = store.getBool('settings.keepAwake') ?? true;
    _fastPour = store.getBool('settings.fastPour') ?? false;
  }

  void _click(bool on) {
    ref
        .read(audioServiceProvider)
        .play(on ? SoundId.uiToggleOn : SoundId.uiToggleOff, volume: 0.4);
    ref.read(hapticServiceProvider).fire(HapticEvent.toggle);
  }

  void _setVolumes({double? music, double? sfx}) {
    setState(() {
      _music = music ?? _music;
      _sfx = sfx ?? _sfx;
    });
    final audio = ref.read(audioServiceProvider);
    audio.applySettings(
      audio.settings.copyWith(musicVolume: _music, sfxVolume: _sfx),
    );
    final store = ref.read(prefsStoreProvider);
    store.setDouble('settings.music', _music);
    store.setDouble('settings.sfx', _sfx);
  }

  void _setHaptics(String level) {
    setState(() => _haptics = level);
    ref.read(prefsStoreProvider).setString('settings.haptics', level);
    final h = ref.read(hapticServiceProvider);
    h.applySettings(
      HapticSettings(
        level: switch (level) {
          'Off' => HapticLevel.off,
          'Soft' => HapticLevel.soft,
          _ => HapticLevel.normal,
        },
      ),
    );
    h.fire(HapticEvent.toggle);
  }

  void _setBool(String key, bool v, void Function(bool) apply) {
    setState(() => apply(v));
    ref.read(prefsStoreProvider).setBool(key, v);
    _click(v);
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFFFFBF5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFE0645A), width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.restart_alt_rounded,
                size: 44,
                color: Color(0xFFE0645A),
              ),
              const SizedBox(height: 10),
              const Text(
                'Start fresh?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3B3548),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This clears every star and level you have finished. '
                'Your settings stay the same.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6E6780),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ChunkyButton(
                      color: const Color(0xFFB9B2C8),
                      expand: true,
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('KEEP'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChunkyButton(
                      color: const Color(0xFFE0645A),
                      expand: true,
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('RESET'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    await ref.read(prefsStoreProvider).removePrefixed([
      'levels.',
      'game_state.',
      'game_progress.',
    ]);
    ref.read(progressVersionProvider.notifier).bump();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress cleared. A fresh start.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final soundOn = ref.watch(soundOnProvider);
    final theme = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1B1838),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: CozySky()),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
              children: [
                Row(
                  children: [
                    ChunkyIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      color: const Color(0xFF3B3660),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Color(0xFF0E0C22),
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 18),

                _Panel(
                  title: 'Sound',
                  icon: Icons.music_note_rounded,
                  children: [
                    _ToggleRow(
                      icon: soundOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      title: 'Music & sounds',
                      subtitle: soundOn ? 'On' : 'Everything is quiet',
                      value: soundOn,
                      onChanged: (v) {
                        ref.read(soundOnProvider.notifier).toggle();
                        if (v) _click(true);
                      },
                    ),
                    _SliderRow(
                      icon: Icons.queue_music_rounded,
                      title: 'Music',
                      value: _music,
                      enabled: soundOn,
                      onChanged: (v) => _setVolumes(music: v),
                    ),
                    _SliderRow(
                      icon: Icons.graphic_eq_rounded,
                      title: 'Game sounds',
                      value: _sfx,
                      enabled: soundOn,
                      onChanged: (v) => _setVolumes(sfx: v),
                      onChangeEnd: (_) => ref
                          .read(audioServiceProvider)
                          .play(SoundId.waterDrop, volume: 0.6),
                    ),
                  ],
                ),

                _Panel(
                  title: 'Vibration',
                  icon: Icons.vibration_rounded,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                      child: _Choices<String>(
                        value: _haptics,
                        options: const {
                          'Off': 'Off',
                          'Soft': 'Soft',
                          'Normal': 'Normal',
                        },
                        onChanged: _setHaptics,
                      ),
                    ),
                  ],
                ),

                _Panel(
                  title: 'Look',
                  icon: Icons.palette_rounded,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        'Colours inside the games',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: [
                          for (final m in AppThemeMode.values)
                            Expanded(
                              child: _ThemeSwatch(
                                mode: m,
                                selected: theme == m,
                                onTap: () {
                                  ref
                                      .read(themeModeProvider.notifier)
                                      .setThemeMode(m);
                                  _click(true);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    _ToggleRow(
                      icon: Icons.category_rounded,
                      title: 'Colour-blind symbols',
                      subtitle: 'Adds a shape to each colour in Still Waters',
                      value: _colorblind,
                      onChanged: (v) => _setBool(
                        'settings.colorblind',
                        v,
                        (x) => _colorblind = x,
                      ),
                    ),
                    _ToggleRow(
                      icon: Icons.slow_motion_video_rounded,
                      title: 'Reduce motion',
                      subtitle: 'Quicker, simpler animations',
                      value: _reduceMotion,
                      onChanged: (v) => _setBool(
                        'settings.reduceMotion',
                        v,
                        (x) => _reduceMotion = x,
                      ),
                    ),
                  ],
                ),

                _Panel(
                  title: 'Play',
                  icon: Icons.sports_esports_rounded,
                  children: [
                    _ToggleRow(
                      icon: Icons.light_mode_rounded,
                      title: 'Keep screen awake',
                      subtitle: 'While you are playing a level',
                      value: _keepAwake,
                      onChanged: (v) => _setBool(
                        'settings.keepAwake',
                        v,
                        (x) => _keepAwake = x,
                      ),
                    ),
                    _ToggleRow(
                      icon: Icons.speed_rounded,
                      title: 'Fast pour',
                      subtitle: 'Quicker pouring in Still Waters',
                      value: _fastPour,
                      onChanged: (v) => _setBool(
                        'settings.fastPour',
                        v,
                        (x) => _fastPour = x,
                      ),
                    ),
                  ],
                ),

                _Panel(
                  title: 'About',
                  icon: Icons.info_rounded,
                  children: [
                    _LinkRow(
                      icon: Icons.favorite_rounded,
                      title: 'Credits',
                      onTap: () => context.push('/credits'),
                    ),
                    _LinkRow(
                      icon: Icons.article_rounded,
                      title: 'Open-source licences',
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: AppBrand.name,
                        applicationVersion: AppBrand.version,
                      ),
                    ),
                    _LinkRow(
                      icon: Icons.restart_alt_rounded,
                      title: 'Reset progress',
                      danger: true,
                      onTap: _confirmReset,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      const CalmLogo(size: 54),
                      const SizedBox(height: 8),
                      Text(
                        '${AppBrand.name} · version ${AppBrand.version}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: _gold),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _panel.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _panelBorder, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0xFF15122C), offset: Offset(0, 5)),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon({
    required this.icon,
    required this.active,
    this.danger = false,
  });
  final IconData icon;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? const Color(0xFFE0645A)
        : active
        ? _gold
        : Colors.white.withValues(alpha: 0.1);
    final fg = danger
        ? Colors.white
        : active
        ? _goldInk
        : Colors.white60;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: fg, size: 22),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: title,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          child: Row(
            children: [
              _RowIcon(icon: icon, active: value),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: _goldInk,
                activeTrackColor: _gold,
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.onChangeEnd,
  });

  final IconData icon;
  final String title;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Row(
          children: [
            _RowIcon(icon: icon, active: enabled && value > 0),
            const SizedBox(width: 14),
            SizedBox(
              width: 112,
              child: Text(
                title,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  activeTrackColor: _gold,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                  thumbColor: Colors.white,
                  overlayColor: _gold.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 11,
                  ),
                ),
                child: Slider(
                  value: value.clamp(0.0, 1.0),
                  onChanged: enabled ? onChanged : null,
                  onChangeEnd: onChangeEnd,
                  semanticFormatterCallback: (v) =>
                      '$title ${(v * 100).round()}%',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final e in options.entries)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChunkyButton(
                semanticLabel: e.value,
                color: e.key == value ? _gold : const Color(0xFF443E6E),
                depth: 4,
                radius: 14,
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 10),
                onPressed: () => onChanged(e.key),
                child: Text(
                  e.value,
                  style: TextStyle(
                    color: e.key == value ? _goldInk : Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, colors) = switch (mode) {
      AppThemeMode.auto => ('Auto', [ThemeColors.dawn(), ThemeColors.dusk()]),
      AppThemeMode.dawn => ('Day', [ThemeColors.dawn()]),
      AppThemeMode.dusk => ('Evening', [ThemeColors.dusk()]),
      AppThemeMode.moonlit => ('Night', [ThemeColors.moonlit()]),
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '$label colours',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: selected ? _gold : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: SizedBox(
                  height: 54,
                  child: Row(
                    children: [
                      for (final c in colors)
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [c.bgGradientA, c.bg],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 14,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: c.accent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? _goldInk : Colors.white70,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          children: [
            _RowIcon(icon: icon, active: false, danger: danger),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: danger ? const Color(0xFFFF9B8F) : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
