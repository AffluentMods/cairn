#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Fetch the pinned MapLibre GL JS build used by the 3D terrain view
# (Addendum A5.2) into assets/web/, and verify its SHA-256. Both files are
# committed so the community/F-Droid build needs no network at build time.
# MapLibre GL JS is BSD-3-Clause; note it in docs/LICENSES.md.
set -euo pipefail

VER="4.7.1"
BASE="https://cdnjs.cloudflare.com/ajax/libs/maplibre-gl/${VER}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/assets/web"
mkdir -p "$DEST"

JS_SHA="be9633c4d870e26fb37f1cfe5c5a77181667114003ea16207ac7850d8da8add1"
CSS_SHA="576b085fdd9487a65a19215328c1e086c07ce5bf6da09b666b3806d3d008dae9"

curl -fsSL "${BASE}/maplibre-gl.js" -o "${DEST}/maplibre-gl.js"
curl -fsSL "${BASE}/maplibre-gl.css" -o "${DEST}/maplibre-gl.css"

echo "${JS_SHA}  ${DEST}/maplibre-gl.js" | sha256sum -c -
echo "${CSS_SHA}  ${DEST}/maplibre-gl.css" | sha256sum -c -
echo "MapLibre GL JS ${VER} fetched and verified."
