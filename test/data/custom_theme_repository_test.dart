// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/theme/cairn_theme.dart';
import 'package:cairn/data/db/app_database.dart';
import 'package:cairn/data/repositories/custom_theme_repository.dart';
import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CustomThemeRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CustomThemeRepository(db);
  });
  tearDown(() async => db.close());

  const spec = CairnThemeSpec(
    id: 'custom-1',
    name: 'My Theme',
    brightness: Brightness.dark,
    accent: Color(0xFF112233),
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF141414),
    raised: Color(0xFF202020),
    outline: Color(0xFF303030),
    textPrimary: Color(0xFFF0F0F0),
    textSecondary: Color(0xFFA0A0A0),
    route: Color(0xFFD9A441),
    track: Color(0xFF3FB8AF),
  );

  test('the custom themes table exists and round-trips a theme', () async {
    await repo.save(spec);
    final all = await repo.watchAll().first;
    expect(all, hasLength(1));
    final back = all.single;
    expect(back.id, 'custom-1');
    expect(back.name, 'My Theme');
    expect(back.isDark, isTrue);
    expect(back.accent.toARGB32(), 0xFF112233);
    expect(back.track.toARGB32(), 0xFF3FB8AF);
  });

  test('save with the same id updates in place', () async {
    await repo.save(spec);
    await repo.save(spec.copyWith(name: 'Renamed'));
    final all = await repo.watchAll().first;
    expect(all, hasLength(1));
    expect(all.single.name, 'Renamed');
  });

  test('delete removes it', () async {
    await repo.save(spec);
    await repo.delete('custom-1');
    expect(await repo.watchAll().first, isEmpty);
  });
}
