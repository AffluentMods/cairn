// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// Cairn palette (spec Section 9.3). Warm neutrals, one gold accent, teal for
/// water and the recorded track. Semantic colors are chosen for legibility on
/// top of a map and are the same in both themes.
abstract final class AppColors {
  // Brand
  static const larch = Color(0xFFD9A441); // accent, one per surface (dark)
  static const larchLight = Color(0xFFB8862E); // accent on light surfaces
  static const glacier = Color(0xFF3FB8AF); // secondary, water and links

  // Surfaces (dark)
  static const inkDeep = Color(0xFF0E1412); // near-black with a green cast
  static const ink = Color(0xFF15201B);
  static const inkRaised = Color(0xFF1E2C25);
  static const textPrimaryDark = Color(0xFFF1EEE6);
  static const textSecondaryDark = Color(0xFFA9B0AB);

  // Surfaces (light)
  static const paper = Color(0xFFF6F3EC);
  static const paperRaised = Color(0xFFFFFFFF);
  static const paperBorder = Color(0xFFE5E0D5);
  static const textPrimaryLight = Color(0xFF1B1F1D);
  static const textSecondaryLight = Color(0xFF5B615E);

  // Semantic (map legibility, chosen per mode where it matters)
  static const fire = Color(0xFFE5484D);
  static const smoke = Color(0xFFF5A524); // caution
  static const closure = Color(0xFF8B8B8B); // also "stale"
  static const water = Color(0xFF4A90E2);
  static const route = Color(0xFFD9A441);
  static const track = Color(0xFF3FB8AF);
  static const trackLight = Color(0xFF2B8F88);
  static const trailOsm = Color(0xFF6B4F2A); // brown, like a paper map
  static const trailInformal = Color(0xFF9C8A6E);
  // The summit triangle and peak labels on the vector base maps.
  static const summit = Color(0xFF4A3B2A);

  // AQI category colors (EPA breakpoints, spec Phase 7).
  static const aqiGood = Color(0xFF3EC46D);
  static const aqiModerate = Color(0xFFF5C518);
  static const aqiUsg = Color(0xFFF5A524);
  static const aqiUnhealthy = Color(0xFFE5484D);
  static const aqiVeryUnhealthy = Color(0xFF9B59B6);
  static const aqiHazardous = Color(0xFF7B2D26);
}
