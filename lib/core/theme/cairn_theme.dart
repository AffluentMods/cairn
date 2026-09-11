// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'cairn_colors.dart';

/// A theme as nine editable colors plus a name and brightness (Fix Pass 1 X4.3,
/// X4.4). Built-in themes and Theme Designer themes are both a [CairnThemeSpec];
/// [themeFromSpec] turns one into a [ThemeData].
@immutable
class CairnThemeSpec {
  const CairnThemeSpec({
    required this.id,
    required this.name,
    required this.brightness,
    required this.accent,
    required this.background,
    required this.surface,
    required this.raised,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.route,
    required this.track,
  });

  final String id;
  final String name;
  final Brightness brightness;
  final Color accent;
  final Color background;
  final Color surface;
  final Color raised;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color route;
  final Color track;

  bool get isDark => brightness == Brightness.dark;

  CairnThemeSpec copyWith({
    String? id,
    String? name,
    Brightness? brightness,
    Color? accent,
    Color? background,
    Color? surface,
    Color? raised,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    Color? route,
    Color? track,
  }) {
    return CairnThemeSpec(
      id: id ?? this.id,
      name: name ?? this.name,
      brightness: brightness ?? this.brightness,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      route: route ?? this.route,
      track: track ?? this.track,
    );
  }
}

/// The near-black used for on-accent text, warm to match the palette.
const _onDark = Color(0xFF16130C);

double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Near-black or white, whichever actually reads better on [background]. This
/// is how a switch knob or a filled button label stays legible on any accent
/// (Fix Pass 1 X4.1). Picking by measured contrast, not a luminance cutoff,
/// keeps mid-tone accents (steel blue, coral) legible.
Color contrastOn(Color background) =>
    _contrastRatio(Colors.white, background) >=
            _contrastRatio(_onDark, background)
        ? Colors.white
        : _onDark;

