// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// The Cairn design tokens carried on every [ThemeData] as a [ThemeExtension]
/// (Fix Pass 1 X4.2). Widgets read these through `context.cairn` so a theme
/// switch, built-in or custom, reskins the whole app. The set mirrors the
/// Theme Designer color rows (X4.4): accent, background, surface, raised,
/// outline, text, secondary text, route, track. [onAccent] is computed by
/// contrast, [water] is a fixed legible blue.
@immutable
class CairnColors extends ThemeExtension<CairnColors> {
  const CairnColors({
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.surface,
    required this.raised,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.route,
    required this.track,
    required this.water,
  });

  final Color accent;
  final Color onAccent;
  final Color background;
  final Color surface;
  final Color raised;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color route;
  final Color track;
  final Color water;

  @override
  CairnColors copyWith({
    Color? accent,
    Color? onAccent,
    Color? background,
    Color? surface,
    Color? raised,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    Color? route,
    Color? track,
    Color? water,
  }) {
    return CairnColors(
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      route: route ?? this.route,
      track: track ?? this.track,
      water: water ?? this.water,
    );
  }

  @override
  CairnColors lerp(ThemeExtension<CairnColors>? other, double t) {
    if (other is! CairnColors) return this;
    return CairnColors(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      route: Color.lerp(route, other.route, t)!,
      track: Color.lerp(track, other.track, t)!,
      water: Color.lerp(water, other.water, t)!,
    );
  }
}

/// `context.cairn` for the current theme's tokens. Falls back to a neutral dark
/// set if a screen is somehow built without the extension, so a read never
/// throws.
extension CairnColorsX on BuildContext {
  CairnColors get cairn =>
      Theme.of(this).extension<CairnColors>() ?? _fallback;

  static const _fallback = CairnColors(
    accent: Color(0xFFD9A441),
    onAccent: Color(0xFF1B1300),
    background: Color(0xFF0E1412),
    surface: Color(0xFF15201B),
    raised: Color(0xFF1E2C25),
    outline: Color(0xFF2E3B34),
    textPrimary: Color(0xFFF1EEE6),
    textSecondary: Color(0xFFA9B0AB),
    route: Color(0xFFD9A441),
    track: Color(0xFF3FB8AF),
    water: Color(0xFF4A90E2),
  );
}
