// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/geo/terrarium.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('terrariumToMeters', () {
    test('sea level is R=128, G=0, B=0', () {
      expect(terrariumToMeters(128, 0, 0), closeTo(0, 1e-9));
    });
    test('one red step is 256 m', () {
      expect(terrariumToMeters(129, 0, 0), closeTo(256, 1e-9));
    });
    test('green is meters, blue is fractional meters', () {
      expect(terrariumToMeters(128, 10, 0), closeTo(10, 1e-9));
      expect(terrariumToMeters(128, 0, 128), closeTo(0.5, 1e-9));
    });
    test('below sea level is negative', () {
      expect(terrariumToMeters(127, 0, 0), closeTo(-256, 1e-9));
    });
  });

  group('bilinearSample', () {
    test('uniform grid returns the constant', () {
      final grid = List<double>.filled(4, 42.0);
      expect(bilinearSample(grid, 2, 2, 0.5, 0.5), closeTo(42, 1e-9));
    });

    test('linear ramp interpolates', () {
      // width 2, height 2, row-major: (0,0)=0 (1,0)=10 (0,1)=0 (1,1)=10
      final grid = <double>[0, 10, 0, 10];
      expect(bilinearSample(grid, 2, 2, 0.5, 0.0), closeTo(5, 1e-9));
      expect(bilinearSample(grid, 2, 2, 0.5, 1.0), closeTo(5, 1e-9));
      expect(bilinearSample(grid, 2, 2, 0.0, 0.0), closeTo(0, 1e-9));
      expect(bilinearSample(grid, 2, 2, 1.0, 0.0), closeTo(10, 1e-9));
    });

    test('clamps outside the grid', () {
      final grid = <double>[0, 10, 0, 10];
      expect(bilinearSample(grid, 2, 2, 5.0, 5.0), closeTo(10, 1e-9));
    });
  });
}
