// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The index of the visible shell branch: 0 Explore, 1 Navigate, 2 Saved,
/// 3 Activity. [AppShell] writes it on every branch change; [CairnMap] reads it
/// so only the active tab holds a live MapLibre surface (Addendum A3).
final shellIndexProvider = StateProvider<int>((ref) => 0);

/// Tab indices, named so widgets do not carry magic numbers.
abstract final class ShellTab {
  static const explore = 0;
  static const navigate = 1;
  static const saved = 2;
  static const activity = 3;
}
