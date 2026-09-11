// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui' show Brightness, Color;

import 'package:drift/drift.dart';

import '../../core/theme/cairn_theme.dart';
import '../db/app_database.dart';

/// Stores Theme Designer themes (Fix Pass 1 X4.4). Colors are ARGB ints in the
/// `CustomThemes` table; here they are exchanged as [CairnThemeSpec].
class CustomThemeRepository {
  CustomThemeRepository(this._db);

  final AppDatabase _db;

  /// Watches all custom themes, newest first.
  Stream<List<CairnThemeSpec>> watchAll() {
    final query = _db.select(_db.customThemes)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toSpec).toList());
  }

  Future<void> save(CairnThemeSpec spec) =>
      _db.into(_db.customThemes).insertOnConflictUpdate(_toRow(spec));

  Future<void> delete(String id) =>
      (_db.delete(_db.customThemes)..where((t) => t.id.equals(id))).go();

  CairnThemeSpec _toSpec(CustomTheme r) => CairnThemeSpec(
        id: r.id,
        name: r.name,
        brightness: r.isDark ? Brightness.dark : Brightness.light,
        accent: Color(r.accent),
        background: Color(r.background),
        surface: Color(r.surface),
        raised: Color(r.raised),
        outline: Color(r.outline),
        textPrimary: Color(r.textPrimary),
        textSecondary: Color(r.textSecondary),
        route: Color(r.route),
        track: Color(r.track),
      );

  CustomThemesCompanion _toRow(CairnThemeSpec s) => CustomThemesCompanion.insert(
        id: s.id,
        name: s.name,
        isDark: s.isDark,
        accent: s.accent.toARGB32(),
        background: s.background.toARGB32(),
        surface: s.surface.toARGB32(),
        raised: s.raised.toARGB32(),
        outline: s.outline.toARGB32(),
        textPrimary: s.textPrimary.toARGB32(),
        textSecondary: s.textSecondary.toARGB32(),
        route: s.route.toARGB32(),
        track: s.track.toARGB32(),
        createdAt: DateTime.now(),
      );
}
