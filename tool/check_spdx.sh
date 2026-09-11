#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Fails if any hand-written Dart file is missing the SPDX header.
# Generated files (*.g.dart, *.freezed.dart, *.mocks.dart) are exempt: they are
# produced by build_runner and carry the generator's own header.
set -euo pipefail

HEADER="SPDX-License-Identifier: GPL-3.0-or-later"
missing=0

while IFS= read -r -d '' file; do
  case "$file" in
    *.g.dart|*.freezed.dart|*.mocks.dart) continue ;;
    */l10n/app_localizations*.dart) continue ;;
  esac
  # Header must appear in the first 3 lines.
  if ! head -n 3 "$file" | grep -qF "$HEADER"; then
    echo "missing SPDX header: $file"
    missing=1
  fi
done < <(find lib test -name '*.dart' -type f -print0 2>/dev/null)

if [ "$missing" -ne 0 ]; then
  echo ""
  echo "Add this as the first line of each file listed above:"
  echo "// $HEADER"
  exit 1
fi

echo "SPDX headers present on all hand-written Dart files."