/// Builds a [ThemeData] from a spec with an explicitly mapped [ColorScheme] (no
/// `fromSeed`, Fix Pass 1 X4.2) and the [CairnColors] tokens attached.
ThemeData themeFromSpec(CairnThemeSpec s) {
  final onAccent = contrastOn(s.accent);
  final scheme = ColorScheme(
    brightness: s.brightness,
    primary: s.accent,
    onPrimary: onAccent,
    primaryContainer: s.raised,
    onPrimaryContainer: s.textPrimary,
    secondary: s.track,
    onSecondary: contrastOn(s.track),
    tertiary: s.accent,
    onTertiary: onAccent,
    error: AppColors.fire,
    onError: Colors.white,
    surface: s.surface,
    onSurface: s.textPrimary,
    onSurfaceVariant: s.textSecondary,
    surfaceContainerHighest: s.raised,
    surfaceContainerHigh: s.raised,
    surfaceContainer: s.surface,
    outline: s.outline,
    outlineVariant: s.outline,
    shadow: Colors.black,
  );

  final cairn = CairnColors(
    accent: s.accent,
    onAccent: onAccent,
    background: s.background,
    surface: s.surface,
    raised: s.raised,
    outline: s.outline,
    textPrimary: s.textPrimary,
    textSecondary: s.textSecondary,
    route: s.route,
    track: s.track,
    water: AppColors.water,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: s.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: s.background,
    textTheme: AppTypography.textTheme(scheme),
    extensions: [cairn],
    dividerTheme: DividerThemeData(color: s.outline, thickness: 1),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: s.accent.withValues(alpha: s.isDark ? 0.20 : 0.16),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      backgroundColor: s.background,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: s.raised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: s.accent,
        foregroundColor: onAccent,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: s.textPrimary,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: s.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? onAccent : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? s.accent : null,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: s.raised,
      contentTextStyle: TextStyle(color: s.textPrimary),
    ),
    // Sheets and dialogs get generous 24 dp corners (Fix Pass 1 X4.5).
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: s.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: s.raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: s.raised,
      side: BorderSide(color: s.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

/// The seven built-in themes (Fix Pass 1 X4.3). Larch is the default dark and
/// Paper the default light; the rest are alternates the user can pick or fork
/// in the Theme Designer.
const cairnBuiltInThemes = <CairnThemeSpec>[
  CairnThemeSpec(
    id: 'larch',
    name: 'Larch',
    brightness: Brightness.dark,
    accent: Color(0xFFD9A441),
    background: Color(0xFF0E1412),
    surface: Color(0xFF15201B),
    raised: Color(0xFF1E2C25),
    outline: Color(0xFF2E3B34),
    textPrimary: Color(0xFFF1EEE6),
    textSecondary: Color(0xFFA9B0AB),
    route: Color(0xFFD9A441),
    track: Color(0xFF3FB8AF),
  ),
  CairnThemeSpec(
    id: 'paper',
    name: 'Paper',
    brightness: Brightness.light,
    accent: Color(0xFFB8862E),
    background: Color(0xFFF6F3EC),
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFFFFFFF),
    outline: Color(0xFFE5E0D5),
    textPrimary: Color(0xFF1B1F1D),
    textSecondary: Color(0xFF5B615E),
    route: Color(0xFFB8862E),
    track: Color(0xFF2B8F88),
  ),
  CairnThemeSpec(
    id: 'basalt',
    name: 'Basalt',
    brightness: Brightness.dark,
    accent: Color(0xFF7AA7C7),
    background: Color(0xFF101315),
    surface: Color(0xFF181C1F),
    raised: Color(0xFF232A30),
    outline: Color(0xFF333C43),
    textPrimary: Color(0xFFECEFF1),
    textSecondary: Color(0xFF9AA4AD),
    route: Color(0xFF7AA7C7),
    track: Color(0xFF4FB0A6),
  ),
  CairnThemeSpec(
    id: 'glacier',
    name: 'Glacier',
    brightness: Brightness.dark,
    accent: Color(0xFF6FC3E0),
    background: Color(0xFF0B1418),
    surface: Color(0xFF10202A),
    raised: Color(0xFF17303C),
    outline: Color(0xFF24424F),
    textPrimary: Color(0xFFE7F3F8),
    textSecondary: Color(0xFF9CB6C0),
    route: Color(0xFF6FC3E0),
    track: Color(0xFF58D6C8),
  ),
  CairnThemeSpec(
    id: 'alpenglow',
    name: 'Alpenglow',
    brightness: Brightness.dark,
    accent: Color(0xFFE8825A),
    background: Color(0xFF16100F),
    surface: Color(0xFF201715),
    raised: Color(0xFF2E201C),
    outline: Color(0xFF3E2C27),
    textPrimary: Color(0xFFF6E9E3),
    textSecondary: Color(0xFFC1A79E),
    route: Color(0xFFE8825A),
    track: Color(0xFF5FB3A3),
  ),
  CairnThemeSpec(
    id: 'headlamp',
    name: 'Headlamp',
    brightness: Brightness.dark,
    accent: Color(0xFFE5484D),
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF141010),
    raised: Color(0xFF201717),
    outline: Color(0xFF3A2422),
    textPrimary: Color(0xFFE8C9C7),
    textSecondary: Color(0xFFA87E7C),
    route: Color(0xFFE5484D),
    track: Color(0xFFB5726C),
  ),
  CairnThemeSpec(
    id: 'topo',
    name: 'Topo',
    brightness: Brightness.light,
    accent: Color(0xFFC56A2C),
    background: Color(0xFFF4EFE3),
    surface: Color(0xFFFFFDF7),
    raised: Color(0xFFFFFFFF),
    outline: Color(0xFFD9CDB3),
    textPrimary: Color(0xFF2A2419),
    textSecondary: Color(0xFF6A5F4C),
    route: Color(0xFFC56A2C),
    track: Color(0xFF3A7CA5),
  ),
];

const cairnDefaultDarkThemeId = 'larch';
const cairnDefaultLightThemeId = 'paper';

/// The built-in with [id], or null if it is not a built-in (a custom theme).
CairnThemeSpec? builtInThemeById(String id) {
  for (final t in cairnBuiltInThemes) {
    if (t.id == id) return t;
  }
  return null;
}
