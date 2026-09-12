// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/theme/cairn_theme.dart';
import '../../core/theme/theme_codec.dart';
import '../../data/data_providers.dart';
import 'widgets/color_picker_sheet.dart';

/// Settings > Appearance > Theme Designer (Fix Pass 1 X4.4). Fork a built-in or
/// edit a custom theme: name it, set its mode, edit its nine colors with a live
/// preview, then save, export, or delete.
class ThemeDesignerScreen extends ConsumerStatefulWidget {
  const ThemeDesignerScreen({
    required this.base,
    this.isEditingCustom = false,
    super.key,
  });

  /// The theme to start from (a built-in to fork, or a custom theme to edit).
  final CairnThemeSpec base;

  /// True when [base] is a saved custom theme being edited in place (keep its
  /// id); false when forking a built-in into a new theme.
  final bool isEditingCustom;

  @override
  ConsumerState<ThemeDesignerScreen> createState() =>
      _ThemeDesignerScreenState();
}

class _ThemeDesignerScreenState extends ConsumerState<ThemeDesignerScreen> {
  late CairnThemeSpec _spec = widget.base;
  late final TextEditingController _name = TextEditingController(
      text: widget.isEditingCustom ? widget.base.name : '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _newId() =>
      'custom-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  CairnThemeSpec _forSave(String unnamed) {
    final name = _name.text.trim();
    return _spec.copyWith(
      id: widget.isEditingCustom ? widget.base.id : _newId(),
      name: name.isEmpty ? unnamed : name,
    );
  }

  Future<void> _save() async {
    final spec = _forSave(context.l10n.designerUnnamed);
    await ref.read(customThemeRepositoryProvider).save(spec);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pick(
      String label, Color current, void Function(Color) apply) async {
    final chosen =
        await showColorPicker(context, initial: current, title: label);
    if (chosen != null) setState(() => apply(chosen));
  }

  Future<void> _exportFile() async {
    final spec = _forSave(context.l10n.designerUnnamed);
    final dir = await getTemporaryDirectory();
    final safe = spec.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${dir.path}/$safe.cairntheme');
    await file.writeAsString(themeToFile(spec));
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _copyCode() async {
    final l10n = context.l10n;
    final code = themeToCode(_forSave(l10n.designerUnnamed));
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.designerCopied)));
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.designerDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.genericCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.genericDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(customThemeRepositoryProvider).delete(widget.base.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditingCustom
            ? l10n.designerTitle
            : l10n.designerNewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.genericSave,
            onPressed: _save,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'file':
                  _exportFile();
                case 'code':
                  _copyCode();
                case 'delete':
                  _delete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'file', child: Text(l10n.designerExportFile)),
              PopupMenuItem(
                  value: 'code', child: Text(l10n.designerExportCode)),
              if (widget.isEditingCustom)
                PopupMenuItem(value: 'delete', child: Text(l10n.genericDelete)),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _LivePreview(spec: _spec, name: _name.text),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _name,
              // Same cap the import codec applies (security re-audit, 6).
              maxLength: maxThemeNameLength,
              decoration: InputDecoration(
                labelText: l10n.designerName,
                hintText: l10n.designerNameHint,
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<Brightness>(
              segments: [
                ButtonSegment(
                    value: Brightness.dark, label: Text(l10n.themeDark)),
                ButtonSegment(
                    value: Brightness.light, label: Text(l10n.themeLight)),
              ],
              selected: {_spec.brightness},
              onSelectionChanged: (s) =>
                  setState(() => _spec = _spec.copyWith(brightness: s.first)),
            ),
          ),
          _header(context, l10n.designerStartFrom),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final b in cairnBuiltInThemes)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      avatar:
                          CircleAvatar(backgroundColor: b.accent, radius: 8),
                      label: Text(b.name),
                      onPressed: () => setState(() => _spec = _spec.copyWith(
                            brightness: b.brightness,
                            accent: b.accent,
                            background: b.background,
                            surface: b.surface,
                            raised: b.raised,
                            outline: b.outline,
                            textPrimary: b.textPrimary,
                            textSecondary: b.textSecondary,
                            route: b.route,
                            track: b.track,
                          )),
                    ),
                  ),
              ],
            ),
          ),
          _header(context, l10n.designerColors),
          _colorRow(l10n.tokenAccent, _spec.accent,
              (c) => _spec = _spec.copyWith(accent: c)),
          _colorRow(l10n.tokenBackground, _spec.background,
              (c) => _spec = _spec.copyWith(background: c)),
          _colorRow(l10n.tokenSurface, _spec.surface,
              (c) => _spec = _spec.copyWith(surface: c)),
          _colorRow(l10n.tokenRaised, _spec.raised,
              (c) => _spec = _spec.copyWith(raised: c)),
          _colorRow(l10n.tokenOutline, _spec.outline,
              (c) => _spec = _spec.copyWith(outline: c)),
          _colorRow(l10n.tokenText, _spec.textPrimary,
              (c) => _spec = _spec.copyWith(textPrimary: c)),
          _colorRow(l10n.tokenSecondary, _spec.textSecondary,
              (c) => _spec = _spec.copyWith(textSecondary: c)),
          _colorRow(l10n.tokenRoute, _spec.route,
              (c) => _spec = _spec.copyWith(route: c)),
          _colorRow(l10n.tokenTrack, _spec.track,
              (c) => _spec = _spec.copyWith(track: c)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _colorRow(
      String label, Color current, CairnThemeSpec Function(Color) apply) {
    return ListTile(
      title: Text(label),
      subtitle: Text(hexOf(current)),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: current,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      onTap: () => _pick(label, current, (c) => _spec = apply(c)),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}

/// A pinned live preview mimicking the Navigate sheet in the theme being edited
/// (Fix Pass 1 X4.4).
class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.spec, required this.name});

  final CairnThemeSpec spec;
  final String name;

  @override
  Widget build(BuildContext context) {
    final onAccent = contrastOn(spec.accent);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: spec.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A hint of the map: a route stroke over the background.
          SizedBox(
            height: 26,
            child: CustomPaint(
              painter: _RouteHint(spec.route, spec.track),
              size: const Size(double.infinity, 26),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: spec.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: spec.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.trim().isEmpty ? 'Trail preview' : name.trim(),
                  style: TextStyle(
                    color: spec.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '5.2 mi   1,240 ft   2h 40m',
                  style: TextStyle(color: spec.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: spec.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Start',
                            style: TextStyle(
                                color: onAccent, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: spec.outline),
                      ),
                      child: Icon(Icons.download,
                          size: 18, color: spec.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteHint extends CustomPainter {
  _RouteHint(this.route, this.track);

  final Color route;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final routePath = Path()
      ..moveTo(0, h * 0.8)
      ..cubicTo(size.width * 0.3, h * 0.1, size.width * 0.5, h * 0.9,
          size.width * 0.8, h * 0.2)
      ..lineTo(size.width, h * 0.4);
    canvas.drawPath(
      routePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = route,
    );
    canvas.drawCircle(
        Offset(size.width * 0.8, h * 0.2), 3.5, Paint()..color = track);
  }

  @override
  bool shouldRepaint(_RouteHint old) =>
      old.route != route || old.track != track;
}
