import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tuning.dart';

class TuningPanel extends StatefulWidget {
  const TuningPanel({required this.tuning, super.key});
  final Tuning tuning;

  @override
  State<TuningPanel> createState() => _TuningPanelState();
}

class _TuningPanelState extends State<TuningPanel> {
  final Map<String, double> _values = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final def in widget.tuning.defs.values) {
      _values[def.key] = widget.tuning[def.key];
      _controllers[def.key] = TextEditingController(
        text: _values[def.key]!.toStringAsFixed(3),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Tuning: ${widget.tuning.gameId}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.tuning.reset();
                      setState(() {
                        for (final def in widget.tuning.defs.values) {
                          _values[def.key] = widget.tuning[def.key];
                          _controllers[def.key]?.text = _values[def.key]!
                              .toStringAsFixed(3);
                        }
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  TextButton(
                    onPressed: _copyDart,
                    child: const Text('Copy Dart'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.tuning.defs.length,
                itemBuilder: (context, index) {
                  final def = widget.tuning.defs.values.elementAt(index);
                  return _TuningRow(
                    def: def,
                    value: _values[def.key]!,
                    controller: _controllers[def.key]!,
                    onChanged: (v) {
                      setState(() {
                        _values[def.key] = v;
                        _controllers[def.key]?.text = v.toStringAsFixed(3);
                        widget.tuning.setOverride(def.key, v);
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyDart() {
    final code = widget.tuning.toDartCode();
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }
}

class _TuningRow extends StatelessWidget {
  const _TuningRow({
    required this.def,
    required this.value,
    required this.controller,
    required this.onChanged,
  });

  final Tunable def;
  final double value;
  final TextEditingController controller;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${def.key}${def.unit.isNotEmpty ? ' (${def.unit})' : ''}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                '${def.min} — ${def.max}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: def.min,
                  max: def.max,
                  divisions: ((def.max - def.min) / 0.01).round().clamp(
                    10,
                    200,
                  ),
                  onChanged: onChanged,
                ),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => onChanged(double.tryParse(v) ?? value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
