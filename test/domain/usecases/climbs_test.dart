// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/climbs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 20 m samples: flat 400 m, climb 600 m at 10 percent (60 m), flat 400 m,
  // a short 40 m dip, climb 400 m at 8 percent (32 m), descend 600 m.
  List<double> profile() {
    final e = <double>[];
    var z = 1000.0;
    for (var i = 0; i < 20; i++) {
      e.add(z);
    }
    for (var i = 0; i < 30; i++) {
      z += 2;
      e.add(z);
    }
    for (var i = 0; i < 20; i++) {
      e.add(z);
    }
    for (var i = 0; i < 2; i++) {
      z -= 1;
      e.add(z);
    }
    for (var i = 0; i < 20; i++) {
      z += 1.6;
      e.add(z);
    }
    for (var i = 0; i < 30; i++) {
      z -= 2;
      e.add(z);
    }
    return e;
  }

  test('finds the two climbs with their gain and grade', () {
    final elevs = profile();
    final dists = [for (var i = 0; i < elevs.length; i++) i * 20.0];
    final climbs = findClimbs(dists, elevs);
    expect(climbs.length, 2);
    expect(climbs[0].gainM, closeTo(60, 6));
    expect(climbs[0].gradePercent, closeTo(10, 2.5));
    expect(climbs[1].gainM, closeTo(32, 6));
    expect(climbs[0].endM, lessThan(climbs[1].startM));
  });

  test('a gentle slope is not a climb and climbAt finds the current one', () {
    final dists = [for (var i = 0; i < 50; i++) i * 20.0];
    final gentle = [for (var i = 0; i < 50; i++) 1000.0 + i * 0.4]; // 2%
    expect(findClimbs(dists, gentle), isEmpty);

    final elevs = profile();
    final d2 = [for (var i = 0; i < elevs.length; i++) i * 20.0];
    final climbs = findClimbs(d2, elevs);
    final mid = (climbs[0].startM + climbs[0].endM) / 2;
    expect(climbAt(climbs, mid), same(climbs[0]));
    expect(climbAt(climbs, 10), isNull);
  });
}
