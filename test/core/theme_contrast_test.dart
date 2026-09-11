// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/theme/cairn_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final spec in cairnBuiltInThemes) {
    group('theme ${spec.id}', () {
      test('primary text is legible on background and surface', () {
        expect(_contrast(spec.textPrimary, spec.background),
            greaterThanOrEqualTo(4.5));
        expect(_contrast(spec.textPrimary, spec.surface),
            greaterThanOrEqualTo(4.5));
      });
      test('secondary text is legible on the background', () {
        expect(_contrast(spec.textSecondary, spec.background),
            greaterThanOrEqualTo(3.0));
      });
      test('the accent label is legible on the accent', () {
        expect(_contrast(contrastOn(spec.accent), spec.accent),
            greaterThanOrEqualTo(3.0));
      });
    });
  }
}
