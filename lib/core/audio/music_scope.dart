import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/providers.dart';

/// Lets screens know when they become visible again after a pop.
final routeObserver = RouteObserver<ModalRoute<void>>();

/// Plays [music] while this screen is the visible route.
class MusicScope extends ConsumerStatefulWidget {
  const MusicScope({required this.music, required this.child, super.key});

  final MusicId music;
  final Widget child;

  @override
  ConsumerState<MusicScope> createState() => _MusicScopeState();
}

class _MusicScopeState extends ConsumerState<MusicScope> with RouteAware {
  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route && route != null) {
      if (_route != null) routeObserver.unsubscribe(this);
      _route = route;
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _play() => ref.read(audioServiceProvider).playMusic(widget.music);

  @override
  void didPush() => _play();

  @override
  void didPopNext() => _play();

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Whether sound is on. Persisted in `settings.sound`.
final soundOnProvider = NotifierProvider<SoundOn, bool>(SoundOn.new);

class SoundOn extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(prefsStoreProvider).getBool('settings.sound') ?? true;

  void toggle() {
    state = !state;
    ref.read(prefsStoreProvider).setBool('settings.sound', state);
    final audio = ref.read(audioServiceProvider);
    audio.applySettings(audio.settings.copyWith(enabled: state));
  }
}
