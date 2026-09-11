// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../data/data_providers.dart';
import '../../../data/db/app_database.dart';
import '../user_waypoints_layer.dart';

/// Drop or edit a user waypoint (Addendum A4.5): kind chips, name, note, save
/// and delete. Standalone pins for now; route attachment and GPX `<wpt>` export
/// are follow-ups.
Future<void> showWaypointEditor(
  BuildContext context, {
  required double lat,
  required double lon,
  UserWaypoint? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _WaypointEditor(lat: lat, lon: lon, existing: existing),
  );
}

class _WaypointEditor extends ConsumerStatefulWidget {
  const _WaypointEditor({required this.lat, required this.lon, this.existing});

  final double lat;
  final double lon;
  final UserWaypoint? existing;

  @override
  ConsumerState<_WaypointEditor> createState() => _WaypointEditorState();
}

class _WaypointEditorState extends ConsumerState<_WaypointEditor> {
  late String _kind = widget.existing?.kind ?? 'water';
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.existing?.note ?? '');

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final id = widget.existing?.id ?? const Uuid().v4();
    await ref.read(userWaypointsRepositoryProvider).upsert(
          UserWaypointsCompanion.insert(
            id: id,
            kind: _kind,
            name: Value(_name.text.trim().isEmpty ? null : _name.text.trim()),
            note: Value(_note.text.trim().isEmpty ? null : _note.text.trim()),
            lat: widget.lat,
            lon: widget.lon,
            createdAt: widget.existing?.createdAt ?? DateTime.now(),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing != null) {
      await ref.read(userWaypointsRepositoryProvider).delete(existing.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? l10n.waypointAdd : l10n.waypointEdit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
              children: [
                for (final k in userWaypointKinds)
                  _KindChip(
                    kind: k,
                    selected: k == _kind,
                    onTap: () => setState(() => _kind = k),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.waypointNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.waypointNoteHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.existing != null)
                  TextButton.icon(
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    label: Text(l10n.waypointDelete,
                        style: TextStyle(color: scheme.error)),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(l10n.genericSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final String kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? scheme.primary.withValues(alpha: 0.16) : null,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(userWaypointIcon(kind), size: 16, color: scheme.onSurface),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                userWaypointLabel(l10n, kind),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
