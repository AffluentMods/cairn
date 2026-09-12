#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Fails if a raw Color(0x...) literal appears in presentation code, where colors
# should come from the theme (context.cairn tokens or the ColorScheme) so a
# theme switch, built-in or custom, reskins everything (Fix Pass 1 X4.6).
#
# A short allowlist covers files whose raw colors are data or representation,
# not chrome, and so are legitimately literal:
#   - the color-picker swatch palette (a palette is colors by definition)
#   - the layer-sheet map-style preview chips and the slope legend gradient
#     (they depict the map and the data, not the app surface)
#   - the immersive full-screen 3D overlay (its own fixed dark chrome)
set -euo pipefail

allow=(
  "lib/presentation/settings/widgets/color_picker_sheet.dart"
  "lib/presentation/map_common/widgets/layer_sheet.dart"
  "lib/presentation/navigate/terrain_3d_screen.dart"
)

is_allowed() {
  local f="$1"
  for a in "${allow[@]}"; do
    [ "$f" = "$a" ] && return 0
  done
  return 1
}

bad=0
while IFS= read -r -d '' file; do
  case "$file" in
    *.g.dart|*.freezed.dart) continue ;;
  esac
  if is_allowed "$file"; then
    continue
  fi
  if grep -nE 'Color\(0x' "$file" >/dev/null; then
    echo "raw Color(0x...) in presentation (use context.cairn / ColorScheme): $file"
    grep -nE 'Color\(0x' "$file" | sed 's/^/    /'
    bad=1
  fi
done < <(find lib/presentation -name '*.dart' -type f -print0 2>/dev/null)

if [ "$bad" -ne 0 ]; then
  echo ""
  echo "Move these to theme tokens, or add the file to the allowlist in"
  echo "tool/check_theme_tokens.sh with a reason if the color is data, not chrome."
  exit 1
fi

echo "check_theme_tokens: ok"
