// SPDX-License-Identifier: GPL-3.0-or-later

/// Which vehicles a Motor Vehicle Use Map segment is open to, and when. The
/// keys are the MVUM's own vehicle classes; [dates] is "yearlong" or a
/// "MM/DD-MM/DD" season as the Forest Service publishes it.
class RoadAccess {
  const RoadAccess({required this.vehicle, required this.dates});

  /// passengerVehicle, highClearance, truck, motorhome, fourWd, atv,
  /// motorcycle, or otherOhv.
  final String vehicle;
  final String dates;

  bool get yearlong => dates == 'yearlong';
}

/// One segment of a National Forest road or motorized trail from the Forest
/// Service Motor Vehicle Use Map (docs/API_NOTES.md), cached locally like OSM
/// trails so the layer and its cards work offline.
class ForestRoad {
  const ForestRoad({
    required this.id,
    required this.routeId,
    required this.number,
    required this.kind,
    required this.symbol,
    required this.seasonal,
    required this.geometry,
    this.name,
    this.symbolName,
    this.surface,
    this.maintLevel,
    this.access = const [],
    this.lengthMi,
  });

  /// Row id: the MVUM route id with a layer prefix, plus a part suffix for
  /// multi-part geometries ("r2100011", "t1151A#1").
  final String id;

  /// The MVUM route id as published ("2100011").
  final String routeId;

  /// The number as printed on the map: "2100" for a main road, "2100-011"
  /// for a spur.
  final String number;

  /// "road" (layer 1) or "trail" (a motorized trail, layer 2).
  final String kind;

  /// The MVUM symbol class (1 to 6 for roads); [symbolName] is its caption.
  final int symbol;
  final String? symbolName;

  /// True when the segment opens for a season, not all year.
  final bool seasonal;
  final String? name;

  /// The MVUM surface code and caption, e.g. "AGG - CRUSHED AGGREGATE OR
  /// GRAVEL".
  final String? surface;

  /// The operational maintenance level caption, e.g. "2 - HIGH CLEARANCE
  /// VEHICLES".
  final String? maintLevel;
  final List<RoadAccess> access;
  final double? lengthMi;

  /// [[lat, lon], ...]
  final List<List<double>> geometry;

  bool get isTrail => kind == 'trail';

  /// The surface code before the dash ("AGG"), or null.
  String? get surfaceCode {
    final s = surface;
    if (s == null) return null;
    final dash = s.indexOf(' - ');
    return (dash < 0 ? s : s.substring(0, dash)).trim().toUpperCase();
  }

  /// The maintenance level digit ("2"), or null.
  String? get maintLevelCode {
    final m = maintLevel;
    if (m == null || m.isEmpty) return null;
    return m.substring(0, 1);
  }
}

/// The number as printed on the Motor Vehicle Use Map. Route ids are seven
/// digits, the main road number followed by a three digit spur: "2100000" is
/// road 2100 and "2100011" is its spur, printed "2100-011". Anything else
/// (an id with letters, a short trail number) is shown as it is.
String forestRoadNumber(String routeId) {
  final id = routeId.trim();
  if (id.length == 7 && RegExp(r'^\d{7}$').hasMatch(id)) {
    final main = id.substring(0, 4);
    final spur = id.substring(4);
    return spur == '000' ? main : '$main-$spur';
  }
  return id;
}
