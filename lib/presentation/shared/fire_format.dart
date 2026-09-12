// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:intl/intl.dart';

/// Acres for a fire card: "0.1", "8.5", "310", "3,047". Spot fires are
/// reported as fractions of an acre, so whole-number rounding would show "0".
String formatAcres(double acres) {
  if (acres < 10) {
    final s = NumberFormat('0.#').format(acres);
    return s == '0' ? NumberFormat('0.#').format(0.1) : s;
  }
  return NumberFormat.decimalPattern().format(acres.round());
}
