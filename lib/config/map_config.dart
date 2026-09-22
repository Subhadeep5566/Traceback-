/// MapConfig — single place to configure the map tile provider.
///
/// To switch to a CDN-backed provider for production, only change
/// [tileUrlTemplate] and [userAgentPackageName]. Nothing else needs to change.
///
/// Tile provider options (no Google Maps):
///   • OpenStreetMap (dev only, no key):
///       https://tile.openstreetmap.org/{z}/{x}/{y}.png
///   • Stadia Maps (free tier, key required):
///       https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png?api_key=KEY
///   • MapTiler (free tier, key required):
///       https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=KEY
///   • OpenFreeMap (free, no key, production-safe):
///       https://tiles.openfreemap.org/tiles/liberty/{z}/{x}/{y}.pbf  (vector)
///       Use raster fallback: https://tile.openstreetmap.org/{z}/{x}/{y}.png
class MapConfig {
  MapConfig._();

  // ──────────────────────────────────────────────
  // Tile provider — change only this URL to swap providers
  // ──────────────────────────────────────────────

  /// Raster tile URL template. Supports {z}, {x}, {y} placeholders.
  /// Current: OpenStreetMap (suitable for development/testing).
  /// For production replace with a CDN-backed URL (see notes above).
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

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
