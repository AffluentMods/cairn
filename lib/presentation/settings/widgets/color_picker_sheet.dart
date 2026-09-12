// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/theme/theme_codec.dart';

/// Curated swatches offered above the sliders, warm neutrals and clear accents
/// that read on a map.
const _swatches = <Color>[
  Color(0xFFD9A441),
  Color(0xFFB8862E),
  Color(0xFFE8825A),
  Color(0xFFE5484D),
  Color(0xFFF5A524),
  Color(0xFF3EC46D),
  Color(0xFF3FB8AF),
  Color(0xFF6FC3E0),
  Color(0xFF7AA7C7),
  Color(0xFF4A90E2),
  Color(0xFF9B7BD4),
  Color(0xFFE86A92),
  Color(0xFFF6F3EC),
  Color(0xFFE5E0D5),
  Color(0xFFA9B0AB),
  Color(0xFF5B615E),
  Color(0xFF2E3B34),
  Color(0xFF1E2C25),
  Color(0xFF15201B),
  Color(0xFF0E1412),
];

/// Opens the color picker for [initial] and resolves to the chosen color, or
/// null if dismissed (Fix Pass 1 X4.4: curated swatches plus an HSV and HEX
/// picker).
Future<Color?> showColorPicker(
  BuildContext context, {
  required Color initial,
  required String title,
}) {
  return showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ColorPickerSheet(initial: initial, title: title),
  );
}

class _ColorPickerSheet extends StatefulWidget {
  const _ColorPickerSheet({required this.initial, required this.title});

  final Color initial;
  final String title;

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final TextEditingController _hex =
      TextEditingController(text: hexOf(widget.initial));

  Color get _color => _hsv.toColor();

  void _setColor(Color c, {bool syncHex = true}) {
    setState(() {
      _hsv = HSVColor.fromColor(c);
      if (syncHex) _hex.text = hexOf(c);
    });
  }

  void _setHsv(HSVColor v) {
    setState(() {
      _hsv = v;
      _hex.text = hexOf(v.toColor());
    });
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.title,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _swatches)
                GestureDetector(
                  onTap: () => _setColor(c),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.toARGB32() == _color.toARGB32()
                            ? scheme.primary
                            : scheme.outline,
                        width: c.toARGB32() == _color.toARGB32() ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _GradientSlider(
            label: 'H',
            value: _hsv.hue,
            max: 360,
            gradient: LinearGradient(colors: [
              for (var h = 0; h <= 360; h += 60)
                HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
            ]),
            onChanged: (v) => _setHsv(_hsv.withHue(v)),
          ),
          _GradientSlider(
            label: 'S',
            value: _hsv.saturation,
            max: 1,
            gradient: LinearGradient(colors: [
              HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
              HSVColor.fromAHSV(1, _hsv.hue, 1, _hsv.value).toColor(),
            ]),
            onChanged: (v) => _setHsv(_hsv.withSaturation(v)),
          ),
          _GradientSlider(
            label: 'V',
            value: _hsv.value,
            max: 1,
            gradient: LinearGradient(colors: [
              HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 0).toColor(),
              HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 1).toColor(),
            ]),
            onChanged: (v) => _setHsv(_hsv.withValue(v)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _hex,
                  decoration: const InputDecoration(
                    labelText: 'HEX',
                    prefixText: '#',
                    isDense: true,
                  ),
                  onSubmitted: (t) {
                    try {
                      _setColor(parseHexColor(t), syncHex: false);
                    } on FormatException {
                      _hex.text = hexOf(_color); // revert an invalid entry
                    }
                  },
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(context, _color),
                child: Text(l10n.genericDone),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A slider whose track is a gradient, so the hue, saturation, and value bands
/// read at a glance.
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.gradient,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final Gradient gradient;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  trackHeight: 10,
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: value.clamp(0, max),
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
