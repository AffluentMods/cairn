// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:intl/intl.dart';

/// Which units the user sees. Everything is stored in SI internally (meters,
/// Celsius, meters per second) and formatted only at the edge (spec Section 2).
enum UnitSystem { imperial, metric }

/// Formats SI values into user-facing strings for the chosen [UnitSystem]. No
/// em dashes, tabular-friendly. The degree sign is fine; it is not an em dash.
class UnitFormatter {
  const UnitFormatter(this.units);

  final UnitSystem units;

  static const _mPerMile = 1609.344;
  static const _mPerFoot = 0.3048;

  bool get _imperial => units == UnitSystem.imperial;

  /// Distance, e.g. "12.4 mi" or "19.9 km". One decimal under 100, none above.
  String distance(double meters) {
    if (_imperial) {
      final mi = meters / _mPerMile;
      return '${_num(mi)} mi';
    }
    final km = meters / 1000.0;
    return '${_num(km)} km';
  }

  /// Elevation or gain, e.g. "2,706 ft" or "825 m". Whole numbers, grouped.
  String elevation(double meters) {
    if (_imperial) {
      final ft = meters / _mPerFoot;
      return '${_grouped(ft)} ft';
    }
    return '${_grouped(meters)} m';
  }

  /// Signed elevation delta, e.g. "+2,706 ft" or "-1,900 ft".
  String elevationSigned(double meters) {
    final sign = meters >= 0 ? '+' : '-';
    return '$sign${elevation(meters.abs())}';
  }

  /// Temperature, e.g. "68 deg" rendered with the degree sign: "68°F".
  String temperature(double celsius) {
    if (_imperial) {
      final f = celsius * 9 / 5 + 32;
      return '${f.round()}°F';
    }
    return '${celsius.round()}°C';
  }

  /// Speed, e.g. "2.3 mph" or "3.7 km/h".
  String speed(double metersPerSecond) {
    if (_imperial) {
      final mph = metersPerSecond / _mPerMile * 3600;
      return '${_num(mph)} mph';
    }
    final kmh = metersPerSecond / 1000.0 * 3600;
    return '${_num(kmh)} km/h';
  }

  /// Pace, e.g. "26:28 /mi" or "16:27 /km". Zero or absurd speeds show a dash.
  String pace(double metersPerSecond) {
    if (metersPerSecond <= 0.05) return '--';
    final secondsPerUnit =
        _imperial ? _mPerMile / metersPerSecond : 1000.0 / metersPerSecond;
    final label = _imperial ? '/mi' : '/km';
    return '${_clock(secondsPerUnit.round())} $label';
  }

  /// Short weight, e.g. "45 lb" or "20 kg". Input in kilograms.
  String weight(double kg) {
    if (_imperial) {
      final lb = kg / 0.45359237;
      return '${lb.round()} lb';
    }
    return '${kg.round()} kg';
  }

  /// A duration as "8h 10m" or "2:58:53" style for elapsed times.
  static String durationHm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  static String durationClock(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h == 0) return '$m:$ss';
    return '$h:$mm:$ss';
  }

  String _num(double v) {
    if (v.abs() >= 100) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  String _grouped(double v) => NumberFormat('#,##0').format(v.round());

  static String _clock(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
