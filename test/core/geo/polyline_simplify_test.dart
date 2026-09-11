// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/geo/polyline_simplify.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collinear points collapse to the endpoints', () {
    final line = <List<double>>[
      [0, 0],
      [0, 0.001],
      [0, 0.002],
      [0, 0.003],
    ];
    final out = simplifyDouglasPeucker(line, 10);
    expect(out.length, 2);
    expect(out.first, [0, 0]);
    expect(out.last, [0, 0.003]);
  });

  test('a real corner is kept', () {
    final line = <List<double>>[
      [0, 0],
      [0, 0.001],
      [0.01, 0.0015], // about 1.1 km off the straight line
      [0, 0.002],
      [0, 0.003],
    ];
    final out = simplifyDouglasPeucker(line, 100);
    expect(out.any((p) => p[0] == 0.01), isTrue);
  });

  test('short lines are returned unchanged', () {
    final line = <List<double>>[
      [0, 0],
      [1, 1],
    ];
    expect(simplifyDouglasPeucker(line, 50).length, 2);
  });
}
