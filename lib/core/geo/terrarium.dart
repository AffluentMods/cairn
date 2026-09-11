// SPDX-License-Identifier: GPL-3.0-or-later

/// Decode a Mapzen/Tilezen "terrarium" RGB elevation sample to meters.
///
///   elevation_m = (R * 256 + G + B / 256) - 32768
///
/// Used both by MapLibre internally (for hillshade) and by Cairn's own elevation
/// lookups when decoding cached terrain tiles offline (spec Section 5.1, 8.3).
double terrariumToMeters(int r, int g, int b) =>
    (r * 256 + g + b / 256) - 32768;

/// Bilinear interpolation over a row-major elevation grid of [width] x [height].
/// [px] and [py] are fractional pixel coordinates. Clamps to the grid edges.
double bilinearSample(
  List<double> grid,
  int width,
  int height,
  double px,
  double py,
) {
  final x0 = px.floor().clamp(0, width - 1);
  final y0 = py.floor().clamp(0, height - 1);
  final x1 = (x0 + 1).clamp(0, width - 1);
  final y1 = (y0 + 1).clamp(0, height - 1);
  final fx = (px - x0).clamp(0.0, 1.0);
  final fy = (py - y0).clamp(0.0, 1.0);

  final v00 = grid[y0 * width + x0];
  final v10 = grid[y0 * width + x1];
  final v01 = grid[y1 * width + x0];
  final v11 = grid[y1 * width + x1];

  final top = v00 + (v10 - v00) * fx;
  final bottom = v01 + (v11 - v01) * fx;
  return top + (bottom - top) * fy;
}
