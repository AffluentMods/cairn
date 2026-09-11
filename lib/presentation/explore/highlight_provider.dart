// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The trail geometry ([lat, lon] pairs) highlighted on Explore by "Show
/// route", or null when nothing is highlighted. It is drawn on the
/// cairn-highlight layer and cleared by a Clear pill (Fix Pass 1 X2.7).
final highlightRouteProvider =
    StateProvider<List<List<double>>?>((ref) => null);
