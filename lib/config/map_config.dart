import 'package:flutter/widgets.dart';

/// MapConfig — single place to configure the map tile provider.
class MapConfig {
  MapConfig._();

  // ──────────────────────────────────────────────
  // Tile provider — dark mode OpenStreetMap
  // ──────────────────────────────────────────────

  /// Raster tile URL template (OpenStreetMap)
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Dark tile shader filter to seamlessly invert OSM tiles into dark mode without watermark
  static Widget darkTileBuilder(BuildContext context, Widget tileWidget, dynamic tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -0.85, 0, 0, 0, 235,
        0, -0.85, 0, 0, 235,
        0, 0, -0.85, 0, 235,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }

  /// Identify your app to the tile server (required by OSM policy).
  static const String userAgentPackageName = 'com.traceback.app';

  // ──────────────────────────────────────────────
  // Default camera settings — Bhubaneswar, Odisha
  // ──────────────────────────────────────────────

  static const double defaultLatitude = 20.2961;
  static const double defaultLongitude = 85.8245;
  static const double defaultZoom = 13.0;
  static const double detailZoom = 15.5;

  static const double minZoom = 4.0;
  static const double maxZoom = 19.0;

  // ──────────────────────────────────────────────
  // Marker colours
  // ──────────────────────────────────────────────

  /// Lost item marker (red)
  static const int lostMarkerColor = 0xFFEF4444;

  /// Found item marker (green/teal)
  static const int foundMarkerColor = 0xFF10B981;

  /// Recovered item marker (blue)
  static const int recoveredMarkerColor = 0xFF0284C7;

  /// Safe / registered item marker (slate)
  static const int safeMarkerColor = 0xFF64748B;
}
