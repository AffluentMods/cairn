// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/settings/settings_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeProxyUrl', () {
    test('empty means off', () {
      expect(normalizeProxyUrl(''), '');
      expect(normalizeProxyUrl('   '), '');
    });

    test('accepts https and strips trailing slashes', () {
      expect(
          normalizeProxyUrl('https://p.example.com/'), 'https://p.example.com');
      expect(normalizeProxyUrl('https://p.example.com/base//'),
          'https://p.example.com/base');
      expect(normalizeProxyUrl('  https://x.y  '), 'https://x.y');
    });

    test('refuses cleartext, other schemes, and bare hosts', () {
      expect(normalizeProxyUrl('http://p.example.com'), isNull);
      expect(normalizeProxyUrl('javascript:alert(1)'), isNull);
      expect(normalizeProxyUrl('p.example.com'), isNull);
      expect(normalizeProxyUrl('https://'), isNull);
    });
  });
}
