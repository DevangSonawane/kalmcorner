import 'package:flutter/material.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/features/games/game_module.dart';

import 'generator.dart';
import 'model.dart';
import 'painter.dart';

class ColorSortGame extends StatefulWidget {
  const ColorSortGame({
    required this.session,
    this.initialLevel = 1,
    super.key,
  });
  final GameSession session;
  final int initialLevel;

  @override
  State<ColorSortGame> createState() => _ColorSortGameState();
}

class _ColorSortGameState extends State<ColorSortGame>
    with WidgetsBindingObserver {
  late ColorSortState _state;
  int? _selected;
  int _level = 1;
  final bool _animating = false;
  final List<ColorSortState> _undoStack = [];
  (int, int)? _hint;
  DateTime? _hintShownAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _level = widget.initialLevel;
    final loaded = widget.session.loadState();
    if (loaded != null) {
      try {
        _level = (loaded['level'] as num?)?.toInt() ?? _level;
      } catch (_) {}
    }
    _state = ColorSortGenerator.generate(_level);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      try {
        widget.session.saveState({'level': _level});
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      widget.session.saveState({'level': _level});
    } catch (_) {}
    super.dispose();
  }

  void _selectTube(int i) {
    if (_animating) return;
    if (_selected == null) {
      if (_state.tubes[i].isEmpty) return;
      setState(() => _selected = i);
      widget.session.audio.play(
        SoundId.selectTube,
        volume: 0.6,
        rate: 0.9 + i * 0.05,
      );
      widget.session.haptics.fire(HapticEvent.tubeSelect);
      return;
    }
    if (_selected == i) {
      setState(() {
        _selected = null;
        _hint = null;
      });
      return;
    }
    final src = _selected!;
    final n = _state.legalMoveCount(src, i);
    if (n > 0) {
      _undoStack.add(_state.copy());
      _state.applyMove(src, i);
      setState(() {
        _selected = null;
        _hint = null;
      });
      widget.session.haptics.fire(HapticEvent.pourPulse);
      _checkWin();
    } else {
      setState(() => _selected = src);
      widget.session.audio.play(SoundId.uiBack, volume: 0.25);
      widget.session.haptics.fire(HapticEvent.invalid);
    }
  }

  void _checkWin() {
    if (_state.isWin) {
      widget.session.audio.play(SoundId.levelComplete, volume: 0.9);
      widget.session.haptics.fire(HapticEvent.levelComplete);
      // tube completion handled visually; level complete
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _level++;
          _state = ColorSortGenerator.generate(_level);
          _undoStack.clear();
          _selected = null;
          _hint = null;
        });
      });
    }
  }

  void _undo() {
    if (_animating || _undoStack.isEmpty) return;
    setState(() {
      _state = _undoStack.removeLast();
      _selected = null;
      _hint = null;
    });
  }

  void _hintAction() {
    if (_animating) return;
    final now = DateTime.now();
    if (_hintShownAt != null &&
        now.difference(_hintShownAt!).inMilliseconds < 3000) {
      return;
    }
    _hintShownAt = now;
    final h = ColorSortSolver.hint(_state);
    setState(() => _hint = h);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Semantics(
      label: 'Color Sort. Tap tubes to pour colors.',
      child: Stack(
        children: [
          GestureDetector(
            onTapDown: (d) {
              final idx = _tubeIndexAt(d.localPosition, size);
              if (idx != null) {
                _selectTube(idx);
              } else {
                setState(() => _selected = null);
              }
            },
            child: CustomPaint(
              size: size,
              painter: ColorSortPainter(
                state: _state,
                selected: _selected,
                tubeWidth: 44,
                unitHeight: 42,
                capacity: _state.capacity,
                hint: _hint,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [_btn('Undo', _undo), _btn('Hint', _hintAction)],
            ),
          ),
        ],
      ),
    );
  }

  int? _tubeIndexAt(Offset pos, Size size) {
    final tubes = _state.tubes;
    final t = tubes.length;
    final gap = 14.0;
    var w = 44.0;
    var g = gap;
    final avail = size.width - 40;
    int perRow = ((avail + g) / (w + g)).floor();
    if (perRow < 1) perRow = 1;
    if (perRow < (t / 3).ceil()) {
      w = 34.0;
      g = 8.0;
      perRow = ((avail + g) / (w + g)).floor();
      if (perRow < 1) perRow = 1;
    }
    final rows = (t / perRow).ceil();
    final tubeH = _state.capacity * 42.0 + 18;
    final rowGap = 24.0;
    final totalH = rows * tubeH + (rows - 1) * rowGap;
    var yStart = (size.height - totalH) / 2;
    if (yStart < 20) yStart = 20;
    for (int i = 0; i < t; i++) {
      final row = i ~/ perRow;
      final col = i % perRow;
      final rowTubes = (row == rows - 1) ? (t - row * perRow) : perRow;
      final rowWidth = rowTubes * (w + g) - g;
      final xStart = (size.width - rowWidth) / 2;
      final x = xStart + col * (w + g);
      final y = yStart + row * (tubeH + rowGap);
      if (pos.dx >= x &&
          pos.dx <= x + w &&
          pos.dy >= y &&
          pos.dy <= y + tubeH) {
        return i;
      }
    }
    return null;
  }

  Widget _btn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    ),
  );
}
