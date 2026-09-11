// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/compute_route_stats.dart';
import 'package:cairn/presentation/map_common/widgets/elevation_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildProfileView', () {
    test('a flat profile is all gentle grade', () {
      final profile = [
        for (var d = 0; d <= 1000; d += 10) ProfilePoint(d.toDouble(), 100),
      ];
      final view = buildProfileView(profile, 2000);
      expect(view.segmentGrade, everyElement(0));
      expect(view.minE, 100);
      expect(view.maxE, 100);
    });

    test('a 30 percent slope is steep grade', () {
      final profile = [
        for (var d = 0; d <= 1000; d += 10)
          ProfilePoint(d.toDouble(), d * 0.30),
      ];
      final view = buildProfileView(profile, 2000);
      // The interior segments (with a full 100 m window) read as steep.
      expect(view.segmentGrade[view.segmentGrade.length ~/ 2], 2);
    });

    test('downsamples to about the target pixel count', () {
      final profile = [
        for (var i = 0; i < 5000; i++) ProfilePoint(i.toDouble(), i.toDouble()),
      ];
      final view = buildProfileView(profile, 500);
      expect(view.dist.length, 501); // target plus the appended last point
      expect(view.segmentGrade.length, view.dist.length - 1);
    });

    test('a short profile is not usable', () {
      final view = buildProfileView([ProfilePoint(0, 0)], 500);
      expect(view.isUsable, isFalse);
    });
  });
}
